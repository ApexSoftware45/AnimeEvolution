--!strict
-- PetSystem.server.luau
-- Handles egg purchases, cutscene trigger, and granting pets.

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------
-- Shared modules
---------------------------------------------------------------------
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if not SharedFolder then
	SharedFolder = Instance.new("Folder")
	SharedFolder.Name = "Shared"
	SharedFolder.Parent = ReplicatedStorage
end

local PetData = require(SharedFolder:WaitForChild("PetData") :: ModuleScript)
local EggData = require(SharedFolder:WaitForChild("EggData") :: ModuleScript)

---------------------------------------------------------------------
-- RemoteEvents / Folders bootstrap
---------------------------------------------------------------------
local function ensureRemote(name: string)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

local PetPurchaseRequest   = ensureRemote("PetPurchaseRequest")   -- Client -> Server: (eggName)
local PetPurchaseResult    = ensureRemote("PetPurchaseResult")    -- Server -> Client: (success:boolean, message:string, petName:string?)
local EggCutsceneEvent     = ensureRemote("EggCutsceneEvent")     -- Server -> Client: (eggModel, petName)
local TutorialEggPurchased = ensureRemote("TutorialEggPurchased") -- Server -> Client: tutorial progression ping
local TutorialPetEquipped  = ensureRemote("TutorialPetEquipped")  -- Server -> Client: tutorial equip ping

-- Pets library folder (models to clone for preview / followers, optional)
local PetsFolder = ReplicatedStorage:FindFirstChild("Pets")
if not PetsFolder then
	PetsFolder = Instance.new("Folder")
	PetsFolder.Name = "Pets"
	PetsFolder.Parent = ReplicatedStorage
end

-- World eggs folder (where your placed egg models live)
local WorldEggs = workspace:FindFirstChild("Eggs")
if not WorldEggs then
	WorldEggs = Instance.new("Folder")
	WorldEggs.Name = "Eggs"
	WorldEggs.Parent = workspace
end

-- Cutscene templates (replicated to clients for animations)
local EggTemplatesFolder = ReplicatedStorage:FindFirstChild("EggCutsceneTemplates")
if not EggTemplatesFolder then
	EggTemplatesFolder = Instance.new("Folder")
	EggTemplatesFolder.Name = "EggCutsceneTemplates"
	EggTemplatesFolder.Parent = ReplicatedStorage
end

local eggTemplateCache: { [string]: Model } = {}

---------------------------------------------------------------------
-- Simple data store (handed off to your DataPersistence when wired)
---------------------------------------------------------------------
type PetInventory = {
	pets: { [string]: boolean }, -- set of owned pet names
	equipped: string?,           -- optional equipped pet name
}

local playerPets: { [number]: PetInventory } = {}

local function getInventory(p: Player): PetInventory
	local inv = playerPets[p.UserId]
	if not inv then
		inv = { pets = {}, equipped = nil }
		playerPets[p.UserId] = inv
	end
	return inv
end

local function getPetDisplayName(petId: string): string
	if PetData then
		local def = PetData[petId]
		if def and typeof(def.DisplayName) == "string" and def.DisplayName ~= "" then
			return def.DisplayName
		end
	end
	return petId
end

---------------------------------------------------------------------
-- Currency helpers (attribute fallback + _G hooks if present)
---------------------------------------------------------------------
local function getAttrNumber(inst: Instance, name: string, default: number): number
	local v = inst:GetAttribute(name)
	if typeof(v) == "number" then return v end
	return default
end

local function trySpend(p: Player, currency: "Money" | "Gems", amount: number): (boolean, string)
	if amount <= 0 then return true, "" end

	-- Prefer global economy helpers if your project defines them
	if currency == "Money" and _G.trySpendMoney then
		local ok, msg = _G.trySpendMoney(p, amount)
		return ok, msg or ""
	elseif currency == "Gems" and _G.trySpendGems then
		local ok, msg = _G.trySpendGems(p, amount)
		return ok, msg or ""
	end

	-- Fallback to attributes
	local current = getAttrNumber(p, currency, 0)
	if current < amount then
		return false, ("Not enough %s. Need %d, have %d."):format(currency, amount, current)
	end
	p:SetAttribute(currency, current - amount)
	return true, ""
end

local function grantPet(p: Player, petName: string)
	local inv = getInventory(p)
	inv.pets[petName] = true

	if typeof(_G.GivePetToPlayer) == "function" then
		local ok, grantResult, extra = pcall(function()
			return _G.GivePetToPlayer(p, petName)
		end)
		if not ok then
			warn("[PetSystem] Failed to hand off pet to inventory:", grantResult)
		elseif grantResult ~= true then
			warn("[PetSystem] Inventory rejected pet grant for", petName, extra)
		end
	end

	if _G.onPetGranted then
		-- Optional hook for analytics or UI synchronization
		pcall(function()
			_G.onPetGranted(p, petName)
		end)
	end
end

---------------------------------------------------------------------
-- Public API (available to other systems & DataPersistence)
---------------------------------------------------------------------
_G.givePet = function(p: Player, petName: string)
	grantPet(p, petName)
end

_G.hasPet = function(p: Player, petName: string): boolean
	local inv = getInventory(p)
	return inv.pets[petName] == true
end

_G.PetSystem_GetSave = function(p: Player)
	local inv = getInventory(p)
	-- Serialize set → array
	local list = {}
	for name, owned in pairs(inv.pets) do
		if owned then table.insert(list, name) end
	end
	return {
		pets = list,
		equipped = inv.equipped,
	}
end

_G.PetSystem_LoadFromData = function(p: Player, data: any)
	local inv = getInventory(p)
	inv.pets = {}
	if data and typeof(data) == "table" then
		if typeof(data.pets) == "table" then
			for _, name in ipairs(data.pets) do
				if typeof(name) == "string" then
					inv.pets[name] = true
				end
			end
		end
		if typeof(data.equipped) == "string" then
			inv.equipped = data.equipped
		else
			inv.equipped = nil
		end
	end
end

---------------------------------------------------------------------
-- Egg Catalog (now sourced from Shared/EggData)
-- Build a runtime structure the purchase flow understands.
---------------------------------------------------------------------
type EggPoolEntry = {
	weight: number,
	name: string?,
	rarity: string?,
	candidates: { string }?,
}

type EggDef = {
	price: number,
	currency: "Money" | "Gems",
	worldModelName: string, -- name under workspace.Eggs
	pool: { EggPoolEntry }, -- weighted RNG
	id: string?,
}

local function buildEggPoolFromEggData(eggEntry: any): { EggPoolEntry }
	local pool = {}
	if not eggEntry or typeof(eggEntry) ~= "table" then
		return pool
	end

	local petsList = eggEntry.Pets
	if typeof(petsList) ~= "table" then
		return pool
	end

	-- Build a fast lookup for exclusions
	local function isExcluded(petId: string, excludeTbl: any): boolean
		if typeof(excludeTbl) ~= "table" then return false end
		for _, ex in ipairs(excludeTbl) do
			if ex == petId then return true end
		end
		return false
	end

	for _, entry in ipairs(petsList) do
		local weight = math.max(tonumber(entry.Weight) or 1, 0)
		if weight <= 0 then
			continue
		end

		if typeof(entry.PetId) == "string" then
			table.insert(pool, { name = entry.PetId, weight = weight })
		elseif typeof(entry.Rarity) == "string" and PetData then
			local candidates = {}
			for petId, def in pairs(PetData) do
				if def and def.Rarity == entry.Rarity and not isExcluded(petId, entry.Exclude) then
					table.insert(candidates, petId)
				end
			end
			if #candidates > 0 then
				table.insert(pool, {
					rarity = entry.Rarity,
					weight = weight,
					candidates = candidates,
				})
			end
		end
	end

	return pool
end

local function buildEggsFromShared(): { [string]: EggDef }
	local eggs: { [string]: EggDef } = {}
	if not EggData then
		return eggs
	end

	local WORLD_MODEL_BY_ID = {
		StarterEgg = "Egg",
		RareEgg = "EggRare",
		SpottedRareEgg = "EggSpotted",
	}

	for id, def in pairs(EggData) do
		local price = tonumber(def.Price) or 0
		local currency: any = def.CurrencyType == "Gems" and "Gems" or "Money"
		local worldModelName = WORLD_MODEL_BY_ID[id] or tostring(def.WorldModelName or id)
		local pool = buildEggPoolFromEggData(def)

		eggs[id] = {
			price = price,
			currency = currency,
			worldModelName = worldModelName,
			pool = (#pool > 0) and pool or { { name = "KidNaruto", weight = 1 } },
			id = id,
		}
	end

	return eggs
end

local Eggs: { [string]: EggDef } = buildEggsFromShared()

---------------------------------------------------------------------
-- RNG helper
---------------------------------------------------------------------
local function pickFromCandidates(entry: EggPoolEntry): string
	local list = entry.candidates
	if list and #list > 0 then
		return list[math.random(1, #list)]
	end
	return entry.name or "Pet"
end

local function rollPet(egg: EggDef): string
	local total = 0
	for _, opt in ipairs(egg.pool) do
		total += math.max(0, opt.weight)
	end
	if total <= 0 then
		local first = egg.pool[1]
		if first then
			return pickFromCandidates(first)
		end
		return "Pet"
	end
	local r = math.random() * total
	local sum = 0
	for _, opt in ipairs(egg.pool) do
		sum += math.max(0, opt.weight)
		if r <= sum then
			return pickFromCandidates(opt)
		end
	end
	return pickFromCandidates(egg.pool[#egg.pool])
end

---------------------------------------------------------------------
-- Validation helpers
---------------------------------------------------------------------
local function ensureModelPrimary(model: Model)
	if model.PrimaryPart then
		return
	end
	local primary = model:FindFirstChild("Primary") or model:FindFirstChildWhichIsA("BasePart", true)
	if primary then
		model.PrimaryPart = primary :: any
	end
end

local function createPlaceholderEggTemplate(eggId: string): Model
	local model = Instance.new("Model")
	model.Name = eggId .. "_Template"

	local part = Instance.new("Part")
	part.Name = "Primary"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2.2, 2.8, 2.2)
	part.Color = Color3.fromRGB(80, 226, 255)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model

	model.PrimaryPart = part
	model.Parent = EggTemplatesFolder
	eggTemplateCache[eggId] = model
	return model
end

local function createTemplateFromSource(eggId: string, source: Instance): Model?
	if not source then
		return nil
	end

	local existing = eggTemplateCache[eggId]
	if existing then
		existing:Destroy()
		eggTemplateCache[eggId] = nil
	end

	local old = EggTemplatesFolder:FindFirstChild(eggId .. "_Template")
	if old then
		old:Destroy()
	end

	local template: Model
	if source:IsA("Model") then
		template = source:Clone()
	else
		template = Instance.new("Model")
		local clone = source:Clone()
		if clone.Name == "" then
			clone.Name = "Primary"
		end
		clone.Parent = template
	end

	template.Name = eggId .. "_Template"
	ensureModelPrimary(template)
	if not template.PrimaryPart then
		local primary = template:FindFirstChildWhichIsA("BasePart", true)
		if not primary then
			return nil
		end
		template.PrimaryPart = primary :: any
	end

	template.Parent = EggTemplatesFolder
	eggTemplateCache[eggId] = template
	return template
end

_G.PetSystem_RegisterEggTemplate = function(eggId: string, source: Instance)
	if typeof(eggId) ~= "string" or eggId == "" or not source then
		return
	end
	createTemplateFromSource(eggId, source)
end

_G.PetSystem_HasEggTemplate = function(eggId: string): boolean
	if typeof(eggId) ~= "string" or eggId == "" then
		return false
	end
	local cached = eggTemplateCache[eggId]
	if cached and cached.Parent then
		return true
	end
	local existing = EggTemplatesFolder:FindFirstChild(eggId .. "_Template")
	return existing ~= nil
end

local function getWorldEggModel(eggId: string, def: EggDef): Model?
	local cached = eggTemplateCache[eggId]
	if cached and cached.Parent then
		return cached
	end

	local existing = EggTemplatesFolder:FindFirstChild(eggId .. "_Template")
	if existing and existing:IsA("Model") then
		ensureModelPrimary(existing)
		eggTemplateCache[eggId] = existing
		return existing
	end

	local source: Instance? = nil
	if WorldEggs then
		source = WorldEggs:FindFirstChild(def.worldModelName)
	end
	if not source then
		source = workspace:FindFirstChild(def.worldModelName, true)
	end

	if source then
		local template = createTemplateFromSource(eggId, source)
		if template then
			return template
		end
	end

	warn(string.format("[PetSystem] No egg model found for '%s'; using placeholder.", eggId))
	return createPlaceholderEggTemplate(eggId)
end

local function resolveInstanceFromPath(path: string): Instance?
	if typeof(path) ~= "string" or path == "" then
		return nil
	end

	local segments = {}
	for segment in string.gmatch(path, "[^/]+") do
		table.insert(segments, segment)
	end
	if #segments == 0 then
		return nil
	end

	local current: Instance?
	local first = segments[1]
	if first == "Workspace" then
		current = workspace
	else
		current = game:FindFirstChild(first)
		if not current then
			local ok, service = pcall(function()
				return game:GetService(first)
			end)
			if ok then
				current = service
			end
		end
	end
	if not current then
		return nil
	end

	for i = 2, #segments do
		current = current:FindFirstChild(segments[i])
		if not current then
			return nil
		end
	end

	return current
end

local function ensurePetTemplateExists(petName: string)
	-- Optional convenience: create a simple placeholder if missing,
	-- so the cutscene still has something to show in LocalScript.
	if PetsFolder:FindFirstChild(petName) then return end

	if PetData then
		local def = PetData[petName]
		if def and typeof(def.ModelPath) == "string" then
			local source = resolveInstanceFromPath(def.ModelPath)
			if source and source:IsA("Model") then
				local clone = source:Clone()
				clone.Name = petName
				if not clone.PrimaryPart then
					local primary = clone:FindFirstChild("Primary") or clone:FindFirstChildWhichIsA("BasePart")
					if primary then
						clone.PrimaryPart = primary :: any
					end
				end
				clone.Parent = PetsFolder
				return
			end
		end
	end

	local model = Instance.new("Model")
	model.Name = petName
	local part = Instance.new("Part")
	part.Name = "Primary"
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Color = Color3.fromRGB(255, 255, 255)
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = true
	part.Parent = model
	model.PrimaryPart = part
	model.Parent = PetsFolder
end

---------------------------------------------------------------------
-- Tutorial helper: tell the client a pet was equipped at least once
---------------------------------------------------------------------
_G.NotifyTutorialPetEquipped = function(p: Player)
	if TutorialPetEquipped then
		TutorialPetEquipped:FireClient(p)
	end
end

---------------------------------------------------------------------
-- Purchase flow
-- 1) Validate egg, price, funds
-- 2) Charge player
-- 3) Roll pet
-- 4) Fire cutscene to client (EggCutsceneEvent)
-- 5) After a short delay, grant pet + respond via PetPurchaseResult
---------------------------------------------------------------------
local CUTSCENE_DELAY = 3.8 -- seconds; keep in sync with your client animation

local function handlePurchase(player: Player, eggName: string)
	local def = Eggs[eggName]
	if not def then
		PetPurchaseResult:FireClient(player, false, "Unknown egg.", "")
		return
	end

	local eggModel = getWorldEggModel(def.id or eggName, def)
	if not eggModel then
		PetPurchaseResult:FireClient(player, false, "Egg model not found.", "")
		return
	end

	-- Spend currency
	local ok, msg = trySpend(player, def.currency, def.price)
	if not ok then
		PetPurchaseResult:FireClient(player, false, msg ~= "" and msg or "Not enough currency.", "")
		return
	end

	if TutorialEggPurchased then
		TutorialEggPurchased:FireClient(player)
	end

	-- Roll outcome
	local petName = rollPet(def)
	ensurePetTemplateExists(petName)

	local petDisplayName = getPetDisplayName(petName)

	-- Fire the client-side cutscene
	EggCutsceneEvent:FireClient(player, eggModel, petName)

	-- Grant pet after animation
	task.delay(CUTSCENE_DELAY, function()
		grantPet(player, petName)
		PetPurchaseResult:FireClient(player, true, ("You hatched: %s!"):format(petDisplayName), petName)
	end)
end

---------------------------------------------------------------------
-- Remote binding
---------------------------------------------------------------------
_G.PetSystem_HandlePurchase = function(player: Player, eggName: string)
	handlePurchase(player, eggName)
end

PetPurchaseRequest.OnServerEvent:Connect(function(player, eggName: any)
	if typeof(eggName) ~= "string" then
		PetPurchaseResult:FireClient(player, false, "Invalid request.", "")
		return
	end
	-- Basic anti-spam (optional)
	local ok, err = pcall(function()
		handlePurchase(player, eggName)
	end)
	if not ok then
		warn("[PetSystem] Purchase error:", err)
		PetPurchaseResult:FireClient(player, false, "Server error.", "")
	end
end)

---------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(p: Player)
	-- If you don’t have a money system yet, seed attributes so testing works.
	if p:GetAttribute("Money") == nil then p:SetAttribute("Money", 0) end
	if p:GetAttribute("Gems") == nil then p:SetAttribute("Gems", 0) end

	-- Ensure inventory exists
	getInventory(p)

	-- Optional: simple debug grant for testing (comment out in prod)
	-- p:SetAttribute("Money", 5000)
end)

Players.PlayerRemoving:Connect(function(p: Player)
	-- If your DataPersistence pulls via _G.PetSystem_GetSave, nothing else needed here.
	-- Place for last-second flush hooks if needed.
end)

---------------------------------------------------------------------
-- Debug helpers (Studio only)
---------------------------------------------------------------------
if RunService:IsStudio() then
	_G.testEggPurchase = function(playerName: string, eggName: string)
		local plr = Players:FindFirstChild(playerName)
		if not plr then
			warn("No player named", playerName)
			return
		end
		handlePurchase(plr, eggName)
	end

	_G.debugGivePet = function(playerName: string, petName: string)
		local plr = Players:FindFirstChild(playerName)
		if not plr then return end
		grantPet(plr, petName)
	end
end

print("[PetSystem] Ready: PetPurchaseRequest, PetPurchaseResult, EggCutsceneEvent, Tutorial events initialized.")

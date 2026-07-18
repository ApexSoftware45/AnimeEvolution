-- Server-side pet inventory + equip handling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetData = require(ReplicatedStorage.Shared.PetData)

local PET_CAP = 3
local SELL_REWARD_BY_RARITY = {
	Common = 500,
	Rare = 10_000,
	Epic = 500_000,
}
math.randomseed(tick() % 1 * 1e7)

local function ensureRemotes()
	local remotesFolder = ReplicatedStorage:FindFirstChild("Pets")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Pets"
		remotesFolder.Parent = ReplicatedStorage
	end

	local inventoryFunction = remotesFolder:FindFirstChild("GetPetInventory")
	if not inventoryFunction then
		inventoryFunction = Instance.new("RemoteFunction")
		inventoryFunction.Name = "GetPetInventory"
		inventoryFunction.Parent = remotesFolder
	end

	local updatedEvent = remotesFolder:FindFirstChild("PetsUpdated")
	if not updatedEvent then
		updatedEvent = Instance.new("RemoteEvent")
		updatedEvent.Name = "PetsUpdated"
		updatedEvent.Parent = remotesFolder
	end

	local equipEvent = remotesFolder:FindFirstChild("EquipPet")
	if not equipEvent then
		local legacy = ReplicatedStorage:FindFirstChild("EquipPet")
		if legacy and legacy:IsA("RemoteEvent") then
			equipEvent = legacy
		else
			equipEvent = Instance.new("RemoteEvent")
			equipEvent.Name = "EquipPet"
		end
	end
	equipEvent.Parent = remotesFolder

	local sellFunction = remotesFolder:FindFirstChild("SellPet")
	if not sellFunction then
		sellFunction = Instance.new("RemoteFunction")
		sellFunction.Name = "SellPet"
	end
	sellFunction.Parent = remotesFolder

	return inventoryFunction, updatedEvent, equipEvent, sellFunction
end

local GetPetInventory, PetsUpdated, EquipPetEvent, SellPetFunction = ensureRemotes()

type PetEntry = {
	uid: string,
	petId: string,
	rarity: string?,
	boosts: {[string]: number}?,
}

type PlayerState = {
	OwnedPets: {PetEntry},
	Equipped: {string},
	source: {}?,
}

local function cloneBoosts(boostsTable: {[string]: number}?)
	if not boostsTable then
		return nil
	end
	local copy = {}
	for key, value in pairs(boostsTable) do
		copy[key] = value
	end
	return copy
end

local playerStates: {[Player]: PlayerState} = {}

local function getPersistentPetsTable(player: Player)
	if typeof(_G.GetPlayerData) == "function" then
		local data = _G.GetPlayerData(player)
		if data then
			data.pets = data.pets or {}
			data.pets.owned = data.pets.owned or {}
			data.pets.equipped = data.pets.equipped or {}
			return data.pets
		end
	end
	return nil
end

local function waitForPersistentPets(player: Player, timeout: number?)
	local elapsed = 0
	local limit = timeout or 2
	while elapsed < limit do
		local petsTable = getPersistentPetsTable(player)
		if petsTable then
			return petsTable
		end
		task.wait(0.1)
		elapsed += 0.1
	end
	return nil
end

local function getPlayerState(player: Player): PlayerState
	local state = playerStates[player]
	if state then
		if not state.source then
			local persistent = getPersistentPetsTable(player)
			if persistent then
				state.OwnedPets = persistent.owned
				state.Equipped = persistent.equipped
				state.source = persistent
			end
		end
		return state
	end

	local persistent = waitForPersistentPets(player)
	if persistent then
		state = {
			OwnedPets = persistent.owned,
			Equipped = persistent.equipped,
			source = persistent,
		}
	else
		state = {
			OwnedPets = {},
			Equipped = {},
		}
	end

	playerStates[player] = state
	return state
end

local function serializeState(state: PlayerState)
	local ownedClone = {}
	for index, entry in ipairs(state.OwnedPets) do
		ownedClone[index] = {
			uid = entry.uid,
			petId = entry.petId,
			rarity = entry.rarity,
			boosts = cloneBoosts(entry.boosts),
		}
	end
	return {
		cap = PET_CAP,
		owned = ownedClone,
		equipped = table.clone(state.Equipped),
	}
end

-- Aggregate boosts of all equipped pets into player attributes used by other systems
local function applyEquippedBoostAttributes(player: Player, state: PlayerState)
	local xp, cash, health, damage = 1.0, 1.0, 1.0, 1.0

	local byUid = {}
	for _, entry in ipairs(state.OwnedPets) do
		byUid[entry.uid] = entry
	end

	for _, uid in ipairs(state.Equipped) do
		local entry = byUid[uid]
		if entry then
			local boosts = entry.boosts
			if not boosts then
				local def = PetData[entry.petId]
				boosts = def and def.Boosts
			end
			if boosts then
				if typeof(boosts.XP) == "number" then xp *= boosts.XP end
				if typeof(boosts.Cash) == "number" then cash *= boosts.Cash end
				if typeof(boosts.Health) == "number" then health *= boosts.Health end
				if typeof(boosts.Damage) == "number" then damage *= boosts.Damage end
			end
		end
	end

	player:SetAttribute("PetXPBoost", xp)
	player:SetAttribute("PetCashBoost", cash)
	player:SetAttribute("PetHealthBoost", health)
	player:SetAttribute("PetDamageBoost", damage)
end

local function buildEquippedSnapshot(state: PlayerState)
	local ownedByUid = {}
	for _, entry in ipairs(state.OwnedPets) do
		ownedByUid[entry.uid] = entry
	end

	local snapshot = {}
	for index, uid in ipairs(state.Equipped) do
		local owned = ownedByUid[uid]
		if owned then
			snapshot[#snapshot + 1] = {
				uid = owned.uid,
				petId = owned.petId,
				slot = index,
			}
		end
	end

	return snapshot
end

local function fireUpdate(player: Player)
	local state = getPlayerState(player)
	PetsUpdated:FireClient(player, serializeState(state))
	applyEquippedBoostAttributes(player, state)

	if typeof(_G.ServerApplyEquippedFollowersForPlayer) == "function" then
		local snapshot = buildEquippedSnapshot(state)
		task.defer(function()
			local ok, err = pcall(function()
				_G.ServerApplyEquippedFollowersForPlayer(player, snapshot)
			end)
			if not ok and err then
				warn("[Pets] Failed to apply equipped follower pets:", err)
			end
		end)
	end
end

-- Starter pets seeding removed per game design (no free starter pets)

local function playerOwns(state: PlayerState, uid: string?)
	if not uid then
		return false
	end

	for _, entry in ipairs(state.OwnedPets) do
		if entry.uid == uid then
			return true
		end
	end

	return false
end

local function findOwnedEntry(state: PlayerState, uid: string)
	for index, entry in ipairs(state.OwnedPets) do
		if entry.uid == uid then
			return index, entry
		end
	end
	return nil, nil
end

local function resolveRarity(entry: PetEntry)
	local definition = PetData[entry.petId]
	return entry.rarity or (definition and definition.Rarity) or "Common"
end

local function getSellReward(entry: PetEntry)
	local rarity = resolveRarity(entry)
	local reward = SELL_REWARD_BY_RARITY[rarity] or SELL_REWARD_BY_RARITY.Common or 0
	return reward, rarity
end

local function isEquipped(state: PlayerState, uid: string)
	for _, equipped in ipairs(state.Equipped) do
		if equipped == uid then
			return true
		end
	end
	return false
end

local function setEquipped(state: PlayerState, uid: string, equipped: boolean)
	if equipped then
		if isEquipped(state, uid) then
			return
		end
		if #state.Equipped >= PET_CAP then
			table.remove(state.Equipped, 1)
		end
		table.insert(state.Equipped, uid)
	else
		for index, equippedId in ipairs(state.Equipped) do
			if equippedId == uid then
				table.remove(state.Equipped, index)
				break
			end
		end
	end
end

GetPetInventory.OnServerInvoke = function(player: Player)
	local state = getPlayerState(player)
	return serializeState(state)
end

EquipPetEvent.OnServerEvent:Connect(function(player: Player, payload)
	if typeof(payload) ~= "table" then
		warn("[Pets] Equip payload must be a table")
		return
	end

	local uid = payload.uid
	if typeof(uid) ~= "string" then
		warn("[Pets] Equip payload missing uid")
		return
	end

	local state = getPlayerState(player)

	local petIdFromUid: string?
	for _, entry in ipairs(state.OwnedPets) do
		if entry.uid == uid then
			petIdFromUid = entry.petId
			break
		end
	end

	if not playerOwns(state, uid) then
		warn("[Pets] Player attempted to equip unowned pet")
		return
	end

	-- Was this already equipped before the click?
	local wasEquipped = isEquipped(state, uid)

	if wasEquipped then
		setEquipped(state, uid, false)
	else
		setEquipped(state, uid, true)
	end

	-- Push updated inventory + boosts + followers
	fireUpdate(player)

	-- 🔔 Tutorial hook: if this was a *new* equip, notify tutorial system
	if not wasEquipped and typeof(_G.NotifyTutorialPetEquipped) == "function" then
		pcall(function()
			_G.NotifyTutorialPetEquipped(player)
		end)
	end

	payload.petId = payload.petId or petIdFromUid
end)

SellPetFunction.OnServerInvoke = function(player: Player, payload)
	local uid
	if typeof(payload) == "table" then
		uid = payload.uid
	elseif typeof(payload) == "string" then
		uid = payload
	end

	if typeof(uid) ~= "string" or uid == "" then
		return {
			success = false,
			reason = "Invalid pet uid",
		}
	end

	local state = getPlayerState(player)
	local index, entry = findOwnedEntry(state, uid)
	if not index or not entry then
		return {
			success = false,
			reason = "Pet not found",
		}
	end

	local reward, rarity = getSellReward(entry)
	if reward <= 0 then
		return {
			success = false,
			reason = "Pet cannot be sold",
		}
	end

	setEquipped(state, uid, false)
	table.remove(state.OwnedPets, index)

	if typeof(_G.addPlayerCash) == "function" then
		local ok, err = pcall(function()
			_G.addPlayerCash(player, reward, "PetSale", false)
		end)
		if not ok then
			warn("[Pets] Failed to award sale cash:", err)
		end
	else
		warn("[Pets] addPlayerCash unavailable; pet sale reward skipped")
	end

	fireUpdate(player)

	return {
		success = true,
		reward = reward,
		rarity = rarity,
		petId = entry.petId,
	}
end

local function generateUid(petId: string): string
	return string.format("%s_%d_%d", petId, os.time(), math.random(1000, 9999))
end

local function givePet(player: Player, petId: string, rarityOverride: string?)
	local definition = PetData[petId]
	if not definition then
		return nil, "Unknown pet id"
	end

	local state = getPlayerState(player)
	local uid = generateUid(petId)

	local entry = {
		uid = uid,
		petId = petId,
		rarity = rarityOverride or definition.Rarity,
		boosts = cloneBoosts(definition.Boosts),
	}

	table.insert(state.OwnedPets, entry)
	fireUpdate(player)

	return entry
end

Players.PlayerAdded:Connect(function(player)
	local state = getPlayerState(player)
	applyEquippedBoostAttributes(player, state)
	-- Ensure follower models reflect currently equipped pets on join
	task.spawn(function()
		local waited = 0
		local timeout = 10
		while typeof(_G.ServerApplyEquippedFollowersForPlayer) ~= "function" and waited < timeout do
			task.wait(0.2)
			waited += 0.2
		end
		if typeof(_G.ServerApplyEquippedFollowersForPlayer) == "function" then
			pcall(function()
				_G.ServerApplyEquippedFollowersForPlayer(player)
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

_G.GivePetToPlayer = function(playerOrName, petId: string, rarityOverride: string?)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end

	if not player or not player:IsA("Player") then
		return false, "Player not found"
	end

	local entry, err = givePet(player, petId, rarityOverride)
	if not entry then
		return false, err
	end

	return true, entry.uid
end

-- Resolve a player's owned petId given an inventory uid
_G.GetPetIdFromUid = function(playerOrName, uid: string)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end
	if not player or not player:IsA("Player") then
		return nil, "Player not found"
	end

	if typeof(uid) ~= "string" or uid == "" then
		return nil, "Invalid uid"
	end

	local state = getPlayerState(player)
	for _, entry in ipairs(state.OwnedPets) do
		if entry.uid == uid then
			return entry.petId
		end
	end

	return nil, "Uid not found"
end

_G.GetEquippedPetsSnapshot = function(playerOrName)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end

	if not player or not player:IsA("Player") then
		return {}
	end

	local state = getPlayerState(player)
	local snapshot = buildEquippedSnapshot(state)
	local copy = {}
	for index, entry in ipairs(snapshot) do
		copy[index] = {
			uid = entry.uid,
			petId = entry.petId,
			slot = entry.slot,
		}
	end
	return copy
end

-- Clear all owned pets (and optionally active followers) for a player
_G.ClearPlayerPets = function(playerOrName, alsoClearFollowers: boolean?)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end

	if not player or not player:IsA("Player") then
		return false, "Player not found"
	end

	local state = getPlayerState(player)
	for i = #state.Equipped, 1, -1 do
		table.remove(state.Equipped, i)
	end
	for i = #state.OwnedPets, 1, -1 do
		table.remove(state.OwnedPets, i)
	end

	fireUpdate(player)

	if alsoClearFollowers and typeof(_G.RemoveAllFollowerPets) == "function" then
		pcall(function()
			_G.RemoveAllFollowerPets(player)
		end)
	end

	return true
end

-- Developer utility: wipe a player's persistent pet data (owned + equipped)
-- Use only for testing or migrations.
_G.WipePlayerPets = function(playerOrName)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end
	if not player or not player:IsA("Player") then
		return false, "Player not found"
	end

	local state = getPlayerState(player)
	for i = #state.Equipped, 1, -1 do
		table.remove(state.Equipped, i)
	end
	for i = #state.OwnedPets, 1, -1 do
		table.remove(state.OwnedPets, i)
	end

	fireUpdate(player)

	if typeof(_G.savePlayerData) == "function" then
		pcall(function()
			_G.savePlayerData(player)
		end)
	end

	return true
end

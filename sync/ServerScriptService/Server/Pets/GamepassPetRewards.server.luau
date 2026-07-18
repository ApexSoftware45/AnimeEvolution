-- ServerScriptService/Pets/GamepassPetRewards.server.luau
-- Awards Robux-exclusive pets when players own or purchase the matching gamepasses.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()
local SIMULATE_STUDIO_GAMEPASSES = true -- Studio/Team Test cannot complete purchases, so grant rewards automatically

-- Manual grants (by lowercase player.Name) for cases where we want to mirror a purchase on live servers.
-- Each entry can map to petId or gamepassId keys that resolve to true to allow easy matching.
local MANUAL_GAMEPASS_GRANTS = {
	maxseason12321 = {
		GokuMUIBlueShirt = true,
		[1573310965] = true,
		BlackFreezer = true,
		[1571569281] = true,
	},
}

local GAMEPASS_REWARDS = {
	{
		gamepassId = 1573310965,
		petId = "GokuMUIBlueShirt",
		displayName = "MUI Boku Pet",
	},
	{
		gamepassId = 1571569281,
		petId = "BlackFreezer",
		displayName = "Black Freezer Pet",
	},
}

local gamepassById: {[number]: {gamepassId: number, petId: string, displayName: string}} = {}
local gamepassByPetId: {[string]: {gamepassId: number, petId: string, displayName: string}} = {}
for _, config in ipairs(GAMEPASS_REWARDS) do
	gamepassById[config.gamepassId] = config
	gamepassByPetId[config.petId] = config
end

local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
if not petsFolder then
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = ReplicatedStorage
end

local requestGrantEvent = petsFolder:FindFirstChild("RequestGamepassPetGrant")
if not requestGrantEvent then
	requestGrantEvent = Instance.new("RemoteEvent")
	requestGrantEvent.Name = "RequestGamepassPetGrant"
	requestGrantEvent.Parent = petsFolder
end

local DATA_WAIT_TIMEOUT = 10
local DATA_POLL_INTERVAL = 0.25

local function getPlayerData(player: Player)
	if typeof(_G.GetPlayerData) ~= "function" then
		return nil
	end
	return _G.GetPlayerData(player)
end

local function waitForPlayerData(player: Player)
	local elapsed = 0
	while player.Parent and elapsed < DATA_WAIT_TIMEOUT do
		local data = getPlayerData(player)
		if data then
			return data
		end
		task.wait(DATA_POLL_INTERVAL)
		elapsed += DATA_POLL_INTERVAL
	end
	return getPlayerData(player)
end

local function playerHasPet(player: Player, data: any?, petId: string): boolean
	data = data or getPlayerData(player)
	if not data then
		return false
	end

	local pets = data.pets
	if typeof(pets) ~= "table" then
		return false
	end

	local owned = pets.owned
	if typeof(owned) ~= "table" then
		return false
	end

	for _, entry in ipairs(owned :: {any}) do
		local ownedPetId = entry.petId or entry.PetId
		if ownedPetId == petId then
			return true
		end
	end

	return false
end

local function awardPet(player: Player, config, data: any?)
	if not player.Parent then
		return
	end

	if playerHasPet(player, data, config.petId) then
		return
	end

	-- Wait for PetInventory to expose GivePetToPlayer (script load ordering)
    -- Some servers can initialize scripts slowly; be generous here.
    local grantFn = _G.GivePetToPlayer
    local waited = 0
    local timeout = 10 -- seconds
    while typeof(grantFn) ~= "function" and waited < timeout do
        task.wait(0.2)
        waited += 0.2
        grantFn = _G.GivePetToPlayer
    end

    if typeof(grantFn) ~= "function" then
		warn("[GamepassPetRewards] GivePetToPlayer helper is missing after wait; cannot grant pet.")
		return
	end

	local success, result = pcall(grantFn, player, config.petId)
	if not success or result == false then
		warn(string.format("[GamepassPetRewards] Failed to give %s to %s: %s", config.petId, player.Name, tostring(result)))
	else
		print(string.format("[GamepassPetRewards] Granted %s to %s", config.petId, player.Name))
	end
end

local function playerOwnsGamepass(player: Player, config): boolean
	if IS_STUDIO and SIMULATE_STUDIO_GAMEPASSES then
		return true
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, config.gamepassId)
	end)

	if not success then
		warn(string.format("[GamepassPetRewards] UserOwnsGamePassAsync failed for %s (%d): %s", player.Name, player.UserId, tostring(owns)))
		return false
	end

	return owns == true
end

local function playerIsWhitelistedForConfig(player: Player, config): boolean
	local grants = MANUAL_GAMEPASS_GRANTS[string.lower(player.Name)]
	if not grants then
		return false
	end

	return grants[config.petId] == true or grants[config.gamepassId] == true
end

local function ensureRewardsForPlayer(player: Player)
	local data = waitForPlayerData(player)

	if not player.Parent then
		return
	end

	if not data then
		warn(string.format("[GamepassPetRewards] Player data unavailable for %s; skipping reward check for now.", player.Name))
		return
	end

	for _, config in ipairs(GAMEPASS_REWARDS) do
		local owns = playerOwnsGamepass(player, config)
		local whitelisted = not owns and playerIsWhitelistedForConfig(player, config)
		if owns or whitelisted then
			if whitelisted then
				print(string.format("[GamepassPetRewards] Manual whitelist matched %s -> %s", player.Name, config.petId))
			end
			awardPet(player, config, data)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		ensureRewardsForPlayer(player)
	end)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	local config = player and gamepassById[gamePassId]
    if not player or not config or not wasPurchased then
        return
    end
    -- Award immediately after a confirmed purchase without re-checking ownership
    -- (UserOwnsGamePassAsync can lag behind for a few seconds.)
    task.spawn(function()
        local data = waitForPlayerData(player)
        awardPet(player, config, data)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		ensureRewardsForPlayer(player)
	end)
end

requestGrantEvent.OnServerEvent:Connect(function(player, payload)
	if not player or not player.Parent then
		return
	end
	if not IS_STUDIO then
		warn(string.format("[GamepassPetRewards] Ignoring RequestGamepassPetGrant from %s outside Studio.", player.Name))
		return
	end

	local config
	if typeof(payload) == "number" then
		config = gamepassById[payload]
	elseif typeof(payload) == "string" then
		config = gamepassByPetId[payload]
	elseif typeof(payload) == "table" then
		local gamepassId = payload.gamepassId
		local petId = payload.petId
		if typeof(gamepassId) == "number" then
			config = gamepassById[gamepassId]
		end
		if not config and typeof(petId) == "string" then
			config = gamepassByPetId[petId]
		end
	end

	if not config then
		warn(string.format("[GamepassPetRewards] Unknown request payload from %s: %s", player.Name, tostring(payload)))
		return
	end

	task.spawn(function()
		local data = waitForPlayerData(player)
		if not data then
			warn(string.format("[GamepassPetRewards] Could not fetch data for %s during manual grant request.", player.Name))
			return
		end
		print(string.format("[GamepassPetRewards] Studio grant requested by %s -> %s", player.Name, config.petId))
		awardPet(player, config, data)
	end)
end)

local summary = {}
for _, config in ipairs(GAMEPASS_REWARDS) do
	table.insert(summary, string.format('%d:%s', config.gamepassId, config.petId))
end
print(string.format('[GamepassPetRewards] Ready (gamepasses: %s)', table.concat(summary, ', ')))
if IS_STUDIO and SIMULATE_STUDIO_GAMEPASSES then
	print('[GamepassPetRewards] Studio mode detected - automatically granting Robux pets for testing.')
end


-- Developer helper: simulate a successful purchase in Studio to test award flow
_G.DebugSimulateGamepassPetPurchase = function(playerOrName, petIdentifier)
    if not RunService:IsStudio() then
        warn("[GamepassPetRewards] DebugSimulateGamepassPetPurchase can only be used in Studio.")
        return false
    end

    local player = playerOrName
    if typeof(playerOrName) == "string" then
        player = Players:FindFirstChild(playerOrName)
    end
    if not player or not player:IsA("Player") then
        warn("[GamepassPetRewards] Provide a Player or player name")
        return false
    end

	local targetConfig
	if typeof(petIdentifier) == "number" then
		targetConfig = gamepassById[petIdentifier]
	elseif typeof(petIdentifier) == "string" then
		local lower = string.lower(petIdentifier)
		for _, config in ipairs(GAMEPASS_REWARDS) do
			if string.lower(config.petId) == lower or (config.displayName and string.lower(config.displayName) == lower) then
				targetConfig = config
				break
			end
		end
	end

	if not targetConfig then
		targetConfig = GAMEPASS_REWARDS[1]
	end

    local data = waitForPlayerData(player)
    awardPet(player, targetConfig, data)
    return true
end

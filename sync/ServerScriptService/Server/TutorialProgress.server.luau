-- ServerScriptService/TutorialProgress.server.luau
-- Bridges the tutorial completion event with DataPersistence and a player attribute.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- We expect this RemoteEvent to already exist (you’re using it in the LocalScript)
local tutorialCompletedEvent = ReplicatedStorage:WaitForChild("TutorialCompleted")

---------------------------------------------------------------------
-- Profile helpers (talk to DataPersistence via _G)
---------------------------------------------------------------------

local function getProfile(player: Player)
	-- DataPersistence.server.luau defines this helper:
	--   _G.getPlayerSaveData(player) -> table or nil
	if typeof(_G.getPlayerSaveData) == "function" then
		return _G.getPlayerSaveData(player)
	end

	-- Fallback to GetPlayerData if present
	if typeof(_G.GetPlayerData) == "function" then
		local ok, profile = pcall(_G.GetPlayerData, player)
		if ok then
			return profile
		end
	end

	return nil
end

local function saveProfile(player: Player, profile: table?)
	-- Main save function from DataPersistence.server.luau
	if typeof(_G.savePlayerData) == "function" then
		local ok, err = pcall(_G.savePlayerData, player)
		if not ok then
			warn("TutorialProgress: savePlayerData failed for", player, err)
		end
	end
end

local function waitForProfile(player: Player, timeoutSeconds: number?): table?
	local deadline = os.clock() + (timeoutSeconds or 10)
	local profile = getProfile(player)

	while not profile and os.clock() < deadline do
		task.wait(0.1)
		profile = getProfile(player)
	end

	if not profile then
		warn("TutorialProgress: no profile for", player.Name, "after wait")
	end

	return profile
end

---------------------------------------------------------------------
-- When a player joins, sync HasFinishedTutorial -> attribute
---------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	local profile = waitForProfile(player, 15)
	if not profile then
		return
	end

	-- Ensure the field exists; DataPersistence default already sets this,
	-- but older saves might not have it yet.
	if profile.HasFinishedTutorial == nil then
		profile.HasFinishedTutorial = false
		saveProfile(player, profile)
	end

	-- Mirror to attribute so the LocalScript can read it
	player:SetAttribute("TutorialCompleted", profile.HasFinishedTutorial == true)
end)

---------------------------------------------------------------------
-- When tutorial is completed, flip the flag & save
---------------------------------------------------------------------

tutorialCompletedEvent.OnServerEvent:Connect(function(player: Player)
	if not player or not player:IsDescendantOf(Players) then
		return
	end

	local profile = waitForProfile(player, 5)
	if not profile then
		return
	end

	if profile.HasFinishedTutorial ~= true then
		profile.HasFinishedTutorial = true
		saveProfile(player, profile)
	end

	-- Also set the attribute immediately for this session
	player:SetAttribute("TutorialCompleted", true)
end)

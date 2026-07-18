-- XP System with REBIRTH INTEGRATION - FIXED

-- Now properly syncs level to player attributes AND leaderstats

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelData = require(ReplicatedStorage.Shared.LevelData)

local CURRENT_LEVEL_CAP = LevelData.LevelCap or 60

-- Create RemoteEvents

local giveXPEvent = ReplicatedStorage:FindFirstChild("GiveXP")

if not giveXPEvent then
	giveXPEvent = Instance.new("RemoteEvent")

	giveXPEvent.Name = "GiveXP"

	giveXPEvent.Parent = ReplicatedStorage
end

local xpDataChangedEvent = ReplicatedStorage:FindFirstChild("XPDataChanged")

if not xpDataChangedEvent then
	xpDataChangedEvent = Instance.new("RemoteEvent")

	xpDataChangedEvent.Name = "XPDataChanged"

	xpDataChangedEvent.Parent = ReplicatedStorage
end

-- Initialize global player data if not exists

if not _G.playerData then
	_G.playerData = {}
end

-- 🆕 CRITICAL FIX: Sync level to ALL locations

local function syncPlayerLevel(player, level)
	-- Update player attribute (for GUI scripts)

	player:SetAttribute("Level", level)

	-- Update leaderstats (for leaderboard)

	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		local levelStat = leaderstats:FindFirstChild("Level")

		if levelStat and levelStat:IsA("IntValue") then
			levelStat.Value = level
		end
	end

	print("🔄 Synced level for " .. player.Name .. " → " .. level)
end

-- Function to update CurrentValue & MaxValue in GUI

local function updateXPValues(player, current, max)
	local playerGui = player:FindFirstChild("PlayerGui")

	if playerGui then
		local xpFolder = playerGui:FindFirstChild("XP")

		if xpFolder then
			local currentValue = xpFolder:FindFirstChild("CurrentValue")

			if currentValue and currentValue:IsA("NumberValue") then
				currentValue.Value = current
			end

			local maxValue = xpFolder:FindFirstChild("MaxValue")

			if maxValue and maxValue:IsA("NumberValue") then
				maxValue.Value = max
			end
		end
	end
end

-- Function to refresh XP GUI (call after character spawn/transform)

local function refreshXPGUI(player)
	local userId = player.UserId

	if not _G.playerData[userId] then
		warn("⚠️ No XP data found for", player.Name)

		return
	end

	local playerGui = player:WaitForChild("PlayerGui", 5)

	if not playerGui then
		return
	end

	local xpFolder = playerGui:WaitForChild("XP", 5)

	if not xpFolder then
		return
	end

	local data = _G.playerData[userId]

	xpDataChangedEvent:FireClient(player, data)

	updateXPValues(player, data.xp, data.maxXP)

	-- 🆕 SYNC LEVEL

	syncPlayerLevel(player, data.level)

	print("🔄 Refreshed XP GUI for", player.Name, "- Level:", data.level, "XP:", data.xp .. "/" .. data.maxXP)
end

-- Function to initialize player data (with save data check)

local function initializePlayerData(player)
	local userId = player.UserId

	if _G.playerData[userId] then
		print("🎮 Using loaded save data for:", player.Name, "Level:", _G.playerData[userId].level)

		local data = _G.playerData[userId]

		local rebirthCount = player:GetAttribute("RebirthCount") or data.rebirthCount or 0

		data.rebirthCount = rebirthCount

		if data.level == 9 then
			print("Skipping broken level 9 for", player.Name)

			data.level = 10

			data.xp = 0
		end

		if data.level >= CURRENT_LEVEL_CAP then
			data.level = CURRENT_LEVEL_CAP

			data.xp = 0

			data.maxXP = 999999999999
		else
			data.maxXP = LevelData.GetXPForLevel(data.level + 1, rebirthCount)
		end

		-- 🆕 SYNC LEVEL IMMEDIATELY

		syncPlayerLevel(player, _G.playerData[userId].level)

		spawn(function()
			wait(3)

			refreshXPGUI(player)
		end)
	else
		-- No save data, create new player data

		local rebirthCount = player:GetAttribute("RebirthCount") or 0

		_G.playerData[userId] = {

			xp = 0,

			level = 1,

			maxXP = LevelData.GetXPForLevel(2, rebirthCount),

			rebirthCount = rebirthCount,
		}

		print("🎮 Initialized NEW player data for:", player.Name, "Level: 1, Rebirths:", rebirthCount)

		-- 🆕 SYNC LEVEL IMMEDIATELY

		syncPlayerLevel(player, 1)

		spawn(function()
			wait(3)

			refreshXPGUI(player)
		end)
	end

	xpDataChangedEvent:FireClient(player, _G.playerData[userId])

	updateXPValues(player, _G.playerData[userId].xp, _G.playerData[userId].maxXP)
end

-- Function to add XP to player (REBIRTH INTEGRATED)

local function getPetBoostMultiplier(player: Player, attributeName: string): number
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return 1
	end
	local value = player:GetAttribute(attributeName)
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return 1
end

function addXP(player, amount)
	if not player or not player.Parent then
		warn("❌ Invalid player passed to addXP")

		return
	end

	local userId = player.UserId

	if not _G.playerData[userId] then
		initializePlayerData(player)
	end

	local data = _G.playerData[userId]

	local rebirthCount = player:GetAttribute("RebirthCount") or 0

	-- Update rebirth count in data if changed

	if data.rebirthCount ~= rebirthCount then
		data.rebirthCount = rebirthCount
	end

	local oldXP = data.xp

	local oldLevel = data.level

	local xpMultiplier = getPetBoostMultiplier(player, "PetXPBoost")
	if amount > 0 and xpMultiplier ~= 1 then
		amount *= xpMultiplier
	end

	data.xp = data.xp + amount

	print(
		"💰 "
			.. player.Name
			.. " gained "
			.. amount
			.. " XP (Rebirth: "
			.. rebirthCount
			.. "x) - "
			.. oldXP
			.. " → "
			.. data.xp
			.. "/"
			.. data.maxXP
	)

	-- Play XP gain sound

	if _G.playXPGainSound then
		_G.playXPGainSound(player)
	end

	updateXPValues(player, data.xp, data.maxXP)

	local leveledUp = false

	local levelsGained = 0

	-- Level up loop (with rebirth-adjusted XP requirements)

	while data.xp >= data.maxXP and data.level < CURRENT_LEVEL_CAP do
		data.xp = data.xp - data.maxXP

		data.level = data.level + 1

		if data.level == 9 then
			print("Skipping broken level 9 for", player.Name)

			data.level = 10
		end

		if data.level >= CURRENT_LEVEL_CAP then
			data.level = CURRENT_LEVEL_CAP
		end

		-- 🆕 SYNC LEVEL EVERY TIME IT CHANGES

		syncPlayerLevel(player, data.level)

		if data.level >= CURRENT_LEVEL_CAP then
			data.maxXP = 999999999999

			data.xp = 0
		else
			data.maxXP = LevelData.GetXPForLevel(data.level + 1, rebirthCount)
		end

		leveledUp = true

		levelsGained = levelsGained + 1

		print(
			"🎉 " .. player.Name .. " leveled up to level " .. data.level .. "! (Next level XP: " .. data.maxXP .. ")"
		)

		if data.level >= CURRENT_LEVEL_CAP then
			print("🏆 " .. player.Name .. " reached MAX LEVEL " .. CURRENT_LEVEL_CAP .. "!")

			break
		end
	end

	-- Send updated data to client

	xpDataChangedEvent:FireClient(player, data)

	updateXPValues(player, data.xp, data.maxXP)

	-- Handle level up

	if leveledUp then
		print("🚀 LEVEL UP! " .. player.Name .. " is now level " .. data.level)

		-- Play level up sound

		if _G.playLevelUpSound then
			_G.playLevelUpSound(player)
		end

		-- Transform if needed (levels 2-current cap)

		if data.level >= 2 and data.level <= CURRENT_LEVEL_CAP then
			print("🔄 Starting transformation to level " .. data.level)

			if _G.playTransformSound then
				_G.playTransformSound("start", player)
			end

			if _G.transformPlayerSeamless and type(_G.transformPlayerSeamless) == "function" then
				local success, result = pcall(function()
					return _G.transformPlayerSeamless(player, data.level, true, true)
				end)

				if success and result then
					print("✅ Transformation successful!")

					spawn(function()
						wait(1.5)

						refreshXPGUI(player)
					end)

					wait(1)

					if _G.playTransformSound then
						_G.playTransformSound("complete", player)
					end
				else
					warn("❌ Transformation failed:", result)
				end
			else
				warn("❌ Transform function not available")
			end
		else
			refreshXPGUI(player)
		end

		-- Auto-save on level up

		if _G.savePlayerData then
			spawn(function()
				wait(2)

				_G.savePlayerData(player)
			end)
		end
	end
end

-- Global functions

_G.addXP = addXP

_G.refreshXPGUI = refreshXPGUI

_G.getPlayerLevel = function(player)
	if not player then
		return 1
	end

	if _G.playerData[player.UserId] then
		return _G.playerData[player.UserId].level
	end

	return 1
end

_G.setPlayerLevel = function(player, level)
	if not player then
		return
	end

	if level > CURRENT_LEVEL_CAP then
		warn("⚠️ Cannot set level above current cap! Capping at level " .. CURRENT_LEVEL_CAP)

		level = CURRENT_LEVEL_CAP
	end

	local userId = player.UserId

	if not _G.playerData[userId] then
		initializePlayerData(player)
	end

	local oldLevel = _G.playerData[userId].level

	local rebirthCount = player:GetAttribute("RebirthCount") or 0

	_G.playerData[userId].level = level

	_G.playerData[userId].xp = 0

	-- 🆕 SYNC LEVEL IMMEDIATELY

	syncPlayerLevel(player, level)

	if level < CURRENT_LEVEL_CAP then
		_G.playerData[userId].maxXP = LevelData.GetXPForLevel(level + 1, rebirthCount)
	else
		_G.playerData[userId].maxXP = 999999999999
	end

	xpDataChangedEvent:FireClient(player, _G.playerData[userId])

	updateXPValues(player, 0, _G.playerData[userId].maxXP)

	print("🔧 Set " .. player.Name .. " level from " .. oldLevel .. " to " .. level)

	spawn(function()
		wait(0.5)

		if _G.transformPlayerSeamless then
			_G.transformPlayerSeamless(player, level, true, true)

			wait(1.5)

			refreshXPGUI(player)
		end
	end)

	if _G.savePlayerData then
		spawn(function()
			wait(2)

			_G.savePlayerData(player)
		end)
	end
end

-- Debug functions

_G.givePlayerXP = function(playerName, amount)
	local player = Players:FindFirstChild(playerName)

	if player then
		addXP(player, amount)
	else
		warn("Player not found:", playerName)
	end
end

-- Handle remote event from client

giveXPEvent.OnServerEvent:Connect(function(player, amount)
	if type(amount) == "number" and amount > 0 and amount <= 1000 then
		addXP(player, amount)
	else
		warn("Invalid XP amount from client:", amount)
	end
end)

-- Player joined

Players.PlayerAdded:Connect(function(player)
	print("👋 " .. player.Name .. " joined XP system")

	wait(0.5)

	initializePlayerData(player)
end)

-- Initialize existing players

for _, player in pairs(Players:GetPlayers()) do
	initializePlayerData(player)
end

-- Clean up on leave

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	if _G.playerData[userId] then
		print("👋 " .. player.Name .. " left at level " .. _G.playerData[userId].level)

		spawn(function()
			wait(10)

			_G.playerData[userId] = nil
		end)
	end
end)

print("✅ XP System loaded with REBIRTH INTEGRATION!")

print("⚡ XP requirements now scale with rebirth multipliers!")

print("🔄 Level syncing to attributes & leaderstats FIXED!")

print("📊 Commands: _G.addXP(player, amount), _G.getPlayerLevel(player)")

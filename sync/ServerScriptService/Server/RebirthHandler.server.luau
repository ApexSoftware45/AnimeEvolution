-- Rebirth Handler System
-- Infinite rebirths once the player hits the level cap. XP grind never gets easier.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureRemote(name: string): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local RebirthEvent = ensureRemote("RebirthEvent")
local RebirthResult = ensureRemote("RebirthResult")

local LevelData
local Shared = ReplicatedStorage:FindFirstChild("Shared")
if Shared then
	local levelModule = Shared:FindFirstChild("LevelData")
	if levelModule and levelModule:IsA("ModuleScript") then
		LevelData = require(levelModule)
	end
end

if not LevelData then
	warn("[RebirthHandler] LevelData missing, using fallback values.")
	LevelData = {
		LevelCap = 60,
		RebirthCreditReward = 1,
		CanRebirth = function(level)
			return level >= 60, 60
		end,
		GetXPForLevel = function(level)
			return 100 * (level ^ 1.5)
		end,
		RebirthRewards = {
			CashBonus = 0,
			GemsBonus = 0,
			TitlePrefix = "Reborn",
			MessageTemplate = "Rebirth #%d complete! Total Credits: %d",
		},
	}
end

local LEVEL_CAP = LevelData.LevelCap or 60
local CREDITS_PER_REBIRTH = LevelData.RebirthCreditReward or 1

local REBIRTH_COOLDOWN = 3
local rebirthCooldowns: { [number]: number } = {}

local function getPlayerLevel(player: Player): number
	if typeof(_G.getPlayerLevel) == "function" then
		local ok, level = pcall(_G.getPlayerLevel, player)
		if ok and typeof(level) == "number" then
			return level
		end
	end
	local attrLevel = player:GetAttribute("Level")
	if typeof(attrLevel) == "number" then
		return attrLevel
	end
	return 1
end

local function resetToLevelOne(player: Player, newRebirthCount: number)
	if typeof(_G.setPlayerLevel) == "function" then
		_G.setPlayerLevel(player, 1)
	else
		player:SetAttribute("Level", 1)
		local levelValue = player:FindFirstChild("Level")
		if levelValue and levelValue:IsA("IntValue") then
			levelValue.Value = 1
		end
	end

	player:SetAttribute("XP", 0)

	if _G.playerData and _G.playerData[player.UserId] then
		local data = _G.playerData[player.UserId]
		data.level = 1
		data.xp = 0
		data.rebirthCount = newRebirthCount
		data.maxXP = LevelData.GetXPForLevel(2)
	end
end

local function applyRewards(player: Player, rebirthCount: number, updatedCredits: number)
	local rewards = LevelData.RebirthRewards or {}

	if rewards.TitlePrefix then
		player:SetAttribute("Title", ("%s %d"):format(rewards.TitlePrefix, rebirthCount))
	end

	if rewards.CashBonus and rewards.CashBonus > 0 and typeof(_G.addMoney) == "function" then
		_G.addMoney(player, rewards.CashBonus, "Rebirth Bonus", false)
	end

	if rewards.GemsBonus and rewards.GemsBonus > 0 and typeof(_G.addGems) == "function" then
		_G.addGems(player, rewards.GemsBonus, "Rebirth Bonus")
	end

	return (rewards.MessageTemplate or "Rebirth #%d complete! Total Credits: %d"):format(rebirthCount, updatedCredits)
end

local function performRebirth(player: Player): (boolean, string)
	local lastRebirth = rebirthCooldowns[player.UserId] or 0
	if tick() - lastRebirth < REBIRTH_COOLDOWN then
		return false, "Please wait before rebirthing again."
	end

	local level = getPlayerLevel(player)
	local rebirthCount = player:GetAttribute("RebirthCount") or 0
	local canRebirth, requiredLevel = LevelData.CanRebirth(level, rebirthCount)

	if not canRebirth then
		return false, ("Reach level %d to rebirth."):format(requiredLevel or LEVEL_CAP)
	end

	local newRebirthCount = rebirthCount + 1
	player:SetAttribute("RebirthCount", newRebirthCount)

	local creditsOwned = player:GetAttribute("RebirthCredits") or 0
	local updatedCredits = creditsOwned + CREDITS_PER_REBIRTH
	player:SetAttribute("RebirthCredits", updatedCredits)
	if _G.playerData and _G.playerData[player.UserId] then
		_G.playerData[player.UserId].rebirthCredits = updatedCredits
	end

	resetToLevelOne(player, newRebirthCount)

	if typeof(_G.transformPlayerSeamless) == "function" then
		task.spawn(function()
			task.wait(0.5)
			_G.transformPlayerSeamless(player, 1, true)
		end)
	end

	if typeof(_G.refreshXPGUI) == "function" then
		task.spawn(function()
			task.wait(1)
			_G.refreshXPGUI(player)
		end)
	end

	if typeof(_G.savePlayerData) == "function" then
		task.spawn(function()
			task.wait(2)
			_G.savePlayerData(player)
		end)
	end

	rebirthCooldowns[player.UserId] = tick()

	local message = applyRewards(player, newRebirthCount, updatedCredits)
	return true, message
end

RebirthEvent.OnServerEvent:Connect(function(player: Player)
	local success, message = performRebirth(player)
	RebirthResult:FireClient(player, success, message)
end)

Players.PlayerAdded:Connect(function(player)
	if player:GetAttribute("RebirthCount") == nil then
		player:SetAttribute("RebirthCount", 0)
	end
	if player:GetAttribute("RebirthCredits") == nil then
		player:SetAttribute("RebirthCredits", 0)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	rebirthCooldowns[player.UserId] = nil
end)

_G.rebirthPlayer = performRebirth
_G.getRebirthCount = function(player: Player)
	return player:GetAttribute("RebirthCount") or 0
end
_G.getRebirthMultiplier = function()
	return 1.0
end
_G.getRebirthCredits = function(player: Player)
	return player:GetAttribute("RebirthCredits") or 0
end

print(string.format("[RebirthHandler] Ready (Level cap %d | Credits per rebirth %d)", LEVEL_CAP, CREDITS_PER_REBIRTH))

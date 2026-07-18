-- ServerScriptService > TutorialDummyRewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dummyKilledEvent = ReplicatedStorage:WaitForChild("TutorialDummyKilled")

-- one-time reward tracking per player
local rewardedPlayers = {}

-- 🔢 Tweak these values however you want
local XP_REWARD = 50
local CASH_REWARD = 50

local function giveRewards(player)
	if not player then return end
	if rewardedPlayers[player] then
		-- already rewarded this player once
		return
	end
	rewardedPlayers[player] = true

	-- ✅ XP reward (same pattern as your Box script)
	if _G.addXP and type(_G.addXP) == "function" then
		local ok, err = pcall(function()
			_G.addXP(player, XP_REWARD)
		end)
		if not ok then
			warn("TutorialDummyRewards: addXP failed:", err)
		end
	else
		warn("TutorialDummyRewards: _G.addXP not found")
	end

	-- ✅ Cash reward
	if _G.addPlayerCash and type(_G.addPlayerCash) == "function" then
		local ok, err = pcall(function()
			_G.addPlayerCash(player, CASH_REWARD, "TutorialDummy")
		end)
		if not ok then
			warn("TutorialDummyRewards: addPlayerCash failed:", err)
		end
	else
		warn("TutorialDummyRewards: _G.addPlayerCash not found")
	end
end

dummyKilledEvent.OnServerEvent:Connect(function(player)
	giveRewards(player)
end)

Players.PlayerRemoving:Connect(function(plr)
	rewardedPlayers[plr] = nil
end)

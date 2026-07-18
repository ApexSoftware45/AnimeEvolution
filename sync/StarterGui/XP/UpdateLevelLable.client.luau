-- LocalScript inside StarterGui.XP
-- Updates "Level Label" to show current level dynamically

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local xpFolder = script.Parent  -- XP folder containing CurrentValue, MaxValue, Progress, etc.

-- Wait for Level Label
local levelLabel = xpFolder:WaitForChild("Level Label")

-- Wait for RemoteEvent from server
local xpDataChangedEvent = ReplicatedStorage:WaitForChild("XPDataChanged")

-- Function to update the level label
local function updateLevelLabel(data)
	if data and data.level then
		levelLabel.Text = "Level: " .. tostring(data.level)
	end
end

-- Listen for XP updates from the server
xpDataChangedEvent.OnClientEvent:Connect(function(data)
	updateLevelLabel(data)
end)

-- In case we want to show default level on spawn
updateLevelLabel({ level = 1 })

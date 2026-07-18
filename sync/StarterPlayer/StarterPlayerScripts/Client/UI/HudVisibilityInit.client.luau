-- Ensures key HUD elements start visible and ready, even if Studio defaults had them hidden.

local Players = game:GetService("Players")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

local function findByPath(path: {string})
	local current: Instance? = playerGui
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function ensureFrameVisible(path: {string})
	local instance = findByPath(path)
	if instance and instance:IsA("GuiObject") then
		instance.Visible = true
	end
end

local function ensureScreenGuiEnabled(name: string)
	local gui = playerGui:FindFirstChild(name)
	if gui and gui:IsA("ScreenGui") then
		gui.Enabled = true
	end
end

local function ensureButtonVisible(names: {string})
	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			for _, name in ipairs(names) do
				if string.lower(descendant.Name) == string.lower(name) then
					descendant.Visible = true
					descendant.Active = true
					descendant.AutoButtonColor = true
					return
				end
			end
		end
	end
end

task.defer(function()
	ensureFrameVisible({"visibleButtons", "buttons"})
	ensureFrameVisible({"visibleButtons", "labels"})
	ensureScreenGuiEnabled("XP")
	ensureButtonVisible({"DailyRewards", "Daily Rewards", "DailyRewardsButton"})
end)

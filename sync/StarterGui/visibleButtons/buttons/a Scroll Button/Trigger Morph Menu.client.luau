-- LocalScript inside: StarterGui > visibleButtons > buttons > (your Morph button)
-- This toggles: PlayerGui.Morph["Morph Full Menu"]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local button = script.Parent

-- wait for PlayerGui to exist
local playerGui = player:WaitForChild("PlayerGui")

-- this is your actual menu
local morphGui = playerGui:WaitForChild("Morph", 5)
if not morphGui then
	warn("❌ Could not find 'Morph' ScreenGui in PlayerGui")
	return
end

local morphMenu = morphGui:WaitForChild("Morph Full Menu", 5)
if not morphMenu then
	warn("❌ Could not find 'Morph Full Menu' inside Morph gui")
	return
end

-- optional: start hidden
morphMenu.Visible = false
local isOpen = false

button.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	morphMenu.Visible = isOpen
end)

-- LocalScript
-- Put this inside: StarterGui > visibleButtons > buttons > Abilities > Open Menu

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local button = script.Parent

-- get the player's UI (what they actually see)
local playerGui = player:WaitForChild("PlayerGui")

-- find the Abilities ScreenGui
local abilitiesGui = playerGui:WaitForChild("Abilities", 5)
if not abilitiesGui then
	warn("❌ Abilities ScreenGui not found in PlayerGui")
	return
end

-- find the actual menu frame inside it
local abilitiesMenu = abilitiesGui:WaitForChild("Abilities Menu", 5)
if not abilitiesMenu then
	warn("❌ 'Abilities Menu' not found inside Abilities GUI")
	return
end

-- start hidden
abilitiesMenu.Visible = false
local isOpen = false

button.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	abilitiesMenu.Visible = isOpen
end)

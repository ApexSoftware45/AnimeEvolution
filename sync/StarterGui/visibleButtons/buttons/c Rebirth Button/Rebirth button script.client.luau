-- RebirthButton LocalScript

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local button = script.Parent

-- try PlayerGui first
local playerGui = player:WaitForChild("PlayerGui")

-- your screenshot: StarterGui > Rebirth > RebirthMenu > MenuFrame
-- so at runtime it should be PlayerGui > Rebirth > RebirthMenu
local rebirthGui = playerGui:WaitForChild("Rebirth", 5)
if not rebirthGui then
	warn("❌ Rebirth GUI not found in PlayerGui")
	return
end

local rebirthMenu = rebirthGui:WaitForChild("RebirthMenu", 5):WaitForChild("MenuFrame")
if not rebirthMenu then
	warn("❌ RebirthMenu frame not found inside Rebirth GUI")
	return
end



rebirthMenu.Visible = false
local isOpen = false

button.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	rebirthMenu.Visible = isOpen
end)

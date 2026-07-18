-- LocalScript under: StarterGui > visibleButtons > buttons > ShopButton
-- Toggles: StarterGui > Shop > MainFrame

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Exact targets by path (in PlayerGui at runtime)
local shopGui   = playerGui:WaitForChild("shop") -- ScreenGui
local mainFrame = shopGui:WaitForChild("MainFrame") :: Frame

local button = script.Parent :: GuiButton
local DEBOUNCE_TIME = 0.2
local lastClick = 0
local isOpen = mainFrame.Visible

-- Keep the Shop ScreenGui enabled so hotbar/UI stays clickable
shopGui.Enabled = true

local function setShopState(open: boolean)
	mainFrame.Visible   = open
	mainFrame.Active    = open
	mainFrame.Selectable= open
	isOpen = open
end

local function toggleShop()
	local now = os.clock()
	if now - lastClick < DEBOUNCE_TIME then return end
	lastClick = now
	setShopState(not isOpen)
end

-- Bind
button.Activated:Connect(toggleShop)
button.MouseButton1Click:Connect(toggleShop)
button.TouchTap:Connect(toggleShop)

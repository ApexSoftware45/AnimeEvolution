-- StarterGui/GamepassShop/OpenShopButton.client.luau
-- Parent this LocalScript under the hotbar `Shop` ImageButton to toggle the shop frame.

local Players = game:GetService("Players")

local button = script.Parent :: GuiButton
if not button or not button:IsA("GuiButton") then
	warn("[OpenShopButton] Script must be parented to a GuiButton")
	return
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local targetGuiName = button:GetAttribute("ShopGuiName") or "shop"
local shopGui = playerGui:FindFirstChild(targetGuiName)

if not shopGui then
	-- fallback to legacy GamepassShop name if attribute missing
	shopGui = playerGui:FindFirstChild("GamepassShop")
end

if not shopGui then
	warn(string.format("[OpenShopButton] Could not find ScreenGui '%s' under PlayerGui", targetGuiName))
	return
end

local mainFrame = shopGui:FindFirstChild("MainFrame") :: Frame?
if not mainFrame or not mainFrame:IsA("Frame") then
	warn("[OpenShopButton] MainFrame was not found under the shop GUI")
	return
end

local DEBOUNCE_TIME = 0.2
local lastClick = 0
local isOpen = mainFrame.Visible

local function setShopState(open: boolean)
	shopGui.Enabled = true -- keep button accessible even when the shop content is hidden
	mainFrame.Visible = open
	mainFrame.Active = open
	mainFrame.Selectable = open
	isOpen = open
end

local function toggleShop()
	local now = os.clock()
	if now - lastClick < DEBOUNCE_TIME then
		return
	end
	lastClick = now

	setShopState(not isOpen)
end

button.Activated:Connect(toggleShop)
button.MouseButton1Click:Connect(toggleShop)
button.TouchTap:Connect(toggleShop)

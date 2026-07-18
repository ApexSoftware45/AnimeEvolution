-- Simple fallback controller that forces the SellFrame to appear when any Sell button is clicked.
-- This does not handle payouts; it only toggles the confirmation frame visibility for the user.

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local petsGui = playerGui:WaitForChild("Pets") :: ScreenGui

local mainFrame = petsGui:WaitForChild("Main Frame") :: Frame
local sellFrame = mainFrame:WaitForChild("SellFrame") :: Frame
local inventoryFrame = mainFrame:WaitForChild("PetInventoryFrame") :: GuiObject
local closeButton: TextButton? = sellFrame:FindFirstChild("CloseButton", true) :: TextButton?

sellFrame.Visible = false

local function raiseZIndex(frame: GuiObject, target: number)
	local delta = math.max(1, target) - frame.ZIndex
	if delta == 0 then
		return
	end

	local function apply(gui: GuiObject)
		gui.ZIndex += delta
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("GuiObject") then
				apply(child)
			end
		end
	end

	apply(frame)
end

raiseZIndex(sellFrame, 100)

local function showSellFrame()
	sellFrame.Visible = true
end

local function hideSellFrame()
	sellFrame.Visible = false
end

if closeButton and not closeButton:GetAttribute("SellFrameCloseBound") then
	closeButton:SetAttribute("SellFrameCloseBound", true)
	closeButton.MouseButton1Click:Connect(hideSellFrame)
end

local function bindSellButton(button: TextButton)
	if button:GetAttribute("SellPopupBound") then
		return
	end

	button:SetAttribute("SellPopupBound", true)
	button.MouseButton1Click:Connect(showSellFrame)
end

local function handleDescendant(descendant: Instance)
	if descendant:IsA("TextButton") and (descendant.Name == "SellButton" or descendant.Name == "Sell") then
		bindSellButton(descendant)
	end
end

for _, descendant in ipairs(inventoryFrame:GetDescendants()) do
	handleDescendant(descendant)
end

inventoryFrame.DescendantAdded:Connect(handleDescendant)

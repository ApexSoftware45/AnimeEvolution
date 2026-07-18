-- StarterGui/GamepassShop/CashBundlePurchase.client.luau
-- Attach this LocalScript to a Frame/ScreenGui that contains the cash bundle buttons.
-- Each GuiButton should have a Number attribute named "DeveloperProductId".

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LOCAL_PLAYER = Players.LocalPlayer
local ROOT = script.Parent
local PROMPT_COOLDOWN = 0.5

if not ROOT then
	warn("[CashBundlePurchase] Script has no parent container.")
	return
end

local playerGui = LOCAL_PLAYER and LOCAL_PLAYER:WaitForChild("PlayerGui", 5)
if not playerGui then
	warn("[CashBundlePurchase] PlayerGui not ready; cash buttons will not be hooked.")
	return
end

local lastPromptTimes: {[number]: number} = {}

local function promptProduct(productId: number)
	if not LOCAL_PLAYER or typeof(productId) ~= "number" then
		return
	end

	local now = tick()
	local last = lastPromptTimes[productId] or 0
	if now - last < PROMPT_COOLDOWN then
		return
	end
	lastPromptTimes[productId] = now

	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(LOCAL_PLAYER, productId)
	end)

	if not success then
		warn(string.format("[CashBundlePurchase] Prompt failed for %d: %s", productId, tostring(err)))
	end
end

local function connectButton(button: GuiButton)
	if button:GetAttribute("CashBundleHooked") then
		return
	end
	button:SetAttribute("CashBundleHooked", true)

	local function onActivate()
		local productId = button:GetAttribute("DeveloperProductId")
		if typeof(productId) ~= "number" then
			warn(string.format("[CashBundlePurchase] %s is missing DeveloperProductId attribute.", button:GetFullName()))
			return
		end
		promptProduct(productId)
	end

	button.Activated:Connect(onActivate)
	button.MouseButton1Click:Connect(onActivate)
	button.TouchTap:Connect(onActivate)
end

local function scan(container: Instance)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant:GetAttribute("DeveloperProductId") ~= nil then
			connectButton(descendant)
		end
	end
end

scan(playerGui)
scan(ROOT)

local function handleDescendant(instance: Instance)
	if instance:IsA("GuiButton") and instance:GetAttribute("DeveloperProductId") ~= nil then
		connectButton(instance)
	end
end

playerGui.DescendantAdded:Connect(handleDescendant)
ROOT.DescendantAdded:Connect(handleDescendant)

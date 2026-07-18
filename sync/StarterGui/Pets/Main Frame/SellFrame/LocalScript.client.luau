-- Standalone SellFrame controller.
-- Ensures every Sell button opens the confirmation panel and routes the sale to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local petsGui = playerGui:WaitForChild("Pets") :: ScreenGui

local mainFrame = (petsGui:FindFirstChild("MainFrame") or petsGui:FindFirstChild("Main Frame")) :: Frame
local inventoryFrame = mainFrame:WaitForChild("PetInventoryFrame") :: GuiObject
local sellFrame = mainFrame:FindFirstChild("SellFrame") :: Frame
local closeButton: TextButton? = sellFrame:FindFirstChild("CloseButton", true) :: TextButton?
local finalSellButton: TextButton = (sellFrame:FindFirstChild("FinalSellButton", true) :: TextButton) or sellFrame:FindFirstChildWhichIsA("TextButton") :: TextButton
local recieveLabel: TextLabel? = sellFrame:FindFirstChild("recieve", true) :: TextLabel?
local confirmLabel: TextLabel? = sellFrame:FindFirstChild("YouSure", true) :: TextLabel?

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local petDataModule = sharedFolder:WaitForChild("PetData")
local PetData = require(petDataModule)

local petsFolder = ReplicatedStorage:WaitForChild("Pets")
local sellPetFunction: RemoteFunction = petsFolder:WaitForChild("SellPet")

local SELL_REWARD = {
	Common = 500,
	Rare = 10_000,
	Epic = 500_000,
}

sellFrame.Visible = false

local pendingSale: {
	uid: string?,
	petId: string?,
	displayName: string?,
	rarity: string?,
}?

local function setZIndex(frame: GuiObject, z: number)
	local delta = z - frame.ZIndex
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

setZIndex(sellFrame, 100)

local function formatNumber(n: number): string
	local s = tostring(math.floor(n + 0.5))
	while true do
		local formatted, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		s = formatted
		if k == 0 then
			break
		end
	end
	return s
end

local function detectSlot(frame: Instance): Frame?
	return frame:FindFirstAncestorWhichIsA("Frame")
end

local function detectRarity(slot: Frame?): string
	if not slot then
		return "Common"
	end
	local attribute = slot:GetAttribute("rarity")
	if typeof(attribute) == "string" and attribute ~= "" then
		return attribute
	end
	local lowerName = slot.Name:lower()
	if lowerName:find("epic") then
		return "Epic"
	elseif lowerName:find("rare") then
		return "Rare"
	end
	return "Common"
end

local function resolvePetId(slot: Frame?): (string?, string?)
	if not slot then
		return nil, nil
	end

	local attrId = slot:GetAttribute("petId")
	if typeof(attrId) == "string" and attrId ~= "" and PetData[attrId] then
		return attrId, PetData[attrId].DisplayName
	end

	local petNameLabel: TextLabel? = slot:FindFirstChild("PetName", true) :: TextLabel?
	if petNameLabel then
		local display = petNameLabel.Text
		for petId, data in pairs(PetData) do
			if data.DisplayName == display or petId == display then
				return petId, data.DisplayName
			end
		end
	end

	return nil, nil
end

local function resolveUid(slot: Frame?): string?
	if not slot then
		return nil
	end

	local attrUid = slot:GetAttribute("uid")
	if typeof(attrUid) == "string" and attrUid ~= "" then
		return attrUid
	end

	local fromName = slot.Name:match("PetSlot_(.+)")
	if fromName then
		return fromName
	end

	return nil
end

local function computeReward(rarity: string?): number
	return SELL_REWARD[rarity or "Common"] or SELL_REWARD.Common
end

local function openSellFrame(slot: Frame)
	local uid = resolveUid(slot)
	local petId, displayName = resolvePetId(slot)
	local rarity = detectRarity(slot)

	pendingSale = {
		uid = uid,
		petId = petId,
		displayName = displayName or petId,
		rarity = rarity,
	}

	local reward = computeReward(rarity)
	if confirmLabel then
		local nameText = pendingSale.displayName or "this pet"
		confirmLabel.Text = string.format("Are You Sure You Want to sell %s?", nameText)
	end

	if recieveLabel then
		recieveLabel.Text = string.format("Receive: %s$", formatNumber(reward))
	end

	setZIndex(sellFrame, 100)
	sellFrame.Visible = true
end

local function closeSellFrame()
	pendingSale = nil
	sellFrame.Visible = false
end

if closeButton and not closeButton:GetAttribute("SellFrameCloseBound") then
	closeButton:SetAttribute("SellFrameCloseBound", true)
	closeButton.MouseButton1Click:Connect(closeSellFrame)
end

finalSellButton.MouseButton1Click:Connect(function()
	if not pendingSale or not pendingSale.uid then
		return
	end

	local success, response = pcall(function()
		return sellPetFunction:InvokeServer({
			uid = pendingSale.uid,
		})
	end)

	if success and typeof(response) == "table" and response.success then
		closeSellFrame()
	else
		warn("[PetsSellFrame] SellPet failed:", response)
	end
end)

local function bindSellButton(button: TextButton)
	if button:GetAttribute("SellPopupBound") then
		return
	end

	button:SetAttribute("SellPopupBound", true)
	button.MouseButton1Click:Connect(function()
		local slot = detectSlot(button)
		if not slot then
			return
		end
		openSellFrame(slot)
	end)
end

local function onDescendantAdded(descendant: Instance)
	if descendant:IsA("TextButton") and (descendant.Name == "SellButton" or descendant.Name == "Sell") then
		bindSellButton(descendant)
	end
end

for _, descendant in ipairs(inventoryFrame:GetDescendants()) do
	onDescendantAdded(descendant)
end

inventoryFrame.DescendantAdded:Connect(onDescendantAdded)

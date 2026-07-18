-- Builds the Pets inventory UI and wires equip / sell actions.
-- Requires StarterGui/Pets/MainFrame to contain:
--   PetInventoryFrame (ScrollingFrame or Frame) with PetTemplateCommon/Rare/Epic descendants
--   SellFrame with YouSure, recieve, FinalSellButton controls

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("Pets") :: ScreenGui

local mainFrame = (screenGui:FindFirstChild("MainFrame") or screenGui:FindFirstChild("Main Frame")) :: Frame?
if not mainFrame then
	error("[PetsUI] MainFrame not found under Pets ScreenGui")
end

local function findDescendantByNames(root: Instance?, names: {string})
	if not root then
		return nil
	end
	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, true)
		if found then
			return found
		end
	end
	-- fallback case-insensitive search
	for _, descendant in ipairs(root:GetDescendants()) do
		for _, name in ipairs(names) do
			if descendant.Name:lower() == name:lower() then
				return descendant
			end
		end
	end
	return nil
end

local inventoryFrame = mainFrame:WaitForChild("PetInventoryFrame") :: GuiObject
local scrollingFrame = inventoryFrame:IsA("ScrollingFrame") and inventoryFrame :: ScrollingFrame or nil
local slotParent: GuiObject = scrollingFrame or inventoryFrame
local emptyLabel: TextLabel? = slotParent:FindFirstChild("EmptyLabel") :: TextLabel?

mainFrame.Visible = false

local petsFolder = ReplicatedStorage:WaitForChild("Pets")
local getInventoryFunction: RemoteFunction = petsFolder:WaitForChild("GetPetInventory")
local petsUpdatedEvent: RemoteEvent = petsFolder:WaitForChild("PetsUpdated")
local equipPetEvent: RemoteEvent = (petsFolder:FindFirstChild("EquipPet") :: RemoteEvent?) or ReplicatedStorage:WaitForChild("EquipPet")
local sellPetFunction: RemoteFunction = petsFolder:WaitForChild("SellPet")

local PetData = require(ReplicatedStorage.Shared.PetData)

local TOGGLE_ACTION = "TogglePetsInventory"

local confirmFrame: Frame? = findDescendantByNames(mainFrame, {"SellFrame"}) :: Frame?
local confirmMessageLabel: TextLabel? = findDescendantByNames(confirmFrame, {"YouSure", "ConfirmText", "MessageLabel"}) :: TextLabel?
local confirmReceiveLabel: TextLabel? = findDescendantByNames(confirmFrame, {"recieve", "Recieve", "Receive", "ReceiveLabel", "RewardLabel"}) :: TextLabel?
local confirmButton: TextButton? = findDescendantByNames(confirmFrame, {"FinalSellButton", "SellButton", "ConfirmButton"}) :: TextButton?
if not confirmButton and confirmFrame then
	confirmButton = confirmFrame:FindFirstChildWhichIsA("TextButton")
end

local function elevateFrame(frame: Frame?, targetZIndex: number)
	if not frame then
		return
	end
	local delta = math.max(1, targetZIndex) - frame.ZIndex
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

if confirmFrame then
	elevateFrame(confirmFrame, 75)
	confirmFrame.Visible = false
	confirmFrame.Active = true
	confirmFrame.Selectable = true
else
	warn("[PetsUI] SellFrame missing; selling UI disabled")
end

local function colorFromHex(hex: string): Color3
	hex = hex:gsub("#", "")
	if #hex ~= 6 then
		return Color3.fromRGB(255, 255, 255)
	end
	local r = tonumber(hex:sub(1, 2), 16) or 255
	local g = tonumber(hex:sub(3, 4), 16) or 255
	local b = tonumber(hex:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

local rarityColors = {
	Common = colorFromHex("#6CFF6C"),
	Uncommon = colorFromHex("#38F9E4"),
	Rare = colorFromHex("#3A7BFF"),
	Epic = colorFromHex("#B259FF"),
	Legendary = colorFromHex("#FFD13B"),
	Mythic = colorFromHex("#FF4C4C"),
	Divine = colorFromHex("#FF4C4C"),
	Robux = colorFromHex("#FFFFFF"),
}

local templateLookup: {[string]: Frame} = {}
local templateFallback: Frame?
local templateStorage = Instance.new("Folder")
templateStorage.Name = "PetTemplateStorage"
templateStorage.Parent = script

local function registerTemplate(frame: Frame)
	frame.Visible = false
	local rarity = frame:GetAttribute("Rarity")
	if not rarity then
		rarity = frame.Name:gsub("PetTemplate", "")
	end
	if typeof(rarity) == "string" and rarity ~= "" then
		templateLookup[rarity] = frame
	end
	templateFallback = templateFallback or frame
	frame.Parent = templateStorage
end

for _, child in ipairs(slotParent:GetChildren()) do
	if child:IsA("Frame") and child.Name:match("^PetTemplate") then
		registerTemplate(child)
	end
end

if not templateFallback then
	warn("[PetsUI] No PetTemplate frames found under PetInventoryFrame")
end

local SELL_REWARD_BY_RARITY = {
	Common = 500,
	Rare = 10_000,
	Epic = 500_000,
}

local pendingSale: {uid: string, petId: string, rarity: string?}? = nil
local sellInProgress = false

local activeSlots: {Frame} = {}
local equippedLookup: {[string]: boolean} = {}
local warnedSellButtons: {[string]: boolean} = {}

local function formatBoost(value: number): string
	return string.format("%.1fx", value)
end

local function formatCurrency(amount: number): string
	local formatted = tostring(math.floor(amount + 0.5))
	while true do
		local replaced, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = replaced
		if count == 0 then
			break
		end
	end
	return formatted
end

local function getSellReward(entry: {petId: string, rarity: string?})
	local rarity = entry.rarity or "Common"
	local reward = SELL_REWARD_BY_RARITY[rarity] or SELL_REWARD_BY_RARITY.Common or 0
	return reward, rarity
end

local function hideSellConfirm()
	if confirmFrame then
		confirmFrame.Visible = false
	end
	pendingSale = nil
end

local function showSellConfirm(entry: {uid: string, petId: string, rarity: string?})
	if not confirmFrame then
		return
	end

	pendingSale = entry
	local reward, rarity = getSellReward(entry)

	if confirmReceiveLabel then
		confirmReceiveLabel.Text = string.format("Receive: %s$", formatCurrency(reward))
	end

	if confirmMessageLabel then
		confirmMessageLabel.Text = string.format("Are you sure you want to sell this %s pet?", rarity)
	end

	confirmFrame.Visible = true
end

local function bindConfirmButton()
	if not confirmButton or confirmButton:GetAttribute("SellConfirmBound") then
		return
	end
	confirmButton:SetAttribute("SellConfirmBound", true)
	confirmButton.MouseButton1Click:Connect(function()
		if sellInProgress or not pendingSale then
			return
		end

		sellInProgress = true
		local success, response = pcall(function()
			return sellPetFunction:InvokeServer({
				uid = pendingSale.uid,
			})
		end)
		sellInProgress = false

		if not success then
			warn("[PetsUI] SellPet failed:", response)
			return
		end

		if typeof(response) == "table" and response.success then
			hideSellConfirm()
		else
			local reason = (typeof(response) == "table" and response.reason) or "Unknown error"
			warn("[PetsUI] SellPet rejected:", reason)
		end
	end)
end

bindConfirmButton()

local function getTemplateForRarity(rarity: string?): Frame?
	if rarity then
		local template = templateLookup[rarity]
		if template then
			return template
		end
	end
	return templateFallback
end

local function clearSlots()
	for _, slot in ipairs(activeSlots) do
		slot:Destroy()
	end
	table.clear(activeSlots)
end

local function wireEquipButton(slot: Frame)
	local button: TextButton? = slot:FindFirstChild("EquipButton", true) :: TextButton?
	if not button or button:GetAttribute("Bound") then
		return
	end
	button:SetAttribute("Bound", true)
	button.MouseButton1Click:Connect(function()
		local uid = slot:GetAttribute("uid")
		local petId = slot:GetAttribute("petId")
		if not uid or not petId then
			return
		end
		equipPetEvent:FireServer({
			uid = uid,
			petId = petId,
		})
	end)
end

local function wireSellButton(slot: Frame, entry)
	local button: TextButton? = slot:FindFirstChild("SellButton", true) :: TextButton?
		or slot:FindFirstChild("Sell", true) :: TextButton?
	if not button then
		if not warnedSellButtons[slot.Name] then
			warnedSellButtons[slot.Name] = true
			warn(string.format("[PetsUI] SellButton missing for slot %s (%s)", slot.Name, entry.petId or "unknown"))
		end
		return
	end
	if button:GetAttribute("SellBound") then
		return
	end
	button:SetAttribute("SellBound", true)
	button.MouseButton1Click:Connect(function()
		local uid = slot:GetAttribute("uid")
		local petId = slot:GetAttribute("petId")
		local rarity = slot:GetAttribute("rarity") or entry.rarity
		if not uid or not petId then
			return
		end
		showSellConfirm({
			uid = uid,
			petId = petId,
			rarity = rarity,
		})
	end)
end

local function styleSlotForRarity(slot: Frame, rarity: string?)
	local color = rarityColors[rarity or ""] or rarityColors.Common or Color3.fromRGB(120, 120, 120)
	slot.BackgroundColor3 = color:Lerp(Color3.new(0.1, 0.1, 0.1), 0.2)
	local gradient: UIGradient? = slot:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(1, color:Lerp(Color3.new(0, 0, 0), 0.4)),
		})
	end
end

local function updateSlot(slot: Frame, entry)
	local petId = entry.petId
	local petDefinition = PetData[petId]
	if not petDefinition then
		slot.Visible = false
		return
	end

	slot.Visible = true
	slot:SetAttribute("uid", entry.uid)
	slot:SetAttribute("petId", petId)

	local rarity = entry.rarity or petDefinition.Rarity or "Common"
	slot:SetAttribute("rarity", rarity)
	styleSlotForRarity(slot, rarity)

	local icon: ImageLabel? = slot:FindFirstChild("Icon", true) :: ImageLabel?
	if icon then
		icon.Image = petDefinition.Thumbnail or ""
	end

	local nameLabel: TextLabel? = slot:FindFirstChild("PetName", true) :: TextLabel?
	if nameLabel then
		nameLabel.Text = petDefinition.DisplayName or petId
	end

	local boosts = entry.boosts or entry.Boosts or petDefinition.Boosts or {}

	local xpHeader: TextLabel? = slot:FindFirstChild("BoostLabel", true) :: TextLabel?
	if xpHeader then
		xpHeader.Text = ("XPBoost: %s"):format(formatBoost(boosts.XP or 1))
	end

	local cashLabel: TextLabel? = slot:FindFirstChild("CashBoost", true) :: TextLabel?
	if cashLabel then
		cashLabel.Text = ("CashBoost: %s"):format(formatBoost(boosts.Cash or 1))
	end

	local healthLabel: TextLabel? = slot:FindFirstChild("HealthBoost", true) :: TextLabel?
	if healthLabel then
		healthLabel.Text = ("HealthBoost: %s"):format(formatBoost(boosts.Health or 1))
	end

	local damageLabel: TextLabel? = slot:FindFirstChild("DmgBoost", true) :: TextLabel?
	if damageLabel then
		damageLabel.Text = ("DmgBoost: %s"):format(formatBoost(boosts.Damage or boosts.Dmg or 1))
	end

	wireEquipButton(slot)
	wireSellButton(slot, entry)

	local equipped = equippedLookup[entry.uid] or false

	local equipButton: TextButton? = slot:FindFirstChild("EquipButton", true) :: TextButton?
	if equipButton then
		equipButton.Text = equipped and "Unequip" or "Equip"
		equipButton.BackgroundColor3 = equipped and Color3.fromRGB(255, 180, 100) or Color3.fromRGB(96, 255, 128)
	end

	local equippedTag: TextLabel? = slot:FindFirstChild("EquippedTag", true) :: TextLabel?
	if equippedTag then
		equippedTag.Visible = equipped
	end
end

local function refreshInventory(inventory)
	table.clear(equippedLookup)
	for _, uid in ipairs(inventory.equipped or {}) do
		equippedLookup[uid] = true
	end

	local owned = inventory.owned or {}

	if emptyLabel then
		emptyLabel.Visible = #owned == 0
	end

	clearSlots()

	for index, entry in ipairs(owned) do
		local petDefinition = PetData[entry.petId]
		local rarity = entry.rarity or (petDefinition and petDefinition.Rarity) or "Common"
		local template = getTemplateForRarity(rarity)
		if template then
			local slot = template:Clone()
			slot.Name = ("PetSlot_%s"):format(entry.uid)
			slot.Visible = true
			slot.LayoutOrder = index
			slot.Parent = slotParent

			table.insert(activeSlots, slot)
			updateSlot(slot, entry)
		else
			warn("[PetsUI] Missing template for rarity:", rarity)
		end
	end

	if scrollingFrame then
		local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
		if layout then
			scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 150)
		end
	end
end

local function fetchInventory()
	local success, result = pcall(function()
		return getInventoryFunction:InvokeServer()
	end)

	if success and result then
		refreshInventory(result)
	else
		warn("[PetsUI] Failed to fetch pet inventory:", result)
	end
end

petsUpdatedEvent.OnClientEvent:Connect(function(inventory)
	refreshInventory(inventory)
end)

fetchInventory()

local function toggleInventory()
	mainFrame.Visible = not mainFrame.Visible
	if not mainFrame.Visible then
		hideSellConfirm()
	end
end

ContextActionService:BindAction(
	TOGGLE_ACTION,
	function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			toggleInventory()
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.P
)

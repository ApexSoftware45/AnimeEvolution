-- REBIRTH MENU – LocalScript
-- Place inside StarterGui > Rebirth > RebirthMenu

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local LevelData = require(sharedFolder:WaitForChild("LevelData"))

local LEVEL_CAP = LevelData.LevelCap or 60
local CREDIT_REWARD = LevelData.RebirthCreditReward or 1

-- ScreenGui & menu widgets
local menuGui = script.Parent
local menuFrame = menuGui:WaitForChild("MenuFrame")
local titleLabel = menuFrame:WaitForChild("TitleLabel")
local rebirthCountLabel = menuFrame:WaitForChild("RebirthCountLabel")
local currentLevelLabel = menuFrame:WaitForChild("CurrentLevelLabel")
local requiredLevelLabel = menuFrame:WaitForChild("RequiredLevelLabel")
local multiplierLabel = menuFrame:WaitForChild("MultiplierLabel")
local statusLabel = menuFrame:WaitForChild("StatusLabel")
local rebirthActionButton = menuFrame:WaitForChild("RebirthButton")
local closeButton = menuFrame:WaitForChild("CloseButton")

-- Optional HUD button (any button under StarterGui/Rebirth that isn't the menu action button)
local openButton do
	local rebirthFolder = playerGui:FindFirstChild("Rebirth")
	if rebirthFolder then
		for _, guiObject in ipairs(rebirthFolder:GetDescendants()) do
			if guiObject:IsA("GuiButton") and guiObject ~= rebirthActionButton and guiObject ~= closeButton then
				openButton = guiObject
				break
			end
		end
	end
end

local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")
local resultEvent = ReplicatedStorage:WaitForChild("RebirthResult")

local function updateMenu()
	local level = player:GetAttribute("Level") or 1
	local rebirths = player:GetAttribute("RebirthCount") or 0
	local credits = player:GetAttribute("RebirthCredits") or 0
	local levelsNeeded = math.max(0, LEVEL_CAP - level)
	local ready = level >= LEVEL_CAP

	titleLabel.Text = "REBIRTH MENU"
	rebirthCountLabel.Text = ("Rebirths: %d"):format(rebirths)
	currentLevelLabel.Text = ("Current Level: %d"):format(level)
	requiredLevelLabel.Text = ("Level Required: %d"):format(LEVEL_CAP)
	multiplierLabel.Text = ("XP Multiplier: 1.0x  |  Rebirth Credits: %d"):format(credits)

	if ready then
		statusLabel.Text = ("✅ Ready! Gain +%d Rebirth Credit."):format(CREDIT_REWARD)
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		rebirthActionButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		rebirthActionButton.Text = "REBIRTH NOW"
		rebirthActionButton.Active = true
	else
		statusLabel.Text = ("❌ Need %d more level%s to reach cap."):format(levelsNeeded, levelsNeeded == 1 and "" or "s")
		statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		rebirthActionButton.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
		rebirthActionButton.Text = "KEEP GRINDING"
		rebirthActionButton.Active = false
	end
end

local function openMenu()
	menuFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
	menuFrame.Visible = true
	updateMenu()

	TweenService:Create(
		menuFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) }
	):Play()
end

local function closeMenu()
	local tween = TweenService:Create(
		menuFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, -0.5, 0) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		menuFrame.Visible = false
	end)
end

local function handleRebirth()
	if rebirthActionButton.Active then
		rebirthEvent:FireServer()
	end
end

if openButton then
	openButton.MouseButton1Click:Connect(openMenu)
else
	-- No separate HUD button; you can call openMenu() from elsewhere if needed
end

closeButton.MouseButton1Click:Connect(closeMenu)
rebirthActionButton.MouseButton1Click:Connect(handleRebirth)

resultEvent.OnClientEvent:Connect(function(success, message)
	if success then
		statusLabel.Text = "✅ " .. message
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		task.delay(2, closeMenu)
	else
		statusLabel.Text = "❌ " .. message
		statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	end

	task.delay(0.5, function()
		if menuFrame.Visible then
			updateMenu()
		end
	end)
end)

player:GetAttributeChangedSignal("Level"):Connect(function()
	if menuFrame.Visible then
		updateMenu()
	end
end)

player:GetAttributeChangedSignal("RebirthCount"):Connect(function()
	if menuFrame.Visible then
		updateMenu()
	end
end)

player:GetAttributeChangedSignal("RebirthCredits"):Connect(function()
	if menuFrame.Visible then
		updateMenu()
	end
end)

menuFrame.Visible = false
updateMenu()
print("✅ Rebirth Menu (infinite) initialized!")

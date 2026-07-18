-- Smart Transformation Loading Screen
-- Waits for actual character readiness instead of timers
-- LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Portrait lookup table; assign your own portrait ids per level
local TRANSFORMATION_PORTRAITS = {
	-- All levels temporary point to level 2 portrait for testing
	[1] = "rbxassetid://116108017548729",
	[2] = "rbxassetid://116108017548729",
	[3] = "rbxassetid://116108017548729",
	[4] = "rbxassetid://116108017548729",
	[5] = "rbxassetid://116108017548729",
	[6] = "rbxassetid://116108017548729",
	[7] = "rbxassetid://116108017548729",
	[8] = "rbxassetid://116108017548729",
	[9] = "rbxassetid://116108017548729",
	[10] = "rbxassetid://116108017548729",
	[11] = "rbxassetid://116108017548729",
	[12] = "rbxassetid://116108017548729",
	[13] = "rbxassetid://116108017548729",
	[14] = "rbxassetid://116108017548729",
	[15] = "rbxassetid://116108017548729",
	[16] = "rbxassetid://116108017548729",
	[17] = "rbxassetid://116108017548729",
	[18] = "rbxassetid://116108017548729",
	[19] = "rbxassetid://116108017548729",
	[20] = "rbxassetid://116108017548729",
	[21] = "rbxassetid://116108017548729",
	[22] = "rbxassetid://116108017548729",
	[23] = "rbxassetid://116108017548729",
	[24] = "rbxassetid://116108017548729",
	[25] = "rbxassetid://116108017548729",
	[26] = "rbxassetid://116108017548729",
	[27] = "rbxassetid://116108017548729",
	[28] = "rbxassetid://116108017548729",
	[29] = "rbxassetid://116108017548729",
	[30] = "rbxassetid://116108017548729",
	[31] = "rbxassetid://116108017548729",
	[32] = "rbxassetid://116108017548729",
	[33] = "rbxassetid://116108017548729",
	[34] = "rbxassetid://116108017548729",
	[35] = "rbxassetid://116108017548729",
	[36] = "rbxassetid://116108017548729",
	[37] = "rbxassetid://116108017548729",
	[38] = "rbxassetid://116108017548729",
	[39] = "rbxassetid://116108017548729",
	[40] = "rbxassetid://116108017548729",
	[41] = "rbxassetid://116108017548729",
	[42] = "rbxassetid://116108017548729",
	[43] = "rbxassetid://116108017548729",
	[44] = "rbxassetid://116108017548729",
	[45] = "rbxassetid://116108017548729",
	[46] = "rbxassetid://116108017548729",
	[47] = "rbxassetid://116108017548729",
	[48] = "rbxassetid://116108017548729",
	[49] = "rbxassetid://116108017548729",
	[50] = "rbxassetid://116108017548729",
	[51] = "rbxassetid://116108017548729",
	[52] = "rbxassetid://116108017548729",
	[53] = "rbxassetid://116108017548729",
	[54] = "rbxassetid://116108017548729",
	[55] = "rbxassetid://116108017548729",
	[56] = "rbxassetid://116108017548729",
	[57] = "rbxassetid://116108017548729",
	[58] = "rbxassetid://116108017548729",
	[59] = "rbxassetid://116108017548729",
	[60] = "rbxassetid://116108017548729",
	default = "rbxassetid://116108017548729"
}

-- Colour palette for celebration/confetti effects
local CELEBRATION_COLOURS = {
	Color3.fromRGB(255, 202, 87),
	Color3.fromRGB(255, 132, 124),
	Color3.fromRGB(120, 201, 255),
	Color3.fromRGB(171, 255, 161),
	Color3.fromRGB(216, 150, 255)
}

-- Wait for RemoteEvent
local showLoadingEvent = ReplicatedStorage:WaitForChild("ShowLoadingScreen", 10)
if not showLoadingEvent then
	showLoadingEvent = Instance.new("RemoteEvent")
	showLoadingEvent.Name = "ShowLoadingScreen"
	showLoadingEvent.Parent = ReplicatedStorage
end

local currentLoadingScreen = nil
local inputsDisabled = false
local isWaitingForCharacter = false

local function getPortraitAsset(level)
	if typeof(level) == "number" and TRANSFORMATION_PORTRAITS[level] then
		return TRANSFORMATION_PORTRAITS[level]
	end

	return TRANSFORMATION_PORTRAITS.default
end

local function spawnCelebrationEffect(parent: Instance)
	local confettiCount = 24

	for _ = 1, confettiCount do
		local confetti = Instance.new("Frame")
		confetti.AnchorPoint = Vector2.new(0.5, 0.5)
		confetti.Size = UDim2.new(0, math.random(10, 22), 0, math.random(16, 30))
		confetti.BackgroundColor3 = CELEBRATION_COLOURS[math.random(1, #CELEBRATION_COLOURS)]
		confetti.BackgroundTransparency = 0.1
		confetti.BorderSizePixel = 0
		confetti.Position = UDim2.new(math.random(), 0, -0.15, 0)
		confetti.Rotation = math.random(-45, 45)
		confetti.ZIndex = 5
		confetti.Name = "CelebrationConfetti"
		confetti.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, math.random(3, 6))
		corner.Parent = confetti

		task.spawn(function()
			while confetti.Parent do
				local startScale = math.random()
				local startOffset = math.random(-140, 140)
				confetti.Position = UDim2.new(startScale, startOffset, -0.15, math.random(-30, 10))
				confetti.Rotation = math.random(-60, 60)

				local fallTime = 1.2 + math.random() * 0.6
				local horizontalDrift = (math.random(-12, 12) / 100)
				local endRotation = confetti.Rotation + math.random(-140, 140)

				local tween = TweenService:Create(confetti, TweenInfo.new(fallTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
					Position = UDim2.new(startScale + horizontalDrift, startOffset, 1.15, math.random(20, 60)),
					Rotation = endRotation
				})

				tween:Play()
				local ok, err = pcall(function()
					tween.Completed:Wait()
				end)

				if not ok then
					warn("Confetti tween error:", err)
					break
				end

				task.wait(math.random() * 0.2)
			end

			if confetti and confetti.Parent then
				confetti:Destroy()
			end
		end)
	end
end

-- ====================================
-- INPUT LOCK SYSTEM
-- ====================================
local function disableInput()
	if inputsDisabled then return end
	inputsDisabled = true
	
	-- Disable all movement and actions
	ContextActionService:BindAction(
		"DisableMovement",
		function() return Enum.ContextActionResult.Sink end,
		false,
		unpack(Enum.PlayerActions:GetEnumItems())
	)
	
	-- Disable character movement
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		end
	end
	
	print("🔒 Input LOCKED")
end

local function enableInput()
	if not inputsDisabled then return end
	inputsDisabled = false
	
	-- Re-enable all actions
	ContextActionService:UnbindAction("DisableMovement")
	
	-- Re-enable character movement
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			
			-- Force reset animation state
			task.wait(0.1)
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			task.wait(0.05)
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			task.wait(0.05)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	
	print("🔓 Input UNLOCKED")
end

-- ====================================
-- CHARACTER READINESS DETECTION
-- ====================================
local function isCharacterReady(character)
	if not character or not character.Parent then
		return false
	end
	
	-- Check for essential parts
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then
		return false
	end
	
	-- Check if humanoid is in a valid state
	if humanoid.Health <= 0 then
		return false
	end
	
	-- Check if animations are loaded
	local animStorage = character:FindFirstChild("LoadedAnimations")
	if not animStorage then
		return false
	end
	
	-- Check if positioned properly (not at origin)
	local pos = rootPart.Position
	if pos.Magnitude < 10 then -- Too close to origin
		return false
	end
	
	-- Check if transformation flag is cleared
	if player:GetAttribute("TransformingInProgress") then
		return false
	end
	
	return true
end

local function waitForCharacterReady()
	local maxWaitTime = 5 -- Max 5 seconds
	local startTime = tick()
	
	print("⏳ Waiting for character to be ready...")
	
	while tick() - startTime < maxWaitTime do
		local character = player.Character
		
		if isCharacterReady(character) then
			print("✅ Character is ready!")
			return true
		end
		
		task.wait(0.1)
	end
	
	warn("⚠️ Character readiness timeout after 5 seconds")
	return false
end

-- ====================================
-- LOADING SCREEN UI
-- ====================================
local function forceCleanupAll()
	for _, gui in pairs(PlayerGui:GetChildren()) do
		if gui.Name == "TransformationLoading" then
			gui:Destroy()
		end
	end
	
	if currentLoadingScreen and currentLoadingScreen.Parent then
		currentLoadingScreen:Destroy()
		currentLoadingScreen = nil
	end
	
	-- Always re-enable input when cleaning up
	enableInput()
	isWaitingForCharacter = false
end

local function createLoadingScreen(payload)
	-- Cleanup any existing screens first
	forceCleanupAll()

	-- LOCK INPUT for the fixed celebration duration
	disableInput()
	isWaitingForCharacter = true

	local message = "Transformation in progress..."
	local level = nil
	local characterName = nil

	if typeof(payload) == "table" then
		message = payload.message or message
		level = payload.level
		characterName = payload.characterName
	elseif typeof(payload) == "string" then
		message = payload
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TransformationLoading"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 200
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui

	currentLoadingScreen = screenGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(6, 9, 18)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.ZIndex = 5
	background.Parent = screenGui

	local backgroundGradient = Instance.new("UIGradient")
	backgroundGradient.Color = ColorSequence.new(
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 20, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 4, 10))
	)
	backgroundGradient.Rotation = 35
	backgroundGradient.Parent = background

	local container = Instance.new("Frame")
	container.Name = "Card"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.Size = UDim2.new(0, 520, 0, 280)
	container.BackgroundColor3 = Color3.fromRGB(16, 14, 26)
	container.BackgroundTransparency = 0.05
	container.BorderSizePixel = 0
	container.ZIndex = 10
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 24)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(255, 198, 107)
	containerStroke.Thickness = 2
	containerStroke.Transparency = 0.25
	containerStroke.Parent = container

	local containerGradient = Instance.new("UIGradient")
	containerGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	containerGradient.Color = ColorSequence.new(
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 21, 46)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 12, 30))
	)
	containerGradient.Parent = container

	local containerScale = Instance.new("UIScale")
	containerScale.Scale = 0.85
	containerScale.Parent = container

	TweenService:Create(
		containerScale,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()

	local containerPadding = Instance.new("UIPadding")
	containerPadding.PaddingTop = UDim.new(0, 24)
	containerPadding.PaddingBottom = UDim.new(0, 24)
	containerPadding.PaddingLeft = UDim.new(0, 28)
	containerPadding.PaddingRight = UDim.new(0, 28)
	containerPadding.Parent = container

	local layoutRoot = Instance.new("Frame")
	layoutRoot.Name = "LayoutRoot"
	layoutRoot.BackgroundTransparency = 1
	layoutRoot.Size = UDim2.new(1, 0, 1, 0)
	layoutRoot.Parent = container

	local horizontalLayout = Instance.new("UIListLayout")
	horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
	horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	horizontalLayout.Padding = UDim.new(0, 24)
	horizontalLayout.Parent = layoutRoot

	local portraitWrapper = Instance.new("Frame")
	portraitWrapper.Name = "PortraitWrapper"
	portraitWrapper.BackgroundTransparency = 1
	portraitWrapper.Size = UDim2.new(0, 220, 1, -20)
	portraitWrapper.Parent = layoutRoot

	local portraitAspect = Instance.new("UIAspectRatioConstraint")
	portraitAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	portraitAspect.AspectRatio = 1
	portraitAspect.Parent = portraitWrapper

	local portraitFrame = Instance.new("Frame")
	portraitFrame.Name = "PortraitFrame"
	portraitFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	portraitFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	portraitFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	portraitFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 52)
	portraitFrame.BackgroundTransparency = 0.05
	portraitFrame.BorderSizePixel = 0
	portraitFrame.ZIndex = 15
	portraitFrame.Parent = portraitWrapper

	local portraitCorner = Instance.new("UICorner")
	portraitCorner.CornerRadius = UDim.new(0, 18)
	portraitCorner.Parent = portraitFrame

	local portraitStroke = Instance.new("UIStroke")
	portraitStroke.Color = Color3.fromRGB(255, 198, 107)
	portraitStroke.Thickness = 2
	portraitStroke.Transparency = 0.3
	portraitStroke.Parent = portraitFrame

	local portraitImage = Instance.new("ImageLabel")
	portraitImage.Name = "Portrait"
	portraitImage.AnchorPoint = Vector2.new(0.5, 0.5)
	portraitImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	portraitImage.Size = UDim2.new(0.92, 0, 0.92, 0)
	portraitImage.BackgroundTransparency = 1
	portraitImage.Image = getPortraitAsset(level)
	portraitImage.ImageColor3 = Color3.new(1, 1, 1)
	portraitImage.ZIndex = 16
	portraitImage.Parent = portraitFrame

	local portraitScale = Instance.new("UIScale")
	portraitScale.Scale = 1
	portraitScale.Parent = portraitImage

	task.spawn(function()
		while portraitImage.Parent do
			local grow = TweenService:Create(
				portraitScale,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Scale = 1.05 }
			)
			grow:Play()
			grow.Completed:Wait()
			if not portraitImage.Parent then
				break
			end
			local shrink = TweenService:Create(
				portraitScale,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			shrink:Play()
			shrink.Completed:Wait()
			task.wait(0.1)
		end
	end)

	if portraitImage.Image == "rbxassetid://0" then
		local placeholderLabel = Instance.new("TextLabel")
		placeholderLabel.BackgroundTransparency = 1
		placeholderLabel.Size = UDim2.new(0.85, 0, 0.85, 0)
		placeholderLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		placeholderLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		placeholderLabel.Text = "Add a portrait id for this level\nin TRANSFORMATION_PORTRAITS"
		placeholderLabel.TextColor3 = Color3.fromRGB(255, 198, 107)
		placeholderLabel.TextWrapped = true
		placeholderLabel.TextScaled = true
		placeholderLabel.Font = Enum.Font.GothamBold
		placeholderLabel.ZIndex = 17
		placeholderLabel.Parent = portraitFrame
	end

	local textColumn = Instance.new("Frame")
	textColumn.Name = "TextColumn"
	textColumn.BackgroundTransparency = 1
	textColumn.Size = UDim2.new(1, -240, 1, -20)
	textColumn.Parent = layoutRoot

	local verticalLayout = Instance.new("UIListLayout")
	verticalLayout.FillDirection = Enum.FillDirection.Vertical
	verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	verticalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	verticalLayout.Padding = UDim.new(0, 10)
	verticalLayout.Parent = textColumn

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.LayoutOrder = 1
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Text = "Transformation Unlocked!"
	titleLabel.TextColor3 = Color3.fromRGB(255, 216, 125)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.TextScaled = true
	titleLabel.ZIndex = 15
	titleLabel.Parent = textColumn

	if level then
		local levelTag = Instance.new("TextLabel")
		levelTag.Name = "LevelTag"
		levelTag.LayoutOrder = 2
		levelTag.BackgroundTransparency = 1
		levelTag.Size = UDim2.new(0, 140, 0, 26)
		levelTag.Text = "Level " .. tostring(level)
		levelTag.TextColor3 = Color3.fromRGB(255, 198, 107)
		levelTag.Font = Enum.Font.GothamMedium
		levelTag.TextScaled = true
		levelTag.TextXAlignment = Enum.TextXAlignment.Left
		levelTag.ZIndex = 16
		levelTag.Parent = textColumn
	end

	local characterLabel = Instance.new("TextLabel")
	characterLabel.Name = "CharacterName"
	characterLabel.LayoutOrder = 3
	characterLabel.BackgroundTransparency = 1
	characterLabel.Size = UDim2.new(1, 0, 0, 34)
	characterLabel.Text = characterName and ("Now becoming: " .. characterName) or "Preparing new form..."
	characterLabel.TextColor3 = Color3.fromRGB(218, 226, 255)
	characterLabel.Font = Enum.Font.GothamMedium
	characterLabel.TextScaled = true
	characterLabel.TextWrapped = true
	characterLabel.TextXAlignment = Enum.TextXAlignment.Left
	characterLabel.ZIndex = 15
	characterLabel.Parent = textColumn

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.LayoutOrder = 4
	messageLabel.BackgroundTransparency = 1
	messageLabel.Size = UDim2.new(1, 0, 0, 60)
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(190, 198, 220)
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextScaled = true
	messageLabel.ZIndex = 15
	messageLabel.Parent = textColumn

	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "Progress"
	progressFrame.LayoutOrder = 5
	progressFrame.BackgroundColor3 = Color3.fromRGB(34, 30, 60)
	progressFrame.BackgroundTransparency = 0.2
	progressFrame.BorderSizePixel = 0
	progressFrame.Size = UDim2.new(1, 0, 0, 16)
	progressFrame.ZIndex = 15
	progressFrame.Parent = textColumn

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progressFrame

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 198, 107)
	progressFill.BackgroundTransparency = 0
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.ZIndex = 16
	progressFill.Parent = progressFrame

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 8)
	progressFillCorner.Parent = progressFill

	task.spawn(function()
		while progressFill.Parent do
			progressFill.Position = UDim2.new(0, 0, 0, 0)
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			local tween = TweenService:Create(
				progressFill,
				TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Size = UDim2.new(1, 0, 1, 0) }
			)
			tween:Play()
			tween.Completed:Wait()
			if not progressFill.Parent then
				break
			end
			task.wait(0.1)
		end
	end)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.LayoutOrder = 6
	statusLabel.BackgroundTransparency = 1
	statusLabel.Size = UDim2.new(1, 0, 0, 28)
	statusLabel.Text = "Stabilizing aura and locking controls..."
	statusLabel.TextColor3 = Color3.fromRGB(160, 168, 196)
	statusLabel.Font = Enum.Font.GothamSemibold
	statusLabel.TextScaled = true
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 15
	statusLabel.Parent = textColumn

	pcall(function()
		spawnCelebrationEffect(screenGui)
	end)

	-- Fixed-length celebration: hide after exactly 3 seconds
	task.delay(3, function()
		if isWaitingForCharacter then
			hideLoadingScreen()
		end
	end)

	print("[TransformationUI] Celebration loading screen active")
	return screenGui
end

local function hideLoadingScreen()
	if not currentLoadingScreen then
		forceCleanupAll()
		return
	end

	print("[TransformationUI] Hide loading screen command received")
	isWaitingForCharacter = false

	local function fadeGuiObject(guiObject: GuiObject)
		local tweenProperties = {}

		-- All GuiObjects share BackgroundTransparency
		tweenProperties.BackgroundTransparency = 1

		if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
			tweenProperties.TextTransparency = 1
		end

		if guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
			tweenProperties.ImageTransparency = 1
		end

		local tween = TweenService:Create(guiObject, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), tweenProperties)
		tween:Play()
	end

	for _, element in ipairs(currentLoadingScreen:GetDescendants()) do
		if element:IsA("GuiObject") then
			pcall(fadeGuiObject, element)
		end
	end

	for _, element in ipairs(currentLoadingScreen:GetChildren()) do
		if element:IsA("GuiObject") then
			pcall(fadeGuiObject, element)
		end
	end

	task.delay(0.3, function()
		forceCleanupAll()
		print("[TransformationUI] Loading screen hidden and input unlocked")
	end)
end


-- ====================================
-- DISABLE ROBLOX SPAWN PROTECTION
-- ====================================
local function disableSpawnProtection()
	local character = player.Character
	if not character then return end
	
	-- Remove ForceField (spawn protection bubble)
	for _, ff in pairs(character:GetChildren()) do
		if ff:IsA("ForceField") then
			ff:Destroy()
			print("🛡️ Removed spawn protection ForceField")
		end
	end
	
	-- Disable spawn protection attribute
	player:SetAttribute("DisableSpawnProtection", true)
end

-- Monitor for new characters and remove spawn protection
player.CharacterAdded:Connect(function(character)
	print("👤 Character added, checking for spawn protection...")
	
	-- Wait a moment for character to load
	task.wait(0.1)
	
	-- Remove spawn protection immediately
	disableSpawnProtection()
	
	-- Keep checking for a few seconds in case it reappears
	for i = 1, 10 do
		task.wait(0.3)
		disableSpawnProtection()
	end
end)

-- ====================================
-- EVENT LISTENERS
-- ====================================
showLoadingEvent.OnClientEvent:Connect(function(action, payload)
	local debugMessage = payload
	if payload and typeof(payload) == "table" then
		debugMessage = payload.message or payload.characterName or "[table payload]"
	end

	print("[TransformationUI] Loading screen event:", action, debugMessage or "")
	
	if action == "show" then
		createLoadingScreen(payload)
	elseif action == "hide" then
		hideLoadingScreen()
	end
end)

-- ====================================
-- INITIALIZATION
-- ====================================
-- Cleanup on initial load
forceCleanupAll()

-- Remove spawn protection on current character if exists
if player.Character then
	disableSpawnProtection()
end

print("✅ Smart Transformation Loading Screen loaded!")
print("   🧠 Monitors character readiness")
print("   🔒 Locks input during transformation")
print("   🛡️ Disables Roblox spawn protection")

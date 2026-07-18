-- LocalScript - Optimized Character Button
-- Only checks unlock status when menu opens, not constantly
-- Place inside each character ImageButton

local button = script.Parent
local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ========================================
-- LEVEL 17 - SIX PATHS MADARA
-- ========================================
local CHARACTER_NAME = "6 path madara"
local REQUIRED_LEVEL = 17
local UNLOCKED_IMAGE = "rbxassetid://92728634136841"
local LOCKED_IMAGE = "rbxassetid://96258390035739"


-- Visual settings
local ORIGINAL_SIZE = button.Size
local HOVER_SIZE = UDim2.new(ORIGINAL_SIZE.X.Scale * 1.05, 0, ORIGINAL_SIZE.Y.Scale * 1.05, 0)
local CLICK_SIZE = UDim2.new(ORIGINAL_SIZE.X.Scale * 0.95, 0, ORIGINAL_SIZE.Y.Scale * 0.95, 0)

-- State
local isUnlocked = false
local currentLevel = 1
local hasChecked = false

-- Get MorphEvent
local morphEvent = ReplicatedStorage:WaitForChild("MorphEvent", 10)

-- Create UI elements (only once)
local lockOverlay = button:FindFirstChild("LockOverlay")
if not lockOverlay then
	lockOverlay = Instance.new("ImageLabel")
	lockOverlay.Name = "LockOverlay"
	lockOverlay.Size = UDim2.new(0.3, 0, 0.3, 0)
	lockOverlay.Position = UDim2.new(0.7, 0, 0.7, 0)
	lockOverlay.BackgroundTransparency = 1
	lockOverlay.Image = "rbxassetid://6031082533"
	lockOverlay.ImageColor3 = Color3.new(1, 0, 0)
	lockOverlay.ZIndex = 10
	lockOverlay.Parent = button
end

local levelLabel = button:FindFirstChild("LevelLabel")
if not levelLabel then
	levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0.2, 0)
	levelLabel.Position = UDim2.new(0, 0, 0.8, 0)
	levelLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	levelLabel.BackgroundTransparency = 0.3
	levelLabel.Text = "Level " .. REQUIRED_LEVEL
	levelLabel.TextColor3 = Color3.new(1, 1, 1)
	levelLabel.TextStrokeTransparency = 0
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.SourceSansBold
	levelLabel.ZIndex = 10
	levelLabel.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = levelLabel
end

-- Get player level
local function getPlayerLevel()
	local level = player:GetAttribute("Level")
	if level then return level end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local levelStat = leaderstats:FindFirstChild("Level")
		if levelStat then return levelStat.Value end
	end

	return 1
end

-- Check unlock status (ONLY when called)
local function checkUnlocked()
	currentLevel = getPlayerLevel()
	isUnlocked = currentLevel >= REQUIRED_LEVEL
	hasChecked = true

	-- Only print when actually checking
	-- print("🔐 Level Check:", CHARACTER_NAME, "- Player Level:", currentLevel, "Required:", REQUIRED_LEVEL, "Unlocked:", isUnlocked)

	return isUnlocked
end

-- Update button appearance
local function updateButtonAppearance()
	if not hasChecked then
		checkUnlocked()
	end

	if isUnlocked then
		button.Image = UNLOCKED_IMAGE
		button.ImageColor3 = Color3.new(1, 1, 1)
		button.ImageTransparency = 0
		lockOverlay.Visible = false
		levelLabel.TextColor3 = Color3.new(0, 1, 0)
		levelLabel.Text = "Level " .. REQUIRED_LEVEL .. " ✓"
	else
		button.Image = LOCKED_IMAGE
		button.ImageColor3 = Color3.new(0.3, 0.3, 0.3)
		button.ImageTransparency = 0.3
		lockOverlay.Visible = true
		levelLabel.TextColor3 = Color3.new(1, 0, 0)
		levelLabel.Text = "Requires Level " .. REQUIRED_LEVEL
	end
end

-- Find the menu frame to detect when it opens
local menu = button.Parent
while menu and not menu:IsA("ScrollingFrame") and not menu.Name:match("Menu") do
	menu = menu.Parent
end

-- Check when menu becomes visible
if menu then
	-- Initial check when menu is already visible
	if menu.Visible then
		updateButtonAppearance()
	end

	-- Check whenever menu visibility changes
	menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if menu.Visible then
			-- Menu just opened - check unlock status now
			checkUnlocked()
			updateButtonAppearance()
		end
	end)
end

-- Also update when level changes
player:GetAttributeChangedSignal("Level"):Connect(function()
	-- Only update if menu is visible
	if menu and menu.Visible then
		checkUnlocked()
		updateButtonAppearance()
	else
		-- Just invalidate the cache, will check next time menu opens
		hasChecked = false
	end
end)

-- Hover effects (only if unlocked)
button.MouseEnter:Connect(function()
	if not hasChecked then checkUnlocked() end

	if not isUnlocked then
		local shakeTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Rotation = 5})
		shakeTween:Play()
		shakeTween.Completed:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1), {Rotation = 0}):Play()
		end)
		return
	end

	TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = HOVER_SIZE}):Play()
end)

button.MouseLeave:Connect(function()
	if not isUnlocked then return end
	TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = ORIGINAL_SIZE}):Play()
end)

-- Handle click
button.MouseButton1Click:Connect(function()
	if not hasChecked then checkUnlocked() end

	if not isUnlocked then
		-- Locked feedback
		local shakeTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Rotation = -10})
		shakeTween:Play()
		shakeTween.Completed:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Rotation = 10}):Play()
			wait(0.1)
			TweenService:Create(button, TweenInfo.new(0.1), {Rotation = 0}):Play()
		end)

		local originalColor = button.ImageColor3
		TweenService:Create(button, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1, 0, 0)}):Play()
		wait(0.2)
		TweenService:Create(button, TweenInfo.new(0.2), {ImageColor3 = originalColor}):Play()
		return
	end

	-- Unlocked - morph
	local clickTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = CLICK_SIZE})
	clickTween:Play()
	clickTween.Completed:Wait()
	TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = ORIGINAL_SIZE}):Play()

	if morphEvent then
		pcall(function()
			morphEvent:FireServer(CHARACTER_NAME)
		end)
	end
end)

print("✅ Optimized button initialized:", CHARACTER_NAME, "- Will check on menu open")
-- LocalScript inside StarterGui > Tutorial1 > NewPlayer

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- This Frame is your blue "Welcome!" banner
local tutorialFrame = script.Parent

-- ✅ CHANGE THESE NAMES TO MATCH YOUR HIERARCHY
-- ScreenGui that holds the mobile buttons
local buttonsGui = playerGui:WaitForChild("Mobile/Tablet Buttons") -- e.g. "MobileButtons" or whatever you named it
local punchButton = buttonsGui:WaitForChild("Punch")               -- your Punch ImageButton name
local arrow = punchButton:WaitForChild("TutorialArrow")            -- yellow arrow ImageLabel

-- Make sure tutorial is visible on spawn
tutorialFrame.Visible = true
arrow.Visible = true

----------------------------------------------------
-- 1. Show the banner for the first 3 seconds
----------------------------------------------------
task.delay(3, function()
	-- Fade out the banner (optional, you can delete this block if you want it to stay longer)
	if tutorialFrame and tutorialFrame.Parent then
		local tween = TweenService:Create(
			tutorialFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)
		tween:Play()
		tween.Completed:Wait()
		tutorialFrame.Visible = false
	end
end)

----------------------------------------------------
-- 2. Make the arrow flash to draw attention
----------------------------------------------------
task.spawn(function()
	local on = true
	while arrow and arrow.Parent and arrow.Visible do
		local goal = {}
		if on then
			goal.ImageTransparency = 0
		else
			goal.ImageTransparency = 0.6
		end

		local tween = TweenService:Create(
			arrow,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			goal
		)
		tween:Play()
		on = not on
		task.wait(0.35)
	end
end)

----------------------------------------------------
-- 3. When the player presses Punch for the first time,
--    stop the tutorial arrow.
----------------------------------------------------
local firstPunchDone = false

local function onPunch()
	if firstPunchDone then return end
	firstPunchDone = true

	-- Hide arrow + banner instantly for now
	if arrow then
		arrow.Visible = false
	end

	if tutorialFrame then
		tutorialFrame.Visible = false
	end

	-- (Next steps of the tutorial will start from here:
	--  show "Defeat the Training Dummy" etc. in the next script.)
end

-- Use Activated so it works for mouse + touch
punchButton.Activated:Connect(onPunch)

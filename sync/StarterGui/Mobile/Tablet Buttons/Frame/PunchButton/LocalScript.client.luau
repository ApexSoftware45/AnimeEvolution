-- Handles the dedicated punch button for touch devices (phones/tablets).
-- Place this LocalScript alongside the PunchButton ImageButton.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent")
local button = script.Parent :: GuiButton

local PUNCH_COOLDOWN = 0.3
local lastPunch = 0

-- Detect if device supports touch
local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled and not GuiService:IsTenFootInterface()
end

-- Control visibility and activity
local function updateVisibility()
	local visible = isTouchDevice()

	-- Reversed logic: hide and disable on touch devices
	button.Active = not visible
	button.AutoButtonColor = not visible
	button.Visible = not visible
end

-- Punch logic (safe for touch devices)
local function attemptPunch()
	if not isTouchDevice() then
		button.Visible = false
		return
	end

	local now = tick()
	if now - lastPunch < PUNCH_COOLDOWN then
		return
	end
	lastPunch = now

	punchEvent:FireServer()

	if _G.ClientSounds and _G.ClientSounds.playLocal then
		_G.ClientSounds.playLocal("rbxassetid://566593606", 0.3, 1.0, workspace)
	end
end

-- Connections
button.Activated:Connect(attemptPunch)
button.MouseButton1Click:Connect(attemptPunch)

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateVisibility)
GuiService:GetPropertyChangedSignal("IsTenFootInterface"):Connect(updateVisibility)

-- 🩶 Fix: Hide immediately before anything draws on screen
button.Visible = false
updateVisibility()

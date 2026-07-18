-- Punch input handler (mouse + touch) with local feedback
-- Left click or tap anywhere on screen to punch with a short cooldown

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent")

local PUNCH_COOLDOWN = 0.3
local lastPunchTime = 0

local function touchHasDedicatedButton(): boolean
	return UserInputService.TouchEnabled
end

local function attemptPunch(sourceLabel: string)
	local now = tick()
	local elapsed = now - lastPunchTime

	if elapsed < PUNCH_COOLDOWN then
		local remaining = math.max(0, PUNCH_COOLDOWN - elapsed)
		print(string.format("[PunchInput] Punch on cooldown (%.2fs remaining)", remaining))
		return
	end

	lastPunchTime = now
	punchEvent:FireServer()

	if _G.ClientSounds and _G.ClientSounds.playLocal then
		-- Quick local punch sound so mobile players get instant feedback
		_G.ClientSounds.playLocal("rbxassetid://566593606", 0.3, 1.0, workspace)
	end

	print(string.format("[PunchInput] Punch triggered via %s", sourceLabel))
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attemptPunch("MouseButton1")
	elseif input.UserInputType == Enum.UserInputType.Touch then
		if not touchHasDedicatedButton() then
			attemptPunch("TouchInput")
		end
	end
end)

-- Touch gestures can bypass InputBegan when UI captures them, so hook the helpers too.
UserInputService.TouchTap:Connect(function(_, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if not touchHasDedicatedButton() then
		attemptPunch("TouchTap")
	end
end)

UserInputService.TouchTapInWorld:Connect(function(_, _, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if not touchHasDedicatedButton() then
		attemptPunch("TouchTapInWorld")
	end
end)

print("[PunchInput] Loaded mouse and touch punch controls.")
print("[PunchInput] Tap or left-click to punch (mobile-friendly).")

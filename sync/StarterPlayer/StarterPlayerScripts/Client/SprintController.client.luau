local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local DEFAULT_WALK_SPEED = 16
local DEFAULT_SPRINT_SPEED = 28

local sprintEnabled = false
local humanoid: Humanoid?
local stateConn: RBXScriptConnection?

local changeEvent = Instance.new("BindableEvent")

local sprintAnimationIds = {
	R15 = {
		Run = "rbxassetid://125854908423295",
	},
	R6 = {
		Run = "rbxassetid://122961843",
	},
}

local sprintTracks: { [string]: AnimationTrack? } = {}

local function stopSprintTracks()
	for _, track in pairs(sprintTracks) do
		if track and track.IsPlaying then
			track:Stop()
		end
	end
	sprintTracks = {}
end

local function loadSprintAnimation(currentHumanoid: Humanoid)
	if not currentHumanoid then
		return
	end
	local rigType = currentHumanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
	local config = sprintAnimationIds[rigType]
	if not config then
		return
	end

	local animator = currentHumanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local animId = config.Run
	if not animId then
		return
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	anim.Name = "SprintRun"
	anim.Priority = Enum.AnimationPriority.Movement

	local track = animator:LoadAnimation(anim)
	if track then
		track.Looped = true
		sprintTracks[rigType] = track
	end
end

local function playSprintAnimation()
	if not humanoid then
		return
	end
	local rigType = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
	local track = sprintTracks[rigType]
	if track then
		track:Play()
	end
end

local function stopSprintAnimation()
	stopSprintTracks()
end

local function applySprintState()
	if not humanoid then
		return
	end

	if sprintEnabled then
		humanoid.WalkSpeed = DEFAULT_SPRINT_SPEED
		playSprintAnimation()
	else
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		stopSprintAnimation()
	end
end

local function setSprintEnabled(enabled: boolean?): boolean
	local target = enabled == true
	if sprintEnabled == target then
		return sprintEnabled
	end

	sprintEnabled = target
	applySprintState()
	changeEvent:Fire(sprintEnabled)
	return sprintEnabled
end

local function toggleSprint(): boolean
	return setSprintEnabled(not sprintEnabled)
end

local function getSprintEnabled(): boolean
	return sprintEnabled
end

local function bindHumanoid(newHumanoid: Humanoid)
	if stateConn then
		stateConn:Disconnect()
		stateConn = nil
	end

	humanoid = newHumanoid
	stopSprintTracks()

	if humanoid then
		loadSprintAnimation(humanoid)
		stateConn = humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Dead then
				setSprintEnabled(false)
			end
		end)
	end

	applySprintState()
end

player.CharacterAdded:Connect(function(character)
	local newHumanoid = character:WaitForChild("Humanoid") :: Humanoid
	bindHumanoid(newHumanoid)
end)

player.CharacterRemoving:Connect(function()
	bindHumanoid(nil :: any)
end)

if player.Character then
	local existingHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if existingHumanoid then
		bindHumanoid(existingHumanoid)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		toggleSprint()
	end
end)

_G.ToggleSprint = toggleSprint
_G.SetSprintEnabled = setSprintEnabled
_G.GetSprintEnabled = getSprintEnabled
_G.SprintChanged = changeEvent.Event

print("[SprintController] Sprint ready. Use _G.ToggleSprint() or GUI button.")

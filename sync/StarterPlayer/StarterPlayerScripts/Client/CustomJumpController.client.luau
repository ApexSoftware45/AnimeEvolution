-- Custom jump controller: disables Roblox's default jump bindings and exposes
-- a manual jump/double-jump entry point for upcoming GUI controls.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local BLOCK_ACTION_NAME = "DisableDefaultJump"
local BLOCK_PRIORITY = Enum.ContextActionPriority.High.Value
local BLOCKED_INPUTS = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA }

local DOUBLE_JUMP_ANIMATION_ID = "rbxassetid://137206500907711"

local humanoid: Humanoid?
local rootPart: BasePart?
local stateConn: RBXScriptConnection?

local doubleJumpAnimation: Animation?
local doubleJumpTrack: AnimationTrack?
local doubleJumpAnimator: Animator?

local canDoubleJump = false
local doubleJumpUsed = false

-----------------------------------------------------------------------
-- Default jump suppression
-----------------------------------------------------------------------
local function disableDefaultJumpBindings()
	local function sinkAction(): Enum.ContextActionResult
		return Enum.ContextActionResult.Sink
	end

	ContextActionService:BindActionAtPriority(
		BLOCK_ACTION_NAME,
		function(_, _, _)
			return sinkAction()
		end,
		false,
		BLOCK_PRIORITY,
		table.unpack(BLOCKED_INPUTS)
	)

	task.defer(function()
		pcall(function()
			ContextActionService:UnbindAction("jumpAction")
		end)
	end)
end

local function disableMobileJumpButton()
	task.spawn(function()
		for _ = 1, 10 do
			local success = pcall(function()
				StarterGui:SetCore("JumpButtonEnabled", false)
			end)
			if success then
				break
			end
			task.wait(0.5)
		end
	end)

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui")

		local function hideJumpDescendant(descendant: Instance)
			if descendant:IsA("ImageButton") and string.find(descendant.Name:lower(), "jump") then
				descendant.Visible = false
				descendant.Active = false
			end
			if descendant:IsA("TextButton") and string.find(descendant.Name:lower(), "jump") then
				descendant.Visible = false
				descendant.Active = false
			end
		end

		local function scanTouchGui(root: Instance)
			for _, desc in ipairs(root:GetDescendants()) do
				hideJumpDescendant(desc)
			end
		end

		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			scanTouchGui(touchGui)
			touchGui.DescendantAdded:Connect(function(desc)
				hideJumpDescendant(desc)
			end)
		end

		playerGui.ChildAdded:Connect(function(child)
			if child.Name == "TouchGui" then
				scanTouchGui(child)
				child.DescendantAdded:Connect(function(desc)
					hideJumpDescendant(desc)
				end)
			end
		end)
	end)
end

disableDefaultJumpBindings()
disableMobileJumpButton()

-----------------------------------------------------------------------
-- Double jump assets
-----------------------------------------------------------------------
local function ensureAnimationTrack(currentHumanoid: Humanoid)
	local animator: Animator? = currentHumanoid:FindFirstChildOfClass("Animator")
	if not animator then
		local candidate = currentHumanoid:FindFirstChild("Animator")
		if candidate and candidate:IsA("Animator") then
			animator = candidate
		end
	end
	if not animator then
		animator = Instance.new("Animator")
		animator.Name = "CustomJumpAnimator"
		animator.Parent = currentHumanoid
	end
	if not animator then
		return
	end

	if doubleJumpTrack and doubleJumpAnimator == animator then
		return
	end

	if not doubleJumpAnimation then
		doubleJumpAnimation = Instance.new("Animation")
		doubleJumpAnimation.Name = "CustomDoubleJump"
		doubleJumpAnimation.AnimationId = DOUBLE_JUMP_ANIMATION_ID
		doubleJumpAnimation.Priority = Enum.AnimationPriority.Action4
	end

	local track = animator:LoadAnimation(doubleJumpAnimation)
	if track then
		track.Looped = false
		doubleJumpTrack = track
		doubleJumpAnimator = animator
	end
end

-----------------------------------------------------------------------
-- Jump helpers
-----------------------------------------------------------------------
local function applyJumpImpulse(currentHumanoid: Humanoid, currentRoot: BasePart): boolean
	local velocity = currentRoot.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	local jumpVector = Vector3.new(0, currentHumanoid.JumpPower, 0)

	currentRoot.AssemblyLinearVelocity = horizontal + jumpVector
	currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	return true
end

local function performPrimaryJump(): boolean
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	if not currentHumanoid or not currentRoot or currentHumanoid.Health <= 0 then
		return false
	 end

	if applyJumpImpulse(currentHumanoid, currentRoot) then
		canDoubleJump = true
		doubleJumpUsed = false
		return true
	end

	return false
end

local function performDoubleJump(): boolean
	if not canDoubleJump or doubleJumpUsed then
		return false
	end

	local currentHumanoid = humanoid
	local currentRoot = rootPart
	if not currentHumanoid or not currentRoot or currentHumanoid.Health <= 0 then
		return false
	end

	ensureAnimationTrack(currentHumanoid)

	local success = applyJumpImpulse(currentHumanoid, currentRoot)
	if success then
		doubleJumpUsed = true
		canDoubleJump = false
		if doubleJumpTrack then
			doubleJumpTrack:Play()
		end

		-- Camera shake
		local camera = workspace.CurrentCamera
		if camera then
			local originalCFrame = camera.CFrame
			local shakeMagnitude = 0.4
			local duration = 0.2
			local elapsed = 0

			task.spawn(function()
				while elapsed < duration do
					elapsed += task.wait()
					local offset = Vector3.new(
						(math.random() - 0.5) * shakeMagnitude,
						(math.random() - 0.5) * shakeMagnitude,
						(math.random() - 0.5) * shakeMagnitude
					)
					camera.CFrame = originalCFrame * CFrame.new(offset)
				end
				camera.CFrame = originalCFrame
			end)
		end

		-- Particle effect
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxassetid://258128463"
		emitter.Lifetime = NumberRange.new(0.2, 0.4)
		emitter.Rate = 0
		emitter.Speed = NumberRange.new(6, 12)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-120, 120)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 0)
		})
		emitter.LightEmission = 0.7
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 150), Color3.fromRGB(255, 255, 255))
		emitter.VelocityInheritance = 0.2
		emitter.SpreadAngle = Vector2.new(360, 360)
		emitter.Parent = currentRoot
		emitter:Emit(20)
		Debris:AddItem(emitter, 0.5)

		return true
	end

	return false
end

local function requestJump(): boolean
	local currentHumanoid = humanoid
	if not currentHumanoid then
		return false
	end

	if currentHumanoid.FloorMaterial ~= Enum.Material.Air then
		return performPrimaryJump()
	end

	return performDoubleJump()
end

-----------------------------------------------------------------------
-- Character lifecycle
-----------------------------------------------------------------------
local function cleanupCharacter()
	if stateConn then
		stateConn:Disconnect()
		stateConn = nil
	end

	humanoid = nil
	rootPart = nil
	doubleJumpTrack = nil
	doubleJumpAnimator = nil
	canDoubleJump = false
	doubleJumpUsed = false
end

local function onHumanoidStateChanged(_, newState: Enum.HumanoidStateType)
	if newState == Enum.HumanoidStateType.Landed
		or newState == Enum.HumanoidStateType.Running
		or newState == Enum.HumanoidStateType.RunningNoPhysics
		or newState == Enum.HumanoidStateType.Dead then
		canDoubleJump = false
		doubleJumpUsed = false
	end
end

local function onCharacterAdded(character: Model)
	cleanupCharacter()

	local newHumanoid = character:WaitForChild("Humanoid") :: Humanoid
	local newRoot = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid = newHumanoid
	rootPart = newRoot
	canDoubleJump = false
	doubleJumpUsed = false

	stateConn = newHumanoid.StateChanged:Connect(onHumanoidStateChanged)
	ensureAnimationTrack(newHumanoid)
end

local function onCharacterRemoving()
	cleanupCharacter()
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

-----------------------------------------------------------------------
-- Public API for upcoming GUI hooks
-----------------------------------------------------------------------
local function publicJumpRequest(): boolean
	return requestJump()
end

_G.TriggerCustomJump = publicJumpRequest

print("[CustomJumpController] Default jump disabled. Use _G.TriggerCustomJump() or your GUI to invoke jumps.")

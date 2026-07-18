-- Itachi Dummy Tutorial Script
-- Place this Script inside the Itachi dummy Model in Workspace (ItachiDummyTutorial).
-- - 30 HP health bar (box style)
-- - Always dies in 1 hit
-- - NO direct XP/cash reward from box/enemy systems
-- - One-time tutorial reward per player: 50 XP + 50 Cash
-- - Fires RemoteEvent "TutorialDummyKilled" to that player
-- - Death animation + quick respawn
-- - Uses PunchEvent like boxes/enemies

local dummy = script.Parent
if not dummy or not dummy:IsA("Model") then
	warn("ItachiDummyTutorial: Script must be parented to the dummy MODEL")
	return
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

----------------------------------------------------
-- CONFIG
----------------------------------------------------
local MAX_HEALTH = 30             -- shows as 30/30, but we force 1-hit kills
local PUNCH_RADIUS = 10           -- how close the player must be
local RESPAWN_DELAY = 3           -- fast respawn for tutorial
local DEATH_ANIMATION_TIMEOUT = 3 -- fallback if animation doesn’t stop
local SHOW_NAME = "Training Dummy" -- label over health bar

-- one-time tutorial reward per player
local XP_REWARD = 50
local CASH_REWARD = 1000

-- RemoteEvent for client tutorial UI
local tutorialEvent = ReplicatedStorage:WaitForChild("TutorialDummyKilled")

----------------------------------------------------
-- ROOT + HUMANOID
----------------------------------------------------
local function findRoot(model: Model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp then
		return hrp
	end
	return model:FindFirstChildWhichIsA("BasePart")
end

local root = findRoot(dummy)
local humanoid = dummy:FindFirstChildOfClass("Humanoid")
if not root or not humanoid then
	warn("ItachiDummyTutorial: Missing Humanoid or root part")
	return
end

humanoid.MaxHealth = MAX_HEALTH
humanoid.Health = MAX_HEALTH

----------------------------------------------------
-- HEALTH BAR (box style)
----------------------------------------------------
local currentHealth = MAX_HEALTH
local healthFill, healthText

local function updateHealthBar()
	if not healthFill then return end

	local percent = math.clamp(currentHealth / MAX_HEALTH, 0, 1)

	local color
	if percent > 0.6 then
		color = Color3.new(0, 1, 0) -- green
	elseif percent > 0.3 then
		color = Color3.new(1, 1, 0) -- yellow
	else
		color = Color3.new(1, 0, 0) -- red
	end

	TweenService:Create(
		healthFill,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(percent, 0, 1, 0), BackgroundColor3 = color}
	):Play()

	if healthText then
		healthText.Text = string.format("%d/%d", currentHealth, MAX_HEALTH)
	end
end

local function createHealthBar()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Size = UDim2.new(6, 0, 3, 0)
	billboardGui.StudsOffset = Vector3.new(0, 4.5, 0)
	billboardGui.MaxDistance = 200
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = root

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "DummyLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = SHOW_NAME
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.ZIndex = 10
	titleLabel.Parent = billboardGui

	local barContainer = Instance.new("Frame")
	barContainer.Size = UDim2.new(1, 0, 0.3, 0)
	barContainer.Position = UDim2.new(0, 0, 0.4, 0)
	barContainer.BackgroundColor3 = Color3.new(0, 0, 0)
	barContainer.BackgroundTransparency = 0.3
	barContainer.BorderSizePixel = 0
	barContainer.Parent = billboardGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = barContainer

	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, -8, 1, -8)
	healthBg.Position = UDim2.new(0, 4, 0, 4)
	healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = barContainer

	local healthBgCorner = Instance.new("UICorner")
	healthBgCorner.CornerRadius = UDim.new(0, 6)
	healthBgCorner.Parent = healthBg

	local fill = Instance.new("Frame")
	fill.Name = "HealthFill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.new(0, 1, 0)
	fill.BorderSizePixel = 0
	fill.Parent = healthBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Position = UDim2.new(0, 0, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = string.format("%d/%d", currentHealth, MAX_HEALTH)
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.ZIndex = 10
	text.Parent = barContainer

	healthFill = fill
	healthText = text
end

----------------------------------------------------
-- ANIMATION SETUP (death anim only)
----------------------------------------------------
local DEFAULT_DEATH = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://85226245896782",
	[Enum.HumanoidRigType.R6]  = "rbxassetid://84623772702206",
}

local animator: Animator? = nil
if humanoid then
	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
end

local deathTrack: AnimationTrack?

local function normalizeId(id)
	if not id or id == "" then return nil end
	id = tostring(id)
	if not id:match("^rbxassetid://") then
		id = "rbxassetid://" .. id
	end
	return id
end

local function loadDeathAnimation()
	if not animator then return end

	local rigType = humanoid and humanoid.RigType or Enum.HumanoidRigType.R15
	local id = DEFAULT_DEATH[rigType]

	local formatted = normalizeId(id)
	if not formatted then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = formatted
	local ok, trackOrErr = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok then
		deathTrack = trackOrErr :: AnimationTrack
		deathTrack.Priority = Enum.AnimationPriority.Action4
	else
		warn("ItachiDummyTutorial: failed to load death anim", trackOrErr)
	end
end

local function playDeathAnimation(onComplete)
	if not deathTrack then
		if onComplete then onComplete() end
		return
	end

	local finished = false
	local conn

	local function complete()
		if finished then return end
		finished = true
		if conn then conn:Disconnect() end
		if onComplete then onComplete() end
	end

	local ok, err = pcall(function()
		conn = deathTrack.Stopped:Connect(complete)
		deathTrack:Play(0.1, 1, 1)
	end)
	if not ok then
		warn("ItachiDummyTutorial: death anim failed", err)
		complete()
		return
	end

	task.delay(DEATH_ANIMATION_TIMEOUT, complete)
end

----------------------------------------------------
-- DAMAGE HANDLING (1-hit kill, no normal rewards)
----------------------------------------------------
local destroyed = false

local function giveTutorialReward(player: Player)
	if not player then return end

	-- use a player attribute so it survives dummy respawns
	if player:GetAttribute("TutorialDummyRewarded") then
		return
	end

	player:SetAttribute("TutorialDummyRewarded", true)

	if _G.addXP and type(_G.addXP) == "function" then
		pcall(function()
			_G.addXP(player, XP_REWARD)
		end)
	end

	if _G.addPlayerCash and type(_G.addPlayerCash) == "function" then
		pcall(function()
			_G.addPlayerCash(player, CASH_REWARD, "TutorialDummy")
		end)
	end
end

local function takeDamage(player, damage, hitPos)
	if destroyed or currentHealth <= 0 then return end

	-- Force at least 30 damage so he always dies in 1 hit
	damage = math.max(damage or MAX_HEALTH, MAX_HEALTH)

	currentHealth = math.max(0, currentHealth - damage)

	-- optional damage numbers
	if _G.showDamageNumber then
		pcall(function()
			_G.showDamageNumber(player, damage, hitPos or root.Position)
		end)
	end

	updateHealthBar()

	if currentHealth <= 0 then
		destroyed = true

		-- one-time tutorial reward + client notification
		if player then
			giveTutorialReward(player)

			if tutorialEvent and tutorialEvent:IsA("RemoteEvent") then
				tutorialEvent:FireClient(player)
			end
		end

		-- ensure Humanoid.Died fires
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end

		-- Play death animation, then respawn
		playDeathAnimation(function()
			-- small burst VFX
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
			emitter.Color = ColorSequence.new(
				Color3.fromRGB(255, 140, 0),
				Color3.fromRGB(255, 240, 200)
			)
			emitter.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1.5),
				NumberSequenceKeypoint.new(1, 0)
			}
			emitter.Speed = NumberRange.new(8, 16)
			emitter.Lifetime = NumberRange.new(0.3, 0.6)
			emitter.Rate = 0
			emitter.Parent = root
			emitter:Emit(40)
			Debris:AddItem(emitter, 1)

			-- hide this dummy and respawn a fresh one
			local oldModel = dummy
			oldModel.Parent = nil

			task.delay(RESPAWN_DELAY, function()
				local newDummy = oldModel:Clone()
				newDummy.Parent = workspace
			end)
		end)
	end
end

----------------------------------------------------
-- PUNCH HOOKUP (uses same PunchEvent as boxes)
----------------------------------------------------
local function fibonacciXP(level)
	if level <= 1 then
		return 10
	elseif level == 2 then
		return 20
	end
	local prev1, prev2 = 20, 10
	for _ = 3, level do
		local current = prev1 + prev2
		prev2 = prev1
		prev1 = current
	end
	return prev1
end

local function resolvePetDamageMultiplier(player)
	local function toPositiveNumber(value)
		local num = tonumber(value)
		if num and num > 0 then return num end
		return nil
	end

	if not player then return 1 end

	local attr = toPositiveNumber(player:GetAttribute("PetDamageBoost"))
	if attr then return attr end

	local statsAttr = toPositiveNumber(player:GetAttribute("PetDamageBoostStats"))
	if statsAttr then return statsAttr end

	local statsInstance = player:FindFirstChild("PetDamageBoostStats")
	if statsInstance then
		if statsInstance:IsA("NumberValue") then
			local v = toPositiveNumber(statsInstance.Value)
			if v then return v end
		elseif statsInstance:IsA("Folder") then
			local preferred = statsInstance:FindFirstChild("Total")
				or statsInstance:FindFirstChild("Damage")
				or statsInstance:FindFirstChild("Value")
			if preferred and preferred:IsA("NumberValue") then
				local v = toPositiveNumber(preferred.Value)
				if v then return v end
			end
			for _, child in ipairs(statsInstance:GetChildren()) do
				if child:IsA("NumberValue") then
					local v = toPositiveNumber(child.Value)
					if v then return v end
				end
			end
		end
	end

	return 1
end

local function hookupPunch()
	local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent", 10)
	if not punchEvent or not punchEvent:IsA("RemoteEvent") then
		warn("ItachiDummyTutorial: PunchEvent missing")
		return
	end

	punchEvent.OnServerEvent:Connect(function(player)
		if destroyed or not root or not root.Parent then return end
		if not player or not player.Character then return end

		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if (hrp.Position - root.Position).Magnitude > PUNCH_RADIUS then
			return
		end

		-- Same damage formula as boxes/enemies (but forced to 1 hit)
		local level = (_G.getPlayerLevel and _G.getPlayerLevel(player)) or 1
		local baseDamage = fibonacciXP(level)
		local damage = baseDamage * resolvePetDamageMultiplier(player)

		takeDamage(player, damage, root.Position)
	end)
end

----------------------------------------------------
-- INIT
----------------------------------------------------
createHealthBar()
updateHealthBar()
loadDeathAnimation()
hookupPunch()

print("ItachiDummyTutorial ready with", MAX_HEALTH, "HP (1-hit kill, tutorial rewards only)")

-- Even-Level Enemy Template
-- Drop this script inside the enemy model/part you want to guard even levels

local enemy = script.Parent
if not enemy then
	warn("EvenLevelEnemy: no parent, aborting")
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRing = nil

do
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if sharedFolder then
		local combatRingModule = sharedFolder:FindFirstChild("CombatRing")
		if combatRingModule and combatRingModule:IsA("ModuleScript") then
			local ok, moduleOrErr = pcall(function()
				return require(combatRingModule)
			end)
			if ok then
				CombatRing = moduleOrErr
			else
				warn("EvenLevelEnemy: CombatRing require failed", moduleOrErr)
			end
		end
	end
end

local DEFAULT_ANIMATIONS = {
	[Enum.HumanoidRigType.R15] = {
		Attack = "rbxassetid://103752860008283",
		Idle = "rbxassetid://507766388",
		Death = "rbxassetid://85226245896782",
	},
	[Enum.HumanoidRigType.R6] = {
		Attack = "rbxassetid://119818896833456",
		Idle = "rbxassetid://96998012326738",
		Death = "rbxassetid://84623772702206",
	},
}

local ATTACK_RADIUS = 8
local PLAYER_PUNCH_RADIUS = 8
local ATTACK_COOLDOWN = 1.2
local ATTACK_CHECK_INTERVAL = 0.2
local RESPAWN_DELAY = 4
local DEATH_ANIMATION_TIMEOUT = 4

local DEFAULT_CONFIG = {Health = 150, Reward = 25}
local HEALTH_BASE = 100
local HEALTH_PER_LEVEL = 20

local ENEMY_DAMAGE_MIN = 12
local ENEMY_BASE_DAMAGE = math.floor(HEALTH_BASE * 0.2 + 0.5) -- align to 20% of base HP
local ENEMY_DAMAGE_PER_LEVEL = math.max(1, math.floor(HEALTH_PER_LEVEL * 0.2 + 0.5))
local ENEMY_DAMAGE_MAX_BASE = math.floor(HEALTH_BASE * 0.35 + 0.5)
local ENEMY_DAMAGE_MAX_PER_LEVEL = math.max(1, math.floor(HEALTH_PER_LEVEL * 0.35 + 0.5))

local BOX_LEVEL_CONFIG = {
	[1] = {Health = 100, Reward = 10},
	[3] = {Health = 300, Reward = 66},
	[5] = {Health = 800, Reward = 132},
	[7] = {Health = 2520, Reward = 412},
	[9] = {Health = 6600, Reward = 898},
	[11] = {Health = 20160, Reward = 2686},
	[13] = {Health = 52780, Reward = 6152},
	[15] = {Health = 138180, Reward = 17894},
	[17] = {Health = 413440, Reward = 42192},
}

local ORDERED_BOX_LEVELS = {1, 3, 5, 7, 9, 11, 13, 15, 17}
local EVEN_LEVEL_CONFIG = {}

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

for index = 1, #ORDERED_BOX_LEVELS - 1 do
	local lowerLevel = ORDERED_BOX_LEVELS[index]
	local upperLevel = ORDERED_BOX_LEVELS[index + 1]
	local evenLevel = lowerLevel + 1
	local lowerConfig = BOX_LEVEL_CONFIG[lowerLevel]
	local upperConfig = BOX_LEVEL_CONFIG[upperLevel]
	if lowerConfig and upperConfig then
		EVEN_LEVEL_CONFIG[evenLevel] = {
			Health = math.floor(lerp(lowerConfig.Health, upperConfig.Health, 0.55) + 0.5),
			Reward = math.floor(lerp(lowerConfig.Reward, upperConfig.Reward, 0.55) + 0.5),
		}
	end
end

do
	local lastOdd = ORDERED_BOX_LEVELS[#ORDERED_BOX_LEVELS]
	local lastConfig = BOX_LEVEL_CONFIG[lastOdd]
	if lastConfig then
		EVEN_LEVEL_CONFIG[lastOdd + 1] = {
			Health = math.floor(lastConfig.Health * 1.4 + 0.5),
			Reward = math.floor(lastConfig.Reward * 1.35 + 0.5),
		}
	end
end

local function resolveEnemyLevel()
	local attr = enemy:GetAttribute("EnemyLevel")
		or script:GetAttribute("EnemyLevel")
		or enemy:GetAttribute("BoxLevel")

	if typeof(attr) == "number" then
		local level = math.max(2, math.floor(attr + 0.5))
		if level % 2 ~= 0 then
			level += 1
		end
		return level
	end

	return 2
end

local function findRoot(instance)
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end
		local hrp = instance:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp
		end
		return instance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local ENEMY_LEVEL = resolveEnemyLevel()
enemy:SetAttribute("EnemyLevel", ENEMY_LEVEL)

local ACTIVE_CONFIG = EVEN_LEVEL_CONFIG[ENEMY_LEVEL]
	or BOX_LEVEL_CONFIG[ENEMY_LEVEL]
	or DEFAULT_CONFIG

local MAX_HEALTH = ACTIVE_CONFIG.Health or DEFAULT_CONFIG.Health
local REWARD_VALUE = ACTIVE_CONFIG.Reward or DEFAULT_CONFIG.Reward
local currentHealth = MAX_HEALTH

enemy:SetAttribute("MaxHealth", MAX_HEALTH)
enemy:SetAttribute("CurrentHealth", currentHealth)

local enemyRoot = findRoot(enemy)
if not enemyRoot then
	warn("EvenLevelEnemy: " .. enemy:GetFullName() .. " missing root part")
	return
end

local punchRangeRing = nil
if CombatRing then
	punchRangeRing = CombatRing.attach(enemy, PLAYER_PUNCH_RADIUS, {
		Name = "PunchRangeRing",
		Hover = 0.05,
		InnerColor = Color3.fromRGB(173, 224, 255),
		OuterColor = Color3.fromRGB(19, 148, 255),
		GlowColor = Color3.fromRGB(121, 211, 255),
		FillTransparency = 0.4,
		OutlineThickness = 10,
		GlowThickness = 18,
		StreakCount = 0,
	})
	if punchRangeRing then
		enemy.Destroying:Connect(function()
			punchRangeRing:destroy()
		end)
	end
end

local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
local enemyAnimator: Animator? = nil
if enemyHumanoid then
	enemyAnimator = enemyHumanoid:FindFirstChildOfClass("Animator")
	if not enemyAnimator then
		enemyAnimator = Instance.new("Animator")
		enemyAnimator.Parent = enemyHumanoid
	end
end

local function getDefaultAnimationId(kind)
	local rigType = (enemyHumanoid and enemyHumanoid.RigType) or Enum.HumanoidRigType.R15
	local rigDefaults = DEFAULT_ANIMATIONS[rigType] or DEFAULT_ANIMATIONS[Enum.HumanoidRigType.R15]
	if rigDefaults then
		return rigDefaults[kind]
	end
	return nil
end

local spawnParent = enemy.Parent
local spawnPivot = enemy:IsA("Model") and enemy:GetPivot() or enemyRoot.CFrame
local respawnTemplate = enemy:Clone()
respawnTemplate.Parent = nil

local scriptTemplate = script:Clone()
scriptTemplate.Parent = nil

local function purgeEnemyScriptInstances(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BaseScript") and descendant.Name == script.Name then
			descendant:Destroy()
		end
	end
	local child = model:FindFirstChild(script.Name)
	if child and child:IsA("BaseScript") then
		child:Destroy()
	end
end

purgeEnemyScriptInstances(respawnTemplate)

local function attachEnemyScript(newEnemy)
	local template = scriptTemplate or script
	if not template then
		return
	end

	local clone = template:Clone()
	clone.Parent = newEnemy
end

local playerPunchCooldown = {}
local lastAttackCheck = 0
local defeated = false
local attackAnimTrack: AnimationTrack? = nil
local idleAnimTrack: AnimationTrack? = nil
local deathAnimTrack: AnimationTrack? = nil

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

local function toPositiveNumber(value)
	local numberValue = tonumber(value)
	if numberValue and numberValue > 0 then
		return numberValue
	end
	return nil
end

local function resolvePetDamageMultiplier(player)
	if not player then
		return 1
	end

	local attrMultiplier = toPositiveNumber(player:GetAttribute("PetDamageBoost"))
	if attrMultiplier then
		return attrMultiplier
	end

	local statsAttr = toPositiveNumber(player:GetAttribute("PetDamageBoostStats"))
	if statsAttr then
		return statsAttr
	end

	local statsInstance = player:FindFirstChild("PetDamageBoostStats")
	if statsInstance then
		if statsInstance:IsA("NumberValue") then
			local fromValue = toPositiveNumber(statsInstance.Value)
			if fromValue then
				return fromValue
			end
		elseif statsInstance:IsA("Folder") then
			local preferred = statsInstance:FindFirstChild("Total")
				or statsInstance:FindFirstChild("Damage")
				or statsInstance:FindFirstChild("Value")
			if preferred and preferred:IsA("NumberValue") then
				local fromPreferred = toPositiveNumber(preferred.Value)
				if fromPreferred then
					return fromPreferred
				end
			end
			for _, child in ipairs(statsInstance:GetChildren()) do
				if child:IsA("NumberValue") then
					local fromChild = toPositiveNumber(child.Value)
					if fromChild then
						return fromChild
					end
				end
			end
		end
	end

	return 1
end

local function applyDamageBoost(player, damage)
	local multiplier = resolvePetDamageMultiplier(player)
	return math.floor(math.max(1, damage * multiplier) + 0.5)
end

local function resolveDamageLevel(player, assumedLevel)
	if _G.getPlayerLevel then
		local ok, value = pcall(_G.getPlayerLevel, player)
		if ok and typeof(value) == "number" and value > 0 then
			return math.max(1, math.floor(value + 0.5))
		end
	end

	if player then
		local attrLevel = player:GetAttribute("Level")
		if typeof(attrLevel) == "number" and attrLevel > 0 then
			return math.max(1, math.floor(attrLevel + 0.5))
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local stat = leaderstats:FindFirstChild("Level")
			if stat and typeof(stat.Value) == "number" and stat.Value > 0 then
				return math.max(1, math.floor(stat.Value + 0.5))
			end
		end
	end

	if typeof(assumedLevel) == "number" and assumedLevel > 0 then
		return math.max(1, math.floor(assumedLevel + 0.5))
	end

	return 1
end

local function computeEnemyPunchDamage(player, assumedLevel)
	local level = resolveDamageLevel(player, assumedLevel)
	local scaled = ENEMY_BASE_DAMAGE + ((level - 1) * ENEMY_DAMAGE_PER_LEVEL)
	local maxCap = ENEMY_DAMAGE_MAX_BASE + ((level - 1) * ENEMY_DAMAGE_MAX_PER_LEVEL)
	local rounded = math.floor(scaled + 0.5)
	local roundedCap = math.floor(maxCap + 0.5)
	return math.clamp(rounded, ENEMY_DAMAGE_MIN, math.max(ENEMY_DAMAGE_MIN, roundedCap))
end

local function updateHealthBar(healthFill, healthText)
	if not healthFill then
		return
	end
	local percent = math.clamp(currentHealth / MAX_HEALTH, 0, 1)
	local color = Color3.new(0, 1, 0)
	if percent <= 0.3 then
		color = Color3.new(1, 0, 0)
	elseif percent <= 0.6 then
		color = Color3.new(1, 1, 0)
	end

	TweenService:Create(
		healthFill,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
	billboardGui.Parent = enemyRoot

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "EnemyLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.format("Enemy L%d", ENEMY_LEVEL)
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

	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = string.format("%d/%d", currentHealth, MAX_HEALTH)
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextStrokeTransparency = 0
	healthText.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.SourceSansBold
	healthText.ZIndex = 10
	healthText.Parent = barContainer

	return fill, healthText
end

local healthFill, healthText = createHealthBar()
updateHealthBar(healthFill, healthText)

local function normalizeAnimationId(animId)
	if not animId then
		return nil
	end
	local idString = tostring(animId)
	if idString == "" then
		return nil
	end
	if not idString:match("^rbxassetid://") then
		idString = "rbxassetid://" .. idString
	end
	return idString
end

local function loadAnimationTrack(animId, looped)
	if not enemyAnimator then
		return nil
	end

	local formattedId = normalizeAnimationId(animId)
	if not formattedId then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = formattedId

	local success, trackOrErr = pcall(function()
		return enemyAnimator:LoadAnimation(animation)
	end)

	if not success then
		warn("EvenLevelEnemy failed to load animation:", trackOrErr)
		return nil
	end

	local track = trackOrErr :: AnimationTrack
	track.Looped = looped or false
	if looped then
		track.Priority = Enum.AnimationPriority.Movement
	else
		track.Priority = Enum.AnimationPriority.Action4
	end
	return track
end

local function setupAnimations()
	local attackId = enemy:GetAttribute("AttackAnimationId")
		or script:GetAttribute("AttackAnimationId")
		or getDefaultAnimationId("Attack")
	local idleId = enemy:GetAttribute("IdleAnimationId")
		or script:GetAttribute("IdleAnimationId")
		or getDefaultAnimationId("Idle")
	local deathId = enemy:GetAttribute("DeathAnimationId")
		or script:GetAttribute("DeathAnimationId")
		or getDefaultAnimationId("Death")

	attackAnimTrack = loadAnimationTrack(attackId, false)
	idleAnimTrack = loadAnimationTrack(idleId, true)
	if deathId then
		deathAnimTrack = loadAnimationTrack(deathId, false)
	end

	if idleAnimTrack and not idleAnimTrack.IsPlaying then
		idleAnimTrack:Play(0.1, 1, 1)
		idleAnimTrack:AdjustWeight(1, 0)
	end

	if attackAnimTrack then
		attackAnimTrack.Stopped:Connect(function()
			if idleAnimTrack then
				if not idleAnimTrack.IsPlaying then
					idleAnimTrack:Play(0.1, 1, 1)
				end
				idleAnimTrack:AdjustWeight(1, 0.05)
			end
		end)
	end
end

local function ensureIdleWeight()
	if idleAnimTrack then
		if not idleAnimTrack.IsPlaying then
			idleAnimTrack:Play(0.1, 1, 1)
		end
		idleAnimTrack:AdjustWeight(1, 0.05)
	end
end

local function playAttackAnimation()
	if attackAnimTrack then
		if attackAnimTrack.IsPlaying then
			attackAnimTrack:Stop()
		end
		if idleAnimTrack and idleAnimTrack.IsPlaying then
			idleAnimTrack:AdjustWeight(0.1, 0.05)
		end
		attackAnimTrack:Play(0.05, 1, 1)
	else
		ensureIdleWeight()
	end
end

local function stopCombatAnimations()
	if attackAnimTrack and attackAnimTrack.IsPlaying then
		attackAnimTrack:Stop()
	end
	if idleAnimTrack and idleAnimTrack.IsPlaying then
		idleAnimTrack:Stop()
	end
end

local function playDeathAnimation(onComplete)
	if not deathAnimTrack then
		if onComplete then
			onComplete()
		end
		return
	end

	local finished = false
	local connection: RBXScriptConnection? = nil

	local function complete()
		if finished then
			return
		end
		finished = true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if onComplete then
			onComplete()
		end
	end

	local ok, err = pcall(function()
		connection = deathAnimTrack.Stopped:Connect(complete)
		deathAnimTrack:Play(0.1, 1, 1)
	end)

	if not ok then
		warn("EvenLevelEnemy death animation failed:", err)
		complete()
		return
	end

	task.delay(DEATH_ANIMATION_TIMEOUT, complete)
end

local function faceEnemyTowards(targetPosition)
	if not enemyRoot or not targetPosition then
		return
	end

	local rootPos = enemyRoot.Position
	local flatTarget = Vector3.new(targetPosition.X, rootPos.Y, targetPosition.Z)
	local direction = flatTarget - rootPos
	if direction.Magnitude < 0.1 then
		return
	end

	local newCFrame = CFrame.lookAt(rootPos, flatTarget)
	enemyRoot.CFrame = newCFrame
end

setupAnimations()

local function rewardPlayer(player)
	if not player then
		return
	end

	local successXP, errXP
	if _G.addXP then
		successXP, errXP = pcall(function()
			_G.addXP(player, REWARD_VALUE)
		end)
		if not successXP then
			warn("EvenLevelEnemy XP reward failed:", errXP)
		end
	end

	if not successXP then
		local giveXPEvent = ReplicatedStorage:FindFirstChild("GiveXP")
		if giveXPEvent and giveXPEvent:IsA("RemoteEvent") then
			giveXPEvent:FireServer(REWARD_VALUE)
		end
	end

	if _G.addPlayerCash then
		local ok, err = pcall(function()
			_G.addPlayerCash(player, REWARD_VALUE, "EnemyReward")
		end)
		if not ok then
			warn("EvenLevelEnemy cash reward failed:", err)
		end
	end
end

local function spawnDefeatBurst()
	if not enemyRoot or not enemyRoot.Parent then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 240, 200))
	emitter.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	}
	emitter.Speed = NumberRange.new(8, 16)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Rate = 0
	emitter.Parent = enemyRoot
	emitter:Emit(40)
	game:GetService("Debris"):AddItem(emitter, 1)
end

local function respawnEnemy(oldEnemy)
	task.delay(RESPAWN_DELAY, function()
		if not spawnParent then
			return
		end

		local newEnemy = respawnTemplate:Clone()
		attachEnemyScript(newEnemy)
		newEnemy.Parent = spawnParent

		if newEnemy:IsA("Model") then
			if newEnemy.PrimaryPart then
				newEnemy:PivotTo(spawnPivot)
			else
				local newRoot = findRoot(newEnemy)
				if newRoot then
					newEnemy:PivotTo(spawnPivot)
				end
			end
		elseif newEnemy:IsA("BasePart") then
			newEnemy.CFrame = spawnPivot
		else
			local newRoot = findRoot(newEnemy)
			if newRoot then
				newRoot.CFrame = spawnPivot
			end
		end

		if oldEnemy then
			oldEnemy:Destroy()
		end
	end)
end

local function defeatEnemy(player)
	if defeated then
		return
	end
	defeated = true
	stopCombatAnimations()

	rewardPlayer(player)
	playDeathAnimation(workspace.Parent)
	wait(1)
	spawnDefeatBurst()
	local oldEnemy = enemy
	if oldEnemy then
		oldEnemy.Parent = nil
	end

	local function finalizeDeath()
		respawnEnemy(oldEnemy)
	end

	playDeathAnimation(finalizeDeath)
end

local function takeDamage(player, damage, hitPosition)
	if defeated or currentHealth <= 0 then
		return
	end

	currentHealth = math.max(0, currentHealth - damage)
	enemy:SetAttribute("CurrentHealth", currentHealth)
	updateHealthBar(healthFill, healthText)

	if _G.showDamageNumber then
		local ok, err = pcall(function()
			_G.showDamageNumber(player, damage, hitPosition or enemyRoot.Position)
		end)
		if not ok then
			warn("EvenLevelEnemy damage number failed:", err)
		end
	end

	if currentHealth <= 0 then
		defeatEnemy(player)
	end
end

local function handlePunchEvent()
	local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent", 10)
	if not punchEvent or not punchEvent:IsA("RemoteEvent") then
		warn("EvenLevelEnemy: PunchEvent missing")
		return
	end

	punchEvent.OnServerEvent:Connect(function(player)
		if defeated then
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not enemyRoot or not enemyRoot.Parent then
			return
		end

		if (root.Position - enemyRoot.Position).Magnitude > PLAYER_PUNCH_RADIUS then
			return
		end

		local level = (_G.getPlayerLevel and _G.getPlayerLevel(player))
			or (player:FindFirstChild("Level") and tonumber(player.Level.Value))
			or 1
		local baseDamage = fibonacciXP(level)
		local scaledDamage = applyDamageBoost(player, baseDamage)
		takeDamage(player, scaledDamage, root.Position)
	end)
end

local function damagePlayer(player, amount)
	playAttackAnimation()

	if _G.damagePlayer then
		local ok, err = pcall(function()
			_G.damagePlayer(player, amount)
		end)
		if ok then
			return
		else
			warn("EvenLevelEnemy _G.damagePlayer failed:", err)
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(amount)
	end
end

Players.PlayerRemoving:Connect(function(player)
	playerPunchCooldown[player.UserId] = nil
end)

RunService.Heartbeat:Connect(function(dt)
	if defeated or not enemyRoot or not enemyRoot.Parent then
		return
	end

	lastAttackCheck += dt
	if lastAttackCheck < ATTACK_CHECK_INTERVAL then
		return
	end
	lastAttackCheck = 0

	local now = os.clock()
	local closestRoot: BasePart? = nil
	local closestDistance = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local distance = (root.Position - enemyRoot.Position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestRoot = root
			end
			if distance <= ATTACK_RADIUS then
				local lastHit = playerPunchCooldown[player.UserId] or 0
				if now - lastHit >= ATTACK_COOLDOWN then
					faceEnemyTowards(root.Position)
					local damage = computeEnemyPunchDamage(player, ENEMY_LEVEL)
					damagePlayer(player, damage)
					playerPunchCooldown[player.UserId] = now
				end
			end
		end
	end

	if closestRoot and closestDistance <= (ATTACK_RADIUS * 1.5) then
		faceEnemyTowards(closestRoot.Position)
	end
end)

handlePunchEvent()

print(string.format("EvenLevelEnemy ready at level %d (%d HP / %d reward)", ENEMY_LEVEL, MAX_HEALTH, REWARD_VALUE))

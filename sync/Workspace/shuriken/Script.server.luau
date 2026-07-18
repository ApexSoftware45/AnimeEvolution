-- XP Object Template
-- Generalized version of the destructible box script that works for any model/part

local xpObject = script.Parent
if not xpObject then
	error("XPObjectTemplate must be placed inside the XP object model or part")
end

local respawnTemplate = xpObject:Clone()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local DEFAULT_OBJECT_COLOR = Color3.new(0.266667, 0.164706, 0.00392157)
local OBJECT_COLOR_BY_LEVEL = {
	[1] = Color3.fromRGB(255, 255, 255),
	[3] = Color3.fromRGB(255, 210, 120),
	[5] = Color3.fromRGB(255, 130, 130),
	[7] = Color3.fromRGB(255, 105, 180),
	[9] = Color3.fromRGB(150, 120, 255),
	[11] = Color3.fromRGB(95, 200, 255),
	[13] = Color3.fromRGB(100, 255, 190),
	[15] = Color3.fromRGB(255, 255, 130),
	[17] = Color3.fromRGB(80, 80, 80),
}

local DEFAULT_OBJECT_CONFIG = {
	Health = 100,
	Reward = 10,
}

local OBJECT_LEVEL_CONFIG = {
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

local function getObjectLevel()
	local levelAttr = xpObject:GetAttribute("BoxLevel")
		or script:GetAttribute("BoxLevel")
	if typeof(levelAttr) == "number" then
		return math.clamp(math.floor(levelAttr + 0.5), 1, 1000)
	end
	return nil
end

local function resolveObjectColor(level)
	if level and OBJECT_COLOR_BY_LEVEL[level] then
		return OBJECT_COLOR_BY_LEVEL[level]
	end
	return DEFAULT_OBJECT_COLOR
end

local function findRootPart(target: Instance?): BasePart?
	if not target then
		return nil
	end

	if target:IsA("BasePart") then
		return target
	end

	if target:IsA("Model") then
		if target.PrimaryPart then
			return target.PrimaryPart
		end

		local candidate = target:FindFirstChildWhichIsA("BasePart")
		if candidate then
			target.PrimaryPart = candidate
			return candidate
		end
	end

	return target:FindFirstChildWhichIsA("BasePart")
end

local objectRoot = findRootPart(xpObject)
if not objectRoot then
	error("XPObjectTemplate requires the parent to be a BasePart or a Model with BaseParts")
end

local OBJECT_LEVEL = getObjectLevel()
pcall(function()
	objectRoot.Color = resolveObjectColor(OBJECT_LEVEL)
end)

local ACTIVE_OBJECT_CONFIG = (OBJECT_LEVEL and OBJECT_LEVEL_CONFIG[OBJECT_LEVEL]) or DEFAULT_OBJECT_CONFIG
local MAX_HEALTH = ACTIVE_OBJECT_CONFIG.Health or DEFAULT_OBJECT_CONFIG.Health
local BOX_REWARD_VALUE = ACTIVE_OBJECT_CONFIG.Reward or DEFAULT_OBJECT_CONFIG.Reward
local RESPAWN_TIME = script:GetAttribute("RespawnTime") or xpObject:GetAttribute("RespawnTime") or 15
local TOUCH_DAMAGE_ENABLED = script:GetAttribute("TouchDamageEnabled")
if TOUCH_DAMAGE_ENABLED == nil then
	TOUCH_DAMAGE_ENABLED = xpObject:GetAttribute("TouchDamageEnabled")
end
if TOUCH_DAMAGE_ENABLED == nil then
	-- Keep touch damage on by default; startup grace below prevents spawn-overlap insta-breaks.
	TOUCH_DAMAGE_ENABLED = true
end

local TOUCH_ARM_DELAY = script:GetAttribute("TouchArmDelay") or xpObject:GetAttribute("TouchArmDelay") or 1
local TOUCH_STARTUP_GRACE = script:GetAttribute("TouchStartupGrace") or xpObject:GetAttribute("TouchStartupGrace") or 1
local HEALTHBAR_ALWAYS_ON_TOP = script:GetAttribute("HealthBarAlwaysOnTop")
if HEALTHBAR_ALWAYS_ON_TOP == nil then
	HEALTHBAR_ALWAYS_ON_TOP = xpObject:GetAttribute("HealthBarAlwaysOnTop")
end
if HEALTHBAR_ALWAYS_ON_TOP == nil then
	HEALTHBAR_ALWAYS_ON_TOP = false
end

local DEBUG_XP_OBJECT = script:GetAttribute("DebugXPObject")
if DEBUG_XP_OBJECT == nil then
	DEBUG_XP_OBJECT = xpObject:GetAttribute("DebugXPObject")
end
DEBUG_XP_OBJECT = DEBUG_XP_OBJECT == true

local currentHealth = MAX_HEALTH
local createdAt = tick()
local touchArmed = TOUCH_ARM_DELAY <= 0
if not touchArmed then
	task.delay(TOUCH_ARM_DELAY, function()
		touchArmed = true
	end)
end

local hitSound
local destroySound
local hitParticles

if DEBUG_XP_OBJECT then
	print(
		("XPObjectTemplate init %s health=%d respawn=%s touch=%s armDelay=%.2f"):format(
			xpObject:GetFullName(),
			MAX_HEALTH,
			tostring(RESPAWN_TIME),
			tostring(TOUCH_DAMAGE_ENABLED),
			TOUCH_ARM_DELAY
		)
	)
end

local function fibonacciXP(level)
	if level <= 1 then
		return 10
	elseif level == 2 then
		return 20
	end
	local prev1, prev2 = 20, 10
	local current = 0
	for _ = 3, level do
		current = prev1 + prev2
		prev2 = prev1
		prev1 = current
	end
	return current
end

local function resolvePetDamageMultiplier(player)
	local function toPositiveNumber(value)
		local numberValue = tonumber(value)
		if numberValue and numberValue > 0 then
			return numberValue
		end
		return nil
	end

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
			local candidates = {}
			if preferred then
				table.insert(candidates, preferred)
			end
			for _, child in ipairs(statsInstance:GetChildren()) do
				table.insert(candidates, child)
			end
			for _, child in ipairs(candidates) do
				local fromChild = toPositiveNumber(child.Value)
				if fromChild then
					return fromChild
				end
			end
		end
	end

	return 1
end

local function applyDamageBoost(player, baseDamage)
	if typeof(baseDamage) ~= "number" then
		return 0
	end
	return baseDamage * resolvePetDamageMultiplier(player)
end

local function getBillboardAdornee(): BasePart
	return objectRoot
end

local function createHitbox(): BasePart
	local existing = xpObject:FindFirstChild("DamageHitbox")
	if existing and existing:IsA("BasePart") then
		return existing
	end

	local hitbox = Instance.new("Part")
	hitbox.Name = "DamageHitbox"
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanTouch = true
	hitbox.CanQuery = false
	hitbox.Massless = true
	hitbox.Anchored = true
	hitbox.Parent = xpObject
	return hitbox
end

local damageHitbox = createHitbox()

local function getObjectPivot(target: Instance)
	if target:IsA("Model") then
		return target:GetPivot()
	end
	return target.CFrame
end

local function alignHitbox()
	if not damageHitbox then
		return
	end

	local padding = script:GetAttribute("HitboxPadding") or xpObject:GetAttribute("HitboxPadding") or 0.4
	local sizePadding = Vector3.new(padding, padding, padding)

	if xpObject:IsA("Model") then
		local extents = xpObject:GetExtentsSize() + sizePadding
		damageHitbox.Size = Vector3.new(
			math.max(extents.X, 0.2),
			math.max(extents.Y, 0.2),
			math.max(extents.Z, 0.2)
		)
		damageHitbox.CFrame = xpObject:GetPivot()
	elseif xpObject:IsA("BasePart") then
		damageHitbox.Size = xpObject.Size + sizePadding
		damageHitbox.CFrame = xpObject.CFrame
	else
		damageHitbox.Size = Vector3.new(4, 4, 4)
		damageHitbox.CFrame = objectRoot.CFrame
	end
end

alignHitbox()
RunService.Heartbeat:Connect(alignHitbox)

local function createDestroyVFX()
	local explosion = Instance.new("Explosion")
	explosion.Position = damageHitbox.Position
	explosion.BlastRadius = 10
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	for _ = 1, 8 do
		local debrisPart = Instance.new("Part")
		debrisPart.Size = Vector3.new(0.5, 0.5, 0.5)
		debrisPart.Material = objectRoot.Material
		debrisPart.Color = objectRoot.Color
		debrisPart.Position = damageHitbox.Position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		debrisPart.Velocity = Vector3.new(
			math.random(-10, 10),
			math.random(5, 15),
			math.random(-10, 10)
		)
		debrisPart.AssemblyAngularVelocity = Vector3.new(
			math.random(-10, 10),
			math.random(-10, 10),
			math.random(-10, 10)
		)
		debrisPart.Parent = workspace
		Debris:AddItem(debrisPart, 5)
	end
end

local function destroyObject(player)
	if not xpObject or not xpObject.Parent then
		return
	end

	local pivot = getObjectPivot(xpObject)
	local parent = xpObject.Parent
	local respawnDelay = math.max(0, RESPAWN_TIME)

	if DEBUG_XP_OBJECT then
		print(
			("XPObjectTemplate destroy %s by %s (respawn in %s)"):format(
				xpObject:GetFullName(),
				player and player.Name or "unknown",
				tostring(respawnDelay)
			)
		)
	end

	if destroySound then
		destroySound:Play()
	end

	createDestroyVFX()

	local levelValue = player:FindFirstChild("Level")
	local level = 1
	if levelValue and levelValue:IsA("NumberValue") then
		level = levelValue.Value
	elseif typeof(player:GetAttribute("Level")) == "number" then
		level = player:GetAttribute("Level")
	end

	local XP_REWARD = BOX_REWARD_VALUE
	print(("XPObjectTemplate awarding %d XP to %s (level %s)"):format(XP_REWARD, player.Name, tostring(level)))

	if _G.addXP and type(_G.addXP) == "function" then
		local success, err = pcall(function()
			_G.addXP(player, XP_REWARD)
		end)
		if not success then
			warn("Failed to award XP:", err)
		end
	else
		local giveXPEvent = ReplicatedStorage:FindFirstChild("GiveXP")
		if giveXPEvent then
			giveXPEvent:FireServer(XP_REWARD)
		else
			warn("No XP system found for XPObjectTemplate")
		end
	end

	local CASH_REWARD = XP_REWARD
	if _G.addPlayerCash and type(_G.addPlayerCash) == "function" then
		local successCash, errCash = pcall(function()
			_G.addPlayerCash(player, CASH_REWARD, "XPObjectReward")
		end)
		if not successCash then
			warn("Failed to award cash:", errCash)
		end
	else
		warn("No cash system available for XPObjectTemplate")
	end

	task.delay(respawnDelay, function()
		if not parent then
			return
		end

		local newObject = respawnTemplate:Clone()
		if newObject:IsA("Model") then
			newObject:PivotTo(pivot)
		elseif newObject:IsA("BasePart") then
			newObject.CFrame = pivot
		end
		newObject.Parent = parent
	end)

	xpObject:Destroy()
end

local function createHealthBar()
	local adornee = getBillboardAdornee()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Size = UDim2.new(6, 0, 3, 0)
	billboardGui.StudsOffset = Vector3.new(0, 4, 0)
	billboardGui.MaxDistance = 200
	billboardGui.AlwaysOnTop = HEALTHBAR_ALWAYS_ON_TOP
	billboardGui.Adornee = adornee
	billboardGui.Parent = adornee

	local displayName = xpObject:GetAttribute("DisplayName")
		or script:GetAttribute("DisplayName")
		or xpObject.Name

	local boxLabel = Instance.new("TextLabel")
	boxLabel.Name = "BoxLabel"
	boxLabel.Size = UDim2.new(1, 0, 0.4, 0)
	boxLabel.Position = UDim2.new(0, 0, 0, 0)
	boxLabel.BackgroundTransparency = 1
	boxLabel.Text = displayName
	boxLabel.TextColor3 = Color3.new(1, 1, 1)
	boxLabel.TextStrokeTransparency = 0
	boxLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	boxLabel.TextScaled = true
	boxLabel.Font = Enum.Font.SourceSansBold
	boxLabel.ZIndex = 10
	boxLabel.Parent = billboardGui

	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.new(1, 0, 0.3, 0)
	bgFrame.Position = UDim2.new(0, 0, 0.4, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bgFrame

	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, -8, 1, -8)
	healthBg.Position = UDim2.new(0, 4, 0, 4)
	healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = bgFrame

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = healthBg

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthFill"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 6)
	healthCorner.Parent = healthBar

	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = currentHealth .. "/" .. MAX_HEALTH
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextStrokeTransparency = 0
	healthText.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.SourceSansBold
	healthText.ZIndex = 10
	healthText.Parent = bgFrame

	return healthBar, healthText
end

local function createSounds()
	local hitSound = Instance.new("Sound")
	hitSound.Name = "HitSound"
	hitSound.SoundId = "rbxassetid://566593606"
	hitSound.Volume = 0.5
	hitSound.Parent = xpObject

	local destroySound = Instance.new("Sound")
	destroySound.Name = "DestroySound"
	destroySound.SoundId = "rbxassetid://566593606"
	destroySound.Volume = 0.8
	destroySound.Pitch = 0.6
	destroySound.Parent = xpObject

	local success1, err1 = pcall(function()
		hitSound:Load()
	end)
	if not success1 then
		warn("Failed to load hit sound:", err1)
	end

	local success2, err2 = pcall(function()
		destroySound:Load()
	end)
	if not success2 then
		warn("Failed to load destroy sound:", err2)
	end

	return hitSound, destroySound
end

local function createHitVFX()
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0, 0)
	attachment.Parent = objectRoot

	local particles = Instance.new("ParticleEmitter")
	particles.Enabled = false
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.new(1, 0.5, 0))
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	}
	particles.Lifetime = NumberRange.new(0.3, 0.8)
	particles.Rate = 100
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Speed = NumberRange.new(5, 15)
	particles.Parent = attachment

	return particles, attachment
end

local activeHealthFill, activeHealthText = createHealthBar()
hitSound, destroySound = createSounds()
hitParticles = select(1, createHitVFX())

local function updateHealthBar()
	if not activeHealthFill or not activeHealthText then
		return
	end

	local healthPercentage = currentHealth / MAX_HEALTH
	local color
	if healthPercentage > 0.6 then
		color = Color3.new(0, 1, 0)
	elseif healthPercentage > 0.3 then
		color = Color3.new(1, 1, 0)
	else
		color = Color3.new(1, 0, 0)
	end

	local tween = TweenService:Create(
		activeHealthFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{
			Size = UDim2.new(healthPercentage, 0, 1, 0),
			BackgroundColor3 = color,
		}
	)
	tween:Play()

	activeHealthText.Text = currentHealth .. "/" .. MAX_HEALTH
end

local hitboxTouchState = {}
local HITBOX_TOUCH_COOLDOWN = script:GetAttribute("HitboxTouchCooldown") or 0.35

local function canRegisterTouch(player)
	if not player then
		return false
	end
	local now = tick()
	local last = hitboxTouchState[player]
	if last and now - last < HITBOX_TOUCH_COOLDOWN then
		return false
	end
	hitboxTouchState[player] = now
	return true
end

local function takeDamage(player, damage, hitPosition)
	if currentHealth <= 0 or damage <= 0 then
		return
	end
	currentHealth = math.max(0, currentHealth - damage)

	if _G.showDamageNumber then
		_G.showDamageNumber(player, damage, hitPosition or damageHitbox.Position)
	end

	if hitSound then
		hitSound:Play()
	end

	if hitParticles then
		hitParticles:Emit(20)
	end

	updateHealthBar()

	if currentHealth <= 0 then
		destroyObject(player)
	end
end

damageHitbox.Touched:Connect(function(hit)
	if not TOUCH_DAMAGE_ENABLED or not touchArmed then
		return
	end
	if tick() - createdAt < TOUCH_STARTUP_GRACE then
		return
	end
	if not hit.Parent then
		return
	end

	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or not canRegisterTouch(player) then
		return
	end

	local level = (_G.getPlayerLevel and _G.getPlayerLevel(player)) or 1
	local baseDamage = fibonacciXP(level)
	local damage = applyDamageBoost(player, baseDamage)
	takeDamage(player, damage, hit.Position)
end)

local function bindPunchEvent(remoteEvent: RemoteEvent)
	if DEBUG_XP_OBJECT then
		print(("XPObjectTemplate bound damage remote %s for %s"):format(remoteEvent.Name, xpObject:GetFullName()))
	end

	remoteEvent.OnServerEvent:Connect(function(player)
		if not player or not player.Character then
			return
		end

		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not xpObject.Parent then
			return
		end

		local distance = (root.Position - damageHitbox.Position).Magnitude
		if distance <= 12 then
			local level = (_G.getPlayerLevel and _G.getPlayerLevel(player)) or 1
			local baseDamage = fibonacciXP(level)
			local damage = applyDamageBoost(player, baseDamage)
			takeDamage(player, damage, damageHitbox.Position)
		end
	end)
end

local function setupPunchDetection()
	local configuredEventName = script:GetAttribute("DamageEventName")
		or xpObject:GetAttribute("DamageEventName")
		or "PunchEvent"

	local existing = ReplicatedStorage:FindFirstChild(configuredEventName)
	if existing and existing:IsA("RemoteEvent") then
		bindPunchEvent(existing)
		return
	end

	if DEBUG_XP_OBJECT then
		print(("XPObjectTemplate waiting for damage remote %s on %s"):format(configuredEventName, xpObject:GetFullName()))
	end

	local childAddedConnection
	childAddedConnection = ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name ~= configuredEventName then
			return
		end
		if not child:IsA("RemoteEvent") then
			warn(("XPObjectTemplate expected RemoteEvent %s but found %s"):format(configuredEventName, child.ClassName))
			return
		end
		if childAddedConnection then
			childAddedConnection:Disconnect()
			childAddedConnection = nil
		end
		bindPunchEvent(child)
	end)
end

setupPunchDetection()

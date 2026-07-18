-- Fixed Destructible Box Script (basic)
-- Place this script inside the box you want to make destructible

local box = script.Parent
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local DEFAULT_BOX_COLOR = Color3.new(0.266667, 0.164706, 0.00392157)
-- Assign box:SetAttribute("BoxLevel", levelNumber) to pick a palette entry below.
local BOX_COLOR_BY_LEVEL = {
	[1] = Color3.fromRGB(255, 255, 255),     -- tutorial
	[3] = Color3.fromRGB(255, 210, 120),     -- amber
	[5] = Color3.fromRGB(255, 130, 130),     -- red
	[7] = Color3.fromRGB(255, 105, 180),     -- pink
	[9] = Color3.fromRGB(150, 120, 255),     -- violet
	[11] = Color3.fromRGB(95, 200, 255),     -- cyan
	[13] = Color3.fromRGB(100, 255, 190),    -- mint
	[15] = Color3.fromRGB(255, 255, 130),    -- yellow
	[17] = Color3.fromRGB(80, 80, 80),       -- charcoal
}

local DEFAULT_BOX_CONFIG = {
	Health = 100,
	Reward = 10,
}

-- Tuned per BoxLevel (mirrors progression doc).
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

local function getBoxLevel()
	local levelAttr = box:GetAttribute("BoxLevel") or script:GetAttribute("BoxLevel")
	if typeof(levelAttr) == "number" then
		return math.clamp(math.floor(levelAttr + 0.5), 1, 1000)
	end
	return nil
end

local function resolveBoxColor(level)
	if level and BOX_COLOR_BY_LEVEL[level] then
		return BOX_COLOR_BY_LEVEL[level]
	end
	return DEFAULT_BOX_COLOR
end

local BOX_LEVEL = getBoxLevel()
pcall(function()
	box.Color = resolveBoxColor(BOX_LEVEL)
end)

local ACTIVE_BOX_CONFIG = (BOX_LEVEL and BOX_LEVEL_CONFIG[BOX_LEVEL]) or DEFAULT_BOX_CONFIG
local MAX_HEALTH = ACTIVE_BOX_CONFIG.Health or DEFAULT_BOX_CONFIG.Health
local BOX_REWARD_VALUE = ACTIVE_BOX_CONFIG.Reward or DEFAULT_BOX_CONFIG.Reward

-- Initialize box health
local currentHealth = MAX_HEALTH

-- Fibonacci-based XP/Damage scaling
-- Level 1 = 10, Level 2 = 20, Level 3 = 30, Level 4 = 50, etc.
local function fibonacciXP(level)
	if level <= 1 then
		return 10
	elseif level == 2 then
		return 20
	end
	local prev1, prev2 = 20, 10
	local current = 0
	for i = 3, level do
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

	-- Primary attribute placed by the PetInventory system
	local attrMultiplier = toPositiveNumber(player:GetAttribute("PetDamageBoost"))
	if attrMultiplier then
		return attrMultiplier
	end

	-- Support legacy/alternate storage via PetDamageBoostStats attribute or Value object
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
				if child:IsA("NumberValue") then
					table.insert(candidates, child)
				end
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

-- Create destruction VFX
local function createDestroyVFX()
	local explosion = Instance.new("Explosion")
	explosion.Position = box.Position
	explosion.BlastRadius = 10
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	for i = 1, 8 do
		local debris = Instance.new("Part")
		debris.Size = Vector3.new(0.5, 0.5, 0.5)
		debris.Material = box.Material
		debris.Color = box.Color
		debris.Position = box.Position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		debris.Velocity = Vector3.new(
			math.random(-10, 10),
			math.random(5, 15),
			math.random(-10, 10)
		)
		debris.AssemblyAngularVelocity = Vector3.new(
			math.random(-10, 10),
			math.random(-10, 10),
			math.random(-10, 10)
		)
		debris.Parent = workspace
		Debris:AddItem(debris, 5)
	end
end

-- Destroy the box
local function destroyBox(player)
	print("🎯 DESTROYING BOX - Called by player:", player.Name)

	if not box.Parent then
		print("Box already destroyed, aborting")
		return
	end

	-- Store box properties for respawning
	local boxRotation = box.CFrame
	local boxSize = box.Size
	local boxMaterial = box.Material
	local boxParent = box.Parent

	-- Play destroy sound
	local destroySound = box:FindFirstChild("DestroySound")
	if destroySound then
		destroySound:Play()
	end

	-- Create destruction VFX
	createDestroyVFX()

	-- Determine XP based on player level
	local level = player:FindFirstChild("Level") and player.Level.Value or 1
	local XP_REWARD = BOX_REWARD_VALUE
	print("📈 Player " .. player.Name .. " is Level " .. level .. ", awarding " .. XP_REWARD .. " XP")

	-- Give XP to player
	if _G.addXP and type(_G.addXP) == "function" then
		local success, err = pcall(function()
			_G.addXP(player, XP_REWARD)
		end)
		if success then
			print("🎉 Successfully gave XP to " .. player.Name)
		else
			warn("❌ Error giving XP:", err)
		end
	else
		local giveXPEvent = ReplicatedStorage:FindFirstChild("GiveXP")
		if giveXPEvent then
			giveXPEvent:FireServer(XP_REWARD)
		else
			warn("❌ No XP system found")
		end
	end

	-- Give cash to player (matches XP reward)
	local CASH_REWARD = XP_REWARD
	if _G.addPlayerCash and type(_G.addPlayerCash) == "function" then
		local successCash, errCash = pcall(function()
			_G.addPlayerCash(player, CASH_REWARD, "BoxReward")
		end)
		if successCash then
			print("Gave $" .. CASH_REWARD .. " to " .. player.Name .. " for destroying the box")
		else
			warn("Error giving cash:", errCash)
		end
	else
		warn("No cash system found")
	end

	-- Destroy the box
	box:Destroy()

	-- Respawn the box after 15 seconds
	task.wait(15)

	local newBox = Instance.new("Part")
	newBox.Name = "Box"
	newBox.Size = boxSize
	newBox.Material = boxMaterial
	newBox.Color = resolveBoxColor(BOX_LEVEL)
	newBox.CFrame = boxRotation
	newBox.Anchored = true
	if BOX_LEVEL then
		newBox:SetAttribute("BoxLevel", BOX_LEVEL)
	end
	newBox.Parent = boxParent

	local newScript = script:Clone()
	newScript.Parent = newBox
	print("Box Respawned Successfully " .. player.Name)
end


-- Create BillboardGui for health bar
local function createHealthBar()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Size = UDim2.new(6, 0, 3, 0) -- Made taller for label
	billboardGui.StudsOffset = Vector3.new(0, 4, 0) -- Moved higher
	billboardGui.Parent = box

	-- Create "BOX" label
	local boxLabel = Instance.new("TextLabel")
	boxLabel.Name = "BoxLabel"
	boxLabel.Size = UDim2.new(1, 0, 0.4, 0) -- Takes up top 40% of space
	boxLabel.Position = UDim2.new(0, 0, 0, 0)
	boxLabel.BackgroundTransparency = 1
	boxLabel.Text = "Box"
	boxLabel.TextColor3 = Color3.new(1, 1, 1)
	boxLabel.TextStrokeTransparency = 0
	boxLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	boxLabel.TextScaled = true
	boxLabel.Font = Enum.Font.SourceSansBold
	boxLabel.ZIndex = 10
	boxLabel.Parent = billboardGui

	-- Background frame for health bar
	local bgFrame = Instance.new("Frame")
	bgFrame.Size = UDim2.new(1, 0, 0.3, 0) -- Made smaller to fit label
	bgFrame.Position = UDim2.new(0, 0, 0.4, 0) -- Positioned below label
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboardGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bgFrame

	-- Health bar background
	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, -8, 1, -8) -- Larger padding
	healthBg.Position = UDim2.new(0, 4, 0, 4)
	healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = bgFrame

	-- Add rounded corners to background
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = healthBg

	-- Health bar fill
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthFill"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	-- Add rounded corners to health bar
	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 6)
	healthCorner.Parent = healthBar

	-- Health text
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

-- Create sound effects with WORKING sound IDs
local function createSounds()
	local hitSound = Instance.new("Sound")
	hitSound.Name = "HitSound"
	hitSound.SoundId = "rbxassetid://566593606" -- Working punch/hit sound
	hitSound.Volume = 0.5
	hitSound.Parent = box

	local destroySound = Instance.new("Sound")
	destroySound.Name = "DestroySound" 
	destroySound.SoundId = "rbxassetid://566593606" -- Same sound but lower pitch
	destroySound.Volume = 0.8
	destroySound.Pitch = 0.6 -- Lower pitch for destroy effect
	destroySound.Parent = box

	-- Test load the sounds
	local success1, err1 = pcall(function() hitSound:Load() end)
	local success2, err2 = pcall(function() destroySound:Load() end)

	if not success1 then
		warn("⚠️ Failed to load hit sound:", err1)
	else
		print("✅ Hit sound loaded successfully")
	end

	if not success2 then
		warn("⚠️ Failed to load destroy sound:", err2)
	else
		print("✅ Destroy sound loaded successfully")
	end

	return hitSound, destroySound
end

-- Create VFX effects
local function createHitVFX()
	-- Create a simple particle effect
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0, 0)
	attachment.Parent = box

	-- Hit particles
	local particles = Instance.new("ParticleEmitter")
	particles.Enabled = false
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.new(1, 0.5, 0)) -- Orange
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

-- Update health bar
local function updateHealthBar(healthBar, healthText)
	local healthPercentage = currentHealth / MAX_HEALTH

	-- Change color based on health
	local color
	if healthPercentage > 0.6 then
		color = Color3.new(0, 1, 0) -- Green
	elseif healthPercentage > 0.3 then
		color = Color3.new(1, 1, 0) -- Yellow
	else
		color = Color3.new(1, 0, 0) -- Red
	end

	-- Tween health bar
	local tween = TweenService:Create(
		healthBar,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{
			Size = UDim2.new(healthPercentage, 0, 1, 0),
			BackgroundColor3 = color
		}
	)
	tween:Play()

	-- Update text
	healthText.Text = currentHealth .. "/" .. MAX_HEALTH
end

-- Handle taking damage
local function takeDamage(player, damage, hitPosition)
	if currentHealth <= 0 then return end
	currentHealth = math.max(0, currentHealth - damage)

	-- 🆕 ADD THIS LINE: Show damage number
	if _G.showDamageNumber then
		_G.showDamageNumber(player, damage, hitPosition or box.Position)
	end

	local hitSound = box:FindFirstChild("HitSound")
	if hitSound then hitSound:Play() end

	local attachment = box:FindFirstChild("Attachment")
	if attachment and attachment:FindFirstChild("ParticleEmitter") then
		attachment.ParticleEmitter:Emit(20)
	end

	local healthBar = box:FindFirstChild("HealthBar")
	if healthBar then
		local bgFrame = healthBar:FindFirstChild("Frame")
		if bgFrame then
			local healthBg = bgFrame:FindFirstChild("Frame")
			if healthBg then
				local healthFill = healthBg:FindFirstChild("HealthFill")
				local healthText = bgFrame:FindFirstChild("TextLabel")
				if healthFill and healthText then
					updateHealthBar(healthFill, healthText)
				end
			end
		end
	end

	if currentHealth <= 0 then
		destroyBox(player)
	end
end

local function setupPunchDetection()
	local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent", 10)
	if punchEvent then
		punchEvent.OnServerEvent:Connect(function(player)
			if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and box.Parent then
				local playerPos = player.Character.HumanoidRootPart.Position
				local distance = (playerPos - box.Position).Magnitude
				if distance <= 12 then
					local level = (_G.getPlayerLevel and _G.getPlayerLevel(player)) or 1
					local baseDamage = fibonacciXP(level)
					local damage = applyDamageBoost(player, baseDamage)
					print("👊 " .. player.Name .. " dealt " .. damage .. " damage at Level " .. level)
					takeDamage(player, damage, box.Position)
				end
			end
		end)
	end
end

local function initializeBox()
	local healthBar, healthText = createHealthBar()
	createSounds()
	createHitVFX()
	setupPunchDetection()
end

initializeBox()

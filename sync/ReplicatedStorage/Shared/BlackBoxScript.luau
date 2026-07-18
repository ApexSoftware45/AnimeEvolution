-- Black variant of the destructible box script.
-- Differences vs BoxScriptTemplate:
--   * MAX_HEALTH = 500
--   * XP/Cash rewards = 50
--   * Respawn color = pure black

local box = script.Parent
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local MAX_HEALTH = 500
local REWARD_VALUE = 50

local currentHealth = MAX_HEALTH

local function fibonacciXP(level)
	if level <= 1 then
		return REWARD_VALUE
	elseif level == 2 then
		return REWARD_VALUE * 2
	end
	local prev1, prev2 = REWARD_VALUE * 2, REWARD_VALUE
	local current = 0
	for _ = 3, level do
		current = prev1 + prev2
		prev2 = prev1
		prev1 = current
	end
	return current
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

local function createDestroyVFX()
	local explosion = Instance.new("Explosion")
	explosion.Position = box.Position
	explosion.BlastRadius = 10
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	for _ = 1, 8 do
		local debrisPart = Instance.new("Part")
		debrisPart.Size = Vector3.new(0.5, 0.5, 0.5)
		debrisPart.Material = box.Material
		debrisPart.Color = Color3.new(0, 0, 0)
		debrisPart.Position = box.Position + Vector3.new(
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

local function destroyBox(player)
	if not box.Parent then
		return
	end

	local boxRotation = box.CFrame
	local boxSize = box.Size
	local boxMaterial = box.Material
	local boxParent = box.Parent

	local destroySound = box:FindFirstChild("DestroySound")
	if destroySound then
		destroySound:Play()
	end

	createDestroyVFX()

	local level = player:FindFirstChild("Level") and player.Level.Value or 1
	local XP_REWARD = REWARD_VALUE

	if _G.addXP and type(_G.addXP) == "function" then
		pcall(function()
			_G.addXP(player, XP_REWARD)
		end)
	else
		local giveXPEvent = ReplicatedStorage:FindFirstChild("GiveXP")
		if giveXPEvent then
			giveXPEvent:FireServer(XP_REWARD)
		end
	end

	local CASH_REWARD = REWARD_VALUE
	if _G.addPlayerCash and type(_G.addPlayerCash) == "function" then
		pcall(function()
			_G.addPlayerCash(player, CASH_REWARD, "BlackBoxReward")
		end)
	end

	box:Destroy()
	task.wait(15)

	local newBox = Instance.new("Part")
	newBox.Name = "BlackBox"
	newBox.Size = boxSize
	newBox.Material = boxMaterial
	newBox.Color = Color3.new(0, 0, 0)
	newBox.CFrame = boxRotation
	newBox.Anchored = true
	newBox.Parent = boxParent

	local newScript = script:Clone()
	newScript.Parent = newBox
end

local function createHealthBar()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Size = UDim2.new(6, 0, 3, 0)
	billboardGui.StudsOffset = Vector3.new(0, 4, 0)
	billboardGui.Parent = box

	local boxLabel = Instance.new("TextLabel")
	boxLabel.Name = "BoxLabel"
	boxLabel.Size = UDim2.new(1, 0, 0.4, 0)
	boxLabel.Position = UDim2.new(0, 0, 0, 0)
	boxLabel.BackgroundTransparency = 1
	boxLabel.Text = "Black Box"
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
	hitSound.Parent = box

	local destroySound = Instance.new("Sound")
	destroySound.Name = "DestroySound"
	destroySound.SoundId = "rbxassetid://566593606"
	destroySound.Volume = 0.8
	destroySound.Pitch = 0.5
	destroySound.Parent = box

	pcall(function()
		hitSound:Load()
		destroySound:Load()
	end)

	return hitSound, destroySound
end

local function createHitVFX()
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0, 0)
	attachment.Parent = box

	local particles = Instance.new("ParticleEmitter")
	particles.Enabled = false
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.new(0.1, 0.1, 0.1))
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

local function updateHealthBar(healthBar, healthText)
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
		healthBar,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{
			Size = UDim2.new(healthPercentage, 0, 1, 0),
			BackgroundColor3 = color,
		}
	)
	tween:Play()

	healthText.Text = currentHealth .. "/" .. MAX_HEALTH
end

local function takeDamage(player, damage, hitPosition)
	if currentHealth <= 0 then return end
	currentHealth = math.max(0, currentHealth - damage)

	if _G.showDamageNumber then
		_G.showDamageNumber(player, damage, hitPosition or box.Position)
	end

	local hitSound = box:FindFirstChild("HitSound")
	if hitSound then hitSound:Play() end

	local attachment = box:FindFirstChild("Attachment")
	if attachment and attachment:FindFirstChild("ParticleEmitter") then
		attachment.ParticleEmitter:Emit(20)
	end

	local healthBarGui = box:FindFirstChild("HealthBar")
	if healthBarGui then
		local bgFrame = healthBarGui:FindFirstChild("Frame")
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
					takeDamage(player, damage, box.Position)
				end
			end
		end)
	end
end

local function initializeBox()
	createHealthBar()
	createSounds()
	createHitVFX()
	setupPunchDetection()
end

initializeBox()


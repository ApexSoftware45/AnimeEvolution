-- Health System with Level Scaling and Regeneration
-- Syncs via Rojo to ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local BASE_HEALTH = 100
local HEALTH_PER_LEVEL = 20 -- Gain 20 HP per level
local REGEN_DELAY = 4 -- Seconds after taking damage before regen starts
local REGEN_PERCENT_PER_SECOND = 10 -- Percent of max health per second

local HEALTHBAR_FULL_HEALTH_HIDE_DELAY = 3 -- Seconds after reaching full health
local PLAYER_HEALTH_BAR_NAME = "PlayerHealthBar"
local PLAYER_HEALTH_BAR_SIZE = UDim2.new(6, 0, 3, 0)
local PLAYER_HEALTH_BAR_OFFSET = Vector3.new(0, 4, 0)

-- Create RemoteEvents
local healthChangedEvent = ReplicatedStorage:FindFirstChild("HealthChanged")
if not healthChangedEvent then
	healthChangedEvent = Instance.new("RemoteEvent")
	healthChangedEvent.Name = "HealthChanged"
	healthChangedEvent.Parent = ReplicatedStorage
	print("✅ Created HealthChanged RemoteEvent")
end

-- Player data storage
local playerHealthData = {}
local playerUiState = {}

local HEALTH_BOOST_ATTRIBUTE = "PetHealthBoost"

local function getPetHealthMultiplier(player: Player): number
	local boost = player:GetAttribute(HEALTH_BOOST_ATTRIBUTE)
	if typeof(boost) == "number" and boost > 0 then
		return boost
	end
	return 1
end

local function getUiState(player)
	local state = playerUiState[player.UserId]
	if not state then
		state = {}
		playerUiState[player.UserId] = state
	end
	return state
end

local function clearBillboard(state)
	if not state then return end

	if state.activeTween then
		state.activeTween:Cancel()
		state.activeTween = nil
	end

	if state.billboard then
		state.billboard:Destroy()
	end

	state.billboard = nil
	state.healthFill = nil
	state.healthText = nil
	state.hideToken = nil
end

local function updateHealthBillboardVisuals(player)
	local data = playerHealthData[player.UserId]
	local state = playerUiState[player.UserId]
	if not data or not state or not state.healthFill or not state.healthText then
		return
	end

	local maxHealth = math.max(1, data.maxHealth or BASE_HEALTH)
	local percent = math.clamp((data.currentHealth or 0) / maxHealth, 0, 1)

	local barColor = Color3.new(0, 1, 0)
	if percent <= 0.3 then
		barColor = Color3.new(1, 0, 0)
	elseif percent <= 0.6 then
		barColor = Color3.new(1, 1, 0)
	end

	if state.activeTween then
		state.activeTween:Cancel()
	end

	state.activeTween = TweenService:Create(
		state.healthFill,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(percent, 0, 1, 0),
			BackgroundColor3 = barColor
		}
	)
	state.activeTween:Play()

	state.healthText.Text = string.format("%d/%d", math.floor(data.currentHealth + 0.5), math.floor(maxHealth + 0.5))
end

local function createPlayerHealthBillboard(player, character)
	local state = getUiState(player)
	clearBillboard(state)

	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = character:WaitForChild("HumanoidRootPart", 5)
	end
	if not rootPart then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = PLAYER_HEALTH_BAR_NAME
	billboard.Size = PLAYER_HEALTH_BAR_SIZE
	billboard.StudsOffset = PLAYER_HEALTH_BAR_OFFSET
	billboard.Enabled = false
	billboard.MaxDistance = 150
	billboard.Adornee = rootPart
	billboard.Parent = rootPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName or player.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.ZIndex = 10
	nameLabel.Parent = billboard

	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Frame"
	bgFrame.Size = UDim2.new(1, 0, 0.3, 0)
	bgFrame.Position = UDim2.new(0, 0, 0.4, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BackgroundTransparency = 0.35
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = bgFrame

	local healthBg = Instance.new("Frame")
	healthBg.Name = "Frame"
	healthBg.Size = UDim2.new(1, -8, 1, -8)
	healthBg.Position = UDim2.new(0, 4, 0, 4)
	healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = bgFrame

	local healthBgCorner = Instance.new("UICorner")
	healthBgCorner.CornerRadius = UDim.new(0, 6)
	healthBgCorner.Parent = healthBg

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg

	local healthFillCorner = Instance.new("UICorner")
	healthFillCorner.CornerRadius = UDim.new(0, 6)
	healthFillCorner.Parent = healthFill

	local healthText = Instance.new("TextLabel")
	healthText.Name = "TextLabel"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = ""
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextStrokeTransparency = 0
	healthText.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.SourceSansBold
	healthText.ZIndex = 10
	healthText.Parent = bgFrame

	state.billboard = billboard
	state.healthFill = healthFill
	state.healthText = healthText

	updateHealthBillboardVisuals(player)
end

local function ensureBillboardConnections(player)
	local state = getUiState(player)

	if state.characterAddedConnection then
		state.characterAddedConnection:Disconnect()
	end
	if state.characterRemovingConnection then
		state.characterRemovingConnection:Disconnect()
	end

	state.characterAddedConnection = player.CharacterAdded:Connect(function(character)
		createPlayerHealthBillboard(player, character)

		local data = playerHealthData[player.UserId]
		if data then
			data.currentHealth = data.maxHealth
			player:SetAttribute("CurrentHealth", data.maxHealth)
			healthChangedEvent:FireClient(player, data.maxHealth, data.maxHealth)
			updateHealthBillboardVisuals(player)
			data.fullHealthSince = tick()
			data.isRegenerating = false
		end
	end)

	state.characterRemovingConnection = player.CharacterRemoving:Connect(function()
		local uiState = getUiState(player)
		if uiState.billboard then
			uiState.billboard.Enabled = false
		end
	end)

	if player.Character then
		createPlayerHealthBillboard(player, player.Character)

		local data = playerHealthData[player.UserId]
		if data then
			data.currentHealth = data.maxHealth
			player:SetAttribute("CurrentHealth", data.maxHealth)
			healthChangedEvent:FireClient(player, data.maxHealth, data.maxHealth)
			updateHealthBillboardVisuals(player)
			data.fullHealthSince = tick()
			data.isRegenerating = false
		end
	end
end

local function cleanupPlayerUi(player)
	local state = playerUiState[player.UserId]
	if not state then
		return
	end

	if state.characterAddedConnection then
		state.characterAddedConnection:Disconnect()
		state.characterAddedConnection = nil
	end

	if state.characterRemovingConnection then
		state.characterRemovingConnection:Disconnect()
		state.characterRemovingConnection = nil
	end

	clearBillboard(state)
	playerUiState[player.UserId] = nil
end
-- Calculate max health based on level
local function getMaxHealth(level)
	return BASE_HEALTH + (HEALTH_PER_LEVEL * (level - 1))
end

-- Initialize player health
local function initializePlayerHealth(player)
	local level = player:GetAttribute("Level") or 1
	local baseMaxHealth = getMaxHealth(level)
	local multiplier = getPetHealthMultiplier(player)
	local maxHealth = math.max(1, math.floor(baseMaxHealth * multiplier + 0.5))

	local existing = playerHealthData[player.UserId]
	if existing and existing.boostConnection then
		existing.boostConnection:Disconnect()
	end

	local data = {
		currentHealth = maxHealth,
		maxHealth = maxHealth,
		lastDamageTime = 0,
		isRegenerating = false,
		fullHealthSince = tick(),
		boostConnection = nil,
	}

	data.boostConnection = player:GetAttributeChangedSignal(HEALTH_BOOST_ATTRIBUTE):Connect(function()
		updateMaxHealth(player)
	end)

	playerHealthData[player.UserId] = data

	ensureBillboardConnections(player)
	
	-- Set attributes for client to read
	player:SetAttribute("CurrentHealth", maxHealth)
	player:SetAttribute("MaxHealth", maxHealth)
	
	-- Send initial data to client
	healthChangedEvent:FireClient(player, maxHealth, maxHealth)

	task.defer(function()
		updateHealthBillboardVisuals(player)
	end)
	
	print("💚 Initialized health for", player.Name, "- Level", level, "HP:", maxHealth)
end

-- Update max health when level changes
local function updateMaxHealth(player)
	local level = player:GetAttribute("Level") or 1
	local data = playerHealthData[player.UserId]
	if not data then return end

	local oldMaxHealth = data.maxHealth
	local baseMaxHealth = getMaxHealth(level)
	local multiplier = getPetHealthMultiplier(player)
	local newMaxHealth = math.max(1, math.floor(baseMaxHealth * multiplier + 0.5))

	local healthPercent = 0
	if oldMaxHealth > 0 then
		healthPercent = data.currentHealth / oldMaxHealth
	end

	data.maxHealth = newMaxHealth
	data.currentHealth = math.clamp(math.floor(newMaxHealth * healthPercent + 0.5), 0, newMaxHealth)

	player:SetAttribute("MaxHealth", newMaxHealth)
	player:SetAttribute("CurrentHealth", data.currentHealth)

	healthChangedEvent:FireClient(player, data.currentHealth, newMaxHealth)
	updateHealthBillboardVisuals(player)

	if data.currentHealth >= data.maxHealth then
		data.fullHealthSince = data.fullHealthSince or tick()
	else
		data.fullHealthSince = nil
	end

	print("[HealthSystem]", player.Name, "leveled up! Health:", oldMaxHealth, "->", newMaxHealth)
end

-- Damage player
local function damagePlayer(player, amount)
	local data = playerHealthData[player.UserId]
	if not data then return false end

	local now = tick()

	data.currentHealth = math.max(0, data.currentHealth - amount)
	data.lastDamageTime = now
	data.isRegenerating = false
	data.fullHealthSince = nil

	player:SetAttribute("CurrentHealth", data.currentHealth)

	healthChangedEvent:FireClient(player, data.currentHealth, data.maxHealth)
	updateHealthBillboardVisuals(player)

	local state = playerUiState[player.UserId]
	if state and state.billboard then
		state.billboard.Enabled = true
	end

	print("dY'\"", player.Name, "took", amount, "damage! Health:", data.currentHealth .. "/" .. data.maxHealth)

	if data.currentHealth <= 0 then
		data.currentHealth = 0
		player:SetAttribute("CurrentHealth", 0)
		healthChangedEvent:FireClient(player, 0, data.maxHealth)
		updateHealthBillboardVisuals(player)

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(humanoid.Health)
		end

		print("dY'?", player.Name, "died! Respawning with full health...")
		return true
	end

	return false
end

-- Heal player
local function healPlayer(player, amount)
	local data = playerHealthData[player.UserId]
	if not data then return end
	
	local oldHealth = data.currentHealth
	data.currentHealth = math.min(data.maxHealth, data.currentHealth + amount)
	
	if oldHealth ~= data.currentHealth then
		player:SetAttribute("CurrentHealth", data.currentHealth)
		healthChangedEvent:FireClient(player, data.currentHealth, data.maxHealth)
		updateHealthBillboardVisuals(player)

		if data.currentHealth >= data.maxHealth then
			data.fullHealthSince = data.fullHealthSince or tick()
			data.isRegenerating = false
		else
			data.fullHealthSince = nil
		end
	end
end

-- Regeneration loop
RunService.Heartbeat:Connect(function()
	local now = tick()
	
	for userId, data in pairs(playerHealthData) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local humanoidAlive = humanoid and humanoid.Health > 0

			-- Check if should start regenerating
			if humanoidAlive and data.currentHealth < data.maxHealth then
				local timeSinceDamage = now - data.lastDamageTime
				
				if timeSinceDamage >= REGEN_DELAY then
					if not data.isRegenerating then
						data.isRegenerating = true
						print("💚", player.Name, "started regenerating health")
					end
				end
			else
				data.isRegenerating = false
			end
			
			-- Apply regeneration
			if humanoidAlive and data.isRegenerating then
				local regenAmount = (data.maxHealth * (REGEN_PERCENT_PER_SECOND / 100)) * (1/60) -- Per frame
				healPlayer(player, regenAmount)
			end

			local state = playerUiState[userId]
			if state and state.billboard then
				local shouldShow = data.currentHealth < data.maxHealth
				if not shouldShow then
					local fullSince = data.fullHealthSince
					if fullSince and (now - fullSince) < HEALTHBAR_FULL_HEALTH_HIDE_DELAY then
						shouldShow = true
					end
				end

				if state.billboard.Enabled ~= shouldShow then
					state.billboard.Enabled = shouldShow
				end
			end
		end
	end
end)

-- Listen for level changes
Players.PlayerAdded:Connect(function(player)
	-- Wait for level to be set
	task.wait(1)
	initializePlayerHealth(player)
	
	-- Listen for level changes
	player:GetAttributeChangedSignal("Level"):Connect(function()
		updateMaxHealth(player)
	end)
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	local data = playerHealthData[player.UserId]
	if data and data.boostConnection then
		data.boostConnection:Disconnect()
		data.boostConnection = nil
	end
	playerHealthData[player.UserId] = nil
	cleanupPlayerUi(player)
end)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1)
		initializePlayerHealth(player)
	end)
end

-- Global API for other scripts
_G.damagePlayer = damagePlayer
_G.healPlayer = healPlayer
_G.getPlayerHealth = function(player)
	local data = playerHealthData[player.UserId]
	return data and data.currentHealth or 0
end
_G.getPlayerMaxHealth = function(player)
	local data = playerHealthData[player.UserId]
	return data and data.maxHealth or 100
end

print("✅ Health System loaded!")
print("💚 Base Health:", BASE_HEALTH)
print("📈 Health per Level:", HEALTH_PER_LEVEL)
print("⏰ Regen Delay:", REGEN_DELAY, "seconds")
print("💉 Regen Rate:", REGEN_PERCENT_PER_SECOND .. "% per second")

-- Damage Numbers Display System
-- Shows floating damage numbers when hitting objects
-- Place in StarterPlayer > StarterPlayerScripts via Rojo

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Wait for the RemoteEvent
local showDamageEvent = ReplicatedStorage:WaitForChild("ShowDamageNumber", 10)

if not showDamageEvent then
	warn("⚠️ ShowDamageNumber RemoteEvent not found!")
	return
end

-- Configuration
local FLOAT_HEIGHT = 8 -- How high the number floats
local FLOAT_DURATION = 1.5 -- How long the animation lasts
local RANDOM_SPREAD = 2 -- Random X/Z offset range

-- Color coding based on damage amount
local function getDamageColor(damage)
	if damage >= 100 then
		return Color3.fromRGB(255, 0, 0) -- Red for high damage
	elseif damage >= 50 then
		return Color3.fromRGB(255, 165, 0) -- Orange for medium-high
	elseif damage >= 20 then
		return Color3.fromRGB(255, 255, 0) -- Yellow for medium
	else
		return Color3.fromRGB(255, 255, 255) -- White for low damage
	end
end

-- Create a floating damage number
local function createDamageNumber(damage, position)
	-- Create a part to attach the BillboardGui to
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position + Vector3.new(
		math.random(-RANDOM_SPREAD, RANDOM_SPREAD),
		2, -- Start slightly above hit point
		math.random(-RANDOM_SPREAD, RANDOM_SPREAD)
	)
	part.Parent = workspace
	
	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(5, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 0, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = part
	
	-- Create damage text
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Size = UDim2.new(1, 0, 1, 0)
	damageLabel.BackgroundTransparency = 1
	damageLabel.Text = "-" .. tostring(math.floor(damage))
	damageLabel.TextColor3 = getDamageColor(damage)
	damageLabel.TextStrokeTransparency = 0
	damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	damageLabel.TextScaled = true
	damageLabel.Font = Enum.Font.SourceSansBold
	damageLabel.TextTransparency = 0
	damageLabel.Parent = billboardGui
	
	-- Animation: Float up and scale
	local endPosition = part.Position + Vector3.new(0, FLOAT_HEIGHT, 0)
	
	-- Position tween (float upward)
	local positionTween = TweenService:Create(
		part,
		TweenInfo.new(FLOAT_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Position = endPosition}
	)
	
	-- Scale tween (start small, grow, then shrink)
	local scaleTween1 = TweenService:Create(
		damageLabel,
		TweenInfo.new(FLOAT_DURATION * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	
	-- Fade out tween
	local fadeTween = TweenService:Create(
		damageLabel,
		TweenInfo.new(FLOAT_DURATION * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1, TextStrokeTransparency = 1}
	)
	
	-- Play animations
	positionTween:Play()
	scaleTween1:Play()
	
	-- Start fade out halfway through
	task.delay(FLOAT_DURATION * 0.5, function()
		fadeTween:Play()
	end)
	
	-- Clean up after animation
	Debris:AddItem(part, FLOAT_DURATION + 0.5)
	
	print("💥 Damage number created:", damage, "at position:", position)
end

-- Listen for damage events from server
showDamageEvent.OnClientEvent:Connect(function(damage, position)
	if damage and position then
		createDamageNumber(damage, position)
	else
		warn("⚠️ Invalid damage number data received")
	end
end)

print("✅ Damage Numbers Display System loaded!")
print("🎯 Listening for damage events...")

-- Enhanced Loading Screen with Complex Animations (FIXED, no logo glow image)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LOADING_BACKGROUNDS = {
	"rbxassetid://100098520891703",
}

local LOADING_TIPS = {
	"💡 Higher levels unlock powerful transformations!",
	"🥊 Destroy boxes to gain XP and level up!",
	"⚡ Each character has unique abilities!",
	"🎁 Login daily for exclusive rewards!",
	"💎 Collect gems to unlock rare items!",
	"🐾 Pets provide combat bonuses!",
	"🔥 Combo attacks deal extra damage!",
	"🌟 Explore different zones for better rewards!",
	"⚔️ Team up with friends for boss battles!",
	"🏆 Complete quests for bonus XP!"
}

local activeConnections = {}
local isDestroying = false

local function cleanupConnections()
	for _, connection in pairs(activeConnections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	activeConnections = {}
end

local function createEnhancedLoadingScreen(message, duration)
	duration = duration or 5

	if playerGui:FindFirstChild("EnhancedLoadingScreen") then
		playerGui.EnhancedLoadingScreen:Destroy()
	end

	cleanupConnections()
	isDestroying = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EnhancedLoadingScreen"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local background = Instance.new("ImageLabel")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Image = LOADING_BACKGROUNDS[math.random(1, #LOADING_BACKGROUNDS)]
	background.ScaleType = Enum.ScaleType.Crop
	background.ImageTransparency = 0.3
	background.Parent = screenGui

	local backgroundOverlay = Instance.new("Frame")
	backgroundOverlay.Size = UDim2.new(1, 0, 1, 0)
	backgroundOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	backgroundOverlay.BackgroundTransparency = 0.5
	backgroundOverlay.Parent = screenGui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.1, 0.2)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0.2, 0.1, 0.3)),
		ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.1, 0.2))
	}
	gradient.Rotation = 45
	gradient.Parent = backgroundOverlay

	coroutine.wrap(function()
		local startTime = tick()
		while screenGui.Parent and not isDestroying and (tick() - startTime) < (duration + 2) do
			TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), {
				Rotation = gradient.Rotation + 360
			}):Play()
			task.wait(2)
		end
	end)()

	local particleContainer = Instance.new("Frame")
	particleContainer.Size = UDim2.new(1, 0, 1, 0)
	particleContainer.BackgroundTransparency = 1
	particleContainer.Parent = screenGui

	for i = 1, 30 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
		particle.BackgroundColor3 = Color3.fromHSV(math.random(), 0.5, 1)
		particle.BackgroundTransparency = math.random(3, 7) / 10
		particle.BorderSizePixel = 0
		particle.Parent = particleContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		local moveTime = math.random(3, 8)
		local moveInfo = TweenInfo.new(moveTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)

		TweenService:Create(particle, moveInfo, {
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			BackgroundTransparency = math.random(5, 9) / 10
		}):Play()
	end

	local logoContainer = Instance.new("Frame")
	logoContainer.Size = UDim2.new(0.5, 0, 0.2, 0)
	logoContainer.Position = UDim2.new(0.25, 0, 0.15, 0)
	logoContainer.BackgroundTransparency = 1
	logoContainer.Parent = screenGui

	-- 🔴 removed the glowEffect block and its animation 👇

	local gameTitle = Instance.new("TextLabel")
	gameTitle.Size = UDim2.new(1, 0, 0.6, 0)
	gameTitle.BackgroundTransparency = 1
	gameTitle.Text = "⚔️ Anime Evolution ⚔️"
	gameTitle.Font = Enum.Font.Fantasy
	gameTitle.TextScaled = true
	gameTitle.TextColor3 = Color3.new(1, 1, 1)
	gameTitle.TextStrokeTransparency = 0
	gameTitle.TextStrokeColor3 = Color3.new(0.2, 0, 0.5)
	gameTitle.Parent = logoContainer

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0.3, 0)
	subtitle.Position = UDim2.new(0, 0, 0.65, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "UNLEASH YOUR POWER"
	subtitle.Font = Enum.Font.SciFi
	subtitle.TextScaled = true
	subtitle.TextColor3 = Color3.new(0.9, 0.9, 1)
	subtitle.TextStrokeTransparency = 0.5
	subtitle.Parent = logoContainer

	local loadingMessage = Instance.new("TextLabel")
	loadingMessage.Size = UDim2.new(0.6, 0, 0.08, 0)
	loadingMessage.Position = UDim2.new(0.2, 0, 0.45, 0)
	loadingMessage.BackgroundTransparency = 1
	loadingMessage.Text = message or "Loading Game Assets"
	loadingMessage.Font = Enum.Font.SourceSans
	loadingMessage.TextScaled = true
	loadingMessage.TextColor3 = Color3.new(1, 1, 1)
	loadingMessage.TextStrokeTransparency = 0.5
	loadingMessage.Parent = screenGui

	coroutine.wrap(function()
		local dots = 0
		local startTime = tick()
		while screenGui.Parent and not isDestroying and (tick() - startTime) < (duration + 2) do
			dots = (dots % 3) + 1
			loadingMessage.Text = (message or "Loading Game Assets") .. string.rep(".", dots)
			task.wait(0.5)
		end
	end)()

	local progressContainer = Instance.new("Frame")
	progressContainer.Size = UDim2.new(0.5, 0, 0.06, 0)
	progressContainer.Position = UDim2.new(0.25, 0, 0.55, 0)
	progressContainer.BackgroundColor3 = Color3.new(0, 0, 0)
	progressContainer.BackgroundTransparency = 0.3
	progressContainer.BorderSizePixel = 0
	progressContainer.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = progressContainer

	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -4, 1, -4)
	progressBg.Position = UDim2.new(0, 2, 0, 2)
	progressBg.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = progressContainer

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 10)
	bgCorner.Parent = progressBg

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.new(0, 1, 0)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = progressBar

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0))
	}
	barGradient.Parent = progressBar

	local percentText = Instance.new("TextLabel")
	percentText.Size = UDim2.new(1, 0, 1, 0)
	percentText.BackgroundTransparency = 1
	percentText.Text = "0%"
	percentText.Font = Enum.Font.SourceSansBold
	percentText.TextScaled = true
	percentText.TextColor3 = Color3.new(1, 1, 1)
	percentText.TextStrokeTransparency = 0
	percentText.Parent = progressContainer

	local tipContainer = Instance.new("Frame")
	tipContainer.Size = UDim2.new(0.6, 0, 0.1, 0)
	tipContainer.Position = UDim2.new(0.2, 0, 0.7, 0)
	tipContainer.BackgroundColor3 = Color3.new(0, 0, 0)
	tipContainer.BackgroundTransparency = 0.7
	tipContainer.BorderSizePixel = 0
	tipContainer.Parent = screenGui

	local tipCorner = Instance.new("UICorner")
	tipCorner.CornerRadius = UDim.new(0, 8)
	tipCorner.Parent = tipContainer

	local tipText = Instance.new("TextLabel")
	tipText.Size = UDim2.new(0.95, 0, 0.8, 0)
	tipText.Position = UDim2.new(0.025, 0, 0.1, 0)
	tipText.BackgroundTransparency = 1
	tipText.Text = LOADING_TIPS[math.random(1, #LOADING_TIPS)]
	tipText.Font = Enum.Font.SourceSans
	tipText.TextScaled = true
	tipText.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	tipText.Parent = tipContainer

	local versionText = Instance.new("TextLabel")
	versionText.Size = UDim2.new(0.2, 0, 0.05, 0)
	versionText.Position = UDim2.new(0.02, 0, 0.93, 0)
	versionText.BackgroundTransparency = 1
	versionText.Text = "v1.0.0"
	versionText.Font = Enum.Font.SourceSans
	versionText.TextScaled = true
	versionText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	versionText.TextStrokeTransparency = 0.5
	versionText.Parent = screenGui

	coroutine.wrap(function()
		logoContainer.Position = UDim2.new(0.25, 0, -0.3, 0)
		TweenService:Create(logoContainer, TweenInfo.new(1, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.25, 0, 0.15, 0)
		}):Play()

		task.wait(0.5)

		local progressTween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Cubic), {
			Size = UDim2.new(1, 0, 1, 0)
		})
		progressTween:Play()

		local startTime = tick()
		local percentConnection = RunService.Heartbeat:Connect(function()
			if isDestroying then return end
			local elapsed = tick() - startTime
			local progress = math.min(elapsed / duration, 1)
			percentText.Text = math.floor(progress * 100) .. "%"
		end)
		table.insert(activeConnections, percentConnection)

		coroutine.wrap(function()
			local tipStartTime = tick()
			while screenGui.Parent and not isDestroying and (tick() - tipStartTime) < duration do
				task.wait(3)
				if tipText.Parent and not isDestroying then
					TweenService:Create(tipText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
					task.wait(0.3)
					if not isDestroying then
						tipText.Text = LOADING_TIPS[math.random(1, #LOADING_TIPS)]
						TweenService:Create(tipText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
					end
				end
			end
		end)()

		progressTween.Completed:Wait()
		task.wait(0.5)

		isDestroying = true
		cleanupConnections()

		for _, obj in pairs(screenGui:GetDescendants()) do
			if obj:IsA("Frame") then
				TweenService:Create(obj, TweenInfo.new(0.5), {
					BackgroundTransparency = 1
				}):Play()
			elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
				TweenService:Create(obj, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				TweenService:Create(obj, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					ImageTransparency = 1
				}):Play()
			end
		end

		task.wait(0.5)
		screenGui:Destroy()
	end)()
end

createEnhancedLoadingScreen("Initializing Epic Adventure", 4)
print("✅ Enhanced Loading Screen loaded (no logo glow)")

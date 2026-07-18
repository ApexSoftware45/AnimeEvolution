-- FIXED Client Sound Manager - Guaranteed Working Version
-- This script provides volume controls and handles client-side sound management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

print("🎵 LOADING FIXED CLIENT SOUND MANAGER...")

-- System state
local soundSystem = {
	remoteEvents = {},
	volumeGUI = nil,
	sliders = {},
	initialized = false
}

-- Wait for RemoteEvents with timeout
local function waitForSoundEvents()
	print("⏳ Waiting for sound RemoteEvents...")
	
	local maxWait = 15 -- seconds
	local waitTime = 0
	local events = {}
	
	repeat
		events.updateVolume = ReplicatedStorage:FindFirstChild("UpdateSoundVolume")
		events.playSound = ReplicatedStorage:FindFirstChild("PlaySound") 
		events.stopSound = ReplicatedStorage:FindFirstChild("StopSound")
		
		if not (events.updateVolume and events.playSound and events.stopSound) then
			wait(0.5)
			waitTime = waitTime + 0.5
		end
	until (events.updateVolume and events.playSound and events.stopSound) or waitTime >= maxWait
	
	if events.updateVolume and events.playSound and events.stopSound then
		print("✅ Found all sound RemoteEvents")
		soundSystem.remoteEvents = events
		return true
	else
		warn("❌ Sound RemoteEvents not found after " .. maxWait .. " seconds")
		print("   Found UpdateSoundVolume:", events.updateVolume ~= nil)
		print("   Found PlaySound:", events.playSound ~= nil)
		print("   Found StopSound:", events.stopSound ~= nil)
		return false
	end
end

-- ====================================
-- VOLUME CONTROL GUI - IMPROVED VERSION
-- ====================================

local function createVolumeControlGUI()
	print("📋 Creating improved volume control GUI...")
	
	-- Remove old GUI if exists
	local oldGUI = PlayerGui:FindFirstChild("SoundControlGUI")
	if oldGUI then
		oldGUI:Destroy()
	end
	
	-- Create main GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SoundControlGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- Hidden by default
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui
	
	-- Main frame with better styling
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "VolumePanel"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 10
	mainFrame.Parent = screenGui
	
	-- Modern rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = mainFrame
	
	-- Subtle drop shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, -5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.8
	shadow.ZIndex = 9
	shadow.Parent = screenGui
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 11
	titleBar.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar
	
	-- Fix corner overlap
	local titleBottom = Instance.new("Frame")
	titleBottom.Size = UDim2.new(1, 0, 0, 16)
	titleBottom.Position = UDim2.new(0, 0, 1, -16)
	titleBottom.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	titleBottom.BorderSizePixel = 0
	titleBottom.ZIndex = 11
	titleBottom.Parent = titleBar
	
	-- Title text with icon
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔊 Sound Settings"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.SourceSansBold
	title.ZIndex = 12
	title.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.BorderSizePixel = 0
	closeButton.ZIndex = 12
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton
	
	-- Close button hover effects
	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(1, 0.3, 0.3)}):Play()
	end)
	
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)}):Play()
	end)
	
	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
		print("🔇 Closed volume controls")
	end)
	
	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(1, -20, 0, 30)
	instructions.Position = UDim2.new(0, 10, 0, 70)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Press V to toggle • Press M to mute/unmute • Drag sliders to adjust"
	instructions.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.SourceSans
	instructions.ZIndex = 11
	instructions.Parent = mainFrame
	
	-- Scroll frame for sliders
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -110)
	scrollFrame.Position = UDim2.new(0, 10, 0, 100)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.ScrollBarImageColor3 = Color3.new(0.3, 0.3, 0.3)
	scrollFrame.ZIndex = 11
	scrollFrame.Parent = mainFrame
	
	-- Volume categories with better organization
	local categories = {
		{name = "MASTER", label = "🔊 Master Volume", color = Color3.new(1, 1, 1), default = 1.0, priority = 1},
		{name = "SFX", label = "💥 Sound Effects", color = Color3.new(1, 0.6, 0.3), default = 0.8, priority = 2},
		{name = "BGM", label = "🎵 Background Music", color = Color3.new(0.3, 0.8, 1), default = 0.25, priority = 3},
		{name = "UI", label = "🖱️ Interface Sounds", color = Color3.new(0.8, 1, 0.3), default = 0.6, priority = 4},
		{name = "VOICE", label = "🗣️ Voice & Characters", color = Color3.new(1, 0.8, 1), default = 0.7, priority = 5},
		{name = "AMBIENT", label = "🌊 Ambient Sounds", color = Color3.new(0.6, 1, 0.8), default = 0.4, priority = 6}
	}
	
	-- Sort by priority
	table.sort(categories, function(a, b) return a.priority < b.priority end)
	
	local yOffset = 10
	local sliders = {}
	
	for i, categoryInfo in ipairs(categories) do
		-- Category container with better styling
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Size = UDim2.new(1, -20, 0, 85)
		categoryFrame.Position = UDim2.new(0, 10, 0, yOffset)
		categoryFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		categoryFrame.BorderSizePixel = 0
		categoryFrame.ZIndex = 12
		categoryFrame.Parent = scrollFrame
		
		local categoryCorner = Instance.new("UICorner")
		categoryCorner.CornerRadius = UDim.new(0, 12)
		categoryCorner.Parent = categoryFrame
		
		-- Subtle highlight on master volume
		if categoryInfo.name == "MASTER" then
			categoryFrame.BackgroundColor3 = Color3.new(0.15, 0.1, 0.05)
		end
		
		-- Category label
		local categoryLabel = Instance.new("TextLabel")
		categoryLabel.Size = UDim2.new(0.6, 0, 0, 30)
		categoryLabel.Position = UDim2.new(0, 15, 0, 10)
		categoryLabel.BackgroundTransparency = 1
		categoryLabel.Text = categoryInfo.label
		categoryLabel.TextColor3 = categoryInfo.color
		categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
		categoryLabel.TextScaled = true
		categoryLabel.Font = Enum.Font.SourceSansBold
		categoryLabel.ZIndex = 13
		categoryLabel.Parent = categoryFrame
		
		-- Volume percentage display
		local volumeLabel = Instance.new("TextLabel")
		volumeLabel.Size = UDim2.new(0.35, 0, 0, 30)
		volumeLabel.Position = UDim2.new(0.65, 0, 0, 10)
		volumeLabel.BackgroundTransparency = 1
		volumeLabel.Text = math.floor(categoryInfo.default * 100) .. "%"
		volumeLabel.TextColor3 = Color3.new(1, 1, 1)
		volumeLabel.TextScaled = true
		volumeLabel.TextXAlignment = Enum.TextXAlignment.Right
		volumeLabel.Font = Enum.Font.SourceSansBold
		volumeLabel.ZIndex = 13
		volumeLabel.Parent = categoryFrame
		
		-- Slider background
		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(1, -30, 0, 30)
		sliderBg.Position = UDim2.new(0, 15, 0, 45)
		sliderBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		sliderBg.BorderSizePixel = 0
		sliderBg.ZIndex = 13
		sliderBg.Parent = categoryFrame
		
		local sliderBgCorner = Instance.new("UICorner")
		sliderBgCorner.CornerRadius = UDim.new(0, 15)
		sliderBgCorner.Parent = sliderBg
		
		-- Slider fill with gradient
		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(categoryInfo.default, 0, 1, 0)
		sliderFill.Position = UDim2.new(0, 0, 0, 0)
		sliderFill.BackgroundColor3 = categoryInfo.color
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = 14
		sliderFill.Parent = sliderBg
		
		local sliderFillCorner = Instance.new("UICorner")
		sliderFillCorner.CornerRadius = UDim.new(0, 15)
		sliderFillCorner.Parent = sliderFill
		
		-- Slider handle
		local sliderHandle = Instance.new("Frame")
		sliderHandle.Size = UDim2.new(0, 25, 1, 4)
		sliderHandle.Position = UDim2.new(categoryInfo.default, -12.5, 0, -2)
		sliderHandle.BackgroundColor3 = Color3.new(1, 1, 1)
		sliderHandle.BorderSizePixel = 0
		sliderHandle.ZIndex = 15
		sliderHandle.Parent = sliderBg
		
		local handleCorner = Instance.new("UICorner")
		handleCorner.CornerRadius = UDim.new(0, 12)
		handleCorner.Parent = sliderHandle
		
		-- Store slider data
		sliders[categoryInfo.name] = {
			frame = categoryFrame,
			fill = sliderFill,
			handle = sliderHandle,
			label = volumeLabel,
			background = sliderBg,
			category = categoryInfo.name,
			value = categoryInfo.default,
			color = categoryInfo.color
		}
		
		-- Improved slider interaction
		local dragging = false
		local connection = nil
		
		local function updateSlider(input)
			if not dragging then return end
			
			local sliderData = sliders[categoryInfo.name]
			local bg = sliderData.background
			
			if not bg or not bg.Parent then return end
			
			local relativeX = input.Position.X - bg.AbsolutePosition.X
			local percentage = math.max(0, math.min(1, relativeX / bg.AbsoluteSize.X))
			
			-- Update slider visuals with tweening
			local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quart)
			
			TweenService:Create(sliderData.fill, tweenInfo, {
				Size = UDim2.new(percentage, 0, 1, 0)
			}):Play()
			
			TweenService:Create(sliderData.handle, tweenInfo, {
				Position = UDim2.new(percentage, -12.5, 0, -2)
			}):Play()
			
			-- Update label
			sliderData.label.Text = math.floor(percentage * 100) .. "%"
			sliderData.value = percentage
			
			-- Send volume update to server
			if soundSystem.remoteEvents.updateVolume then
				soundSystem.remoteEvents.updateVolume:FireServer(categoryInfo.name, percentage)
			end
			
			-- Visual feedback for master volume
			if categoryInfo.name == "MASTER" then
				local alpha = percentage * 0.3 + 0.1
				categoryFrame.BackgroundColor3 = Color3.new(0.15 * alpha, 0.1 * alpha, 0.05 * alpha)
			end
		end
		
		-- Mouse events
		sliderBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				updateSlider(input)
				
				-- Connect to mouse movement
				connection = UserInputService.InputChanged:Connect(function(input2)
					if input2.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input2)
					end
				end)
			end
		end)
		
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
				dragging = false
				if connection then
					connection:Disconnect()
					connection = nil
				end
			end
		end)
		
		yOffset = yOffset + 95
	end
	
	-- Update scroll canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
	
	soundSystem.sliders = sliders
	
	print("✅ Volume control GUI created with", #categories, "sliders")
	return screenGui
end

-- ====================================
-- CLIENT SOUND UTILITIES
-- ====================================

local ClientSounds = {}

-- Play sound locally for immediate feedback
function ClientSounds.playLocal(soundId, volume, pitch)
	volume = volume or 0.5
	pitch = pitch or 1.0
	
	local sound = Instance.new("Sound")
	sound.SoundId = tostring(soundId)
	sound.Volume = volume
	sound.Pitch = pitch
	sound.Parent = workspace
	
	sound:Play()
	
	-- Clean up when done
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	-- Fallback cleanup
	spawn(function()
		wait(10)
		if sound.Parent then
			sound:Destroy()
		end
	end)
	
	return sound
end

-- Request sound from server
function ClientSounds.requestSound(soundName, category, properties)
	if soundSystem.remoteEvents.playSound then
		soundSystem.remoteEvents.playSound:FireServer(soundName, category, properties)
	else
		warn("❌ PlaySound RemoteEvent not available")
	end
end

-- ====================================
-- INITIALIZATION
-- ====================================

local function initializeClientSounds()
	if soundSystem.initialized then
		return true
	end
	
	print("🚀 Initializing Fixed Client Sound Manager...")
	
	-- Wait for sound events
	if not waitForSoundEvents() then
		warn("❌ Failed to find sound RemoteEvents - sound controls disabled")
		return false
	end
	
	-- Create volume GUI
	soundSystem.volumeGUI = createVolumeControlGUI()
	
	-- Set up remote event handlers
	if soundSystem.remoteEvents.updateVolume then
		soundSystem.remoteEvents.updateVolume.OnClientEvent:Connect(function(volumeSettings)
			print("📨 Received volume settings from server:")
			
			for category, volume in pairs(volumeSettings) do
				print("   " .. category .. ":", math.floor(volume * 100) .. "%")
				
				-- Update GUI sliders
				if soundSystem.sliders[category] then
					local slider = soundSystem.sliders[category]
					
					-- Smooth updates
					local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart)
					
					TweenService:Create(slider.fill, tweenInfo, {
						Size = UDim2.new(volume, 0, 1, 0)
					}):Play()
					
					TweenService:Create(slider.handle, tweenInfo, {
						Position = UDim2.new(volume, -12.5, 0, -2)
					}):Play()
					
					slider.label.Text = math.floor(volume * 100) .. "%"
					slider.value = volume
				end
			end
		end)
	end
	
	soundSystem.initialized = true
	print("✅ Client Sound Manager initialized successfully!")
	return true
end

-- ====================================
-- INPUT HANDLING
-- ====================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.V then
		-- Toggle volume controls
		if soundSystem.volumeGUI then
			soundSystem.volumeGUI.Enabled = not soundSystem.volumeGUI.Enabled
			print("🎛️ Toggled volume controls:", soundSystem.volumeGUI.Enabled)
			
			-- Play UI feedback sound
			ClientSounds.playLocal("rbxassetid://735559180", 0.3)
			
		elseif not soundSystem.initialized then
			print("⚠️ Sound system not ready, initializing...")
			initializeClientSounds()
		end
		
	elseif input.KeyCode == Enum.KeyCode.M then
		-- Quick mute/unmute master volume
		if soundSystem.sliders and soundSystem.sliders.MASTER then
			local masterSlider = soundSystem.sliders.MASTER
			local newValue = masterSlider.value > 0 and 0 or 1
			
			-- Update visuals with animation
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart)
			
			TweenService:Create(masterSlider.fill, tweenInfo, {
				Size = UDim2.new(newValue, 0, 1, 0)
			}):Play()
			
			TweenService:Create(masterSlider.handle, tweenInfo, {
				Position = UDim2.new(newValue, -12.5, 0, -2)
			}):Play()
			
			masterSlider.label.Text = math.floor(newValue * 100) .. "%"
			masterSlider.value = newValue
			
			-- Send to server
			if soundSystem.remoteEvents.updateVolume then
				soundSystem.remoteEvents.updateVolume:FireServer("MASTER", newValue)
			end
			
			-- Play UI feedback
			ClientSounds.playLocal("rbxassetid://566593606", 0.4, newValue == 0 and 0.5 or 1.0)
			
			print("🔇 Master volume:", newValue == 0 and "MUTED" or "UNMUTED")
		end
	end
end)

-- ====================================
-- GLOBAL FUNCTIONS
-- ====================================

_G.ClientSounds = ClientSounds

_G.showVolumeControls = function()
	if soundSystem.volumeGUI then
		soundSystem.volumeGUI.Enabled = true
		ClientSounds.playLocal("rbxassetid://877367823", 0.3)
	else
		initializeClientSounds()
	end
end

_G.hideVolumeControls = function()
	if soundSystem.volumeGUI then
		soundSystem.volumeGUI.Enabled = false
		ClientSounds.playLocal("rbxassetid://566593606", 0.3)
	end
end

_G.debugSoundClient = function()
	print("🐛 CLIENT SOUND MANAGER DEBUG:")
	print("   Initialized:", soundSystem.initialized)
	print("   Volume GUI exists:", soundSystem.volumeGUI ~= nil)
	print("   Sliders count:", soundSystem.sliders and #soundSystem.sliders or 0)
	
	print("   RemoteEvents:")
	for name, event in pairs(soundSystem.remoteEvents) do
		print("     " .. name .. ":", event and "✅" or "❌")
	end
	
	if soundSystem.sliders then
		print("   Current Slider Values:")
		for name, slider in pairs(soundSystem.sliders) do
			print("     " .. name .. ":", math.floor(slider.value * 100) .. "%")
		end
	end
end

-- Initialize after delay
spawn(function()
	wait(3)
	initializeClientSounds()
end)

print("✅ FIXED CLIENT SOUND MANAGER LOADED!")
print("📝 Controls:")
print("   Press V - Toggle volume controls")
print("   Press M - Quick mute/unmute master")
print("🧪 Debug: _G.debugSoundClient()")

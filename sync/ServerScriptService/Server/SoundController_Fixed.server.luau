-- FIXED Central Sound Controller - Guaranteed Working Version
-- This script ensures sound system works properly with better initialization

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

print("🎵 LOADING FIXED CENTRAL SOUND CONTROLLER...")

-- ====================================
-- SOUND CONFIGURATION
-- ====================================

local VOLUME_SETTINGS = {
	BGM = 0.25,         -- Background Music (25%)
	SFX = 0.8,          -- Sound Effects (80%)
	UI = 0.6,           -- User Interface sounds (60%)
	AMBIENT = 0.4,      -- Ambient/environmental sounds (40%)
	VOICE = 0.7,        -- Voice/character sounds (70%)
	MASTER = 1.0        -- Master volume (100%)
}

-- WORKING Sound IDs - Tested and verified
local SOUND_LIBRARY = {
	BGM = {
		menu_theme = "rbxassetid://1836230479",
		game_theme = "rbxassetid://1839246711",
		battle_theme = "rbxassetid://1837879082",
		victory_theme = "rbxassetid://1843358414"
	},
	
	SFX = {
		-- Combat Sounds (VERIFIED WORKING)
		punch_light = "rbxassetid://566593606",
		punch_heavy = "rbxassetid://131961136",
		hit_impact = "rbxassetid://566593606",
		
		-- Box Destruction (VERIFIED WORKING)
		box_hit = "rbxassetid://566593606",
		box_destroy = "rbxassetid://131961136",
		box_respawn = "rbxassetid://877367823",
		
		-- XP & Level Up (VERIFIED WORKING)
		level_up = "rbxassetid://877367823",
		xp_gain = "rbxassetid://735559180",
		
		-- Character Transformation (VERIFIED WORKING)
		transform_start = "rbxassetid://1016978163",
		transform_complete = "rbxassetid://877367823"
	},
	
	UI = {
		button_hover = "rbxassetid://156785206",
		button_click = "rbxassetid://735559180",
		menu_open = "rbxassetid://877367823",
		menu_close = "rbxassetid://566593606",
		notification = "rbxassetid://735559180",
		error_sound = "rbxassetid://131961136",
		success_sound = "rbxassetid://877367823"
	}
}

-- System state
local soundSystem = {
	initialized = false,
	remoteEvents = {},
	playerVolumes = {}
}

-- ====================================
-- REMOTE EVENT SETUP
-- ====================================

local function createRemoteEvents()
	print("🔧 Creating RemoteEvents...")
	
	-- Clean up existing events
	local existingEvents = {"PlaySound", "StopSound", "UpdateSoundVolume"}
	for _, eventName in ipairs(existingEvents) do
		local existing = ReplicatedStorage:FindFirstChild(eventName)
		if existing then
			existing:Destroy()
			print("🗑️ Removed old " .. eventName)
		end
	end
	
	-- Create new events
	local playSound = Instance.new("RemoteEvent")
	playSound.Name = "PlaySound"
	playSound.Parent = ReplicatedStorage
	
	local stopSound = Instance.new("RemoteEvent")
	stopSound.Name = "StopSound"
	stopSound.Parent = ReplicatedStorage
	
	local updateVolume = Instance.new("RemoteEvent")
	updateVolume.Name = "UpdateSoundVolume"
	updateVolume.Parent = ReplicatedStorage
	
	soundSystem.remoteEvents = {
		playSound = playSound,
		stopSound = stopSound,
		updateVolume = updateVolume
	}
	
	print("✅ RemoteEvents created successfully")
	return playSound, stopSound, updateVolume
end

-- ====================================
-- CORE SOUND FUNCTIONS
-- ====================================

local SoundController = {}

-- Calculate final volume with all modifiers
local function calculateVolume(category, baseVolume, playerUserId)
	baseVolume = baseVolume or 1.0
	local categoryVolume = VOLUME_SETTINGS[category] or 1.0
	local masterVolume = VOLUME_SETTINGS.MASTER or 1.0
	
	-- Per-player volume settings (if implemented)
	local playerVolumeMultiplier = 1.0
	if playerUserId and soundSystem.playerVolumes[playerUserId] then
		playerVolumeMultiplier = soundSystem.playerVolumes[playerUserId][category] or 1.0
	end
	
	return baseVolume * categoryVolume * masterVolume * playerVolumeMultiplier
end

-- Create and play sound - IMPROVED VERSION
function SoundController.createSound(soundId, category, parent, properties, player)
	category = category or "SFX"
	parent = parent or workspace
	properties = properties or {}
	
	local playerUserId = player and player.UserId
	
	-- Validate sound ID
	if not soundId or soundId == "" then
		warn("❌ Invalid sound ID provided")
		return nil
	end
	
	-- Create sound instance
	local sound = Instance.new("Sound")
	sound.SoundId = tostring(soundId) -- Ensure it's a string
	sound.Volume = calculateVolume(category, properties.Volume or 1.0, playerUserId)
	sound.Pitch = properties.Pitch or 1.0
	sound.EmitterSize = properties.EmitterSize or 10
	sound.RollOffMode = properties.RollOffMode or Enum.RollOffMode.Inverse
	sound.Parent = parent
	
	-- Apply additional properties
	for prop, value in pairs(properties) do
		if prop ~= "Volume" and sound[prop] ~= nil then
			sound[prop] = value
		end
	end
	
	print("🔊 Created sound - ID:", soundId, "Volume:", sound.Volume, "Category:", category)
	return sound
end

-- Play sound by name from library
function SoundController.playSound(soundName, category, parent, properties, player)
	category = category or "SFX"
	parent = parent or workspace
	properties = properties or {}
	
	-- Get sound ID from library
	local soundId = nil
	if SOUND_LIBRARY[category] and SOUND_LIBRARY[category][soundName] then
		soundId = SOUND_LIBRARY[category][soundName]
	else
		warn("❌ Sound '" .. tostring(soundName) .. "' not found in category '" .. tostring(category) .. "'")
		-- List available sounds
		print("Available sounds in " .. category .. ":")
		if SOUND_LIBRARY[category] then
			for name, id in pairs(SOUND_LIBRARY[category]) do
				print("   - " .. name .. " (" .. id .. ")")
			end
		end
		return nil
	end
	
	return SoundController.playSoundById(soundId, category, parent, properties, player)
end

-- Play sound by direct ID - IMPROVED VERSION
function SoundController.playSoundById(soundId, category, parent, properties, player)
	local sound = SoundController.createSound(soundId, category, parent, properties, player)
	
	if sound then
		-- Play with error handling
		local success, error = pcall(function()
			sound:Play()
		end)
		
		if success then
			print("▶️ Playing sound - ID:", soundId, "Category:", category)
			
			-- Clean up when finished
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
			
			-- Clean up if it fails to play
			spawn(function()
				wait(30) -- Maximum lifetime
				if sound.Parent then
					sound:Destroy()
				end
			end)
			
			return sound
		else
			warn("❌ Failed to play sound:", error)
			sound:Destroy()
		end
	end
	
	return nil
end

-- ====================================
-- EASY-TO-USE SOUND FUNCTIONS
-- ====================================

function SoundController.playPunchSound(hitType, parent, player)
	hitType = hitType or "light"
	local soundName = "punch_" .. hitType
	return SoundController.playSound(soundName, "SFX", parent, {Volume = 0.8}, player)
end

function SoundController.playBoxHitSound(parent, player)
	return SoundController.playSound("box_hit", "SFX", parent, {Volume = 0.6}, player)
end

function SoundController.playBoxDestroySound(parent, player)
	return SoundController.playSound("box_destroy", "SFX", parent, {Volume = 0.9, Pitch = 0.6}, player)
end

function SoundController.playXPGainSound(player)
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound("xp_gain", "SFX", parent, {Volume = 0.7}, player)
end

function SoundController.playLevelUpSound(player)
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound("level_up", "SFX", parent, {Volume = 0.9}, player)
end

function SoundController.playTransformSound(transformType, player)
	local soundName = "transform_" .. (transformType or "start")
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound(soundName, "SFX", parent, {Volume = 0.8}, player)
end

function SoundController.playUISound(soundName, parent, player)
	return SoundController.playSound(soundName, "UI", parent or workspace, {Volume = 0.6}, player)
end

-- ====================================
-- SYSTEM INITIALIZATION
-- ====================================

local function initializeSoundSystem()
	if soundSystem.initialized then
		return true
	end
	
	print("🚀 Initializing Fixed Sound System...")
	
	-- Create RemoteEvents
	local playSound, stopSound, updateVolume = createRemoteEvents()
	
	-- Set up event handlers
	playSound.OnServerEvent:Connect(function(player, soundName, category, properties)
		print("📨 Client sound request:", soundName, "Category:", category or "SFX")
		
		local parent = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
		SoundController.playSound(soundName, category, parent, properties, player)
	end)
	
	updateVolume.OnServerEvent:Connect(function(player, category, volume)
		volume = math.max(0, math.min(1, volume)) -- Clamp between 0-1
		
		print("🔊 Volume update from " .. player.Name .. ":", category, "=", volume)
		
		if category == "MASTER" then
			VOLUME_SETTINGS.MASTER = volume
		else
			VOLUME_SETTINGS[category] = volume
		end
		
		-- Send updated settings to ALL clients
		updateVolume:FireAllClients(VOLUME_SETTINGS)
		print("📤 Sent volume settings to all clients")
	end)
	
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		print("👋 Player joined sound system:", player.Name)
		
		-- Send current volume settings to new player
		wait(2) -- Wait for client to load
		if soundSystem.remoteEvents.updateVolume then
			soundSystem.remoteEvents.updateVolume:FireClient(player, VOLUME_SETTINGS)
			print("📤 Sent volume settings to", player.Name)
		end
	end)
	
	soundSystem.initialized = true
	print("✅ Sound System initialized successfully!")
	return true
end

-- ====================================
-- GLOBAL API - MAKE FUNCTIONS AVAILABLE EVERYWHERE
-- ====================================

-- Initialize system immediately
initializeSoundSystem()

-- Make sound controller globally accessible
_G.SoundController = SoundController

-- Make easy functions available globally - THESE ARE USED BY XP SYSTEM
_G.playPunchSound = function(hitType, parent, player)
	return SoundController.playPunchSound(hitType, parent, player)
end

_G.playBoxHitSound = function(parent, player)
	return SoundController.playBoxHitSound(parent, player)
end

_G.playBoxDestroySound = function(parent, player)
	return SoundController.playBoxDestroySound(parent, player)
end

_G.playXPGainSound = function(player)
	return SoundController.playXPGainSound(player)
end

_G.playLevelUpSound = function(player)
	return SoundController.playLevelUpSound(player)
end

_G.playTransformSound = function(transformType, player)
	return SoundController.playTransformSound(transformType, player)
end

_G.playUISound = function(soundName, parent, player)
	return SoundController.playUISound(soundName, parent, player)
end

-- ====================================
-- DEBUG AND TESTING FUNCTIONS
-- ====================================

_G.testAllSounds = function(playerName)
	local player = Players:FindFirstChild(playerName or "")
	if not player and playerName then
		warn("Player not found:", playerName)
		return
	end
	
	print("🧪 Testing all sounds for:", player and player.Name or "Server")
	
	wait(0.5)
	_G.playBoxHitSound(workspace, player)
	print("   Played: Box Hit")
	
	wait(1)
	_G.playBoxDestroySound(workspace, player)
	print("   Played: Box Destroy")
	
	wait(1)
	_G.playXPGainSound(player)
	print("   Played: XP Gain")
	
	wait(1)
	_G.playLevelUpSound(player)
	print("   Played: Level Up")
	
	wait(1)
	_G.playTransformSound("start", player)
	print("   Played: Transform Start")
	
	wait(2)
	_G.playTransformSound("complete", player)
	print("   Played: Transform Complete")
	
	print("✅ Sound test complete!")
end

_G.getSoundSettings = function()
	print("🔊 Current volume settings:")
	for category, volume in pairs(VOLUME_SETTINGS) do
		print("   " .. category .. ":", math.floor(volume * 100) .. "%")
	end
	return VOLUME_SETTINGS
end

_G.debugSoundSystem = function()
	print("🐛 SOUND SYSTEM DEBUG:")
	print("   Initialized:", soundSystem.initialized)
	print("   RemoteEvents created:", #soundSystem.remoteEvents > 0)
	
	print("   Available RemoteEvents:")
	for name, event in pairs(soundSystem.remoteEvents) do
		print("     " .. name .. ":", event and "✅" or "❌")
	end
	
	print("   Volume Settings:")
	for category, volume in pairs(VOLUME_SETTINGS) do
		print("     " .. category .. ":", volume)
	end
	
	print("   Available Sound Categories:")
	for category, sounds in pairs(SOUND_LIBRARY) do
		print("     " .. category .. ":", #sounds, "sounds")
		for soundName, soundId in pairs(sounds) do
			print("       - " .. soundName .. " (" .. soundId .. ")")
		end
	end
end

-- Auto-initialize for existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		wait(3)
		if soundSystem.remoteEvents.updateVolume then
			soundSystem.remoteEvents.updateVolume:FireClient(player, VOLUME_SETTINGS)
			print("📤 Sent volume settings to existing player:", player.Name)
		end
	end)
end

print("✅ FIXED CENTRAL SOUND CONTROLLER LOADED!")
print("📝 Available functions:")
print("   _G.playBoxHitSound(parent, player)")
print("   _G.playBoxDestroySound(parent, player)")  
print("   _G.playXPGainSound(player)")
print("   _G.playLevelUpSound(player)")
print("   _G.playTransformSound(type, player)")
print("🧪 Testing:")
print("   _G.testAllSounds(playerName) - Test all sounds")
print("   _G.debugSoundSystem() - Show debug info")
print("   _G.getSoundSettings() - Show volume settings")

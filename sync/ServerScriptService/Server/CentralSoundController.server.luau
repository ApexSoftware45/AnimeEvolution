-- FIXED Central Sound Controller - Working Sound IDs Only
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🎵 LOADING SOUND CONTROLLER (WORKING SOUNDS ONLY)...")

-- Volume settings
local VOLUME_SETTINGS = {
	BGM = 0.25,
	SFX = 0.8,
	UI = 0.6,
	AMBIENT = 0.4,
	VOICE = 0.7,
	MASTER = 1.0
}

-- ONLY WORKING SOUND IDs
local SOUND_LIBRARY = {
	SFX = {
		punch_light = "rbxassetid://566593606",
		punch_heavy = "rbxassetid://131961136",
		hit_impact = "rbxassetid://566593606",
		box_hit = "rbxassetid://566593606",
		box_destroy = "rbxassetid://131961136",
		box_respawn = "rbxassetid://877367823",
		level_up = "rbxassetid://877367823",
		xp_gain = "rbxassetid://131961136",  -- FIXED
		transform_start = "rbxassetid://566593606",  -- FIXED
		transform_complete = "rbxassetid://877367823"
	}
}

-- Create RemoteEvents
local function createRemoteEvents()
	for _, name in ipairs({"PlaySound", "StopSound", "UpdateSoundVolume"}) do
		local existing = ReplicatedStorage:FindFirstChild(name)
		if existing then existing:Destroy() end
	end
	
	local playSound = Instance.new("RemoteEvent")
	playSound.Name = "PlaySound"
	playSound.Parent = ReplicatedStorage
	
	local stopSound = Instance.new("RemoteEvent")
	stopSound.Name = "StopSound"
	stopSound.Parent = ReplicatedStorage
	
	local updateVolume = Instance.new("RemoteEvent")
	updateVolume.Name = "UpdateSoundVolume"
	updateVolume.Parent = ReplicatedStorage
	
	print("✅ RemoteEvents created")
	return playSound, stopSound, updateVolume
end

-- Sound controller
local SoundController = {}

function SoundController.playSound(soundId, category, parent, volume, player)
	category = category or "SFX"
	parent = parent or workspace
	volume = volume or 1.0
	
	local finalVolume = volume * (VOLUME_SETTINGS[category] or 1.0) * VOLUME_SETTINGS.MASTER
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = finalVolume
	sound.Parent = parent
	
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
	
	print("▶️ Playing:", soundId, "Volume:", finalVolume)
	return sound
end

-- Easy functions
_G.playBoxHitSound = function(parent, player)
	return SoundController.playSound(SOUND_LIBRARY.SFX.box_hit, "SFX", parent, 0.6, player)
end

_G.playBoxDestroySound = function(parent, player)
	return SoundController.playSound(SOUND_LIBRARY.SFX.box_destroy, "SFX", parent, 0.9, player)
end

_G.playXPGainSound = function(player)
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound(SOUND_LIBRARY.SFX.xp_gain, "SFX", parent, 0.7, player)
end

_G.playLevelUpSound = function(player)
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound(SOUND_LIBRARY.SFX.level_up, "SFX", parent, 0.9, player)
end

_G.playTransformSound = function(transformType, player)
	local soundId = transformType == "complete" and SOUND_LIBRARY.SFX.transform_complete or SOUND_LIBRARY.SFX.transform_start
	local parent = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace
	return SoundController.playSound(soundId, "SFX", parent, 0.8, player)
end

-- Initialize
local playSound, stopSound, updateVolume = createRemoteEvents()

updateVolume.OnServerEvent:Connect(function(player, category, volume)
	VOLUME_SETTINGS[category] = math.max(0, math.min(1, volume))
	updateVolume:FireAllClients(VOLUME_SETTINGS)
	print("🔊 Updated", category, "to", volume)
end)

print("✅ SOUND CONTROLLER LOADED (WORKING SOUNDS ONLY)!")
print("📝 Available: _G.playBoxHitSound, _G.playXPGainSound, _G.playLevelUpSound")

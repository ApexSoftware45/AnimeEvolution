-- CENTRAL SOUND CONTROLLER
-- Place this in ServerScriptService
-- Manages all game sounds without deprecated methods

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Sound configurations
local SOUNDS = {
    -- Combat sounds
    punch = {
        id = "rbxassetid://566593606",
        volume = 0.5,
        pitch = 1
    },
    boxHit = {
        id = "rbxassetid://566593606", 
        volume = 0.4,
        pitch = 1.2
    },
    boxDestroy = {
        id = "rbxassetid://566593606",
        volume = 0.7,
        pitch = 0.6
    },
    
    -- XP/Level sounds
    xpGain = {
        id = "rbxassetid://9125402735", -- Coin/pickup sound
        volume = 0.3,
        pitch = 1.2
    },
    levelUp = {
        id = "rbxassetid://9125527144", -- Achievement sound
        volume = 0.6,
        pitch = 1
    },
    
    -- Ability sounds
    kiBlast = {
        id = "rbxassetid://2101148847", -- Energy blast
        volume = 0.5,
        pitch = 1
    },
    kiCharge = {
        id = "rbxassetid://2101148764", -- Power up
        volume = 0.4,
        pitch = 1
    },
    auraActivate = {
        id = "rbxassetid://2101148764", -- Public aura power up
        volume = 0.5,
        pitch = 1
    },
    dash = {
        id = "rbxassetid://5943191430", -- Whoosh
        volume = 0.3,
        pitch = 1.3
    },
    flight = {
        id = "rbxassetid://142070127", -- Wind/flight
        volume = 0.2,
        pitch = 1,
        looped = true
    }
}

-- Sound pools for preventing spam
local soundPools = {}
local lastPlayTime = {}
local SOUND_COOLDOWN = 0.1 -- Minimum time between same sound

-- Initialize sound pools
local function initializeSoundPools()
    for soundName, config in pairs(SOUNDS) do
        soundPools[soundName] = {}
        lastPlayTime[soundName] = {}
        
        -- Pre-create sound instances
        for i = 1, 3 do
            local sound = Instance.new("Sound")
            sound.SoundId = config.id
            sound.Volume = config.volume
            sound.Pitch = config.pitch or 1
            sound.Looped = config.looped or false
            sound.Parent = SoundService
            
            table.insert(soundPools[soundName], {
                sound = sound,
                inUse = false
            })
        end
    end
    print("✅ Sound pools initialized")
end

-- Get available sound from pool
local function getSoundFromPool(soundName)
    if not soundPools[soundName] then
        warn("❌ Sound not found:", soundName)
        return nil
    end
    
    for _, poolItem in ipairs(soundPools[soundName]) do
        if not poolItem.inUse then
            poolItem.inUse = true
            
            -- Auto-release after sound finishes
            task.spawn(function()
                task.wait(poolItem.sound.TimeLength or 1)
                poolItem.inUse = false
            end)
            
            return poolItem.sound
        end
    end
    
    -- All sounds in use, create a temporary one
    local config = SOUNDS[soundName]
    local tempSound = Instance.new("Sound")
    tempSound.SoundId = config.id
    tempSound.Volume = config.volume
    tempSound.Pitch = config.pitch or 1
    tempSound.Parent = SoundService
    
    -- Clean up temp sound after use
    tempSound.Ended:Connect(function()
        tempSound:Destroy()
    end)
    
    return tempSound
end

-- Play sound at position
local function playSound3D(soundName, position, player)
    -- Check cooldown
    local now = tick()
    if lastPlayTime[soundName][player] and now - lastPlayTime[soundName][player] < SOUND_COOLDOWN then
        return -- Skip if played too recently
    end
    lastPlayTime[soundName][player] = now
    
	local soundTemplate = getSoundFromPool(soundName)
	if not soundTemplate then return end
	
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position
	part.Parent = workspace
	
	local sound = soundTemplate:Clone()
	sound.Parent = part
	sound:Play()
	
	local cleanupDelay = (sound.TimeLength and sound.TimeLength > 0) and (sound.TimeLength + 0.25) or 2
	Debris:AddItem(part, cleanupDelay)
	Debris:AddItem(sound, cleanupDelay)
	
	sound.Ended:Connect(function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

-- Play sound for specific player
local function playSoundForPlayer(soundName, player)
    local sound = getSoundFromPool(soundName)
    if not sound then return end
    
    sound:Play()
end

-- Global sound functions
_G.playPunchSound = function(position, player)
    playSound3D("punch", position, player)
end

_G.playBoxHitSound = function(box, player)
    if box and box:IsA("BasePart") then
        playSound3D("boxHit", box.Position, player)
    end
end

_G.playBoxDestroySound = function(box, player)
    if box and box:IsA("BasePart") then
        playSound3D("boxDestroy", box.Position, player)
    end
end

_G.playXPGainSound = function(player)
    playSoundForPlayer("xpGain", player)
end

_G.playLevelUpSound = function(player)
    playSoundForPlayer("levelUp", player)
    
    -- Extra effect for level up
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- Create visual effect with sound
            local attachment = Instance.new("Attachment")
            attachment.Parent = rootPart
            
            local particle = Instance.new("ParticleEmitter")
            particle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            particle.Color = ColorSequence.new(Color3.new(1, 1, 0))
            particle.Size = NumberSequence.new(2)
            particle.Lifetime = NumberRange.new(1, 2)
            particle.Rate = 100
            particle.Speed = NumberRange.new(10)
            particle.VelocitySpread = 360
            particle.Parent = attachment
            
            task.wait(1)
            particle.Enabled = false
            
            task.wait(2)
            attachment:Destroy()
        end
    end
end

_G.playKiBlastSound = function(position, player)
    playSound3D("kiBlast", position, player)
end

_G.playKiChargeSound = function(player)
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            playSound3D("kiCharge", rootPart.Position, player)
        end
    end
end

_G.playAuraSound = function(player, activate)
    if activate then
        playSoundForPlayer("auraActivate", player)
    end
end

_G.playDashSound = function(player)
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            playSound3D("dash", rootPart.Position, player)
        end
    end
end

-- Flight sound handling (continuous)
local flightSounds = {}

_G.startFlightSound = function(player)
    if flightSounds[player] then return end
    
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local sound = Instance.new("Sound")
            sound.SoundId = SOUNDS.flight.id
            sound.Volume = SOUNDS.flight.volume
            sound.Pitch = SOUNDS.flight.pitch
            sound.Looped = true
            sound.Parent = rootPart
            sound:Play()
            
            flightSounds[player] = sound
        end
    end
end

_G.stopFlightSound = function(player)
    if flightSounds[player] then
        flightSounds[player]:Stop()
        flightSounds[player]:Destroy()
        flightSounds[player] = nil
    end
end

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
    if flightSounds[player] then
        flightSounds[player]:Destroy()
        flightSounds[player] = nil
    end
    lastPlayTime[player] = nil
end)

-- Initialize system
initializeSoundPools()

print("✅ Central Sound Controller loaded!")
print("🔊 Sound functions available:")
print("  _G.playPunchSound(position, player)")
print("  _G.playBoxHitSound(box, player)")
print("  _G.playBoxDestroySound(box, player)")
print("  _G.playXPGainSound(player)")
print("  _G.playLevelUpSound(player)")
print("  _G.playKiBlastSound(position, player)")
print("  _G.playKiChargeSound(player)")
print("  _G.playAuraSound(player, activate)")
print("  _G.playDashSound(player)")
print("  _G.startFlightSound(player)")
print("  _G.stopFlightSound(player)")

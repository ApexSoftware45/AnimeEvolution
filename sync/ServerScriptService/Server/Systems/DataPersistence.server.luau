-- Data Persistence System - FIXED VERSION
-- Properly integrates with XP System for seamless level/XP saving and loading

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local playerDataStore = DataStoreService:GetDataStore("PlayerProgressV2") -- Changed version to force fresh start

-- Auto-save interval (in seconds)
local AUTO_SAVE_INTERVAL = 60

-- Player data cache
local playerDataCache = {}
local saveQueue = {}

_G.GetPlayerData = function(playerOrId)
    if typeof(playerOrId) == "Instance" then
        return playerDataCache[playerOrId.UserId]
    elseif typeof(playerOrId) == "number" then
        return playerDataCache[playerOrId]
    end
    return nil
end

-- Data structure template
local function getDefaultData()
    return {
        -- Progression
        level = 1,
        xp = 0,
        maxXP = 100,
        rebirthCount = 0,
        rebirthCredits = 0,
        
        -- Currency
        cash = 100,
        gems = 0,
        
        -- Unlocks
        unlockedCharacters = {1}, -- Start with character 1 unlocked
        pets = {
            owned = {},
            equipped = {},
        },
        inventory = {},
        
        -- Stats
        totalPlayTime = 0,
        joinDate = os.time(),
        lastSeen = os.time(),
        HasFinishedTutorial = false,
        
        -- Settings
        autoAttack = false,
        musicVolume = 0.5,
        sfxVolume = 0.5
    }
end

-- Load player data
local function loadPlayerData(player)
    local userId = player.UserId
    
    local success, data = pcall(function()
        return playerDataStore:GetAsync(userId)
    end)
    
    if success then
        if data then
            -- Merge with default to ensure all fields exist
            local defaultData = getDefaultData()
            for key, value in pairs(defaultData) do
                if data[key] == nil then
                    data[key] = value
                end
            end

            data.pets = data.pets or {}
            data.pets.owned = data.pets.owned or {}
            data.pets.equipped = data.pets.equipped or {}
            
            if data.cash == nil then
                local legacyCoins = data.coins
                if typeof(legacyCoins) == "number" then
                    data.cash = legacyCoins
                else
                    data.cash = defaultData.cash
                end
            end

            data.coins = nil

            -- Cache the data
            playerDataCache[userId] = data
            
            -- IMPORTANT: Initialize XP system data BEFORE it auto-initializes
            if not _G.playerData then
                _G.playerData = {}
            end
            
            _G.playerData[userId] = {
                xp = data.xp,
                level = data.level,
                maxXP = data.maxXP,
                rebirthCount = data.rebirthCount or 0,
                rebirthCredits = data.rebirthCredits or 0,
            }
            
            -- Set attributes
            player:SetAttribute("RebirthCount", data.rebirthCount or 0)
            player:SetAttribute("RebirthCredits", data.rebirthCredits or 0)
            player:SetAttribute("Cash", data.cash or defaultData.cash)
            
            print("✅ Loaded data for " .. player.Name)
            print("   📊 Level: " .. data.level .. " | XP: " .. data.xp .. "/" .. data.maxXP)
            
            return data
        else
            -- New player
            local newData = getDefaultData()
            playerDataCache[userId] = newData
            
            -- Initialize XP system for new player
            if not _G.playerData then
                _G.playerData = {}
            end
            
            _G.playerData[userId] = {
                xp = 0,
                level = 1,
                maxXP = 100,
                rebirthCount = 0,
                rebirthCredits = 0,
            }
            
            -- Set attributes for new player
            player:SetAttribute("RebirthCount", 0)
            player:SetAttribute("RebirthCredits", 0)
            player:SetAttribute("Cash", newData.cash or 0)
            
            print("🆕 Created new save for " .. player.Name)
            return newData
        end
    else
        warn("❌ Failed to load data for " .. player.Name .. ": " .. tostring(data))
        
        -- Fallback to default
        local defaultData = getDefaultData()
        playerDataCache[userId] = defaultData
        
        if not _G.playerData then
            _G.playerData = {}
        end
        
        _G.playerData[userId] = {
            xp = 0,
            level = 1,
            maxXP = 100,
            rebirthCount = 0,
            rebirthCredits = 0
        }
        
        -- Set attributes
        player:SetAttribute("RebirthCount", 0)
        player:SetAttribute("RebirthCredits", 0)
        player:SetAttribute("Cash", 0)
        
        return defaultData
    end
end

-- Save player data
local function savePlayerData(player)
    local userId = player.UserId
    local data = playerDataCache[userId]
    
    if not data then
        warn("⚠️ No data to save for " .. player.Name)
        return false
    end
    
    -- Update data from XP system (primary source of truth)
    if _G.playerData and _G.playerData[userId] then
        data.xp = _G.playerData[userId].xp
        data.level = _G.playerData[userId].level
        data.maxXP = _G.playerData[userId].maxXP
        data.rebirthCount = _G.playerData[userId].rebirthCount or player:GetAttribute("RebirthCount") or 0
        data.rebirthCredits = _G.playerData[userId].rebirthCredits or player:GetAttribute("RebirthCredits") or 0
    else
        data.rebirthCount = player:GetAttribute("RebirthCount") or data.rebirthCount or 0
        data.rebirthCredits = player:GetAttribute("RebirthCredits") or data.rebirthCredits or 0
    end

    local currentCash = player:GetAttribute("Cash")
    if typeof(_G.getPlayerCash) == "function" then
        local ok, cashValue = pcall(_G.getPlayerCash, player)
        if ok and typeof(cashValue) == "number" then
            currentCash = cashValue
        end
    end
    if typeof(currentCash) ~= "number" then
        currentCash = playerDataCache[userId] and playerDataCache[userId].cash or 0
    end
    data.cash = math.max(0, math.floor(currentCash + 0.5))
    
    -- Update timestamp
    data.lastSeen = os.time()
    
    -- Attempt to save with retries
    local attempts = 0
    local success = false
    
    while attempts < 3 and not success do
        attempts = attempts + 1
        
        success = pcall(function()
            playerDataStore:SetAsync(userId, data)
        end)
        
        if not success and attempts < 3 then
            wait(1) -- Wait before retry
        end
    end
    
    if success then
        print("💾 Saved data for " .. player.Name .. " (Level " .. data.level .. ", XP: " .. data.xp .. ")")
    else
        warn("❌ Failed to save data for " .. player.Name .. " after " .. attempts .. " attempts")
        
        -- Add to save queue for later retry
        table.insert(saveQueue, {userId = userId, data = data, playerName = player.Name})
    end
    
    return success
end

-- Process save queue
local function processSaveQueue()
    if #saveQueue == 0 then return end
    
    local processed = {}
    
    for i, entry in ipairs(saveQueue) do
        local success = pcall(function()
            playerDataStore:SetAsync(entry.userId, entry.data)
        end)
        
        if success then
            table.insert(processed, i)
            print("✅ Processed queued save for " .. (entry.playerName or "UserId: " .. entry.userId))
        end
    end
    
    -- Remove processed entries (from end to avoid index issues)
    for i = #processed, 1, -1 do
        table.remove(saveQueue, processed[i])
    end
end

-- Auto-save loop
spawn(function()
    while true do
        wait(AUTO_SAVE_INTERVAL)
        
        print("🔄 Auto-saving all players...")
        
        -- Save all online players
        for _, player in pairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
        
        -- Process any queued saves
        processSaveQueue()
    end
end)

-- Player joined
Players.PlayerAdded:Connect(function(player)
    print("👋 " .. player.Name .. " joining, loading data...")
    
    -- Load data FIRST before XP system initializes
    local data = loadPlayerData(player)
    
    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = data.level
    level.Parent = leaderstats
    
    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = data.cash or 0
    cash.Parent = leaderstats
    
    local rebirths = Instance.new("IntValue")
    rebirths.Name = "Rebirths"
    rebirths.Value = player:GetAttribute("RebirthCount") or data.rebirthCount or 0
    rebirths.Parent = leaderstats
    
    player:GetAttributeChangedSignal("RebirthCount"):Connect(function()
        rebirths.Value = player:GetAttribute("RebirthCount") or 0
    end)
    
    -- Wait for XP system to be ready, then sync
    spawn(function()
        wait(1) -- Give XP system time to initialize
        
        -- Sync leaderstats with XP system data
        if _G.playerData and _G.playerData[player.UserId] then
            level.Value = _G.playerData[player.UserId].level
        end
        
        -- Update leaderstats when XP system changes level
        spawn(function()
            while player.Parent do
                wait(1)
                if _G.playerData and _G.playerData[player.UserId] then
                    level.Value = _G.playerData[player.UserId].level
                end
            end
        end)
    end)
    
    print("✅ " .. player.Name .. " data loaded and synced!")
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
    print("👋 " .. player.Name .. " leaving, saving data...")
    savePlayerData(player)
    
    -- Clean up cache after a delay (in case of save retry)
    spawn(function()
        wait(10)
        playerDataCache[player.UserId] = nil
    end)
end)

-- Server shutdown
game:BindToClose(function()
    print("🛑 Server shutting down, saving all player data...")
    
    -- Save all players
    for _, player in pairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
    
    -- Process remaining queue
    processSaveQueue()
    
    print("✅ All data saved, shutting down...")
    wait(5) -- Ensure saves complete
end)

-- Global functions for other scripts
_G.savePlayerData = savePlayerData
_G.loadPlayerData = loadPlayerData
_G.getPlayerSaveData = function(player)
    return playerDataCache[player.UserId]
end

print("✅ Data Persistence System V2 loaded!")
print("   💾 Auto-save interval: " .. AUTO_SAVE_INTERVAL .. " seconds")
print("   📊 Integrated with XP System for seamless saving")

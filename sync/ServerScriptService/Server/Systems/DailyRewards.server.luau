-- Daily Rewards System
-- Manages daily login bonuses and streak tracking while awarding cash

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dailyRewardsStore = DataStoreService:GetDataStore("DailyRewards")

-- Remote events
local claimRewardEvent = Instance.new("RemoteEvent")
claimRewardEvent.Name = "ClaimDailyReward"
claimRewardEvent.Parent = ReplicatedStorage

local rewardStatusEvent = Instance.new("RemoteEvent")
rewardStatusEvent.Name = "DailyRewardStatus"
rewardStatusEvent.Parent = ReplicatedStorage

-- Daily rewards configuration (7-day cycle)
local REWARDS = {
    [1] = {cash = 100, gems = 0, items = {}, name = "Day 1"},
    [2] = {cash = 200, gems = 0, items = {}, name = "Day 2"},
    [3] = {cash = 300, gems = 5, items = {}, name = "Day 3"},
    [4] = {cash = 500, gems = 0, items = {}, name = "Day 4"},
    [5] = {cash = 750, gems = 10, items = {"CommonPet"}, name = "Day 5"},
    [6] = {cash = 1000, gems = 15, items = {}, name = "Day 6"},
    [7] = {cash = 1500, gems = 25, items = {"RarePet"}, name = "Week Complete!"}
}

-- Preserve legacy `coins` field for any older UI that still expects it
for _, reward in pairs(REWARDS) do
    reward.coins = reward.cash
end

local function checkDailyReward(player)
    local success, data = pcall(function()
        return dailyRewardsStore:GetAsync(player.UserId)
    end)

    if not success then
        warn("[DailyRewards] Failed to check reward for " .. player.Name)
        return false, 0, nil
    end

    local currentTime = os.time()

    if not data then
        return true, 1, nil
    end

    local lastClaim = data.lastClaim
    local timeDiff = currentTime - lastClaim

    if timeDiff >= 86400 then
        local streak = data.streak or 0

        if timeDiff <= 172800 then
            streak = (streak % 7) + 1
        else
            streak = 1
        end

        return true, streak, data
    end

    local timeUntilNext = 86400 - timeDiff
    return false, data.streak or 1, timeUntilNext
end

local function grantReward(player, day)
    local reward = REWARDS[day]
    if not reward then
        return false
    end

    local rewardCash = reward.cash or reward.coins or 0

    if rewardCash > 0 then
        if typeof(_G.addPlayerCash) == "function" then
            _G.addPlayerCash(player, rewardCash, "DailyReward")
        else
            local currentCash = player:GetAttribute("Cash") or 0
            player:SetAttribute("Cash", currentCash + rewardCash)
        end
    end

    local currentGems = player:GetAttribute("Gems") or 0
    player:SetAttribute("Gems", currentGems + (reward.gems or 0))

    for _, item in pairs(reward.items) do
        local inventory = player:GetAttribute("Inventory") or {}
        table.insert(inventory, item)
        player:SetAttribute("Inventory", inventory)
    end

    local success = pcall(function()
        dailyRewardsStore:SetAsync(player.UserId, {
            lastClaim = os.time(),
            streak = day,
            totalClaims = (player:GetAttribute("TotalDailyClaims") or 0) + 1
        })
    end)

    if success then
        player:SetAttribute("TotalDailyClaims", (player:GetAttribute("TotalDailyClaims") or 0) + 1)

        rewardStatusEvent:FireClient(player, {
            claimed = true,
            day = day,
            reward = reward
        })

        print("[DailyRewards] " .. player.Name .. " claimed day " .. day .. " reward. +" .. rewardCash .. " cash")
        return true
    end

    return false
end

claimRewardEvent.OnServerEvent:Connect(function(player)
    local canClaim, currentDay, timeUntilNext = checkDailyReward(player)

    if canClaim then
        grantReward(player, currentDay)
    else
        rewardStatusEvent:FireClient(player, {
            claimed = false,
            day = currentDay,
            timeUntilNext = timeUntilNext
        })
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.wait(1)

    local canClaim, currentDay, timeUntilNext = checkDailyReward(player)

    rewardStatusEvent:FireClient(player, {
        canClaim = canClaim,
        currentDay = currentDay,
        timeUntilNext = timeUntilNext,
        rewards = REWARDS
    })
end)

print("[DailyRewards] System loaded")

-- Cash System
-- Maintains authoritative cash balances, syncs leaderstats, attributes, and UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CASH_REMOTE_NAME = "CashUpdated"
local cashRemote = ReplicatedStorage:FindFirstChild(CASH_REMOTE_NAME)

if not cashRemote then
    cashRemote = Instance.new("RemoteEvent")
    cashRemote.Name = CASH_REMOTE_NAME
    cashRemote.Parent = ReplicatedStorage
end

local playerCash = {}

local function getPetBoostMultiplier(player: Player, attributeName: string): number
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return 1
    end
    local value = player:GetAttribute(attributeName)
    if typeof(value) == "number" and value > 0 then
        return value
    end
    return 1
end

local function getLeaderstatsValue(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    return leaderstats:FindFirstChild("Cash")
end

local function ensureLeaderstatsValue(player)
    local cashValue = getLeaderstatsValue(player)

    if cashValue then
        return cashValue
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    cashValue = Instance.new("IntValue")
    cashValue.Name = "Cash"
    cashValue.Parent = leaderstats

    return cashValue
end

local function updateCachedSave(player, amount)
    if typeof(_G.getPlayerSaveData) ~= "function" then
        return
    end

    local data = _G.getPlayerSaveData(player)
    if not data then
        return
    end

    data.cash = amount
end

local function broadcastCash(player, amount)
    player:SetAttribute("Cash", amount)
    player:SetAttribute("Money", amount)

    local cashValue = ensureLeaderstatsValue(player)
    if cashValue then
        cashValue.Value = amount
    end

    cashRemote:FireClient(player, amount)
end

local function setCash(player, amount, reason)
    if not player or not player:IsDescendantOf(Players) then
        return 0
    end

    amount = math.max(0, math.floor(amount + 0.5))

    local userId = player.UserId
    playerCash[userId] = amount

    updateCachedSave(player, amount)
    broadcastCash(player, amount)

    if reason then
        print(string.format("[CashSystem] %s balance set to %d (%s)", player.Name, amount, reason))
    end

    return amount
end

local function getCash(player)
    if not player then
        return 0
    end

    local cached = playerCash[player.UserId]
    if typeof(cached) == "number" then
        return cached
    end

    local attributeValue = player:GetAttribute("Cash")
    if typeof(attributeValue) == "number" then
        return attributeValue
    end

    return 0
end

local function addCash(player, delta, reason, applyBoost)
	if not player then
		return 0
	end

    if typeof(delta) ~= "number" or delta == 0 then
        return getCash(player)
    end

	if delta > 0 and applyBoost ~= false then
		local cashMultiplier = getPetBoostMultiplier(player, "PetCashBoost")
		if cashMultiplier ~= 1 then
			delta = math.floor(delta * cashMultiplier + 0.5)
		end
	end

    local newTotal = getCash(player) + delta
    return setCash(player, newTotal, reason)
end

local function trySpendCash(player, cost, reason)
    if not player or typeof(cost) ~= "number" or cost <= 0 then
        return false
    end

    local current = getCash(player)
    if current < cost then
        return false
    end

    setCash(player, current - cost, reason or "Spend")
    return true
end

local function initializePlayer(player)
    task.spawn(function()
        -- Wait for DataPersistence to register save data
        local data
        for _ = 1, 50 do
            if typeof(_G.getPlayerSaveData) == "function" then
                data = _G.getPlayerSaveData(player)
            end

            if data then
                break
            end

            task.wait(0.1)
        end

        local startCash = 0
        if data and typeof(data.cash) == "number" then
            startCash = data.cash
        elseif data and typeof(data.coins) == "number" then
            startCash = data.coins
            data.cash = startCash
            data.coins = nil
        else
            local attrCash = player:GetAttribute("Cash")
            if typeof(attrCash) == "number" then
                startCash = attrCash
            end
        end

        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then
            leaderstats = player:WaitForChild("leaderstats", 5)
        end

        if leaderstats then
            ensureLeaderstatsValue(player)
        end

        setCash(player, startCash, "Initialize")
    end)
end

Players.PlayerAdded:Connect(function(player)
    initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playerCash[player.UserId] = nil
end)

_G.getPlayerCash = getCash
_G.setPlayerCash = setCash
_G.addPlayerCash = function(player: Player, amount: number, reason: string?, applyBoost: boolean?)
	return addCash(player, amount, reason, applyBoost)
end
_G.trySpendPlayerCash = trySpendCash

_G.getMoneyBalance = function(player: Player)
    return getCash(player)
end

_G.addMoney = function(player: Player, amount: number, reason: string?, applyBoost: boolean?)
    return addCash(player, amount, reason, applyBoost)
end

_G.trySpendMoney = function(player: Player, amount: number, reason: string?)
    local ok = trySpendCash(player, amount, reason)
    if ok then
        return true, ""
    end
    local current = getCash(player)
    return false, string.format("Not enough Money. Need %d, have %d.", amount, current)
end

print("[CashSystem] Loaded")

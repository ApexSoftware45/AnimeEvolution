-- Cash Display Controller
-- Keeps the cash HUD label in sync with the player's balance

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cashRemote = ReplicatedStorage:WaitForChild("CashUpdated", 10)

if not cashRemote then
    warn("[CashDisplay] CashUpdated remote missing")
    return
end

local trackedLabels = {}

local function formatNumber(amount)
    local rounded = math.floor((amount or 0) + 0.5)
    local sign = rounded < 0 and "-" or ""
    local str = tostring(math.abs(rounded))
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

local function updateDisplay(amount)
    local display = formatNumber(amount or player:GetAttribute("Cash") or 0)
    for label in pairs(trackedLabels) do
        if label:IsDescendantOf(playerGui) then
            label.Text = display
        else
            trackedLabels[label] = nil
        end
    end
end

local function trackLabel(label)
    if not label:IsA("TextLabel") then
        return
    end

    trackedLabels[label] = true
    updateDisplay(player:GetAttribute("Cash"))
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    if descendant.Name == "CashLabel" and descendant:IsA("TextLabel") then
        trackLabel(descendant)
    end
end

playerGui.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "CashLabel" and descendant:IsA("TextLabel") then
        trackLabel(descendant)
    end
end)

player:GetAttributeChangedSignal("Cash"):Connect(function()
    updateDisplay(player:GetAttribute("Cash"))
end)

cashRemote.OnClientEvent:Connect(updateDisplay)

updateDisplay(player:GetAttribute("Cash"))

--!strict
-- Client UI for Daily Rewards. Works with server system in src/server/Systems/DailyRewards.server.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes from server script
local ClaimDailyReward: RemoteEvent = ReplicatedStorage:WaitForChild("ClaimDailyReward") :: any
local DailyRewardStatus: RemoteEvent = ReplicatedStorage:WaitForChild("DailyRewardStatus") :: any

-- Simple UI builder
local function createUi()
    local gui = Instance.new("ScreenGui")
    gui.Name = "DailyRewardsUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.fromOffset(360, 220)
    frame.Position = UDim2.new(0.5, -180, 0.35, -110)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Daily Rewards"
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 22)
    status.Position = UDim2.new(0, 10, 0, 46)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 16
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(210, 220, 235)
    status.Text = "Checking..."
    status.Parent = frame

    local rewards = Instance.new("TextLabel")
    rewards.Name = "Rewards"
    rewards.Size = UDim2.new(1, -20, 0, 80)
    rewards.Position = UDim2.new(0, 10, 0, 72)
    rewards.BackgroundTransparency = 1
    rewards.Font = Enum.Font.Gotham
    rewards.TextWrapped = true
    rewards.TextYAlignment = Enum.TextYAlignment.Top
    rewards.TextXAlignment = Enum.TextXAlignment.Left
    rewards.TextSize = 14
    rewards.TextColor3 = Color3.fromRGB(200, 210, 230)
    rewards.Text = ""
    rewards.Parent = frame

    local claim = Instance.new("TextButton")
    claim.Name = "ClaimButton"
    claim.Size = UDim2.new(0, 150, 0, 34)
    claim.Position = UDim2.new(0.5, -75, 1, -48)
    claim.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    claim.BorderSizePixel = 0
    claim.Font = Enum.Font.GothamBold
    claim.TextSize = 16
    claim.TextColor3 = Color3.new(1,1,1)
    claim.Text = "Claim"
    claim.AutoButtonColor = true
    claim.Parent = frame

    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0, 8)
    claimCorner.Parent = claim

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -32, 0, 8)
    close.BackgroundTransparency = 0.2
    close.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
    close.Text = "✕"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.Gotham
    close.TextSize = 14
    close.Parent = frame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = close

    close.Activated:Connect(function()
        gui.Enabled = false
    end)

    claim.Activated:Connect(function()
        ClaimDailyReward:FireServer()
    end)

    gui.Enabled = false
    gui.Parent = playerGui
    return gui
end

local gui = playerGui:FindFirstChild("DailyRewardsUI") :: ScreenGui?
if not gui then
    gui = createUi()
end

local panel = gui:WaitForChild("Panel")
local statusLabel = panel:WaitForChild("Status") :: TextLabel
local rewardsLabel = panel:WaitForChild("Rewards") :: TextLabel
local claimButton = panel:WaitForChild("ClaimButton") :: TextButton

local function formatRewardsList(list)
    local lines = {}
    for i, entry in ipairs(list) do
        local parts = {}
        if typeof(entry.cash) == "number" and entry.cash > 0 then
            table.insert(parts, string.format("$%d", entry.cash))
        end
        if typeof(entry.gems) == "number" and entry.gems > 0 then
            table.insert(parts, string.format("%d Gems", entry.gems))
        end
        if typeof(entry.items) == "table" and #entry.items > 0 then
            table.insert(parts, table.concat(entry.items, ", "))
        end
        lines[#lines+1] = string.format("Day %d: %s", i, (#parts>0 and table.concat(parts, " + ") or "-") )
    end
    return table.concat(lines, "\n")
end

local function applyStatus(payload)
    if typeof(payload) ~= "table" then
        return
    end
    local canClaim = payload.canClaim
    local day = payload.currentDay or payload.day or 1
    local timeUntil = payload.timeUntilNext
    local rewards = payload.rewards

    if payload.claimed then
        statusLabel.Text = string.format("Claimed Day %d!", day)
    elseif canClaim then
        statusLabel.Text = string.format("Ready: Day %d", day)
    elseif typeof(timeUntil) == "number" then
        local hrs = math.floor(timeUntil / 3600)
        local mins = math.floor((timeUntil % 3600)/60)
        statusLabel.Text = string.format("Next in %dh %dm", hrs, mins)
    else
        statusLabel.Text = "Come back tomorrow!"
    end

    claimButton.AutoButtonColor = true
    claimButton.Active = canClaim == true
    claimButton.Modal = false
    claimButton.TextTransparency = (canClaim == true) and 0 or 0.4
    claimButton.BackgroundTransparency = (canClaim == true) and 0 or 0.2
    claimButton.Text = (canClaim == true) and "Claim" or "Not Ready"

    if typeof(rewards) == "table" then
        rewardsLabel.Text = formatRewardsList(rewards)
    end
end

DailyRewardStatus.OnClientEvent:Connect(function(payload)
    applyStatus(payload)
end)

-- Public open function other UI can call
function _G.ShowDailyRewards()
    gui.Enabled = true
end

-- Attempt to auto-wire a button named like "DailyRewards" / "Daily Rewards"
task.defer(function()
    local function tryHook(container: Instance)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local name = string.lower(obj.Name)
                if name == "dailyrewards" or name == "daily_rewards" or name == "daily rewards" then
                    (obj :: any).Activated:Connect(function()
                        _G.ShowDailyRewards()
                    end)
                end
            end
        end
    end
    tryHook(playerGui)
    playerGui.DescendantAdded:Connect(function(inst)
        if (inst:IsA("TextButton") or inst:IsA("ImageButton")) and inst.Parent then
            local lname = string.lower(inst.Name)
            if lname == "dailyrewards" or lname == "daily_rewards" or lname == "daily rewards" then
                (inst :: any).Activated:Connect(function()
                    _G.ShowDailyRewards()
                end)
            end
        end
    end)
end)

-- Optional keybind: press "Y" to open (handy for testing)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Y then
        gui.Enabled = not gui.Enabled
    end
end)


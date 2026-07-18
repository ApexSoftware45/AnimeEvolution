-- StarterPlayerScripts / AutoTheme.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- get theme module from ReplicatedStorage/Shared/uitheme
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(SharedFolder:WaitForChild("uitheme"))

local function getDeviceMode()
    local cam = workspace.CurrentCamera
    if not cam then return "Desktop" end
    local size = cam.ViewportSize
    if size.X < (Theme.Breakpoints and Theme.Breakpoints.MobileMax or 900) then
        return "Mobile"
    elseif size.X < (Theme.Breakpoints and Theme.Breakpoints.TabletMax or 1300) then
        return "Tablet"
    else
        return "Desktop"
    end
end

local function ensureCorner(guiObject, radius)
    if not guiObject:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = radius or (Theme.CornerRadius or UDim.new(0, 12))
        corner.Parent = guiObject
    end
end

local function applyThemeTo(instance)
    -- opt-out
    if instance:FindFirstChild("NoAutoTheme") then return end

    local mode = getDeviceMode()

    if instance:IsA("Frame") or instance:IsA("ScrollingFrame") then
        instance.BackgroundColor3 = Theme.Colors.Panel
        instance.BorderSizePixel = 0
        ensureCorner(instance)

        -- mobile shrink (you can comment this out)
        if mode == "Mobile" then
            instance.AutomaticSize = Enum.AutomaticSize.None
        end

    elseif instance:IsA("TextLabel") then
        instance.Font = Theme.Font
        instance.TextColor3 = Theme.Colors.TextPrimary
        instance.TextStrokeTransparency = 1

        if mode == "Mobile" then
            instance.TextScaled = false
            instance.TextSize = Theme.Sizes.Body
        else
            instance.TextScaled = false
            instance.TextSize = Theme.Sizes.Body + 2
        end

    elseif instance:IsA("TextButton") then
        instance.Font = Theme.Font
        instance.TextColor3 = Color3.new(1,1,1)
        instance.BackgroundColor3 = Theme.Colors.Accent
        instance.BorderSizePixel = 0
        ensureCorner(instance, Theme.SmallCorner)

    elseif instance:IsA("ImageButton") or instance:IsA("ImageLabel") then
        -- don't overwrite your pictures, just round them
        if instance.BackgroundTransparency == 0 then
            instance.BackgroundColor3 = Theme.Colors.PanelAlt
        end
        ensureCorner(instance, Theme.SmallCorner)
    end
end

local function themeDescendants(root)
    for _, child in ipairs(root:GetDescendants()) do
        applyThemeTo(child)
    end
end

-- theme everything that already exists
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        themeDescendants(gui)
        gui.DescendantAdded:Connect(applyThemeTo)
    end
end

-- theme future guis
playerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        themeDescendants(child)
        child.DescendantAdded:Connect(applyThemeTo)
    end
end)

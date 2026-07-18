-- StarterGui/GamepassShop/BlackFriezaPurchase.client.luau
-- Attach this LocalScript to the Black Frieza ImageButton inside the shop UI.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local BUTTON: GuiButton? = script.Parent :: GuiButton
local LOCAL_PLAYER = Players.LocalPlayer
local GAMEPASS_ID = 1571569281
local PROMPT_COOLDOWN = 0.5

if not BUTTON or not BUTTON:IsA("GuiButton") then
    warn("[BlackFriezaPurchase] Parent must be a GuiButton")
    return
end

local lastPrompt = 0

local function promptPurchase()
    if not LOCAL_PLAYER then
        return
    end

    local now = tick()
    if now - lastPrompt < PROMPT_COOLDOWN then
        return
    end
    lastPrompt = now

    local success, err = pcall(function()
        MarketplaceService:PromptGamePassPurchase(LOCAL_PLAYER, GAMEPASS_ID)
    end)
    if not success then
        warn(string.format("[BlackFriezaPurchase] Prompt failed: %s", tostring(err)))
    end
end

BUTTON.Activated:Connect(promptPurchase)
BUTTON.MouseButton1Click:Connect(promptPurchase)
BUTTON.TouchTap:Connect(function()
    promptPurchase()
end)

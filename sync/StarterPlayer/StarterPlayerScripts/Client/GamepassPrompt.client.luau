-- StarterPlayerScripts/Client/GamepassPrompt.client.luau
-- Listens for ProximityPrompt holds and, for gamepass prompts, opens the purchase UI on the client.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer

-- If you want to restrict to a specific pass, set it here; otherwise read from prompt attribute
local FALLBACK_GAMEPASS_ID = 1573310965

local debounce: {[ProximityPrompt]: number} = {}

local function getGamepassId(prompt: ProximityPrompt): number
    local attr = prompt:GetAttribute("GamepassId")
    if typeof(attr) == "number" then
        return attr
    end
    return FALLBACK_GAMEPASS_ID
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player ~= LOCAL_PLAYER then
        return
    end

    -- Accept either attribute on the prompt itself or on its parent, and do not
    -- require a specific prompt name. This makes it work for all stations.
    local attrOnPrompt = prompt:GetAttribute("GamepassId")
    local attrOnParent = prompt.Parent and prompt.Parent:GetAttribute("GamepassId")
    if typeof(attrOnPrompt) ~= "number" and typeof(attrOnParent) ~= "number" then
        return
    end

    local last = debounce[prompt]
    local now = tick()
    if last and now - last < 0.5 then
        return
    end
    debounce[prompt] = now

    local gamepassId = typeof(attrOnPrompt) == "number" and attrOnPrompt or attrOnParent or getGamepassId(prompt)
    MarketplaceService:PromptGamePassPurchase(LOCAL_PLAYER, gamepassId)
end)

-- Robust fallback path: the server also fires an explicit request when a
-- gamepass station prompt completes a hold. Listen for that too.
local purchaseRemote: RemoteEvent = (ReplicatedStorage:FindFirstChild("GamepassPurchaseRequest") :: any)
if not purchaseRemote or not purchaseRemote:IsA("RemoteEvent") then
    purchaseRemote = Instance.new("RemoteEvent")
    purchaseRemote.Name = "GamepassPurchaseRequest"
    purchaseRemote.Parent = ReplicatedStorage
end

purchaseRemote.OnClientEvent:Connect(function(gamepassId: number)
    if typeof(gamepassId) == "number" then
        MarketplaceService:PromptGamePassPurchase(LOCAL_PLAYER, gamepassId)
    end
end)

print("[GamepassPrompt.client] Ready")

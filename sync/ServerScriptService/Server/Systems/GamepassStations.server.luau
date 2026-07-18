-- ServerScriptService/Systems/GamepassStations.server.luau
-- Automatically attaches hold-to-purchase prompts to tagged gamepass stations.

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TAG_NAME = "GamepassStation"
local ATTR_GAMEPASS_ID = "GamepassId"
local ATTR_DISPLAY_NAME = "GamepassDisplayName"
local ATTR_HOLD_DURATION = "HoldDuration"
local ATTR_PROMPT_DISTANCE = "PromptDistance"

local DEFAULT_GAMEPASS_ID = 1573310965
local DEFAULT_DISPLAY = "MUI Boku Gamepass"
local DEFAULT_HOLD_DURATION = 3.0
local DEFAULT_PROMPT_DISTANCE = 6 -- slightly shorter to avoid overlap with other E prompts

type PromptState = {
	prompt: ProximityPrompt,
	gamepassId: number,
	displayName: string,
}

local promptState: {[ProximityPrompt]: PromptState} = {}
local promptConnections: {[ProximityPrompt]: RBXScriptConnection} = {}
local processed: {[Instance]: boolean} = {}

local purchaseRemote: RemoteEvent = (function()
    local existing = ReplicatedStorage:FindFirstChild("GamepassPurchaseRequest")
    if existing and existing:IsA("RemoteEvent") then
        return existing
    end
    local ev = Instance.new("RemoteEvent")
    ev.Name = "GamepassPurchaseRequest"
    ev.Parent = ReplicatedStorage
    return ev
end)()

local function toNumber(value: any, fallback: number): number
	if typeof(value) == "number" and value == value then
		return value
	end
	return fallback
end

local function toString(value: any, fallback: string): string
	if typeof(value) == "string" and value ~= "" then
		return value
	end
	return fallback
end

local function findPromptParent(instance: Instance): (Instance?, ProximityPrompt?)
	if instance:IsA("ProximityPrompt") then
		if instance.Parent then
			return instance.Parent, instance
		end
		return nil, nil
	end

	if instance:IsA("Attachment") then
		return instance, instance:FindFirstChildOfClass("ProximityPrompt")
	end

	if instance:IsA("BasePart") then
		return instance, instance:FindFirstChildOfClass("ProximityPrompt")
	end

	if instance:IsA("Model") then
		local primary = instance.PrimaryPart
		if not primary then
			primary = instance:FindFirstChildWhichIsA("BasePart", true)
		end
		if primary then
			return primary, primary:FindFirstChildOfClass("ProximityPrompt")
		end
	end

	return nil, nil
end

local function configurePrompt(prompt: ProximityPrompt, displayText: string, holdDuration: number, promptDistance: number)
    prompt.ActionText = "Purchase"
    prompt.ObjectText = displayText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.Style = Enum.ProximityPromptStyle.Hold
    prompt.HoldDuration = math.max(holdDuration, 0.05)
    prompt.MaxActivationDistance = math.max(promptDistance, 1)
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    -- Prefer OneGlobally to prevent competing nearby prompts from stealing focus
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
    prompt.Enabled = true
end

local function onPromptTriggered(player: Player, prompt: ProximityPrompt)
    -- Robust fallback: notify the triggering client to open the purchase UI.
    local state = promptState[prompt]
    local gamepassId
    if state then
        gamepassId = state.gamepassId
    else
        local attr = prompt:GetAttribute(ATTR_GAMEPASS_ID) or (prompt.Parent and prompt.Parent:GetAttribute(ATTR_GAMEPASS_ID))
        if typeof(attr) == "number" then
            gamepassId = attr
        end
    end
    if typeof(gamepassId) == "number" then
        purchaseRemote:FireClient(player, gamepassId)
    end
end

local function setupPrompt(instance: Instance)
	if processed[instance] then
		return
	end
	processed[instance] = true

	local promptParent, existingPrompt = findPromptParent(instance)
	if not promptParent then
		warn(string.format("[GamepassStations] Could not find a BasePart or Attachment for %s", instance:GetFullName()))
		return
	end

	local prompt = existingPrompt
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = promptParent
	end

	local gamepassId = toNumber(promptParent:GetAttribute(ATTR_GAMEPASS_ID) or instance:GetAttribute(ATTR_GAMEPASS_ID), DEFAULT_GAMEPASS_ID)
	local displayName = toString(promptParent:GetAttribute(ATTR_DISPLAY_NAME) or instance:GetAttribute(ATTR_DISPLAY_NAME), DEFAULT_DISPLAY)
	local holdDuration = toNumber(promptParent:GetAttribute(ATTR_HOLD_DURATION) or instance:GetAttribute(ATTR_HOLD_DURATION), DEFAULT_HOLD_DURATION)
	local promptDistance = toNumber(promptParent:GetAttribute(ATTR_PROMPT_DISTANCE) or instance:GetAttribute(ATTR_PROMPT_DISTANCE), DEFAULT_PROMPT_DISTANCE)

	configurePrompt(prompt, displayName, holdDuration, promptDistance)

    local state: PromptState = {
        prompt = prompt,
        gamepassId = gamepassId,
        displayName = displayName,
    }
    promptState[prompt] = state

    -- Expose attributes so the client can identify this prompt
    prompt:SetAttribute("GamepassId", gamepassId)
    prompt:SetAttribute("GamepassDisplayName", displayName)

	if promptConnections[prompt] then
		promptConnections[prompt]:Disconnect()
	end

	promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
		onPromptTriggered(player, prompt)
	end)

	prompt.Destroying:Connect(function()
		local connection = promptConnections[prompt]
		if connection then
			connection:Disconnect()
			promptConnections[prompt] = nil
		end
		promptState[prompt] = nil
	end)
end

local function handleInstance(instance: Instance)
	if processed[instance] then
		return
	end

	if CollectionService:HasTag(instance, TAG_NAME) then
		task.defer(function()
			setupPrompt(instance)
		end)
	end
end

for _, instance in ipairs(CollectionService:GetTagged(TAG_NAME)) do
	handleInstance(instance)
end

CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(handleInstance)
CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(instance)
	processed[instance] = nil
end)

workspace.DescendantAdded:Connect(function(descendant)
	if CollectionService:HasTag(descendant, TAG_NAME) then
		handleInstance(descendant)
	end
end)

print(string.format("[GamepassStations] Ready (tag = %s)", TAG_NAME))

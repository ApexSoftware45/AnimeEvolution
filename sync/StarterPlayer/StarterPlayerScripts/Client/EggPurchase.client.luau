-- StarterPlayerScripts/EggPurchase.client.luau
-- Bridges proximity prompts to the PetSystem purchase RemoteEvents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local purchaseRequest = ReplicatedStorage:WaitForChild("PetPurchaseRequest")
local purchaseResult = ReplicatedStorage:WaitForChild("PetPurchaseResult")

local activePurchase = false
local lastEggRequested: string? = nil

local registeredPrompts: {[ProximityPrompt]: boolean} = {}

local function resolveEggId(instance: Instance?): string?
	local current = instance
	while current do
		local value = current:GetAttribute("EggId")
		if typeof(value) == "string" and value ~= "" then
			return value
		end
		current = current.Parent
	end
	return nil
end

local function notify(message: string)
	if message == "" then
		return
	end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Egg Hatch",
			Text = message,
			Duration = 3,
		})
	end)
end

local function onPromptTriggered(prompt: ProximityPrompt, triggerPlayer: Player?)
	if triggerPlayer and triggerPlayer ~= player then
		return
	end

	if activePurchase then
		return
	end

	local eggId = resolveEggId(prompt)
	if not eggId then
		warn(("[EggPurchaseClient] Missing EggId attribute for prompt %s"):format(prompt:GetFullName()))
		return
	end

	activePurchase = true
	lastEggRequested = eggId
	purchaseRequest:FireServer(eggId)
end

local function monitorPrompt(prompt: ProximityPrompt)
	if registeredPrompts[prompt] then
		return
	end
	registeredPrompts[prompt] = true

	prompt.Triggered:Connect(function(triggerPlayer)
		onPromptTriggered(prompt, triggerPlayer)
	end)
end

local function tryRegister(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		monitorPrompt(instance)
		return
	end

	if instance:IsA("Attachment") or instance:IsA("BasePart") then
		local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			monitorPrompt(prompt)
		end
		return
	end

	if instance:IsA("Model") then
		local primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
		if primary then
			local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				monitorPrompt(prompt)
			end
		end
	end
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	tryRegister(descendant)
end

workspace.DescendantAdded:Connect(function(instance)
	tryRegister(instance)
end)

purchaseResult.OnClientEvent:Connect(function(success: boolean, message: string?, petName: string?)
	activePurchase = false
	lastEggRequested = nil
	if typeof(message) == "string" and message ~= "" then
		notify(message)
	elseif success and typeof(petName) == "string" and petName ~= "" then
		notify(("You received %s!"):format(petName))
	end
end)

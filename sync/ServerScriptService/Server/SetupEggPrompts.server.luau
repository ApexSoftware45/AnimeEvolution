-- ServerScriptService/SetupEggPrompts.server.luau
-- Ensures each egg station in the map has a ProximityPrompt that fires PetPurchaseRequest.

local STATIONS_ROOT_PATH = { "Pet Egg Stations" }

local STATION_TO_EGG = {
	["CommonEggStation"] = "StarterEgg",
	["Rare"] = "RareEgg",
	["SpottedRareEgg"] = "SpottedRareEgg",
}

-- Source of truth for egg definitions now comes from Shared/EggData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local EggData = require(SharedFolder:WaitForChild("EggData"))

local function getEggInfo(eggId: string): { displayName: string, price: number }
    local def = EggData[eggId]
    if def then
        local display = def.DisplayName or eggId
        local price = tonumber(def.Price) or 0
        return { displayName = display, price = price }
    end
    -- Fallback labels
    if eggId == "StarterEgg" then
        return { displayName = "Starter Egg", price = 1000 }
    elseif eggId == "RareEgg" then
        return { displayName = "Rare Egg", price = 15000 }
    elseif eggId == "SpottedRareEgg" then
        return { displayName = "Spotted Rare Egg", price = 150000 }
    end
    return { displayName = eggId, price = 0 }
end

local HOLD_DURATION = 0.8
local PROMPT_DISTANCE = 9

local function formatPrice(amount: number): string
	if amount % 1 ~= 0 then
		return string.format("%.2f", amount)
	end
	local str = tostring(math.floor(amount + 0.5))
	local segments = {}
	while #str > 3 do
		table.insert(segments, 1, str:sub(-3))
		str = str:sub(1, -4)
	end
	if #str > 0 then
		table.insert(segments, 1, str)
	end
	return table.concat(segments, ",")
end

local function getHostPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		local primary = instance.PrimaryPart
		if not primary then
			primary = instance:FindFirstChildWhichIsA("BasePart", true)
		end
		return primary
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function findEggVisual(station: Instance): Instance?
	local lowerName
	for _, descendant in ipairs(station:GetDescendants()) do
		if descendant:IsA("Model") then
			lowerName = string.lower(descendant.Name)
			if string.find(lowerName, "egg") then
				return descendant
			end
		end
	end

	for _, descendant in ipairs(station:GetDescendants()) do
		if descendant:IsA("BasePart") then
			lowerName = string.lower(descendant.Name)
			if string.find(lowerName, "egg") then
				return descendant
			end
		end
	end

	local fallback = station:FindFirstChildWhichIsA("Model", true)
	if fallback then
		return fallback
	end
	return station:FindFirstChildWhichIsA("BasePart", true)
end

local function attemptRegisterTemplate(eggId: string, station: Instance, attempt: number?)
	local tries = attempt or 0
	local hasTemplateFn = _G.PetSystem_HasEggTemplate
	if typeof(hasTemplateFn) == "function" and hasTemplateFn(eggId) then
		return
	end

	local registerFn = _G.PetSystem_RegisterEggTemplate
	if typeof(registerFn) ~= "function" then
		if tries < 8 then
			task.delay(0.5, function()
				attemptRegisterTemplate(eggId, station, tries + 1)
			end)
		end
		return
	end

	local visual = findEggVisual(station)
	if not visual then
		if tries < 8 then
			task.delay(0.5, function()
				attemptRegisterTemplate(eggId, station, tries + 1)
			end)
		else
			warn(string.format("[SetupEggPrompts] Unable to locate egg visual for '%s' at %s", eggId, station:GetFullName()))
		end
		return
	end

	registerFn(eggId, visual)
end

local function ensurePromptForStation(station: Instance, eggId: string)
    local egg = getEggInfo(eggId)

	local host = getHostPart(station)
	if not host then
		warn(string.format("[SetupEggPrompts] Could not locate BasePart for %s", station:GetFullName()))
		return
	end

	host:SetAttribute("EggId", eggId)
	host:SetAttribute("EggPrice", egg.price)

	local prompt = host:FindFirstChild("EggPurchasePrompt")
	if prompt and not prompt:IsA("ProximityPrompt") then
		prompt = nil
	end

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EggPurchasePrompt"
		prompt.Parent = host
	end

	prompt:SetAttribute("EggId", eggId)
	prompt.ActionText = "Hold E"
    prompt.ObjectText = string.format("%s - %s$", egg.displayName, formatPrice(egg.price))
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = HOLD_DURATION
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.Enabled = true

	task.defer(function()
		attemptRegisterTemplate(eggId, station)
	end)
end

local function findStationsRoot(): Instance?
	local current: Instance = workspace
	for _, segment in ipairs(STATIONS_ROOT_PATH) do
		local nextNode = current:FindFirstChild(segment)
		if not nextNode then
			return nil
		end
		current = nextNode
	end
	return current
end

local function setupAllStations()
	local root = findStationsRoot()
	if not root then
		warn("[SetupEggPrompts] Could not find workspace folder 'Pet Egg Stations'")
		return
	end

	for stationName, eggId in pairs(STATION_TO_EGG) do
		local station = root:FindFirstChild(stationName)
		if station then
			ensurePromptForStation(station, eggId)
		else
			warn(string.format("[SetupEggPrompts] Station '%s' not found under %s", stationName, root:GetFullName()))
		end
	end
end

setupAllStations()

workspace.DescendantAdded:Connect(function(instance)
	local parent = instance.Parent
	if not parent then
		return
	end

	local root = findStationsRoot()
	if not root or not instance:IsDescendantOf(root) then
		return
	end

	for stationName, eggId in pairs(STATION_TO_EGG) do
		if instance.Name == stationName or parent.Name == stationName then
			local station = instance.Name == stationName and instance or parent
			ensurePromptForStation(station, eggId)
			break
		end
	end
end)

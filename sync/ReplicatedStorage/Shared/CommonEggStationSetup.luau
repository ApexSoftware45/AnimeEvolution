-- ReplicatedStorage/Shared/CommonEggStationSetup.luau
-- Utility so workspace egg stations can self-register with the server egg system.

local CollectionService = game:GetService("CollectionService")

local STATION_TAG = "CommonEggStation"
local ATTRIBUTE_FLAG = "IsCommonEggStation"

local function findRoot(instance: Instance): Instance
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true) or instance
	end
	return instance
end

return function(rootInstance: Instance, config: {EggId: string?, Price: number?}?): ()
	local target = findRoot(rootInstance)
	if not target then
		warn("[CommonEggStationSetup] Could not determine a base part to tag.")
		return
	end

	CollectionService:AddTag(target, STATION_TAG)
	target:SetAttribute(ATTRIBUTE_FLAG, true)

	if config then
		if typeof(config.EggId) == "string" then
			target:SetAttribute("EggId", config.EggId)
		end
		if typeof(config.Price) == "number" then
			target:SetAttribute("EggPrice", config.Price)
		end
	end
end

-- ReplicatedStorage/Shared/RareEggStationSetup.luau
-- Helper to tag workstation parts/models as rare egg stations.

local CollectionService = game:GetService("CollectionService")

local STATION_TAG = "RareEggStation"
local ATTRIBUTE_FLAG = "IsRareEggStation"
local TYPE_ATTRIBUTE = "EggStationType"

local function findRoot(instance: Instance): Instance
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true) or instance
	end
	return instance
end

type SetupOptions = {
	EggId: string?,
	Price: number?,
	DisplayName: string?,
}

return function(rootInstance: Instance, options: SetupOptions?)
	local target = findRoot(rootInstance)
	if not target then
		warn("[RareEggStationSetup] Could not determine a base part to tag.")
		return
	end

	CollectionService:AddTag(target, STATION_TAG)
	target:SetAttribute(ATTRIBUTE_FLAG, true)
	target:SetAttribute(TYPE_ATTRIBUTE, "rare")
	target:SetAttribute("EggRarity", "rare")

	if options then
		if typeof(options.EggId) == "string" then
			target:SetAttribute("EggId", options.EggId)
		end
		if typeof(options.Price) == "number" then
			target:SetAttribute("EggPrice", options.Price)
		end
		if typeof(options.DisplayName) == "string" then
			target:SetAttribute("EggDisplayName", options.DisplayName)
		end
	end
end

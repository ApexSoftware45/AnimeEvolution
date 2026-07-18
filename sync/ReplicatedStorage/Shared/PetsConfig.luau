-- ReplicatedStorage/Shared/PetsConfig.luau
-- Thin wrapper kept for backwards compatibility; new modules live alongside this file.

local sharedFolder = script.Parent

local PetData = require(sharedFolder:WaitForChild("PetData"))
local EggData = require(sharedFolder:WaitForChild("EggData"))

local PetsConfig = {}
PetsConfig.Pets = PetData
PetsConfig.Eggs = EggData

function PetsConfig.GetPet(petId: string)
	return PetData[petId]
end

function PetsConfig.GetEgg(eggId: string)
	return EggData[eggId]
end

return PetsConfig

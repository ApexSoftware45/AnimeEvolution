-- Utility functions for weighted pet selection.

local Random = Random

local function resolveRandom(rngOrSeed)
	if typeof(rngOrSeed) == "Random" then
		return rngOrSeed
	end

	if typeof(rngOrSeed) == "number" then
		return Random.new(rngOrSeed)
	end

	return Random.new()
end

local function chooseWeightedPet(petEntries, rngOrSeed)
	assert(typeof(petEntries) == "table", "petEntries must be an array")
	assert(#petEntries > 0, "petEntries cannot be empty")

	local totalWeight = 0
	for _, entry in ipairs(petEntries) do
		local weight = entry.Weight or entry.weight
		assert(typeof(weight) == "number", "Each pet entry must include a numeric Weight")
		assert(weight >= 0, "Weights cannot be negative")
		totalWeight += weight
	end

	assert(totalWeight > 0, "Total weight must be greater than zero")

	local rng = resolveRandom(rngOrSeed)
	local threshold = rng:NextNumber() * totalWeight

	local cumulative = 0
	for index, entry in ipairs(petEntries) do
		cumulative += entry.Weight or entry.weight
		if threshold < cumulative then
			return entry.PetId or entry.petId or entry.PetName, entry, index
		end
	end

	-- Fallback in case of floating point rounding.
	local lastEntry = petEntries[#petEntries]
	return lastEntry.PetId or lastEntry.petId or lastEntry.PetName, lastEntry, #petEntries
end

return {
	ChooseWeightedPet = chooseWeightedPet,
}

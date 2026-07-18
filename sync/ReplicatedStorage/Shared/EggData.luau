-- ReplicatedStorage/Shared/EggData.luau
-- Egg definitions that describe shop stations, pricing, and rewards.

local eggs = {
	StarterEgg = {
		Id = "StarterEgg",
		DisplayName = "Starter Egg",
		Price = 1000,
		CurrencyType = "Money",
		AnimationType = "basicCrack",
		Pets = {
			{PetId = "KidNaruto", Weight = 1},
			{PetId = "Krillin", Weight = 1},
			{PetId = "RockLee", Weight = 1},
		},
	},
	RareEgg = {
		Id = "RareEgg",
		DisplayName = "Rare Egg",
		Price = 15000,
		CurrencyType = "Money",
		AnimationType = "basicCrack",
		Pets = {
			{PetId = "Hinata", Weight = 33},
			{PetId = "Neji", Weight = 33},
			{PetId = "Sakura", Weight = 33},
		},
	},
	SpottedRareEgg = {
		Id = "SpottedRareEgg",
		DisplayName = "Spotted Rare Egg",
		Price = 150000,
		CurrencyType = "Money",
		AnimationType = "basicCrack",
		Pets = {
			-- Restore intended odds: Epic ~3%, Rare ~97%
			{Rarity = "Rare", Weight = 97},
			{Rarity = "Epic", Weight = 3},
		},
	},
}

return eggs

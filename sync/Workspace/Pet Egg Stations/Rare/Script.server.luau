local ReplicatedStorage = game:GetService("ReplicatedStorage")
local setupRareEgg = require(ReplicatedStorage.Shared.RareEggStationSetup)

setupRareEgg(script.Parent, {
	EggId = "RareEgg",   -- optional, defaults to RareEgg
	Price = 15000,       -- optional override
	DisplayName = "Rare Egg", -- optional
})
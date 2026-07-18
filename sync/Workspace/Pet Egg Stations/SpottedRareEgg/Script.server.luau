local ReplicatedStorage = game:GetService("ReplicatedStorage")
local setup = require(game.ReplicatedStorage.Shared.RareEggStationSetup)
setup(script.Parent, {
	EggId = "SpottedRareEgg",
	DisplayName = "Spotted Rare Egg",
	Price = 150000,
})
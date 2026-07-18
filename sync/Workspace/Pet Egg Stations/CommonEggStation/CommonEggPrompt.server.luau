local ReplicatedStorage = game:GetService("ReplicatedStorage")
local setupCommonEgg = require(ReplicatedStorage.Shared.CommonEggStationSetup)

setupCommonEgg(script.Parent, {
	EggId = "CommonEgg", -- optional override
	Price = 1000,          -- optional override
})
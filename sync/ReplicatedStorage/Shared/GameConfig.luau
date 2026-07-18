-- Shared Game Configuration Module
-- This module contains configuration shared between client and server

local GameConfig = {}

-- Character Levels
GameConfig.CharacterLevels = {
	[1] = "Kid Naruto",
	[2] = "Kid Sasuke",
	[3] = "Boruto Uzumaki"
}

-- XP Configuration
GameConfig.XP = {
	BaseMax = 100,
	LevelMultiplier = 1.2,
	BoxReward = 10
}

-- Combat Configuration
GameConfig.Combat = {
	PunchDamage = 25,
	PunchRange = 12,
	BoxHealth = 100
}

-- Animation IDs
GameConfig.Animations = {
	R15 = {
		Idle = "rbxassetid://2510196951",
		Walk = "rbxassetid://2510197830",
		Run = "rbxassetid://2510198475",
		Jump = "rbxassetid://2510197830",
		Punch = "rbxassetid://103752860008283"
	},
	R6 = {
		Idle = "rbxassetid://180435571",
		Walk = "rbxassetid://180426354",
		Run = "rbxassetid://180426354",
		Jump = "rbxassetid://180436148",
		Punch = "rbxassetid://119818896833456"
	}
}

-- Sound Effects
GameConfig.Sounds = {
	Punch = "rbxassetid://566593606",
	BoxHit = "rbxassetid://566593606",
	BoxDestroy = "rbxassetid://566593606"
}

return GameConfig

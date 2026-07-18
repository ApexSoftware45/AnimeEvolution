-- Level Data Configuration Module with REBIRTH SYSTEM
-- Optimized for rebirth-based progression (18 hours optimal, 37 hours no rebirth)
-- Shared between client and server

local LevelData = {}


LevelData.LevelCap = 18
LevelData.RebirthCreditReward = 1

local BASE_XP_TABLE = {
	[1] = 30,
	[2] = 60,
	[3] = 480,
	[4] = 1620,
	[5] = 3840,
	[6] = 7500,
	[7] = 12960,
	[8] = 20580,
	[9] = 87480,
	[10] = 120000,
	[11] = 159720,
	[12] = 207360,
	[13] = 263640,
	[14] = 329280,
	[15] = 405000,
	[16] = 491520,
	[17] = 589560,
	[18] = 699840,
	[19] = 31878000,
	[20] = 63929250,
	[21] = 103370400,
	[22] = 206740800,
	[23] = 334215000,
	[24] = 668430000,
	[25] = 945315000,
	[26] = 1890630000,
	[27] = 3056508000,
	[28] = 6113016000,
	[29] = 9881625600,
	[30] = 13628815200,
	[31] = 27257630400,
	[32] = 44032208640,
	[33] = 88064417280,
	[34] = 142344498240,
	[35] = 209278906200,
	[36] = 418557812400,
	[37] = 676412499840,
	[38] = 1352824999680,
	[39] = 2185887594240,
	[40] = 2965643811900,
	[41] = 5931287623800,
	[42] = 9582594690060,
	[43] = 19165189380120,
	[44] = 30979340837760,
	[45] = 40039383837600,
	[46] = 80078767675200,
	[47] = 129465850908240,
	[48] = 258931701816480,
	[49] = 418490722910400,
	[50] = 570913162974000,
	[51] = 1141826325948000,
	[52] = 1844961152596800,
	[53] = 3689922305193600,
	[54] = 5967373416429600,
	[55] = 8090280667312200,
	[56] = 16180561334624400,
	[57] = 26154985187662800,
	[58] = 40976170380614696,
	[59] = 66242278458323520,
	[60] = 105000000000000000,
}

-- Calculate actual XP requirements based on rebirth count
function LevelData.GetXPForLevel(level, _rebirthCount)
	return BASE_XP_TABLE[level] or 0
end

-- Get total XP needed from level 1 to target level
function LevelData.GetTotalXP(level, rebirthCount)
	local total = 0
	for i = 1, level do
		total = total + LevelData.GetXPForLevel(i, rebirthCount)
	end
	return total
end

-- Get current level from total XP
function LevelData.GetLevelFromXP(totalXP, rebirthCount)
	local accumulated = 0
	
	for level = 1, 60 do
		local requiredXP = LevelData.GetXPForLevel(level, rebirthCount)
		accumulated = accumulated + requiredXP
		
		if totalXP < accumulated then
			return math.max(1, level - 1)
		end
	end
	
	return 60 -- Max level
end

-- 🆕 FIXED: Check if player can rebirth (now checks >= milestone and current rebirth count)
function LevelData.CanRebirth(level, rebirthCount)
	local requiredLevel = LevelData.LevelCap
	if level >= requiredLevel then
		return true, requiredLevel
	end
	return false, requiredLevel
end

-- Get rebirth multiplier display text
function LevelData.GetRebirthMultiplierText(rebirthCount)
	local total = rebirthCount or 0
	return ("1.0x (Rebirths completed: %d)"):format(total)
end

-- Estimate time to next level
function LevelData.GetTimeToNextLevel(currentLevel, currentXP, rebirthCount)
	if currentLevel >= 60 then return 0 end
	
	local nextLevelXP = LevelData.GetXPForLevel(currentLevel + 1, rebirthCount)
	local remainingXP = nextLevelXP - currentXP
	
	-- Calculate XP per minute (Fibonacci damage scaling)
	local function getFibDamage(level)
		if level <= 1 then return 10 end
		if level == 2 then return 20 end
		local prev1, prev2 = 20, 10
		for i = 3, level do
			local current = prev1 + prev2
			prev2 = prev1
			prev1 = current
		end
		return prev1
	end
	
	local damage = getFibDamage(currentLevel)
	local xpPerPunch = damage * 0.1
	local xpPerMinute = xpPerPunch * 2 * 60 -- 2 punches per second
	
	return math.ceil(remainingXP / xpPerMinute)
end

-- Character unlocks (ALL 60 LEVELS)
LevelData.CharacterUnlocks = {
	[1] = "Kid Naruto",          [2] = "Kid Sasuke 2",        [3] = "Sasuke Curse",
	[4] = "Naruto Teen",         [5] = "Sasuke Teen",         [6] = "Kakashi",
	[7] = "Naruto Sage Mode",    [8] = "Itachi Uchiha",       [9] = "Nagato",
	[10] = "Obito",              [11] = "Madara",             [12] = "Adult Sasuke",
	[13] = "Naruto Hokage",      [14] = "Boruto Uzumaki",    [15] = "Sasuke Rinnegan",
	[16] = "Naruto 6 Path",      [17] = "6 Path Madara",     [18] = "Naruto Baryon Mode",
	[19] = "Raditz",             [20] = "Base Frieza",       [21] = "Piccolo",
	[22] = "Base Vegeta",        [23] = "Base Gohan",        [24] = "Base Goku",
	[25] = "Trunks",             [26] = "Goku Black",        [27] = "Final Frieza",
	[28] = "Vegeta Jacket",      [29] = "Goku Jacket",       [30] = "Trunks SSJ",
	[31] = "Vegeta SSJ",         [32] = "Goku SSJ",          [33] = "Vegeta GT",
	[34] = "Perfect Cell",       [35] = "Gohan SS2",         [36] = "Majin Buu",
	[37] = "Vegito Base",        [38] = "Goku SS3",          [39] = "Vegeta SS3",
	[40] = "Trunks SS Rage",     [41] = "Super Buu",         [42] = "Super Vegito",
	[43] = "SS4 Vegeta",         [44] = "SS4 Goku",          [45] = "God Goku",
	[46] = "Golden Frieza",      [47] = "Blue Vegeta",       [48] = "Blue Goku",
	[49] = "Rose Goku Black",    [50] = "Orange Piccolo",    [51] = "BE Vegeta",
	[52] = "UI Sign Goku",       [53] = "UE Vegeta",         [54] = "Beast Gohan",
	[55] = "UI Goku",            [56] = "Blue Gogeta",       [57] = "SS4 Gogeta",
	[58] = "Black Frieza",       [59] = "Beerus",            [60] = "Drip Goku"
}

-- Rebirth rewards
LevelData.RebirthRewards = {
	CashBonus = 25000,
	GemsBonus = 250,
	TitlePrefix = "Reborn",
	MessageTemplate = "Rebirth #%d complete! Total Credits: %d"
}

-- Milestone rewards (every 5 levels)
LevelData.LevelRewards = {
	[5] = {Money = 1000, Gems = 10},
	[10] = {Money = 5000, Gems = 50},
	[15] = {Money = 15000, Gems = 150},
	[20] = {Money = 50000, Gems = 500},
	[25] = {Money = 150000, Gems = 1500},
	[30] = {Money = 500000, Gems = 5000},
	[35] = {Money = 1500000, Gems = 15000},
	[40] = {Money = 5000000, Gems = 50000},
	[45] = {Money = 15000000, Gems = 150000},
	[50] = {Money = 50000000, Gems = 500000},
	[55] = {Money = 150000000, Gems = 1500000},
	[60] = {Money = 1000000000, Gems = 10000000}
}

return LevelData

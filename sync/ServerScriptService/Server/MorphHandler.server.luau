-- Server Script - Handles character morphing requests from clients
-- Synced via Rojo to ServerScriptService
-- ALL 60 CHARACTERS MAPPED

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local COOLDOWN_TIME = 2

-- Track player cooldowns
local playerCooldowns = {}

-- Find or create RemoteEvent
local morphEvent = ReplicatedStorage:FindFirstChild("MorphEvent")
if not morphEvent then
	morphEvent = Instance.new("RemoteEvent")
	morphEvent.Name = "MorphEvent"
	morphEvent.Parent = ReplicatedStorage
	print("✅ Created MorphEvent in ReplicatedStorage")
end

-- 🆕 COMPLETE CHARACTER MAPPING - ALL 60 LEVELS
local CHARACTER_TO_LEVEL = {
	-- NARUTO CHARACTERS (1-18)
	["Kid Naruto"] = 1,
	["Kid Sasuke"] = 2,
	["Kid Sasuke 2"] = 2,
	["Sasuke Curse"] = 3,
	["Naruto Teen"] = 4,
	["Sasuke Teen"] = 5,
	["Kakashi"] = 6,
	["Naruto Sage Mode"] = 7,
	["Itachi Uchiha"] = 8,
	["Nagato"] = 9,
	["Obito"] = 10,
	["Madara"] = 11,
	["Adult Sasuke"] = 12,
	["Naruto Hokage"] = 13,
	["Boruto Uzumaki"] = 14,
	["Sasuke Rinnegan"] = 15,
	["Naruto 6 Path"] = 16,
	["6 Path Madara"] = 17,
	["Naruto Baryon Mode"] = 18,
	
	-- DRAGON BALL CHARACTERS (19-60)
	["Raditz"] = 19,
	["Base Frieza"] = 20,
	["Piccolo"] = 21,
	["Base Vegeta"] = 22,
	["Base Gohan"] = 23,
	["Base Goku"] = 24,
	["Trunks"] = 25,
	["Goku Black"] = 26,
	["Final Frieza"] = 27,
	["Vegeta Jacket"] = 28,
	["Goku Jacket"] = 29,
	["Trunks SSJ"] = 30,
	["Vegeta SSJ"] = 31,
	["Goku SSJ"] = 32,
	["Vegeta GT"] = 33,
	["Perfect Cell"] = 34,
	["Gohan SS2"] = 35,
	["Majin Buu"] = 36,
	["Vegito Base"] = 37,
	["Goku SS3"] = 38,
	["Vegeta SS3"] = 39,
	["Trunks SS Rage"] = 40,
	["Super Buu"] = 41,
	["Super Vegito"] = 42,
	["SS4 Vegeta"] = 43,
	["SS4 Goku"] = 44,
	["God Goku"] = 45,
	["Golden Frieza"] = 46,
	["Blue Vegeta"] = 47,
	["Blue Goku"] = 48,
	["Rose Goku Black"] = 49,
	["Orange Piccolo"] = 50,
	["BE Vegeta"] = 51,
	["UI Sign Goku"] = 52,
	["UE Vegeta"] = 53,
	["Beast Gohan"] = 54,
	["UI Goku"] = 55,
	["Blue Gogeta"] = 56,
	["SS4 Gogeta"] = 57,
	["Black Frieza"] = 58,
	["Beerus"] = 59,
	["Drip Goku"] = 60,
}

-- Function to morph player using ModularTransformation system
local function morphPlayer(player, characterName)
	print("🔄 Morph request - Player:", player.Name, "Character:", characterName)
	
	if not player or not player.Character then
		warn("❌ Invalid player or character")
		return false
	end
	
	-- Check cooldown
	local currentTime = tick()
	if playerCooldowns[player.UserId] and (currentTime - playerCooldowns[player.UserId]) < COOLDOWN_TIME then
		warn("⏳ Player", player.Name, "is on cooldown")
		return false
	end
	
	-- Find the level for this character name
	local targetLevel = CHARACTER_TO_LEVEL[characterName]
	if not targetLevel then
		warn("❌ Character name not found in mapping:", characterName)
		warn("Available characters: Type _G.listMorphCharacters() to see all")
		return false
	end
	
	print("📋 Found character mapping:", characterName, "-> Level", targetLevel)
	
	-- Use the global transformation function
	if not _G.transformPlayerSeamless then
		warn("❌ ModularTransformation system not loaded!")
		return false
	end
	
	-- Call seamless transformation (false = no loading screen for manual morphs)
	local success = _G.transformPlayerSeamless(player, targetLevel, false)
	
	if success then
		playerCooldowns[player.UserId] = currentTime
		print("✅ Successfully morphed", player.Name, "into", characterName, "(Level", targetLevel .. ")")
		return true
	else
		warn("❌ Transformation failed for", player.Name)
		return false
	end
end

-- Handle morph requests
morphEvent.OnServerEvent:Connect(function(player, characterName)
	print("📥 Morph request received from:", player.Name, "Character:", characterName)
	
	if type(characterName) ~= "string" then
		warn("❌ Invalid character name type from:", player.Name)
		return
	end
	
	local success = morphPlayer(player, characterName)
	
	if success then
		print("🎉 Morph successful for", player.Name)
	else
		warn("❌ Morph failed for", player.Name)
	end
end)

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

-- Debug commands
_G.listMorphCharacters = function()
	print("📋 Available Morph Characters:")
	local sorted = {}
	for name, level in pairs(CHARACTER_TO_LEVEL) do
		table.insert(sorted, {name = name, level = level})
	end
	table.sort(sorted, function(a, b) return a.level < b.level end)
	
	print("\n🍥 NARUTO CHARACTERS:")
	for _, char in ipairs(sorted) do
		if char.level <= 18 then
			print("  Level " .. char.level .. " - " .. char.name)
		end
	end
	
	print("\n🐉 DRAGON BALL CHARACTERS:")
	for _, char in ipairs(sorted) do
		if char.level >= 19 then
			print("  Level " .. char.level .. " - " .. char.name)
		end
	end
end

_G.morphPlayerTo = function(playerName, characterName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		warn("❌ Player not found:", playerName)
		return false
	end
	return morphPlayer(player, characterName)
end

print("✅ Morph Handler loaded with ALL 60 characters!")
print("🍥 Naruto characters: 1-18")
print("🐉 Dragon Ball characters: 19-60")
print("💡 Commands: _G.listMorphCharacters(), _G.morphPlayerTo(playerName, characterName)")

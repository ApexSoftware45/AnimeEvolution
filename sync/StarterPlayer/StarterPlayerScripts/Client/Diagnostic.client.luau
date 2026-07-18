-- Diagnostic Script - Check What's Running
-- Place this in StarterPlayerScripts to see what's actually loading

print("🔍 DIAGNOSTIC: Checking all systems...")

-- Check if we're in the right location
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if player then
	print("✅ LocalPlayer found:", player.Name)
else
	print("❌ LocalPlayer not found")
end

-- Check PlayerGui
local playerGui = player and player:WaitForChild("PlayerGui")
if playerGui then
	print("✅ PlayerGui found")
	
	-- Check for XP folder
	wait(3) -- Wait for StarterGui to copy
	local xpFolder = playerGui:FindFirstChild("XP")
	if xpFolder then
		print("✅ XP folder found with contents:")
		for _, child in pairs(xpFolder:GetChildren()) do
			print("   -", child.Name, "(" .. child.ClassName .. ")")
		end
	else
		print("❌ XP folder not found in PlayerGui")
		print("📋 PlayerGui contents:")
		for _, child in pairs(playerGui:GetChildren()) do
			print("   -", child.Name)
		end
	end
end

-- Check ReplicatedStorage for RemoteEvents
local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("📋 ReplicatedStorage contents:")
for _, child in pairs(ReplicatedStorage:GetChildren()) do
	print("   -", child.Name, "(" .. child.ClassName .. ")")
end

-- Check for specific RemoteEvents
local xpEvent = ReplicatedStorage:FindFirstChild("XPDataChanged")
local soundEvents = {
	ReplicatedStorage:FindFirstChild("PlaySound"),
	ReplicatedStorage:FindFirstChild("StopSound"), 
	ReplicatedStorage:FindFirstChild("UpdateSoundVolume")
}

print("🔍 RemoteEvent Status:")
print("   XPDataChanged:", xpEvent and "FOUND" or "NOT FOUND")
print("   PlaySound:", soundEvents[1] and "FOUND" or "NOT FOUND")
print("   StopSound:", soundEvents[2] and "FOUND" or "NOT FOUND") 
print("   UpdateSoundVolume:", soundEvents[3] and "FOUND" or "NOT FOUND")

-- Check for _G functions (from server scripts)
spawn(function()
	wait(5) -- Wait for server scripts to load
	print("🔍 Global Function Status:")
	print("   _G.SoundController:", _G.SoundController and "FOUND" or "NOT FOUND")
	print("   _G.playBoxHitSound:", _G.playBoxHitSound and "FOUND" or "NOT FOUND")
	print("   _G.addXP:", _G.addXP and "FOUND" or "NOT FOUND")
	print("   _G.getPlayerLevel:", _G.getPlayerLevel and "FOUND" or "NOT FOUND")
end)

-- Set up global test functions
_G.diagnosticTest = function()
	print("🧪 Diagnostic Test Running...")
	print("✅ Client script is working!")
	return "CLIENT_OK"
end

_G.testXPFolder = function()
	local xpFolder = playerGui:FindFirstChild("XP")
	if xpFolder then
		print("✅ XP folder found in test")
		for _, child in pairs(xpFolder:GetChildren()) do
			print("   -", child.Name, "Type:", child.ClassName)
			if child.Name == "XP Bar" then
				print("     Size:", child.Size)
				print("     Position:", child.Position)
				if child:IsA("ImageLabel") then
					print("     ImageTransparency:", child.ImageTransparency)
				end
			end
		end
		return true
	else
		print("❌ XP folder not found in test")
		return false
	end
end

_G.testSoundSystem = function()
	print("🎵 Testing sound system...")
	local updateVolume = ReplicatedStorage:FindFirstChild("UpdateSoundVolume")
	if updateVolume then
		print("✅ UpdateSoundVolume found, testing...")
		updateVolume:FireServer("SFX", 0.5)
		print("🔊 Sent volume update test")
	else
		print("❌ UpdateSoundVolume not found")
	end
end

print("✅ Diagnostic script loaded!")
print("📝 Test commands:")
print("   _G.diagnosticTest() - Test if client script works")
print("   _G.testXPFolder() - Test XP folder access") 
print("   _G.testSoundSystem() - Test sound system")

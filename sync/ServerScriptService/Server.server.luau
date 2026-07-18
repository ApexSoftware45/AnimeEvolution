-- Server Initialization Script
-- This script runs when the server starts

print("🚀 Dragon Ball Game Server Starting...")
print("📋 Loading Systems:")

-- Allow time for all systems to initialize
wait(1)

print("   ✅ XP System Loaded")
print("   ✅ Character Transformation System Loaded")
print("   ✅ Box Spawner Loaded")
print("   ✅ Combat System Ready")

print("🎮 Dragon Ball Game Server Ready!")
print("📝 Admin Commands Available:")
print("   _G.givePlayerXP(playerName, amount) - Give XP to player")
print("   _G.setPlayerLevel(player, level) - Set player level (1-3)")
print("   _G.transformPlayer(player, level) - Transform player character")
print("   _G.testPunch(playerName) - Test punch animation")
-- ServerScriptService/init.server.luau (add this chunk)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- create once so clients can call it
if not ReplicatedStorage:FindFirstChild("BuyEggEvent") then
    local ev = Instance.new("RemoteEvent")
    ev.Name = "BuyEggEvent"
    ev.Parent = ReplicatedStorage
end

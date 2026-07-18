-- Damage Numbers Server Setup
-- Creates the RemoteEvent for damage numbers
-- Provides global functions for showing damage

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for showing damage numbers
local showDamageEvent = ReplicatedStorage:FindFirstChild("ShowDamageNumber")
if not showDamageEvent then
	showDamageEvent = Instance.new("RemoteEvent")
	showDamageEvent.Name = "ShowDamageNumber"
	showDamageEvent.Parent = ReplicatedStorage
	print("✅ Created ShowDamageNumber RemoteEvent")
else
	print("✅ ShowDamageNumber RemoteEvent already exists")
end

-- Global function to show damage numbers to a specific player
_G.showDamageNumber = function(player, damage, position)
	if player and damage and position then
		-- Fire to the specific player who dealt the damage
		showDamageEvent:FireClient(player, damage, position)
		print("💥 Sent damage number to " .. player.Name .. ": " .. damage .. " at " .. tostring(position))
	end
end

-- Optional: Function to show damage to all players (for bosses, etc.)
_G.showDamageNumberToAll = function(damage, position)
	if damage and position then
		showDamageEvent:FireAllClients(damage, position)
		print("💥 Sent damage number to all players: " .. damage)
	end
end

print("✅ Damage Numbers Server Setup complete!")
print("🎯 Use _G.showDamageNumber(player, damage, position) to show damage numbers")

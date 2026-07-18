-- NPC Respawn Script
-- Place this script in ServerScriptService

local npcModel = workspace:WaitForChild("enemy") -- CHANGE THIS to your NPC's name
local RESPAWN_DELAY = 8 -- Time in seconds before respawn

-- Store the original NPC as a template
local npcTemplate = npcModel:Clone()
local spawnPosition = npcModel:FindFirstChild("HumanoidRootPart").CFrame

-- Function to respawn the NPC
local function respawnNPC()
	wait(RESPAWN_DELAY)

	-- Create a new NPC from the template
	local newNPC = npcTemplate:Clone()
	newNPC.Parent = workspace

	-- Set position
	if newNPC:FindFirstChild("HumanoidRootPart") then
		newNPC.HumanoidRootPart.CFrame = spawnPosition
	end

	-- Setup death detection for the new NPC
	local humanoid = newNPC:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		wait(3) -- Wait for death animation
		newNPC:Destroy()
		respawnNPC() -- Respawn again
	end)
end

-- Setup initial death detection
local humanoid = npcModel:WaitForChild("Humanoid")
humanoid.Died:Connect(function()
	wait(3) -- Wait for death animation
	npcModel:Destroy()
	respawnNPC()
end)

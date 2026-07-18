-- Camera Follow LocalScript
-- This script ensures the camera follows the player's character

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Function to set camera subject
local function setCameraSubject()
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
		camera.CameraType = Enum.CameraType.Custom
		print("Camera now following character")
	end
end

-- Set camera subject when character spawns
player.CharacterAdded:Connect(setCameraSubject)

-- Set it immediately if character already exists
if player.Character then
	setCameraSubject()
end

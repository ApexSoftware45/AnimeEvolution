-- EggCutscene.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("EggCutsceneEvent")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local petDataModule = sharedFolder:FindFirstChild("PetData")
local PetData = {}
if petDataModule and petDataModule:IsA("ModuleScript") then
	PetData = require(petDataModule)
end

-- Main function: plays the egg cracking animation
event.OnClientEvent:Connect(function(eggModel, petName)
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	-- Create clone of the egg model for the animation
	local eggClone = eggModel:Clone()
	eggClone.Parent = workspace
	local eggOffset = CFrame.new(0, 3, -8)
	eggClone:PivotTo(root.CFrame * eggOffset) -- in front of player with more breathing room

	-- Focus camera on the egg
	Camera.CameraType = Enum.CameraType.Scriptable
	local startCFrame = Camera.CFrame
	local eggPivot = eggClone:GetPivot()
	local focusPosition = eggPivot.Position + Vector3.new(0, 1.5, 0)
	local cameraPosition = (root.CFrame * CFrame.new(0, 8, -2)).Position
	local eggCFrame = CFrame.new(cameraPosition, focusPosition)
	TweenService:Create(Camera, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {CFrame = eggCFrame}):Play()

	task.wait(1.0)

	-- Shake animation
	for i = 1, 6 do
		TweenService:Create(eggClone.PrimaryPart, TweenInfo.new(0.08), {
			CFrame = eggClone.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(8))
		}):Play()
		task.wait(0.08)
		TweenService:Create(eggClone.PrimaryPart, TweenInfo.new(0.08), {
			CFrame = eggClone.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(-8))
		}):Play()
		task.wait(0.08)
	end

	-- Crack effect
	local crack = Instance.new("ParticleEmitter")
	crack.Texture = "rbxassetid://10791488641" -- crack spark texture
	crack.Rate = 30
	crack.Lifetime = NumberRange.new(0.5)
	crack.Speed = NumberRange.new(1, 2)
	crack.Parent = eggClone.PrimaryPart
	task.wait(0.8)

	-- Flash + destroy egg
	local flash = Instance.new("PointLight")
	flash.Brightness = 5
	flash.Range = 8
	flash.Color = Color3.fromRGB(255, 255, 255)
	flash.Parent = eggClone.PrimaryPart
	TweenService:Create(flash, TweenInfo.new(0.3), {Brightness = 0}):Play()
	task.wait(0.3)

	eggClone:Destroy()

	-- Spawn pet model
	local petTemplate = ReplicatedStorage:WaitForChild("Pets"):FindFirstChild(petName)
	if petTemplate then
		local pet = petTemplate:Clone()
		pet.Parent = workspace
		local previewPosition = root.CFrame * CFrame.new(0, 2, -6)
		pet:PivotTo(previewPosition)

		local definition = PetData[petName]
		if definition and typeof(definition.Scale) == "number" then
			pcall(function()
				pet:ScaleTo(definition.Scale)
			end)
		end

		local primary = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart", true)
		if primary then
			primary.Anchored = true
		end
		for _, descendant in ipairs(pet:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end

		-- Pet sparkle effect
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxassetid://243098098" -- sparkle texture
		sparkle.Rate = 40
		sparkle.Lifetime = NumberRange.new(0.7)
		sparkle.Speed = NumberRange.new(2, 3)
		sparkle.Parent = primary

		task.wait(2)
		sparkle.Enabled = false
		task.delay(0.5, function()
			sparkle:Destroy()
		end)
		Debris:AddItem(pet, 1.5)
	end

	-- Reset camera
	TweenService:Create(Camera, TweenInfo.new(1.0), {CFrame = startCFrame}):Play()
	task.wait(1)
	Camera.CameraType = Enum.CameraType.Custom
end)

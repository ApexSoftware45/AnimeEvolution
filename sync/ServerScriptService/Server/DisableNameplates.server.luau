--!strict
-- Removes default Roblox humanoid nameplates for all characters/NPCs.

local Workspace = game:GetService("Workspace")

local function disableNameplate(humanoid: Humanoid?)
	if not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	if descendant:IsA("Humanoid") then
		disableNameplate(descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Humanoid") then
		disableNameplate(descendant)
	end
end)

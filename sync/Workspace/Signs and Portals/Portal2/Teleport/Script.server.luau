local portal_name = "Portal1" --Portal Name here
local portal = script.Parent.Parent.Parent:FindFirstChild(portal_name)

script.Parent.Touched:Connect(function(hit)
	if game.Players:GetPlayerFromCharacter(hit.Parent) then
		local humanoidRootPart = hit.Parent:WaitForChild("HumanoidRootPart")
		
		humanoidRootPart.CFrame = CFrame.new(portal.Teleport.Position.X + 5,portal.Teleport.Position.Y,portal.Teleport.Position.Z)
	end
end)
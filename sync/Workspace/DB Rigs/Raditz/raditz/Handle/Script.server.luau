debounce = true

function onTouched(hit)
	if (hit.Parent:findFirstChild("Humanoid") ~= nil and debounce == true) then
		debounce = false
		local h = Instance.new("Hat")
		local p = script.Parent:Clone()
		h.Name = "Hair"
		p.Parent = h
		p.Position = hit.Parent:findFirstChild("Head").Position
		p.Name = "Handle"
		p.Size = Vector3.new(1,1,1)
		p.Anchored = false
		p.CanCollide = false
		p.Locked = true
		p:WaitForChild("Script"):Destroy()
		h.Parent = hit.Parent
		h.AttachmentForward = Vector3.new(0, -.2, 1)
		h.AttachmentPos = Vector3.new(-0.05, 1.35, 1.62)

		wait(5)
		debounce = true
	end
end

script.Parent.Touched:connect(onTouched)
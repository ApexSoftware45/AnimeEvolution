debounce = true
function onTouched(hit)
	if (hit.Parent:findFirstChild("Humanoid") ~= nil and debounce == true) then
local j = hit.Parent:findFirstChild("Humanoid") 
if j~= nil then 
c = hit.Parent:GetChildren() 
for i = 1, #c do 
if (c[i].className == "Hat") or (c[i].className == "Accoutrement") then 
c[i]:Remove() 
end 
end 
end  
		debounce = false
		h = Instance.new("Hat")
		p = Instance.new("Part")
		h.Name = "Cloud"
		p.Parent = h
		p.Position = hit.Parent:findFirstChild("Head").Position
		p.Name = "Handle" 
		p.formFactor = 0
		p.Size = Vector3.new(2, 1, 1) 
		p.BottomSurface = 0 
		p.TopSurface = 0 
		p.Locked = true 
		script.Parent.Mesh:clone().Parent = p
		h.Parent = hit.Parent
		h.AttachmentPos = Vector3.new(0, .1, 0)
		wait(5)
		debounce = true
	end
end

script.Parent.Touched:connect(onTouched)

-- DrQuantumphysics' Hat giver/remover script
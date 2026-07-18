permission = { "Watery" }
Door = script.Parent

function checkOkToLetIn(name)
	for i = 1,#permission do
		if (string.upper(name) == string.upper(permission[i])) then return true end
	end
	return false
end

function onTouched(hit)
		print("Door Hit")
		local human = hit:findFirstChild("Humanoid")
		if (human ~= nil ) then
			print("Human touched door")
			if (checkOkToLetIn(human.Parent.Name)) then
				print("Human passed test")
				hit.Size = Vector3.new(4,2,7)
			end
		end

end

connection = Door.Touched:connect(onTouched)
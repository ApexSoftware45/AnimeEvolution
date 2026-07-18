local debounce = true

function onTouched(part)
	local h = part.Parent:findFirstChild("Humanoid")
	if (h~=nil) and (h.Health ~= 0) then
		local thisplr = game.Players:findFirstChild(h.Parent.Name)
		if (thisplr~=nil) then
				local cash = thisplr:findFirstChild("Checkpoint")
				if (cash ~= nil) then
					debounce = false
					cash.Value = script.Parent.Position
					debounce = true
				end
		end
	end
end

script.Parent.Touched:connect(onTouched)
-- LocalScript for a sprint toggle button. Place under the ImageButton.
local button = script.Parent

if not button or not button:IsA("GuiButton") then
	warn("[SprintButton] Parent is not a GuiButton.")
	return
end

button.AutoButtonColor = false
button.Visible = true

local normalImage = button:GetAttribute("NormalImage") or button.Image
local pressedImage = button:GetAttribute("PressedImage") or button:GetAttribute("ActiveImage") or normalImage

local function setVisual(isEnabled: boolean)
	button.Image = isEnabled and pressedImage or normalImage
	button:SetAttribute("SprintEnabled", isEnabled)
end

local function waitForAPI(timeout: number): boolean
	local remaining = timeout
	while remaining > 0 do
		if typeof(_G.ToggleSprint) == "function" and typeof(_G.GetSprintEnabled) == "function" then
			return true
		end
		task.wait(0.2)
		remaining -= 0.2
	end
	return false
end

if not waitForAPI(5) then
	warn("[SprintButton] Sprint API not ready; button disabled.")
	button.Active = false
	return
end

local ok, current = pcall(function()
	return _G.GetSprintEnabled()
end)
setVisual(ok and current or false)

button.Activated:Connect(function()
	local toggleFn = _G.ToggleSprint
	if typeof(toggleFn) ~= "function" then
		return
	end
	local success, newState = pcall(toggleFn)
	if success then
		setVisual(newState and true or false)
	end
end)

if typeof(_G.SprintChanged) == "RBXScriptSignal" then
	_G.SprintChanged:Connect(function(isEnabled)
		setVisual(isEnabled and true or false)
	end)
end

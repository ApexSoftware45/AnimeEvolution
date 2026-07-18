-- LocalScript placed under the Auto Punch ImageButton.
-- Toggles the backend auto-punch controller and swaps images for states.

local button = script.Parent

if not button or not button:IsA("GuiButton") then
	warn("[AutoPunchButton] Parent is not a GuiButton.")
	return
end

button.AutoButtonColor = false
button.Visible = true

local normalImage = button:GetAttribute("NormalImage") or button.Image
local pressedImage = button:GetAttribute("PressedImage") or button:GetAttribute("ActiveImage") or normalImage

local function setButtonVisual(isEnabled: boolean)
	button.Image = isEnabled and pressedImage or normalImage
	button:SetAttribute("AutoPunchEnabled", isEnabled)
end

local function getAPI()
	return _G.ToggleAutoPunch, _G.GetAutoPunchEnabled, _G.AutoPunchChanged
end

local function waitForAPI(timeout: number?): boolean
	local remaining = timeout or 5
	while remaining > 0 do
		local toggleFn, getFn, _ = getAPI()
		if typeof(toggleFn) == "function" and typeof(getFn) == "function" then
			return true
		end
		task.wait(0.2)
		remaining -= 0.2
	end
	return false
end

if not waitForAPI(5) then
	warn("[AutoPunchButton] Auto punch API not ready; button disabled.")
	button.Active = false
	return
end

local _, getFn, changedSignal = getAPI()
local initialState = false
local success, result = pcall(function()
	return getFn()
end)
if success then
	initialState = result and true or false
end
setButtonVisual(initialState)

button.Activated:Connect(function()
	local toggleFn = _G.ToggleAutoPunch
	if typeof(toggleFn) ~= "function" then
		return
	end
	local ok, newState = pcall(toggleFn)
	if ok then
		setButtonVisual(newState and true or false)
	end
end)

if typeof(changedSignal) == "RBXScriptSignal" then
	changedSignal:Connect(function(isEnabled)
		setButtonVisual(isEnabled and true or false)
	end)
end

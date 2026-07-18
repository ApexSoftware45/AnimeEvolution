-- Mobile jump button controller: shows the jump UI on touch devices and hooks it to the custom jump controller.

local UserInputService = game:GetService("UserInputService")

local button = script.Parent

local function hookButton(button: GuiButton)
	button.Visible = false
	button.Active = true
	button.AutoButtonColor = true

	local function updateVisibility()
		if UserInputService.TouchEnabled then
			button.Visible = true
		else
			button.Visible = false
		end
	end

	updateVisibility()

	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateVisibility)

	button.Activated:Connect(function()
		if typeof(_G.TriggerCustomJump) == "function" then
			_G.TriggerCustomJump()
		end
	end)
end

local guiButton = button:IsA("GuiButton") and button or nil
if guiButton then
	hookButton(guiButton)
else
	warn("[MobileJumpButton] Parent is not a GuiButton")
end

-- 🐾 Pet Button Script (No Sound)
-- Place this inside: StarterGui > visibleButtons > labels > PetButton

local button = script.Parent
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local petsGui = playerGui:WaitForChild("Pets")
local mainFrame = petsGui:WaitForChild("Main Frame")

-- Hide Pets menu by default
mainFrame.Visible = false

-- Toggle open/close on click
button.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible

	-- Optional: smooth fade animation
	if mainFrame.Visible then
		mainFrame.BackgroundTransparency = 1
		for i = 1, 10 do
			mainFrame.BackgroundTransparency = 1 - (i * 0.1)
			task.wait(0.02)
		end
	else
		for i = 1, 10 do
			mainFrame.BackgroundTransparency = i * 0.1
			task.wait(0.02)
		end
	end
end)

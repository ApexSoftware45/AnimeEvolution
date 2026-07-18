local bar = script.Parent.Background.Bar
local text = script.Parent.Background.TextLabel

local currentNum = script.Parent.CurrentValue
local maxNum = script.Parent.MaxValue

local barSmooth = 5

while true do
	local bt = time()
	task.wait()
	local dT = time() - bt
	
	if currentNum.Value > maxNum.Value then
		currentNum.Value = maxNum.Value
	end
	
	local targetSize = UDim2.new(currentNum.Value / maxNum.Value, 0, 1, 0)
	bar.Size = bar.Size:Lerp(targetSize, barSmooth * dT)
	
	text.Text = math.floor(currentNum.Value).. "/" ..math.floor(maxNum.Value)
end
--Script to display the XP bar GUI
--// LocalScript inside: StarterGui > Pets > Main Frame > CloseButton
local TweenService = game:GetService("TweenService")

local closeButton = script.Parent
local mainFrame   = closeButton.Parent
local tweenInfo   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local cached = false
local targets = {}  -- { [obj] = {bg=?, text=?, img=?} }
local busy = false

-- Cache original transparencies once
local function cacheOriginals()
	if cached then return end
	for _, obj in ipairs(mainFrame:GetDescendants()) do
		local t = {}
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			t.bg = obj.BackgroundTransparency
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			t.bg   = obj.BackgroundTransparency
			t.text = obj.TextTransparency
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			t.bg  = obj.BackgroundTransparency
			t.img = obj.ImageTransparency
		end
		if next(t) ~= nil then
			targets[obj] = t
		end
	end
	cached = true
end

local function tweenTo(obj, goal)
	local ok, tween = pcall(function()
		return TweenService:Create(obj, tweenInfo, goal)
	end)
	if ok and tween then tween:Play() end
end

local function fadeOutAndHide()
	if busy then return end
	busy = true
	cacheOriginals()

	-- Fade to 1
	for obj, t in pairs(targets) do
		local goal = {}
		if t.bg  ~= nil then goal.BackgroundTransparency = 1 end
		if t.text~= nil then goal.TextTransparency       = 1 end
		if t.img ~= nil then goal.ImageTransparency      = 1 end
		if next(goal) ~= nil then tweenTo(obj, goal) end
	end

	task.wait(tweenInfo.Time + 0.02)
	mainFrame.Visible = false

	-- Restore originals immediately so the next open looks normal
	for obj, t in pairs(targets) do
		if t.bg  ~= nil then obj.BackgroundTransparency = t.bg end
		if t.text~= nil then obj.TextTransparency       = t.text end
		if t.img ~= nil then obj.ImageTransparency      = t.img end
	end

	busy = false
end

closeButton.MouseButton1Click:Connect(fadeOutAndHide)
closeButton.TouchTap:Connect(fadeOutAndHide)

-- StarterPlayerScripts/UI/GuiResponsiveManager.client.luau
-- Keeps UI consistent across devices (auto scaling) and enforces single-menu focus/Z-order.
-- Any ScreenGui can opt out by setting attributes:
--   AutoScale = false        -> skips UIScale injection.
--   AllowMultiple = true     -> menu won't auto-close other menus.
--   IgnoreInset = false      -> respect Roblox top inset instead of full-bleed.
--   PersistentGui = true     -> treated like HUD; never auto-closed or reordered.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

local DESIGN_RESOLUTION = Vector2.new(1920, 1080)
local MIN_SCALE = 0.5
local MAX_SCALE = 1
local BASE_DISPLAY_ORDER = 100
local EXCLUDE_ATTRIBUTE = "ResponsiveIgnore"

local tracked: { [ScreenGui]: {
	ScaleObject: UIScale?,
	AutoScale: boolean,
	Exclusive: boolean,
	Persistent: boolean,
	Connections: { RBXScriptConnection },
} } = {}

local activeOrder = 0

local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled and not GuiService:IsTenFootInterface()
end

local function computeScaleFactor()
	if not isTouchDevice() then
		return 1
	end

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize
	if not viewport or viewport.Magnitude <= 0 then
		viewport = GuiService:GetScreenResolution()
	end

	if not viewport or viewport.Magnitude <= 0 then
		return 1
	end

	local scaleX = viewport.X / DESIGN_RESOLUTION.X
	local scaleY = viewport.Y / DESIGN_RESOLUTION.Y
	local target = math.min(scaleX, scaleY)
	return math.clamp(target, MIN_SCALE, MAX_SCALE)
end

local currentScale = computeScaleFactor()

local function updateScaleForGui(screenGui: ScreenGui)
	local info = tracked[screenGui]
	if not info or not info.AutoScale or not info.ScaleObject then
		return
	end
	info.ScaleObject.Scale = currentScale
end

local function refreshAllScales()
	currentScale = computeScaleFactor()
	for gui in pairs(tracked) do
		updateScaleForGui(gui)
	end
end

local function hookCamera(camera: Camera?)
	if not camera then
		return
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		refreshAllScales()
	end)
end

if workspace.CurrentCamera then
	hookCamera(workspace.CurrentCamera)
else
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hookCamera(workspace.CurrentCamera)
		refreshAllScales()
	end)
end

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
	refreshAllScales()
end)

local function untrackGui(screenGui: ScreenGui)
	local info = tracked[screenGui]
	if not info then
		return
	end
	tracked[screenGui] = nil

	if info.Connections then
		for _, conn in ipairs(info.Connections) do
			conn:Disconnect()
		end
	end
end

local function closeOtherMenus(exceptGui: ScreenGui)
	for gui, info in pairs(tracked) do
		if gui ~= exceptGui and info.Exclusive and not info.Persistent and gui.Enabled then
			gui.Enabled = false
		end
	end
end

local function bringToFront(screenGui: ScreenGui)
	activeOrder += 1
	if activeOrder > 5000 then
		activeOrder = 0
	end
	screenGui.DisplayOrder = BASE_DISPLAY_ORDER + activeOrder
end

local function handleEnabledChange(screenGui: ScreenGui)
	local info = tracked[screenGui]
	if not info or info.Persistent then
		return
	end

	if screenGui.Enabled then
		if info.Exclusive then
			closeOtherMenus(screenGui)
		end
		bringToFront(screenGui)
	end
end

local function ensureScaleObject(screenGui: ScreenGui): UIScale
	local existing = screenGui:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end

	local scale = Instance.new("UIScale")
	scale.Name = "ResponsiveScale"
	scale.Parent = screenGui
	return scale
end

local function shouldManage(screenGui: ScreenGui): boolean
	return screenGui:GetAttribute(EXCLUDE_ATTRIBUTE) ~= true
end

local function trackScreenGui(screenGui: ScreenGui)
	if tracked[screenGui] then
		return
	end

	if not shouldManage(screenGui) then
		return
	end

	local persistent = screenGui:GetAttribute("PersistentGui") == true
	local autoScale = screenGui:GetAttribute("AutoScale") ~= false
	local allowMultiple = screenGui:GetAttribute("AllowMultiple") == true
	local exclusive = screenGui:GetAttribute("ExclusiveMenu") == true

	screenGui.IgnoreGuiInset = screenGui:GetAttribute("IgnoreInset") ~= false

	local info = {
		ScaleObject = nil :: UIScale?,
		AutoScale = autoScale,
		Exclusive = exclusive,
		Persistent = persistent,
		Connections = {},
	}
	tracked[screenGui] = info

	if autoScale then
		info.ScaleObject = ensureScaleObject(screenGui)
		updateScaleForGui(screenGui)
	end

	table.insert(info.Connections, screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		handleEnabledChange(screenGui)
	end))

	table.insert(info.Connections, screenGui.AncestryChanged:Connect(function(_, parent)
		if not parent then
			untrackGui(screenGui)
		end
	end))
	table.insert(info.Connections, screenGui:GetAttributeChangedSignal(EXCLUDE_ATTRIBUTE):Connect(function()
		if not shouldManage(screenGui) then
			untrackGui(screenGui)
		else
			if not tracked[screenGui] then
				trackScreenGui(screenGui)
			end
		end
	end))

	-- Ensure initial state respects ordering.
	handleEnabledChange(screenGui)
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
	if descendant:IsA("ScreenGui") then
		trackScreenGui(descendant)
	end
end

playerGui.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ScreenGui") then
		trackScreenGui(descendant)
	end
end)

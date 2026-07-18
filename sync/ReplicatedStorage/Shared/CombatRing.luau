-- Creates a stylized glowing ring that hovers around a rig/root part so players can read melee range.
-- The effect is built with a transparent plane + SurfaceGui so it stays lightweight while matching modern sim visuals.

local TweenService = game:GetService("TweenService")

local MIN_RADIUS = 1
local PLANE_THICKNESS = 0.05

local DEFAULT_OUTER_COLOR = Color3.fromRGB(255, 196, 64)
local DEFAULT_GLOW_COLOR = Color3.fromRGB(255, 244, 145)
local DEFAULT_INNER_COLOR = Color3.fromRGB(255, 255, 194)
local DEFAULT_STREAK_COLOR = Color3.fromRGB(255, 255, 255)

export type RingConfig = {
	Name: string?,
	Hover: number?,
	VerticalOffset: number?,
	PixelsPerStud: number?,
	AlwaysOnTop: boolean?,
	OuterColor: Color3?,
	GlowColor: Color3?,
	InnerColor: Color3?,
	StreakColor: Color3?,
	FillTransparency: number?,
	OutlineThickness: number?,
	GlowThickness: number?,
	OutlineTransparency: number?,
	GlowTransparency: number?,
	StreakCount: number?,
	StreakSpeed: number?,
	Color: Color3?, -- backwards compatibility fallback for outer/glow color
}

export type RingHandle = {
	updateRadius: (self: RingHandle, radius: number) -> (),
	setVisible: (self: RingHandle, visible: boolean) -> (),
	destroy: (self: RingHandle) -> (),
}

type TweenRef = Tween

local Ring = {}
Ring.__index = Ring

local function findRoot(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end

		local hrp = instance:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end

		return instance:FindFirstChildWhichIsA("BasePart")
	end

	return nil
end

local function computeHalfHeight(target: Instance?, root: BasePart): number
	if target and target:IsA("Model") then
		local ok, size = pcall(function()
			return target:GetExtentsSize()
		end)
		if ok and size then
			return size.Y * 0.5
		end
	end

	return root.Size.Y * 0.5
end

local function computeBaseOffset(target: Instance?, root: BasePart, config: RingConfig?): number
	if config and typeof(config.VerticalOffset) == "number" then
		return config.VerticalOffset
	end

	local hover = (config and config.Hover) or 0.08
	return -computeHalfHeight(target, root) + hover
end

local function createPlane(target: Instance, root: BasePart, radius: number, offset: number, config: RingConfig)
	local plane = Instance.new("Part")
	plane.Name = string.format("%sPlane", config.Name or "CombatRing")
	plane.Anchored = false
	plane.CanCollide = false
	plane.CanTouch = false
	plane.CanQuery = false
	plane.Massless = true
	plane.CastShadow = false
	plane.Transparency = 1
	plane.Size = Vector3.new(math.max(MIN_RADIUS, radius) * 2, PLANE_THICKNESS, math.max(MIN_RADIUS, radius) * 2)
	plane.CFrame = CFrame.new(root.Position) * CFrame.new(0, offset, 0)
	plane.Parent = target

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CombatRingWeld"
	weld.Part0 = root
	weld.Part1 = plane
	weld.Parent = plane

	return plane
end

local function createSurfaceGui(plane: BasePart, config: RingConfig)
	local options = config or {}
	local surface = Instance.new("SurfaceGui")
	surface.Name = "CombatRingGui"
	surface.Face = Enum.NormalId.Top
	surface.Adornee = plane
	if options.AlwaysOnTop == false then
		surface.AlwaysOnTop = false
	else
		surface.AlwaysOnTop = true
	end
	surface.LightInfluence = 0
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = (config.PixelsPerStud and math.max(5, config.PixelsPerStud)) or 35
	surface.CanvasSize = Vector2.new(512, 512)
	surface.ResetOnSpawn = false
	surface.Enabled = true
	surface.Parent = plane

	return surface
end

local function createUICircle(parent: Instance, config: RingConfig, tweenBucket: {TweenRef})
	local innerColor = config.InnerColor or DEFAULT_INNER_COLOR
	local primaryColor = config.OuterColor or config.Color or DEFAULT_OUTER_COLOR
	local glowColor = config.GlowColor or config.Color or DEFAULT_GLOW_COLOR
	local streakColor = config.StreakColor or DEFAULT_STREAK_COLOR

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.Position = UDim2.fromScale(0.5, 0.5)
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.BackgroundColor3 = innerColor
	fill.BackgroundTransparency = config.FillTransparency or 0.35
	fill.BorderSizePixel = 0
	fill.ClipsDescendants = true
	fill.Parent = parent

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, glowColor),
		ColorSequenceKeypoint.new(0.45, innerColor),
		ColorSequenceKeypoint.new(1, innerColor),
	})
	fillGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.65),
	})
	fillGradient.Parent = fill

	local outlineFrame = Instance.new("Frame")
	outlineFrame.Name = "Outline"
	outlineFrame.Size = UDim2.fromScale(1, 1)
	outlineFrame.Position = fill.Position
	outlineFrame.AnchorPoint = fill.AnchorPoint
	outlineFrame.BackgroundTransparency = 1
	outlineFrame.Parent = parent

	local outlineCorner = Instance.new("UICorner")
	outlineCorner.CornerRadius = UDim.new(1, 0)
	outlineCorner.Parent = outlineFrame

	local outlineStroke = Instance.new("UIStroke")
	outlineStroke.Name = "OutlineStroke"
	outlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outlineStroke.Color = primaryColor
	outlineStroke.Thickness = config.OutlineThickness or 8
	outlineStroke.Transparency = config.OutlineTransparency or 0.05
	outlineStroke.Parent = outlineFrame

	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "Glow"
	glowFrame.Size = UDim2.fromScale(1, 1)
	glowFrame.Position = fill.Position
	glowFrame.AnchorPoint = fill.AnchorPoint
	glowFrame.BackgroundTransparency = 1
	glowFrame.Parent = parent

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glowFrame

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Name = "GlowStroke"
	glowStroke.Color = glowColor
	glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke.Thickness = config.GlowThickness or (outlineStroke.Thickness * 1.8)
	glowStroke.Transparency = config.GlowTransparency or 0.55
	glowStroke.Parent = glowFrame

	local streakFolder = Instance.new("Folder")
	streakFolder.Name = "Streaks"
	streakFolder.Parent = fill

	local streakCount = math.clamp(config.StreakCount or 6, 0, 12)
	if streakCount > 0 then
		for index = 1, streakCount do
			local streak = Instance.new("Frame")
			streak.Name = string.format("Streak_%d", index)
			streak.AnchorPoint = Vector2.new(0.5, 0.5)

			local radiusScale = 0.15 + math.random() * 0.25
			local radial = (index / streakCount) * math.pi * 2
			local posX = 0.5 + math.cos(radial) * radiusScale
			local posY = 0.5 + math.sin(radial) * radiusScale

			streak.Position = UDim2.fromScale(posX, posY)
			streak.Size = UDim2.fromScale(0.03, 0.45 + math.random() * 0.15)
			streak.BackgroundColor3 = streakColor
			streak.BackgroundTransparency = 0.15
			streak.Rotation = math.random(-25, 25)
			streak.BorderSizePixel = 0
			streak.Parent = streakFolder

			local streakCorner = Instance.new("UICorner")
			streakCorner.CornerRadius = UDim.new(1, 0)
			streakCorner.Parent = streak

			local streakGradient = Instance.new("UIGradient")
			streakGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			streakGradient.Parent = streak

			local rotateDelta = math.random(10, 25)
			local rotationTween = TweenService:Create(
				streak,
				TweenInfo.new(
					(config.StreakSpeed or (2.5 + math.random())),
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					-1,
					true
				),
				{ Rotation = streak.Rotation + rotateDelta }
			)
			rotationTween:Play()
			table.insert(tweenBucket, rotationTween)

			local drift = Vector2.new(
				math.cos(radial + math.rad(math.random(-15, 15))) * radiusScale,
				math.sin(radial + math.rad(math.random(-15, 15))) * radiusScale
			)
			local driftTween = TweenService:Create(
				streak,
				TweenInfo.new(
					(config.StreakSpeed or 3) + math.random(),
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					-1,
					true
				),
				{ Position = UDim2.fromScale(0.5 + drift.X, 0.5 + drift.Y) }
			)
			driftTween:Play()
			table.insert(tweenBucket, driftTween)
		end
	end
end

function Ring:updateRadius(radius: number)
	self._radius = math.max(MIN_RADIUS, radius)
	if self._plane then
		local clamped = math.max(MIN_RADIUS, self._radius)
		self._plane.Size = Vector3.new(clamped * 2, PLANE_THICKNESS, clamped * 2)
	end
end

function Ring:setVisible(visible: boolean)
	if self._surface then
		self._surface.Enabled = visible
	end
end

function Ring:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	if self._ancestryConn then
		self._ancestryConn:Disconnect()
		self._ancestryConn = nil
	end

	if self._rootConn then
		self._rootConn:Disconnect()
		self._rootConn = nil
	end

	if self._tweens then
		for _, tween in ipairs(self._tweens) do
			if tween then
				tween:Destroy()
			end
		end
		self._tweens = nil
	end

	if self._plane then
		self._plane:Destroy()
		self._plane = nil
	end
end

local CombatRing = {}

function CombatRing.attach(target: Instance, radius: number, config: RingConfig?): RingHandle?
	local root = findRoot(target)
	if not root then
		warn("CombatRing: no valid root for", target:GetFullName())
		return nil
	end

	local options: RingConfig = config or {}
	local offset = computeBaseOffset(target, root, options)
	local plane = createPlane(target, root, radius, offset, options)
	local surface = createSurfaceGui(plane, options)

	local tweens = {}
	createUICircle(surface, options, tweens)

	local controller = setmetatable({
		_target = target,
		_root = root,
		_plane = plane,
		_surface = surface,
		_radius = math.max(MIN_RADIUS, radius),
		_tweens = tweens,
	}, Ring)

	controller._ancestryConn = target.AncestryChanged:Connect(function(_, parent)
		if not parent then
			controller:destroy()
		end
	end)

	controller._rootConn = root.Destroying:Connect(function()
		controller:destroy()
	end)

	return controller
end

return CombatRing

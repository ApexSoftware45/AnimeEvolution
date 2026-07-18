-- ReplicatedStorage/UITheme
-- Centralized colors + helper funcs for all UIs

local Theme = {}

-- 🎨 MASTER PALETTE
Theme.Colors = {
	Background = Color3.fromRGB(15, 15, 18),     -- main windows
	Panel = Color3.fromRGB(25, 25, 32),          -- inner panels/cards
	Header = Color3.fromRGB(8, 8, 12),           -- top bar
	Stroke = Color3.fromRGB(60, 60, 80),         -- borders
	TabActive = Color3.fromRGB(90, 70, 210),     -- active tab
	TabInactive = Color3.fromRGB(28, 28, 36),    -- inactive tab

	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(215, 215, 215),

	Danger = Color3.fromRGB(230, 70, 70),
	Success = Color3.fromRGB(90, 225, 90),
	Warning = Color3.fromRGB(255, 185, 60),

	-- rarity colors (for pets, items, etc.)
	Rarity = {
		Common = Color3.fromRGB(190, 190, 190),
		Uncommon = Color3.fromRGB(110, 210, 130),
		Rare = Color3.fromRGB(80, 150, 230),
		Epic = Color3.fromRGB(175, 90, 255),
		Legendary = Color3.fromRGB(255, 180, 50),
		Mythic = Color3.fromRGB(255, 90, 120),
	}
}

-- 🧱 SHARED RADII
Theme.Radius = {
	Window = UDim.new(0, 14),
	Button = UDim.new(0, 8),
	Card = UDim.new(0, 10),
}

-- ========== HELPER FUNCTIONS ==========

-- style a main window/frame
function Theme.ApplyWindow(frame: Frame)
	frame.BackgroundColor3 = Theme.Colors.Background
	frame.BorderSizePixel = 0

	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Window
	corner.Parent = frame

	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Thickness = 2
	stroke.Parent = frame
end

-- style a header / title bar
function Theme.ApplyHeader(frame: Frame)
	frame.BackgroundColor3 = Theme.Colors.Header
	frame.BorderSizePixel = 0
end

-- style a tab button
function Theme.ApplyTab(button: TextButton | ImageButton, isActive: boolean)
	button.BorderSizePixel = 0
	button.BackgroundColor3 = isActive and Theme.Colors.TabActive or Theme.Colors.TabInactive
	button.TextColor3 = Theme.Colors.TextPrimary

	local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = Theme.Radius.Button
	corner.Parent = button
end

-- style a card (like your pet row)
function Theme.ApplyCard(frame: Frame)
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BorderSizePixel = 0
	local c = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = Theme.Radius.Card
	c.Parent = frame
end

-- rarity text helper
function Theme.GetRarityColor(rarity: string)
	return Theme.Colors.Rarity[rarity] or Theme.Colors.TextPrimary
end

return Theme

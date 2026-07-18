local Players = game:GetService("Players")

local LOCAL_PLAYER = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

type MenuDef = {
	key: string,
	aliases: {string},
	primaryGui: string?,
	primaryFrame: string?,
	guiCandidates: {string},
	frameCandidates: {string},
}

local menuDefs: {MenuDef} = {
	{
		key = "Pets",
		aliases = {"Pets", "Pet"},
		primaryGui = "Pets",
		primaryFrame = "MainFrame",
		guiCandidates = {"Pets", "PetsUI", "PetsGui", "PetInventory"},
		frameCandidates = {"MainFrame", "Main Frame", "PetInventoryFrame"},
	},
	{
		key = "Shop",
		aliases = {"Shop", "Store"},
		primaryGui = "shop",
		primaryFrame = "MainFrame",
		guiCandidates = {"shop", "Shop", "GamepassShop", "ShopUI"},
		frameCandidates = {"MainFrame", "Main Frame", "ShopFrame"},
	},
	{
		key = "Morphs",
		aliases = {"Morphs", "Morph"},
		primaryGui = "Morph",
		primaryFrame = "Morph Full Menu",
		guiCandidates = {"Morph", "Morphs", "MorphMenu", "MorphGui", "MorphsUI"},
		frameCandidates = {"Morph Full Menu", "MorphFullMenu", "MainFrame", "Main Frame", "MorphFrame", "MorphMenuFrame"},
	},
	{
		key = "Abilities",
		aliases = {"Abilities", "Ability", "Skills"},
		primaryGui = "Abilities",
		primaryFrame = "MainFrame",
		guiCandidates = {"Abilities", "Ability", "AbilityMenu", "AbilitiesUI", "SkillsUI"},
		frameCandidates = {"MainFrame", "Main Frame", "AbilitiesFrame", "AbilityFrame"},
	},
	{
		key = "Rebirth",
		aliases = {"Rebirth", "Rebirths"},
		primaryGui = "Rebirth",
		primaryFrame = "MainFrame",
		guiCandidates = {"Rebirth", "RebirthMenu", "RebirthGui", "RebirthUI"},
		frameCandidates = {"MainFrame", "Main Frame", "RebirthFrame"},
	},
	{
		key = "Settings",
		aliases = {"Settings", "Options"},
		primaryGui = "SoundControlGUI",
		primaryFrame = "VolumePanel",
		guiCandidates = {"SoundControlGUI", "Settings", "SettingsUI", "OptionsUI"},
		frameCandidates = {"MainFrame", "Main Frame", "SettingsFrame", "VolumePanel"},
	},
}

local defsByKey: {[string]: MenuDef} = {}
local defsByAlias: {[string]: MenuDef} = {}

local function normalize(value: string?): string
	if typeof(value) ~= "string" then
		return ""
	end
	local lowered = string.lower(value)
	return lowered:gsub("[%s_%-%p]", "")
end

for _, def in ipairs(menuDefs) do
	defsByKey[normalize(def.key)] = def
	for _, alias in ipairs(def.aliases) do
		defsByAlias[normalize(alias)] = def
	end
end

local boundControls: {[GuiObject]: boolean} = {}
local warnedMissingTarget: {[string]: boolean} = {}
local didInitialScan = false
local visibleButtonsRoot: Instance? = nil
local visibleButtonsContainer: Instance? = nil

local function findScreenGuiByName(name: string): ScreenGui?
	local direct = playerGui:FindFirstChild(name)
	if direct and direct:IsA("ScreenGui") then
		return direct
	end

	local wanted = normalize(name)
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and normalize(child.Name) == wanted then
			return child
		end
	end

	return nil
end

local function findScreenGuiByCandidates(candidates: {string}): ScreenGui?
	for _, candidate in ipairs(candidates) do
		local direct = playerGui:FindFirstChild(candidate)
		if direct and direct:IsA("ScreenGui") then
			return direct
		end
	end

	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			local childName = normalize(child.Name)
			for _, candidate in ipairs(candidates) do
				if childName == normalize(candidate) then
					return child
				end
			end
		end
	end

	return nil
end

local function resolveScreenGui(def: MenuDef, targetGuiOverride: string?): ScreenGui?
	if typeof(targetGuiOverride) == "string" and targetGuiOverride ~= "" then
		local overrideGui = findScreenGuiByName(targetGuiOverride)
		if overrideGui then
			return overrideGui
		end
	end
	if def.primaryGui then
		local primary = findScreenGuiByName(def.primaryGui)
		if primary then
			return primary
		end
	end
	return findScreenGuiByCandidates(def.guiCandidates)
end

local function findFrameByCandidates(root: Instance, candidates: {string}): GuiObject?
	for _, candidate in ipairs(candidates) do
		local direct = root:FindFirstChild(candidate)
		if direct and direct:IsA("GuiObject") then
			return direct
		end
	end

	for _, candidate in ipairs(candidates) do
		local descendant = root:FindFirstChild(candidate, true)
		if descendant and descendant:IsA("GuiObject") then
			return descendant
		end
	end

	return nil
end

local function resolveFrame(screenGui: ScreenGui, def: MenuDef, targetFrameOverride: string?): GuiObject?
	if typeof(targetFrameOverride) == "string" and targetFrameOverride ~= "" then
		local direct = screenGui:FindFirstChild(targetFrameOverride)
		if direct and direct:IsA("GuiObject") then
			return direct
		end
		local descendant = screenGui:FindFirstChild(targetFrameOverride, true)
		if descendant and descendant:IsA("GuiObject") then
			return descendant
		end
	end
	if def.primaryFrame and def.primaryFrame ~= "" then
		local direct = screenGui:FindFirstChild(def.primaryFrame)
		if direct and direct:IsA("GuiObject") then
			return direct
		end
		local descendant = screenGui:FindFirstChild(def.primaryFrame, true)
		if descendant and descendant:IsA("GuiObject") then
			return descendant
		end
	end
	return findFrameByCandidates(screenGui, def.frameCandidates)
end

local function getMenuState(def: MenuDef, targetGuiOverride: string?, targetFrameOverride: string?): boolean?
	if def.key == "Settings" then
		local settingsGui = resolveScreenGui(def, targetGuiOverride)
		if settingsGui then
			return settingsGui.Enabled
		end
	end

	local screenGui = resolveScreenGui(def, targetGuiOverride)
	if not screenGui then
		return nil
	end

	local frame = resolveFrame(screenGui, def, targetFrameOverride)
	if frame then
		return frame.Visible
	end

	return screenGui.Enabled
end

local function applyMenuState(def: MenuDef, shouldOpen: boolean, targetGuiOverride: string?, targetFrameOverride: string?)
	if def.key == "Settings" then
		if shouldOpen and typeof(_G.showVolumeControls) == "function" then
			_G.showVolumeControls()
			return
		elseif not shouldOpen and typeof(_G.hideVolumeControls) == "function" then
			_G.hideVolumeControls()
			return
		end
	end

	local screenGui = resolveScreenGui(def, targetGuiOverride)
	if not screenGui then
		if not warnedMissingTarget[def.key] then
			warnedMissingTarget[def.key] = true
			warn(string.format("[MenuButtonRouter] Target ScreenGui missing for menu '%s'", def.key))
		end
		return
	end

	local frame = resolveFrame(screenGui, def, targetFrameOverride)
	if frame then
		screenGui.Enabled = true
		frame.Visible = shouldOpen
		frame.Active = shouldOpen
		frame.Selectable = shouldOpen
	else
		screenGui.Enabled = shouldOpen
	end
end

local function closeOtherMenus(exceptDef: MenuDef)
	for _, def in ipairs(menuDefs) do
		if def ~= exceptDef then
			applyMenuState(def, false, nil, nil)
		end
	end
end

local function toggleMenu(def: MenuDef, targetGuiOverride: string?, targetFrameOverride: string?)
	local current = getMenuState(def, targetGuiOverride, targetFrameOverride)
	local shouldOpen = not (current == true)
	if shouldOpen then
		closeOtherMenus(def)
	end
	applyMenuState(def, shouldOpen, targetGuiOverride, targetFrameOverride)
end

local function readTextFromInstance(instance: Instance): string?
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		return instance.Text
	end
	return nil
end

local function resolveMenuDefForControl(control: GuiObject): MenuDef?
	if control:GetAttribute("MenuRouterDisabled") == true then
		return nil
	end

	local function matchByText(raw: string?): MenuDef?
		local key = normalize(raw)
		if key == "" then
			return nil
		end
		return defsByAlias[key] or defsByKey[key]
	end

	local menuKeyAttr = control:GetAttribute("MenuKey")
	if typeof(menuKeyAttr) == "string" and menuKeyAttr ~= "" then
		local fromAttr = matchByText(menuKeyAttr)
		if fromAttr then
			return fromAttr
		end
	end

	local buttonNameDef = matchByText(control.Name)
	if buttonNameDef then
		return buttonNameDef
	end

	local ownTextDef = matchByText(readTextFromInstance(control))
	if ownTextDef then
		return ownTextDef
	end

	for _, descendant in ipairs(control:GetDescendants()) do
		local descTextDef = matchByText(readTextFromInstance(descendant))
		if descTextDef then
			return descTextDef
		end
	end

	local current: Instance? = control
	for _ = 1, 3 do
		current = current and current.Parent
		if not current then
			break
		end
		for _, nearby in ipairs(current:GetChildren()) do
			local nearbyTextDef = matchByText(readTextFromInstance(nearby))
			if nearbyTextDef then
				return nearbyTextDef
			end
			for _, nested in ipairs(nearby:GetChildren()) do
				local nestedTextDef = matchByText(readTextFromInstance(nested))
				if nestedTextDef then
					return nestedTextDef
				end
			end
		end
	end

	return nil
end

local function bindControl(control: GuiObject, def: MenuDef)
	local targetGui = control:GetAttribute("MenuTargetGui")
	local targetFrame = control:GetAttribute("MenuTargetFrame")
	local targetGuiOverride = typeof(targetGui) == "string" and targetGui or nil
	local targetFrameOverride = typeof(targetFrame) == "string" and targetFrame or nil

	if control:IsA("GuiButton") then
		control.Activated:Connect(function()
			toggleMenu(def, targetGuiOverride, targetFrameOverride)
		end)
		return
	end

	-- Fallback for non-GuiButton controls explicitly marked/recognized as menu controls.
	control.Active = true
	control.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleMenu(def, targetGuiOverride, targetFrameOverride)
		end
	end)
end

local function tryBindControl(instance: Instance)
	if not instance:IsA("GuiObject") then
		return
	end

	local control = instance :: GuiObject
	if boundControls[control] then
		return
	end

	local def = resolveMenuDefForControl(control)
	if not def then
		return
	end

	boundControls[control] = true
	bindControl(control, def)
end

local function findByNormalizedName(root: Instance, wantedName: string): Instance?
	local wanted = normalize(wantedName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if normalize(descendant.Name) == wanted then
			return descendant
		end
	end
	return nil
end

local function refreshVisibleButtonsReferences()
	local screenGui = playerGui:FindFirstChild("visibleButtons")
		or playerGui:FindFirstChild("VisibleButtons")
		or findByNormalizedName(playerGui, "visibleButtons")
	if not screenGui then
		visibleButtonsRoot = nil
		visibleButtonsContainer = nil
		return
	end

	local buttonsContainer = screenGui:FindFirstChild("buttons")
		or screenGui:FindFirstChild("Buttons")
		or findByNormalizedName(screenGui, "buttons")
	if not buttonsContainer then
		visibleButtonsRoot = screenGui
		visibleButtonsContainer = nil
		return
	end

	visibleButtonsRoot = screenGui
	visibleButtonsContainer = buttonsContainer
end

local function isDescendantOf(candidate: Instance, ancestor: Instance?): boolean
	if not ancestor then
		return false
	end
	local current: Instance? = candidate
	while current do
		if current == ancestor then
			return true
		end
		current = current.Parent
	end
	return false
end

local function shouldAttemptAutoBinding(control: GuiObject): boolean
	if isDescendantOf(control, visibleButtonsContainer) then
		return true
	end

	local explicit = control:GetAttribute("MenuKey")
	if typeof(explicit) == "string" and explicit ~= "" then
		return true
	end

	return false
end

local function bindVisibleButtonsPath()
	refreshVisibleButtonsReferences()
	if not visibleButtonsContainer then
		return
	end
	for _, descendant in ipairs(visibleButtonsContainer:GetDescendants()) do
		tryBindControl(descendant)
	end
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
	if descendant:IsA("GuiObject") and shouldAttemptAutoBinding(descendant) then
		tryBindControl(descendant)
	end
end
bindVisibleButtonsPath()
didInitialScan = true

local function reportBindingStatus()
	local count = 0
	for _ in pairs(boundControls) do
		count += 1
	end
	print(string.format("[MenuButtonRouter] Bound %d menu controls.", count))
end

if didInitialScan then
	reportBindingStatus()
end

playerGui.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("GuiObject") then
		if shouldAttemptAutoBinding(descendant) then
			tryBindControl(descendant)
		end
	end
	bindVisibleButtonsPath()
end)

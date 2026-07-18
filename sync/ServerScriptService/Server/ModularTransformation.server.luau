
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create essential RemoteEvents
local punchEvent = ReplicatedStorage:FindFirstChild("PunchEvent")
if not punchEvent then
	punchEvent = Instance.new("RemoteEvent")
	punchEvent.Name = "PunchEvent"
	punchEvent.Parent = ReplicatedStorage
	print("Created PunchEvent")
end

-- ====================================
-- CONFIGURATION - Add new characters here
-- ====================================

local CHARACTER_CONFIG = {
	-- NARUTO CHARACTERS (Levels 1-18)
	[1] = {
		name = "Kid Naruto",
		source = "asset",
		location = 135449981702602,
		fallback_asset = nil
	},
	[2] = {
		name = "Kid Sasuke 2", 
		source = "asset",
		location = 107037795506079,
		fallback_asset = nil
	},
	[3] = {
		name = "Sasuke Curse", 
		source = "asset",
		location = 110613839605621,
		fallback_asset = nil
	},
	[4] = {
		name = "Naruto Teen", 
		source = "asset",
		location = 128290584450319,
		fallback_asset = nil
	},
	[5] = {
		name = "Sasuke Teen", 
		source = "asset",
		location = 106767438400689,
		fallback_asset = nil
	},
	[6] = {
		name = "Kakashi", 
		source = "asset",
		location = 93293923591574,
		fallback_asset = nil
	},
	[7] = {
		name = "Naruto Sage Mode", 
		source = "asset",
		location = 81158968386298,
		fallback_asset = nil
	},
	[8] = {
		name = "Itachi Uchiha", 
		source = "asset",
		location = 125505933570040,
		fallback_asset = nil
	},
	[9] = {
		name = "Nagato", 
		source = "asset",
		location = 73161914210543,
		fallback_asset = nil
	},
	[10] = {
		name = "Obito", 
		source = "asset",
		location = 75743656144298,
		fallback_asset = nil
	},
	[11] = {
		name = "Madara", 
		source = "asset",
		location = 84563957097396,
		fallback_asset = nil
	},
	[12] = {
		name = "Adult Sasuke", 
		source = "asset",
		location = 110195613882780,
		fallback_asset = nil
	},
	[13] = {
		name = "Naruto Hokage", 
		source = "asset",
		location = 107180720790641,
		fallback_asset = nil
	},
	[14] = {
		name = "Boruto Uzumaki", 
		source = "asset",
		location = 89027479877124,
		fallback_asset = nil
	},
	[15] = {
		name = "Sasuke Rinnegan", 
		source = "asset",
		location = 119576771074622,
		fallback_asset = nil
	},
	[16] = {
		name = "Naruto 6 Path", 
		source = "asset",
		location = 74187453623910,
		fallback_asset = nil
	},
	[17] = {
		name = "6 Path Madara", 
		source = "asset",
		location = 83308437099374,
		fallback_asset = nil
	},
	[18] = {
		name = "Naruto Baryon Mode", 
		source = "asset",
		location = 100201673299597,
		fallback_asset = nil
	},

	-- DRAGON BALL CHARACTERS (Levels 19-60)
	[19] = {
		name = "Raditz",
		source = "asset",
		location = 87047680862995,
		fallback_asset = nil
	},
	[20] = {
		name = "Base Frieza",
		source = "asset",
		location = 87550932043815,
		fallback_asset = nil
	},
	[21] = {
		name = "Piccolo",
		source = "asset",
		location = 106091949028712,
		fallback_asset = nil
	},
	[22] = {
		name = "Base Vegeta",
		source = "asset",
		location = 70689164790505,
		fallback_asset = nil
	},
	[23] = {
		name = "Base Gohan",
		source = "asset",
		location = 91433235507345,
		fallback_asset = nil
	},
	[24] = {
		name = "Base Goku",
		source = "asset",
		location = 84387426887510,
		fallback_asset = nil
	},
	[25] = {
		name = "Trunks",
		source = "asset",
		location = 97816086036050,
		fallback_asset = nil
	},
	[26] = {
		name = "Goku Black",
		source = "asset",
		location = 98338831267130,
		fallback_asset = nil
	},
	[27] = {
		name = "Final Frieza",
		source = "asset",
		location = 131134362511461,
		fallback_asset = nil
	},
	[28] = {
		name = "Vegeta Jacket",
		source = "asset",
		location = 83966646328867,
		fallback_asset = nil
	},
	[29] = {
		name = "Goku Jacket",
		source = "asset",
		location = 94214850616808,
		fallback_asset = nil
	},
	[30] = {
		name = "Trunks SSJ",
		source = "asset",
		location = 138659985704397,
		fallback_asset = nil
	},
	[31] = {
		name = "Vegeta SSJ",
		source = "asset",
		location = 91281155941579,
		fallback_asset = nil
	},
	[32] = {
		name = "Goku SSJ",
		source = "asset",
		location = 91908757880408,
		fallback_asset = nil
	},
	[33] = {
		name = "Vegeta GT",
		source = "asset",
		location = 92831711573961,
		fallback_asset = nil
	},
	[34] = {
		name = "Perfect Cell",
		source = "asset",
		location = 130657211564875,
		fallback_asset = nil
	},
	[35] = {
		name = "Gohan SS2",
		source = "asset",
		location = 108879821139140,
		fallback_asset = nil
	},
	[36] = {
		name = "Majin Buu",
		source = "asset",
		location = 70970662288082,
		fallback_asset = nil
	},
	[37] = {
		name = "Vegito Base",
		source = "asset",
		location = 119950490500272,
		fallback_asset = nil
	},
	[38] = {
		name = "Goku SS3",
		source = "asset",
		location = 116572289794922,
		fallback_asset = nil
	},
	[39] = {
		name = "Vegeta SS3",
		source = "asset",
		location = 138149022751119,
		fallback_asset = nil
	},
	[40] = {
		name = "Trunks SS Rage",
		source = "asset",
		location = 120768285755245,
		fallback_asset = nil
	},
	[41] = {
		name = "Super Buu",
		source = "asset",
		location = 140433836208154,
		fallback_asset = nil
	},
	[42] = {
		name = "Super Vegito",
		source = "asset",
		location = 102957908409053,
		fallback_asset = nil
	},
	[43] = {
		name = "SS4 Vegeta",
		source = "asset",
		location = 80264824954671,
		fallback_asset = nil
	},
	[44] = {
		name = "SS4 Goku",
		source = "asset",
		location = 117019542169664,
		fallback_asset = nil
	},
	[45] = {
		name = "God Goku",
		source = "asset",
		location = 140048366703867,
		fallback_asset = nil
	},
	[46] = {
		name = "Golden Frieza",
		source = "asset",
		location = 111936777325577,
		fallback_asset = nil
	},
	[47] = {
		name = "Blue Vegeta",
		source = "asset",
		location = 76577261933125,
		fallback_asset = nil
	},
	[48] = {
		name = "Blue Goku",
		source = "asset",
		location = 136408335988949,
		fallback_asset = nil
	},
	[49] = {
		name = "Rose Goku Black",
		source = "asset",
		location = 93417031170464,
		fallback_asset = nil
	},
	[50] = {
		name = "Orange Piccolo",
		source = "asset",
		location = 122484175352446,
		fallback_asset = nil
	},
	[51] = {
		name = "BE Vegeta",
		source = "asset",
		location = 73801726487982,
		fallback_asset = nil
	},
	[52] = {
		name = "UI Sign Goku",
		source = "asset",
		location = 110451488739464,
		fallback_asset = nil
	},
	[53] = {
		name = "UE Vegeta",
		source = "asset",
		location = 127977775624658,
		fallback_asset = nil
	},
	[54] = {
		name = "Beast Gohan",
		source = "asset",
		location = 94560396263632,
		fallback_asset = nil
	},
	[55] = {
		name = "UI Goku",
		source = "asset",
		location = 87960943579954,
		fallback_asset = nil
	},
	[56] = {
		name = "Blue Gogeta",
		source = "asset",
		location = 134443998756664,
		fallback_asset = nil
	},
	[57] = {
		name = "SS4 Gogeta",
		source = "asset",
		location = 103561282109984,
		fallback_asset = nil
	},
	[58] = {
		name = "Black Frieza",
		source = "asset",
		location = 87723430855404,
		fallback_asset = nil
	},
	[59] = {
		name = "Beerus",
		source = "asset",
		location = 75516604216733,
		fallback_asset = nil
	},
	[60] = {
		name = "Drip Goku",
		source = "asset",
		location = 122122112352833,
		fallback_asset = nil
	}
}

--level test command
--_G.setPlayerLevel(game.Players.Majorfail4545, 5)

local SPAWN_LOCATION = Vector3.new(534.252, 25, 141.024)

-- Cache for loaded characters
local characterCache = {}

-- ====================================
-- PUNCH ANIMATION HANDLER
-- ====================================

local function playPunchAnimation(character)
	print("👊 Attempting to play punch animation for:", character.Name)
	
	-- Find the LoadedAnimations folder
	local animStorage = character:FindFirstChild("LoadedAnimations")
	if not animStorage then
		warn("❌ No LoadedAnimations folder found")
		return
	end
	
	-- Find the punch animation track
	local punchValue = animStorage:FindFirstChild("Punch")
	if not punchValue or not punchValue:IsA("ObjectValue") or not punchValue.Value then
		warn("❌ No Punch animation value found")
		return
	end
	
	local punchTrack = punchValue.Value
	if not punchTrack then
		warn("❌ Punch animation track is nil")
		return
	end
	
	-- Play the punch animation
	print("🎯 Playing punch animation!")
	
	-- Adjust animation speed to exactly 0.3 seconds
	punchTrack:AdjustSpeed(punchTrack.Length / 0.3)
	punchTrack:Play()
	
	-- Optional: Add punch sound effect
	local punchSound = Instance.new("Sound")
	punchSound.SoundId = "rbxassetid://566593606"
	punchSound.Volume = 0.3
	punchSound.Parent = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	punchSound:Play()
	
	-- Clean up sound after playing
	punchSound.Ended:Connect(function()
		punchSound:Destroy()
	end)
	
	print("✅ Punch animation played successfully!")
end

-- ====================================
-- CORE CHARACTER SYSTEM
-- ====================================

local CharacterSystem = {}

-- Find character model from various sources
function CharacterSystem.findCharacter(config)
	-- Check cache first
	if characterCache[config.name] and characterCache[config.name].Parent then
		return characterCache[config.name]
	end

	local character = nil

	if config.source == "workspace" then
		-- Try workspace first
		character = workspace:FindFirstChild(config.name)
		if character then 
			characterCache[config.name] = character
			return character 
		end

		-- Try specific folder
		if config.location then
			local folder = workspace:FindFirstChild(config.location)
			if folder then
				character = folder:FindFirstChild(config.name)
				if character then 
					characterCache[config.name] = character
					return character 
				end
			end
		end

	elseif config.source == "asset" then
		-- Load from asset ID with better error handling
		print("Loading character asset:", config.name, "ID:", config.location)

		local success, result = pcall(function()
			return InsertService:LoadAsset(config.location)
		end)

		if success and result then
			-- Look for a Model with a Humanoid (proper character model)
			for _, child in pairs(result:GetChildren()) do
				if child:IsA("Model") then
					-- Check if this model has a humanoid (is a character)
					local humanoid = child:FindFirstChildOfClass("Humanoid")
					if humanoid then
						character = child
						break
					elseif not character then
						-- Use first model as fallback
						character = child
					end
				end
			end

			if character then
				-- Store original in workspace for caching
				character.Name = config.name .. "_Original"
				character.Parent = workspace
				characterCache[config.name] = character
				
				result:Destroy()
				print("Successfully loaded character:", config.name)
				return character
			else
				warn("No Model found in asset:", config.location)
			end
		else
			warn("Failed to load asset:", config.location, "Error:", result)
		end
	end

	-- Try fallback asset if configured
	if config.fallback_asset then
		print("Trying fallback asset for:", config.name)
		local success, result = pcall(function()
			return InsertService:LoadAsset(config.fallback_asset)
		end)

		if success and result then
			for _, child in pairs(result:GetChildren()) do
				if child:IsA("Model") then
					character = child
					break
				end
			end

			if character then
				character.Name = config.name
				character.Parent = workspace
				characterCache[config.name] = character
				result:Destroy()
				print("Successfully loaded fallback character:", config.name)
				return character
			end
		end
	end

	warn("Could not find or load character:", config.name)
	return nil
end

-- Set up character for proper functionality
function CharacterSystem.setupCharacter(character, player)
	if not character then
		warn("Cannot setup nil character")
		return nil
	end

	print("Setting up character:", character.Name, "for player:", player.Name)

	-- Ensure humanoid exists
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		print("Created new Humanoid")
	end

	-- Configure humanoid
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.AutoRotate = true
	
	-- Try to preserve appearance if HumanoidDescription exists
	local humanoidDescription = character:FindFirstChildOfClass("HumanoidDescription")
	if humanoidDescription then
		local success = pcall(function()
			humanoid:ApplyDescription(humanoidDescription)
		end)
		if success then
			print("Applied existing HumanoidDescription")
		else
			print("Could not apply HumanoidDescription, continuing anyway")
		end
	end
	
	-- Fix and weld all accessories properly
	local head = character:FindFirstChild("Head")
	if not head then
		warn("⚠️ No head found for accessory attachment")
	end
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				-- Remove any existing welds first
				for _, weld in pairs(handle:GetChildren()) do
					if weld:IsA("Weld") or weld:IsA("WeldConstraint") or weld:IsA("Motor6D") then
						weld:Destroy()
					end
				end
				
				-- Find the attachment in the handle
				local handleAttachment = handle:FindFirstChildOfClass("Attachment")
				
				if handleAttachment and head then
					-- Find matching attachment in head
					local headAttachment = head:FindFirstChild(handleAttachment.Name)
					
					if headAttachment then
						-- Create RigidConstraint to properly attach
						local rigidConstraint = Instance.new("RigidConstraint")
						rigidConstraint.Attachment0 = handleAttachment
						rigidConstraint.Attachment1 = headAttachment
						rigidConstraint.Parent = handle
						print("✅ Welded accessory:", accessory.Name, "via attachments")
					else
						-- Fallback: Create a WeldConstraint directly
						local weldConstraint = Instance.new("WeldConstraint")
						weldConstraint.Part0 = handle
						weldConstraint.Part1 = head
						weldConstraint.Parent = handle
						print("✅ Welded accessory:", accessory.Name, "via direct weld")
					end
					
					-- Make sure handle can't fall
					handle.CanCollide = false
					handle.Massless = true
				elseif head then
					-- No attachments, use direct weld
					local weld = Instance.new("Weld")
					weld.Part0 = head
					weld.Part1 = handle
					weld.C0 = CFrame.new(0, 0.5, 0) -- Default hair position
					weld.Parent = handle
					handle.CanCollide = false
					handle.Massless = true
					print("✅ Welded accessory:", accessory.Name, "via manual weld")
				end
			end
		end
	end
	
	-- Also check for loose parts that might be accessories
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and (part.Name:lower():match("hair") or part.Name:lower():match("hat") or part.Name:lower():match("accessory")) then
			if not part:FindFirstChildOfClass("Weld") and not part:FindFirstChildOfClass("WeldConstraint") and not part:FindFirstChildOfClass("Motor6D") then
				if head and part ~= head then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = head
					weld.Part1 = part
					weld.Parent = part
					part.CanCollide = false
					part.Massless = true
					print("✅ Welded loose part:", part.Name)
				end
			end
		end
	end
	
	-- Preserve clothing items
	local shirt = character:FindFirstChildOfClass("Shirt")
	local pants = character:FindFirstChildOfClass("Pants") 
	local shirtGraphic = character:FindFirstChildOfClass("ShirtGraphic")
	
	if shirt then print("Shirt preserved:", shirt.ShirtTemplate) end
	if pants then print("Pants preserved:", pants.PantsTemplate) end
	if shirtGraphic then print("T-Shirt preserved:", shirtGraphic.Graphic) end

	-- Find or create root part
	local rootPart = character:FindFirstChild("HumanoidRootPart") or 
		character:FindFirstChild("Torso") or 
		character:FindFirstChild("UpperTorso") or
		character:FindFirstChild("LowerTorso")

	if rootPart and rootPart.Name ~= "HumanoidRootPart" then
		-- Rename instead of cloning to preserve welds
		rootPart.Name = "HumanoidRootPart"
	end

	if not rootPart then
		-- Create a basic root part if none exists
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Material = Enum.Material.ForceField
		rootPart.Transparency = 1
		rootPart.CanCollide = false
		rootPart.Parent = character
		print("Created new HumanoidRootPart")
	end

	if rootPart then
		rootPart.Anchored = false
		rootPart.CanCollide = false
		character.PrimaryPart = rootPart

		-- Add RootAttachment if it doesn't exist
		if not rootPart:FindFirstChild("RootAttachment") then
			local attachment = Instance.new("Attachment")
			attachment.Name = "RootAttachment"
			attachment.Parent = rootPart
		end
	end

	-- Unanchor all parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			part.Anchored = false
		end
	end

	-- Remove conflicting scripts that might interfere  
	local conflictingScripts = {"Animate", "Health", "Sound"}
	for _, scriptName in pairs(conflictingScripts) do
		local script = character:FindFirstChild(scriptName)
		if script then 
			script:Destroy() 
			print("Removed conflicting script:", scriptName)
		end
	end

	-- Set up character immediately, don't wait
	CharacterSystem.setupAnimations(character, player)

	return character
end

-- Setup animations for character
function CharacterSystem.setupAnimations(character, player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Create Animator if it doesn't exist
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Detect if character is R6 or R15
	local isR15 = character:FindFirstChild("UpperTorso") ~= nil
	local rigType = isR15 and "R15" or "R6"
	print("🔍 Detected rig type for " .. character.Name .. ": " .. rigType)

	-- BETTER Animation IDs for different rig types
	local ANIMATIONS = {}

	--_G.setPlayerLevel(game.Players.Majorfail4545, 3)

		-- Check for custom animations first
	
	if isR15 then
		-- R15 Animation IDs (modern rigs)
		ANIMATIONS = {
			Idle = "rbxassetid://2510196951",    -- R15 idle
			Walk = {
				"rbxassetid://507767714",      -- Default R15 run (bigger arm swing)
				"rbxassetid://507777826"       -- Default R15 walk fallback
			},
			Jump = "rbxassetid://2510197830",    -- R15 jump (using walk as fallback)
			Punch = "rbxassetid://103752860008283"    -- Updated R15 punch animation (0.3 sec)
		}
	else
		-- R6 Animation IDs (classic rigs) - FIXED IDS
		ANIMATIONS = {
			Idle = "rbxassetid://96998012326738",     -- Classic R6 idle
			Walk = "rbxassetid://125854908423295",     -- my r6 walk
			Jump = "rbxassetid://180436148",     -- Classic R6 jump
			Punch = "rbxassetid://119818896833456"     -- User's R6 punch animation (0.3 sec)
		}
	end
	local config = CHARACTER_CONFIG[CharacterSystem.getPlayerLevel(player)]
	if config and config.animations then
		ANIMATIONS = config.animations
		print("Using custom animations for", character.Name)
	end

	print("📝 Using " .. rigType .. " animations for " .. character.Name)

	-- STOP ALL EXISTING ANIMATIONS FIRST to prevent conflicts
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end
	print("🛑 Stopped all existing animations to prevent conflicts")

	-- Load animations with error handling
	local animations = {}
	for animName, animId in pairs(ANIMATIONS) do
		local candidateIds = (typeof(animId) == "table") and animId or {animId}
		local loadedTrack = nil
		local usedId = nil

		for attemptIndex, candidateId in ipairs(candidateIds) do
			local success, result = pcall(function()
				local animObject = Instance.new("Animation")
				animObject.AnimationId = candidateId
				local animTrack = animator:LoadAnimation(animObject)

				-- Set priorities
				if animName == "Punch" then
					animTrack.Priority = Enum.AnimationPriority.Action
					animTrack.Looped = false -- Punch should not loop
				elseif animName == "Jump" then
					animTrack.Priority = Enum.AnimationPriority.Core
				elseif animName == "Walk" or animName == "Run" then
					animTrack.Priority = Enum.AnimationPriority.Movement
				else
					animTrack.Priority = Enum.AnimationPriority.Idle
				end

				return animTrack
			end)

			if success then
				loadedTrack = result
				usedId = candidateId
				if attemptIndex > 1 then
					warn(string.format("Fallback animation used for %s (%s attempt %d)", animName, rigType, attemptIndex))
				end
				break
			else
				warn("�O Failed to load " .. rigType .. " animation:", animName, "ID:", candidateId, "Error:", result)
			end
		end

		if loadedTrack then
			animations[animName] = loadedTrack
			print("�o. Loaded " .. rigType .. " animation:", animName, "ID:", usedId, "for", character.Name)
		else
			warn("�O All attempts failed for " .. rigType .. " animation:", animName)
		end
	end
	-- Store animations for punch system
	local animStorage = character:FindFirstChild("LoadedAnimations")
	if not animStorage then
		animStorage = Instance.new("Folder")
		animStorage.Name = "LoadedAnimations"
		animStorage.Parent = character
	end

	for animName, track in pairs(animations) do
		local value = Instance.new("ObjectValue")
		value.Name = animName
		value.Value = track
		value.Parent = animStorage
	end

	-- IMPROVED Movement animation handling with better state control
	local currentState = "idle"
	local currentAnim = nil

	local function switchToAnimation(newState, animTrack)
		if currentState == newState then return end

		-- Stop current animation
		if currentAnim then
			currentAnim:Stop()
		end

		-- Start new animation
		if animTrack then
			animTrack.Looped = true
			animTrack:Play()
			currentAnim = animTrack
		end

		currentState = newState
		print("🎭 " .. character.Name .. " switched to:", newState)
	end

	-- Start with idle animation
	if animations.Idle then
		switchToAnimation("idle", animations.Idle)
	else
		-- If no animations loaded, use default Roblox animate  
		print("⚠️ No animations loaded, attempting default animations")
	end

	-- Only set up movement detection if we have animations
	if animations.Walk or animations.Run or animations.Idle then
		-- FIXED Movement detection with proper thresholds
		humanoid.Running:Connect(function(speed)
			-- More precise speed thresholds
			if speed > 12 then
				-- Running
				if animations.Run and currentState ~= "running" then
					switchToAnimation("running", animations.Run)
				end
			elseif speed > 1 then
				-- Walking  
				if animations.Walk and currentState ~= "walking" then
					switchToAnimation("walking", animations.Walk)
				end
			else
				-- Idle (speed 0 or very low)
				if animations.Idle and currentState ~= "idle" then
					switchToAnimation("idle", animations.Idle)
				end
			end
		end)

		-- Handle jumping separately to prevent infinite jump
		humanoid.Jumping:Connect(function()
			if animations.Jump and currentState ~= "jumping" then
				if currentAnim then currentAnim:Stop() end
				animations.Jump.Looped = false -- IMPORTANT: Jump should NOT loop
				animations.Jump:Play()
				print("🦘 " .. character.Name .. " jumped")

				-- Return to previous state after jump
				animations.Jump.Ended:Connect(function()
					if currentState == "jumping" then
						if animations.Idle then
							switchToAnimation("idle", animations.Idle)
						end
					end
				end)
			end
		end)
	end

	-- Fix T-pose and ensure character can move
	wait(0.2)
	if humanoid.Parent then
		-- Reset movement states
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		wait(0.1)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		wait(0.1)
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		wait(0.1)
		-- Ensure character isn't frozen
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true
	end

	print("✅ " .. rigType .. " animations set up successfully for " .. character.Name)
	print("🎯 Current state:", currentState)
end

-- NEW: Seamless in-place transformation (no visible death/respawn)
-- showLoadingScreen parameter controls whether to show the loading overlay
-- preservePosition parameter controls whether to keep current position (true for level-ups) or use spawn (false for respawns)
function CharacterSystem.transformPlayerSeamless(player, level, showLoadingScreen, preservePosition)
	local config = CHARACTER_CONFIG[level]
	if not config then
		warn("No character configuration for level " .. level)
		return false
	end

	print("🔄 SEAMLESS TRANSFORM: " .. player.Name .. " to level " .. level .. " (" .. config.name .. ")")

	-- Show loading screen only if requested (for level-up transformations)
	local showLoadingEvent = ReplicatedStorage:FindFirstChild("ShowLoadingScreen")
	if showLoadingScreen ~= false then -- Default to true if not specified
		if not showLoadingEvent then
			showLoadingEvent = Instance.new("RemoteEvent")
			showLoadingEvent.Name = "ShowLoadingScreen"
			showLoadingEvent.Parent = ReplicatedStorage
		end
		
		-- Show loading screen and WAIT for it to render
		pcall(function()
			showLoadingEvent:FireClient(player, "show", {
				message = "Transforming to " .. config.name .. "...",
				level = level,
				characterName = config.name
			})
			print("📤 Sent SHOW command to client")
		end)
		
		-- CRITICAL: Wait for loading screen to render and input to lock
		wait(0.3)
	end

	-- Set transformation flag
	player:SetAttribute("TransformingInProgress", true)

	-- Save current state
	local oldCharacter = player.Character
	local savedPosition = CFrame.new(SPAWN_LOCATION) -- Default to spawn location
	local savedHealth = 100
	
	-- Only preserve position if explicitly requested (for level-up transformations)
	if preservePosition and oldCharacter then
		local rootPart = oldCharacter:FindFirstChild("HumanoidRootPart")
		if rootPart then
			savedPosition = rootPart.CFrame
			print("📍 Preserving position for transformation:", savedPosition.Position)
		end
		
		local humanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			savedHealth = humanoid.Health
		end
	else
		print("🏠 Using spawn location:", SPAWN_LOCATION)
	end

	-- Find new character model
	local originalCharacter = CharacterSystem.findCharacter(config)
	if not originalCharacter then
		warn("❌ Could not find character: " .. config.name)
		player:SetAttribute("TransformingInProgress", false)
		showLoadingEvent:FireClient(player, "hide")
		return false
	end

	-- Clone and setup new character
	local newCharacter = originalCharacter:Clone()
	newCharacter.Name = player.Name
	newCharacter = CharacterSystem.setupCharacter(newCharacter, player)
	
	if not newCharacter then
		warn("❌ Failed to setup new character")
		player:SetAttribute("TransformingInProgress", false)
		showLoadingEvent:FireClient(player, "hide")
		return false
	end

	-- Position new character at saved location BEFORE parenting
	if newCharacter.PrimaryPart then
		newCharacter:SetPrimaryPartCFrame(savedPosition)
	end

	-- Quick swap: destroy old, assign new (fast enough to appear seamless)
	if oldCharacter then
		player.Character = nil
		oldCharacter:Destroy()
	end
	
	wait(0.05) -- Tiny delay for physics to settle
	
	-- Assign new character
	newCharacter.Parent = workspace
	player.Character = newCharacter
	
	-- Ensure position is correct and character is stable
	if newCharacter.PrimaryPart then
		-- Temporarily anchor to prevent falling during setup
		newCharacter.PrimaryPart.Anchored = true
		newCharacter:SetPrimaryPartCFrame(savedPosition)
		wait(0.1) -- Let physics settle
		newCharacter.PrimaryPart.Anchored = false
		print("📍 Character positioned at:", newCharacter.PrimaryPart.Position)
	end

	-- Setup humanoid
	local humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = math.min(savedHealth, humanoid.MaxHealth)
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true
	end
	
	-- DISABLE SPAWN PROTECTION
	for _, ff in pairs(newCharacter:GetChildren()) do
		if ff:IsA("ForceField") then
			ff:Destroy()
			print("🛡️ Removed spawn protection ForceField")
		end
	end

	wait(0.3) -- Let character settle

	-- Clear transformation flag
	player:SetAttribute("TransformingInProgress", false)

	-- Hide loading screen ONLY if we showed it
	if showLoadingScreen ~= false and showLoadingEvent then
		pcall(function()
			showLoadingEvent:FireClient(player, "hide")
			print("📤 Sent HIDE command to client")
		end)
		
		-- Backup: Send hide again after delay
		spawn(function()
			wait(0.5)
			pcall(function()
				showLoadingEvent:FireClient(player, "hide")
				print("📤 Sent BACKUP HIDE command")
			end)
		end)
	end

	-- Refresh XP GUI
	spawn(function()
		wait(0.5)
		if _G.refreshXPGUI then
			_G.refreshXPGUI(player)
			print("🔄 XP GUI refreshed after seamless transformation!")
		end
	end)

	print("🎉 Seamless transformation complete for " .. player.Name)
	return true
end

-- OLD Transform player to specific level (DEPRECATED - kept for compatibility only)
function CharacterSystem.transformPlayer(player, level)
	local config = CHARACTER_CONFIG[level]
	if not config then
		warn("No character configuration for level " .. level)
		return false
	end

	print("🔄 OLD TRANSFORMING " .. player.Name .. " to level " .. level .. " (" .. config.name .. ")")
	print("⚠️ WARNING: Using deprecated transform method! Use transformPlayerSeamless instead.")

	-- Set transformation flag to prevent auto-respawn interference
	player:SetAttribute("TransformingInProgress", true)

	-- Find character model
	local originalCharacter = CharacterSystem.findCharacter(config)
	if not originalCharacter then
		warn("❌ Could not find character: " .. config.name)
		player:SetAttribute("TransformingInProgress", false)
		return false
	end

	print("✅ Found character model:", originalCharacter.Name)

	-- Remove current character
	if player.Character then
		local oldCharacter = player.Character
		player.Character = nil
		oldCharacter:Destroy()
		wait(0.5) -- Give time for cleanup
	end

	-- Clone and setup new character
	local newCharacter = originalCharacter:Clone()
	newCharacter.Name = player.Name
	print("📋 Cloned character, setting up...")

	-- Setup character BEFORE assigning to player
	newCharacter = CharacterSystem.setupCharacter(newCharacter, player)
	if not newCharacter then
		warn("❌ Failed to setup character")
		player:SetAttribute("TransformingInProgress", false)
		return false
	end

	-- Parent to workspace and assign to player
	newCharacter.Parent = workspace
	wait(0.1)
	player.Character = newCharacter
	wait(0.1)

	-- Position character and ensure it's not frozen
	if newCharacter.PrimaryPart then
		newCharacter:SetPrimaryPartCFrame(CFrame.new(SPAWN_LOCATION))
		print("📍 Positioned character at spawn")
		
		-- Ensure character can move
		local humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid.AutoRotate = true
			humanoid:MoveTo(SPAWN_LOCATION)
		end
	else
		warn("⚠️ No PrimaryPart found for positioning")
	end

	-- Clear transformation flag AFTER everything is complete
	wait(1)
	player:SetAttribute("TransformingInProgress", false)

	-- 🆕 REFRESH XP GUI AFTER TRANSFORMATION
	spawn(function()
		wait(0.5) -- Give GUI time to fully load
		if _G.refreshXPGUI then
			_G.refreshXPGUI(player)
			print("🔄 XP GUI refreshed after transformation!")
		else
			warn("⚠️ _G.refreshXPGUI not found - XP system may not be loaded")
		end
	end)

	print("🎉 Successfully transformed " .. player.Name .. " to " .. config.name)
	return true
end

-- Get player's current level (integrate with your XP system)
function CharacterSystem.getPlayerLevel(player)
	-- Try multiple methods to get level
	if _G.getPlayerLevel then
		local level = _G.getPlayerLevel(player)
		print("Got player level from _G.getPlayerLevel:", level)
		return level
	end

	if _G.playerData and _G.playerData[player.UserId] then
		local level = _G.playerData[player.UserId].level or 1
		print("Got player level from _G.playerData:", level)
		return level
	end

	-- Default level
	print("Using default level: 1")
	return 1
end

-- Main spawn function (NO loading screen on initial spawn, ALWAYS use spawn location)
function CharacterSystem.spawnPlayerCharacter(player)
	local level = CharacterSystem.getPlayerLevel(player)
	print("🚀 Spawning character for " .. player.Name .. " at level " .. level)
	-- Pass false for showLoadingScreen and false for preservePosition (always spawn at spawn location)
	return CharacterSystem.transformPlayerSeamless(player, level, false, false)
end

-- ====================================
-- PUNCH EVENT HANDLER - FIXED WITH COOLDOWN!
-- ====================================

local playerPunchCooldowns = {}
local PUNCH_COOLDOWN = 0.3 -- Match client cooldown

punchEvent.OnServerEvent:Connect(function(player)
	local currentTime = tick()
	local lastPunchTime = playerPunchCooldowns[player] or 0
	
	-- Check cooldown (server-side validation)
	if currentTime - lastPunchTime < PUNCH_COOLDOWN then
		return -- Silently ignore if on cooldown
	end
	
	print("👊 PUNCH EVENT - Player:", player.Name, "punched!")
	
	-- Check if player has a character
	if not player.Character then
		warn("❌ Player has no character")
		return
	end
	
	-- Update cooldown
	playerPunchCooldowns[player] = currentTime
	
	-- Play the punch animation on the player's character
	playPunchAnimation(player.Character)
end)

-- Clean up cooldown data when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerPunchCooldowns[player] = nil
end)

-- ====================================
-- GLOBAL API - Use these functions
-- ====================================

-- Transform any player to any level instantly (NOW USES SEAMLESS VERSION!)
_G.transformPlayer = CharacterSystem.transformPlayerSeamless
_G.transformPlayerOld = CharacterSystem.transformPlayer -- Keep old version for fallback
_G.transformPlayerSeamless = CharacterSystem.transformPlayerSeamless -- Explicit access

-- Respawn player with level-appropriate character
_G.respawnPlayer = CharacterSystem.spawnPlayerCharacter

-- Debug function
_G.debugTransform = function(playerName, level)
	local player = Players:FindFirstChild(playerName)
	if player then
		print("🐛 DEBUG: Manually transforming", playerName, "to level", level)
		return CharacterSystem.transformPlayer(player, level)
	else
		warn("Player not found:", playerName)
		return false
	end
end

-- Manual punch test
_G.testPunch = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player and player.Character then
		print("🧪 TEST: Playing punch animation for", playerName)
		playPunchAnimation(player.Character)
	else
		warn("Player or character not found:", playerName)
	end
end

-- Clear character cache (for fixing broken characters)
_G.clearCharacterCache = function()
	print("🧹 Clearing character cache...")
	for name, character in pairs(characterCache) do
		if character and character.Parent then
			character:Destroy()
		end
	end
	characterCache = {}
	print("✅ Character cache cleared!")
end

-- Force reload a specific character
_G.reloadCharacter = function(level)
	local config = CHARACTER_CONFIG[level]
	if config and characterCache[config.name] then
		local oldChar = characterCache[config.name]
		if oldChar and oldChar.Parent then
			oldChar:Destroy()
		end
		characterCache[config.name] = nil
		print("🔄 Cleared cached version of", config.name)
	end
end

-- Test accessory welding on current character
_G.fixAccessories = function(player)
	if not player then
		player = Players:GetPlayers()[1]
	end
	
	if player and player.Character then
		local character = player.Character
		local head = character:FindFirstChild("Head")
		local fixCount = 0
		
		-- Fix all accessories
		for _, accessory in pairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				if handle and head then
					-- Create fresh weld
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = head
					weld.Parent = handle
					handle.CanCollide = false
					handle.Massless = true
					fixCount = fixCount + 1
				end
			end
		end
		
		print("🔧 Fixed", fixCount, "accessories for", player.Name)
	end
end

-- ====================================
-- AUTO-SPAWN SYSTEM
-- ====================================

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	print("👋 Player joined:", player.Name)
	
	-- Disable spawn protection for this player
	player:SetAttribute("DisableSpawnProtection", true)
	
	wait(1) -- Wait for other systems to load
	CharacterSystem.spawnPlayerCharacter(player)

	-- Handle respawning - but ONLY if not during a transformation
	player.CharacterRemoving:Connect(function()
		print("👻 Character removing for:", player.Name)

		-- Check if this is a manual transformation (don't auto-respawn)
		if player:GetAttribute("TransformingInProgress") then
			print("🔄 Transformation in progress - skipping auto-respawn")
			return
		end

		wait(3) -- Longer wait to prevent rapid respawning
		-- Only respawn if player is still in game and not transforming
		if player.Parent and not player:GetAttribute("TransformingInProgress") then
			CharacterSystem.spawnPlayerCharacter(player)
		end
	end)
end)

-- Handle existing players (for testing)
for _, player in pairs(Players:GetPlayers()) do
	if not player.Character then
		print("🔄 Spawning character for existing player:", player.Name)
		spawn(function()
			wait(1)
			CharacterSystem.spawnPlayerCharacter(player)
		end)
	end
end

print("✅ Modular Character System loaded successfully with PUNCH ANIMATION!")
print("📝 Available commands:")
print("   _G.transformPlayer(player, level)")
print("   _G.respawnPlayer(player)") 
print("   _G.debugTransform(playerName, level)")
print("   _G.testPunch(playerName)")
print("   _G.clearCharacterCache() - Fix broken cached characters")
print("   _G.reloadCharacter(level) - Reload specific character model")
print("   _G.fixAccessories(player) - Fix flying accessories on current character")
print("   _G.hideLoadingScreens() - Force close any stuck loading screens")

-- EMERGENCY: Force hide loading screens for all players
_G.hideLoadingScreens = function()
	local showLoadingEvent = ReplicatedStorage:FindFirstChild("ShowLoadingScreen")
	if showLoadingEvent then
		for _, player in pairs(Players:GetPlayers()) do
			for i = 1, 3 do
				showLoadingEvent:FireClient(player, "hide")
			end
			print("🚨 Sent 3x hide commands to " .. player.Name)
		end
		print("✅ Force-closed all loading screens")
	else
		warn("❌ ShowLoadingScreen RemoteEvent not found")
	end
end

-- DISABLE loading screens entirely (for testing)
_G.disableLoadingScreens = function()
	local showLoadingEvent = ReplicatedStorage:FindFirstChild("ShowLoadingScreen")
	if showLoadingEvent then
		showLoadingEvent:Destroy()
		print("✅ Loading screens DISABLED - transformations will be instant with no overlay")
	else
		warn("❌ ShowLoadingScreen RemoteEvent not found")
	end
end

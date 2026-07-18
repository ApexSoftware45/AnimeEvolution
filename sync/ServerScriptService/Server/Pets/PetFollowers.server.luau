--!strict
-- Server-side follower handler: keeps equipped pets trailing behind their owner.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local activePetsFolder = workspace:FindFirstChild("ActivePets")
if not activePetsFolder then
	activePetsFolder = Instance.new("Folder")
	activePetsFolder.Name = "ActivePets"
	activePetsFolder.Parent = workspace
end

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if not sharedFolder then
	sharedFolder = Instance.new("Folder")
	sharedFolder.Name = "Shared"
	sharedFolder.Parent = ReplicatedStorage
end

local petDataModule = sharedFolder:FindFirstChild("PetData")
local petData = {}
if petDataModule and petDataModule:IsA("ModuleScript") then
	petData = require(petDataModule)
else
	warn("[PetFollowers] Shared.PetData module is missing; follower pets will use placeholders.")
end

local SERVICE_LOOKUP: {[string]: Instance} = {
	Workspace = workspace,
	workspace = workspace,
	ReplicatedStorage = ReplicatedStorage,
	replicatedstorage = ReplicatedStorage,
	ServerStorage = ServerStorage,
	serverstorage = ServerStorage,
}

local DEFAULT_ANIMATIONS = {
	R6 = {
		Idle = "rbxassetid://96998012326738",
		Walk = "rbxassetid://125854908423295",
		Run = "rbxassetid://125854908423295",
	},
	R15 = {
		Idle = "rbxassetid://2510196951",
		Walk = "rbxassetid://10921269718",
		Run = "rbxassetid://10921269718",
	},
}

local MAX_FOLLOW_DISTANCE = 22
local MOVE_TO_INTERVAL = 0.25
local HORIZONTAL_TOLERANCE = 0.5

local function trim(str: string): string
	return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function resolveInstancePath(path: string): Instance?
	if typeof(path) ~= "string" or path == "" then
		return nil
	end

	local segments = string.split(path, "/")
	if #segments == 0 then
		return nil
	end

	local current: Instance? = nil
	for index, rawSegment in ipairs(segments) do
		local segment = trim(rawSegment)
		if segment ~= "" then
			if index == 1 then
				current = SERVICE_LOOKUP[segment]
				if not current then
					current = ReplicatedStorage:FindFirstChild(segment)
						or workspace:FindFirstChild(segment)
						or ServerStorage:FindFirstChild(segment)
				end
			else
				if not current then
					return nil
				end
				current = current:FindFirstChild(segment)
			end
		end

		if not current then
			return nil
		end
	end

	return current
end

type PetConfig = {
	id: string,
	modelPath: string?,
	scale: number?,
	offset: Vector3,
	speed: number,
	sideSpacing: number,
	animations: {[string]: string}?,
}

local PET_CONFIG: {[string]: PetConfig} = {}
for petId, definition in pairs(petData) do
	if typeof(petId) == "string" and typeof(definition) == "table" then
		local offset = definition.FollowOffset
		if typeof(offset) ~= "Vector3" then
			offset = Vector3.new(0, 0, 4)
		end

		PET_CONFIG[petId] = {
			id = definition.Id or petId,
			modelPath = typeof(definition.ModelPath) == "string" and definition.ModelPath or nil,
			scale = typeof(definition.Scale) == "number" and definition.Scale or nil,
			offset = offset :: Vector3,
			speed = typeof(definition.Speed) == "number" and definition.Speed or 16,
			sideSpacing = typeof(definition.SideSpacing) == "number" and definition.SideSpacing or 3,
			animations = typeof(definition.Animations) == "table" and definition.Animations or nil,
		}
	end
end

local function getPrimaryPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		model.PrimaryPart = root
		return root
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			model.PrimaryPart = descendant
			return descendant
		end
	end

	return nil
end

local function sanitizeModel(model: Model, primary: BasePart)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = false
			descendant.CollisionGroup = "Default"
		elseif descendant:IsA("Humanoid") then
			descendant.PlatformStand = false
			descendant.AutoRotate = true
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				descendant:SetStateEnabled(state, true)
			end
			if not descendant:FindFirstChildOfClass("Animator") then
				local animator = Instance.new("Animator")
				animator.Parent = descendant
			end
		end
	end

	primary.Anchored = false
	primary.CanCollide = false
	model.PrimaryPart = primary
end

local function computeFollowPosition(rootCF: CFrame, offset: Vector3): Vector3
	local rightComponent = rootCF.RightVector * offset.X
	local upComponent = rootCF.UpVector * offset.Y
	local backComponent = -rootCF.LookVector * offset.Z
	return rootCF.Position + rightComponent + upComponent + backComponent
end

type AnimationController = {
	play: (self: AnimationController, state: string) -> (),
	updateForSpeed: (self: AnimationController, speed: number) -> (),
	destroy: (self: AnimationController) -> (),
	tracks: {[string]: AnimationTrack},
	currentState: string?,
	connections: {RBXScriptConnection},
}

local function setupPetAnimations(model: Model, humanoid: Humanoid, config: PetConfig): AnimationController?
	local isR15 = model:FindFirstChild("UpperTorso") ~= nil
	local rigKey = isR15 and "R15" or "R6"
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animationIds = DEFAULT_ANIMATIONS[rigKey]
	if typeof(config.animations) == "table" then
		animationIds = config.animations
	end

	local tracks: {[string]: AnimationTrack} = {}
	for name, id in pairs(animationIds) do
		local success, track = pcall(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = id
			return animator:LoadAnimation(animation)
		end)

		if success and track then
			track.Priority = (name == "Idle") and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Movement
			if name ~= "Jump" then
				track.Looped = true
			end
			tracks[name] = track
		else
			warn("[PetFollowers] Failed to load animation", name, id, success and "unknown error" or track)
		end
	end

	if next(tracks) == nil then
		return nil
	end

	local controller = {
		tracks = tracks,
		currentState = nil,
		connections = {},
	} :: AnimationController

	function controller:play(stateName: string)
		if self.currentState == stateName then
			return
		end

		local newTrack = self.tracks[stateName]
		if not newTrack then
			return
		end

		if self.currentState and self.tracks[self.currentState] then
			self.tracks[self.currentState]:Stop(0.2)
		end

		newTrack:Play()
		self.currentState = stateName
	end

	function controller:updateForSpeed(speed: number)
		if speed > 8 then
			if self.tracks.Run then
				self:play("Run")
				return
			end
			if self.tracks.Walk then
				self:play("Walk")
				return
			end
		elseif speed > 1 then
			if self.tracks.Walk then
				self:play("Walk")
				return
			end
		end

		if self.tracks.Idle then
			self:play("Idle")
		end
	end

	function controller:destroy()
		for _, conn in ipairs(self.connections) do
			conn:Disconnect()
		end
		for _, track in pairs(self.tracks) do
			track:Stop()
			track:Destroy()
		end
		self.tracks = {}
		self.currentState = nil
	end

	controller:updateForSpeed(0)
	controller.connections[#controller.connections + 1] = humanoid.Running:Connect(function(speed)
		controller:updateForSpeed(speed)
	end)

	return controller
end

type PlayerPetEntry = {
	uid: string,
	petId: string,
	model: Model,
	config: PetConfig,
	root: BasePart,
	humanoid: Humanoid?,
	animation: AnimationController?,
	lastMoveTo: number,
}

type PlayerPetState = {
	pets: {PlayerPetEntry},
}

local templateCache: {[string]: Model} = {}
local playerPets: {[Player]: PlayerPetState} = {}

local function getPlayerState(player: Player): PlayerPetState
	local state = playerPets[player]
	if not state then
		state = {pets = {}}
		playerPets[player] = state
	end
	return state
end

local function loadPetTemplate(petId: string): Model?
	if templateCache[petId] then
		return templateCache[petId]
	end

	local config = PET_CONFIG[petId]
	if not config then
		warn("[PetFollowers] Unknown pet id:", petId)
		return nil
	end

	local model: Model?

	if config.modelPath then
		local source = resolveInstancePath(config.modelPath)
		if source and source:IsA("Model") then
			model = source:Clone()
		end
	end

	if not model then
		local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
		if petsFolder then
			local candidate = petsFolder:FindFirstChild(petId)
			if candidate and candidate:IsA("Model") then
				model = candidate:Clone()
			end
		end
	end

	if not model then
		model = Instance.new("Model")
		model.Name = petId .. "_Placeholder"
		local part = Instance.new("Part")
		part.Name = "Primary"
		part.Size = Vector3.new(1.5, 1.5, 1.5)
		part.Color = Color3.fromRGB(255, 255, 255)
		part.Material = Enum.Material.Neon
		part.CanCollide = false
		part.Anchored = true
		part.Parent = model
		model.PrimaryPart = part
	end

	model.Name = petId
	model.Archivable = true

	if config.scale and config.scale ~= 1 then
		pcall(function()
			model:ScaleTo(config.scale)
		end)
	end

	local primary = getPrimaryPart(model)
	if not primary then
		model:Destroy()
		warn("[PetFollowers] Template missing primary part for pet id:", petId)
		return nil
	end

	sanitizeModel(model, primary)
	model.Parent = nil

	templateCache[petId] = model
	return model
end

local function destroyPetEntry(entry: PlayerPetEntry)
	if entry.animation then
		entry.animation:destroy()
	end
	if entry.model then
		entry.model:Destroy()
	end
end

local function createPetEntry(player: Player, petId: string, uid: string): PlayerPetEntry?
	local config = PET_CONFIG[petId]
	if not config then
		warn("[PetFollowers] No follower config for pet id:", petId)
		return nil
	end

	local template = loadPetTemplate(petId)
	if not template then
		return nil
	end

	local pet = template:Clone()
	pet.Name = string.format("%s_%s", player.Name, petId)
	pet.Parent = activePetsFolder

	local primary = getPrimaryPart(pet)
	if not primary then
		pet:Destroy()
		warn("[PetFollowers] Spawned pet missing primary part:", petId)
		return nil
	end

	local humanoid = pet:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = config.speed or humanoid.WalkSpeed or 12
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	end

	primary.AssemblyLinearVelocity = Vector3.zero
	primary.AssemblyAngularVelocity = Vector3.zero
	primary:SetNetworkOwner(nil)

	local animation = humanoid and setupPetAnimations(pet, humanoid, config) or nil

	local entry: PlayerPetEntry = {
		uid = uid,
		petId = petId,
		model = pet,
		config = config,
		root = primary,
		humanoid = humanoid,
		animation = animation,
		lastMoveTo = 0,
	}

	return entry
end

local function positionPetsBehindPlayer(player: Player)
	local state = playerPets[player]
	if not state then
		return
	end

	local pets = state.pets
	if #pets == 0 then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local count = #pets
	local centerIndex = (count + 1) / 2
	for index, entry in ipairs(pets) do
		local config = entry.config
		local baseOffset = config.offset or Vector3.new(0, 0, 4)
		local spacing = config.sideSpacing or 3
		local offsetX = (index - centerIndex) * spacing
		local offset = Vector3.new(baseOffset.X + offsetX, baseOffset.Y, baseOffset.Z)
		local targetPosition = computeFollowPosition(humanoidRootPart.CFrame, offset)
		local lookVector = humanoidRootPart.CFrame.LookVector
		entry.model:PivotTo(CFrame.new(targetPosition, targetPosition + lookVector))
		entry.lastMoveTo = 0
	end
end

local function clearFollowers(player: Player)
	local state = playerPets[player]
	if not state then
		return
	end

	for _, entry in ipairs(state.pets) do
		destroyPetEntry(entry)
	end

	playerPets[player] = nil
end

local function buildDesiredOrder(player: Player, snapshot: {any}?): { {uid: string, petId: string} }
	local desired = {}
	if snapshot then
		for _, entry in ipairs(snapshot) do
			if typeof(entry) == "table" then
				local uid = entry.uid
				local petId = entry.petId
				if typeof(uid) == "string" and uid ~= "" and typeof(petId) == "string" and PET_CONFIG[petId] then
					desired[#desired + 1] = {
						uid = uid,
						petId = petId,
					}
				end
			end
		end
	else
		local snapshotFn = _G.GetEquippedPetsSnapshot
		if typeof(snapshotFn) == "function" then
			local ok, result = pcall(snapshotFn, player)
			if ok and typeof(result) == "table" then
				for _, entry in ipairs(result) do
					if typeof(entry) == "table" then
						local uid = entry.uid
						local petId = entry.petId
						if typeof(uid) == "string" and uid ~= "" and typeof(petId) == "string" and PET_CONFIG[petId] then
							desired[#desired + 1] = {
								uid = uid,
								petId = petId,
							}
						end
					end
				end
			elseif not ok then
				warn("[PetFollowers] GetEquippedPetsSnapshot failed:", result)
			end
		end
	end

	return desired
end

local function refreshFollowersForPlayer(player: Player, snapshot: {any}?)
	local desired = buildDesiredOrder(player, snapshot)
	if #desired == 0 then
		clearFollowers(player)
		return
	end

	local state = getPlayerState(player)
	local currentMap: {[string]: PlayerPetEntry} = {}
	for _, entry in ipairs(state.pets) do
		currentMap[entry.uid] = entry
	end

	local newList: {PlayerPetEntry} = {}
	for _, want in ipairs(desired) do
		local config = PET_CONFIG[want.petId]
		if config then
			local existing = currentMap[want.uid]
			if existing and existing.petId ~= want.petId then
				destroyPetEntry(existing)
				existing = nil
			end

			if not existing then
				existing = createPetEntry(player, want.petId, want.uid)
			end

			if existing then
				existing.config = config
				existing.petId = want.petId
				table.insert(newList, existing)
				currentMap[want.uid] = nil
			end
		end
	end

	for _, leftover in pairs(currentMap) do
		destroyPetEntry(leftover)
	end

	if #newList == 0 then
		playerPets[player] = nil
	else
		state.pets = newList
		positionPetsBehindPlayer(player)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	task.defer(function()
		local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
		if root then
			positionPetsBehindPlayer(player)
		end
	end)
end

local function onCharacterRemoving(player: Player)
	local state = playerPets[player]
	if not state then
		return
	end

	for _, entry in ipairs(state.pets) do
		if entry.model and entry.model.Parent then
			entry.model:PivotTo(CFrame.new(0, -200, 0))
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		onCharacterRemoving(player)
	end)
	if typeof(_G.GetEquippedPetsSnapshot) == "function" then
		task.defer(function()
			refreshFollowersForPlayer(player)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clearFollowers(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playerPets[player] then
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		player.CharacterRemoving:Connect(function()
			onCharacterRemoving(player)
		end)
	end
	if typeof(_G.GetEquippedPetsSnapshot) == "function" then
		task.defer(function()
			refreshFollowersForPlayer(player)
		end)
	end
end

RunService.Heartbeat:Connect(function()
	for player, state in pairs(playerPets) do
		local pets = state.pets
		if #pets == 0 then
			playerPets[player] = nil
			continue
		end

		local character = player.Character
		local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not characterRoot then
			for _, entry in ipairs(pets) do
				if entry.humanoid then
					entry.humanoid:Move(Vector3.zero, false)
				end
			end
			continue
		end

		local count = #pets
		local centerIndex = (count + 1) / 2
		for index, entry in ipairs(pets) do
			local pet = entry.model
			local humanoid = entry.humanoid
			local rootPart = entry.root

			if not pet or not pet.Parent or not rootPart or not rootPart.Parent then
				destroyPetEntry(entry)
				pets[index] = nil
				continue
			end

			local config = entry.config
			local baseOffset = config.offset or Vector3.new(0, 0, 4)
			local spacing = config.sideSpacing or 3
			local offsetX = (index - centerIndex) * spacing
			local offset = Vector3.new(baseOffset.X + offsetX, baseOffset.Y, baseOffset.Z)
			local targetPosition = computeFollowPosition(characterRoot.CFrame, offset)
			local distance = (targetPosition - rootPart.Position).Magnitude

			if distance > MAX_FOLLOW_DISTANCE then
				pet:PivotTo(CFrame.new(targetPosition, targetPosition + characterRoot.CFrame.LookVector))
				rootPart.AssemblyLinearVelocity = Vector3.zero
				if humanoid then
					humanoid:Move(Vector3.zero, false)
				end
				entry.lastMoveTo = tick()
				continue
			end

			if humanoid then
				humanoid.WalkSpeed = config.speed or humanoid.WalkSpeed or 12

				local horizontalVector = Vector3.new(
					targetPosition.X - rootPart.Position.X,
					0,
					targetPosition.Z - rootPart.Position.Z
				)
				local horizontalDistance = horizontalVector.Magnitude

				if horizontalDistance > HORIZONTAL_TOLERANCE then
					humanoid:Move(horizontalVector.Unit, false)
				else
					humanoid:Move(Vector3.zero, false)
				end

				local now = tick()
				if (now - (entry.lastMoveTo or 0)) > MOVE_TO_INTERVAL or distance > 2 then
					humanoid:MoveTo(targetPosition)
					entry.lastMoveTo = now
				end
			else
				pet:PivotTo(CFrame.new(targetPosition, targetPosition + characterRoot.CFrame.LookVector))
			end
		end

		local compact: {PlayerPetEntry} = {}
		for _, entry in ipairs(pets) do
			if entry and entry.model and entry.model.Parent then
				compact[#compact + 1] = entry
			end
		end
		state.pets = compact
		if #compact == 0 then
			playerPets[player] = nil
		end
	end
end)

_G.ServerApplyEquippedFollowersForPlayer = function(playerOrName, snapshot: {any}?)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end

	if not player or not player:IsA("Player") then
		return
	end

	refreshFollowersForPlayer(player, snapshot)
end

_G.RemoveAllFollowerPets = function(playerOrName)
	local player = playerOrName
	if typeof(playerOrName) == "string" then
		player = Players:FindFirstChild(playerOrName)
	end

	if not player or not player:IsA("Player") then
		return
	end

	clearFollowers(player)
end

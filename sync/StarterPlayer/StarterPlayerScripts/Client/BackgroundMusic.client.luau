-- Background Music LocalScript with Sound Controller Integration
-- Dynamically scans workspace/Background Music for tracks (Sound instances)

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- Wait for sound controller to be available
local function waitForSoundController()
	local attempts = 0
	while not _G.playBackgroundMusic and attempts < 50 do
		task.wait(0.1)
		attempts += 1
	end
	return _G.playBackgroundMusic ~= nil
end

local MUSIC_FOLDER_NAME = "Background Music"
local musicFolder = Workspace:FindFirstChild(MUSIC_FOLDER_NAME)
if not musicFolder then
	musicFolder = Instance.new("Folder")
	musicFolder.Name = MUSIC_FOLDER_NAME
	musicFolder.Parent = Workspace
end

local DEFAULT_TRACKS = {
	{id = "rbxassetid://119837595487522", name = "custom_track_1"},
	{id = "rbxassetid://132801302002858", name = "custom_track_2"},
}

local trackList = {}
local playlistVersion = 0
local currentSound = nil
local currentIndex = 1

local registerCustomTracks -- forward declaration
local playWithoutSoundController -- forward declaration

local function shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

local function cloneDefaultTracks()
	local list = {}
	for _, entry in ipairs(DEFAULT_TRACKS) do
		list[#list + 1] = {id = entry.id, name = entry.name}
	end
	return list
end

local function rebuildTrackList()
	local newList = {}
	for _, inst in ipairs(musicFolder:GetDescendants()) do
		if inst:IsA("Sound") and inst.SoundId ~= "" then
			local label = inst.Name ~= "" and inst.Name or nil
			newList[#newList + 1] = {id = inst.SoundId, name = label}
		end
	end

	if #newList == 0 then
		newList = cloneDefaultTracks()
	end

	trackList = newList
	playlistVersion += 1
	if currentIndex > #trackList then
		currentIndex = 1
	end

	if registerCustomTracks then
		registerCustomTracks()
	end
end

musicFolder.DescendantAdded:Connect(function(inst)
	if inst:IsA("Sound") then
		rebuildTrackList()
	end
end)

musicFolder.DescendantRemoving:Connect(function(inst)
	if inst:IsA("Sound") then
		rebuildTrackList()
	end
end)

rebuildTrackList()

local function buildPlaybackQueue()
	local queue = {}
	for _, entry in ipairs(trackList) do
		queue[#queue + 1] = entry
	end
	shuffle(queue)
	return queue
end

-- Function to add your custom tracks to the sound controller
registerCustomTracks = function()
	if _G.SoundController and _G.SoundController.addSoundToLibrary then
		for index, entry in ipairs(trackList) do
			local musicName = entry.name
			if not musicName or musicName == "" then
				musicName = ("workspace_track_%d"):format(index)
			end
			_G.SoundController.addSoundToLibrary("BGM", musicName, entry.id)
			print("dYZ Registered custom track:", musicName)
		end
	end
end

local function playWithSoundController()
	registerCustomTracks()

	local playbackQueue = {}
	local queueVersion = -1

	local function refreshQueue()
		if queueVersion == playlistVersion and #playbackQueue > 0 then
			return
		end
		playbackQueue = buildPlaybackQueue()
		queueVersion = playlistVersion
		currentIndex = 1
	end

	local function playNext()
		refreshQueue()
		if #playbackQueue == 0 then
			warn("[BackgroundMusic] No tracks available to play.")
			return
		end

		if currentSound then
			currentSound:Stop()
			currentSound = nil
		end

		local entry = playbackQueue[currentIndex]
		if not entry or not entry.id or entry.id == "" then
			queueVersion = -1
			return playNext()
		end

		local soundId = entry.id
		local trackName = entry.name or ("custom_track_" .. currentIndex)
		print(("dYZ Playing background music: %s (%s)"):format(soundId, trackName))

		currentSound = _G.SoundController.playSoundById(
			soundId,
			"BGM",
			Workspace,
			{
				Volume = 0.5,
				Looped = false,
				EmitterSize = 1000,
			}
		)

		if currentSound then
			currentSound.Ended:Connect(function()
				currentIndex += 1
				if currentIndex > #playbackQueue then
					queueVersion = -1
					currentIndex = 1
				end
				task.wait(1)
				playNext()
			end)
		else
			warn("[BackgroundMusic] Failed to play via sound controller, falling back.")
			playWithoutSoundController()
		end
	end

	playNext()
end

-- Fallback function to play sounds without the sound controller
playWithoutSoundController = function()
	print("dYZ Using fallback background music system")

	local playbackQueue = {}
	local queueVersion = -1

	local function refreshQueue()
		if queueVersion == playlistVersion and #playbackQueue > 0 then
			return
		end
		playbackQueue = buildPlaybackQueue()
		queueVersion = playlistVersion
		currentIndex = 1
	end

	local function playNext()
		refreshQueue()
		if #playbackQueue == 0 then
			warn("[BackgroundMusic] No tracks available to play.")
			return
		end

		if currentSound then
			currentSound:Destroy()
		end

		local entry = playbackQueue[currentIndex]
		if not entry or not entry.id or entry.id == "" then
			queueVersion = -1
			return playNext()
		end

		currentSound = Instance.new("Sound")
		currentSound.SoundId = entry.id
		currentSound.Volume = 0.3
		currentSound.Parent = SoundService
		currentSound:Play()

		print(("dYZ Playing background music (fallback): %s"):format(entry.id))

		currentSound.Ended:Connect(function()
			currentIndex += 1
			if currentIndex > #playbackQueue then
				queueVersion = -1
				currentIndex = 1
			end
			task.wait(1)
			playNext()
		end)
	end

	playNext()
end

-- Main initialization
local function initializeBackgroundMusic()
	print("dYZ Initializing background music system...")
	task.wait(2)

	if waitForSoundController() then
		print("o Sound controller available, using integrated system")
		playWithSoundController()
	else
		print("s Sound controller not available, using fallback system")
		playWithoutSoundController()
	end
end

-- Global controls
_G.stopBackgroundMusic = function()
	if currentSound then
		currentSound:Stop()
		print("Stopped background music")
	end
end

_G.resumeBackgroundMusic = function()
	if currentSound and not currentSound.IsPlaying then
		currentSound:Play()
		print("Resumed background music")
	end
end

_G.skipTrack = function()
	if currentSound then
		currentSound:Stop()
		print("Skipped to next track")
	end
end

initializeBackgroundMusic()

print("o Background Music system loaded with sound controller integration!")
print('dY Controls: _G.stopBackgroundMusic(), _G.resumeBackgroundMusic(), _G.skipTrack()')

-- ServerScriptService/TimePlayedService
-- Tracks seconds played, shows minutes in the playerlist, saves total across sessions,
-- and periodically pushes totals into an OrderedDataStore for global leaderboards.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Standard store for persistent totals
local TimePlayedStore = DataStoreService:GetDataStore("TimePlayedTotal_v1")
-- Ordered store for global rankings (higher = better)
local TimePlayedOrdered = DataStoreService:GetOrderedDataStore("TimePlayedRank_v1")

-- CONFIG
local SAVE_INTERVAL = 60            -- save every 60s to respect DataStore limits
local LEADERSTATS_UNIT = "Minutes"  -- what shows in the player list
local INCREMENT_STEP = 1            -- seconds added per tick
local TICK_INTERVAL = 1             -- how often to tick (1s)

-- Internal bookkeeping
local sessionStart = {}
local sessionAccumulated = {}  -- seconds accumulated this session
local lastSave = {}            -- last save os.time()

local function safeGet(ds, key, defaultValue)
	local ok, value = pcall(function()
		return ds:GetAsync(key)
	end)
	if ok and typeof(value) == typeof(defaultValue) then
		return value
	end
	return defaultValue
end

local function updateOrdered(userId, totalSeconds)
	-- Push to the ordered store (use UpdateAsync to be safe with races)
	local key = tostring(userId)
	pcall(function()
		TimePlayedOrdered:UpdateAsync(key, function(oldValue)
			-- Keep the max we've ever recorded so the board never goes backwards
			oldValue = tonumber(oldValue) or 0
			if totalSeconds > oldValue then
				return totalSeconds
			else
				return oldValue
			end
		end)
	end)
end

local function saveNow(player)
	local userId = player.UserId
	local key = "u_" .. userId
	local played = sessionAccumulated[userId] or 0

	-- Load current stored total, then add our session time and write back.
	local stored = safeGet(TimePlayedStore, key, 0)
	local newTotal = stored + played

	local ok, err = pcall(function()
		TimePlayedStore:SetAsync(key, newTotal)
	end)
	if ok then
		-- Also push to the ordered store for global ranking
		updateOrdered(userId, newTotal)
		-- Reset session counter after a successful save
		sessionAccumulated[userId] = 0
		lastSave[userId] = os.time()
	else
		warn(("TimePlayedService: Save failed for %s: %s"):format(player.Name, err))
	end
end

local function autosaveLoop(player)
	local userId = player.UserId
	while player.Parent == Players do
		task.wait(1)
		-- Periodic save to not lose too much progress
		if (os.time() - (lastSave[userId] or 0)) >= SAVE_INTERVAL then
			saveNow(player)
		end
	end
end

local function onPlayerAdded(player)
	-- Load existing total (in seconds)
	local key = "u_" .. player.UserId
	local totalSeconds = safeGet(TimePlayedStore, key, 0)

	sessionStart[player.UserId] = os.clock()
	sessionAccumulated[player.UserId] = 0
	lastSave[player.UserId] = os.time()

	-- Tick loop: add seconds (no longer updates leaderstats)
	task.spawn(function()
		while player.Parent == Players do
			task.wait(TICK_INTERVAL)
			sessionAccumulated[player.UserId] += INCREMENT_STEP
		end
	end)

	-- Keep the ordered board fresh on join too
	updateOrdered(player.UserId, totalSeconds)

	-- Background autosaver
	task.spawn(function() autosaveLoop(player) end)
end

local function onPlayerRemoving(player)
	-- One final save for this player
	saveNow(player)

	-- Clean up
	sessionStart[player.UserId] = nil
	sessionAccumulated[player.UserId] = nil
	lastSave[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Save everyone when the server is closing
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(saveNow, player)
	end
end)

-- SurfaceGui / Script  (server Script)
-- Works with: model > SurfaceGui > MainFrame > Players > Scroll (+ UIListLayout + header labels)
-- and SurfaceGui > Template (Frame with: Rank [TextLabel], PlrName [TextLabel], Amount [TextLabel], PlayerIcon [ImageLabel?])

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Ordered = DataStoreService:GetOrderedDataStore("TimePlayedRank_v1")

local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local scroll = mainFrame:WaitForChild("Players"):WaitForChild("Scroll")
local layout = scroll:WaitForChild("UIListLayout")
local template = gui:WaitForChild("Template") :: Frame

-- CONFIG
local SHOW_ENTRIES = 25
local REFRESH_SECS = 60
local DESCENDING = true -- highest time first

local function secondsToNice(s)
	s = math.max(0, math.floor(tonumber(s) or 0))
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local sec = s % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, sec)
	else
		return string.format("%ds", sec)
	end
end

local function usernameFromUserId(userId)
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	return ok and name or ("UserId:" .. tostring(userId))
end

local function clearRows()
	for _, child in ipairs(scroll:GetChildren()) do
		-- keep the header labels "Rank", "Name", "Amount" that you already placed
		if child:IsA("Frame") and child.Name:match("^Row_") then
			child:Destroy()
		end
	end
end

local function addRow(rank, userId, totalSeconds)
	local row = template:Clone()
	row.Name = "Row_" .. rank
	row.Visible = true
	row.Parent = scroll

	local function setText(childName, val)
		local obj = row:FindFirstChild(childName)
		if obj and obj:IsA("TextLabel") then
			obj.Text = tostring(val)
		end
	end

	setText("Rank", rank)
	setText("PlrName", usernameFromUserId(userId))
	setText("Amount", secondsToNice(totalSeconds))

	local avatar = row:FindFirstChild("PlayerIcon")
	if avatar and avatar:IsA("ImageLabel") then
		avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
	end
end

local function refresh()
	clearRows()

	local ok, pages = pcall(function()
		return Ordered:GetSortedAsync(DESCENDING, SHOW_ENTRIES)
	end)
	if not ok then
		-- show a single error row
		local row = template:Clone()
		row.Name = "Row_Error"
		row.Visible = true
		row.Parent = scroll
		local lbl = row:FindFirstChild("PlrName")
		if lbl and lbl:IsA("TextLabel") then lbl.Text = "Leaderboard temporarily unavailable" end
		return
	end

	local page = pages:GetCurrentPage()
	local rank = 1
	for _, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		if userId then
			addRow(rank, userId, tonumber(entry.value) or 0)
			rank += 1
		end
	end

	-- autosize the scroll canvas to fit rows
	task.defer(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
end

-- kick it off + periodic updates
task.spawn(function()
	while true do
		refresh()
		task.wait(REFRESH_SECS)
	end
end)

-- Auto punch controller: toggles the punch remote every 0.5 seconds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local punchEvent = ReplicatedStorage:WaitForChild("PunchEvent")

local AUTO_INTERVAL = 0.5
local autoPunchEnabled = false
local accumulated = 0

local changeEvent = Instance.new("BindableEvent")

local function firePunch()
	punchEvent:FireServer()
end

RunService.Heartbeat:Connect(function(dt)
	if autoPunchEnabled then
		accumulated += dt
		if accumulated >= AUTO_INTERVAL then
			accumulated -= AUTO_INTERVAL
			firePunch()
		end
	else
		accumulated = 0
	end
end)

local function setAutoPunchEnabled(enabled: boolean?): boolean
	local target = enabled == true
	if autoPunchEnabled == target then
		return autoPunchEnabled
	end

	autoPunchEnabled = target
	if autoPunchEnabled then
		accumulated = AUTO_INTERVAL -- fire immediately on next Heartbeat
	else
		accumulated = 0
	end
	changeEvent:Fire(autoPunchEnabled)
	return autoPunchEnabled
end

local function toggleAutoPunch(): boolean
	return setAutoPunchEnabled(not autoPunchEnabled)
end

local function getAutoPunchEnabled(): boolean
	return autoPunchEnabled
end

_G.SetAutoPunchEnabled = setAutoPunchEnabled
_G.ToggleAutoPunch = toggleAutoPunch
_G.GetAutoPunchEnabled = getAutoPunchEnabled
_G.AutoPunchChanged = changeEvent.Event

print("[AutoPunch] Ready - call _G.ToggleAutoPunch() or _G.SetAutoPunchEnabled(true/false)")

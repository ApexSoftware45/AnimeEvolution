--Do not edit this with out knowledge of 'Lua' and roblox's twists. Learn at 'wiki.roblox.com'.
local Config = script.Parent:FindFirstChild("Configuration")

if Config == nil then
	assert(false,"Configuration file missing from this model.")
end


local Dir = Config:FindFirstChild("Direction")
local Pow = Config:FindFirstChild("Power")

if Dir == nil or Pow == nil then
	assert(false,"'Direction' or 'Power' is missing from 'Configuration'")
end

-------[=======[ Main ]=======]-------

local ddir = Vector3.new(0,10,0)

if string.find(string.lower(Dir.Value),"north") ~= nil then
	ddir = ddir + Vector3.new(Pow.Value,0,0)
end

if string.find(string.lower(Dir.Value),"south") ~= nil then
	ddir = ddir + Vector3.new(-(Pow.Value),0,0)
end

if string.find(string.lower(Dir.Value),"east") ~= nil then
	ddir = ddir + Vector3.new(0,0,Pow.Value)
end

if string.find(string.lower(Dir.Value),"west") ~= nil then
	ddir = ddir + Vector3.new(0,0,-(Pow.Value))
end


function Work(pDir)
	local c = pDir:GetChildren()
	if #c == 0 then
		return
	end

	for i, a in pairs(c) do
		if a.className == "Part" then
			local test = a:FindFirstChild("Wind")
			if test == nil then
				if not(a.Anchored) then
					local t = a:FindFirstChild("NO WIND")
					if t ~= nil and t.className ~= "StringValue" then
						t = nil
					end
	
					if t == nil and ddir ~= Vector3.new(0,0,0) then
						local vel = Instance.new("BodyForce")
						vel.force = ddir
						vel.Name = "Wind"
						vel.Parent = a
					end
				end
			else
				if test.force ~= ddir then
					test:Remove()
				end
			end
		end
		Work(a)
	end
end

repeat
	Work(Workspace)
	wait()
until false 
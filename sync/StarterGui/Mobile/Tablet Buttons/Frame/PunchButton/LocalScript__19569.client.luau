local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvents from server
local tutorialDummyEvent = ReplicatedStorage:WaitForChild("TutorialDummyKilled")
local tutorialEggPurchasedEvent = ReplicatedStorage:FindFirstChild("TutorialEggPurchased")
local tutorialPetEquippedEvent = ReplicatedStorage:FindFirstChild("TutorialPetEquipped") -- final step
local tutorialCompletedEvent = ReplicatedStorage:WaitForChild("TutorialCompleted")

-- Server gate for returning players
local getTutorialStatusFn = ReplicatedStorage:FindFirstChild("GetTutorialStatus")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Should this player see the tutorial at all?
local function shouldShowTutorial(): boolean
	-- If attribute is already set, trust it first
	local attr = player:GetAttribute("TutorialCompleted")
	if attr == true then
		return false
	end

	-- Ask server, which can look at saved data / per-server memory
	if getTutorialStatusFn and getTutorialStatusFn:IsA("RemoteFunction") then
		local ok, result = pcall(function()
			return getTutorialStatusFn:InvokeServer()
		end)
		if ok then
			return result and true or false
		end
	end

	-- Fallback: if anything fails, default to showing tutorial
	return true
end

if not shouldShowTutorial() then
	-- Hide any tutorial UI in case something was left visible
	local punchButton = script.Parent
	local clickArrow = punchButton:FindFirstChild("ImageLabel")
	if clickArrow then
		clickArrow:SetAttribute("StopFlashing", true)
		clickArrow.Visible = false
	end

	local tGui = playerGui:FindFirstChild("Tutorial1")
	if tGui then
		local newPlayerFrame = tGui:FindFirstChild("NewPlayer")
		if newPlayerFrame and newPlayerFrame:IsA("Frame") then
			newPlayerFrame.Visible = false
		end
	end

	local visibleButtonsGui = playerGui:FindFirstChild("visibleButtons")
	if visibleButtonsGui and visibleButtonsGui:IsA("ScreenGui") then
		local petsTutFrame = visibleButtonsGui:FindFirstChild("PetsTutorialArrow")
		if petsTutFrame then
			local petsClick = petsTutFrame:FindFirstChild("PetsClickme")
			if petsClick and petsClick:IsA("ImageLabel") then
				petsClick:SetAttribute("StopFlashing", true)
				petsClick.Visible = false
			end
		end
	end

	-- Don’t wire ANY tutorial events for returning players
	return
end

-- Base UI references (only for first-time players)
local punchButton = script.Parent
local clickArrow = punchButton:WaitForChild("ImageLabel")

local tutorialGui = playerGui:WaitForChild("Tutorial1")
local banner = tutorialGui:WaitForChild("NewPlayer")
local bannerText = banner:WaitForChild("TextLabel")

local visibleButtonsGui = playerGui:WaitForChild("visibleButtons")
local petsArrowGui = visibleButtonsGui:WaitForChild("PetsTutorialArrow")
local petsClickArrow = petsArrowGui:WaitForChild("PetsClickme")

petsArrowGui.Enabled = false
petsClickArrow.Visible = false
petsClickArrow.ImageTransparency = 0

-- CONFIG
-- Dummy: Workspace > ItachiDummyTutorial > Head > TutorialArrow (BillboardGui)
local DUMMY_NAME = "ItachiDummyTutorial"
local DUMMY_HEAD_NAME = "Head"
local DUMMY_ARROW_NAME = "TutorialArrow"

-- Egg: Workspace > Pet Egg Stations > CommonEggStation > Glass > BillboardGui
local EGG_FOLDER = "Pet Egg Stations"
local EGG_STATION = "CommonEggStation"
local EGG_GLASS = "Glass"
local EGG_ARROW_NAME = "BillboardGui"

local REWARD_TEXT_DELAY = 4.0
local FINAL_BANNER_DELAY = 8.0

-- Helpers
local function startFlashing(imageLabel)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then return end

	imageLabel.ImageTransparency = 0
	imageLabel:SetAttribute("StopFlashing", false)

	task.spawn(function()
		local visible = true
		while imageLabel
			and imageLabel.Parent
			and not imageLabel:GetAttribute("StopFlashing") do

			local goal = {
				ImageTransparency = visible and 0.6 or 0
			}

			local tween = TweenService:Create(
				imageLabel,
				TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				goal
			)
			tween:Play()
			visible = not visible
			task.wait(0.3)
		end

		if imageLabel then
			imageLabel.ImageTransparency = 0
		end
	end)
end

local function stopFlashing(imageLabel)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then return end
	imageLabel:SetAttribute("StopFlashing", true)
	imageLabel.ImageTransparency = 0
end

local function findDummyArrow()
	local dummy = workspace:FindFirstChild(DUMMY_NAME)
	if not dummy then return nil end
	local head = dummy:FindFirstChild(DUMMY_HEAD_NAME)
	if not head then return nil end
	return head:FindFirstChild(DUMMY_ARROW_NAME)
end

local function findEggArrow()
	local folder = workspace:FindFirstChild(EGG_FOLDER)
	if not folder then return nil end
	local station = folder:FindFirstChild(EGG_STATION)
	if not station then return nil end
	local glass = station:FindFirstChild(EGG_GLASS)
	if not glass then return nil end
	return glass:FindFirstChild(EGG_ARROW_NAME)
end

-- State
local firstPunchDone = false
local dummyStepStarted = false
local petsStepStarted = false
local tutorialFinished = false

local dummyArrowImage : ImageLabel? = nil
local eggArrowImage : ImageLabel? = nil

-- So we can disconnect them on finish
local dummyConn, eggConn, petConn

-- STEP 1
bannerText.Text = "Welcome! Tap the punch button to train!"
banner.Visible = true
clickArrow.Visible = true
startFlashing(clickArrow)

-- STEP 2: dummy
local function startDummyStep()
	if dummyStepStarted or tutorialFinished then return end
	dummyStepStarted = true

	bannerText.Text = "Great! Now walk over and defeat the training dummy!"
	banner.Visible  = true

	local arrow = findDummyArrow()
	if arrow and arrow:IsA("BillboardGui") then
		arrow.Enabled = true
		local img = arrow:FindFirstChildWhichIsA("ImageLabel")
		if img then
			dummyArrowImage = img
			startFlashing(img)
		end
	end
end

-- STEP 3: egg
local function startEggStep()
	if tutorialFinished then return end

	bannerText.Text = "Now walk over to the egg to hatch a pet!"
	banner.Visible  = true

	local arrow = findEggArrow()
	if arrow and arrow:IsA("BillboardGui") then
		arrow.Enabled = true
		local img = arrow:FindFirstChildWhichIsA("ImageLabel")
		if img then
			eggArrowImage = img
			startFlashing(img)
		end
	end
end

-- STEP 4: pets
local function startPetsStep()
	if petsStepStarted or tutorialFinished then return end
	petsStepStarted = true

	if eggArrowImage then
		stopFlashing(eggArrowImage)
	end
	local eggArrow = findEggArrow()
	if eggArrow and eggArrow:IsA("BillboardGui") then
		eggArrow.Enabled = false
	end

	bannerText.Text = "Open up your Pets and equip your first Pet!"
	banner.Visible  = true

	petsArrowGui.Enabled   = true
	petsClickArrow.Visible = true
	startFlashing(petsClickArrow)
end

-- FINAL: tutorial completed once
local function finishTutorial()
	if tutorialFinished then return end
	tutorialFinished = true

	-- Tell the server we’re done so it can persist this
	tutorialCompletedEvent:FireServer()

	-- Disconnect listeners so killing Itachi / buying more eggs
	-- never triggers the tutorial again in this session
	if dummyConn then dummyConn:Disconnect(); dummyConn = nil end
	if eggConn   then eggConn:Disconnect();   eggConn   = nil end
	if petConn   then petConn:Disconnect();   petConn   = nil end

	stopFlashing(petsClickArrow)
	petsClickArrow.Visible = false
	petsArrowGui.Enabled   = false

	bannerText.Text = "Awesome! Your pet boosts your damage and cash. Have fun training!"
	banner.Visible  = true

	task.delay(FINAL_BANNER_DELAY, function()
		if banner and tutorialFinished then
			banner.Visible = false
		end
	end)
end

-- Connections
local function onPunch()
	if firstPunchDone or tutorialFinished then return end
	firstPunchDone = true

	stopFlashing(clickArrow)
	clickArrow.Visible = false

	startDummyStep()
end

punchButton.Activated:Connect(onPunch)

dummyConn = tutorialDummyEvent.OnClientEvent:Connect(function()
	if tutorialFinished then return end

	if dummyArrowImage then
		stopFlashing(dummyArrowImage)
	end
	local arrow = findDummyArrow()
	if arrow and arrow:IsA("BillboardGui") then
		arrow.Enabled = false
	end

	bannerText.Text = "Nice! You defeated the training dummy! +50 XP +1000 Cash!"
	banner.Visible  = true

	task.delay(REWARD_TEXT_DELAY, function()
		if not tutorialFinished then
			startEggStep()
		end
	end)
end)

if tutorialEggPurchasedEvent then
	eggConn = tutorialEggPurchasedEvent.OnClientEvent:Connect(function()
		if tutorialFinished then return end
		startPetsStep()
	end)
end

if tutorialPetEquippedEvent then
	petConn = tutorialPetEquippedEvent.OnClientEvent:Connect(function()
		if tutorialFinished then return end
		finishTutorial()
	end)
end 
--[[
	STEAL A GAME  —  CLIENT SCRIPT
	Put this LocalScript in StarterPlayer > StarterPlayerScripts.
	Handles the on-screen UI, chase music and effects, the treadmill running
	animation, slap knockback, and "Sell"/"Steal" prompt text.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------
-- Chase music: paste the ID of any music track you're allowed to use.
-- In Studio: Toolbox > Audio, search "chase" or "intense", right-click a
-- track > Copy Asset ID, then paste the number between the quotes.
local CHASE_MUSIC_ID = ""
local CHASE_MUSIC_VOLUME = 0.6
-- Speed numbers are "speed points" set by the server (Config in ServerScriptService.StealAGame)
local START_SPEED = ReplicatedStorage:GetAttribute("StartSpeed") or 1000

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")

------------------------------------------------------------------
-- UI
------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "StealAGameUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextStrokeTransparency = 0
	l.TextColor3 = Color3.new(1, 1, 1)
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = props.Parent or gui
	return l
end

-- Cash and speed, top left under Roblox's buttons: two separate round boxes
local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
-- The shop opens to a section when you press a + button
local function openShopSection(section)
	local menuGui = player.PlayerGui:FindFirstChild("MenuUI")
	local ev = menuGui and menuGui:FindFirstChild("OpenShopSection")
	if ev then
		ev:Fire(section)
	end
end
local function statBox(y, icon, color, dark, section)
	local box = UI.new("Frame", {Position = UDim2.fromOffset(18, y), Size = UDim2.fromOffset(290, 66), BackgroundColor3 = Color3.new(1, 1, 1), Parent = gui}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 4)})
	UI.gradient(box, color, dark, 90)
	UI.new("Frame", {Size = UDim2.new(1, -24, 0.4, 0), Position = UDim2.fromOffset(12, 4), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, Parent = box}, {UI.corner(1, true)})
	local iconBubble = UI.new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -8, 0.5, 0), Size = UDim2.fromOffset(78, 78), BackgroundColor3 = Color3.new(1, 1, 1), Parent = box}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 4)})
	UI.label({Position = UDim2.fromScale(0.12, 0.12), Size = UDim2.fromScale(0.76, 0.76), Text = icon, Outline = false, Parent = iconBubble})
	-- + button that opens that part of the shop
	local plus = UI.new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, Parent = box}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 3)})
	UI.gradient(plus, Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 170, 30), 90)
	-- The plus is drawn from bars (a "+" character sits off-centre in this font): black outline bars, then white bars on top
	for _, bar in ipairs({{28, 11, Color3.new(0, 0, 0)}, {11, 28, Color3.new(0, 0, 0)}, {23, 6, Color3.new(1, 1, 1)}, {6, 23, Color3.new(1, 1, 1)}}) do
		UI.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(bar[1], bar[2]), BackgroundColor3 = bar[3], BorderSizePixel = 0, Parent = plus}, {UI.corner(3)})
	end
	UI.bounce(plus)
	plus.Activated:Connect(function()
		openShopSection(section)
	end)
	return UI.label({Position = UDim2.fromOffset(80, 10), Size = UDim2.new(1, -140, 1, -20), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 3.5, Parent = box})
end
local cashLabel = statBox(72, "\u{1F4B5}", Color3.fromRGB(120, 235, 120), Color3.fromRGB(40, 160, 60), "cash")
local speedLabel = statBox(160, "\u{1F45F}", Color3.fromRGB(130, 200, 255), Color3.fromRGB(40, 110, 220), "speed")
-- active boosts show under the boxes
local boostLabel = UI.label({Position = UDim2.fromOffset(22, 236), Size = UDim2.fromOffset(290, 66), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Outline = 2.5, Parent = gui})

-- DROP button (or press G) while you're holding a game
local dropButton, dropText = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(190, 54), Text = "DROP (G)", Parent = gui}, Color3.fromRGB(235, 80, 80))
dropButton.Visible = false

local notifLabel = label({
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62),
	Size = UDim2.fromOffset(860, 52), Visible = false,
})

-- "SOMEONE IS STEALING YOUR GAME!" alarm banner (big and flashing)
local alertBanner = UI.new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 176), Size = UDim2.fromOffset(820, 86), BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 30, Parent = gui}, {UI.corner(18), UI.stroke(Color3.new(0, 0, 0), 5)})
local alertGrad = UI.gradient(alertBanner, Color3.fromRGB(255, 70, 70), Color3.fromRGB(190, 0, 20), 90)
local alertText = UI.label({Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.94, 0.58), Text = "", Outline = 4, ZIndex = 31, Parent = alertBanner})
local alertSub = UI.label({Position = UDim2.fromScale(0.03, 0.64), Size = UDim2.fromScale(0.94, 0.3), Text = "", Outline = 2.5, ZIndex = 31, Parent = alertBanner})
local alertScale = UI.new("UIScale", {Parent = alertBanner})
local alertToken = 0
remotes:WaitForChild("Alert").OnClientEvent:Connect(function(kind, thief, gameName)
	alertToken += 1
	local my = alertToken
	if kind == "stealing" then
		alertText.Text = "\u{1F6A8} " .. string.upper(thief) .. " IS STEALING YOUR GAME! \u{1F6A8}"
		alertSub.Text = "Chase them and SLAP them to get " .. gameName .. " back!"
	else
		alertText.Text = "\u{1F6A8} " .. string.upper(thief) .. " STOLE YOUR GAME! \u{1F6A8}"
		alertSub.Text = gameName .. " is gone. Lock your base to stay safe!"
	end
	alertBanner.Visible = true
	alertScale.Scale = 0.6
	TweenService:Create(alertScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.spawn(function()
		local t0 = os.clock()
		while alertToken == my and os.clock() - t0 < 4.5 do
			local on = math.floor((os.clock() - t0) * 4) % 2 == 0
			alertGrad.Color = on and ColorSequence.new(Color3.fromRGB(255, 70, 70), Color3.fromRGB(190, 0, 20)) or ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 120, 0))
			task.wait(0.05)
		end
		if alertToken == my then
			alertBanner.Visible = false
		end
	end)
end)

-- Big chase banner that stays up for the whole chase
local chaseLabel = label({
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 108),
	Size = UDim2.fromOffset(600, 56), TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundColor3 = Color3.fromRGB(220, 40, 50), BackgroundTransparency = 0.1,
	TextStrokeTransparency = 0.4, Text = "YOU'RE BEING CHASED! RUN HOME!", Visible = false,
})
Instance.new("UICorner", chaseLabel).CornerRadius = UDim.new(0, 14)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = chaseLabel
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = chaseLabel
end

-- "CAUGHT!" flash
local caughtFlash = Instance.new("Frame")
caughtFlash.Size = UDim2.fromScale(1, 1)
caughtFlash.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
caughtFlash.BackgroundTransparency = 1
caughtFlash.ZIndex = 20
caughtFlash.Parent = gui
local caughtText = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(700, 110), Text = "CAUGHT!", TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 21})
local caughtSub = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(700, 34), Text = "", TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 21})

-- On the treadmill: a simple STOP button that works with touch, mouse or controller
local treadLabel = UI.new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(320, 120), BackgroundTransparency = 1, Visible = false, Parent = gui})
UI.label({Size = UDim2.new(1, 0, 0, 44), Text = "\u{1F3C3} RUNNING!", TextColor3 = Color3.fromRGB(120, 200, 255), Outline = 3.5, Parent = treadLabel})
local stopButton = UI.actionButton({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.fromOffset(200, 62), Text = "STOP", Parent = treadLabel}, Color3.fromRGB(235, 70, 80))

label({
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(640, 22), Font = Enum.Font.Gotham, TextStrokeTransparency = 0.5,
	Text = "Go deeper into the Vault for rarer games  |  Run them home before the shopkeeper catches you  |  Press ? for help",
})

-- Red vignette for chases
local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 1
vignette.Parent = gui
local vignetteStroke = Instance.new("UIStroke")
vignetteStroke.Color = Color3.fromRGB(255, 0, 0)
vignetteStroke.Thickness = 22
vignetteStroke.Transparency = 1
vignetteStroke.Parent = vignette

------------------------------------------------------------------
-- CASH + SPEED
------------------------------------------------------------------
local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local function updateCash()
	cashLabel.Text = "$" .. UI.fmt(cash.Value)
end
cash.Changed:Connect(updateCash)
updateCash()

-- Finer number for speed so it visibly ticks up (1.23M, 512.4K)
local SUF = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
local function speedText(points)
	if points < 1000 then
		return tostring(math.floor(points))
	end
	local i = math.min(#SUF, math.floor(math.log10(points) / 3))
	local v = points / 10 ^ (i * 3)
	local s = v < 100 and string.format("%.2f", math.floor(v * 100) / 100) or string.format("%.1f", math.floor(v * 10) / 10)
	return s .. SUF[i]
end

-- The speed number counts up smoothly toward the real value
local shownSpeed = (player:GetAttribute("SpeedPoints") or START_SPEED) * (player:GetAttribute("SpeedMultiplier") or 1)
local function targetSpeed()
	return (player:GetAttribute("SpeedPoints") or START_SPEED) * (player:GetAttribute("SpeedMultiplier") or 1)
end
local function updateSpeedLabel()
	speedLabel.Text = speedText(shownSpeed)
end
RunService.RenderStepped:Connect(function(dt)
	local target = targetSpeed()
	if math.abs(target - shownSpeed) > 0.5 then
		shownSpeed += (target - shownSpeed) * math.min(1, dt * 8)
		if math.abs(target - shownSpeed) < 1 then
			shownSpeed = target
		end
		updateSpeedLabel()
	end
end)

-- Boost timers
task.spawn(function()
	while true do
		local lines = {}
		local now = workspace:GetServerTimeNow()
		local su = player:GetAttribute("BoostSpeedUntil") or 0
		if su > now then
			table.insert(lines, '<font color="#7fd8ff">\u{26A1} ' .. tostring(player:GetAttribute("BoostSpeed")) .. 'x speed  ' .. UI.fmtTime(su - now) .. '</font>')
		end
		local mu = player:GetAttribute("BoostMoneyUntil") or 0
		if mu > now then
			table.insert(lines, '<font color="#ffd23c">\u{1F911} ' .. tostring(player:GetAttribute("BoostMoney")) .. 'x money  ' .. UI.fmtTime(mu - now) .. '</font>')
		end
		local friends = player:GetAttribute("FriendsHere") or 0
		if friends > 0 then
			table.insert(lines, '<font color="#78ff5a">\u{1F465} +' .. (friends * 10) .. '% cash from friends</font>')
		end
		boostLabel.Text = table.concat(lines, "\n")
		task.wait(0.5)
	end
end)

-- Drop
local dropEvent = remotes:WaitForChild("DropHeld")
local function refreshDrop()
	dropButton.Visible = (player:GetAttribute("Held") or 0) > 0
end
player:GetAttributeChangedSignal("Held"):Connect(refreshDrop)
refreshDrop()
dropButton.Activated:Connect(function()
	dropEvent:FireServer()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.G and (player:GetAttribute("Held") or 0) > 0 then
		dropEvent:FireServer()
	end
end)
player:GetAttributeChangedSignal("SpeedPoints"):Connect(updateSpeedLabel)
player:GetAttributeChangedSignal("SpeedMultiplier"):Connect(updateSpeedLabel)

local downUntil = 0
remotes:WaitForChild("Caught").OnClientEvent:Connect(function(title)
	-- Fall flat on the ground, then get back up
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum and root and not root.Anchored then
		downUntil = os.clock() + 1.8
		hum.PlatformStand = true
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {char}
		params.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), params)
		local groundY = hit and hit.Position.Y or (root.Position.Y - 3)
		local _, yaw = root.CFrame:ToEulerAnglesYXZ()
		root.CFrame = CFrame.new(root.Position.X, groundY + 1.1, root.Position.Z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(90), 0, 0)
		root.AssemblyLinearVelocity = Vector3.zero
		task.delay(1.8, function()
			if hum.Parent and os.clock() >= downUntil then
				hum.PlatformStand = false
				local pos = root.Position
				root.CFrame = CFrame.new(pos.X, pos.Y + 2.5, pos.Z) * CFrame.Angles(0, yaw, 0)
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
	caughtSub.Text = "The " .. tostring(title) .. " grabbed you. The game was returned."
	caughtFlash.BackgroundTransparency = 0.45
	caughtText.TextTransparency, caughtText.TextStrokeTransparency = 0, 0
	caughtSub.TextTransparency, caughtSub.TextStrokeTransparency = 0, 0
	caughtText.Size = UDim2.fromOffset(900, 150)
	TweenService:Create(caughtText, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(700, 110)}):Play()
	task.delay(1.3, function()
		local info = TweenInfo.new(0.6)
		TweenService:Create(caughtFlash, info, {BackgroundTransparency = 1}):Play()
		TweenService:Create(caughtText, info, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		TweenService:Create(caughtSub, info, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end)
updateSpeedLabel()

------------------------------------------------------------------
-- NOTIFICATIONS
------------------------------------------------------------------
local notifToken = 0
remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, color)
	notifToken += 1
	local myToken = notifToken
	notifLabel.Text = text
	notifLabel.TextColor3 = color or Color3.new(1, 1, 1)
	notifLabel.TextTransparency = 0
	notifLabel.TextStrokeTransparency = 0
	notifLabel.Visible = true
	task.delay(2.5, function()
		if notifToken == myToken then
			TweenService:Create(notifLabel, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end)

------------------------------------------------------------------
-- SLAP / CATCH KNOCKBACK
------------------------------------------------------------------
remotes:WaitForChild("Knockback").OnClientEvent:Connect(function(velocity)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum and not root.Anchored then
		if os.clock() < downUntil then
			-- Already knocked flat by a shopkeeper: just a small slide
			root.AssemblyLinearVelocity = velocity * 0.35
			return
		end
		hum.PlatformStand = true
		root.AssemblyLinearVelocity = velocity
		task.delay(0.7, function()
			if hum.Parent and os.clock() >= downUntil then
				hum.PlatformStand = false
			end
		end)
	end
end)

------------------------------------------------------------------
-- CHASE MUSIC + EFFECTS
------------------------------------------------------------------
local music = Instance.new("Sound")
music.Name = "ChaseMusic"
music.Looped = true
music.Volume = 0
music.SoundId = CHASE_MUSIC_ID ~= "" and ("rbxassetid://" .. CHASE_MUSIC_ID) or ""
music.Parent = SoundService

local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "ChaseTint"
tint.Parent = Lighting

local chasing = false
local chaseToken = 0

remotes:WaitForChild("Chase").OnClientEvent:Connect(function(on, title)
	chasing = on
	chaseToken += 1
	local myToken = chaseToken
	local camera = workspace.CurrentCamera

	if on then
		chaseLabel.Text = "THE " .. string.upper(tostring(title or "SHOPKEEPER")) .. " IS CHASING YOU! RUN HOME!"
		chaseLabel.Visible = true
		if music.SoundId ~= "" then
			if not music.IsPlaying then
				music.TimePosition = 0
				music:Play()
			end
			TweenService:Create(music, TweenInfo.new(0.5), {Volume = CHASE_MUSIC_VOLUME}):Play()
		end
		-- A gentle, steady red edge and slight tint (no flashing, no camera zoom)
		TweenService:Create(tint, TweenInfo.new(0.6), {TintColor = Color3.fromRGB(255, 235, 235), Saturation = 0.05, Contrast = 0.05}):Play()
		TweenService:Create(vignetteStroke, TweenInfo.new(0.6), {Transparency = 0.75}):Play()
	else
		chaseLabel.Visible = false
		TweenService:Create(vignetteStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
		TweenService:Create(tint, TweenInfo.new(0.8), {TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0}):Play()
		TweenService:Create(camera, TweenInfo.new(0.8), {FieldOfView = 70}):Play()
		if music.IsPlaying then
			local fade = TweenService:Create(music, TweenInfo.new(1.2), {Volume = 0})
			fade:Play()
			fade.Completed:Connect(function()
				if not chasing then
					music:Stop()
				end
			end)
		end
	end
end)

------------------------------------------------------------------
-- TREADMILL RUNNING ANIMATION
------------------------------------------------------------------
local runTrack
local onTreadmill = false
local treadmillStop = remotes:WaitForChild("TreadmillStop")

local function stopRunAnim()
	if runTrack then
		runTrack:Stop(0.2)
		runTrack = nil
	end
end

remotes:WaitForChild("Treadmill").OnClientEvent:Connect(function(on)
	onTreadmill = on
	treadLabel.Visible = on
	stopRunAnim()
	if not on then return end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = hum.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180426354" or "rbxassetid://913376220"
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		runTrack = track
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.2)
		local points = player:GetAttribute("SpeedPoints") or START_SPEED
		track:AdjustSpeed(1 + math.clamp(math.log10(points / START_SPEED), 0, 6) * 0.35)
	end
end)

-- Every second on the treadmill, pop up how much speed you just gained, beside your character
local function showGainPopup(gained)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not camera then return end
	local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen then return end

	local text = gained < 10 and string.format("+%.1f speed", gained) or ("+" .. speedText(gained) .. " speed")
	local popup = label({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(screenPos.X + 90 + math.random(-10, 10), screenPos.Y - 20 + math.random(-15, 15)),
		Size = UDim2.fromOffset(180, 34),
		TextColor3 = Color3.fromRGB(90, 255, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	})
	local rise = TweenService:Create(popup, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = popup.Position - UDim2.fromOffset(0, 70),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	rise:Play()
	rise.Completed:Connect(function()
		popup:Destroy()
	end)
end

task.spawn(function()
	local lastBonus = player:GetAttribute("SpeedPoints") or START_SPEED
	while true do
		task.wait(1)
		local bonus = player:GetAttribute("SpeedPoints") or START_SPEED
		local gained = bonus - lastBonus
		lastBonus = bonus
		if onTreadmill and gained > 0 then
			showGainPopup(gained)
		end
	end
end)

-- Jump or press STOP to get off the treadmill
local function leaveTreadmill()
	if onTreadmill then
		onTreadmill = false
		treadLabel.Visible = false
		treadmillStop:FireServer()
	end
end
UserInputService.JumpRequest:Connect(leaveTreadmill)
stopButton.Activated:Connect(leaveTreadmill)

------------------------------------------------------------------
-- SLOW DOWN switch (walk at normal speed when you want precise control)
------------------------------------------------------------------
do
	local slowEvent = remotes:WaitForChild("SlowDown")
	local holder = UI.new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -40), Size = UDim2.fromOffset(220, 58), BackgroundColor3 = Color3.new(1, 1, 1), Parent = gui}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 3.5)})
	UI.gradient(holder, Color3.fromRGB(80, 75, 120), Color3.fromRGB(40, 36, 70), 90)
	UI.label({Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(110, 34), TextXAlignment = Enum.TextXAlignment.Left, Text = "Slow Down", Outline = 3, Parent = holder})
	local track = UI.new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(74, 38), BackgroundColor3 = Color3.fromRGB(110, 110, 130), Text = "", AutoButtonColor = false, Parent = holder}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 3)})
	local knob = UI.new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track}, {UI.corner(1, true), UI.stroke(Color3.new(0, 0, 0), 2)})
	local on = false
	local function render()
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.new(1, -34, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)}):Play()
		TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = on and Color3.fromRGB(70, 210, 100) or Color3.fromRGB(110, 110, 130)}):Play()
	end
	track.Activated:Connect(function()
		on = not on
		render()
		slowEvent:FireServer(on)
	end)
end

------------------------------------------------------------------
-- NO CRAZY SPINNING: never trip or ragdoll from bumping into things
------------------------------------------------------------------
local function steadyCharacter(char)
	local hum = char:WaitForChild("Humanoid")
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end
if player.Character then
	task.spawn(steadyCharacter, player.Character)
end
player.CharacterAdded:Connect(steadyCharacter)
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum and not hum.PlatformStand and not root.Anchored then
		local spin = root.AssemblyAngularVelocity
		if spin.Magnitude > 6 then
			root.AssemblyAngularVelocity = Vector3.new(0, math.clamp(spin.Y, -6, 6), 0)
		end
		-- if something tipped you over, stand back up
		if root.CFrame.UpVector.Y < 0.5 and os.clock() > downUntil then
			local _, yaw = root.CFrame:ToEulerAnglesYXZ()
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
		end
	end
end)

------------------------------------------------------------------
-- LOCK WALLS: other bases' walls are solid, your own lets you through
------------------------------------------------------------------
task.spawn(function()
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local bases = map and map:WaitForChild("Bases", 60)
	if not bases then return end
	local function hook(d)
		if (d.Name == "LaserBarrier" or d.Name == "DoorBarrier") and d:IsA("BasePart") then
			local function apply()
				if d:GetAttribute("OwnerId") == player.UserId and d.CanCollide then
					d.CanCollide = false
				end
			end
			d:GetPropertyChangedSignal("CanCollide"):Connect(apply)
			d:GetAttributeChangedSignal("OwnerId"):Connect(apply)
			apply()
		end
	end
	for _, d in ipairs(bases:GetDescendants()) do
		hook(d)
	end
	bases.DescendantAdded:Connect(hook)
end)

------------------------------------------------------------------
-- INVITE A FRIEND pad by the vault path
------------------------------------------------------------------
task.spawn(function()
	local SocialService = game:GetService("SocialService")
	local map = workspace:WaitForChild("StealAGameMap", 30)
	local inviteModel = map and map:WaitForChild("Lobby", 30) and map.Lobby:WaitForChild("InviteFriend", 30)
	if not inviteModel then return end
	local touch = inviteModel:WaitForChild("InviteTouch")
	local last = 0
	touch.Touched:Connect(function(hit)
		if hit.Parent ~= player.Character or os.clock() - last < 6 then return end
		last = os.clock()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		end
	end)
	-- spin the cash around the character and let the character bob (only while it's close enough to see)
	local orbit = inviteModel:WaitForChild("InviteCash")
	local center = orbit:GetAttribute("Center") or touch.Position
	local inviter = inviteModel:FindFirstChild("Inviter")
	local base = inviter and inviter:GetPivot()
	local start = {}
	for _, p in ipairs(orbit:GetChildren()) do
		start[p] = p.CFrame
	end
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam or (cam.CFrame.Position - center).Magnitude > 220 then return end
		local t = os.clock()
		local spinCF = CFrame.new(center) * CFrame.Angles(0, t * 1.2, 0) * CFrame.new(-center)
		for p, cf in pairs(start) do
			p.CFrame = spinCF * cf * CFrame.new(0, math.sin(t * 2 + cf.Position.X) * 0.4, 0)
		end
		if inviter and base then
			inviter:PivotTo(base * CFrame.new(0, math.sin(t * 2) * 0.3, 0) * CFrame.Angles(0, math.sin(t * 0.8) * 0.4, 0))
		end
	end)

	-- Swap the stand-in for one of your own friends (only you see this one)
	local avatars = ReplicatedStorage:WaitForChild("InviteAvatars", 30)
	local friend = avatars and avatars:WaitForChild(tostring(player.UserId), 30)
	if not (friend and inviter and base) then return end
	local function feetBelowPivot(model)
		local box, size = model:GetBoundingBox()
		return model:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	end
	local standIn = inviter
	local clone = friend:Clone()
	clone:PivotTo(base)
	local newBase = base + Vector3.new(0, feetBelowPivot(clone) - feetBelowPivot(standIn), 0)
	clone:PivotTo(newBase)
	clone.Parent = inviteModel
	inviter, base = clone, newBase
	standIn.Parent = nil
	local labelPart = inviteModel:FindFirstChild("InviteLabel")
	local text = labelPart and labelPart:FindFirstChildWhichIsA("TextLabel", true)
	if text then
		local name = (friend:GetAttribute("FriendName") or "FRIEND"):gsub("[<>&]", ""):upper()
		text.Text = '<font color="#ffd23c">\u{1F465} INVITE ' .. name .. ' \u{1F465}</font>\n<font color="#78ff5a">Each Friend = 10% Cash Boost</font>'
	end
end)

player.CharacterAdded:Connect(function()
	onTreadmill = false
	treadLabel.Visible = false
	stopRunAnim()
end)

------------------------------------------------------------------
-- CASE BUTTONS
-- Your cases: Pick up / Place / Swap (E) and Sell (F).
-- Someone else's cases: Steal (E).
------------------------------------------------------------------
local function refreshCasePrompt(prompt)
	local mine = prompt:GetAttribute("OwnerId") == player.UserId
	local hasGame = prompt:GetAttribute("HasGame") == true
	local heldCount = player:GetAttribute("Held") or 0
	if mine then
		if hasGame then
			prompt.ActionText = heldCount >= 2 and "Swap" or "Pick up"
			prompt.Enabled = true
		else
			local first = string.split(player:GetAttribute("HeldNames") or "", "|")[1]
			prompt.ActionText = (first and first ~= "") and ("Place " .. first) or "Place game"
			prompt.Enabled = heldCount > 0 and prompt:GetAttribute("Reserved") ~= true
		end
	else
		prompt.ActionText = "Steal"
		prompt.Enabled = hasGame
	end
end

local function refreshSellPrompt(prompt)
	prompt.Enabled = prompt:GetAttribute("OwnerId") == player.UserId and prompt:GetAttribute("HasGame") == true
end

local function watch(tag, refresh)
	local function add(prompt)
		refresh(prompt)
		prompt.AttributeChanged:Connect(function()
			refresh(prompt)
		end)
	end
	for _, prompt in ipairs(CollectionService:GetTagged(tag)) do
		add(prompt)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
end
watch("CasePrompt", refreshCasePrompt)
watch("SellPrompt", refreshSellPrompt)
-- Buy-case / build-floor buttons only show for the base's owner
watch("OwnerOnlyPrompt", function(prompt)
	prompt.Enabled = prompt:GetAttribute("OwnerId") == player.UserId
end)

------------------------------------------------------------------
-- INSTALL TIMERS: fade in when you're close to a case, fade out as you leave
------------------------------------------------------------------
local FADE_NEAR, FADE_FAR = 14, 24
local fadeTimer = 0
RunService.Heartbeat:Connect(function(dt)
	fadeTimer += dt
	if fadeTimer < 0.05 then return end
	fadeTimer = 0
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, bb in ipairs(CollectionService:GetTagged("InstallTimer")) do
		local adornee = bb.Parent
		local label = bb:FindFirstChildOfClass("TextLabel")
		if adornee and adornee:IsA("BasePart") and label then
			local alpha = 1
			if bb:GetAttribute("Active") == true then
				local d = (adornee.Position - root.Position).Magnitude
				alpha = math.clamp((d - FADE_NEAR) / (FADE_FAR - FADE_NEAR), 0, 1)
			end
			bb.Enabled = alpha < 1
			label.TextTransparency = alpha
			label.TextStrokeTransparency = math.max(alpha, 0.2)
		end
	end
end)

local function refreshAllCasePrompts()
	for _, prompt in ipairs(CollectionService:GetTagged("CasePrompt")) do
		refreshCasePrompt(prompt)
	end
end
player:GetAttributeChangedSignal("Held"):Connect(refreshAllCasePrompts)
player:GetAttributeChangedSignal("HeldNames"):Connect(refreshAllCasePrompts)
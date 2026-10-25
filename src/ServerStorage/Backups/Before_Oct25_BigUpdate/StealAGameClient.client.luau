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

------------------------------------------------------------------
-- SOUNDS the server asks for (locking, unlocking, slap hits)
------------------------------------------------------------------
remotes:WaitForChild("PlaySound").OnClientEvent:Connect(function(name)
	UI.sfx(name)
end)

------------------------------------------------------------------
-- SLAP: a real swing of the arm, with a whoosh, synced with the hit
------------------------------------------------------------------
local swinging = false
local function slapSwing()
	local char = player.Character
	if swinging or not char then return end
	local shoulder
	local arm = char:FindFirstChild("RightUpperArm")
	if arm then
		shoulder = arm:FindFirstChild("RightShoulder")
	else
		local torso = char:FindFirstChild("Torso")
		shoulder = torso and torso:FindFirstChild("Right Shoulder")
	end
	if not shoulder then return end
	swinging = true
	UI.sfx("swing")
	local base = shoulder.C0
	-- wind up out to the side, sweep across in front (the hit lands here), then relax back
	local keys = {
		{CFrame.Angles(math.rad(60), 0, math.rad(70)), 0.08, Enum.EasingStyle.Quad},
		{CFrame.Angles(math.rad(85), 0, math.rad(-55)), 0.1, Enum.EasingStyle.Back},
		{CFrame.new(), 0.18, Enum.EasingStyle.Sine},
	}
	task.spawn(function()
		for _, k in ipairs(keys) do
			if not shoulder.Parent then break end
			local tw = TweenService:Create(shoulder, TweenInfo.new(k[2], k[3], Enum.EasingDirection.Out), {C0 = base * k[1]})
			tw:Play()
			tw.Completed:Wait()
		end
		if shoulder.Parent then
			shoulder.C0 = base
		end
		swinging = false
	end)
end
local hookedTools = {}
local function watchTool(tool)
	if tool:IsA("Tool") and tool.Name == "Slap" and not hookedTools[tool] then
		hookedTools[tool] = true
		tool.Activated:Connect(slapSwing)
	end
end
local function watchCharacter(char)
	for _, c in ipairs(char:GetChildren()) do
		watchTool(c)
	end
	char.ChildAdded:Connect(watchTool)
end
if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

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
-- GIANT SHOPKEEPERS: every stride is a heavy thud that shakes your screen,
-- harder the closer they are (and while they're chasing you)
------------------------------------------------------------------
local shake = 0
local chasing = false -- set by the chase event below
local function addShake(amount)
	shake = math.max(shake, amount)
end
RunService:BindToRenderStep("GiantShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake <= 0.01 then return end
	local camera = workspace.CurrentCamera
	local t = os.clock() * 28
	local a = shake * shake
	camera.CFrame = camera.CFrame * CFrame.new(math.noise(t, 0.3) * a * 0.9, math.noise(0.7, t) * a * 0.9, 0) * CFrame.Angles(0, 0, math.noise(t, t) * a * 0.035)
	shake = math.max(0, shake - dt * 3)
end)
task.spawn(function()
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local folder = map and map:WaitForChild("Shopkeepers", 60)
	if not folder then return end
	local STOMP_ID = "rbxasset://sounds/action_jump_land.mp3"
	local near = {} -- guards close enough to hear
	local state = {} -- root -> {Sound, Walked, Last}
	-- every half second, find the giants near you
	task.spawn(function()
		while true do
			local cam = workspace.CurrentCamera
			local cp = cam and cam.CFrame.Position
			table.clear(near)
			if cp then
				for _, m in ipairs(folder:GetChildren()) do
					local root = m:FindFirstChild("HumanoidRootPart")
					if root and (root.Position - cp).Magnitude < 170 then
						table.insert(near, root)
						if not state[root] then
							local s = Instance.new("Sound")
							s.SoundId = STOMP_ID
							s.Volume = 1.6
							s.RollOffMode = Enum.RollOffMode.InverseTapered
							s.RollOffMinDistance = 15
							s.RollOffMaxDistance = 170
							s.Parent = root
							state[root] = {Sound = s, Walked = 0, Last = root.Position, Scale = m:GetAttribute("Scale") or 4}
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local char = player.Character
		local me = char and char:FindFirstChild("HumanoidRootPart")
		for _, root in ipairs(near) do
			local st = state[root]
			if st and root.Parent then
				local p = root.Position
				st.Walked += Vector3.new(p.X - st.Last.X, 0, p.Z - st.Last.Z).Magnitude
				st.Last = p
				if st.Walked >= 2.2 * st.Scale then
					st.Walked = 0
					st.Sound.PlaybackSpeed = 0.32 + math.random() * 0.08
					st.Sound:Play()
					if me then
						local close = 1 - math.clamp((p - me.Position).Magnitude / 110, 0, 1)
						addShake(close * (chasing and 1.25 or 0.75))
					end
				end
			end
		end
	end)
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

local chaseToken = 0

remotes:WaitForChild("Chase").OnClientEvent:Connect(function(on, title)
	chasing = on
	chaseToken += 1
	local myToken = chaseToken
	local camera = workspace.CurrentCamera

	if on then
		chaseLabel.Text = "THE " .. string.upper(tostring(title or "SHOPKEEPER")) .. " IS CHASING YOU! RUN HOME!"
		chaseLabel.Visible = true
		addShake(1.3) -- the giant spots you
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

-- Every second on the treadmill the server sends the exact gain: pop it up beside you
-- with a shoe, a bounce and a soft ping that climbs in pitch the longer you run
local gainSound = Instance.new("Sound")
gainSound.Name = "TreadGain"
gainSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
gainSound.Volume = 0.35
gainSound.Parent = SoundService
local gainStreak = 0
local function showGainPopup(gained)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not camera then return end
	gainStreak = math.min(gainStreak + 1, 12)
	-- (no sound: the treadmill ping every second was too annoying)
	local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen then return end

	local amount = gained < 10 and string.format("%.1f", gained) or speedText(gained)
	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 48), Rotation = math.random(-8, 8),
		Position = UDim2.fromOffset(screenPos.X + 70 + math.random(-12, 12), screenPos.Y - 30 + math.random(-18, 18)), Parent = gui,
	})
	local scale = UI.new("UIScale", {Scale = 0.2, Parent = holder})
	local shoe = UI.label({Size = UDim2.fromOffset(48, 48), Text = "\u{1F45F}", Outline = false, Parent = holder})
	local num = UI.label({Position = UDim2.fromOffset(50, 2), Size = UDim2.fromOffset(150, 44), TextXAlignment = Enum.TextXAlignment.Left, Text = "+" .. amount, Outline = 3.5, Parent = holder})
	UI.gradient(num, Color3.fromRGB(180, 255, 190), Color3.fromRGB(40, 210, 90), 90)
	local stroke = num:FindFirstChildOfClass("UIStroke")
	-- pop in big, settle, drift up and fade
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.15}):Play()
	task.delay(0.25, function()
		TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1}):Play()
	end)
	TweenService:Create(shoe, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Rotation = -20}):Play()
	local fade = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.45)
	TweenService:Create(holder, TweenInfo.new(1.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = holder.Position - UDim2.fromOffset(0, 80)}):Play()
	TweenService:Create(num, fade, {TextTransparency = 1}):Play()
	TweenService:Create(shoe, fade, {TextTransparency = 1}):Play()
	if stroke then
		TweenService:Create(stroke, fade, {Transparency = 1}):Play()
	end
	task.delay(1.4, function()
		holder:Destroy()
	end)
end
remotes:WaitForChild("TreadGain").OnClientEvent:Connect(showGainPopup)

-- Jump or press STOP to get off the treadmill
local function leaveTreadmill()
	gainStreak = 0
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
		UI.sfx("toggle")
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
	-- a gentle idle and a friendly wave every few seconds
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local function load(id)
			local a = Instance.new("Animation")
			a.AnimationId = id
			local ok, tr = pcall(function()
				return animator:LoadAnimation(a)
			end)
			return ok and tr or nil
		end
		local idle = load("rbxassetid://507766388")
		if idle then
			idle.Looped = true
			idle:Play()
		end
		local wave = load("rbxassetid://507770239")
		if wave then
			wave.Priority = Enum.AnimationPriority.Action
			task.spawn(function()
				while clone.Parent do
					task.wait(6)
					wave:Play(0.3)
				end
			end)
		end
	end
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
------------------------------------------------------------------
-- VAULT GAMES slowly spin and bob on their pedestals (done on your own
-- screen, so the server doesn't have to send 150 moving parts every frame)
------------------------------------------------------------------
task.spawn(function()
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local folder = map and map:WaitForChild("VaultGames", 60)
	if not folder then return end
	local homes = {}
	local function track(item)
		if item:IsA("BasePart") then
			homes[item] = item.CFrame
		end
	end
	for _, item in ipairs(folder:GetChildren()) do
		track(item)
	end
	folder.ChildAdded:Connect(track)
	folder.ChildRemoved:Connect(function(item)
		homes[item] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local cp = cam.CFrame.Position
		local t = os.clock()
		for item, home in pairs(homes) do
			local hp = home.Position
			if (hp - cp).Magnitude < 180 then
				item.CFrame = CFrame.new(hp + Vector3.new(0, math.sin(t * 2 + hp.X) * 0.3, 0)) * CFrame.Angles(0, t * 1.1 + hp.X * 0.1, 0)
			end
		end
	end)
end)

------------------------------------------------------------------
-- TRAIL EFFECTS for everyone near you: rainbow trails flow through every
-- colour, and lightning trails throw real bolts off the runner
------------------------------------------------------------------
do
	local rainbow = {}
	local function addRainbow(obj)
		rainbow[obj] = true
	end
	for _, obj in ipairs(CollectionService:GetTagged("RainbowTrail")) do
		addRainbow(obj)
	end
	CollectionService:GetInstanceAddedSignal("RainbowTrail"):Connect(addRainbow)
	CollectionService:GetInstanceRemovedSignal("RainbowTrail"):Connect(function(obj)
		rainbow[obj] = nil
	end)
	local function hue(h)
		return Color3.fromHSV(h % 1, 0.95, 1)
	end
	local rainbowTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		rainbowTimer += dt
		if rainbowTimer < 1 / 30 or next(rainbow) == nil then return end
		rainbowTimer = 0
		local h = os.clock() * 0.35
		local seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, hue(h)), ColorSequenceKeypoint.new(0.25, hue(h + 0.2)), ColorSequenceKeypoint.new(0.5, hue(h + 0.4)),
			ColorSequenceKeypoint.new(0.75, hue(h + 0.6)), ColorSequenceKeypoint.new(1, hue(h + 0.8)),
		})
		for obj in pairs(rainbow) do
			if obj.Parent then
				obj.Color = seq
			end
		end
	end)

	-- Lightning bolts, drawn from a small pool of reusable parts
	local boltFolder = Instance.new("Folder")
	boltFolder.Name = "TrailBolts"
	boltFolder.Parent = workspace
	local free = {}
	local function getPart()
		local p = table.remove(free)
		if not p then
			p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.Neon
			p.Parent = boltFolder
		end
		return p
	end
	local rng = Random.new()
	local function bolt(from, to, color)
		local pts = {from}
		local n = 6
		local jag = (to - from).Magnitude * 0.13
		for i = 1, n - 1 do
			table.insert(pts, from:Lerp(to, i / n) + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * jag)
		end
		table.insert(pts, to)
		local used = {}
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local len = (b - a).Magnitude
			for layer = 1, 2 do
				local p = getPart()
				local w = layer == 1 and 0.38 or 0.12
				p.Size = Vector3.new(w, w, len)
				p.CFrame = CFrame.lookAt((a + b) / 2, b)
				p.Color = layer == 1 and color or Color3.new(1, 1, 1)
				p.Transparency = layer == 1 and 0.35 or 0
				table.insert(used, p)
			end
		end
		task.delay(rng:NextNumber(0.07, 0.14), function()
			for _, p in ipairs(used) do
				p.Transparency = 1
				table.insert(free, p)
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(0.11)
			local cam = workspace.CurrentCamera
			local cp = cam and cam.CFrame.Position
			if cp then
				for _, plr in ipairs(Players:GetPlayers()) do
					local char = plr.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root and root:GetAttribute("TrailFx") == "lightning" and (root.Position - cp).Magnitude < 150 then
						local vel = root.AssemblyLinearVelocity
						local flat = Vector3.new(vel.X, 0, vel.Z)
						local color = root:GetAttribute("TrailRainbow") and hue(rng:NextNumber()) or Color3.fromHex(root:GetAttribute("TrailColor") or "ffd23c")
						local back = flat.Magnitude > 1 and -flat.Unit or -root.CFrame.LookVector
						local side = back:Cross(Vector3.yAxis)
						local moving = flat.Magnitude > 6
						-- crackling arcs streaming off behind you while you run (a few even when standing)
						if moving or rng:NextNumber() < 0.25 then
							for _ = 1, moving and rng:NextInteger(1, 2) or 1 do
								local from = root.Position + Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(-1, 1.2), rng:NextNumber(-0.8, 0.8))
								bolt(from, from + back * rng:NextNumber(4, 9) + side * rng:NextNumber(-3, 3) + Vector3.new(0, rng:NextNumber(-2.5, 1.5), 0), color)
							end
						end
						-- now and then a bolt strikes the ground behind you
						if moving and rng:NextNumber() < 0.2 then
							local hit = root.Position + back * rng:NextNumber(3, 6)
							bolt(hit + Vector3.new(rng:NextNumber(-1, 1), 7, rng:NextNumber(-1, 1)), hit - Vector3.new(0, 3, 0), color)
						end
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------
-- TOP 10 LEADERBOARD board by the vault entrance: tap MONEY or SPEED to switch
------------------------------------------------------------------
task.spawn(function()
	local HttpService = game:GetService("HttpService")
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local lobby = map and map:WaitForChild("Lobby", 60)
	local lb = lobby and lobby:WaitForChild("Leaderboard", 60)
	local screen = lb and lb:WaitForChild("LeaderboardScreen", 30)
	local data = ReplicatedStorage:WaitForChild("LeaderboardData", 60)
	if not (screen and data) then return end
	local sg = UI.new("SurfaceGui", {
		Name = "LeaderboardGui", Adornee = screen, Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 30, LightInfluence = 0, MaxDistance = 160, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local bg = UI.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sg})
	UI.gradient(bg, Color3.fromRGB(70, 45, 140), Color3.fromRGB(25, 18, 55), 90)
	UI.label({Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.92, 0.11), Text = "\u{1F3C6} TOP 10 \u{1F3C6}", TextColor3 = Color3.fromRGB(255, 215, 80), Outline = 4, Parent = bg})
	local scopeLabel = UI.label({Position = UDim2.fromScale(0.04, 0.13), Size = UDim2.fromScale(0.92, 0.045), Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.fromRGB(200, 195, 240), Outline = 2, Parent = bg})
	local category = "Cash"
	local render
	local tabs = {}
	local function tab(key, text, x, color)
		local b, _, setColor = UI.actionButton({Position = UDim2.fromScale(x, 0.19), Size = UDim2.fromScale(0.42, 0.1), Text = text, Parent = bg, Radius = 16}, color)
		tabs[key] = {SetColor = setColor, Color = color}
		b.Activated:Connect(function()
			if category ~= key then
				category = key
				UI.sfx("toggle")
				render()
			end
		end)
	end
	local rows = {}
	for i = 1, 10 do
		local y = 0.31 + (i - 1) * 0.068
		local row = UI.new("Frame", {Position = UDim2.fromScale(0.04, y), Size = UDim2.fromScale(0.92, 0.06), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = i <= 3 and 0.75 or 0.88, Parent = bg}, {UI.corner(10)})
		local medal = ({"\u{1F947}", "\u{1F948}", "\u{1F949}"})[i] or ("#" .. i)
		UI.label({Position = UDim2.fromScale(0.01, 0.05), Size = UDim2.fromScale(0.13, 0.9), Text = medal, Outline = 2.5, Parent = row})
		local name = UI.label({Position = UDim2.fromScale(0.16, 0.08), Size = UDim2.fromScale(0.5, 0.84), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 2.5, Parent = row})
		local value = UI.label({Position = UDim2.fromScale(0.66, 0.08), Size = UDim2.fromScale(0.32, 0.84), TextXAlignment = Enum.TextXAlignment.Right, Text = "", Outline = 2.5, Parent = row})
		rows[i] = {Name = name, Value = value}
	end
	render = function()
		for key, t in pairs(tabs) do
			t.SetColor(key == category and t.Color or Color3.fromRGB(90, 85, 120))
		end
		local ok, d = pcall(function()
			return HttpService:JSONDecode(data.Value)
		end)
		d = ok and type(d) == "table" and d or {}
		scopeLabel.Text = d.Global == false and "This server only (saving is unavailable)" or "All servers \u{2022} updates every minute"
		local list = d[category] or {}
		for i = 1, 10 do
			local e = list[i]
			rows[i].Name.Text = e and e.Name or "-"
			if e then
				rows[i].Value.Text = category == "Cash" and ("$" .. UI.fmt(e.Value)) or (UI.fmt(e.Value) .. " \u{1F45F}")
				rows[i].Value.TextColor3 = category == "Cash" and Color3.fromRGB(130, 255, 140) or Color3.fromRGB(140, 210, 255)
			else
				rows[i].Value.Text = ""
			end
		end
	end
	tab("Cash", "\u{1F4B5} MONEY", 0.05, Color3.fromRGB(60, 200, 90))
	tab("Speed", "\u{1F45F} SPEED", 0.53, Color3.fromRGB(70, 150, 255))
	render()
	data:GetPropertyChangedSignal("Value"):Connect(render)
end)

------------------------------------------------------------------
-- LUCKY SPIN wheel turns slowly on its own (each player's game, so the server stays quiet)
------------------------------------------------------------------
task.spawn(function()
	local map = workspace:WaitForChild("StealAGameMap", 60)
	local lobby = map and map:WaitForChild("Lobby", 60)
	local spin = lobby and lobby:WaitForChild("LuckySpin", 60)
	local wheel = spin and spin:WaitForChild("SpinWheel", 30)
	if not wheel then return end
	local axis = wheel:GetAttribute("Axis")
	local facing = wheel:GetAttribute("Facing")
	if not (axis and facing) then return end
	local start = {}
	for _, p in ipairs(wheel:GetDescendants()) do
		if p:IsA("BasePart") then
			start[p] = p.CFrame
		end
	end
	local pivot = CFrame.lookAt(axis, axis + facing)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam or (cam.CFrame.Position - axis).Magnitude > 200 then return end
		local turn = pivot * CFrame.Angles(0, 0, os.clock() * 0.35) * pivot:Inverse()
		for p, cf in pairs(start) do
			p.CFrame = turn * cf
		end
	end)
end)

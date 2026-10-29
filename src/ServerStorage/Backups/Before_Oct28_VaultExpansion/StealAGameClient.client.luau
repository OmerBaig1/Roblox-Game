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
-- CASH and SPEED: a dark glass pill each, with a lit icon badge, a small caption over a big number, a chip for a live
-- state (a boost, Slow Down) and a + that opens that part of the shop
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local function statBox(y, icon, caption, color, section)
	local box = UI.new("Frame", {Name = caption .. "Box", Position = UDim2.fromOffset(22, y), Size = UDim2.fromOffset(292, 62), BackgroundColor3 = Color3.new(1, 1, 1), Parent = gui},
		{K.corner(), K.stroke(color:Lerp(Color3.new(1, 1, 1), 0.2), 2, 0.25)})
	UI.new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(46, 34, 82):Lerp(color, 0.12), Color3.fromRGB(20, 14, 38)), Transparency = NumberSequence.new(0.06), Parent = box})
	-- a soft light along the top edge
	UI.new("Frame", {Position = UDim2.fromOffset(30, 3), Size = UDim2.new(1, -60, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = box}, {K.corner()})
	-- the icon badge sits over the left end
	local badge = UI.new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -12, 0.5, 0), Size = UDim2.fromOffset(66, 66), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = box},
		{K.corner(), K.stroke(Color3.new(1, 1, 1), 2.5, 0.35)})
	UI.new("UIGradient", {Rotation = 120, Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color:Lerp(Color3.new(0, 0, 0), 0.3)), Parent = badge})
	UI.new("Frame", {Position = UDim2.fromScale(0.16, 0.08), Size = UDim2.fromScale(0.68, 0.36), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.78, ZIndex = 2, Parent = badge}, {K.corner()})
	local iconScale = UI.new("UIScale", {Parent = badge})
	UI.new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1, Image = icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = badge})
	K.text({Text = caption, FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 12, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.45), Position = UDim2.fromOffset(62, 7), Size = UDim2.fromOffset(120, 14), Parent = box})
	local value = K.text({Text = "", FontFace = K.TITLE, TextSize = 30, Position = UDim2.fromOffset(62, 20), Size = UDim2.fromOffset(150, 36), Parent = box})
	UI.new("UIStroke", {Color = Color3.fromRGB(10, 6, 24), Thickness = 1.5, Transparency = 0.35, Parent = value})
	local valueScale = UI.new("UIScale", {Parent = value})
	-- a small state chip just left of the +
	local chip, chipText = K.chip({Text = "", Style = "solid", Color = color, TextSize = 13, Height = 22, Pad = 8, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0), ZIndex = 3, Parent = box})
	chip.Visible = false
	-- + button that opens that part of the shop (drawn from bars: a "+" glyph sits off-centre in these fonts)
	local plus = UI.new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(42, 42), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, Parent = box},
		{K.corner(), K.stroke(Color3.fromRGB(190, 110, 10), 2, 0.1)})
	UI.gradient(plus, Color3.fromRGB(255, 226, 110), Color3.fromRGB(255, 160, 30), 90)
	for _, bar in ipairs({{20, 6}, {6, 20}}) do
		UI.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(bar[1], bar[2]), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = plus},
			{K.corner(), UI.new("UIStroke", {Color = Color3.fromRGB(170, 90, 0), Thickness = 1, Transparency = 0.3})})
	end
	plus:SetAttribute("Sfx", "tap")
	UI.bounce(plus)
	plus.Activated:Connect(function()
		openShopSection(section)
	end)
	-- a quick, small pulse of the number (and its colour) to acknowledge a change
	local function pulse(tint)
		valueScale.Scale = 1.07
		TweenService:Create(valueScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
		value.TextColor3 = tint
		TweenService:Create(value, TweenInfo.new(0.45), {TextColor3 = Color3.new(1, 1, 1)}):Play()
		iconScale.Scale = 1.08
		TweenService:Create(iconScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end
	local function setChip(text, chipColor)
		chip.Visible = text ~= nil
		if text then
			chipText.Text = text
			chip.BackgroundColor3 = chipColor or color
		end
		-- the number gets the room the chip isn't using
		value.Size = UDim2.fromOffset(text and 118 or 160, 36)
	end
	return {Label = value, Pulse = pulse, SetChip = setChip}
end
-- icons: a gold coin over banknotes, a lightning bolt (drawn for this game)
local cashBox = statBox(68, "rbxassetid://109281737853986", "CASH", Color3.fromRGB(70, 210, 100), "cash")
local speedBox = statBox(144, "rbxassetid://140359567620445", "SPEED", Color3.fromRGB(80, 170, 255), "speed")
local cashLabel, speedLabel = cashBox.Label, speedBox.Label
-- TRAIL BONUS badge beside the speed box while your trail adds speed. TrailSpeed is the very factor the server
-- multiplies your speed by (refreshMultipliers), so the badge can't disagree with your real speed.
local trailBadge = UI.new("Frame", {Name = "TrailBadge", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(322, 144 + 31), Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, Parent = gui},
	{K.corner(), K.stroke(Color3.fromRGB(255, 190, 240), 2, 0.2), UI.new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})})
UI.new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 110, 210), Color3.fromRGB(170, 60, 220)), Parent = trailBadge})
local trailBadgeText = K.text({Text = "", FontFace = K.TITLE, TextSize = 18, Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, Parent = trailBadge})
UI.new("UIStroke", {Color = Color3.fromRGB(70, 20, 90), Thickness = 1.5, Transparency = 0.3, Parent = trailBadgeText})
local trailBadgeScale = UI.new("UIScale", {Parent = trailBadge})
local function refreshTrailBadge()
	local m = player:GetAttribute("TrailSpeed") or 1
	local text = "\u{2728} \u{00D7}" .. string.format("%g", m)
	if m > 1 and (not trailBadge.Visible or trailBadgeText.Text ~= text) then
		trailBadgeScale.Scale = 1.25
		TweenService:Create(trailBadgeScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end
	trailBadgeText.Text = text
	trailBadge.Visible = m > 1
end
player:GetAttributeChangedSignal("TrailSpeed"):Connect(refreshTrailBadge)
refreshTrailBadge()
-- active boosts show under the boxes
local boostLabel = UI.label({Name = "BoostLabel", Position = UDim2.fromOffset(24, 214), Size = UDim2.fromOffset(290, 66), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Outline = 2.5, Parent = gui})

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
-- THE ALARM: rings while any theft from your base is under way. Every theft has its own id from the server and ends
-- with "returned" (got back) or "stolen" (it reached their base), so one ending never silences another.
local alarm = Instance.new("Sound")
alarm.Name = "TheftAlarm"
alarm.SoundId = "rbxassetid://9118781307" -- Pro Sound Effects: sci-fi siren, constant varied alarms
alarm.Looped = true
alarm.Volume = 0.28
alarm.Parent = SoundService
task.spawn(function()
	pcall(function()
		game:GetService("ContentProvider"):PreloadAsync({alarm})
	end)
	if alarm.TimeLength == 0 then
		-- the siren didn't load: a quick double beep from the built-in sounds instead
		alarm.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		alarm.PlaybackSpeed = 1.5
	end
end)
local activeThefts = {} -- theft id -> true
local function refreshAlarm()
	local ringing = next(activeThefts) ~= nil
	if ringing and not alarm.IsPlaying then
		alarm:Play()
	elseif not ringing and alarm.IsPlaying then
		alarm:Stop()
	end
end
remotes:WaitForChild("Alert").OnClientEvent:Connect(function(kind, thief, gameName, id)
	if kind == "returned" then
		if id then
			activeThefts[id] = nil
		end
		refreshAlarm()
		if next(activeThefts) == nil then
			alertToken += 1
			alertBanner.Visible = false
		end
		return
	end
	alertToken += 1
	local my = alertToken
	if kind == "stealing" then
		if id then
			activeThefts[id] = true
			-- a safety net: never ring for ever if an end message is somehow missed
			task.delay(120, function()
				activeThefts[id] = nil
				refreshAlarm()
			end)
		end
		alertText.Text = "\u{1F6A8} " .. string.upper(thief) .. " IS STEALING YOUR GAME! \u{1F6A8}"
		alertSub.Text = "Chase them and SLAP them to get " .. gameName .. " back!"
	else
		if id then
			activeThefts[id] = nil
		end
		alertText.Text = "\u{1F6A8} " .. string.upper(thief) .. " STOLE YOUR GAME! \u{1F6A8}"
		alertSub.Text = gameName .. " is gone. Lock your base to stay safe!"
	end
	refreshAlarm()
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
local lastCash = cash.Value
local function updateCash()
	cashLabel.Text = "$" .. UI.fmt(cash.Value)
	local d = cash.Value - lastCash
	lastCash = cash.Value
	if d < 0 then
		cashBox.Pulse(Color3.fromRGB(255, 170, 190))
	elseif d > 0 and d >= math.max(1000, cash.Value * 0.05) then
		cashBox.Pulse(Color3.fromRGB(150, 255, 170))
	end
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
		speedLabel.TextColor3 = shownSpeed == target and Color3.new(1, 1, 1) or Color3.fromRGB(170, 225, 255)
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
			local pct = string.format("%.1f", (player:GetAttribute("FriendBoost") or 0) * 100):gsub("%.0$", "")
			table.insert(lines, '<font color="#78ff5a">\u{1F465} +' .. pct .. '% cash from ' .. friends .. (friends == 1 and ' friend' or ' friends') .. '</font>')
		end
		boostLabel.Text = table.concat(lines, "\n")
		if gui:GetAttribute("SlowMode") then
			speedBox.SetChip("SLOW", Color3.fromRGB(150, 150, 175))
		elseif su > now then
			speedBox.SetChip("\u{26A1}" .. tostring(player:GetAttribute("BoostSpeed")) .. "x", Color3.fromRGB(120, 220, 255))
		else
			speedBox.SetChip(nil)
		end
		cashBox.SetChip(mu > now and (tostring(player:GetAttribute("BoostMoney")) .. "x") or nil, Color3.fromRGB(255, 214, 80))
		task.wait(0.5)
	end
end)

------------------------------------------------------------------
-- PROMPT PANELS: the treadmill's Run/Stop and Upgrade prompts and each case's Pick up/Place/Swap/Steal and Sell
-- prompts (Style Custom + a Kind attribute, see Base) draw as one small panel per anchor: a row per prompt in a list
-- layout, so they can never land on top of each other. Each kind has its own colour AND its own wording. It hangs beside the
-- runner in screen space (StudsOffset is camera-relative, SizeOffset is in pixels), so it stays clear of the avatar
-- at any zoom. Each row's look comes only from its own prompt: Run/Stop from the run prompt's Running attribute,
-- Upgrade from its Cost/Maxed attributes and your cash. The server still decides every upgrade; a row only shows
-- "upgraded" once your TreadLevel has really gone up.
------------------------------------------------------------------
local panels = {} -- anchor part -> {Gui, List, Rows = {[prompt] = row}}
local ROW_COLORS = {
	run = Color3.fromRGB(70, 175, 255), stop = Color3.fromRGB(255, 95, 95),
	buy = Color3.fromRGB(95, 225, 125), poor = Color3.fromRGB(120, 118, 140), max = Color3.fromRGB(255, 205, 70),
	steal = Color3.fromRGB(255, 125, 50), locked = Color3.fromRGB(120, 118, 140),
	pickup = Color3.fromRGB(165, 125, 255), swap = Color3.fromRGB(165, 125, 255), place = Color3.fromRGB(60, 215, 195),
	sell = Color3.fromRGB(255, 200, 60),
}
-- states where pressing does something (the key fills while held); the rest shake instead
local ROW_ACTIVE = {run = true, stop = true, buy = true, steal = true, pickup = true, swap = true, place = true, sell = true}
local SECOND_ROW = {upgrade = true, sell = true}
local function cashNow()
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
end
-- what a row should say right now: state, title, small line under it (or nil)
local function rowState(prompt)
	local kind = prompt:GetAttribute("Kind")
	if kind == "sell" then
		return "sell", "Sell", "+$" .. UI.fmt(prompt:GetAttribute("SellValue") or 0) .. (prompt:GetAttribute("Installed") and "" or "  (not installed)")
	elseif kind == "case" then
		local name = prompt:GetAttribute("GameName")
		if prompt:GetAttribute("OwnerId") ~= player.UserId then
			if prompt:GetAttribute("Locked") then
				return "locked", "Steal", "Base is locked"
			end
			return "steal", "Steal", name
		end
		-- your own case: what refreshCasePrompt (below) put on the prompt
		if prompt.ActionText == "Swap" then
			return "swap", "Swap", name
		elseif prompt.ActionText == "Pick up" then
			return "pickup", "Pick Up", name
		end
		local held = prompt.ActionText:match("^Place (.+)$")
		return "place", "Place Game", held ~= "game" and held or nil
	end
	if kind == "upgrade" then
		if prompt:GetAttribute("Maxed") then
			return "max", "MAX LEVEL", "Fully upgraded"
		end
		local cost, cash = prompt:GetAttribute("Cost") or 0, cashNow()
		if cash >= cost then
			return "buy", "Upgrade Treadmill", "$" .. UI.fmt(cost)
		end
		return "poor", "Upgrade Treadmill", "Need $" .. UI.fmt(cost - cash) .. " more"
	end
	if prompt:GetAttribute("Running") then
		return "stop", "Stop Running", nil
	end
	return "run", "Run Treadmill", nil
end
local function keyLabel(prompt, inputType)
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return (prompt.GamepadKeyCode.Name:gsub("Button", ""))
	end
	return prompt.KeyboardKeyCode.Name
end

local function paintRow(row)
	local state, title, sub = rowState(row.Prompt)
	local c = ROW_COLORS[state]
	row.Stroke.Color = c
	row.Glow.Color = c
	row.Strip.BackgroundColor3 = c
	-- the key face lights up in the row's colour on the left of a sharp edge, white on the right (see makeRow)
	local lit = c:Lerp(Color3.new(1, 1, 1), 0.15)
	row.Fill.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, lit), ColorSequenceKeypoint.new(0.5, lit),
		ColorSequenceKeypoint.new(0.501, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))})
	row.Title.Text = title
	row.Title.TextColor3 = state == "poor" and Color3.fromRGB(190, 188, 205) or Color3.new(1, 1, 1)
	row.Sub.Visible = sub ~= nil -- (the words' list layout centres the title when there's no second line)
	if sub and not row.Flashing then
		row.Sub.Text = sub
		row.Sub.TextColor3 = state == "poor" and Color3.fromRGB(255, 125, 125) or c
	end
	row.State = state
end

local function tweenScale(row, to, t, style)
	TweenService:Create(row.Scale, TweenInfo.new(t, style or Enum.EasingStyle.Quad), {Scale = to}):Play()
end

local ROW_TEXT_MAX = 190 -- the widest the words may get before a long game name ends in "..."
local function makeRow(panel, prompt, inputType)
	local key = keyLabel(prompt, inputType)
	local wide = #key > 1
	local row = {Prompt = prompt}
	-- Sized by what's in it: the holder and the button grow with AutomaticSize, and inside the button a left-to-right
	-- list lays out the accent strip, the keycap and the words (title over an optional second line), so a short
	-- label makes a short row and the width follows any text change by itself.
	local holder = UI.new("Frame", {Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = SECOND_ROW[prompt:GetAttribute("Kind")] and 2 or 1, Parent = panel.List})
	-- a soft drop shadow (scale-sized, so it follows the button's width without adding to it)
	UI.new("Frame", {Position = UDim2.fromOffset(0, 3), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Parent = holder}, {UI.corner(12)})
	-- the highlight: a thick outline on a frame the button's exact size and shape, drawn outside its rounded edge in the
	-- row's colour, shown on hover and while the key is held (an outline adds nothing to the auto-sized width). The
	-- button itself is not Selectable, so Roblox never draws its square selection box around it (the prompts take
	-- their keys and gamepad buttons directly, not through menu navigation).
	row.Glow = UI.new("UIStroke", {Thickness = 5, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	UI.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder}, {UI.corner(12), row.Glow})
	local btn = UI.new("TextButton", {Text = "", AutoButtonColor = false, Selectable = false, Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.new(1, 1, 1), Parent = holder},
		{UI.corner(12), UI.new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14)}),
		UI.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder})})
	UI.gradient(btn, Color3.fromRGB(40, 37, 62), Color3.fromRGB(22, 20, 36), 90)
	row.Stroke = UI.stroke(ROW_COLORS.run, 2)
	row.Stroke.Parent = btn
	row.Scale = UI.new("UIScale", {Parent = holder})
	row.Strip = UI.new("Frame", {Size = UDim2.fromOffset(4, 30), BorderSizePixel = 0, LayoutOrder = 1, Parent = btn}, {UI.corner(2)})
	-- the key: a white face sitting on a darker base, like a real keycap. Holding it lights the face itself up in the
	-- row's colour, sweeping left to right: a gradient on the face, so it keeps the key's rounded shape exactly (a
	-- separate fill frame was clipped to a square, because ClipsDescendants ignores rounded corners).
	local base = UI.new("Frame", {Size = UDim2.fromOffset(wide and 42 or 30, 31), BackgroundColor3 = Color3.fromRGB(140, 140, 165), LayoutOrder = 2, Parent = btn}, {UI.corner(8)})
	local face = UI.new("Frame", {Size = UDim2.new(1, 0, 1, -4), BackgroundColor3 = Color3.new(1, 1, 1), Parent = base}, {UI.corner(8)})
	row.Fill = UI.new("UIGradient", {Offset = Vector2.new(-0.5, 0), Parent = face}) -- -0.5 all white .. 0.5 all lit
	UI.new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = wide and 13 or 18, TextColor3 = Color3.fromRGB(24, 22, 36), Text = key, ZIndex = 2, Parent = face})
	local words = UI.new("Frame", {Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 3, Parent = btn},
		{UI.new("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder})})
	local cap = Vector2.new(ROW_TEXT_MAX, math.huge)
	row.Title = UI.new("TextLabel", {Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "", LayoutOrder = 1, Parent = words}, {UI.new("UISizeConstraint", {MaxSize = cap})})
	row.Sub = UI.new("TextLabel", {Size = UDim2.fromOffset(0, 15), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "", LayoutOrder = 2, Parent = words}, {UI.new("UISizeConstraint", {MaxSize = cap})})
	row.Holder = holder

	local hovered, holding = false, false
	local function refreshGlow()
		local on = hovered or holding
		TweenService:Create(row.Glow, TweenInfo.new(on and 0.12 or 0.25), {Transparency = on and 0.45 or 1}):Play()
		TweenService:Create(row.Stroke, TweenInfo.new(0.12), {Thickness = on and 2.5 or 2}):Play()
	end
	local holdTween
	local function stopFill()
		if holdTween then
			holdTween:Cancel() -- (left running, it went on filling the key after you let go)
			holdTween = nil
		end
		row.Fill.Offset = Vector2.new(-0.5, 0)
	end
	local function onPress()
		if not ROW_ACTIVE[row.State] then
			-- a quick shake (of the row inside its slot: the list layout owns the slot's position); the server says
			-- no too, and tells you why
			for i, dx in ipairs({-6, 5, -3, 0}) do
				task.delay((i - 1) * 0.05, function()
					btn.Position = UDim2.fromOffset(dx, 0)
				end)
			end
		else
			tweenScale(row, 0.94, 0.06)
			task.delay(0.07, tweenScale, row, 1, 0.18, Enum.EasingStyle.Back)
		end
	end
	row.Conns = {
		prompt.AttributeChanged:Connect(function()
			paintRow(row)
		end),
		prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
			paintRow(row)
		end),
		prompt.PromptButtonHoldBegan:Connect(function()
			stopFill()
			holding = true
			refreshGlow()
			if ROW_ACTIVE[row.State] and prompt.HoldDuration > 0 then
				holdTween = TweenService:Create(row.Fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Offset = Vector2.new(0.5, 0)})
				holdTween:Play()
			end
		end),
		prompt.PromptButtonHoldEnded:Connect(function()
			stopFill()
			holding = false
			refreshGlow()
		end),
		prompt.Triggered:Connect(function()
			stopFill()
			onPress()
		end),
		btn.MouseEnter:Connect(function()
			hovered = true
			refreshGlow()
			tweenScale(row, 1.04, 0.12)
		end),
		btn.MouseLeave:Connect(function()
			hovered = false
			refreshGlow()
			tweenScale(row, 1, 0.12)
		end),
		-- click or tap holds the prompt like its key would
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				prompt:InputHoldBegin()
			end
		end),
		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				prompt:InputHoldEnd()
			end
		end),
	}
	paintRow(row)
	return row
end

local function removeRow(prompt)
	for anchor, panel in pairs(panels) do
		local row = panel.Rows[prompt]
		if row then
			for _, c in ipairs(row.Conns) do
				c:Disconnect()
			end
			row.Holder:Destroy()
			panel.Rows[prompt] = nil
			if next(panel.Rows) == nil then
				panel.Gui:Destroy()
				panels[anchor] = nil
			end
		end
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom or not prompt:GetAttribute("Kind") then return end
	local anchor = prompt.Parent
	if not (anchor and anchor:IsA("BasePart")) then return end
	local panel = panels[anchor]
	if not panel then
		local gui = UI.new("BillboardGui", {Name = "TreadmillPanel", Adornee = anchor, AlwaysOnTop = true, LightInfluence = 0,
			Size = UDim2.fromOffset(300, 104), StudsOffset = Vector3.new(2, 1.5, 0), SizeOffset = Vector2.new(0.55, 0), Parent = player:WaitForChild("PlayerGui")})
		-- rows line up on their left edge (the keycaps in a column) and each is only as wide as it needs to be
		local list = UI.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui},
			{UI.new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Left})})
		panel = {Gui = gui, List = list, Rows = {}}
		panels[anchor] = panel
	end
	if panel.Rows[prompt] then
		paintRow(panel.Rows[prompt]) -- shown again before it was hidden: reuse the row, never a second one
	else
		panel.Rows[prompt] = makeRow(panel, prompt, inputType)
	end
end)
ProximityPromptService.PromptHidden:Connect(removeRow)

local function repaintAll()
	for _, panel in pairs(panels) do
		for _, row in pairs(panel.Rows) do
			paintRow(row)
		end
	end
end
-- your cash changes what the upgrade row can promise; a real level-up gets a short "UPGRADED!"
task.spawn(function()
	player:WaitForChild("leaderstats"):WaitForChild("Cash").Changed:Connect(repaintAll)
end)
local lastTreadLevel = player:GetAttribute("TreadLevel")
player:GetAttributeChangedSignal("TreadLevel"):Connect(function()
	local level = player:GetAttribute("TreadLevel")
	local went = lastTreadLevel and level and level > lastTreadLevel
	lastTreadLevel = level
	if not went then return end
	for _, panel in pairs(panels) do
		for _, row in pairs(panel.Rows) do
			if row.Prompt:GetAttribute("Kind") == "upgrade" then
				row.Flashing = true
				row.Sub.Visible = true
				row.Sub.Text = "UPGRADED!  Lv " .. level
				row.Sub.TextColor3 = ROW_COLORS.buy
				tweenScale(row, 1.08, 0.1)
				task.delay(0.12, tweenScale, row, 1, 0.25, Enum.EasingStyle.Back)
				task.delay(1.3, function()
					row.Flashing = false
					if row.Holder.Parent then
						paintRow(row)
					end
				end)
			end
		end
	end
end)

------------------------------------------------------------------
-- SOUNDS the server asks for (locking, unlocking, slap hits, collecting cash)
------------------------------------------------------------------
remotes:WaitForChild("PlaySound").OnClientEvent:Connect(function(name)
	UI.sfx(name)
end)

------------------------------------------------------------------
-- SLAP: a real swing of the arm, with a whoosh, synced with the hit
------------------------------------------------------------------
-- Character joints can't be tweened any more (C0 is read-only), so the swing is layered on top
-- of the normal animation every frame through each joint's Transform.
-- Poses: {time, shoulder offset, waist offset}: wind up, sweep across in front (the hit), relax.
local SWING_KEYS = {
	{0, CFrame.new(), CFrame.new()},
	{0.08, CFrame.Angles(math.rad(60), 0, math.rad(70)), CFrame.Angles(0, math.rad(25), 0)},
	{0.2, CFrame.Angles(math.rad(85), 0, math.rad(-60)), CFrame.Angles(0, math.rad(-30), 0)},
	{0.42, CFrame.new(), CFrame.new()},
}
local SWING_EASE = {Enum.EasingStyle.Quad, Enum.EasingStyle.Back, Enum.EasingStyle.Sine}
local swinging = {}
local function slapSwing(char, isMe)
	if not char or swinging[char] then return end
	local arm = char:FindFirstChild("RightUpperArm")
	local torso = char:FindFirstChild("Torso")
	local shoulder = arm and arm:FindFirstChild("RightShoulder") or torso and torso:FindFirstChild("Right Shoulder")
	if not shoulder then return end
	local upper = char:FindFirstChild("UpperTorso")
	local waist = upper and upper:FindFirstChild("Waist")
	swinging[char] = true
	if isMe then
		UI.sfx("swing")
	end
	local t0 = os.clock()
	local conn
	conn = RunService.PreSimulation:Connect(function()
		local t = os.clock() - t0
		-- pcall so a missing joint can never leave the swing stuck (which used to mute every slap after the first)
		local ok = pcall(function()
			for i = 1, #SWING_KEYS - 1 do
				local a, b = SWING_KEYS[i], SWING_KEYS[i + 1]
				if t <= b[1] then
					local alpha = TweenService:GetValue((t - a[1]) / (b[1] - a[1]), SWING_EASE[i], Enum.EasingDirection.Out)
					shoulder.Transform *= a[2]:Lerp(b[2], alpha)
					if waist then
						waist.Transform *= a[3]:Lerp(b[3], alpha)
					end
					return
				end
			end
		end)
		if not ok or t > SWING_KEYS[#SWING_KEYS][1] or not shoulder.Parent then
			conn:Disconnect()
			swinging[char] = nil
		end
	end)
end
remotes:WaitForChild("SlapSwing").OnClientEvent:Connect(function(other)
	if other ~= player then
		slapSwing(other.Character, false)
	end
end)
------------------------------------------------------------------
-- CARRYING: anyone holding a game (the server welds it in front of their chest) reaches both arms forward around
-- it. Done on every screen for every carrier, so everyone sees it. The arms replace the walk swing while the legs
-- keep walking; the pose eases in and out so it never snaps.
------------------------------------------------------------------
-- {part, joint, pose} for the R15 rig players use. Measured in a playtest: the palms land just outside the case's
-- side edges, halfway up, at its middle depth.
local CARRY_POSE = {
	{"RightUpperArm", "RightShoulder", CFrame.Angles(math.rad(62), 0, math.rad(20))},
	{"LeftUpperArm", "LeftShoulder", CFrame.Angles(math.rad(62), 0, math.rad(-20))},
	{"RightLowerArm", "RightElbow", CFrame.Angles(math.rad(28), 0, 0)},
	{"LeftLowerArm", "LeftElbow", CFrame.Angles(math.rad(28), 0, 0)},
}
local carryWeight = {} -- character -> 0..1
local carryJoints = {} -- character -> {{joint, pose, isRightArm}}
local function carryJointsOf(char)
	local list = carryJoints[char]
	if list then
		return list
	end
	list = {}
	for _, def in ipairs(CARRY_POSE) do
		local part = char:FindFirstChild(def[1])
		local joint = part and part:FindFirstChild(def[2])
		if joint then
			table.insert(list, {joint, def[3], def[2]:find("Right") ~= nil})
		end
	end
	if #list > 0 then -- a character still loading its parts is asked again next frame
		carryJoints[char] = list
		char.Destroying:Connect(function()
			carryJoints[char] = nil
			carryWeight[char] = nil
		end)
	end
	return list
end
RunService.PreSimulation:Connect(function(dt)
	local cam = workspace.CurrentCamera
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local w = carryWeight[char] or 0
			local goal = (p:GetAttribute("Held") or 0) > 0 and 1 or 0
			w = goal > w and math.min(goal, w + dt / 0.2) or math.max(goal, w - dt / 0.25)
			carryWeight[char] = w > 0 and w or nil
			if w > 0 and (not cam or (cam.CFrame.Position - root.Position).Magnitude < 250) then
				local ease = TweenService:GetValue(w, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				for _, j in ipairs(carryJointsOf(char)) do
					-- a slap swings the right arm out of the carry for a moment
					if j[1].Parent and not (j[3] and swinging[char]) then
						j[1].Transform = j[1].Transform:Lerp(j[2], ease)
					end
				end
			end
		end
	end
end)

local hookedTools = {}
local function watchTool(tool)
	if tool:IsA("Tool") and tool.Name == "Slap" and not hookedTools[tool] then
		hookedTools[tool] = true
		tool.Activated:Connect(function()
			slapSwing(player.Character, true)
		end)
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
-- One line, reused: a new message replaces the last (pressing something again and again never stacks them) and
-- pops in with a quick bounce
local notifToken = 0
local notifScale = UI.new("UIScale", {Parent = notifLabel})
remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, color)
	notifToken += 1
	local myToken = notifToken
	notifLabel.Text = text
	notifLabel.TextColor3 = color or Color3.new(1, 1, 1)
	notifLabel.TextTransparency = 0
	notifLabel.TextStrokeTransparency = 0
	notifLabel.Visible = true
	notifScale.Scale = 0.82
	TweenService:Create(notifScale, TweenInfo.new(0.28, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(2.5, function()
		if notifToken == myToken then
			TweenService:Create(notifLabel, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end)

-- A friend joined (or was already here when you joined): who, and the boost they bring
local RewardFx = require(ReplicatedStorage:WaitForChild("RewardFx"))
local function pctText(k)
	return (string.format("%.1f", k * 100):gsub("%.0$", "")) .. "%"
end
-- Cash your games earned while you were offline (added when you joined), shown when you first step into your base
remotes:WaitForChild("OfflineEarnings").OnClientEvent:Connect(function(amount, rate)
	-- (the server sends this once, and only for $1 or more)
	RewardFx.toast({
		Title = "While you were away",
		Name = "+$" .. UI.fmt(amount),
		NameColor = Color3.fromRGB(130, 255, 150),
		Sub = string.format("Your games earned at %d%% speed offline", math.floor(rate * 100 + 0.5)),
		Image = "rbxassetid://109281737853986", -- the CASH box's coin picture
		Accent = Color3.fromRGB(70, 210, 100),
		Duration = 4.5,
	})
end)

remotes:WaitForChild("FriendJoined").OnClientEvent:Connect(function(info)
	RewardFx.toast({
		Title = info.Here and "Friend in this server" or "Friend joined",
		Name = info.Name,
		UserId = info.UserId,
		Gain = "+" .. pctText(info.Gain),
		GainNote = "FRIEND BOOST",
		Sub = "Cash boost from friends: +" .. pctText(info.Total),
		Accent = Color3.fromRGB(80, 214, 110),
	})
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
-- TREADMILL RUNNING ANIMATION and WIND
-- Both are paced by your treadmill's level (TreadLevel): the run cycle plays up to 2.6x faster and the wind streaks
-- get denser, faster and brighter. The pace rises by the same step every level, so every upgrade runs faster.
-- An upgrade while running eases into the new pace. The wind is two emitters in a box around you, made when you get
-- on and faded out (then removed) when you get off.
------------------------------------------------------------------
local runTrack
local onTreadmill = false
local treadmillStop = remotes:WaitForChild("TreadmillStop")
local TREAD_MAX = ReplicatedStorage:GetAttribute("TreadMaxLevel") or 40

-- 0 at level 0 .. 1 at the max level
local function treadPace()
	return math.clamp(player:GetAttribute("TreadLevel") or 0, 0, TREAD_MAX) / TREAD_MAX
end

local wind -- {Zone, Streaks, Puffs, Conn, Pace, Fade}
local function setWind(w, k, fade)
	-- k: pace 0..1; fade: 0..1 how far it has come in
	-- kept slow enough that the streaks stream past within ~15 studs instead of vanishing off into the distance
	w.Streaks.Rate = (20 + 80 * k) * fade
	w.Streaks.Speed = NumberRange.new(18 + 22 * k, 26 + 34 * k)
	w.Streaks.Size = NumberSequence.new(0.3 + 0.12 * k)
	w.Streaks.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.45 - 0.3 * k), NumberSequenceKeypoint.new(1, 1)})
	w.Puffs.Rate = (3 + 12 * k) * fade
	w.Puffs.Speed = NumberRange.new(10 + 16 * k, 16 + 22 * k)
end

local function stopRunAnim()
	if runTrack then
		runTrack:Stop(0.2)
		runTrack = nil
	end
	if wind then
		local w = wind
		wind = nil
		w.Conn:Disconnect()
		-- no new air; what's already blowing finishes, then it's all removed
		w.Streaks.Rate, w.Puffs.Rate = 0, 0
		task.delay(0.8, w.Zone.Destroy, w.Zone)
	end
end

local function startWind(root)
	-- an invisible box a little wider and taller than you, so streaks pass beside you instead of through you
	local zone = Instance.new("Part")
	zone.Name = "TreadWind"
	zone.Size = Vector3.new(8, 7, 1)
	zone.Transparency = 1
	zone.CanCollide, zone.CanQuery, zone.CanTouch, zone.Massless = false, false, false, true
	zone.CFrame = root.CFrame * CFrame.new(0, 0.5, -1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = zone, root
	weld.Parent = zone
	local function emitter(props)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.EmissionDirection = Enum.NormalId.Back -- the box's back is behind you: the air rushes past from front to back
		e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		e.SpreadAngle = Vector2.new(6, 6)
		e.LightEmission = 0.6
		e.Rate = 0
		for k, v in pairs(props) do
			e[k] = v
		end
		e.Parent = zone
		return e
	end
	-- glowing pale-blue streaks stretched along their flight (plain white vanished against the light floors and walls)
	local streaks = emitter({Orientation = Enum.ParticleOrientation.VelocityParallel, Lifetime = NumberRange.new(0.18, 0.26),
		Squash = NumberSequence.new(-2.5), LightEmission = 1, Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))})
	-- a few faint wisps of air
	local puffs = emitter({Lifetime = NumberRange.new(0.4, 0.6), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(1, 1)}), Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))})
	zone.Parent = root.Parent
	local w = {Zone = zone, Streaks = streaks, Puffs = puffs, Pace = treadPace(), Fade = 0}
	wind = w
	w.Conn = RunService.Heartbeat:Connect(function(dt)
		-- ease toward the pace for your level (an upgrade speeds up over about a second) and fade in on getting on
		local goal = treadPace()
		if math.abs(goal - w.Pace) < 0.002 and w.Fade >= 1 then
			return
		end
		w.Pace += (goal - w.Pace) * (1 - math.exp(-dt * 3))
		w.Fade = math.min(1, w.Fade + dt * 2.5)
		setWind(w, w.Pace, w.Fade)
		if runTrack then
			runTrack:AdjustSpeed(1 + 1.6 * w.Pace)
		end
	end)
	setWind(w, w.Pace, 0)
end

-- The top treadmills' turning parts (TreadModels k.spin): spun here so the server sends nothing per frame.
-- Turned from where each first appeared, by the clock, so every player sees the same angle.
local spinStart = setmetatable({}, {__mode = "k"})
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, m in ipairs(CollectionService:GetTagged("TreadSpin")) do
		local start = spinStart[m]
		if not start then
			start = m:GetPivot()
			spinStart[m] = start
		end
		m:PivotTo(start * CFrame.fromAxisAngle(m:GetAttribute("SpinAxis"), t * m:GetAttribute("SpinSpeed")))
	end
end)

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
		track:AdjustSpeed(1 + 1.6 * treadPace())
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		startWind(root)
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
	-- the HUD's own speed icon, so the gain reads as "this goes into SPEED"
	local shoe = UI.new("ImageLabel", {Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(0, 1), BackgroundTransparency = 1, Image = "rbxassetid://140359567620445", ScaleType = Enum.ScaleType.Fit, Parent = holder})
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
	TweenService:Create(shoe, fade, {ImageTransparency = 1}):Play()
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
		stopRunAnim()
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
	local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
	local OFF = {Color3.fromRGB(92, 84, 140), Color3.fromRGB(44, 38, 78)}
	local ON = {Color3.fromRGB(80, 214, 128), Color3.fromRGB(28, 128, 76)}
	-- the whole pill is the button; it sits on a darker base, so pressing it sinks the face onto the base.
	-- It lives in the left menu column (MenuUI's Menu list), right under the DAILY and GIFT row.
	local holder = UI.new("Frame", {Name = "SlowDown", LayoutOrder = 4, Size = UDim2.fromOffset(232, 60), BackgroundTransparency = 1})
	task.spawn(function()
		holder.Parent = player.PlayerGui:WaitForChild("MenuUI"):WaitForChild("Menu")
	end)
	local pop = UI.new("UIScale", {Parent = holder})
	UI.new("Frame", {Position = UDim2.fromOffset(0, 5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(18, 15, 34), Parent = holder}, {UI.corner(1, true), UI.stroke(BLACK, 3.5)})
	local face = UI.new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, Parent = holder}, {UI.corner(1, true), UI.stroke(BLACK, 3.5)})
	local grad = UI.gradient(face, OFF[1], OFF[2], 90)
	UI.new("Frame", {Position = UDim2.new(0, 24, 0, 4), Size = UDim2.new(1, -48, 0, 3), BackgroundColor3 = WHITE, BackgroundTransparency = 0.62, BorderSizePixel = 0, Parent = face}, {UI.corner(1, true)})
	-- a turtle badge that lights up while it's on
	local badge = UI.new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(34, 30, 60), Parent = face}, {UI.corner(1, true), UI.stroke(BLACK, 2.5)})
	local badgeScale = UI.new("UIScale", {Parent = badge})
	UI.new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "\u{1F422}", TextScaled = true, Parent = badge},
		{UI.new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})
	UI.label({Position = UDim2.fromOffset(62, 7), Size = UDim2.fromOffset(94, 26), TextXAlignment = Enum.TextXAlignment.Left, Text = "Slow Down", Outline = 2.5, Parent = face})
	local status = UI.label({Position = UDim2.fromOffset(62, 34), Size = UDim2.fromOffset(94, 16), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 2, Parent = face})
	local track = UI.new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(58, 32), BackgroundColor3 = Color3.fromRGB(70, 64, 104), Parent = face}, {UI.corner(1, true), UI.stroke(BLACK, 2.5)})
	local knob = UI.new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = WHITE, Parent = track}, {UI.corner(1, true), UI.stroke(BLACK, 2)})

	-- the server's attribute is the truth; the switch follows it, so the two can never disagree
	local on = player:GetAttribute("SlowDown") == true
	local hover, pressed, nextToggle = false, false, 0
	local function paint()
		local c = on and ON or OFF
		local lift = hover and 0.1 or 0
		grad.Color = ColorSequence.new(c[1]:Lerp(WHITE, lift), c[2]:Lerp(WHITE, lift))
	end
	local function render(animate)
		local t = animate and 0.2 or 0
		TweenService:Create(knob, TweenInfo.new(t, Enum.EasingStyle.Back), {Position = on and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
		TweenService:Create(track, TweenInfo.new(t), {BackgroundColor3 = on and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(70, 64, 104)}):Play()
		TweenService:Create(badge, TweenInfo.new(t), {BackgroundColor3 = on and Color3.fromRGB(255, 236, 150) or Color3.fromRGB(34, 30, 60)}):Play()
		status.Text = on and '<font color="#C8FFD6">ON</font>  normal walk' or '<font color="#C8C0EC">OFF</font>  full speed'
		paint()
		gui:SetAttribute("SlowMode", on)
	end
	render(false)
	local function release()
		if pressed then
			pressed = false
			TweenService:Create(face, TweenInfo.new(0.16, Enum.EasingStyle.Back), {Position = UDim2.new()}):Play()
			TweenService:Create(pop, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = hover and 1.03 or 1}):Play()
		end
	end
	face.MouseEnter:Connect(function()
		hover = true
		paint()
		TweenService:Create(pop, TweenInfo.new(0.12), {Scale = 1.03}):Play()
	end)
	face.MouseLeave:Connect(function()
		hover = false
		release()
		paint()
		TweenService:Create(pop, TweenInfo.new(0.12), {Scale = 1}):Play()
	end)
	face.MouseButton1Down:Connect(function()
		pressed = true
		TweenService:Create(face, TweenInfo.new(0.05), {Position = UDim2.fromOffset(0, 4)}):Play()
		TweenService:Create(pop, TweenInfo.new(0.05), {Scale = 0.96}):Play()
	end)
	face.MouseButton1Up:Connect(release)
	face.Activated:Connect(function()
		release()
		-- a quick double tap can't flip it twice before the server answers
		if os.clock() < nextToggle then
			return
		end
		nextToggle = os.clock() + 0.3
		on = not on
		UI.sfx("toggle", on and 0.9 or 1.1)
		render(true)
		badgeScale.Scale = 1.25
		TweenService:Create(badgeScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
		slowEvent:FireServer(on)
	end)
	player:GetAttributeChangedSignal("SlowDown"):Connect(function()
		local v = player:GetAttribute("SlowDown") == true
		if v ~= on then
			on = v
			render(true)
		end
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
		text.Text = '<font color="#ffd23c">\u{1F465} INVITE ' .. name .. ' \u{1F465}</font>\n<font color="#78ff5a">1st Friend +10% Cash</font>' -- the extra-friend line is its own smaller label (World)
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
-- TRAIL BUBBLES (Bubblegum, Ocean, Toxic): little shiny balls that float up, wobble and pop
------------------------------------------------------------------
do
	local folder = Instance.new("Folder")
	folder.Name = "TrailBubbles"
	folder.Parent = workspace
	local free = {}
	local rng = Random.new()
	local function bubble(pos, color)
		local b = table.remove(free)
		if not b then
			b = Instance.new("Part")
			b.Shape = Enum.PartType.Ball
			b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
			b.Material = Enum.Material.SmoothPlastic -- Glass renders these dark; plastic keeps the bubble's colour
			b.Reflectance = 0.15
			b.Parent = folder
		end
		local size = rng:NextNumber(0.35, 0.8)
		b.Size = Vector3.one * size
		b.Color = color
		b.Transparency = 0.25
		b.CFrame = CFrame.new(pos)
		local life = rng:NextNumber(0.9, 1.6)
		local drift = Vector3.new(rng:NextNumber(-1.5, 1.5), rng:NextNumber(2.5, 4.5), rng:NextNumber(-1.5, 1.5))
		TweenService:Create(b, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(pos + drift)}):Play()
		task.delay(life, function()
			-- pop: a quick swell as it vanishes
			TweenService:Create(b, TweenInfo.new(0.12), {Size = Vector3.one * size * 1.6, Transparency = 1}):Play()
			task.delay(0.15, function()
				table.insert(free, b)
			end)
		end)
	end
	task.spawn(function()
		while true do
			task.wait(0.12)
			local cam = workspace.CurrentCamera
			local cp = cam and cam.CFrame.Position
			if cp then
				for _, plr in ipairs(Players:GetPlayers()) do
					local char = plr.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					local hex = root and root:GetAttribute("TrailBubbles")
					if hex and (root.Position - cp).Magnitude < 120 then
						local color = Color3.fromHex(hex)
						local moving = root.AssemblyLinearVelocity.Magnitude > 6
						for _ = 1, moving and rng:NextInteger(1, 2) or (rng:NextNumber() < 0.35 and 1 or 0) do
							bubble(root.Position + Vector3.new(rng:NextNumber(-1.4, 1.4), rng:NextNumber(-1.5, 1), rng:NextNumber(-1.4, 1.4)), color:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.35)))
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


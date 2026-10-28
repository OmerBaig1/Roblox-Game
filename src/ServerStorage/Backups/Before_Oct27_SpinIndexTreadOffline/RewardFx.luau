--[[
	RewardFx: how the game says "you got something". Nothing here takes clicks, so it never blocks the game.
	RewardFx.toast(opts): a card that slides in at the top centre (inside the empty middle of Roblox's top bar),
	holds, then slides away. One at a time; the rest wait in a queue so they never overlap.
	  opts = {Title, Name, Gain, Sub, Accent = Color3, UserId (avatar) or Icon (emoji), Sfx, Duration}
	RewardFx.reward(opts): the big centre-screen reveal for every claimed reward (UI.popup sends here). One shared look,
	an accent for the kind of reward, and more of everything for rarer ones. Queued; shorter when others are waiting.
	Cash and speed rewards skip the reveal and go to RewardFx.collect instead.
	  opts = {Kind = "cash" | "speed" | "boost" | "game" | "spin" | "area" | "daily" | "index", Title, Sub, Icon, Color,
	          Amount, Tier (1 common .. 5 legendary) or Rarity (a game rarity name),
	          Badge (small label over the title), Poster + Reveal/RevealTitle/RevealColor (a mystery game cracks open)}
	RewardFx.collect(kind, amount, tier): coins ("cash") or bolts ("speed") pop out where you claimed and fly into the
	CASH or SPEED box in the top left.
]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local new = UI.new
local WHITE = Color3.new(1, 1, 1)

local Fx = {}

local toastGui
local function layer()
	if toastGui and toastGui.Parent then
		return toastGui
	end
	toastGui = new("ScreenGui", {Name = "ToastUI", ResetOnSpawn = false, DisplayOrder = 30, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui")})
	return toastGui
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- smaller screens get a smaller card (phones), big screens never blow it up
local function screenScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min(vp.X / 1100, vp.Y / 720), 0.62, 1)
end

local toastQueue, toasting = {}, false
local function showToast()
	if toasting or #toastQueue == 0 then
		return
	end
	toasting = true
	local o = table.remove(toastQueue, 1)
	local accent = o.Accent or K.C.Green
	local W, H = 392, 74
	local top = math.max(6, (GuiService:GetGuiInset().Y - H * screenScale()) / 2)
	-- starts above the screen and drops in (a plain Frame: a CanvasGroup would render the text soft and dim)
	local card = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.fromOffset(W, H), BackgroundColor3 = WHITE, ZIndex = 5, Parent = layer()},
		{K.corner(20), new("UIGradient", {Rotation = 90, Color = ColorSequence.new(K.C.Surface:Lerp(accent, 0.18), K.C.PanelLow)}),
			new("UIStroke", {Color = accent:Lerp(WHITE, 0.35), Thickness = 2, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	local scale = new("UIScale", {Scale = screenScale() * 0.86, Parent = card})
	-- a soft light along the top and an accent bar down the left
	new("Frame", {Position = UDim2.fromOffset(18, 3), Size = UDim2.new(1, -36, 0, 2), BackgroundColor3 = WHITE, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 6, Parent = card}, {K.corner()})
	new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 5, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 6, Parent = card})

	-- avatar (or icon) in a ring of the accent colour
	local ring = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = WHITE, ZIndex = 6, Parent = card}, {K.corner()})
	new("UIGradient", {Rotation = 120, Color = ColorSequence.new(accent:Lerp(WHITE, 0.4), accent:Lerp(Color3.new(), 0.25)), Parent = ring})
	local face = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -6, 1, -6), BackgroundColor3 = K.C.Surface2, ZIndex = 7, Parent = ring}, {K.corner()})
	if o.UserId then
		local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8, Parent = face}, {K.corner()})
		task.spawn(function()
			local ok, url = pcall(Players.GetUserThumbnailAsync, Players, o.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if ok and img.Parent then
				img.Image = url
			end
		 end)
	else
		new("TextLabel", {Size = UDim2.fromScale(0.72, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Text = o.Icon or "\u{2B50}", TextScaled = true, ZIndex = 8, Parent = face})
	end

	K.text({Text = string.upper(o.Title or ""), FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 12, TextColor3 = accent:Lerp(WHITE, 0.35), Position = UDim2.fromOffset(80, 12), Size = UDim2.new(1, -190, 0, 14), ZIndex = 6, Parent = card})
	local name = K.text({Text = o.Name or "", FontFace = K.TITLE, TextSize = 24, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(80, 26), Size = UDim2.new(1, -190, 0, 26), ZIndex = 6, Parent = card})
	new("UIStroke", {Color = Color3.fromRGB(10, 6, 24), Thickness = 1.5, Transparency = 0.4, Parent = name})
	K.text({Text = o.Sub or "", TextSize = 13, TextColor3 = K.C.Text2, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(80, 52), Size = UDim2.new(1, -190, 0, 14), ZIndex = 6, Parent = card})

	-- the gain, big, on a pill at the right
	local pill = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(96, 46), BackgroundColor3 = WHITE, ZIndex = 6, Parent = card}, {K.corner(14)})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(accent:Lerp(WHITE, 0.3), accent:Lerp(Color3.new(), 0.2)), Parent = pill})
	local gain = K.text({Text = o.Gain or "", FontFace = K.TITLE, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 26), ZIndex = 7, Parent = pill})
	new("UIStroke", {Color = accent:Lerp(Color3.new(), 0.6), Thickness = 1.5, Transparency = 0.2, Parent = gain})
	K.text({Text = o.GainNote or "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 14), ZIndex = 7, Parent = pill})
	local pillScale = new("UIScale", {Scale = 0.6, Parent = pill})

	-- in: drop down from above the screen with a small scale-up; the gain pops a beat later
	local s = screenScale()
	tween(card, 0.45, {Position = UDim2.new(0.5, 0, 0, top + H * s)})
	tween(scale, 0.5, {Scale = s}, Enum.EasingStyle.Back)
	UI.sfx(o.Sfx or "coin")
	task.delay(0.22, function()
		tween(pillScale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	end)

	task.delay(o.Duration or 3.6, function()
		-- out: shrink a touch and lift back off the top, then the next one comes in
		tween(card, 0.32, {Position = UDim2.new(0.5, 0, 0, -10)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(scale, 0.32, {Scale = s * 0.9}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.34)
		card:Destroy()
		toasting = false
		showToast()
	end)
end

function Fx.toast(opts)
	table.insert(toastQueue, opts)
	showToast()
end

------------------------------------------------------------------
-- REWARD REVEALS
------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GOLD = UI.GOLD

-- how big a reward feels, 1 (common) to 5 (legendary and up)
local TIERS = {
	{Rays = 6, Stars = 8, Hold = 1.9, Sfx = "claim"},
	{Rays = 8, Stars = 12, Hold = 2.2, Sfx = "claim"},
	{Rays = 10, Stars = 18, Hold = 2.5, Sfx = "reward"},
	{Rays = 12, Stars = 24, Hold = 2.9, Sfx = "hatchrare", Flash = 0.8, Confetti = 26},
	{Rays = 16, Stars = 34, Hold = 3.3, Sfx = "hatchlegend", Flash = 0.65, Confetti = 46, Shimmer = true},
}
local rarityTier = {}
task.spawn(function()
	local v = ReplicatedStorage:WaitForChild("RarityData", 30)
	local ok, list = pcall(HttpService.JSONDecode, HttpService, v and v.Value or "[]")
	for i, r in ipairs(ok and list or {}) do
		rarityTier[r.Name] = math.min(i, 5)
	end
end)
local function tierOf(o)
	if o.Tier then
		return math.clamp(o.Tier, 1, 5)
	end
	return o.Rarity and rarityTier[o.Rarity] or 2
end

-- the same pictures as the CASH and SPEED boxes in the corner
local KIND_IMAGE = {cash = "rbxassetid://109281737853986", speed = "rbxassetid://140359567620445"}
local HUD_BOX = {cash = "CASHBox", speed = "SPEEDBox"}

local rewardGui, stage
local function rewardLayer()
	if not (rewardGui and rewardGui.Parent) then
		rewardGui = new("ScreenGui", {Name = "RewardUI", ResetOnSpawn = false, DisplayOrder = 25, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui")})
		stage = K.stage(rewardGui, 1280, 720)
	end
	return rewardGui, stage
end

------------------------------------------------------------------
-- CASH AND SPEED: no big reveal. The icons pop out where you claimed and fly into your CASH or SPEED box, all one
-- motion: each rides a curve that bulges outward first (the burst), eased in-out so the pop flows straight into the
-- flight, and shrinks and fades as it lands. One RenderStepped moves every icon, and the box is looked up every frame,
-- so they land on it wherever it is on any screen. Claims close together queue a beat apart instead of piling up.
------------------------------------------------------------------
-- where you last clicked or tapped (InputObject positions leave out the top bar; this layer covers it)
local lastPress, lastPressAt = nil, -10
UserInputService.InputBegan:Connect(function(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
		lastPress, lastPressAt = Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset(), os.clock()
	end
end)

local FLY_TIME, POP = 0.95, 0.2 -- seconds per icon; the share of it spent popping in
local flyers = {} -- icons in flight: {Img, Glow, Kind, Start, From, Out, To, Size, Spin}
local flyConn
local nextLaunch, lastLand = 0, {}
local amountLabels = 0 -- "+$..." labels still showing; each new one starts above the last so they never overlap

local function smooth01(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
local function backOut(x) -- overshoots to ~1.1 then settles at 1
	local c = 1.70158
	return 1 + (c + 1) * (x - 1) ^ 3 + c * (x - 1) ^ 2
end
local function inOutCubic(x)
	return x < 0.5 and 4 * x ^ 3 or 1 - (-2 * x + 2) ^ 3 / 2
end

-- the middle of the CASH or SPEED box's round icon, where it is right now
local function hudTarget(kind)
	local hud = Players.LocalPlayer.PlayerGui:FindFirstChild("StealAGameUI")
	local box = hud and hud:FindFirstChild(HUD_BOX[kind])
	return box and box.AbsolutePosition + Vector2.new(21, box.AbsoluteSize.Y / 2)
end

-- an icon reaching the box: a ring ripples off it (at most a few a second, so a stream reads as one hit) and a chime
local function land(kind, at, n)
	local now = os.clock()
	if now - (lastLand[kind] or 0) > 0.08 then
		UI.sfx(kind == "cash" and "coin" or "pop", 1 + math.min(n, 10) * 0.04)
	end
	if now - (lastLand[kind] or 0) < 0.22 then
		return
	end
	lastLand[kind] = now
	local color = kind == "cash" and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(150, 210, 255)
	local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(at.X, at.Y), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, ZIndex = 59, Parent = rewardLayer()},
		{UI.corner(1, true), new("UIStroke", {Color = color, Thickness = 4, Transparency = 0.1})})
	tween(ring, 0.4, {Size = UDim2.fromOffset(104, 104)}, Enum.EasingStyle.Quad)
	tween(ring:FindFirstChildOfClass("UIStroke"), 0.4, {Transparency = 1, Thickness = 1}, Enum.EasingStyle.Quad)
	task.delay(0.42, ring.Destroy, ring)
end

local function stepFlyers()
	local now = os.clock()
	for i = #flyers, 1, -1 do
		local f = flyers[i]
		local t = (now - f.Start) / FLY_TIME
		if t >= 1 or not f.Img.Parent then
			f.Img:Destroy()
			table.remove(flyers, i)
			land(f.Kind, f.To, f.N)
		elseif t >= 0 then
			f.To = hudTarget(f.Kind) or f.To
			local e = inOutCubic(t)
			-- cubic curve: out from the claim, then swinging in to the box from just below and right of it
			local u = 1 - e
			local pos = f.From * (u * u * u) + f.Out * (3 * u * u * e) + (f.To + Vector2.new(90, 70)) * (3 * u * e * e) + f.To * (e * e * e)
			local s = t < POP and backOut(t / POP) or 1 - 0.6 * smooth01((t - 0.72) / 0.28)
			local fade = smooth01((t - 0.82) / 0.18)
			f.Img.Visible = true
			f.Img.Position = UDim2.fromOffset(pos.X, pos.Y)
			f.Img.Size = UDim2.fromOffset(f.Size * s, f.Size * s)
			f.Img.Rotation = f.Spin * u
			f.Img.ImageTransparency = fade * 0.6
			f.Glow.BackgroundTransparency = 0.8 + 0.2 * math.max(fade, 1 - smooth01(t / POP))
		end
	end
	if #flyers == 0 then
		flyConn:Disconnect()
		flyConn = nil
	end
end

function Fx.collect(kind, amount, tier)
	local root = rewardLayer()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	-- start at the button you pressed to claim (a server reward arrives a moment after the click)
	local from = (lastPress and os.clock() - lastPressAt < 3) and lastPress or Vector2.new(vp.X * 0.5, vp.Y * 0.45)
	local ss = screenScale()
	-- more icons for bigger rewards, fewer while lots are already flying
	local count = math.clamp(4 + (tier or 2), 5, 9)
	if #flyers > 30 then
		count = 2
	end
	local start = math.max(os.clock(), nextLaunch)
	nextLaunch = start + 0.16
	local color = kind == "cash" and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(120, 200, 255)
	for i = 1, count do
		local ang = (i / count + math.random() * 0.15) * math.pi * 2
		local reach = math.random(110, 190) * ss
		local img = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.new(), BackgroundTransparency = 1, Image = KIND_IMAGE[kind],
			ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 61, Parent = root})
		-- a soft glow behind each one
		local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.5), BackgroundColor3 = color, BackgroundTransparency = 1, ZIndex = 60, Parent = img}, {UI.corner(1, true)})
		table.insert(flyers, {Img = img, Glow = glow, Kind = kind, N = i, Start = start + (i - 1) * 0.045, From = from,
			Out = from + Vector2.new(math.cos(ang), math.sin(ang)) * reach, To = hudTarget(kind) or from, Size = math.random(40, 50) * ss, Spin = math.random(-40, 40)})
	end
	flyConn = flyConn or RunService.RenderStepped:Connect(stepFlyers)
	-- how much you got, small, rising from where you claimed
	if amount then
		task.delay(start - os.clock(), function()
			local text = kind == "cash" and "+$" .. UI.fmt(amount) or "+" .. UI.fmt(amount) .. " speed"
			local y = from.Y - 10 - math.min(amountLabels, 4) * 34 * ss
			amountLabels += 1
			task.delay(1.15, function()
				amountLabels -= 1
			end)
			local lbl = K.text({Text = text, FontFace = K.TITLE, TextSize = math.floor(30 * ss), TextColor3 = color:Lerp(WHITE, 0.4), TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(from.X, y), Size = UDim2.fromOffset(300, 40), ZIndex = 62, Parent = root})
			local stroke = new("UIStroke", {Color = Color3.fromRGB(10, 6, 24), Thickness = 2, Parent = lbl})
			local sc = new("UIScale", {Scale = 0.5, Parent = lbl})
			tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
			tween(lbl, 1.1, {Position = UDim2.fromOffset(from.X, y - 50)}, Enum.EasingStyle.Quad)
			local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.7)
			TweenService:Create(lbl, fade, {TextTransparency = 1}):Play()
			TweenService:Create(stroke, fade, {Transparency = 1}):Play()
			task.delay(1.15, lbl.Destroy, lbl)
		end)
	end
end

-- stars flying out of a point
local function starBurst(parent, at, color, count, reach)
	for _ = 1, count do
		local s = math.random(18, 30)
		local star = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = at, Size = UDim2.fromOffset(s, s), Text = "\u{2726}", TextColor3 = math.random() < 0.5 and WHITE or color:Lerp(WHITE, 0.3), Outline = false, ZIndex = 55, Parent = parent})
		local ang = math.random() * math.pi * 2
		local d = math.random(math.floor(reach * 0.5), math.floor(reach))
		tween(star, math.random(60, 95) / 100, {Position = at + UDim2.fromOffset(math.cos(ang) * d, math.sin(ang) * d), Rotation = math.random(-180, 180), TextTransparency = 1}, Enum.EasingStyle.Quad)
		task.delay(1, star.Destroy, star)
	end
end

-- paper confetti drifting down the whole screen (big rewards only)
local function confetti(parent, color, count)
	local palette = {color, color:Lerp(WHITE, 0.5), GOLD, WHITE, Color3.fromRGB(255, 110, 180), Color3.fromRGB(90, 200, 255)}
	for _ = 1, count do
		local x = math.random()
		local p = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, -0.05, -math.random(0, 160)), Size = UDim2.fromOffset(math.random(8, 12), math.random(14, 20)), Rotation = math.random(0, 180),
			BackgroundColor3 = palette[math.random(#palette)], BorderSizePixel = 0, ZIndex = 45, Parent = parent})
		local t = math.random(180, 260) / 100
		tween(p, t, {Position = UDim2.new(x + (math.random() - 0.5) * 0.2, 0, 1.08, 0), Rotation = p.Rotation + math.random(-540, 540)}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		task.delay(t, p.Destroy, p)
	end
end

local rewardQueue, revealing = {}, false
local function showReward()
	if revealing or #rewardQueue == 0 then
		return
	end
	revealing = true
	local o = table.remove(rewardQueue, 1)
	local root, st = rewardLayer()
	local tier = tierOf(o)
	local T = TIERS[tier]
	local kind = o.Kind or "reward"
	local color = o.Color or GOLD
	-- when more are waiting, each one is quicker
	local hold = #rewardQueue > 0 and math.max(1.3, T.Hold * 0.6) or (o.Duration and math.max(o.Duration, T.Hold) or T.Hold)

	local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(820, 400), BackgroundTransparency = 1, ZIndex = 50, Parent = st})
	local scale = new("UIScale", {Scale = 0.25, Parent = holder})
	local MID = UDim2.fromScale(0.5, 0.36)
	-- a soft glow and turning rays behind the picture; rarer rewards get more rays and a second, counter-turning set
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(250, 250), BackgroundColor3 = color:Lerp(WHITE, 0.45), BackgroundTransparency = 0.55, ZIndex = 50, Parent = holder}, {UI.corner(1, true)})
	local bursts = {}
	for layer = 1, T.Shimmer and 2 or 1 do
		local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(330 + tier * 40 - layer * 60, 330 + tier * 40 - layer * 60), BackgroundTransparency = 1, Rotation = layer * 11, ZIndex = 50, Parent = holder})
		for i = 0, T.Rays - 1 do
			local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, layer == 1 and 30 or 16, 1, 0), Rotation = i * 180 / T.Rays, BackgroundColor3 = color:Lerp(WHITE, layer == 1 and 0.55 or 0.8), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 50, Parent = b}, {UI.corner(1, true)})
			new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
		end
		bursts[layer] = b
	end
	local spinSpeed = 40 + tier * 6
	local turnConn = RunService.RenderStepped:Connect(function(dt)
		for i, b in ipairs(bursts) do
			b.Rotation += dt * spinSpeed * (i == 1 and 1 or -0.7)
		end
	end)

	-- the picture: the reward's emoji
	local icon = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(150, 150), Text = o.Icon or "\u{1F381}", Outline = false, ZIndex = 52, Parent = holder})
	local iconScale = new("UIScale", {Parent = icon})
	local ph, phScale
	if o.Poster then
		-- sits a little higher than the icon so the enlarged cover clears the badge under it
		ph = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID - UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(128, 160), BackgroundTransparency = 1, ZIndex = 52, Parent = holder}, {UI.corner(12), UI.stroke(UI.BLACK, 5)})
		phScale = new("UIScale", {Scale = o.Reveal and 0 or 1, Parent = ph})
		o.Poster.Parent = ph
		icon.Visible = o.Reveal == true
	end

	-- the words: a small badge (rarity, LUCKY SPIN...), the title, and what you got
	local badgeText = o.Badge or (tier >= 3 and o.Rarity and string.upper(o.Rarity)) or nil
	local badge
	if badgeText then
		badge = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.63), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = color, ZIndex = 53, Parent = holder},
			{K.corner(), new("UIStroke", {Color = WHITE, Thickness = 2, Transparency = 0.2}), new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})})
		local bt = K.text({Text = badgeText, FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 16, Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 54, Parent = badge})
		new("UIStroke", {Color = color:Lerp(UI.BLACK, 0.6), Thickness = 1.5, Parent = bt})
	end
	local title = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.645), Size = UDim2.new(1, 0, 0, 80), Text = o.Title or "", Outline = 5, ZIndex = 53, Parent = holder})
	local titleGrad = UI.gradient(title, color:Lerp(WHITE, 0.55), color, 90)
	local sub = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.new(1, 0, 0, 44), Text = o.Reveal and "" or (o.Sub or ""), Outline = 3.5, ZIndex = 53, Parent = holder})

	-- in: everything pops up together
	tween(scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
	UI.sfx(o.Reveal and "pop" or T.Sfx)
	if T.Flash then
		local flash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = color:Lerp(WHITE, 0.7), BackgroundTransparency = T.Flash, BorderSizePixel = 0, ZIndex = 40, Parent = root})
		tween(flash, 0.6, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
		task.delay(0.65, flash.Destroy, flash)
	end
	if T.Confetti then
		confetti(root, color, T.Confetti)
	end

	-- the accent for this kind of reward
	local extra = 0
	if o.Reveal and ph then
		-- MYSTERY GAME: the ? shakes harder and harder, a white flash, then the game pops out
		extra = 1.4
		task.spawn(function()
			task.wait(0.45)
			for k = 1, 8 do
				local a = (k % 2 == 0 and 1 or -1) * (6 + k * 2)
				tween(icon, 0.07, {Rotation = a, Size = UDim2.fromOffset(150 + k * 6, 150 + k * 6)}, Enum.EasingStyle.Quad)
				spinSpeed += 8
				task.wait(0.08)
			end
			local flash = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(60, 60), BackgroundColor3 = WHITE, ZIndex = 54, Parent = holder}, {UI.corner(1, true)})
			tween(flash, 0.45, {Size = UDim2.fromOffset(520, 520), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
			task.delay(0.5, flash.Destroy, flash)
			-- no tilt: a rotated frame stops clipping, and the cover art would spill out of it
			icon.Visible = false
			tween(phScale, 0.5, {Scale = 1.15}, Enum.EasingStyle.Back)
			UI.sfx(T.Sfx)
			local rc = o.RevealColor or color
			title.Text = o.RevealTitle or title.Text
			titleGrad.Color = ColorSequence.new(rc:Lerp(WHITE, 0.55), rc)
			sub.Text = o.Sub or ""
			for _, b in ipairs(bursts) do
				for _, ray in ipairs(b:GetChildren()) do
					ray.BackgroundColor3 = rc:Lerp(WHITE, 0.5)
				end
			end
			glow.BackgroundColor3 = rc:Lerp(WHITE, 0.4)
			starBurst(holder, MID, rc, T.Stars, 260)
			task.wait(0.5)
			tween(phScale, 0.25, {Scale = 1.05}, Enum.EasingStyle.Sine)
		end)
	else
		if ph then
			-- a game you can see straight away: it pops in
			phScale.Scale = 0.4
			tween(phScale, 0.5, {Scale = 1.05}, Enum.EasingStyle.Back)
		end
		if kind == "boost" then
			-- two rings pulse out like a power-up switching on
			for k = 0, 1 do
				task.delay(0.15 + k * 0.3, function()
					local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(120, 120), BackgroundTransparency = 1, ZIndex = 51, Parent = holder},
						{UI.corner(1, true), new("UIStroke", {Color = color:Lerp(WHITE, 0.3), Thickness = 8})})
					tween(ring, 0.6, {Size = UDim2.fromOffset(420, 420)}, Enum.EasingStyle.Quad)
					tween(ring:FindFirstChildOfClass("UIStroke"), 0.6, {Transparency = 1, Thickness = 1}, Enum.EasingStyle.Quad)
					task.delay(0.65, ring.Destroy, ring)
				end)
			end
			UI.sfx("unlock")
		elseif kind == "spin" then
			-- flung off the wheel: the prize spins in, and the wheel's colours burst out around it
			icon.Rotation = -360
			iconScale.Scale = 0.2
			tween(icon, 0.6, {Rotation = 0}, Enum.EasingStyle.Quint)
			tween(iconScale, 0.6, {Scale = 1}, Enum.EasingStyle.Back)
			local wheel = o.WheelColors or {color}
			for k = 1, 16 do
				local ang = k / 16 * math.pi * 2
				local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(22, 22), BackgroundColor3 = wheel[(k - 1) % #wheel + 1], ZIndex = 51, Parent = holder}, {UI.corner(1, true), new("UIStroke", {Color = WHITE, Thickness = 2})})
				tween(dot, 0.7, {Position = MID + UDim2.fromOffset(math.cos(ang) * 230, math.sin(ang) * 230), Size = UDim2.fromOffset(8, 8)}, Enum.EasingStyle.Quint)
				task.delay(0.75, dot.Destroy, dot)
			end
		else
			-- daily, area, index...: a happy little wobble
			icon.Rotation = -14
			tween(icon, 0.5, {Rotation = 0}, Enum.EasingStyle.Elastic)
		end
		starBurst(holder, MID, color, T.Stars, 200 + tier * 25)
		if tier >= 5 then
			task.delay(0.4, UI.sfx, "sparkle")
		end
	end

	-- out: shrink away, then the next one
	task.delay(hold + extra, function()
		tween(scale, 0.3, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.32)
		turnConn:Disconnect()
		holder:Destroy()
		revealing = false
		showReward()
	end)
end

function Fx.reward(opts)
	if (opts.Kind == "cash" or opts.Kind == "speed") and not opts.Poster then
		Fx.collect(opts.Kind, opts.Amount, opts.Tier)
		return
	end
	table.insert(rewardQueue, opts)
	showReward()
end

return Fx

--[[
	RewardFx: how the game says "you got something". Nothing here takes clicks, so it never blocks the game.
	RewardFx.toast(opts): a card that slides in at the top centre (inside the empty middle of Roblox's top bar),
	holds, then slides away. One at a time; the rest wait in a queue so they never overlap.
	  opts = {Title, Name, Gain, Sub, Accent = Color3, UserId (avatar) or Icon (emoji), Sfx, Duration}
	RewardFx.reward(opts): the big centre-screen reveal for every claimed reward (UI.popup sends here). One shared look,
	an accent for the kind of reward, and more of everything for rarer ones. Queued; shorter when others are waiting.
	  opts = {Kind = "cash" | "speed" | "boost" | "game" | "spin" | "area" | "daily" | "index", Title, Sub, Icon, Color,
	          Amount (cash/speed count up to it), Tier (1 common .. 5 legendary) or Rarity (a game rarity name),
	          Badge (small label over the title), Poster + Reveal/RevealTitle/RevealColor (a mystery game cracks open)}
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

local function centreOf(obj)
	return obj.AbsolutePosition + obj.AbsoluteSize / 2
end

-- a number that runs up to its value (cash and speed amounts)
local function countUp(lbl, prefix, amount, suffix, time)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / time)
		lbl.Text = prefix .. UI.fmt(amount * (1 - (1 - k) ^ 3)) .. suffix
		if k >= 1 or not lbl.Parent then
			conn:Disconnect()
		end
	end)
end

-- little pictures that burst out of the reward and fly into your CASH or SPEED box, each landing with a coin chime
local function flyToHud(root, from, kind, count)
	local hud = Players.LocalPlayer.PlayerGui:FindFirstChild("StealAGameUI")
	local box = hud and hud:FindFirstChild(HUD_BOX[kind])
	if not box then
		return
	end
	local target = box.AbsolutePosition + Vector2.new(21, box.AbsoluteSize.Y / 2)
	for i = 1, count do
		local ang = math.random() * math.pi * 2
		local out = from + Vector2.new(math.cos(ang), math.sin(ang)) * math.random(70, 150)
		local f = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.fromOffset(46, 46), BackgroundTransparency = 1, Image = KIND_IMAGE[kind], Rotation = math.random(-30, 30), ZIndex = 60, Parent = root})
		tween(f, 0.3, {Position = UDim2.fromOffset(out.X, out.Y)}, Enum.EasingStyle.Quad)
		task.delay(0.3 + i * 0.06, function()
			local tw = tween(f, 0.42, {Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(26, 26), Rotation = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tw.Completed:Once(function()
				f:Destroy()
				UI.sfx("coin", 1 + i * 0.04)
			end)
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

	-- the picture: the cash/speed artwork, or the reward's emoji
	local icon
	if KIND_IMAGE[kind] then
		icon = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, Image = KIND_IMAGE[kind], ScaleType = Enum.ScaleType.Fit, ZIndex = 52, Parent = holder})
	else
		icon = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(150, 150), Text = o.Icon or "\u{1F381}", Outline = false, ZIndex = 52, Parent = holder})
	end
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
		if kind == "cash" then
			-- the coins drop in with a bounce, money sprays out and flies into your CASH box while the number runs up
			icon.Position = MID - UDim2.fromOffset(0, 80)
			tween(icon, 0.55, {Position = MID}, Enum.EasingStyle.Bounce)
			if o.Amount then
				countUp(sub, "+$", o.Amount, "", 0.9)
			end
			task.delay(0.45, function()
				if icon.Parent then
					flyToHud(root, centreOf(icon), "cash", 4 + tier * 2)
				end
			end)
		elseif kind == "speed" then
			-- it rushes in from the left trailing streaks, with a whoosh and a quick burst of light
			icon.Position = MID - UDim2.fromOffset(300, 0)
			tween(icon, 0.28, {Position = MID}, Enum.EasingStyle.Quint)
			UI.sfx("swing", 0.9)
			for k = 1, 6 do
				local y = (k - 3.5) * 22
				local streak = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = MID + UDim2.fromOffset(-60, y), Size = UDim2.fromOffset(0, k % 2 == 0 and 6 or 4), BackgroundColor3 = k % 2 == 0 and WHITE or color:Lerp(WHITE, 0.3), BorderSizePixel = 0, ZIndex = 51, Parent = holder}, {UI.corner(1, true)})
				tween(streak, 0.22, {Size = UDim2.fromOffset(260 + k * 20, streak.Size.Y.Offset)}, Enum.EasingStyle.Quad)
				task.delay(0.22, function()
					tween(streak, 0.4, {Size = UDim2.fromOffset(0, streak.Size.Y.Offset), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
				end)
			end
			local flash = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = MID, Size = UDim2.fromOffset(40, 40), BackgroundColor3 = color:Lerp(WHITE, 0.6), ZIndex = 51, Parent = holder}, {UI.corner(1, true)})
			tween(flash, 0.4, {Size = UDim2.fromOffset(360, 360), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
			task.delay(0.45, flash.Destroy, flash)
			if o.Amount then
				countUp(sub, "+", o.Amount, " speed", 0.8)
			end
			task.delay(0.35, function()
				if icon.Parent then
					flyToHud(root, centreOf(icon), "speed", 3 + tier)
				end
			end)
		elseif kind == "boost" then
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
	table.insert(rewardQueue, opts)
	showReward()
end

return Fx

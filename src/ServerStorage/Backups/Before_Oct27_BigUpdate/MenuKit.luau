--[[
	MenuKit: the look shared by the premium menus (Pet Hatchery, My Pets, Shop, Index).
	Layouts are drawn at a fixed design size and fitted to the screen by one UIScale, so spacing stays exact on every
	device, and windows keep clear of the HUD. Thin light borders instead of black outlines, Builder Sans for text,
	Fredoka for titles, one accent colour per menu. Icons (chevrons, the close X) are drawn from bars around their own
	centre, never font glyphs, so they sit dead centre.
]]
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("UIKit"))
local new = UI.new

local K = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
K.WHITE, K.BLACK = WHITE, BLACK
K.C = {
	Panel = rgb(38, 31, 68), PanelLow = rgb(20, 16, 38), Surface = rgb(46, 38, 82), Surface2 = rgb(57, 48, 98), SurfaceHi = rgb(74, 63, 124),
	Text = WHITE, Text2 = rgb(200, 192, 236), Muted = rgb(146, 138, 190), Gold = rgb(255, 212, 92),
	Green = rgb(62, 204, 112), Violet = rgb(140, 92, 250), Red = rgb(255, 104, 120), Disabled = rgb(78, 72, 108),
}
K.TITLE = Font.new("rbxasset://fonts/families/FredokaOne.json")
function K.font(weight)
	return Font.new("rbxasset://fonts/families/BuilderSans.json", weight or Enum.FontWeight.Bold)
end

function K.tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
function K.corner(px)
	return new("UICorner", {CornerRadius = px and UDim.new(0, px) or UDim.new(1, 0)})
end
function K.stroke(color, thickness, transparency)
	return new("UIStroke", {Color = color or WHITE, Thickness = thickness or 1.5, Transparency = transparency or 0.85, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

-- crisp text at a fixed size (the window's UIScale does the fitting)
function K.text(props)
	local d = {BackgroundTransparency = 1, FontFace = K.font(), TextSize = 16, TextColor3 = WHITE, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center}
	for k, v in pairs(props) do
		d[k] = v
	end
	return new("TextLabel", d)
end

-- an icon drawn from rounded bars, centred on its own bounding box: "left", "right", "close" or "check"
function K.icon(parent, kind, size, color, z)
	local holder = new("Frame", {Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z, Parent = parent})
	local t = math.max(2, math.floor(size * 0.17 + 0.5))
	local bars = {}
	local function bar(cx, cy, len, rot)
		local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, cx, 0.5, cy), Size = UDim2.fromOffset(len, t), Rotation = rot, BackgroundColor3 = color or WHITE, BorderSizePixel = 0, ZIndex = z, Parent = holder}, {K.corner()})
		table.insert(bars, b)
	end
	if kind == "close" then
		bar(0, 0, size, 45)
		bar(0, 0, size, -45)
	elseif kind == "check" then
		-- a short arm down-right into a long arm up-right, centred on the whole tick
		local s1, s2 = size * 0.36, size * 0.72
		bar(-size * 0.22, size * 0.12, s1 + t * 0.5, 45)
		bar(size * 0.1, -size * 0.04, s2, -50)
	else
		-- arms of length L meet at the vertex; the vertex and arm ends are symmetric about the centre
		local a = size * 0.36
		local len = a * math.sqrt(2) + t
		local s = kind == "left" and 1 or -1
		bar(0, -a / 2, len, -45 * s)
		bar(0, a / 2, len, 45 * s)
	end
	return holder, bars
end

-- a pressable button: a face over a darker base, so it sinks when pressed. Kind = primary | secondary | ghost | danger
local KINDS = {primary = K.C.Green, secondary = K.C.Violet, ghost = K.C.Surface2, danger = K.C.Red}
function K.button(props)
	local z = props.ZIndex or 2
	local radius = props.Radius or 14
	local holder = new("Frame", {Name = props.Name or "Button", Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, BackgroundTransparency = 1, ZIndex = z, Parent = props.Parent})
	local base = new("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 4), BorderSizePixel = 0, ZIndex = z, Parent = holder}, {K.corner(radius)})
	local face = new("TextButton", {Size = UDim2.fromScale(1, 1), AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = z + 1, Parent = holder}, {K.corner(radius)})
	local grad = new("UIGradient", {Rotation = 90, Parent = face})
	-- a thin light along the top edge instead of an outline: it reads as a rounded, lit surface
	new("Frame", {Position = UDim2.fromOffset(radius * 0.6, 2), Size = UDim2.new(1, -radius * 1.2, 0, 2), BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = z + 2, Parent = face}, {K.corner()})
	local pop = new("UIScale", {Parent = holder})
	local two = props.Sub ~= nil
	local main = K.text({Text = props.Text or "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = props.TextSize or 22, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 8, 0, two and 7 or 0), Size = UDim2.new(1, -16, two and 0.55 or 1, two and -7 or 0), ZIndex = z + 2, Parent = face})
	local sub = two and K.text({Text = props.Sub, FontFace = K.font(Enum.FontWeight.Bold), TextSize = props.SubSize or 16, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.12,
		Position = UDim2.new(0, 8, 0.55, -3), Size = UDim2.new(1, -16, 0.45, -4), ZIndex = z + 2, Parent = face}) or nil
	local st = {Kind = props.Kind or "primary", Enabled = true, Hover = false, Busy = false}
	local function paint()
		local c = (st.Enabled and not st.Busy) and KINDS[st.Kind] or K.C.Disabled
		if st.Hover and st.Enabled then
			c = c:Lerp(WHITE, 0.12)
		end
		grad.Color = ColorSequence.new(c:Lerp(WHITE, 0.16), c:Lerp(BLACK, 0.1))
		base.BackgroundColor3 = c:Lerp(BLACK, 0.5)
		main.TextTransparency = st.Enabled and 0 or 0.3
	end
	paint()
	-- pressed: the face sinks onto its base and the button squeezes a touch; released: it springs back.
	-- One tween per property, so rapid clicks just retarget it and nothing can get stuck half-pressed.
	local pressed = false
	local function up()
		if pressed then
			pressed = false
			K.tween(face, 0.12, {Position = UDim2.new()}, Enum.EasingStyle.Back)
			K.tween(pop, 0.18, {Scale = 1}, Enum.EasingStyle.Back)
		end
	end
	face.MouseEnter:Connect(function()
		st.Hover = true
		paint()
	end)
	face.MouseLeave:Connect(function()
		st.Hover = false
		up()
		paint()
	end)
	face.MouseButton1Down:Connect(function()
		if st.Enabled and not st.Busy then
			pressed = true
			K.tween(face, 0.05, {Position = UDim2.fromOffset(0, 3)})
			K.tween(pop, 0.05, {Scale = 0.97})
		end
	end)
	face.MouseButton1Up:Connect(up)
	local api = {Holder = holder, Face = face, Main = main, Sub = sub}
	function api.setEnabled(on)
		st.Enabled = on
		paint()
	end
	function api.isEnabled()
		return st.Enabled
	end
	function api.setBusy(on)
		st.Busy = on
		paint()
	end
	function api.setKind(kind)
		st.Kind = kind
		paint()
	end
	function api.setText(text, subText, subColor)
		main.Text = text
		if sub and subText then
			sub.Text = subText
			sub.TextColor3 = subColor or WHITE
		end
	end
	-- a quick no-shake: something about this press didn't work
	function api.shake()
		task.spawn(function()
			for _, x in ipairs({-7, 6, -4, 3, 0}) do
				face.Position = UDim2.fromOffset(x, 0)
				task.wait(0.035)
			end
		end)
	end
	face.Activated:Connect(function()
		up()
		UI.sfx(st.Enabled and (props.Sfx or "press") or "deny")
	end)
	api.Activated = face.Activated
	return api
end

-- a round icon button
function K.iconButton(props)
	local z = props.ZIndex or 2
	local size = props.Size or 44
	local b = new("TextButton", {Name = props.Name or "IconButton", AnchorPoint = props.AnchorPoint or Vector2.zero, Position = props.Position or UDim2.new(), Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = props.Color or K.C.Surface2, AutoButtonColor = false, Text = "", ZIndex = z, Parent = props.Parent}, {K.corner(), K.stroke(WHITE, 1.5, 0.8)})
	local scale = new("UIScale", {Parent = b})
	local _, bars = K.icon(b, props.Icon, math.floor(size * (props.IconScale or 0.42)), WHITE, z + 1)
	local base = props.Color or K.C.Surface2
	local enabled = true
	b.MouseEnter:Connect(function()
		if enabled then
			K.tween(b, 0.12, {BackgroundColor3 = base:Lerp(WHITE, 0.14)})
		end
	end)
	b.MouseLeave:Connect(function()
		K.tween(b, 0.12, {BackgroundColor3 = base})
		K.tween(scale, 0.12, {Scale = 1})
	end)
	b.MouseButton1Down:Connect(function()
		if enabled then
			K.tween(scale, 0.06, {Scale = 0.9})
		end
	end)
	b.MouseButton1Up:Connect(function()
		K.tween(scale, 0.14, {Scale = 1}, Enum.EasingStyle.Back)
	end)
	b.Activated:Connect(function()
		if enabled then
			UI.sfx(props.Sfx or "click")
		end
	end)
	local api = {Button = b, Activated = b.Activated}
	function api.setEnabled(on)
		enabled = on
		b.Active = on
		b.BackgroundTransparency = on and 0 or 0.55
		for _, bar in ipairs(bars) do
			bar.BackgroundTransparency = on and 0 or 0.65
		end
	end
	function api.isEnabled()
		return enabled
	end
	return api
end

-- a small rounded label that sizes itself to its text. Style = "tint" (default, on dark panels), "dark" (on bright
-- headers: a dark glass pill) or "solid" (filled with the colour, dark text: counts and tags over pictures)
function K.chip(props)
	local color = props.Color or K.C.Text2
	local style = props.Style or "tint"
	local bg, bgT, text = color, 0.84, color:Lerp(WHITE, 0.4)
	if style == "dark" then
		bg, bgT, text = rgb(20, 12, 36), 0.45, color:Lerp(WHITE, 0.55)
	elseif style == "solid" then
		bg, bgT, text = color, 0, color:Lerp(BLACK, 0.72)
	end
	local f = new("Frame", {Name = "Chip", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, props.Height or 30), Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = bg, BackgroundTransparency = bgT, LayoutOrder = props.LayoutOrder or 0, ZIndex = props.ZIndex or 2, Parent = props.Parent},
		{K.corner(), K.stroke(style == "solid" and WHITE or color, 1, style == "solid" and 0.5 or 0.6), new("UIPadding", {PaddingLeft = UDim.new(0, props.Pad or 12), PaddingRight = UDim.new(0, props.Pad or 12)})})
	local t = K.text({Text = props.Text or "", TextSize = props.TextSize or 15, TextColor3 = text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = (props.ZIndex or 2) + 1, Parent = f})
	return f, t
end

-- an on/off switch with its label on the left
function K.toggle(props)
	local z = props.ZIndex or 2
	local b = new("TextButton", {Name = "Toggle", AnchorPoint = props.AnchorPoint or Vector2.zero, Position = props.Position, Size = props.Size, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = z, Parent = props.Parent})
	K.text({Text = props.Text, TextSize = 16, TextColor3 = K.C.Text2, Size = UDim2.new(1, -56, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = z, Parent = b})
	local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 26), BackgroundColor3 = K.C.Surface2, ZIndex = z, Parent = b}, {K.corner(), K.stroke(WHITE, 1, 0.8)})
	local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, ZIndex = z + 1, Parent = track}, {K.corner()})
	local value = props.Value == true
	local function show(animate)
		local t = animate and 0.15 or 0
		K.tween(knob, t, {Position = UDim2.new(0, value and 24 or 4, 0.5, 0)})
		K.tween(track, t, {BackgroundColor3 = value and K.C.Green or K.C.Surface2})
	end
	show(false)
	b.Activated:Connect(function()
		value = not value
		UI.sfx("toggle")
		show(true)
		if props.OnChange then
			props.OnChange(value)
		end
	end)
	return b
end

-- how each kind of window opens: it starts a little smaller and offset, and settles into place.
-- Never rotate a window: Roblox stops clipping (ClipsDescendants, ScrollingFrames) under a rotated frame, so every
-- hidden row would spill out while it turned.
local MOTIONS = {
	pop = {Scale = 0.9, X = 0, Y = 16, Time = 0.3, Style = Enum.EasingStyle.Back}, -- springy (Pets, Hatchery)
	rise = {Scale = 0.97, X = 0, Y = 44, Time = 0.3, Style = Enum.EasingStyle.Quint}, -- slides up like a shop shutter (Shop)
	book = {Scale = 0.96, X = 40, Y = 0, Time = 0.32, Style = Enum.EasingStyle.Quint}, -- slides in like a turned page (Index)
}

-- a window drawn at W x H and fitted to the screen, clear of the HUD's side columns and the top bar. opts:
--   Name, W, H; Title + Icon + Accent (+ Accent2) draw a coloured header inside the card (one outline, no seams)
--   Motion = "pop" | "rise" | "book"; Sounds = {{sound, pitch, delay}, ...} played on opening (default {{"open"}})
--   Safe = {Left, Right} px the HUD columns use; on screens too small to keep them clear the window covers them
-- Returns {Frame (show/hide), Card, Body (below the header), Tools (header row, right side), Scale, Close, Open(), Hide(instant), Toggle()}
-- Every window joins UI.Windows, so opening one closes any other menu.
function K.window(gui, opts)
	local W, H = opts.W, opts.H
	local holder = new("Frame", {Name = opts.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui})
	local fit = new("Frame", {Name = "Fit", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Parent = holder})
	local fitScale = new("UIScale", {Parent = fit})
	-- the opening motion moves this frame, so the fitted position itself never drifts
	local mover = new("Frame", {Name = "Mover", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = fit})
	local scale = new("UIScale", {Parent = mover})
	new("Frame", {Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8), Size = UDim2.new(1, 22, 1, 22), BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, ZIndex = 0, Parent = mover}, {K.corner(30)})
	local accent = opts.Accent
	local card = new("Frame", {Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 1, Parent = mover}, {K.corner(24), K.stroke(WHITE, 1.5, 0.84)})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(accent and K.C.Panel:Lerp(accent, 0.16) or K.C.Panel, accent and K.C.PanelLow:Lerp(accent, 0.05) or K.C.PanelLow), Parent = card})

	local body, tools, close = card, nil, nil
	if opts.Title then
		-- the header is a band inside the card: rounded on top like the card, squared off below, no outline of its own
		local HEAD = 68
		local hc = ColorSequence.new(accent:Lerp(WHITE, 0.12), (opts.Accent2 or accent:Lerp(BLACK, 0.25)))
		local band = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = card}, {K.corner(24), new("UIGradient", {Color = hc})})
		new("Frame", {Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = band}, {new("UIGradient", {Color = hc})})
		new("Frame", {Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = BLACK, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 2, Parent = band})
		-- a soft light across the top half
		new("Frame", {Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0.42, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 2, Parent = band}, {K.corner(20)})
		local badge = new("Frame", {Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = WHITE, ZIndex = 3, Parent = band}, {K.corner(), K.stroke(accent:Lerp(BLACK, 0.35), 2.5, 0)})
		new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = opts.Icon or "", TextScaled = true, ZIndex = 4, Parent = badge}, {new("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7)})})
		local title = K.text({Text = opts.Title, FontFace = K.TITLE, TextSize = 32, Position = UDim2.fromOffset(76, 0), Size = UDim2.new(0, 300, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3, Parent = band})
		new("UIStroke", {Color = accent:Lerp(BLACK, 0.6), Thickness = 2, Transparency = 0.25, Parent = title})
		tools = new("Frame", {Name = "Tools", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -78, 0.5, 0), Size = UDim2.new(1, -460, 0, 40), BackgroundTransparency = 1, ZIndex = 3, Parent = band},
			{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
		close = K.iconButton({Icon = "close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = 44, IconScale = 0.38, Color = accent:Lerp(BLACK, 0.35), ZIndex = 4, Parent = band, Sfx = "tap"})
		body = new("Frame", {Name = "Body", Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 1, -HEAD), BackgroundTransparency = 1, ZIndex = 2, Parent = card})
	else
		close = K.iconButton({Icon = "close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 18), Size = 42, IconScale = 0.4, ZIndex = 30, Parent = card, Sfx = "tap"})
	end

	-- fit inside the screen minus the top bar and the HUD's side columns, centred in what's left
	-- this game's HUD: cash/speed pills and the menu buttons reach ~310 px on the left, the side buttons ~154 px on the right
	local safe = opts.Safe or {Left = 326, Right = 156}
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local top = GuiService:GetGuiInset().Y + 10
		local availH = vp.Y - top - 12
		local left, right = safe.Left, safe.Right
		local s = math.min((vp.X - left - right) / W, availH / H, opts.MaxScale or 1.2)
		if s < 0.8 then
			-- a small screen: keeping the HUD clear would make the window unreadable, so it covers the HUD instead
			left, right = 12, 12
			s = math.min((vp.X - 24) / W, availH / H, opts.MaxScale or 1.2)
		end
		fitScale.Scale = s
		fit.Position = UDim2.fromOffset(left + (vp.X - left - right) / 2, top + availH / 2)
	end
	refit()
	local function watchCamera()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
		end
		refit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	local motion = MOTIONS[opts.Motion or "pop"]
	local win = {Frame = holder, Card = card, Body = body, Tools = tools, Scale = scale, Close = close, Fit = fit, Refit = refit}
	local token = 0
	function win.Open()
		token += 1
		UI.closeOthers(win)
		refit()
		holder.Visible = true
		scale.Scale = motion.Scale
		mover.Position = UDim2.fromOffset(motion.X, motion.Y)
		K.tween(scale, motion.Time, {Scale = 1}, motion.Style)
		K.tween(mover, motion.Time * 0.9, {Position = UDim2.new()}, Enum.EasingStyle.Quint)
		local clicked = UI.justClicked()
		for _, snd in ipairs(opts.Sounds or {{"open"}}) do
			if clicked and snd[1] == "open" then
				-- the menu button already popped
			elseif (snd[3] or 0) > 0 then
				task.delay(snd[3], UI.sfx, snd[1], snd[2])
			else
				UI.sfx(snd[1], snd[2])
			end
		end
	end
	-- instant = another menu is taking over (no sound, no animation)
	function win.Hide(instant)
		if not holder.Visible then
			return
		end
		token += 1
		local my = token
		if instant then
			holder.Visible = false
			return
		end
		UI.sfx("close")
		K.tween(scale, 0.12, {Scale = 0.94}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		K.tween(mover, 0.12, {Position = UDim2.fromOffset(0, 12)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.12, function()
			if token == my then
				holder.Visible = false
			end
		end)
	end
	function win.Toggle()
		if holder.Visible then
			win.Hide()
		else
			win.Open()
		end
	end
	close.Activated:Connect(function()
		win.Hide()
	end)
	table.insert(UI.Windows, win)
	return win
end

-- a column of tabs: Items = {{Icon, Text, Color}}, onSelect(i). Returns {select(i, quiet), note(i, text, color)}
function K.sideTabs(props)
	local z = props.ZIndex or 3
	local accent = props.Accent or K.C.Violet
	local list = new("Frame", {Position = props.Position, Size = props.Size, BackgroundTransparency = 1, ZIndex = z, Parent = props.Parent},
		{new("UIListLayout", {Padding = UDim.new(0, props.Gap or 8), SortOrder = Enum.SortOrder.LayoutOrder})})
	local tabs, current = {}, 0
	local api = {Frame = list}
	local function paint(i)
		local t = tabs[i]
		local on = i == current
		local color = t.Color or accent
		K.tween(t.Button, 0.15, {BackgroundColor3 = on and color:Lerp(K.C.Surface, 0.35) or (t.Hover and K.C.Surface2 or K.C.Surface)})
		t.Stroke.Color = on and color:Lerp(WHITE, 0.35) or WHITE
		t.Stroke.Transparency = on and 0.1 or 0.9
		t.Label.TextColor3 = on and WHITE or K.C.Text2
		t.Note.TextColor3 = on and WHITE or (t.NoteColor or K.C.Muted)
		K.tween(t.Bar, 0.18, {Size = UDim2.new(0, 5, on and 0.6 or 0, 0)}, Enum.EasingStyle.Back)
	end
	function api.select(i, quiet)
		if not quiet and i ~= current then
			UI.sfx(props.Sfx or "tap")
		end
		local old = current
		current = i
		if tabs[old] then
			paint(old)
		end
		paint(i)
		if props.OnSelect then
			props.OnSelect(i)
		end
	end
	function api.note(i, text, color)
		tabs[i].Note.Text = text
		tabs[i].NoteColor = color or K.C.Muted
		tabs[i].Note.TextColor3 = i == current and WHITE or tabs[i].NoteColor
	end
	for i, it in ipairs(props.Items) do
		local b = new("TextButton", {LayoutOrder = i, Size = UDim2.new(1, 0, 0, props.Height or 52), BackgroundColor3 = K.C.Surface, AutoButtonColor = false, Text = "", ZIndex = z, Parent = list}, {K.corner(14)})
		local st = K.stroke(WHITE, 1.5, 0.9)
		st.Parent = b
		local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 5, 0, 0), BackgroundColor3 = (it.Color or accent):Lerp(WHITE, 0.3), BorderSizePixel = 0, ZIndex = z + 1, Parent = b}, {K.corner()})
		new("TextLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Text = it.Icon or "", TextScaled = true, ZIndex = z + 1, Parent = b})
		local lbl = K.text({Text = it.Text, TextSize = props.TextSize or 17, TextColor3 = K.C.Text2, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -112, 1, 0), ZIndex = z + 1, Parent = b})
		local note = K.text({Text = "", TextSize = 14, TextColor3 = K.C.Muted, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 60, 1, 0), ZIndex = z + 1, Parent = b})
		tabs[i] = {Button = b, Stroke = st, Label = lbl, Note = note, Bar = bar, Color = it.Color}
		b.MouseEnter:Connect(function()
			tabs[i].Hover = true
			paint(i)
		end)
		b.MouseLeave:Connect(function()
			tabs[i].Hover = false
			paint(i)
		end)
		b.Activated:Connect(function()
			if current ~= i then
				api.select(i)
			end
		end)
	end
	return api
end

-- a rounded progress bar; returns set(k, animate) and the track frame
function K.bar(props)
	local z = props.ZIndex or 3
	local color = props.Color or K.C.Green
	local track = new("Frame", {Position = props.Position, Size = props.Size, AnchorPoint = props.AnchorPoint or Vector2.zero, BackgroundColor3 = rgb(16, 12, 32), ZIndex = z, Parent = props.Parent}, {K.corner(), K.stroke(WHITE, 1, 0.9)})
	local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, ZIndex = z + 1, Parent = track},
		{K.corner(), new("UIGradient", {Rotation = 90, Color = ColorSequence.new(color:Lerp(WHITE, 0.35), color)})})
	return function(k, animate)
		k = math.clamp(k, 0, 1)
		local size = UDim2.fromScale(k > 0 and math.max(k, 0.05) or 0, 1)
		if animate then
			K.tween(fill, 0.45, {Size = size}, Enum.EasingStyle.Quint)
		else
			fill.Size = size
		end
	end, track
end

-- one fitted full-screen layer (the hatching show) drawn at W x H
function K.stage(parent, W, H)
	local fit = new("Frame", {Name = "Stage", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 2, Parent = parent})
	local s = new("UIScale", {Parent = fit})
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local inset = GuiService:GetGuiInset().Y
		s.Scale = math.min(vp.X / W, (vp.Y - inset) / H, 1.25)
		fit.Position = UDim2.new(0.5, 0, 0.5, inset / 2)
	end
	refit()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refit)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	return fit, s
end

return K

--[[
	ShopKit: the look of the Pet Hatchery (the shop and the hatching show).
	Layouts are drawn at a fixed design size and fitted to the screen by one UIScale, so spacing stays exact on every
	device. Thin light borders instead of black outlines, Builder Sans for text, Fredoka for titles. Icons (chevrons,
	the close X) are drawn from bars around their own centre, never font glyphs, so they sit dead centre.
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

-- an icon drawn from rounded bars, centred on its own bounding box: "left", "right" or "close"
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
	local edge = K.stroke(WHITE, 1.5, 0.78)
	edge.Parent = face
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
	local function up()
		face.Position = UDim2.new()
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
			face.Position = UDim2.fromOffset(0, 3)
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
		UI.sfx(st.Enabled and "press" or "lock")
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

-- a small rounded label that sizes itself to its text
function K.chip(props)
	local color = props.Color or K.C.Text2
	local f = new("Frame", {Name = "Chip", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, props.Height or 30), Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = color, BackgroundTransparency = 0.84, LayoutOrder = props.LayoutOrder or 0, ZIndex = props.ZIndex or 2, Parent = props.Parent},
		{K.corner(), K.stroke(color, 1, 0.6), new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})})
	local t = K.text({Text = props.Text or "", TextSize = props.TextSize or 15, TextColor3 = color:Lerp(WHITE, 0.4), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = (props.ZIndex or 2) + 1, Parent = f})
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

-- a window drawn at W x H and fitted to the screen. Returns {Frame (show/hide), Card (draw on it), Scale (opening pop), Close}
function K.window(gui, opts)
	local W, H = opts.W, opts.H
	local holder = new("Frame", {Name = opts.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui})
	local fit = new("Frame", {Name = "Fit", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Parent = holder})
	local fitScale = new("UIScale", {Parent = fit})
	new("Frame", {Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8), Size = UDim2.new(1, 22, 1, 22), BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, ZIndex = 0, Parent = fit}, {K.corner(30)})
	local card = new("Frame", {Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 1, Parent = fit}, {K.corner(24), K.stroke(WHITE, 1.5, 0.84)})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(K.C.Panel, K.C.PanelLow), Parent = card})
	local scale = new("UIScale", {Parent = card})
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local inset = GuiService:GetGuiInset().Y
		fitScale.Scale = math.min((vp.X - 24) / W, (vp.Y - inset - 20) / H, opts.MaxScale or 1.2)
		fit.Position = UDim2.new(0.5, 0, 0.5, inset / 2)
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
	local close = K.iconButton({Icon = "close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 18), Size = 42, IconScale = 0.4, ZIndex = 30, Parent = card, Sfx = "close"})
	close.Activated:Connect(function()
		holder.Visible = false
	end)
	return {Frame = holder, Card = card, Scale = scale, Close = close, Fit = fit, Refit = refit}
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

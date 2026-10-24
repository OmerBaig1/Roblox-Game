--[[
	UIKit
	Shared look for every menu: chunky buttons with black borders, a moving
	shine and sparkles, coloured panels with a header bar, and big bouncy
	reward pop-ups.
]]

local TweenService = game:GetService("TweenService")

local UI = {}
UI.FONT = Enum.Font.FredokaOne
UI.BG = Color3.fromRGB(26, 22, 44)
UI.PANEL = Color3.fromRGB(44, 38, 72)
UI.WHITE = Color3.new(1, 1, 1)
UI.BLACK = Color3.new(0, 0, 0)
UI.GOLD = Color3.fromRGB(255, 205, 50)
UI.GREEN = Color3.fromRGB(60, 210, 90)
UI.BLUE = Color3.fromRGB(70, 160, 255)
UI.PINK = Color3.fromRGB(255, 90, 200)
UI.PURPLE = Color3.fromRGB(170, 70, 255)
UI.RED = Color3.fromRGB(235, 60, 70)
UI.ROBUX = "\u{E002}"

function UI.new(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	if props then
		obj.Parent = props.Parent
	end
	return obj
end
local new = UI.new

function UI.corner(r, scale)
	return new("UICorner", {CornerRadius = scale and UDim.new(r, 0) or UDim.new(0, r)})
end

function UI.stroke(color, thickness, contextual)
	return new("UIStroke", {Color = color or UI.BLACK, Thickness = thickness or 3, ApplyStrokeMode = contextual and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round})
end

function UI.gradient(parent, a, b, rotation)
	return new("UIGradient", {Color = ColorSequence.new(a, b), Rotation = rotation or 90, Parent = parent})
end

-- Text with a thick black outline (bubbly game style)
function UI.label(props)
	local d = {BackgroundTransparency = 1, Font = UI.FONT, TextScaled = true, TextColor3 = UI.WHITE, RichText = true}
	for k, v in pairs(props) do
		d[k] = v
	end
	local outline = d.Outline
	d.Outline = nil
	local l = new("TextLabel", d)
	if outline ~= false then
		UI.stroke(UI.BLACK, outline or 2.5, true).Parent = l
	end
	return l
end

local SUFFIXES = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
function UI.fmt(n)
	n = tonumber(n) or 0
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = math.min(#SUFFIXES, math.floor(math.log10(n) / 3))
	local v = n / 10 ^ (i * 3)
	return (v >= 100 and string.format("%d", math.floor(v)) or string.format("%.1f", math.floor(v * 10) / 10)) .. SUFFIXES[i]
end

function UI.commas(n)
	local s = tostring(math.floor(n))
	while true do
		local k
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return s
end

function UI.fmtTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor(seconds % 3600 / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- A white shine that sweeps across a frame every few seconds
function UI.shine(frame, period)
	local clip = new("Frame", {Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = frame.ZIndex + 2, Parent = frame})
	local bar = new("Frame", {Size = UDim2.new(0.3, 0, 2, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.4, 0.5), Rotation = 25, BackgroundColor3 = UI.WHITE, BorderSizePixel = 0, ZIndex = frame.ZIndex + 2, Parent = clip})
	new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)}), Parent = bar})
	task.spawn(function()
		while frame.Parent do
			task.wait((period or 3) + math.random())
			if frame.Parent and frame.Visible then
				bar.Position = UDim2.fromScale(-0.4, 0.5)
				TweenService:Create(bar, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(1.4, 0.5)}):Play()
			end
		end
	end)
	return clip
end

-- Little twinkling stars over a frame
function UI.sparkles(frame, rate)
	task.spawn(function()
		while frame.Parent do
			task.wait(rate or 0.5)
			if frame.Visible then
				local size = math.random(10, 20)
				local star = new("TextLabel", {
					BackgroundTransparency = 1, Text = "\u{2726}", Font = UI.FONT, TextScaled = true,
					TextColor3 = math.random() < 0.5 and UI.WHITE or Color3.fromRGB(255, 240, 150),
					Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(math.random(10, 90) / 100, math.random(10, 90) / 100),
					TextTransparency = 1, ZIndex = frame.ZIndex + 3, Parent = frame,
				})
				local tin = TweenService:Create(star, TweenInfo.new(0.35), {TextTransparency = 0, Rotation = 45})
				tin:Play()
				task.delay(0.45, function()
					TweenService:Create(star, TweenInfo.new(0.35), {TextTransparency = 1, Rotation = 90}):Play()
					task.delay(0.4, function()
						star:Destroy()
					end)
				end)
			end
		end
	end)
end

-- Hover grows a little, clicking squishes it
function UI.bounce(button)
	local scale = button:FindFirstChildOfClass("UIScale") or new("UIScale", {Parent = button})
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1.06}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = 1}):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), {Scale = 0.94}):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = 1.06}):Play()
	end)
end

-- Chunky menu button. props: Name, Parent, Size, Position, AnchorPoint, LayoutOrder, Color, Icon, Text, Wide, Radius
function UI.fancyButton(props)
	local color = props.Color or UI.BLUE
	local b = new("TextButton", {
		Name = props.Name, Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0, BackgroundColor3 = UI.WHITE, Text = "", AutoButtonColor = false, Parent = props.Parent,
	}, {UI.corner(props.Radius or 18), UI.stroke(UI.BLACK, props.Border or 3.5)})
	UI.gradient(b, color:Lerp(UI.WHITE, 0.3), color:Lerp(UI.BLACK, 0.2), 90)
	-- glossy top half
	new("Frame", {Size = UDim2.new(1, -8, 0.42, 0), Position = UDim2.fromOffset(4, 3), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.78, Parent = b}, {UI.corner((props.Radius or 18) - 4)})
	local icon, text
	if props.Wide then
		icon = UI.label({Size = UDim2.new(0, b.Size.Y.Offset - 10, 1, -10), Position = UDim2.fromOffset(8, 5), Text = props.Icon or "", Outline = false, Parent = b})
		text = UI.label({Position = UDim2.new(0, b.Size.Y.Offset + 2, 0.18, 0), Size = UDim2.new(1, -(b.Size.Y.Offset + 10), 0.64, 0), TextXAlignment = Enum.TextXAlignment.Left, Text = props.Text or "", Parent = b})
	else
		icon = UI.label({Position = UDim2.fromScale(0.15, 0.04), Size = UDim2.fromScale(0.7, 0.58), Text = props.Icon or "", Outline = false, Parent = b})
		text = UI.label({Position = UDim2.fromScale(0.04, 0.64), Size = UDim2.fromScale(0.92, 0.3), Text = props.Text or "", Parent = b})
	end
	UI.shine(b, props.ShineEvery or 3)
	UI.sparkles(b, props.SparkleEvery or 0.7)
	UI.bounce(b)
	local badge = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = UI.RED, Visible = false, ZIndex = 10, Parent = b}, {UI.corner(1, true), UI.stroke(UI.BLACK, 2.5)})
	local badgeText = UI.label({Size = UDim2.fromScale(1, 1), Text = "!", ZIndex = 11, Parent = badge})
	return b, {Icon = icon, Text = text, Badge = badge, BadgeText = badgeText}
end

-- Coloured panel with a header bar (title + icon + close button)
function UI.panel(gui, opts)
	local color = opts.Color or UI.GOLD
	local p = new("Frame", {
		Name = opts.Name, AnchorPoint = Vector2.new(0.5, 0.5), Position = opts.Position or UDim2.fromScale(0.5, 0.53), Size = opts.Size or UDim2.fromScale(0.82, 0.82),
		BackgroundColor3 = UI.WHITE, Visible = false, Parent = gui,
	}, {UI.corner(22), UI.stroke(UI.BLACK, 5), new("UISizeConstraint", {MaxSize = opts.MaxSize or Vector2.new(920, 620)})})
	UI.gradient(p, Color3.fromRGB(60, 45, 110):Lerp(color, 0.28), Color3.fromRGB(32, 26, 64):Lerp(color, 0.1), 90)
	local scale = new("UIScale", {Parent = p})
	local header = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = UI.WHITE, Parent = p}, {UI.corner(22), UI.stroke(UI.BLACK, 4)})
	UI.gradient(header, color:Lerp(UI.WHITE, 0.3), color:Lerp(UI.BLACK, 0.15), 90)
	-- polka dots on the header
	for i = 1, 14 do
		new("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.new(i / 15, 0, 0.5 + ((i % 2 == 0) and 0.18 or -0.22), 0), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.8, Parent = header}, {UI.corner(3)})
	end
	UI.label({Position = UDim2.fromOffset(16, 8), Size = UDim2.fromOffset(54, 54), Text = opts.Icon or "", Outline = false, Parent = header})
	UI.label({Position = UDim2.fromOffset(78, 10), Size = UDim2.new(0.55, 0, 0, 50), TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Title or "", Outline = 3.5, Parent = header})
	local close = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = UI.WHITE, Text = "", AutoButtonColor = false, Parent = header}, {UI.corner(14), UI.stroke(UI.BLACK, 3.5)})
	UI.gradient(close, Color3.fromRGB(255, 110, 120), Color3.fromRGB(210, 40, 60), 90)
	UI.label({Size = UDim2.fromScale(1, 1), Text = "X", Outline = 3, Parent = close})
	UI.bounce(close)
	local body = new("Frame", {Name = "Body", Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 1, -74), BackgroundTransparency = 1, Parent = p})
	local panel = {Frame = p, Header = header, Body = body, Scale = scale, Close = close}
	close.Activated:Connect(function()
		p.Visible = false
	end)
	return panel
end

function UI.open(panel)
	panel.Frame.Visible = true
	panel.Scale.Scale = 0.85
	TweenService:Create(panel.Scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- Big coloured action button (claim / buy). Returns the button and its text label
function UI.actionButton(props, color)
	local b = new("TextButton", {
		Name = props.Name, Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0, BackgroundColor3 = UI.WHITE, Text = "", AutoButtonColor = false, Parent = props.Parent,
	}, {UI.corner(props.Radius or 14), UI.stroke(UI.BLACK, 3)})
	local grad = UI.gradient(b, color:Lerp(UI.WHITE, 0.25), color:Lerp(UI.BLACK, 0.2), 90)
	local t = UI.label({Position = UDim2.fromScale(0.06, 0.14), Size = UDim2.fromScale(0.88, 0.72), Text = props.Text or "", Parent = b})
	UI.bounce(b)
	local function setColor(c)
		grad.Color = ColorSequence.new(c:Lerp(UI.WHITE, 0.25), c:Lerp(UI.BLACK, 0.2))
	end
	return b, t, setColor
end

------------------------------------------------------------------
-- REWARD POP-UPS (queued so they never overlap)
------------------------------------------------------------------
local queue = {}
local showing = false

local function showNext(gui)
	if showing or #queue == 0 then return end
	showing = true
	local opts = table.remove(queue, 1)
	local color = opts.Color or UI.GOLD
	local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(820, 340), BackgroundTransparency = 1, ZIndex = 50, Parent = gui})
	local scale = new("UIScale", {Scale = 0.2, Parent = holder})
	-- glow + spinning rays behind
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(240, 240), BackgroundColor3 = color:Lerp(UI.WHITE, 0.4), BackgroundTransparency = 0.35, ZIndex = 50, Parent = holder}, {UI.corner(1, true)})
	new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.6)}), Parent = glow})
	local burst = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(420, 420), BackgroundTransparency = 1, ZIndex = 50, Parent = holder})
	for i = 0, 7 do
		new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 34, 1, 0), Rotation = i * 22.5, BackgroundColor3 = color:Lerp(UI.WHITE, 0.6), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 50, Parent = burst}, {UI.corner(1, true)})
	end
	if opts.Icon then
		UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(150, 150), Text = opts.Icon, Outline = false, ZIndex = 52, Parent = holder})
	end
	if opts.Poster then
		local ph = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromOffset(128, 160), BackgroundTransparency = 1, ZIndex = 52, Parent = holder}, {UI.corner(12), UI.stroke(UI.BLACK, 5)})
		opts.Poster.Parent = ph
	end
	local title = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.64), Size = UDim2.new(1, 0, 0, 84), Text = opts.Title or "", Outline = 5, ZIndex = 53, Parent = holder})
	UI.gradient(title, color:Lerp(UI.WHITE, 0.55), color, 90)
	local sub = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.new(1, 0, 0, 38), Text = opts.Sub or "", Outline = 3.5, ZIndex = 53, Parent = holder})
	local spin = true
	task.spawn(function()
		while spin and burst.Parent do
			burst.Rotation += 1.2
			task.wait()
		end
	end)
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(opts.Duration or 2.6, function()
		local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		TweenService:Create(scale, info, {Scale = 0}):Play()
		task.wait(0.4)
		spin = false
		holder:Destroy()
		showing = false
		showNext(gui)
	end)
end

function UI.popup(gui, opts)
	table.insert(queue, opts)
	showNext(gui)
end

return UI

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

------------------------------------------------------------------
-- SOUND EFFECTS: short and quiet. Each sound lists a few candidates; the first one that
-- actually loads is used (falls back to Roblox's built-in sounds), so none silently fail.
------------------------------------------------------------------
-- Max = seconds before the sound fades out (trims long tails)
local SFX = {
	click   = {Ids = {"rbxassetid://8816939097", "rbxassetid://102702078778790", "rbxasset://sounds/clickfast.wav"}, Volume = 0.4, Pitch = 1},
	pop     = {Ids = {"rbxassetid://119393948345399", "rbxassetid://102702078778790", "rbxasset://sounds/clickfast.wav"}, Volume = 0.35, Pitch = 1, Max = 0.3},
	press   = {Ids = {"rbxassetid://117649901456711", "rbxassetid://88442833509532", "rbxasset://sounds/clickfast.wav"}, Volume = 0.35, Pitch = 1},
	open    = {Ids = {"rbxassetid://127438224839678", "rbxassetid://17582213219", "rbxasset://sounds/clickfast.wav"}, Volume = 0.22, Pitch = 1.1, Max = 0.5},
	close   = {Ids = {"rbxassetid://127438224839678", "rbxassetid://17582213219", "rbxasset://sounds/clickfast.wav"}, Volume = 0.2, Pitch = 0.8, Max = 0.45},
	toggle  = {Ids = {"rbxassetid://9119717523", "rbxasset://sounds/switch.wav", "rbxasset://sounds/clickfast.wav"}, Volume = 0.35, Pitch = 1},
	lock    = {Ids = {"rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.35, Pitch = 0.7, Max = 0.45},
	unlock  = {Ids = {"rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.35, Pitch = 1.25, Max = 0.4},
	reward  = {Ids = {"rbxassetid://135165335432475", "rbxassetid://122399158411452", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.35, Pitch = 1},
	claim   = {Ids = {"rbxassetid://106145041472451", "rbxassetid://89593894732695", "rbxassetid://135165335432475", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.4, Pitch = 1},
	sparkle = {Ids = {"rbxassetid://135257162986933", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.22, Pitch = 1.2, Max = 1.2},
	buy     = {Ids = {"rbxassetid://134810204798705", "rbxassetid://91206735719300", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.4, Pitch = 1, Max = 1.2},
	swing   = {Ids = {"rbxassetid://123796710194563", "rbxassetid://7655466603", "rbxasset://sounds/swordslash.wav"}, Volume = 0.4, Pitch = 1.15, Max = 0.5},
	slap    = {Ids = {"rbxassetid://511340819", "rbxassetid://8556065163", "rbxassetid://140165921656547", "rbxasset://sounds/action_jump_land.mp3"}, Volume = 0.6, Pitch = 1},
}
-- Every menu button has its own voice: {sound, pitch}. Unnamed buttons just click.
local BUTTON_SFX = {
	SHOP = {"pop", 1.15}, INDEX = {"pop", 0.9}, DAILY = {"click", 1.25}, GIFT = {"pop", 1.4},
	INFO = {"click", 1.4}, DOWNLOADS = {"click", 0.95}, INSTALLED = {"pop", 1.05},
}
local sfxReady = {}
do
	local ContentProvider = game:GetService("ContentProvider")
	local SoundService = game:GetService("SoundService")
	local folder = Instance.new("Folder")
	folder.Name = "UISounds"
	folder.Parent = SoundService
	for name, def in pairs(SFX) do
		task.spawn(function()
			for _, id in ipairs(def.Ids) do
				local s = Instance.new("Sound")
				s.Name = name
				s.SoundId = id
				s.Volume = def.Volume
				s.PlaybackSpeed = def.Pitch
				s.Parent = folder
				pcall(function()
					ContentProvider:PreloadAsync({s})
				end)
				if s.TimeLength > 0 then
					sfxReady[name] = s
					return
				end
				s:Destroy()
			end
		end)
	end
end
local lastButtonSfx = 0
function UI.sfx(name, pitch)
	local s = sfxReady[name]
	local def = SFX[name]
	if not s then return end
	s.Volume = def.Volume
	s.PlaybackSpeed = def.Pitch * (pitch or 1)
	s.TimePosition = 0
	s:Play()
	if def.Max then
		local token = tostring(os.clock())
		s:SetAttribute("Play", token)
		task.delay(def.Max, function()
			if s:GetAttribute("Play") == token and s.IsPlaying then
				TweenService:Create(s, TweenInfo.new(0.08), {Volume = 0}):Play()
			end
		end)
	end
end

-- A claimed reward: a bright chime with a little sparkle on top
function UI.claimSfx()
	UI.sfx("claim")
	task.delay(0.08, UI.sfx, "sparkle")
end

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

-- Is this frame actually on screen? (it and every parent visible, inside an enabled ScreenGui)
function UI.shown(obj)
	while obj do
		if obj:IsA("LayerCollector") then
			return obj.Enabled and obj.Parent ~= nil
		end
		if obj:IsA("GuiObject") and not obj.Visible then
			return false
		end
		obj = obj.Parent
	end
	return false
end

-- A vertical list that scrolls (mouse wheel, drag or scroll bar)
function UI.scroller(parent, pos, size)
	return new("ScrollingFrame", {
		Position = pos, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 10,
		ScrollBarImageColor3 = UI.WHITE, ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingEnabled = true, Active = true, Parent = parent,
	})
end

-- A white shine that sweeps across a frame every few seconds
function UI.shine(frame, period)
	local clip = new("Frame", {Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = frame.ZIndex + 2, Parent = frame})
	local bar = new("Frame", {Size = UDim2.new(0.3, 0, 2, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.4, 0.5), Rotation = 25, BackgroundColor3 = UI.WHITE, BorderSizePixel = 0, ZIndex = frame.ZIndex + 2, Parent = clip})
	new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)}), Parent = bar})
	task.spawn(function()
		while frame.Parent do
			task.wait((period or 3) + math.random())
			if UI.shown(frame) then
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
			if UI.shown(frame) then
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
	if not button:GetAttribute("Silent") then
		button.Activated:Connect(function()
			local own = BUTTON_SFX[button.Name]
			if own then
				UI.sfx(own[1], own[2])
			else
				UI.sfx(button:GetAttribute("Sfx") or "click")
			end
			lastButtonSfx = os.clock()
		end)
	end
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
	close:SetAttribute("Silent", true) -- plays the close whoosh below instead of a click
	UI.bounce(close)
	local body = new("Frame", {Name = "Body", Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 1, -74), BackgroundTransparency = 1, Parent = p})
	local panel = {Frame = p, Header = header, Body = body, Scale = scale, Close = close}
	close.Activated:Connect(function()
		p.Visible = false
		UI.sfx("close")
	end)
	return panel
end

function UI.open(panel)
	-- the button that opened it already made its own sound
	if os.clock() - lastButtonSfx > 0.15 then
		UI.sfx("open")
	end
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
	b:SetAttribute("Sfx", "press")
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
	local icon
	if opts.Icon then
		icon = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(150, 150), Text = opts.Icon, Outline = false, ZIndex = 52, Parent = holder})
	end
	local ph, phScale
	if opts.Poster then
		ph = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromOffset(128, 160), BackgroundTransparency = 1, ZIndex = 52, Parent = holder}, {UI.corner(12), UI.stroke(UI.BLACK, 5)})
		phScale = new("UIScale", {Scale = opts.Reveal and 0 or 1, Parent = ph})
		opts.Poster.Parent = ph
		if icon then
			icon.Visible = opts.Reveal == true
		end
	end
	local title = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.64), Size = UDim2.new(1, 0, 0, 84), Text = opts.Title or "", Outline = 5, ZIndex = 53, Parent = holder})
	local titleGrad = UI.gradient(title, color:Lerp(UI.WHITE, 0.55), color, 90)
	local sub = UI.label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.new(1, 0, 0, 38), Text = opts.Reveal and "" or (opts.Sub or ""), Outline = 3.5, ZIndex = 53, Parent = holder})
	local spin = true
	local spinSpeed = 1.2
	task.spawn(function()
		while spin and burst.Parent do
			burst.Rotation += spinSpeed
			task.wait()
		end
	end)
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local extra = 0
	if opts.Reveal and ph and icon then
		-- MYSTERY REVEAL: the ? shakes harder and harder, a white flash, then the game pops out
		extra = 1.4
		task.spawn(function()
			task.wait(0.45)
			for k = 1, 8 do
				local a = (k % 2 == 0 and 1 or -1) * (6 + k * 2)
				TweenService:Create(icon, TweenInfo.new(0.07), {Rotation = a, Size = UDim2.fromOffset(150 + k * 6, 150 + k * 6)}):Play()
				spinSpeed = 1.2 + k * 0.8
				task.wait(0.08)
			end
			local flash = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = UI.WHITE, ZIndex = 54, Parent = holder}, {UI.corner(1, true)})
			TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = UDim2.fromOffset(520, 520), BackgroundTransparency = 1}):Play()
			task.delay(0.5, flash.Destroy, flash)
			icon.Visible = false
			ph.Rotation = -25
			TweenService:Create(phScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.25}):Play()
			TweenService:Create(ph, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			UI.claimSfx()
			spinSpeed = 3
			local rc = opts.RevealColor or color
			title.Text = opts.RevealTitle or title.Text
			titleGrad.Color = ColorSequence.new(rc:Lerp(UI.WHITE, 0.55), rc)
			sub.Text = opts.Sub or ""
			for _, ray in ipairs(burst:GetChildren()) do
				ray.BackgroundColor3 = rc:Lerp(UI.WHITE, 0.5)
			end
			glow.BackgroundColor3 = rc:Lerp(UI.WHITE, 0.4)
			-- confetti of little stars bursting out
			for _ = 1, 14 do
				local star = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(26, 26), Text = "\u{2726}", TextColor3 = math.random() < 0.5 and UI.WHITE or rc:Lerp(UI.WHITE, 0.3), Outline = false, ZIndex = 55, Parent = holder})
				local ang = math.random() * math.pi * 2
				local dist = math.random(140, 260)
				TweenService:Create(star, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, math.cos(ang) * dist, 0.36, math.sin(ang) * dist), Rotation = math.random(-180, 180), TextTransparency = 1}):Play()
				task.delay(0.85, star.Destroy, star)
			end
			task.wait(0.5)
			TweenService:Create(phScale, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Scale = 1.1}):Play()
		end)
	end
	task.delay((opts.Duration or 2.6) + extra, function()
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
	if opts.Reveal then
		UI.sfx("pop") -- the big chime waits for the reveal
	else
		UI.claimSfx()
	end
	table.insert(queue, opts)
	showNext(gui)
end

return UI

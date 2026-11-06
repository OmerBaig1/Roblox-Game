--[[
	UIKit
	Shared look for every menu: chunky buttons with black borders, a moving
	shine and sparkles, coloured panels with a header bar, and big bouncy
	reward pop-ups.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
	-- Interface sounds: Google's Material Design UI set (CC BY 4.0), uploaded to Roblox under the original file names.
	-- One soft, clean family: taps for buttons, rising notes to open menus, a falling note to close.
	click   = {Ids = {"rbxassetid://122966251252708", "rbxassetid://8816939097", "rbxasset://sounds/clickfast.wav"}, Volume = 0.5, Pitch = 1}, -- ui_tap-variant-02
	pop     = {Ids = {"rbxassetid://114030580225727", "rbxassetid://3623733749", "rbxasset://sounds/clickfast.wav"}, Volume = 0.5, Pitch = 1, Max = 0.4}, -- ui_tap-variant-03
	press   = {Ids = {"rbxassetid://123087446204451", "rbxassetid://3623733749", "rbxasset://sounds/clickfast.wav"}, Volume = 0.5, Pitch = 1}, -- ui_tap-variant-04
	tap     = {Ids = {"rbxassetid://118050128378427", "rbxassetid://3623733749", "rbxasset://sounds/clickfast.wav"}, Volume = 0.45, Pitch = 1, Max = 0.4}, -- ui_tap-variant-01
	open    = {Ids = {"rbxassetid://79351880562463", "rbxassetid://3623740277", "rbxasset://sounds/clickfast.wav"}, Volume = 0.5, Pitch = 1, Max = 0.8}, -- navigation_forward-selection-minimal
	menuopen = {Ids = {"rbxassetid://127898241244912", "rbxassetid://3623740277", "rbxasset://sounds/clickfast.wav"}, Volume = 0.5, Pitch = 1, Max = 0.9}, -- navigation_forward-selection
	close   = {Ids = {"rbxassetid://108038441910574", "rbxassetid://73147193690974", "rbxasset://sounds/clickfast.wav"}, Volume = 0.35, Pitch = 1, Max = 0.6}, -- navigation_backward-selection-minimal
	page    = {Ids = {"rbxassetid://86797626996300", "rbxassetid://92044948572397", "rbxasset://sounds/clickfast.wav"}, Volume = 0.45, Pitch = 1, Max = 0.8}, -- navigation_transition-right
	coin    = {Ids = {"rbxassetid://98466697920863", "rbxassetid://131222240980061", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.45, Pitch = 1, Max = 1}, -- notification_simple-01
	deny    = {Ids = {"rbxassetid://88258639627967", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.4, Pitch = 1, Max = 0.6}, -- state-change_confirm-down
	toggle  = {Ids = {"rbxassetid://9119717523", "rbxasset://sounds/switch.wav", "rbxasset://sounds/clickfast.wav"}, Volume = 0.35, Pitch = 1},
	-- picking a game up out of your case: the menu-open note, a little higher and cut short so it's its own sound
	pickup  = {Ids = {"rbxassetid://127898241244912", "rbxassetid://3623740277", "rbxasset://sounds/clickfast.wav"}, Volume = 0.4, Pitch = 1.15, Max = 0.5}, -- navigation_forward-selection
	-- the tutorial's text appearing: the soft tap, high and quiet, cut short so ticks never ring into each other
	type    = {Ids = {"rbxassetid://118050128378427", "rbxassetid://3623733749", "rbxasset://sounds/clickfast.wav"}, Volume = 0.16, Pitch = 1.45, Max = 0.09},
	lock    = {Ids = {"rbxassetid://88258639627967", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.4, Pitch = 1, Max = 0.6},
	unlock  = {Ids = {"rbxassetid://127898241244912", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.45, Pitch = 1, Max = 0.9},
	reward  = {Ids = {"rbxassetid://117728785646872", "rbxassetid://135165335432475", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.5, Pitch = 1}, -- hero_simple-celebration-03
	claim   = {Ids = {"rbxassetid://85218505327576", "rbxassetid://106145041472451", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.5, Pitch = 1}, -- hero_simple-celebration-01
	sparkle = {Ids = {"rbxassetid://135257162986933", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.22, Pitch = 1.2, Max = 1.2},
	buy     = {Ids = {"rbxassetid://134810204798705", "rbxassetid://91206735719300", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.4, Pitch = 1, Max = 1.2},
	swing   = {Ids = {"rbxassetid://123796710194563", "rbxassetid://7655466603", "rbxasset://sounds/swordslash.wav"}, Volume = 0.4, Pitch = 1.15, Max = 0.5},
	-- egg hatching: a knock for every wobble, the crack, a burst, then a sting that grows with the rarity
	eggknock = {Ids = {"rbxassetid://9120756768", "rbxassetid://8816939097", "rbxasset://sounds/clickfast.wav"}, Volume = 0.45, Pitch = 1.4, Max = 0.25},
	eggcrack = {Ids = {"rbxassetid://9113959343", "rbxassetid://9113959332", "rbxasset://sounds/clickfast.wav"}, Volume = 0.6, Pitch = 1, Max = 0.7},
	hatch    = {Ids = {"rbxassetid://119620526223720", "rbxassetid://1841488866", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.5, Pitch = 1, Max = 2},
	hatchrare = {Ids = {"rbxassetid://1840076509", "rbxassetid://128460880879263", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.45, Pitch = 1},
	hatchlegend = {Ids = {"rbxassetid://128460880879263", "rbxassetid://1844016113", "rbxasset://sounds/electronicpingshort.wav"}, Volume = 0.55, Pitch = 1},
	slap    = {Ids = {"rbxassetid://511340819", "rbxassetid://8556065163", "rbxassetid://140165921656547", "rbxasset://sounds/action_jump_land.mp3"}, Volume = 0.6, Pitch = 1},
}
-- Every menu button has its own voice: {sound, pitch}. Unnamed buttons just click.
-- false = silent: the menu it opens plays its own sound at the same moment, so a click never stacks two sounds
local BUTTON_SFX = {
	SHOP = false, INDEX = false, DAILY = false, GIFT = false, INFO = false, DOWNLOADS = false, INSTALLED = false, PETS = false,
}
local sfxReady = {}
-- only a playing client loads sounds (requiring this in Studio's edit mode or on the server must not leave a
-- UISounds folder behind in the place)
if game:GetService("RunService"):IsClient() and game:GetService("RunService"):IsRunning() then
	local ContentProvider = game:GetService("ContentProvider")
	local SoundService = game:GetService("SoundService")
	local folder = Instance.new("Folder")
	folder.Name = "UISounds"
	folder.Parent = SoundService
	-- every menu sound plays through one group, so they can be turned down or muted together
	local group = SoundService:FindFirstChild("UI") or Instance.new("SoundGroup")
	group.Name = "UI"
	group.Parent = SoundService
	UI.SoundGroup = group
	for name, def in pairs(SFX) do
		task.spawn(function()
			for _, id in ipairs(def.Ids) do
				local s = Instance.new("Sound")
				s.Name = name
				s.SoundId = id
				s.Volume = def.Volume
				s.PlaybackSpeed = def.Pitch
				s.SoundGroup = group
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
local lastPlayed = {}
function UI.sfx(name, pitch)
	local s = sfxReady[name]
	local def = SFX[name]
	if not s then return end
	-- rapid clicks restart a sound instead of stacking it, and never more than once per 50 ms
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < 0.05 then return end
	lastPlayed[name] = now
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
	-- CanvasGroup, not a clipping Frame: the shine bar is rotated, and only a CanvasGroup clips rotated
	-- pieces (and follows the frame's rounded corners)
	local clip = new("CanvasGroup", {Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = frame.ZIndex + 2, Parent = frame})
	local round = frame:FindFirstChildOfClass("UICorner")
	if round then
		round:Clone().Parent = clip
	end
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
					Position = UDim2.fromScale(math.random(16, 84) / 100, math.random(16, 84) / 100), -- kept clear of the border
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
	local hovering = false
	button.MouseEnter:Connect(function()
		hovering = true
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Scale = 1.05}):Play()
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Scale = 1}):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {Scale = 0.94}):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = hovering and 1.05 or 1}):Play()
	end)
	if not button:GetAttribute("Silent") then
		button.Activated:Connect(function()
			local own = BUTTON_SFX[button.Name]
			if own == false then
				return
			elseif own then
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
	}, {UI.corner(props.Radius or 18), UI.stroke(color:Lerp(UI.BLACK, 0.65), props.Border or 3.5)})
	UI.gradient(b, color:Lerp(UI.WHITE, 0.35), color:Lerp(UI.BLACK, 0.12), 90)
	local r = props.Radius or 18
	-- a darker band along the bottom: the button reads as a raised, chunky block
	new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.34, 0), BackgroundColor3 = color:Lerp(UI.BLACK, 0.45), BorderSizePixel = 0, Parent = b},
		{UI.corner(r), new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0.35)})})
	-- glossy top half and a thin lit rim just inside the edge
	new("Frame", {Size = UDim2.new(1, -10, 0.4, 0), Position = UDim2.fromOffset(5, 4), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.72, Parent = b},
		{UI.corner(r - 5), new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0.2, 1)})})
	new("Frame", {Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, Parent = b},
		{UI.corner(r - 2), new("UIStroke", {Color = UI.WHITE, Thickness = 1.5, Transparency = 0.55})})
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
	table.insert(UI.Windows, panel)
	return panel
end

------------------------------------------------------------------
-- SCREEN SIZE. The HUD is drawn in pixels on a design canvas about 2000x1200, scaled to the real screen so every
-- size, gap, position and animation keeps the same SHARE of the screen: 0.9 at 1080p, 1.2 at 1440p, 1.8 at 4K.
-- (Until Oct 29 it was 1 at 1440p, which made the HUD look small on a real 1440p monitor: the layouts had only ever
-- been judged in Studio's small viewport, where the floor below made them relatively bigger.) Small screens get a
-- floor so text stays readable (a lower one on touch screens, which have less room). Windows (MenuKit) fit themselves to the space left
-- and cap their size by the same scale, so they cover the same share of a 1080p screen as of a 1440p one.
------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
function UI.hudScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(2560, 1440)
	if vp.X < 50 or vp.Y < 50 then
		vp = Vector2.new(2560, 1440) -- a minimised window reports a 1x1 viewport
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	return math.clamp(math.min(vp.Y / 1200, vp.X / 2000), touch and 0.5 or 0.62, 1.8)
end

local canvases = {}
-- lays gui out on the design canvas: its children move into a frame "Canvas" (window holders that fit themselves,
-- marked SelfFit, stay put). Returns the canvas frame.
function UI.canvas(gui)
	if canvases[gui] then
		return canvases[gui]
	end
	local root = new("Frame", {Name = "Canvas", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui})
	local scale = new("UIScale", {Parent = root})
	canvases[gui] = root
	local function fit()
		local k = UI.hudScale()
		scale.Scale = k
		root.Size = UDim2.fromScale(1 / k, 1 / k)
	end
	fit()
	local function watch()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		end
		fit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watch)
	watch()
	local function adopt(child)
		if child == root or not child:IsA("GuiObject") or child:GetAttribute("SelfFit") then
			return
		end
		task.defer(function()
			if child.Parent == gui and not child:GetAttribute("SelfFit") then
				child.Parent = root
			end
		end)
	end
	for _, c in ipairs(gui:GetChildren()) do
		adopt(c)
	end
	gui.ChildAdded:Connect(adopt)
	return root
end
-- the design-canvas scale an object is drawn at (1 outside any canvas)
function UI.canvasScale(obj)
	local root = obj and obj:FindFirstAncestor("Canvas")
	local sc = root and root:FindFirstChildOfClass("UIScale")
	return sc and sc.Scale or 1
end
-- FindFirstChild anywhere below, waiting up to timeout seconds (things may move into a canvas)
function UI.findDeep(parent, name, timeout)
	local t0 = os.clock()
	repeat
		local found = parent:FindFirstChild(name, true)
		if found then
			return found
		end
		task.wait(0.05)
	until os.clock() - t0 > (timeout or 10)
	return nil
end

-- A small red notification dot (with an optional count) that sits INSIDE its parent's corner, so it never clips,
-- never covers the label it belongs to and never takes the click
function UI.dot(parent, props)
	props = props or {}
	local size = props.Size or 14
	local d = new("Frame", {Name = "Dot", AnchorPoint = Vector2.new(1, 0), Position = props.Position or UDim2.new(1, -5, 0, 5), Size = UDim2.fromOffset(size, size),
		AutomaticSize = props.Count and Enum.AutomaticSize.X or Enum.AutomaticSize.None, BackgroundColor3 = Color3.fromRGB(255, 64, 82), Visible = false, Active = false, ZIndex = props.ZIndex or 20, Parent = parent},
		{UI.corner(1, true), new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = props.Ring or 2, Transparency = 0.05})})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 130, 140), Color3.fromRGB(225, 30, 55)), Parent = d})
	local text
	if props.Count then
		new("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = d})
		text = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextColor3 = Color3.new(1, 1, 1),
			FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy), TextSize = math.floor(size * 0.72), ZIndex = (props.ZIndex or 20) + 1, Parent = d})
	end
	local api = {Frame = d}
	function api.set(n)
		local on = (tonumber(n) or (n and 1 or 0)) > 0
		d.Visible = on
		if text then
			text.Text = on and tostring(n) or ""
		end
	end
	return api
end

------------------------------------------------------------------
-- TILE BUTTON: the big HUD tiles (PETS, DOWNLOADS, INSTALLED). Each is an emblem rather than a flat box: a faceted gem
-- with a slow orbiting ring, a small turning 3D model standing out of it (a ViewportFrame, like the Play Time gift) and
-- a ribbon carrying the label. Every tile has its own colours, model and click burst (TILE_STYLES); they share the build.
-- States: hover lifts it, a click squashes and pops it and fires its burst, active (its window is open) lights a halo
-- and turns the ribbon white, disabled greys it, and a red count badge sits on its corner.
-- props: Name, Parent, Size (px), Position, AnchorPoint, LayoutOrder, Text, Style ("pets"/"downloads"/"installed").
-- Returns button, refs {Text, Badge, BadgeText, Face, setActive(on), setEnabled(on)}.
------------------------------------------------------------------
local function tilePart(model, class, props)
	local p = Instance.new(class)
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = model
	return p
end
-- SpecialMesh spheres don't draw in a ViewportFrame, so these are true Ball parts (always round: sized by the mean)
local function tileBall(model, x, y, z, sx, sy, sz, color)
	local d = (sx + sy + sz) / 3
	return tilePart(model, "Part", {Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(x, y, z), Color = color})
end

-- A burst bit: flies from the tile's centre by (dx, dy) px while spinning and fading, then is gone. All of them are plain
-- non-Active frames, so they never catch a click, and they fly out to the sides and above: never over the label.
local function burstBit(fx, size, color, dx, dy, spin, life, round)
	local bit = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(size.X, size.Y), Rotation = math.random(0, 360),
		BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 31, Parent = fx})
	if round then
		UI.corner(1, true).Parent = bit
	end
	local tw = TweenService:Create(bit, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, dx, 0.42, dy), Rotation = bit.Rotation + spin, BackgroundTransparency = 1, Size = UDim2.fromOffset(size.X * 0.6, size.Y * 0.6)})
	tw:Play()
	tw.Completed:Once(function()
		bit:Destroy()
	end)
	return bit
end
-- a shape made of several bars (a tick, a chevron, a paw) flying as one
local function burstGlyph(fx, build, dx, dy, spin, life, startScale)
	local g = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, ZIndex = 31, Parent = fx})
	local s = new("UIScale", {Scale = startScale or 0.5, Parent = g})
	build(g)
	TweenService:Create(s, TweenInfo.new(life * 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local tw = TweenService:Create(g, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, dx, 0.42, dy), Rotation = spin})
	tw:Play()
	task.delay(life * 0.55, function()
		for _, d in ipairs(g:GetChildren()) do
			if d:IsA("Frame") then
				TweenService:Create(d, TweenInfo.new(life * 0.45), {BackgroundTransparency = 1}):Play()
			end
		end
	end)
	tw.Completed:Once(function()
		g:Destroy()
	end)
end
local function glyphBar(g, x, y, w, h, rot, color, round)
	local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), Rotation = rot or 0, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 32, Parent = g})
	if round then
		UI.corner(1, true).Parent = f
	end
end
local function burstRing(fx, color, grow)
	local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 30, Parent = fx}, {UI.corner(1, true)})
	local st = new("UIStroke", {Color = color, Thickness = 6, Parent = ring})
	local info = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(st, info, {Thickness = 1, Transparency = 1}):Play()
	local tw = TweenService:Create(ring, info, {Size = UDim2.fromScale(grow, grow)})
	tw:Play()
	tw.Completed:Once(function()
		ring:Destroy()
	end)
end

local TILE_STYLES = {
	-- a paw print that hops; the burst is paws and warm sparks floating up and away
	pets = {
		Top = Color3.fromRGB(255, 176, 70), Low = Color3.fromRGB(226, 66, 104), Glow = Color3.fromRGB(255, 214, 120), Chime = 1.25,
		Build = function(model)
			local cream, pink = Color3.fromRGB(255, 244, 226), Color3.fromRGB(255, 138, 150)
			tileBall(model, 0, -0.38, 0, 1.5, 1.22, 0.7, cream)
			tileBall(model, 0, -0.42, -0.26, 0.92, 0.72, 0.34, pink)
			for _, t in ipairs({{-0.92, 0.3, 0.52, 0.72}, {-0.34, 0.76, 0.56, 0.78}, {0.34, 0.76, 0.56, 0.78}, {0.92, 0.3, 0.52, 0.72}}) do
				tileBall(model, t[1], t[2], 0, t[3], t[4], 0.5, cream)
				tileBall(model, t[1], t[2] + 0.02, -0.2, t[3] * 0.58, t[4] * 0.58, 0.22, pink)
			end
		end,
		Animate = function(t, hot)
			local hop = math.abs(math.sin(t * (hot and 5 or 2.4))) * (hot and 0.2 or 0.09)
			return CFrame.new(0, hop, 0) * CFrame.Angles(0.12, math.sin(t * 1.1) * 0.5, math.sin(t * 2.4) * 0.07)
		end,
		Burst = function(fx)
			burstRing(fx, Color3.fromRGB(255, 214, 120), 1.5)
			local warm = {Color3.fromRGB(255, 196, 80), Color3.fromRGB(255, 120, 150), Color3.fromRGB(255, 244, 226)}
			for k = 1, 4 do
				local a = math.rad(-180 + 40 * k + math.random(-8, 8))
				burstGlyph(fx, function(g)
					local c = warm[k % 2 + 1]
					glyphBar(g, 0.5, 0.66, 0.56, 0.5, 0, c, true)
					glyphBar(g, 0.16, 0.42, 0.22, 0.3, -22, c, true)
					glyphBar(g, 0.38, 0.2, 0.22, 0.3, -8, c, true)
					glyphBar(g, 0.62, 0.2, 0.22, 0.3, 8, c, true)
					glyphBar(g, 0.84, 0.42, 0.22, 0.3, 22, c, true)
				end, math.cos(a) * math.random(58, 80), math.sin(a) * math.random(58, 80) - 14, math.random(-28, 28), 0.6)
			end
			for k = 1, 10 do
				local a = math.rad(math.random(-205, 25))
				burstBit(fx, Vector2.new(7, 7), warm[k % #warm + 1], math.cos(a) * math.random(40, 72), math.sin(a) * math.random(40, 72), 90, 0.5, true)
			end
		end,
	},
	-- an arrow that keeps dropping; the burst is chevrons and data bits raining down the sides
	downloads = {
		Top = Color3.fromRGB(70, 216, 255), Low = Color3.fromRGB(44, 86, 232), Glow = Color3.fromRGB(150, 236, 255), Chime = 1.05,
		Build = function(model)
			local white = Color3.fromRGB(245, 252, 255)
			local arrow = Instance.new("Model")
			arrow.Name = "Arrow"
			local shaft = tilePart(arrow, "Part", {Name = "Shaft", Size = Vector3.new(0.62, 1.05, 0.5), CFrame = CFrame.new(0, 0.62, 0), Color = white})
			-- the head: two wedges back to back, flat tops level with the bottom of the shaft
			tilePart(arrow, "WedgePart", {Size = Vector3.new(0.5, 0.82, 0.72), CFrame = CFrame.new(-0.36, -0.28, 0) * CFrame.Angles(0, math.pi / 2, math.pi), Color = white})
			tilePart(arrow, "WedgePart", {Size = Vector3.new(0.5, 0.82, 0.72), CFrame = CFrame.new(0.36, -0.28, 0) * CFrame.Angles(0, -math.pi / 2, math.pi), Color = white})
			arrow.PrimaryPart = shaft
			arrow.Parent = model
		end,
		Animate = function(t, hot, model)
			local arrow = model:FindFirstChild("Arrow")
			if arrow then
				local k = (t * (hot and 1.5 or 0.8)) % 1
				arrow:PivotTo(CFrame.new(0, 0.62 - 0.38 * math.sin(k * math.pi), 0))
			end
			return CFrame.Angles(0.14, math.sin(t * 0.9) * 0.42, 0)
		end,
		Burst = function(fx)
			burstRing(fx, Color3.fromRGB(120, 230, 255), 1.45)
			for k = 1, 6 do
				local x = (k - 3.5) * 25
				burstGlyph(fx, function(g)
					local c = k % 2 == 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 230, 255)
					glyphBar(g, 0.3, 0.42, 0.58, 0.2, 45, c, true)
					glyphBar(g, 0.7, 0.42, 0.58, 0.2, -45, c, true)
				end, x, math.random(-58, -32) - (3.5 - math.abs(k - 3.5)) * 14, 0, 0.5, 0.7)
			end
			for k = 1, 10 do
				local side = k % 2 == 0 and 1 or -1
				burstBit(fx, Vector2.new(6, 6), k % 3 == 0 and Color3.new(1, 1, 1) or Color3.fromRGB(90, 200, 255), side * math.random(50, 76), math.random(-46, 40), 0, 0.46)
			end
		end,
	},
	-- a game cartridge with a green tick; the burst is ticks, gold stars and green confetti
	installed = {
		Top = Color3.fromRGB(150, 236, 90), Low = Color3.fromRGB(16, 150, 96), Glow = Color3.fromRGB(190, 255, 150), Chime = 1.5, Cam = 13.5,
		Build = function(model)
			local body, label, gold = Color3.fromRGB(232, 238, 246), Color3.fromRGB(30, 54, 92), Color3.fromRGB(255, 202, 72)
			tilePart(model, "Part", {Size = Vector3.new(1.75, 2.1, 0.42), CFrame = CFrame.new(-0.14, 0.04, 0), Color = body})
			tilePart(model, "Part", {Size = Vector3.new(1.32, 1.06, 0.06), CFrame = CFrame.new(-0.14, 0.32, -0.23), Color = label})
			tilePart(model, "Part", {Size = Vector3.new(0.86, 0.1, 0.06), CFrame = CFrame.new(-0.14, 0.52, -0.27), Color = gold})
			tilePart(model, "Part", {Size = Vector3.new(0.86, 0.1, 0.06), CFrame = CFrame.new(-0.14, 0.26, -0.27), Color = Color3.fromRGB(120, 230, 255)})
			for k = 0, 4 do
				tilePart(model, "Part", {Size = Vector3.new(0.17, 0.3, 0.05), CFrame = CFrame.new(-0.74 + k * 0.3, -0.84, -0.22), Color = gold})
			end
			tilePart(model, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.26, 1.2, 1.2), CFrame = CFrame.new(0.72, -0.56, -0.42) * CFrame.Angles(0, math.pi / 2, 0), Color = Color3.fromRGB(46, 206, 104)})
			tilePart(model, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.42, 1.42), CFrame = CFrame.new(0.72, -0.56, -0.36) * CFrame.Angles(0, math.pi / 2, 0), Color = Color3.new(1, 1, 1)})
			tilePart(model, "Part", {Size = Vector3.new(0.36, 0.17, 0.08), CFrame = CFrame.new(0.56, -0.6, -0.58) * CFrame.Angles(0, 0, -0.8), Color = Color3.new(1, 1, 1)})
			tilePart(model, "Part", {Size = Vector3.new(0.68, 0.17, 0.08), CFrame = CFrame.new(0.82, -0.52, -0.58) * CFrame.Angles(0, 0, 0.8), Color = Color3.new(1, 1, 1)})
		end,
		Animate = function(t, hot)
			return CFrame.new(0, math.sin(t * 1.8) * 0.05, 0) * CFrame.Angles(0.1, math.sin(t * (hot and 2.4 or 1)) * 0.46, -0.08)
		end,
		Burst = function(fx)
			burstRing(fx, Color3.fromRGB(190, 255, 150), 1.5)
			for k = 1, 3 do
				local a = math.rad(-150 + (k - 1) * 60)
				burstGlyph(fx, function(g)
					local c = Color3.fromRGB(120, 255, 130)
					glyphBar(g, 0.3, 0.62, 0.42, 0.2, 45, c, true)
					glyphBar(g, 0.62, 0.48, 0.76, 0.2, -50, c, true)
				end, math.cos(a) * 76, math.sin(a) * 76, 0, 0.58)
			end
			for k = 1, 4 do
				local a = math.rad(-195 + k * 42)
				burstGlyph(fx, function(g)
					local c = Color3.fromRGB(255, 214, 80)
					glyphBar(g, 0.5, 0.5, 0.26, 0.9, 45, c)
					glyphBar(g, 0.5, 0.5, 0.26, 0.9, -45, c)
					glyphBar(g, 0.5, 0.5, 0.2, 0.9, 0, c)
					glyphBar(g, 0.5, 0.5, 0.9, 0.2, 0, c)
				end, math.cos(a) * math.random(46, 64), math.sin(a) * math.random(46, 64), 90, 0.48, 0.3)
			end
			local conf = {Color3.fromRGB(120, 255, 130), Color3.fromRGB(255, 214, 80), Color3.fromRGB(90, 220, 255), Color3.new(1, 1, 1)}
			for k = 1, 12 do
				local a = math.rad(math.random(-210, 30))
				burstBit(fx, Vector2.new(9, 5), conf[k % #conf + 1], math.cos(a) * math.random(45, 78), math.sin(a) * math.random(45, 78) + 10, 300, 0.52)
			end
		end,
	},
}

function UI.tileButton(props)
	local size = props.Size or 112
	local style = TILE_STYLES[props.Style]
	local btn = new("TextButton", {Name = props.Name, Size = UDim2.fromOffset(size, size), Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = props.Parent})
	local pop = new("UIScale", {Parent = btn})
	local face = new("Frame", {Name = "Face", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = btn})
	local function gem(name, scale, y, z)
		return new("Frame", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.41, y), Size = UDim2.fromScale(scale, scale), Rotation = 45, ZIndex = z, Parent = face}, {UI.corner(math.floor(size * scale * 0.2))})
	end
	-- active: a halo round the gem
	local halo = new("Frame", {Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.41), Size = UDim2.fromScale(0.98, 0.98), BackgroundTransparency = 1, ZIndex = 1, Parent = face}, {UI.corner(1, true)})
	local haloStroke = new("UIStroke", {Color = style.Glow, Thickness = 5, Transparency = 1, Parent = halo})
	local shadow = gem("Shadow", 0.72, 8, 2)
	shadow.BackgroundColor3 = UI.BLACK
	shadow.BackgroundTransparency = 0.68
	local base = gem("Base", 0.72, 5, 3)
	local outer = gem("Gem", 0.72, 0, 4)
	outer.BackgroundColor3 = UI.WHITE
	local outerGrad = new("UIGradient", {Rotation = 45, Parent = outer}) -- 45 + the gem's own 45 = top to bottom on screen
	local rim = new("UIStroke", {Color = UI.WHITE, Thickness = 2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = outer})
	-- a lighter facet across the upper half, and a dark sunken centre for the model to stand out of
	local facet = gem("Facet", 0.6, -3, 5)
	facet.BackgroundColor3 = UI.WHITE
	facet.BackgroundTransparency = 0.72
	new("UIGradient", {Rotation = 45, Transparency = NumberSequence.new(0, 1), Parent = facet})
	local well = gem("Well", 0.47, 0, 6)
	well.BackgroundColor3 = UI.WHITE
	local wellGrad = new("UIGradient", {Rotation = 45, Parent = well})
	-- the slow orbit: one bright arc going round the gem
	local orbit = new("Frame", {Name = "Orbit", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.41), Size = UDim2.fromScale(0.62, 0.62), BackgroundTransparency = 1, ZIndex = 7, Parent = face}, {UI.corner(1, true)})
	local orbitStroke = new("UIStroke", {Color = UI.WHITE, Thickness = 2, Parent = orbit})
	new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1)}), Parent = orbitStroke})
	-- the 3D model
	local view = new("ViewportFrame", {Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.39), Size = UDim2.fromScale(0.92, 0.92), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(205, 205, 205), LightColor = UI.WHITE, LightDirection = Vector3.new(-0.5, -1, 0.7), ZIndex = 8, Parent = face})
	local model = Instance.new("Model")
	model.Parent = view
	style.Build(model)
	local cam = new("Camera", {FieldOfView = 28, Parent = view})
	-- far enough back that the whole model, moving, stays inside the gem's diamond
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.2, -(style.Cam or 10.5)), Vector3.new(0, 0, 0))
	view.CurrentCamera = cam
	local parts = {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			parts[p] = p.CFrame
		end
	end
	-- the ribbon: the label bar over the bottom of the gem
	local ribbon = new("Frame", {Name = "Ribbon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.new(1, 0, 0.235, 0), BackgroundColor3 = UI.WHITE, ZIndex = 10, Parent = face}, {UI.corner(math.floor(size * 0.07))})
	local ribbonGrad = new("UIGradient", {Rotation = 90, Parent = ribbon})
	local ribbonRim = new("UIStroke", {Color = UI.WHITE, Thickness = 1.5, Transparency = 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ribbon})
	local text = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -12, 0.74, 0), BackgroundTransparency = 1,
		Text = props.Text or "", TextColor3 = UI.WHITE, TextScaled = true, FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy), ZIndex = 11, Parent = ribbon})
	local textStroke = new("UIStroke", {Color = style.Low:Lerp(UI.BLACK, 0.6), Thickness = 1.4, Transparency = 0.1, Parent = text})
	local badge = new("Frame", {Name = "Badge", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, -2), Size = UDim2.fromOffset(26, 26), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(255, 64, 82), Visible = false, ZIndex = 20, Parent = face},
		{UI.corner(1, true), new("UIStroke", {Color = UI.WHITE, Thickness = 2}), new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}),
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 130, 140), Color3.fromRGB(225, 30, 55))})})
	local badgeText = new("TextLabel", {Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", TextColor3 = UI.WHITE, TextSize = 17,
		FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy), ZIndex = 21, Parent = badge})
	local fx = new("Frame", {Name = "BurstFx", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30, Parent = btn})

	local st = {Hover = false, Down = false, Active = false, Enabled = true, Popping = false}
	local function paint()
		local top, low = style.Top, style.Low
		if not st.Enabled then
			local grey = Color3.fromRGB(120, 120, 130)
			top, low = top:Lerp(grey, 0.75), low:Lerp(grey, 0.75)
		end
		if st.Hover and st.Enabled then
			top, low = top:Lerp(UI.WHITE, 0.1), low:Lerp(UI.WHITE, 0.1)
		end
		outerGrad.Color = ColorSequence.new(top, low)
		base.BackgroundColor3 = low:Lerp(UI.BLACK, 0.5)
		wellGrad.Color = ColorSequence.new(low:Lerp(UI.BLACK, 0.5), low:Lerp(UI.BLACK, 0.2))
		rim.Transparency = st.Active and 0 or 0.25
		rim.Thickness = st.Active and 3 or 2
		ribbonGrad.Color = st.Active and ColorSequence.new(UI.WHITE, style.Glow) or ColorSequence.new(top, low)
		ribbonRim.Transparency = st.Active and 0 or 0.25
		text.TextColor3 = st.Active and low:Lerp(UI.BLACK, 0.5) or UI.WHITE
		textStroke.Transparency = st.Active and 1 or 0.1
		text.TextTransparency = st.Enabled and 0 or 0.35
		local lift = st.Down and 3 or (st.Hover and -3 or 0)
		TweenService:Create(face, TweenInfo.new(st.Down and 0.06 or 0.16, Enum.EasingStyle.Quad), {Position = UDim2.fromOffset(0, lift)}):Play()
		if not st.Popping then
			TweenService:Create(pop, TweenInfo.new(st.Down and 0.06 or 0.2, Enum.EasingStyle.Quad), {Scale = st.Down and 0.9 or 1}):Play()
		end
	end
	paint()
	btn.MouseEnter:Connect(function() st.Hover = true paint() end)
	btn.MouseLeave:Connect(function() st.Hover = false st.Down = false paint() end)
	btn.MouseButton1Down:Connect(function() if st.Enabled then st.Down = true paint() end end)
	btn.MouseButton1Up:Connect(function() st.Down = false paint() end)
	local lastBurst = 0
	-- Activated covers mouse, touch and gamepad alike. Rapid clicks still open and close the window, but only one burst
	-- runs at a time (they last about half a second), so they can never pile up.
	btn.Activated:Connect(function()
		st.Down = false
		lastButtonSfx = os.clock() -- the window it opens plays the sound
		local now = os.clock()
		if st.Enabled and now - lastBurst > 0.45 then
			lastBurst = now
			style.Burst(fx)
			UI.sfx("sparkle", style.Chime)
		end
		st.Popping = true
		pop.Scale = 0.86
		local tw = TweenService:Create(pop, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
		tw:Play()
		tw.Completed:Once(function()
			st.Popping = false
		end)
		paint()
	end)
	RunService.RenderStepped:Connect(function()
		if not UI.shown(btn) then return end
		local t = os.clock()
		local hot = st.Hover or st.Active
		orbit.Rotation = (t * (hot and 110 or 45)) % 360
		local spin = style.Animate(t, hot, model)
		for p, cf in pairs(parts) do
			p.CFrame = spin * cf
		end
		local arrow = model:FindFirstChild("Arrow")
		if arrow then
			arrow:PivotTo(spin * arrow:GetPivot())
		end
		-- the halo breathes while its window is open
		haloStroke.Transparency = st.Active and 0.35 + 0.25 * math.sin(t * 4) or 1
		orbitStroke.Thickness = st.Active and 3 or 2
	end)
	local refs = {Text = text, Badge = badge, BadgeText = badgeText, Face = face}
	function refs.setActive(on)
		st.Active = on
		paint()
	end
	function refs.setEnabled(on)
		st.Enabled = on
		btn.Active = on
		paint()
	end
	return btn, refs
end

-- did a menu button just make its own sound? (then the window it opens doesn't add a second one)
function UI.justClicked()
	return os.clock() - lastButtonSfx < 0.15
end

-- every menu window in the game (UIKit panels and MenuKit windows): one is open at a time
UI.Windows = UI.Windows or {}
function UI.closeOthers(keep)
	for _, w in ipairs(UI.Windows) do
		if w ~= keep and w.Frame.Visible then
			if w.Hide then
				w.Hide(true)
			else
				w.Frame.Visible = false
			end
		end
	end
end

function UI.open(panel)
	UI.closeOthers(panel)
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
	local edge = UI.stroke(color:Lerp(UI.BLACK, 0.55), 2.5)
	local b = new("TextButton", {
		Name = props.Name, Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0, BackgroundColor3 = UI.WHITE, Text = "", AutoButtonColor = false, Parent = props.Parent,
	}, {UI.corner(props.Radius or 14), edge})
	b:SetAttribute("Sfx", "press")
	local grad = UI.gradient(b, color:Lerp(UI.WHITE, 0.25), color:Lerp(UI.BLACK, 0.15), 90)
	-- a soft light across the top half: a rounded, lit surface instead of a flat one
	new("Frame", {Name = "Gloss", Position = UDim2.new(0, 6, 0, 3), Size = UDim2.new(1, -12, 0.42, 0), BackgroundColor3 = UI.WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = b}, {UI.corner(math.max(4, (props.Radius or 14) - 4))})
	local t = UI.label({Position = UDim2.fromScale(0.06, 0.14), Size = UDim2.fromScale(0.88, 0.72), Text = props.Text or "", Parent = b})
	local tEdge = t:FindFirstChildOfClass("UIStroke")
	if tEdge then
		tEdge.Color = color:Lerp(UI.BLACK, 0.7)
		tEdge.Thickness = 2
	end
	UI.bounce(b)
	local function setColor(c)
		grad.Color = ColorSequence.new(c:Lerp(UI.WHITE, 0.25), c:Lerp(UI.BLACK, 0.15))
		edge.Color = c:Lerp(UI.BLACK, 0.55)
		if tEdge then
			tEdge.Color = c:Lerp(UI.BLACK, 0.7)
		end
	end
	return b, t, setColor
end

------------------------------------------------------------------
-- REWARD POP-UPS: every reward reveal lives in RewardFx (queued, with an accent per kind of reward). Required here
-- rather than at the top because RewardFx requires this module.
------------------------------------------------------------------
function UI.popup(_gui, opts)
	require(script.Parent:WaitForChild("RewardFx")).reward(opts)
end

return UI

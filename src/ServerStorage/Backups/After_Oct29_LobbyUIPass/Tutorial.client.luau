--[[
	Tutorial
	A first-time walkthrough for brand-new players:
	  1. A flowing path of glowing chevrons leads from where you stand to the Game Vault
	  2. ...then to a game to steal
	  3. Once you're holding it, the path leads back to YOUR base (found by its owner id, never someone else's)
	  4. A guide card types out how installing, the Index, money and the treadmill work
	  5. Finally it points at the ? button, where help always lives
	The goal always has a marker (name + distance) over it, a light pillar on it, and an arrow at the edge of the
	screen whenever it's off-screen. The card steps aside into a small objective pill while a menu is open.
	Finishing (or skipping) tells the server, so it only ever runs once.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local C = K.C
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local player = Players.LocalPlayer
local new = UI.new
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(255, 212, 92)
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Wait for the save to load; only players who haven't done it yet get the tutorial
while player:GetAttribute("TutorialDone") == nil do
	player:GetAttributeChangedSignal("TutorialDone"):Wait()
end
if player:GetAttribute("TutorialDone") then
	return
end

local map = workspace:WaitForChild("StealAGameMap")
local ENTRANCE = map:GetAttribute("VaultEntrance") or Vector3.new(0, 0, 20)
local HALL_HALF = (map:GetAttribute("HallWidth") or 120) / 2
local gamesFolder = map:WaitForChild("VaultGames")
local bases = map:WaitForChild("Bases")
local playerGui = player:WaitForChild("PlayerGui")
local menuGui = playerGui:WaitForChild("MenuUI")
local baseGui = playerGui:WaitForChild("BaseUI")

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Your base: its front barrier carries your UserId once you own it
local function myPlot()
	for _, plot in ipairs(bases:GetChildren()) do
		local b = plot:FindFirstChild("LaserBarrier")
		if b and b:GetAttribute("OwnerId") == player.UserId then
			return plot, b
		end
	end
end
local function insideMyBase(pos)
	local _, barrier = myPlot()
	if not barrier then return false end
	local lp = barrier.CFrame:PointToObjectSpace(pos)
	return lp.Z > -1 and math.abs(lp.X) < 34
end
local function inVault(pos)
	return math.abs(pos.X) < HALL_HALF and pos.Z > ENTRANCE.Z + 2
end
-- is a menu window (Shop, Index, Pets, Hatchery...) open?
local function menuOpen()
	for _, w in ipairs(UI.Windows or {}) do
		if w.Frame and w.Frame.Visible then
			return true
		end
	end
	return false
end

------------------------------------------------------------------
-- GUIDE CARD: bottom centre, clear of the HUD; fades/slides in, and the text types itself out
------------------------------------------------------------------
local TOTAL = 8
local CARD_W, CARD_H = 600, 178
local gui = new("ScreenGui", {Name = "TutorialUI", ResetOnSpawn = false, DisplayOrder = 15, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local holder = new("Frame", {Name = "Guide", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -64), Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundTransparency = 1, Visible = false, Parent = gui})
local fitScale = new("UIScale", {Parent = holder})
local mover = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder})
new("Frame", {Name = "Shadow", Position = UDim2.fromOffset(0, 8), Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, Parent = mover}, {K.corner(24)})
local card = new("CanvasGroup", {Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = mover}, {K.corner(24)})
-- the background is its own frame: a UIGradient on the CanvasGroup itself would tint everything inside it
new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = card}, {K.corner(24),
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(C.Panel:Lerp(Color3.fromRGB(110, 70, 200), 0.18), C.PanelLow)})})
-- a lit rim drawn just inside the edge (a CanvasGroup would clip an outside stroke)
new("Frame", {Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), BackgroundTransparency = 1, Parent = card}, {K.corner(23), K.stroke(WHITE, 1.5, 0.78)})
local strip = new("Frame", {Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = card})
new("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 190)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 170, 255))}), Parent = strip})

-- the guide's face
local avatar = new("Frame", {Position = UDim2.fromOffset(20, 22), Size = UDim2.fromOffset(66, 66), BackgroundColor3 = WHITE, Parent = card}, {K.corner(), K.stroke(WHITE, 2.5, 0.35)})
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(255, 146, 50)), Parent = avatar})
local avatarFace = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.68, 0.68), BackgroundTransparency = 1, Text = "\u{1F575}\u{FE0F}", TextScaled = true, Parent = avatar})

K.text({Text = "HOW TO STEAL", FontFace = K.TITLE, TextSize = 19, TextColor3 = GOLD, Position = UDim2.fromOffset(102, 16), Size = UDim2.fromOffset(240, 24), Parent = card})
-- progress: one dot per step (done = filled, current = a longer bar)
local dotRow = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 23), Size = UDim2.fromOffset(160, 10), BackgroundTransparency = 1, Parent = card},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})})
local dots = {}
for i = 1, TOTAL do
	dots[i] = new("Frame", {Size = UDim2.fromOffset(8, 8), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, LayoutOrder = i, Parent = dotRow}, {K.corner()})
end
-- the current objective, always in view
local objective = new("Frame", {Position = UDim2.fromOffset(102, 46), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = GOLD, BackgroundTransparency = 0.84, Parent = card},
	{K.corner(), K.stroke(GOLD, 1.25, 0.45), new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14)})})
local objectiveText = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 16, TextColor3 = GOLD:Lerp(WHITE, 0.45), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = objective})
local body = K.text({Text = "", FontFace = K.font(Enum.FontWeight.SemiBold), TextSize = 18, TextColor3 = C.Text2, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromOffset(102, 84), Size = UDim2.fromOffset(CARD_W - 102 - 24, 46), Parent = card})
local skipButton = new("TextButton", {Name = "Skip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -12), Size = UDim2.fromOffset(110, 30), BackgroundColor3 = WHITE, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = card}, {K.corner()})
local skipText = K.text({Text = "Skip tutorial", FontFace = K.font(Enum.FontWeight.Bold), TextSize = 15, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = skipButton})
skipButton.MouseEnter:Connect(function()
	tween(skipButton, 0.12, {BackgroundTransparency = 0.9})
	tween(skipText, 0.12, {TextColor3 = WHITE})
end)
skipButton.MouseLeave:Connect(function()
	tween(skipButton, 0.12, {BackgroundTransparency = 1})
	tween(skipText, 0.12, {TextColor3 = C.Muted})
end)
-- footer right: NEXT for reading steps, how far away the goal is for walking steps
local nextButton = K.button({Text = "Next", Kind = "primary", TextSize = 19, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -16), Size = UDim2.fromOffset(150, 40), ZIndex = 2, Parent = card, Sfx = "press"})
local distText = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Bold), TextSize = 15, TextColor3 = C.Text2, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -14), Size = UDim2.fromOffset(240, 30), Parent = card})

-- the small pill that stands in for the card while a menu is open (in the top bar, clear of every window)
local pill = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.PanelLow, BackgroundTransparency = 0.08, Visible = false, Parent = gui},
	{K.corner(), K.stroke(GOLD, 1.5, 0.35), new("UIPadding", {PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})})
local pillText = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 16, TextColor3 = GOLD:Lerp(WHITE, 0.4), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill})

-- fit to the screen: full size beside the Slow Down switch, or a little smaller and lifted above it on narrow screens
local function refit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local inset = GuiService:GetGuiInset()
	local s = math.min(1.1, (vp.X - 2 * 262) / CARD_W, vp.Y / 720)
	if s >= 0.8 then
		holder.Position = UDim2.new(0.5, 0, 1, -64)
	else
		s = math.clamp((vp.X - 24) / CARD_W, 0.5, 0.9)
		holder.Position = UDim2.new(0.5, 0, 1, -112)
	end
	fitScale.Scale = s
	pill.Position = UDim2.new(0.5, 0, 0, math.max(30, inset.Y / 2))
end
refit()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
end

local currentStep, typing, typeToken = 0, false, 0
local shown = false -- the card is up (not hidden behind a menu)
local finished = false
local function paintDots(n)
	for i, d in ipairs(dots) do
		local on = i == n
		tween(d, 0.25, {Size = UDim2.fromOffset(on and 22 or 8, 8), BackgroundColor3 = i <= n and GOLD or WHITE, BackgroundTransparency = i < n and 0.15 or (on and 0 or 0.8)}, Enum.EasingStyle.Back)
	end
end
local function showCard(on)
	if on == shown or finished then
		return
	end
	shown = on
	if on then
		holder.Visible = true
		card.GroupTransparency = 1
		mover.Position = UDim2.fromOffset(0, 26)
		tween(card, 0.25, {GroupTransparency = 0})
		tween(mover, 0.35, {Position = UDim2.new()}, Enum.EasingStyle.Back)
	else
		tween(card, 0.18, {GroupTransparency = 1})
		local tw = tween(mover, 0.18, {Position = UDim2.fromOffset(0, 26)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Connect(function()
			if not shown then
				holder.Visible = false
			end
		end)
	end
end

-- n = step (1..8), objectiveLine = what to do right now, buttonText = NEXT label (nil on walking steps)
local function say(text, n, objectiveLine, buttonText)
	typeToken += 1
	local my = typeToken
	if n ~= currentStep then
		currentStep = n
		paintDots(n)
	end
	objectiveText.Text = "\u{1F3AF}  " .. objectiveLine
	pillText.Text = "\u{1F3AF}  " .. objectiveLine
	objective.Size = UDim2.fromOffset(0, 30)
	nextButton.Holder.Visible = buttonText ~= nil
	distText.Visible = buttonText == nil
	nextButton.setText(buttonText or "")
	-- a fresh message: the old one slides out, the new one types in
	body.Text = text
	body.MaxVisibleGraphemes = 0
	body.Position = UDim2.fromOffset(110, 84)
	tween(body, 0.22, {Position = UDim2.fromOffset(102, 84)})
	local popIn = new("UIScale", {Scale = 0.85, Parent = objective})
	tween(popIn, 0.3, {Scale = 1}, Enum.EasingStyle.Back).Completed:Connect(function()
		popIn:Destroy()
	end)
	if shown then
		local bump = new("UIScale", {Scale = 0.97, Parent = avatar})
		tween(bump, 0.3, {Scale = 1}, Enum.EasingStyle.Back).Completed:Connect(function()
			bump:Destroy()
		end)
	end
	typing = true
	task.spawn(function()
		-- ~110 letters a second, timed by the clock (one letter per frame was capping it at 30-60), with a soft tick
		-- at most every 0.07s while the card is on screen so the speed never turns into a buzz
		local count = utf8.len(text) or #text
		local startAt, lastTick, i = os.clock(), 0, 0
		while i < count do
			if typeToken ~= my or finished then return end
			local now = os.clock()
			i = math.min(count, math.floor((now - startAt) * 110) + 1)
			body.MaxVisibleGraphemes = i
			if shown and now - lastTick > 0.07 then
				lastTick = now
				UI.sfx("type", 0.92 + math.random() * 0.2)
			end
			RunService.Heartbeat:Wait()
		end
		if typeToken == my then
			body.MaxVisibleGraphemes = -1
			typing = false
		end
	end)
end

------------------------------------------------------------------
-- POINTER: a bouncing hand and a glowing ring around a button on screen
------------------------------------------------------------------
local hand = UI.label({AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(60, 60), Text = "", Outline = false, Visible = false, ZIndex = 20, Parent = gui})
local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 19, Parent = gui}, {UI.corner(20)})
local ringStroke = UI.stroke(GOLD, 5)
ringStroke.Parent = ring
local pointTarget, pointDir -- a GuiObject, and which side the hand sits on ("left", "right" or "below")
local HANDS = {left = "\u{1F449}", right = "\u{1F448}", below = "\u{1F446}"}
local function pointAt(target, dir)
	pointTarget, pointDir = target, dir
	hand.Text = dir and HANDS[dir] or ""
end

------------------------------------------------------------------
-- THE PATH: bold arrows that stream out of your chest and float toward the goal at chest height. Each is a
-- bright chevron laid on a bigger black one (a thick black outline on any background), tilted up to face the
-- camera behind you and bobbing gently. A light tether joins your chest to the first arrow.
------------------------------------------------------------------
local arrowFolder = new("Folder", {Name = "TutorialArrows", Parent = workspace})
local MAX_ARROWS, SPACING = 26, 5
local HIDDEN = CFrame.new(0, -1e4, 0)
local ARROW_YELLOW = Color3.fromRGB(255, 220, 40)
local function arrowPart(color, material, size)
	return new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = material, Color = color,
		Size = size, Transparency = 1, CFrame = HIDDEN, Parent = arrowFolder})
end
local arrows = {}
for i = 1, MAX_ARROWS do
	-- 1, 2: the black outline arms; 3, 4: the bright fill arms
	arrows[i] = {
		arrowPart(BLACK, Enum.Material.SmoothPlastic, Vector3.new(1.3, 0.26, 2.8)),
		arrowPart(BLACK, Enum.Material.SmoothPlastic, Vector3.new(1.3, 0.26, 2.8)),
		arrowPart(ARROW_YELLOW, Enum.Material.Neon, Vector3.new(0.8, 0.34, 2.3)),
		arrowPart(ARROW_YELLOW, Enum.Material.Neon, Vector3.new(0.8, 0.34, 2.3)),
	}
end
-- arms run back from the tip at the origin (the arrow points along -z); each fill sits inside its black shell,
-- poking out of both faces, so the black shows as a rim all round from any side
local ARMS = {
	CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 1.2), CFrame.Angles(0, -math.rad(40), 0) * CFrame.new(0, 0, 1.2),
	CFrame.Angles(0, math.rad(40), 0) * CFrame.new(0, 0, 1.25), CFrame.Angles(0, -math.rad(40), 0) * CFrame.new(0, 0, 1.25),
}
local TILT = CFrame.Angles(math.rad(35), 0, 0) -- tip up, so the face turns toward the camera behind you
local function setArrow(pair, cf, transparency, color)
	for k = 1, 4 do
		pair[k].CFrame = cf * ARMS[k]
		pair[k].Transparency = transparency
	end
	pair[3].Color, pair[4].Color = color, color
end
local function hideArrow(pair)
	for k = 1, 4 do
		pair[k].Transparency = 1
		pair[k].CFrame = HIDDEN
	end
end
-- the tether: a beam from your chest out to where the first arrow floats
local tetherPart = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, Parent = arrowFolder})
local tether0 = new("Attachment", {Parent = tetherPart})
local tether1 = new("Attachment", {Parent = tetherPart})
local tether = new("Beam", {Attachment0 = tether0, Attachment1 = tether1, FaceCamera = true, LightEmission = 1, LightInfluence = 0, Width0 = 0.5, Width1 = 0.9, Segments = 1,
	Color = ColorSequence.new(ARROW_YELLOW), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.05)}), Enabled = false, Parent = tetherPart})

-- THE GOAL: a light pillar and a pulsing ring on the spot, and a marker (name + distance) over it, seen through walls
local beacon = new("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.one, Parent = arrowFolder})
local a0 = new("Attachment", {Parent = beacon})
local a1 = new("Attachment", {Position = Vector3.new(0, 34, 0), Parent = beacon})
local pillar = new("Beam", {Attachment0 = a0, Attachment1 = a1, FaceCamera = true, LightEmission = 1, LightInfluence = 0, Width0 = 3.2, Width1 = 1.2, Segments = 1, Color = ColorSequence.new(GOLD),
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 1)}), Enabled = false, Parent = beacon})
local goalRing = new("Part", {Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = GOLD, Size = Vector3.new(0.15, 7, 7), Transparency = 1, Parent = arrowFolder})

local marker = new("BillboardGui", {Size = UDim2.fromOffset(240, 120), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 2000, Enabled = false, Adornee = beacon, Parent = arrowFolder})
local tag = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.PanelLow, BackgroundTransparency = 0.1, Parent = marker},
	{K.corner(), K.stroke(GOLD, 2, 0.1), new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}),
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
local tagTitle = K.text({Text = "", FontFace = K.TITLE, TextSize = 19, TextColor3 = GOLD, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 1, Parent = tag})
local tagDist = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Bold), TextSize = 15, TextColor3 = C.Text2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, Parent = tag})
-- a solid chevron pointing down at the spot, with a soft glow behind it
local pointer = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, Parent = marker})
local pointerScale = new("UIScale", {Parent = pointer})
new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = GOLD, BackgroundTransparency = 0.78, Parent = pointer}, {K.corner()})
for _, s in ipairs({-1, 1}) do
	-- two thick rounded bars meeting at the bottom: a bold down-chevron with a thick black outline so it reads on
	-- any background (the left bar leans \ and the right one /, so they meet in a V)
	local edge = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, s * 11, 0.5, -2), Size = UDim2.fromOffset(17, 40), Rotation = s * 42, BackgroundColor3 = BLACK, Parent = pointer}, {K.corner()})
	new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundColor3 = WHITE, Parent = edge}, {K.corner(), new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 245, 150), ARROW_YELLOW)})})
end

-- OFF-SCREEN ARROW: at the edge of the screen, pointing at the goal, with how far it is
-- a bright yellow disc with a thick black rim and a black chevron: the highest-contrast thing on screen
local edgeArrow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(62, 62), BackgroundColor3 = WHITE, Visible = false, ZIndex = 5, Parent = gui},
	{K.corner(), K.stroke(BLACK, 4, 0), new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 245, 150), ARROW_YELLOW)})})
-- The guide card and the objective pill sit on the 1440p design canvas (UIKit.canvas), scaled to the screen; the
-- pointer hand, its ring and the edge arrow are placed in screen pixels, so they stay where they are
for _, f in ipairs({hand, ring, edgeArrow}) do
	f:SetAttribute("SelfFit", true)
end
UI.canvas(gui)
local edgeTurn = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Parent = edgeArrow})
local edgeIcon = K.icon(edgeTurn, "right", 26, BLACK, 7)
edgeIcon.Position = UDim2.new(0.5, 3, 0.5, 0) -- the chevron's point sits toward the goal
local edgeDist = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Heavy), TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(90, 18), ZIndex = 6, Parent = edgeArrow})
new("UIStroke", {Color = BLACK, Thickness = 2, Transparency = 0.3, Parent = edgeDist})

local route, goal -- list of points the path leads through, and the goal (nil hides everything)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {map}
local function groundY(x, z, fromY)
	local origin = Vector3.new(x, fromY, z)
	for _ = 1, 4 do
		local hit = workspace:Raycast(origin, Vector3.new(0, -30, 0), rayParams)
		if not hit then return nil end
		if hit.Instance.Transparency < 0.95 then
			return hit.Position.Y
		end
		origin = hit.Position - Vector3.new(0, 0.05, 0) -- skip invisible parts
	end
	return nil
end
local function setRoute(points, goalPos, goalText)
	route, goal = points, points and goalPos or nil
	if goal then
		-- the pillar and ring stand on the ground under the goal
		local y = groundY(goal.X, goal.Z, goal.Y + 6) or (goal.Y - 4)
		beacon.Position = Vector3.new(goal.X, y + 0.1, goal.Z)
		goalRing.CFrame = CFrame.new(goal.X, y + 0.12, goal.Z) * CFrame.Angles(0, 0, math.pi / 2)
		tagTitle.Text = goalText or ""
	end
	marker.Enabled = goal ~= nil
	pillar.Enabled = goal ~= nil
	if not goal then
		goalRing.Transparency = 1
	end
end
local function studs(d)
	return string.format("%d studs", math.floor(d / 5 + 0.5) * 5)
end

local clock = 0
local arrowsShown = false
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local t = clock
	-- the card makes room for any menu: a small objective pill takes its place
	if currentStep > 0 and not finished then
		local menu = menuOpen()
		showCard(not menu)
		pill.Visible = menu
	end
	avatarFace.Rotation = math.sin(t * 2.2) * 6

	-- on-screen pointer
	local target = pointTarget
	if target and UI.shown(target) then
		local inset = GuiService:GetGuiInset()
		local pos, size = target.AbsolutePosition + inset, target.AbsoluteSize
		local center = pos + size / 2
		local bob = math.sin(t * 6) * 8
		local offset = pointDir == "left" and Vector2.new(-size.X / 2 - 40 + bob, 0)
			or pointDir == "right" and Vector2.new(size.X / 2 + 40 - bob, 0)
			or Vector2.new(0, size.Y / 2 + 40 - bob)
		hand.Position = UDim2.fromOffset(center.X + offset.X, center.Y + offset.Y)
		ring.Position = UDim2.fromOffset(center.X, center.Y)
		ring.Size = UDim2.fromOffset(size.X + 14, size.Y + 14)
		ringStroke.Transparency = 0.15 + (math.sin(t * 5) + 1) * 0.25
		hand.Visible, ring.Visible = true, true
	else
		hand.Visible, ring.Visible = false, false
	end

	local root = getRoot()
	local cam = workspace.CurrentCamera
	if not route or not root or not cam then
		edgeArrow.Visible = false
		if arrowsShown then
			arrowsShown = false
			tether.Enabled = false
			for _, pair in ipairs(arrows) do
				hideArrow(pair)
			end
		end
		return
	end
	arrowsShown = true

	-- the goal: bobbing marker, breathing ring, live distance
	local flat = Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)
	local dist = flat.Magnitude
	marker.StudsOffset = Vector3.new(0, 7 + math.sin(t * 3) * 0.6, 0)
	pointer.Position = UDim2.new(0.5, 0, 0, 46 + math.sin(t * 3 + 1) * 4)
	pointerScale.Scale = 1 + (math.sin(t * 4) + 1) * 0.06
	tagDist.Text = studs(dist)
	distText.Text = dist > 6 and (studs(dist) .. " away") or "You're here!"
	local pulse = (math.sin(t * 3) + 1) / 2
	goalRing.Transparency = 0.25 + pulse * 0.4
	goalRing.Size = Vector3.new(0.15, 6.5 + pulse * 1.5, 6.5 + pulse * 1.5)

	-- off-screen: an arrow on the screen's edge points the way
	local sp, onScreen = cam:WorldToViewportPoint(beacon.Position + Vector3.new(0, 7, 0))
	local vp = cam.ViewportSize
	if onScreen and sp.X > 40 and sp.X < vp.X - 40 and sp.Y > 40 and sp.Y < vp.Y - 40 then
		edgeArrow.Visible = false
	else
		local d = Vector2.new(sp.X, sp.Y) - vp / 2
		if sp.Z < 0 then
			d = -d -- behind you: flip so it points the way you need to turn
		end
		if d.Magnitude < 1 then
			d = Vector2.new(0, -1)
		end
		-- it rides a rectangle between the top bar and the guide card, so it never covers either
		local top = GuiService:GetGuiInset().Y + 50
		local bottom = vp.Y - (shown and CARD_H * fitScale.Scale + 110 or 70)
		-- ...and between the HUD's button columns on the left and right
		local left, right = math.min(340, vp.X * 0.25), vp.X - math.min(180, vp.X * 0.14)
		local c = Vector2.new((left + right) / 2, (top + bottom) / 2)
		local hx, hy = (right - left) / 2, math.max(20, (bottom - top) / 2)
		local k = math.min(hx / math.max(math.abs(d.X), 1e-3), hy / math.max(math.abs(d.Y), 1e-3))
		local p = c + d * k
		edgeArrow.Position = UDim2.fromOffset(p.X, p.Y)
		edgeTurn.Rotation = math.deg(math.atan2(d.Y, d.X))
		edgeDist.Text = studs(dist)
		edgeArrow.Visible = true
	end

	-- the path from your chest to the goal (R15's UpperTorso or R6's Torso)
	local char = root.Parent
	local chest = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
	local start = chest.Position + Vector3.new(0, 0.3, 0)
	local fromY = root.Position.Y + 2
	local underYou = groundY(start.X, start.Z, fromY)
	local lift = underYou and math.clamp(start.Y - underYou, 1.5, 6) or 3 -- your chest's height over the ground
	local pts = {Vector3.new(start.X, 0, start.Z)}
	for _, p in ipairs(route) do
		table.insert(pts, Vector3.new(p.X, 0, p.Z))
	end
	local lengths, total = {}, 0
	for i = 1, #pts - 1 do
		lengths[i] = (pts[i + 1] - pts[i]).Magnitude
		total += lengths[i]
	end
	-- where along the path (dd studs from your chest) an arrow floats, and which way the path runs there
	local function along(dd)
		local seg, d = 1, dd
		while seg < #lengths and d > lengths[seg] do
			d -= lengths[seg]
			seg += 1
		end
		local a, b = pts[seg], pts[seg + 1]
		local dir = (b - a).Magnitude > 0.01 and (b - a).Unit or Vector3.new(0, 0, -1)
		local p = a + dir * d
		local y = groundY(p.X, p.Z, fromY)
		-- the first few studs ease out of your chest; after that they ride at chest height over the ground
		local k = math.clamp(dd / 6, 0, 1)
		return y and Vector3.new(p.X, start.Y + (y + lift - start.Y) * k, p.Z), dir, k
	end
	local phase = (t * 6) % SPACING -- the arrows stream forward toward the goal
	local firstPos
	for i, pair in ipairs(arrows) do
		local dd = 1.5 + phase + (i - 1) * SPACING
		local pos, dir, k = nil, nil, 0
		if dd <= total - 3 then
			pos, dir, k = along(dd)
		end
		if not pos then
			hideArrow(pair)
		else
			pos += Vector3.new(0, math.sin(t * 3 - i * 0.8) * 0.3 * k, 0)
			firstPos = firstPos or pos
			-- fade in as they leave you and out near the goal, with a bright wave running toward the goal
			local edge = math.clamp((dd - 1.5) / 2.5, 0, 1) * math.clamp((total - 3 - dd) / 6, 0, 1)
			local wave = (math.sin(t * 5 - i * 0.7) + 1) / 2
			setArrow(pair, CFrame.lookAt(pos, pos + dir) * TILT, 1 - edge * (0.8 + wave * 0.2), ARROW_YELLOW:Lerp(WHITE, wave * 0.35))
		end
	end
	tether.Enabled = firstPos ~= nil
	if firstPos then
		tether0.WorldPosition, tether1.WorldPosition = start, firstPos
	end
end)

------------------------------------------------------------------
-- THE STEPS
------------------------------------------------------------------
local advance = Instance.new("BindableEvent")

local function finish()
	if finished then return end
	typeToken += 1
	setRoute(nil)
	pointAt(nil)
	pill.Visible = false
	showCard(false)
	finished = true
	remotes:WaitForChild("TutorialDone"):FireServer()
	task.delay(0.3, function()
		gui:Destroy()
		arrowFolder:Destroy()
	end)
	advance:Fire()
end
skipButton.Activated:Connect(function()
	UI.sfx("tap")
	finish()
end)
nextButton.Activated:Connect(function()
	if typing then
		-- first tap finishes the sentence, the next one moves on
		typeToken += 1
		body.MaxVisibleGraphemes = -1
		typing = false
	else
		advance:Fire()
	end
end)

-- Show a line with a NEXT button and wait for it (or for `doneWhen` to come true)
local function textStep(text, n, objectiveLine, buttonText, doneWhen)
	if finished then return end
	say(text, n, objectiveLine, buttonText or "Next")
	local done = false
	local conn = advance.Event:Connect(function()
		done = true
	end)
	while not done and not finished do
		if doneWhen and doneWhen() then
			break
		end
		task.wait(0.1)
	end
	conn:Disconnect()
end

local function held()
	return (player:GetAttribute("Held") or 0) > 0
end

-- The nearest game still sitting on a pedestal in the first level
local function nearestVaultGame(from)
	local best, bestD
	for _, item in ipairs(gamesFolder:GetChildren()) do
		if item:IsA("BasePart") and item.Position.Z < ENTRANCE.Z + 200 then
			local d = (item.Position - from).Magnitude
			if not bestD or d < bestD then
				best, bestD = item, d
			end
		end
	end
	return best
end

local VAULT_OUTSIDE = ENTRANCE + Vector3.new(0, 0, -8)
local VAULT_INSIDE = ENTRANCE + Vector3.new(0, 0, 14)

local function runTutorial()
	-- wait until you have a base and a body
	while not (myPlot() and getRoot()) do
		task.wait(0.5)
	end
	-- The daily reward screen goes first: it pops up by itself when a reward is waiting,
	-- so wait for it to appear and then to be closed before starting
	local dailyPanel = menuGui:FindFirstChild("Daily", true) -- on MenuUI's design canvas
	local waited = 0
	while player:GetAttribute("DailyReady") == nil and waited < 20 do
		task.wait(0.25)
		waited += 0.25
	end
	if dailyPanel and player:GetAttribute("DailyReady") == true then
		local t0 = os.clock()
		while not dailyPanel.Visible and os.clock() - t0 < 8 do
			task.wait(0.2)
		end
		while dailyPanel.Visible do
			task.wait(0.2)
		end
	end
	task.wait(0.3)

	-- 1-3: vault, steal, home (repeats if a shopkeeper takes the game back)
	local stage = "vault"
	local said
	local function sayOnce(key, ...)
		if said ~= key then
			said = key
			say(...)
		end
	end
	while not finished and stage ~= "home done" do
		local root = getRoot()
		if root then
			local pos = root.Position
			if stage == "vault" then
				if inVault(pos) then
					stage = "steal"
				elseif held() then
					stage = "home"
				else
					setRoute({VAULT_OUTSIDE, VAULT_INSIDE}, ENTRANCE + Vector3.new(0, 4, 0), "GAME VAULT")
					sayOnce("vault", "Welcome to Steal a Game! Follow the glowing path to the Game Vault.", 1, "Go to the Game Vault")
				end
			elseif stage == "steal" then
				if held() then
					stage = "home"
				else
					local item = nearestVaultGame(pos)
					if item then
						local pts = inVault(pos) and {item.Position} or {VAULT_OUTSIDE, VAULT_INSIDE, item.Position}
						setRoute(pts, item.Position, "STEAL ME!")
					else
						setRoute(nil)
					end
					-- (after "the shopkeeper took it back!" that message stays until you grab another one)
					if said ~= "lost" then
						sayOnce("steal", "Every level has games on pedestals. Walk up to one and hold E to steal it!", 2, "Steal a game: hold E at a pedestal")
					end
				end
			elseif stage == "home" then
				local _, barrier = myPlot()
				if not held() then
					if insideMyBase(pos) then
						stage = "home done"
					else
						stage = "steal"
						said = "lost"
						say("The shopkeeper took it back! Grab another one and run straight home.", 2, "Steal another game")
					end
				elseif barrier then
					local home = (barrier.CFrame * CFrame.new(0, -7, 6)).Position
					local pts = inVault(pos) and {ENTRANCE + Vector3.new(0, 0, -6), home} or {home}
					setRoute(pts, home + Vector3.new(0, 4, 0), "YOUR BASE")
					sayOnce("home", "You got one! Run it back to your base before the shopkeeper catches you!", 3, "Bring it home to your base")
				end
			end
		end
		task.wait(0.15)
	end
	setRoute(nil)

	-- 4: installing
	pointAt(baseGui:FindFirstChild("DOWNLOADS", true), "left")
	textStep("Nice steal! Your game is installing in a case. Games only earn money once installed. DOWNLOADS shows how long is left.", 4, "Check your DOWNLOADS")

	-- 5: the Index (moves on by itself once you claim)
	local indexButton = menuGui:FindFirstChild("INDEX", true)
	local indexPanel = menuGui:FindFirstChild("Index")
	local claimAll = indexPanel and indexPanel:FindFirstChild("ClaimAll", true)
	local function claimedSomething()
		if indexPanel and indexPanel.Visible then
			pointAt(claimAll, "below")
		else
			pointAt(indexButton, "right")
		end
		local ok, state = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("IndexState") or "{}")
		if ok then
			for _, info in pairs(state) do
				if info.C then
					return true
				end
			end
		end
		return false
	end
	textStep("Every new game you find goes in your INDEX. Open it and claim the reward for free cash and speed!", 5, "Open the INDEX and claim", "Next", claimedSomething)

	-- 6: collecting money (path to the cash pad)
	pointAt(nil)
	local plot = myPlot()
	local pad = plot and plot:FindFirstChild("CollectPad")
	if pad then
		setRoute({pad.Position}, pad.Position + Vector3.new(0, 3, 0), "COLLECT CASH")
	end
	textStep("Installed games earn money every second. Step on the green pad in your base to collect it.", 6, "Collect cash at the green pad")

	-- 7: the treadmill (path to it)
	local tread = plot and plot:FindFirstChild("TreadmillAnchor")
	if tread then
		setRoute({tread.Position}, tread.Position + Vector3.new(0, 4, 0), "TREADMILL")
	end
	textStep("Run on your treadmill to get faster. Faster runners escape the shopkeepers deeper in the Vault, where rarer games are!", 7, "Train on your treadmill")
	setRoute(nil)

	-- 8: where to find help
	pointAt(menuGui:FindFirstChild("INFO", true), "below")
	textStep("That's it! If you ever get stuck, press the ? button to see how to play. Happy stealing!", 8, "Press ? anytime for help", "Got it!")
	finish()
end

task.spawn(runTutorial)

--[[
	PetsUI
	The Pet Hatchery shop (scrolls sideways), each egg's info page (silhouettes + odds), the hatching
	show (1 egg or 10 at once, skippable), the MY PETS bag, the PETS button, and the pets that
	follow every player around.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local PetData = require(ReplicatedStorage:WaitForChild("PetData"))
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local petFunc = remotes:WaitForChild("Pets")
local player = Players.LocalPlayer
local new, label, fmt = UI.new, UI.label, UI.fmt
local WHITE, BLACK = UI.WHITE, UI.BLACK
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local gui = new("ScreenGui", {Name = "PetsUI", ResetOnSpawn = false, DisplayOrder = 7, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})
local hatchGui = new("ScreenGui", {Name = "HatchUI", ResetOnSpawn = false, DisplayOrder = 40, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false, Parent = player.PlayerGui})

------------------------------------------------------------------
-- STATE from the server's attributes
------------------------------------------------------------------
local function decode(name, default)
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute(name) or default)
	end)
	return ok and type(t) == "table" and t or HttpService:JSONDecode(default)
end
local discovered = {} -- pet keys you've ever had this session (the info pages show these in colour)
local function owned()
	local list = decode("PetsOwned", "[]")
	for _, p in ipairs(list) do
		discovered[p.K] = true
	end
	return list
end
owned()

------------------------------------------------------------------
-- 3D PICTURES (ViewportFrames)
------------------------------------------------------------------
local spinning = {} -- [viewport] = {Model, Speed, Base}
local function viewport(parent, model, props)
	local vp = new("ViewportFrame", {
		BackgroundTransparency = 1, Ambient = rgb(200, 200, 210), LightColor = WHITE, LightDirection = Vector3.new(0.4, -1, 0.8),
		Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, ZIndex = props.ZIndex or 2, Parent = parent,
	})
	model.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local cf, size = model:GetBoundingBox()
	local r = math.max(size.X, size.Y, size.Z)
	local dist = r / (2 * math.tan(math.rad(15))) * (props.Zoom or 1.05)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.3, dist * 0.2, -dist), cf.Position)
	if props.Spin then
		spinning[vp] = {Model = model, Speed = props.Spin, Angle = math.random() * 6}
	end
	if props.Silhouette then
		vp.ImageColor3 = rgb(15, 12, 25)
	end
	return vp
end
RunService.RenderStepped:Connect(function(dt)
	for vp, s in pairs(spinning) do
		if not vp.Parent then
			spinning[vp] = nil
		elseif vp.Visible and UI.shown(vp) then
			s.Angle += dt * s.Speed
			s.Model:PivotTo(CFrame.Angles(0, math.sin(s.Angle) * 0.6, 0))
		end
	end
end)

-- light rays turning behind a picture (rarity coloured)
local raySets = {}
local function rays(parent, color, size, count)
	local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size, BackgroundTransparency = 1, ZIndex = 1, Parent = parent})
	for i = 0, (count or 6) - 1 do
		local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.12, 0, 1, 0), Rotation = i * 180 / (count or 6), BackgroundColor3 = color, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 1, Parent = f}, {UI.corner(1, true)})
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
	end
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = color:Lerp(WHITE, 0.4), BackgroundTransparency = 0.7, ZIndex = 1, Parent = f}, {UI.corner(1, true)})
	raySets[f] = {Speed = 25}
	return f, glow
end
RunService.RenderStepped:Connect(function(dt)
	for f, s in pairs(raySets) do
		if not f.Parent then
			raySets[f] = nil
		elseif UI.shown(f) then
			f.Rotation = (f.Rotation + dt * s.Speed) % 360
		end
	end
end)

local function rarityOf(pet)
	return PetData.RARITIES[pet.R]
end

-- stars bursting out from the middle of a frame
local function starBurst(parent, color, count, dist)
	for _ = 1, count do
		local star = label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), Text = "\u{2726}", TextColor3 = math.random() < 0.5 and WHITE or color:Lerp(WHITE, 0.3), Outline = false, ZIndex = 30, Parent = parent})
		local ang = math.random() * math.pi * 2
		local d = math.random(60, dist or 260)
		tween(star, 0.9, {Position = UDim2.new(0.5, math.cos(ang) * d, 0.5, math.sin(ang) * d), Rotation = math.random(-200, 200), TextTransparency = 1})
		task.delay(0.95, star.Destroy, star)
	end
end

------------------------------------------------------------------
-- THE PET HATCHERY SHOP (scrolls sideways)
------------------------------------------------------------------
local PINK = rgb(255, 130, 200)
local shop = UI.panel(gui, {Name = "Hatchery", Title = "PET HATCHERY", Icon = "\u{1F95A}", Color = PINK, MaxSize = Vector2.new(1180, 600), Size = UDim2.fromScale(0.92, 0.8)})
local shopMsg = label({Position = UDim2.fromOffset(20, 6), Size = UDim2.new(0.62, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, Text = "", Outline = 2, Parent = shop.Body})
local function setShopMsg(text, color)
	shopMsg.Text = text
	shopMsg.TextColor3 = color or WHITE
end
local function defaultMsg()
	setShopMsg(string.format("Pets make your games install faster!  Your pets: <font color=\"#7dff8c\">+%s%%</font> install speed", fmt(player:GetAttribute("PetBoost") or 0)), WHITE)
end
player:GetAttributeChangedSignal("PetBoost"):Connect(defaultMsg)
defaultMsg()

local skipAnim = false
local skipBtn, skipText, skipColor = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 2), Size = UDim2.fromOffset(240, 34), Text = "SKIP ANIMATION: OFF", Parent = shop.Body}, rgb(110, 100, 140))
skipBtn.Activated:Connect(function()
	skipAnim = not skipAnim
	skipText.Text = skipAnim and "SKIP ANIMATION: ON" or "SKIP ANIMATION: OFF"
	skipColor(skipAnim and UI.GREEN or rgb(110, 100, 140))
end)

local strip = new("ScrollingFrame", {
	Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 1, -54), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
	ScrollBarThickness = 10, ScrollBarImageColor3 = WHITE, Parent = shop.Body,
})
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip})
new("UIPadding", {PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 40), PaddingBottom = UDim.new(0, 12), Parent = strip})
-- the mouse wheel scrolls it sideways too
local function nudge(px)
	local maxX = math.max(0, strip.AbsoluteCanvasSize.X - strip.AbsoluteWindowSize.X)
	tween(strip, 0.25, {CanvasPosition = Vector2.new(math.clamp(strip.CanvasPosition.X + px, 0, maxX), 0)})
end
strip.MouseWheelForward:Connect(function() nudge(-260) end)
strip.MouseWheelBackward:Connect(function() nudge(260) end)
for _, side in ipairs({-1, 1}) do
	local b = new("TextButton", {AnchorPoint = Vector2.new(side == -1 and 0 or 1, 0.5), Position = UDim2.new(side == -1 and 0 or 1, side == -1 and 6 or -6, 0.5, 20), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, ZIndex = 20, Parent = shop.Body}, {UI.corner(1, true), UI.stroke(BLACK, 3)})
	UI.gradient(b, rgb(255, 180, 230), rgb(220, 70, 160), 90)
	label({Size = UDim2.fromScale(1, 1), Text = side == -1 and "\u{25C0}" or "\u{25B6}", Outline = 2.5, ZIndex = 21, Parent = b})
	UI.bounce(b)
	b.Activated:Connect(function()
		nudge(side * 520)
	end)
end

local hatching = false
local hatch -- defined below
local openInfo -- defined below
local priceLabels = {}

local function buy(egg, count)
	if hatching then return end
	local ok, res = petFunc:InvokeServer("buy", egg.Index, count)
	if not ok then
		setShopMsg(tostring(res), rgb(255, 130, 130))
		task.delay(2.5, defaultMsg)
		return
	end
	hatch(egg, res)
end

for i, egg in ipairs(PetData.EGGS) do
	local card = new("Frame", {LayoutOrder = i, Size = UDim2.new(0, 232, 1, -14), BackgroundColor3 = WHITE, Parent = strip}, {UI.corner(20), UI.stroke(BLACK, 4)})
	UI.gradient(card, egg.Color:Lerp(WHITE, 0.35), egg.Color:Lerp(BLACK, 0.45), 90)
	UI.sparkles(card, 0.8)
	-- the egg on a glowing nest, turning gently
	local stage = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(200, 210), BackgroundTransparency = 1, Parent = card})
	rays(stage, egg.Spot, UDim2.fromScale(1.05, 1.05), 6)
	new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(150, 34), BackgroundColor3 = rgb(150, 100, 60), ZIndex = 1, Parent = stage}, {UI.corner(1, true), UI.stroke(BLACK, 2.5)})
	local eggVp = viewport(stage, PetModels.egg(egg), {Size = UDim2.fromScale(1, 1), Spin = 1.2, Zoom = 1.15})
	local eggScale = new("UIScale", {Parent = eggVp})
	card.MouseEnter:Connect(function()
		tween(eggScale, 0.2, {Scale = 1.08}, Enum.EasingStyle.Back)
	end)
	card.MouseLeave:Connect(function()
		eggScale.Scale = 1
	end)
	label({Position = UDim2.new(0, 8, 0, 222), Size = UDim2.new(1, -16, 0, 34), Text = egg.Name, Outline = 3, Parent = card})
	local price = label({Position = UDim2.new(0, 8, 0, 258), Size = UDim2.new(1, -16, 0, 28), Text = "$" .. fmt(egg.Price), TextColor3 = rgb(255, 235, 120), Outline = 2.5, Parent = card})
	priceLabels[price] = egg
	label({Position = UDim2.new(0, 8, 0, 288), Size = UDim2.new(1, -16, 0, 18), Font = Enum.Font.GothamBold, Text = string.format('Up to <font color="#1effe1">+%d%%</font> install speed', egg.Pets[7].Boost), Outline = 2, Parent = card})
	local b1 = UI.actionButton({AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(0.5, -14, 0, 52), Text = "BUY 1", Parent = card}, UI.GREEN)
	local b10 = UI.actionButton({AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10), Size = UDim2.new(0.5, -14, 0, 52), Text = "BUY 10", Parent = card}, UI.PURPLE)
	label({AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -64), Size = UDim2.new(0.5, -14, 0, 16), Font = Enum.Font.GothamBold, Text = "$" .. fmt(egg.Price * PetData.HATCH_MANY), TextColor3 = rgb(230, 210, 255), Outline = 1.5, Parent = card})
	b1.Activated:Connect(function() buy(egg, 1) end)
	b10.Activated:Connect(function() buy(egg, PetData.HATCH_MANY) end)
	-- the (i) button: what's inside this egg
	local info = new("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = card}, {UI.corner(1, true), UI.stroke(BLACK, 3)})
	UI.gradient(info, rgb(140, 210, 255), rgb(40, 120, 230), 90)
	label({Size = UDim2.fromScale(1, 1), Text = "i", Outline = 2.5, ZIndex = 11, Parent = info})
	UI.bounce(info)
	info.Activated:Connect(function()
		openInfo(egg)
	end)
end
-- price turns red when you can't afford it
local function refreshPrices()
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
	for lbl, egg in pairs(priceLabels) do
		lbl.TextColor3 = cash >= egg.Price and rgb(255, 235, 120) or rgb(255, 120, 120)
	end
end
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 30)
	local cash = ls and ls:WaitForChild("Cash", 30)
	if cash then
		cash.Changed:Connect(refreshPrices)
		refreshPrices()
	end
end)

------------------------------------------------------------------
-- EGG INFO: silhouettes of everything inside, with the odds
------------------------------------------------------------------
local infoPage = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(30, 24, 50), BackgroundTransparency = 0.05, Visible = false, ZIndex = 50, Parent = shop.Body}, {UI.corner(18)})
local infoTitle = label({Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -200, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 3, ZIndex = 51, Parent = infoPage})
local infoBack = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 8), Size = UDim2.fromOffset(150, 40), Text = "\u{25C0} BACK", Parent = infoPage}, UI.RED)
infoBack.ZIndex = 52
for _, d in ipairs(infoBack:GetDescendants()) do
	if d:IsA("GuiObject") then
		d.ZIndex = 53
	end
end
infoBack.Activated:Connect(function()
	infoPage.Visible = false
end)
local infoRow = new("Frame", {Position = UDim2.fromOffset(16, 56), Size = UDim2.new(1, -32, 1, -66), BackgroundTransparency = 1, ZIndex = 51, Parent = infoPage},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center})})
openInfo = function(egg)
	infoTitle.Text = egg.Name .. "  <font color=\"#c8c3e6\">- what could hatch</font>"
	for _, c in ipairs(infoRow:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	owned()
	for r, pet in ipairs(egg.Pets) do
		local rar = PetData.RARITIES[r]
		local known = discovered[pet.Key]
		local card = new("Frame", {Size = UDim2.new(1 / 7, -9, 0.92, 0), BackgroundColor3 = WHITE, ZIndex = 51, Parent = infoRow}, {UI.corner(14), UI.stroke(BLACK, 3)})
		UI.gradient(card, rar.Color:Lerp(BLACK, 0.25), rar.Color:Lerp(BLACK, 0.7), 90)
		local pic = new("Frame", {Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.9, 0.5), BackgroundTransparency = 1, ZIndex = 52, Parent = card})
		if known then
			rays(pic, rar.Color, UDim2.fromScale(1, 1), 4)
		end
		local vp = viewport(pic, PetModels.build(pet), {Size = UDim2.fromScale(1, 1), Silhouette = not known, Spin = known and 1 or nil, ZIndex = 53})
		if not known then
			label({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.35, 0.35), Text = "?", TextColor3 = rgb(200, 195, 230), Outline = 2.5, ZIndex = 54, Parent = vp})
		end
		label({Position = UDim2.fromScale(0.04, 0.55), Size = UDim2.fromScale(0.92, 0.11), Text = known and pet.N or "???", Outline = 2.5, ZIndex = 52, Parent = card})
		label({Position = UDim2.fromScale(0.04, 0.67), Size = UDim2.fromScale(0.92, 0.08), Text = string.upper(rar.Name), TextColor3 = rar.Color:Lerp(WHITE, 0.35), Outline = 2, ZIndex = 52, Parent = card})
		label({Position = UDim2.fromScale(0.04, 0.77), Size = UDim2.fromScale(0.92, 0.1), Text = PetData.oddsText(egg.Odds[r]), TextColor3 = rgb(255, 235, 120), Outline = 2.5, ZIndex = 52, Parent = card})
		label({Position = UDim2.fromScale(0.04, 0.88), Size = UDim2.fromScale(0.92, 0.08), Font = Enum.Font.GothamBold, Text = "+" .. pet.Boost .. "% speed", TextColor3 = rgb(130, 255, 150), Outline = 2, ZIndex = 52, Parent = card})
	end
	infoPage.Visible = true
	UI.sfx("pop", 1.1)
end

------------------------------------------------------------------
-- HATCHING
------------------------------------------------------------------
local backdrop = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(10, 5, 25), BackgroundTransparency = 1, Parent = hatchGui})
local stageArea = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = hatchGui})
local skipNow = false
local quiet = false -- rebuilding a grid you've already seen: no sounds
local function sfx(name, pitch)
	if not quiet then
		UI.sfx(name, pitch)
	end
end
local skipHatch = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 150), Size = UDim2.fromOffset(170, 50), Text = "SKIP \u{25B6}\u{25B6}", Parent = hatchGui}, rgb(110, 100, 140))
skipHatch.ZIndex = 40
for _, d in ipairs(skipHatch:GetDescendants()) do
	if d:IsA("GuiObject") then
		d.ZIndex = 41
	end
end
skipHatch.Activated:Connect(function()
	skipNow = true
end)
local function clearStage()
	for _, c in ipairs(stageArea:GetChildren()) do
		c:Destroy()
	end
end
local function waitOrSkip(t)
	local t0 = os.clock()
	while os.clock() - t0 < t and not skipNow do
		task.wait()
	end
end

-- one egg (or a cell of the 10-egg grid): wobble, crack, burst, reveal
local function eggCell(parent, egg, size, pos)
	local cell = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = 3, Parent = parent})
	local eggVp = viewport(cell, PetModels.egg(egg), {Size = UDim2.fromScale(1, 1), Zoom = 1.1, ZIndex = 5})
	local eggScale = new("UIScale", {Parent = eggVp})
	return {Cell = cell, Egg = eggVp, EggScale = eggScale}
end

local function reveal(c, pet, big)
	local rar = rarityOf(pet)
	c.Egg.Visible = false
	-- a white flash where the egg was
	local flash = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 0.2), BackgroundColor3 = WHITE, ZIndex = 20, Parent = c.Cell}, {UI.corner(1, true)})
	tween(flash, 0.45, {Size = UDim2.fromScale(big and 2.6 or 1.8, big and 2.6 or 1.8), BackgroundTransparency = 1})
	task.delay(0.5, flash.Destroy, flash)
	local r, glow = rays(c.Cell, rar.Color, UDim2.fromScale(big and 1.9 or 1.4, big and 1.9 or 1.4), pet.R >= 5 and 10 or 6)
	raySets[r].Speed = 20 + pet.R * 8
	local petVp = viewport(c.Cell, PetModels.build(pet), {Size = UDim2.fromScale(1, 1), Spin = 1.3, ZIndex = 6})
	local s = new("UIScale", {Scale = 0, Parent = petVp})
	tween(s, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
	petVp.Rotation = -20
	tween(petVp, 0.5, {Rotation = 0}, Enum.EasingStyle.Back)
	starBurst(c.Cell, rar.Color, big and (8 + pet.R * 4) or (3 + pet.R), big and 320 or 120)
	c.Pet = petVp
	c.Glow = glow
	return rar
end

local function nameplate(parent, pet, y, scale)
	local rar = rarityOf(pet)
	local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, y, 0), Size = UDim2.fromOffset(560 * scale, 140 * scale), BackgroundTransparency = 1, ZIndex = 25, Parent = parent})
	local nm = label({Size = UDim2.fromScale(1, 0.45), Text = pet.N, Outline = 4 * scale, ZIndex = 26, Parent = holder})
	UI.gradient(nm, rar.Color:Lerp(WHITE, 0.6), rar.Color, 90)
	label({Position = UDim2.fromScale(0, 0.47), Size = UDim2.fromScale(1, 0.25), Text = string.upper(rar.Name), TextColor3 = rar.Color:Lerp(WHITE, 0.3), Outline = 3 * scale, ZIndex = 26, Parent = holder})
	label({Position = UDim2.fromScale(0, 0.74), Size = UDim2.fromScale(1, 0.24), Font = Enum.Font.GothamBold, Text = "+" .. pet.Boost .. "% install speed", TextColor3 = rgb(130, 255, 150), Outline = 2.5 * scale, ZIndex = 26, Parent = holder})
	local sc = new("UIScale", {Scale = 0.3, Parent = holder})
	tween(sc, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
	return holder
end

local function rarityJingle(best)
	if quiet then
		return
	elseif best >= 5 then
		UI.sfx("hatchlegend")
	elseif best >= 3 then
		UI.sfx("hatchrare")
	else
		UI.claimSfx()
	end
end

-- shake the egg(s) faster and harder, one knock per wobble
local function wobble(cells)
	for k = 1, 9 do
		if skipNow then return end
		local ang = (k % 2 == 0 and 1 or -1) * (5 + k * 1.8)
		local t = 0.16 - k * 0.011
		for _, c in ipairs(cells) do
			tween(c.Egg, t, {Rotation = ang * (0.8 + math.random() * 0.4)}, Enum.EasingStyle.Sine)
			c.EggScale.Scale = 1 + k * 0.012
		end
		sfx("eggknock", 1 + k * 0.05)
		waitOrSkip(t + 0.04)
	end
end

local StarterGui = game:GetService("StarterGui")
local function setHotbar(on)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, on)
	end)
end

local function finish()
	setHotbar(true)
	clearStage()
	tween(backdrop, 0.25, {BackgroundTransparency = 1})
	task.wait(0.25)
	hatchGui.Enabled = false
	hatching = false
	shop.Frame.Visible = true
	defaultMsg()
end

-- a big close-up of one pet, with arrows to flip through a batch
local function closeUp(egg, results, index, onBack)
	clearStage()
	local pet = PetData.PETS[results[index].K]
	local c = {Cell = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 1, ZIndex = 3, Parent = stageArea}), Egg = new("Frame", {Parent = stageArea, Visible = false})}
	reveal(c, pet, true)
	nameplate(stageArea, pet, 0.64, 1)
	if #results > 1 then
		label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.06, 0), Size = UDim2.fromOffset(300, 34), Text = index .. " / " .. #results, Outline = 3, ZIndex = 26, Parent = stageArea})
		for _, dir in ipairs({-1, 1}) do
			local b = UI.actionButton({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, dir * 260, 0.4, 0), Size = UDim2.fromOffset(70, 70), Text = dir == -1 and "\u{25C0}" or "\u{25B6}", Parent = stageArea, Radius = 35}, PINK)
			b.ZIndex = 30
			b.Activated:Connect(function()
				closeUp(egg, results, (index - 1 + dir) % #results + 1, onBack)
			end)
		end
	end
	local back = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(240, 60), Text = #results > 1 and "\u{25C0} ALL PETS" or "AWESOME!", Parent = stageArea}, UI.GREEN)
	back.ZIndex = 30
	back.Activated:Connect(onBack)
end

hatch = function(egg, results, instant)
	hatching = true
	skipNow = skipAnim or instant == true
	quiet = instant == true
	shop.Frame.Visible = false
	infoPage.Visible = false
	clearStage()
	hatchGui.Enabled = true
	setHotbar(false) -- the tool bar sat over the buttons
	skipHatch.Visible = not skipNow
	tween(backdrop, 0.3, {BackgroundTransparency = 0.12})
	local best = 1
	for _, res in ipairs(results) do
		best = math.max(best, PetData.PETS[res.K].R)
		discovered[res.K] = true
	end
	if #results == 1 then
		local pet = PetData.PETS[results[1].K]
		local c = eggCell(stageArea, egg, UDim2.fromOffset(300, 340), UDim2.fromScale(0.5, 0.42))
		if not skipNow then
			c.EggScale.Scale = 0.4
			tween(c.EggScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			waitOrSkip(0.4)
		end
		wobble({c})
		sfx("eggcrack")
		waitOrSkip(0.15)
		skipHatch.Visible = false
		sfx("hatch")
		reveal(c, pet, true)
		nameplate(stageArea, pet, 0.66, 1)
		rarityJingle(best)
		if pet.R >= 5 then
			-- a little screen shake for the big ones
			task.spawn(function()
				for k = 1, 8 do
					stageArea.Position = UDim2.fromOffset(math.random(-8, 8), math.random(-8, 8))
					task.wait(0.03)
				end
				stageArea.Position = UDim2.new()
			end)
		end
		local ok = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(240, 60), Text = "AWESOME!", Parent = stageArea}, UI.GREEN)
		ok.ZIndex = 30
		ok.Activated:Connect(finish)
		return
	end
	-- TEN EGGS at once, all over the screen
	local cells = {}
	local cols = 5
	for i = 1, #results do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local pos = UDim2.new(0.5, (col - (cols - 1) / 2) * 190, 0.38 + row * 0.33, 0)
		cells[i] = eggCell(stageArea, egg, UDim2.fromOffset(160, 180), pos)
		if not skipNow then
			cells[i].EggScale.Scale = 0
			tween(cells[i].EggScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			waitOrSkip(0.05)
		end
	end
	waitOrSkip(0.3)
	wobble(cells)
	sfx("eggcrack")
	waitOrSkip(0.15)
	skipHatch.Visible = false
	sfx("hatch")
	for i, c in ipairs(cells) do
		local pet = PetData.PETS[results[i].K]
		reveal(c, pet, false)
		label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, 20, 0, 24), Text = pet.N, TextColor3 = rarityOf(pet).Color:Lerp(WHITE, 0.4), Outline = 2.5, ZIndex = 26, Parent = c.Cell})
		-- each pet can be clicked for a closer look
		local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 28, Parent = c.Cell})
		hit.Activated:Connect(function()
			local function back()
				-- back to the grid, already hatched
				clearStage()
				hatch(egg, results, true)
			end
			closeUp(egg, results, i, back)
		end)
		if not skipNow then
			task.wait(0.06)
		end
	end
	rarityJingle(best)
	label({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.06, 0), Size = UDim2.fromOffset(620, 40), Text = "Click a pet to see it up close!", Outline = 3, ZIndex = 26, Parent = stageArea})
	local close = UI.actionButton({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(240, 58), Text = "CLOSE", Parent = stageArea}, UI.RED)
	close.ZIndex = 30
	close.Activated:Connect(finish)
end

remotes:WaitForChild("OpenHatchery").OnClientEvent:Connect(function()
	if hatching or shop.Frame.Visible then return end
	infoPage.Visible = false
	defaultMsg()
	refreshPrices()
	UI.open(shop)
end)

------------------------------------------------------------------
-- MY PETS (pets of the same kind stack together)
------------------------------------------------------------------
local bag = UI.panel(gui, {Name = "MyPets", Title = "MY PETS", Icon = "\u{1F43E}", Color = rgb(255, 160, 60), MaxSize = Vector2.new(940, 640), Size = UDim2.fromScale(0.7, 0.82)})
local bagStats = label({Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -260, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 2.5, Parent = bag.Body})
local bestBtn = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 2), Size = UDim2.fromOffset(200, 40), Text = "EQUIP BEST", Parent = bag.Body}, UI.GREEN)
bestBtn.Activated:Connect(function()
	petFunc:InvokeServer("best")
end)
local bagHint = label({Position = UDim2.fromOffset(20, 36), Size = UDim2.new(1, -260, 0, 18), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rgb(210, 205, 235), Text = "Hatch more at the Pet Hatchery next to the Trail Shop!", Outline = 1.5, Parent = bag.Body})
local bagGrid = UI.scroller(bag.Body, UDim2.fromOffset(14, 62), UDim2.new(1, -28, 1, -72))
new("UIGridLayout", {CellSize = UDim2.fromOffset(158, 222), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bagGrid})
new("UIPadding", {PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = bagGrid})
local bagCards = {}

local function stacks()
	local list = owned()
	local eq = {}
	for _, id in ipairs(decode("PetsEquipped", "[]")) do
		eq[id] = true
	end
	local byKey = {}
	for _, p in ipairs(list) do
		local s = byKey[p.K]
		if not s then
			s = {Key = p.K, Ids = {}, Equipped = {}, Free = {}}
			byKey[p.K] = s
		end
		table.insert(s.Ids, p.I)
		table.insert(eq[p.I] and s.Equipped or s.Free, p.I)
	end
	return byKey, #list
end

local function refreshBag()
	local byKey, count = stacks()
	bagStats.Text = string.format('<font color="#7dff8c">+%s%%</font> install speed   \u{2022}   %d / %d out   \u{2022}   %d / %d pets', fmt(player:GetAttribute("PetBoost") or 0), #decode("PetsEquipped", "[]"), PetData.EQUIP_MAX, count, PetData.MAX_PETS)
	for key, card in pairs(bagCards) do
		if not byKey[key] then
			card.Frame:Destroy()
			bagCards[key] = nil
		end
	end
	for key, s in pairs(byKey) do
		local pet = PetData.PETS[key]
		local rar = rarityOf(pet)
		local card = bagCards[key]
		if not card then
			local f = new("Frame", {BackgroundColor3 = WHITE, Parent = bagGrid}, {UI.corner(14), UI.stroke(BLACK, 3)})
			UI.gradient(f, rar.Color:Lerp(BLACK, 0.2), rar.Color:Lerp(BLACK, 0.7), 90)
			local pic = new("Frame", {Position = UDim2.fromOffset(9, 6), Size = UDim2.fromOffset(140, 112), BackgroundTransparency = 1, Parent = f})
			rays(pic, rar.Color, UDim2.fromScale(1, 1.2), 4)
			viewport(pic, PetModels.build(pet), {Size = UDim2.fromScale(1, 1), Spin = 0.8, ZIndex = 3})
			label({Position = UDim2.fromOffset(6, 118), Size = UDim2.new(1, -12, 0, 24), Text = pet.N, Outline = 2.5, Parent = f})
			label({Position = UDim2.fromOffset(6, 142), Size = UDim2.new(1, -12, 0, 16), Text = string.upper(rar.Name) .. "  \u{2022}  +" .. pet.Boost .. "%", TextColor3 = rar.Color:Lerp(WHITE, 0.4), Outline = 2, Parent = f})
			local countLbl = label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(50, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Right, Outline = 2.5, ZIndex = 5, Parent = f})
			local eqBadge = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = UI.GREEN, ZIndex = 5, Visible = false, Parent = f}, {UI.corner(1, true), UI.stroke(BLACK, 2.5)})
			label({Size = UDim2.fromScale(1, 1), Text = "\u{2713}", Outline = 2, ZIndex = 6, Parent = eqBadge})
			local eqB, eqT, eqC = UI.actionButton({Position = UDim2.fromOffset(6, 164), Size = UDim2.new(1, -52, 0, 50), Text = "EQUIP", Parent = f}, UI.GREEN)
			local del, delT, delC = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 164), Size = UDim2.fromOffset(40, 50), Text = "X", Parent = f}, UI.RED)
			card = {Frame = f, Count = countLbl, Badge = eqBadge, EqText = eqT, EqColor = eqC, DelText = delT, DelColor = delC, Sure = 0}
			bagCards[key] = card
			eqB.Activated:Connect(function()
				local st = card.Stack
				if #st.Free > 0 then
					local ok, msg = petFunc:InvokeServer("equip", st.Free[1])
					if not ok then
						bagHint.Text = msg
						bagHint.TextColor3 = rgb(255, 140, 140)
					end
				elseif #st.Equipped > 0 then
					petFunc:InvokeServer("unequip", st.Equipped[1])
				end
			end)
			del.Activated:Connect(function()
				-- tap twice to delete (so you never lose a pet by accident)
				local st = card.Stack
				if os.clock() - card.Sure > 2.5 then
					card.Sure = os.clock()
					delT.Text = "?"
					task.delay(2.5, function()
						delT.Text = "X"
					end)
					return
				end
				card.Sure = 0
				delT.Text = "X"
				local id = st.Free[1] or st.Equipped[1]
				if id then
					petFunc:InvokeServer("delete", id)
				end
			end)
		end
		card.Stack = s
		card.Count.Text = #s.Ids > 1 and ("x" .. #s.Ids) or ""
		card.Badge.Visible = #s.Equipped > 0
		local canEquip = #s.Free > 0
		card.EqText.Text = canEquip and (#s.Equipped > 0 and "EQUIP +1" or "EQUIP") or "UNEQUIP"
		card.EqColor(canEquip and UI.GREEN or rgb(230, 140, 40))
		-- equipped first, then the strongest
		card.Frame.LayoutOrder = (#s.Equipped > 0 and 0 or 100000) - pet.Boost
	end
end
player:GetAttributeChangedSignal("PetsOwned"):Connect(function()
	if bag.Frame.Visible then
		refreshBag()
	end
end)
player:GetAttributeChangedSignal("PetsEquipped"):Connect(function()
	if bag.Frame.Visible then
		refreshBag()
	end
end)

------------------------------------------------------------------
-- PETS button: above DOWNLOADS, only once you own a pet (with a "!" the first time)
------------------------------------------------------------------
local petsBtn, petsRefs = UI.fancyButton({Name = "PETS", Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 0.5, -152), Size = UDim2.fromOffset(128, 104), Color = rgb(255, 150, 60), Icon = "\u{1F43E}", Text = "PETS", SparkleEvery = 0.5})
petsBtn.Visible = false
petsRefs.BadgeText.Text = "!"
local function refreshButton()
	local count = #owned()
	petsBtn.Visible = count > 0
	petsRefs.Badge.Visible = count > 0 and not player:GetAttribute("PetsSeen")
end
player:GetAttributeChangedSignal("PetsOwned"):Connect(refreshButton)
player:GetAttributeChangedSignal("PetsSeen"):Connect(refreshButton)
refreshButton()
-- the badge bounces so you notice it
task.spawn(function()
	local s = new("UIScale", {Parent = petsRefs.Badge})
	while true do
		if petsRefs.Badge.Visible then
			tween(s, 0.3, {Scale = 1.3}, Enum.EasingStyle.Sine)
			task.wait(0.3)
			tween(s, 0.3, {Scale = 1}, Enum.EasingStyle.Sine)
		end
		task.wait(0.4)
	end
end)
petsBtn.Activated:Connect(function()
	if bag.Frame.Visible then
		bag.Frame.Visible = false
		return
	end
	if not player:GetAttribute("PetsSeen") then
		task.spawn(petFunc.InvokeServer, petFunc, "seen")
	end
	bagHint.Text = "Hatch more at the Pet Hatchery next to the Trail Shop!"
	bagHint.TextColor3 = rgb(210, 205, 235)
	refreshBag()
	UI.open(bag)
end)

------------------------------------------------------------------
-- PETS IN THE WORLD: everyone's equipped pets follow them around
------------------------------------------------------------------
local petFolder = Instance.new("Folder")
petFolder.Name = "FollowPets"
petFolder.Parent = workspace
local followers = {} -- [player] = {Key = "1-1,2-3", Pets = {{Model, Pet, CF}}}
local FLYERS = {bird = true, ghost = true, fish = true, octo = true}
local SLOTS = {
	[1] = {Vector3.new(2.8, 0, 3)},
	[2] = {Vector3.new(-2.6, 0, 3), Vector3.new(2.6, 0, 3)},
	[3] = {Vector3.new(-3.2, 0, 2.4), Vector3.new(0, 0, 4.4), Vector3.new(3.2, 0, 2.4)},
}
local PET_SCALE = 0.75

local function clearFollower(f)
	for _, p in ipairs(f.Pets) do
		p.Model:Destroy()
	end
	f.Pets = {}
end

local function syncFollower(plr)
	local key = plr:GetAttribute("PetsOut") or ""
	local f = followers[plr]
	if not f then
		f = {Key = nil, Pets = {}}
		followers[plr] = f
	end
	if f.Key == key then return end
	f.Key = key
	clearFollower(f)
	for k in string.gmatch(key, "[^,]+") do
		local pet = PetData.PETS[k]
		if pet then
			local m = PetModels.build(pet)
			m:ScaleTo(m:GetScale() * PET_SCALE)
			PetModels.addEffects(m, pet)
			m.Parent = petFolder
			table.insert(f.Pets, {Model = m, Pet = pet, CF = nil, Phase = math.random() * 6})
		end
	end
end

local function watch(plr)
	plr:GetAttributeChangedSignal("PetsOut"):Connect(function()
		syncFollower(plr)
	end)
	syncFollower(plr)
end
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(watch, plr)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(plr)
	local f = followers[plr]
	if f then
		clearFollower(f)
		followers[plr] = nil
	end
end)

local giantEgg, giantBase
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for plr, f in pairs(followers) do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local n = #f.Pets
		if root and hum and n > 0 and (root.Position - camPos).Magnitude < 250 then
			local feetY = root.Position.Y - hum.HipHeight - root.Size.Y / 2
			local vel = root.AssemblyLinearVelocity
			local moving = Vector3.new(vel.X, 0, vel.Z).Magnitude > 2
			local _, yaw = root.CFrame:ToEulerAnglesYXZ()
			local facing = CFrame.Angles(0, yaw, 0)
			local slots = SLOTS[math.min(n, 3)]
			for i, p in ipairs(f.Pets) do
				local off = slots[i] or slots[#slots]
				local ground = Vector3.new(root.Position.X, feetY, root.Position.Z) + facing:VectorToWorldSpace(off)
				local lift
				if FLYERS[p.Pet.B] then
					lift = 1.6 + math.sin(t * 2.2 + p.Phase) * 0.35
				else
					-- little hops while you run, a gentle bounce while you stand
					lift = moving and math.abs(math.sin(t * 9 + p.Phase)) * 0.7 or math.abs(math.sin(t * 2 + p.Phase)) * 0.12
				end
				local target = CFrame.new(ground + Vector3.new(0, lift, 0)) * facing
				p.CF = p.CF and p.CF:Lerp(target, 1 - math.exp(-dt * 12)) or target
				if (p.CF.Position - target.Position).Magnitude > 40 then
					p.CF = target -- teleported: catch up at once
				end
				p.Model:PivotTo(p.CF)
			end
		end
	end
	-- the giant egg at the Hatchery turns slowly
	if not giantEgg then
		local map = workspace:FindFirstChild("StealAGameMap")
		local h = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("PetHatchery")
		giantEgg = h and h:FindFirstChild("GiantEgg")
		giantBase = giantEgg and giantEgg:GetPivot()
	elseif giantEgg.Parent then
		giantEgg:PivotTo(giantBase * CFrame.new(0, math.sin(t * 1.5) * 0.4, 0) * CFrame.Angles(0, t * 0.4, 0))
	end
end)

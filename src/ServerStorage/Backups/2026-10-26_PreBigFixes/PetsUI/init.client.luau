--[[
	PetsUI
	The MY PETS bag, the PETS button and the pets that follow every player around. The Pet Hatchery shop
	and the hatching show are in the Hatchery module beside this script.
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

------------------------------------------------------------------
-- THE PET HATCHERY: the shop and the hatching show live in the Hatchery module
------------------------------------------------------------------
require(script:WaitForChild("Hatchery")).init({
	Gui = gui, PetFunc = petFunc, Discovered = discovered, Owned = owned,
	OpenEvent = remotes:WaitForChild("OpenHatchery"),
})

------------------------------------------------------------------
-- MY PETS: a grid of collectible cards (pets of the same kind stack) beside a details panel for the selected one.
-- Equip Best sits in the toolbar above the grid, so the grid fills its column exactly.
------------------------------------------------------------------
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local C = K.C
local ORANGE = rgb(255, 150, 50)
local bag = K.window(gui, {Name = "MyPets", W = 1020, H = 600, Title = "My Pets", Icon = "\u{1F43E}", Accent = ORANGE, Accent2 = rgb(255, 84, 120),
	Motion = "pop", Sounds = {{"menuopen"}}})
local body = bag.Body
-- header chips: your boost, pets out, pets owned
local _, boostChip = K.chip({Color = C.Green, Style = "dark", LayoutOrder = 1, ZIndex = 4, Parent = bag.Tools})
local _, outChip = K.chip({Color = rgb(255, 214, 120), Style = "dark", LayoutOrder = 2, ZIndex = 4, Parent = bag.Tools})
local _, ownChip = K.chip({Color = WHITE, Style = "dark", LayoutOrder = 3, ZIndex = 4, Parent = bag.Tools})

local TILE_W, TILE_H, GAP, COLS = 118, 138, 12, 5
local GRID_W = COLS * TILE_W + (COLS - 1) * GAP -- 638
-- room inside the scrolling grid on every side for a card's hover growth and the selected card's outline, which is
-- drawn outside the card: without it the outline of an edge card is cut off by the grid's clipping
local PAD = 8
-- toolbar over the grid: a hint, and Equip Best lined up with the grid's right edge
local bagHint = K.text({Text = "", TextSize = 16, TextColor3 = C.Text2, TextWrapped = true, Position = UDim2.fromOffset(20 + PAD + 2, 14), Size = UDim2.fromOffset(GRID_W - 222, 48), ZIndex = 3, Parent = body})
local bestBtn = K.button({Text = "Equip Best", Kind = "primary", TextSize = 19, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(20 + PAD + GRID_W, 14), Size = UDim2.fromOffset(188, 46), ZIndex = 3, Parent = body})
local function hint(text, color)
	bagHint.Text = text
	bagHint.TextColor3 = color or C.Text2
end
local HINT = "Tap a pet to see it. Pets you equip follow you and speed up installs!"
-- the grid: exactly five cards wide (the scroll bar has its own gutter)
local grid = new("ScrollingFrame", {Position = UDim2.fromOffset(20, 64), Size = UDim2.fromOffset(GRID_W + PAD * 2 + 8, 456), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.5, ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3, Parent = body},
	{new("UIGridLayout", {CellSize = UDim2.fromOffset(TILE_W, TILE_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder}),
	new("UIPadding", {PaddingTop = UDim.new(0, PAD), PaddingLeft = UDim.new(0, PAD), PaddingRight = UDim.new(0, PAD), PaddingBottom = UDim.new(0, PAD)})})
local empty = new("Frame", {Position = UDim2.fromOffset(20 + PAD, 72), Size = UDim2.fromOffset(GRID_W, 440), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = body})
new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 110), Size = UDim2.fromOffset(90, 90), BackgroundTransparency = 1, Text = "\u{1F95A}", TextScaled = true, ZIndex = 3, Parent = empty})
K.text({Text = "No pets yet!", FontFace = K.TITLE, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 214), Size = UDim2.new(1, 0, 0, 36), ZIndex = 3, Parent = empty})
K.text({Text = "Hatch eggs at the Pet Hatchery next to the Trail Shop.", TextSize = 17, TextColor3 = C.Text2, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, 0, 0, 24), ZIndex = 3, Parent = empty})

-- the details panel
local DX = 20 + GRID_W + PAD * 2 + 8 + 12
local detail = new("Frame", {Position = UDim2.fromOffset(DX, 16), Size = UDim2.fromOffset(1020 - DX - 20, 496), BackgroundColor3 = WHITE, ZIndex = 3, ClipsDescendants = true, Parent = body}, {K.corner(18), K.stroke(WHITE, 1.5, 0.86)})
local DW = 1020 - DX - 20
local detailGrad = new("UIGradient", {Rotation = 90, Parent = detail})
local stage = new("Frame", {Size = UDim2.fromOffset(DW, 232), BackgroundTransparency = 1, ZIndex = 3, Parent = detail})
local dRarity = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(DW / 2, 236), Size = UDim2.fromOffset(DW, 30), BackgroundTransparency = 1, ZIndex = 4, Parent = detail},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
local dName = K.text({Text = "", FontFace = K.TITLE, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 270), Size = UDim2.fromOffset(DW - 24, 38), ZIndex = 4, Parent = detail})
local dNameGrad = new("UIGradient", {Rotation = 90, Parent = dName})
local dBoost = K.text({Text = "", TextSize = 19, TextColor3 = rgb(130, 240, 160), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(12, 310), Size = UDim2.fromOffset(DW - 24, 24), ZIndex = 4, Parent = detail})
local dOwned = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Medium), TextSize = 15, TextColor3 = C.Text2, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(12, 336), Size = UDim2.fromOffset(DW - 24, 20), ZIndex = 4, Parent = detail})
local equipBtn = K.button({Text = "Equip", Kind = "primary", TextSize = 21, Position = UDim2.fromOffset(16, 372), Size = UDim2.fromOffset(DW - 32, 56), ZIndex = 4, Parent = detail})
local deleteBtn = K.button({Text = "Delete one", Kind = "ghost", TextSize = 17, Position = UDim2.fromOffset(16, 438), Size = UDim2.fromOffset(DW - 32, 42), ZIndex = 4, Parent = detail})

local cards = {} -- [key] = card
local selectedKey
local stacksNow = {}

local function stacks()
	local list = owned()
	local eq = {}
	for _, id in ipairs(decode("PetsEquipped", "[]")) do
		eq[id] = true
	end
	local byKey = {}
	for _, p in ipairs(list) do
		local st = byKey[p.K]
		if not st then
			st = {Key = p.K, Ids = {}, Equipped = {}, Free = {}}
			byKey[p.K] = st
		end
		table.insert(st.Ids, p.I)
		table.insert(eq[p.I] and st.Equipped or st.Free, p.I)
	end
	return byKey, #list
end

local deleteArmed = 0
local function showDetail(key)
	local st = stacksNow[key]
	local pet = st and PetData.PETS[key]
	detail.Visible = pet ~= nil
	if not pet then
		return
	end
	local rar = rarityOf(pet)
	if detail:GetAttribute("Key") ~= key then
		detail:SetAttribute("Key", key)
		stage:ClearAllChildren()
		rays(stage, rar.Color, UDim2.fromScale(0.95, 1.25), pet.R >= 5 and 8 or 6)
		local vp = viewport(stage, PetModels.build(pet), {Size = UDim2.fromScale(1, 1), Spin = 0.9, ZIndex = 4})
		local sc = new("UIScale", {Scale = 0.7, Parent = vp})
		tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
		detailGrad.Color = ColorSequence.new(rar.Color:Lerp(C.Surface, 0.55), C.Surface)
		for _, c in ipairs(dRarity:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		K.chip({Text = string.upper(rar.Name), Color = rar.Color, TextSize = 15, Height = 28, LayoutOrder = 1, ZIndex = 5, Parent = dRarity})
		dName.Text = pet.N
		dNameGrad.Color = ColorSequence.new(WHITE, rar.Color:Lerp(WHITE, 0.45))
		dBoost.Text = "+" .. pet.Boost .. "% install speed each"
		deleteArmed = 0
	end
	dOwned.Text = string.format("You have %d  \u{2022}  %d equipped", #st.Ids, #st.Equipped)
	local canEquip = #st.Free > 0
	equipBtn.setText(canEquip and (#st.Equipped > 0 and "Equip another" or "Equip") or "Unequip")
	equipBtn.setKind(canEquip and "primary" or "ghost")
	if os.clock() - deleteArmed > 2.5 then
		deleteBtn.setText("Delete one")
		deleteBtn.setKind("ghost")
	end
end

local function selectPet(key)
	if selectedKey == key then
		return
	end
	local old = cards[selectedKey]
	selectedKey = key
	-- the selected card keeps its size (so it never reaches past the grid's gutter); a white outline marks it
	if old then
		tween(old.Stroke, 0.12, {Thickness = 1.5, Transparency = 0.45, Color = old.Rar.Color})
		tween(old.Scale, 0.12, {Scale = 1})
	end
	local c = cards[key]
	if c then
		tween(c.Stroke, 0.15, {Thickness = 3, Transparency = 0, Color = WHITE})
	end
	showDetail(key)
end

local function makeCard(key, pet)
	local rar = rarityOf(pet)
	local f = new("TextButton", {Name = key, BackgroundColor3 = WHITE, AutoButtonColor = false, Text = "", ZIndex = 4, Parent = grid}, {K.corner(16)})
	new("UIGradient", {Rotation = 90, Color = ColorSequence.new(rar.Color:Lerp(C.Surface, 0.55), C.Surface:Lerp(rar.Color, 0.06)), Parent = f})
	local stroke = K.stroke(rar.Color, 1.5, 0.45)
	stroke.Parent = f
	local scale = new("UIScale", {Parent = f})
	if pet.R >= 5 then
		-- Legendary and up: a soft glow behind the pet
		new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TILE_W / 2, 48), Size = UDim2.fromOffset(84, 84), BackgroundColor3 = rar.Color:Lerp(WHITE, 0.3), BackgroundTransparency = 0.72, ZIndex = 4, Parent = f}, {K.corner()})
	end
	viewport(f, PetModels.build(pet), {Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(TILE_W - 12, 86), ZIndex = 5})
	K.text({Text = pet.N, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(6, 92), Size = UDim2.fromOffset(TILE_W - 12, 18), ZIndex = 5, Parent = f})
	K.text({Text = rar.Name .. "  \u{2022}  +" .. pet.Boost .. "%", TextSize = 12, TextColor3 = rar.Color:Lerp(WHITE, 0.3), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 112), Size = UDim2.fromOffset(TILE_W - 12, 16), ZIndex = 5, Parent = f})
	-- equipped: a green tick top-left; how many you have: a pill top-right
	local tick = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.Green, Visible = false, ZIndex = 6, Parent = f}, {K.corner(), K.stroke(WHITE, 1.5, 0.2)})
	K.icon(tick, "check", 14, WHITE, 7)
	local countPill, countText = K.chip({Text = "", Color = C.Gold, Style = "solid", Pad = 8, TextSize = 13, Height = 22, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), ZIndex = 6, Parent = f})
	local card = {Frame = f, Stroke = stroke, Scale = scale, Tick = tick, Count = countPill, CountText = countText, Rar = rar, Pet = pet}
	f.MouseEnter:Connect(function()
		tween(scale, 0.12, {Scale = 1.03})
	end)
	f.MouseLeave:Connect(function()
		tween(scale, 0.12, {Scale = 1})
	end)
	f.MouseButton1Down:Connect(function()
		tween(scale, 0.06, {Scale = 0.96})
	end)
	f.MouseButton1Up:Connect(function()
		tween(scale, 0.18, {Scale = 1}, Enum.EasingStyle.Back)
	end)
	f.Activated:Connect(function()
		UI.sfx("tap", 1.1)
		selectPet(key)
	end)
	return card
end

local function refreshBag(stagger)
	local byKey, count = stacks()
	stacksNow = byKey
	local eqCount = #decode("PetsEquipped", "[]")
	boostChip.Text = "+" .. fmt(player:GetAttribute("PetBoost") or 0) .. "% install speed"
	outChip.Text = eqCount .. " / " .. PetData.EQUIP_MAX .. " out"
	ownChip.Text = count .. " / " .. PetData.MAX_PETS .. " pets"
	for key, card in pairs(cards) do
		if not byKey[key] then
			card.Frame:Destroy()
			cards[key] = nil
		end
	end
	local order = {}
	for key, st in pairs(byKey) do
		local pet = PetData.PETS[key]
		if pet then
			local card = cards[key]
			if not card then
				card = makeCard(key, pet)
				cards[key] = card
			end
			card.Tick.Visible = #st.Equipped > 0
			card.Count.Visible = #st.Ids > 1
			card.CountText.Text = "x" .. #st.Ids
			-- equipped first, then the strongest
			card.Frame.LayoutOrder = (#st.Equipped > 0 and 0 or 100000) - pet.Boost * 10 - pet.R
			table.insert(order, card)
		end
	end
	empty.Visible = #order == 0
	grid.Visible = #order > 0
	if not stacksNow[selectedKey or ""] then
		selectedKey = nil
		table.sort(order, function(x, y)
			return x.Frame.LayoutOrder < y.Frame.LayoutOrder
		end)
		if order[1] then
			selectPet(order[1].Frame.Name)
		else
			detail.Visible = false
		end
	else
		showDetail(selectedKey)
	end
	if stagger then
		-- the cards pop in one after another as the menu opens
		table.sort(order, function(x, y)
			return x.Frame.LayoutOrder < y.Frame.LayoutOrder
		end)
		for i, card in ipairs(order) do
			card.Scale.Scale = 0.6
			task.delay(math.min(i, 20) * 0.018, function()
				tween(card.Scale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
			end)
		end
	end
end

-- a server answer that didn't work shows in the toolbar for a moment, with a soft buzz
local function failed(msg)
	UI.sfx("deny")
	hint(tostring(msg), rgb(255, 150, 160))
	task.delay(2.5, function()
		if bagHint.Text == tostring(msg) then
			hint(HINT)
		end
	end)
end
equipBtn.Activated:Connect(function()
	local st = stacksNow[selectedKey or ""]
	if not st then
		return
	end
	if #st.Free > 0 then
		local ok, msg = petFunc:InvokeServer("equip", st.Free[1])
		if not ok then
			equipBtn.shake()
			failed(msg)
		end
	elseif #st.Equipped > 0 then
		petFunc:InvokeServer("unequip", st.Equipped[1])
	end
end)
deleteBtn.Activated:Connect(function()
	local st = stacksNow[selectedKey or ""]
	if not st then
		return
	end
	-- tap twice to delete, so you never lose a pet by accident
	if os.clock() - deleteArmed > 2.5 then
		deleteArmed = os.clock()
		deleteBtn.setText("Tap again to delete")
		deleteBtn.setKind("danger")
		task.delay(2.5, function()
			if os.clock() - deleteArmed >= 2.5 then
				deleteBtn.setText("Delete one")
				deleteBtn.setKind("ghost")
			end
		end)
		return
	end
	deleteArmed = 0
	deleteBtn.setText("Delete one")
	deleteBtn.setKind("ghost")
	local id = st.Free[1] or st.Equipped[1]
	if id then
		petFunc:InvokeServer("delete", id)
	end
end)
bestBtn.Activated:Connect(function()
	local ok, msg = petFunc:InvokeServer("best")
	if ok then
		UI.sfx("sparkle", 1.2)
		hint("Your strongest pets are out!", rgb(140, 255, 170))
		task.delay(2, function()
			if bagHint.Text == "Your strongest pets are out!" then
				hint(HINT)
			end
		end)
	elseif msg then
		failed(msg)
	end
end)
for _, attr in ipairs({"PetsOwned", "PetsEquipped", "PetBoost"}) do
	player:GetAttributeChangedSignal(attr):Connect(function()
		if bag.Frame.Visible then
			refreshBag(false)
		end
	end)
end

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
		bag.Hide()
		return
	end
	if not player:GetAttribute("PetsSeen") then
		task.spawn(petFunc.InvokeServer, petFunc, "seen")
	end
	hint(HINT)
	refreshBag(true)
	bag.Open()
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
end)

------------------------------------------------------------------
-- THE HATCHERY'S EGGS turn and float (the giant egg under the dome and one on every nest).
-- The server marks each with Spin (radians a second), Bob (studs) and Base (its true home), and streams it in whole.
-- Every frame they're placed from Base and the clock alone, so frame rate, streaming or a missed frame can never make
-- one drift, jump or snap back; all their parts move in one BulkMoveTo. Nothing runs while you're far away.
------------------------------------------------------------------
do
	local hatchery
	local eggs = {} -- [model] = {Parts, Offsets, Base, Spin, Bob, Phase}
	local dirty = true
	local function collect(model)
		local base = model:GetAttribute("Base")
		if typeof(base) ~= "CFrame" then
			return
		end
		local parts, offsets = {}, {}
		-- parts are measured against where they were built, so a client that saw the egg mid-turn still gets them right
		local now = model:GetPivot()
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				table.insert(parts, p)
				table.insert(offsets, now:ToObjectSpace(p.CFrame))
			end
		end
		eggs[model] = {Parts = parts, Offsets = offsets, Base = base, Spin = model:GetAttribute("Spin") or 0.4, Bob = model:GetAttribute("Bob") or 0, Phase = (#eggs + base.Position.X) % 6.28}
	end
	local function scan()
		dirty = false
		table.clear(eggs)
		if not (hatchery and hatchery.Parent) then
			local map = workspace:FindFirstChild("StealAGameMap")
			hatchery = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("PetHatchery")
			if hatchery then
				hatchery.DescendantAdded:Connect(function(d)
					if d:IsA("BasePart") then
						dirty = true
					end
				end)
				hatchery.DescendantRemoving:Connect(function(d)
					if d:IsA("BasePart") then
						dirty = true
					end
				end)
			end
		end
		if not hatchery then
			return
		end
		for _, m in ipairs(hatchery:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("Spin") then
				collect(m)
			end
		end
	end
	local lastScan = 0
	local partsBuf, cfBuf = {}, {}
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		if dirty or (not hatchery and t - lastScan > 2) then
			lastScan = t
			scan()
		end
		local cam = workspace.CurrentCamera
		if not (cam and hatchery and next(eggs)) then
			return
		end
		table.clear(partsBuf)
		table.clear(cfBuf)
		for _, e in pairs(eggs) do
			if (e.Base.Position - cam.CFrame.Position).Magnitude < 180 then
				local cf = e.Base * CFrame.new(0, math.sin(t * 1.4 + e.Phase) * e.Bob, 0) * CFrame.Angles(0, t * e.Spin + e.Phase, 0)
				for i, p in ipairs(e.Parts) do
					partsBuf[#partsBuf + 1] = p
					cfBuf[#cfBuf + 1] = cf * e.Offsets[i]
				end
			end
		end
		if #partsBuf > 0 then
			workspace:BulkMoveTo(partsBuf, cfBuf, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

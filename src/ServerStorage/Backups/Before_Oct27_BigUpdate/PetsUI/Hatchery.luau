--[[
	Hatchery (client): the Pet Hatchery shop and the hatching show. Started by PetsUI: Hatchery.init({...}).
	The server charges, rolls and saves in one call (the "Pets" RemoteFunction) and only then answers, so everything
	here is presentation and can't give or lose anything.
	Shop: a showcase of the selected egg with its buy buttons, what it can hatch with each pet's real odds, and a row
	of every egg. Hatching: the egg's own sequence from HatchStyles, played on its 3D model (EggRig) in a
	ViewportFrame with a 2D particle layer, then the pet reveal. One frame loop drives it all.
	In Studio only, firing PlayerGui.HatchUI.HatchPreview(eggIndex, {petKeys}) plays a hatch with made-up results.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local PetData = require(ReplicatedStorage:WaitForChild("PetData"))
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))
local EggRig = require(ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("EggRig"))
local K = require(ReplicatedStorage:WaitForChild("MenuKit"))
local Particles = require(script.Parent:WaitForChild("Particles"))
local Styles = require(script.Parent:WaitForChild("HatchStyles"))

local new, fmt = UI.new, UI.fmt
local C, WHITE, BLACK = K.C, K.WHITE, K.BLACK
local EGGS, RARITIES = PetData.EGGS, PetData.RARITIES
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local STAR = "\u{2726}"
local DUSK = rgb(10, 6, 24)

-- how big the moment is, by the pet's rarity: Build = seconds of build-up (times the egg's Pace), Tint = the seam and
-- the light inside turn the rarity colour near the end, Ring/Flash/Shake on opening, Blackout = the room goes dark
local TIERS = {
	{Build = 1.3},
	{Build = 1.35},
	{Build = 1.5},
	{Build = 1.7, Tint = true},
	{Build = 2, Tint = true, Ring = true, Shake = 5},
	{Build = 2.3, Tint = true, Ring = true, Shake = 7, Flash = true},
	{Build = 2.7, Tint = true, Ring = true, Shake = 8, Flash = true, Blackout = true, Banner = "SECRET!"},
}

local H = {}

function H.init(d)
	local player = Players.LocalPlayer
	local petFunc, discovered, owned = d.PetFunc, d.Discovered, d.Owned

	------------------------------------------------------------------
	-- 3D PICTURES
	------------------------------------------------------------------
	local EGG_AT = Vector3.new(0, 1.42, 0)
	local function aim(cam, yaw, pitch, dist, lift)
		local y, p = math.rad(yaw), math.rad(pitch)
		local dir = Vector3.new(math.sin(y) * math.cos(p), math.sin(p), -math.cos(y) * math.cos(p))
		local t = EGG_AT + Vector3.new(0, lift or 0, 0)
		cam.CFrame = CFrame.lookAt(t + dir * 10.5 * dist, t)
	end
	local function eggView(parent, egg, props)
		local vp = new("ViewportFrame", {BackgroundTransparency = 1, Ambient = props.Ambient or rgb(150, 144, 178), LightColor = rgb(255, 248, 236), LightDirection = Vector3.new(-0.5, -1, 0.7),
			Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, ZIndex = props.ZIndex or 3, Parent = parent})
		local model = PetModels.egg(egg)
		model.Parent = vp
		if props.Stand then
			-- a display stand in the egg's colours: a dark disc, a lit rim, and a pool of light under the egg
			local function disc(h, dia, y, color, mat, t)
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Cylinder
				p.Anchored = true
				p.Size = Vector3.new(h, dia, dia)
				p.CFrame = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2)
				p.Color, p.Material, p.Transparency = color, mat, t or 0
				p.Parent = vp
			end
			disc(0.36, 3.0, -0.19, egg.Color:Lerp(rgb(24, 20, 44), 0.78), Enum.Material.SmoothPlastic)
			disc(0.06, 3.08, -0.06, egg.Spot, Enum.Material.Neon, 0.3)
			disc(0.06, 2.92, -0.3, egg.Spot, Enum.Material.Neon, 0.55)
			disc(0.02, 2.2, 0.005, egg.Spot:Lerp(WHITE, 0.3), Enum.Material.Neon, 0.8)
		end
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		cam.Parent = vp
		vp.CurrentCamera = cam
		aim(cam, props.Yaw or 16, props.Pitch or 9, props.Dist or 1, props.Lift)
		return vp, model, cam
	end
	local swaying = {} -- [viewport] = {Model, Base, Angle, Speed}
	local function petView(parent, pet, props)
		local vp = new("ViewportFrame", {BackgroundTransparency = 1, Ambient = rgb(170, 165, 192), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, 0.8),
			Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, ZIndex = props.ZIndex or 3, Parent = parent})
		local model = PetModels.build(pet)
		model.Parent = vp
		local cam = Instance.new("Camera")
		cam.FieldOfView = 30
		cam.Parent = vp
		vp.CurrentCamera = cam
		local cf, size = model:GetBoundingBox()
		local dist = math.max(size.X, size.Y, size.Z) / (2 * math.tan(math.rad(15))) * (props.Zoom or 1.1)
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.35, dist * 0.18, -dist), cf.Position)
		if props.Sway then
			swaying[vp] = {Model = model, Base = model:GetPivot(), Angle = math.random() * 6, Speed = props.Sway}
		end
		return vp, model
	end
	-- light rays turning behind a picture
	local rotors = {} -- [frame] = degrees per second
	local function rays(parent, color, scale, count, z)
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = z or 2, Parent = parent})
		for i = 0, count - 1 do
			local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.08, 0, 1, 0), Rotation = i * 180 / count, BackgroundColor3 = color:Lerp(WHITE, 0.3), BackgroundTransparency = 0.62, BorderSizePixel = 0, ZIndex = z or 2, Parent = f}, {K.corner()})
			new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
		end
		for k, s in ipairs({0.55, 0.36}) do
			new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = color:Lerp(WHITE, 0.45), BackgroundTransparency = 0.84 - k * 0.06, ZIndex = z or 2, Parent = f}, {K.corner()})
		end
		rotors[f] = 22
		return f
	end

	local function cash()
		local ls = player:FindFirstChild("leaderstats")
		local c = ls and ls:FindFirstChild("Cash")
		return c and c.Value or 0
	end

	------------------------------------------------------------------
	-- THE SHOP
	------------------------------------------------------------------
	local W, HGT = 1040, 600
	local shop = K.window(d.Gui, {Name = "Hatchery", W = W, H = HGT, Motion = "pop", Sounds = {{"menuopen", 1.06}}})
	local card = shop.Card

	-- header: title, your pets' boost, the skip toggle (the close button comes with the window)
	local head = new("Frame", {Position = UDim2.fromOffset(28, 14), Size = UDim2.fromOffset(640, 46), BackgroundTransparency = 1, ZIndex = 2, Parent = card},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder})})
	K.text({Text = "Pet Hatchery", FontFace = K.TITLE, TextSize = 34, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 46), LayoutOrder = 1, ZIndex = 2, Parent = head})
	local _, boostText = K.chip({Color = C.Green, LayoutOrder = 2, ZIndex = 2, Parent = head})
	local function showBoost()
		boostText.Text = string.format("Your pets: +%s%% install speed", fmt(player:GetAttribute("PetBoost") or 0))
	end
	player:GetAttributeChangedSignal("PetBoost"):Connect(showBoost)
	showBoost()
	local skipAnim = false
	K.toggle({Text = "Skip animation", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -84, 0, 23), Size = UDim2.fromOffset(200, 32), ZIndex = 2, Parent = card, OnChange = function(v)
		skipAnim = v
	end})
	new("Frame", {Position = UDim2.fromOffset(24, 74), Size = UDim2.new(1, -48, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 2, Parent = card})

	-- the showcase: the selected egg on a lit pedestal, with its buy buttons
	local show = new("Frame", {Position = UDim2.fromOffset(24, 90), Size = UDim2.fromOffset(500, 390), BackgroundColor3 = WHITE, ZIndex = 2, ClipsDescendants = true, Parent = card}, {K.corner(18), K.stroke(WHITE, 1.5, 0.9)})
	local showGrad = new("UIGradient", {Rotation = 90, Parent = show})
	local halo = {}
	for i, s in ipairs({330, 240, 160}) do
		halo[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(250, 150), Size = UDim2.fromOffset(s, s), BackgroundTransparency = 0.9, ZIndex = 2, Parent = show}, {K.corner()})
	end
	local eggIndex = K.text({Text = "", TextSize = 14, TextColor3 = C.Muted, Position = UDim2.fromOffset(20, 14), Size = UDim2.fromOffset(200, 20), ZIndex = 6, Parent = show})
	local b1 = K.button({Text = "Hatch 1", Sub = "", Kind = "primary", Position = UDim2.fromOffset(16, 306), Size = UDim2.fromOffset(226, 66), ZIndex = 6, Parent = show})
	local b10 = K.button({Text = "Hatch " .. PetData.HATCH_MANY, Sub = "", Kind = "secondary", Position = UDim2.fromOffset(258, 306), Size = UDim2.fromOffset(226, 66), ZIndex = 6, Parent = show})
	-- a message pill over the showcase (not enough cash, server errors)
	local toast = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Red, Visible = false, ZIndex = 20, Parent = show},
		{K.corner(), new("UIPadding", {PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})})
	local toastText = K.text({Text = "", TextSize = 16, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = 21, Parent = toast})
	local toastScale = new("UIScale", {Parent = toast})
	local toastId = 0
	local function showToast(text, color)
		toastId += 1
		local id = toastId
		toast.BackgroundColor3 = color or C.Red
		toastText.Text = text
		toast.Visible = true
		toastScale.Scale = 0.7
		K.tween(toastScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
		task.delay(2.6, function()
			if id == toastId then
				toast.Visible = false
			end
		end)
	end

	-- what the selected egg is and what it can hatch
	local info = new("Frame", {Position = UDim2.fromOffset(540, 90), Size = UDim2.fromOffset(476, 390), BackgroundTransparency = 1, ZIndex = 2, Parent = card})
	local eggName = K.text({Text = "", FontFace = K.TITLE, TextSize = 40, Size = UDim2.fromOffset(476, 46), ZIndex = 2, Parent = info})
	local nameGrad = new("UIGradient", {Rotation = 90, Parent = eggName})
	local tagline = K.text({Text = "", FontFace = K.font(Enum.FontWeight.Medium), TextSize = 17, TextColor3 = C.Text2, Position = UDim2.fromOffset(0, 48), Size = UDim2.fromOffset(476, 22), ZIndex = 2, Parent = info})
	local chips = new("Frame", {Position = UDim2.fromOffset(0, 84), Size = UDim2.fromOffset(476, 30), BackgroundTransparency = 1, ZIndex = 2, Parent = info},
		{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
	K.text({Text = "WHAT CAN HATCH", TextSize = 14, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 130), Size = UDim2.fromOffset(300, 20), ZIndex = 2, Parent = info})
	K.text({Text = "chance per hatch", FontFace = K.font(Enum.FontWeight.Medium), TextSize = 14, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(176, 130), Size = UDim2.fromOffset(300, 20), ZIndex = 2, Parent = info})
	local gridHost = new("Frame", {Position = UDim2.fromOffset(0, 158), Size = UDim2.fromOffset(476, 232), BackgroundTransparency = 1, ZIndex = 2, Parent = info})

	-- one grid of pet tiles per egg, built the first time it's shown; unknown pets are silhouettes
	local grids = {}
	local TILE, GAP = 110, 12
	local function gridFor(egg)
		local g = grids[egg.Index]
		if g then
			return g
		end
		g = {Frame = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = gridHost}), Tiles = {}}
		local n = #egg.Pets
		for i, pet in ipairs(egg.Pets) do
			local row, col = (i - 1) // 4, (i - 1) % 4
			local inRow = math.min(4, n - row * 4)
			local x0 = (476 - (inRow * TILE + (inRow - 1) * GAP)) / 2
			local rar = RARITIES[pet.R]
			local tile = new("Frame", {Position = UDim2.fromOffset(x0 + col * (TILE + GAP), row * (TILE + GAP)), Size = UDim2.fromOffset(TILE, TILE), BackgroundColor3 = WHITE, ZIndex = 3, Parent = g.Frame},
				{K.corner(14), K.stroke(rar.Color, 1.5, 0.55)})
			new("UIGradient", {Rotation = 90, Color = ColorSequence.new(rar.Color:Lerp(C.Surface2, 0.72), C.Surface), Parent = tile})
			local vp = petView(tile, pet, {Position = UDim2.fromOffset(5, 4), Size = UDim2.fromOffset(TILE - 10, 64), ZIndex = 4, Zoom = 1.05})
			local q = K.text({Text = "?", FontFace = K.TITLE, TextSize = 28, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = vp})
			local name = K.text({Text = pet.N, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(6, 68), Size = UDim2.fromOffset(TILE - 12, 18), ZIndex = 4, Parent = tile})
			K.text({Text = rar.Name, TextSize = 13, TextColor3 = rar.Color:Lerp(WHITE, 0.25), Position = UDim2.fromOffset(9, 88), Size = UDim2.fromOffset(60, 16), ZIndex = 4, Parent = tile})
			K.text({Text = PetData.oddsText(egg.Odds[pet.R] / #egg.Tiers[pet.R]), TextSize = 14, TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(TILE - 69, 88), Size = UDim2.fromOffset(60, 16), ZIndex = 4, Parent = tile})
			g.Tiles[i] = {Pet = pet, Vp = vp, Q = q, Name = name}
			-- a known pet turns to face you while you hover its tile (only one picture animates at a time, so the
			-- showcase egg keeps a steady frame rate)
			local m = vp:FindFirstChildOfClass("Model")
			local base = m and m:GetPivot()
			tile.MouseEnter:Connect(function()
				if m and discovered[pet.Key] then
					swaying[vp] = {Model = m, Base = base, Angle = 0, Speed = 1.6}
				end
			end)
			tile.MouseLeave:Connect(function()
				swaying[vp] = nil
				if m then
					m:PivotTo(base)
				end
			end)
		end
		grids[egg.Index] = g
		return g
	end
	local function refreshGrid(g)
		for _, t in ipairs(g.Tiles) do
			local known = discovered[t.Pet.Key] == true
			t.Vp.ImageColor3 = known and WHITE or rgb(16, 12, 30)
			t.Q.Visible = not known
			t.Name.Text = known and t.Pet.N or "???"
			t.Name.TextColor3 = known and WHITE or C.Muted
		end
	end

	-- the row of every egg
	local strip = new("Frame", {Position = UDim2.fromOffset(86, 494), Size = UDim2.fromOffset(868, 92), BackgroundTransparency = 1, ZIndex = 2, Parent = card})
	local prevBtn = K.iconButton({Icon = "left", Position = UDim2.fromOffset(24, 517), Size = 46, ZIndex = 3, Parent = card})
	local nextBtn = K.iconButton({Icon = "right", Position = UDim2.fromOffset(W - 70, 517), Size = 46, ZIndex = 3, Parent = card})
	local thumbs = {}
	local selected = 0
	local select -- defined below
	for i, egg in ipairs(EGGS) do
		local b = new("TextButton", {Position = UDim2.fromOffset((i - 1) * 110, 0), Size = UDim2.fromOffset(98, 92), BackgroundColor3 = C.Surface, AutoButtonColor = false, Text = "", ZIndex = 3, Parent = strip}, {K.corner(14)})
		local st = K.stroke(WHITE, 1.5, 0.88)
		st.Parent = b
		local sc = new("UIScale", {Parent = b})
		eggView(b, egg, {Position = UDim2.fromOffset(11, 0), Size = UDim2.fromOffset(76, 70), ZIndex = 4, Yaw = 20, Pitch = 10, Dist = 0.98})
		local price = K.text({Text = "$" .. fmt(egg.Price), TextSize = 15, TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 68), Size = UDim2.fromOffset(90, 18), ZIndex = 4, Parent = b})
		thumbs[i] = {Button = b, Stroke = st, Scale = sc, Price = price}
		b.MouseEnter:Connect(function()
			if selected ~= i then
				K.tween(b, 0.12, {BackgroundColor3 = C.Surface2})
				K.tween(sc, 0.12, {Scale = 1.03})
			end
		end)
		b.MouseLeave:Connect(function()
			if selected ~= i then
				K.tween(b, 0.12, {BackgroundColor3 = C.Surface})
				K.tween(sc, 0.12, {Scale = 1})
			end
		end)
		b.Activated:Connect(function()
			if selected ~= i then
				UI.sfx("click", 1.1)
				select(i)
			end
		end)
	end

	-- prices go red and the buttons grey out when you can't afford them (they still explain why when pressed)
	local function refreshAfford()
		local money = cash()
		for i, t in ipairs(thumbs) do
			t.Price.TextColor3 = money >= EGGS[i].Price and C.Gold or C.Red
		end
		local egg = EGGS[selected]
		if not egg then
			return
		end
		for _, b in ipairs({{b1, 1}, {b10, PetData.HATCH_MANY}}) do
			local cost = egg.Price * b[2]
			local ok = money >= cost
			b[1].setEnabled(ok)
			b[1].setText("Hatch " .. b[2], "$" .. fmt(cost), ok and WHITE or rgb(255, 196, 204))
		end
	end

	-- Roblox can leave a still ViewportFrame blank after its window is hidden and shown again; a tiny camera
	-- nudge makes every picture in the shop draw again
	local nudge = 1
	local function redrawPictures()
		nudge = -nudge
		for _, vp in ipairs(card:GetDescendants()) do
			if vp:IsA("ViewportFrame") and vp.CurrentCamera then
				vp.CurrentCamera.CFrame *= CFrame.new(0, 0, 0.001 * nudge)
			end
		end
	end

	local showcase = {}
	select = function(i)
		i = math.clamp(i, 1, #EGGS)
		local egg = EGGS[i]
		local old = selected
		selected = i
		-- the egg on the pedestal pops in
		if showcase.Vp then
			showcase.Vp:Destroy()
		end
		local vp, model, cam = eggView(show, egg, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(320, 304), ZIndex = 4, Stand = true, Dist = 0.92, Pitch = 13, Lift = -0.15})
		-- the turn carries on from where the last egg was (it used to restart at 0 on every pick), and the new
		-- picture is aimed now so its first frame isn't drawn from the default angle
		showcase.Vp, showcase.Rig, showcase.Cam, showcase.Yaw = vp, EggRig.new(model), cam, showcase.Yaw or 0
		aim(cam, 16 - math.deg(showcase.Yaw), 13, 0.92, -0.15)
		vp.LightDirection = CFrame.Angles(0, showcase.Yaw, 0) * Vector3.new(-0.5, -1, 0.7)
		local s = new("UIScale", {Scale = 0.86, Parent = vp})
		K.tween(s, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
		vp.ImageTransparency = 1
		K.tween(vp, 0.2, {ImageTransparency = 0})
		-- its colours on the card
		showGrad.Color = ColorSequence.new(egg.Color:Lerp(C.Surface, 0.7), C.PanelLow:Lerp(egg.Color, 0.08))
		for k, f in ipairs(halo) do
			K.tween(f, 0.3, {BackgroundColor3 = egg.Spot:Lerp(WHITE, 0.2), BackgroundTransparency = 0.93 - k * 0.025})
		end
		eggIndex.Text = string.format("EGG %d OF %d", i, #EGGS)
		eggName.Text = egg.Name
		nameGrad.Color = ColorSequence.new(WHITE, egg.Spot:Lerp(WHITE, 0.45))
		tagline.Text = egg.Tagline or ""
		for _, c in ipairs(chips:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		K.chip({Text = string.format("Up to +%d%% install speed", egg.Best.Boost), Color = C.Green, LayoutOrder = 1, ZIndex = 3, Parent = chips})
		K.chip({Text = #egg.Pets .. " pets", Color = C.Text2, LayoutOrder = 2, ZIndex = 3, Parent = chips})
		local top = egg.Pets[#egg.Pets]
		K.chip({Text = RARITIES[top.R].Name .. " inside", Color = RARITIES[top.R].Color, LayoutOrder = 3, ZIndex = 3, Parent = chips})
		-- what it hatches
		if old > 0 and grids[old] then
			grids[old].Frame.Visible = false
		end
		local g = gridFor(egg)
		refreshGrid(g)
		g.Frame.Visible = true
		-- the row
		for k, t in ipairs(thumbs) do
			local on = k == i
			t.Button.BackgroundColor3 = on and C.SurfaceHi or C.Surface
			t.Stroke.Color = on and EGGS[k].Spot:Lerp(WHITE, 0.2) or WHITE
			t.Stroke.Transparency = on and 0 or 0.88
			t.Stroke.Thickness = on and 2 or 1.5
			-- only the thumbs that change: each resize redraws that thumb's 3D egg, which competes with the turning showcase
			if t.Scale.Scale ~= (on and 1.06 or 1) then
				K.tween(t.Scale, 0.18, {Scale = on and 1.06 or 1}, Enum.EasingStyle.Back)
			end
		end
		prevBtn.setEnabled(i > 1)
		nextBtn.setEnabled(i < #EGGS)
		refreshAfford()
	end
	prevBtn.Activated:Connect(function()
		if selected > 1 then
			select(selected - 1)
		end
	end)
	nextBtn.Activated:Connect(function()
		if selected < #EGGS then
			select(selected + 1)
		end
	end)

	-- never an empty shop: something is always selected (the first open picks the best egg you can afford)
	select(1)
	local opened = false
	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 30)
		local c = ls and ls:WaitForChild("Cash", 30)
		if c then
			c.Changed:Connect(refreshAfford)
			refreshAfford()
		end
	end)

	------------------------------------------------------------------
	-- THE HATCHING SHOW
	------------------------------------------------------------------
	local hatchGui = new("ScreenGui", {Name = "HatchUI", ResetOnSpawn = false, DisplayOrder = 40, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false, Parent = player:WaitForChild("PlayerGui")})
	local backdrop = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = DUSK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = hatchGui})
	local flashLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, Parent = hatchGui})
	local SW, SH = 1280, 720
	local stageRoot = K.stage(hatchGui, SW, SH)
	local fxBackLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = stageRoot})
	local stage = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = stageRoot})
	local fxFrontLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30, Parent = stageRoot})
	local ui = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 40, Parent = stageRoot})
	local fxBack, fxFront = Particles.new(fxBackLayer), Particles.new(fxFrontLayer)
	local skipBtn = K.button({Text = "Skip", Kind = "ghost", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 24), Size = UDim2.fromOffset(130, 48), TextSize = 19, ZIndex = 50, Parent = stageRoot})

	local hatching, buying = false, false
	local skipNow, quiet = false, false
	local session = 0
	local live = {} -- [ctx] = true: eggs on stage, stepped every frame
	skipBtn.Activated:Connect(function()
		skipNow = true
	end)

	local function clearStage()
		session += 1
		table.clear(live)
		for _, layer in ipairs({stage, ui}) do
			for _, c in ipairs(layer:GetChildren()) do
				c:Destroy()
			end
		end
		fxBack:clear()
		fxFront:clear()
		-- rings, beams, the loading bar and the scanner live on the particle layers too
		for _, layer in ipairs({fxBackLayer, fxFrontLayer}) do
			for _, c in ipairs(layer:GetChildren()) do
				c:Destroy()
			end
		end
	end
	local function setHotbar(on)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, on)
		end)
	end

	-- one egg on stage: the API the HatchStyles use
	local Ctx = {}
	Ctx.__index = Ctx
	local function newCtx(egg, pet, size, center, lite)
		local cell = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(center.X, center.Y), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = 3, Parent = stage})
		-- darker than the shop: the egg's own glow carries the show
		local vp, model, cam = eggView(cell, egg, {Size = UDim2.fromScale(1, 1), ZIndex = 5, Ambient = rgb(104, 98, 130)})
		local style = Styles[egg.Name] or Styles.default
		local c = setmetatable({
			Egg = egg, Pet = pet, Rar = pet and RARITIES[pet.R], Tier = pet and TIERS[pet.R] or TIERS[1], Style = style, Lite = lite,
			Cell = cell, Vp = vp, Cam = cam, Rig = EggRig.new(model), Scale = new("UIScale", {Parent = vp}),
			Center = center, Px = size / 380, Session = session, T = 0, Dt = 0, X = 0, Knock = 0, Timers = {},
			Pose = CFrame.identity, JoltA = 0, JoltV = 0, Shards = {},
			Yaw = style.Cam.Yaw, Pitch = style.Cam.Pitch, Dist = style.Cam.Dist,
		}, Ctx)
		live[c] = true
		return c
	end
	function Ctx:alive()
		return self.Session == session
	end
	function Ctx:step(dt)
		self.T += dt
		self.Dt = dt
		self.JoltV += (-260 * self.JoltA - 16 * self.JoltV) * dt
		self.JoltA += self.JoltV * dt
		self.Rig.Pose = self.Pose * CFrame.Angles(0, 0, math.rad(self.JoltA))
		-- the small eggs of a 10-egg hatch re-place their parts every other frame (half the cost, too small to see)
		self.Pending = (self.Pending or 0) + dt
		self.Flip = not self.Flip
		if not self.Lite or self.Flip then
			self.Rig:step(self.Pending)
			self.Pending = 0
		end
		aim(self.Cam, self.Yaw, self.Pitch, self.Dist)
		for i = #self.Shards, 1, -1 do
			local s = self.Shards[i]
			s.Age += dt
			if s.Age >= s.Life then
				s.P:Destroy()
				table.remove(self.Shards, i)
			else
				s.Vel -= Vector3.new(0, s.Gravity * dt, 0)
				s.Pos += s.Vel * dt
				s.Rot = s.Rot * CFrame.fromAxisAngle(s.Axis, s.Spin * dt)
				s.P.CFrame = CFrame.new(s.Pos) * s.Rot
				s.P.Transparency = s.T + (1 - s.T) * math.clamp((s.Age / s.Life - 0.55) / 0.45, 0, 1)
			end
		end
	end
	function Ctx:every(key, interval)
		local last = self.Timers[key]
		if not last or self.T - last >= interval then
			self.Timers[key] = self.T
			return true
		end
		return false
	end
	function Ctx:emit(def)
		local e = table.clone(def)
		e.At = self.Center + (def.At or Vector2.zero) * self.Px
		if def.Target then
			e.Target = self.Center + def.Target * self.Px
		end
		e.Scale = self.Px
		e.Amount = self.Lite and 0.22 or 1
		;((def.Z or 20) < 8 and fxBack or fxFront):emit(e)
	end
	function Ctx:knocks(x, n, fn)
		local due = math.floor(n * x ^ (1 / 0.7))
		while self.Knock < due do
			self.Knock += 1
			fn(self.Knock)
		end
	end
	function Ctx:sfx(name, pitch)
		if not quiet and not self.Quiet then
			UI.sfx(name, pitch)
		end
	end
	function Ctx:jolt(deg)
		self.JoltV += deg * 18 * (math.random() < 0.5 and -1 or 1)
	end
	function Ctx:around(y, cf)
		return CFrame.new(0, y, 0) * cf * CFrame.new(0, -y, 0)
	end
	function Ctx:backdrop(color, transparency, t)
		if self.Quiet then
			return
		end
		K.tween(backdrop, t or 0.4, {BackgroundColor3 = color, BackgroundTransparency = transparency})
	end
	function Ctx:flash(color, a)
		if self.Lite or quiet then
			return
		end
		local f = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = a or 0.3, BorderSizePixel = 0, ZIndex = 60, Parent = flashLayer})
		K.tween(f, 0.55, {BackgroundTransparency = 1})
		task.delay(0.6, f.Destroy, f)
	end
	function Ctx:shake(px)
		if self.Lite or quiet then
			return
		end
		task.spawn(function()
			for k = 1, 8 do
				local a = px * (1 - k / 9)
				stage.Position = UDim2.fromOffset(math.random(-100, 100) / 100 * a, math.random(-100, 100) / 100 * a)
				task.wait(0.03)
			end
			stage.Position = UDim2.new()
		end)
	end
	function Ctx:ring(color, from, to, t, thick, squash, at)
		local p = self.Center + (at or Vector2.zero) * self.Px
		local sq = squash or 1
		local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(from * self.Px, from * self.Px * sq), BackgroundTransparency = 1, ZIndex = 25, Parent = fxFrontLayer}, {K.corner()})
		local st = new("UIStroke", {Color = color, Thickness = thick * self.Px, Transparency = 0.1, Parent = ring})
		K.tween(ring, t, {Size = UDim2.fromOffset(to * self.Px, to * self.Px * sq)}, Enum.EasingStyle.Quart)
		K.tween(st, t, {Transparency = 1, Thickness = 1}, Enum.EasingStyle.Quart)
		task.delay(t + 0.05, ring.Destroy, ring)
	end
	function Ctx:beam(color, t)
		local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(self.Center.X, self.Center.Y + 40 * self.Px), Size = UDim2.fromOffset(150 * self.Px, 0), BackgroundColor3 = color, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2, Parent = fxBackLayer},
			{new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)})})})
		K.tween(b, 0.25, {Size = UDim2.fromOffset(150 * self.Px, 720)})
		K.tween(b, t, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(t + 0.05, b.Destroy, b)
	end
	function Ctx:glow(color, transparency)
		if not self.Glow then
			self.Glow = {}
			for i, s in ipairs({1.15, 0.85, 0.55}) do
				self.Glow[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundTransparency = 1, ZIndex = 2, Parent = self.Cell}, {K.corner()})
			end
		end
		for i, f in ipairs(self.Glow) do
			f.BackgroundColor3 = color
			f.BackgroundTransparency = 1 - (1 - transparency) * (0.12 + 0.09 * i)
		end
	end
	function Ctx:shards(def)
		local rng = Random.new()
		local count = math.floor((def.Count or 10) * (self.Lite and 0.5 or 1))
		for _ = 1, count do
			local p = Instance.new(def.Cube and "Part" or "WedgePart")
			local s = rng:NextNumber(def.Size[1], def.Size[2])
			p.Size = def.Cube and Vector3.new(s, s, s) or Vector3.new(s * 0.35, s, s * 1.2)
			p.Anchored = true
			p.Color = def.Colors[rng:NextInteger(1, #def.Colors)]
			p.Material = def.Material or Enum.Material.SmoothPlastic
			p.Transparency = def.Transparency or 0
			local dir = Vector3.new(rng:NextNumber(-1, 1), (def.Up or 0.5) + rng:NextNumber(-0.3, 0.6), rng:NextNumber(-1, 0.6)).Unit
			local pos = (self.Rig.Pose * CFrame.new(Vector3.new(0, def.Y or 1.4, 0) + dir * 0.9)).Position
			local rot = CFrame.Angles(rng:NextNumber(0, 6.3), rng:NextNumber(0, 6.3), rng:NextNumber(0, 6.3))
			p.CFrame = CFrame.new(pos) * rot
			p.Parent = self.Vp
			table.insert(self.Shards, {P = p, Pos = pos, Vel = dir * rng:NextNumber(def.Speed[1], def.Speed[2]), Rot = rot, Axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit,
				Spin = rng:NextNumber(4, 10), Gravity = def.Gravity or 25, Age = 0, Life = rng:NextNumber(0.9, 1.3), T = p.Transparency})
		end
	end
	function Ctx:animate(t, fn)
		if skipNow then
			fn(1)
			return
		end
		local t0 = os.clock()
		while true do
			local a = math.min(1, (os.clock() - t0) / t)
			fn(a)
			if a >= 1 or not self:alive() then
				return
			end
			task.wait()
		end
	end
	function Ctx:wait(t)
		local t0 = os.clock()
		while os.clock() - t0 < t and not skipNow and self:alive() do
			task.wait()
		end
	end
	function Ctx:scaleTo(s, t, style, dir)
		if not t or t <= 0 then
			self.Scale.Scale = s
		else
			K.tween(self.Scale, t, {Scale = s}, style, dir)
		end
	end
	-- a pixel loading bar under the egg; returns set(k), set(nil) removes it
	function Ctx:bar(n, colors)
		local px = self.Px
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(self.Center.X, self.Center.Y + 165 * px), Size = UDim2.fromOffset((n * 18 + 8) * px, 22 * px), BackgroundColor3 = rgb(20, 16, 36), BorderSizePixel = 0, ZIndex = 26, Parent = fxFrontLayer},
			{new("UIStroke", {Color = WHITE, Thickness = 2 * px})})
		local cells = {}
		for i = 1, n do
			cells[i] = new("Frame", {Position = UDim2.fromOffset((4 + (i - 1) * 18) * px, 4 * px), Size = UDim2.fromOffset(14 * px, 14 * px), BackgroundColor3 = colors[(i - 1) % #colors + 1], BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 27, Parent = f})
		end
		return function(k)
			if not k then
				f:Destroy()
				return
			end
			local lit = math.floor(k * n + 0.5)
			for i, cell in ipairs(cells) do
				cell.BackgroundTransparency = i <= lit and 0 or 1
			end
		end
	end
	-- a scan line across the egg; returns set(yOffset), set(nil) removes it
	function Ctx:scanner(color)
		local px = self.Px
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(280 * px, 4 * px), BackgroundColor3 = color, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 26, Parent = fxFrontLayer},
			{new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})})
		return function(y)
			if not y then
				f:Destroy()
				return
			end
			f.Position = UDim2.fromOffset(self.Center.X, self.Center.Y + y * px)
		end
	end

	-- the part of every build-up the eggs share: the seam cracks open over the second half, and rare pets turn it
	-- (and the light inside) their rarity colour near the end
	local function sharedBuild(c, x)
		local tier, rar = c.Tier, c.Rar
		local tint = tier.Tint and x > 0.6
		c.Rig:reveal("Crack", math.clamp((x - 0.45) / 0.5, 0, 1), tint and rar.Color:Lerp(WHITE, 0.25) or nil)
		if tint then
			local k = math.min(1, (x - 0.6) / 0.3)
			c.Rig:paint("Core", rar.Color, k)
			c:glow(rar.Color, 1 - 0.55 * k)
			if not c.Tinted then
				c.Tinted = true
				c:sfx("sparkle", 1.15)
			end
		end
		if tier.Blackout and x > 0.55 and not c.Dark then
			c.Dark = true
			c:backdrop(BLACK, 0.02, 0.6)
		end
	end

	-- the pet comes out where the egg was
	local function reveal(c, pet, big)
		local rar = RARITIES[pet.R]
		task.spawn(function()
			c:animate(0.25, function(a)
				c.Rig:fade(a)
			end)
		end)
		if c.Glow then
			for _, f in ipairs(c.Glow) do
				K.tween(f, 0.3, {BackgroundTransparency = 1})
			end
		end
		local r = rays(c.Cell, rar.Color, big and 1.9 or 1.45, pet.R >= 5 and 12 or 8, 2)
		rotors[r] = 18 + pet.R * 6
		r.Size = UDim2.fromScale(0.2, 0.2)
		K.tween(r, 0.4, {Size = UDim2.fromScale(big and 1.9 or 1.45, big and 1.9 or 1.45)}, Enum.EasingStyle.Back)
		local vp = petView(c.Cell, pet, {Size = UDim2.fromScale(1, 1), ZIndex = 6, Zoom = 1.15, Sway = 1.1})
		local s = new("UIScale", {Scale = 0.15, Parent = vp})
		if c.Style.Reveal == "fade" then
			vp.ImageTransparency = 1
			K.tween(vp, 0.6, {ImageTransparency = 0})
			K.tween(s, 0.6, {Scale = 1}, Enum.EasingStyle.Quad)
		else
			vp.Position = UDim2.fromOffset(0, 50 * c.Px)
			K.tween(vp, 0.45, {Position = UDim2.new()}, Enum.EasingStyle.Back)
			K.tween(s, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
		end
		c:emit({Count = big and (10 + pet.R * 4) or (14 + pet.R * 3), Shape = STAR, Colors = {rar.Color:Lerp(WHITE, 0.3), WHITE}, Size = {10, 18}, Speed = {180, 360}, Drag = 2, Life = {0.7, 1.1}, Spin = {-120, 120}, Z = 12})
		c.PetVp = vp
	end

	-- the pet's name card under the reveal
	local function nameplate(pet, y, isNew)
		local rar = RARITIES[pet.R]
		local holder = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2, y), Size = UDim2.fromOffset(640, 132), BackgroundTransparency = 1, ZIndex = 41, Parent = ui})
		local pills = new("Frame", {Size = UDim2.fromOffset(640, 30), BackgroundTransparency = 1, ZIndex = 41, Parent = holder},
			{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
		K.chip({Text = string.upper(rar.Name), Color = rar.Color, TextSize = 16, LayoutOrder = 1, ZIndex = 42, Parent = pills})
		if isNew then
			K.chip({Text = "NEW!", Color = C.Gold, TextSize = 16, LayoutOrder = 2, ZIndex = 42, Parent = pills})
		end
		local name = K.text({Text = pet.N, FontFace = K.TITLE, TextSize = 50, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 34), Size = UDim2.fromOffset(640, 58), ZIndex = 42, Parent = holder})
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, rar.Color:Lerp(WHITE, 0.35)), Parent = name})
		new("UIStroke", {Color = rgb(12, 8, 26), Thickness = 2, Transparency = 0.3, Parent = name})
		K.text({Text = "+" .. pet.Boost .. "% install speed", TextSize = 21, TextColor3 = rgb(130, 240, 160), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 96), Size = UDim2.fromOffset(640, 26), ZIndex = 42, Parent = holder})
		local sc = new("UIScale", {Scale = 0.6, Parent = holder})
		K.tween(sc, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
		return holder
	end
	local function banner(text, color)
		local b = K.text({Text = text, FontFace = K.TITLE, TextSize = 72, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(SW / 2, 82), Size = UDim2.fromOffset(700, 90), ZIndex = 45, Parent = ui})
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, color), Parent = b})
		new("UIStroke", {Color = rgb(12, 8, 26), Thickness = 3, Transparency = 0.2, Parent = b})
		local s = new("UIScale", {Scale = 2.2, Parent = b})
		K.tween(s, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
	end
	local function jingle(best)
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

	local hatch, buy -- defined below
	local function finish()
		setHotbar(true)
		K.tween(backdrop, 0.25, {BackgroundTransparency = 1})
		clearStage()
		skipBtn.Holder.Visible = false
		task.wait(0.25)
		hatchGui.Enabled = false
		backdrop.BackgroundColor3 = DUSK
		hatching = false
		shop.Frame.Visible = true
		shop.Scale.Scale = 0.94
		K.tween(shop.Scale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
		if grids[selected] then
			refreshGrid(grids[selected])
		end
		refreshAfford()
		task.delay(0.05, redrawPictures)
	end
	-- the buttons under a finished hatch: back to the shop, or the same again
	local function endButtons(egg, count)
		local done = K.button({Text = count > 1 and "Close" or "Awesome!", Kind = "primary", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2 - 134, 636), Size = UDim2.fromOffset(250, 62), ZIndex = 44, Parent = ui})
		done.Activated:Connect(finish)
		local cost = egg.Price * count
		local again = K.button({Text = "Hatch " .. count .. " again", Sub = "$" .. fmt(cost), Kind = "secondary", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2 + 134, 636), Size = UDim2.fromOffset(250, 62), TextSize = 20, ZIndex = 44, Parent = ui})
		again.setEnabled(cash() >= cost)
		again.Activated:Connect(function()
			if buying then
				return
			end
			if cash() < cost then
				again.shake()
				again.setText("Hatch " .. count .. " again", "Need $" .. fmt(cost - cash()) .. " more", rgb(255, 196, 204))
				return
			end
			again.setBusy(true)
			local ok, err = buy(egg, count, nil, true)
			if not ok then
				again.setBusy(false)
				again.shake()
				if err then
					again.setText("Hatch " .. count .. " again", tostring(err), rgb(255, 196, 204))
				end
			end
		end)
	end

	-- ONE EGG: it flies in from the showcase, plays its own build-up and opening, and the pet comes out
	local HOME = Vector2.new(SW / 2, 300)
	local function hatchOne(egg, pet, from, isNew)
		local c = newCtx(egg, pet, 380, HOME, false)
		local style, tier, rar = c.Style, c.Tier, c.Rar
		if not skipNow then
			if from then
				c.Cell.Position = UDim2.fromOffset(from.X, from.Y)
				c.Cell.Size = UDim2.fromOffset(from.W, from.W)
				K.tween(c.Cell, 0.45, {Position = UDim2.fromOffset(HOME.X, HOME.Y), Size = UDim2.fromOffset(380, 380)}, Enum.EasingStyle.Quint)
			else
				c.Scale.Scale = 0.4
				K.tween(c.Scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
			end
			c:wait(0.45)
		end
		if style.Start and not skipNow then
			style.Start(c)
		end
		local dur = tier.Build * (style.Pace or 1)
		local t0 = os.clock()
		while not skipNow and c:alive() do
			local x = (os.clock() - t0) / dur
			if x >= 1 then
				break
			end
			c.X = x
			style.Build(c, x)
			sharedBuild(c, x)
			task.wait()
		end
		if not c:alive() then
			return
		end
		skipBtn.Holder.Visible = false
		if skipNow then
			c.Rig:fade(1)
		else
			style.Open(c)
			if tier.Ring then
				c:ring(rar.Color, 40, 460, 0.65, 8)
			end
			if tier.Flash then
				c:flash(rar.Color, 0.2)
			end
		end
		if not c:alive() then
			return
		end
		K.tween(backdrop, 0.5, {BackgroundColor3 = DUSK, BackgroundTransparency = 0.1})
		UI.sfx("hatch")
		reveal(c, pet, true)
		nameplate(pet, 498, isNew)
		if tier.Banner then
			banner(tier.Banner, rar.Color)
		end
		jingle(pet.R)
		if tier.Shake then
			c:shake(tier.Shake)
		end
		task.wait(quiet and 0 or 0.35)
		if c:alive() then
			endButtons(egg, 1)
		end
	end

	-- a close look at one pet of a batch, with arrows to flip through them
	local function closeUp(egg, results, index, onBack)
		clearStage()
		local pet = PetData.PETS[results[index].K]
		local rar = RARITIES[pet.R]
		local cell = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(HOME.X, HOME.Y), Size = UDim2.fromOffset(360, 360), BackgroundTransparency = 1, ZIndex = 3, Parent = stage})
		rays(cell, rar.Color, 1.8, pet.R >= 5 and 12 or 8, 2)
		local vp = petView(cell, pet, {Size = UDim2.fromScale(1, 1), ZIndex = 6, Zoom = 1.15, Sway = 1.1})
		local s = new("UIScale", {Scale = 0.6, Parent = vp})
		K.tween(s, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
		nameplate(pet, 498, false)
		K.text({Text = index .. " / " .. #results, TextSize = 20, TextColor3 = C.Text2, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2, 40), Size = UDim2.fromOffset(200, 26), ZIndex = 41, Parent = ui})
		for _, dir in ipairs({-1, 1}) do
			local b = K.iconButton({Icon = dir < 0 and "left" or "right", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(HOME.X + dir * 270, HOME.Y), Size = 64, ZIndex = 44, Parent = ui})
			b.Activated:Connect(function()
				closeUp(egg, results, (index - 1 + dir) % #results + 1, onBack)
			end)
		end
		local back = K.button({Text = "All pets", Kind = "ghost", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2, 636), Size = UDim2.fromOffset(250, 62), ZIndex = 44, Parent = ui})
		back.Activated:Connect(onBack)
	end

	hatch = function(egg, results, instant, fromVp)
		-- where the showcase egg is on screen, read before the shop hides
		local fromAbs
		if fromVp and fromVp.Parent and fromVp.AbsoluteSize.X > 0 then
			fromAbs = {Center = fromVp.AbsolutePosition + fromVp.AbsoluteSize / 2, W = fromVp.AbsoluteSize.X}
		end
		local isNew = {}
		local best = 1
		for i, res in ipairs(results) do
			best = math.max(best, PetData.PETS[res.K].R)
			isNew[i] = not discovered[res.K]
			discovered[res.K] = true
		end
		hatching = true
		skipNow = skipAnim or instant == true
		quiet = instant == true
		shop.Frame.Visible = false
		clearStage()
		hatchGui.Enabled = true
		setHotbar(false) -- the tool bar sat over the buttons
		skipBtn.Holder.Visible = not skipNow
		backdrop.BackgroundColor3 = DUSK
		K.tween(backdrop, 0.3, {BackgroundTransparency = 0.1})
		if #results == 1 then
			-- the showcase egg's spot in the stage's design pixels (the stage is laid out now it's enabled)
			local from
			if fromAbs and stageRoot.AbsoluteSize.X > 0 then
				local s = stageRoot.AbsoluteSize.X / SW
				local p = (fromAbs.Center - stageRoot.AbsolutePosition) / s
				from = {X = p.X, Y = p.Y, W = fromAbs.W / s}
			end
			hatchOne(egg, PetData.PETS[results[1].K], from, isNew[1])
			return
		end
		-- MANY EGGS at once in a grid; they share the build-up, each opens its own way
		local cells = {}
		local cols = 5
		for i, res in ipairs(results) do
			local col, row = (i - 1) % cols, (i - 1) // cols
			local c = newCtx(egg, PetData.PETS[res.K], 190, Vector2.new(SW / 2 + (col - 2) * 214, 190 + row * 236), true)
			c.Quiet = i > 1
			cells[i] = c
			if not skipNow then
				c.Scale.Scale = 0
				K.tween(c.Scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
				c:wait(0.04)
			end
		end
		local lead = cells[1]
		if not skipNow then
			lead:wait(0.3)
			for _, c in ipairs(cells) do
				if c.Style.Start then
					c.Style.Start(c)
				end
			end
		end
		local t0 = os.clock()
		while not skipNow and lead:alive() do
			local x = (os.clock() - t0) / 1.5
			if x >= 1 then
				break
			end
			for _, c in ipairs(cells) do
				c.X = x
				c.Style.Build(c, x)
				sharedBuild(c, x)
			end
			task.wait()
		end
		if not lead:alive() then
			return
		end
		skipBtn.Holder.Visible = false
		for _, c in ipairs(cells) do
			if skipNow then
				c.Rig:fade(1)
			else
				task.spawn(c.Style.Open, c)
				task.wait(0.05)
			end
		end
		lead:wait(0.45)
		if not lead:alive() then
			return
		end
		K.tween(backdrop, 0.5, {BackgroundColor3 = DUSK, BackgroundTransparency = 0.1})
		if not quiet then
			UI.sfx("hatch")
		end
		for i, c in ipairs(cells) do
			local pet = c.Pet
			reveal(c, pet, false)
			local rar = RARITIES[pet.R]
			K.text({Text = pet.N, TextSize = 17, TextColor3 = rar.Color:Lerp(WHITE, 0.45), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, 16, 0, 22), ZIndex = 26, Parent = c.Cell})
			if isNew[i] then
				K.chip({Text = "NEW", Color = C.Gold, TextSize = 13, Height = 22, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), ZIndex = 26, Parent = c.Cell})
			end
			local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 28, Parent = c.Cell})
			hit.Activated:Connect(function()
				closeUp(egg, results, i, function()
					hatch(egg, results, true)
				end)
			end)
			if not skipNow then
				task.wait(0.05)
			end
		end
		jingle(best)
		if best >= 5 and not quiet then
			lead:ring(RARITIES[best].Color, 60, 900, 0.7, 10)
		end
		K.text({Text = "Tap a pet to see it up close", TextSize = 19, TextColor3 = C.Text2, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(SW / 2, 36), Size = UDim2.fromOffset(600, 26), ZIndex = 41, Parent = ui})
		endButtons(egg, #results)
	end

	-- the server charges, rolls and saves before it answers; `buying` stops a double-press sending two purchases
	buy = function(egg, count, fromVp, again)
		if buying or (hatching and not again) then
			return false
		end
		local cost = egg.Price * count
		if cash() < cost then
			return false, "You need $" .. fmt(cost - cash()) .. " more"
		end
		buying = true
		local called, ok, res = pcall(petFunc.InvokeServer, petFunc, "buy", egg.Index, count)
		buying = false
		if not called then
			return false, "Couldn't reach the server, try again"
		elseif not ok then
			return false, tostring(res)
		end
		UI.sfx("buy")
		task.spawn(hatch, egg, res, false, fromVp)
		return true
	end
	for _, b in ipairs({{b1, 1}, {b10, PetData.HATCH_MANY}}) do
		b[1].Activated:Connect(function()
			local egg = EGGS[selected]
			if buying or hatching or not egg then
				return
			end
			b[1].setBusy(true)
			local ok, err = buy(egg, b[2], showcase.Vp)
			b[1].setBusy(false)
			if not ok and err then
				b[1].shake()
				showToast(err, C.Red)
			end
		end)
	end

	------------------------------------------------------------------
	-- the frame loop: the showcase egg turns, eggs on stage animate, particles move
	------------------------------------------------------------------
	RunService.RenderStepped:Connect(function(dt)
		-- the showcase egg turns at a constant rate (time-based, so frame rate never changes its speed). The camera and
		-- the light circle the egg instead of the egg turning: moving its ~100 parts every frame made Roblox redraw the
		-- picture only now and then and slowed the whole game; now only its orbiting / twinkling bits move
		if shop.Frame.Visible and showcase.Rig then
			showcase.Yaw += dt * 0.5
			aim(showcase.Cam, 16 - math.deg(showcase.Yaw), 13, 0.92, -0.15)
			showcase.Vp.LightDirection = CFrame.Angles(0, showcase.Yaw, 0) * Vector3.new(-0.5, -1, 0.7)
			showcase.Rig:step(dt, true)
		end
		if hatchGui.Enabled then
			for c in pairs(live) do
				c:step(dt)
			end
			fxBack:step(dt)
			fxFront:step(dt)
		end
		for f, speed in pairs(rotors) do
			if not f.Parent then
				rotors[f] = nil
			elseif UI.shown(f) then
				f.Rotation = (f.Rotation + dt * speed) % 360
			end
		end
		for vp, s in pairs(swaying) do
			if not vp.Parent then
				swaying[vp] = nil
			elseif UI.shown(vp) then
				s.Angle += dt * s.Speed
				s.Model:PivotTo(s.Base * CFrame.Angles(0, math.sin(s.Angle) * 0.6, 0))
			end
		end
	end)

	-- opening the shop: the egg you last looked at, or the best one you can afford
	local function open()
		if hatching or shop.Frame.Visible then
			return
		end
		owned()
		if not opened then
			opened = true
			local pick = 1
			for i, egg in ipairs(EGGS) do
				if cash() >= egg.Price then
					pick = i
				end
			end
			select(pick)
		else
			refreshGrid(gridFor(EGGS[selected]))
			refreshAfford()
		end
		toast.Visible = false
		shop.Open()
		task.delay(0.05, redrawPictures)
	end
	d.OpenEvent.OnClientEvent:Connect(open)

	-- arrow keys / Q and E flip through the eggs while the shop is open
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not shop.Frame.Visible or hatching then
			return
		end
		local k = input.KeyCode
		if (k == Enum.KeyCode.Left or k == Enum.KeyCode.Q) and selected > 1 then
			select(selected - 1)
		elseif (k == Enum.KeyCode.Right or k == Enum.KeyCode.E) and selected < #EGGS then
			select(selected + 1)
		end
	end)

	-- Studio only: play a hatch with made-up results (nothing is bought or saved)
	if RunService:IsStudio() then
		local preview = Instance.new("BindableEvent")
		preview.Name = "HatchPreview"
		preview.Parent = hatchGui
		preview.Event:Connect(function(eggIndex, keys, opts)
			local egg = EGGS[eggIndex]
			if not egg or hatching then
				return
			end
			local results = {}
			for i, key in ipairs(keys) do
				results[i] = {I = -i, K = key}
			end
			if opts == "fromShop" and not shop.Frame.Visible then
				open()
				select(eggIndex)
				task.wait(0.4)
			end
			hatch(egg, results, false, shop.Frame.Visible and showcase.Vp or nil)
			if opts == "auto" then
				task.wait(1.2)
				finish()
			end
		end)
	end
end

return H

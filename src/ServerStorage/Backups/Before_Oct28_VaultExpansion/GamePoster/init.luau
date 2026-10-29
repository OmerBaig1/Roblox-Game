--[[
	GamePoster
	Draws cover art for a game. Used on the games in the world (server) and in the Index (client).
	Every game gets its own colors and picture, picked from its name, so the same game always
	looks the same everywhere.

	GamePoster.Create({Name = "Sea of Robbers", Rarity = "Epic", Color = Color3}) -> Frame
]]

local GamePoster = {}

local function hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

local function box(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end

local function circle(parent, props)
	local f = box(parent, props)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f
	return f
end

local function gradient(parent, a, b, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function text(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	for k, v in pairs(props) do
		t[k] = v
	end
	t.Parent = parent
	return t
end

-- Picture styles
local ART = {}

-- Retro sunset: a big striped sun on the horizon
function ART.sun(art, rng, c1, c2)
	local sun = circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(0.85, 0.85 * 0.8), BackgroundColor3 = Color3.new(1, 1, 1)})
	sun.SizeConstraint = Enum.SizeConstraint.RelativeXX
	sun.Size = UDim2.fromScale(0.8, 0.8)
	gradient(sun, c2, c1, 90)
	for i = 0, 3 do
		box(art, {Position = UDim2.fromScale(0, 0.62 + i * 0.09), Size = UDim2.fromScale(1, 0.025 + i * 0.008), BackgroundColor3 = c1:Lerp(Color3.new(0, 0, 0), 0.6)})
	end
	box(art, {Position = UDim2.fromScale(0, 0.95), Size = UDim2.fromScale(1, 0.05), BackgroundColor3 = c1:Lerp(Color3.new(0, 0, 0), 0.6)})
end

-- Planet with a ring
function ART.planet(art, rng, c1, c2)
	local x, y = rng:NextNumber(0.4, 0.6), rng:NextNumber(0.45, 0.6)
	local planet = circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(0.55, 0.55), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1)})
	gradient(planet, c2, c1, 45)
	local ring = circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.new(0.95, 0, 0.08, 0), BackgroundColor3 = c2:Lerp(Color3.new(1, 1, 1), 0.5), BackgroundTransparency = 0.15})
	ring.ZIndex = 2
	circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x + 0.32, y - 0.25), Size = UDim2.fromScale(0.12, 0.12), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = c2})
end

-- City skyline with lit windows
function ART.skyline(art, rng, c1, c2)
	circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0.25, 0.75), 0.3), Size = UDim2.fromScale(0.3, 0.3), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = c2})
	local x = 0
	while x < 1 do
		local w = rng:NextNumber(0.1, 0.2)
		local h = rng:NextNumber(0.25, 0.65)
		local b = box(art, {Position = UDim2.fromScale(x, 1 - h), Size = UDim2.fromScale(w - 0.01, h), BackgroundColor3 = c1:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0.45, 0.7))})
		b.ZIndex = 2
		for wy = 0.1, 0.8, 0.22 do
			if rng:NextNumber() < 0.6 then
				local win = box(b, {Position = UDim2.fromScale(0.25, wy), Size = UDim2.fromScale(0.5, 0.08), BackgroundColor3 = c2})
				win.ZIndex = 3
			end
		end
		x += w
	end
end

-- Floating bubbles / orbs
function ART.orbs(art, rng, c1, c2)
	for _ = 1, 9 do
		local s = rng:NextNumber(0.1, 0.35)
		local o = circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.15, 0.95)), Size = UDim2.fromScale(s, s), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = rng:NextNumber(0, 0.4)})
		gradient(o, c2, c1:Lerp(c2, 0.3), rng:NextInteger(0, 360))
	end
end

-- Hills and a road to the horizon
function ART.hills(art, rng, c1, c2)
	circle(art, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0.2, 0.8), 0.28), Size = UDim2.fromScale(0.22, 0.22), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = c2})
	for i = 1, 3 do
		local hill = circle(art, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(rng:NextNumber(0, 1), 0.5 + i * 0.1), Size = UDim2.fromScale(rng:NextNumber(0.9, 1.4), 0.8), BackgroundColor3 = c1:Lerp(Color3.new(0, 0, 0), 0.25 + i * 0.15)})
		hill.ZIndex = i + 1
	end
end

local STYLES = {"sun", "planet", "skyline", "orbs", "hills"}

------------------------------------------------------------------
-- DRAWING KIT for hand-made posters (see the modules inside GamePoster.Art)
-- All positions are the CENTER of the shape, in 0-1 of the picture area.
-- rect/ellipse sizes are 0-1 of width and height; circle size is 0-1 of width.
-- Shapes drawn later appear on top. opts: {rot = degrees, t = transparency,
-- round = 0-1 corner roundness, grad = {colorA, colorB, rotation}}
------------------------------------------------------------------
local ASPECT = 0.775 -- picture height / width

local function makeKit(art)
	local kit = {ASPECT = ASPECT}
	local z = 0

	local function shape(props, opts)
		opts = opts or {}
		z += 1
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z
		f.Rotation = opts.rot or 0
		f.BackgroundTransparency = opts.t or 0
		for k, v in pairs(props) do
			f[k] = v
		end
		if opts.round then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(opts.round, 0)
			c.Parent = f
		end
		if opts.grad then
			gradient(f, opts.grad[1], opts.grad[2], opts.grad[3] or 90)
		end
		f.Parent = art
		return f
	end

	local function with(opts, key, value)
		local copy = {}
		for k, v in pairs(opts or {}) do
			copy[k] = v
		end
		copy[key] = value
		return copy
	end

	function kit.sky(top, bottom)
		return shape({Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1)}, {grad = {top, bottom, 90}})
	end

	function kit.rect(cx, cy, w, h, color, opts)
		return shape({Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(w, h), BackgroundColor3 = color}, opts)
	end

	function kit.ellipse(cx, cy, w, h, color, opts)
		return kit.rect(cx, cy, w, h, color, with(opts, "round", 1))
	end

	function kit.circle(cx, cy, d, color, opts)
		return shape({Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(d, d), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = color}, with(opts, "round", 1))
	end

	function kit.text(cx, cy, w, h, str, color, opts)
		opts = opts or {}
		z += 1
		local t = Instance.new("TextLabel")
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(cx, cy)
		t.Size = UDim2.fromScale(w, h)
		t.BackgroundTransparency = 1
		t.Font = opts.font or Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = str
		t.TextColor3 = color
		t.TextTransparency = opts.t or 0
		t.TextStrokeTransparency = opts.stroke and 0.2 or 1
		t.Rotation = opts.rot or 0
		t.ZIndex = z
		t.Parent = art
		return t
	end

	-- A row of round wave tops at height y, filled solid below
	function kit.waves(y, color, d, opts)
		d = d or 0.14
		kit.rect(0.5, (y + 1) / 2 + 0.01, 1.04, 1 - y + 0.02, color, opts)
		local x = -0.03
		while x <= 1.05 do
			kit.circle(x, y, d, color, opts)
			x += d * 0.85
		end
	end

	-- Scattered little stars in the top part of the picture
	function kit.stars(count, rng, maxY)
		for _ = 1, count do
			kit.circle(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.04, maxY or 0.5), rng:NextNumber(0.012, 0.025), Color3.new(1, 1, 1), {t = rng:NextNumber(0, 0.5)})
		end
	end

	return kit
end

-- Hand-made posters, loaded from every ModuleScript inside GamePoster.Art (the module's name is the poster family)
local CUSTOM, FAMILY = {}, {}
local artFolder = script:FindFirstChild("Art")
if artFolder then
	for _, mod in ipairs(artFolder:GetChildren()) do
		if mod:IsA("ModuleScript") then
			local ok, result = pcall(require, mod)
			if ok and type(result) == "table" then
				for name, draw in pairs(result) do
					CUSTOM[name] = draw
					FAMILY[name] = mod.Name
				end
			else
				warn("[GamePoster] Couldn't load " .. mod.Name .. ": " .. tostring(result))
			end
		end
	end
end

------------------------------------------------------------------
-- THE COVER: every poster family has a title treatment like a real game logo (its own font, a two-tone fill and
-- a dark outline) and a colour grade for the light over its art. A few games borrow another family's look.
------------------------------------------------------------------
local rgb, F = Color3.fromRGB, Enum.Font
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local THEMES = {
	Haunted = {Font = F.Creepster, Fill = {rgb(255, 80, 70), rgb(150, 10, 20)}, Edge = rgb(25, 0, 0), Grade = rgb(25, 45, 25)},
	Arcade = {Font = F.LuckiestGuy, Fill = {rgb(255, 245, 110), rgb(255, 140, 30)}, Edge = rgb(70, 20, 0), Grade = rgb(60, 20, 90)},
	Toys = {Font = F.LuckiestGuy, Fill = {WHITE, rgb(175, 220, 255)}, Edge = rgb(40, 20, 90), Grade = rgb(35, 20, 85)},
	Cyber = {Font = F.Michroma, Fill = {rgb(130, 255, 255), rgb(255, 70, 210)}, Edge = rgb(10, 0, 30), Grade = rgb(60, 0, 90)},
	Dragon = {Font = F.GrenzeGotisch, Fill = {rgb(255, 238, 170), rgb(205, 135, 35)}, Edge = rgb(40, 15, 0), Grade = rgb(70, 25, 10)},
	Ninja = {Font = F.Bangers, Fill = {WHITE, rgb(255, 125, 115)}, Edge = rgb(60, 0, 10), Grade = rgb(80, 10, 25)},
	Robots = {Font = F.Sarpanch, Fill = {rgb(240, 245, 255), rgb(130, 150, 178)}, Edge = rgb(12, 18, 30), Grade = rgb(15, 35, 70)},
	Space = {Font = F.Oswald, Fill = {WHITE, rgb(140, 195, 255)}, Edge = rgb(5, 10, 40), Grade = rgb(10, 20, 75)},
	Pirate = {Font = F.Fondamento, Fill = {rgb(255, 232, 175), rgb(212, 150, 60)}, Edge = rgb(40, 20, 5), Grade = rgb(8, 40, 60)},
	Bargain = {Font = F.FredokaOne, Fill = {WHITE, rgb(255, 222, 125)}, Edge = rgb(50, 30, 10), Grade = rgb(45, 30, 15)},
	-- chrome gothic letters with a blood-red edge
	Chrome = {Font = F.GrenzeGotisch, Fill = {WHITE, rgb(150, 160, 178)}, Edge = rgb(130, 0, 15), Grade = rgb(50, 10, 40)},
}
local THEME_FOR = {["Five Nights at Teddy's"] = "Haunted", ["Devil May Nubs V"] = "Chrome"}
local PLAIN = {Font = F.FredokaOne, Fill = {WHITE, rgb(220, 225, 240)}, Edge = rgb(10, 10, 20), Grade = rgb(20, 20, 40)}

-- 1 = Common ... the order in the game's RarityData; rarer covers get a metal frame (5+) and a foil sheen (6+)
local tierOf
local function rarityTier(name)
	if not tierOf then
		tierOf = {}
		local v = game:GetService("ReplicatedStorage"):FindFirstChild("RarityData")
		local ok, list = pcall(function()
			return game:GetService("HttpService"):JSONDecode(v.Value)
		end)
		for i, r in ipairs(ok and list or {}) do
			tierOf[r.Name] = i
		end
	end
	return tierOf[name] or 1
end

-- a full-size layer whose transparency follows a gradient (the light and shadow passes)
local function layer(parent, color, z, rotation, keys)
	local f = box(parent, {Name = "Light", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color})
	f.ZIndex = z
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	local seq = {}
	for _, k in ipairs(keys) do
		table.insert(seq, NumberSequenceKeypoint.new(k[1], k[2]))
	end
	g.Transparency = NumberSequence.new(seq)
	g.Parent = f
	return f
end

-- for the case packaging (CasePackaging draws its back-cover screenshots with the same kit)
GamePoster.makeKit = makeKit
function GamePoster.family(name)
	return FAMILY[name]
end

function GamePoster.Create(info)
	local seed = hash(info.Name)
	local rng = Random.new(seed)
	local hue = (seed % 360) / 360
	local c1 = Color3.fromHSV(hue, 0.65, 0.85)
	local c2 = Color3.fromHSV((hue + rng:NextNumber(0.12, 0.45)) % 1, 0.55, 1)
	local rarityColor = info.Color or WHITE
	local theme = THEMES[THEME_FOR[info.Name] or FAMILY[info.Name]] or PLAIN
	local tier = rarityTier(info.Rarity)

	local root = box(nil, {Name = "Poster", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ClipsDescendants = true})
	gradient(root, rgb(10, 10, 16), theme.Grade:Lerp(BLACK, 0.4), 90)

	-- Picture
	local art = box(root, {Name = "Art", Position = UDim2.fromScale(0, 0.09), Size = UDim2.fromScale(1, 0.62), BackgroundTransparency = 1, ClipsDescendants = true})
	local custom = CUSTOM[info.Name]
	local drewCustom = false
	if custom then
		local ok, err = pcall(custom, makeKit(art), rng)
		if ok then
			drewCustom = true
		else
			warn("[GamePoster] Art for " .. info.Name .. " failed: " .. tostring(err))
			art:ClearAllChildren()
		end
	end
	if not drewCustom then
		for _ = 1, 10 do
			circle(art, {Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber(0, 0.6)), Size = UDim2.fromScale(0.02, 0.02), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = WHITE, BackgroundTransparency = rng:NextNumber(0, 0.5)})
		end
		ART[STYLES[seed % #STYLES + 1]](art, rng, c1, c2)
	end

	-- Light over the picture, like a lit cover instead of flat colour: a soft key light from the top left, the
	-- family's colour grade rising out of the bottom, darker edges, and the bottom melting into the title
	layer(art, WHITE, 900, 45, {{0, 0.82}, {0.3, 1}, {1, 1}})
	layer(art, theme.Grade, 901, 90, {{0, 1}, {0.45, 1}, {1, 0.35}})
	layer(art, BLACK, 902, 0, {{0, 0.45}, {0.16, 1}, {0.84, 1}, {1, 0.45}})
	layer(art, BLACK, 903, 90, {{0, 0.55}, {0.14, 1}, {0.78, 1}, {1, 0.05}})
	if tier >= 6 then
		-- foil: a bright band across the picture
		layer(art, WHITE, 904, 35, {{0, 1}, {0.44, 1}, {0.5, 0.72}, {0.56, 1}, {1, 1}})
	end

	-- Top bar with the rarity
	local top = box(root, {Name = "TopBar", Size = UDim2.fromScale(1, 0.09), BackgroundColor3 = WHITE})
	top.ZIndex = 5
	gradient(top, rgb(22, 22, 30), rgb(8, 8, 12), 90)
	local r = text(top, {Size = UDim2.fromScale(0.9, 0.72), Position = UDim2.fromScale(0.05, 0.14), Text = string.upper(info.Rarity or ""), TextColor3 = tier >= 5 and WHITE or rarityColor, TextStrokeTransparency = 1, Font = Enum.Font.GothamBlack})
	r.ZIndex = 6
	if tier >= 5 then
		gradient(r, rarityColor:Lerp(WHITE, 0.55), rarityColor, 90)
	end
	local line = box(top, {Position = UDim2.fromScale(0, 0.92), Size = UDim2.fromScale(1, 0.08), BackgroundColor3 = rarityColor})
	line.ZIndex = 6

	-- Title: the family's logo look
	local titleBack = box(root, {Name = "TitleBar", Position = UDim2.fromScale(0, 0.71), Size = UDim2.fromScale(1, 0.24), BackgroundColor3 = WHITE})
	titleBack.ZIndex = 5
	gradient(titleBack, rgb(4, 4, 8), theme.Grade:Lerp(BLACK, 0.55), 90)
	local title = text(titleBack, {Size = UDim2.fromScale(0.92, 0.82), Position = UDim2.fromScale(0.04, 0.08), Text = info.Name, Font = theme.Font,
		TextColor3 = WHITE, TextStrokeColor3 = theme.Edge, TextStrokeTransparency = 0})
	title.ZIndex = 6
	gradient(title, theme.Fill[1], theme.Fill[2], 90)

	-- Rarity stripe at the bottom
	local stripe = box(root, {Name = "Stripe", Position = UDim2.fromScale(0, 0.95), Size = UDim2.fromScale(1, 0.05), BackgroundColor3 = WHITE})
	stripe.ZIndex = 5
	gradient(stripe, rarityColor:Lerp(WHITE, tier >= 5 and 0.45 or 0.15), rarityColor, 0)

	-- A frame in the rarity's colour round the whole cover (polished metal from Legendary up). Sized by scale so
	-- it reads the same on a display case and in the Index.
	for _, e in ipairs({{0, 0, 1, 0.012}, {0, 0.988, 1, 0.012}, {0, 0, 0.016, 1}, {0.984, 0, 0.016, 1}}) do
		local edge = box(root, {Name = "Frame", Position = UDim2.fromScale(e[1], e[2]), Size = UDim2.fromScale(e[3], e[4]), BackgroundColor3 = WHITE})
		edge.ZIndex = 7
		if tier >= 5 then
			gradient(edge, rarityColor:Lerp(WHITE, 0.7), rarityColor:Lerp(BLACK, 0.2), 45)
		else
			edge.BackgroundColor3 = rarityColor:Lerp(BLACK, 0.25)
		end
	end

	return root
end

return GamePoster

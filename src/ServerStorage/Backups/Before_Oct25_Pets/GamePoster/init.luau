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

-- Hand-made posters, loaded from every ModuleScript inside GamePoster.Art
local CUSTOM = {}
local artFolder = script:FindFirstChild("Art")
if artFolder then
	for _, mod in ipairs(artFolder:GetChildren()) do
		if mod:IsA("ModuleScript") then
			local ok, result = pcall(require, mod)
			if ok and type(result) == "table" then
				for name, draw in pairs(result) do
					CUSTOM[name] = draw
				end
			else
				warn("[GamePoster] Couldn't load " .. mod.Name .. ": " .. tostring(result))
			end
		end
	end
end

function GamePoster.Create(info)
	local seed = hash(info.Name)
	local rng = Random.new(seed)
	local hue = (seed % 360) / 360
	local c1 = Color3.fromHSV(hue, 0.65, 0.85)
	local c2 = Color3.fromHSV((hue + rng:NextNumber(0.12, 0.45)) % 1, 0.55, 1)
	local rarityColor = info.Color or Color3.new(1, 1, 1)

	local root = box(nil, {Name = "Poster", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true})
	gradient(root, Color3.fromHSV(hue, 0.7, 0.25), Color3.fromHSV((hue + 0.08) % 1, 0.6, 0.7), 90)

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
			circle(art, {Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber(0, 0.6)), Size = UDim2.fromScale(0.02, 0.02), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = rng:NextNumber(0, 0.5)})
		end
		ART[STYLES[seed % #STYLES + 1]](art, rng, c1, c2)
	end

	-- Top bar with the rarity
	local top = box(root, {Name = "TopBar", Size = UDim2.fromScale(1, 0.09), BackgroundColor3 = Color3.fromRGB(15, 15, 20)})
	top.ZIndex = 5
	local r = text(top, {Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), Text = string.upper(info.Rarity or ""), TextColor3 = rarityColor, TextStrokeTransparency = 1})
	r.ZIndex = 6

	-- Title
	local titleBack = box(root, {Name = "TitleBar", Position = UDim2.fromScale(0, 0.71), Size = UDim2.fromScale(1, 0.24), BackgroundColor3 = Color3.fromRGB(12, 12, 18)})
	titleBack.ZIndex = 5
	gradient(titleBack, Color3.fromRGB(12, 12, 18), Color3.fromHSV(hue, 0.5, 0.2), 90)
	local title = text(titleBack, {Size = UDim2.fromScale(0.92, 0.84), Position = UDim2.fromScale(0.04, 0.08), Text = info.Name, TextColor3 = c2:Lerp(Color3.new(1, 1, 1), 0.6), TextStrokeColor3 = Color3.new(0, 0, 0)})
	title.ZIndex = 6

	-- Rarity stripe at the bottom
	local stripe = box(root, {Name = "Stripe", Position = UDim2.fromScale(0, 0.95), Size = UDim2.fromScale(1, 0.05), BackgroundColor3 = rarityColor})
	stripe.ZIndex = 5

	return root
end

return GamePoster

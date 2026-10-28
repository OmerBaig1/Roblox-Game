--[[
	STEAL A GAME - TREADMILL MODELS
	What the treadmill looks like at every level: a different machine for each level, from the
	Starter Jogger (level 0) to the Cosmic Emperor (level 40, MAX). Only looks live here. Speed gains,
	prices and saving stay in Config and the main script, so a design can be any shape without
	touching gameplay. Base.rebuildTreadmill calls TreadModels.build whenever the level changes.

	Designs are built in "design space" around the belt: x is to the runner's right, y is up from
	the top of the pad, z points to the runner's back (the runner faces -z, toward the console).
	The belt runs from z = -4.5 to 4.5 and the runner stands at z = 0.

	Every design stays inside ENVELOPE so the runner is never hidden (UnitTest TreadModels_Test
	builds every level and checks this):
	  - nothing over the belt where the runner stands
	  - beside the belt: nothing higher than the runner's hip
	  - straight in front of the runner: console height, or high above their head (tall pieces go
	    to the sides); see-through parts are allowed there
	  - behind the belt: low, so the camera behind the runner looks over it
]]

local TM = {}

local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

-- design space sits at the top of the pad, over the belt's centre (relative to the plot's TreadCF)
TM.ORIGIN = CFrame.new(0, 1, -10)
-- the belt: 8 slats whose centres run from z = -4 to 4, top at y = 0.7
TM.SLAT_COUNT, TM.SLAT_GAP = 8, 1
TM.BELT_START = -4
TM.SLAT_Y = 0.575
TM.BELT_TOP = 0.7

TM.ENVELOPE = {
	HalfW = 4.8, FrontZ = -9.4, BackZ = 7.6, MaxY = 9.2, -- the whole machine fits on the pad
	RunnerHalfW = 2.2, BeltHalfL = 4.5,                  -- the runner's space over the belt
	SideMaxY = 3.4,                                      -- beside the belt
	FrontLowY = 4.6, FrontHighY = 7.2,                   -- straight in front: below the first or above the second
	SeeThrough = 0.6,                                    -- parts at least this transparent may go in front
	BackMaxY = 2.4,                                      -- behind the belt
	MaxParts = 165, MaxLights = 2, MaxEmitters = 2, -- parts include the tier stage (~30); only the MAX machine needs > 100
}

------------------------------------------------------------------
-- BUILD KIT: every helper takes design-space positions and sizes. Options (o):
-- rx/ry/rz = turn in degrees, t = transparency, refl = reflectance, solid = people can stand on it, name
------------------------------------------------------------------
local AXIS = {x = CFrame.new(), y = CFrame.Angles(0, 0, math.pi / 2), z = CFrame.Angles(0, math.pi / 2, 0)}

local function newKit(model, origin, slats)
	local k = {rgb = rgb, M = M, WHITE = WHITE, BLACK = BLACK}
	local function turn(o)
		return CFrame.Angles(math.rad(o.rx or 0), math.rad(o.ry or 0), math.rad(o.rz or 0))
	end
	local function make(class, cf, size, color, mat, o)
		local p = Instance.new(class)
		if o.shape then
			p.Shape = o.shape
		end
		p.Size = size
		p.CFrame = origin * cf
		p.Color = color
		p.Material = mat or M.SmoothPlastic
		p.Transparency = o.t or 0
		p.Reflectance = o.refl or 0
		p.Anchored = true
		-- decorations never block anyone, or the treadmill prompts
		p.CanCollide = o.solid == true
		p.CanQuery = o.solid == true
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Name = o.name or (p.Material == M.Neon and "Glow" or "Part")
		p.Parent = model
		return p
	end

	function k.box(x, y, z, sx, sy, sz, color, mat, o)
		o = o or {}
		return make("Part", CFrame.new(x, y, z) * turn(o), Vector3.new(sx, sy, sz), color, mat, o)
	end
	function k.glow(x, y, z, sx, sy, sz, color, o)
		return k.box(x, y, z, sx, sy, sz, color, M.Neon, o)
	end
	-- a wedge is tall at its +z end and slopes down toward -z
	function k.wedge(x, y, z, sx, sy, sz, color, mat, o)
		o = o or {}
		return make("WedgePart", CFrame.new(x, y, z) * turn(o), Vector3.new(sx, sy, sz), color, mat, o)
	end
	function k.ball(x, y, z, d, color, mat, o)
		o = o or {}
		o.shape = Enum.PartType.Ball
		return make("Part", CFrame.new(x, y, z) * turn(o), Vector3.new(d, d, d), color, mat, o)
	end
	-- a cylinder `len` long along `axis` ("x", "y" or "z"; turned by o first)
	function k.cyl(x, y, z, len, d, color, mat, axis, o)
		o = o or {}
		o.shape = Enum.PartType.Cylinder
		return make("Part", CFrame.new(x, y, z) * turn(o) * AXIS[axis or "x"], Vector3.new(len, d, d), color, mat, o)
	end
	-- a ring (or an arc of one) made of o.n segments (default 16) around `axis`. Angles a0..a1 in degrees:
	-- 0 is the top (+z for a flat "y" ring) and they run anticlockwise seen from the + end of the axis.
	-- `color` can be a function of how far round the arc (0..1) for gradients. thick is radial, o.depth along the axis.
	function k.ring(x, y, z, r, thick, color, mat, axis, o)
		o = o or {}
		local n, a0, a1 = o.n or 16, math.rad(o.a0 or 0), math.rad(o.a1 or 360)
		local depth = o.depth or thick
		local seg = r * math.abs(a1 - a0) / n * 1.1
		local base = CFrame.new(x, y, z) * turn(o)
		local parts = {}
		for i = 0, n - 1 do
			local f = (i + 0.5) / n
			local a = a0 + f * (a1 - a0)
			local cf, size
			if axis == "x" then
				cf, size = base * CFrame.Angles(a, 0, 0) * CFrame.new(0, r, 0), Vector3.new(depth, thick, seg)
			elseif axis == "y" then
				cf, size = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, r), Vector3.new(seg, depth, thick)
			else
				cf, size = base * CFrame.Angles(0, 0, a) * CFrame.new(0, r, 0), Vector3.new(seg, thick, depth)
			end
			table.insert(parts, make("Part", cf, size, type(color) == "function" and color(f) or color, mat, {t = o.t, refl = o.refl, name = o.name or "Ring"}))
		end
		return parts
	end
	-- turns `parts` for ever around `axis` (a Vector3 in the frame at x, y, z turned by o), `speed` in radians a
	-- second. Only tags them: the client spins every "TreadSpin" model, so the server sends nothing per frame.
	function k.spin(parts, x, y, z, axis, speed, o)
		local m = Instance.new("Model")
		m.Name = "Spin"
		for _, p in ipairs(parts) do
			p.Parent = m
		end
		m.WorldPivot = origin * CFrame.new(x, y, z) * turn(o or {})
		m:SetAttribute("SpinAxis", axis)
		m:SetAttribute("SpinSpeed", speed)
		m:AddTag("TreadSpin")
		m.Parent = model
		return m
	end
	-- build something on both sides: fn(-1) on the runner's left, fn(1) on the right
	function k.m(fn)
		fn(-1)
		fn(1)
	end
	function k.light(p, color, range, brightness)
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = range or 10
		l.Brightness = brightness or 1
		l.Shadows = false
		l.Parent = p
		return l
	end
	-- gentle effects: "sparkle" (twinkles all round), "rise" (bubbles or embers drifting up),
	-- "smoke" (slow puffs going up), "fire"
	function k.fx(p, kind, c1, c2)
		if kind == "fire" then
			local f = Instance.new("Fire")
			f.Color, f.SecondaryColor = c1, c2 or c1
			f.Size, f.Heat = 2.5, 6
			f.Parent = p
			return f
		end
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(c1, c2 or c1)
		e.LightEmission = 0.8
		if kind == "smoke" then
			e.Texture = "rbxasset://textures/particles/smoke_main.dds"
			e.Size = NumberSequence.new(1, 3)
			e.Transparency = NumberSequence.new(0.5, 1)
			e.Lifetime = NumberRange.new(2, 3)
			e.Speed = NumberRange.new(1.5, 2.5)
			e.Rate = 4
			e.LightEmission = 0
			e.EmissionDirection = Enum.NormalId.Top
		else
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Size = NumberSequence.new(kind == "rise" and 0.35 or 0.45, 0)
			e.Lifetime = NumberRange.new(1, 2)
			e.Speed = kind == "rise" and NumberRange.new(1.5, 3) or NumberRange.new(0.3, 1)
			e.SpreadAngle = kind == "rise" and Vector2.new(15, 15) or Vector2.new(180, 180)
			e.EmissionDirection = Enum.NormalId.Top
			e.Rate = 8
			e.Shape = Enum.ParticleEmitterShape.Box
		end
		e.Parent = p
		return e
	end
	-- writing on one face of a part ("Front" faces -z, out to the lobby; "Back" faces the runner)
	function k.text(p, face, text, color, pixelsPerStud)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId[face]
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = pixelsPerStud or 40
		sg.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(0.9, 0.84)
		t.Position = UDim2.fromScale(0.05, 0.08)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = color
		t.TextStrokeTransparency = 0.4
		t.Text = text
		t.Parent = sg
		sg.Parent = p
		return t
	end
	-- the running belt every design needs: colours repeat along the slats (two for stripes, more for a pattern)
	function k.belt(colors, mat, width)
		for i = 1, TM.SLAT_COUNT do
			local z = TM.BELT_START + (i - 1) * TM.SLAT_GAP
			table.insert(slats, k.box(0, TM.SLAT_Y, z, width or 4, 0.25, TM.SLAT_GAP - 0.08, colors[(i - 1) % #colors + 1], mat, {name = "Slat"}))
		end
	end
	-- the solid slab under the belt (you can walk across it)
	function k.deck(width, color, mat)
		return k.box(0, 0.225, 0, width, 0.45, 10, color, mat, {solid = true, name = "Deck"})
	end
	return k
end

------------------------------------------------------------------
-- THE MACHINES, in unlock order (entry 1 is level 0)
------------------------------------------------------------------
local MODELS = {}
TM.MODELS = MODELS
local function add(name, build)
	table.insert(MODELS, {Name = name, Build = build})
end

-- 0: a plain home-gym treadmill
add("Starter Jogger", function(k)
	local frame, dark, steel, blue = rgb(78, 84, 96), rgb(52, 56, 66), rgb(160, 166, 178), rgb(80, 170, 255)
	k.deck(4.8, frame, M.SmoothPlastic)
	k.belt({rgb(32, 32, 38), rgb(44, 44, 52)}, M.Fabric, 4.3)
	k.box(0, 0.6, -5.6, 4.8, 1.2, 1.6, frame, M.SmoothPlastic, {solid = true, name = "MotorHood"})
	k.cyl(0, 0.4, 5.15, 4.8, 0.8, dark, M.Metal)
	k.m(function(s)
		k.box(s * 2.6, 0.5, 0, 0.4, 0.8, 10.2, dark, M.SmoothPlastic)
		k.glow(s * 2.82, 0.55, 0, 0.05, 0.14, 9.4, blue)
		k.box(s * 2.55, 2.4, -5.4, 0.35, 3.6, 0.35, steel, M.Metal)
		k.box(s * 2.55, 3.05, -3.3, 0.25, 0.25, 4.2, steel, M.Metal)
		k.box(s * 2.55, 3.05, -1.3, 0.34, 0.34, 0.6, rgb(30, 30, 34), M.SmoothPlastic)
	end)
	k.box(0, 3.85, -5.45, 5.4, 1.1, 0.45, dark, M.SmoothPlastic, {name = "Console"})
	local screen = k.glow(0, 3.9, -5.2, 2.4, 0.62, 0.06, rgb(40, 110, 170))
	k.text(screen, "Back", "GO!", WHITE)
	k.glow(0, 4.45, -5.45, 5.4, 0.1, 0.45, blue)
end)

-- 1: hand-built from timber, with an A-frame and rope rails
add("Timber Trotter", function(k)
	local wood, light, rope = rgb(120, 78, 45), rgb(170, 120, 70), rgb(205, 175, 115)
	k.deck(4.8, wood, M.WoodPlanks)
	k.belt({rgb(150, 105, 60), rgb(128, 88, 50)}, M.Wood, 4.2)
	k.m(function(s)
		k.box(s * 3.1, 3.8, -5.6, 0.6, 7.6, 0.6, wood, M.Wood, {rz = s * 6})
		k.box(s * 3.2, 0.3, -5.6, 1.4, 0.6, 1.6, light, M.WoodPlanks) -- post feet
		k.box(s * 2.6, 1.6, 1.2, 0.35, 2.6, 0.35, wood, M.Wood)
		k.box(s * 2.6, 2.9, -2.1, 0.18, 0.18, 6.8, rope, M.Fabric)
		local lamp = k.ball(s * 2.75, 6.6, -5.6, 0.7, rgb(255, 200, 100), M.Neon)
		k.box(s * 2.75, 7.1, -5.6, 0.08, 0.5, 0.08, BLACK, M.Metal)
		if s > 0 then
			k.light(lamp, rgb(255, 190, 110), 12, 1)
		end
	end)
	k.box(0, 7.7, -5.6, 6.6, 0.6, 0.6, wood, M.Wood, {name = "Crossbeam"})
	local sign = k.box(0, 8.55, -5.6, 3.6, 1.1, 0.2, light, M.WoodPlanks)
	k.text(sign, "Front", "TROT ON!", rgb(70, 40, 20))
	k.text(sign, "Back", "TROT ON!", rgb(70, 40, 20))
	k.box(0, 1.2, -5.8, 3.2, 1.9, 1.4, light, M.WoodPlanks, {name = "Crate"})
	k.box(3.7, 0.6, 6.2, 1.6, 1.2, 1.2, rgb(220, 190, 95), M.Grass, {name = "HayBale"})
	k.cyl(-3.9, 0.8, -7.8, 1.6, 1.3, light, M.Wood, "y")
	k.cyl(-3.9, 0.45, -7.8, 0.2, 1.4, rgb(60, 60, 65), M.Metal, "y")
	k.cyl(-3.9, 1.2, -7.8, 0.2, 1.4, rgb(60, 60, 65), M.Metal, "y")
end)

-- 2: an arcade cabinet between two speaker towers, under a glowing marquee
add("Retro Arcade", function(k)
	local cab, pink, cyan = rgb(60, 25, 120), rgb(255, 60, 170), rgb(60, 240, 230)
	k.deck(5, rgb(20, 20, 26), M.SmoothPlastic)
	k.belt({rgb(18, 18, 22), rgb(235, 235, 235)}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.glow(s * 2.55, 0.47, 0, 0.1, 0.1, 10, s < 0 and pink or cyan)
		k.box(s * 3.4, 3.5, -6.4, 1.6, 7, 1.6, cab, M.SmoothPlastic, {name = "Tower"})
		k.glow(s * 3.4, 5.5, -7.22, 1.0, 1.0, 0.05, s < 0 and cyan or pink)
		k.glow(s * 3.4, 5.5, -5.58, 1.0, 1.0, 0.05, s < 0 and cyan or pink)
		k.cyl(s * 3.4, 3.2, -7.22, 0.06, 1.1, BLACK, M.SmoothPlastic, "z") -- speaker cone
		k.cyl(s * 3.4, 3.2, -5.58, 0.06, 1.1, BLACK, M.SmoothPlastic, "z")
		k.cyl(s * 3.9, 0.15, 6.6, 0.3, 0.9, rgb(255, 210, 60), M.Neon, "y") -- tokens
	end)
	k.box(0, 2.25, -6.4, 3.2, 4.5, 2, cab, M.SmoothPlastic, {name = "Cabinet"})
	local screen = k.glow(0, 3.4, -5.38, 2.4, 1.3, 0.05, rgb(30, 200, 160))
	k.text(screen, "Back", "1UP", WHITE)
	k.box(0, 2.35, -5.2, 3.2, 0.3, 0.9, rgb(30, 30, 36), M.SmoothPlastic)
	k.ball(-0.8, 2.75, -5.1, 0.45, rgb(230, 40, 40), M.SmoothPlastic)
	for i, c in ipairs({rgb(255, 220, 40), rgb(40, 200, 255), rgb(90, 255, 90)}) do
		k.cyl(0.1 + i * 0.4, 2.55, -5.1, 0.1, 0.3, c, M.Neon, "y")
	end
	local marquee = k.box(0, 7.85, -6.4, 8.4, 1.3, 1.6, rgb(20, 20, 26), M.SmoothPlastic, {name = "Marquee"})
	k.text(marquee, "Front", "ARCADE", pink)
	k.text(marquee, "Back", "ARCADE", cyan)
	k.glow(0, 7.15 + 0.08, -6.4, 8.4, 0.08, 1.6, pink)
end)

-- 3: chunky toy bricks with studs, stacked crooked
add("Brick Builder", function(k)
	local red, yellow, blue, green = rgb(220, 40, 40), rgb(255, 200, 30), rgb(30, 110, 220), rgb(60, 180, 70)
	k.deck(5, red, M.SmoothPlastic)
	k.belt({yellow, blue}, M.SmoothPlastic, 4)
	local function brick(x, y, z, w, d, color, studs)
		k.box(x, y, z, w, 1.2, d, color, M.SmoothPlastic)
		if studs then
			for _, dx in ipairs({-w / 4, w / 4}) do
				for _, dz in ipairs({-d / 4, d / 4}) do
					k.cyl(x + dx, y + 0.7, z + dz, 0.2, 0.55, color, M.SmoothPlastic, "y")
				end
			end
		end
	end
	-- tall crooked stack on the left, short one on the right
	for i, c in ipairs({blue, yellow, green, red, blue}) do
		brick(-3.65 + (i % 2) * 0.25, 0.6 + (i - 1) * 1.2, -6.4, 2, 2, c, i == 5)
	end
	for i, c in ipairs({green, yellow}) do
		brick(3.5 - (i % 2) * 0.2, 0.6 + (i - 1) * 1.2, -6.6, 2, 2, c, i == 2)
	end
	k.box(-3.65, 7.6, -6.4, 0.2, 1.2, 0.2, WHITE, M.SmoothPlastic)
	k.box(-3.65, 7.9, -5.85, 0.12, 0.7, 1.0, red, M.SmoothPlastic, {name = "Flag"})
	brick(0, 2.0, -5.8, 3.2, 1.6, green, true) -- the console is a big brick
	k.box(0, 0.7, -5.8, 1.2, 1.4, 1.2, WHITE, M.SmoothPlastic)
	k.m(function(s)
		k.box(s * 2.55, 0.65, 0, 0.5, 0.4, 10, yellow, M.SmoothPlastic)
	end)
	brick(0, 0.6, 6.0, 2.4, 1.6, blue, true)
	brick(3.8, 0.6, 6.4, 1.6, 1.6, yellow, true)
end)

-- 4: peppermint belt between candy canes, a lollipop console and a giant sweet on top
add("Candy Rush", function(k)
	local pink, red, mint = rgb(255, 150, 200), rgb(235, 40, 60), rgb(120, 230, 190)
	k.deck(5, pink, M.SmoothPlastic)
	k.belt({WHITE, red}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		for i = 0, 7 do
			k.cyl(s * 3.2, 0.45 + i * 0.9, -6.2, 0.9, 0.6, i % 2 == 0 and red or WHITE, M.SmoothPlastic, "y")
		end
		k.ring(s * 3.75, 7.65, -6.2, 0.55, 0.5, red, M.SmoothPlastic, "z", {n = 6, a0 = s * 90, a1 = s * -90, depth = 0.6})
		for z = -4, 4, 2 do
			k.ball(s * 2.6, 0.4, z, 0.6, WHITE, M.SmoothPlastic, {name = "Icing"})
		end
	end)
	k.cyl(0, 1.6, -6.2, 3.2, 0.25, WHITE, M.SmoothPlastic, "y")
	k.cyl(0, 3.7, -6.2, 0.4, 1.6, rgb(255, 90, 200), M.SmoothPlastic, "z", {name = "Lollipop"})
	k.ring(0, 3.7, -6.0, 0.45, 0.18, WHITE, M.SmoothPlastic, "z", {n = 8, depth = 0.05})
	k.cyl(0, 8.3, -6.2, 2.4, 1.4, rgb(255, 160, 40), M.SmoothPlastic, "x", {name = "Sweet"})
	k.m(function(s)
		k.wedge(s * 1.7, 8.3, -6.2, 1.2, 1.4, 1.0, rgb(255, 200, 90), M.Foil, {ry = s * 90})
	end)
	for i, g in ipairs({{-3.8, 6.4, rgb(90, 220, 90)}, {3.6, 6.6, rgb(255, 150, 40)}, {-4.0, -8.6, rgb(170, 90, 255)}, {4.0, -8.6, mint}}) do
		k.ball(g[1], 0.5, g[2], 1.1, g[3], M.Glass, {name = "Gumdrop" .. i})
	end
end)

-- 5: a hamster habitat: clear tubes over the front, a water bottle and a little wheel
add("Hamster Habitat", function(k)
	local shavings, orange, tube = rgb(230, 195, 135), rgb(255, 140, 30), rgb(160, 225, 255)
	k.deck(5, shavings, M.Sand)
	k.belt({orange, rgb(255, 175, 80)}, M.SmoothPlastic, 4)
	k.m(function(s)
		k.cyl(s * 3.4, 3.75, -6.4, 7.0, 1.1, tube, M.Glass, "y", {t = 0.45})
		k.cyl(s * 3.4, 0.35, -6.4, 0.7, 1.5, orange, M.SmoothPlastic, "y")
		k.cyl(s * 3.4, 7.25, -6.4, 0.3, 1.3, orange, M.SmoothPlastic, "y")
		k.cyl(s * 2.7, 0.9, 0, 9, 0.9, tube, M.Glass, "z", {t = 0.45})
		k.cyl(s * 2.7, 0.9, 4.8, 0.3, 1.1, orange, M.SmoothPlastic, "z")
	end)
	k.cyl(0, 7.9, -6.4, 6.0, 1.1, tube, M.Glass, "x", {t = 0.45, name = "TopTube"})
	k.ball(-3.4, 7.9, -6.4, 1.4, orange, M.SmoothPlastic)
	k.ball(3.4, 7.9, -6.4, 1.4, orange, M.SmoothPlastic)
	-- water bottle clipped to the left tube
	k.cyl(-4.2, 4.6, -7.6, 3.2, 1.0, rgb(150, 210, 255), M.Glass, "y", {t = 0.3, name = "Bottle"})
	k.cyl(-4.2, 6.35, -7.6, 0.3, 0.8, rgb(60, 160, 90), M.SmoothPlastic, "y")
	k.cyl(-4.2, 2.8, -7.6, 0.6, 0.18, rgb(200, 200, 210), M.Metal, "y")
	-- the console is a seed dispenser
	k.box(0, 1.5, -5.8, 2.8, 2.2, 1.2, orange, M.SmoothPlastic)
	k.box(0, 2.4, -5.18, 2.2, 1.0, 0.06, rgb(255, 245, 210), M.Glass, {t = 0.2})
	-- a little hamster wheel and food bowl behind
	k.ring(3.5, 1.15, 6.0, 1.0, 0.2, orange, M.SmoothPlastic, "x", {n = 12, depth = 0.6})
	k.box(3.5, 0.5, 6.0, 0.2, 1.0, 0.2, rgb(200, 200, 210), M.Metal)
	k.cyl(-3.5, 0.25, 6.2, 0.5, 1.6, rgb(240, 100, 140), M.SmoothPlastic, "y", {name = "FoodBowl"})
	k.ball(-3.5, 0.55, 6.2, 0.6, rgb(240, 220, 150), M.Sand)
end)

-- 6: a beach shack: surfboards, a palm tree and a tiki torch
add("Surf Shack", function(k)
	local plank, palm, sand = rgb(205, 175, 125), rgb(110, 75, 40), rgb(235, 215, 160)
	k.deck(5, plank, M.WoodPlanks)
	k.belt({sand, rgb(70, 190, 220)}, M.SmoothPlastic, 4.2)
	k.box(0, 0.05, 6.2, 8, 0.1, 2.6, sand, M.Sand, {name = "Beach"})
	for i, b in ipairs({{-3.3, rgb(255, 120, 80), -6}, {3.3, rgb(60, 200, 220), 8}}) do
		k.box(b[1], 3.3, -6.2, 1.3, 6.0, 0.25, b[2], M.SmoothPlastic, {rz = b[3], name = "Surfboard" .. i})
		k.cyl(b[1] - math.sin(math.rad(b[3])) * 3, 3.3 + math.cos(math.rad(b[3])) * 3, -6.2, 0.25, 1.3, b[2], M.SmoothPlastic, "z")
		k.box(b[1], 3.3, -6.36, 0.22, 5.6, 0.06, WHITE, M.SmoothPlastic, {rz = b[3]})
	end
	-- palm tree at the front left corner, leaning in
	for i = 0, 2 do
		k.cyl(-3.9 + i * 0.3, 1.2 + i * 2.3, -7.6, 2.5, 0.6 - i * 0.07, palm, M.Wood, "y", {rz = -6})
	end
	local top = Vector3.new(-3.2, 7.9, -7.6)
	for _, a in ipairs({0, 72, 144, 216, 288}) do
		local r = math.rad(a)
		k.box(top.X + math.sin(r) * 0.75, top.Y - 0.2, top.Z + math.cos(r) * 0.75, 0.6, 0.12, 1.6, rgb(60, 170, 60), M.Grass, {ry = a, rx = -14, name = "Frond"})
	end
	k.ball(top.X, top.Y - 0.4, top.Z, 0.6, rgb(120, 80, 40), M.SmoothPlastic, {name = "Coconut"})
	-- tiki torch, front right
	k.cyl(4.2, 2.0, -8.6, 4.0, 0.3, palm, M.Wood, "y")
	local cup = k.cyl(4.2, 4.2, -8.6, 0.5, 0.6, rgb(90, 60, 30), M.Wood, "y")
	k.fx(cup, "fire", rgb(255, 160, 40), rgb(255, 60, 20))
	-- cooler box console and a beach ball
	k.box(0, 1.2, -5.8, 2.8, 1.9, 1.4, rgb(40, 140, 230), M.SmoothPlastic, {name = "Cooler"})
	k.box(0, 2.2, -5.8, 2.9, 0.25, 1.5, WHITE, M.SmoothPlastic)
	k.ball(-3.6, 0.7, 6.4, 1.2, rgb(255, 80, 80), M.SmoothPlastic, {name = "BeachBall"})
end)

-- 7: a brass steam engine: boiler and chimney on one side, gears on the other, pipes over the top
add("Steam Engine", function(k)
	local wood, brass, copper, iron = rgb(70, 45, 30), rgb(200, 150, 60), rgb(184, 115, 51), rgb(50, 45, 45)
	k.deck(4.8, wood, M.WoodPlanks)
	k.belt({rgb(60, 48, 42), rgb(88, 68, 48)}, M.Fabric, 4.2)
	k.m(function(s)
		k.cyl(s * 2.55, 0.7, 0, 10, 0.3, brass, M.Metal, "z")
	end)
	k.cyl(-3.4, 2.4, -7, 4.4, 2.4, copper, M.Metal, "y", {name = "Boiler"})
	for _, y in ipairs({0.8, 2.4, 4.0}) do
		k.cyl(-3.4, y, -7, 0.25, 2.5, brass, M.Metal, "y")
	end
	k.ball(-3.4, 4.6, -7, 2.3, copper, M.Metal)
	local chimney = k.cyl(-3.4, 6.6, -7, 2.4, 0.8, iron, M.Metal, "y", {name = "Chimney"})
	k.fx(chimney, "smoke", rgb(200, 200, 200))
	-- gears on the right
	k.cyl(3.6, 3.6, -6.6, 0.4, 2.6, brass, M.Metal, "x", {name = "Gear"})
	k.ring(3.6, 3.6, -6.6, 1.45, 0.4, brass, M.Metal, "x", {n = 10, depth = 0.4})
	k.cyl(3.6, 3.6, -6.6, 0.5, 0.7, iron, M.Metal, "x")
	k.cyl(3.7, 1.4, -8.0, 0.4, 1.6, copper, M.Metal, "x", {name = "SmallGear"})
	k.ring(3.7, 1.4, -8.0, 0.95, 0.3, copper, M.Metal, "x", {n = 8, depth = 0.4})
	-- pipes: up from the boiler, across over the top, down to the gears
	k.cyl(-3.4, 8.2, -7, 1.0, 0.5, copper, M.Metal, "y")
	k.cyl(0, 8.0, -7, 6.8, 0.5, copper, M.Metal, "x", {name = "Pipe"})
	k.cyl(3.4, 6.5, -7, 3.0, 0.5, copper, M.Metal, "y")
	k.ball(3.4, 8.0, -7, 0.65, brass, M.Metal)
	k.ball(-3.4, 8.0, -7, 0.65, brass, M.Metal)
	-- gauge panel console
	k.box(0, 2.0, -5.7, 3, 2.6, 0.7, wood, M.WoodPlanks, {name = "Console"})
	for _, x in ipairs({-0.7, 0.7}) do
		k.cyl(x, 2.6, -5.32, 0.08, 0.9, rgb(240, 230, 200), M.SmoothPlastic, "z")
		k.cyl(x, 2.6, -5.3, 0.06, 1.05, brass, M.Metal, "z")
		k.glow(x, 2.75, -5.26, 0.06, 0.38, 0.02, rgb(230, 60, 40), {rz = x > 0 and -35 or 25})
	end
	local lamp = k.ball(0, 3.45, -5.7, 0.5, rgb(255, 190, 90), M.Neon)
	k.light(lamp, rgb(255, 180, 90), 10, 1)
end)

-- 8: a farm tractor: giant tyres either side of the engine hood
add("Farm Tractor", function(k)
	local green, yellow, tyre = rgb(40, 140, 60), rgb(250, 200, 40), rgb(30, 30, 32)
	k.box(0, 0.25, 0, 5, 0.5, 10, green, M.SmoothPlastic, {solid = true, name = "Deck"})
	k.belt({rgb(110, 80, 50), rgb(92, 66, 42)}, M.Ground, 4.2)
	k.m(function(s)
		k.cyl(s * 3.7, 2.4, -7.0, 1.3, 4.4, tyre, M.Rubber, "x", {name = "Tyre"})
		k.ring(s * 3.7, 2.4, -7.0, 2.15, 0.35, tyre, M.Rubber, "x", {n = 12, depth = 1.5, name = "Tread"})
		k.cyl(s * 3.75, 2.4, -7.0, 1.4, 2.4, yellow, M.SmoothPlastic, "x", {name = "Hub"})
		k.box(s * 3.7, 4.85, -7.0, 1.6, 0.25, 4.4, green, M.SmoothPlastic, {name = "Fender"})
		k.box(s * 2.6, 0.75, 0, 0.3, 0.5, 10, yellow, M.SmoothPlastic)
		k.glow(s * 0.9, 2.3, -8.35, 0.7, 0.5, 0.1, rgb(255, 250, 210), {name = "Headlight"})
	end)
	k.box(0, 1.8, -6.6, 2.8, 2.6, 3.5, green, M.SmoothPlastic, {name = "Hood"})
	k.box(0, 1.6, -8.4, 2.4, 1.6, 0.12, rgb(40, 40, 40), M.DiamondPlate, {name = "Grille"})
	k.box(0, 3.15, -6.6, 2.9, 0.1, 3.6, yellow, M.SmoothPlastic)
	local pipe = k.cyl(1.0, 3.9, -7.6, 1.4, 0.35, rgb(60, 60, 64), M.Metal, "y", {name = "Exhaust"})
	k.fx(pipe, "smoke", rgb(120, 120, 120))
	k.cyl(0, 3.8, -4.95, 0.12, 1.1, tyre, M.Rubber, "z", {name = "SteeringWheel"})
	k.box(0, 3.4, -5.05, 0.15, 0.8, 0.15, tyre, M.Metal)
	k.box(-3.6, 0.6, 6.4, 1.8, 1.2, 1.2, rgb(225, 195, 95), M.Grass, {name = "HayBale"})
	k.ball(3.6, 0.5, 6.3, 1.1, rgb(255, 130, 30), M.SmoothPlastic, {name = "Pumpkin"})
	k.cyl(3.6, 1.1, 6.3, 0.3, 0.15, rgb(60, 120, 40), M.SmoothPlastic, "y")
end)

-- 9: broken blocks of glacier ice, an igloo console, a snowman and a snowflake crest
add("Glacier Dash", function(k)
	local ice, deep, snow = rgb(170, 220, 255), rgb(110, 180, 240), rgb(245, 250, 255)
	k.deck(5, deep, M.Ice)
	k.belt({rgb(225, 242, 255), rgb(150, 200, 240)}, M.Ice, 4.2)
	-- jagged ice blocks stacked at both front corners
	for _, b in ipairs({{-3.5, 1.4, -6.6, 2.2, 2.8, 2.2, 6}, {-3.7, 3.9, -6.9, 1.8, 2.4, 1.8, -10}, {-3.4, 5.9, -6.5, 1.3, 1.8, 1.3, 14},
		{3.6, 1.2, -6.8, 2.0, 2.4, 2.0, -8}, {3.4, 3.2, -6.5, 1.6, 1.8, 1.6, 12}}) do
		k.box(b[1], b[2], b[3], b[4], b[5], b[6], ice, M.Glass, {t = 0.25, ry = b[7], name = "IceBlock"})
	end
	k.m(function(s)
		k.box(s * 2.6, 0.55, 0, 0.5, 0.6, 10, snow, M.Snow)
	end)
	-- igloo console
	k.ball(0, 0.6, -6.2, 3.0, snow, M.Snow, {name = "Igloo"})
	k.box(0, 0.8, -4.8, 1.0, 1.2, 0.6, snow, M.Snow)
	-- snowflake crest above the front
	for _, a in ipairs({0, 60, 120}) do
		k.glow(0, 8.2, -6.6, 0.18, 1.8, 0.18, rgb(200, 240, 255), {rz = a, name = "Snowflake"})
	end
	local flake = k.ball(0, 8.2, -6.6, 0.5, WHITE, M.Neon)
	k.fx(flake, "sparkle", WHITE, rgb(170, 220, 255))
	k.light(flake, rgb(170, 220, 255), 12, 1)
	-- snowman behind
	k.ball(-3.6, 0.55, 6.0, 1.2, snow, M.Snow, {name = "Snowman"})
	k.ball(-3.6, 1.45, 6.0, 0.9, snow, M.Snow)
	k.ball(-3.6, 2.1, 6.0, 0.6, snow, M.Snow)
	k.box(-3.6, 2.1, 5.65, 0.1, 0.1, 0.4, rgb(255, 130, 30), M.SmoothPlastic)
	k.ball(3.7, 0.2, 6.2, 1.6, snow, M.Snow, {name = "SnowPile"})
end)

-- 10: a low racing kart: nose cone, front wing, slick tyres, rear wing and a start-light pole
add("Pit Lane Racer", function(k)
	local red, carbon, white = rgb(225, 30, 40), rgb(30, 30, 34), rgb(240, 240, 240)
	k.deck(4.8, carbon, M.SmoothPlastic)
	k.belt({rgb(44, 44, 48), rgb(60, 60, 64)}, M.Asphalt, 4.2)
	k.m(function(s)
		k.wedge(s * 3.0, 0.75, 0.6, 1.4, 1.5, 7.6, red, M.SmoothPlastic, {name = "Sidepod"})
		k.glow(s * 3.71, 0.6, 0.6, 0.04, 0.12, 6, white)
		k.cyl(s * 3.85, 0.8, -6.0, 1.0, 1.6, BLACK, M.Rubber, "x", {name = "Tyre"})
		k.cyl(s * 3.85, 0.8, -6.0, 1.05, 0.9, rgb(200, 200, 205), M.Metal, "x")
		k.cyl(s * 3.85, 0.95, 5.9, 1.2, 1.9, BLACK, M.Rubber, "x")
		k.cyl(s * 3.85, 0.95, 5.9, 1.25, 1.0, red, M.SmoothPlastic, "x")
		k.box(s * 4.3, 0.75, -8.4, 0.12, 0.8, 1.6, red, M.SmoothPlastic, {name = "Endplate"})
		k.box(s * 1.6, 1.45, 6.8, 0.15, 1.3, 0.5, red, M.SmoothPlastic)
	end)
	k.box(0, 0.25, -8.4, 8.6, 0.12, 1.4, carbon, M.SmoothPlastic, {name = "FrontWing"})
	k.box(0, 0.42, -8.7, 8.6, 0.1, 0.5, red, M.SmoothPlastic)
	k.wedge(0, 0.6, -6.8, 1.6, 0.9, 3.4, red, M.SmoothPlastic, {name = "Nose"})
	local board = k.box(0, 1.5, -5.3, 2.2, 1.6, 0.3, white, M.SmoothPlastic, {name = "NumberBoard"})
	k.text(board, "Front", "1", red)
	k.box(0, 2.3, -4.95, 2.2, 0.5, 0.6, carbon, M.SmoothPlastic, {name = "Dash"})
	k.ring(0, 3.05, -4.95, 0.5, 0.14, BLACK, M.Rubber, "z", {n = 10, depth = 0.14, name = "SteeringWheel"})
	k.box(0, 2.2, 6.8, 6, 0.15, 1.0, carbon, M.SmoothPlastic, {name = "RearWing"})
	k.box(0, 2.31, 6.8, 6, 0.06, 0.3, red, M.SmoothPlastic)
	-- start lights on a pole at the front left
	k.box(-4.3, 3.2, -8.9, 0.3, 6.4, 0.3, carbon, M.Metal)
	k.box(-3.95, 6.6, -8.9, 0.7, 2.0, 0.5, carbon, M.SmoothPlastic, {name = "StartLights"})
	for i, c in ipairs({red, rgb(255, 180, 0), rgb(60, 255, 90)}) do
		k.ball(-3.95, 7.2 - (i - 1) * 0.6, -8.6, 0.42, c, M.Neon)
	end
	for i = 0, 2 do
		k.cyl(4.0, 0.25 + i * 0.47, -8.6, 0.45, 1.4, BLACK, M.Rubber, "y", {name = "TyreStack"})
	end
end)

-- 11: a jungle temple: stepped stone pillars with braziers, an idol face, trees overhead
add("Jungle Temple", function(k)
	local stone, moss, leaf, gold, bark = rgb(130, 135, 115), rgb(85, 125, 62), rgb(55, 150, 55), rgb(230, 180, 60), rgb(90, 62, 36)
	k.deck(5, stone, M.Slate)
	k.belt({rgb(95, 85, 65), rgb(112, 100, 72)}, M.Slate, 4.2)
	k.m(function(s)
		for i, w in ipairs({2.4, 1.9, 1.4}) do
			k.box(s * 3.5, (i - 1) * 1.5 + 0.75, -6.8, w, 1.5, w, i == 2 and moss or stone, M.Slate, {name = "Step"})
		end
		local brazier = k.box(s * 3.5, 4.75, -6.8, 1.0, 0.5, 1.0, gold, M.Foil, {name = "Brazier"})
		k.fx(brazier, "fire", rgb(255, 170, 60), rgb(255, 80, 20))
		k.box(s * 3.9, 3.8, -8.7, 0.8, 7.6, 0.8, bark, M.Wood, {name = "Trunk"})
		k.ball(s * 3.6, 8.0, -8.0, 2.2, leaf, M.Grass, {name = "Canopy"})
		k.box(s * 2.6, 6.2, -7.6, 0.12, 3.0, 0.12, leaf, M.Grass, {name = "Vine"})
		k.box(s * 2.6, 0.55, 0, 0.5, 0.6, 10, moss, M.Slate)
	end)
	k.ball(0, 8.3, -8.0, 1.8, leaf, M.Grass, {name = "Canopy"})
	-- the idol: a stone face looking out at the path
	k.box(0, 1.9, -6.4, 3.0, 3.6, 1.2, stone, M.Slate, {name = "Idol"})
	k.wedge(0, 4.1, -6.4, 3.2, 0.8, 1.2, moss, M.Slate, {ry = 180})
	for _, x in ipairs({-0.65, 0.65}) do
		k.glow(x, 2.7, -7.02, 0.6, 0.35, 0.05, rgb(90, 255, 120), {name = "Eye"})
	end
	k.box(0, 1.5, -7.02, 1.6, 0.4, 0.05, rgb(40, 40, 36), M.Slate, {name = "Mouth"})
	local gem = k.glow(0, 2.9, -5.78, 0.5, 0.5, 0.05, rgb(90, 255, 120), {rz = 45})
	k.light(gem, rgb(120, 255, 140), 10, 1)
	k.ball(-3.7, 0.4, 6.3, 1.4, moss, M.Slate, {name = "Boulder"})
	k.ball(3.4, 0.3, 6.6, 1.0, stone, M.Slate, {name = "Boulder"})
end)

-- 12: a pirate ship: plank deck in a hull, a ship's wheel, a mast with a flag, cannons and a chest
add("Pirate Deck", function(k)
	local hull, plank, gold, sail, iron = rgb(95, 60, 35), rgb(150, 105, 62), rgb(220, 175, 60), rgb(240, 230, 205), rgb(45, 45, 50)
	k.deck(5, hull, M.WoodPlanks)
	k.belt({plank, rgb(132, 92, 55)}, M.WoodPlanks, 4.2)
	k.m(function(s)
		k.box(s * 2.75, 0.8, 0, 0.5, 1.6, 10.4, hull, M.WoodPlanks, {name = "Hull"})
		k.box(s * 2.75, 1.66, 0, 0.6, 0.12, 10.4, gold, M.Foil)
	end)
	k.wedge(0, 0.8, -7.0, 5, 1.6, 3, hull, M.WoodPlanks, {ry = 180, name = "Prow"})
	-- ship's wheel
	k.box(0, 1.4, -5.3, 0.5, 2.0, 0.5, hull, M.Wood)
	k.ring(0, 3.1, -5.0, 0.95, 0.2, plank, M.Wood, "z", {n = 12, depth = 0.2, name = "Wheel"})
	for _, a in ipairs({0, 45, 90, 135}) do
		k.box(0, 3.1, -5.0, 0.14, 2.4, 0.14, plank, M.Wood, {rz = a, name = "Spoke"})
	end
	k.cyl(0, 3.1, -5.0, 0.3, 0.4, gold, M.Foil, "z")
	-- mast, sail and flag on the left
	k.cyl(-3.7, 4.4, -7.4, 8.8, 0.5, hull, M.Wood, "y", {name = "Mast"})
	k.box(-3.7, 7.4, -7.4, 0.3, 0.3, 3.6, hull, M.Wood)
	k.box(-3.7, 5.6, -7.4, 0.1, 3.3, 3.4, sail, M.Fabric, {name = "Sail"})
	k.cyl(-3.7, 8.0, -7.4, 0.5, 1.2, hull, M.Wood, "y")
	local flag = k.box(-3.7, 8.75, -6.7, 0.06, 0.8, 1.2, BLACK, M.Fabric, {name = "Flag"})
	k.text(flag, "Left", "\u{2620}", WHITE)
	k.text(flag, "Right", "\u{2620}", WHITE)
	-- cannons on the right
	for _, z in ipairs({-2, 1.8}) do
		k.box(3.9, 0.45, z, 1.0, 0.5, 1.0, hull, M.Wood)
		k.cyl(3.9, 1.0, z, 1.8, 0.6, iron, M.Metal, "x", {name = "Cannon"})
	end
	-- treasure chest and a coil of rope behind
	k.box(3.5, 0.45, 6.3, 1.4, 0.9, 1.0, hull, M.WoodPlanks, {name = "Chest"})
	k.box(3.5, 1.0, 6.3, 1.45, 0.2, 1.05, gold, M.Foil)
	local coins = k.glow(3.5, 1.15, 6.3, 1.0, 0.1, 0.6, rgb(255, 210, 70))
	k.light(coins, rgb(255, 200, 90), 8, 0.8)
	k.cyl(-3.5, 0.2, 6.3, 0.4, 1.4, rgb(200, 170, 110), M.Fabric, "y", {name = "Rope"})
end)

-- 13: a rocket on the launch pad beside its gantry, with mission control as the console
add("Rocket Launch", function(k)
	local pad, hazard, white, red, iron = rgb(110, 110, 120), rgb(250, 200, 30), rgb(240, 240, 245), rgb(220, 50, 50), rgb(60, 60, 66)
	k.deck(5, pad, M.Concrete)
	k.belt({rgb(40, 40, 46), hazard}, M.SmoothPlastic, 4.2)
	-- the rocket, right
	k.cyl(3.3, 4.3, -7.2, 5.8, 1.8, white, M.SmoothPlastic, "y", {name = "Rocket"})
	k.cyl(3.3, 7.6, -7.2, 0.8, 1.4, red, M.SmoothPlastic, "y")
	k.cyl(3.3, 8.25, -7.2, 0.5, 0.9, red, M.SmoothPlastic, "y")
	k.cyl(3.3, 8.65, -7.2, 0.3, 0.4, red, M.SmoothPlastic, "y")
	k.cyl(3.3, 5.6, -7.2, 1.9, 0.7, rgb(120, 200, 255), M.Glass, "z", {name = "Window"})
	k.cyl(3.3, 2.0, -7.2, 0.4, 1.85, red, M.SmoothPlastic, "y")
	for _, f in ipairs({{3.3 + 1.2, -7.2, -90}, {3.3 - 1.2, -7.2, 90}, {3.3, -8.4, 0}}) do
		k.wedge(f[1], 1.9, f[2], 0.15, 1.8, 0.6, red, M.SmoothPlastic, {ry = f[3], name = "Fin"})
	end
	local nozzle = k.cyl(3.3, 1.0, -7.2, 0.8, 1.2, iron, M.Metal, "y", {name = "Nozzle"})
	k.fx(nozzle, "smoke", rgb(235, 235, 235))
	-- the gantry, left, with an arm across to the rocket
	for _, z in ipairs({-6.4, -8.2}) do
		k.box(-3.8, 4.0, z, 0.3, 8, 0.3, red, M.Metal, {name = "Gantry"})
	end
	for i = 0, 2 do
		k.box(-3.8, 1.5 + i * 2.4, -7.3, 0.2, 2.4, 0.2, red, M.Metal, {rx = i % 2 == 0 and 40 or -40})
	end
	k.box(-3.8, 7.9, -7.3, 1.4, 0.2, 2.2, iron, M.DiamondPlate)
	k.box(0, 7.6, -7.2, 6.6, 0.35, 0.5, red, M.Metal, {name = "Arm"})
	-- mission control console
	k.box(0, 1.4, -5.8, 3, 2, 1.2, pad, M.SmoothPlastic, {name = "Console"})
	local screen = k.glow(0, 1.8, -5.18, 2.2, 0.8, 0.05, rgb(30, 60, 40))
	k.text(screen, "Back", "3 \u{00B7} 2 \u{00B7} 1", rgb(120, 255, 140))
	k.cyl(0.9, 2.45, -5.8, 0.15, 0.5, red, M.Neon, "y", {name = "LaunchButton"})
	k.m(function(s)
		k.glow(s * 2.6, 0.46, 0, 0.2, 0.04, 10, hazard)
	end)
	k.ball(-3.6, 0.5, 6.3, 1.4, white, M.SmoothPlastic, {name = "FuelTank"})
end)

-- 14: a racing chariot in gold and crimson: spoked wheels, a curved shield front, two golden horses
add("Golden Chariot", function(k)
	local crimson, gold, dark = rgb(160, 20, 35), rgb(255, 200, 60), rgb(90, 15, 20)
	k.deck(4.8, dark, M.WoodPlanks)
	k.belt({crimson, rgb(130, 15, 28)}, M.Fabric, 4.2)
	-- shield front and flared sides
	k.box(0, 1.9, -5.0, 4.6, 2.6, 0.4, crimson, M.SmoothPlastic, {name = "Shield"})
	k.box(0, 3.3, -5.0, 4.8, 0.2, 0.5, gold, M.Foil)
	k.ball(0, 3.75, -5.0, 0.7, gold, M.Foil, {name = "Emblem"})
	k.m(function(s)
		k.box(s * 2.95, 1.4, -3.0, 0.3, 1.8, 3.6, crimson, M.SmoothPlastic, {ry = s * -12})
		k.box(s * 2.95, 2.35, -3.0, 0.35, 0.15, 3.7, gold, M.Foil, {ry = s * -12})
		-- spoked wheels
		k.ring(s * 3.85, 1.6, 0.8, 1.45, 0.3, gold, M.Foil, "x", {n = 14, depth = 0.35, name = "Wheel"})
		for _, a in ipairs({0, 45, 90, 135}) do
			k.box(s * 3.85, 1.6, 0.8, 0.14, 2.8, 0.14, gold, M.Foil, {rx = a})
		end
		k.cyl(s * 3.85, 1.6, 0.8, 0.7, 0.6, dark, M.Metal, "x")
		-- a golden horse rearing at each front corner
		k.box(s * 3.4, 0.4, -7.3, 1.6, 0.8, 2.8, dark, M.Marble, {name = "Plinth"})
		k.box(s * 3.4, 1.8, -7.3, 1.0, 1.3, 2.2, gold, M.Foil, {rx = -18, name = "Horse"})
		k.box(s * 3.4, 3.1, -8.1, 0.7, 1.6, 0.7, gold, M.Foil, {rx = -25})
		k.box(s * 3.4, 3.9, -8.45, 0.7, 0.7, 1.3, gold, M.Foil, {rx = 25})
		k.box(s * 3.4, 4.55, -8.05, 0.2, 0.9, 0.5, crimson, M.Fabric, {name = "Plume"})
		k.box(s * 2.7, 3.2, -6.8, 0.1, 0.1, 3.4, gold, M.Foil, {name = "Rein"})
	end)
	k.box(0, 0.25, 6.0, 3.0, 0.5, 1.6, gold, M.Foil, {name = "Step"})
end)

-- 15: synthwave: an outline sun fading yellow to magenta, neon palms and wireframe hills
add("Synthwave Sunset", function(k)
	local night, magenta, cyan, purple = rgb(18, 10, 36), rgb(255, 50, 190), rgb(40, 230, 255), rgb(140, 60, 255)
	k.deck(5, night, M.SmoothPlastic)
	k.belt({rgb(24, 12, 44), rgb(70, 20, 90)}, M.SmoothPlastic, 4.2)
	k.ring(0, 5.2, -8.2, 3.8, 0.3, function(f)
		return rgb(255, 230, 60):Lerp(magenta, math.abs(f - 0.5) * 2)
	end, M.Neon, "z", {n = 20, depth = 0.3, name = "Sun"})
	for i, y in ipairs({1.6, 2.4, 3.2}) do
		k.glow(0, y, -8.2, 6.6 - i * 0.5, 0.12, 0.3, magenta:Lerp(rgb(255, 230, 60), i / 4), {name = "SunStripe"})
	end
	k.m(function(s)
		k.glow(s * 2.55, 0.47, 0, 0.08, 0.06, 10, cyan, {name = "GridLine"})
		k.glow(s * 3.9, 3.0, -6.0, 0.25, 6, 0.25, s < 0 and cyan or magenta, {rz = s * 6, name = "PalmTrunk"})
		for _, a in ipairs({-50, -10, 30}) do
			k.glow(s * 3.7, 6.0, -6.0, 0.15, 0.15, 1.8, s < 0 and cyan or magenta, {ry = 90 + a * s, rz = s * -20, name = "PalmLeaf"})
		end
		k.wedge(s * 3.3, 0.6, 6.0, 1.6, 1.2, 1.2, purple, M.Neon, {t = 0.35, ry = s * 90, name = "Hill"})
	end)
	k.glow(0, 0.47, 5.2, 4.8, 0.06, 0.08, cyan)
	k.glow(0, 0.47, -5.2, 4.8, 0.06, 0.08, cyan)
	local dash = k.box(0, 2.0, -5.6, 3.0, 2.2, 0.8, rgb(30, 30, 40), M.Glass, {name = "Dash"})
	k.text(dash, "Back", "SUNSET", magenta)
	k.text(dash, "Front", "SUNSET", cyan)
	local sun = k.ball(0, 0.4, -8.2, 0.1, magenta, M.Neon, {t = 1})
	k.light(sun, magenta, 14, 1.2)
end)

-- 16: a low black armoured cruiser: long nose, slit lights, swept fins and a jet turbine
add("Shadow Prowler", function(k)
	local black, gun, red = rgb(16, 16, 20), rgb(48, 50, 56), rgb(255, 30, 40)
	k.deck(4.8, black, M.SmoothPlastic)
	k.belt({rgb(24, 24, 28), rgb(34, 34, 40)}, M.SmoothPlastic, 4.2)
	k.wedge(0, 0.6, -7.2, 4.6, 1.2, 4.2, black, M.SmoothPlastic, {name = "Nose"})
	k.wedge(0, 1.45, -5.6, 3.6, 0.5, 1.0, gun, M.Metal, {name = "Hood"})
	k.m(function(s)
		k.box(s * 3.2, 0.9, 0.2, 1.4, 1.8, 8.6, black, M.SmoothPlastic, {name = "Pod"})
		k.wedge(s * 3.2, 2.05, 0.2, 1.4, 0.5, 8.6, gun, M.Metal, {ry = 180})
		k.glow(s * 3.92, 1.15, 0.2, 0.05, 0.12, 7.2, red, {name = "SlitLight"})
		k.wedge(s * 3.75, 2.6, 2.6, 0.25, 1.6, 3.6, black, M.SmoothPlastic, {rz = s * 10, name = "Fin"})
		k.cyl(s * 3.55, 1.0, -6.4, 1.3, 2.0, BLACK, M.Rubber, "x", {name = "Wheel"})
		k.cyl(s * 3.6, 1.0, -6.4, 1.35, 1.1, red, M.Neon, "x")
		k.glow(s * 1.4, 0.5, -9.05, 1.0, 0.18, 0.2, rgb(255, 245, 220), {name = "Headlight"})
		k.glow(s * 2.1, 0.03, 0, 0.3, 0.05, 9, red, {name = "Underglow"})
	end)
	local turbine = k.cyl(0, 1.0, 5.6, 1.0, 1.9, gun, M.Metal, "z", {name = "Turbine"})
	k.cyl(0, 1.0, 6.15, 0.1, 1.3, rgb(255, 120, 40), M.Neon, "z")
	k.fx(turbine, "rise", rgb(255, 120, 40), red)
	local hud = k.wedge(0, 2.4, -5.0, 3.0, 1.0, 1.0, black, M.SmoothPlastic, {name = "Cockpit"})
	k.glow(0, 2.5, -4.98, 2.2, 0.06, 0.6, red, {rx = 45})
	k.light(hud, red, 12, 1)
end)

-- 17: a dojo walk: vermilion torii gate, stone lanterns, bamboo rails and falling blossom
add("Torii Dojo", function(k)
	local vermilion, black, tatami, bamboo, stone = rgb(220, 60, 40), rgb(30, 28, 28), rgb(205, 195, 140), rgb(130, 170, 70), rgb(160, 160, 155)
	k.deck(5, rgb(70, 50, 35), M.Wood)
	k.belt({rgb(175, 182, 112), rgb(152, 162, 96)}, M.Fabric, 4.2)
	k.m(function(s)
		k.cyl(s * 3.4, 4.0, -6.8, 8.0, 0.7, vermilion, M.SmoothPlastic, "y", {name = "Post"})
		k.cyl(s * 3.4, 0.3, -6.8, 0.6, 1.0, black, M.SmoothPlastic, "y")
		k.wedge(s * 4.15, 8.85, -6.8, 0.6, 0.5, 0.8, black, M.SmoothPlastic, {ry = s * 90, name = "Kasagi"})
		-- stone lantern
		k.box(s * 4.2, 0.5, -8.7, 0.9, 1.0, 0.9, stone, M.Slate)
		k.box(s * 4.2, 1.4, -8.7, 0.4, 0.8, 0.4, stone, M.Slate)
		local fire = k.box(s * 4.2, 2.1, -8.7, 0.7, 0.6, 0.7, rgb(255, 210, 120), M.Neon, {name = "Lantern"})
		k.wedge(s * 4.2, 2.65, -8.7, 1.0, 0.5, 1.0, stone, M.Slate, {ry = 0})
		if s > 0 then
			k.light(fire, rgb(255, 200, 120), 10, 1)
		end
		-- bamboo rail
		k.cyl(s * 2.6, 2.6, -1.5, 7, 0.3, bamboo, M.SmoothPlastic, "z", {name = "Bamboo"})
		for _, z in ipairs({-4, 1.5}) do
			k.cyl(s * 2.6, 1.3, z, 2.6, 0.3, bamboo, M.SmoothPlastic, "y")
		end
	end)
	k.box(0, 7.5, -6.8, 7.4, 0.5, 0.45, vermilion, M.SmoothPlastic, {name = "Nuki"})
	k.box(0, 8.3, -6.8, 8.0, 0.55, 0.7, vermilion, M.SmoothPlastic)
	k.box(0, 8.75, -6.8, 7.7, 0.35, 0.8, black, M.SmoothPlastic, {name = "Kasagi"})
	local plaque = k.box(0, 7.9, -7.1, 1.0, 0.8, 0.12, black, M.SmoothPlastic)
	k.text(plaque, "Front", "\u{8D70}", rgb(255, 210, 90))
	k.fx(plaque, "sparkle", rgb(255, 180, 210), rgb(255, 140, 190))
	-- writing desk console with a scroll
	k.box(0, 1.0, -5.7, 2.6, 2.0, 1.0, rgb(70, 50, 35), M.Wood)
	local scroll = k.box(0, 2.2, -5.7, 1.8, 0.4, 0.8, rgb(250, 245, 230), M.Fabric, {rx = 20})
	k.text(scroll, "Top", "\u{8D70}", black)
	-- raked gravel and a stone behind
	k.box(0, 0.06, 6.3, 6, 0.12, 2.4, rgb(225, 220, 205), M.Sand, {name = "Gravel"})
	k.ball(2.4, 0.35, 6.4, 1.0, stone, M.Slate)
end)

-- 18: a mech bay: tank tracks down the sides and two hydraulic arms raised over the front
add("Mech Hangar", function(k)
	local yellow, steel, dark, cyan = rgb(250, 190, 30), rgb(120, 125, 135), rgb(40, 42, 48), rgb(60, 220, 255)
	k.deck(4.8, steel, M.DiamondPlate)
	k.belt({rgb(50, 50, 55), rgb(78, 78, 84)}, M.DiamondPlate, 4)
	k.m(function(s)
		k.box(s * 3.3, 0.9, 0, 1.3, 1.8, 9, dark, M.Metal, {name = "Track"})
		k.cyl(s * 3.3, 0.9, -4.5, 1.3, 1.8, dark, M.Metal, "x")
		k.cyl(s * 3.3, 0.9, 4.5, 1.3, 1.8, dark, M.Metal, "x")
		k.box(s * 3.3, 1.85, 0, 1.0, 0.12, 9, yellow, M.SmoothPlastic)
		-- an arm: shoulder, upper arm, forearm raised, claw
		k.box(s * 3.5, 3.0, -6.8, 1.8, 1.8, 1.8, yellow, M.SmoothPlastic, {name = "Shoulder"})
		k.box(s * 3.6, 1.0, -6.8, 1.2, 2.2, 1.2, dark, M.Metal)
		k.box(s * 3.6, 5.2, -6.9, 0.9, 2.8, 0.9, steel, M.Metal, {rz = s * 6, name = "Forearm"})
		k.cyl(s * 3.0, 4.9, -6.9, 2.6, 0.3, rgb(200, 200, 205), M.Metal, "y", {name = "Piston"})
		k.box(s * 3.4, 6.8, -6.9, 1.3, 0.5, 1.3, yellow, M.SmoothPlastic)
		k.wedge(s * 3.0, 7.7, -6.9, 0.35, 1.4, 0.8, dark, M.Metal, {ry = s * 90, name = "Claw"})
		k.wedge(s * 3.85, 7.7, -6.9, 0.35, 1.4, 0.8, dark, M.Metal, {ry = s * -90})
	end)
	-- the mech's head is the console
	k.box(0, 2.3, -6.0, 2.8, 1.8, 1.8, yellow, M.SmoothPlastic, {name = "Head"})
	k.glow(0, 2.5, -6.92, 2.2, 0.5, 0.05, cyan, {name = "Visor"})
	k.glow(0, 2.5, -5.08, 2.2, 0.5, 0.05, cyan)
	k.box(0, 0.9, -6.0, 1.4, 1.0, 1.4, dark, M.Metal)
	local beacon = k.ball(0, 3.4, -6.0, 0.6, rgb(255, 140, 20), M.Neon, {name = "Beacon"})
	k.light(beacon, rgb(255, 150, 40), 10, 1)
	for i = 0, 3 do
		k.box(-1.65 + i * 1.1, 0.06, 6.0, 0.55, 0.12, 1.4, i % 2 == 0 and yellow or BLACK, M.SmoothPlastic, {name = "Hazard", ry = 30})
	end
end)

-- 19: a toxic lab: a bubbling vat, a rack of test tubes, hazard barrels and a skull screen
add("Toxic Lab", function(k)
	local purple, goo, steel, yellow = rgb(70, 30, 100), rgb(110, 255, 60), rgb(130, 135, 145), rgb(240, 200, 30)
	k.deck(5, purple, M.Metal)
	k.belt({rgb(40, 24, 58), rgb(56, 110, 44)}, M.SmoothPlastic, 4.2)
	-- vat, left
	k.cyl(-3.5, 3.4, -7.0, 5.2, 2.2, rgb(170, 255, 170), M.Glass, "y", {t = 0.5, name = "Vat"})
	local liquid = k.cyl(-3.5, 2.8, -7.0, 3.8, 1.8, goo, M.Neon, "y", {t = 0.25})
	k.fx(liquid, "rise", goo, rgb(200, 255, 160))
	k.cyl(-3.5, 0.4, -7.0, 0.8, 2.4, steel, M.Metal, "y")
	k.cyl(-3.5, 6.2, -7.0, 0.4, 2.4, steel, M.Metal, "y")
	k.light(liquid, goo, 12, 1.2)
	-- pipe over the top to the tube rack
	k.cyl(-3.5, 7.1, -7.0, 1.4, 0.45, steel, M.Metal, "y")
	k.cyl(0, 7.75, -7.0, 7.0, 0.45, steel, M.Metal, "x", {name = "Pipe"})
	k.cyl(3.5, 6.0, -7.0, 3.5, 0.45, steel, M.Metal, "y")
	-- test tubes, right
	k.box(3.5, 2.2, -7.0, 2.4, 0.3, 1.0, steel, M.Metal, {name = "Rack"})
	k.box(3.5, 1.1, -7.0, 2.2, 2.2, 0.2, steel, M.Metal)
	for i, c in ipairs({goo, rgb(255, 80, 200), rgb(80, 200, 255)}) do
		local x = 2.75 + (i - 1) * 0.75
		k.cyl(x, 3.0, -7.0, 2.6, 0.5, WHITE, M.Glass, "y", {t = 0.5, name = "TestTube"})
		k.cyl(x, 2.6, -7.0, 1.6 - i * 0.2, 0.4, c, M.Neon, "y")
	end
	-- skull screen console
	k.box(0, 1.6, -5.7, 3, 2.6, 0.7, purple, M.Metal, {name = "Console"})
	local screen = k.glow(0, 2.0, -5.33, 2.2, 1.2, 0.05, rgb(20, 60, 20))
	k.text(screen, "Back", "\u{2620}", goo)
	local back = k.glow(0, 2.0, -6.07, 2.2, 1.2, 0.05, rgb(20, 60, 20))
	k.text(back, "Front", "\u{2620}", goo)
	-- barrels behind, one tipped over and leaking
	k.cyl(-3.6, 0.85, 6.2, 1.7, 1.2, yellow, M.Metal, "y", {name = "Barrel"})
	k.cyl(-3.6, 0.85, 6.2, 0.2, 1.25, BLACK, M.Metal, "y")
	k.cyl(3.4, 0.6, 6.4, 1.7, 1.2, yellow, M.Metal, "x", {name = "Barrel"})
	k.cyl(2.2, 0.03, 6.4, 0.06, 1.8, goo, M.Neon, "y", {name = "Puddle"})
	k.cyl(-2.8, 0.03, -8.4, 0.06, 1.2, goo, M.Neon, "y", {name = "Puddle"})
end)

-- 20: polished gold on white marble: fluted columns under a gold arch, a hanging diamond, velvet ropes
add("Gilded Prestige", function(k)
	local gold, marble, velvet = rgb(255, 200, 60), rgb(240, 238, 232), rgb(150, 20, 40)
	k.deck(5, marble, M.Marble)
	k.belt({velvet, rgb(122, 14, 32)}, M.Fabric, 4.2)
	k.m(function(s)
		k.box(s * 2.6, 0.5, 0, 0.35, 0.3, 10.1, gold, M.Foil)
		k.box(s * 3.4, 0.35, -6.4, 1.6, 0.7, 1.6, marble, M.Marble, {name = "ColumnBase"})
		k.cyl(s * 3.4, 3.6, -6.4, 5.8, 1.0, gold, M.Foil, "y", {name = "Column"})
		k.box(s * 3.4, 6.7, -6.4, 1.5, 0.45, 1.5, marble, M.Marble, {name = "Capital"})
		k.cyl(s * 2.6, 3.0, -2.6, 5, 0.25, gold, M.Foil, "z", {name = "Handrail"})
		k.ball(s * 2.6, 3.0, -0.1, 0.45, gold, M.Foil)
		k.cyl(s * 2.6, 1.75, -0.4, 2.5, 0.2, gold, M.Foil, "y")
		k.cyl(s * 2.4, 1.0, 6.6, 2.0, 0.22, gold, M.Foil, "y", {name = "Stanchion"})
		k.ball(s * 2.4, 2.1, 6.6, 0.4, gold, M.Foil)
	end)
	k.ring(0, 5.75, -6.4, 3.2, 0.4, gold, M.Foil, "z", {n = 14, a0 = -90, a1 = 90, depth = 0.6, name = "Arch"})
	local diamond = k.box(0, 8.1, -6.4, 0.7, 0.7, 0.7, rgb(200, 240, 255), M.Glass, {rx = 45, rz = 45, t = 0.1, name = "Diamond"})
	k.fx(diamond, "sparkle", rgb(255, 240, 180), WHITE)
	k.light(diamond, rgb(255, 230, 160), 12, 1)
	k.cyl(0, 1.7, 6.6, 4.6, 0.15, velvet, M.Fabric, "x", {name = "VelvetRope"})
	k.box(0, 0.05, 6.4, 3.0, 0.1, 2.4, velvet, M.Fabric, {name = "Carpet"})
	local podium = k.box(0, 1.4, -5.7, 2.6, 2.4, 1.0, marble, M.Marble, {name = "Podium"})
	k.box(0, 2.72, -5.7, 2.9, 0.25, 1.2, gold, M.Foil)
	local screen = k.glow(0, 1.8, -5.18, 1.8, 0.9, 0.05, rgb(40, 30, 10))
	k.text(screen, "Back", "$$$", gold)
	k.text(podium, "Front", "\u{2605}", gold)
end)

-- 21: cyberpunk back street: a leaning neon sign pylon, a server rack in cables, a see-through holo screen
add("Neon Underground", function(k)
	local gunmetal, magenta, cyan, dark = rgb(40, 42, 52), rgb(255, 40, 160), rgb(0, 230, 255), rgb(16, 16, 22)
	k.deck(4.8, gunmetal, M.Metal)
	k.belt({dark, rgb(28, 28, 40)}, M.SmoothPlastic, 4)
	k.m(function(s)
		k.glow(s * 2.12, 0.47, 0, 0.1, 0.06, 9.6, s < 0 and magenta or cyan, {name = "EdgeLight"})
		k.box(s * 2.6, 0.75, 0, 0.6, 0.6, 9.6, dark, M.Metal)
	end)
	-- left: a leaning pylon carrying a vertical sign
	k.box(-3.9, 4.2, -7.6, 0.9, 8.2, 0.9, dark, M.Metal, {rz = -5, name = "Pylon"})
	local sign = k.box(-3.1, 5.6, -7.6, 1.4, 4.2, 0.3, dark, M.SmoothPlastic, {name = "Sign"})
	k.text(sign, "Back", "R\nU\nN", magenta)
	k.text(sign, "Front", "R\nU\nN", cyan)
	k.glow(-3.1, 7.75, -7.6, 1.5, 0.1, 0.35, magenta)
	k.glow(-3.1, 3.45, -7.6, 1.5, 0.1, 0.35, magenta)
	k.light(sign, magenta, 12, 1.2)
	-- right: a server rack with blinking strips and loose cables
	k.box(3.6, 1.9, -6.8, 1.6, 3.8, 1.6, dark, M.Metal, {name = "Rack"})
	for i = 0, 3 do
		k.glow(3.6, 0.8 + i * 0.85, -5.98, 1.2, 0.1, 0.05, i % 2 == 0 and cyan or magenta)
	end
	k.box(2.95, 1.6, -5.6, 0.12, 3.0, 0.12, BLACK, M.Rubber, {rz = 18, name = "Cable"})
	k.box(3.3, 1.2, -5.5, 0.12, 2.4, 0.12, BLACK, M.Rubber, {rz = -12, name = "Cable"})
	-- a slanted light bar overhead and a see-through holo screen over the dash
	k.glow(0, 8.1, -7.6, 6.4, 0.25, 0.25, cyan, {rz = 6, name = "LightBar"})
	k.wedge(0, 1.6, -5.6, 3.0, 2.2, 1.0, gunmetal, M.Metal, {name = "Dash"})
	local holo = k.box(0, 4.6, -6.2, 2.4, 1.4, 0.05, cyan, M.Neon, {t = 0.65, name = "Holo"})
	k.text(holo, "Back", "SPEED", WHITE)
	-- chevrons on the floor behind
	for i = 0, 1 do
		k.m(function(s)
			k.glow(s * 0.42, 0.04, 5.6 + i * 1.1, 1.1, 0.05, 0.22, i == 0 and cyan or magenta, {ry = s * 40, name = "Chevron"})
		end)
	end
end)

-- 22: a haunted crypt: iron fences, a dead tree with a lantern, a tombstone console and a ghost
add("Haunted Crypt", function(k)
	local stone, iron, bark, purple, pumpkin = rgb(95, 95, 105), rgb(25, 25, 30), rgb(55, 45, 50), rgb(150, 80, 255), rgb(215, 90, 15)
	k.deck(5, rgb(60, 58, 66), M.Slate)
	k.belt({rgb(40, 36, 50), rgb(58, 50, 70)}, M.Slate, 4.2)
	k.m(function(s)
		for z = -4, 4, 2 do
			k.box(s * 2.7, 1.3, z, 0.15, 2.2, 0.15, iron, M.Metal, {name = "FencePost"})
			k.box(s * 2.7, 2.5, z, 0.25, 0.25, 0.25, iron, M.Metal, {rx = 45, rz = 45})
		end
		k.box(s * 2.7, 2.1, 0, 0.1, 0.12, 8.2, iron, M.Metal)
		k.box(s * 2.7, 0.7, 0, 0.1, 0.12, 8.2, iron, M.Metal)
	end)
	-- dead tree at the front left, one branch reaching over the top
	k.box(-3.7, 3.6, -7.8, 0.9, 7.2, 0.9, bark, M.Wood, {rz = -4, name = "DeadTree"})
	k.box(-2.3, 8.15, -7.8, 3.2, 0.35, 0.35, bark, M.Wood, {rz = 18, name = "Branch"})
	k.box(-4.1, 6.0, -7.8, 1.2, 0.3, 0.3, bark, M.Wood, {rz = -30})
	k.box(-2.7, 7.2, -7.8, 0.05, 0.9, 0.05, iron, M.Metal)
	local lantern = k.box(-2.7, 6.45, -7.8, 0.5, 0.6, 0.5, rgb(170, 120, 255), M.Neon, {name = "Lantern"})
	k.light(lantern, purple, 12, 1.2)
	-- tombstone console, breathing fog
	local tomb = k.box(0, 1.6, -6.0, 2.6, 2.6, 0.6, stone, M.Slate, {name = "Tombstone"})
	k.cyl(0, 2.9, -6.0, 0.6, 2.6, stone, M.Slate, "z")
	k.text(tomb, "Front", "R.I.P.", rgb(40, 40, 45))
	k.text(tomb, "Back", "DON'T\nSTOP", rgb(190, 160, 255))
	k.fx(tomb, "smoke", purple, rgb(80, 60, 110))
	-- jack-o'-lanterns grinning at whoever looks
	for _, p in ipairs({{3.7, -8.2, -1}, {-3.5, 6.4, 1}, {3.6, 6.3, 1}}) do
		k.ball(p[1], 0.5, p[2], 1.2, pumpkin, M.SmoothPlastic, {name = "Pumpkin"})
		k.glow(p[1], 0.55, p[2] + p[3] * 0.56, 0.45, 0.14, 0.1, rgb(255, 170, 40), {name = "Grin"})
		k.cyl(p[1], 1.15, p[2], 0.3, 0.15, rgb(60, 110, 40), M.SmoothPlastic, "y")
	end
	-- a ghost at the front right
	k.ball(3.6, 5.0, -7.2, 1.3, rgb(235, 240, 255), M.SmoothPlastic, {t = 0.35, name = "Ghost"})
	k.ball(3.6, 4.2, -7.1, 0.9, rgb(235, 240, 255), M.SmoothPlastic, {t = 0.45})
	for _, dx in ipairs({-0.25, 0.25}) do
		k.ball(3.6 + dx, 5.15, -7.82, 0.22, BLACK, M.SmoothPlastic)
	end
end)

-- 23: a volcano forge: two smoking volcanoes, lava cracks in the deck, an anvil with a glowing ingot
add("Volcano Forge", function(k)
	local basalt, lava, iron, ash = rgb(35, 30, 30), rgb(255, 100, 20), rgb(55, 55, 60), rgb(80, 70, 65)
	k.deck(5, basalt, M.Basalt)
	k.belt({rgb(30, 26, 26), rgb(150, 45, 10)}, M.Basalt, 4.2)
	k.m(function(s)
		k.glow(s * 2.55, 0.46, 0, 0.12, 0.04, 9.6, lava, {name = "LavaCrack"})
		for i, d in ipairs({2.8, 2.1, 1.4}) do
			k.cyl(s * 3.4, 0.9 + (i - 1) * 1.8, -7.2, 1.8, d, i == 3 and ash or basalt, M.Basalt, "y", {name = "Volcano"})
		end
		local crater = k.cyl(s * 3.4, 5.45, -7.2, 0.15, 1.0, lava, M.Neon, "y", {name = "Crater"})
		k.fx(crater, "fire", rgb(255, 140, 30), rgb(200, 30, 10))
		k.glow(s * 3.4, 4.5, -6.48, 0.3, 1.8, 0.08, lava, {name = "LavaFlow"})
		k.glow(s * 3.5, 2.7, -6.13, 0.3, 1.8, 0.08, lava)
		k.glow(s * 3.3, 0.9, -5.78, 0.3, 1.8, 0.08, lava)
	end)
	-- the anvil, with a hammer leaning on it
	k.box(0, 0.6, -6.0, 1.6, 1.2, 1.2, iron, M.Metal, {name = "AnvilBase"})
	k.box(0, 1.5, -6.0, 0.9, 0.8, 0.8, iron, M.Metal)
	k.box(0, 2.2, -6.0, 2.4, 0.6, 1.1, iron, M.Metal, {name = "Anvil"})
	k.wedge(-1.5, 2.2, -6.0, 0.6, 0.6, 0.8, iron, M.Metal, {ry = 90, name = "AnvilHorn"})
	local ingot = k.glow(0.3, 2.56, -6.0, 0.9, 0.12, 0.35, lava, {name = "Ingot"})
	k.light(ingot, rgb(255, 120, 40), 14, 1.5)
	k.box(1.4, 1.2, -5.3, 0.15, 2.0, 0.15, rgb(110, 70, 40), M.Wood, {rz = -20, name = "Hammer"})
	k.box(1.75, 2.15, -5.3, 0.7, 0.35, 0.35, iron, M.Metal, {rz = -20})
	-- obsidian shards and a lava crack behind
	k.box(-3.4, 0.8, 6.2, 0.8, 1.6, 0.8, basalt, M.Basalt, {rx = 12, rz = -15, name = "Obsidian"})
	k.box(3.6, 0.6, 6.5, 0.7, 1.2, 0.7, basalt, M.Basalt, {rx = -10, rz = 20, name = "Obsidian"})
	k.glow(0, 0.03, 6.2, 0.2, 0.05, 2.2, lava, {ry = 30})
end)

-- 24: Atlantis: a golden trident, coral, a giant clam holding a glowing pearl, a starfish
add("Atlantis Tide", function(k)
	local sand, gold, coral = rgb(230, 210, 160), rgb(255, 200, 70), rgb(255, 110, 120)
	k.deck(5, rgb(30, 120, 140), M.Slate)
	k.belt({rgb(25, 120, 160), rgb(38, 158, 190)}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.box(s * 2.6, 0.55, 0, 0.5, 0.5, 10, sand, M.Sand)
	end)
	-- trident on the right
	k.cyl(3.8, 4.4, -7.6, 8.0, 0.28, gold, M.Foil, "y", {name = "Trident"})
	k.box(3.8, 7.9, -7.6, 1.6, 0.25, 0.25, gold, M.Foil)
	for _, dx in ipairs({-0.7, 0, 0.7}) do
		local h = dx == 0 and 1.2 or 0.9
		k.box(3.8 + dx, 8.0 + h / 2, -7.6, 0.18, h, 0.18, gold, M.Foil, {name = "Prong"})
	end
	-- coral on the left, leaning every way
	for _, c in ipairs({{-3.6, 0, -7.4, 3.2, 0, coral}, {-3.2, 0, -7.0, 2.4, 25, rgb(255, 160, 60)}, {-4.1, 0, -6.6, 2.6, -22, rgb(200, 90, 220)}, {-3.5, 1.4, -8.2, 2.0, -35, coral}}) do
		local r = math.rad(c[5])
		local tip = Vector3.new(c[1] - math.sin(r) * c[4], c[2] + math.cos(r) * c[4], c[3])
		k.cyl(c[1] - math.sin(r) * c[4] / 2, c[2] + math.cos(r) * c[4] / 2, c[3], c[4], 0.45, c[6], M.SmoothPlastic, "y", {rz = c[5], name = "Coral"})
		k.ball(tip.X, tip.Y, tip.Z, 0.6, c[6], M.SmoothPlastic)
	end
	-- the clam console
	k.cyl(0, 0.4, -6.2, 0.8, 0.8, sand, M.Sand, "y")
	k.cyl(0, 1.0, -6.2, 0.5, 2.6, rgb(255, 170, 190), M.SmoothPlastic, "y", {name = "Clam"})
	k.cyl(0, 2.5, -6.75, 0.35, 2.6, rgb(255, 185, 205), M.SmoothPlastic, "y", {rx = -55})
	local pearl = k.ball(0, 1.6, -6.2, 0.8, rgb(240, 255, 255), M.Neon, {name = "Pearl"})
	k.light(pearl, rgb(150, 255, 255), 12, 1)
	k.fx(pearl, "rise", rgb(200, 255, 255), WHITE)
	-- a starfish and a shell behind
	for i = 0, 4 do
		local a = math.rad(i * 72)
		k.box(2.8 + math.sin(a) * 0.35, 0.06, 6.3 + math.cos(a) * 0.35, 0.25, 0.12, 0.7, rgb(255, 140, 70), M.SmoothPlastic, {ry = i * 72, name = "Starfish"})
	end
	k.ball(-3.3, 0.2, 6.4, 0.9, rgb(255, 230, 220), M.SmoothPlastic, {name = "Shell"})
end)

-- 25: a clockwork tower with clock faces, brass cogs and a swinging pendulum
add("Clockwork Tower", function(k)
	local bronze, brick, cream, dark, brass = rgb(150, 100, 50), rgb(120, 70, 50), rgb(245, 235, 210), rgb(45, 35, 30), rgb(210, 165, 70)
	k.deck(4.8, dark, M.WoodPlanks)
	k.belt({rgb(70, 50, 30), rgb(105, 76, 40)}, M.Fabric, 4.2)
	-- the tower on the left, with a pointed roof
	k.box(-3.6, 3.6, -7.4, 2.0, 7.2, 2.0, brick, M.Brick, {name = "Tower"})
	k.box(-3.6, 7.35, -7.4, 2.3, 0.3, 2.3, bronze, M.Metal)
	k.wedge(-3.6, 8.3, -7.95, 2.2, 1.6, 1.1, dark, M.Slate, {name = "Roof"})
	k.wedge(-3.6, 8.3, -6.85, 2.2, 1.6, 1.1, dark, M.Slate, {ry = 180})
	for _, f in ipairs({{-8.42, -1}, {-6.38, 1}}) do
		k.cyl(-3.6, 5.4, f[1] - f[2] * 0.02, 0.04, 1.8, brass, M.Metal, "z")
		k.cyl(-3.6, 5.4, f[1], 0.06, 1.6, cream, M.SmoothPlastic, "z", {name = "ClockFace"})
		k.box(-3.6, 5.62, f[1] + f[2] * 0.05, 0.1, 0.5, 0.03, dark, M.SmoothPlastic, {name = "Hand"})
		k.box(-3.38, 5.4, f[1] + f[2] * 0.05, 0.5, 0.08, 0.03, dark, M.SmoothPlastic, {rz = 30})
	end
	-- cogs and the pendulum on the right
	k.cyl(3.3, 3.4, -7.0, 0.4, 2.2, brass, M.Metal, "z", {name = "Cog"})
	k.ring(3.3, 3.4, -7.0, 1.2, 0.35, brass, M.Metal, "z", {n = 10, depth = 0.4})
	k.cyl(3.3, 3.4, -7.0, 0.5, 0.6, dark, M.Metal, "z")
	k.cyl(3.7, 1.2, -6.4, 0.4, 1.2, bronze, M.Metal, "z", {name = "Cog"})
	k.box(4.3, 4.3, -8.4, 0.3, 8.6, 0.3, dark, M.Metal)
	k.box(3.75, 8.45, -8.4, 1.3, 0.3, 0.3, dark, M.Metal)
	k.box(3.3, 7.0, -8.4, 0.1, 2.6, 0.1, brass, M.Metal, {name = "Pendulum"})
	k.cyl(3.3, 5.5, -8.4, 0.15, 0.9, brass, M.Metal, "z")
	-- a speed dial for the console
	k.box(0, 1.5, -5.6, 2.4, 2.4, 0.8, dark, M.Wood, {name = "Console"})
	local dial = k.cyl(0, 3.4, -5.6, 0.3, 1.6, bronze, M.Metal, "z", {name = "Dial"})
	k.cyl(0, 3.4, -5.44, 0.04, 1.3, cream, M.SmoothPlastic, "z")
	k.glow(0.2, 3.58, -5.41, 0.06, 0.6, 0.02, rgb(220, 40, 30), {rz = -40, name = "Needle"})
	k.light(dial, rgb(255, 210, 150), 10, 1)
end)

-- 26: a royal throne: velvet posts with gold finials, a golden arch and ruby, lion-head armrests
add("Royal Throne", function(k)
	local velvet, gold, deep, ruby = rgb(110, 30, 140), rgb(255, 200, 60), rgb(70, 18, 90), rgb(220, 20, 50)
	k.box(0, 0.225, 0, 5.2, 0.45, 10, gold, M.Foil, {solid = true, name = "Deck"})
	k.belt({velvet, rgb(138, 40, 168)}, M.Fabric, 4.2)
	k.m(function(s)
		k.box(s * 3.1, 1.3, -1.2, 1.1, 1.7, 6.4, velvet, M.Fabric, {name = "Armrest"})
		k.box(s * 3.1, 2.25, -1.2, 1.3, 0.2, 6.6, gold, M.Foil)
		k.ball(s * 3.1, 2.7, -4.7, 1.25, rgb(200, 140, 40), M.Foil, {name = "Mane"})
		k.ball(s * 3.1, 2.7, -5.1, 0.9, gold, M.Foil, {name = "Lion"})
		k.box(s * 3.3, 3.8, -6.6, 1.1, 7.6, 1.1, velvet, M.Fabric, {name = "ThronePost"})
		k.box(s * 3.3, 3.8, -6.03, 0.3, 7.0, 0.08, gold, M.Foil)
		k.ball(s * 3.3, 7.95, -6.6, 0.8, gold, M.Foil, {name = "Finial"})
		k.box(s * 1.7, 0.06, 6.3, 0.2, 0.1, 2.6, gold, M.Foil)
	end)
	k.box(0, 0.6, -6.7, 4.6, 1.2, 1.4, gold, M.Foil, {name = "Seat"})
	local cushion = k.box(0, 2.8, -6.7, 4.4, 3.2, 0.7, deep, M.Fabric, {name = "Cushion"})
	k.text(cushion, "Back", "\u{265B}", gold)
	for _, x in ipairs({-1.5, 1.5}) do
		k.ball(x, 3.6, -6.33, 0.3, gold, M.Foil)
	end
	k.ring(0, 5.6, -6.6, 3.2, 0.35, gold, M.Foil, "z", {n = 14, a0 = -90, a1 = 90, depth = 0.5, name = "Arch"})
	local gem = k.box(0, 8.0, -6.6, 0.6, 0.6, 0.6, ruby, M.Glass, {rx = 45, rz = 45, t = 0.1, name = "Ruby"})
	k.light(gem, rgb(255, 150, 200), 12, 1)
	k.fx(gem, "sparkle", gold, WHITE)
	k.box(0, 0.05, 6.3, 3.2, 0.1, 2.6, ruby, M.Fabric, {name = "Carpet"})
end)

-- 27: a dragon's lair: a long neck rising at the front right, the head looming over, wings folded along the sides
add("Dragon's Lair", function(k)
	local scale, belly, horn, eye, gold, wing = rgb(150, 25, 25), rgb(230, 150, 70), rgb(235, 225, 200), rgb(255, 220, 40), rgb(255, 200, 60), rgb(110, 20, 25)
	k.deck(5, rgb(45, 30, 30), M.Slate)
	k.belt({rgb(60, 12, 12), rgb(88, 22, 16)}, M.Slate, 4.2)
	-- the neck, bending in toward the middle as it rises
	k.cyl(3.6, 1.2, -7.4, 2.4, 1.8, scale, M.Slate, "y", {name = "Neck"})
	k.cyl(3.5, 3.4, -7.5, 2.4, 1.5, scale, M.Slate, "y", {rz = 8})
	k.cyl(3.3, 5.5, -7.5, 2.2, 1.3, scale, M.Slate, "y", {rz = 18})
	k.ball(3.0, 7.3, -7.4, 1.2, scale, M.Slate)
	for _, y in ipairs({1.4, 3.6}) do
		k.box(3.6 - (y > 2 and 0.15 or 0), y, -6.6, 0.9, 1.6, 0.12, belly, M.Slate, {name = "Belly"})
	end
	-- the head, looking across over the front
	k.box(1.6, 7.9, -7.4, 2.2, 1.1, 1.5, scale, M.Slate, {name = "Head"})
	local snout = k.box(0.1, 7.8, -7.4, 1.0, 0.8, 1.2, scale, M.Slate, {name = "Snout"})
	k.box(0.6, 7.4, -7.4, 1.4, 0.25, 1.0, belly, M.Slate, {name = "Jaw"})
	for _, z in ipairs({-7.95, -6.85}) do
		k.box(2.5, 8.75, z, 0.25, 0.9, 0.25, horn, M.SmoothPlastic, {rz = -35, name = "Horn"})
	end
	k.glow(1.0, 8.15, -8.16, 0.3, 0.2, 0.05, eye, {name = "Eye"})
	k.glow(1.0, 8.15, -6.64, 0.3, 0.2, 0.05, eye, {name = "Eye"})
	k.fx(snout, "fire", rgb(255, 160, 40), rgb(255, 40, 10))
	-- folded wings and belly scales along the sides
	k.m(function(s)
		k.wedge(s * 3.6, 2.0, 0.5, 0.2, 2.6, 6.0, wing, M.Fabric, {rz = s * -20, name = "Wing"})
		k.box(s * 3.95, 2.95, 0.5, 0.25, 0.25, 6.2, rgb(60, 15, 15), M.Slate, {name = "WingBone"})
		k.box(s * 2.6, 0.6, 0, 0.5, 0.5, 10, belly, M.Slate)
	end)
	-- the tail curls round the back
	k.cyl(-2.4, 0.5, 5.6, 2.0, 0.9, scale, M.Slate, "z", {ry = -25, name = "Tail"})
	k.cyl(-3.5, 0.45, 6.6, 1.6, 0.7, scale, M.Slate, "z", {ry = -60})
	k.wedge(-4.3, 0.5, 6.9, 0.2, 0.9, 0.9, scale, M.Slate, {ry = -90})
	-- a hoard of gold and an egg on a pedestal
	k.ball(-3.5, 0.3, -7.6, 2.4, gold, M.Foil, {name = "Hoard"})
	k.glow(-3.1, 1.4, -7.2, 0.35, 0.35, 0.35, rgb(80, 255, 140), {rx = 45, rz = 45})
	k.glow(-3.9, 1.3, -8.0, 0.3, 0.3, 0.3, rgb(80, 160, 255), {rx = 45, rz = 45})
	k.cyl(0, 0.8, -6.0, 1.6, 1.4, rgb(70, 60, 60), M.Slate, "y", {name = "Pedestal"})
	local egg = k.ball(0, 2.1, -6.0, 1.3, rgb(255, 120, 40), M.Neon, {name = "Egg"})
	k.light(egg, rgb(255, 120, 50), 12, 1.2)
end)

-- 28: a hover racer: a floating white deck, crescent blades, a halo of light and twin thrusters
add("Hyperion Speed", function(k)
	local white, cyan, steel, dark = rgb(240, 244, 250), rgb(0, 200, 255), rgb(170, 180, 195), rgb(24, 30, 42)
	k.box(0, 0.3, 0, 4.6, 0.3, 10, white, M.SmoothPlastic, {solid = true, name = "Deck"})
	k.glow(0, 0.07, 0, 4.0, 0.06, 9.4, cyan, {name = "HoverGlow"})
	k.belt({dark, rgb(0, 110, 180)}, M.Glass, 4)
	k.m(function(s)
		k.cyl(s * 2.85, 0.75, 0, 9.6, 1.1, white, M.SmoothPlastic, "z", {name = "Pod"})
		k.ball(s * 2.85, 0.75, -4.8, 1.1, white, M.SmoothPlastic)
		k.ball(s * 2.85, 0.75, 4.8, 1.1, white, M.SmoothPlastic)
		for _, z in ipairs({-2, 0, 2}) do
			k.cyl(s * 2.85, 0.75, z, 0.12, 1.16, cyan, M.Neon, "z")
		end
		k.ring(0, 3.2, -6.4, 3.9, 0.7, white, M.SmoothPlastic, "z", {n = 6, a0 = s * -90, a1 = s * -44, depth = 0.6, name = "Blade"})
		k.ring(0, 3.2, -6.05, 3.6, 0.14, cyan, M.Neon, "z", {n = 6, a0 = s * -90, a1 = s * -45, depth = 0.1})
		k.cyl(s * 1.3, 0.75, 5.7, 1.4, 1.0, steel, M.Metal, "z", {name = "Thruster"})
		k.cyl(s * 1.3, 0.75, 6.42, 0.06, 0.75, cyan, M.Neon, "z")
	end)
	local halo = k.ring(0, 8.3, -6.4, 1.5, 0.22, cyan, M.Neon, "y", {n = 14, depth = 0.22, name = "Halo"})
	k.fx(halo[1], "sparkle", cyan, WHITE)
	k.wedge(0, 1.5, -5.4, 3.2, 1.8, 1.6, white, M.SmoothPlastic, {name = "Console"})
	local holo = k.box(0, 4.3, -5.6, 2.4, 1.2, 0.05, cyan, M.Neon, {t = 0.65, name = "Holo"})
	k.text(holo, "Back", "MACH 1", WHITE)
	k.light(holo, cyan, 12, 1)
end)

-- 29: a crystal cavern: amethyst and teal crystals of every size, a geode console, a floating gem
add("Crystal Cavern", function(k)
	local rock, amethyst, teal = rgb(55, 45, 70), rgb(170, 90, 255), rgb(60, 230, 210)
	k.deck(5, rock, M.Slate)
	k.belt({rgb(40, 30, 60), rgb(66, 48, 96)}, M.Slate, 4.2)
	-- a crystal standing on (x, z), leaning `tilt` degrees (positive leans to the left)
	local function crystal(x, z, h, w, color, tilt)
		local r = math.rad(tilt)
		local cx, cy = x - math.sin(r) * h / 2, math.cos(r) * h / 2
		k.box(cx, cy, z, w, h, w, color, M.Glass, {rz = tilt, t = 0.2, name = "Crystal"})
		k.glow(cx, cy, z, w * 0.45, h * 0.85, w * 0.45, color, {rz = tilt})
	end
	crystal(-3.6, -7.2, 7.6, 1.0, amethyst, 4)
	crystal(-3.0, -7.8, 4.2, 0.8, amethyst, -18)
	crystal(-3.9, -6.3, 3.2, 0.7, teal, 8)
	crystal(3.6, -7.0, 5.6, 1.1, teal, -4)
	crystal(3.0, -7.8, 3.6, 0.8, amethyst, 15)
	crystal(4.0, -6.0, 2.6, 0.6, amethyst, -10)
	crystal(-3.4, 1.0, 2.4, 0.6, teal, 10)
	crystal(3.5, -1.5, 2.0, 0.5, amethyst, -12)
	crystal(3.3, 2.6, 2.8, 0.6, teal, -6)
	crystal(-3.5, 6.2, 2.0, 0.6, amethyst, 10)
	crystal(3.6, 6.4, 1.6, 0.5, teal, -10)
	-- geode console
	k.cyl(0, 1.4, -6.0, 1.0, 2.8, rock, M.Slate, "z", {name = "Geode"})
	k.cyl(0, 1.4, -5.48, 0.06, 2.1, amethyst, M.Neon, "z")
	k.cyl(0, 1.4, -6.52, 0.06, 2.1, amethyst, M.Neon, "z")
	-- a gem floating over the front
	local gem = k.box(0, 8.2, -6.8, 1.0, 1.0, 1.0, rgb(220, 160, 255), M.Glass, {rx = 45, rz = 45, t = 0.1, name = "FloatingGem"})
	k.glow(0, 8.2, -6.8, 0.5, 0.5, 0.5, amethyst, {rx = 45, rz = 45})
	k.light(gem, amethyst, 14, 1.2)
	k.fx(gem, "sparkle", amethyst, teal)
end)

-- 30: a storm generator: two Tesla coils with a lightning bolt jumping between them over the top
add("Storm Titan", function(k)
	local steel, dark, electric, cloud = rgb(70, 80, 100), rgb(30, 34, 46), rgb(120, 200, 255), rgb(90, 95, 110)
	k.deck(5, dark, M.Metal)
	k.belt({rgb(30, 35, 50), rgb(50, 60, 85)}, M.Metal, 4.2)
	k.m(function(s)
		k.cyl(s * 3.5, 0.5, -7.0, 1.0, 1.8, dark, M.Metal, "y", {name = "CoilBase"})
		k.cyl(s * 3.5, 3.3, -7.0, 4.6, 0.7, rgb(190, 120, 60), M.Metal, "y", {name = "Coil"})
		for i = 0, 2 do
			k.cyl(s * 3.5, 1.6 + i * 1.6, -7.0, 0.15, 1.3 - i * 0.2, steel, M.Metal, "y")
		end
		k.ring(s * 3.5, 6.0, -7.0, 0.65, 0.35, steel, M.Metal, "y", {n = 10, depth = 0.35, name = "Toroid"})
		k.ball(s * 3.5, 6.55, -7.0, 0.8, electric, M.Neon, {name = "CoilOrb"})
		k.ball(s * 3.6, 8.3, -7.3, 1.4, cloud, M.SmoothPlastic, {name = "Cloud"})
		k.ball(s * 2.9, 8.5, -6.9, 1.1, cloud, M.SmoothPlastic)
		k.glow(s * 2.6, 0.46, 0, 0.12, 0.04, 9.6, electric)
		k.box(s * 3.6, 1.0, 6.4, 0.2, 2.0, 0.2, steel, M.Metal, {name = "GroundRod"})
		k.ball(s * 3.6, 2.1, 6.4, 0.3, electric, M.Neon)
	end)
	-- the bolt: a zigzag that only dips low outside the runner's lane
	local pts = {{-3.3, 6.9}, {-2.45, 8.3}, {-0.8, 7.55}, {0.6, 8.6}, {2.45, 7.65}, {3.3, 6.9}}
	local mid
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local dx, dy = b[1] - a[1], b[2] - a[2]
		local seg = k.glow((a[1] + b[1]) / 2, (a[2] + b[2]) / 2, -7.0, math.sqrt(dx * dx + dy * dy) + 0.1, 0.16, 0.16, rgb(200, 235, 255), {rz = math.deg(math.atan2(dy, dx)), name = "Bolt"})
		mid = i == 3 and seg or mid
	end
	k.fx(mid, "sparkle", electric, WHITE)
	k.light(mid, electric, 16, 1.5)
	-- generator console
	local gen = k.box(0, 1.5, -5.8, 2.8, 2.6, 1.2, steel, M.Metal, {name = "Generator"})
	k.text(gen, "Back", "\u{26A1}", rgb(255, 230, 80))
	k.text(gen, "Front", "\u{26A1}", rgb(255, 230, 80))
	k.glow(0, 2.88, -5.8, 2.9, 0.15, 1.3, electric)
end)

-- 31: an Egyptian tomb run: obelisks with golden tips, a sarcophagus console, a step pyramid
add("Pharaoh's Run", function(k)
	local sandstone, gold, lapis, sand, skin = rgb(220, 190, 130), rgb(255, 200, 60), rgb(30, 60, 170), rgb(235, 210, 150), rgb(255, 215, 140)
	k.deck(5, sandstone, M.Sandstone)
	k.belt({sand, lapis}, M.Sandstone, 4.2)
	k.m(function(s)
		k.box(s * 2.6, 0.55, 0, 0.5, 0.5, 10, gold, M.Foil)
		k.box(s * 3.5, 0.4, -7.0, 1.8, 0.8, 1.8, sandstone, M.Sandstone)
		local obelisk = k.box(s * 3.5, 3.9, -7.0, 1.1, 6.2, 1.1, sandstone, M.Sandstone, {name = "Obelisk"})
		k.text(obelisk, "Front", "\u{2625}", lapis)
		k.text(obelisk, "Back", "\u{2625}", lapis)
		k.wedge(s * 3.5, 7.4, -7.275, 1.1, 0.8, 0.55, gold, M.Foil, {name = "Pyramidion"})
		k.wedge(s * 3.5, 7.4, -6.725, 1.1, 0.8, 0.55, gold, M.Foil, {ry = 180})
		k.cyl(s * 3.7, 0.8, 6.3, 1.6, 0.3, gold, M.Foil, "y")
		local bowl = k.cyl(s * 3.7, 1.75, 6.3, 0.4, 1.0, gold, M.Foil, "y", {name = "Brazier"})
		k.fx(bowl, "fire", rgb(255, 180, 60), rgb(255, 90, 20))
	end)
	-- the sarcophagus, its face to the path and a glowing scarab for the runner
	local sarc = k.box(0, 1.9, -6.0, 2.4, 3.4, 1.0, gold, M.Foil, {name = "Sarcophagus"})
	for i = 1, 3 do
		k.box(0, 0.5 + i * 0.6, -6.52, 2.42, 0.22, 0.05, lapis, M.SmoothPlastic, {name = "Band"})
	end
	k.box(0, 3.05, -6.52, 1.0, 0.8, 0.05, skin, M.SmoothPlastic, {name = "Face"})
	for _, x in ipairs({-0.22, 0.22}) do
		k.box(x, 3.15, -6.56, 0.2, 0.1, 0.03, BLACK, M.SmoothPlastic)
	end
	k.box(0, 3.75, -6.0, 2.5, 0.3, 1.1, lapis, M.SmoothPlastic)
	k.glow(0, 2.4, -5.48, 0.8, 0.6, 0.05, rgb(60, 220, 160), {name = "Scarab"})
	k.light(sarc, rgb(255, 210, 130), 12, 1)
	-- a step pyramid and a dune behind
	for i, w in ipairs({2.2, 1.6, 1.0}) do
		k.box(-3.6, (i - 0.5) * 0.65, 6.3, w, 0.65, w, sandstone, M.Sandstone, {name = "StepPyramid"})
	end
	k.wedge(1.5, 0.4, 6.6, 2.0, 0.8, 1.6, sand, M.Sand, {ry = 90, name = "Dune"})
end)

-- 32: a phoenix spreading fiery wings over the front, rising from two braziers
add("Phoenix Rising", function(k)
	local ember, flame, gold, deep = rgb(255, 90, 20), rgb(255, 170, 40), rgb(255, 215, 80), rgb(140, 30, 10)
	k.deck(5, deep, M.Slate)
	k.belt({rgb(120, 30, 10), rgb(190, 75, 20)}, M.SmoothPlastic, 4.2)
	local body = k.ball(0, 8.1, -7.0, 1.3, ember, M.Neon, {name = "PhoenixBody"})
	k.ball(0, 8.75, -7.6, 0.8, flame, M.Neon, {name = "PhoenixHead"})
	k.wedge(0, 8.7, -8.15, 0.25, 0.25, 0.45, gold, M.Foil, {name = "Beak"})
	k.box(0, 8.6, -6.3, 0.3, 0.4, 0.9, gold, M.Neon, {rx = -30, name = "Tail"})
	k.light(body, rgb(255, 140, 50), 16, 1.5)
	k.m(function(s)
		k.box(s * 1.45, 8.0, -7.0, 2.1, 0.5, 1.0, ember, M.Neon, {name = "Wing"})
		-- primary feathers droop outward from the wing tip
		for i, f in ipairs({{0, 2.2, ember}, {-25, 2.3, flame}, {-50, 2.2, gold}}) do
			local a = math.rad(f[1])
			k.box(s * (2.45 + math.cos(a) * f[2] / 2), 8.0 + math.sin(a) * f[2] / 2, -7.0 + (i - 2) * 0.2, f[2], 0.35, 0.8, f[3], M.Neon, {rz = s * f[1], name = "Feather"})
		end
		k.cyl(s * 3.6, 1.2, -7.0, 2.4, 1.2, deep, M.Slate, "y", {name = "BrazierStand"})
		local bowl = k.cyl(s * 3.6, 2.6, -7.0, 0.5, 1.6, gold, M.Foil, "y", {name = "Brazier"})
		k.fx(bowl, "fire", rgb(255, 180, 60), rgb(255, 60, 10))
		k.box(s * 1.6, 0.05, 6.2, 0.6, 0.06, 2.0, gold, M.Foil, {ry = s * -20, name = "FallenFeather"})
	end)
	-- a low golden altar holding glowing coals
	k.box(0, 1.2, -5.8, 2.4, 2.0, 1.0, deep, M.Slate, {name = "Altar"})
	k.box(0, 2.3, -5.8, 2.6, 0.2, 1.2, gold, M.Foil)
	k.glow(0, 2.45, -5.8, 2.0, 0.1, 0.8, flame, {name = "Coals"})
end)

-- 33: a cloud kingdom: winged pillars with halos, a golden arch, clouds all round and a cloud console
add("Cloud Kingdom", function(k)
	local white, cloud, gold, sky = rgb(250, 252, 255), rgb(235, 242, 255), rgb(255, 210, 90), rgb(160, 225, 255)
	k.deck(5, white, M.Marble)
	k.belt({rgb(240, 250, 255), sky}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.box(s * 3.4, 0.3, -6.8, 1.4, 0.6, 1.4, gold, M.Foil)
		k.cyl(s * 3.4, 3.4, -6.8, 6.4, 0.9, white, M.Marble, "y", {name = "Pillar"})
		k.box(s * 3.4, 6.75, -6.8, 1.3, 0.3, 1.3, gold, M.Foil)
		k.ring(s * 3.4, 7.6, -6.8, 0.55, 0.14, gold, M.Neon, "y", {n = 10, depth = 0.1, name = "Halo"})
		-- a feathered wing on the outside of each pillar
		for i, f in ipairs({{6, 3.0}, {16, 2.5}, {26, 2.0}}) do
			local a = math.rad(f[1])
			k.box(s * (3.55 + math.sin(a) * f[2] / 2), 4.4 + math.cos(a) * f[2] / 2, -6.8 + (i - 2) * 0.25, 0.4, f[2], 0.7, white:Lerp(sky, i * 0.15), M.SmoothPlastic, {rz = -s * f[1], name = "Feather"})
		end
		k.ball(s * 3.3, 0.6, -1.5, 1.6, cloud, M.SmoothPlastic, {name = "Cloud"})
		k.ball(s * 3.5, 0.5, 1.4, 1.4, cloud, M.SmoothPlastic, {name = "Cloud"})
		k.ball(s * 3.3, 0.6, 5.8, 1.8, cloud, M.SmoothPlastic, {name = "Cloud"})
	end)
	k.ring(0, 5.8, -6.8, 3.0, 0.3, gold, M.Foil, "z", {n = 12, a0 = -70, a1 = 70, depth = 0.3, name = "GoldArch"})
	local star = k.ball(0, 8.1, -6.8, 0.6, gold, M.Neon, {name = "Star"})
	k.fx(star, "sparkle", gold, WHITE)
	k.light(star, rgb(255, 240, 200), 14, 1.2)
	-- a cloud console with a little golden harp
	k.ball(0, 1.3, -6.0, 2.0, cloud, M.SmoothPlastic, {name = "Cloud"})
	k.ball(-0.9, 1.0, -5.8, 1.4, cloud, M.SmoothPlastic)
	k.ball(0.9, 1.1, -6.2, 1.5, cloud, M.SmoothPlastic)
	k.box(-0.45, 3.0, -6.0, 0.15, 1.5, 0.15, gold, M.Foil, {name = "Harp"})
	k.ring(-0.45, 3.0, -6.0, 0.75, 0.15, gold, M.Foil, "z", {n = 5, a0 = -20, a1 = -160, depth = 0.15})
	for i = 1, 3 do
		k.glow(-0.45 + i * 0.22, 3.0, -6.0, 0.03, 1.1 - math.abs(i - 2) * 0.25, 0.03, rgb(255, 250, 220))
	end
end)

-- 34: a stone portal: a gate of old bricks with crystals and glowing eyes, a see-through galaxy swirl inside
add("Star Portal", function(k)
	local light, darkstone, crystal, void = rgb(170, 170, 185), rgb(120, 120, 135), rgb(120, 240, 255), rgb(40, 30, 120)
	k.deck(5, darkstone, M.Cobblestone)
	k.belt({rgb(40, 50, 90), rgb(70, 90, 150)}, M.Slate, 4.2)
	k.m(function(s)
		for i = 0, 3 do
			k.box(s * (3.5 + (i % 2) * 0.1), 0.95 + i * 1.9, -7.0, 1.6, 1.9, 1.6, i % 2 == 0 and light or darkstone, M.Cobblestone, {name = "PortalStone"})
		end
		k.box(s * 4.1, 2.2, -6.3, 0.4, 1.6, 0.4, crystal, M.Glass, {rz = s * -25, t = 0.1, name = "Crystal"})
		k.box(s * 3.9, 8.5, -7.0, 0.45, 1.2, 0.45, crystal, M.Glass, {rz = s * -20, t = 0.1, name = "Crystal"})
		k.glow(s * 0.9, 8.15, -7.82, 0.6, 0.35, 0.05, crystal, {name = "RuneEye"})
		k.glow(s * 0.9, 8.15, -6.18, 0.6, 0.35, 0.05, crystal, {name = "RuneEye"})
	end)
	k.box(0, 8.1, -7.0, 8.6, 1.6, 1.6, light, M.Cobblestone, {name = "Lintel"})
	-- the swirl, see-through so the runner shows through it
	local disc = k.cyl(0, 4.0, -7.0, 0.1, 5.4, void, M.Neon, "z", {t = 0.6, name = "PortalDisc"})
	for i, r in ipairs({2.2, 1.5, 0.8}) do
		k.ring(0, 4.0, -7.0 + 0.05 * i, r, 0.16, crystal:Lerp(rgb(170, 90, 255), i / 3), M.Neon, "z", {n = 10, depth = 0.05, t = 0.6, rz = i * 25, name = "Swirl"})
	end
	k.fx(disc, "sparkle", crystal, rgb(170, 90, 255))
	k.light(disc, rgb(120, 160, 255), 14, 1.5)
	-- a stone pedestal holding a crystal, and shards behind
	k.box(0, 0.9, -5.4, 2.2, 1.8, 0.9, darkstone, M.Cobblestone, {name = "Pedestal"})
	k.box(0, 2.3, -5.4, 0.5, 1.0, 0.5, crystal, M.Glass, {ry = 45, t = 0.1})
	k.box(-3.5, 0.6, 6.3, 0.5, 1.4, 0.5, crystal, M.Glass, {rz = 15, rx = 10, t = 0.1, name = "Shard"})
	k.box(3.6, 0.5, 6.5, 0.4, 1.0, 0.4, crystal, M.Glass, {rz = -20, t = 0.1, name = "Shard"})
end)

-- 35: an infernal gate: iron pillars with curling horns, a chain strung between them, a horned skull console
add("Infernal Gate", function(k)
	local iron, rust, hellred, bone = rgb(40, 36, 38), rgb(70, 45, 40), rgb(255, 30, 20), rgb(220, 210, 190)
	k.deck(5, iron, M.CorrodedMetal)
	k.belt({rgb(30, 10, 10), rgb(70, 15, 15)}, M.CorrodedMetal, 4.2)
	k.m(function(s)
		k.box(s * 3.4, 3.2, -6.8, 1.2, 6.4, 1.2, iron, M.CorrodedMetal, {name = "Pillar"})
		k.box(s * 3.4, 6.55, -6.8, 1.5, 0.3, 1.5, rust, M.Metal)
		k.box(s * 3.75, 7.15, -6.8, 0.6, 1.0, 0.6, bone, M.SmoothPlastic, {rz = s * -25, name = "Horn"})
		k.box(s * 4.1, 7.95, -6.8, 0.45, 0.9, 0.45, bone, M.SmoothPlastic, {rz = s * -10})
		k.box(s * 4.15, 8.7, -6.8, 0.3, 0.7, 0.3, hellred, M.Neon, {rz = s * 8, name = "HornTip"})
		for _, z in ipairs({-3, 0, 3}) do
			k.wedge(s * 2.7, 0.9, z, 0.3, 1.2, 0.6, iron, M.Metal, {name = "Spike"})
		end
		k.box(s * 4.3, 5.9, -6.8, 0.06, 1.2, 0.06, iron, M.Metal)
		local lamp = k.box(s * 4.3, 5.0, -6.8, 0.45, 0.6, 0.45, hellred, M.Neon, {name = "Lantern"})
		k.fx(lamp, "fire", rgb(255, 60, 20), rgb(120, 0, 0))
	end)
	-- a chain strung across above head height
	for i = -3, 3 do
		k.box(i * 0.85, 7.62 - (9 - i * i) * 0.02, -6.8, 0.75, 0.3, 0.12, iron, M.Metal, {rx = i % 2 == 0 and 0 or 90, name = "ChainLink"})
	end
	-- the skull console, eyes burning both ways
	local skull = k.box(0, 1.9, -6.0, 2.4, 2.2, 1.6, bone, M.SmoothPlastic, {name = "Skull"})
	k.box(0, 0.4, -6.1, 1.8, 0.8, 1.3, bone, M.SmoothPlastic, {name = "Jaw"})
	k.m(function(s)
		k.glow(s * 0.55, 2.1, -6.82, 0.5, 0.45, 0.05, hellred, {name = "Eye"})
		k.glow(s * 0.55, 2.1, -5.18, 0.5, 0.45, 0.05, hellred, {name = "Eye"})
		k.box(s * 1.45, 3.3, -6.0, 0.3, 1.0, 0.3, bone, M.SmoothPlastic, {rz = s * -35, name = "SkullHorn"})
	end)
	k.light(skull, hellred, 12, 1.2)
	k.ring(0, 0.04, 6.3, 1.0, 0.12, hellred, M.Neon, "y", {n = 12, depth = 0.05, name = "RuneCircle"})
end)

-- 36: a celestial observatory: a brass telescope, an armillary sphere round a tiny sun, a crescent moon
add("Celestial Observatory", function(k)
	local navy, gold, star, sky = rgb(20, 30, 80), rgb(255, 200, 70), rgb(255, 250, 220), rgb(120, 170, 255)
	k.deck(5, navy, M.SmoothPlastic)
	k.belt({rgb(15, 20, 60), rgb(30, 40, 100)}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.box(s * 2.6, 0.5, 0, 0.35, 0.3, 10.1, gold, M.Foil)
		k.glow(s * 3.4, 0.04, 0, 0.06, 0.04, 5.5, sky, {ry = s * 8, name = "Constellation"})
		for _, z in ipairs({-2.7, 0.3, 2.7}) do
			k.ball(s * (3.4 - z * 0.05), 0.05, z, 0.3, star, M.Neon)
		end
	end)
	-- telescope on a tripod, left
	for _, a in ipairs({0, 120, 240}) do
		local r = math.rad(a)
		k.box(-3.6 + math.sin(r) * 0.35, 1.65, -7.4 + math.cos(r) * 0.35, 0.14, 3.3, 0.14, gold, M.Foil, {rz = math.sin(r) * 12, rx = -math.cos(r) * 12, name = "Tripod"})
	end
	k.ball(-3.6, 3.3, -7.4, 0.6, gold, M.Foil)
	k.cyl(-3.6, 4.39, -7.91, 3.4, 0.8, navy, M.Metal, "y", {rx = -25, name = "Telescope"})
	k.cyl(-3.6, 4.39, -7.91, 0.4, 0.9, gold, M.Foil, "y", {rx = -25})
	k.cyl(-3.6, 5.93, -8.63, 0.06, 0.7, sky, M.Neon, "y", {rx = -25, name = "Lens"})
	-- armillary sphere, right
	k.cyl(3.5, 0.2, -7.2, 0.4, 1.4, navy, M.SmoothPlastic, "y")
	k.cyl(3.5, 1.4, -7.2, 2.8, 0.4, gold, M.Foil, "y")
	for _, axis in ipairs({"x", "y", "z"}) do
		k.ring(3.5, 4.3, -7.2, 1.1, 0.12, gold, M.Foil, axis, {n = 10, depth = 0.12, name = "Armillary"})
	end
	local sun = k.ball(3.5, 4.3, -7.2, 0.6, gold, M.Neon, {name = "Sun"})
	k.light(sun, rgb(255, 220, 140), 12, 1.2)
	k.fx(sun, "sparkle", gold, star)
	-- a crescent moon over the front
	k.ring(0, 8.25, -7.2, 0.7, 0.22, star, M.Neon, "z", {n = 8, a0 = 30, a1 = 250, depth = 0.2, name = "Moon"})
	-- the star chart console
	local chart = k.box(0, 1.6, -5.7, 2.8, 2.4, 0.6, navy, M.SmoothPlastic, {name = "StarChart"})
	k.text(chart, "Back", "\u{2726} \u{00B7} \u{2727}\n\u{00B7} \u{2605} \u{00B7}\n\u{2727} \u{00B7} \u{2726}", star)
	k.box(0, 2.85, -5.7, 3.0, 0.15, 0.7, gold, M.Foil)
end)

-- 37: a rainbow of mystery: three bands arching off stacks of ? blocks, a rainbow belt, a ? console
add("Rainbow Mystery", function(k)
	local rainbow = {rgb(255, 70, 70), rgb(255, 160, 40), rgb(255, 230, 60), rgb(80, 220, 90), rgb(60, 170, 255), rgb(150, 90, 255)}
	k.deck(5, WHITE, M.SmoothPlastic)
	k.belt(rainbow, M.SmoothPlastic, 4.2)
	-- each band has its own centre so every one clears the runner's head
	for i, b in ipairs({{4.25, 4.75, rainbow[1]}, {3.95, 4.95, rainbow[3]}, {3.65, 5.15, rainbow[5]}}) do
		k.ring(0, b[2], -7.6 + (i - 1) * 0.2, b[1], 0.3, b[3], M.Neon, "z", {n = 12, a0 = -90, a1 = 90, depth = 0.4, name = "Rainbow"})
	end
	local function block(x, y, z, size, color, turn)
		local b = k.box(x, y, z, size, size, size, color, M.SmoothPlastic, {ry = turn, name = "MysteryBlock"})
		k.text(b, "Front", "?", WHITE)
		k.text(b, "Back", "?", WHITE)
		return b
	end
	k.m(function(s)
		for i = 0, 2 do
			block(s * 3.95, 0.7 + i * 1.4, -7.4, 1.4, rainbow[(i * 2 + (s > 0 and 1 or 0)) % 6 + 1], (i % 2 == 0 and 8 or -8) * s)
		end
		block(s * 3.6, 0.5, 6.3, 1.0, rainbow[s > 0 and 4 or 2], 20 * s)
	end)
	local console = block(0, 1.0, -5.8, 1.8, rgb(255, 200, 40), 0)
	k.fx(console, "sparkle", rgb(255, 120, 200), rgb(120, 220, 255))
	k.light(console, rgb(255, 230, 160), 12, 1)
end)

-- 38: a kraken rising from a shipwreck: two great tentacles curling over the front, an anchor console
add("Kraken's Grasp", function(k)
	local wreck, purple, tip, sucker, iron = rgb(60, 70, 60), rgb(110, 40, 140), rgb(200, 120, 220), rgb(240, 170, 210), rgb(55, 60, 66)
	k.deck(5, wreck, M.WoodPlanks)
	k.belt({rgb(20, 50, 60), rgb(30, 70, 80)}, M.WoodPlanks, 4.2)
	-- (x, y, diameter) up the right tentacle; mirrored for the left
	local big = {{3.6, 0.6, 1.4}, {3.75, 1.7, 1.3}, {3.85, 2.8, 1.2}, {3.8, 3.9, 1.1}, {3.6, 4.9, 1.0}, {3.35, 5.85, 0.95},
		{3.1, 6.75, 0.9}, {2.7, 7.55, 0.8}, {2.0, 8.15, 0.7}, {1.25, 8.4, 0.6}, {0.6, 8.2, 0.5}, {0.35, 7.75, 0.4}}
	k.m(function(s)
		local z = -7.2 + s * 0.3
		for i, p in ipairs(big) do
			k.ball(s * p[1], p[2], z, p[3], purple:Lerp(tip, i / #big), M.SmoothPlastic, {name = "Tentacle"})
			if i >= 3 and i <= 7 then
				k.ball(s * (p[1] - p[3] / 2), p[2], z, 0.35, sucker, M.SmoothPlastic, {name = "Sucker"})
			end
		end
		k.box(s * 2.6, 0.55, 0, 0.5, 0.5, 10, rgb(80, 60, 40), M.WoodPlanks)
	end)
	-- a smaller tentacle curling up beside the belt
	for i, p in ipairs({{3.7, 0.45, 0.9}, {3.9, 1.2, 0.8}, {3.85, 2.0, 0.65}, {3.6, 2.6, 0.5}, {3.35, 2.95, 0.4}}) do
		k.ball(p[1], p[2], 1.5, p[3], purple:Lerp(tip, i / 5), M.SmoothPlastic, {name = "Tentacle"})
	end
	-- the anchor console
	k.box(0, 2.2, -6.0, 0.35, 3.4, 0.35, iron, M.Metal, {name = "Anchor"})
	k.ring(0, 4.15, -6.0, 0.3, 0.1, iron, M.Metal, "z", {n = 8, depth = 0.1})
	k.box(0, 3.55, -6.0, 1.8, 0.25, 0.25, rgb(110, 80, 50), M.Wood)
	local arms = k.ring(0, 1.4, -6.0, 1.0, 0.3, iron, M.Metal, "z", {n = 7, a0 = 110, a1 = 250, depth = 0.3})
	k.fx(arms[4], "rise", rgb(200, 240, 255), WHITE)
	-- its eyes, peeping out from under the front of the pad
	k.m(function(s)
		local eye = k.ball(s * 1.1, 0.25, -8.8, 0.9, rgb(255, 220, 60), M.Neon, {name = "KrakenEye"})
		k.box(s * 1.1, 0.3, -9.2, 0.15, 0.5, 0.1, BLACK, M.SmoothPlastic)
		if s > 0 then
			k.light(eye, rgb(120, 230, 220), 12, 1)
		end
	end)
end)

-- 39: a quantum core: a great chrome ring with rune lights, a violet core over the top, capacitor tubes
add("Quantum Core", function(k)
	local chrome, black, violet, white = rgb(200, 205, 215), rgb(18, 18, 24), rgb(160, 80, 255), rgb(240, 240, 255)
	k.deck(4.8, black, M.SmoothPlastic)
	k.belt({rgb(25, 25, 35), rgb(60, 40, 110)}, M.SmoothPlastic, 4.2)
	k.ring(0, 4.6, -7.4, 4.0, 0.45, chrome, M.Metal, "z", {n = 20, depth = 0.6, rz = 9, name = "QuantumRing"})
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		k.glow(-math.sin(a) * 4.0, 4.6 + math.cos(a) * 4.0, -7.08, 0.3, 0.3, 0.05, violet, {rz = i * 45 + 22.5, name = "Rune"})
	end
	local core = k.ball(0, 7.9, -7.4, 0.8, violet, M.Neon, {name = "Core"})
	k.ring(0, 7.9, -7.4, 0.75, 0.08, white, M.Neon, "y", {n = 10, depth = 0.08, name = "Orbit"})
	k.fx(core, "sparkle", violet, white)
	k.light(core, violet, 14, 1.5)
	k.m(function(s)
		k.cyl(s * 3.0, 1.2, 0, 8, 0.8, white, M.Glass, "z", {t = 0.5, name = "Capacitor"})
		k.cyl(s * 3.0, 1.2, 0, 7.6, 0.4, violet, M.Neon, "z")
		k.cyl(s * 3.0, 1.2, -4.1, 0.4, 1.0, chrome, M.Metal, "z")
		k.cyl(s * 3.0, 1.2, 4.1, 0.4, 1.0, chrome, M.Metal, "z")
		k.box(s * 3.0, 0.5, -7.4, 1.4, 1.0, 1.4, black, M.SmoothPlastic, {name = "RingFoot"})
	end)
	k.cyl(0, 1.2, -5.6, 2.4, 1.6, chrome, M.Metal, "y", {name = "Pedestal"})
	k.cyl(0, 2.45, -5.6, 0.1, 1.5, violet, M.Neon, "y")
	local dial = k.cyl(0, 3.6, -5.6, 0.05, 1.6, violet, M.Neon, "z", {t = 0.6, name = "HoloDial"})
	k.light(dial, violet, 10, 1)
end)

-- 40 (MAX): the Cosmic Emperor, a chrome-and-gold star throne. Armoured nacelles with gold dorsal fins and violet
-- thrusters run down both sides; layered horns of gold and chrome sweep up from the prows and curl over the
-- runner's head; between their tips a star core turns inside a spinning orrery (no other machine moves). A
-- black glass dais with gold bands carries the crown, and a swept rear wing closes the back.
add("Cosmic Emperor", function(k)
	local void, chrome, gold, star, violet, cyan = rgb(16, 10, 34), rgb(214, 220, 236), rgb(255, 205, 70), rgb(255, 250, 230), rgb(150, 80, 255), rgb(120, 230, 255)
	k.box(0, 0.225, 0, 5.0, 0.45, 10, void, M.Glass, {solid = true, name = "Deck"})
	k.belt({rgb(20, 10, 40), rgb(40, 18, 78)}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		-- gold belt rails with a violet light along the top
		k.box(s * 2.36, 0.55, 0, 0.28, 0.3, 9.6, gold, M.Foil, {name = "Rail"})
		k.glow(s * 2.36, 0.72, 0, 0.12, 0.04, 9.2, violet)
		-- the nacelle: chrome hull, black glass armour, a gold spine whose fins rise toward the back
		k.box(s * 3.4, 0.6, 0, 1.5, 1.2, 9.2, chrome, M.Metal, {refl = 0.25, name = "Nacelle"})
		k.box(s * 3.4, 1.32, 0, 1.3, 0.25, 8.6, void, M.Glass, {name = "Armour"})
		k.box(s * 3.4, 1.5, 0, 0.22, 0.12, 8.8, gold, M.Foil, {name = "Spine"})
		for i, z in ipairs({-3, -1, 1, 3}) do
			local h = 0.25 + i * 0.24
			k.wedge(s * 3.4, 1.56 + h / 2, z, 0.12, h, 1.1, gold, M.Foil, {name = "Fin"})
		end
		k.glow(s * 4.16, 0.7, 0, 0.05, 0.16, 8.0, violet, {name = "Channel"})
		k.glow(s * 3.4, 0.02, 0, 1.2, 0.04, 9.0, violet, {name = "Underglow"})
		k.wedge(s * 3.4, 0.6, -5.6, 1.5, 1.2, 2.0, chrome, M.Metal, {refl = 0.25, name = "Prow"})
		-- thruster with a gold collar and a glowing core
		k.cyl(s * 3.4, 0.65, 5.3, 1.4, 1.0, chrome, M.Metal, "z", {refl = 0.25, name = "Thruster"})
		k.cyl(s * 3.4, 0.65, 4.72, 0.2, 1.15, gold, M.Foil, "z")
		k.cyl(s * 3.4, 0.65, 6.02, 0.06, 0.72, violet, M.Neon, "z", {name = "ThrusterCore"})
		-- the horns: gold outside, a chrome band and (lower down) a violet edge inside, curling over the top
		k.box(s * 2.95, 0.7, -7.0, 1.3, 1.4, 1.3, chrome, M.Metal, {refl = 0.25, name = "HornFoot"})
		k.box(s * 2.95, 1.45, -7.0, 1.4, 0.12, 1.4, gold, M.Foil)
		k.ring(0, 4.4, -7.0, 4.15, 0.5, gold, M.Foil, "z", {n = 8, a0 = s * -138, a1 = s * -27, depth = 0.7, name = "Horn"})
		k.ring(0, 4.4, -7.0, 3.82, 0.18, chrome, M.Metal, "z", {n = 8, a0 = s * -138, a1 = s * -27, depth = 0.85, refl = 0.25, name = "HornBand"})
		k.ring(0, 4.4, -7.0, 3.66, 0.12, function(f)
			return violet:Lerp(cyan, f)
		end, M.Neon, "z", {n = 5, a0 = s * -134, a1 = s * -50, depth = 0.4, name = "HornEdge"})
		k.ball(s * 1.88, 8.1, -7.0, 0.55, gold, M.Foil, {name = "HornTip"})
		-- the rear wing's struts
		k.box(s * 1.6, 1.05, 6.6, 0.15, 1.0, 0.5, gold, M.Foil, {name = "WingStrut"})
	end)
	-- the orrery between the horn tips: a star core and two rings turning different ways
	local core = k.ball(0, 8.25, -7.0, 0.8, star, M.Neon, {name = "StarCore"})
	k.fx(core, "sparkle", gold, star)
	k.light(core, rgb(210, 170, 255), 16, 1.6)
	k.spin(k.ring(0, 8.25, -7.0, 0.8, 0.1, gold, M.Neon, "y", {n = 8, depth = 0.1, rx = 20, name = "Orrery"}), 0, 8.25, -7.0, Vector3.yAxis, 0.9, {rx = 20})
	k.spin(k.ring(0, 8.25, -7.0, 0.72, 0.08, cyan, M.Neon, "x", {n = 8, depth = 0.08, name = "Orrery"}), 0, 8.25, -7.0, Vector3.yAxis, -0.6)
	-- the dais: chrome foot, black glass column with gold bands, the crown on top
	k.cyl(0, 0.2, -5.9, 0.4, 2.0, chrome, M.Metal, "y", {refl = 0.25, name = "DaisFoot"})
	k.cyl(0, 0.44, -5.9, 0.08, 2.1, violet, M.Neon, "y")
	local dais = k.box(0, 1.55, -5.9, 1.5, 2.1, 1.0, void, M.Glass, {name = "Dais"})
	k.text(dais, "Front", "\u{2605} MAX \u{2605}", gold)
	k.text(dais, "Back", "\u{2605} MAX \u{2605}", gold)
	k.light(dais, violet, 10, 1)
	for _, y in ipairs({0.75, 2.6}) do
		k.box(0, y, -5.9, 1.6, 0.14, 1.1, gold, M.Foil, {name = "DaisBand"})
	end
	k.ring(0, 2.95, -5.9, 0.6, 0.12, gold, M.Foil, "y", {n = 8, depth = 0.5, name = "Crown"})
	for i = 0, 4 do
		local a = math.rad(i * 72)
		k.box(math.sin(a) * 0.6, 3.4, -5.9 + math.cos(a) * 0.6, 0.16, 0.45, 0.16, gold, M.Foil, {ry = i * 72, name = "CrownPoint"})
	end
	local jewel = k.ball(0, 3.15, -5.9, 0.4, rgb(255, 40, 90), M.Neon, {name = "Jewel"})
	k.fx(jewel, "rise", violet, gold)
	-- the swept rear wing, low enough for the camera behind to look over
	k.box(0, 1.62, 6.6, 4.4, 0.14, 0.9, chrome, M.Metal, {refl = 0.25, rx = -6, name = "RearWing"})
	k.glow(0, 1.62, 7.06, 4.4, 0.06, 0.06, violet)
end)

assert(#MODELS >= 1, "no treadmill models")

------------------------------------------------------------------
-- TIERS: every 8 levels the treadmill moves up a tier, and whatever its theme, every machine stands on its
-- tier's stage: a rim round the pad in the tier's finish, rank lights front and back (one more lights up each
-- level, all 8 at the top of a tier), and back-corner pieces that grow with the tier (low enough that the
-- camera behind the runner looks over them). Stage parts are all named "Tier...".
------------------------------------------------------------------
TM.LEVELS_PER_TIER = 8
TM.TIERS = {
	{Name = "Standard", Rim = rgb(62, 66, 76), Mat = M.SmoothPlastic, Pip = rgb(120, 200, 255)},
	{Name = "Bronze", Rim = rgb(140, 84, 44), Mat = M.Metal, Pip = rgb(255, 150, 60), Inlay = rgb(215, 140, 75), Post = 0.6},
	{Name = "Chrome", Rim = rgb(200, 206, 220), Mat = M.Metal, Refl = 0.3, Pip = rgb(90, 230, 255), Inlay = rgb(50, 56, 70), Line = rgb(90, 230, 255), Post = 1.2},
	{Name = "Gold", Rim = rgb(36, 32, 30), Mat = M.Metal, Pip = rgb(255, 210, 80), Inlay = rgb(255, 200, 60), InlayMat = M.Foil, Line = rgb(255, 180, 50), Post = 1.8},
	{Name = "Prism", Rim = rgb(236, 240, 250), Mat = M.Marble, Pip = "rainbow", Inlay = rgb(170, 220, 255), InlayMat = M.Glass, Line = rgb(190, 140, 255), Crystal = rgb(200, 235, 255)},
	{Name = "MAX", Rim = rgb(18, 12, 34), Mat = M.Glass, Pip = rgb(255, 205, 70), Inlay = rgb(255, 205, 70), InlayMat = M.Foil, Line = rgb(150, 80, 255), Crystal = rgb(255, 215, 120)},
}

function TM.tier(level)
	return TM.TIERS[math.min(level // TM.LEVELS_PER_TIER + 1, #TM.TIERS)]
end

-- how many rank lights are lit at `level` (1..8)
function TM.rank(level)
	return level // TM.LEVELS_PER_TIER + 1 >= #TM.TIERS and TM.LEVELS_PER_TIER or level % TM.LEVELS_PER_TIER + 1
end

local RIM_X, RIM_FRONT, RIM_BACK, RIM_W = 4.55, -9.15, 7.35, 0.4
local function buildStage(k, level)
	local tier, rank = TM.tier(level), TM.rank(level)
	local midZ, sideLen, endLen = (RIM_FRONT + RIM_BACK) / 2, RIM_BACK - RIM_FRONT + RIM_W, RIM_X * 2 - RIM_W
	local function rim(y, h, wide, color, mat, refl, name)
		k.m(function(s)
			k.box(s * RIM_X, y, midZ, wide, h, sideLen, color, mat, {refl = refl, name = name})
		end)
		for _, z in ipairs({RIM_FRONT, RIM_BACK}) do
			k.box(0, y, z, endLen, h, wide, color, mat, {refl = refl, name = name})
		end
	end
	rim(0.08, 0.32, RIM_W, tier.Rim, tier.Mat, tier.Refl, "TierRim")
	if tier.Inlay then
		rim(0.26, 0.04, 0.14, tier.Inlay, tier.InlayMat or M.Metal, nil, "TierInlay")
	end
	if tier.Line then
		-- a light line round the foot of the rim, just outside it
		k.m(function(s)
			k.glow(s * 4.77, 0.03, midZ, 0.04, 0.06, sideLen, tier.Line, {name = "TierLine"})
		end)
		for _, z in ipairs({RIM_FRONT - 0.22, RIM_BACK + 0.22}) do
			k.glow(0, 0.03, z, endLen + 0.4, 0.06, 0.04, tier.Line, {name = "TierLine"})
		end
	end
	-- rank lights on the front rim (seen from the path) and the back rim (seen from behind the runner)
	for i = 1, TM.LEVELS_PER_TIER do
		local lit = i <= rank
		local color = tier.Pip == "rainbow" and Color3.fromHSV((i - 1) / TM.LEVELS_PER_TIER, 0.55, 1) or tier.Pip
		for _, z in ipairs({RIM_FRONT, RIM_BACK}) do
			k.box(-2.45 + (i - 1) * 0.7, 0.3, z, 0.36, 0.14, 0.24, lit and color or tier.Rim:Lerp(BLACK, 0.4), lit and M.Neon or M.SmoothPlastic, {name = "TierPip"})
		end
	end
	-- back corners: a post that grows with the tier, or a turning crystal at the top two tiers
	k.m(function(s)
		if tier.Crystal then
			local x, z = s * 4.35, 7.2
			k.box(x, 0.12, z, 0.7, 0.24, 0.7, tier.Inlay, tier.InlayMat, {name = "TierPost"})
			local shell = k.box(x, 1.25, z, 0.55, 2.0, 0.55, tier.Crystal, M.Glass, {t = 0.25, ry = 45, name = "TierCrystal"})
			local core = k.glow(x, 1.25, z, 0.22, 1.6, 0.22, tier.Line, {ry = 45, name = "TierCrystal"})
			k.spin({shell, core}, x, 1.25, z, Vector3.yAxis, s * 0.8)
		elseif tier.Post then
			local x, z, h = s * 4.45, 7.25, tier.Post
			k.box(x, h / 2, z, 0.6, h, 0.6, tier.Rim, tier.Mat, {refl = tier.Refl, name = "TierPost"})
			if tier.Line then
				k.glow(x, h + 0.09, z, 0.4, 0.18, 0.4, tier.Line, {name = "TierPost"})
			else
				k.box(x, h + 0.06, z, 0.66, 0.12, 0.66, tier.Inlay, M.Metal, {name = "TierPost"})
			end
		end
	end)
end

------------------------------------------------------------------
-- BUILDING ONE
------------------------------------------------------------------
function TM.get(level)
	return MODELS[math.clamp(level, 0, #MODELS - 1) + 1]
end

-- builds the machine for `level` into `model`, placed by the plot's TreadCF; returns the belt slats
function TM.build(level, model, treadCF)
	local design = TM.get(level)
	local slats = {}
	local kit = newKit(model, treadCF * TM.ORIGIN, slats)
	design.Build(kit)
	buildStage(kit, level)
	assert(#slats == TM.SLAT_COUNT, design.Name .. " has no belt")
	return slats, design
end

return TM

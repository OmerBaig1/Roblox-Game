--[[
	STEAL A GAME - TREADMILL MODELS
	What the treadmill looks like at every level: 15 machines, from the Starter Jogger (level 0) to the Cosmic Emperor
	(level 14, MAX). Only looks live here. Speed gains, prices and saving stay in Config and the main script.
	Base.rebuildTreadmill calls TreadModels.build whenever the level changes. Each machine is its own module in
	the Machines folder (returning {Name, Build = function(k)}), in level order by module name.

	Designs are built in "design space" around the belt: x is to the runner's right, y is up from the top of the pad,
	z points to the runner's back (the runner faces -z, toward the console). The belt runs from z = -4.5 to 4.5 and
	the runner stands at z = 0.

	Every design stays inside ENVELOPE so the runner is never hidden (UnitTest TreadModels_Test builds every level and
	checks this):
	  - nothing over the belt where the runner stands
	  - beside the belt: nothing higher than the runner's hip
	  - straight in front of the runner: console height, or high above their head (tall pieces go to the sides);
	    see-through parts are allowed there
	  - behind the belt: low, so the camera behind the runner looks over it

	Everything that moves is marked with k.anim and moved by the client (TreadFx), so the server sends nothing per frame.
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
	HalfW = 4.8, FrontZ = -9.4, BackZ = 7.6, MaxY = 12.4, -- the whole machine fits on the pad
	RunnerHalfW = 2.2, BeltHalfL = 4.5,                  -- the runner's space over the belt
	SideMaxY = 3.4,                                      -- beside the belt
	FrontLowY = 4.6, FrontHighY = 7.2,                   -- straight in front: below the first or above the second
	SeeThrough = 0.6,                                    -- parts at least this transparent may go in front
	BackMaxY = 2.4,                                      -- behind the belt
	MaxParts = 420, MaxLights = 5, MaxEmitters = 8,      -- parts include the tier stage (~30)
}

local PARTICLE = "rbxasset://textures/particles/"
local TEXTURES = {
	sparkle = PARTICLE .. "sparkles_main.dds", smoke = PARTICLE .. "smoke_main.dds", fire = PARTICLE .. "fire_main.dds",
	sparks = PARTICLE .. "fire_sparks_main.dds", glow = PARTICLE .. "forcefield_glow_main.dds",
	vortex = PARTICLE .. "forcefield_vortex_main.dds", core = PARTICLE .. "explosion01_core_main.dds",
	puff = PARTICLE .. "explosion01_smoke_main.dds", wave = PARTICLE .. "explosion01_shockwave_main.dds",
}

------------------------------------------------------------------
-- BUILD KIT: every helper takes design-space positions and sizes. Options (o):
-- rx/ry/rz = turn in degrees, t = transparency, refl = reflectance, solid = people can stand on it, name
------------------------------------------------------------------
local AXIS = {x = CFrame.new(), y = CFrame.Angles(0, 0, math.pi / 2), z = CFrame.Angles(0, math.pi / 2, 0)}

local function newKit(model, origin, slats)
	local k = {rgb = rgb, M = M, WHITE = WHITE, BLACK = BLACK, V = Vector3.new}
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
		p.CastShadow = o.shadow ~= false and (o.t or 0) < 0.5
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
	function k.corner(x, y, z, sx, sy, sz, color, mat, o)
		o = o or {}
		return make("CornerWedgePart", CFrame.new(x, y, z) * turn(o), Vector3.new(sx, sy, sz), color, mat, o)
	end
	function k.ball(x, y, z, d, color, mat, o)
		o = o or {}
		o.shape = Enum.PartType.Ball
		return make("Part", CFrame.new(x, y, z) * turn(o), Vector3.new(d, d, d), color, mat, o)
	end
	-- a smooth stretched sphere: the bodywork shape
	function k.ell(x, y, z, sx, sy, sz, color, mat, o)
		o = o or {}
		local p = make("Part", CFrame.new(x, y, z) * turn(o), Vector3.new(sx, sy, sz), color, mat, o)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end
	-- a cylinder `len` long along `axis` ("x", "y" or "z"; turned by o first)
	function k.cyl(x, y, z, len, d, color, mat, axis, o)
		o = o or {}
		o.shape = Enum.PartType.Cylinder
		return make("Part", CFrame.new(x, y, z) * turn(o) * AXIS[axis or "x"], Vector3.new(len, d, d), color, mat, o)
	end
	-- a rod from point a to point b (Vector3s); o.box makes it square
	function k.seg(a, b, d, color, mat, o)
		o = o or {}
		if not o.box then
			o.shape = Enum.PartType.Cylinder
		end
		return make("Part", CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new((b - a).Magnitude, d, d), color, mat, o)
	end
	-- a flat triangle between three points (Vector3s), made of two wedges: facets, membranes, sails. Returns both parts.
	function k.tri(a, b, c, color, mat, o)
		o = o or {}
		local thick = o.thick or 0.06
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		return {
			make("WedgePart", CFrame.fromMatrix((a + b) / 2, right, up, back), Vector3.new(thick, height, math.abs(ab:Dot(back))), color, mat, o),
			make("WedgePart", CFrame.fromMatrix((a + c) / 2, -right, up, -back), Vector3.new(thick, height, math.abs(ac:Dot(back))), color, mat, o),
		}
	end
	-- a round body standing up from (x, y, z): profile is {{height, diameter}, ...} with a slice between each pair
	function k.lathe(x, y, z, profile, color, mat, o)
		o = o or {}
		local parts = {}
		for i = 1, #profile - 1 do
			local a, b = profile[i], profile[i + 1]
			local copy = table.clone(o)
			table.insert(parts, k.cyl(x, y + (a[1] + b[1]) / 2, z, math.abs(b[1] - a[1]) + 0.02, (a[2] + b[2]) / 2, type(color) == "function" and color(i / (#profile - 1)) or color, mat, "y", copy))
		end
		return parts
	end
	-- see-through vessel glass. Plastic, not the Glass material: particles and parts inside must show through it
	function k.glass(x, y, z, len, d, tint, axis, o)
		o = o or {}
		o.t = o.t or 0.72
		o.refl = o.refl or 0.15
		o.name = o.name or "VesselGlass"
		return k.cyl(x, y, z, len, d, tint, M.SmoothPlastic, axis or "y", o)
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
	-- a cog: hub, disc and o.teeth teeth round it. Returns its parts, ready for k.anim("spin", ...)
	function k.gear(x, y, z, r, depth, color, mat, axis, o)
		o = o or {}
		local parts = {k.cyl(x, y, z, depth, r * 2, color, mat, axis, {rx = o.rx, ry = o.ry, rz = o.rz, name = o.name or "Gear"})}
		for _, p in ipairs(k.ring(x, y, z, r + 0.08, 0.26, color, mat, axis, {n = o.teeth or 10, depth = depth, rx = o.rx, ry = o.ry, rz = o.rz, name = o.name or "GearTooth"})) do
			p.Size = axis == "x" and Vector3.new(p.Size.X, p.Size.Y, 0.3) or axis == "y" and Vector3.new(0.3, p.Size.Y, p.Size.Z) or Vector3.new(0.3, p.Size.Y, p.Size.Z)
			table.insert(parts, p)
		end
		return parts
	end
	-- a wheel on an "x" axle: tyre, rim and spokes. Returns its parts, ready for k.anim("spin", ...)
	function k.wheel(x, y, z, d, width, tyre, rim, o)
		o = o or {}
		local parts = {
			k.cyl(x, y, z, width, d, tyre, o.tyreMat or M.Rubber, "x", {name = "Tyre"}),
			k.cyl(x, y, z, width + 0.04, d * 0.62, rim, o.rimMat or M.Metal, "x", {name = "Rim", refl = o.refl}),
			k.cyl(x, y, z, width + 0.1, d * 0.2, o.hub or tyre, o.rimMat or M.Metal, "x", {name = "Hub"}),
		}
		for i = 0, (o.spokes or 5) - 1 do
			table.insert(parts, k.box(x, y, z, width + 0.08, d * 0.54, d * 0.07, o.spoke or tyre, M.SmoothPlastic, {rx = i * 180 / (o.spokes or 5), name = "Spoke"}))
		end
		return parts
	end
	-- marks parts as moving; the client does the moving (see TreadFx for every kind and its settings).
	-- x, y, z is the pivot; vectors in params and path are relative to it.
	function k.anim(kind, parts, x, y, z, params, o)
		local m = Instance.new("Model")
		m.Name = "Fx_" .. kind
		local function take(list)
			for _, p in ipairs(list) do
				if typeof(p) == "Instance" then
					p.Parent = m
				else
					take(p)
				end
			end
		end
		take(typeof(parts) == "Instance" and {parts} or parts)
		m.WorldPivot = origin * CFrame.new(x, y, z) * turn(o or {})
		m:SetAttribute("Fx", kind)
		for key, v in pairs(params or {}) do
			if key == "path" then
				for i, point in ipairs(v) do
					m:SetAttribute("P" .. i, point)
				end
			else
				m:SetAttribute(key, v)
			end
		end
		m:AddTag("TreadAnim")
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
	-- an invisible part for emitters and lights to sit on (Box shape emitters fill it)
	function k.spot(x, y, z, sx, sy, sz, o)
		o = o or {}
		o.t, o.name = 1, o.name or "FxSpot"
		return k.box(x, y, z, sx or 0.2, sy or 0.2, sz or 0.2, WHITE, M.SmoothPlastic, o)
	end
	-- a particle emitter. e = {tex, c1, c2, size = {start, end}, alpha = {start, end}, life = {min, max}, speed = {min, max},
	-- rate, spread = {x, y}, dir = "Top", accel, drag, light, rot = {min, max}, spinV = {min, max}, run = rate while running}
	function k.emit(p, e)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = TEXTURES[e.tex or "sparkle"]
		pe.Color = ColorSequence.new(e.c1 or WHITE, e.c2 or e.c1 or WHITE)
		pe.Size = NumberSequence.new(e.size and e.size[1] or 0.4, e.size and e.size[2] or 0)
		pe.Transparency = NumberSequence.new(e.alpha and e.alpha[1] or 0, e.alpha and e.alpha[2] or 1)
		pe.Lifetime = NumberRange.new(e.life and e.life[1] or 1, e.life and e.life[2] or 2)
		pe.Speed = NumberRange.new(e.speed and e.speed[1] or 1, e.speed and e.speed[2] or 2)
		pe.Rate = e.rate or 5
		pe.SpreadAngle = e.spread and Vector2.new(e.spread[1], e.spread[2]) or Vector2.new(10, 10)
		pe.EmissionDirection = Enum.NormalId[e.dir or "Top"]
		pe.Acceleration = e.accel or Vector3.zero
		pe.Drag = e.drag or 0
		pe.LightEmission = e.light or 0.6
		pe.LightInfluence = e.lit or 0
		pe.Rotation = e.rot and NumberRange.new(e.rot[1], e.rot[2]) or NumberRange.new(0, 360)
		pe.RotSpeed = e.spinV and NumberRange.new(e.spinV[1], e.spinV[2]) or NumberRange.new(-30, 30)
		pe.Shape = Enum.ParticleEmitterShape.Box
		if e.run then
			pe:SetAttribute("RunRate", e.run)
		end
		pe.Parent = p
		return pe
	end
	-- a machine's own running sound in place of its tier's: {SoundId, volume, playback speed}
	function k.motor(id, volume, speed)
		k.Motor = {id, volume, speed or 1}
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
-- THE MACHINES, in unlock order (the first is level 0)
------------------------------------------------------------------
local MODELS = {}
TM.MODELS = MODELS
do
	local modules = script.Machines:GetChildren()
	table.sort(modules, function(a, b)
		return a.Name < b.Name
	end)
	for _, module in ipairs(modules) do
		table.insert(MODELS, require(module))
	end
end
assert(#MODELS >= 1, "no treadmill models")

------------------------------------------------------------------
-- TIERS: every 3 levels the treadmill moves up a tier, and whatever its theme, every machine stands on its
-- tier's stage: a rim round the pad in the tier's finish, rank lights front and back (one more lights up each
-- level, all 3 at the top of a tier), and back-corner pieces that grow with the tier (low enough that the
-- camera behind the runner looks over them). Stage parts are all named "Tier...". The last machine alone is MAX.
------------------------------------------------------------------
TM.LEVELS_PER_TIER = 3
-- Motor = each tier's running sound under the footsteps: {SoundId, volume, playback speed}. All Pro Sound Effects
-- loops from the Roblox library, picked by their descriptions: Standard a conveyor belt with rattling rollers, Bronze a
-- train carriage's steady clack, Chrome a fluttering machine and compressor, Gold a deep ticking metallic hum, Prism a
-- slow pulsing synth tone, MAX a big pulsing synth rumble. Swap any of them here, or per machine with k.motor.
TM.TIERS = {
	{Name = "Standard", Rim = rgb(62, 66, 76), Mat = M.SmoothPlastic, Pip = rgb(120, 200, 255), Motor = {"rbxassetid://9112890083", 0.16, 1}},
	{Name = "Bronze", Rim = rgb(140, 84, 44), Mat = M.Metal, Pip = rgb(255, 150, 60), Inlay = rgb(215, 140, 75), Post = 0.6, Motor = {"rbxassetid://9113120822", 0.18, 1.1}},
	{Name = "Chrome", Rim = rgb(200, 206, 220), Mat = M.Metal, Refl = 0.3, Pip = rgb(90, 230, 255), Inlay = rgb(50, 56, 70), Line = rgb(90, 230, 255), Post = 1.2, Motor = {"rbxassetid://9112890980", 0.14, 1.25}},
	{Name = "Gold", Rim = rgb(36, 32, 30), Mat = M.Metal, Pip = rgb(255, 210, 80), Inlay = rgb(255, 200, 60), InlayMat = M.Foil, Line = rgb(255, 180, 50), Post = 1.8, Motor = {"rbxassetid://9125674129", 0.3, 1}},
	{Name = "Prism", Rim = rgb(236, 240, 250), Mat = M.Marble, Pip = "rainbow", Inlay = rgb(170, 220, 255), InlayMat = M.Glass, Line = rgb(190, 140, 255), Crystal = rgb(200, 235, 255), Motor = {"rbxassetid://9126084278", 0.22, 1.25}},
	{Name = "MAX", Rim = rgb(18, 12, 34), Mat = M.Glass, Pip = rgb(255, 205, 70), Inlay = rgb(255, 205, 70), InlayMat = M.Foil, Line = rgb(150, 80, 255), Crystal = rgb(255, 215, 120), Motor = {"rbxassetid://9119845261", 0.26, 1.1}},
}

function TM.tier(level)
	if level >= #MODELS - 1 then
		return TM.TIERS[#TM.TIERS]
	end
	return TM.TIERS[math.min(level // TM.LEVELS_PER_TIER + 1, #TM.TIERS - 1)]
end

-- how many rank lights are lit at `level` (1..3)
function TM.rank(level)
	return level % TM.LEVELS_PER_TIER + 1
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
			k.box((i - 2) * 1.1, 0.3, z, 0.7, 0.14, 0.24, lit and color or tier.Rim:Lerp(BLACK, 0.4), lit and M.Neon or M.SmoothPlastic, {name = "TierPip"})
		end
	end
	-- back corners: a post that grows with the tier, or a turning crystal at the top two tiers
	k.m(function(s)
		if tier.Crystal then
			local x, z = s * 4.35, 7.2
			k.box(x, 0.12, z, 0.7, 0.24, 0.7, tier.Inlay, tier.InlayMat, {name = "TierPost"})
			local shell = k.box(x, 1.25, z, 0.55, 2.0, 0.55, tier.Crystal, M.Glass, {t = 0.25, ry = 45, name = "TierCrystal"})
			local core = k.glow(x, 1.25, z, 0.22, 1.6, 0.22, tier.Line, {ry = 45, name = "TierCrystal"})
			k.anim("spin", {shell, core}, x, 1.25, z, {Axis = Vector3.yAxis, Speed = s * 0.8})
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
	-- the running sounds, silent until the main script fades them in for a runner: footsteps on the belt, quicker
	-- each level, over the machine's motor. Volume holds the level they fade up to.
	local deck = model:FindFirstChild("Deck") or slats[1]
	local motor = kit.Motor or TM.tier(level).Motor
	for _, def in ipairs({{"RunSteps", "rbxasset://sounds/action_footsteps_plastic.mp3", 0.45, 1 + 0.5 * level / (#MODELS - 1)}, {"RunMotor", motor[1], motor[2], motor[3]}}) do
		local s = Instance.new("Sound")
		s.Name, s.SoundId, s.Looped, s.Volume, s.PlaybackSpeed = def[1], def[2], true, 0, def[4]
		s:SetAttribute("Volume", def[3])
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance, s.RollOffMaxDistance = 10, 60
		s.Parent = deck
	end
	assert(#slats == TM.SLAT_COUNT, design.Name .. " has no belt")
	return slats, design
end

return TM

--[[
	EggForge (Studio edit-time only, used from the command bar / MCP; nothing requires it at runtime)
	Builds the 8 premium egg models into ReplicatedStorage.EggAssets with CSG, so every egg has a real hollow shell
	that splits along a zigzag seam when it hatches. Re-run after changing a design:
		require(game.ServerStorage.PetLab.Code.EggForge:Clone()).buildAll()

	Model contract (read by the hatch animator in PetsUI): PrimaryPart "Root" at the base centre, the egg standing on
	y = 0, widest at y = MID, seam at y = SEAM. Every part is anchored and has
	  Piece = "Top" | "Bottom" | "Free"  which shell half it moves with when the egg opens (Free = ornaments that stay)
	  Fx    = optional effect role: Glow (lights up), Crack (seam light, hidden until hatching), Core (light inside),
	          Orbit (circles the egg; attributes Axis, Speed), Float (bobs), Grow (vines), Twinkle, Rune
	  Order = optional sequence number for its Fx (cracks spread from the front, circuit traces light bottom to top)
]]
local GS = game:GetService("GeometryService")
local OPTS = {RenderFidelity = Enum.RenderFidelity.Precise, CollisionFidelity = Enum.CollisionFidelity.Box, SplitApart = false}

local F = {}
F.R, F.MID, F.BOT, F.TOP = 1.1, 1.25, 1.25, 1.55 -- horizontal radius, widest height, radius below and above it
F.SEAM, F.WALL, F.TEETH = 1.8, 0.1, 12
local R, MID, BOT, TOP, SEAM = F.R, F.MID, F.BOT, F.TOP, F.SEAM
local TAU, rad, sin, cos = math.pi * 2, math.rad, math.sin, math.cos
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = M.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

-- a solid egg: two half-ellipsoids (the top one taller) joined at MID; grow = studs added to every radius
local function solidEgg(grow, color, mat)
	local function half(ry, below)
		local ball = part({Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Color = color, Material = mat})
		local box = part({Size = Vector3.new(4, 2, 4), CFrame = CFrame.new(0, below and -1 or 1, 0), Color = color, Material = mat})
		local h = GS:IntersectAsync(ball, {box}, OPTS)[1]
		h.Size = Vector3.new(2 * (R + grow), ry + grow, 2 * (R + grow))
		h.CFrame = CFrame.new(0, MID, 0) -- a CSG half keeps its pivot at the flat face (the ball's centre)
		return h
	end
	local op = GS:UnionAsync(half(BOT, true), {half(TOP, false)}, OPTS)[1]
	op.Color, op.Material = color, mat
	return op
end

-- horizontal radius of the outer shell at height y
function F.radiusAt(y)
	local k = (y - MID) / (y < MID and BOT or TOP)
	return R * math.sqrt(math.max(0, 1 - k * k))
end

-- a point on the outer surface at angle th (0 = front, -Z) and height y, pushed out along the normal
function F.surf(th, y, out)
	local r = F.radiusAt(y)
	local p = Vector3.new(r * sin(th), y, -r * cos(th))
	local ry = y < MID and BOT or TOP
	local n = Vector3.new(p.X / (R * R), (y - MID) / (ry * ry), p.Z / (R * R)).Unit
	return p + n * (out or 0), n
end

-- the cutter above the seam: a block plus a ring of diamond teeth, so the seam zigzags
local function seamCutter(color)
	local block = part({Size = Vector3.new(6, 3, 6), CFrame = CFrame.new(0, SEAM + 1.5, 0), Color = color})
	local r = F.radiusAt(SEAM)
	local tw = TAU * r / (F.TEETH * math.sqrt(2))
	local teeth = {}
	for i = 0, F.TEETH - 1 do
		local th = i / F.TEETH * TAU
		teeth[i + 1] = part({Size = Vector3.new(tw, tw, 1), Color = color,
			CFrame = CFrame.new(0, SEAM, 0) * CFrame.Angles(0, -th, 0) * CFrame.new(0, 0, -r) * CFrame.Angles(0, 0, math.pi / 4)})
	end
	return GS:UnionAsync(block, teeth, OPTS)[1], tw / math.sqrt(2)
end

-- one egg being built
local Egg = {}
Egg.__index = Egg

function Egg:add(p, piece, fx, order)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p:SetAttribute("Piece", piece or (p.Position.Y > SEAM - 0.05 and "Top" or "Bottom"))
	if fx then
		p:SetAttribute("Fx", fx)
	end
	if order then
		p:SetAttribute("Order", order)
	end
	p.Parent = self.Model
	return p
end

-- split a part that crosses the seam into its top and bottom pieces
function Egg:split(op, fx)
	local top = GS:IntersectAsync(op, {self.Cutter}, OPTS)[1]
	local bottom = GS:SubtractAsync(op, {self.Cutter}, OPTS)[1]
	for _, p in ipairs({top, bottom}) do
		p.UsePartColor = true
		p.Color, p.Material, p.Transparency, p.Reflectance = op.Color, op.Material, op.Transparency, op.Reflectance
	end
	self:add(top, "Top", fx)
	self:add(bottom, "Bottom", fx)
	return top, bottom
end

-- the hollow shell (inside painted `inner`), cut along the seam, with the hidden seam cracks and a light inside
function Egg:shell(color, mat, inner, opts)
	opts = opts or {}
	local outer = solidEgg(0, color, mat)
	local hollow = GS:SubtractAsync(outer, {solidEgg(-F.WALL, inner, mat)}, OPTS)[1]
	local cutter, depth = seamCutter(inner)
	self.Cutter = cutter
	local top = GS:IntersectAsync(hollow, {cutter}, OPTS)[1]
	local bottom = GS:SubtractAsync(hollow, {cutter}, OPTS)[1]
	for _, p in ipairs({top, bottom}) do
		p.Transparency = opts.Transparency or 0
		p.Reflectance = opts.Reflectance or 0
		p.CastShadow = true
	end
	top.Name, bottom.Name = "ShellTop", "ShellBottom"
	self:add(top, "Top")
	self:add(bottom, "Bottom")
	-- the seam: one glowing segment per tooth edge, ordered by distance from the front
	local crack = opts.Crack or inner
	local half = math.pi / F.TEETH
	for i = 0, F.TEETH - 1 do
		local th = i / F.TEETH * TAU
		local pts = {{th - half, SEAM}, {th, SEAM - depth}, {th + half, SEAM}}
		for k = 1, 2 do
			local a = F.surf(pts[k][1], pts[k][2], 0.012)
			local b = F.surf(pts[k + 1][1], pts[k + 1][2], 0.012)
			local mid = (pts[k][1] + pts[k + 1][1]) / 2
			local d = math.abs((mid + math.pi) % TAU - math.pi)
			local s = self:rod(a, b, 0.06, crack, M.Neon, "Bottom", "Crack", d)
			s.Transparency = 1
		end
	end
	-- the light inside, seen when the shell opens (or through a see-through shell)
	local core = self:ell(Vector3.new(1.5, 1.9, 1.5), CFrame.new(0, MID + 0.15, 0), opts.CoreColor or inner, M.Neon, "Bottom", "Core")
	core.Transparency = opts.CoreTransparency or 0.35
	return top, bottom
end

-- a raised band hugging the shell between heights y1 and y2 (tilt = degrees about Z); split if it crosses the seam
function Egg:band(y1, y2, color, mat, opts)
	opts = opts or {}
	local grown = solidEgg(opts.Out or 0.04, color, mat)
	local slab = part({Size = Vector3.new(6, y2 - y1, 6), CFrame = CFrame.new(0, (y1 + y2) / 2, 0) * CFrame.Angles(0, 0, rad(opts.Tilt or 0)), Color = color, Material = mat})
	local op = GS:IntersectAsync(grown, {slab}, OPTS)[1]
	op.UsePartColor = true
	op.Color, op.Material = color, mat
	op.Transparency = opts.Transparency or 0
	op.Reflectance = opts.Reflectance or 0
	op.Name = opts.Name or "Band"
	if opts.Tilt then
		return self:split(op, opts.Fx)
	end
	return self:add(op, nil, opts.Fx)
end

-- a cap over the shell from height y up
function Egg:cap(y, color, mat, out)
	local grown = solidEgg(out or 0.05, color, mat)
	local block = part({Size = Vector3.new(6, 4, 6), CFrame = CFrame.new(0, y + 2, 0), Color = color, Material = mat})
	local op = GS:IntersectAsync(grown, {block}, OPTS)[1]
	op.UsePartColor = true
	op.Color, op.Material = color, mat
	op.Name = "Cap"
	return self:add(op, "Top")
end

-- an ellipsoid (a block with a sphere mesh stretches to any size)
function Egg:ell(size, cf, color, mat, piece, fx, order)
	local p = part({Name = fx or "Detail", Size = size, CFrame = cf, Color = color, Material = mat or M.SmoothPlastic})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return self:add(p, piece, fx, order)
end

function Egg:ball(d, pos, color, mat, piece, fx, order)
	return self:add(part({Name = fx or "Detail", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(pos), Color = color, Material = mat or M.SmoothPlastic}), piece, fx, order)
end

function Egg:block(size, cf, color, mat, piece, fx, order)
	return self:add(part({Name = fx or "Detail", Size = size, CFrame = cf, Color = color, Material = mat or M.SmoothPlastic}), piece, fx, order)
end

-- a disc lying flat against the surface (or with its face along `normal`)
function Egg:disc(d, thick, pos, normal, color, mat, piece, fx, order)
	local cf = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, math.pi / 2, 0)
	return self:add(part({Name = fx or "Detail", Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, d, d), CFrame = cf, Color = color, Material = mat or M.SmoothPlastic}), piece, fx, order)
end

-- a thin rod between two points, flat side toward the surface
function Egg:rod(a, b, thick, color, mat, piece, fx, order)
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local _, n = F.surf(math.atan2(mid.X, -mid.Z), math.clamp(mid.Y, 0.01, MID + TOP - 0.01))
	local y = (b - a).Unit
	local z = (n - y * n:Dot(y))
	z = z.Magnitude > 1e-3 and z.Unit or Vector3.new(0, 0, -1)
	local cf = CFrame.fromMatrix(mid, y:Cross(z), y, z)
	return self:add(part({Name = fx or "Detail", Size = Vector3.new(thick, len + thick * 0.6, thick * 0.7), CFrame = cf, Color = color, Material = mat or M.SmoothPlastic}), piece, fx, order)
end

-- a CFrame on the surface: -Z out of the shell, +Y along the surface rotated `spin` degrees from "up"
function F.flat(th, y, out, spin)
	local p, n = F.surf(th, y, out)
	local up = Vector3.yAxis - n * n.Y
	up = up.Magnitude > 1e-3 and up.Unit or Vector3.new(0, 0, 1)
	return CFrame.fromMatrix(p, up:Cross(n), up, n) * CFrame.Angles(0, 0, rad(spin or 0))
end

-- a faceted crystal (octagonal prism with a pyramid tip), base at cf, pointing along cf's +Y
local crystalProto = {}
function Egg:crystal(w, h, cf, color, mat, piece, fx, transparency)
	local key = tostring(color) .. tostring(mat)
	local proto = crystalProto[key]
	if not proto then
		local H, W = 2, 0.5
		local a = part({Size = Vector3.new(W, H, W), Color = color, Material = mat})
		local b = part({Size = Vector3.new(W, H, W), CFrame = CFrame.Angles(0, math.pi / 4, 0), Color = color, Material = mat})
		local L = (H + W) * 1.5
		local top = H / 2
		local ra = part({Size = Vector3.new(L, L, L), CFrame = CFrame.new(0, top - L / math.sqrt(2), 0) * CFrame.Angles(math.pi / 4, 0, 0), Color = color, Material = mat})
		local rb = part({Size = Vector3.new(L, L, L), CFrame = CFrame.new(0, top - L / math.sqrt(2), 0) * CFrame.Angles(0, 0, math.pi / 4), Color = color, Material = mat})
		proto = GS:IntersectAsync(a, {b, ra, rb}, OPTS)[1]
		proto.UsePartColor = true
		crystalProto[key] = proto
	end
	local c = proto:Clone()
	c.Name = fx or "Crystal"
	c.Color, c.Material = color, mat
	c.Transparency = transparency or 0
	c.Size = Vector3.new(w, h, w)
	c.CFrame = cf * CFrame.new(0, h / 2, 0)
	return self:add(c, piece, fx)
end

------------------------------------------------------------------
-- THE EIGHT EGGS (keys are PetData egg names)
------------------------------------------------------------------
local DESIGNS = {}

-- Ember: black basalt split by glowing magma veins, sitting in a ring of cooled lava rock
DESIGNS["Ember Egg"] = function(e, rng)
	local MAGMA, HOT = rgb(255, 105, 25), rgb(255, 170, 60)
	e:shell(rgb(46, 34, 32), M.Basalt, HOT, {Crack = rgb(255, 200, 90)})
	local function vein(th, y, steps, dir, w)
		local prev = F.surf(th, y, 0.01)
		for _ = 1, steps do
			y += dir * rng:NextNumber(0.15, 0.22)
			th += rng:NextNumber(-0.24, 0.24)
			if dir > 0 and y > SEAM - 0.3 and y < SEAM + 0.1 then break end
			local nxt = F.surf(th, y, 0.01)
			e:rod(prev, nxt, w, MAGMA, M.Neon, nil, "Glow", y)
			prev, w = nxt, math.max(0.045, w * 0.88)
			if rng:NextNumber() < 0.3 then
				local bth, by = th + rng:NextNumber(-0.5, 0.5), y + dir * 0.2
				e:rod(nxt, F.surf(bth, by, 0.01), w * 0.75, MAGMA, M.Neon, nil, "Glow", by)
				e:ball(w * 1.5, F.surf(th, y, 0.005), HOT, M.Neon, nil, "Glow", y)
			end
		end
	end
	for i = 0, 6 do
		vein(i / 7 * TAU + rng:NextNumber(-0.2, 0.2), 0.22, rng:NextInteger(5, 7), 1, 0.13)
	end
	for i = 0, 3 do
		vein(i / 4 * TAU + 0.4, SEAM + 0.12, 3, 1, 0.09)
	end
	-- cooled lava rocks around the base, with a few embers still glowing between them
	for i = 0, 6 do
		local th = i / 7 * TAU + rng:NextNumber(-0.2, 0.2)
		local r = 1.0 + rng:NextNumber(0, 0.15)
		local s = rng:NextNumber(0.34, 0.52)
		e:ell(Vector3.new(s * 1.2, s * 0.62, s), CFrame.new(r * sin(th), s * 0.2, -r * cos(th)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, TAU), rng:NextNumber(-0.3, 0.3)), rgb(38, 30, 29), M.Basalt, "Free")
		if i % 2 == 0 then
			e:ell(Vector3.new(0.2, 0.1, 0.16), CFrame.new((r + 0.05) * sin(th + 0.4), 0.05, -(r + 0.05) * cos(th + 0.4)), HOT, M.Neon, "Free", "Glow", 0)
		end
	end
end

-- Tide: an ocean-blue shell, deeper water at the base, a curling line of foam and a pearl on top
DESIGNS["Tide Egg"] = function(e, rng)
	e:shell(rgb(56, 140, 222), M.SmoothPlastic, rgb(170, 240, 255), {Reflectance = 0.04})
	e:band(0, 0.66, rgb(26, 74, 168), M.SmoothPlastic, {Out = 0.02, Name = "Depths"})
	local FOAM = rgb(240, 250, 255)
	for i = 0, 29 do
		local th = i / 30 * TAU
		local y = 0.7 + 0.08 * sin(th * 4)
		e:ball(0.17 + 0.07 * (0.5 + 0.5 * sin(th * 4)), F.surf(th, y, 0.02), FOAM)
		if i % 3 == 0 then
			e:ball(0.1, F.surf(th + 0.05, y + 0.17, 0.03), FOAM)
		end
	end
	-- the pearl in its gold setting
	local top = MID + TOP
	e:block(Vector3.new(0.14, 0.42, 0.42), CFrame.new(0, top - 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(240, 190, 80), M.Foil, "Top").Shape = Enum.PartType.Cylinder
	for i = 0, 4 do
		local th = i / 5 * TAU
		e:ell(Vector3.new(0.1, 0.22, 0.1), CFrame.new(0.2 * sin(th), top + 0.1, -0.2 * cos(th)) * CFrame.Angles(0, -th, 0) * CFrame.Angles(rad(-25), 0, 0), rgb(240, 190, 80), M.Foil, "Top")
	end
	e:ball(0.36, Vector3.new(0, top + 0.2, 0), rgb(248, 246, 255), M.SmoothPlastic, "Top", "Glow", 0).Reflectance = 0.06
	-- bubbles drifting up beside it
	for i, b in ipairs({{1.45, 1.5, 0.26}, {1.62, 2.1, 0.16}, {-1.5, 1.9, 0.2}}) do
		local p = e:ball(b[3], Vector3.new(b[1], b[2], -0.2), rgb(200, 240, 255), M.Glass, "Free", "Float", i)
		p.Transparency = 0.45
	end
end

-- Grove: living moss over bark roots, a flowering vine spiralling up and a sprout on top
DESIGNS["Grove Egg"] = function(e, rng)
	e:shell(rgb(98, 162, 70), M.Grass, rgb(225, 255, 170))
	e:band(0, 0.42, rgb(112, 80, 52), M.Wood, {Out = 0.03, Name = "Bark"})
	local BARK = rgb(98, 70, 46)
	for i = 0, 4 do
		local th = i / 5 * TAU + 0.3
		local a = F.surf(th, 0.3, 0.03)
		local b = Vector3.new(1.35 * sin(th + 0.15), 0.04, -1.35 * cos(th + 0.15))
		e:rod(a, b, 0.12, BARK, M.Wood, "Free")
	end
	-- the vine: stem segments with leaves on alternate sides, growing from the roots to the top
	local STEM = rgb(60, 118, 48)
	local LEAVES = {rgb(78, 188, 84), rgb(130, 214, 96)}
	local steps = 34
	local prev = F.surf(-0.6, 0.45, 0.02)
	for i = 1, steps do
		local k = i / steps
		local th = -0.6 + k * 2.2 * TAU
		local y = 0.45 + k * 2.15
		if y > SEAM - 0.22 and y < SEAM + 0.08 then
			prev = F.surf(th, y, 0.02)
			continue
		end
		local cur = F.surf(th, y, 0.02)
		e:rod(prev, cur, 0.055, STEM, M.SmoothPlastic, nil, "Grow", k)
		if i % 2 == 0 then
			local side = (i % 4 == 0) and 1 or -1
			e:ell(Vector3.new(0.2, 0.4, 0.05), F.flat(th, y, 0.05, 60 * side - 40), LEAVES[(i // 2) % 2 + 1], M.SmoothPlastic, nil, "Grow", k)
		end
		prev = cur
	end
	-- a flower on the front
	local fc = F.flat(0.55, 1.15, 0.04)
	for i = 0, 4 do
		e:ell(Vector3.new(0.17, 0.3, 0.05), fc * CFrame.Angles(0, 0, i / 5 * TAU) * CFrame.new(0, 0.14, 0), rgb(255, 150, 196), M.SmoothPlastic, "Bottom", "Grow", 0.3)
	end
	e:ball(0.13, (fc * CFrame.new(0, 0, -0.03)).Position, rgb(255, 214, 80), M.SmoothPlastic, "Bottom", "Grow", 0.3)
	-- the sprout
	local top = MID + TOP
	e:rod(Vector3.new(0, top - 0.05, 0), Vector3.new(0.05, top + 0.32, 0), 0.07, STEM, M.SmoothPlastic, "Top")
	for _, side in ipairs({-1, 1}) do
		e:ell(Vector3.new(0.26, 0.5, 0.06), CFrame.new(0.05 + side * 0.2, top + 0.4, 0) * CFrame.Angles(0, 0, rad(-side * 55)), LEAVES[2], M.SmoothPlastic, "Top")
	end
end

-- Frost: clear ice under a snow cap, icicles hanging from its rim, crystals growing round the base and on top
DESIGNS["Frost Egg"] = function(e, rng)
	local ICE, CRYSTAL = rgb(186, 226, 252), rgb(150, 215, 255)
	e:shell(ICE, M.Ice, rgb(225, 248, 255), {Crack = rgb(240, 252, 255)})
	e:cap(2.32, rgb(246, 250, 255), M.Snow, 0.06)
	for i = 0, 9 do
		local th = i / 10 * TAU + 0.15
		local p = F.surf(th, 2.3, 0.05)
		local len = rng:NextNumber(0.18, 0.34)
		e:crystal(0.09, len, CFrame.new(p) * CFrame.Angles(math.pi, 0, 0), rgb(210, 240, 255), M.Glass, "Top", nil, 0.1)
	end
	for i = 0, 6 do
		local th = i / 7 * TAU + rng:NextNumber(-0.15, 0.15)
		local r = 0.95 + rng:NextNumber(0, 0.12)
		local tilt = rng:NextNumber(18, 34)
		local h = rng:NextNumber(0.55, 1.0)
		e:crystal(h * 0.32, h, CFrame.new(r * sin(th), 0, -r * cos(th)) * CFrame.Angles(0, -th, 0) * CFrame.Angles(rad(-tilt), 0, 0), CRYSTAL, M.Glass, "Free", nil, 0.12)
	end
	local top = MID + TOP + 0.04
	e:crystal(0.2, 0.62, CFrame.new(0, top - 0.1, 0), CRYSTAL, M.Glass, "Top", "Glow", 0.08)
	for _, side in ipairs({-1, 1}) do
		e:crystal(0.14, 0.38, CFrame.new(side * 0.16, top - 0.14, 0.04) * CFrame.Angles(0, 0, rad(-side * 28)), CRYSTAL, M.Glass, "Top", nil, 0.08)
	end
	for _ = 1, 12 do
		local th, y = rng:NextNumber(0, TAU), rng:NextNumber(0.35, 2.2)
		if math.abs(y - SEAM + 0.1) > 0.18 then
			e:ball(0.06, F.surf(th, y, 0.01), rgb(255, 255, 255), M.Neon, nil, "Twinkle", rng:NextNumber())
		end
	end
end

-- Arcade: glossy grape candy shell with neon trim, a pixel invader on the front, a joystick on top, a coin in orbit
DESIGNS["Arcade Egg"] = function(e, rng)
	e:shell(rgb(112, 58, 205), M.SmoothPlastic, rgb(255, 130, 225), {Reflectance = 0.05, Crack = rgb(255, 255, 255)})
	e:band(0.46, 0.58, rgb(255, 70, 185), M.Neon, {Fx = "Glow", Name = "NeonPink"})
	e:band(0.64, 0.7, rgb(60, 230, 255), M.Neon, {Fx = "Glow", Name = "NeonCyan"})
	e:band(2.24, 2.32, rgb(60, 230, 255), M.Neon, {Fx = "Glow", Name = "NeonCyan"})
	local INVADER = {"0010100", "0111110", "1101011", "1111111", "1010101"}
	local px = 0.115
	for row, line in ipairs(INVADER) do
		for col = 1, #line do
			if line:sub(col, col) == "1" then
				local th = (col - 4) * px / F.radiusAt(1.25)
				local y = 1.48 - (row - 1) * px
				e:block(Vector3.new(px * 0.92, px * 0.92, 0.04), F.flat(th, y, 0.015), rgb(120, 255, 130), M.Neon, "Bottom", "Glow", rng:NextNumber())
			end
		end
	end
	local PIX = {rgb(255, 230, 80), rgb(60, 230, 255), rgb(255, 90, 170), rgb(255, 255, 255)}
	for _ = 1, 16 do
		local th, y = rng:NextNumber(0.9, TAU - 0.9), rng:NextNumber(0.85, 2.15)
		if math.abs(y - SEAM + 0.1) > 0.2 then
			e:block(Vector3.new(0.09, 0.09, 0.03), F.flat(th, y, 0.012), PIX[rng:NextInteger(1, #PIX)], M.Neon, nil, "Twinkle", rng:NextNumber())
		end
	end
	-- the joystick
	local top = MID + TOP
	local base = e:block(Vector3.new(0.1, 0.56, 0.56), CFrame.new(0, top - 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(30, 26, 40), M.SmoothPlastic, "Top")
	base.Shape = Enum.PartType.Cylinder
	local stick = e:block(Vector3.new(0.4, 0.08, 0.08), CFrame.new(0, top + 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), rgb(70, 66, 84), M.Metal, "Top")
	stick.Shape = Enum.PartType.Cylinder
	e:ball(0.32, Vector3.new(0, top + 0.44, 0), rgb(255, 50, 70), M.SmoothPlastic, "Top").Reflectance = 0.08
	-- a coin circling it
	local coin = e:disc(0.42, 0.07, Vector3.new(1.6, 1.75, 0), Vector3.new(0, 0, -1), rgb(255, 200, 60), M.Foil, "Free", "Orbit")
	coin:SetAttribute("Axis", Vector3.new(0.12, 1, 0).Unit)
	coin:SetAttribute("Speed", 1.4)
	local emboss = e:disc(0.26, 0.09, Vector3.new(1.6, 1.75, 0), Vector3.new(0, 0, -1), rgb(255, 225, 120), M.Foil, "Free", "Orbit")
	emboss:SetAttribute("Axis", Vector3.new(0.12, 1, 0).Unit)
	emboss:SetAttribute("Speed", 1.4)
end

-- Circuit: a gunmetal shell banded in chrome, cyan traces running up to a glowing core lens, an antenna on top
DESIGNS["Circuit Egg"] = function(e, rng)
	local CHROME, TRACE = rgb(176, 186, 200), rgb(70, 235, 255)
	e:shell(rgb(42, 50, 68), M.Metal, rgb(90, 240, 255), {Crack = rgb(180, 250, 255)})
	e:band(0, 0.16, rgb(28, 32, 42), M.DiamondPlate, {Out = 0.03, Name = "Base"})
	e:band(0.36, 0.5, CHROME, M.Metal, {Name = "Chrome", Reflectance = 0.1})
	e:band(2.3, 2.42, CHROME, M.Metal, {Name = "Chrome", Reflectance = 0.1})
	for i = 0, 11 do
		e:ball(0.07, F.surf(i / 12 * TAU, 0.43, 0.05), rgb(120, 128, 140), M.Metal)
	end
	-- the core lens
	local lp, ln = F.surf(0, 1.2, 0.03)
	e:disc(0.66, 0.1, lp, ln, CHROME, M.Metal, "Bottom")
	e:disc(0.46, 0.12, lp + ln * 0.01, ln, rgb(20, 24, 34), M.SmoothPlastic, "Bottom")
	e:disc(0.3, 0.14, lp + ln * 0.02, ln, TRACE, M.Neon, "Bottom", "Glow", 1.2)
	-- traces: up from the chrome band, a jog sideways, up again, ending in a node
	for i = 0, 9 do
		local th = i / 10 * TAU + 0.31
		local near = math.abs((th + math.pi) % TAU - math.pi) < 0.5
		local y = 0.52
		local prev = F.surf(th, y, 0.01)
		for k = 1, (near and 1 or 3) do
			local y2 = math.min(y + rng:NextNumber(0.25, 0.4), SEAM - 0.32)
			local up = F.surf(th, y2, 0.01)
			e:rod(prev, up, 0.05, TRACE, M.Neon, "Bottom", "Glow", y2)
			if k < 3 then
				local th2 = th + (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(0.14, 0.24)
				local side = F.surf(th2, y2, 0.01)
				e:rod(up, side, 0.05, TRACE, M.Neon, "Bottom", "Glow", y2 + 0.01)
				th, prev = th2, side
			else
				prev = up
			end
			y = y2
		end
		e:ball(0.11, prev, TRACE, M.Neon, "Bottom", "Glow", y + 0.02)
	end
	for i = 0, 5 do
		local th = i / 6 * TAU + 0.5
		local a = F.surf(th, 2.28, 0.01)
		local b = F.surf(th, SEAM + 0.14, 0.01)
		e:rod(a, b, 0.05, TRACE, M.Neon, "Top", "Glow", 2.3)
		e:ball(0.09, b, TRACE, M.Neon, "Top", "Glow", 2.3)
	end
	-- the antenna
	local top = MID + TOP
	e:rod(Vector3.new(0, top - 0.05, 0), Vector3.new(0, top + 0.42, 0), 0.06, CHROME, M.Metal, "Top")
	e:ball(0.14, Vector3.new(0, top + 0.46, 0), TRACE, M.Neon, "Top", "Glow", 2.6)
end

-- Phantom: a see-through violet shell with a soul glowing inside, tattered ghost hem, runes and a spirit flame
DESIGNS["Phantom Egg"] = function(e, rng)
	local VIOLET, RUNE = rgb(122, 72, 196), rgb(200, 150, 255)
	e:shell(VIOLET, M.SmoothPlastic, rgb(92, 52, 150), {Crack = rgb(220, 170, 255), CoreColor = rgb(176, 110, 255), CoreTransparency = 0.55})
	-- a faint glowing aura just off the shell: the ghostly sheen
	local aura = e:ell(Vector3.new(2.5, 3.05, 2.5), CFrame.new(0, 1.42, 0), rgb(190, 140, 255), M.Neon, "Bottom", "Aura")
	aura.Transparency = 0.86
	for i = 0, 7 do
		local th = i / 8 * TAU + 0.2
		local r = 0.8
		local p = e:ell(Vector3.new(0.26, 0.46, 0.22), CFrame.new(r * sin(th), 0.06, -r * cos(th)) * CFrame.Angles(0, -th, 0) * CFrame.Angles(rad(-18), 0, 0), rgb(150, 100, 220), M.SmoothPlastic, "Bottom")
		p.Transparency = 0.5
	end
	-- six runes round the middle: an open diamond with a light at its heart
	for i = 0, 5 do
		local th = i / 6 * TAU
		local function at(dx, dy)
			return F.surf(th + dx / F.radiusAt(1.2), 1.2 + dy, 0.012)
		end
		local pts = {at(0, 0.19), at(0.13, 0), at(0, -0.19), at(-0.13, 0)}
		for k = 1, 4 do
			e:rod(pts[k], pts[k % 4 + 1], 0.04, RUNE, M.Neon, "Bottom", "Rune", i)
		end
		e:ball(0.07, at(0, 0), rgb(255, 225, 255), M.Neon, "Bottom", "Rune", i)
	end
	-- the spirit flame
	local top = MID + TOP
	for k, f in ipairs({{0.5, 0.5, rgb(160, 80, 255)}, {0.34, 0.5, rgb(210, 130, 255)}, {0.18, 0.36, rgb(255, 200, 255)}}) do
		local p = e:ell(Vector3.new(f[1], f[2], f[1]), CFrame.new(0, top + 0.06 + (k - 1) * 0.27, 0), f[3], M.Neon, "Top", "Glow", k)
		p.Transparency = 0.15
	end
	-- wisps circling it
	for i, w in ipairs({{1.55, 1.0, Vector3.new(0.3, 1, 0)}, {1.65, 1.9, Vector3.new(-0.2, 1, 0.25)}, {1.5, 1.5, Vector3.new(0.1, 1, -0.3)}}) do
		for k = 0, 1 do
			local th = i * 2.1 - k * 0.22
			local p = e:ball(k == 0 and 0.17 or 0.1, Vector3.new(w[1] * sin(th), w[2], -w[1] * cos(th)), k == 0 and rgb(230, 200, 255) or rgb(170, 110, 255), M.Neon, "Free", "Orbit")
			p.Transparency = k * 0.3
			p:SetAttribute("Axis", w[3].Unit)
			p:SetAttribute("Speed", 0.9 + i * 0.15)
		end
	end
end

-- Celestial: a night-sky shell full of stars, a galaxy belt, gold filigree with a gem, a star crown, a ring and a moon
DESIGNS["Celestial Egg"] = function(e, rng)
	local GOLD = rgb(240, 192, 84)
	e:shell(rgb(24, 22, 70), M.SmoothPlastic, rgb(255, 232, 170), {Crack = rgb(255, 245, 210)})
	e:band(1.0, 1.55, rgb(104, 82, 214), M.Neon, {Tilt = 22, Out = 0.015, Transparency = 0.62, Name = "Galaxy"})
	e:band(0.5, 0.62, GOLD, M.Foil, {Name = "Gold"})
	e:band(0.69, 0.72, GOLD, M.Foil, {Name = "Gold"})
	e:band(2.28, 2.38, GOLD, M.Foil, {Name = "Gold"})
	local STARS = {rgb(255, 255, 255), rgb(255, 236, 170), rgb(255, 170, 230), rgb(170, 210, 255)}
	for _ = 1, 40 do
		local th, y = rng:NextNumber(0, TAU), rng:NextNumber(0.55, 2.65)
		if math.abs(y - SEAM + 0.1) > 0.16 and math.abs(y - 2.33) > 0.1 and math.abs(y - 0.6) > 0.14 then
			e:ball(rng:NextNumber(0.04, 0.1), F.surf(th, y, 0.01), STARS[rng:NextInteger(1, #STARS)], M.Neon, nil, "Twinkle", rng:NextNumber())
		end
	end
	-- the gem on the gold band, set between two little ones
	for k, g in ipairs({{0, 0.22, 0.26}, {-0.34, 0.13, 0.16}, {0.34, 0.13, 0.16}}) do
		-- pointing out of the shell, half sunk into the band
		local cf = F.flat(g[1], 0.56, 0.02) * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, -g[3] * 0.45, 0)
		e:crystal(g[2], g[3], cf, k == 1 and rgb(120, 220, 255) or rgb(255, 120, 200), M.Glass, "Bottom", "Glow", 0.05)
	end
	-- the star crown
	local top = MID + TOP
	local sc = CFrame.new(0, top + 0.36, 0)
	for i = 0, 4 do
		e:ell(Vector3.new(0.13, 0.46, 0.08), sc * CFrame.Angles(0, 0, i / 5 * TAU) * CFrame.new(0, 0.2, 0), rgb(255, 222, 130), M.Neon, "Top", "Glow", 3)
	end
	e:ball(0.2, sc.Position, rgb(255, 250, 225), M.Neon, "Top", "Glow", 3)
	e:rod(Vector3.new(0, top - 0.04, 0), Vector3.new(0, top + 0.2, 0), 0.06, GOLD, M.Foil, "Top")
	-- a tilted ring of stardust and a moon, both circling
	local ringAxis = Vector3.new(0.38, 1, 0.12).Unit
	local ringCF = CFrame.new(0, MID + 0.1, 0) * CFrame.fromAxisAngle(Vector3.yAxis:Cross(ringAxis).Unit, math.acos(ringAxis.Y))
	for i = 0, 33 do
		local th = i / 34 * TAU
		local p = e:ball(i % 3 == 0 and 0.09 or 0.06, (ringCF * CFrame.new(1.72 * sin(th), 0, -1.72 * cos(th))).Position, i % 3 == 0 and rgb(255, 236, 170) or rgb(220, 225, 255), M.Neon, "Free", "Orbit")
		p:SetAttribute("Axis", ringAxis)
		p:SetAttribute("Speed", 0.35)
	end
	local moon = e:ball(0.3, Vector3.new(-1.95, 2.05, 0.3), rgb(205, 205, 232), M.SmoothPlastic, "Free", "Orbit")
	moon:SetAttribute("Axis", Vector3.new(-0.25, 1, 0.3).Unit)
	moon:SetAttribute("Speed", 0.6)
end

-- builds one egg model (unparented)
function F.build(name)
	local model = Instance.new("Model")
	model.Name = name
	local root = part({Name = "Root", Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1})
	root.Parent = model
	model.PrimaryPart = root
	local e = setmetatable({Model = model}, Egg)
	local seed = 0
	for i = 1, #name do
		seed = (seed * 31 + name:byte(i)) % 1000003
	end
	DESIGNS[name](e, Random.new(seed))
	if e.Cutter then
		e.Cutter:Destroy()
	end
	model:SetAttribute("Mid", MID)
	model:SetAttribute("Seam", SEAM)
	return model
end

-- rebuilds every egg in PetData into ReplicatedStorage.EggAssets
function F.buildAll()
	local RS = game:GetService("ReplicatedStorage")
	local PetData = require(RS.PetData:Clone())
	local folder = RS:FindFirstChild("EggAssets") or Instance.new("Folder")
	folder.Name = "EggAssets"
	local built = {}
	for _, egg in ipairs(PetData.EGGS) do
		if DESIGNS[egg.Name] then
			local old = folder:FindFirstChild(egg.Name)
			if old then
				old:Destroy()
			end
			local m = F.build(egg.Name)
			m.Parent = folder
			table.insert(built, egg.Name .. " (" .. #m:GetChildren() .. " parts)")
			task.wait()
		end
	end
	folder.Parent = RS
	return built
end

return F

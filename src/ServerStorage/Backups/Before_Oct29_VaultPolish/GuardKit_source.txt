--[[
	GuardKit: how every shopkeeper moves and sounds. Shared by GuardMotion (draws them on each player's screen), the
	unit tests and the Studio pose viewer (ServerStorage.GuardLab), so what is tested is exactly what players see.

	RIG. Six Motor6Ds made by GuardLab.GuardRigKit: Root (pelvis), Neck, LeftShoulder, RightShoulder, LeftHip,
	RightHip. The Root pivots at the hip line, so a lean bends the body over the legs.

	POSES. A pose is joint key -> Vector3 of angles in radians (X pitch, Y yaw, Z roll) plus:
	  Off   root offset in body studs (times the guard's scale). Y is AIR only (a hop, a float): it never pushes down.
	  Free  0 = planted (the default): legs keep the angles written for them whatever the body does, so leaning,
	        laughing or rolling never swings the feet through the floor. 1 = the legs follow the body (a somersault,
	        a pirouette, flying).
	Signs: -X on Root leans forward, +X on a hip or shoulder swings that limb forward, on the left shoulder -Z lifts
	the arm out to the side (+Z on the right). Positive Root Z leans to the guard's left.

	SOLVER (K.solve). Turns a pose into joint transforms: clamps every limb to its safe range (no arm swinging into
	the chest, no leg through the hips), keeps planted legs where they were written, then raises or lowers the body
	so its lowest point - a heel, a toe, or the hem of a robe - sits exactly on the floor (plus any air).

	MOTION[key] = {Stride, Foot, Gait, Idle, Grab, Laugh}. Stride = studs per full cycle (two footfalls) at
	scale 1; Foot = phase of the first footfall. Gait(p, phase, s) with s.Run (1 chasing, ~0.6 walking home) and s.T;
	Idle(p, t); Grab(p, age) is the 0.3 s lunge that decides a catch; Laugh(p, age) plays after a catch (~1.9 s).

	AUDIO[key] = the guard's own running sound: two footfall sounds (left, right), pitch, volume, an optional layer
	(armour clank, squeak, servo...) every N steps, or a Loop for the ones that float.
]]

local K = {}

local V = Vector3.new
local ZERO = Vector3.zero
local sin, cos, abs, pi, clamp, max, min, floor = math.sin, math.cos, math.abs, math.pi, math.clamp, math.max, math.min, math.floor

K.KEYS = {"Root", "Neck", "LS", "RS", "LH", "RH"}
K.JOINTS = {Root = "Root", Neck = "Neck", LS = "LeftShoulder", RS = "RightShoulder", LH = "LeftHip", RH = "RightHip"}
K.GRAB_TIME = 0.3 -- keep in step with Config.GUARD_GRAB_TIME

-- safe ranges (min, max) for each limb
K.LIMITS = {
	Neck = {V(-0.6, -1.1, -0.45), V(0.8, 1.1, 0.45)},
	LS = {V(-1.4, -0.9, -2.7), V(3.0, 0.9, 0.22)},
	RS = {V(-1.4, -0.9, -0.22), V(3.0, 0.9, 2.7)},
	LH = {V(-1.0, -0.5, -0.7), V(1.3, 0.5, 0.2)},
	RH = {V(-1.0, -0.5, -0.2), V(1.3, 0.5, 0.7)},
}

local function clampv(v, lim)
	return V(clamp(v.X, lim[1].X, lim[2].X), clamp(v.Y, lim[1].Y, lim[2].Y), clamp(v.Z, lim[1].Z, lim[2].Z))
end
local function euler(v)
	return CFrame.fromEulerAnglesXYZ(v.X, v.Y, v.Z)
end

function K.newPose()
	return {Root = ZERO, Neck = ZERO, LS = ZERO, RS = ZERO, LH = ZERO, RH = ZERO, Off = ZERO, Free = 0}
end

-- a = a blended toward b by w (in place)
function K.blend(a, b, w)
	for _, k in ipairs(K.KEYS) do
		a[k] = a[k]:Lerp(b[k], w)
	end
	a.Off = a.Off:Lerp(b.Off, w)
	a.Free = a.Free + (b.Free - a.Free) * w
end

------------------------------------------------------------------
-- RIG + SOLVER
------------------------------------------------------------------
-- Reads a rigged guard (at any scale). Returns nil until all six joints are there.
function K.measure(model)
	local J = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			for key, name in pairs(K.JOINTS) do
				if d.Name == name then
					J[key] = d
				end
			end
		end
	end
	for _, key in ipairs(K.KEYS) do
		if not J[key] or not J[key].Part0 or not J[key].Part1 then
			return nil
		end
	end
	local rig = {J = J, C0 = {}, C1i = {}, Scale = model:GetAttribute("Scale") or 1}
	for key, j in pairs(J) do
		rig.C0[key] = j.C0
		rig.C1i[key] = j.C1:Inverse()
	end
	-- the points that can touch the floor: each foot's heel, middle and toe, and the hem of the torso (robes, gowns)
	rig.Feet = {}
	for _, key in ipairs({"LH", "RH"}) do
		local s = J[key].Part1.Size
		rig.Feet[key] = {V(0, -s.Y / 2, 0), V(0, -s.Y / 2, -s.Z * 0.35), V(0, -s.Y / 2, s.Z * 0.35)}
	end
	local ts = J.Root.Part1.Size
	rig.Hem = {V(0, -ts.Y / 2, 0), V(0, -ts.Y / 2, -ts.Z * 0.35), V(0, -ts.Y / 2, ts.Z * 0.35), V(ts.X * 0.35, -ts.Y / 2, 0), V(-ts.X * 0.35, -ts.Y / 2, 0)}
	rig.Rest = K.lowest(rig, CFrame.identity, {LH = CFrame.identity, RH = CFrame.identity})
	rig.RestFeet = K.feet(rig, CFrame.identity, {LH = CFrame.identity, RH = CFrame.identity})
	return rig
end

-- the lowest point of the body (in root space) for a body rotation and the two hip transforms
function K.lowest(rig, R, hips)
	local torso = rig.C0.Root * R * rig.C1i.Root
	local low = math.huge
	for _, key in ipairs({"LH", "RH"}) do
		local leg = torso * rig.C0[key] * hips[key] * rig.C1i[key]
		for _, pt in ipairs(rig.Feet[key]) do
			low = min(low, (leg * pt).Y)
		end
	end
	for _, pt in ipairs(rig.Hem) do
		low = min(low, (torso * pt).Y)
	end
	return low
end

-- where the middle of each foot is (in root space)
function K.feet(rig, R, hips)
	local torso = rig.C0.Root * R * rig.C1i.Root
	local f = {}
	for _, key in ipairs({"LH", "RH"}) do
		f[key] = (torso * rig.C0[key] * hips[key] * rig.C1i[key]) * rig.Feet[key][1]
	end
	return f
end

-- pose -> {key = Transform}; also returns the lift used (how far the body was raised to keep the feet down)
function K.solve(rig, p, out)
	out = out or {}
	local R = euler(p.Root)
	local plant = 1 - clamp(p.Free or 0, 0, 1)
	local counter = CFrame.identity:Lerp(R:Inverse(), plant)
	local hips = {}
	for _, key in ipairs({"LH", "RH"}) do
		hips[key] = counter * euler(clampv(p[key], K.LIMITS[key]))
	end
	local lift = rig.Rest - K.lowest(rig, R, hips)
	-- foot lock: a planted body moves over its feet, so the point between them stays where it was
	local f = K.feet(rig, R, hips)
	local drift = ((f.LH - rig.RestFeet.LH) + (f.RH - rig.RestFeet.RH)) / 2 * plant
	local s = rig.Scale
	out.Root = CFrame.new(p.Off.X * s - drift.X, lift + max(p.Off.Y, 0) * s, p.Off.Z * s - drift.Z) * R
	out.LH, out.RH = hips.LH, hips.RH
	out.Neck = euler(clampv(p.Neck, K.LIMITS.Neck))
	out.LS = euler(clampv(p.LS, K.LIMITS.LS))
	out.RS = euler(clampv(p.RS, K.LIMITS.RS))
	return out, lift
end

------------------------------------------------------------------
-- MOTION HELPERS
------------------------------------------------------------------
local function ease(x)
	x = clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
K.ease = ease
-- a smooth 0 -> 1 -> 0 bump lasting dur, once every period
local function pulse(t, period, dur)
	local x = (t % period) / dur
	if x >= 1 then
		return 0
	end
	return sin(x * pi)
end
local function legs(p, ph, amp, spread)
	local a = sin(ph)
	p.LH = V(amp * a, 0, -(spread or 0))
	p.RH = V(-amp * a, 0, spread or 0)
end
local function swing(p, ph, amp, out, fwd)
	local a = sin(ph)
	p.LS = V((fwd or 0) - amp * a, 0, -(out or 0.1))
	p.RS = V((fwd or 0) + amp * a, 0, out or 0.1)
end
local function arms(p, l, r)
	p.LS, p.RS = l, r
end
local function sides(p, out, fwd)
	p.LS = V(fwd or 0.05, 0, -(out or 0.12))
	p.RS = V(fwd or 0.05, 0, out or 0.12)
end
-- chest rising and falling (a small backward tilt of the body over planted legs) with the shoulders
local function breathe(p, t, amp, rate)
	amp, rate = amp or 1, rate or 1.4
	local b = sin(t * rate)
	p.Root += V(0.022 * amp * b, 0, 0)
	p.LS += V(0, 0, -0.03 * amp * b)
	p.RS += V(0, 0, 0.03 * amp * b)
	p.Neck += V(-0.015 * amp * b, 0, 0)
end
-- slow weight shift from one foot to the other
local function shift(p, t, period, amt)
	p.Root += V(0, 0, (amt or 0.035) * sin(t * 2 * pi / (period or 7)))
end
-- a slow look along the hall
local function scan(p, t, amt, period)
	p.Neck += V(0, (amt or 0.35) * sin(t * 2 * pi / (period or 10)), 0)
end
-- running bob: highest as the legs pass each other
local function air(ph, h)
	return V(0, h * cos(ph) ^ 2, 0)
end

-- a lunge-and-grab over GRAB_TIME: a short wind-up, then both hands reach for you
local function grab(p, a, o)
	o = o or {}
	local wind = ease(a / 0.08) * (1 - ease((a - 0.08) / 0.12))
	local k = ease((a - 0.05) / (o.Speed or 0.2))
	-- the thief is a quarter of the giant's height: the body leans in and the hands go forward and DOWN to them.
	-- Reach sets the arms' angle in the world (Reach 1.5 = 43 degrees below level); the lean already tips the arms
	-- forward, so it comes off their own angle
	local lean = (o.Lean or 0.3) + 0.12
	local r = math.max(0.15, (o.Reach or 1.5) * 0.5 - lean)
	local out = o.Out or 0.25
	arms(p, V(r * k - 0.45 * wind, 0, -out), V(r * k - 0.45 * wind, 0, out))
	p.Root = V(0.1 * wind - lean * k, (o.Yaw or 0) * k, 0)
	local st = o.Stance or 0.45
	p.LH = V(st * k, 0, -0.05)
	p.RH = V(-st * 0.7 * k, 0, 0.05)
	p.Neck = V((o.Head or 0.18) * k, 0, 0)
	return k
end

-- the laugh: settles in, shakes, and eases back out by ~1.9 s (so the guard recovers into its idle)
local function laughIn(a)
	return ease(a / 0.3) * (1 - ease((a - 1.55) / 0.4))
end
local function laugh(p, a, o)
	o = o or {}
	local inn = laughIn(a)
	local k = sin(a * (o.Rate or 14))
	p.Root = V(((o.Back or 0.15) + (o.Shake or 0.04) * k) * inn, 0, 0)
	p.Neck = V(((o.Head or 0.35) + (o.Shake or 0.04) * 1.5 * k) * inn, 0, 0)
	return inn, k
end

------------------------------------------------------------------
-- EVERY GUARD
------------------------------------------------------------------
local M = {}
K.MOTION = M

-- 1 Brutus: a heavy, confident security chief. Rolls his shoulders as he runs; hands on his belt at rest, a slow
-- look along the shop; grabs like a bouncer; a deep belly laugh, rocking back on his heels.
M.brutus = {Stride = 5.2,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.55 * r, 0.06)
		swing(p, ph, 0.38 * r, 0.3)
		p.Root = V(-0.06 - 0.1 * r, 0.12 * sin(ph) * r, 0)
		p.Neck = V(0.08 * r, -0.08 * sin(ph) * r, 0)
		p.Off = air(ph, 0.08 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.07), V(0, 0, 0.07)
		local f = pulse(t, 11, 1.6) -- cracks his knuckles now and then
		arms(p, V(0.12 + 0.55 * f, 0.2 * f, -0.2 + 0.05 * f), V(0.12 + 0.55 * f, -0.2 * f, 0.2 - 0.05 * f))
		breathe(p, t, 1.2)
		shift(p, t, 8, 0.03)
		scan(p, t, 0.3, 12)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.45, Lean = 0.25, Stance = 0.4})
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.2, Shake = 0.045, Rate = 12, Head = 0.42})
		arms(p, V(0.5 * inn + 0.04 * k, 0.3 * inn, -0.12), V(0.5 * inn - 0.04 * k, -0.3 * inn, 0.12))
		p.LH, p.RH = V(0, 0, -0.07), V(0, 0, 0.07)
	end}

-- 2 Tusk: a barrel-bodied warthog. Short fast legs, head down like a battering ram. At rest he weighs coins in one
-- hand and snorts; the grab is a head-down shove; the laugh is a snorting chuckle.
M.tusk = {Stride = 3.4,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.6 * r, 0.08)
		swing(p, ph, 0.45 * r, 0.22)
		p.Root = V(-0.06 - 0.24 * r, 0, 0.06 * sin(ph) * r)
		p.Neck = V(-0.12 * r, 0, 0)
		p.Off = air(ph, 0.1 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.08), V(0, 0, 0.08)
		sides(p, 0.22, 0.1)
		p.RS = V(0.7 + 0.06 * abs(sin(t * 2.2)), 0.3, 0.12)
		breathe(p, t, 1.5, 1.7)
		local snort = pulse(t, 6.5, 0.45)
		p.Neck += V(-0.18 - 0.12 * snort, 0.25 * sin(t * 0.6), 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.2, Lean = 0.35, Stance = 0.5, Head = -0.15})
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.12, Shake = 0.07, Rate = 18, Head = 0.25})
		sides(p, 0.28, 0.25 * inn)
		p.LH, p.RH = V(0, 0, -0.08), V(0, 0, 0.08)
	end}

-- 3 Kong: a silverback. Long arms reach forward in turn as he runs, hunched over; at rest he breathes slowly and
-- watches; the grab sweeps both arms in from wide; the laugh is a chest-pounding roar.
M.kong = {Stride = 6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.45 * r, 0.15)
		local a = sin(ph)
		arms(p, V(0.35 - 0.85 * a * r, 0, -0.3), V(0.35 + 0.85 * a * r, 0, 0.3))
		p.Root = V(-0.08 - 0.34 * r, 0.14 * a * r, 0.05 * a * r)
		p.Neck = V(0.3 * r, 0, 0)
		p.Off = air(ph, 0.15 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.14), V(0, 0, 0.14)
		p.Root = V(-0.16, 0, 0)
		arms(p, V(0.22, 0, -0.22), V(0.22, 0, 0.22))
		p.Neck = V(0.14, 0, 0)
		breathe(p, t, 1.7, 1.0)
		scan(p, t, 0.5, 13)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.55, Lean = 0.38, Stance = 0.45})
		local wide = 0.9 * (1 - k) + 0.2
		p.LS = V(p.LS.X, 0, -wide)
		p.RS = V(p.RS.X, 0, wide)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local b = sin(a * 10)
		arms(p, V((1.2 + 0.3 * b) * inn, 0.6 * inn, -0.12), V((1.2 - 0.3 * b) * inn, -0.6 * inn, 0.12))
		p.Root = V(0.18 * inn, 0, 0)
		p.Neck = V(0.5 * inn, 0, 0)
		p.LH, p.RH = V(0, 0, -0.14), V(0, 0, 0.14)
	end}

-- 4 Static: a jackal DJ who moves to his own beat. A bouncy, grooving run; nods along to his headphones at rest; a
-- quick swipe of a grab; throws his head back to cackle.
M.static = {Stride = 4.4,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.65 * r, 0)
		swing(p, ph, 0.5 * r, 0.15)
		p.Root = V(-0.12 * r, 0.15 * sin(ph) * r, 0.08 * sin(ph) * r)
		p.Neck = V(0.08 * abs(sin(ph * 2)), 0, 0)
		p.Off = air(ph, 0.2 * r)
	end,
	Idle = function(p, t)
		local beat = max(0, sin(t * 4.2))
		p.Neck = V(0.1 * beat, 0.15 * sin(t * 0.5), 0)
		p.Root = V(0, 0, 0.05 * sin(t * 2.1))
		sides(p, 0.15, 0.08)
		local cans = pulse(t, 9, 2.4)
		p.RS = V(0.08 + 1.9 * cans, 0, 0.15 + 0.5 * cans)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.3, Lean = 0.3, Yaw = 0.3})
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.1, Shake = 0.05, Rate = 20, Head = 0.55})
		p.RS = V(1.9 * inn, 0, 0.5 * inn)
		p.LS = V(0.1, 0, -0.25 * inn - 0.1)
	end}

-- 5 Sergeant Tin: a wind-up toy soldier. Everything moves in crisp, ratcheting toy steps: a straight-legged march,
-- arms swinging stiffly at his sides. At rest he stands to attention, head clicking round, and presents arms now and
-- then. Grabs with both stiff arms; laughs in mechanical hops ("ha. ha. ha.").
local function ratchet(x, steps)
	-- moves like a toy mechanism: quick snaps between held positions
	local s = x * steps
	local i = floor(s)
	return (i + ease((s - i) / 0.35)) / steps
end
M.tin = {Stride = 3.8,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V((0.75 * max(0, a) - 0.1 * max(0, -a)) * r, 0, 0)
		p.RH = V((0.75 * max(0, -a) - 0.1 * max(0, a)) * r, 0, 0)
		p.LS = V(-0.55 * a * r, 0, -0.06)
		p.RS = V(0.55 * a * r, 0, 0.06)
		p.Neck = V(0.04, 0, 0)
		p.Off = V(0, 0.05 * abs(a) * r, 0)
	end,
	Idle = function(p, t)
		p.LS, p.RS = V(0, 0, -0.05), V(0, 0, 0.05)
		-- the head clicks between three positions
		local look = ratchet((t / 3) % 3, 1)
		local head = ({0, 0.32, -0.32})[floor((t / 3) % 3) + 1]
		p.Neck = V(0, head * ease(look % 1 / 0.2), 0)
		-- the clockwork ticks
		p.Root = V(0.012 * pulse(t, 1, 0.15), 0, 0)
		-- presents arms: a crisp move of the right arm across the body, held, and back
		local pr = pulse(t, 10, 2.2)
		p.RS = V(0.05 + 1.0 * clamp(pr * 1.6, 0, 1), -0.25 * clamp(pr * 1.6, 0, 1), 0.05)
	end,
	Grab = function(p, a)
		local k = ratchet(clamp((a - 0.05) / 0.22, 0, 1), 2)
		arms(p, V(0.45 * k, 0, -0.08), V(0.45 * k, 0, 0.08))
		p.Root = V(-0.3 * k, 0, 0)
		p.LH, p.RH = V(0.35 * k, 0, 0), V(-0.2 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local hop = ease((a * 3 % 1) / 0.25) * (1 - ease((a * 3 % 1 - 0.5) / 0.25))
		p.Root = V(0.1 * inn, 0, 0)
		p.Neck = V((0.18 + 0.1 * hop) * inn, 0, 0.1 * ratchet((a * 1.5) % 1, 2) * inn)
		p.Off = V(0, 0.12 * hop * inn, 0)
		p.LS, p.RS = V(0, 0, -0.05 - 0.15 * hop * inn), V(0, 0, 0.05 + 0.15 * hop * inn)
	end}

-- 6 Stitches: a patched plush bear who bounces after you on both feet as if still on his toy spring. At rest he
-- sags and sways, lopsided; the grab is a big bear hug; the laugh is a bouncy giggle.
M.stitches = {Stride = 5.5, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local h = abs(sin(ph))
		p.LH, p.RH = V(-0.1 + 0.3 * (1 - h), 0, -0.06), V(-0.1 + 0.3 * (1 - h), 0, 0.06)
		arms(p, V(0.4 * h, 0, -0.8 - 0.3 * h), V(0.4 * h, 0, 0.8 + 0.3 * h))
		p.Neck = V(0, 0, 0.22 * sin(ph * 0.5))
		p.Root = V(-0.08 * r, 0, 0)
		p.Off = V(0, 1.5 * h ^ 0.7 * r, 0)
	end,
	Idle = function(p, t)
		p.Root = V(-0.04, 0, 0.05 * sin(t * 0.9))
		p.Neck = V(0.05, 0.12 * sin(t * 0.4), 0.18 + 0.05 * sin(t * 0.9 + 1))
		arms(p, V(0.06 * sin(t * 0.9 - 0.6), 0, -0.2), V(0.06 * sin(t * 0.9 - 0.3), 0, 0.2))
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.25, Lean = 0.2, Stance = 0.3})
		local wide = 1.2 * (1 - k) + 0.15
		p.LS = V(p.LS.X, 0, -wide)
		p.RS = V(p.RS.X, 0, wide)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local hop = abs(sin(a * 9))
		p.Off = V(0, 0.35 * hop * inn, 0)
		p.Neck = V(0.25 * inn, 0, 0.25 * sin(a * 4.5) * inn)
		arms(p, V(0.3 * inn, 0, -0.5 * inn - 0.15), V(0.3 * inn, 0, 0.5 * inn + 0.15))
	end}

-- 7 Captain Calico: a cursed pirate captain on a peg leg. A lurching run (the peg leg barely bends), cutlass ready;
-- at rest he peers through his spyglass hand; grabs cutlass-high; laughs with the blade in the air.
M.calico = {Stride = 4.6,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V(0.7 * a * r, 0, 0)
		p.RH = V(-0.35 * a * r, 0, 0.08)
		p.LS = V(-0.45 * a * r, 0, -0.2)
		p.RS = V(1.1, 0, 0.2)
		p.Root = V(-0.1 * r, 0, 0.17 * a * r)
		p.Off = V(0, 0.22 * max(0, -a) * r, 0)
	end,
	Idle = function(p, t)
		local glass = pulse(t, 12, 4.5)
		p.LS = V(0.1 + 1.45 * clamp(glass * 1.5, 0, 1), 0.2 * glass, -0.12)
		p.RS = V(0.25, -0.2, 0.15)
		p.Neck = V(0.04, 0.45 * sin(t * 0.5) * glass, 0)
		breathe(p, t)
		shift(p, t, 6, 0.04)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.4, Lean = 0.25})
		p.RS = V(1.9, 0, 0.2)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.18, Shake = 0.05, Rate = 11, Head = 0.45})
		p.RS = V(0.25 + 2.5 * inn, 0, 0.2)
		p.LS = V(0.4 * inn, 0, -0.3)
	end}

-- 8 Brineback: a hammerhead first mate on wide sea legs, rolling as if the deck moves under him. Arms on hips at rest;
-- a two-handed haul of a grab; slaps his knee laughing.
M.brine = {Stride = 4.8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.45 * r, 0.22)
		swing(p, ph, 0.25 * r, 0.45)
		p.Root = V(-0.08 * r, 0, 0.18 * sin(ph) * r)
		p.Off = air(ph, 0.08 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.2), V(0, 0, 0.2)
		p.Root = V(0.02 * sin(t * 0.8 + 1), 0, 0.06 * sin(t * 0.8))
		arms(p, V(0.15, 0.1, -0.45), V(0.15, -0.1, 0.45))
		p.Neck = V(0, 0.3 * sin(t * 0.35), -0.05 * sin(t * 0.8))
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.3, Out = 0.35})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V(-0.15 * inn, 0, 0)
		p.Neck = V(0.5 * inn, 0, 0)
		p.RS = V((0.5 + 0.35 * max(0, sin(a * 12))) * inn, 0, 0.25)
		p.LS = V(0.4 * inn, 0, -0.35)
		p.LH, p.RH = V(0, 0, -0.2), V(0, 0, 0.2)
	end}

-- 9 Mortimer: a giggling skeleton who tiptoes after thieves, lantern held out. At rest the lantern sways as he peers
-- about, head cocked; a bony snatch; a rattling giggle.
M.mortimer = {Stride = 4.2,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V((1.0 * max(0, a) - 0.1) * r, 0, 0)
		p.RH = V((1.0 * max(0, -a) - 0.1) * r, 0, 0)
		arms(p, V(0.9 + 0.15 * a, 0, -0.2), V(0.9 - 0.15 * a, 0, 0.2))
		p.Root = V(-0.28 * r, 0, 0)
		p.Neck = V(0.22 * r, 0, 0)
		p.Off = V(0, 0.22 * abs(a) * r, 0)
	end,
	Idle = function(p, t)
		p.LS = V(1.3, 0, -0.15 + 0.05 * sin(t * 1.3))
		p.RS = V(0.1, 0, 0.15)
		p.Root = V(-0.12, 0, 0)
		p.Neck = V(0.12, 0.5 * sin(t * 2 * pi / 7), 0.12)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.35, Out = 0.15})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 26)
		p.Root = V((0.08 + 0.03 * k) * inn, 0, 0)
		p.Neck = V((0.35 + 0.06 * k) * inn, 0, 0.1 * inn)
		arms(p, V(0.3, 0, -0.15 - 0.3 * inn), V(0.3, 0, 0.15 + 0.3 * inn))
	end}

-- 10 Count Fangula: glides above the floor, cape spread like wings. Hovers at rest, cape drawn across his face; the
-- grab flares the cape and clutches; a rising "mwahaha" with arms spread.
M.fangula = {Stride = 6,
	Gait = function(p, ph, s)
		p.LH, p.RH = V(-0.12, 0, -0.04), V(-0.12, 0, 0.04)
		arms(p, V(0.4, 0, -1.1), V(0.4, 0, 1.1))
		p.Root = V(-0.22 * s.Run, 0, 0)
		p.Neck = V(0.15, 0, 0)
		p.Off = V(0, 1.0 + 0.2 * sin(s.T * 2.4), 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.RS = V(1.1, -0.6, 0.15)
		p.LS = V(0.15, 0, -0.18)
		p.Off = V(0, 0.6 + 0.12 * sin(t * 1.3), 0)
		p.Neck = V(-0.06, 0.3 * sin(t * 0.3), 0)
		p.Free = 1
	end,
	Grab = function(p, a)
		local flare = ease(a / 0.12) * (1 - ease((a - 0.12) / 0.15))
		local k = ease((a - 0.1) / 0.18)
		arms(p, V(1.4 * k, 0, -1.5 * flare - 0.2), V(1.4 * k, 0, 1.5 * flare + 0.2))
		p.Root = V(-0.3 * k, 0, 0)
		p.Off = V(0, 0.6 - 0.3 * k, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V(0.5 * inn, 0, -1.8 * inn - 0.1), V(0.5 * inn, 0, 1.8 * inn + 0.1))
		p.Root = V(0.12 * inn, 0, 0)
		p.Neck = V(0.45 * inn, 0, 0)
		p.Off = V(0, 0.4 + 0.7 * inn, 0)
		p.Free = 1
	end}

-- 11 Unit Vex: a by-the-book riot enforcer: an athletic, pumping sprint. Visor sweeps the hall at rest, baton in
-- hand; an arrest of a grab; a clipped, synthetic laugh.
M.vex = {Stride = 6.4,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.85 * r, 0)
		swing(p, ph, 1.0 * r, 0.1, 0.2)
		p.Root = V(-0.06 - 0.24 * r, 0, 0)
		p.Neck = V(0.22 * r, 0, 0)
		p.Off = air(ph, 0.25 * r)
	end,
	Idle = function(p, t)
		p.RS = V(0.4, 0, 0.12)
		p.LS = V(0.05, 0, -0.12)
		p.Neck = V(0, 0.6 * sin(t * 2 * pi / 9), 0)
		breathe(p, t, 0.8)
		shift(p, t, 9, 0.025)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.3})
		p.LS = V(p.LS.X * 0.75, 0, -0.2)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.1, Shake = 0.03, Rate = 16, Head = 0.25})
		p.Neck += V(0, 0, 0.2 * inn)
		p.RS = V(0.4 + 1.0 * inn, 0, 0.12)
	end}

-- 12 Vapor: a chrome-limbed wolf: a long loping sprint, body low. Sniffs the air at rest; a pouncing bite of a grab;
-- howls when it catches you.
M.vapor = {Stride = 8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.95 * r, 0)
		arms(p, V(0.5 + 0.55 * sin(ph + pi) * r, 0, -0.2), V(0.5 + 0.55 * sin(ph) * r, 0, 0.2))
		p.Root = V(-0.08 - 0.45 * r, 0, 0)
		p.Neck = V(0.45 * r, 0, 0)
		p.Off = air(ph, 0.22 * r)
	end,
	Idle = function(p, t)
		local sniff = pulse(t, 5, 1.2)
		p.Neck = V(0.12 + 0.05 * sin(t * 9) * sniff, 0.35 * sin(t * 0.45), 0.12 * sin(t * 0.7))
		p.Root = V(-0.08, 0, 0)
		sides(p, 0.18, 0.15)
		breathe(p, t)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.3, Lean = 0.45, Stance = 0.55, Head = 0.35})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Neck = V(0.8 * inn, 0, 0)
		p.Root = V(0.18 * inn, 0, 0)
		sides(p, 0.4 * inn + 0.15, 0.2)
	end}

-- 13 Kage: the ninja run, arms swept back, body low and silent. Perfectly still at rest, hands together; a
-- lightning-fast strike of a grab; a silent shoulder-shaking chuckle.
M.kage = {Stride = 6.8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.95 * r, 0)
		arms(p, V(-1.2 * r, 0, -0.22), V(-1.2 * r, 0, 0.22))
		p.Root = V(-0.08 - 0.42 * r, 0, 0)
		p.Neck = V(0.4 * r, 0, 0)
		p.Off = air(ph, 0.15 * r)
	end,
	Idle = function(p, t)
		arms(p, V(0.95, 0.45, -0.1), V(0.95, -0.45, 0.1))
		breathe(p, t, 0.5, 1.0)
		p.Neck += V(0, 0.25 * sin(t * 2 * pi / 14), 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.4, Stance = 0.6, Speed = 0.12})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 16)
		arms(p, V(0.95 * inn, 0.45 * inn, -0.1 - 0.05 * k * inn), V(0.95 * inn, -0.45 * inn, 0.1 + 0.05 * k * inn))
		p.Neck = V(0.15 * inn, 0, 0)
		p.Root = V(0.05 * inn, 0, 0)
	end}

-- 14 Taiho: a horned oni in samurai armour who stomps the ground flat. A wide sumo stance at rest, fists ready, huge
-- slow breaths; both fists clamp down in the grab; a roaring laugh, one fist shaken at the sky.
M.oni = {Stride = 3.8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.4 * r, 0.3)
		swing(p, ph, 0.45 * r, 0.4)
		p.Root = V(-0.1 * r, 0.1 * sin(ph) * r, 0.14 * sin(ph) * r)
		p.Off = air(ph, 0.06 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.25), V(0, 0, 0.25)
		arms(p, V(0.2, 0, -0.4), V(0.2, 0, 0.4))
		breathe(p, t, 1.9, 0.9)
		scan(p, t, 0.3, 14)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.3, Out = 0.4})
		p.LH, p.RH = V(p.LH.X, 0, -0.25), V(p.RH.X, 0, 0.25)
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.22, Shake = 0.05, Rate = 9, Head = 0.55})
		p.LS = V((1.3 + 0.2 * k) * inn, 0, -0.4)
		p.RS = V(0.2, 0, 0.4)
		p.LH, p.RH = V(0, 0, -0.25), V(0, 0, 0.25)
	end}

-- 15 SB-9000: an industrial security mech that moves in exact, ticking steps: each pose snaps and holds. Its head
-- turns in fixed clicks at rest; a hydraulic clamp of a grab; laughs in three flat steps.
M.sb9000 = {Stride = 4,
	Gait = function(p, ph, s)
		local r = s.Run
		local q = floor(ph / pi) * pi + ease((ph % pi) / pi / 0.4) * pi
		legs(p, q, 0.55 * r, 0)
		swing(p, q, 0.45 * r, 0.15)
		p.Root = V(-0.05 * r, 0, 0)
	end,
	Idle = function(p, t)
		local i = floor(t / 2.5) % 4
		local x = ease(((t / 2.5) % 1) / 0.15)
		local from, to = ({0, 0.45, 0, -0.45})[i + 1], ({0.45, 0, -0.45, 0})[i + 1]
		p.Neck = V(0, from + (to - from) * x, 0)
		arms(p, V(0.2, 0, -0.15), V(0.2, 0, 0.15))
	end,
	Grab = function(p, a)
		local k = ease((a - 0.05) / 0.12)
		local shut = ease((a - 0.17) / 0.1)
		arms(p, V(0.45 * k, 0, -0.45 + 0.35 * shut), V(0.45 * k, 0, 0.45 - 0.35 * shut))
		p.Root = V(-0.3 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local step = floor(clamp(a / 0.45, 0, 3)) / 3
		p.Root = V(0.15 * step * inn, 0, 0)
		p.Neck = V(0.3 * step * inn, 0, 0)
		arms(p, V(0.2, 0, -0.15 - 0.3 * step * inn), V(0.2, 0, 0.15 + 0.3 * step * inn))
	end}

-- 16 Model-7: a sleek android whose sprint skips like corrupted video for an instant now and then. Stands rigid at
-- rest with a rare glitch of the head; a precise grab; a stuttering laugh.
M.model7 = {Stride = 5,
	Gait = function(p, ph, s)
		local r = s.Run
		local glitch = (s.T * 0.9) % 1 < 0.07
		local q = glitch and floor(ph / (pi / 2)) * (pi / 2) or ph
		legs(p, q, 0.75 * r, 0)
		swing(p, q, 0.75 * r, 0.1)
		p.Root = V(-0.18 * r, glitch and 0.12 or 0, 0)
		p.Off = air(ph, 0.18 * r)
	end,
	Idle = function(p, t)
		local glitch = (t % 7) < 0.12
		p.Neck = V(0, glitch and 0.4 or 0.2 * sin(t * 0.4), glitch and 0.15 or 0)
		sides(p, 0.06, 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.25})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local q = floor(a * 8) / 8
		p.Neck = V((0.25 + 0.12 * sin(q * 20)) * inn, 0, 0.12 * inn)
		p.Root = V(0.1 * inn, 0, 0)
		p.RS = V(1.6 * inn, 0, 0.15)
	end}

-- 17 Sir Scorch: a dragon knight who charges behind his shield, sword drawn back. A still guard stance at rest; a
-- shield bash and grab; sword raised in triumph.
M.scorch = {Stride = 5.6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.75 * r, 0)
		p.LS = V(1.3, -0.45, -0.1)
		p.RS = V(-0.5 + 0.25 * sin(ph), 0, 0.45)
		p.Root = V(-0.06 - 0.24 * r, -0.2 * r, 0)
		p.Off = air(ph, 0.2 * r)
	end,
	Idle = function(p, t)
		p.LS = V(0.9, -0.35, -0.1)
		p.RS = V(0.35, 0, 0.2)
		p.LH, p.RH = V(0.15, 0, -0.08), V(-0.1, 0, 0.08)
		breathe(p, t, 0.9)
		scan(p, t, 0.25, 11)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.3})
		p.RS = V(0.35 + 0.9 * k, 0, 0.3)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.12, Shake = 0.03, Rate = 10, Head = 0.45})
		p.RS = V(0.35 + 2.45 * inn, 0, 0.3)
		p.LS = V(0.9, -0.35, -0.1)
	end}

-- 18 Magmor: a lava golem, slow and enormous: long heavy strides, fists low. Slumped and heaving at rest like a
-- furnace; a two-fisted crush of a grab; a slow, rumbling laugh, fists raised.
M.magmor = {Stride = 7,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.45 * r, 0.1)
		swing(p, ph, 0.55 * r, 0.3)
		p.Root = V(-0.08 - 0.15 * r, 0.2 * sin(ph) * r, 0)
		p.Off = air(ph, 0.04 * r)
	end,
	Idle = function(p, t)
		p.Root = V(-0.14 + 0.05 * sin(t * 0.6), 0, 0)
		arms(p, V(0.1, 0, -0.3), V(0.1, 0, 0.3))
		p.Neck = V(0.15 + 0.03 * sin(t * 0.6), 0.2 * sin(t * 0.25), 0)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.4, Lean = 0.3, Speed = 0.24})
		p.LS = V(p.LS.X, 0, -0.5 + 0.35 * k)
		p.RS = V(p.RS.X, 0, 0.5 - 0.35 * k)
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.2, Shake = 0.04, Rate = 7, Head = 0.45})
		arms(p, V((1.7 + 0.2 * k) * inn, 0, -0.55), V((1.7 - 0.2 * k) * inn, 0, 0.55))
	end}

-- 19 Commander Nova: still runs like he's on the Moon: long floaty bounds with a long hang time. Drifts at rest and
-- waves; a slow-motion grab; a slow somersault of triumph.
M.nova = {Stride = 13, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local h = abs(sin(ph)) ^ 0.55
		local a = sin(ph)
		p.LH, p.RH = V(1.0 * a * r, 0, -0.08), V(-1.0 * a * r, 0, 0.08)
		arms(p, V(0.3 - 0.5 * a, 0, -0.8 - 0.25 * h), V(0.3 + 0.5 * a, 0, 0.8 + 0.25 * h))
		p.Root = V(-0.12 * r, 0, 0)
		p.Off = V(0, 2.4 * h * r, 0)
	end,
	Idle = function(p, t)
		p.Off = V(0, 0.3 + 0.2 * sin(t * 0.9), 0)
		p.Root = V(0.04 * sin(t * 0.5), 0, 0.04 * sin(t * 0.7))
		local wave = pulse(t, 9, 2.5)
		p.RS = V(0.1 + 0.15 * sin(t * 6) * wave, 0, 0.2 + 2.0 * clamp(wave * 1.5, 0, 1))
		p.LS = V(0.1, 0, -0.35)
		p.LH, p.RH = V(0.1 * sin(t * 0.9), 0, -0.05), V(-0.1 * sin(t * 0.9), 0, 0.05)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.25, Speed = 0.24})
		p.Off = V(0, 0.3, 0)
	end,
	Laugh = function(p, a)
		local f = ease(a / 1.5)
		if f >= 1 then
			f = 0 -- a full turn is the same as none: ending on 0 means nothing unwinds as the laugh fades out
		end
		p.Root = V(-f * 2 * pi, 0, 0)
		p.Off = V(0, 3 * sin(f * pi), 0)
		p.LH, p.RH = V(1.1 * sin(f * pi), 0, 0), V(1.1 * sin(f * pi), 0, 0)
		arms(p, V(0.5, 0, -1.0), V(0.5, 0, 1.0))
		p.Free = 1
	end}

-- 20 Zorp: a noodle-limbed alien overlord, every limb flopping a beat behind. Strokes its chin at rest, head wobbling
-- slowly; a stretchy reach of a grab; waves all its limbs laughing.
M.zorp = {Stride = 4.8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.65 * r, 0)
		p.LH += V(0, 0, 0.15 * sin(ph * 2))
		p.RH += V(0, 0, 0.15 * sin(ph * 2 + 1))
		arms(p, V(-1.0 * sin(ph - 0.8) * r, 0, -0.6 - 0.3 * sin(ph * 2)), V(1.0 * sin(ph - 0.8) * r, 0, 0.6 + 0.3 * sin(ph * 2 + 1)))
		p.Root = V(-0.05, 0.22 * sin(ph - 0.5) * r, 0.12 * sin(ph * 2) * r)
		p.Neck = V(0.12 * sin(ph * 2), 0, 0.25 * sin(ph - 1))
		p.Off = air(ph, 0.15 * r)
	end,
	Idle = function(p, t)
		p.RS = V(1.25, 0.2, 0.15)
		p.LS = V(0.8, 0.35, -0.15)
		p.Neck = V(0.06 * sin(t * 1.1), 0.2 * sin(t * 0.35), 0.18 * sin(t * 0.8))
		p.Root = V(0, 0, 0.05 * sin(t * 0.8 + 1))
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.7, Lean = 0.3})
		p.LS += V(0.15 * sin(a * 20) * k, 0, 0)
		p.RS += V(-0.15 * sin(a * 20) * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V((1.4 + 0.6 * sin(a * 8)) * inn, 0, -1.0 * inn - 0.2), V((1.4 + 0.6 * sin(a * 8 + 2)) * inn, 0, 1.0 * inn + 0.2))
		p.Neck = V(0.2 * inn, 0, 0.3 * sin(a * 5) * inn)
		p.Root = V(0.08 * inn, 0, 0.12 * sin(a * 6) * inn)
	end}

-- 21 Dex: a diver in a brass helmet who wades along as if underwater, arms paddling. Bobs gently at rest as if
-- floating; a slow two-handed reach; a bubbly laugh with a thumbs up.
M.dex = {Stride = 4.4,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.45 * r, 0.05)
		arms(p, V(0.8 + 0.5 * sin(ph * 2) * r, 0, -0.45), V(0.8 + 0.5 * sin(ph * 2 + pi) * r, 0, 0.45))
		p.Root = V(-0.08 - 0.18 * r, 0, 0)
		p.Off = V(0, 0.18 * sin(ph * 2) ^ 2 * r, 0)
	end,
	Idle = function(p, t)
		p.Off = V(0, 0.1 + 0.07 * sin(t * 1.1), 0)
		arms(p, V(0.3 + 0.12 * sin(t * 1.1), 0, -0.45), V(0.3 + 0.12 * sin(t * 1.1 + 1), 0, 0.45))
		p.Neck = V(0.08, 0.3 * sin(t * 0.4), 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.4, Lean = 0.25, Speed = 0.24, Out = 0.35})
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.12, Shake = 0.04, Rate = 9, Head = 0.3})
		p.RS = V(1.4 * inn, 0, 0.2)
		p.LS = V(0.2, 0, -0.4)
		p.Off = V(0, 0.1 * inn, 0)
	end}

-- 22 King Tridentus: the sea king, surging after you in majestic lunges, trident driving forward each stride.
-- Surveys his kingdom chin-up at rest; pins you with the trident; a booming laugh, trident raised to the heavens.
M.tridentus = {Stride = 6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.7 * r, 0)
		p.RS = V(1.0 + 0.5 * max(0, sin(ph * 2)) * r, 0, 0.15)
		p.LS = V(-0.35 * sin(ph) * r, 0, -0.35)
		p.Root = V(-0.05 - 0.13 * r, -0.12 * r, 0)
		p.Off = air(ph, 0.12 * r)
	end,
	Idle = function(p, t)
		p.RS = V(0.3, 0, 0.28)
		p.LS = V(0.15, 0, -0.3)
		p.Neck = V(-0.1, 0.35 * sin(t * 2 * pi / 14), 0)
		breathe(p, t, 1.3, 1.0)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.3})
		p.RS = V(0.3 + 1.3 * k, 0, 0.15)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.22, Shake = 0.04, Rate = 9, Head = 0.5})
		p.RS = V(0.3 + 2.6 * inn, 0, 0.12)
		p.LS = V(0.15, 0, -0.3 - 0.5 * inn)
	end}

-- 23 Mumbles: a hulking mummy, arms out straight, stiff legs shuffling. Sways at rest with arms half raised, head
-- lolling; lurches into the grab; a wheezing laugh with flailing arms.
M.mumbles = {Stride = 3,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH, p.RH = V(0.35 * a * r, 0, 0), V(-0.35 * a * r, 0, 0)
		arms(p, V(1.5, 0, -0.08 + 0.05 * a), V(1.5, 0, 0.08 - 0.05 * a))
		p.Root = V(-0.05, 0, 0.1 * a * r)
		p.Neck = V(-0.15, 0, 0.15)
	end,
	Idle = function(p, t)
		p.Root = V(0, 0, 0.07 * sin(t * 0.8))
		arms(p, V(1.0 + 0.08 * sin(t * 1.7), 0, -0.1), V(0.85 + 0.08 * sin(t * 1.5), 0, 0.1))
		p.Neck = V(-0.15, 0.1 * sin(t * 0.4), 0.2 * sin(t * 0.8 + 1))
	end,
	Grab = function(p, a)
		local k = ease((a - 0.05) / 0.22)
		arms(p, V(1.5 - 0.9 * k, 0, -0.1), V(1.5 - 0.9 * k, 0, 0.1))
		p.Root = V(-0.4 * k, 0, 0)
		p.LH, p.RH = V(0.4 * k, 0, 0), V(-0.3 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V((0.1 + 0.04 * sin(a * 7)) * inn, 0, 0)
		p.Neck = V(0.3 * inn, 0, 0.15 * sin(a * 3) * inn)
		arms(p, V(1.2, 0, -0.2 - 0.7 * inn * abs(sin(a * 5))), V(1.2, 0, 0.2 + 0.7 * inn * abs(sin(a * 5 + 1))))
	end}

-- 24 Anubis: the jackal god, a stately stride with the staff, head swivelling like a temple guardian. Still as a
-- statue at rest, head turning very slowly; hooks you with the staff; raises both arms to the sky.
M.anubis = {Stride = 4.6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.6 * r, 0)
		p.LS = V(0.35 - 0.3 * sin(ph) * r, 0, -0.45)
		p.RS = V(0.9, 0, 0.2)
		p.Neck = V(0, 0.22 * sin(ph) * r, 0)
		p.Root = V(-0.12 * r, 0, 0)
		p.Off = air(ph, 0.12 * r)
	end,
	Idle = function(p, t)
		p.RS = V(0.45, 0, 0.28)
		p.LS = V(0.12, 0, -0.15)
		p.Neck = V(0, 0.45 * sin(t * 2 * pi / 16), 0)
		breathe(p, t, 0.5, 0.9)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.25})
		p.RS = V(0.45 + 1.25 * k, 0, 0.2)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V(0.3 * inn, 0, -0.15 - 2.2 * inn), V(0.3 * inn, 0, 0.28 + 2.1 * inn))
		p.Neck = V(0.5 * inn, 0, 0)
		p.Root = V(0.1 * inn, 0, 0)
	end}

-- 25 Sir Peppermint: a candy cane knight: a knightly trot, lance levelled, shield across. Lance planted at rest, a
-- slow look along the hall; sweeps you up with lance arm and shield; raises the lance with little triumphant hops.
M.peppermint = {Stride = 5,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.6 * r, 0)
		p.RS = V(1.3, 0, 0.12)
		p.LS = V(1.0, -0.45, -0.1)
		p.Root = V(-0.05 - 0.1 * r, -0.12 * r, 0)
		p.Off = air(ph, 0.18 * r)
	end,
	Idle = function(p, t)
		p.RS = V(0.3, 0, 0.22)
		p.LS = V(0.85, -0.35, -0.1)
		breathe(p, t)
		scan(p, t, 0.4, 11)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.45, Lean = 0.3})
		p.LS = V(1.0 + 0.4 * k, -0.3, -0.1)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.RS = V(0.3 + 2.5 * inn, 0, 0.2)
		p.LS = V(0.85, -0.35, -0.1)
		p.Neck = V(0.35 * inn, 0, 0)
		p.Off = V(0, 0.2 * abs(sin(a * 6)) * inn, 0)
	end}

-- 26 Baron von Bonbon: a sinister gingerbread chef who skips with delight. Rubs his hands together, scheming, at
-- rest; a grabby chef's lunge; a chef's kiss and a flourish.
M.bonbon = {Stride = 5.2,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V((0.9 * max(0, a) - 0.15) * r, 0, 0)
		p.RH = V((0.9 * max(0, -a) - 0.15) * r, 0, 0)
		p.RS = V(1.8 + 0.3 * sin(ph * 4), 0, 0.3)
		p.LS = V(-0.45 * a * r, 0, -0.55)
		p.Neck = V(0.15, 0, 0.15 * a)
		p.Off = V(0, 0.6 * max(0, sin(ph * 2)) * r, 0)
	end,
	Idle = function(p, t)
		arms(p, V(1.0 + 0.06 * sin(t * 7), 0.45, -0.08), V(1.0 - 0.06 * sin(t * 7), -0.45, 0.08))
		p.Neck = V(-0.12, 0.25 * sin(t * 0.5), 0)
		p.Root = V(-0.06, 0, 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.3})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local f = ease((a - 0.2) / 0.5)
		p.RS = V((1.6 - 0.6 * f) * inn, 0, (0.2 + 0.9 * f) * inn)
		p.LS = V(0.1, 0, -0.45)
		p.Neck = V(0.3 * f * inn, 0, 0)
		p.Root = V(0.08 * inn, 0, 0)
	end}

-- 27 Pemberton: an emperor penguin butler with a frantic, rocking waddle, flippers out. Straightens his bow tie at
-- rest; flippers out for the grab; flaps madly and hops laughing.
M.pemberton = {Stride = 2.2,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH, p.RH = V(0.2 * a * r, 0, -0.08), V(-0.2 * a * r, 0, 0.08)
		arms(p, V(-0.2, 0, -0.6 - 0.25 * abs(a)), V(-0.2, 0, 0.6 + 0.25 * abs(a)))
		p.Root = V(0, 0.12 * a * r, 0.26 * a * r)
		p.Neck = V(0.08, 0, -0.22 * a)
	end,
	Idle = function(p, t)
		local tie = pulse(t, 8, 1.8)
		p.LS = V(0.05 + 1.25 * clamp(tie * 1.5, 0, 1), 0.45 * tie, -0.1)
		p.RS = V(0.05, 0, 0.12)
		p.Root = V(0, 0, 0.03 * sin(t * 1.2))
		p.Neck = V(-0.08 - 0.12 * tie, 0.2 * sin(t * 0.5), 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.3, Lean = 0.2, Out = 0.4, Stance = 0.2})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local f = sin(a * 20)
		arms(p, V(0, 0, (-0.6 - 0.5 * f) * inn - 0.1), V(0, 0, (0.6 + 0.5 * f) * inn + 0.1))
		p.Off = V(0, 0.25 * abs(sin(a * 8)) * inn, 0)
		p.Neck = V(0.3 * inn, 0, 0)
	end}

-- 28 Yuki: a shaggy yeti who gallops on its knuckles, leaning right over. Hunched and heaving at rest, sniffing the
-- cold; rears up to grab; a rearing roar of a laugh.
M.yuki = {Stride = 7.5,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.7 * r, 0.1)
		arms(p, V(0.9 + 0.85 * sin(ph + 1.2) * r, 0, -0.25), V(0.9 + 0.85 * sin(ph + 1.2 + pi) * r, 0, 0.25))
		p.Root = V(-0.1 - 0.5 * r, 0, 0.06 * sin(ph) * r)
		p.Neck = V(0.55 * r, 0, 0)
		p.Off = air(ph, 0.12 * r)
	end,
	Idle = function(p, t)
		p.Root = V(-0.28 + 0.05 * sin(t * 1.1), 0, 0)
		p.Neck = V(0.3 + 0.06 * sin(t * 7) * pulse(t, 6, 1.2), 0.35 * sin(t * 0.45), 0)
		arms(p, V(0.4, 0, -0.3), V(0.4, 0, 0.3))
		p.LH, p.RH = V(0, 0, -0.1), V(0, 0, 0.1)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.2, Out = 0.3})
		p.Neck = V(0.3, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V(0.25 * inn, 0, 0)
		arms(p, V(2.1 * inn, 0, -0.8 * inn - 0.2), V(2.1 * inn, 0, 0.8 * inn + 0.2))
		p.Neck = V((0.65 + 0.04 * sin(a * 28)) * inn, 0, 0)
	end}

-- 29 Sheriff Tumbleweed: rides an invisible horse: a bouncing giddy-up, one hand on the reins, lasso circling. Thumbs
-- in his belt at rest, tipping his hat now and then; throws the lasso to grab; a "yeehaw" with the lasso overhead.
M.sheriff = {Stride = 5, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		local b = abs(sin(ph))
		p.LH, p.RH = V(0.4 * a * r + 0.2, 0, -0.3), V(-0.4 * a * r + 0.2, 0, 0.3)
		p.LS = V(1.0, 0, -0.1)
		p.RS = V(2.4, (s.T * 10) % (2 * pi), 0.3)
		p.Root = V(-0.08 + 0.12 * b, 0, 0)
		p.Off = V(0, 0.6 * b * r, 0)
	end,
	Idle = function(p, t)
		local hat = pulse(t, 9, 1.4)
		p.RS = V(0.15 + 1.9 * hat, 0, 0.25)
		p.LS = V(0.15, 0, -0.3)
		p.LH, p.RH = V(0, 0, -0.14), V(0, 0, 0.14)
		p.Neck = V(-0.2 * hat, 0.2 * sin(t * 0.4), 0)
		shift(p, t, 7, 0.03)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.4, Lean = 0.25})
		p.RS = V(2.6 - 1.0 * k, 0, 0.3)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.RS = V(2.7 * inn, (a * 14) % (2 * pi), 0.35)
		p.LS = V(0.2, 0, -0.4)
		p.Off = V(0, 0.3 * abs(sin(a * 6)) * inn, 0)
		p.Neck = V(0.3 * inn, 0, 0)
	end}

-- 30 Rattler: a rattlesnake outlaw who slithers side to side as he runs while his head stays locked on you. His
-- poncho hangs from his shoulders, so his arms stay close in and his body and head do the talking. Sways like a
-- charmed snake at rest, tasting the air; rears back and strikes with his whole body; a hissing, rattling laugh.
M.rattler = {Stride = 6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.5 * r, 0)
		arms(p, V(0.1 + 0.12 * sin(ph) * r, 0, -0.05), V(0.1 - 0.12 * sin(ph) * r, 0, 0.05))
		p.Root = V(-0.2 * r, 0.3 * sin(ph) * r, 0.12 * sin(ph) * r)
		p.Neck = V(0.22 * r, -0.3 * sin(ph) * r, 0)
	end,
	Idle = function(p, t)
		p.Root = V(0, 0, 0.09 * sin(t * 1.3))
		p.Neck = V(0.05 + 0.04 * pulse(t, 3.5, 0.3), 0, -0.22 * sin(t * 1.3 - 0.6))
		arms(p, V(0.06, 0, -0.04), V(0.06, 0, 0.04))
	end,
	Grab = function(p, a)
		local wind = ease(a / 0.1) * (1 - ease((a - 0.1) / 0.06))
		local k = ease((a - 0.1) / 0.1)
		p.Root = V(0.2 * wind - 0.5 * k, 0, 0)
		p.Neck = V(-0.2 * wind + 0.35 * k, 0, 0)
		arms(p, V(0.55 * k, 0, -0.05), V(0.55 * k, 0, 0.05))
		p.LH, p.RH = V(0.5 * k, 0, 0), V(-0.35 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V((0.12 + 0.025 * sin(a * 30)) * inn, 0, 0.06 * sin(a * 3) * inn)
		p.Neck = V(0.3 * inn, 0, 0.1 * sin(a * 2) * inn)
		arms(p, V(0.06, 0, -0.04), V(0.06, 0, 0.04))
	end}

-- 31 Tiki Tok: a carved tiki spirit that charges in a war-dance stomp, spear raised. Drums a slow beat on its belly
-- at rest; a spear-hand grab; a stomping war dance.
M.tiki = {Stride = 4.4,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V(1.0 * max(0, a) * r, 0, -0.18)
		p.RH = V(1.0 * max(0, -a) * r, 0, 0.18)
		p.RS = V(2.2, 0, 0.35)
		p.LS = V(1.3, 0, -0.65 + 0.25 * a)
		p.Root = V(-0.06, 0, 0.12 * a * r)
		p.Off = V(0, 0.4 * abs(sin(ph)) * r, 0)
	end,
	Idle = function(p, t)
		local a = sin(t * 3)
		p.LS = V(0.55 + 0.25 * max(0, a), 0.35, -0.1)
		p.RS = V(0.55 + 0.25 * max(0, -a), -0.35, 0.1)
		p.LH, p.RH = V(0, 0, -0.16), V(0, 0, 0.16)
		p.Root = V(0, 0, 0.025 * a)
		scan(p, t, 0.2, 12)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.3})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local b = sin(a * 8)
		p.LH = V(0.9 * max(0, b) * inn, 0, -0.2)
		p.RH = V(0.9 * max(0, -b) * inn, 0, 0.2)
		p.RS = V(2.4 * inn, 0, 0.4)
		p.LS = V(1.4 * inn, 0, -0.6)
		p.Neck = V(0.25 * inn, 0, 0)
		p.Off = V(0, 0.25 * abs(b) * inn, 0)
	end}

-- 32 Itza: a jaguar warrior who prowls low and bursts into a pouncing sprint. Crouched and coiled at rest, watching;
-- a pounce of a grab; a purring chuckle and a long cat stretch.
M.itza = {Stride = 7.8,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.9 * r, 0)
		arms(p, V(0.85 + 0.45 * sin(ph + pi) * r, 0, -0.2), V(0.85 + 0.45 * sin(ph) * r, 0, 0.2))
		p.Root = V(-0.1 - 0.5 * r, 0, 0)
		p.Neck = V(0.55 * r, 0, 0)
		p.Off = air(ph, 0.18 * r)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0.42, 0, -0.08), V(-0.3, 0, 0.08)
		p.Root = V(-0.28, 0, 0.04 * sin(t * 1.6))
		p.Neck = V(0.3, 0.3 * sin(t * 2 * pi / 6), 0)
		arms(p, V(0.55, 0, -0.2), V(0.55, 0, 0.2))
		breathe(p, t)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.04) / 0.2)
		arms(p, V(2.0 - 1.5 * k, 0, -0.25), V(2.0 - 1.5 * k, 0, 0.25))
		p.Root = V(-0.45 * k, 0, 0)
		p.Neck = V(0.3, 0, 0)
		p.Off = V(0, 0.7 * sin(k * pi), 0)
		p.LH, p.RH = V(0.5 * k, 0, 0), V(-0.4 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V((-0.2 + 0.03 * sin(a * 12)) * inn, 0, 0)
		arms(p, V(1.8 * inn, 0, -0.25), V(1.8 * inn, 0, 0.25))
		p.Neck = V(0.35 * inn, 0, 0.15 * inn)
		p.LH, p.RH = V(0.3 * inn, 0, 0), V(-0.3 * inn, 0, 0)
	end}

-- 33 Wobbles: a grinning carnival clown on a skipping run, arms windmilling. Juggles invisible balls at rest; a big
-- clown hug of a grab; doubles over laughing.
M.wobbles = {Stride = 5,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.75 * r, 0.1)
		arms(p, V(1.2 + 1.5 * sin(s.T * 8), 0, -0.8), V(1.2 - 1.5 * sin(s.T * 8), 0, 0.8))
		p.Root = V(0.05 * sin(ph * 2), 0, 0.12 * sin(ph) * r)
		p.Off = V(0, 0.45 * max(0, sin(ph * 2)) * r, 0)
	end,
	Idle = function(p, t)
		p.LS = V(0.8 + 0.35 * sin(t * 5), 0, -0.2)
		p.RS = V(0.8 + 0.35 * sin(t * 5 + pi), 0, 0.2)
		p.Neck = V(0.25 + 0.08 * sin(t * 5), 0, 0)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.3})
		local wide = 1.0 * (1 - k) + 0.25
		p.LS = V(p.LS.X, 0, -wide)
		p.RS = V(p.RS.X, 0, wide)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V((-0.35 + 0.06 * sin(a * 16)) * inn, 0, 0)
		arms(p, V(0.6 * inn, 0, -0.3), V(0.6 * inn, 0, 0.3))
		p.Neck = V(0.55 * inn, 0, 0)
	end}

-- 34 Taurus: a minotaur strongman. A head-down bull charge, horns first. Paws the floor and snorts at rest; drives in
-- horns-first to grab; flexes in a double-biceps pose.
M.taurus = {Stride = 6.4,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.75 * r, 0.05)
		swing(p, ph, 0.5 * r, 0.35, 0.2)
		p.Root = V(-0.08 - 0.28 * r, 0, 0)
		p.Neck = V(-0.25 * r, 0, 0)
		p.Off = air(ph, 0.18 * r)
	end,
	Idle = function(p, t)
		breathe(p, t, 1.7, 1.2)
		local paw = pulse(t, 7, 2.2)
		p.RH = V(0.3 * sin(t * 6) * paw, 0, 0.06)
		p.LH = V(0, 0, -0.06)
		p.Neck += V(-0.12 - 0.08 * pulse(t, 4.5, 0.4), 0.2 * sin(t * 0.4), 0)
		arms(p, p.LS + V(0.15, 0, -0.32), p.RS + V(0.15, 0, 0.32))
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.4, Lean = 0.4, Head = -0.3})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V(0.2 * inn, 0, -0.3 - 1.3 * inn), V(0.2 * inn, 0, 0.3 + 1.3 * inn))
		p.Root = V(0.1 * inn, 0, 0)
		p.Neck = V((0.3 + 0.04 * sin(a * 10)) * inn, 0, 0)
	end}

-- 35 Jetpack Jenny: a goggled aviator who skims along on her jetpack, legs trailing. Hovers at rest, shading her eyes
-- to scan the hall; a swooping grab; a loop-the-loop.
M.jenny = {Stride = 10,
	Gait = function(p, ph, s)
		p.LH, p.RH = V(-0.4, 0, -0.08), V(-0.55, 0, 0.08)
		arms(p, V(0.15, 0, -0.55), V(0.15, 0, 0.55))
		p.Root = V(-0.55 * s.Run, 0, 0.08 * sin(s.T * 2))
		p.Neck = V(0.5 * s.Run, 0, 0)
		p.Off = V(0, 2.0 + 0.3 * sin(s.T * 3), 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.Off = V(0, 0.9 + 0.15 * sin(t * 2.6), 0)
		local shade = pulse(t, 10, 3)
		p.LS = V(0.1 + 1.9 * clamp(shade * 1.5, 0, 1), 0, -0.3)
		p.RS = V(0.1, 0, 0.3)
		p.Neck = V(0.05, 0.5 * sin(t * 0.5), 0)
		p.LH, p.RH = V(-0.1, 0, -0.05), V(-0.15, 0, 0.05)
		p.Free = 1
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.4})
		p.Off = V(0, 0.6, 0)
		p.Free = 0.5
	end,
	Laugh = function(p, a)
		local f = ease(a / 1.2)
		if f >= 1 then
			f = 0
		end
		p.Root = V(f * 2 * pi, 0, 0)
		p.Off = V(0, 1.0 + 2.2 * sin(f * pi), 0)
		arms(p, V(0.2, 0, -0.6), V(0.2, 0, 0.6))
		p.Free = 1
	end}

-- 36 Ironclad: a riveted steam automaton: piston strides, knees pumping high. Stands still at rest, furnace
-- breathing, the occasional mechanical twitch; a piston punch of a grab; a steam-powered fist pump.
M.ironclad = {Stride = 6,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V((1.1 * max(0, a) - 0.2) * r, 0, 0)
		p.RH = V((1.1 * max(0, -a) - 0.2) * r, 0, 0)
		swing(p, ph, 0.45 * r, 0.25)
		p.Root = V(-0.08 * r, 0, 0)
		p.Off = V(0, 0.25 * abs(a) * r, 0)
	end,
	Idle = function(p, t)
		breathe(p, t, 1.4, 0.8)
		local twitch = pulse(t, 5.3, 0.18)
		p.RS = V(0.2 + 0.1 * twitch, 0, 0.25)
		p.LS = V(0.2, 0, -0.25)
		p.Neck += V(0, 0.15 * floor(sin(t * 0.3) * 3) / 3, 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.2, Speed = 0.12})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local b = abs(sin(a * 7))
		p.RS = V((2.0 + 0.6 * b) * inn, 0, 0.2)
		p.LS = V(0.2, 0, -0.3)
		p.Root = V(0.12 * inn, 0, 0)
		p.Off = V(0, 0.25 * b * inn, 0)
	end}

-- 37 Moe: a short-sighted giant mole: a crouched scurry, claws digging at the air. Squints and sniffs at rest, claws
-- rubbing together; snatches with both claws; digs in a frenzy of delight.
M.moe = {Stride = 2.6,
	Gait = function(p, ph, s)
		local r = s.Run
		legs(p, ph, 0.55 * r, 0.1)
		arms(p, V(1.1 + 0.6 * sin(ph * 2) * r, 0, -0.3), V(1.1 + 0.6 * sin(ph * 2 + pi) * r, 0, 0.3))
		p.Root = V(-0.1 - 0.3 * r, 0, 0.08 * sin(ph) * r)
		p.Neck = V(0.35 * r, 0.18 * sin(ph * 2), 0)
		p.Off = air(ph, 0.06 * r)
	end,
	Idle = function(p, t)
		p.Neck = V(0.2 + 0.05 * sin(t * 8) * pulse(t, 4, 1), 0.3 * sin(t * 0.7), 0)
		arms(p, V(1.0, 0.35 + 0.07 * sin(t * 6), -0.1), V(1.0, -0.35 - 0.07 * sin(t * 6), 0.1))
		p.Root = V(-0.15, 0, 0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.3, Lean = 0.35, Out = 0.35})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V((0.8 + 0.7 * sin(a * 16)) * inn, 0, -0.25), V((0.8 + 0.7 * sin(a * 16 + pi)) * inn, 0, 0.25))
		p.Root = V(-0.3 * inn, 0, 0)
		p.Neck = V(0.3 * inn, 0, 0)
	end}

-- 38 Queen Lumina: a crystal sorceress who leaps after you in grand jetes, arms in a perfect arc, a pirouette now and
-- then. Moves her arms slowly through ballet positions at rest, with a slow pirouette; an arcane grasp; a regal laugh
-- behind her hand and a curtsy.
M.lumina = {Stride = 10, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local h = abs(sin(ph))
		local lead = sin(ph) >= 0 and 1 or -1
		p.LH, p.RH = V(1.0 * h * lead * r, 0, 0), V(-1.0 * h * lead * r, 0, 0)
		arms(p, V(0.5, 0, -1.6), V(0.5, 0, 1.6))
		p.Neck = V(0.2, 0, 0)
		local spin = (s.T % 6 < 0.8) and ease((s.T % 6) / 0.8) or 0
		p.Root = V(0, spin * 2 * pi, 0)
		p.Free = spin > 0 and 1 or 0
		p.Off = V(0, 1.6 * h ^ 0.8 * r, 0)
	end,
	Idle = function(p, t)
		local c = sin(t * 0.6)
		arms(p, V(0.3 + 0.25 * c, 0, -0.6 - 0.4 * c), V(0.3 + 0.25 * c, 0, 0.6 + 0.4 * c))
		p.Neck = V(-0.08, 0.2 * sin(t * 0.3), 0.05 * c)
		local spin = (t % 14) < 2.5 and ease((t % 14) / 2.5) or 0
		p.Root = V(0, spin * 2 * pi, 0)
		p.Free = spin > 0 and spin < 1 and 1 or 0
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.2})
		p.RS = V(p.RS.X + 0.4 * k, 0, 0.35)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local curtsy = ease((a - 1.0) / 0.4) * (1 - ease((a - 1.6) / 0.3))
		p.RS = V(1.6 * inn * (1 - curtsy), -0.4, 0.2 + 0.8 * curtsy)
		p.LS = V(0.2, 0, -0.3 - 0.8 * curtsy)
		p.Neck = V(0.15 * inn, 0, 0.18 * inn)
		p.RH = V(-0.45 * curtsy, 0, 0.1)
		p.Root = V(0.06 * inn - 0.15 * curtsy, 0, 0)
	end}

-- 39 Chronos: an ancient time wizard who moves in skipped frames: freezes, jumps ahead. Turns his hourglass over,
-- impatient, at rest; a time-stopped grab that jumps from frame to frame; rewinds himself in jerky steps laughing.
M.chronos = {Stride = 4.4,
	Gait = function(p, ph, s)
		local r = s.Run
		local skip = (s.T * 2.5) % 1 < 0.18
		local q = skip and floor(ph / 0.9) * 0.9 or ph
		legs(p, q, 0.5 * r, 0)
		swing(p, q, 0.35 * r, 0.12)
		p.RS = V(1.3, 0, 0.2)
		p.Root = V(-0.08 * r, 0, 0)
		p.Off = air(q, 0.1 * r)
	end,
	Idle = function(p, t)
		local turn = ease(((t % 5) - 3.5) / 0.8)
		p.RS = V(1.15, turn * pi, 0.2)
		p.LS = V(0.15, 0, -0.2)
		p.Neck = V(-0.2, 0.15 * sin(t * 0.4), 0)
		breathe(p, t, 0.6, 1.0)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.25})
		local q = floor(a / 0.075) * 0.075
		local k = ease((q - 0.05) / 0.2)
		p.LS = V(0.4 * k, 0, -0.25)
		p.RS = V(0.4 * k, 0, 0.25)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V(0, -floor(a * 6) * 0.35 * inn, 0)
		p.RS = V(2.5 * inn, 0, 0.3)
		p.LS = V(0.9 * inn, 0, -0.8 * inn)
		p.Neck = V(0.3 * inn, 0, 0)
		p.Free = 1
	end}

-- 40 The Game Master: never walks: floats, arms raised, cape trailing. Hovers at rest, slowly turning to watch the
-- hall; a telekinetic grab with one outstretched hand; rises high, arms flung wide, laughing.
M.gamemaster = {Stride = 9,
	Gait = function(p, ph, s)
		p.LH, p.RH = V(-0.12, 0, -0.06), V(-0.05, 0, 0.06)
		arms(p, V(0.4, 0, -1.9 + 0.15 * sin(s.T * 2)), V(0.4, 0, 1.9 - 0.15 * sin(s.T * 2)))
		p.Root = V(-0.18 * s.Run, 0, 0)
		p.Off = V(0, 2.6 + 0.4 * sin(s.T * 1.6), 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.Off = V(0, 2.0 + 0.3 * sin(t * 1.1), 0)
		arms(p, V(0.25, 0, -0.45), V(0.25, 0, 0.45))
		p.Root = V(0, 0.25 * sin(t * 0.2), 0)
		p.Neck = V(0.15, 0, 0)
		p.Free = 1
	end,
	Grab = function(p, a)
		local k = ease((a - 0.05) / 0.2)
		p.RS = V(1.6 * k, 0, 0.2)
		p.LS = V(0.3, 0, -0.9 * k - 0.3)
		p.Root = V(-0.2 * k, 0, 0)
		p.Off = V(0, 2.0 - 1.0 * k, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		arms(p, V(0.6 * inn, 0, -0.4 - 2.0 * inn), V(0.6 * inn, 0, 0.4 + 2.0 * inn))
		p.Neck = V(0.6 * inn, 0, 0)
		p.Root = V(0.2 * inn, 0, 0)
		p.Off = V(0, 1.0 + 1.8 * inn, 0)
		p.Free = 1
	end}

-- the taunt when a chase starts: points straight at you
function K.taunt(p, age)
	local k = ease(age / 0.2) * (1 - ease((age - 0.7) / 0.2))
	p.RS = V(1.55 * k, 0, 0.12)
	p.Neck = V(0, 0, 0.12 * sin(age * 10) * k)
end
-- the grab missed (the thief slipped away): a stumble forward and a quick recovery
function K.whiff(p, age)
	local k = ease(age / 0.15) * (1 - ease((age - 0.25) / 0.25))
	arms(p, V(1.2 * k, 0, -0.35 * k - 0.1), V(1.2 * k, 0, 0.35 * k + 0.1))
	p.Root = V(-0.28 * k, 0, 0.06 * k)
	p.LH, p.RH = V(0.45 * k, 0, 0), V(-0.3 * k, 0, 0)
end

------------------------------------------------------------------
-- RUNNING SOUNDS
------------------------------------------------------------------
-- Every sound used, cut to one footfall: Id, base Volume (evens out their loudness), Off/Len = the slice to play.
-- All are free Creator Store audio checked to load (most are Pro Sound Effects recordings).
K.SOUNDS = {
	mil = {Id = 113663232024295, Vol = 0.66}, -- heavy military boot
	heavy1 = {Id = 85383897332935, Vol = 0.8}, heavy2 = {Id = 91926553559466, Vol = 0.8},
	heavy3 = {Id = 118881096487952, Vol = 0.9}, heavy6 = {Id = 84534976496830, Vol = 0.9},
	heavy7 = {Id = 121542193392069, Vol = 0.83},
	mech = {Id = 6964740205, Vol = 0.95}, -- heavy mech foot
	boot = {Id = 98810424870259, Vol = 1.15},
	stomp = {Id = 9114523358, Vol = 3.5}, -- foot stomp on a hard floor
	robo = {Id = 9125818616, Vol = 1.4, Len = 0.5}, -- robot foot on metal
	robolight = {Id = 9118243695, Vol = 3.2, Len = 0.3}, -- light bipedal robot step
	rattlebody = {Id = 9118263405, Vol = 2.4, Off = 0.4, Len = 0.5}, -- robot step with a body rattle
	servo = {Id = 9118353503, Vol = 2.2, Len = 0.45}, -- servo whine
	squeak = {Id = 9120222027, Vol = 2.0, Off = 0.1, Len = 0.4}, -- toy squeak
	duck = {Id = 121866723225693, Vol = 0.55, Len = 0.45}, -- rubber squeak (clown shoe)
	plush = {Id = 72412705492327, Vol = 1.0, Off = 0.1, Len = 0.45}, -- teddy squeak
	snowstomp = {Id = 9125965296, Vol = 1.5, Off = 0.82, Len = 0.5},
	snow = {Id = 332621136, Vol = 4, Off = 0.08, Len = 0.28},
	sand = {Id = 136355513209326, Vol = 3.5, Off = 0.05, Len = 0.4},
	splash = {Id = 9117942767, Vol = 1.8, Len = 0.5},
	clank = {Id = 9119076586, Vol = 1.4, Len = 0.4}, -- metal/armour impact
	crunch = {Id = 9113563538, Vol = 1.6}, -- dull crunchy box hit (gingerbread)
	hoof = {Id = 9118621947, Vol = 2.2, Len = 0.35}, -- wood on rock: a hard hoof/peg clack
	woodknock = {Id = 9113921754, Vol = 1.5, Len = 0.35}, -- wood on stone
	candy = {Id = 9117581790, Vol = 1.0, Len = 0.35}, -- hard plastic tap
	thud = {Id = 9120880314, Vol = 4, Len = 0.4}, -- muted wooden thud
	boing = {Id = 77363542728036, Vol = 1.3, Off = 0.3, Len = 0.55},
	tick = {Id = 8140501675, Vol = 3.5, Len = 0.25},
	squish = {Id = 9113660936, Vol = 1.5, Len = 0.35},
	rattle = {Id = 9120921325, Vol = 2.5, Len = 0.45}, -- rattling lattice (a snake's rattle, loose bones)
	clatter = {Id = 9117518577, Vol = 0.75, Len = 0.4}, -- plastic clatter (bones)
	stone = {Id = 99879384384244, Vol = 3.0, Len = 0.35},
	concrete = {Id = 73316535929963, Vol = 2.6, Len = 0.3},
	cloth = {Id = 9113821261, Vol = 3.5, Off = 1.35, Len = 0.6},
	-- loops for the ones that float
	flutter = {Id = 9114499799, Vol = 3.0, Loop = true},
	plasma = {Id = 9125742262, Vol = 2.5, Loop = true},
	rocket = {Id = 135314203986462, Vol = 0.6, Loop = true},
}

-- Steps = {left foot, right foot}; Pitch; Vol; Layer = {sound, pitch, vol, every N steps}; Loop = {sound, pitch, vol}
K.AUDIO = {
	brutus = {Steps = {"mil", "mil"}, Pitch = 0.8, Vol = 1, Layer = {"heavy1", 0.7, 0.5, 1}},
	tusk = {Steps = {"hoof", "hoof"}, Pitch = 0.75, Vol = 0.9, Layer = {"heavy2", 0.6, 0.6, 1}},
	kong = {Steps = {"heavy6", "thud"}, Pitch = 0.55, Vol = 1.1},
	static = {Steps = {"concrete", "concrete"}, Pitch = 1.15, Vol = 0.8, Layer = {"squeak", 1.7, 0.25, 4}},
	tin = {Steps = {"woodknock", "woodknock"}, Pitch = 1.3, Vol = 0.8, Layer = {"tick", 1.4, 0.5, 2}},
	stitches = {Steps = {"plush", "plush"}, Pitch = 0.9, Vol = 0.8, Layer = {"boing", 1.2, 0.35, 2}},
	calico = {Steps = {"concrete", "hoof"}, Pitch = 0.85, Vol = 0.9},
	brine = {Steps = {"splash", "splash"}, Pitch = 0.8, Vol = 0.8, Layer = {"heavy3", 0.7, 0.6, 1}},
	mortimer = {Steps = {"clatter", "clatter"}, Pitch = 1.1, Vol = 0.6, Layer = {"rattle", 1.3, 0.35, 2}},
	fangula = {Loop = {"flutter", 0.8, 0.5}},
	vex = {Steps = {"mil", "mil"}, Pitch = 1.0, Vol = 0.85, Layer = {"clank", 1.3, 0.35, 1}},
	vapor = {Steps = {"robolight", "stone"}, Pitch = 1.3, Vol = 0.8},
	kage = {Steps = {"stone", "stone"}, Pitch = 1.5, Vol = 0.3},
	oni = {Steps = {"heavy7", "heavy7"}, Pitch = 0.5, Vol = 1.15, Layer = {"clank", 0.6, 0.5, 1}},
	sb9000 = {Steps = {"robo", "robo"}, Pitch = 0.8, Vol = 1.0, Layer = {"servo", 1.0, 0.35, 1}},
	model7 = {Steps = {"robolight", "robolight"}, Pitch = 1.0, Vol = 0.8, Layer = {"servo", 1.6, 0.25, 2}},
	scorch = {Steps = {"mech", "clank"}, Pitch = 0.8, Vol = 0.95},
	magmor = {Steps = {"heavy6", "heavy6"}, Pitch = 0.42, Vol = 1.2, Layer = {"stone", 0.5, 0.6, 1}},
	nova = {Steps = {"boot", "boot"}, Pitch = 0.7, Vol = 0.9, Layer = {"flutter", 1.4, 0.4, 1}},
	zorp = {Steps = {"squish", "squish"}, Pitch = 1.3, Vol = 0.8},
	dex = {Steps = {"splash", "boot"}, Pitch = 0.6, Vol = 0.9},
	tridentus = {Steps = {"splash", "splash"}, Pitch = 0.95, Vol = 0.8, Layer = {"heavy2", 0.8, 0.5, 1}},
	mumbles = {Steps = {"sand", "sand"}, Pitch = 0.8, Vol = 0.8, Layer = {"cloth", 0.9, 0.3, 2}},
	anubis = {Steps = {"sand", "sand"}, Pitch = 1.1, Vol = 0.8, Layer = {"hoof", 0.7, 0.4, 2}},
	peppermint = {Steps = {"clank", "candy"}, Pitch = 1.25, Vol = 0.85},
	bonbon = {Steps = {"crunch", "crunch"}, Pitch = 1.0, Vol = 0.8, Layer = {"candy", 1.6, 0.3, 2}},
	pemberton = {Steps = {"snow", "snow"}, Pitch = 1.3, Vol = 0.8, Layer = {"squeak", 2.2, 0.15, 4}},
	yuki = {Steps = {"snowstomp", "snowstomp"}, Pitch = 0.6, Vol = 1.0, Layer = {"heavy1", 0.5, 0.5, 1}},
	sheriff = {Steps = {"concrete", "hoof"}, Pitch = 0.9, Vol = 0.9, Layer = {"clatter", 1.7, 0.2, 1}},
	rattler = {Steps = {"sand", "sand"}, Pitch = 1.3, Vol = 0.7, Layer = {"rattle", 1.5, 0.45, 3}},
	tiki = {Steps = {"thud", "woodknock"}, Pitch = 0.75, Vol = 1.0},
	itza = {Steps = {"stone", "stone"}, Pitch = 1.2, Vol = 0.55, Layer = {"cloth", 1.2, 0.25, 2}},
	wobbles = {Steps = {"duck", "duck"}, Pitch = 1.0, Vol = 0.75, Layer = {"boing", 1.5, 0.3, 4}},
	taurus = {Steps = {"hoof", "hoof"}, Pitch = 0.6, Vol = 1.1, Layer = {"heavy7", 0.6, 0.6, 1}},
	jenny = {Loop = {"rocket", 1.2, 0.35}},
	ironclad = {Steps = {"rattlebody", "rattlebody"}, Pitch = 0.7, Vol = 1.0, Layer = {"servo", 0.6, 0.4, 1}},
	moe = {Steps = {"sand", "crunch"}, Pitch = 1.5, Vol = 0.7},
	lumina = {Steps = {"clank", "woodknock"}, Pitch = 1.8, Vol = 0.5, Layer = {"candy", 2.0, 0.3, 1}},
	chronos = {Steps = {"tick", "tick"}, Pitch = 1.0, Vol = 0.8, Layer = {"cloth", 0.8, 0.3, 2}},
	gamemaster = {Loop = {"plasma", 0.6, 0.5}},
}

return K

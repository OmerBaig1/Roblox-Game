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
	  Sink  body studs the whole body goes DOWN, through the floor on purpose (the hammerhead swimming under the
	        deck). The only thing that ever lowers a guard below the floor.
	  Wing, Fold  for guards with wing joints (LeftWing/RightWing Motor6Ds): flap angle (+ = up) and how far the wings
	        are swept back (1 = folded against the back).
	FX[key] (optional): what the guard's equipment gives off while it moves (GuardMotion draws it): jets from a
	jetpack, water from boots, wisps from a robe hem, the shark's fin cutting the water.
	Signs: -X on Root leans forward, +X on a hip or shoulder swings that limb forward, on the left shoulder -Z lifts
	the arm out to the side (+Z on the right). Positive Root Z leans to the guard's left.

	SOLVER (K.solve). Turns a pose into joint transforms: clamps every limb to its safe range (no arm swinging into
	the chest, no leg through the hips), keeps planted legs where they were written, then raises or lowers the body
	so its lowest point - a heel, a toe, or the hem of a robe - sits exactly on the floor (plus any air).

	MOTION[key] = {Stride, Foot, Gait, Idle, Grab, Laugh}. Stride = studs per full cycle (two footfalls) at
	scale 1; Foot = phase of the first footfall. Gait(p, phase, s) with s.Run (1 chasing, ~0.6 walking home) and s.T;
	Idle(p, t); Grab(p, age) plays right after a catch (the catch itself is decided on the server first); Laugh(p, age) plays after a catch (~1.9 s).

	AUDIO[key] = the guard's own running sound: two footfall sounds (left, right), pitch, volume, an optional layer
	(armour clank, squeak, servo...) every N steps, or a Loop for the ones that float.
]]

local K = {}

local V = Vector3.new
local ZERO = Vector3.zero
local sin, cos, abs, pi, clamp, max, min, floor = math.sin, math.cos, math.abs, math.pi, math.clamp, math.max, math.min, math.floor

K.KEYS = {"Root", "Neck", "LS", "RS", "LH", "RH"}
K.JOINTS = {Root = "Root", Neck = "Neck", LS = "LeftShoulder", RS = "RightShoulder", LH = "LeftHip", RH = "RightHip"}
-- optional: a rig with split limbs (LeftShin on a LeftKnee joint, LeftForearm on a LeftElbow...). In a pose LK/RK/LE/RE are how
-- far that joint bends (radians, 0 = as modelled); knees bend the shin back, elbows the forearm forward
K.EXTRA = {LK = "LeftKnee", RK = "RightKnee", LE = "LeftElbow", RE = "RightElbow"}
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
	return {Root = ZERO, Neck = ZERO, LS = ZERO, RS = ZERO, LH = ZERO, RH = ZERO, Off = ZERO, Free = 0, Sink = 0, Wing = 0, Fold = 1, LK = 0, RK = 0, LE = 0, RE = 0}
end

-- a = a blended toward b by w (in place)
function K.blend(a, b, w)
	for _, k in ipairs(K.KEYS) do
		a[k] = a[k]:Lerp(b[k], w)
	end
	a.Off = a.Off:Lerp(b.Off, w)
	for _, k in ipairs({"Free", "Sink", "Wing", "Fold", "LK", "RK", "LE", "RE"}) do
		a[k] = a[k] + (b[k] - a[k]) * w
	end
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
			for key, name in pairs(K.EXTRA) do
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
		local kn = J[key == "LH" and "LK" or "RK"]
		local s = (kn and kn.Part1 or J[key].Part1).Size
		rig.Feet[key] = {V(0, -s.Y / 2, 0), V(0, -s.Y / 2, -s.Z * 0.35), V(0, -s.Y / 2, s.Z * 0.35)}
	end
	-- four-legged rigs (model attribute Quad): the front paws (the arms) touch the floor too
	rig.Quad = model:GetAttribute("Quad") == true
	if rig.Quad then
		rig.Hands = {}
		for _, key in ipairs({"LS", "RS"}) do
			local s = J[key].Part1.Size
			rig.Hands[key] = {V(0, -s.Y / 2, 0), V(0, -s.Y / 2, -s.Z * 0.35), V(0, -s.Y / 2, s.Z * 0.35)}
		end
	end
	local ts = J.Root.Part1.Size
	rig.Hem = {V(0, -ts.Y / 2, 0), V(0, -ts.Y / 2, -ts.Z * 0.35), V(0, -ts.Y / 2, ts.Z * 0.35), V(ts.X * 0.35, -ts.Y / 2, 0), V(-ts.X * 0.35, -ts.Y / 2, 0)}
	rig.Rest = K.lowest(rig, CFrame.identity, {LH = CFrame.identity, RH = CFrame.identity}, {LS = CFrame.identity, RS = CFrame.identity})
	rig.RestFeet = K.feet(rig, CFrame.identity, {LH = CFrame.identity, RH = CFrame.identity})
	return rig
end

-- the lowest point of the body (in root space) for a body rotation and the two hip transforms (and, on a Quad
-- rig, the two shoulder transforms: its front paws stand on the floor as well)
local KNEE = {LH = "LK", RH = "RK"}
-- a leg's lowest piece (the shin on a split leg, the whole leg otherwise) in root space
local function legEnd(rig, torso, hips, knees, key)
	local leg = torso * rig.C0[key] * hips[key] * rig.C1i[key]
	local kn = KNEE[key]
	if rig.J[kn] then
		leg = leg * rig.C0[kn] * (knees and knees[kn] or CFrame.identity) * rig.C1i[kn]
	end
	return leg
end
function K.lowest(rig, R, hips, arms, knees)
	local torso = rig.C0.Root * R * rig.C1i.Root
	local low = math.huge
	if rig.Hands and arms then
		for _, key in ipairs({"LS", "RS"}) do
			local arm = torso * rig.C0[key] * arms[key] * rig.C1i[key]
			for _, pt in ipairs(rig.Hands[key]) do
				low = min(low, (arm * pt).Y)
			end
		end
	end
	for _, key in ipairs({"LH", "RH"}) do
		local leg = legEnd(rig, torso, hips, knees, key)
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
function K.feet(rig, R, hips, knees)
	local torso = rig.C0.Root * R * rig.C1i.Root
	local f = {}
	for _, key in ipairs({"LH", "RH"}) do
		f[key] = legEnd(rig, torso, hips, knees, key) * rig.Feet[key][1]
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
	local arms = {LS = euler(clampv(p.LS, K.LIMITS.LS)), RS = euler(clampv(p.RS, K.LIMITS.RS))}
	local knees = {LK = CFrame.Angles(-(p.LK or 0), 0, 0), RK = CFrame.Angles(-(p.RK or 0), 0, 0)}
	local lift = rig.Rest - K.lowest(rig, R, hips, arms, knees)
	-- foot lock: a planted body moves over its feet, so the point between them stays where it was
	local f = K.feet(rig, R, hips, knees)
	local drift = ((f.LH - rig.RestFeet.LH) + (f.RH - rig.RestFeet.RH)) / 2 * plant
	local s = rig.Scale
	out.Root = CFrame.new(p.Off.X * s - drift.X, lift + (max(p.Off.Y, 0) - (p.Sink or 0)) * s, p.Off.Z * s - drift.Z) * R
	out.LH, out.RH = hips.LH, hips.RH
	out.Neck = euler(clampv(p.Neck, K.LIMITS.Neck))
	out.LS, out.RS = arms.LS, arms.RS
	out.LK, out.RK = knees.LK, knees.RK
	out.LE, out.RE = CFrame.Angles(p.LE or 0, 0, 0), CFrame.Angles(p.RE or 0, 0, 0)
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

-- A full running stride. o: Hip (leg swing), Knee (how far the shin folds as the leg comes through), Arm (arm swing, opposite
-- the legs), ArmBase, Elbow (the bend the arms hold), ElbowSwing (more bend as the arm comes forward), Lean, Twist (shoulders
-- against hips), Roll (over the planted foot), Bounce, Spread, Head (keeps the eyes level against the lean). Rigs without
-- knees and elbows just ignore those. Each guard passes its own build: a heavy one is nothing like a light one.
local function run(p, ph, r, o)
	local a, c = sin(ph), cos(ph)
	local spread = o.Spread or 0.03
	p.LH = V((o.Hip or 0.8) * a * r + 0.06, 0, -spread)
	p.RH = V(-(o.Hip or 0.8) * a * r + 0.06, 0, spread)
	local kb, kk = o.KneeBase or 0.2, (o.Knee or 1.2) * r
	p.LK = kb + kk * max(0, c) ^ 1.5
	p.RK = kb + kk * max(0, -c) ^ 1.5
	local ab, am = o.ArmBase or 0.2, (o.Arm or 0.7) * r
	p.LS = V(ab - am * a, 0, -(o.Out or 0.14))
	p.RS = V(ab + am * a, 0, o.Out or 0.14)
	local eb, es = o.Elbow or 1.1, (o.ElbowSwing or 0.3) * r
	p.LE = eb - es * a
	p.RE = eb + es * a
	p.Root = V(-(o.Lean or 0.2) * r - 0.03 * r * cos(ph * 2), -(o.Twist or 0.1) * a * r, (o.Roll or 0.03) * a * r)
	p.Neck = V((o.Head or (o.Lean or 0.2) * 0.8) * r, (o.Twist or 0.1) * 0.6 * a * r, -(o.Roll or 0.03) * 0.6 * a * r)
	p.Off = V(0, (o.Bounce or 0.1) * r * a * a, 0)
end

-- A burrower going in or coming out (w: 0 on the surface, 1 under). In: it tips right over first, nose to the floor and hips
-- high, and only then sinks, so the head goes under first and the legs last. Out: it rights itself while still under and
-- then rises, so the head breaks the surface first. a = the pose so far, g = the underground pose.
function K.dive(a, g, w, goingIn)
	local sink = g.Sink
	if goingIn then
		K.blend(a, g, ease(w / 0.5))
		a.Sink = sink * ease((w - 0.45) / 0.55)
	else
		K.blend(a, g, ease((w - 0.55) / 0.45))
		a.Sink = sink * ease(w / 0.6)
	end
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
		p.RS += V(0.22 * sin(ph) * s.Run, 0, 0)
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

-- 8 Brineback: a hammerhead first mate. He stands on the flooded deck at rest, arms on hips. The moment he moves he
-- dives: the whole body goes under the deck and only his dorsal fin (FX "fin") cuts through the water after you,
-- trailing ripples, spray and bubbles. The grab is him bursting up out of the water in front of you, jaws first;
-- he slaps his knee laughing. He swims home the same way.
M.brine = {Stride = 9, Dive = true,
	Gait = function(p, ph, s)
		-- he dives like the predator he is: arcs over nose first and is gone, only the fin and the moving earth left
		p.Sink = 8
		p.Root = V(-1.95, 0, 0.05 * sin(ph))
		arms(p, V(-0.5, 0, -0.35), V(-0.5, 0, 0.35))
		p.Free = 1
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.2), V(0, 0, 0.2)
		p.Root = V(0.02 * sin(t * 0.8 + 1), 0, 0.06 * sin(t * 0.8))
		arms(p, V(0.15, 0.1, -0.45), V(0.15, -0.1, 0.45))
		p.Neck = V(0, 0.3 * sin(t * 0.35), -0.05 * sin(t * 0.8))
	end,
	Grab = function(p, a)
		-- the surge: up out of the water in ~0.15 s, rearing back with the jaws open and arms thrown wide, then
		-- dropping onto you
		local up = ease(a / 0.15)
		local arc = sin(clamp(a / 0.5, 0, 1) * pi)
		p.Sink = 6 * (1 - up)
		p.Off = V(0, 0.9 * arc, 0)
		p.Root = V(0.35 * arc - 0.3 * ease((a - 0.3) / 0.2), 0, 0)
		p.Neck = V(0.4 * arc, 0, 0)
		arms(p, V(1.2 * up, 0, -0.9 * arc - 0.2), V(1.2 * up, 0, 0.9 * arc + 0.2))
		p.LH, p.RH = V(-0.3 * arc, 0, -0.1), V(-0.3 * arc, 0, 0.1)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Root = V(-0.15 * inn, 0, 0)
		p.Neck = V(0.5 * inn, 0, 0)
		p.RS = V((0.5 + 0.35 * max(0, sin(a * 12))) * inn, 0, 0.25)
		p.LS = V(0.4 * inn, 0, -0.35)
		p.LH, p.RH = V(0, 0, -0.2), V(0, 0, 0.2)
	end}


-- 9 Mortimer, the Grim Reaper: Death never runs. It floats a hand's breadth off the crypt floor at a steady height
-- (no bobbing: the robe trails wisps from its hem, FX "wisps"), leaning toward you with its free hand reaching and the
-- scythe held upright and still in the other (the scythe is part of that arm's mesh, so that arm stays near rest).
-- Its legs are inside the robe and never move. The grab: the bony hand sweeps in and snaps shut. A whispered laugh,
-- head tilting.
M.mortimer = {Stride = 9,
	Gait = function(p, ph, s)
		local r = s.Run
		p.Off = V(0, 0.45, 0)
		p.Root = V(-0.2 * r, 0, 0.025 * sin(s.T * 1.1))
		p.LS = V(0.95 * r, 0.15, -0.3)
		p.RS = V(0.15, 0, 0.12)
		p.Neck = V(0.15 * r, 0, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.Off = V(0, 0.3, 0)
		p.LS = V(0.15, 0, -0.12)
		p.RS = V(0.1, 0, 0.1)
		p.Root = V(-0.06, 0, 0)
		p.Neck = V(0.18, 0.4 * sin(t * 2 * pi / 16), 0)
		p.Free = 1
	end,
	Grab = function(p, a)
		local reach = ease((a - 0.02) / 0.14)
		local close = ease((a - 0.16) / 0.1)
		p.Off = V(0, 0.3, 0)
		p.Root = V(-0.32 * reach, 0, 0)
		p.LS = V(1.3 * reach - 0.2 * close, 0.15 * (1 - close), -0.3)
		p.RS = V(0.15 + 0.25 * reach, 0, 0.12)
		p.Neck = V(0.3 * reach, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Off = V(0, 0.3 + 0.2 * inn, 0)
		p.Root = V(0.1 * inn, 0, 0)
		p.Neck = V(0.3 * inn, 0, 0.25 * inn)
		p.LS = V(0.5 * inn, 0, -0.3 - 0.4 * inn)
		p.RS = V(0.1, 0, 0.1)
		p.Free = 1
	end}


-- 10 Count Fangula: a predator in evening dress. He hunts: long, low, gliding strides with very little bounce, body
-- pitched into the run, head thrust forward and fixed on you, both clawed hands reaching ahead, one a little further
-- with each stride, the cape streaming behind him. At rest he stands tall and still, hands low at his sides, head
-- tilting as he studies you. The grab: arms sweep wide, then clamp; the laugh: the classic "mwahaha", head back, arms spread.
M.fangula = {Stride = 9.5,
	Gait = function(p, ph, s)
		-- he flies: laid forward and low like a drawn blade, legs trailing together, coat streaming, one clawed hand
		-- reaching ahead and the other swept back. A slow supernatural sway, never a flap or a bob: he is carried
		local r, t = s.Run, s.T
		p.Off = V(0, 1.05 + 0.05 * sin(t * 1.5), 0)
		p.Root = V(-0.72 * r, 0, 0.06 * sin(t * 0.9))
		p.LH = V(-0.16 + 0.04 * sin(t * 1.1), 0, -0.03)
		p.RH = V(-0.3 + 0.04 * sin(t * 1.1 + 1), 0, 0.03)
		p.RS = V(1.3 + 0.08 * sin(t * 1.9), -0.1, 0.1)
		p.LS = V(-0.45 + 0.08 * sin(t * 1.3), 0, -0.4)
		p.Neck = V(0.55 * r, 0.06 * sin(t * 0.7), -0.04 * sin(t * 0.9))
		p.Free = 1
	end,
	Idle = function(p, t)
		-- even at rest his boots never quite touch the floor
		p.Off = V(0, 0.3 + 0.04 * sin(t * 1.1), 0)
		arms(p, V(0.08 + 0.02 * sin(t * 0.9), 0, -0.08), V(0.08 + 0.02 * sin(t * 0.9 + 0.5), 0, 0.08))
		p.LH, p.RH = V(-0.04, 0, -0.02), V(-0.08, 0, 0.02)
		breathe(p, t, 0.7, 0.9)
		p.Neck += V(0.05, 0.3 * sin(t * 2 * pi / 11), 0.12 * sin(t * 0.37))
		p.Free = 1
	end,
	Grab = function(p, a)
		local flare = ease(a / 0.1) * (1 - ease((a - 0.12) / 0.15))
		local k = ease((a - 0.08) / 0.16)
		arms(p, V(1.35 * k, 0, -1.2 * flare - 0.2), V(1.35 * k, 0, 1.2 * flare + 0.2))
		p.Root = V(-0.6 + 0.25 * k, 0, 0)
		p.Neck = V(0.3 * k, 0, 0)
		p.LH, p.RH = V(-0.1, 0, -0.03), V(-0.2, 0, 0.03)
		p.Off = V(0, 1.0 - 0.6 * k, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.18, Shake = 0.03, Rate = 9, Head = 0.5})
		arms(p, V(0.4 * inn, 0, -0.25 - 1.0 * inn), V(0.4 * inn, 0, 0.25 + 1.0 * inn))
		p.Off = V(0, 0.4, 0)
		p.LH, p.RH = V(-0.04, 0, -0.02), V(-0.08, 0, 0.02)
		p.Free = 1
	end}


-- 11 Unit Vex: a by-the-book riot enforcer in a full sprint: long powerful strides, arms driving opposite the legs
-- in tight arcs, body leaning into the run with the head held level on the target (the neck counters the lean), a
-- small counter-twist of the torso with each stride and a clean flight phase. At rest the visor sweeps the hall.
-- An arrest of a grab; a clipped, synthetic laugh.
M.vex = {Stride = 7.5,
	Gait = function(p, ph, s)
		-- a trained sprinter: tall, balanced, knees driving, arms pumping hard from the shoulder with the elbows bent
		run(p, ph, s.Run, {Hip = 0.82, Knee = 1.4, Arm = 0.8, ArmBase = 0.18, Elbow = 1.35, ElbowSwing = 0.35, Lean = 0.2, Twist = 0.13, Roll = 0.02, Bounce = 0.1})
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.05), V(0, 0, 0.05)
		arms(p, V(0.15, 0, -0.15), V(0.35, -0.2, 0.12))
		breathe(p, t, 0.8, 1.1)
		scan(p, t, 0.6, 9)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.6, Lean = 0.3})
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.1, Shake = 0.03, Rate = 16, Head = 0.25})
		arms(p, V(0.25, 0, -0.2), V(0.25 + 0.3 * inn, 0, 0.2))
	end}


-- 12 Vapor: a cybernetic wolf on four legs (a Quad rig: the arms are its front legs and their paws stand on the
-- floor). It runs in a rotary gallop: the hind legs strike a beat apart, then the fore legs, the back rocking with
-- each bound and the head held low and level on the prey. At rest it stands square, sniffing the air, ears turning.
-- The grab is a pounce, forelegs up and jaws first; the laugh is a howl, head thrown back.
M.vapor = {Stride = 10,
	Gait = function(p, ph, s)
		local r = s.Run
		p.LH = V(0.6 * sin(ph) * r, 0, 0)
		p.RH = V(0.6 * sin(ph + 0.5) * r, 0, 0)
		p.LS = V(0.65 * sin(ph + pi) * r, 0, 0)
		p.RS = V(0.65 * sin(ph + pi + 0.5) * r, 0, 0)
		p.Root = V(0.07 * sin(ph * 2 + 0.6) * r, 0, 0)
		p.Neck = V(-0.12 * r - 0.05 * sin(ph * 2) * r, 0, 0)
		p.Off = V(0, 0.18 * max(0, sin(ph * 2 - 0.4)) * r, 0)
	end,
	Idle = function(p, t)
		local sniff = pulse(t, 6, 1.2)
		p.Neck = V(0.12 * sniff + 0.03 * sin(t * 8) * sniff, 0.35 * sin(t * 2 * pi / 9), 0)
		breathe(p, t, 0.6, 1.4)
		p.LS, p.RS = V(0, 0, -0.03), V(0, 0, 0.03)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.02) / 0.15)
		local arc = sin(clamp(a / 0.45, 0, 1) * pi)
		p.Root = V(0.35 * arc - 0.2 * ease((a - 0.3) / 0.15), 0, 0)
		p.LS, p.RS = V(1.3 * k, 0, -0.1), V(1.3 * k, 0, 0.1)
		p.LH, p.RH = V(-0.5 * k, 0, 0), V(-0.5 * k, 0, 0)
		p.Neck = V(-0.25 * k, 0, 0)
		p.Off = V(0, 0.7 * arc, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.Neck = V(0.75 * inn, 0, 0)
		p.Root = V(0.12 * inn, 0, 0)
		p.LS, p.RS = V(0, 0, -0.03), V(0, 0, 0.03)
	end}


-- 13 Kage: an assassin. At rest he stands poised and still, the katana sheathed across his back, handle between his
-- shoulders. When a chase starts he reaches back, takes the handle and draws that same sword straight out of
-- the sheath (K.draw: the one katana, moved by the hand that holds it; the sheath stays on his back, empty), then runs
-- low and fast, left arm swept behind, blade held out ahead. It goes back the same way when the chase is over. A
-- lightning slash of a grab; a silent shoulder-shaking chuckle.
M.kage = {Stride = 8,
	Carry = {Joint = "Gear_KatanaJoint", Draw = true},
	Taunt = function(p, age)
		local k = ease(age / 0.2) * (1 - ease((age - 0.7) / 0.2))
		p.LS = V(0.5 * k, 0, -0.35 * k - 0.1)
		p.RS = V(0.55, -0.2, 0.25)
		p.Root = V(-0.1 * k, 0.2 * k, 0)
		p.Neck = V(0.08 * k, -0.2 * k, 0)
		p.LH, p.RH = V(0.3 * k, 0, -0.04), V(-0.22 * k, 0, 0.04)
	end,
	Gait = function(p, ph, s)
		-- a ninja's run: low, long and quiet, the knees folding high behind him; the left arm pumps with the stride and
		-- the right holds the blade out ahead, moving with the shoulders (its elbow is K.draw's)
		local r = s.Run
		run(p, ph, r, {Hip = 0.86, Knee = 1.55, Arm = 0.7, ArmBase = -0.05, Elbow = 1.2, ElbowSwing = 0.4, Lean = 0.36, Twist = 0.14, Roll = 0.03, Bounce = 0.14, Head = 0.3})
		p.RS = V(0.6 + 0.16 * sin(ph) * r, -0.2, 0.25)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0.04, 0, -0.08), V(-0.04, 0, 0.08)
		arms(p, V(0.08, 0, -0.1), V(0.08, 0, 0.1))
		breathe(p, t, 0.5, 1.0)
		p.Neck += V(0.03, 0.25 * sin(t * 2 * pi / 14), 0)
	end,
	Grab = function(p, a)
		local up = ease(a / 0.08) * (1 - ease((a - 0.1) / 0.1))
		local k = ease((a - 0.08) / 0.12)
		p.RS = V(0.55 + 1.3 * up + 0.5 * k, -0.2, 0.25)
		p.LS = V(1.0 * k, 0, -0.25)
		p.Root = V(-0.42 * k, 0.2 * k, 0)
		p.LH, p.RH = V(0.6 * k, 0, -0.04), V(-0.42 * k, 0, 0.04)
		p.Neck = V(0.22 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 16)
		arms(p, V(0.2 * inn, 0, -0.16 - 0.05 * k * inn), V(0.55 * inn, -0.2 * inn, 0.25 + 0.04 * k * inn))
		p.Neck = V(0.15 * inn, 0, 0)
		p.Root = V(0.05 * inn, 0, 0)
	end}


-- 14 Taiho, the Oni Samurai: an armoured giant at full charge. Every stride carries weight: the planted leg takes it
-- and the whole body drops and rolls over that foot, then drives forward off it; armoured shoulders swing against the
-- hips, the free arm pumps hard, the club stays high in his right fist, the head low and thrust forward. At rest: a
-- wide planted stance, club held ready, huge slow breaths. The grab is an overhead club slam; he laughs with the club raised.
M.oni = {Stride = 9,
	Gait = function(p, ph, s)
		-- all weight: wide heavy strides, the body drops and rolls over each planted foot and the armoured shoulders swing
		-- against the hips; the free arm pumps hard and the club rides with the shoulder, ready to come down
		local r = s.Run
		local a = sin(ph)
		run(p, ph, r, {Hip = 0.62, Knee = 0.95, KneeBase = 0.3, Arm = 0.68, ArmBase = 0.25, Elbow = 0.95, ElbowSwing = 0.3, Lean = 0.2, Twist = 0.17, Roll = 0.1, Bounce = 0.05, Spread = 0.1, Head = 0.14, Out = 0.2})
		p.RS = V(0.35 + 0.25 * a * r, 0, 0.12)
		p.RE = 0.8 + 0.2 * a * r
		p.Off = V(0, 0.09 * r * cos(ph) ^ 4, 0)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.18), V(0, 0, 0.18)
		p.RS = V(0.05 + 0.02 * sin(t * 0.9), 0, 0.02)
		p.LS = V(0.15, 0, -0.18)
		breathe(p, t, 2.2, 0.8)
		scan(p, t, 0.35, 14)
	end,
	Grab = function(p, a)
		local up = ease(a / 0.1) * (1 - ease((a - 0.12) / 0.12))
		local k = ease((a - 0.1) / 0.14)
		p.RS = V(1.3 * up + 0.95 * k, 0, 0.1)
		p.LS = V(0.9 * k, 0, -0.3)
		p.Root = V(0.14 * up - 0.42 * k, 0.15 * k, 0)
		p.LH, p.RH = V(0.45 * k, 0, -0.14), V(-0.35 * k, 0, 0.14)
		p.Neck = V(0.22 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn, k = laugh(p, a, {Back = 0.22, Shake = 0.05, Rate = 9, Head = 0.55})
		p.RS = V((0.9 + 0.1 * k) * inn, 0, 0.1)
		p.LS = V(0.3 * inn, 0, -0.35)
		p.LH, p.RH = V(0, 0, -0.18), V(0, 0, 0.18)
	end}


-- 15 SB-9000: an industrial security mech. At rest it stands and its head turns in fixed clicks. It doesn't run after
-- thieves: it lifts off on its twin-thruster jetpack (FX "jet" from the nozzles) and flies at you a body's height off
-- the floor, leaning into the thrust, legs hanging together, arms out for balance. Lift-off and touch-down follow the
-- gait weight, so it rises as it sets off and lands as it stops. A hydraulic clamp of a grab; laughs in three flat steps.
M.sb9000 = {Stride = 12,
	Gait = function(p, ph, s)
		local r = s.Run
		p.Off = V(0, 1.1, 0)
		p.Root = V(-0.32 * r, 0, 0)
		p.LH, p.RH = V(-0.25, 0, -0.04), V(-0.3, 0, 0.04)
		arms(p, V(0.3, 0, -0.55), V(0.3, 0, 0.55))
		p.Neck = V(0.25 * r, 0, 0)
		p.Free = 1
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
		p.Off = V(0, 0.6 * (1 - k), 0)
		p.Free = 1
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

-- 17 Sir Scorch, the Dragon Knight: at rest he stands guard with his flame sword, wings folded against his back.
-- Chasing, he doesn't run: the wings sweep open and beat, carrying him just above the floor, sword arm forward,
-- legs trailing. Each downstroke lifts him a little and the upstroke lets him settle, so the height follows the
-- wings and nothing else (FX "embers" stream off the wings and blade). The grab: a wingbeat surge and a mailed
-- fist; a roaring laugh, sword raised, wings flared.
local FLAP = 6.5 -- wingbeats, radians a second
M.scorch = {Stride = 12,
	Gait = function(p, ph, s)
		local r = s.Run
		local beat = sin(s.T * FLAP)
		p.Wing = 0.15 + 0.6 * beat
		p.Fold = 0
		p.Off = V(0, 0.55 + 0.1 * -cos(s.T * FLAP), 0) -- rises on the downstroke (when the wings come down)
		p.Root = V(-0.3 * r, 0, 0)
		p.LH, p.RH = V(-0.35, 0, -0.04), V(-0.2, 0, 0.04)
		p.LS = V(0.6, -0.3, -0.25)
		p.RS = V(0.9, 0, 0.3)
		p.Neck = V(0.25 * r, 0, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.Fold = 1
		p.Wing = 0.05 * sin(t * 0.8)
		p.LS = V(0.9, -0.35, -0.1)
		p.RS = V(0.35, 0, 0.2)
		p.LH, p.RH = V(0.15, 0, -0.08), V(-0.1, 0, 0.08)
		breathe(p, t, 0.9)
		scan(p, t, 0.25, 11)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.3})
		p.RS = V(0.35 + 0.9 * k, 0, 0.3)
		p.Fold = 0
		p.Wing = 0.7 - 1.2 * k
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.12, Shake = 0.03, Rate = 10, Head = 0.45})
		p.RS = V(0.35 + 2.45 * inn, 0, 0.3)
		p.LS = V(0.9, -0.35, -0.1)
		p.Fold = 1 - inn
		p.Wing = 0.5 * inn
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

-- 19 Commander Nova: a space ranger who moves like he's still on the Moon. Long, slow, floating bounds: each push-off
-- carries him up in a smooth arc and he lands on the leading foot, arms out for balance, with a soft puff from his
-- suit's thrusters (FX "jet", small and blue) as he pushes. Nothing flips, nothing goes below the floor. At rest he
-- drifts on his toes and waves; a careful two-handed grab; laughs floating up with his arms raised, then settles.
M.nova = {Stride = 13, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		local h = a * a -- 0 at each landing, 1 at the top of the bound: smooth both ways
		p.LH, p.RH = V(0.75 * a * r, 0, -0.08), V(-0.75 * a * r, 0, 0.08)
		arms(p, V(0.25 - 0.35 * a, 0, -0.7 - 0.2 * h), V(0.25 + 0.35 * a, 0, 0.7 + 0.2 * h))
		p.Root = V(-0.14 * r + 0.06 * h, 0, 0)
		p.Neck = V(0.08, 0, 0)
		p.Off = V(0, 1.4 * h * r, 0)
	end,
	Idle = function(p, t)
		p.Off = V(0, 0.12 + 0.04 * sin(t * 0.9), 0)
		p.Root = V(0.03 * sin(t * 0.5), 0, 0.03 * sin(t * 0.7))
		local wave = pulse(t, 9, 2.5)
		p.RS = V(0.1 + 0.15 * sin(t * 6) * wave, 0, 0.2 + 2.0 * clamp(wave * 1.5, 0, 1))
		p.LS = V(0.1, 0, -0.35)
		p.LH, p.RH = V(0.06 * sin(t * 0.9), 0, -0.05), V(-0.06 * sin(t * 0.9), 0, 0.05)
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.25, Speed = 0.24})
		p.Off = V(0, 0.2, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 9)
		p.Off = V(0, 0.9 * inn, 0)
		p.Root = V(0.12 * inn, 0, 0.04 * k * inn)
		p.Neck = V(0.4 * inn, 0, 0)
		arms(p, V(0.4 * inn, 0, -0.4 - 1.6 * inn), V(0.4 * inn, 0, 0.4 + 1.6 * inn))
		p.LH, p.RH = V(-0.2 * inn, 0, -0.1), V(0.15 * inn, 0, 0.1)
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

-- 21 Dex, the deep-sea diver: on land he stands heavy in his brass helmet and weighted boots. Chasing, he swims through
-- the air as if it were the deep, in a real front crawl: laid out flat and streamlined, one arm reaching far ahead and
-- pulling down and back under the body while the other comes back over the top, out to the side; the whole body rolls
-- toward the pulling arm, each pull is a small surge, the hips rise and fall, the legs flutter from the hip with the
-- feet trailing, and the head stays up with a turn to breathe every other stroke. Bubbles rise from his helmet valve
-- (FX "bubbles"). He drops upright to grab; a gurgling laugh.
local function crawl(x, side)
	local u = (x % (2 * pi)) / (2 * pi)
	if u < 0.55 then -- the pull: from full reach down and back to the hip
		return V(3.0 - 3.1 * ease(u / 0.55), 0, side * 0.1)
	end
	local k = (u - 0.55) / 0.45 -- the recovery: out of the "water" and round the side
	return V(-0.1 + 3.1 * ease(k), 0, side * (0.1 + 1.9 * sin(k * pi)))
end
M.dex = {Stride = 15, Foot = 0,
	Gait = function(p, ph, s)
		local r = clamp(s.Run, 0.7, 1)
		local a = sin(ph)
		p.Root = V(-1.28 + 0.05 * sin(ph * 2), 0.34 * a * r, 0)
		p.Off = V(0, 1.42 + 0.12 * abs(a), 0)
		p.LS = crawl(ph, -1)
		p.RS = crawl(ph + pi, 1)
		p.LH = V(-0.12 + 0.3 * r * sin(ph * 3), 0, -0.05)
		p.RH = V(-0.12 - 0.3 * r * sin(ph * 3), 0, 0.05)
		p.Neck = V(0.72, 0.4 * max(0, sin(ph * 0.5)) ^ 3, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		arms(p, V(0.3 + 0.08 * sin(t * 1.1), 0, -0.3), V(0.3 + 0.08 * sin(t * 1.1 + 1), 0, 0.3))
		breathe(p, t, 1.6, 0.8)
		p.Neck += V(0.08, 0.3 * sin(t * 0.4), 0)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.02) / 0.18)
		p.Root = V(-1.25 + 0.75 * k, 0, 0)
		p.Off = V(0, 1.4 * (1 - k), 0)
		p.LS = V(2.4 - 1.0 * k, 0, -0.9 + 0.6 * k)
		p.RS = V(2.4 - 1.0 * k, 0, 0.9 - 0.6 * k)
		p.Neck = V(0.7 - 0.4 * k, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.12, Shake = 0.04, Rate = 9, Head = 0.3})
		p.RS = V(1.4 * inn, 0, 0.2)
		p.LS = V(0.2, 0, -0.4)
	end}


-- 22 King Tridentus, Lord of the Sea, rides his royal seahorse (Gear_Mount, fixed to his torso: they move as one).
-- He sits astride it always, legs around its body, left hand on the reins at its neck, trident in his right. At
-- rest the seahorse sways gently in place and he surveys his kingdom. Chasing, the seahorse surges after you in
-- strong rhythmic pulses - it rocks forward and rises a little with each push, the king leaning into it, trident
-- driven forward - with foam boiling up beneath it (FX "wave"). He pins you with the trident; a booming laugh,
-- trident raised to the heavens.
local function seated(p)
	p.LH, p.RH = V(0.3, 0, -0.42), V(0.3, 0, 0.42)
	p.LS = V(0.75, 0.2, -0.15)
	p.Free = 1
end
M.tridentus = {Stride = 14, Foot = 0,
	Gait = function(p, ph, s)
		-- a seahorse swims: slow rhythmic surges, its whole body rocking, the rider moving with it. His trident is always
		-- working: levelled at you, raised and turned in the current, then driven forward with a lean of his whole body
		local r, t = s.Run, s.T
		local push = 0.5 + 0.5 * sin(ph * 2)
		seated(p)
		p.Off = V(0, 0.3 * push * r, 0)
		local cyc = (t % 6.5) / 6.5
		local rs, lean = V(1.3, 0, 0.15), 0
		if cyc < 0.35 then
			rs = V(1.3 + 0.1 * sin(t * 2), 0, 0.15)
		elseif cyc < 0.6 then
			local k = sin(((cyc - 0.35) / 0.25) * pi)
			rs = V(1.3 + 1.4 * k, 0.5 * sin(t * 3) * k, 0.15 + 0.1 * k)
		else
			local k = sin(clamp((cyc - 0.6) / 0.28, 0, 1) * pi)
			rs = V(1.3 + 0.45 * k, 0, 0.1)
			lean = 0.22 * k
		end
		p.RS = rs
		p.Root = V(-0.14 * r - 0.05 * push - lean, 0, 0.03 * sin(t * 0.8))
		p.Neck = V(0.06 + lean * 0.6, 0, 0)
	end,
	Idle = function(p, t)
		seated(p)
		p.Off = V(0, 0.05 + 0.04 * sin(t * 1.4), 0)
		p.Root = V(0.02 * sin(t * 1.4 + 0.6), 0, 0.02 * sin(t * 0.7))
		p.RS = V(0.35, 0, 0.25)
		p.Neck = V(-0.1, 0.35 * sin(t * 2 * pi / 14), 0)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.03) / 0.16)
		seated(p)
		p.Root = V(-0.3 * k, 0, 0)
		p.RS = V(0.4 + 1.2 * k, 0, 0.12)
		p.Neck = V(0.15 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.18, Shake = 0.04, Rate = 9, Head = 0.5})
		seated(p)
		p.RS = V(0.3 + 2.5 * inn, 0, 0.12)
	end}



-- 23 Mumbles, the tomb mummy: three thousand years stiff. He lurches: the left leg steps, the right drags stiff
-- behind it (each step a dull footfall, each drag a scrape of linen - AUDIO), the whole body pitching and rolling
-- over the stepping leg, both arms held out straight, reaching, the head lolling to one side. At rest he sways
-- where he stands, arms half raised, head hanging. The grab: a sudden lunge, both hands closing; a wheezing laugh.
M.mumbles = {Stride = 4.2, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		local step = max(0, a)
		p.LH = V((0.55 * a + 0.05) * r, 0, -0.04)
		p.RH = V((-0.25 + 0.15 * a) * r, 0, 0.06)
		p.Root = V(-0.14 - 0.06 * step, 0.08 * a * r, -0.1 * a * r)
		arms(p, V(1.4 + 0.08 * sin(ph * 2), 0, -0.12), V(1.35 + 0.08 * sin(ph * 2 + 1), 0, 0.12))
		p.Neck = V(0.12, 0.05 * a, 0.22)
		p.Off = air(ph, 0.03 * r)
		p.LS += V(-0.28 * sin(ph) * s.Run, 0, 0)
		p.RS += V(0.28 * sin(ph) * s.Run, 0, 0)
	end,
	Idle = function(p, t)
		p.Root = V(-0.05, 0, 0.05 * sin(t * 0.7))
		arms(p, V(0.75 + 0.06 * sin(t * 0.9), 0, -0.12), V(0.7 + 0.06 * sin(t * 0.9 + 1), 0, 0.12))
		p.Neck = V(0.18, 0.12 * sin(t * 0.4), 0.2 + 0.05 * sin(t * 0.7))
	end,
	Grab = function(p, a)
		grab(p, a, {Reach = 1.5, Lean = 0.38, Stance = 0.5, Out = 0.12})
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 7)
		p.Root = V((0.1 + 0.03 * k) * inn, 0, 0.06 * k * inn)
		p.Neck = V((0.3 + 0.05 * k) * inn, 0, 0.2 * inn)
		arms(p, V((0.9 + 0.2 * k) * inn, 0, -0.2), V((0.9 - 0.2 * k) * inn, 0, 0.2))
	end}


-- 24 Anubis: the jackal god walks as if the tomb is his and you are already in it: a long, measured stride, upright
-- and regal, the was-sceptre in his right hand swinging forward with each step, the left arm swinging close, the
-- head level and still. At rest he stands sentinel, sceptre grounded, head turning slowly. The grab: the sceptre
-- sweeps you in and his hand closes; he laughs with the sceptre raised, head back. Every arm angle stays close to
-- the body (the old laugh threw the arms far out to the sides, where they looked detached from the shoulders).
M.anubis = {Stride = 6.2,
	Gait = function(p, ph, s)
		-- a god does not sprint: long, upright, unhurried strides that still eat the ground, head high and still, the free
		-- arm swinging and the staff arm rising with each step as if it were being planted ahead of him
		local r = s.Run
		local a = sin(ph)
		run(p, ph, r, {Hip = 0.66, Knee = 0.9, KneeBase = 0.12, Arm = 0.5, ArmBase = 0.1, Elbow = 0.5, ElbowSwing = 0.2, Lean = 0.08, Twist = 0.07, Roll = 0.02, Bounce = 0.04, Head = 0.04})
		p.RS = V(0.25 + 0.16 * a * r, 0, 0.14)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.05), V(0, 0, 0.05)
		p.RS = V(0.25, 0, 0.18)
		p.LS = V(0.05, 0, -0.12)
		breathe(p, t, 0.9, 0.9)
		scan(p, t, 0.35, 15)
	end,
	Grab = function(p, a)
		local k = grab(p, a, {Reach = 1.5, Lean = 0.3, Out = 0.15})
		p.RS = V(0.3 + 1.1 * k, 0, 0.2)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.15, Shake = 0.03, Rate = 8, Head = 0.5})
		p.RS = V(0.3 + 1.6 * inn, 0, 0.2)
		p.LS = V(0.25 * inn, 0, -0.15 - 0.2 * inn)
	end}


-- 25 Sir Peppermint, the Candy Cane Knight: a parade-ground paladin. He charges in a high-stepping knightly march
-- (no knees, so the legs lift high and straight), candy-cane mace held upright at his shoulder, the free arm
-- swinging in time, chest out, helmet level: toy-soldier precision turned into a full charge. At rest he stands at
-- attention, mace shouldered, head snapping left and right. The grab: the mace sweeps down in a hooking arc; the
-- laugh: a booming knightly laugh, mace raised in salute.
M.peppermint = {Stride = 5.8,
	Gait = function(p, ph, s)
		local r = s.Run
		local a = sin(ph)
		p.LH = V((0.75 * max(0, a) - 0.25 * max(0, -a)) * r, 0, -0.03)
		p.RH = V((0.75 * max(0, -a) - 0.25 * max(0, a)) * r, 0, 0.03)
		p.RS = V(1.45, 0, 0.25)
		p.LS = V(0.1 + 0.55 * a * r, 0, -0.15)
		p.Root = V(-0.1 * r, 0.05 * a * r, 0)
		p.Neck = V(0.08 * r, 0, 0)
		p.Off = air(ph, 0.1 * r)
		p.RS += V(0.18 * sin(ph) * s.Run, 0, 0)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.03), V(0, 0, 0.03)
		p.RS = V(1.3, 0, 0.22)
		p.LS = V(0.05, 0, -0.1)
		breathe(p, t, 0.8, 1.0)
		local side = floor(t / 5) % 2 == 0 and 0.35 or -0.35
		p.Neck += V(0, side * ease((t % 5) / 0.3), 0)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.04) / 0.16)
		p.RS = V(1.45 + 0.9 * k, 0, 0.25 - 0.2 * k)
		p.LS = V(1.2 * k, 0, -0.2)
		p.Root = V(-0.32 * k, 0, 0)
		p.LH, p.RH = V(0.4 * k, 0, 0), V(-0.3 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.2, Shake = 0.04, Rate = 10, Head = 0.45})
		p.RS = V(1.45 + 1.4 * inn, 0, 0.25)
		p.LS = V(0.4 * inn, 0, -0.3 * inn - 0.1)
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
		p.LS += V(-0.3 * abs(sin(ph)) * s.Run, 0, -0.3 * abs(sin(ph)))
		p.RS += V(-0.3 * abs(cos(ph)) * s.Run, 0, 0.3 * abs(cos(ph)))
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
		p.LS += V(0.28 * sin(ph * 2) * s.Run, 0, 0)
		p.RS += V(-0.28 * sin(ph * 2) * s.Run, 0, 0)
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
		p.LS += V(-0.4 * sin(ph) * s.Run, 0, 0)
		p.RS += V(0.4 * sin(ph) * s.Run, 0, 0)
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
		p.LS += V(0.42 * sin(ph) * s.Run, 0, 0)
		p.RS += V(-0.42 * sin(ph) * s.Run, 0, 0)
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

-- 32 Itza, the Jaguar Warrior (a Quad rig: when the body goes down, the hands are paws on the floor). At rest he
-- stands tall, carved staff in his right hand, tail-tip twitching, head low and watchful. When a chase starts he
-- slings the staff across his back (Carry: the one staff moves from his hand to its strap and back afterwards)
-- and drops to all fours: body low and long, fore and hind legs in a bounding feline gallop, shoulders working,
-- head level and locked on you. The grab is a pounce; the laugh a rumbling snarl, rising back onto his feet.
M.itza = {Stride = 9,
	Carry = {Joint = "Gear_StaffJoint", Held = "idle", From = 0.05, To = 0.3},
	Taunt = function(p, age)
		-- swings the staff over his shoulder onto his back, then crouches
		local up = ease(age / 0.18) * (1 - ease((age - 0.3) / 0.2))
		local crouch = ease((age - 0.35) / 0.4)
		p.RS = V(2.6 * up + 0.9 * crouch, 0, 0.3 * up)
		p.LS = V(0.9 * crouch, 0, -0.1)
		p.Root = V(-0.9 * crouch, 0, 0)
		p.LH, p.RH = V(-0.3 * crouch, 0, -0.05), V(-0.3 * crouch, 0, 0.05)
		p.Neck = V(0.7 * crouch, 0, 0)
	end,
	Gait = function(p, ph, s)
		-- a big cat's gallop on all fours: body level and low, hind pair driving together (a little apart), fore pair reaching
		-- and pulling half a stride later, the spine rocking between the two, head held up and forward on the prey
		local r = s.Run
		p.Root = V(-1.36 + 0.09 * sin(ph * 2 + 0.6) * r, 0.05 * sin(ph) * r, 0)
		p.LH = V(-0.08 + 0.62 * sin(ph) * r, 0, -0.08)
		p.RH = V(-0.08 + 0.62 * sin(ph + 0.45) * r, 0, 0.08)
		p.LS = V(1.42 + 0.72 * sin(ph + pi) * r, 0, -0.1)
		p.RS = V(1.42 + 0.72 * sin(ph + pi + 0.45) * r, 0, 0.1)
		p.Neck = V(0.8, 0.05 * sin(ph) * r, 0)
		p.Off = V(0, 0.2 * max(0, sin(ph * 2 - 0.5)) * r, 0)
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0.05, 0, -0.07), V(-0.05, 0, 0.07)
		p.RS = V(0.15, 0, 0.12)
		p.LS = V(0.1, 0, -0.15)
		breathe(p, t, 1.0, 1.2)
		p.Neck += V(0.12, 0.3 * sin(t * 2 * pi / 8), 0)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.02) / 0.15)
		local arc = sin(clamp(a / 0.45, 0, 1) * pi)
		p.Root = V(-1.15 + 0.5 * arc, 0, 0)
		p.LS, p.RS = V(1.8 * k, 0, -0.15), V(1.8 * k, 0, 0.15)
		p.LH, p.RH = V(-0.6, 0, -0.06), V(-0.6, 0, 0.06)
		p.Neck = V(0.8, 0, 0)
		p.Off = V(0, 0.6 * arc, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 9)
		p.Root = V(0.05 * inn, 0, 0)
		p.Neck = V((0.35 + 0.05 * k) * inn, 0, 0)
		arms(p, V(0.5 * inn, 0, -0.35), V(0.5 * inn, 0, 0.35))
	end}


-- 33 Wobbles: a carnival clown who lives on his pogo stick (Gear_Pogo). The stick is rigid with his torso and the
-- pose never moves his arms or legs relative to it, so his hands stay on the handlebar and his feet on the pegs
-- through every bounce (the roster's Lift raises him so the stick's foot, not his, is on the floor at rest). Each
-- bound: he squashes down onto the spring (the whole rider pitching forward over the bar), rebounds up and forward,
-- flies, and lands on the stick. At rest he balances with little twitchy hops; he grabs by lunging off the top of a
-- bounce; he laughs bouncing in place, head thrown back.
local GRIP = V(0.45, 0, -0.2) -- left arm on the handlebar (the right mirrors it); the pogo was fitted to this pose
local function onStick(p)
	p.LS, p.RS = GRIP, V(GRIP.X, 0, -GRIP.Z)
	p.LH, p.RH = V(0, 0, -0.06), V(0, 0, 0.06)
	p.Free = 1
end
M.wobbles = {Stride = 11, Foot = 0,
	Gait = function(p, ph, s)
		local r = s.Run
		local h = abs(sin(ph)) -- 0 = on the spring, 1 = top of the arc (one bound per half cycle)
		local squash = (1 - h) ^ 6
		onStick(p)
		p.Off = V(0, 1.5 * h * r, 0)
		p.Root = V(-0.1 - 0.16 * squash + 0.04 * h, 0, 0.05 * sin(ph))
		p.Neck = V(0.15 + 0.15 * squash, 0, 0.08 * sin(ph * 2))
	end,
	Idle = function(p, t)
		local hop = abs(sin(t * 3.4)) ^ 3
		onStick(p)
		p.Off = V(0, 0.25 * hop, 0)
		p.Root = V(-0.05, 0, 0.04 * sin(t * 1.7))
		p.Neck = V(0.15 + 0.08 * sin(t * 5), 0.2 * sin(t * 0.9), 0)
	end,
	Taunt = function(p, age)
		onStick(p)
		local k = ease(age / 0.2) * (1 - ease((age - 0.7) / 0.2))
		p.Off = V(0, 0.6 * abs(sin(age * 8)) * k, 0)
		p.Neck = V(-0.15 * k, 0, 0.25 * sin(age * 12) * k)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.03) / 0.15)
		onStick(p)
		p.Off = V(0, 0.5 * sin(clamp(a / 0.45, 0, 1) * pi), 0)
		p.Root = V(-0.35 * k, 0, 0)
		p.Neck = V(0.3 * k, 0, 0)
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local hop = abs(sin(a * 7)) * inn
		onStick(p)
		p.Off = V(0, 0.45 * hop, 0)
		p.Root = V(0.12 * inn, 0, 0.06 * sin(a * 7) * inn)
		p.Neck = V(0.5 * inn, 0, 0)
	end}



-- 34 Taurus: a minotaur strongman. A head-down bull charge, horns first. Paws the floor and snorts at rest; drives in
-- horns-first to grab; flexes in a double-biceps pose.
M.taurus = {Stride = 8,
	-- the wind-up before each charge (GuardMotion act "windup", from the server): weight back, head down, one hoof scraping the floor
	Windup = function(p, a)
		local k = ease(a / 0.25)
		local scrape = sin(a * 13) * k
		p.Root = V(0.12 * k, 0, -0.04 * k)
		p.Neck = V(-0.5 * k, 0, 0)
		p.LH = V(0.24 * k, 0, -0.08)
		p.LK = 0.45 * k
		p.RH = V((-0.3 + 0.32 * scrape) * k, 0, 0.08)
		p.RK = (0.55 + 0.35 * scrape) * k
		arms(p, V(0.35 * k, 0, -0.5 * k - 0.1), V(0.35 * k, 0, 0.5 * k + 0.1))
		p.LE, p.RE = 0.7 * k, 0.7 * k
	end,
	-- the end of a charge: hooves dig in, he straightens up blowing hard
	Recover = function(p, a)
		local k = 1 - ease(a / 0.6)
		p.Root = V(-0.5 * k + 0.08 * (1 - k), 0, 0)
		p.Neck = V(-0.15 * k + 0.1 * (1 - k), 0, 0)
		p.LH, p.RH = V(0.3 * k, 0, -0.08), V(-0.2 * k, 0, 0.08)
		p.LK, p.RK = 0.5 * k, 0.3 * k
		arms(p, V(0.35, 0, -0.3), V(0.35, 0, 0.3))
		p.LE, p.RE = 0.6, 0.6
	end,
	Gait = function(p, ph, s)
		-- the charge: head down, horns first, driving hard off every hoof, with big heavy arms pumping
		local r = s.Run
		run(p, ph, r, {Hip = 0.82, Knee = 1.25, KneeBase = 0.25, Arm = 0.6, ArmBase = 0.35, Elbow = 1.05, ElbowSwing = 0.3, Lean = 0.52, Twist = 0.12, Roll = 0.05, Bounce = 0.13, Spread = 0.06, Head = -0.2, Out = 0.3})
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

-- 35 Jetpack Jenny: a goggled aviator with twin brass tanks on her back. At rest she stands on the floor, hand
-- shading her eyes. When she sets off, the tanks fire (FX "jet" from both nozzles) and she lifts off as she
-- accelerates (the gait weight carries her up), flying a steady body-height above the floor, leaning into the
-- thrust, legs together trailing, arms back along her sides; she banks into turns (GuardMotion's lean) and touches
-- down as she stops. No bobbing: the height comes from the thrust and nothing else. The grab: she brakes upright and
-- reaches; the laugh: a hover in place, fists on hips, head back.
M.jenny = {Stride = 12,
	Gait = function(p, ph, s)
		local r = s.Run
		p.LH, p.RH = V(-0.4, 0, -0.06), V(-0.5, 0, 0.06)
		arms(p, V(-0.35, 0, -0.35), V(-0.35, 0, 0.35))
		p.Root = V(-0.5 * r, 0, 0)
		p.Neck = V(0.45 * r, 0, 0)
		p.Off = V(0, 1.8, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		local shade = pulse(t, 10, 3)
		p.LS = V(0.1 + 1.9 * clamp(shade * 1.5, 0, 1), 0, -0.3)
		p.RS = V(0.1, 0, 0.3)
		p.Neck = V(0.05, 0.5 * sin(t * 0.5), 0)
		p.LH, p.RH = V(0, 0, -0.05), V(0, 0, 0.05)
		breathe(p, t, 0.8, 1.2)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.03) / 0.18)
		p.Root = V(-0.5 + 0.35 * k, 0, 0)
		p.Off = V(0, 1.8 - 1.2 * k, 0)
		arms(p, V(1.4 * k, 0, -0.25), V(1.4 * k, 0, 0.25))
		p.LH, p.RH = V(-0.4 + 0.5 * k, 0, -0.06), V(-0.5 + 0.5 * k, 0, 0.06)
		p.Neck = V(0.2, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 11)
		p.Off = V(0, 0.6 * inn, 0)
		p.Root = V((0.1 + 0.02 * k) * inn, 0, 0)
		p.Neck = V((0.4 + 0.04 * k) * inn, 0, 0)
		arms(p, V(-0.2 * inn, 0.5 * inn, -0.7 * inn), V(-0.2 * inn, -0.5 * inn, 0.7 * inn))
		p.LH, p.RH = V(-0.15 * inn, 0, -0.06), V(-0.2 * inn, 0, 0.06)
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

-- 37 Moe, the Mole Miner: at rest he stands on the cave floor, lamp on, peering short-sightedly. The moment he sets
-- off he digs straight down and tunnels after you: the whole body is under the floor and a travelling hump of
-- churned earth (FX "mound": loose soil, pebbles and dust thrown up along its path) is all you see. The grab: he
-- bursts up out of the ground in a spray of dirt, claws first; he laughs, dusting himself off. He tunnels home too.
M.moe = {Stride = 9, Dive = true,
	Gait = function(p, ph, s)
		-- diving head first: as this pose blends in (slowly: Dive) the body tips over its claws and goes in nose down
		p.Sink = 7.5
		p.Root = V(-2.15, 0, 0.06 * sin(ph))
		arms(p, V(2.5 + 0.35 * sin(ph * 2), 0, -0.3), V(2.5 - 0.35 * sin(ph * 2), 0, 0.3))
		p.Neck = V(-0.2, 0, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.1), V(0, 0, 0.1)
		arms(p, V(0.35, 0, -0.3), V(0.35, 0, 0.3))
		p.Neck = V(0.15 + 0.1 * pulse(t, 5, 0.8), 0.4 * sin(t * 0.6), 0)
		breathe(p, t, 1.2, 1.5)
	end,
	Grab = function(p, a)
		-- bursts up out of the ground in ~0.15 s, claws high, then drops onto you
		local up = ease(a / 0.15)
		local arc = sin(clamp(a / 0.5, 0, 1) * pi)
		p.Sink = 6 * (1 - up)
		p.Off = V(0, 0.8 * arc, 0)
		p.Root = V(0.2 * arc - 0.3 * ease((a - 0.3) / 0.2), 0, 0)
		arms(p, V(2.2 * up, 0, -0.5 * arc - 0.2), V(2.2 * up, 0, 0.5 * arc + 0.2))
		p.Neck = V(0.3 * arc, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		local k = sin(a * 13)
		p.Root = V((0.1 + 0.04 * k) * inn, 0, 0)
		p.Neck = V((0.35 + 0.05 * k) * inn, 0, 0)
		arms(p, V((0.6 + 0.3 * k) * inn, 0, -0.3), V((0.6 - 0.3 * k) * inn, 0, 0.3))
		p.LH, p.RH = V(0, 0, -0.1), V(0, 0, 0.1)
	end}


-- 38 Queen Lumina, the Crystal Sorceress: her magic holds her up. At rest she stands, staff grounded, crystals
-- pulsing. Chasing, she rises a little off the floor and glides at you on a slow current of crystal light (FX
-- "crystal": motes shed from the hem of her gown), body tall, the staff hand forward channelling, the free hand
-- raised to cast. Her gown and legs move as one (the gown is part of the legs' mesh). The grab: the free hand
-- snaps forward and the crystals flare; laughs with the staff lifted, head back.
M.lumina = {Stride = 12,
	Gait = function(p, ph, s)
		local r = s.Run
		p.Off = V(0, 0.4, 0)
		p.Root = V(-0.1 * r, 0, 0.03 * sin(s.T * 1.2))
		p.LH, p.RH = ZERO, ZERO
		p.RS = V(0.55, 0, 0.18)
		p.LS = V(0.9 * r, 0, -0.55)
		p.Neck = V(0.05, 0, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		local c = sin(t * 0.6)
		p.RS = V(0.1, 0, 0.15)
		p.LS = V(0.25 + 0.15 * c, 0, -0.35 - 0.2 * c)
		p.Neck = V(-0.08, 0.2 * sin(t * 0.3), 0.05 * c)
		breathe(p, t, 0.6, 1.0)
	end,
	Grab = function(p, a)
		local k = ease((a - 0.03) / 0.14)
		p.Off = V(0, 0.4 * (1 - k), 0)
		p.LS = V(1.5 * k, 0, -0.25)
		p.RS = V(0.55, 0, 0.18)
		p.Root = V(-0.25 * k, 0, 0)
		p.Neck = V(0.2 * k, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laughIn(a)
		p.RS = V(0.1 + 1.6 * inn, 0, 0.18)
		p.LS = V(0.2, 0, -0.3 - 0.6 * inn)
		p.Neck = V(0.35 * inn, 0, 0.12 * inn)
		p.Root = V(0.1 * inn, 0, 0)
	end}


-- 39 Chronos, the Time Wizard: an ancient who has all the time in the world. He walks after you at a measured,
-- unhurried pace, robe swaying, planting his staff ahead with every other step, his free hand raised and open as if
-- holding the moment still, head level. At rest he turns his hourglass over, waits, turns it again. The grab: the
-- free hand snaps shut on you; the laugh: slow and knowing, head tilted back, the staff lifted.
M.chronos = {Stride = 5.2,
	Gait = function(p, ph, s)
		-- he doesn't travel, time does: bolt upright, robe hanging straight, drifting forward in a slow rise and fall with the
		-- staff rocking like a pendulum and the hourglass held out before him. Nothing like Dracula's dive or Aeon's flight
		local r, t = s.Run, s.T
		p.Off = V(0, 0.9 + 0.1 * sin(t * 1.3), 0)
		p.Root = V(-0.07 * r, 0, 0.03 * sin(t * 0.65))
		p.LH, p.RH = V(-0.04, 0, -0.02), V(-0.04, 0, 0.02)
		p.RS = V(0.55 + 0.28 * sin(t * 1.3), 0, 0.2)
		p.LS = V(0.95, 0.2, -0.3)
		p.Neck = V(0.08, 0.1 * sin(t * 0.45), 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		local turn = pulse(t, 7, 1.2)
		p.Off = V(0, 0.55 + 0.07 * sin(t * 1.3), 0)
		p.LH, p.RH = V(-0.03, 0, -0.03), V(-0.03, 0, 0.03)
		p.RS = V(0.3, 0, 0.18)
		p.LS = V(0.9 + 0.3 * turn, 0.3 * turn, -0.2)
		breathe(p, t, 0.8, 0.8)
		p.Neck += V(0.12, 0.2 * sin(t * 0.3), 0)
		p.Free = 1
	end,
	Grab = function(p, a)
		local k = ease((a - 0.03) / 0.16)
		p.Off = V(0, 0.9 - 0.4 * k, 0)
		p.LS = V(0.85 + 0.6 * k, 0.2 - 0.2 * k, -0.35 + 0.2 * k)
		p.RS = V(0.45, 0, 0.2)
		p.Root = V(-0.25 * k, 0, 0)
		p.LH, p.RH = V(-0.04, 0, -0.03), V(-0.04, 0, 0.03)
		p.Neck = V(0.15 * k, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		local inn = laugh(p, a, {Back = 0.14, Shake = 0.02, Rate = 6, Head = 0.45})
		p.Off = V(0, 0.5, 0)
		p.LH, p.RH = V(-0.03, 0, -0.03), V(-0.03, 0, 0.03)
		p.RS = V(0.4 + 0.9 * inn, 0, 0.2)
		p.LS = V(0.5 * inn, 0, -0.3 - 0.3 * inn)
		p.Free = 1
	end}


-- 40 Aeon, the Infinite Emperor: grounded and statue-still on his throne-room floor until he sees you. Then he
-- ascends: arms spread, star-core flaring (FX "aura"), he rises straight up to a commanding height (the taunt), and
-- once airborne he flies at you, body leaning into the flight, cape streaming, sceptre held forward, legs together.
-- He never bobs: the height is held. When he stops (a catch, or home) the gait fades and he settles back down to
-- the floor. The grab: a dive with the sceptre hand; the laugh: hovering low, arms opened wide to the stars.
local HIGH = 2.6
M.gamemaster = {Stride = 12,
	Taunt = function(p, age)
		local rise = ease((age - 0.05) / 0.75)
		p.Off = V(0, HIGH * rise, 0)
		arms(p, V(0.5 * rise, 0, -0.4 - 0.9 * rise), V(0.5 * rise, 0, 0.4 + 0.9 * rise))
		p.LH, p.RH = V(-0.15 * rise, 0, -0.04), V(-0.15 * rise, 0, 0.04)
		p.Neck = V(-0.15 * rise, 0, 0)
		p.Free = 1
	end,
	Gait = function(p, ph, s)
		local r = s.Run
		p.Off = V(0, HIGH, 0)
		p.Root = V(-0.32 * r, 0, 0)
		p.LS = V(1.0, 0, -0.2)
		p.RS = V(-0.3, 0, 0.45)
		p.LH, p.RH = V(-0.25, 0, -0.04), V(-0.3, 0, 0.04)
		p.Neck = V(0.3 * r, 0, 0)
		p.Free = 1
	end,
	Idle = function(p, t)
		p.LH, p.RH = V(0, 0, -0.06), V(0, 0, 0.06)
		p.LS = V(0.3, 0, -0.2)
		p.RS = V(0.1, 0, 0.18)
		breathe(p, t, 1.0, 0.8)
		scan(p, t, 0.3, 16)
	end,
	Grab = function(p, a)
		-- he comes down in front of you, the sceptre driven down at his left and his bare right hand reaching for you, eyes on you
		local k = ease((a - 0.03) / 0.16)
		p.Off = V(0, HIGH * (1 - k) + 0.3 * k, 0)
		p.Root = V(-0.32 - 0.1 * k, 0, 0)
		p.RS = V(-0.3 + 1.45 * k, 0, 0.45 - 0.3 * k)
		p.LS = V(1.0 - 0.5 * k, 0, -0.2)
		p.LH, p.RH = V(-0.25 + 0.4 * k, 0, -0.04), V(-0.3 + 0.2 * k, 0, 0.04)
		p.Neck = V(0.3 - 0.55 * k, 0, 0)
		p.Free = 1
	end,
	Laugh = function(p, a)
		-- not a giggle: he stands over you, sceptre planted, right hand rising open as if holding your defeat up to the light,
		-- and looks down at you while he laughs. Only the shoulders move
		local inn = laughIn(a)
		local k = sin(a * 7)
		p.Root = V((0.06 + 0.02 * k) * inn, 0, 0)
		p.Neck = V((-0.22 + 0.04 * k) * inn, 0, 0)
		p.LS = V(0.3 + 0.1 * inn, 0, -0.2)
		p.RS = V(0.1 + 1.05 * inn, -0.25 * inn, 0.18 + 0.32 * inn)
		p.Off = V(0, 0.3 * inn, 0)
		p.LH, p.RH = V(-0.05 * inn, 0, -0.06), V(-0.05 * inn, 0, 0.06)
		p.Free = 1
	end}


------------------------------------------------------------------
-- EFFECTS
------------------------------------------------------------------
-- FX[key] = list of emitters, each: Kind, Part (a body part or Gear_ part), At (where on that part, as a fraction of
-- its size, -0.5..0.5, in the part's own axes; +Z is the back). They run while the guard moves or flies (scaled by
-- how much), so a jet only fires while it flies. Kinds: jet (flame + smoke from a nozzle, downward), puff (a small
-- blue thruster), bubbles (a stream rising from a valve), wisps (green spectral smoke trailing from a robe), crystal
-- (violet motes), embers (sparks), aura (violet energy round a flying body), wave (foam boiling up round the feet, on
-- the floor), fin (the shark's dorsal fin and its wake, on the water), mound (the mole's travelling hump of earth).
K.FX = {
	brine = {{Kind = "finmound"}},
	fangula = {{Kind = "redmist", Part = "Gear_Coat", At = V(0, -0.5, 0.1)}},
	chronos = {{Kind = "clock", Part = "Torso", At = V(0, 0.1, -0.2)}},
	taurus = {{Kind = "gust", Part = "Torso", At = V(0, 0.2, -0.5), Charge = true}},
	mortimer = {{Kind = "wisps", Part = "Torso", At = V(0, -0.5, 0)}},
	sb9000 = {{Kind = "steam", Part = "Gear_Jetpack", At = V(-0.42, -0.45, -0.2), Burst = 26}, {Kind = "steam", Part = "Gear_Jetpack", At = V(-0.42, -0.45, 0.2), Burst = 26}}, -- steam driven: both nozzles, a blast at take-off
	scorch = {{Kind = "embers", Part = "Torso", At = V(0, 0.25, 0.5)}},
	nova = {{Kind = "puff", Part = "Torso", At = V(0, -0.25, 0.5)}},
	dex = {{Kind = "bubbles", Part = "Head", At = V(0.3, 0.35, 0)}}, -- the helmet's exhaust valve
	tridentus = {{Kind = "bubbles", Part = "Gear_MountNeck", At = V(0, 0.1, -0.5)}, {Kind = "bubbles", Part = "Gear_Mount", At = V(0, 0, 0.5)}, {Kind = "current", Part = "Gear_Mount", At = V(0, 0.2, 0.5)}},
	jenny = {{Kind = "jet", Part = "Torso", At = V(-0.24, -0.4, 0.5)}, {Kind = "jet", Part = "Torso", At = V(0.24, -0.4, 0.5)}},
	lumina = {{Kind = "crystal", Part = "Torso", At = V(0, -0.5, 0)}},
	moe = {{Kind = "mound"}},
	gamemaster = {{Kind = "aura", Part = "Torso", At = V(0, 0.1, -0.3)}}, -- the star core in his chest
}

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
-- THE KATANA DRAW (Carry.Draw): one sword, moved only by the hand that holds it
------------------------------------------------------------------
-- The draw needs a real elbow: a rigid arm moves the hand on an arc, which would lever the blade round inside the sheath.
-- Kage's right arm is two pieces (RightArm, RightForearm on a RightElbow joint) solved as a two-bone arm.
-- K.drawSetup reads the rig (the sword joint's attributes are in rig units) for the giant's scale; K.draw(d, armPose, p)
-- with p: 0 = sheathed, 1 = drawn and held. Returns the shoulder and elbow transforms and the sword (torso space).
--   0.00-0.30  the arm goes from the pose up behind the neck to the handle; the sword does not move
--   0.30-0.38  the hand closes on it
--   0.38-0.62  the pull: palm and sword travel in a straight line along the sword's own axis, so the blade slides out of
--              the sheath without ever leaving its line
--   0.62-1.00  the tip is clear: the arm comes down to the pose while the blade swings behind him, up and over, into the grip
function K.drawSetup(model, rig, def)
	local j = model:FindFirstChild(def.Joint, true)
	local ej = model:FindFirstChild("RightElbow", true)
	if not (j and ej) then
		return nil
	end
	local s = rig.Scale
	local grip = j:GetAttribute("Grip")
	local rest = j.C0 * j.C1:Inverse()
	local d = {Joint = j, Elbow = ej, P = 0, Held = def.Held or 0.75, Rest = rest, C0 = rig.C0.RS, C1i = rig.C1i.RS, EC0 = ej.C0, EC1i = ej.C1:Inverse(),
		Grip = (grip - grip.Position) + grip.Position * s, Hand = j:GetAttribute("Hand") * s, HandleOff = j:GetAttribute("HandleOff") * s,
		Len = j:GetAttribute("Len") * s, E0 = j:GetAttribute("ElbowRest") * s, H0 = j:GetAttribute("HandRest") * s}
	d.S = d.C0.Position
	d.L1, d.L2 = (d.E0 - d.S).Magnitude, (d.H0 - d.E0).Magnitude
	d.Handle = rest * d.HandleOff
	return d
end

local function turnBetween(a, b)
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(clamp(a.Unit:Dot(b.Unit), -1, 1)))
end
local ELBOW_OUT = Vector3.new(0.85, 0.25, 0.45) -- the elbow points out to the side and back: never across his own head
-- two-bone arm: the shoulder and elbow transforms that put the palm on point (torso space)
local function armTo(d, point)
	local to = point - d.S
	local dist = clamp(to.Magnitude, abs(d.L1 - d.L2) + 0.01, d.L1 + d.L2 - 0.01)
	local dir = to.Unit
	local along = (d.L1 * d.L1 - d.L2 * d.L2 + dist * dist) / (2 * dist)
	local side = (ELBOW_OUT - dir * ELBOW_OUT:Dot(dir)).Unit
	local elbow = d.S + dir * along + side * math.sqrt(max(0, d.L1 * d.L1 - along * along))
	local u = turnBetween(d.E0 - d.S, elbow - d.S)
	local v = turnBetween(u * (d.H0 - d.E0), d.S + dir * dist - elbow)
	return u, u:Inverse() * v * u
end
local function forearm(d, rs, el)
	return d.C0 * rs * d.C1i * d.EC0 * el * d.EC1i
end
-- the sword with its handle in the palm, pointing where rot says
local function inPalm(d, rs, el, rot)
	return (CFrame.new((forearm(d, rs, el) * d.Hand)) * rot) * CFrame.new(-d.HandleOff)
end
-- a sword rotation with its blade pointing along dir
local function bladeTo(dir, side)
	local up = -dir.Unit
	local back = side:Cross(up).Unit
	return CFrame.fromMatrix(Vector3.zero, up:Cross(back).Unit, up, back)
end
function K.draw(d, armPose, p)
	local heldEl = CFrame.Angles(d.Held, 0, 0)
	if p <= 0.38 then
		local rs, el = armTo(d, d.Handle)
		local k = ease(p / 0.3)
		return armPose:Lerp(rs, k), CFrame.identity:Lerp(el, k), d.Rest
	end
	local axis = d.Rest.UpVector
	if p < 0.62 then
		local out = ease((p - 0.38) / 0.24) * d.Len
		local rs, el = armTo(d, d.Handle + axis * out)
		return rs, el, d.Rest + axis * out
	end
	local rs0, el0 = armTo(d, d.Handle + axis * d.Len)
	local k = ease((p - 0.62) / 0.38)
	local rs, el = rs0:Lerp(armPose, k), el0:Lerp(heldEl, k)
	if p >= 1 then
		return rs, el, forearm(d, rs, el) * d.Grip
	end
	-- the swing: blade from down its sheath's line, to pointing straight behind, to straight up, to the grip
	local side = d.Rest.RightVector
	local k2 = (p - 0.62) / 0.38
	local r0, r1, r2 = d.Rest.Rotation, bladeTo(Vector3.new(0.3, 0, 1), side), bladeTo(Vector3.new(0.3, 1, 0.1), side)
	local r3 = (forearm(d, rs, el) * d.Grip).Rotation
	local rot
	if k2 < 0.3 then
		rot = r0:Lerp(r1, ease(k2 / 0.3))
	elseif k2 < 0.6 then
		rot = r1:Lerp(r2, ease((k2 - 0.3) / 0.3))
	else
		rot = r2:Lerp(r3, ease((k2 - 0.6) / 0.4))
	end
	return rs, el, inPalm(d, rs, el, rot)
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
	nightwind = {Id = 9125602736, Vol = 1.0, Loop = true}, -- Heavenly Presence, Eerie Choral Tones, Dark (Pro Sound Effects)
	clockloop = {Id = 8140501675, Vol = 2.0, Loop = true},
	spectral = {Id = 9114625545, Vol = 0.4, Loop = true}, -- Gods Wind, Spooky, Eerie (Pro Sound Effects); a loud take (loudness 177 at Vol 1), kept as ambience
	plasma = {Id = 9125742262, Vol = 2.5, Loop = true},
	rocket = {Id = 135314203986462, Vol = 0.6, Loop = true},
	bubbles = {Id = 9113604980, Vol = 0.45, Loop = true}, -- underwater bubble swells
	draw = {Id = 9119747260, Vol = 1.3, Len = 0.9}, -- a sabre out of its scabbard
	dig = {Id = 9125880099, Vol = 1.2, Loop = true}, -- deep clunky rock scrapes (the mole tunnelling)
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
	brine = {Loop = {"bubbles", 1.0, 0.7}},
	mortimer = {Loop = {"spectral", 0.8, 1}}, -- a cold supernatural wind (was "Flutter By", which read as wings flapping)
	fangula = {Loop = {"nightwind", 0.75, 0.7}},
	vex = {Steps = {"mil", "mil"}, Pitch = 1.0, Vol = 0.85, Layer = {"clank", 1.3, 0.35, 1}},
	vapor = {Steps = {"robolight", "stone"}, Pitch = 1.3, Vol = 0.8},
	kage = {Steps = {"stone", "stone"}, Pitch = 1.5, Vol = 0.3},
	oni = {Steps = {"heavy7", "heavy7"}, Pitch = 0.5, Vol = 1.15, Layer = {"clank", 0.6, 0.5, 1}},
	sb9000 = {Loop = {"rocket", 0.85, 0.6}},
	model7 = {Steps = {"robolight", "robolight"}, Pitch = 1.0, Vol = 0.8, Layer = {"servo", 1.6, 0.25, 2}},
	scorch = {Loop = {"flutter", 0.55, 0.9}},
	magmor = {Steps = {"heavy6", "heavy6"}, Pitch = 0.42, Vol = 1.2, Layer = {"stone", 0.5, 0.6, 1}},
	nova = {Steps = {"boot", "boot"}, Pitch = 0.7, Vol = 0.9, Layer = {"flutter", 1.4, 0.4, 1}},
	zorp = {Steps = {"squish", "squish"}, Pitch = 1.3, Vol = 0.8},
	dex = {Loop = {"bubbles", 1.35, 0.55}},
	tridentus = {Loop = {"bubbles", 0.7, 0.7}},
	mumbles = {Steps = {"stone", "cloth"}, Pitch = 0.7, Vol = 0.9}, -- a dull footfall, then the dragged foot scraping linen
	anubis = {Steps = {"sand", "sand"}, Pitch = 1.1, Vol = 0.8, Layer = {"hoof", 0.7, 0.4, 2}},
	peppermint = {Steps = {"clank", "clank"}, Pitch = 1.15, Vol = 0.85, Layer = {"candy", 1.4, 0.3, 2}},
	bonbon = {Steps = {"crunch", "crunch"}, Pitch = 1.0, Vol = 0.8, Layer = {"candy", 1.6, 0.3, 2}},
	pemberton = {Steps = {"snow", "snow"}, Pitch = 1.3, Vol = 0.8, Layer = {"squeak", 2.2, 0.15, 4}},
	yuki = {Steps = {"snowstomp", "snowstomp"}, Pitch = 0.6, Vol = 1.0, Layer = {"heavy1", 0.5, 0.5, 1}},
	sheriff = {Steps = {"concrete", "hoof"}, Pitch = 0.9, Vol = 0.9, Layer = {"clatter", 1.7, 0.2, 1}},
	rattler = {Steps = {"sand", "sand"}, Pitch = 1.3, Vol = 0.7, Layer = {"rattle", 1.5, 0.45, 3}},
	tiki = {Steps = {"thud", "woodknock"}, Pitch = 0.75, Vol = 1.0},
	itza = {Steps = {"stone", "concrete"}, Pitch = 1.35, Vol = 0.45}, -- soft paw falls
	wobbles = {Steps = {"boing", "boing"}, Pitch = 0.85, Vol = 0.9, Layer = {"duck", 1.0, 0.4, 2}},
	taurus = {Steps = {"hoof", "hoof"}, Pitch = 0.6, Vol = 1.1, Layer = {"heavy7", 0.6, 0.6, 1}},
	jenny = {Loop = {"rocket", 1.2, 0.35}},
	ironclad = {Steps = {"rattlebody", "rattlebody"}, Pitch = 0.7, Vol = 1.0, Layer = {"servo", 0.6, 0.4, 1}},
	moe = {Loop = {"dig", 0.8, 0.8}},
	lumina = {Loop = {"plasma", 1.6, 0.3}},
	chronos = {Loop = {"clockloop", 0.6, 0.6}},
	gamemaster = {Loop = {"plasma", 0.6, 0.6}},
}

return K

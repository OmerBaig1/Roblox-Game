--[[
	PetAnimator (Pet Lab draft)
	Code-driven animation for rigged premium pets: no Animation assets, so nothing has to be uploaded
	under the place owner's account. Each frame the follow code calls :Step(dt, t, speed, turn, camDist) and the
	animator blends idle and moving poses onto the pet's Motor6D.Transform values.

	Everything about how a pet moves is data in its PetConfigs entry:
	  Mode      follow style, a function in PetAnimator.Modes (Bound, Hover, Glide, Hop, Roll, Scuttle, Slither,
	            Waddle).
	            It drives the Body joint.
	  Head, Ears, Tail, Wings, Chain, Wobble, Orbit, Spin   optional blocks for the joints they name.
	  Special   signature move, a function in PetAnimator.Specials, played every few seconds while standing still.
	            If the pet starts moving it winds down quickly from the same pose, unless Special.Finish is set
	            (moves that can't stop halfway).
	  Glow, MoveFx   lights that flicker and flare with the special; trails and emitters that only run while moving.
	  LandFx    {emitter name, count} burst every time the mode lands (hops, bounds).
	  Stepped   joint poses update only this many times a second (8-bit pets snap like old sprites).
	  Glitch    corrupted-data pets: now and then a random joint jumps for a frame or two, ghost copies flicker.
	  Spinners  joints that spin continuously about their Y axis (rotors), faster while moving.
	  Walk      legs that swing in an alternating walk cycle with the gait instead of bounding together.
	Missing joints are skipped, so one animator drives every body plan. A new body plan or signature move is a new
	function in Modes or Specials, never a check on the pet's name.

	LOD (PET_BIBLE §6): pass camDist. 60-140 studs animates every other frame, turns trails and beams off and halves
	particle rates; past 140 nothing animates and emitters stop.
]]
local PetAnimator = {}
PetAnimator.__index = PetAnimator

local rad = math.rad
local sin = math.sin
local A = CFrame.Angles
local TAU = math.pi * 2
local ZERO = Vector3.zero
local EMPTY = {}
local EARS = {{"EarL", 1}, {"EarR", -1}}

-- a 0..1 bump: 0 at the ends, 1 in the middle
local function bump(x)
	if x <= 0 or x >= 1 then
		return 0
	end
	return sin(x * math.pi)
end

local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- a special's strength from its bump: reaches full a little early and holds, eased at both ends so poses never kink
local function ease(b, k)
	return smooth(b * (k or 1.6))
end

local function randRange(r, rng)
	return r[1] + rng:NextNumber() * (r[2] - r[1])
end

-- how fast the gait cycles run for a travel speed: 0..1 up to a normal walk (16 studs/s), then it keeps rising
-- with each doubling of speed up to 3 (at 64+ studs/s), so pets in this game (players run ~200 studs/s) visibly
-- run instead of sliding. Capped so cycles never outrun the frame rate and strobe.
local function pace(speed)
	local walk = speed / 16
	return math.clamp(walk, 0, 1) + math.clamp(math.log(math.max(walk, 1), 2), 0, 2)
end
PetAnimator.pace = pace
local ROLL_MAX = 30 -- studs/s: faster rolling spins past what 60 fps can show and looks frozen or backwards
local MOVE_WOBBLE = 0.75 -- a Moving wobble (wings, legs, fins) cycles 1 + this * pace times faster while travelling

function PetAnimator.new(model, cfg)
	local self = setmetatable({}, PetAnimator)
	self.Model = model
	self.Cfg = cfg
	self.Rng = Random.new()
	self.M = {}
	self.Fx = {}
	self.Emitters = {} -- {emitter, authored Rate, authored Enabled}, for LOD
	self.Lines = {} -- trails and beams -> authored Enabled, for LOD
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			self.M[d.Name] = d
		elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Light") then
			self.Fx[d.Name] = d
			if d:IsA("ParticleEmitter") then
				table.insert(self.Emitters, {d, d.Rate, d.Enabled})
			elseif not d:IsA("Light") then
				self.Lines[d] = d.Enabled
			end
		end
	end
	self.GlowBase = {}
	for i, gl in ipairs(cfg.Glow or EMPTY) do
		self.GlowBase[i] = self.Fx[gl.Light] and self.Fx[gl.Light].Brightness or 1
	end
	self.Phase = self.Rng:NextNumber() * 10
	self.Moving = 0 -- smoothed 0 (idle) .. 1 (moving)
	self.Turn = 0 -- smoothed turn, so deep banks never flip in one frame
	self.Gait, self.Half, self.Flap, self.Wave, self.HopX = 0, 0, 0, 0, 0
	self.LandAt = -100
	self.Swing, self.SwingV, self.SpinA, self.SideA = 0, 0, 0, 0
	self.CurlA, self.RollA, self.StepAcc, self.SnapX = 0, 0, 0, 0
	if cfg.Glitch then
		self.GlitchState = {Next = 0, Until = -1, Copies = {}}
		for _, n in ipairs(cfg.Glitch.Copies or EMPTY) do
			local p = model:FindFirstChild(n)
			if p then
				table.insert(self.GlitchState.Copies, {p, p.Transparency})
				p.Transparency = 1
			end
		end
	end
	self.Pulses = {}
	self.WobPh = {} -- each wobble's cycle position, built up per frame so its rate can change without a jump
	self.WobCf = {} -- this frame's wobble pose per joint; several wobbles on one joint combine
	self.Off = {} -- this frame's pose offsets from the special, by joint name
	self.Done = {} -- joints a block posed this frame
	self.Loose = {} -- joints no block drives that are holding a special's offset
	self.S = {spX = -1, spB = 0} -- this frame's shared values (mode, special) for the joint blocks
	self.Held, self.Skip, self.RateScale = 0, false, 1
	self.Special = {Next = cfg.Special and -1 or math.huge, X = -1, Out = false, Fired = {}} -- -1: timed from the first Step
	return self
end

function PetAnimator:_set(name, cf)
	local m = self.M[name]
	if m then
		local off = self.Off[name]
		m.Transform = off and cf * off or cf
		self.Done[name] = true
	end
end

-- a random-interval pulse: returns a 0..1 bump `len` seconds long, its progress 0..1 (-1 when resting) and its state
function PetAnimator:_pulse(key, t, every, len)
	local pl = self.Pulses[key]
	if not pl then
		pl = {Next = t + randRange(every, self.Rng), At = -1, Side = 1, Fired = false}
		self.Pulses[key] = pl
	end
	if pl.At < 0 and t >= pl.Next then
		pl.At, pl.Fired = t, false
		pl.Side = self.Rng:NextInteger(0, 1) * 2 - 1
	end
	if pl.At < 0 then
		return 0, -1, pl
	end
	local x = (t - pl.At) / len
	if x >= 1 then
		pl.At = -1
		pl.Next = t + randRange(every, self.Rng)
		return 0, -1, pl
	end
	return bump(x), x, pl
end

-- the Emitters entries for these names, looked up once by the caller
function PetAnimator:_emitters(names)
	local list = {}
	for _, e in ipairs(self.Emitters) do
		if table.find(names, e[1].Name) then
			table.insert(list, e)
		end
	end
	return list
end

local NONE = {}

-- runs those emitters at `mult` times their authored rate (LOD scaling still applies)
function PetAnimator:_surge(list, mult)
	mult *= self.RateScale
	if list.Mult ~= mult then
		list.Mult = mult
		for _, e in ipairs(list) do
			e[1].Rate = e[2] * mult
		end
	end
end

function PetAnimator:_setLod(lod)
	self.Lod = lod
	self.RateScale = lod == 1 and 0.5 or 1
	for _, e in ipairs(self.Emitters) do
		e[1].Rate = e[2] * self.RateScale
		e[1].Enabled = e[3] and lod < 2
	end
	for line, on in pairs(self.Lines) do
		line.Enabled = on and lod == 0
	end
end

----------------------------------------------------------------------------------------------------------------
-- Modes: how the body travels. Each returns the Body joint's transform and fills s.Lift (vertical motion that
-- floating pieces share), s.Pitch (body pitch the head steadies against) and s.Land (true on a landing frame).
----------------------------------------------------------------------------------------------------------------
local Modes = {}
PetAnimator.Modes = Modes

local function breathe(c, s)
	return sin(s.p * c.Body.BreatheRate * TAU) * c.Body.Breathe * s.idle
end

-- quadrupeds: a bounding hop whose rate rises with speed, pitch with the stride, lean into turns
function Modes.Bound(self, c, s)
	local m, mv = c.Move, s.mv
	self.Gait += s.dt * m.HopRate * (0.7 + 0.5 * pace(s.speed))
	local g = self.Gait * TAU
	local half = math.floor(self.Gait * 2) -- |sin| touches the ground twice per cycle
	if half ~= self.Half then
		self.Half = half
		s.Land = mv > 0.3
	end
	s.Lift = math.abs(sin(g)) * m.HopHeight * mv
	s.Pitch = sin(g * 2) * m.Pitch * mv
	s.Gait = g
	return CFrame.new(0, s.Lift + breathe(c, s), 0) * A(rad(s.Pitch), 0, rad(-s.turn * c.Body.Lean * mv))
end

-- fliers: bob, drift in a lazy figure-eight when idle, heave with each downstroke, pitch forward and bank when flying.
-- Twirl = now and then a full pirouette when idle. Hang = hangs upside-down when idle (bats) and flips upright to fly.
-- Jitter = erratic darting while flying (studs).
function Modes.Hover(self, c, s)
	local h, mv = c.Hover, s.mv
	local bob = sin(s.p * h.BobRate * TAU) * h.Bob
	local heave = -math.cos(self.Flap) * h.Heave * (0.4 + 0.6 * mv)
	local d = h.Drift * s.idle
	local w = s.p * h.DriftRate * TAU
	local spin = 0
	if h.Twirl then
		local _, x = self:_pulse(h, s.t, h.Twirl.Every, h.Twirl.Time)
		spin = x >= 0 and smooth(x) * TAU * s.idle or 0
	end
	local jx, jy = 0, 0
	if h.Jitter then
		jx = (sin(s.p * 7.3) * 0.6 + sin(s.p * 11.1) * 0.4) * h.Jitter * mv
		jy = (sin(s.p * 9.7) * 0.6 + sin(s.p * 5.3) * 0.4) * h.Jitter * mv
	end
	local hang = h.Hang and math.pi * smooth(1 - mv * 2) or 0
	s.Lift = bob + heave
	s.Pitch = -h.Tilt * mv
	return CFrame.new(sin(w) * d + jx, s.Lift + jy, sin(w * 2) * d * 0.5) * A(rad(s.Pitch), spin, rad(-s.turn * h.Bank * mv) + hang)
end

-- swimmers and drifters (fish, rays, ghosts): float with a slow bob, the nose follows the bob's climb, bank into
-- turns, pitch by Tilt while travelling (negative Tilt sits up). Startle = now and then a startled wiggle.
-- Snap = teleport-steps (hops per second): the body hangs where it was, then snaps forward to catch up.
function Modes.Glide(self, c, s)
	local g, mv = c.Glide, s.mv
	local w = s.p * g.BobRate * TAU
	local yaw = 0
	if g.Startle then
		local _, x = self:_pulse(g, s.t, g.Startle.Every, g.Startle.Time)
		yaw = x >= 0 and sin(x * TAU * 4) * bump(x) * g.Startle.Angle * s.idle or 0
	end
	local behind = 0
	if g.Snap then
		self.SnapX = (self.SnapX + s.dt * g.Snap) % 1
		local k = self.SnapX
		if g.Zoom then
			-- falls behind, then eases forward over the last quarter instead of snapping (a snail's zoom); the lag is
			-- scaled rather than clipped so the whole catch-up stays eased
			k = k < 0.75 and k / 0.75 or 1 - smooth((k - 0.75) / 0.25)
			behind = math.min(s.speed * 0.75 / g.Snap, 1.5) * k * mv
		else
			behind = math.min(s.speed * k / g.Snap, 1.5) * mv
		end
	end
	s.Lift = sin(w) * g.Bob
	s.Pitch = -g.Tilt * mv + math.cos(w) * g.Climb
	return CFrame.new(0, s.Lift, behind) * A(rad(s.Pitch), rad(yaw), rad(-s.turn * g.Bank * mv))
end

-- hedgehogs, coins, orbs: curl up when travelling and roll with the distance covered (Radius studs), then come
-- to rest upright the short way round and uncurl. Lift raises the ball so it rolls on its surface.
-- Side turns it side-on while rolling (a coin rolls on its edge like a wheel); Flip = now and then, when idle,
-- it jumps and flips once in the air (lands with s.Land).
function Modes.Roll(self, c, s)
	local r = c.Roll
	self.CurlA += ((s.speed > 1.5 and 1 or 0) - self.CurlA) * (1 - math.exp(-s.dt * 6))
	local k = smooth(self.CurlA)
	if s.speed > 1.5 then
		self.RollA += math.min(s.speed, ROLL_MAX) * s.dt / r.Radius
	else
		local rest = math.floor(self.RollA / TAU + 0.5) * TAU
		self.RollA += (rest - self.RollA) * (1 - math.exp(-s.dt * 5))
	end
	local side = r.Side and rad(r.Side) * k or 0
	local hop, flip = 0, 0
	if r.Flip then
		local _, x, pl = self:_pulse(r.Flip, s.t, r.Flip.Every, r.Flip.Time)
		if x >= 0 then
			hop, flip = bump(x) * r.Flip.Height * s.idle, smooth(x) * TAU * s.idle
			if x > 0.9 and not pl.Fired then
				pl.Fired, s.Land = true, true
			end
		end
	end
	s.Lift, s.Pitch = r.Lift * k + hop, 0
	s.Curl = k
	return CFrame.new(0, s.Lift + breathe(c, s), 0) * A(-self.RollA - flip, 0, rad(-s.turn * c.Body.Lean * s.mv)) * A(0, side, 0)
end

-- seals, penguins, tortoises: a slow side-to-side rock with each step; Tilt leans it forward while moving
-- (a seal's belly-slide)
function Modes.Waddle(self, c, s)
	local w, mv = c.Waddle, s.mv
	self.Gait += s.dt * w.Rate * (0.6 + 0.6 * pace(s.speed))
	local g = self.Gait * TAU
	s.Gait = g
	s.Lift = math.abs(sin(g)) * w.Bob * mv
	s.Pitch = -(w.Tilt or 0) * mv
	return CFrame.new(0, s.Lift + breathe(c, s), 0)
		* A(rad(s.Pitch), rad(sin(g) * w.Yaw * mv), rad(sin(g) * w.Roll * mv - s.turn * c.Body.Lean * mv))
end

-- crabs and beetles: quick skittering steps with a little bounce and rock; Side turns the body (degrees) while
-- travelling, so a crab goes sideways
function Modes.Scuttle(self, c, s)
	local sc, mv = c.Scuttle, s.mv
	self.Gait += s.dt * sc.StepRate * (0.6 + 0.8 * pace(s.speed))
	local g = self.Gait * TAU
	s.Gait = g
	s.Lift = math.abs(sin(g)) * sc.Bounce * mv
	s.Pitch = 0
	self.SideA += (sc.Side * math.clamp(mv * 2, 0, 1) - self.SideA) * (1 - math.exp(-s.dt * 5)) -- eases round, no snap
	return CFrame.new(0, s.Lift + breathe(c, s), 0) * A(0, rad(self.SideA), rad(sin(g) * sc.Rock * mv))
end

-- blobs and toads: discrete hops with a pause between. The body leaps ahead of the steadily moving root and
-- waits for it while sitting, so it doesn't slide along the ground. Faster travel means more hops, not longer
-- ones (Rate..MaxRate hops/s, Stride studs each); past MaxRate the lead shrinks so it never exceeds half a
-- Stride (it stays a smooth curve, so the body never pops).
-- A hop already started always finishes.
function Modes.Hop(self, c, s)
	local h = c.Hop
	local rate = math.clamp(s.speed / h.Stride, h.Rate, h.MaxRate)
	local x = self.HopX
	if x > 0 or s.speed > 1.5 then
		local nx = x + s.dt * rate
		if x < h.Air and nx >= h.Air then
			s.Land = true
		end
		x = nx >= 1 and (s.speed > 1.5 and nx - 1 or 0) or nx
	end
	self.HopX = x
	local air = math.min(x / h.Air, 1)
	local up = x > 0 and x < h.Air
	local stride = s.speed / rate
	local k = math.min(1, h.Stride * 0.5 / math.max(stride * (1 - h.Air), 0.001))
	local ahead = x > 0 and stride * k * (smooth(air) - x) or 0
	local squash = x >= h.Air and bump((x - h.Air) / 0.2) or 0
	s.Lift = up and bump(air) * h.Height or 0
	s.Pitch = (up and sin(air * TAU) * h.Pitch or 0) - squash * 5
	return CFrame.new(0, s.Lift - squash * h.Squash + breathe(c, s), -ahead) * A(rad(s.Pitch), 0, rad(-s.turn * c.Body.Lean * s.mv))
end

-- serpents: a travelling wave; Chain joints carry it down the body (see the Chain block). Airborne ones built
-- above their Root add a slow Bob.
function Modes.Slither(self, c, s)
	local sl, mv = c.Slither, s.mv
	self.Wave += s.dt * TAU * (sl.Rate + sl.MoveRate * mv * (0.6 + 0.6 * pace(s.speed)))
	local yaw = sin(self.Wave) * sl.Yaw * (sl.Idle * s.idle + mv)
	s.Lift = sl.Bob and sin(s.p * sl.BobRate * TAU) * sl.Bob or 0
	s.Pitch = 0
	s.HeadYaw = -yaw * 0.8 -- the head keeps looking ahead while the body swings
	return CFrame.new(sin(self.Wave + 1) * sl.Sway * mv, s.Lift + breathe(c, s), 0) * A(0, rad(yaw), rad(-s.turn * c.Body.Lean * mv))
end

----------------------------------------------------------------------------------------------------------------
-- Specials: signature moves. Called every frame with s.spX (0..1 progress, -1 when not playing) and s.spB (its
-- 0..1 bump). They add pose offsets to self.Off by joint name and may set s.Still (0..1 calms flapping and swaying).
-- Emitter bursts at fixed moments are data: Special.Bursts = {{emitter name, at progress, count}, ...}.
----------------------------------------------------------------------------------------------------------------
local Specials = {}
PetAnimator.Specials = Specials

-- Cinder Lynx: glances back and flicks its tail high (the ember shower is a burst)
function Specials.EmberFlick(self, sp, s)
	local b = s.spB
	if b <= 0 then
		return
	end
	local off = self.Off
	off.Body = A(rad(-3 * b), 0, 0)
	off.Neck = A(rad(8 * b), rad(-40 * b), 0)
	off.EarL = A(rad(-10 * b), 0, rad(6 * b))
	off.EarR = A(rad(-10 * b), 0, rad(-6 * b))
	off.Tail = A(rad(-55 * b), rad(sin(s.spX * math.pi * 6) * 14 * b), 0)
end

-- rears back with wings spread wide and jaw open, then holds the pose (the shockwave is a burst)
function Specials.Roar(self, sp, s)
	local b = s.spB
	if b <= 0 then
		return
	end
	local hold = ease(b)
	local off = self.Off
	off.Body = CFrame.new(0, sp.Rise * hold, sp.Rise * hold) * A(rad(sp.Rear * hold), 0, 0)
	off.Neck = A(rad(12 * hold), 0, 0)
	off.Jaw = A(rad(-sp.JawOpen * hold), 0, 0)
	off.WingL = A(0, rad(-sp.Spread * 0.4 * hold), rad(-sp.Spread * hold))
	off.WingR = A(0, rad(sp.Spread * 0.4 * hold), rad(sp.Spread * hold))
	off.Tail = A(rad(-15 * hold), 0, 0)
	s.Still = hold
end

-- transformation: a part ignites (drops its texture and goes Neon in a hot colour), named emitters surge, a prop swells,
-- light-ray beams fan out, and everything settles back when the move ends or is interrupted
-- Part or Parts = what ignites; Pose = extra joint angles at full strength (a trunk raised to trumpet)
function Specials.Ignite(self, sp, s)
	local st = self.IgniteState
	if not st then
		st = {Parts = {}, Grow = sp.Grow and self.Model:FindFirstChild(sp.Grow.Part), Rays = {}}
		for _, n in ipairs(sp.Parts or (sp.Part and {sp.Part}) or EMPTY) do
			local p = self.Model:FindFirstChild(n)
			table.insert(st.Parts, {p, p.Material, p.Color, p:IsA("MeshPart") and p.TextureID or false})
		end
		st.Size = st.Grow and st.Grow.Size
		for _, n in ipairs(sp.Rays or EMPTY) do
			local r = self.Fx[n]
			table.insert(st.Rays, {r, r.Width0, r.Width1})
		end
		st.Surge = sp.Surge and self:_emitters(sp.Surge.Emitters) or {}
		self.IgniteState = st
	end
	local b = s.spB
	if b <= 0 then
		if st.Lit then
			st.Lit, st.Hot = false, false
			for _, q in ipairs(st.Parts) do
				q[1].Material, q[1].Color = q[2], q[3]
				if q[4] then
					q[1].TextureID = q[4]
				end
			end
			if st.Grow then
				st.Grow.Size = st.Size
			end
			if st.Fill then
				st.Fill.FillTransparency = 1
			end
			for _, r in ipairs(st.Rays) do
				r[1].Enabled = false
			end
			self:_surge(st.Surge, 1)
		end
		return
	end
	st.Lit = true
	local hold = ease(b)
	-- Neon over a generated texture renders off-palette, so the part burns as a solid hot colour instead
	local hot = hold > 0.3
	for _, q in ipairs(st.Parts) do
		if hot ~= st.Hot then
			q[1].Material = hot and Enum.Material.Neon or q[2]
			if q[4] then
				q[1].TextureID = hot and "" or q[4]
			end
		end
		q[1].Color = q[3]:Lerp(sp.Hot, hold)
	end
	st.Hot = hot
	if st.Grow then
		st.Grow.Size = st.Size * (1 + sp.Grow.By * hold)
	end
	for _, r in ipairs(st.Rays) do
		r[1].Enabled = self.Lod == 0 and hold > 0.05
		r[1].Width0, r[1].Width1 = r[2] * hold, r[3] * hold
	end
	self:_surge(st.Surge, 1 + (sp.Surge and sp.Surge.By or 0) * hold)
	local off = self.Off
	off.Body = CFrame.new(0, sp.Rise * hold, 0) * A(rad(sp.Rear * hold), 0, 0)
	off.Neck = A(rad(10 * hold), 0, 0)
	for j, r in pairs(sp.Pose or NONE) do
		off[j] = A(rad(r.X * hold), rad(r.Y * hold), rad(r.Z * hold))
	end
	if sp.Fill then -- the whole body floods with light through the outline highlight
		st.Fill = st.Fill or self.Model:FindFirstChild("Outline")
		st.Fill.FillColor = sp.Hot
		st.Fill.FillTransparency = 1 - sp.Fill * hold
	end
	if sp.Spread then -- wings thrown wide (a wyrmling's Refraction)
		off.WingL = A(0, rad(-sp.Spread * 0.4 * hold), rad(-sp.Spread * hold))
		off.WingR = A(0, rad(sp.Spread * 0.4 * hold), rad(sp.Spread * hold))
	end
	s.Still = hold * 0.5
end

-- rears up and lifts (Rise studs, Rear degrees); petals, rings and the like are bursts
function Specials.Rear(self, sp, s)
	local hold = ease(s.spB)
	if hold <= 0 then
		return
	end
	self.Off.Body = CFrame.new(0, sp.Rise * hold, 0) * A(rad(sp.Rear * hold), 0, 0)
	s.Still = hold * 0.5
end

-- transformation: a part cycles through a list of colours (seasons), burning as solid Neon while it does, with a
-- named emitter recoloured to match; then it returns to its own texture
function Specials.Cycle(self, sp, s)
	local st = self.CycleState
	if not st then
		local part = self.Model:FindFirstChild(sp.Part)
		st = {Part = part, Material = part.Material, Color = part.Color, Texture = part.TextureID, Emitter = self.Fx[sp.Emitter]}
		st.EmitColor = st.Emitter and st.Emitter.Color
		self.CycleState = st
	end
	local x = s.spX
	if x < 0 then
		if st.Lit then
			st.Lit = false
			st.Part.Material, st.Part.Color, st.Part.TextureID = st.Material, st.Color, st.Texture
			if st.Emitter then
				st.Emitter.Color = st.EmitColor
			end
		end
		return
	end
	if not st.Lit then
		st.Lit = true
		st.Part.Material = Enum.Material.Neon
		st.Part.TextureID = ""
	end
	local n = #sp.Colors
	local f = x * n
	local i = math.min(n, math.floor(f) + 1)
	local col = sp.Colors[i]:Lerp(sp.Colors[math.min(n, i + 1)], smooth((f - (i - 1) - 0.7) / 0.3))
	st.Part.Color = col
	if st.Emitter then
		st.Emitter.Color = ColorSequence.new(col)
	end
	s.Still = s.spB * 0.5
end

-- turns the head a long way round (Yaw degrees, an owl's 180) to look behind, holds, and turns back; flashes
-- are bursts and the Glow flare
function Specials.Swivel(self, sp, s)
	local b = s.spB
	if b <= 0 then
		return
	end
	local hold = ease(b)
	self.Off.Neck = A(0, rad(sp.Yaw * hold), 0)
	s.Still = hold * 0.5
end

-- transformation: the whole body floods with light (the Outline highlight's fill fades in, Fill = peak opacity),
-- named emitters surge, the body lifts and arches; lights flare through Glow and bursts carry spouts and the like
function Specials.Luminesce(self, sp, s)
	local st = self.LumState
	if not st then
		st = {Fill = self.Model:FindFirstChild("Outline"), Surge = self:_emitters(sp.Surge.Emitters)}
		self.LumState = st
	end
	local hold = ease(s.spB)
	self:_surge(st.Surge, 1 + sp.Surge.By * hold)
	if hold <= 0 then
		if st.Lit then
			st.Lit = false
			st.Fill.FillTransparency = 1
		end
		return
	end
	st.Lit = true
	st.Fill.FillColor = sp.Color
	st.Fill.FillTransparency = 1 - sp.Fill * hold
	self.Off.Body = CFrame.new(0, sp.Rise * hold, 0) * A(rad(sp.Rear * hold), 0, 0)
	s.Still = hold * 0.4
end

-- a full roll around its length with a little rise (bubbles etc. are bursts); Axis = "X" makes it a
-- loop-the-loop instead. Pair with Finish = true: a roll can't stop halfway without snapping.
function Specials.Roll(self, sp, s)
	if s.spX < 0 then
		return
	end
	local a = rad(360 * smooth(s.spX))
	self.Off.Body = CFrame.new(0, sp.Rise * s.spB, 0) * (sp.Axis == "X" and A(a, 0, 0) or A(0, 0, a))
end

-- Show = parts that appear only during a roll (energy blades), Surge = emitters that flare with it (afterburners)
local rollBase = Specials.Roll
function Specials.Roll(self, sp, s)
	if sp.Show or sp.Surge then
		local st = self.RollState
		if not st then
			st = {Show = {}, Surge = sp.Surge and self:_emitters(sp.Surge.Emitters) or {}}
			for _, n in ipairs(sp.Show or EMPTY) do
				local p = self.Model:FindFirstChild(n)
				table.insert(st.Show, {p, p.Transparency})
			end
			self.RollState = st
		end
		local on = s.spX >= 0
		for _, q in ipairs(st.Show) do
			q[1].Transparency = on and q[2] + (1 - q[2]) * (1 - math.min(1, s.spB * 3)) or 1
		end
		self:_surge(st.Surge, 1 + (sp.Surge and sp.Surge.By or 0) * s.spB)
	end
	rollBase(self, sp, s)
end

-- claw machine: the claw (Claw joint) drops Drop studs onto the prize, grabs it, lifts it Lift studs... and drops it.
-- Then a sad droop (Droop degrees) of the body and the listed limbs.
function Specials.Grab(self, sp, s)
	local x = s.spX
	if x < 0 then
		return
	end
	local down = smooth(x / 0.22) * (1 - smooth((x - 0.34) / 0.22))
	local clawY = -sp.Drop * down + sp.Lift * bump((x - 0.34) / 0.5) * (x < 0.6 and 1 or 0)
	local prizeY = 0
	if x > 0.26 and x < 0.6 then
		prizeY = math.max(0, clawY + sp.Drop)
	elseif x >= 0.6 and x < 0.7 then
		local f = (x - 0.6) / 0.1 -- falls back down with a little bounce
		prizeY = math.max(0, (1 - f * f) * (sp.Lift * 0.6)) + math.abs(sin(f * math.pi * 2)) * 0.05
	end
	local off = self.Off
	off[sp.Claw] = CFrame.new(0, clawY, 0) * A(0, rad(sin(x * 30) * 6 * down), 0)
	off[sp.Prize] = CFrame.new(0, prizeY, 0)
	local droop = bump((x - 0.66) / 0.34)
	off.Body = A(rad(-sp.Droop * droop), 0, 0)
	for _, n in ipairs(sp.Limbs or EMPTY) do
		off[n] = A(rad(sp.Droop * 1.5 * droop), 0, 0)
	end
	s.Still = math.max(down, droop)
end

-- a change of form: Hide parts fade out and Show parts fade in (with a glitchy flicker at the swap). Scatter joints
-- come apart in order: they rattle, burst straight out from the body's centre (Radius studs), circle it together
-- once, fly home along the same path and lock back in with a recoil. Used for a phantom's cube form and a boss's
-- Phase 2. Pair Scatter with Finish = true.
function Specials.Morph(self, sp, s)
	local st = self.MorphState
	if not st then
		st = {Hide = {}, Show = {}, Scatter = {}}
		for _, n in ipairs(sp.Hide or EMPTY) do
			local p = self.Model:FindFirstChild(n)
			table.insert(st.Hide, {p, p.Transparency})
		end
		for _, n in ipairs(sp.Show or EMPTY) do
			local p = self.Model:FindFirstChild(n)
			table.insert(st.Show, {p, p.Transparency})
		end
		for _, n in ipairs(sp.Scatter or EMPTY) do
			local m = self.M[n]
			if m then
				-- Part0's centre seen from the joint (joint frames use pet axes), and the way out from it; pieces
				-- sitting right above the centre (a head) go straight up
				local c = m.C0:Inverse().Position
				local away = Vector3.new(-c.X, 0, -c.Z)
				away = away.Magnitude > 0.3 and away.Unit or Vector3.yAxis
				local axis = away:Cross(Vector3.yAxis)
				table.insert(st.Scatter, {n, c, away, axis.Magnitude > 0 and axis.Unit or nil})
			end
		end
		self.MorphState = st
	end
	local x = s.spX
	if x < 0 then
		if st.Active then
			st.Active = false
			for _, q in ipairs(st.Hide) do
				q[1].Transparency = q[2]
			end
			for _, q in ipairs(st.Show) do
				q[1].Transparency = q[2]
			end
		end
		return
	end
	st.Active = true
	local form, rise = ease(s.spB), 0
	if #st.Scatter > 0 then
		-- 0-.1 rattle, .1-.3 burst out, .3-.76 one turn together, .76-.92 home, .92-1 lock-in recoil
		local out = smooth((x - 0.1) / 0.2) * (1 - smooth((x - 0.76) / 0.16))
		local turn = A(0, smooth((x - 0.3) / 0.46) * TAU, 0)
		local rattle = bump(x / 0.1) * 0.04
		for i, q in ipairs(st.Scatter) do
			local c, away, axis = q[2], q[3], q[4]
			local push = away * sp.Radius * out + Vector3.new(sin(s.t * 55 + i) * rattle, (0.25 * sp.Radius + sin(x * TAU * 2 + i) * 0.12) * out, 0)
			local tilt = axis and CFrame.fromAxisAngle(axis, rad(-25) * out) or A(0, 0, 0)
			self.Off[q[1]] = CFrame.new(c) * turn * CFrame.new(push - c) * tilt
		end
		form = out
		rise = -0.06 * bump(x / 0.1) - 0.1 * bump((x - 0.9) / 0.1) -- braces, then the armour slams home
	end
	-- flicker between the two forms around the swap, like a bad signal
	local swapped = form > 0.5 or (form > 0.25 and sin(s.t * 60) > 0)
	for _, q in ipairs(st.Hide) do
		q[1].Transparency = swapped and 1 or q[2]
	end
	for _, q in ipairs(st.Show) do
		q[1].Transparency = swapped and 0 or 1
	end
	self.Off.Body = CFrame.new(0, sp.Rise * form + rise, 0)
	s.Still = form
end

-- rises into a tight coil: the listed joints curl and lift, the Spin prop speeds up and named emitters spray,
-- then it all unwinds
function Specials.Coil(self, sp, s)
	self.CoilSurge = self.CoilSurge or self:_emitters(sp.Surge.Emitters)
	local hold = ease(s.spB)
	self:_surge(self.CoilSurge, 1 + sp.Surge.By * hold)
	if hold <= 0 then
		return
	end
	local off = self.Off
	off.Body = CFrame.new(0, sp.Rise * hold, 0) * A(rad(sp.Rear * hold), 0, 0)
	for _, n in ipairs(sp.Joints) do
		off[n] = A(rad(-sp.Lift * hold), rad(sp.Curl * hold), 0)
	end
	s.SpinBoost = sp.SpinBoost * hold
	s.Still = hold * 0.7
end

-- Secret mechanic (a wyrm's Phase Shift): fades out, reappears Jump studs away (pet space; the follow slot is on
-- the owner's left, so +X lands on their right), lingers, then fades out and back home. Beams go dark while it's
-- gone; bursts mark the flashes at both points. Needs no Finish: an interrupt mirrors the progress, which lands
-- in the matching fade, so the jump home always happens while it's invisible.
function Specials.Phase(self, sp, s)
	local st = self.PhaseState
	if not st then
		st = {Parts = {}}
		for _, p in ipairs(self.Model:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 1 then
				table.insert(st.Parts, {p, p.Transparency})
			end
		end
		self.PhaseState = st
	end
	local x = s.spX
	if x < 0 then
		if st.Active then
			st.Active = false
			for _, q in ipairs(st.Parts) do
				q[1].Transparency = q[2]
			end
			for line, on in pairs(self.Lines) do
				if line:IsA("Beam") then
					line.Enabled = on and self.Lod == 0
				end
			end
		end
		return
	end
	st.Active = true
	-- gone by .2, back in by .3; gone again by .8 (the jump home happens while invisible), back in by .9
	local fade = math.max(smooth((x - 0.1) / 0.1) * (1 - smooth((x - 0.2) / 0.1)), smooth((x - 0.7) / 0.1) * (1 - smooth((x - 0.8) / 0.1)))
	for _, q in ipairs(st.Parts) do
		q[1].Transparency = q[2] + (1 - q[2]) * fade
	end
	for line, on in pairs(self.Lines) do
		if line:IsA("Beam") then
			line.Enabled = on and self.Lod == 0 and fade < 0.5
		end
	end
	if x >= 0.2 and x < 0.8 then
		self.Off.Body = CFrame.new(sp.Jump)
	end
	s.Still = 0.5
end

-- an armour hound's Lost My Head: the Joint pops straight up (Height studs), bobs there while it spins round Spins
-- times, then drops back on under gravity with a clunk. Surge emitters (flame from the empty neck) flare while it's
-- off. Pair with Finish = true.
function Specials.PopOff(self, sp, s)
	self.PopSurge = self.PopSurge or self:_emitters(sp.Surge.Emitters)
	local x = s.spX
	if x < 0 then
		self:_surge(self.PopSurge, 1)
		return
	end
	local up = smooth(x / 0.18)
	local fall = math.clamp((x - 0.78) / 0.14, 0, 1)
	local off = up * (1 - fall * fall) -- 1 while it's up, accelerates back down
	local clunk = bump((x - 0.92) / 0.08)
	local h = sp.Height * off + sin(x * TAU * 1.5) * 0.08 * off - clunk * 0.05
	self.Off[sp.Joint] = CFrame.new(0, h, 0) * A(rad(clunk * 8), smooth((x - 0.15) / 0.6) * TAU * sp.Spins, 0)
	self:_surge(self.PopSurge, 1 + sp.Surge.By * off)
	s.Still = off
end

-- transformation (a chimera's Soul Rotation): each head in Heads awakens in turn, rearing up (Lift degrees) while its
-- emitter surges; the Light and the body's Flame emitter take that head's colour, then it all settles back
function Specials.Awaken(self, sp, s)
	local st = self.AwakenState
	if not st then
		st = {Light = self.Fx[sp.Light], Flame = self.Fx[sp.Flame], Heads = {}}
		st.LightColor = st.Light and st.Light.Color
		st.FlameColor = st.Flame and st.Flame.Color
		for i, h in ipairs(sp.Heads) do
			st.Heads[i] = self:_emitters({h.Emitter})
		end
		self.AwakenState = st
	end
	local x = s.spX
	if x < 0 then
		if st.Lit then
			st.Lit = false
			if st.Light then
				st.Light.Color = st.LightColor
			end
			if st.Flame then
				st.Flame.Color = st.FlameColor
			end
			for _, list in ipairs(st.Heads) do
				self:_surge(list, 1)
			end
		end
		return
	end
	st.Lit = true
	local n = #sp.Heads
	local f = x * n
	local cur = math.min(n, math.floor(f) + 1)
	for i, h in ipairs(sp.Heads) do
		local k = i == cur and bump(f - (i - 1)) or 0
		self:_surge(st.Heads[i], 1 + sp.By * k)
		if k > 0 then
			self.Off[h.Joint] = A(rad(-sp.Lift * smooth(k * 1.5)), 0, 0)
		end
	end
	-- colours blend across each handover so the flame never jumps
	local col = sp.Heads[cur].Color:Lerp(sp.Heads[math.min(n, cur + 1)].Color, smooth((f - (cur - 1) - 0.8) / 0.2))
	if st.Light then
		st.Light.Color = st.LightColor:Lerp(col, ease(s.spB, 4))
	end
	if st.Flame then
		st.Flame.Color = ColorSequence.new(col)
	end
	s.Still = ease(s.spB, 4) * 0.4
end

-- a pegasus's Comet Dive: wings fold (Pose), it climbs, then dives forward in an arc (Dist studs ahead, Drop below
-- its hover) and pulls up back into place; Surge emitters (its comet trail) blaze through the dive. Pair with Finish.
function Specials.Dive(self, sp, s)
	self.DiveSurge = self.DiveSurge or self:_emitters(sp.Surge.Emitters)
	local x = s.spX
	if x < 0 then
		self:_surge(self.DiveSurge, 1)
		return
	end
	local a = smooth(x) * TAU -- once round an ellipse: up, forward and down, back and up
	local y = (1 - math.cos(a)) * 0.5 * -sp.Drop + sin(a) * sp.Rise
	local z = -sin(a * 0.5) * sp.Dist
	local pitch = -math.cos(a) * sp.Pitch * bump(x)
	self.Off.Body = CFrame.new(0, y, z) * A(rad(pitch), 0, 0)
	local fold = ease(s.spB, 3)
	for j, r in pairs(sp.Pose or NONE) do
		self.Off[j] = A(rad(r.X * fold), rad(r.Y * fold), rad(r.Z * fold))
	end
	self:_surge(self.DiveSurge, 1 + sp.Surge.By * fold)
	s.Still = fold
end

-- a skywhale's Moonrise: the Moons (authored invisible) rise out of its ring (Rise studs), circle it once (Radius
-- studs) and sink back in and vanish
function Specials.Moonrise(self, sp, s)
	local st = self.MoonState
	if not st then
		st = {}
		for _, n in ipairs(sp.Moons) do
			table.insert(st, {self.Model:FindFirstChild(n)})
		end
		self.MoonState = st
	end
	local x = s.spX
	local up = x >= 0 and smooth(x / 0.2) * (1 - smooth((x - 0.8) / 0.2)) or 0
	local n = #st
	for i, q in ipairs(st) do
		q[1].Transparency = 1 - up
		if up > 0 then
			local a = (i - 1) / n * TAU + smooth((x - 0.15) / 0.7) * TAU
			self.Off[sp.Moons[i]] = CFrame.new(math.cos(a) * sp.Radius * up, sp.Rise * up + sin(a * 2) * 0.1, sin(a) * sp.Radius * up)
		end
	end
	s.Still = up * 0.5
end

-- Secret mechanic (a star spider's Weave): the Stars (props jointed to the Root) fly out to the Shape points
-- (pet space; the owner stands at about (3.6, 0, -1.6)), Threads (beams between them) spin up, the constellation
-- hangs there, then the threads unravel and the stars fly home
function Specials.Weave(self, sp, s)
	local st = self.WeaveState
	if not st then
		st = {Threads = {}}
		for i, n in ipairs(sp.Stars) do
			st[i] = sp.Shape[i] - self.M[n].C0.Position
		end
		for _, n in ipairs(sp.Threads) do
			local b = self.Fx[n]
			table.insert(st.Threads, {b, b.Width0, b.Width1})
			b.Enabled = false
			self.Lines[b] = nil -- the weave owns these, not the LOD toggle
		end
		self.WeaveState = st
	end
	local x = s.spX
	if x < 0 then
		if st.Active then
			st.Active = false
			for _, q in ipairs(st.Threads) do
				q[1].Enabled = false
			end
		end
		return
	end
	st.Active = true
	local n = #sp.Stars
	for i, name in ipairs(sp.Stars) do
		-- each star leaves a moment after the one before, and returns in the same order
		local d = (i - 1) / n * 0.08
		local out = smooth((x - d) / 0.18) * (1 - smooth((x - 0.78 - d) / 0.14))
		self.Off[name] = CFrame.new(st[i] * out)
	end
	local woven = smooth((x - 0.25) / 0.12) * (1 - smooth((x - 0.66) / 0.12))
	for i, q in ipairs(st.Threads) do
		-- threads draw in one after another
		local k = math.clamp(woven * #st.Threads - (i - 1) * 0.5, 0, 1)
		q[1].Enabled = k > 0 and self.Lod == 0
		q[1].Width0, q[1].Width1 = q[2] * k, q[3] * k
	end
	s.Still = 0.5 * woven
end

-- a jellyfish's Pulse Dash: the bell squeezes (Pose joints curl in), then it shoots forward Dist studs, tipping
-- Tip degrees, and drifts back to its place while the Pose joints stream out behind; the light ring is a burst.
-- Pair with Finish = true.
function Specials.Dash(self, sp, s)
	local x = s.spX
	if sp.Show then -- beams that draw in only for the move (a koi's portal rings)
		local st = self.DashState
		if not st then
			st = {}
			for _, n in ipairs(sp.Show) do
				local b = self.Fx[n]
				table.insert(st, {b, b.Width0, b.Width1})
				self.Lines[b] = nil -- the move owns these, not the LOD toggle
				b.Enabled = false
			end
			self.DashState = st
		end
		local vis = x >= 0 and smooth(x / 0.15) * (1 - smooth((x - 0.55) / 0.15)) or 0
		for _, q in ipairs(st) do
			q[1].Enabled = vis > 0.02 and self.Lod == 0
			q[1].Width0, q[1].Width1 = q[2] * vis, q[3] * vis
		end
	end
	if x < 0 then
		return
	end
	local squeeze = bump(x / 0.3)
	local shoot = smooth((x - 0.2) / 0.12) * (1 - smooth((x - 0.4) / 0.6))
	self.Off.Body = CFrame.new(0, -0.15 * squeeze + sp.Rise * shoot, -sp.Dist * shoot) * A(rad(-sp.Tip * shoot), 0, 0)
	local k = squeeze - shoot * 0.6
	for j, r in pairs(sp.Pose or NONE) do
		self.Off[j] = A(rad(r.X * k), rad(r.Y * k), rad(r.Z * k))
	end
	s.Still = math.max(squeeze, shoot)
end

----------------------------------------------------------------------------------------------------------------

-- speed: studs/s the pet is travelling; turn: -1..1 how hard it is turning (right positive);
-- camDist: studs from the camera (optional, enables LOD)
function PetAnimator:Step(dt, t, speed, turn, camDist)
	local lod = camDist and (camDist > 140 and 2 or camDist > 60 and 1 or 0) or 0
	if lod ~= self.Lod then
		self:_setLod(lod)
	end
	if lod == 2 then
		return
	end
	self.Held += dt
	if lod == 1 then
		self.Skip = not self.Skip
		if self.Skip then
			return
		end
	end
	dt, self.Held = self.Held, 0
	local cfgStep = self.Cfg.Stepped
	if cfgStep then -- 8-bit pets: hold the pose between steps
		self.StepAcc += dt
		if self.StepAcc < 1 / cfgStep then
			return
		end
		dt, self.StepAcc = self.StepAcc, 0
	end

	local c = self.Cfg
	local s = self.S
	local p = t + self.Phase
	self.Moving += (math.clamp(speed / 10, 0, 1) - self.Moving) * (1 - math.exp(-dt * 6))
	local mv = self.Moving
	local idle = 1 - mv
	self.Turn += (turn - self.Turn) * (1 - math.exp(-dt * 8))
	turn = self.Turn
	s.t, s.p, s.dt, s.speed, s.turn, s.mv, s.idle = t, p, dt, speed, turn, mv, idle
	s.Land, s.Still, s.HeadYaw, s.Gait, s.SpinBoost, s.Curl = false, 0, 0, 0, 0, 0

	-- special move: starts only when standing still. If the pet starts moving it jumps to the matching point on
	-- the way down (same pose, so nothing pops) and winds down three times as fast, unless it must Finish.
	local sp = self.Special
	if c.Special then
		if sp.Next < 0 then
			sp.Next = t + randRange(c.Special.Every, self.Rng)
		end
		if sp.X < 0 then
			if mv < 0.15 and t >= sp.Next then
				sp.X, sp.Out = 0, false
				table.clear(sp.Fired)
			end
		else
			if mv > 0.4 and not sp.Out and not c.Special.Finish then
				sp.Out = true
				sp.X = math.max(sp.X, 1 - sp.X)
			end
			sp.X += dt / c.Special.Duration * (sp.Out and 3 or 1)
			if sp.X >= 1 then
				sp.X = -1
				sp.Next = t + randRange(c.Special.Every, self.Rng)
			end
		end
	end
	local spX = sp.X
	s.spX, s.spB = spX, bump(spX)

	local body = Modes[c.Mode or "Bound"](self, c, s)
	if s.Land then
		self.LandAt = t
		local lf = c.LandFx and self.Fx[c.LandFx[1]]
		if lf and lod == 0 then
			lf:Emit(c.LandFx[2])
		end
	end
	table.clear(self.Off)
	if c.Special then
		Specials[c.Special.Kind](self, c.Special, s)
		for i, bu in ipairs(c.Special.Bursts or EMPTY) do
			if spX >= bu[2] and not sp.Fired[i] and not sp.Out then
				sp.Fired[i] = true
				local e = self.Fx[bu[1]]
				if e then
					e:Emit(bu[3])
				end
			end
		end
	end
	local calm = 1 - s.Still
	-- glitch: a random joint jumps for a frame or two now and then; ghost copies blink
	local gl = c.Glitch
	if gl then
		local gs = self.GlitchState
		if t >= gs.Next then
			local r = self.Rng
			gs.Joint = gl.Joints[r:NextInteger(1, #gl.Joints)]
			gs.Jump = CFrame.new(r:NextNumber(-1, 1) * gl.Amount, r:NextNumber(-1, 1) * gl.Amount, r:NextNumber(-1, 1) * gl.Amount)
			gs.Until = t + gl.Frames / 60
			gs.Next = t + randRange(gl.Every, r)
		end
		local on = t < gs.Until
		if on and not self.Off[gs.Joint] then
			self.Off[gs.Joint] = gs.Jump
		end
		-- ghost copies tear off to either side (Split studs) only while the glitch lasts, like a bad video signal
		for i, q in ipairs(gs.Copies) do
			if on ~= gs.On then
				q[1].Transparency = on and q[2] or 1
			end
			if on then
				self.Off[q[1].Name] = CFrame.new((i % 2 == 1 and -1 or 1) * (gl.Split or 0), 0, 0)
			end
		end
		gs.On = on
	end
	self:_set("Body", body)

	-- head: slow look-around when idle, steadies against the body when moving, now and then a curious tilt
	local h = c.Head
	local roll = 0
	if h then
		local lookYaw = (sin(p * h.LookRate * TAU) * h.LookYaw + sin(p * h.LookRate * 2.7 * TAU) * h.LookYaw * 0.25) * idle
		local lookPitch = sin(p * h.LookRate * 1.6 * TAU) * h.LookPitch * idle
		if h.Tilt then
			local tb, _, pl = self:_pulse(h, t, h.Tilt.Every, h.Tilt.Time)
			roll = ease(tb, 2) * h.Tilt.Angle * pl.Side * idle
		end
		-- Graze: now and then the head dips down to graze (degrees) and comes back up
		if h.Graze then
			local gb = self:_pulse(h.Graze, t, h.Graze.Every, h.Graze.Time)
			lookPitch -= ease(gb, 2.5) * h.Graze.Angle * idle
		end
		-- Curl tucks the head in while a Roll pet is balled up
		lookPitch -= (s.Curl or 0) * (h.Tuck or 0) + mv * (h.Down or 0) -- Down = head lowered while moving
		self:_set("Neck", A(rad(lookPitch - s.Pitch * 0.7), rad(lookYaw + turn * 15 * mv + s.HeadYaw), rad(roll)))
	end

	-- ears: random twitches, swept back while running; floppy ears (Ears.Flop) hang against the head's tilt
	-- on a spring and flap with each stride
	local e = c.Ears
	if e then
		local fl = e.Flop
		local flap = 0
		if fl then
			local goal = -roll * fl.Swing - turn * 12 * mv
			self.SwingV += ((goal - self.Swing) * 90 - self.SwingV * 7) * dt
			self.Swing += self.SwingV * dt
			flap = (0.5 + 0.5 * sin(s.Gait * 2)) * fl.Flap * mv
		end
		for _, ear in ipairs(EARS) do
			local tw = self:_pulse(ear[1], t, e.TwitchEvery, 0.22)
			self:_set(ear[1], A(rad(e.Back * mv), 0, rad(ear[2] * (tw * e.TwitchAngle - flap) + self.Swing)))
		end
	end

	-- tail: lazy sway when idle (plus bursts of wagging), streams back and up when moving
	local tl = c.Tail
	if tl then
		local sway = sin(p * tl.SwayRate * TAU) * tl.Sway * (idle + 0.4 * mv) - turn * 20 * mv
		if tl.Wag then
			local wb = self:_pulse(tl, t, tl.Wag.Every, tl.Wag.Time)
			sway += sin(t * tl.Wag.Rate * TAU) * tl.Wag.Angle * ease(wb, 3)
		end
		local lift = -(tl.Stream * mv) - 8 * sin(p * tl.SwayRate * 0.5 * TAU) * idle
		self:_set("Tail", A(rad(lift), rad(sway * calm), 0))
	end

	-- wings: flap faster and wider when moving; Glide holds them out for a beat every Glide beats
	local w = c.Wings
	if w then
		self.Flap += dt * TAU * (w.Rate + (w.MoveRate - w.Rate) * mv)
		local ang = sin(self.Flap) * (w.Amp + (w.MoveAmp - w.Amp) * mv) * calm + w.Rest
		if w.Glide then
			local g = bump(self.Flap / TAU % (w.Glide + 1) - w.Glide) * mv
			ang += (w.GlideAngle - ang) * g
		end
		local sweep = w.Sweep * mv
		self:_set("WingL", A(0, rad(sweep), rad(-ang)))
		self:_set("WingR", A(0, rad(-sweep), rad(ang)))
	end

	-- segment chain: the body's wave travels down the joints, each a little behind the one before.
	-- Rise adds a slower up-and-down wave, so airborne serpents coil in a spiral instead of a flat S.
	-- Upright = the chain stands up (a rearing serpent), so the side-to-side wave bends about Z instead of Y.
	local ch = c.Chain
	if ch then
		for i, name in ipairs(ch.Joints) do
			local k = ch.Idle * idle + mv
			local yaw = sin(self.Wave - i * ch.Lag) * ch.Amp * k - turn * ch.Bend * mv
			local pitch = ch.Rise and math.cos(self.Wave * 0.5 - i * ch.Lag) * ch.Rise * k or 0
			if ch.Upright then
				self:_set(name, A(rad(pitch * calm), 0, rad(yaw * calm)))
			else
				self:_set(name, A(rad(pitch * calm), rad(yaw * calm), 0))
			end
		end
	end

	-- wobbles: any joint that sways (Rot, degrees) or shifts (Pos, studs) on a wave. Pulse = one push per cycle
	-- then rest; Every = random-interval pulses (Emit fires an emitter as it starts); Land = jiggle after landings;
	-- Sweep = fixed offset while moving
	local wobRate = 1 + MOVE_WOBBLE * mv * pace(s.speed)
	local wobCf = self.WobCf
	table.clear(wobCf)
	for wi, wb in ipairs(c.Wobble or EMPTY) do
		local k
		if wb.Every then
			local x, pl
			k, x, pl = self:_pulse(wb, t, wb.Every, wb.Time)
			if wb.Emit and x >= 0.15 and not pl.Fired then
				pl.Fired = true
				local em = self.Fx[wb.Emit[1]]
				if em then
					em:Emit(wb.Emit[2])
				end
			end
		elseif wb.Steer then
			-- tilts toward each of 8 directions in turn, like a joystick being steered (Rot.X = tilt degrees)
			local ph = p * wb.Rate
			local dir = (math.floor(ph) % 8) * math.pi / 4
			local kk = bump(ph - math.floor(ph)) * ((wb.Idle or 1) * idle + (wb.Moving or 0) * mv)
			local cf = A(rad(math.cos(dir) * wb.Rot.X * kk), 0, rad(sin(dir) * wb.Rot.X * kk))
			wobCf[wb.Joint] = wobCf[wb.Joint] and wobCf[wb.Joint] * cf or cf
			continue
		else
			-- idle wobbles keep their rate; the ones that also play while moving speed up with travel
			local wp = self.WobPh
			wp[wi] = (wp[wi] or p * wb.Rate) + dt * wb.Rate * (wb.Moving and wobRate or 1)
			local ph = wp[wi] + (wb.Phase or 0)
			if wb.Pulse then
				k = bump((ph - math.floor(ph)) / wb.Pulse)
			else
				k = sin(ph * TAU)
			end
		end
		k *= ((wb.Idle or 1) * idle + (wb.Moving or 0) * mv) * calm
		if wb.Land then
			local since = t - self.LandAt
			k += sin(since * 28) * math.exp(-since * 7) * wb.Land
		end
		local r, sw = wb.Rot or ZERO, wb.Sweep or ZERO
		-- SweepPos = fixed shift while moving (a cloud trailing behind)
		local cf = CFrame.new((wb.Pos or ZERO) * k + (wb.SweepPos or ZERO) * mv) * A(rad(r.X * k + sw.X * mv), rad(r.Y * k + sw.Y * mv), rad(r.Z * k + sw.Z * mv))
		wobCf[wb.Joint] = wobCf[wb.Joint] and wobCf[wb.Joint] * cf or cf
	end
	for joint, cf in pairs(wobCf) do
		self:_set(joint, cf)
	end

	-- rotors: spin continuously, faster while moving
	local sp2 = c.Spinners
	if sp2 then
		self.SpinR = (self.SpinR or 0) + dt * TAU * (sp2.Rate + (sp2.MoveRate - sp2.Rate) * mv)
		for i, name in ipairs(sp2.Joints) do
			self:_set(name, A(0, self.SpinR * (i % 2 == 0 and -1 or 1), 0))
		end
	end

	-- walk cycle: legs swing alternately with the gait (Swing degrees), knees lift on the forward swing
	local wk = c.Walk
	if wk then
		for _, leg in ipairs(wk.Legs) do
			local ph = s.Gait + (leg[2] > 0 and 0 or math.pi)
			local sw = sin(ph) * wk.Swing * mv
			self:_set(leg[1], CFrame.new(0, math.max(0, math.cos(ph)) * wk.Lift * mv, 0) * A(rad(sw), 0, 0))
		end
	end

	-- orbiting pieces: circle their joint (TiltX 90 stands the circle up like a halo), pull in tighter while running.
	-- Face = point along the path (escort fish) instead of tumbling by Spin. Height raises the circle (studs), Long
	-- stretches it front-to-back into an oval so it clears a long body
	local o = c.Orbit
	if o then
		local n = #o.Parts
		for i, name in ipairs(o.Parts) do
			local ang = (t * o.Rate + (i - 1) / n) * TAU
			local r = o.Radius * (1 - 0.2 * mv)
			local y = sin(t * 1.3 + i * 2) * o.Bob + s.Lift * 0.6 + (o.Height or 0)
			local turnTo = o.Face and A(0, math.pi - ang, 0) or A(0, t * o.Spin + i, 0)
			self:_set(name, A(rad(o.TiltX or 0), 0, rad(o.Tilt)) * CFrame.new(math.cos(ang) * r, y, sin(ang) * r * (o.Long or 1)) * turnTo)
		end
	end

	-- a single floating prop that turns in place (sun discs, rings); a special can speed it up (s.SpinBoost)
	local sn = c.Spin
	if sn then
		self.SpinA += dt * sn.Rate * (1 + s.SpinBoost) * TAU
		self:_set(sn.Joint, CFrame.new(0, sin(p * 0.6 * TAU) * sn.Bob + s.Lift * 0.5, 0) * A(0, 0, self.SpinA))
	end

	-- effects that respond to motion and to the special
	for i, gl in ipairs(c.Glow or EMPTY) do
		local l = self.Fx[gl.Light]
		if l then
			l.Brightness = self.GlowBase[i] * (1 + gl.Flare * s.spB) + sin(p * 7 + i) * gl.Flicker
		end
	end
	local moving = mv > 0.35
	for _, name in ipairs(c.MoveFx or EMPTY) do
		local f = self.Fx[name]
		if f then
			f.Enabled = moving and (self.Lines[f] == nil or lod == 0)
		end
	end

	-- special poses and glitches on joints no block drives (shell halves, spikes, ghost copies) still have to show,
	-- and must let go when they end
	local loose, done = self.Loose, self.Done
	for name, off in pairs(self.Off) do
		local m = self.M[name]
		if m and not done[name] then
			m.Transform = off
			loose[name] = true
		end
	end
	for name in pairs(loose) do
		if not self.Off[name] then
			if not done[name] then
				self.M[name].Transform = CFrame.identity
			end
			loose[name] = nil
		end
	end
	table.clear(done)
end

return PetAnimator

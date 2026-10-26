--[[
	PetAnimator (Pet Lab draft)
	Code-driven animation for rigged premium pets: no Animation assets, so nothing has to be uploaded
	under the place owner's account. Each frame the follow code calls :Step(dt, t, speed, turn, camDist) and the
	animator blends idle and moving poses onto the pet's Motor6D.Transform values.

	Everything about how a pet moves is data in its PetConfigs entry:
	  Mode      follow style, a function in PetAnimator.Modes (Bound, Hover, Hop, Slither). It drives the Body joint.
	  Head, Ears, Tail, Wings, Chain, Wobble, Orbit, Spin   optional blocks for the joints they name.
	  Special   signature move, a function in PetAnimator.Specials, played every few seconds while standing still.
	  Glow, MoveFx   lights that flicker and flare with the special; trails and emitters that only run while moving.
	  LandFx    {emitter name, count} burst every time the mode lands (hops, bounds).
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

local function randRange(r, rng)
	return r[1] + rng:NextNumber() * (r[2] - r[1])
end

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
	self.Gait, self.Half, self.Flap, self.Wave, self.HopX = 0, 0, 0, 0, 0
	self.LandAt = -100
	self.Swing, self.SwingV = 0, 0
	self.Pulses = {}
	self.Off = {} -- this frame's pose offsets from the special, by joint name
	self.S = {} -- this frame's shared values (mode, special) for the joint blocks
	self.Held, self.Skip, self.RateScale = 0, false, 1
	self.Special = {Next = cfg.Special and randRange(cfg.Special.Every, self.Rng) or math.huge, At = -1, Fired = {}}
	return self
end

function PetAnimator:_set(name, cf)
	local m = self.M[name]
	if m then
		local off = self.Off[name]
		m.Transform = off and cf * off or cf
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
	self.Gait += s.dt * m.HopRate * (0.7 + 0.5 * math.clamp(s.speed / 16, 0, 1))
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

-- fliers: bob, drift in a lazy figure-eight when idle, heave with each downstroke, pitch forward and bank when flying
function Modes.Hover(self, c, s)
	local h, mv = c.Hover, s.mv
	local bob = sin(s.p * h.BobRate * TAU) * h.Bob
	local heave = -math.cos(self.Flap) * h.Heave * (0.4 + 0.6 * mv)
	local d = h.Drift * s.idle
	local w = s.p * h.DriftRate * TAU
	s.Lift = bob + heave
	s.Pitch = -h.Tilt * mv
	return CFrame.new(sin(w) * d, s.Lift, sin(w * 2) * d * 0.5) * A(rad(s.Pitch), 0, rad(-s.turn * h.Bank * mv))
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

-- serpents: a travelling wave; Chain joints carry it down the body (see the Chain block)
function Modes.Slither(self, c, s)
	local sl, mv = c.Slither, s.mv
	self.Wave += s.dt * TAU * (sl.Rate + sl.MoveRate * mv * (0.6 + 0.6 * math.clamp(s.speed / 16, 0, 1)))
	local yaw = sin(self.Wave) * sl.Yaw * (sl.Idle * s.idle + mv)
	s.Lift, s.Pitch = 0, 0
	s.HeadYaw = -yaw * 0.8 -- the head keeps looking ahead while the body swings
	return CFrame.new(sin(self.Wave + 1) * sl.Sway * mv, breathe(c, s), 0) * A(0, rad(yaw), rad(-s.turn * c.Body.Lean * mv))
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
	local hold = math.min(1, b * 1.6)
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
function Specials.Ignite(self, sp, s)
	local st = self.IgniteState
	if not st then
		st = {Part = self.Model:FindFirstChild(sp.Part), Grow = sp.Grow and self.Model:FindFirstChild(sp.Grow.Part), Rays = {}, Surge = {}}
		st.Material, st.Color, st.Texture = st.Part.Material, st.Part.Color, st.Part.TextureID
		st.Size = st.Grow and st.Grow.Size
		for _, n in ipairs(sp.Rays or EMPTY) do
			local r = self.Fx[n]
			table.insert(st.Rays, {r, r.Width0, r.Width1})
		end
		for _, e in ipairs(self.Emitters) do
			if table.find(sp.Surge.Emitters, e[1].Name) then
				table.insert(st.Surge, e)
			end
		end
		self.IgniteState = st
	end
	local b = s.spB
	if b <= 0 then
		if st.Lit then
			st.Lit, st.Hot = false, false
			st.Part.Material, st.Part.Color, st.Part.TextureID = st.Material, st.Color, st.Texture
			if st.Grow then
				st.Grow.Size = st.Size
			end
			for _, r in ipairs(st.Rays) do
				r[1].Enabled = false
			end
			for _, e in ipairs(st.Surge) do
				e[1].Rate = e[2] * self.RateScale
			end
		end
		return
	end
	st.Lit = true
	local hold = math.min(1, b * 1.6)
	-- Neon over a generated texture renders off-palette, so the part burns as a solid hot colour instead
	local hot = hold > 0.3
	if hot ~= st.Hot then
		st.Hot = hot
		st.Part.Material = hot and Enum.Material.Neon or st.Material
		st.Part.TextureID = hot and "" or st.Texture
	end
	st.Part.Color = st.Color:Lerp(sp.Hot, hold)
	if st.Grow then
		st.Grow.Size = st.Size * (1 + sp.Grow.By * hold)
	end
	for _, r in ipairs(st.Rays) do
		r[1].Enabled = self.Lod == 0 and hold > 0.05
		r[1].Width0, r[1].Width1 = r[2] * hold, r[3] * hold
	end
	for _, e in ipairs(st.Surge) do
		e[1].Rate = e[2] * (1 + sp.Surge.By * hold) * self.RateScale
	end
	local off = self.Off
	off.Body = CFrame.new(0, sp.Rise * hold, 0) * A(rad(sp.Rear * hold), 0, 0)
	off.Neck = A(rad(10 * hold), 0, 0)
	s.Still = hold * 0.5
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

	local c = self.Cfg
	local s = self.S
	local p = t + self.Phase
	self.Moving += (math.clamp(speed / 10, 0, 1) - self.Moving) * (1 - math.exp(-dt * 6))
	local mv = self.Moving
	local idle = 1 - mv
	s.t, s.p, s.dt, s.speed, s.turn, s.mv, s.idle = t, p, dt, speed, turn, mv, idle
	s.Land, s.Still, s.HeadYaw, s.Gait = false, 0, 0, 0

	-- special move: only when standing still, cut short if the pet starts moving
	local sp = self.Special
	local spX = -1
	if c.Special then
		if sp.At < 0 and mv < 0.15 and t >= sp.Next then
			sp.At = t
			table.clear(sp.Fired)
		end
		if sp.At >= 0 then
			spX = (t - sp.At) / c.Special.Duration
			if spX >= 1 or mv > 0.4 then
				sp.At, spX = -1, -1
				sp.Next = t + randRange(c.Special.Every, self.Rng)
			end
		end
	end
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
			if spX >= bu[2] and not sp.Fired[i] then
				sp.Fired[i] = true
				local e = self.Fx[bu[1]]
				if e then
					e:Emit(bu[3])
				end
			end
		end
	end
	local calm = 1 - s.Still
	self:_set("Body", body)

	-- head: slow look-around when idle, steadies against the body when moving, now and then a curious tilt
	local h = c.Head
	local roll = 0
	if h then
		local lookYaw = (sin(p * h.LookRate * TAU) * h.LookYaw + sin(p * h.LookRate * 2.7 * TAU) * h.LookYaw * 0.25) * idle
		local lookPitch = sin(p * h.LookRate * 1.6 * TAU) * h.LookPitch * idle
		if h.Tilt then
			local tb, _, pl = self:_pulse(h, t, h.Tilt.Every, h.Tilt.Time)
			roll = math.min(1, tb * 2) * h.Tilt.Angle * pl.Side * idle
		end
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
			sway += sin(t * tl.Wag.Rate * TAU) * tl.Wag.Angle * math.min(1, wb * 3)
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

	-- segment chain: the body's wave travels down the joints, each a little behind the one before
	local ch = c.Chain
	if ch then
		for i, name in ipairs(ch.Joints) do
			local yaw = sin(self.Wave - i * ch.Lag) * ch.Amp * (ch.Idle * idle + mv) - turn * ch.Bend * mv
			self:_set(name, A(0, rad(yaw * calm), 0))
		end
	end

	-- wobbles: any joint that sways (Rot, degrees) or shifts (Pos, studs) on a wave. Pulse = one push per cycle
	-- then rest; Every = random-interval pulses (Emit fires an emitter as it starts); Land = jiggle after landings;
	-- Sweep = fixed offset while moving
	for _, wb in ipairs(c.Wobble or EMPTY) do
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
		elseif wb.Pulse then
			local ph = p * wb.Rate + (wb.Phase or 0)
			k = bump((ph - math.floor(ph)) / wb.Pulse)
		else
			k = sin((p * wb.Rate + (wb.Phase or 0)) * TAU)
		end
		k *= ((wb.Idle or 1) * idle + (wb.Moving or 0) * mv) * calm
		if wb.Land then
			local since = t - self.LandAt
			k += sin(since * 28) * math.exp(-since * 7) * wb.Land
		end
		local r, sw = wb.Rot or ZERO, wb.Sweep or ZERO
		self:_set(wb.Joint, CFrame.new((wb.Pos or ZERO) * k) * A(rad(r.X * k + sw.X * mv), rad(r.Y * k + sw.Y * mv), rad(r.Z * k + sw.Z * mv)))
	end

	-- orbiting pieces: circle their joint (TiltX 90 stands the circle up like a halo), pull in tighter while running
	local o = c.Orbit
	if o then
		local n = #o.Parts
		for i, name in ipairs(o.Parts) do
			local ang = (t * o.Rate + (i - 1) / n) * TAU
			local r = o.Radius * (1 - 0.2 * mv)
			local y = sin(t * 1.3 + i * 2) * o.Bob + s.Lift * 0.6
			self:_set(name, A(rad(o.TiltX or 0), 0, rad(o.Tilt)) * CFrame.new(math.cos(ang) * r, y, sin(ang) * r) * A(0, t * o.Spin + i, 0))
		end
	end

	-- a single floating prop that turns in place (sun discs, rings)
	local sn = c.Spin
	if sn then
		self:_set(sn.Joint, CFrame.new(0, sin(p * 0.6 * TAU) * sn.Bob + s.Lift * 0.5, 0) * A(0, 0, t * sn.Rate * TAU))
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
end

return PetAnimator

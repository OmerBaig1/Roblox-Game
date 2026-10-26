--[[
	PetAnimator (Pet Lab draft)
	Code-driven animation for rigged premium pets: no Animation assets, so nothing has to be uploaded
	under the place owner's account. Each frame the follow code calls :Step(dt, t, speed, turn) and the
	animator blends idle and moving poses onto the pet's Motor6D.Transform values.

	Rig contract (joint names): Body (Root->Body), Neck, EarL, EarR, Tail, plus any orbit joints listed in the config.
	Missing joints are skipped, so the same animator works for pets without ears or tails.
]]
local PetAnimator = {}
PetAnimator.__index = PetAnimator

local rad = math.rad
local A = CFrame.Angles
local TAU = math.pi * 2

-- a 0..1 bump: 0 at the ends, 1 in the middle
local function bump(x)
	if x <= 0 or x >= 1 then
		return 0
	end
	return math.sin(x * math.pi)
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
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") then
			self.M[m.Name] = m
		end
	end
	self.Fx = {}
	for _, e in ipairs(model:GetDescendants()) do
		if e:IsA("ParticleEmitter") or e:IsA("Trail") or e:IsA("Light") then
			self.Fx[e.Name] = e
		end
	end
	self.BaseLight = self.Fx.TailGlow and self.Fx.TailGlow.Brightness or 1
	self.Phase = self.Rng:NextNumber() * 10
	self.Moving = 0 -- smoothed 0 (idle) .. 1 (moving)
	self.Gait = 0
	self.Twitch = {L = {Next = randRange({1, 3}, self.Rng), At = -1}, R = {Next = randRange({2, 5}, self.Rng), At = -1}}
	self.Special = {Next = cfg.Special and randRange(cfg.Special.Every, self.Rng) or math.huge, At = -1, Burst = false}
	return self
end

function PetAnimator:_set(name, cf)
	local m = self.M[name]
	if m then
		m.Transform = cf
	end
end

-- speed: studs/s the pet is travelling; turn: -1..1 how hard it is turning (right positive)
function PetAnimator:Step(dt, t, speed, turn)
	local c = self.Cfg
	local p = t + self.Phase
	self.Moving += (math.clamp(speed / 10, 0, 1) - self.Moving) * (1 - math.exp(-dt * 6))
	local mv = self.Moving
	local idle = 1 - mv

	-- gait: a bounding hop whose rate rises with speed
	self.Gait += dt * c.Move.HopRate * (0.7 + 0.5 * math.clamp(speed / 16, 0, 1))
	local g = self.Gait * TAU
	local hopY = math.abs(math.sin(g)) * c.Move.HopHeight * mv
	local bodyPitch = math.sin(g * 2) * c.Move.Pitch * mv

	-- special move: only when standing still
	local sp = self.Special
	local spX = -1
	if c.Special then
		if sp.At < 0 and mv < 0.15 and t >= sp.Next then
			sp.At, sp.Burst = t, false
		end
		if sp.At >= 0 then
			spX = (t - sp.At) / c.Special.Duration
			if spX >= 1 or mv > 0.4 then
				sp.At, spX = -1, -1
				sp.Next = t + randRange(c.Special.Every, self.Rng)
			end
		end
	end
	local spB = bump(spX)

	-- body: breathing when idle, hop + pitch + lean into turns when moving
	local breathe = math.sin(p * c.Body.BreatheRate * TAU) * c.Body.Breathe * idle
	self:_set("Body", CFrame.new(0, hopY + breathe, 0) * A(rad(bodyPitch - 3 * spB), 0, rad(-turn * c.Body.Lean * mv)))

	-- head: slow look-around when idle, steadies against the hop when moving, glances back during the special
	local h = c.Head
	local lookYaw = (math.sin(p * h.LookRate * TAU) * h.LookYaw + math.sin(p * h.LookRate * 2.7 * TAU) * h.LookYaw * 0.25) * idle
	local lookPitch = math.sin(p * h.LookRate * 1.6 * TAU) * h.LookPitch * idle
	self:_set("Neck", A(rad(lookPitch - bodyPitch * 0.7 + 8 * spB), rad(lookYaw + turn * 15 * mv - 40 * spB), 0))

	-- ears: random twitches, swept back while running, perked during the special
	local e = c.Ears
	for side, sign in pairs({L = 1, R = -1}) do
		local tw = self.Twitch[side]
		if tw.At < 0 and t >= tw.Next then
			tw.At = t
		end
		local twitch = 0
		if tw.At >= 0 then
			local x = (t - tw.At) / 0.22
			twitch = bump(x)
			if x >= 1 then
				tw.At = -1
				tw.Next = t + randRange(e.TwitchEvery, self.Rng)
			end
		end
		self:_set("Ear" .. side, A(rad(e.Back * mv - 10 * spB), 0, rad(sign * (twitch * e.TwitchAngle + 6 * spB))))
	end

	-- tail: lazy sway when idle, streams back and up when moving, flicks high during the special
	local tl = c.Tail
	local sway = math.sin(p * tl.SwayRate * TAU) * tl.Sway * (idle + 0.4 * mv) - turn * 20 * mv
	local lift = -(tl.Stream * mv) - 8 * math.sin(p * tl.SwayRate * 0.5 * TAU) * idle - 55 * spB
	local wiggle = math.sin(math.max(spX, 0) * math.pi * 6) * 14 * spB
	self:_set("Tail", A(rad(lift), rad(sway + wiggle), 0))

	-- orbiting pieces: circle the shoulders, pull in tighter while running
	local o = c.Orbit
	if o then
		local n = #o.Parts
		for i, name in ipairs(o.Parts) do
			local ang = (t * o.Rate + (i - 1) / n) * TAU
			local r = o.Radius * (1 - 0.2 * mv)
			local y = math.sin(t * 1.3 + i * 2) * o.Bob + hopY * 0.6
			self:_set(name, A(0, 0, rad(o.Tilt)) * CFrame.new(math.cos(ang) * r, y, math.sin(ang) * r) * A(0, t * o.Spin + i, 0))
		end
	end

	-- effects that respond to motion
	local fx = self.Fx
	if fx.EmberTrail then
		fx.EmberTrail.Enabled = mv > 0.35
	end
	if fx.Embers and spX >= 0.3 and not sp.Burst then
		sp.Burst = true
		fx.Embers:Emit(30)
	end
	if fx.TailGlow then
		fx.TailGlow.Brightness = self.BaseLight * (1 + 1.5 * spB) + math.sin(p * 7) * 0.1
	end
end

return PetAnimator

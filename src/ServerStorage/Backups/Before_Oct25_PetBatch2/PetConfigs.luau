--[[
	PetConfigs (Pet Lab draft)
	Per-pet motion and effect settings read by PetAnimator. Angles are degrees, distances studs, rates cycles/second.
	Every premium pet gets one entry keyed by its model name. Later this merges into the real pet catalog.
	No = roster number (docs/pets/ROSTER.md), the order the lab's follower cycles through.
]]
local V = Vector3.new

return {
	Coalpup = {
		Id = "coalpup",
		No = 1,
		Tier = 1, -- Common
		Mode = "Bound",
		Body = {Breathe = 0.03, BreatheRate = 1.1, Lean = 8},
		Head = {LookYaw = 22, LookPitch = 8, LookRate = 0.3, Tilt = {Angle = 18, Every = {3, 6}, Time = 1.4}},
		-- floppy ears: hang against head tilts and flap with each hop
		Ears = {TwitchAngle = 6, TwitchEvery = {3, 7}, Back = 12, Flop = {Swing = 0.9, Flap = 26}},
		Tail = {Sway = 8, SwayRate = 0.7, Stream = 12, Wag = {Angle = 32, Rate = 6, Every = {2, 5}, Time = 1.2}},
		Move = {HopHeight = 0.32, HopRate = 3, Pitch = 8},
	},
	FlickerMoth = {
		Id = "flicker_moth",
		No = 2,
		Tier = 1, -- Common
		Mode = "Hover",
		Hover = {Bob = 0.12, BobRate = 0.5, Heave = 0.06, Drift = 0.35, DriftRate = 0.12, Tilt = 12, Bank = 25},
		Wings = {Rate = 1.4, MoveRate = 7, Amp = 18, MoveAmp = 40, Rest = 8, Sweep = 6},
		Wobble = {
			{Joint = "Antennae", Rot = V(6, 0, 0), Rate = 0.7, Moving = 0.4, Sweep = V(20, 0, 0)},
		},
	},
	MagmaToad = {
		Id = "magma_toad",
		No = 3,
		Tier = 2, -- Uncommon
		Mode = "Hop",
		-- heavy hops with a sit between them
		Hop = {Rate = 0.9, MaxRate = 2.6, Stride = 2.4, Air = 0.45, Height = 0.6, Pitch = 14, Squash = 0.1},
		Body = {Breathe = 0.03, BreatheRate = 0.5, Lean = 4},
		Head = {LookYaw = 10, LookPitch = 4, LookRate = 0.12}, -- grumpy, barely bothers to look around
		Wobble = {
			{Joint = "Sac", Pos = V(0, -0.02, -0.14), Pulse = 0.35, Rate = 0.55, Moving = 0.3}, -- croak
			{Joint = "Blisters", Pos = V(0, 0.3, 0), Rot = V(10, 0, 6), Rate = 0.5, Idle = 0.1, Land = 0.5}, -- jiggle on landing
		},
		LandFx = {"Pop", 3},
	},
	PyreSalamander = {
		Id = "pyre_salamander",
		No = 4,
		Tier = 3, -- Rare
		Mode = "Slither",
		Slither = {Rate = 0.25, MoveRate = 1.6, Yaw = 6, Idle = 0.4, Sway = 0.08},
		Body = {Breathe = 0.02, BreatheRate = 0.8, Lean = 6},
		Head = {LookYaw = 30, LookPitch = 8, LookRate = 0.35}, -- quick, curious glances
		Chain = {Joints = {"Back", "Tail1", "Tail2"}, Lag = 0.9, Amp = 14, Idle = 0.3, Bend = 18},
		Wobble = {
			{Joint = "Frill", Rot = V(0, 0, 5), Rate = 0.9, Moving = 1.4}, -- the frill ripples
		},
		MoveFx = {"HeatTrail"},
	},
	CinderLynx = {
		Id = "cinder_lynx",
		No = 5,
		Tier = 4, -- Epic
		Mode = "Bound",
		Body = {Breathe = 0.035, BreatheRate = 0.9, Lean = 10},
		Head = {LookYaw = 20, LookPitch = 6, LookRate = 0.22},
		Ears = {TwitchAngle = 28, TwitchEvery = {2, 6}, Back = 22},
		Tail = {Sway = 16, SwayRate = 0.8, Stream = 30},
		Move = {HopHeight = 0.45, HopRate = 2.4, Pitch = 7},
		Orbit = {Parts = {"Shard1", "Shard2", "Shard3"}, Radius = 1.45, Rate = 0.18, Bob = 0.15, Tilt = 14, Spin = 1.4},
		-- signature move: flicks its tail up and throws off a shower of embers
		Special = {Kind = "EmberFlick", Every = {7, 12}, Duration = 1.2, Bursts = {{"Embers", 0.3, 30}}},
		Glow = {{Light = "TailGlow", Flicker = 0.1, Flare = 1.5}},
		MoveFx = {"EmberTrail"},
	},
	ObsidianDrake = {
		Id = "obsidian_drake",
		No = 6,
		Tier = 5, -- Legendary
		Mode = "Hover",
		Hover = {Bob = 0.15, BobRate = 0.3, Heave = 0.14, Drift = 0.25, DriftRate = 0.08, Tilt = 18, Bank = 32},
		-- slow beats when idle; powerful flaps when following, gliding with wings held out every fourth beat
		Wings = {Rate = 0.55, MoveRate = 1.5, Amp = 22, MoveAmp = 38, Rest = 4, Sweep = 10, Glide = 3, GlideAngle = 14},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.18},
		Tail = {Sway = 12, SwayRate = 0.4, Stream = 18},
		Wobble = {
			-- now and then the jaw opens to exhale smoke
			{Joint = "Jaw", Rot = V(-16, 0, 0), Every = {4, 7}, Time = 1.4, Emit = {"Smoke", 8}},
		},
		Orbit = {Parts = {"Halo1", "Halo2", "Halo3"}, Radius = 0.75, Rate = 0.1, Bob = 0.05, Tilt = 0, TiltX = 90, Spin = 0.4},
		-- signature move: rears back, wings wide, jaw open, and a ring of heat rolls out along the ground
		Special = {Kind = "Roar", Every = {9, 14}, Duration = 2.2, Rise = 0.3, Rear = 22, JawOpen = 35, Spread = 35,
			Bursts = {{"RoarWave", 0.4, 60}, {"Smoke", 0.35, 12}}},
		Glow = {{Light = "ChestGlow", Flicker = 0.15, Flare = 2}},
		MoveFx = {"EmberTrailL", "EmberTrailR"},
	},
	SolflareQilin = {
		Id = "solflare_qilin",
		No = 7,
		Tier = 6, -- Mythic
		Mode = "Bound",
		Body = {Breathe = 0.03, BreatheRate = 0.6, Lean = 8},
		Head = {LookYaw = 14, LookPitch = 5, LookRate = 0.15}, -- slow, regal
		Tail = {Sway = 14, SwayRate = 0.5, Stream = 25},
		-- elegant floating bound: high, slow strides
		Move = {HopHeight = 0.6, HopRate = 1.6, Pitch = 5},
		Wobble = {
			{Joint = "Mane", Rot = V(5, 4, 7), Rate = 0.45, Moving = 1.6, Sweep = V(14, 0, 0)},
		},
		Spin = {Joint = "Disc", Rate = 0.05, Bob = 0.08},
		Orbit = {Parts = {"Mote1", "Mote2", "Mote3"}, Radius = 1.15, Rate = 0.15, Bob = 0.04, Tilt = 0, TiltX = 90, Spin = 1},
		-- transformation: the mane ignites, flames surge, the sun disc swells and light rays fan out, then it all settles
		Special = {Kind = "Ignite", Every = {10, 16}, Duration = 3, Part = "Mane", Hot = Color3.fromRGB(255, 200, 80),
			Grow = {Part = "Disc", By = 0.4}, Rays = {"Ray1", "Ray2", "Ray3", "Ray4", "Ray5", "Ray6"},
			Surge = {Emitters = {"ManeFlames"}, By = 4}, Rise = 0.25, Rear = 12},
		Glow = {{Light = "ManeGlow", Flicker = 0.15, Flare = 2}, {Light = "DiscGlow", Flicker = 0.05, Flare = 1.5}},
		MoveFx = {"HoofFireF", "HoofFireB"},
	},
}

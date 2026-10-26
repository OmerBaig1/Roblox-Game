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
		Tail = {Sway = 8, SwayRate = 0.7, Stream = 12, Wag = {Angle = 30, Rate = 4.5, Every = {2, 5}, Time = 1.2}},
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
		Glow = {{Light = "ChestGlow", Flicker = 0.15, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"EmberTrailL", "EmberTrailR"},
	},
	Bubblefin = {
		Id = "bubblefin",
		No = 8,
		Tier = 1, -- Common
		Mode = "Glide",
		-- swims at waist height; now and then a startled wiggle
		Glide = {Bob = 0.12, BobRate = 0.5, Climb = 8, Tilt = 8, Bank = 25, Startle = {Every = {5, 9}, Time = 1, Angle = 20}},
		Wobble = {
			{Joint = "Tail", Rot = V(0, 22, 0), Rate = 1.2, Moving = 1.8}, -- swish
			{Joint = "FinL", Rot = V(0, 0, 25), Rate = 1.6, Moving = 1.3}, -- paddle
			{Joint = "FinR", Rot = V(0, 0, -25), Rate = 1.6, Moving = 1.3, Phase = 0.5},
		},
	},
	CoralCrab = {
		Id = "coral_crab",
		No = 9,
		Tier = 1, -- Common
		Mode = "Scuttle",
		Scuttle = {StepRate = 4, Bounce = 0.06, Rock = 5, Side = 90}, -- sideways while moving
		Body = {Breathe = 0.02, BreatheRate = 1, Lean = 0},
		Wobble = {
			-- claws click in turn, raised while scuttling
			{Joint = "ClawL", Rot = V(0, -14, 0), Pulse = 0.25, Rate = 0.8, Moving = 0.5, Sweep = V(35, 0, 0)},
			{Joint = "ClawR", Rot = V(0, 14, 0), Pulse = 0.25, Rate = 0.8, Phase = 0.5, Moving = 0.5, Sweep = V(35, 0, 0)},
			{Joint = "Eyes", Rot = V(0, 20, 0), Rate = 0.3, Moving = 0.3}, -- eye stalks look around
		},
	},
	LanternEel = {
		Id = "lantern_eel",
		No = 10,
		Tier = 2, -- Uncommon
		Mode = "Slither",
		-- swims through the air; coils in a lazy S when idle
		Slither = {Rate = 0.3, MoveRate = 1.4, Yaw = 8, Idle = 0.6, Sway = 0.08, Bob = 0.12, BobRate = 0.4},
		Body = {Breathe = 0.01, BreatheRate = 0.6, Lean = 6},
		Head = {LookYaw = 12, LookPitch = 5, LookRate = 0.25},
		Chain = {Joints = {"Mid", "Tail"}, Lag = 1, Amp = 22, Idle = 0.8, Bend = 15},
		Wobble = {
			{Joint = "Lure", Rot = V(14, 0, 10), Rate = 0.6, Moving = 0.5, Sweep = V(35, 0, 0)}, -- pendulum, trails behind
		},
	},
	SurfOtter = {
		Id = "surf_otter",
		No = 11,
		Tier = 3, -- Rare
		Mode = "Glide",
		-- belly-up when idle; Tilt tips its head end up so it sits up and surfs the orb while moving
		Glide = {Bob = 0.12, BobRate = 0.35, Climb = 3, Tilt = 60, Bank = 25},
		Head = {LookYaw = 15, LookPitch = 6, LookRate = 0.2},
		Wobble = {
			{Joint = "Orb", Pos = V(0, 0.12, 0), Rate = 0.35, Moving = 1}, -- floats with the otter (same bob as Glide)
			{Joint = "Paws", Rot = V(-25, 0, 0), Pulse = 0.3, Rate = 0.6, Moving = 0}, -- cracks the shell on its tummy
			{Joint = "Tail", Rot = V(0, 12, 0), Rate = 0.5, Moving = 0.6},
		},
		MoveFx = {"Droplets", "FoamTrail"},
	},
	ReefguardManta = {
		Id = "reefguard_manta",
		No = 12,
		Tier = 4, -- Epic
		Mode = "Glide",
		Glide = {Bob = 0.15, BobRate = 0.25, Climb = 4, Tilt = 6, Bank = 40},
		Wings = {Rate = 0.35, MoveRate = 0.7, Amp = 12, MoveAmp = 18, Rest = 0, Sweep = 0}, -- slow undulation
		Tail = {Sway = 10, SwayRate = 0.3, Stream = 8},
		Wobble = {
			{Joint = "Lobes", Rot = V(8, 0, 0), Rate = 0.4},
		},
		Orbit = {Parts = {"Remora1", "Remora2"}, Radius = 1.1, Rate = 0.2, Bob = 0.05, Tilt = 0, Face = true},
		-- signature move: a full barrel roll that throws off a ring of bubbles
		Special = {Kind = "Roll", Every = {8, 12}, Duration = 1.4, Rise = 0.5, Finish = true, Bursts = {{"BubbleRing", 0.5, 40}}},
		Glow = {{Light = "SpotGlow", Flicker = 0.05, Flare = 1.5}},
		MoveFx = {"Bubbles", "TailTrail"},
	},
	MaelstromSerpent = {
		Id = "maelstrom_serpent",
		No = 13,
		Tier = 5, -- Legendary
		Mode = "Slither",
		-- rears up out of its whirlpool, floating; the coiled base turns with the wave
		Slither = {Rate = 0.2, MoveRate = 1, Yaw = 6, Idle = 0.5, Sway = 0.1, Bob = 0.15, BobRate = 0.3},
		Body = {Breathe = 0.02, BreatheRate = 0.5, Lean = 10},
		Head = {LookYaw = 20, LookPitch = 6, LookRate = 0.2},
		Chain = {Joints = {"Seg3", "Seg4", "Seg5"}, Lag = 0.8, Amp = 10, Idle = 0.6, Bend = 12, Rise = 6, Upright = true},
		Spin = {Joint = "Ring", Rate = 0.25, Bob = 0.05},
		Orbit = {Parts = {"Pearl1", "Pearl2", "Pearl3"}, Radius = 1.6, Rate = 0.2, Bob = 0.25, Tilt = 18, Spin = 1}, -- glowing pearls
		-- signature move: rises into a tight coil while the whirlpool spins up and sprays
		Special = {Kind = "Coil", Every = {9, 14}, Duration = 2.6, Rise = 0.8, Rear = -8, Joints = {"Seg3", "Seg4", "Seg5"},
			Curl = 35, Lift = 10, SpinBoost = 4, Surge = {Emitters = {"Spray", "WaterJet"}, By = 1}},
		Glow = {{Light = "TideGlow", Flicker = 0.05, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"FoamTrail"},
	},
	CoralcrownLeviathan = {
		Id = "coralcrown_leviathan",
		No = 14,
		Tier = 6, -- Mythic
		Mode = "Glide",
		-- majestic glide; jellyfish lanterns circle the castle
		Glide = {Bob = 0.2, BobRate = 0.2, Climb = 4, Tilt = 5, Bank = 25},
		Wobble = {
			{Joint = "Fluke", Rot = V(14, 0, 0), Rate = 0.35, Moving = 1.6}, -- fluke sweeps
			{Joint = "FinL", Rot = V(0, 0, 10), Rate = 0.3, Moving = 1.4},
			{Joint = "FinR", Rot = V(0, 0, -10), Rate = 0.3, Moving = 1.4},
		},
		Orbit = {Parts = {"Lantern1", "Lantern2", "Lantern3"}, Radius = 1.4, Rate = 0.12, Bob = 0.12, Tilt = 8, Spin = 0.6},
		-- transformation: Bioluminant Tide. The whole body floods with light, the castle windows blaze, the blowhole spouts
		Special = {Kind = "Luminesce", Every = {10, 16}, Duration = 3.2, Color = Color3.fromRGB(90, 255, 230), Fill = 0.55,
			Rise = 0.3, Rear = -6, Surge = {Emitters = {"Spout", "RarityAura"}, By = 4}, Bursts = {{"Spout", 0.45, 40}}},
		Glow = {{Light = "CastleGlow", Flicker = 0.1, Flare = 2.5}, {Light = "RarityGlow", Flicker = 0.08, Flare = 2}},
		MoveFx = {"GlowWake"},
	},
	MosscapBunny = {
		Id = "mosscap_bunny",
		No = 15,
		Tier = 1, -- Common
		Mode = "Hop",
		Hop = {Rate = 1.2, MaxRate = 3.2, Stride = 1.6, Air = 0.4, Height = 0.45, Pitch = 12, Squash = 0.08}, -- quick hops
		Body = {Breathe = 0.03, BreatheRate = 1.4, Lean = 6},
		Ears = {TwitchAngle = 20, TwitchEvery = {1.5, 4}, Back = 25}, -- ears swivel
		Wobble = {
			{Joint = "Neck", Rot = V(-4, 0, 0), Pulse = 0.15, Rate = 1.5, Moving = 0.2}, -- nose twitch
			{Joint = "Cap", Rot = V(6, 0, 4), Rate = 0.4, Idle = 0.3, Land = 0.8}, -- cap wobbles on landing
		},
	},
	Bramblehog = {
		Id = "bramblehog",
		No = 16,
		Tier = 2, -- Uncommon
		Mode = "Roll",
		Roll = {Radius = 1.05, Lift = 0}, -- curls into a ball and rolls, uncurls when it stops
		Body = {Breathe = 0.03, BreatheRate = 1.2, Lean = 0},
		Head = {LookYaw = 18, LookPitch = 8, LookRate = 0.35, Tuck = 60}, -- sniffs around; tucks in to roll
		MoveFx = {"Leaves"},
	},
	PetalSprite = {
		Id = "petal_sprite",
		No = 17,
		Tier = 2, -- Uncommon
		Mode = "Hover",
		-- quick fluttery darting flight; a twirl now and then
		Hover = {Bob = 0.12, BobRate = 0.6, Heave = 0.05, Drift = 0.3, DriftRate = 0.15, Tilt = 15, Bank = 30, Twirl = {Every = {5, 9}, Time = 1.2}},
		Wings = {Rate = 3, MoveRate = 8, Amp = 20, MoveAmp = 32, Rest = 10, Sweep = 8},
		Head = {LookYaw = 20, LookPitch = 8, LookRate = 0.3},
		Wobble = {
			{Joint = "Skirt", Rot = V(0, 15, 6), Rate = 0.7, Moving = 1.5},
		},
	},
	GlimmerwoodFawn = {
		Id = "glimmerwood_fawn",
		No = 18,
		Tier = 3, -- Rare
		Mode = "Bound",
		Body = {Breathe = 0.03, BreatheRate = 0.8, Lean = 9},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.2, Graze = {Every = {5, 9}, Time = 2.2, Angle = 35}},
		Ears = {TwitchAngle = 25, TwitchEvery = {2, 5}, Back = 20},
		Tail = {Sway = 10, SwayRate = 1, Stream = 15},
		Move = {HopHeight = 0.4, HopRate = 2.6, Pitch = 7}, -- light springing bound
		Orbit = {Parts = {"Firefly"}, Radius = 1.3, Rate = 0.25, Bob = 0.2, Tilt = 10, Spin = 0},
		MoveFx = {"GoldTrail"},
	},
	RunebarkOwl = {
		Id = "runebark_owl",
		No = 19,
		Tier = 4, -- Epic
		Mode = "Hover",
		Hover = {Bob = 0.1, BobRate = 0.3, Heave = 0.08, Drift = 0.15, DriftRate = 0.08, Tilt = 14, Bank = 35},
		-- silent swooping flight: a few beats, then a long glide
		Wings = {Rate = 0.4, MoveRate = 1.6, Amp = 8, MoveAmp = 30, Rest = 0, Sweep = 12, Glide = 2, GlideAngle = 10},
		Head = {LookYaw = 25, LookPitch = 6, LookRate = 0.15, Tilt = {Angle = 22, Every = {4, 8}, Time = 1.5}},
		Wobble = {
			{Joint = "TailF", Rot = V(6, 0, 0), Rate = 0.3, Moving = 0.6},
		},
		Orbit = {Parts = {"Rune1", "Rune2", "Rune3"}, Radius = 1.6, Rate = 0.1, Bob = 0.15, Tilt = 10, Spin = 0.5},
		-- signature move: Owl Turn. The head swivels a full 180 to look back at you, the runes flash, then it turns back
		Special = {Kind = "Swivel", Every = {8, 12}, Duration = 2.4, Yaw = 180, Bursts = {{"RuneFlash", 0.4, 25}}},
		Glow = {{Light = "RuneGlow", Flicker = 0.05, Flare = 3}},
		MoveFx = {"LeafTrail"},
	},
	ElderhornSpirit = {
		Id = "elderhorn_spirit",
		No = 20,
		Tier = 5, -- Legendary
		Mode = "Bound",
		-- walks on air with slow strides (built floating, hooves never touch)
		Body = {Breathe = 0.03, BreatheRate = 0.4, Lean = 6},
		Move = {HopHeight = 0.15, HopRate = 1.2, Pitch = 3},
		Wobble = {
			{Joint = "Antlers", Rot = V(3, 4, 2), Rate = 0.15, Moving = 0.5}, -- stands proud, antlers barely sway
			{Joint = "Beard", Rot = V(6, 0, 5), Rate = 0.4, Moving = 1.5, Sweep = V(12, 0, 0)},
		},
		Spin = {Joint = "Wreath", Rate = 0.08, Bob = 0.06},
		Orbit = {Parts = {"Spirit1", "Spirit2", "Spirit3"}, Radius = 0.9, Rate = 0.08, Bob = 0.2, Tilt = 10, Spin = 0}, -- lights drift in the antlers
		-- signature move: Bloom. The antlers burst into blossom and a ring of flowers ripples out over the ground
		Special = {Kind = "Rear", Every = {9, 14}, Duration = 2.4, Rise = 0.3, Rear = 10, Bursts = {{"Blossoms", 0.3, 30}, {"FlowerRing", 0.45, 50}}},
		Glow = {{Light = "SpiritGlow", Flicker = 0.08, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"HoofPetals", "SpiritTrail"},
	},
	WorldtreeTortoise = {
		Id = "worldtree_tortoise",
		No = 21,
		Tier = 6, -- Mythic
		Mode = "Waddle",
		Waddle = {Rate = 0.9, Bob = 0.04, Roll = 5, Yaw = 4}, -- steady waddle
		Body = {Breathe = 0.02, BreatheRate = 0.3, Lean = 3},
		Head = {LookYaw = 15, LookPitch = 5, LookRate = 0.12},
		Tail = {Sway = 10, SwayRate = 0.5, Stream = 0},
		Wobble = {
			{Joint = "Tree", Rot = V(4, 0, 5), Rate = 0.25, Moving = 1.5}, -- the tree sways
		},
		Orbit = {Parts = {"Island1", "Island2", "Island3"}, Radius = 1.9, Rate = 0.06, Bob = 0.15, Tilt = 6, Spin = 0.3},
		-- transformation: Season Turn. The tree burns through spring blossom, autumn gold and winter frost, then back to summer
		Special = {Kind = "Cycle", Every = {11, 16}, Duration = 4.5, Part = "Tree", Emitter = "Leaves",
			Colors = {Color3.fromRGB(255, 160, 210), Color3.fromRGB(255, 170, 50), Color3.fromRGB(210, 240, 255), Color3.fromRGB(120, 230, 110)}},
		Glow = {{Light = "TreeGlow", Flicker = 0.06, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
	},
	SnowpuffSeal = {
		Id = "snowpuff_seal",
		No = 22,
		Tier = 1, -- Common
		Mode = "Waddle",
		Waddle = {Rate = 1.8, Bob = 0.05, Roll = 10, Yaw = 8, Tilt = 15}, -- belly-slides with a wobble
		Body = {Breathe = 0.03, BreatheRate = 0.5, Lean = 6},
		Head = {LookYaw = 12, LookPitch = 4, LookRate = 0.15, Graze = {Every = {5, 10}, Time = 1.8, Angle = -28}}, -- sleepy yawn
		Wobble = {
			{Joint = "FlipperL", Rot = V(0, 0, -18), Pulse = 0.3, Rate = 0.5, Moving = 1.2}, -- flipper pats
			{Joint = "FlipperR", Rot = V(0, 0, 18), Pulse = 0.3, Rate = 0.5, Phase = 0.5, Moving = 1.2},
			{Joint = "TailFlippers", Rot = V(8, 10, 0), Rate = 0.6, Moving = 1.4},
		},
	},
	IcicleBat = {
		Id = "icicle_bat",
		No = 23,
		Tier = 2, -- Uncommon
		Mode = "Hover",
		-- hangs upside-down when idle; erratic fluttering flight
		Hover = {Bob = 0.1, BobRate = 0.4, Heave = 0.08, Drift = 0.2, DriftRate = 0.3, Tilt = 12, Bank = 35, Hang = true, Jitter = 0.35},
		Wings = {Rate = 0.8, MoveRate = 6, Amp = 6, MoveAmp = 40, Rest = -10, Sweep = 6}, -- faster than 6 beats/s strobes at 60 fps
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.3},
		Wobble = {
			{Joint = "Ears", Rot = V(8, 0, 0), Pulse = 0.2, Rate = 0.7, Moving = 0.3},
		},
	},
	RimebackRam = {
		Id = "rimeback_ram",
		No = 24,
		Tier = 3, -- Rare
		Mode = "Bound",
		Body = {Breathe = 0.03, BreatheRate = 0.6, Lean = 7},
		Head = {LookYaw = 12, LookPitch = 5, LookRate = 0.18, Down = 18, Graze = {Every = {4, 8}, Time = 1.2, Angle = 20}}, -- paws and dips; head down to charge
		Tail = {Sway = 12, SwayRate = 1.4, Stream = 10},
		Move = {HopHeight = 0.3, HopRate = 2, Pitch = 9}, -- heavy bound
		Wobble = {
			-- now and then it shakes the frost off its coat
			{Joint = "Wool", Rot = V(0, 0, 10), Every = {6, 11}, Time = 0.7, Emit = {"FrostShake", 12}},
		},
		Orbit = {Parts = {"Snowflake"}, Radius = 1.4, Rate = 0.15, Bob = 0.2, Tilt = 12, Spin = 1.2},
		MoveFx = {"SnowTrail"},
	},
	PrismWyrmling = {
		Id = "prism_wyrmling",
		No = 25,
		Tier = 4, -- Epic
		Mode = "Hover",
		Hover = {Bob = 0.12, BobRate = 0.4, Heave = 0.1, Drift = 0.2, DriftRate = 0.12, Tilt = 16, Bank = 35, Jitter = 0.15}, -- darting flight
		Wings = {Rate = 1, MoveRate = 3.5, Amp = 10, MoveAmp = 30, Rest = 4, Sweep = 10},
		Head = {LookYaw = 20, LookPitch = 6, LookRate = 0.22},
		Tail = {Sway = 14, SwayRate = 0.6, Stream = 15},
		Orbit = {Parts = {"Prism1", "Prism2"}, Radius = 1.4, Rate = 0.14, Bob = 0.15, Tilt = 15, Spin = 1.5},
		-- signature move: Refraction. Wings thrown wide, its spikes blaze and a fan of rainbow light falls on the ground
		Special = {Kind = "Ignite", Every = {9, 13}, Duration = 2.6, Part = "Spikes", Hot = Color3.fromRGB(235, 250, 255), Spread = 35,
			Rays = {"Ray1", "Ray2", "Ray3", "Ray4", "Ray5", "Ray6"}, Surge = {Emitters = {"Sparkles"}, By = 3}, Rise = 0.3, Rear = 10},
		Glow = {{Light = "PrismGlow", Flicker = 0.08, Flare = 2}},
		MoveFx = {"CrystalTrail"},
	},
	AuroraMammoth = {
		Id = "aurora_mammoth",
		No = 26,
		Tier = 5, -- Legendary
		Mode = "Bound",
		-- slow, heavy stride; snow puffs at every step
		Body = {Breathe = 0.04, BreatheRate = 0.4, Lean = 5},
		Move = {HopHeight = 0.18, HopRate = 1.3, Pitch = 4},
		Head = {LookYaw = 12, LookPitch = 4, LookRate = 0.12},
		Tail = {Sway = 15, SwayRate = 0.7, Stream = 10},
		Wobble = {
			{Joint = "Trunk", Rot = V(18, 10, 0), Rate = 0.3, Moving = 0.6}, -- trunk curls and sways
			{Joint = "Ears", Rot = V(8, 0, 0), Pulse = 0.4, Rate = 0.45}, -- ears fan
		},
		Orbit = {Parts = {"Wisp1", "Wisp2", "Wisp3"}, Radius = 1.6, Rate = 0.1, Bob = 0.2, Tilt = 12, Spin = 0},
		-- signature move: Aurora Call. Raises its trunk and trumpets while aurora ribbons stream up into the sky
		Special = {Kind = "Ignite", Every = {10, 15}, Duration = 3, Rays = {"Call1", "Call2", "Call3", "Call4"}, Rise = 0.2, Rear = 8,
			Pose = {Trunk = V(110, 0, 0)}, Bursts = {{"Trumpet", 0.3, 30}}},
		Glow = {{Light = "AuroraGlow", Flicker = 0.1, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		LandFx = {"SnowPuff", 4},
		MoveFx = {"AuroraTrail"},
	},
	HailstormGriffin = {
		Id = "hailstorm_griffin",
		No = 27,
		Tier = 6, -- Mythic
		Mode = "Hover",
		Hover = {Bob = 0.15, BobRate = 0.3, Heave = 0.14, Drift = 0.2, DriftRate = 0.08, Tilt = 18, Bank = 35},
		Wings = {Rate = 0.5, MoveRate = 1.7, Amp = 14, MoveAmp = 38, Rest = 6, Sweep = 12, Glide = 3, GlideAngle = 12},
		Head = {LookYaw = 20, LookPitch = 6, LookRate = 0.18, Graze = {Every = {5, 9}, Time = 1.6, Angle = 30}}, -- preens
		Tail = {Sway = 12, SwayRate = 0.5, Stream = 18},
		Wobble = {
			{Joint = "Cloud", Pos = V(0, 0.08, 0), Rate = 0.3, Moving = 1, SweepPos = V(0, -0.3, 1.4)}, -- the cloud trails behind in flight
		},
		Orbit = {Parts = {"Hailstone1", "Hailstone2", "Hailstone3"}, Radius = 2, Rate = 0.16, Bob = 0.25, Tilt = 14, Spin = 2},
		-- transformation: Blizzard. Its wings frost over and blaze, the cloud swells, hail and lightning burst out
		Special = {Kind = "Ignite", Every = {11, 16}, Duration = 3.2, Parts = {"WingL", "WingR"}, Hot = Color3.fromRGB(200, 245, 255),
			Grow = {Part = "Cloud", By = 0.5}, Rays = {"Bolt1", "Bolt2", "Bolt3", "Bolt4"}, Surge = {Emitters = {"Snow"}, By = 4},
			Spread = 30, Rise = 0.3, Rear = 10, Bursts = {{"Hail", 0.35, 40}, {"Hail", 0.6, 30}}},
		Glow = {{Light = "StormGlow", Flicker = 0.25, Flare = 3}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
	},
	CrystalHeartGolem = {
		Id = "crystal_heart_golem",
		No = 28,
		Tier = 7, -- Secret
		Mode = "Glide",
		Glide = {Bob = 0.2, BobRate = 0.3, Climb = 3, Tilt = 6, Bank = 20},
		-- the heart beats and every shard pulses outward with it
		Wobble = {
			{Joint = "Heart", Pos = V(0, 0, -0.08), Pulse = 0.22, Rate = 1.1, Moving = 1},
			{Joint = "Head", Pos = V(0, 0.12, 0), Pulse = 0.25, Rate = 1.1, Moving = 1},
			{Joint = "ArmL", Pos = V(-0.12, 0, 0), Rot = V(0, 0, 4), Pulse = 0.25, Rate = 1.1, Moving = 1},
			{Joint = "ArmR", Pos = V(0.12, 0, 0), Rot = V(0, 0, -4), Pulse = 0.25, Rate = 1.1, Moving = 1},
			{Joint = "LegL", Pos = V(-0.06, -0.08, 0), Pulse = 0.25, Rate = 1.1, Moving = 1},
			{Joint = "LegR", Pos = V(0.06, -0.08, 0), Pulse = 0.25, Rate = 1.1, Moving = 1},
		},
		-- Secret mechanic: Shatter & Reform. The shards rattle, burst out around the heart, circle it once together,
		-- then fly home and lock back into shape
		Special = {Kind = "Morph", Every = {12, 18}, Duration = 3.6, Finish = true, Radius = 1.8, Rise = 0.2,
			Scatter = {"Head", "ArmL", "ArmR", "LegL", "LegR", "Spikes"}, Bursts = {{"ShardBurst", 0.12, 40}, {"ShardBurst", 0.92, 40}}},
		Glow = {{Light = "HeartGlow", Flicker = 0.4, Flare = 1.5}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
	},
	PixelPup = {
		Id = "pixel_pup",
		No = 29,
		Tier = 1, -- Common
		Mode = "Bound",
		Stepped = 12, -- 8-bit: poses snap at 12 fps
		Body = {Breathe = 0.04, BreatheRate = 1.1, Lean = 8},
		Head = {LookYaw = 22, LookPitch = 8, LookRate = 0.3, Tilt = {Angle = 18, Every = {3, 6}, Time = 1.2}},
		Tail = {Sway = 8, SwayRate = 0.7, Stream = 12, Wag = {Angle = 30, Rate = 5, Every = {2, 5}, Time = 1.2}},
		Move = {HopHeight = 0.32, HopRate = 3, Pitch = 8},
		Wobble = {
			{Joint = "Ears", Rot = V(12, 0, 0), Rate = 1.5, Idle = 0.3, Moving = 1},
		},
	},
	CoinHopper = {
		Id = "coin_hopper",
		No = 30,
		Tier = 2, -- Uncommon
		Mode = "Roll",
		-- rolls on its edge like a wheel; when idle it flips itself in the air and lands with a sparkle
		Roll = {Radius = 0.95, Lift = 0, Side = 90, Flip = {Every = {4, 7}, Time = 0.9, Height = 1.2}},
		Body = {Breathe = 0.03, BreatheRate = 1, Lean = 0},
		Wobble = {
			{Joint = "Arms", Rot = V(0, 0, 12), Rate = 0.8, Moving = 0.2},
			{Joint = "Legs", Rot = V(15, 0, 0), Rate = 1.6, Idle = 0.2, Moving = 0},
		},
		LandFx = {"Sparkle", 12},
	},
	JoystickCritter = {
		Id = "joystick_critter",
		No = 31,
		Tier = 3, -- Rare
		Mode = "Hop",
		Hop = {Rate = 1.4, MaxRate = 3.4, Stride = 1.8, Air = 0.4, Height = 0.5, Pitch = 8, Squash = 0.06},
		Body = {Breathe = 0.02, BreatheRate = 1, Lean = 6},
		Wobble = {
			{Joint = "Stick", Rot = V(16, 0, 0), Steer = true, Rate = 1.2, Moving = 0.4}, -- steered round 8 directions
			{Joint = "Buttons", Pos = V(0, -0.05, 0), Pulse = 0.2, Rate = 1.7, Moving = 0.5}, -- buttons press
		},
		Orbit = {Parts = {"PixelHeart"}, Radius = 1.3, Rate = 0.2, Bob = 0.2, Tilt = 10, Spin = 1.5},
		MoveFx = {"NeonTrail"},
	},
	CartridgeCrab = {
		Id = "cartridge_crab",
		No = 32,
		Tier = 3, -- Rare
		Mode = "Scuttle",
		Scuttle = {StepRate = 4.5, Bounce = 0.05, Rock = 5, Side = 90},
		Body = {Breathe = 0.02, BreatheRate = 0.9, Lean = 0},
		Wobble = {
			-- now and then it blows the dust out of its own cartridge
			{Joint = "Shell", Rot = V(-14, 0, 0), Every = {5, 9}, Time = 0.8, Emit = {"DustPuff", 10}},
			{Joint = "ClawL", Rot = V(0, 14, 0), Pulse = 0.25, Rate = 0.8, Moving = 0.5, Sweep = V(30, 0, 0)}, -- claws click
			{Joint = "ClawR", Rot = V(0, -14, 0), Pulse = 0.25, Rate = 0.8, Phase = 0.5, Moving = 0.5, Sweep = V(30, 0, 0)},
			{Joint = "Eyes", Rot = V(0, 18, 0), Rate = 0.3},
		},
		Orbit = {Parts = {"Pixel"}, Radius = 1.4, Rate = 0.25, Bob = 0.15, Tilt = 10, Spin = 2},
		MoveFx = {"PixelTrail"},
	},
	ClawMachineOcto = {
		Id = "claw_machine_octo",
		No = 33,
		Tier = 4, -- Epic
		Mode = "Glide",
		Glide = {Bob = 0.15, BobRate = 0.3, Climb = 4, Tilt = 8, Bank = 25},
		Wobble = {
			{Joint = "TentL", Rot = V(8, 0, 12), Rate = 0.5, Moving = 1.4, Sweep = V(20, 0, 0)}, -- curl in waves, trail when gliding
			{Joint = "TentR", Rot = V(8, 0, -12), Rate = 0.5, Phase = 0.5, Moving = 1.4, Sweep = V(20, 0, 0)},
			{Joint = "Claw", Rot = V(0, 0, 8), Rate = 0.4}, -- the claw sways inside the dome
		},
		-- signature move: Grab! The claw drops, grabs the plush, lifts it... and drops it. Sad droop.
		Special = {Kind = "Grab", Every = {9, 13}, Duration = 3.4, Finish = true, Claw = "Claw", Prize = "Prize",
			Drop = 0.75, Lift = 0.6, Droop = 12, Limbs = {"TentL", "TentR"}},
		Glow = {{Light = "NeonGlow", Flicker = 0.1, Flare = 1}},
		MoveFx = {"NeonTrail"},
	},
	HighScoreDragon = {
		Id = "high_score_dragon",
		No = 34,
		Tier = 5, -- Legendary
		Mode = "Slither",
		-- S-wave flight; coils when idle while its score digits tick over
		Slither = {Rate = 0.3, MoveRate = 1.3, Yaw = 8, Idle = 0.6, Sway = 0.1, Bob = 0.15, BobRate = 0.3},
		Body = {Breathe = 0.02, BreatheRate = 0.6, Lean = 10},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.2},
		Chain = {Joints = {"Seg2", "Seg3", "Tail"}, Lag = 0.9, Amp = 16, Idle = 0.7, Bend = 16, Rise = 6},
		Wobble = {
			{Joint = "Wings", Rot = V(0, 0, 0), Pos = V(0, 0.06, 0), Rate = 1.2, Moving = 1.5},
			{Joint = "Digit1", Rot = V(90, 0, 0), Pulse = 0.12, Rate = 0.25},
			{Joint = "Digit2", Rot = V(90, 0, 0), Pulse = 0.12, Rate = 0.5},
			{Joint = "Digit3", Rot = V(90, 0, 0), Pulse = 0.12, Rate = 1},
			{Joint = "Digit4", Rot = V(90, 0, 0), Pulse = 0.12, Rate = 2}, -- the last digit ticks fastest, like a counter
		},
		-- signature move: New High Score. A pixel firework of digits and a quick loop-de-loop
		Special = {Kind = "Roll", Axis = "X", Every = {9, 13}, Duration = 1.6, Rise = 0.9, Finish = true, Bursts = {{"OneUp", 0.1, 45}, {"OneUp", 0.55, 30}}},
		Glow = {{Light = "VectorGlow", Flicker = 0.15, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"PixelTrail"},
	},
	GlitchPhantom = {
		Id = "glitch_phantom",
		No = 35,
		Tier = 6, -- Mythic
		Mode = "Glide",
		-- teleport-steps: it hangs back, then snaps forward
		Glide = {Bob = 0.12, BobRate = 0.35, Climb = 3, Tilt = 6, Bank = 20, Snap = 4},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.25},
		-- now and then a short tear: one joint jumps and red/blue copies split off to the sides
		Glitch = {Joints = {"Neck", "Body", "Ears", "Legs"}, Every = {0.8, 2.4}, Amount = 0.14, Frames = 5, Copies = {"GhostR", "GhostB"}, Split = 0.16},
		Orbit = {Parts = {"Block1", "Block2", "Block3"}, Radius = 1.7, Rate = 0.2, Bob = 0.2, Tilt = 15, Spin = 3},
		-- transformation: Corrupt. It glitches into a floating data cube and back
		Special = {Kind = "Morph", Every = {11, 16}, Duration = 3, Hide = {"Body", "Head", "Ears", "Whiskers", "Legs", "GhostR", "GhostB"},
			Show = {"CubeForm"}, Rise = 0.5, Radius = 0, Bursts = {{"GlitchBurst", 0.18, 40}, {"GlitchBurst", 0.82, 40}}},
		Glow = {{Light = "GlitchGlow", Flicker = 0.4, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"GlitchTrail"},
	},
	FinalBoss = {
		Id = "final_boss",
		No = 36,
		Tier = 7, -- Secret
		Mode = "Bound",
		-- menacing breathing; heavy stomping bound
		Body = {Breathe = 0.07, BreatheRate = 0.35, Lean = 4},
		Move = {HopHeight = 0.14, HopRate = 1.5, Pitch = 3},
		Head = {LookYaw = 15, LookPitch = 5, LookRate = 0.12},
		Wobble = {
			{Joint = "ArmL", Rot = V(6, 0, 4), Rate = 0.35, Moving = 1.5},
			{Joint = "ArmR", Rot = V(6, 0, -4), Rate = 0.35, Phase = 0.5, Moving = 1.5},
			{Joint = "Core", Pos = V(0, 0, -0.05), Pulse = 0.3, Rate = 0.9, Moving = 1}, -- the core pulses
		},
		-- Secret mechanic: Phase 2. The armour rattles, bursts off and circles the exposed core on its energy arcs,
		-- then flies home and locks back on
		Special = {Kind = "Morph", Every = {13, 19}, Duration = 4, Finish = true, Hide = {"Body"}, Show = {"CoreFrame"}, Scatter = {"Spikes", "Neck", "ArmL", "ArmR"},
			Radius = 1.6, Rise = 0.3, Bursts = {{"Overload", 0.12, 50}, {"Overload", 0.92, 30}, {"StompDust", 0.92, 10}}},
		Glow = {{Light = "CoreGlow", Flicker = 0.25, Flare = 2.5}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		LandFx = {"StompDust", 5},
	},
	BoltBug = {
		Id = "bolt_bug",
		No = 37,
		Tier = 1, -- Common
		Mode = "Scuttle",
		Scuttle = {StepRate = 6, Bounce = 0.03, Rock = 4, Side = 0}, -- quick little scuttle
		Body = {Breathe = 0.02, BreatheRate = 1.2, Lean = 6},
		Head = {LookYaw = 15, LookPitch = 5, LookRate = 0.3},
		Wobble = {
			{Joint = "Antenna", Rot = V(10, 0, 14), Every = {1.5, 4}, Time = 0.35}, -- the spark-plug antenna twitches
		},
	},
	DronePup = {
		Id = "drone_pup",
		No = 38,
		Tier = 2, -- Uncommon
		Mode = "Hover",
		-- hovers with a tilt-wobble; tips forward into the direction of travel
		Hover = {Bob = 0.1, BobRate = 0.6, Heave = 0, Drift = 0.25, DriftRate = 0.35, Tilt = 18, Bank = 30},
		Spinners = {Joints = {"Rotor1", "Rotor2", "Rotor3", "Rotor4"}, Rate = 5, MoveRate = 9},
		Wobble = {
			{Joint = "Ears", Rot = V(15, 0, 0), Rate = 0.7, Moving = 1.5, Sweep = V(25, 0, 0)}, -- floppy ear antennas
		},
	},
	SynthSlime = {
		Id = "synth_slime",
		No = 39,
		Tier = 2, -- Uncommon
		Mode = "Hop",
		-- squishy hops in time with the beat
		Hop = {Rate = 2, MaxRate = 3, Stride = 1.6, Air = 0.4, Height = 0.45, Pitch = 5, Squash = 0.18},
		Body = {Breathe = 0.04, BreatheRate = 2, Lean = 4},
		Wobble = {
			{Joint = "Bars", Pos = V(0, 0.18, 0), Pulse = 0.35, Rate = 2, Moving = 1}, -- equalizer bars bounce to a 120 bpm beat
			{Joint = "Face", Pos = V(0, 0.03, 0), Pulse = 0.35, Rate = 2, Moving = 0.5},
		},
	},
	MechRaptor = {
		Id = "mech_raptor",
		No = 40,
		Tier = 3, -- Rare
		Mode = "Bound",
		-- walks instead of bounding: a low gait with legs swinging in turn; the head stays level like a bird's
		Body = {Breathe = 0.02, BreatheRate = 0.8, Lean = 8},
		Move = {HopHeight = 0.065, HopRate = 1.6, Pitch = 2}, -- scaled up 1.3x (owner feedback): longer, slower strides
		Walk = {Legs = {{"LegL", 1}, {"LegR", -1}}, Swing = 30, Lift = 0.16},
		Head = {LookYaw = 25, LookPitch = 6, LookRate = 0.35},
		Tail = {Sway = 10, SwayRate = 0.9, Stream = 8}, -- the tail balances
		Wobble = {
			{Joint = "Arms", Rot = V(12, 0, 0), Rate = 0.6, Moving = 1.2},
		},
		Orbit = {Parts = {"Scanner"}, Radius = 1.5, Rate = 0.2, Bob = 0.15, Tilt = 10, Spin = 0},
		MoveFx = {"OrangeTrail"},
	},
	ChromePanther = {
		Id = "chrome_panther",
		No = 41,
		Tier = 4, -- Epic
		Mode = "Bound",
		-- low, fast prowling bound
		Body = {Breathe = 0.03, BreatheRate = 0.7, Lean = 12},
		Move = {HopHeight = 0.3, HopRate = 2.8, Pitch = 6},
		Head = {LookYaw = 20, LookPitch = 5, LookRate = 0.2, Down = 10},
		Ears = {TwitchAngle = 20, TwitchEvery = {2, 5}, Back = 25},
		Tail = {Sway = 20, SwayRate = 1.2, Stream = 25, Wag = {Angle = 25, Rate = 3, Every = {3, 6}, Time = 0.8}}, -- tail lash
		Wobble = {
			{Joint = "ScanArm", Rot = V(0, 40, 0), Rate = 0.6}, -- the scan sweeps side to side
		},
		Orbit = {Parts = {"HoloCube1", "HoloCube2"}, Radius = 1.4, Rate = 0.2, Bob = 0.15, Tilt = 12, Spin = 2},
		-- signature move: Holo Scan. The visor projects a fan of scanning beams that sweeps the ground
		Special = {Kind = "Ignite", Every = {8, 12}, Duration = 2.8, Part = "Visor", Hot = Color3.fromRGB(150, 245, 255),
			Rays = {"Scan1", "Scan2", "Scan3", "Scan4", "Scan5"}, Rise = 0, Rear = 4},
		Glow = {{Light = "NeonGlow", Flicker = 0.2, Flare = 2}},
		MoveFx = {"MagentaTrail"},
	},
	HyperdriveHawk = {
		Id = "hyperdrive_hawk",
		No = 42,
		Tier = 5, -- Legendary
		Mode = "Hover",
		-- hovers on jet thrust with small corrections; banking jet flight, wings swept back at speed
		Hover = {Bob = 0.08, BobRate = 0.8, Heave = 0, Drift = 0.12, DriftRate = 0.35, Tilt = 20, Bank = 45},
		Wings = {Rate = 0.3, MoveRate = 0.6, Amp = 4, MoveAmp = 6, Rest = 2, Sweep = 30},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.25},
		Wobble = {
			{Joint = "TailFan", Rot = V(6, 8, 0), Rate = 0.5, Moving = 1},
		},
		Orbit = {Parts = {"EnergyOrb1", "EnergyOrb2"}, Radius = 1.6, Rate = 0.3, Bob = 0.2, Tilt = 15, Spin = 0},
		-- signature move: Boost. Energy blades extend, the afterburners flare and it throws a quick loop
		Special = {Kind = "Roll", Axis = "X", Every = {9, 13}, Duration = 1.6, Rise = 1.2, Finish = true, Show = {"BladeL", "BladeR"},
			Surge = {Emitters = {"AfterburnerL", "AfterburnerR"}, By = 0.5}},
		Glow = {{Light = "EngineGlow", Flicker = 0.2, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
		MoveFx = {"JetTrailL", "JetTrailR"},
	},
	MainframeBeetle = {
		Id = "mainframe_beetle",
		No = 43,
		Tier = 6, -- Mythic
		Mode = "Scuttle",
		Scuttle = {StepRate = 2.5, Bounce = 0.05, Rock = 4, Side = 0}, -- heavy scuttle
		Body = {Breathe = 0.02, BreatheRate = 0.5, Lean = 5},
		Head = {LookYaw = 10, LookPitch = 8, LookRate = 0.15}, -- the horn tilts
		Wobble = {
			{Joint = "StatusLights", Pos = V(0, 0.015, 0), Pulse = 0.5, Rate = 1.6}, -- status lights blink
		},
		Orbit = {Parts = {"DataCube1", "DataCube2", "DataCube3"}, Radius = 2.1, Rate = 0.12, Bob = 0.2, Tilt = 10, Spin = 1.5},
		-- transformation: Overclock. The shell halves swing open, wings unfold and buzz, data streams spiral up
		Special = {Kind = "Ignite", Every = {11, 16}, Duration = 3.4, Parts = {"StatusLights"}, Hot = Color3.fromRGB(200, 255, 220),
			Rays = {"DataStream1", "DataStream2", "DataStream3", "DataStream4"}, Surge = {Emitters = {"DataBits"}, By = 3},
			Pose = {ShellL = V(0, 0, 70), ShellR = V(0, 0, -70), Wings = V(-15, 0, 0)}, Rise = 0.3, Rear = 6},
		Glow = {{Light = "DataGlow", Flicker = 0.15, Flare = 2.5}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
	},
	QuantumCoreWyrm = {
		Id = "quantum_core_wyrm",
		No = 44,
		Tier = 7, -- Secret
		Mode = "Slither",
		-- smooth chain flight: the holo rings follow the head, the singularity turns inside the middle ring
		Slither = {Rate = 0.25, MoveRate = 1.2, Yaw = 6, Idle = 0.6, Sway = 0.1, Bob = 0.2, BobRate = 0.3},
		Body = {Breathe = 0.01, BreatheRate = 0.5, Lean = 10},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.2},
		Chain = {Joints = {"Seg2", "Seg3", "Seg4", "Seg5", "Seg6", "Seg7", "Seg8"}, Lag = 0.7, Amp = 7, Idle = 0.7, Bend = 6, Rise = 4},
		Wobble = {
			{Joint = "Jaw", Rot = V(-14, 0, 0), Every = {4, 8}, Time = 1},
			{Joint = "Crest", Rot = V(6, 0, 0), Rate = 0.4, Moving = 1.5, Sweep = V(15, 0, 0)}, -- the fin crest streams back in flight
		},
		Spin = {Joint = "Core", Rate = 0.4, Bob = 0.03},
		-- Secret mechanic: Phase Shift. It fades out, reappears on your other side with a ring flash, then phases back
		-- (no Finish: an interrupt mirrors it into the fade-out and jump home, so it never follows from the wrong side)
		Special = {Kind = "Phase", Every = {12, 18}, Duration = 4, Jump = V(7.2, 0, 0),
			Bursts = {{"PhaseFlash", 0.12, 60}, {"PhaseFlash", 0.24, 60}, {"PhaseFlash", 0.72, 60}, {"PhaseFlash", 0.84, 60}}},
		Glow = {{Light = "CoreGlow", Flicker = 0.2, Flare = 2}, {Light = "RarityGlow", Flicker = 0.08, Flare = 1.5}},
	},
	WispKit = {
		Id = "wisp_kit",
		No = 45,
		Tier = 1, -- Common
		Mode = "Glide",
		-- floats low after you; the wispy tail curls and uncurls
		Glide = {Bob = 0.15, BobRate = 0.4, Climb = 5, Tilt = 6, Bank = 20},
		Head = {LookYaw = 20, LookPitch = 8, LookRate = 0.3, Tilt = {Angle = 16, Every = {3, 6}, Time = 1.2}},
		Wobble = {
			{Joint = "Tail", Rot = V(0, 25, 10), Rate = 0.35, Moving = 1.2, Sweep = V(25, 0, 0)},
			{Joint = "Ears", Rot = V(-12, 0, 0), Every = {2, 5}, Time = 0.3}, -- ear flick
		},
	},
	LanternImp = {
		Id = "lantern_imp",
		No = 46,
		Tier = 2, -- Uncommon
		Mode = "Hover",
		Hover = {Bob = 0.12, BobRate = 0.5, Heave = 0.08, Drift = 0.25, DriftRate = 0.15, Tilt = 14, Bank = 30},
		Wings = {Rate = 2, MoveRate = 5, Amp = 18, MoveAmp = 35, Rest = 5, Sweep = 6},
		Head = {LookYaw = 22, LookPitch = 8, LookRate = 0.3, Tilt = {Angle = 18, Every = {3, 6}, Time = 1}}, -- mischievous head cocks
		Wobble = {
			{Joint = "Lantern", Rot = V(12, 0, 14), Rate = 0.6, Moving = 0.6, Sweep = V(30, 0, 0)}, -- pendulum, lags behind in flight
			{Joint = "Tail", Rot = V(0, 20, 0), Rate = 0.7, Moving = 1.2},
		},
	},
	BoneRaven = {
		Id = "bone_raven",
		No = 47,
		Tier = 3, -- Rare
		Mode = "Hover",
		-- ragged flapping flight with small lurches; sharp, bird-like head tilts
		Hover = {Bob = 0.12, BobRate = 0.4, Heave = 0.12, Drift = 0.2, DriftRate = 0.1, Tilt = 16, Bank = 35, Jitter = 0.12},
		Wings = {Rate = 0.6, MoveRate = 3, Amp = 10, MoveAmp = 38, Rest = 5, Sweep = 8},
		Head = {LookYaw = 25, LookPitch = 8, LookRate = 0.3, Tilt = {Angle = 30, Every = {3, 6}, Time = 1}},
		Wobble = {
			{Joint = "Tail", Rot = V(8, 10, 0), Rate = 0.5, Moving = 1},
			{Joint = "Talons", Rot = V(10, 0, 0), Rate = 0.4, Moving = 0.5, Sweep = V(30, 0, 0)}, -- tucked back in flight
		},
		Orbit = {Parts = {"Wisp"}, Radius = 1.3, Rate = 0.2, Bob = 0.2, Tilt = 12, Spin = 0},
		MoveFx = {"FeatherTrail"},
	},
	HauntedArmorHound = {
		Id = "haunted_armor_hound",
		No = 48,
		Tier = 4, -- Epic
		Mode = "Bound",
		-- clanking bound; the empty plates rattle and the plume sways
		Body = {Breathe = 0.03, BreatheRate = 0.6, Lean = 8},
		Move = {HopHeight = 0.35, HopRate = 2.2, Pitch = 7},
		Head = {LookYaw = 18, LookPitch = 6, LookRate = 0.2},
		Tail = {Sway = 14, SwayRate = 0.8, Stream = 20},
		Wobble = {
			{Joint = "Plates", Pos = V(0.015, 0.025, 0), Rate = 3, Idle = 0.4, Moving = 1},
			{Joint = "Plume", Rot = V(10, 0, 8), Rate = 0.5, Moving = 1.5, Sweep = V(25, 0, 0)},
		},
		Orbit = {Parts = {"Flame1", "Flame2"}, Radius = 1.5, Rate = 0.18, Bob = 0.15, Tilt = 10, Spin = 0},
		-- signature move: Lost My Head. The helmet pops off, spins in the air and clunks back on; ghost flame roars
		-- out of the empty neck meanwhile
		Special = {Kind = "PopOff", Every = {8, 12}, Duration = 3, Finish = true, Joint = "Neck", Height = 1.1, Spins = 1,
			Surge = {Emitters = {"NeckFlame"}, By = 8}, Bursts = {{"Pop", 0.05, 20}, {"Pop", 0.92, 15}}},
		Glow = {{Light = "VisorGlow", Flicker = 0.15, Flare = 1.5}},
		MoveFx = {"GhostTrail"},
	},
	SpecterJelly = {
		Id = "specter_jelly",
		No = 49,
		Tier = 4, -- Epic
		Mode = "Glide",
		Glide = {Bob = 0.25, BobRate = 0.3, Climb = 4, Tilt = 10, Bank = 20},
		Wobble = {
			{Joint = "Inner", Pos = V(0, 0.06, 0), Pulse = 0.4, Rate = 0.5, Moving = 1}, -- the inner glow pulses
			{Joint = "Tent1", Rot = V(14, 0, 10), Rate = 0.5, Moving = 1.5, Sweep = V(30, 0, 0)}, -- tentacles wave in turn
			{Joint = "Tent2", Rot = V(14, 0, 10), Rate = 0.5, Phase = 0.25, Moving = 1.5, Sweep = V(30, 0, 0)},
			{Joint = "Tent3", Rot = V(14, 0, -10), Rate = 0.5, Phase = 0.5, Moving = 1.5, Sweep = V(30, 0, 0)},
			{Joint = "Tent4", Rot = V(14, 0, -10), Rate = 0.5, Phase = 0.75, Moving = 1.5, Sweep = V(30, 0, 0)},
		},
		Orbit = {Parts = {"Soul1", "Soul2", "Soul3"}, Radius = 1.5, Rate = 0.12, Bob = 0.25, Tilt = 10, Spin = 0},
		-- signature move: Pulse Dash. One big squeeze shoots it forward, releasing a ring of light
		Special = {Kind = "Dash", Every = {8, 12}, Duration = 2.4, Finish = true, Dist = 2.5, Rise = 0.3, Tip = 20,
			Pose = {Tent1 = V(-25, 0, 0), Tent2 = V(-25, 0, 0), Tent3 = V(-25, 0, 0), Tent4 = V(-25, 0, 0)}, Bursts = {{"LightRing", 0.3, 50}}},
		Glow = {{Light = "JellyGlow", Flicker = 0.1, Flare = 2}},
		MoveFx = {"SpecterTrail"},
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

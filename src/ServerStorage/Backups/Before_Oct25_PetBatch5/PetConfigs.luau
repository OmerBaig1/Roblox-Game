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
		Wings = {Rate = 0.8, MoveRate = 9, Amp = 6, MoveAmp = 45, Rest = -10, Sweep = 6},
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

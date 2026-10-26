--[[
	PetConfigs (Pet Lab draft)
	Per-pet motion and effect settings read by PetAnimator. Angles are degrees, distances studs, rates cycles/second.
	Every premium pet gets one entry keyed by its model name. Later this merges into the real pet catalog.
]]
return {
	CinderLynx = {
		Id = "cinder_lynx",
		Tier = 4, -- Epic
		Body = {Breathe = 0.035, BreatheRate = 0.9, Lean = 10},
		Head = {LookYaw = 20, LookPitch = 6, LookRate = 0.22},
		Ears = {TwitchAngle = 28, TwitchEvery = {2, 6}, Back = 22},
		Tail = {Sway = 16, SwayRate = 0.8, Stream = 30},
		Move = {HopHeight = 0.45, HopRate = 2.4, Pitch = 7},
		Orbit = {Parts = {"Shard1", "Shard2", "Shard3"}, Radius = 1.45, Rate = 0.18, Bob = 0.15, Tilt = 14, Spin = 1.4},
		-- signature move: flicks its tail up and throws off a shower of embers
		Special = {Kind = "EmberFlick", Every = {7, 12}, Duration = 1.2},
	},
}

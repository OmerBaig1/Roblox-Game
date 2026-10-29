--[[
	HatchStyles: how each egg hatches (keys are PetData egg names). Played by the hatching show in Hatchery on the
	3D egg (c.Rig, an EggRig) and a 2D particle layer. Each style has:
	  Pace     multiplies the rarity's build-up time
	  Cam      {Yaw, Pitch, Dist} the camera starts at (degrees; Dist 1 = the egg fills the picture)
	  Start(c) once, before the build-up
	  Build(c, x)  every frame of the build-up, x = 0..1. Set c.Pose (the egg, in egg space), c.Yaw/Pitch/Dist, and paint,
	           light or move the rig; emit particles with c:emit (At/Target are px from the egg's centre)
	  Open(c)  how it breaks open; may wait (c:animate, c:wait). The pet appears when it returns
	  Reveal   "rise" (default) or "fade": how the pet appears
	The show adds the shared parts: seam cracks spreading over the second half, the rarity's colour, knocks' sounds
	and the 10-egg grid (c.Lite: smaller particles and no flashes). Durations stay short; Skip jumps to the reveal.
]]
local S = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE = Color3.new(1, 1, 1)
local rad, sin, cos, noise = math.rad, math.sin, math.cos, math.noise
local V = Vector2.new
local function rnd(a, b)
	return a + (b - a) * math.random()
end
local function outCubic(a)
	return 1 - (1 - a) ^ 3
end
local function inOut(a)
	return a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2
end
local function outBack(a)
	local c1 = 1.70158
	return 1 + (c1 + 1) * (a - 1) ^ 3 + c1 * (a - 1) ^ 2
end
local STAR, SNOW, SPARK = "\u{2726}", "\u{2744}", "\u{2727}"

------------------------------------------------------------------
-- EMBER: it rumbles, the veins run white-hot, smoke and embers rise, then the cap blasts off on a lava fountain
------------------------------------------------------------------
S["Ember Egg"] = {
	Pace = 1, Cam = {Yaw = 14, Pitch = 6, Dist = 1},
	Build = function(c, x)
		local j = 0.015 + 0.06 * x * x
		c.Pose = CFrame.new(noise(c.T * 13, 0.5) * j * 2, 0, noise(c.T * 13, 7.3) * j * 2) * CFrame.Angles(0, 0, rad(noise(c.T * 15, 3.1) * 12 * x))
		c.Rig:paint("Glow", rgb(255, 238, 170), x * 0.9)
		c.Pitch = 6 - 10 * x
		c.Dist = 1 - 0.1 * x
		if c:every("smoke", 0.2 - 0.11 * x) then
			c:emit({At = V(rnd(-30, 30), -125), Colors = {rgb(72, 62, 60), rgb(100, 86, 82)}, Size = {20, 30}, Grow = 2.6, Speed = {30, 60}, Dir = {-20, 20}, Life = {1.1, 1.6}, Alpha = 0.5, Drag = 0.4, Z = 4})
		end
		if c:every("embers", 0.11 - 0.08 * x) then
			c:emit({At = V(0, 105), Spread = 75, Colors = {rgb(255, 140, 40), rgb(255, 205, 90)}, Size = {4, 7}, Speed = {70, 150}, Dir = {-30, 30}, Gravity = -60, Life = {0.6, 1}, Z = 9})
		end
		c:knocks(x, 7, function(k)
			c:jolt(2 + k * 0.6)
			c:sfx("eggknock", 0.7 + k * 0.04)
			c:emit({At = V(0, 125), Count = 4, Spread = 45, Colors = {rgb(60, 50, 48)}, Size = {10, 16}, Grow = 2, Speed = {20, 50}, Dir = {-80, 80}, Life = {0.5, 0.8}, Alpha = 0.4, Z = 4})
		end)
	end,
	Open = function(c)
		c:sfx("eggcrack")
		c:flash(rgb(255, 150, 60), 0.4)
		c:shake(9)
		c:shards({Count = 12, Colors = {rgb(46, 34, 32), rgb(64, 46, 42)}, Material = Enum.Material.Basalt, Speed = {9, 16}, Up = 0.9, Gravity = 26, Size = {0.22, 0.42}, Y = 1.9})
		c:emit({At = V(0, -30), Count = 30, Colors = {rgb(255, 120, 30), rgb(255, 200, 80), rgb(255, 80, 20)}, Size = {6, 12}, Speed = {300, 480}, Dir = {-30, 30}, Gravity = 900, Life = {0.8, 1.2}, Z = 10})
		c:ring(rgb(255, 140, 40), 50, 300, 0.55, 8)
		c:animate(0.6, function(a)
			local e = 1 - (1 - a) ^ 2
			c.Rig.Piece.Top = CFrame.new(0, 3.4 * e, 0) * c:around(2.2, CFrame.Angles(0, a * 8, a * 0.8))
			c.Rig:fade(a * a, "Top")
		end)
	end,
}

------------------------------------------------------------------
-- TIDE: it rides the swell like a buoy, ripples spread and bubbles rise, then it bursts in a splash
------------------------------------------------------------------
S["Tide Egg"] = {
	Pace = 1.05, Cam = {Yaw = 18, Pitch = 10, Dist = 1},
	Build = function(c, x)
		local amp = 0.6 + x
		c.Pose = CFrame.new(0, sin(c.T * 2.6) * 0.1 * amp, 0) * c:around(0.4, CFrame.Angles(rad(sin(c.T * 2) * 6 * amp), 0, rad(cos(c.T * 1.7) * 8 * amp)))
		c.Rig:paint("Glow", WHITE, x)
		if c:every("ripple", 0.75 - 0.4 * x) then
			c:ring(rgb(170, 230, 255), 60, 300, 1.1, 3, 0.28, V(0, 118))
		end
		if c:every("bubbles", 0.17 - 0.11 * x) then
			c:emit({At = V(0, 110), Spread = 80, Shape = "ring", Colors = {rgb(200, 240, 255)}, Size = {8, 16}, Speed = {60, 110}, Dir = {-12, 12}, Life = {1, 1.5}, Alpha = 0.15, Drag = 0.2, Z = 9})
		end
		c:knocks(x, 6, function(k)
			c:sfx("eggknock", 1.2 + k * 0.06)
			c:jolt(1.5)
		end)
	end,
	Open = function(c)
		c:sfx("eggcrack")
		c:flash(rgb(140, 220, 255), 0.35)
		c:shards({Count = 14, Colors = {rgb(56, 140, 222), rgb(26, 74, 168), rgb(240, 250, 255)}, Speed = {7, 13}, Up = 0.6, Gravity = 30, Size = {0.2, 0.38}, Y = 1.4})
		c:emit({At = V(0, -10), Count = 34, Colors = {rgb(120, 200, 255), rgb(190, 240, 255), WHITE}, Size = {6, 11}, Speed = {250, 420}, Dir = {-60, 60}, Gravity = 1000, Life = {0.7, 1.1}, Z = 10})
		c:ring(rgb(190, 240, 255), 40, 360, 0.6, 6, 0.32, V(0, 110))
		c:ring(rgb(190, 240, 255), 40, 260, 0.6, 4)
		c:animate(0.12, function(a)
			c.Rig:fade(a)
		end)
	end,
}

------------------------------------------------------------------
-- GROVE: it sways while the vine grows back up it and petals spiral in, then the top opens like a seed pod
------------------------------------------------------------------
S["Grove Egg"] = {
	Pace = 1.1, Cam = {Yaw = 20, Pitch = 12, Dist = 1},
	Start = function(c)
		c.Rig.Grow = 0
	end,
	Build = function(c, x)
		c.Rig.Grow = math.min(1, x * 1.25)
		c.Pose = c:around(0, CFrame.Angles(0, 0, rad(sin(c.T * 1.6) * 5 * (0.5 + x))))
		if c:every("petals", 0.13 - 0.08 * x) then
			local a = math.random() * math.pi * 2
			c:emit({At = V(cos(a), sin(a)) * 250, Target = V(0, -10), Colors = {rgb(255, 170, 205), rgb(255, 222, 236), rgb(150, 225, 110)}, Size = {9, 14}, Squash = 0.6, Life = {0.9, 1.3}, Spin = {-200, 200}, Z = 9})
		end
		c:glow(rgb(190, 255, 150), 1 - 0.55 * x)
		c:knocks(x, 6, function(k)
			c:sfx("eggknock", 1 + k * 0.05)
			c:jolt(1.2)
		end)
	end,
	Open = function(c)
		c:sfx("eggcrack")
		c:flash(rgb(200, 255, 170), 0.3)
		c:beam(rgb(215, 255, 185), 0.9)
		c:emit({At = V(0, -40), Count = 30, Colors = {rgb(255, 170, 205), rgb(255, 222, 236), rgb(150, 225, 110)}, Size = {9, 15}, Squash = 0.6, Speed = {160, 320}, Dir = {-90, 90}, Gravity = 260, Life = {0.9, 1.4}, Spin = {-200, 200}, Z = 10})
		-- the lid swings back on a hinge at the back of the seam
		local hinge = CFrame.new(0, 1.8, 0.95)
		c:animate(0.55, function(a)
			local e = outBack(a)
			c.Rig.Piece.Top = CFrame.new(0, 0.25 * e, 0.2 * e) * hinge * CFrame.Angles(rad(105 * e), 0, 0) * hinge:Inverse()
		end)
	end,
}

------------------------------------------------------------------
-- FROST: frost creeps over it while snow falls; it freezes for a beat with the seam blazing, then shatters
------------------------------------------------------------------
S["Frost Egg"] = {
	Pace = 1.15, Cam = {Yaw = 16, Pitch = 9, Dist = 1},
	Start = function(c)
		c:backdrop(rgb(14, 30, 56), 0.1, 1)
	end,
	Build = function(c, x)
		local sh = 0.4 + 1.4 * x
		c.Pose = c:around(0, CFrame.Angles(rad(noise(c.T * 30, 1) * sh * 2), 0, rad(noise(c.T * 30, 2) * sh * 2)))
		c.Rig:paint("Shell", rgb(240, 250, 255), x * 0.75)
		c.Rig.TwinkleSpeed = 1 + 3 * x
		if c:every("snow", 0.15 - 0.1 * x) then
			c:emit({At = V(rnd(-280, 280), -280), Shape = SNOW, Colors = {rgb(220, 240, 255), WHITE}, Size = {10, 18}, Speed = {40, 80}, Dir = {165, 195}, Spin = {-60, 60}, Life = {2.2, 3}, Alpha = 0.1, Z = 6})
		end
		c:knocks(x, 5, function(k)
			c:sfx("eggknock", 1.5 + k * 0.05)
			c:jolt(0.8)
			c:emit({At = V(0, -10), Spread = 90, Count = 3, Shape = SPARK, Colors = {WHITE}, Size = {10, 16}, Speed = {0, 10}, Life = {0.35, 0.5}, Z = 11})
		end)
	end,
	Open = function(c)
		c.Rig:reveal("Crack", 1, WHITE)
		c:wait(0.16)
		c:sfx("eggcrack")
		c:flash(rgb(200, 235, 255), 0.5)
		c:shake(5)
		c.Rig:fade(1, "Top")
		c.Rig:fade(1, "Bottom")
		c:shards({Count = 18, Colors = {rgb(200, 235, 255), rgb(235, 248, 255), rgb(150, 210, 250)}, Material = Enum.Material.Glass, Transparency = 0.15, Speed = {10, 17}, Up = 0.25, Gravity = 8, Size = {0.2, 0.45}, Y = 1.4})
		c:emit({Count = 18, Shape = STAR, Colors = {WHITE, rgb(190, 230, 255)}, Size = {12, 22}, Speed = {200, 340}, Drag = 2, Life = {0.6, 0.9}, Spin = {-120, 120}, Z = 10})
		c:ring(rgb(220, 245, 255), 60, 380, 0.5, 10)
	end,
}

------------------------------------------------------------------
-- ARCADE: 8-bit everything (it hops in steps, flickers through the palette, a loading bar fills), then a pixel burst
------------------------------------------------------------------
local PAL = {rgb(255, 70, 185), rgb(60, 230, 255), rgb(255, 230, 80), rgb(120, 255, 130)}
S["Arcade Egg"] = {
	Pace = 0.95, Cam = {Yaw = 12, Pitch = 8, Dist = 1},
	Start = function(c)
		c.Palette = 1
		c.Loading = c:bar(10, PAL)
	end,
	Build = function(c, x)
		local step = math.floor(c.T * 12) / 12
		local hop = math.abs(sin(step * 7)) * 0.2 * (0.4 + x)
		c.Pose = CFrame.new(0, math.floor(hop / 0.05) * 0.05, 0)
		c.Rig.OrbitSpeed = 1 + 7 * x
		if c:every("palette", 0.18 - 0.11 * x) then
			c.Palette = c.Palette % #PAL + 1
			c.Rig:paint("Glow", PAL[c.Palette], 0.85)
		end
		c.Loading(x)
		if c:every("pixels", 0.08) then
			local a = math.random() * math.pi * 2
			c:emit({At = V(cos(a), sin(a)) * rnd(120, 200), Shape = "square", Colors = PAL, Size = {6, 10}, Speed = {0, 0}, Life = {0.25, 0.45}, Z = 9})
		end
		c:knocks(x, 8, function(k)
			c:sfx("eggknock", 1.6 + k * 0.08)
			c:jolt(1)
		end)
	end,
	Open = function(c)
		for _ = 1, 2 do
			c.Rig:fade(1)
			c:wait(0.05)
			c.Rig:fade(0)
			c:wait(0.05)
		end
		c:sfx("eggcrack")
		c:flash(rgb(255, 120, 230), 0.3)
		c.Rig:fade(1)
		c.Loading(nil)
		c:emit({Count = 46, Shape = "square", Colors = {rgb(112, 58, 205), PAL[1], PAL[2], PAL[3], PAL[4]}, Size = {8, 14}, Speed = {160, 360}, Drag = 1.5, Gravity = 300, Life = {0.7, 1.1}, Z = 10})
		c:shards({Count = 14, Colors = {rgb(112, 58, 205), PAL[1], PAL[2]}, Cube = true, Speed = {8, 14}, Up = 0.5, Gravity = 22, Size = {0.2, 0.3}, Y = 1.4})
	end,
}

------------------------------------------------------------------
-- CIRCUIT: a boot sequence (traces light bottom to top, a scanner sweeps, servos turn it in steps), then it unscrews
------------------------------------------------------------------
S["Circuit Egg"] = {
	Pace = 1.1, Cam = {Yaw = 10, Pitch = 8, Dist = 1},
	Start = function(c)
		c.Rig:light("Glow", 0, 0.85)
		c.Spin, c.Turns = 0, 0
		c.Scan = c:scanner(rgb(90, 240, 255))
	end,
	Build = function(c, x)
		c.Rig:light("Glow", x * 1.05, 0.85)
		local turns = math.floor(x * 4)
		if turns > c.Turns then
			c.Turns = turns
			c:sfx("eggknock", 0.9)
			c:jolt(0.6)
		end
		c.Spin += (rad(turns * 30) - c.Spin) * math.min(1, c.Dt * 10)
		c.Pose = CFrame.new(0, 0.18 * x, 0) * CFrame.Angles(0, c.Spin, 0)
		c.Scan(sin(c.T * 3) * 120)
		if x > 0.6 and c:every("steam", 0.22) then
			local side = math.random() < 0.5 and -1 or 1
			c:emit({At = V(side * 105, -25), Count = 2, Colors = {rgb(230, 240, 250)}, Size = {10, 16}, Grow = 2.5, Speed = {80, 140}, Dir = {side * 90 - 15, side * 90 + 15}, Life = {0.5, 0.8}, Alpha = 0.35, Drag = 2, Z = 8})
		end
	end,
	Open = function(c)
		c.Scan(nil)
		c:sfx("eggknock", 0.8)
		c:animate(0.22, function(a)
			c.Rig.Piece.Top = CFrame.Angles(0, rad(90) * inOut(a), 0)
		end)
		c:sfx("eggcrack")
		c:flash(rgb(90, 240, 255), 0.35)
		c:ring(rgb(90, 240, 255), 50, 300, 0.45, 5)
		c:emit({Count = 24, Shape = "square", Colors = {rgb(90, 240, 255), rgb(200, 250, 255)}, Size = {5, 9}, Speed = {200, 360}, Drag = 2.5, Life = {0.5, 0.8}, Z = 10})
		for _, side in ipairs({-1, 1}) do
			c:emit({At = V(side * 100, -20), Count = 5, Colors = {rgb(235, 245, 255)}, Size = {14, 22}, Grow = 2.5, Speed = {120, 200}, Dir = {side * 90 - 20, side * 90 + 20}, Life = {0.6, 0.9}, Alpha = 0.3, Drag = 2, Z = 8})
		end
		c:animate(0.5, function(a)
			c.Rig.Piece.Top = CFrame.new(0, 0.5 * a + 3 * a * a, 0) * CFrame.Angles(0, rad(90) + a * 10, 0)
			c.Rig:fade(a ^ 3, "Top")
		end)
	end,
}

------------------------------------------------------------------
-- PHANTOM: the lights go out, it drifts and flickers, its runes wake one by one, then it lets go into smoke
------------------------------------------------------------------
S["Phantom Egg"] = {
	Pace = 1.2, Cam = {Yaw = 14, Pitch = 10, Dist = 1.02}, Reveal = "fade",
	Start = function(c)
		c:backdrop(rgb(4, 2, 10), 0.04, 0.8)
		c.Rig:light("Rune", 0, 0.85)
	end,
	Build = function(c, x)
		c.Pose = CFrame.new(sin(c.T * 1.3) * 0.18, 0.15 + sin(c.T * 2.6) * 0.12, 0) * c:around(1.4, CFrame.Angles(0, sin(c.T * 0.9) * 0.4, rad(sin(c.T * 1.3) * 6)))
		local flicker = noise(c.T * 8, 4.2) > 0.3 - 0.35 * x
		c.Rig:fade(flicker and 0.55 * x or 0)
		c.Rig:light("Rune", x * 1.1, 0.85)
		c.Rig.OrbitSpeed = 1 + 4 * x
		if c:every("wisps", 0.16 - 0.08 * x) then
			c:emit({At = V(rnd(-80, 80), 100), Colors = {rgb(160, 100, 255), rgb(90, 50, 160)}, Size = {14, 22}, Grow = 2, Speed = {40, 80}, Dir = {-30, 30}, Life = {1, 1.5}, Alpha = 0.55, Z = 5})
		end
		c:knocks(x, 5, function(k)
			c:sfx("eggknock", 0.55 + k * 0.03)
			c:jolt(1)
		end)
	end,
	Open = function(c)
		c:sfx("sparkle", 0.6)
		c.Rig:paint("Core", rgb(255, 230, 255), 1)
		c:emit({Count = 26, Colors = {rgb(140, 90, 230), rgb(60, 30, 110), rgb(200, 160, 255)}, Size = {20, 34}, Grow = 2.2, Speed = {60, 160}, Drag = 1, Life = {0.9, 1.4}, Alpha = 0.45, Z = 9})
		c:ring(rgb(170, 110, 255), 30, 260, 0.8, 4)
		c:animate(0.7, function(a)
			c.Rig.Piece.Top = CFrame.new(0, a * 1.2, 0)
			c.Rig.Piece.Bottom = CFrame.new(0, a * 0.4, 0)
			c.Rig:fade(a)
		end)
	end,
}

------------------------------------------------------------------
-- CELESTIAL: it rises as the camera circles it, starlight gathers in and the ring spins up; it implodes, then novas
------------------------------------------------------------------
S["Celestial Egg"] = {
	Pace = 1.3, Cam = {Yaw = 10, Pitch = 8, Dist = 1.05},
	Start = function(c)
		c:backdrop(rgb(8, 6, 26), 0.03, 0.8)
		c:emit({At = V(0, 0), Count = 40, Spread = 520, Colors = {WHITE, rgb(200, 215, 255)}, Size = {2, 4}, Speed = {0, 4}, Life = {6, 8}, Alpha = 0.2, Z = 1})
	end,
	Build = function(c, x)
		c.Pose = CFrame.new(0, 0.6 * outCubic(x), 0)
		c.Rig.OrbitSpeed = 1 + 5 * x
		c.Rig.TwinkleSpeed = 1 + 4 * x
		c.Yaw = 10 + 70 * x * x
		c.Pitch = 8 - 6 * x
		c.Rig:paint("Shell", rgb(255, 240, 205), x * 0.55)
		if c:every("gather", 0.1 - 0.075 * x) then
			local a = math.random() * math.pi * 2
			c:emit({At = V(cos(a), sin(a)) * 280, Target = V(0, -20), Shape = STAR, Colors = {rgb(255, 240, 200), rgb(200, 220, 255), rgb(255, 200, 240)}, Size = {8, 14}, Life = {0.7, 1}, Spin = {-90, 90}, Z = 9})
		end
		c:glow(rgb(255, 230, 170), 1 - 0.6 * x)
		c:knocks(x, 6, function(k)
			c:sfx("sparkle", 0.9 + k * 0.08)
			c:jolt(0.5)
		end)
	end,
	Open = function(c)
		c.Rig:paint("Shell", WHITE, 1)
		c:scaleTo(0.55, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		c:wait(0.2)
		c:sfx("eggcrack")
		c:flash(rgb(255, 245, 220), 0.15)
		c:shake(6)
		c.Rig:fade(1)
		c:scaleTo(1, 0)
		c:ring(rgb(255, 225, 150), 30, 520, 0.7, 12)
		c:ring(rgb(200, 190, 255), 30, 380, 0.55, 6)
		c:emit({Count = 44, Shape = STAR, Colors = {rgb(255, 230, 160), WHITE, rgb(255, 190, 235), rgb(180, 210, 255)}, Size = {10, 20}, Speed = {260, 520}, Drag = 2.2, Life = {0.8, 1.3}, Spin = {-120, 120}, Z = 10})
	end,
}

------------------------------------------------------------------
-- any other egg: a wobble and a shatter
------------------------------------------------------------------
S.default = {
	Pace = 1, Cam = {Yaw = 15, Pitch = 9, Dist = 1},
	Build = function(c, x)
		c.Pose = c:around(0, CFrame.Angles(0, 0, rad(sin(c.T * 14) * 8 * x)))
		c:knocks(x, 6, function(k)
			c:sfx("eggknock", 1 + k * 0.06)
			c:jolt(1.5)
		end)
	end,
	Open = function(c)
		c:sfx("eggcrack")
		c:shards({Count = 12, Colors = {c.Egg.Color, c.Egg.Spot}, Speed = {8, 14}, Up = 0.6, Gravity = 26, Size = {0.2, 0.4}, Y = 1.4})
		c.Rig:fade(1)
	end,
}

return S

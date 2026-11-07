-- MAX. A star held in a gimbal of planets, throned on chrome and gold. A live sun burns at the top inside three great rings, each
-- turning its own way with a planet riding it. Sweeping gold horns rise from armoured nacelles with violet thrusters that
-- ignite on the throttle. The deck is black glass full of stars, a comet laps the whole machine, a nebula breathes round it.
return {Name = "Cosmic Emperor", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local void, chrome, gold, star, violet, cyan, rose, ink = rgb(16, 10, 34), rgb(170, 176, 196), rgb(235, 165, 35), rgb(255, 232, 170), rgb(150, 80, 255), rgb(120, 230, 255), rgb(255, 80, 150), rgb(8, 6, 18)
	k.box(0, 0.05, -0.8, 8.8, 0.1, 15.9, ink, M.Glass, {name = "StarFloor"})
	-- stars set in the black floor, twinkling
	local stars = {}
	for i = 1, 40 do
		local x, z = (i * 37 % 41) / 41 * 8.4 - 4.2, (i * 61 % 53) / 53 * 15.4 - 8.5
		if math.abs(x) > 2.7 or z < -6 or z > 5.6 then
			table.insert(stars, k.ball(x, 0.12, z, 0.07 + (i % 3) * 0.05, star, M.Neon, {name = string.format("Star%02d", i), shadow = false}))
		end
	end
	k.anim("pulse", stars, 0, 0, 0, {Speed = 1.5, Stagger = 2.4, ColorA = rgb(90, 70, 130), ColorB = star, Run = 2})
	k.box(0, 0.225, 0, 5.0, 0.45, 10, void, M.Glass, {solid = true, name = "Deck"})
	k.belt({rgb(20, 10, 40), rgb(44, 20, 84)}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		-- gold rails with a running violet light
		k.box(s * 2.36, 0.55, 0, 0.28, 0.3, 9.6, gold, M.Metal, {name = "Rail"})
		local run = {}
		for i = 0, 9 do
			table.insert(run, k.glow(s * 2.36, 0.72, -4.5 + i, 0.14, 0.04, 0.8, violet, {name = "RailCell" .. i}))
		end
		k.anim("pulse", run, 0, 0, 0, {Speed = 5, Stagger = 0.85, Sharp = 3, ColorA = rgb(40, 16, 90), ColorB = cyan, Idle = 0.5, Run = 2.6})
		-- the nacelle: chrome hull, black armour, a gold spine whose fins rise toward the back
		k.ell(s * 3.42, 0.95, 0, 2.3, 1.75, 10.0, chrome, M.Metal, {refl = 0.25, name = "Nacelle"})
		k.ell(s * 3.42, 1.35, 0, 1.75, 1.05, 8.6, void, M.Glass, {name = "Armour"})
		k.box(s * 3.42, 1.86, 0, 0.2, 0.1, 7.6, gold, M.Metal, {name = "Spine"})
		for i, z in ipairs({-3, -1.4, 0.2, 1.8, 3.2}) do
			local h = 0.3 + i * 0.22
			k.wedge(s * 3.42, 1.9 + h / 2, z, 0.1, h, 1.2, gold, M.Metal, {name = "Fin"})
		end
		local channel = {}
		for i = 0, 5 do
			table.insert(channel, k.glow(s * 4.5, 0.9, -3.8 + i * 1.5, 0.05, 0.2, 1.2, cyan, {name = "Channel" .. i}))
		end
		k.anim("pulse", channel, 0, 0, 0, {Speed = 3, Stagger = -0.9, Sharp = 2, ColorA = rgb(30, 50, 110), ColorB = cyan, Run = 2.4})
		k.ell(s * 3.42, 0.72, -5.0, 2.1, 1.1, 2.8, gold, M.Metal, {name = "Prow"})
		-- thruster: gold collar, a violet core, a flame that lengthens on the throttle
		k.cyl(s * 3.42, 0.85, 5.15, 1.2, 1.3, chrome, M.Metal, "z", {refl = 0.25, name = "Thruster"})
		k.cyl(s * 3.42, 0.85, 4.65, 0.22, 1.45, gold, M.Metal, "z")
		k.cyl(s * 3.42, 0.85, 5.8, 0.14, 1.45, gold, M.Metal, "z", {name = "ThrusterLip"})
		local core = k.cyl(s * 3.42, 0.85, 5.88, 0.05, 1.05, violet, M.Neon, "z", {name = "ThrusterCore"})
		k.anim("pulse", core, 0, 0, 0, {Speed = 8, ColorA = violet, ColorB = cyan, Idle = 0.4, Run = 1.6})
		local flame = k.cyl(s * 3.42, 0.85, 6.3, 0.8, 0.7, rgb(190, 150, 255), M.Neon, "z", {t = 0.2, name = "ThrusterFlame", shadow = false})
		k.anim("gauge", flame, 0, 0, 0, {GAxis = "X", FromEnd = -1, Speed = 20, Amp = 0.42, Idle = 0.15, Run = 1})
		k.emit(k.spot(s * 3.42, 0.85, 6.55, 0.7, 0.7, 0.1), {tex = "glow", c1 = cyan, c2 = violet, size = {0.75, 0.05}, alpha = {0.1, 1}, life = {0.2, 0.45}, speed = {8, 14}, rate = 2, run = 36, dir = "Back", spread = {6, 6}, light = 1})

		-- THE HORNS: triple-layered arcs up from the prows, curling over the head to the star
		k.box(s * 3.0, 0.8, -7.0, 1.4, 1.6, 1.5, chrome, M.Metal, {refl = 0.25, name = "HornFoot"})
		k.box(s * 3.0, 1.65, -7.0, 1.5, 0.14, 1.6, gold, M.Metal)
		k.box(s * 3.0, 0.8, -7.76, 1.0, 0.8, 0.03, void, M.Glass)
		k.ring(0, 4.4, -7.0, 4.28, 0.56, gold, M.Metal, "z", {n = 10, a0 = s * -142, a1 = s * -36, depth = 0.8, name = "Horn"})
		k.ring(0, 4.4, -7.0, 3.92, 0.2, chrome, M.Metal, "z", {n = 10, a0 = s * -142, a1 = s * -36, depth = 0.95, refl = 0.25, name = "HornBand"})
		local edge = k.ring(0, 4.4, -7.0, 3.74, 0.13, function(f)
			return violet:Lerp(cyan, f)
		end, M.Neon, "z", {n = 6, a0 = s * -138, a1 = s * -62, depth = 0.4, name = "HornEdge"})
		-- blades fanning off the horns' outside, like a crown
		for i, a in ipairs({-118, -96, -74, -54}) do
			local r = math.rad(a * s)
			local bx, by = -math.sin(r) * 4.6, 4.4 + math.cos(r) * 4.6
			if math.abs(bx) < 4.65 then
				k.wedge(bx, by + 0.25, -7.0, 0.1, 1.0, 0.6, gold, M.Metal, {name = "HornBlade"})
			end
		end
		-- a low wing strut at the back
		k.box(s * 1.6, 1.05, 6.6, 0.15, 1.0, 0.5, gold, M.Metal, {name = "WingStrut"})
	end)

	-- THE STAR in its gimbal: three great rings on their own axes, each carrying a planet, over the runner's head
	local cx, cy, cz = 0, 9.75, -7.0
	local sun = k.ball(cx, cy, cz, 1.45, star, M.Neon, {name = "StarCore"})
	k.anim("pulse", sun, 0, 0, 0, {Speed = 1.6, ColorA = rgb(250, 180, 70), ColorB = star, Run = 2.2})
	k.light(sun, rgb(230, 190, 255), 14, 0.8)
	k.emit(sun, {tex = "glow", c1 = rgb(255, 200, 110), c2 = violet, size = {2.2, 3.4}, alpha = {0.85, 1}, life = {1, 1.6}, speed = {0, 0}, rate = 1.5, spread = {0, 0}, light = 1})
	k.emit(k.spot(cx, cy, cz, 1, 1, 1), {tex = "sparks", c1 = star, c2 = gold, size = {0.3, 0.03}, life = {0.5, 1.1}, speed = {3, 7}, rate = 8, run = 24, spread = {180, 180}, light = 1})
	-- solar flares: spikes that turn round the star
	local flares = {}
	for i = 0, 7 do
		table.insert(flares, k.box(cx, cy, cz, 0.12, 2.15, 0.12, gold, M.Neon, {rz = i * 22.5, rx = i * 45, name = "Flare"}))
	end
	k.anim("spin", flares, cx, cy, cz, {Axis = V(0.3, 1, 0.2).Unit, Speed = 0.6, Run = 2.6})
	-- ring 1, biggest, tips forward; carries a ringed gas giant
	local function orbit(radius, thick, color, mat, rx, rz, speed, planet)
		local parts = k.ring(cx, cy, cz, radius, thick, color, mat, "y", {n = 22, depth = thick, rx = rx, rz = rz, name = "Gimbal"})
		local tilt = CFrame.Angles(math.rad(rx), 0, math.rad(rz))
		local at = (tilt * CFrame.new(radius, 0, 0)).Position
		local px, py, pz = cx + at.X, cy + at.Y, cz + at.Z
		table.insert(parts, k.ball(px, py, pz, planet.d, planet.c, planet.mat or M.SmoothPlastic, {name = "Planet"}))
		if planet.band then
			table.insert(parts, k.ell(px, py, pz, planet.d * 1.02, planet.d * 0.3, planet.d * 1.02, planet.band, M.SmoothPlastic, {name = "PlanetBand"}))
		end
		if planet.rings then
			for _, q in ipairs(k.ring(px, py, pz, planet.d * 0.82, 0.08, planet.rings, M.Neon, "y", {n = 12, depth = 0.04, rx = 20, rz = -14, name = "PlanetRing"})) do
				table.insert(parts, q)
			end
		end
		local up = (tilt * CFrame.new(0, 1, 0)).Position
		k.anim("spin", parts, cx, cy, cz, {Axis = up, Speed = speed, Run = 2.4})
	end
	orbit(2.42, 0.11, gold, M.Metal, 18, 8, 0.45, {d = 0.72, c = rgb(230, 170, 110), band = rgb(190, 110, 70), rings = rgb(255, 225, 170)})
	orbit(2.02, 0.09, chrome, M.Metal, -32, -24, -0.7, {d = 0.5, c = rgb(70, 170, 255), band = rgb(90, 220, 140)})
	orbit(1.62, 0.08, cyan, M.Neon, 60, 36, 1.0, {d = 0.36, c = rose, mat = M.Neon})
	-- the mount: crown points where the horns meet the gimbal
	k.m(function(s)
		k.ball(s * 2.72, 8.3, -7.0, 0.62, gold, M.Metal, {name = "HornTip"})
		k.glow(s * 2.72, 8.3, -7.34, 0.26, 0.26, 0.03, rose, {rz = 45, name = "HornJewel"})
	end)
	-- THE COMET: laps the whole machine low down, with a trail
	local comet = k.ball(-4.2, 2.0, -9, 0.42, WHITE, M.Neon, {name = "Comet"})
	k.emit(comet, {tex = "glow", c1 = cyan, c2 = violet, size = {0.5, 0}, alpha = {0.1, 1}, life = {0.5, 0.8}, speed = {0, 0.2}, rate = 45, spread = {180, 180}, light = 1})
	k.anim("travel", comet, 0, 0, 0, {Speed = 7, Idle = 0.6, Run = 1.6, path = {V(-4.5, 0.8, -9.1), V(4.5, 0.8, -9.1), V(4.6, 2.1, 0), V(4.5, 0.8, 7.2), V(-4.5, 0.8, 7.2), V(-4.6, 2.1, 0), V(-4.5, 0.8, -9.1)}})

	-- THE DAIS, the console: black glass, gold bands, a floating crown with a jewel
	k.cyl(0, 0.2, -5.9, 0.4, 2.4, chrome, M.Metal, "y", {refl = 0.25, name = "DaisFoot"})
	local footGlow = k.cyl(0, 0.44, -5.9, 0.08, 2.5, violet, M.Neon, "y", {name = "DaisGlow"})
	k.anim("pulse", footGlow, 0, 0, 0, {Speed = 2, ColorA = violet, ColorB = cyan, Run = 2.4})
	local dais = k.box(0, 1.55, -5.9, 1.9, 2.1, 1.2, void, M.Glass, {name = "Dais"})
	k.text(dais, "Front", "\u{2605} MAX \u{2605}", gold)
	k.text(dais, "Back", "\u{2605} MAX \u{2605}", gold)
	k.light(dais, violet, 10, 1)
	for _, y in ipairs({0.75, 2.6}) do
		k.box(0, y, -5.9, 2.0, 0.14, 1.3, gold, M.Metal, {name = "DaisBand"})
	end
	local crown = k.ring(0, 3.35, -5.9, 0.62, 0.13, gold, M.Metal, "y", {n = 10, depth = 0.45, name = "Crown"})
	for i = 0, 7 do
		local a = math.rad(i * 45)
		table.insert(crown, k.box(math.sin(a) * 0.62, 3.75, -5.9 + math.cos(a) * 0.62, 0.15, 0.42, 0.15, gold, M.Metal, {ry = i * 45, name = "CrownPoint"}))
		table.insert(crown, k.ball(math.sin(a) * 0.62, 4.02, -5.9 + math.cos(a) * 0.62, 0.15, i % 2 == 0 and rose or cyan, M.Neon, {name = "CrownGem"}))
	end
	local jewel = k.ball(0, 3.4, -5.9, 0.46, rose, M.Neon, {name = "Jewel"})
	table.insert(crown, jewel)
	k.anim("spin", crown, 0, 3.4, -5.9, {Axis = Vector3.yAxis, Speed = 0.6, Run = 2.4})
	k.emit(jewel, {tex = "sparkle", c1 = gold, c2 = violet, size = {0.36, 0}, life = {0.6, 1.2}, speed = {1, 2.4}, rate = 5, run = 14, spread = {25, 25}})

	-- THE REAR WING, swept and low, with a running light
	k.box(0, 1.62, 6.6, 4.8, 0.14, 1.0, chrome, M.Metal, {refl = 0.25, rx = -6, name = "RearWing"})
	k.glow(0, 1.62, 7.1, 4.8, 0.06, 0.06, violet, {name = "WingLight"})
	local sigil = k.ring(0, 0.2, 6.3, 1.1, 0.07, gold, M.Neon, "y", {n = 14, depth = 0.04, name = "Sigil"})
	for i = 0, 3 do
		table.insert(sigil, k.glow(0, 0.2, 6.3, 0.05, 0.04, 2.1, cyan, {ry = i * 45, name = "SigilLine"}))
	end
	k.anim("spin", sigil, 0, 0.2, 6.3, {Axis = Vector3.yAxis, Speed = -0.6, Run = 2.6})
	-- the nebula, breathing round everything
	k.emit(k.spot(0, 3.5, -1, 8.8, 5, 15), {tex = "smoke", c1 = violet, c2 = rose, size = {3, 5.5}, alpha = {0.94, 1}, life = {3, 5}, speed = {0.1, 0.4}, rate = 1, run = 2, spread = {180, 180}, light = 0.3})
	k.emit(k.spot(0, 5, -1, 8.8, 8, 15), {tex = "sparkle", c1 = star, c2 = cyan, size = {0.32, 0}, life = {0.8, 1.8}, speed = {0.2, 0.6}, rate = 8, run = 18, spread = {180, 180}, light = 0.7})
end}

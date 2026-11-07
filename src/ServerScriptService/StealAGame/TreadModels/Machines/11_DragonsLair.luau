-- A great dragon curled round the runner, guarding its gold. The neck rises from the right and arches over the head; the head
-- looks down and out at the path, jaw working, eyes burning, smoke at the nostrils and real fire on the throttle. Bat wings
-- rise at both sides and beat slowly. Back spines along the rails, the tail lashing behind, a heap of treasure and a glowing egg.
return {Name = "Dragon's Lair", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9113224519", 0.25, 0.7)
	local scale, scaleDark, belly, horn, gold, wing, wingDark, rock, eye = rgb(170, 28, 30), rgb(106, 16, 20), rgb(240, 170, 90), rgb(238, 226, 200), rgb(255, 200, 60), rgb(150, 28, 34), rgb(70, 14, 20), rgb(52, 44, 46), rgb(255, 225, 60)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, rock, M.Slate, {name = "CaveFloor"})
	k.deck(5, rgb(44, 30, 30), M.Slate)
	k.belt({rgb(66, 14, 14), rgb(94, 26, 18)}, M.Slate, 4.2)
	k.m(function(s)
		-- the dragon's flanks run down both sides of the lane, with a row of spines
		k.ell(s * 3.5, 1.1, 0.2, 2.2, 2.0, 10.6, scale, M.Slate, {name = "Flank"})
		k.ell(s * 2.85, 0.75, 0.2, 0.9, 0.95, 10.0, belly, M.SmoothPlastic, {name = "FlankBelly"})
		for i, z in ipairs({-4.2, -3.1, -2.0, -0.9, 0.2, 1.3, 2.4, 3.5}) do
			local h = 1.0 + math.sin(i / 8 * math.pi) * 0.4
			k.wedge(s * 3.62, 2.0 + h / 2 - 0.1, z, 0.14, h, 1.0, horn:Lerp(scale, 0.25), M.SmoothPlastic, {name = "Spine"})
		end
		-- scale plates down the flank
		for i = 0, 6 do
			k.ell(s * 4.5, 1.1, -3.9 + i * 1.3, 0.14, 0.9, 1.3, scaleDark, M.Slate, {name = "ScalePlate"})
		end
		-- a clawed foot at the front of each flank
		k.ell(s * 3.7, 0.5, -5.0, 1.5, 0.9, 1.6, scale, M.Slate, {name = "Foot"})
		for _, dx in ipairs({-0.42, 0, 0.42}) do
			k.wedge(s * 3.7 + dx, 0.34, -6.0, 0.24, 0.5, 0.6, horn, M.SmoothPlastic, {name = "Claw"})
		end

		-- A BAT WING: arm, fingers and real membranes between them, beating slowly from the shoulder
		local wx, wy, wz = s * 3.9, 3.0, -6.7
		local parts = {}
		local elbow = V(s * 4.42, 7.2, -7.5)
		local tips = {V(s * 4.6, 12.0, -8.95), V(s * 4.7, 11.9, -6.6), V(s * 4.7, 9.9, -4.8), V(s * 4.6, 6.6, -4.8)}
		local root = V(s * 4.4, 3.5, -5.2)
		table.insert(parts, k.seg(V(wx, wy, wz), elbow, 0.42, scale, M.Slate, {name = "WingArm"}))
		table.insert(parts, k.ball(elbow.X, elbow.Y, elbow.Z, 0.56, scale, M.Slate, {name = "WingElbow"}))
		for i, tip in ipairs(tips) do
			table.insert(parts, k.seg(elbow, tip, 0.19 - i * 0.015, scale, M.Slate, {name = "WingFinger"}))
			-- the membrane between this finger and the next, scalloped by a mid-point pulled toward the elbow
			local nextTip = tips[i + 1] or root
			local dip = elbow:Lerp((tip + nextTip) / 2, 0.72)
			local c = i % 2 == 0 and wing or wingDark
			table.insert(parts, k.tri(elbow, tip, dip, c, M.Fabric, {thick = 0.05, name = "Membrane"}))
			table.insert(parts, k.tri(elbow, dip, nextTip, c:Lerp(BLACK, 0.12), M.Fabric, {thick = 0.05, name = "Membrane"}))
		end
		-- the hooked claw at the top of the wing
		table.insert(parts, k.seg(tips[1], tips[1] + V(0, 0.32, -0.28), 0.12, horn, M.SmoothPlastic, {name = "WingClaw"}))
		k.anim("swing", parts, wx, wy, wz, {Axis = Vector3.zAxis, Amp = s * 3.5, Speed = 0.9, Run = 2.4})
	end)

	-- THE NECK: rising at the right, arching over; each ring smaller, with a pale throat
	local path = {
		V(3.35, 1.3, -7.6), V(3.45, 2.7, -7.75), V(3.55, 4.1, -7.85), V(3.55, 5.5, -7.9), V(3.5, 6.85, -7.9),
		V(3.15, 8.05, -7.85), V(2.45, 9.15, -7.75), V(1.8, 9.95, -7.7), V(1.05, 10.3, -7.6),
	}
	local neckD = {2.3, 2.1, 1.95, 1.8, 1.68, 1.56, 1.45, 1.35, 1.28}
	for i, p in ipairs(path) do
		k.ball(p.X, p.Y, p.Z, neckD[i], i % 2 == 0 and scale or scale:Lerp(scaleDark, 0.25), M.Slate, {name = "Neck"})
		if i < #path then
			local n = path[i + 1]
			k.seg(p, n, neckD[i] * 0.85, scale, M.Slate, {name = "NeckLink"})
		end
		-- throat plates facing the path
		k.ell(p.X - 0.1, p.Y, p.Z - neckD[i] * 0.42, neckD[i] * 0.62, neckD[i] * 0.72, 0.3, belly, M.SmoothPlastic, {name = "Throat"})
		-- spines along the back of the neck
		k.wedge(p.X + neckD[i] * 0.42, p.Y + 0.15, p.Z + neckD[i] * 0.3, 0.14, 0.7, 0.55, horn:Lerp(scale, 0.25), M.SmoothPlastic, {name = "NeckSpine"})
	end
	k.ball(3.3, 0.9, -7.6, 2.9, scale, M.Slate, {name = "Chest"})

	-- THE HEAD: looks down at the path over the runner. The cranium breathes, the jaw works, the eyes burn.
	local hy, hz = 10.1, -7.75
	local head = {
		k.ell(0.25, hy + 0.05, hz, 2.0, 1.45, 1.75, scale, M.Slate, {name = "Skull"}),
		k.box(-0.95, hy + 0.1, hz - 0.05, 1.5, 0.75, 1.2, scale, M.Slate, {name = "Muzzle"}),
		k.wedge(-1.05, hy + 0.56, hz - 0.05, 1.25, 0.3, 1.1, scaleDark, M.Slate, {ry = 90, name = "MuzzleRidge"}),
		k.ell(-1.8, hy + 0.08, hz - 0.05, 0.75, 0.72, 1.15, scale, M.Slate, {name = "Snout"}),
	}
	k.m(function(z)
		local zo = hz - 0.05 + z * 0.8
		-- horn sweeping back, in three pieces
		table.insert(head, k.seg(V(0.7, hy + 0.55, zo * 1), V(1.45, hy + 1.2, zo), 0.3, horn, M.SmoothPlastic, {name = "Horn"}))
		table.insert(head, k.seg(V(1.45, hy + 1.2, zo), V(2.2, hy + 1.45, zo), 0.2, horn, M.SmoothPlastic, {name = "Horn"}))
		table.insert(head, k.seg(V(2.2, hy + 1.45, zo), V(2.8, hy + 1.4, zo), 0.1, horn, M.SmoothPlastic, {name = "Horn"}))
		-- brow and cheek
		table.insert(head, k.box(-0.15, hy + 0.5, hz + z * 0.74, 0.95, 0.2, 0.3, scaleDark, M.Slate, {rz = 14, name = "Brow"}))
		table.insert(head, k.wedge(0.8, hy - 0.2, hz + z * 0.82, 0.14, 0.6, 0.65, horn:Lerp(scale, 0.3), M.SmoothPlastic, {ry = 90, name = "CheekFrill"}))
		-- the nostrils
		table.insert(head, k.ball(-2.1, hy + 0.28, hz - 0.05 + z * 0.3, 0.17, BLACK, M.SmoothPlastic, {name = "Nostril"}))
	end)
	-- upper teeth
	for i = 0, 4 do
		table.insert(head, k.wedge(-1.95 + i * 0.36, hy - 0.42, hz - 0.5, 0.14, 0.3, 0.14, horn, M.SmoothPlastic, {rx = 180, name = "UpperTooth"}))
		table.insert(head, k.wedge(-1.95 + i * 0.36, hy - 0.42, hz + 0.4, 0.14, 0.3, 0.14, horn, M.SmoothPlastic, {rx = 180, name = "UpperTooth"}))
	end
	k.anim("slide", head, 0, hy, hz, {Offset = V(0, 0.12, 0), Speed = 0.8, Run = 2})
	local eyes = {}
	k.m(function(z)
		table.insert(eyes, k.ell(-0.42, hy + 0.3, hz + z * 0.82, 0.48, 0.28, 0.1, eye, M.Neon, {name = "Eye"}))
		k.box(-0.42, hy + 0.3, hz + z * 0.88, 0.07, 0.24, 0.02, BLACK, M.SmoothPlastic, {name = "Pupil"})
	end)
	k.anim("pulse", eyes, 0, 0, 0, {Speed = 1.4, ColorA = rgb(220, 120, 20), ColorB = eye, Run = 2.6})
	k.light(eyes[1], rgb(255, 170, 60), 12, 1)
	-- the jaw: hinged at the back, drops and closes
	local jaw = {
		k.box(-0.9, hy - 0.72, hz - 0.05, 2.2, 0.32, 1.05, belly, M.SmoothPlastic, {name = "Jaw"}),
		k.box(-0.9, hy - 0.86, hz - 0.05, 2.3, 0.1, 1.15, scale, M.Slate, {name = "JawSkin"}),
		k.box(-1.3, hy - 0.54, hz - 0.05, 1.4, 0.05, 0.7, rgb(170, 40, 60), M.SmoothPlastic, {name = "Tongue"}),
	}
	for i = 0, 3 do
		table.insert(jaw, k.wedge(-1.75 + i * 0.4, hy - 0.45, hz - 0.45, 0.12, 0.26, 0.12, horn, M.SmoothPlastic, {name = "LowerTooth"}))
		table.insert(jaw, k.wedge(-1.75 + i * 0.4, hy - 0.45, hz + 0.35, 0.12, 0.26, 0.12, horn, M.SmoothPlastic, {name = "LowerTooth"}))
	end
	k.anim("swing", jaw, 0.3, hy - 0.6, hz, {Axis = Vector3.zAxis, Amp = 7, Speed = 0.8, Run = 2.6})
	-- a glow in the throat, and fire out of the mouth (out over the path, in front of the machine)
	local throat = k.ball(-1.15, hy - 0.3, hz - 0.05, 0.5, rgb(255, 160, 40), M.Neon, {name = "ThroatFire"})
	k.anim("flicker", throat, 0, 0, 0, {Speed = 5, ColorA = rgb(170, 50, 10), ColorB = rgb(255, 215, 90), Run = 2})
	k.emit(k.spot(-2.15, hy - 0.3, hz - 0.3, 0.4, 0.3, 0.4), {tex = "fire", c1 = rgb(255, 235, 150), c2 = rgb(255, 70, 15), size = {0.55, 2.1}, alpha = {0.05, 1}, life = {0.28, 0.5}, speed = {11, 16}, rate = 1, run = 55, dir = "Front", spread = {9, 9}, light = 1})
	k.emit(k.spot(-2.15, hy + 0.3, hz - 0.05, 0.3, 0.1, 0.6), {tex = "smoke", c1 = rgb(90, 86, 86), size = {0.3, 1.3}, alpha = {0.5, 1}, life = {0.8, 1.4}, speed = {1, 2}, rate = 3, run = 6, spread = {14, 14}, light = 0, lit = 1})

	-- THE HOARD, front left: a low spill of coins with a chest, goblets and jewels on it, sparkling
	local gx, gz = -2.95, -7.2
	local dimGold, brightGold = rgb(214, 158, 44), rgb(255, 216, 96)
	k.ell(gx, 0.3, gz, 3.6, 1.0, 4.1, dimGold, M.Foil, {name = "HoardBase"})
	for i = 1, 38 do
		local a, r = i * 2.39996, math.sqrt(i / 38) * 1.65
		local dy = 0.72 - (r / 1.65) ^ 2 * 0.5
		k.cyl(gx + math.cos(a) * r * 0.95, dy, gz + math.sin(a) * r * 1.15, 0.05, 0.38, i % 3 == 0 and dimGold or brightGold, M.Foil, "y", {rx = (i * 37) % 50 - 25, rz = (i * 53) % 50 - 25, name = "Coin"})
	end
	-- an open chest sitting in the gold
	k.box(-3.2, 0.95, -7.7, 1.3, 0.7, 0.9, rgb(92, 56, 32), M.WoodPlanks, {ry = 20, name = "HoardChest"})
	k.box(-3.2, 1.36, -7.7, 1.15, 0.12, 0.76, brightGold, M.Neon, {ry = 20, name = "ChestGold"})
	k.cyl(-3.32, 1.6, -8.05, 1.32, 0.62, rgb(92, 56, 32), M.WoodPlanks, "x", {ry = 20, name = "ChestLid"})
	-- a goblet and a crown on top
	k.lathe(-2.15, 0.55, -6.3, {{0, 0.42}, {0.08, 0.1}, {0.5, 0.1}, {0.68, 0.42}, {0.95, 0.5}}, brightGold, M.Foil, {name = "Goblet"})
	k.ring(-2.35, 0.86, -7.75, 0.3, 0.09, brightGold, M.Foil, "y", {n = 8, depth = 0.24, name = "Crown"})
	for i = 0, 4 do
		local a = math.rad(i * 72)
		k.box(-2.35 + math.sin(a) * 0.3, 1.1, -7.75 + math.cos(a) * 0.3, 0.07, 0.2, 0.07, brightGold, M.Foil, {name = "CrownPoint"})
	end
	local jewels = {}
	for i, g in ipairs({{-3.75, 0.72, -6.7, rgb(70, 255, 150)}, {-2.05, 0.65, -7.05, rgb(70, 170, 255)}, {-2.85, 0.92, -6.45, rgb(255, 60, 110)}, {-3.9, 0.55, -8.0, rgb(200, 90, 255)}}) do
		table.insert(jewels, k.box(g[1], g[2], g[3], 0.3, 0.3, 0.3, g[4], M.Neon, {rx = 45, rz = 45, name = "Jewel" .. i}))
	end
	k.emit(k.spot(gx, 1.1, gz, 2.8, 0.8, 3.2), {tex = "sparkle", c1 = rgb(255, 240, 170), size = {0.5, 0}, life = {0.5, 1.2}, speed = {0.3, 0.9}, spread = {180, 180}, rate = 8, run = 16})
	-- THE EGG, the console: on a nest of stone, facing the runner, pulsing with a heartbeat
	k.cyl(0, 0.8, -5.95, 1.6, 2.1, rock, M.Slate, "y", {name = "Nest"})
	k.cyl(0, 1.65, -5.95, 0.12, 2.25, gold, M.Foil, "y", {name = "NestBand"})
	for i = 0, 7 do
		local a = math.rad(i * 45 + 20)
		k.box(math.sin(a) * 1.0, 1.85, -5.95 + math.cos(a) * 1.0, 0.45, 0.5, 0.45, rock, M.Slate, {rx = i * 30, ry = i * 40, name = "NestStone"})
	end
	local egg = k.ell(0, 2.95, -5.95, 1.65, 2.3, 1.65, rgb(255, 130, 40), M.Neon, {name = "Egg"})
	k.anim("pulse", egg, 0, 0, 0, {Speed = 2.4, Sharp = 3, ColorA = rgb(160, 50, 10), ColorB = rgb(255, 200, 80), Run = 2.4})
	k.light(egg, rgb(255, 140, 60), 12, 1)
	for i = 0, 5 do
		local a = i * 1.05
		k.ell(math.sin(a) * 0.76, 2.55 + (i % 3) * 0.45, -5.95 + math.cos(a) * 0.76, 0.44, 0.58, 0.44, rgb(120, 24, 16), M.Slate, {name = "EggScale"})
	end
	-- THE TAIL, round the back and lashing
	local tail = {}
	local tailPts = {V(3.6, 0.85, 5.2), V(2.9, 0.75, 6.2), V(1.7, 0.65, 6.7), V(0.4, 0.58, 6.9), V(-0.9, 0.5, 6.9), V(-2.1, 0.44, 6.7)}
	for i = 1, #tailPts - 1 do
		k.seg(tailPts[i], tailPts[i + 1], 1.25 - i * 0.16, scale, M.Slate, {name = "Tail"})
		k.wedge(tailPts[i].X, tailPts[i].Y + 0.7 - i * 0.06, tailPts[i].Z, 0.1, 0.6 - i * 0.05, 0.55, horn:Lerp(scale, 0.25), M.SmoothPlastic, {ry = 90, name = "TailSpine"})
	end
	table.insert(tail, k.seg(V(-2.1, 0.44, 6.7), V(-3.2, 0.42, 6.3), 0.42, scale, M.Slate, {name = "TailEnd"}))
	table.insert(tail, k.wedge(-3.75, 0.45, 6.1, 0.1, 0.8, 1.0, horn, M.SmoothPlastic, {ry = 110, name = "TailBlade"}))
	k.anim("swing", tail, -2.1, 0.44, 6.7, {Axis = Vector3.yAxis, Amp = 15, Speed = 1.2, Run = 2.2})
	-- smoke drifting across the cave floor
	k.emit(k.spot(0, 0.3, -9, 7, 0.1, 0.3), {tex = "smoke", c1 = rgb(80, 66, 66), size = {1.2, 3}, alpha = {0.7, 1}, life = {1.5, 2.6}, speed = {0.7, 1.4}, rate = 3, dir = "Front", spread = {25, 8}, light = 0, lit = 1})
end}

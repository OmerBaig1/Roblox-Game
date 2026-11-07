-- A forge built on a live volcano. Lava erupts from the crater on the right, runs down its flanks and rains molten bombs. On the
-- left a great trip hammer pounds an ingot on an anvil in showers of sparks, bellows pumping beside it. A crucible overhead
-- pours into channels that carry lava round both sides of the runner to the moulds behind. A furnace burns at the console.
return {Name = "Volcano Forge", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9112780743", 0.3, 0.6)
	local basalt, rock, ash, lava, hot, iron, ember, gold = rgb(38, 32, 32), rgb(58, 48, 44), rgb(86, 76, 70), rgb(235, 70, 10), rgb(255, 130, 25), rgb(52, 52, 58), rgb(150, 34, 6), rgb(255, 196, 70)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, basalt, M.Basalt, {name = "Ground"})
	-- lava cracks in the ground, breathing together
	local cracks = {}
	for i, c in ipairs({{-4.0, -3.6, 1.8, 30}, {-3.3, 3.3, 2.4, -35}, {3.7, 2.8, 2.2, 22}, {3.2, -3.4, 1.8, -28}, {-1.6, 6.9, 2.0, 70}, {1.8, -8.9, 2.4, 80}, {-1.5, -8.8, 1.6, 100}}) do
		table.insert(cracks, k.box(c[1], 0.09, c[2], 0.16, 0.04, c[3], lava, M.Neon, {ry = c[4], name = "Crack" .. i}))
	end
	k.anim("pulse", cracks, 0, 0, 0, {Speed = 1.6, Stagger = 0.9, ColorA = ember, ColorB = hot, Run = 2})
	k.deck(5, rock, M.Basalt)
	k.belt({rgb(30, 26, 26), rgb(170, 58, 12)}, M.Basalt, 4.2)
	k.m(function(s)
		-- iron-edged lava channel beside the runner, flowing back
		k.box(s * 3.35, 0.42, 0, 1.9, 0.7, 10.4, iron, M.Metal, {name = "Channel"})
		k.box(s * 3.35, 0.78, 0, 1.3, 0.06, 10.2, lava, M.Neon, {name = "ChannelLava"})
		k.box(s * 2.48, 0.86, 0, 0.14, 0.16, 10.4, rock, M.Metal)
		k.box(s * 4.22, 0.86, 0, 0.14, 0.16, 10.4, rock, M.Metal)
		local flow = {}
		for i = 1, 8 do
			table.insert(flow, k.ell(s * 3.35, 0.82, 0, 0.8 - (i % 3) * 0.2, 0.12, 1.0, hot, M.Neon, {name = "Flow" .. i}))
		end
		k.anim("travel", flow, s * 3.35, 0.82, 0, {Speed = 1.6, Run = 2.4, Wobble = 0.1, path = {V(0, 0, -5), V(0, 0, 5)}})
		for _, z in ipairs({-3, 0, 3}) do
			k.box(s * 3.35, 1.0, z, 1.95, 0.14, 0.3, iron, M.Metal, {name = "ChannelBrace"})
		end
	end)

	-- THE VOLCANO, right front: a faceted cone of rock, leaning outward so the runner's sightline stays clear
	local vx, vz = 3.55, -7.1
	local rings = {
		{y = 0.05, cx = 2.98, rx = 1.65, rz = 2.1},
		{y = 2.2, cx = 3.05, rx = 1.5, rz = 2.0},
		{y = 4.5, cx = 3.62, rx = 1.0, rz = 1.75},
		{y = 7.3, cx = 3.62, rx = 0.95, rz = 1.4},
		{y = 9.9, cx = 3.6, rx = 0.92, rz = 1.0},
	}
	local SIDES = 8
	local function corner(ring, i, jag)
		local a = (i + (ring.y > 3 and 0.5 or 0)) / SIDES * math.pi * 2
		local j = 1 + ((i * 7 + math.floor(ring.y * 3)) % 3 - 1) * (jag or 0.05)
		return V(ring.cx + math.cos(a) * ring.rx * j, ring.y, vz + math.sin(a) * ring.rz * j)
	end
	for r = 1, #rings - 1 do
		local lo, hi = rings[r], rings[r + 1]
		for i = 0, SIDES - 1 do
			local a0, a1 = corner(lo, i), corner(lo, i + 1)
			local b0, b1 = corner(hi, i), corner(hi, i + 1)
			local c1 = rock:Lerp(ash, (r - 1) / 4 + (i % 2) * 0.12)
			k.tri(a0, a1, b0, c1, M.Basalt, {thick = 0.1, name = "VolcanoFacet"})
			k.tri(a1, b1, b0, c1:Lerp(BLACK, 0.16), M.Basalt, {thick = 0.1, name = "VolcanoFacet"})
		end
	end
	-- a core so no sky shows through the facets
	k.lathe(3.1, 0.05, vz, {{0, 3}, {2.2, 2.7}}, rock, M.Basalt, {name = "VolcanoCore"})
	k.lathe(vx, 2.2, vz, {{0, 1.8}, {2.3, 1.75}, {5.1, 1.6}, {7.6, 1.5}}, basalt, M.Basalt, {name = "VolcanoCore"})
	-- the crater: lava that swells, with a rim
	k.ring(vx, 10.05, vz, 0.98, 0.3, ash, M.Basalt, "y", {n = 10, depth = 0.34, name = "CraterRim"})
	local pool = k.cyl(vx, 9.95, vz, 0.2, 1.75, lava, M.Neon, "y", {name = "CraterLava"})
	k.anim("pulse", pool, 0, 0, 0, {Speed = 2.6, ColorA = lava, ColorB = rgb(255, 150, 40), Run = 2})
	k.light(pool, rgb(255, 120, 40), 14, 1)
	local dome = k.ell(vx, 10.1, vz, 1.55, 0.5, 1.55, hot, M.Neon, {name = "LavaDome"})
	k.anim("slide", dome, vx, 10.1, vz, {Offset = V(0, 0.14, 0), Speed = 3.4, Run = 2})
	-- rivers of lava down the ridges, lighting from the top down
	local rivers = {}
	for n, i in ipairs({1, 3, 4, 6}) do
		for r = #rings, 2, -1 do
			local a, b = corner(rings[r], i, 0), corner(rings[r - 1], i, 0)
			local c = (rings[r].cx + rings[r - 1].cx) / 2
			local push = V(0, 0, 0)
			table.insert(rivers, k.seg(a + push, b + push, 0.15, lava, M.Neon, {box = true, name = string.format("River%d%d", n, 9 - r)}))
		end
	end
	k.anim("pulse", rivers, 0, 0, 0, {Speed = 3, Stagger = 0.65, ColorA = ember, ColorB = hot, Run = 2})
	-- lava bombs thrown from the crater, falling back to the ground
	local bombs = {}
	for i = 1, 3 do
		table.insert(bombs, k.ball(vx, 10.4, vz, 0.32 + i * 0.05, hot, M.Neon, {name = "Bomb" .. i}))
	end
	k.anim("travel", bombs, vx, 0, vz, {Speed = 3.4, Idle = 0.55, Run = 1.5, path = {V(0, 10.4, 0), V(0.3, 11.8, -0.6), V(0.7, 12.1, -1.2), V(1.0, 10.2, -1.7), V(1.15, 6.8, -2.1), V(1.2, 0.3, -2.25)}})
	-- embers fountain and a smoke plume
	k.emit(k.spot(vx, 10.6, vz, 1.3, 0.1, 1.3), {tex = "sparks", c1 = hot, c2 = lava, size = {0.45, 0.08}, life = {0.8, 1.6}, speed = {7, 13}, rate = 12, run = 38, spread = {26, 26}, accel = V(0, -14, 0), light = 1})
	k.emit(k.spot(vx, 10.8, vz, 1.1, 0.1, 1.1), {tex = "smoke", c1 = rgb(90, 80, 76), c2 = rgb(40, 36, 36), size = {1.4, 4.2}, alpha = {0.4, 1}, life = {1.5, 2.6}, speed = {3.5, 5.5}, rate = 2.5, run = 8, spread = {14, 14}, light = 0, lit = 1, accel = V(0, 0.5, 1)})

	-- THE TRIP HAMMER, left front: posts, an arm on a pivot, the head falling on the anvil
	local hx, pivotY, pivotZ = -3.6, 5.4, -8.7
	k.m(function(s)
		k.box(hx + s * 0.75, 2.8, pivotZ, 0.42, 5.6, 0.5, iron, M.Metal, {name = "HammerPost"})
		k.box(hx + s * 0.75, 0.2, pivotZ, 0.7, 0.4, 1.0, rock, M.Basalt)
	end)
	k.cyl(hx, pivotY, pivotZ, 1.9, 0.34, gold, M.Metal, "x", {name = "HammerPivot"})
	local hammer = {
		k.box(hx, pivotY - 0.05, -6.8, 0.42, 0.42, 3.9, rgb(110, 70, 42), M.WoodPlanks, {name = "HammerArm"}),
		k.box(hx, pivotY - 0.4, -5.2, 1.15, 1.5, 1.15, iron, M.Metal, {name = "HammerHead"}),
		k.box(hx, pivotY - 0.15 + 0.3, -5.2, 1.3, 0.14, 1.3, gold, M.Metal, {name = "HammerBand"}),
		k.box(hx, pivotY - 1.18, -5.2, 0.95, 0.12, 0.95, rgb(130, 130, 136), M.Metal, {name = "HammerFace"}),
	}
	k.anim("swing", hammer, hx, pivotY, pivotZ, {Axis = Vector3.xAxis, Amp = 15, Speed = 2.2, Idle = 0.6, Run = 2.2})
	-- the anvil and its white-hot ingot
	k.box(hx, 0.5, -5.2, 1.4, 1.0, 1.4, rock, M.Basalt, {name = "AnvilBlock"})
	k.box(hx, 1.2, -5.2, 0.8, 0.4, 0.8, iron, M.Metal, {name = "AnvilWaist"})
	k.box(hx, 1.62, -5.2, 1.35, 0.44, 1.2, iron, M.Metal, {name = "Anvil"})
	k.wedge(hx + 0.9, 1.62, -5.2, 0.8, 0.44, 0.45, iron, M.Metal, {ry = -90, name = "AnvilHorn"})
	local ingot = k.box(hx, 1.92, -5.2, 0.9, 0.16, 0.44, hot, M.Neon, {name = "Ingot"})
	k.anim("pulse", ingot, 0, 0, 0, {Speed = 4.4, Sharp = 3, ColorA = lava, ColorB = rgb(255, 245, 190), Idle = 0.6, Run = 2.2})
	k.light(ingot, rgb(255, 150, 50), 11, 1.1)
	k.emit(k.spot(hx, 2.05, -5.2, 0.7, 0.1, 0.5), {tex = "sparks", c1 = rgb(255, 240, 170), c2 = lava, size = {0.32, 0.05}, life = {0.25, 0.6}, speed = {5, 11}, rate = 5, run = 34, spread = {60, 60}, accel = V(0, -24, 0), light = 1})
	-- bellows pumping into the forge
	local bellows = k.box(-2.8, 1.2, -7.4, 1.0, 0.8, 1.5, rgb(106, 66, 40), M.Fabric, {name = "Bellows"})
	k.anim("gauge", bellows, 0, 0, 0, {GAxis = "Y", Speed = 2.2, Amp = 0.32, Idle = 0.6, Run = 2.2})
	k.box(-2.8, 0.45, -7.4, 1.05, 0.7, 1.55, iron, M.Metal, {name = "BellowsBase"})

	-- THE CRUCIBLE overhead: a beam out from the volcano, a tilting pot, a stream of lava falling beside the lane
	k.box(-1.0, 8.7, -7.5, 5.5, 0.42, 0.42, iron, M.Metal, {name = "CrucibleBeam"})
	k.m(function(s)
		k.seg(V(-2.75 + s * 0.3, 8.5, -7.5), V(-2.75, 7.8, -7.5), 0.06, BLACK, M.Metal, {name = "CrucibleChain"})
	end)
	local pot = k.lathe(-2.75, 7.25, -7.5, {{0, 0.65}, {0.72, 1.0}}, iron, M.Metal, {name = "Crucible"})
	table.insert(pot, k.cyl(-2.75, 7.98, -7.5, 0.06, 0.82, hot, M.Neon, "y", {name = "CrucibleMelt"}))
	k.anim("swing", pot, -2.75, 7.8, -7.5, {Axis = Vector3.zAxis, Amp = 8, Speed = 0.7, Run = 1.6})
	local stream = k.cyl(-3.0, 3.85, -7.5, 6.8, 0.2, hot, M.Neon, "y", {name = "PourStream", shadow = false})
	k.anim("pulse", stream, 0, 0, 0, {Speed = 9, ColorA = lava, ColorB = rgb(255, 170, 50)})
	k.seg(V(-3.0, 0.25, -7.5), V(-3.3, 0.6, -5.2), 0.3, iron, M.Metal, {box = true, name = "Sluice"})

	-- THE FURNACE console: brick arch and a fire in its mouth facing the runner
	k.box(0, 1.65, -6.05, 3.5, 3.1, 1.7, rgb(92, 60, 48), M.Cobblestone, {name = "Furnace"})
	k.box(0, 3.22, -6.05, 3.7, 0.2, 1.85, iron, M.Metal, {name = "FurnaceCap"})
	k.ring(0, 1.55, -5.18, 0.95, 0.24, ash, M.Brick, "z", {n = 8, a0 = -90, a1 = 90, depth = 0.24, name = "FurnaceArch"})
	k.box(0, 1.05, -5.17, 1.75, 1.15, 0.03, BLACK, M.SmoothPlastic, {name = "FurnaceMouth"})
	local fire = {}
	for i = 0, 4 do
		table.insert(fire, k.ell(-0.7 + i * 0.35, 1.0, -5.13, 0.42, 0.7 + (i % 2) * 0.3, 0.05, i % 2 == 0 and hot or lava, M.Neon, {name = "Flame" .. i}))
	end
	k.anim("gauge", fire, 0, 0, 0, {GAxis = "Y", Speed = 9, Amp = 0.32, Stagger = 1.7, Run = 1.6})
	-- dials and tools over the fire
	k.cyl(0, 2.7, -5.15, 0.06, 0.9, gold, M.Metal, "z", {name = "HeatDial"})
	k.cyl(0, 2.7, -5.12, 0.03, 0.75, rgb(245, 235, 210), M.SmoothPlastic, "z")
	local needle = k.box(0, 2.84, -5.09, 0.04, 0.3, 0.015, rgb(220, 30, 20), M.Neon, {name = "HeatNeedle"})
	k.anim("swing", needle, 0, 2.7, -5.09, {Axis = Vector3.zAxis, Amp = 46, Speed = 0.8, Idle = 0.5, Run = 2.4})
	k.m(function(s)
		k.seg(V(s * 1.3, 2.45, -5.1), V(s * 1.15, 1.3, -5.05), 0.08, iron, M.Metal, {name = "Tongs"})
		k.seg(V(s * 1.15, 2.45, -5.1), V(s * 1.3, 1.3, -5.05), 0.08, iron, M.Metal, {name = "Tongs"})
	end)
	local warm = k.text(k.box(0, 3.6, -5.5, 2.2, 0.56, 0.1, iron, M.Metal, {rx = 10, name = "ForgeSign"}), "Back", "HOT WORK", hot, 46)

	-- BEHIND: the moulds where the lava ends, stacked ingots and a sword cooling in stone
	k.box(0, 0.35, 6.35, 5.2, 0.6, 1.8, iron, M.Metal, {name = "MouldTable"})
	local molten = {}
	for i = 1, 4 do
		table.insert(molten, k.box(-2.4 + i * 0.96, 0.67, 6.35, 0.75, 0.05, 1.3, hot, M.Neon, {name = "Mould" .. i}))
	end
	k.anim("pulse", molten, 0, 0, 0, {Speed = 1.8, Stagger = 0.9, ColorA = ember, ColorB = hot, Run = 2})
	for row = 0, 2 do
		for i = 0, 2 - row do
			k.box(3.7 + (i - (2 - row) / 2) * 0.48, 0.32 + row * 0.26, 6.4, 0.44, 0.24, 1.0, gold, M.Foil, {name = "GoldIngot"})
		end
	end
	k.ball(-3.65, 0.42, 6.4, 1.3, rock, M.Basalt, {name = "SwordStone"})
	k.box(-3.65, 1.5, 6.4, 0.22, 1.6, 0.05, rgb(255, 150, 60), M.Neon, {name = "SwordBlade"})
	k.box(-3.65, 2.25, 6.4, 0.7, 0.1, 0.1, gold, M.Foil, {name = "SwordGuard"})
	-- embers on the air around the whole machine
	k.emit(k.spot(0, 0.5, -1, 8.4, 0.2, 14), {tex = "sparks", c1 = hot, c2 = lava, size = {0.2, 0.03}, life = {1.5, 3}, speed = {1, 2.4}, rate = 5, run = 14, spread = {20, 20}, light = 1, accel = V(0, 0.4, 0)})
end}

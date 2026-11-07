-- The gates of a kingdom above the clouds. White marble colonnade with gold capitals, a sunburst turning behind a great halo,
-- enormous feathered wings that open and close, gold gates that swing, clouds rolling round the deck, doves circling,
-- feathers falling and a golden harp whose strings shimmer. It's the brightest machine in the game, and proud of it.
return {Name = "Cloud Kingdom", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local marble, shade, gold, deepGold, sky, cloud, blush = rgb(248, 248, 252), rgb(210, 216, 232), rgb(255, 208, 84), rgb(214, 158, 44), rgb(150, 215, 255), rgb(244, 248, 255), rgb(255, 228, 210)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, sky, M.SmoothPlastic, {name = "SkyFloor"})
	k.deck(5, marble, M.Marble)
	k.belt({rgb(240, 250, 255), rgb(170, 225, 255)}, M.SmoothPlastic, 4.2)
	-- the clouds that carry it, slowly rolling
	local function puff(list, x, y, z, d, c)
		table.insert(list, k.ball(x, y, z, d, c or cloud, M.SmoothPlastic, {name = "Cloud"}))
	end
	k.m(function(s)
		k.box(s * 2.58, 0.55, 0, 0.42, 0.7, 10.2, marble, M.Marble, {name = "MarbleRail"})
		k.box(s * 2.58, 0.94, 0, 0.5, 0.08, 10.2, gold, M.Foil, {name = "GoldRail"})
		local roll = {}
		for i, c in ipairs({{3.55, 0.75, 3.3, 2.3}, {3.95, 0.5, 2.0, 1.5}, {3.6, 0.55, 0.9, 1.85}, {3.55, 0.9, -0.5, 2.3}, {3.6, 0.5, -2.1, 1.7}, {3.65, 0.7, -3.4, 2.1}, {3.2, 0.42, 4.6, 1.3}}) do
			puff(roll, s * c[1], c[2], c[3], c[4], i % 3 == 0 and shade or cloud)
		end
		k.anim("slide", roll, s * 3.7, 0.7, 0, {Offset = V(s * 0.05, 0.1, 0.3), Speed = 0.55, Phase = s, Run = 1.8})
		-- a column at the side with a gold capital and base
		k.box(s * 3.65, 0.3, -7.1, 1.65, 0.6, 1.65, marble, M.Marble, {name = "ColumnPlinth"})
		k.cyl(s * 3.65, 0.72, -7.1, 0.24, 1.42, gold, M.Foil, "y", {name = "ColumnBase"})
		k.cyl(s * 3.65, 4.0, -7.1, 6.4, 1.05, marble, M.Marble, "y", {name = "Column"})
		for i = 0, 7 do
			local a = math.rad(i * 45)
			k.box(s * 3.65 + math.sin(a) * 0.49, 4.0, -7.1 + math.cos(a) * 0.49, 0.1, 6.3, 0.1, shade, M.Marble, {name = "Flute"})
		end
		k.lathe(s * 3.65, 7.2, -7.1, {{0, 1.1}, {0.25, 1.35}, {0.5, 1.75}}, gold, M.Foil, {name = "Capital"})
		-- THE WING: real feathers in three ranks, opening and closing from the shoulder of the column
		local parts = {}
		local shoulder = V(s * 4.0, 7.9, -7.0)
		for rank, spec in ipairs({{n = 7, len = 4.0, base = 7.95, step = 11, w = 0.62, c = WHITE}, {n = 6, len = 2.8, base = 7.9, step = 12, w = 0.56, c = rgb(236, 240, 252)}, {n = 5, len = 1.7, base = 7.9, step = 14, w = 0.5, c = blush}}) do
			for i = 0, spec.n - 1 do
				local a = math.rad(6 + i * spec.step)
				-- feathers fan from straight up toward the front of the machine (never over the runner)
				local tip = V(s * 4.3, spec.base + math.cos(a) * spec.len, -7.0 - math.sin(a) * spec.len * 0.5)
				local start = V(s * (4.0 + rank * 0.07), spec.base - 0.1, -7.0 - math.sin(a) * 0.3)
				local len = (tip - start).Magnitude
				table.insert(parts, k.seg(start, tip, spec.w, spec.c, M.SmoothPlastic, {box = true, name = "Feather"}))
				parts[#parts].Size = V(len, spec.w, 0.12)
				table.insert(parts, k.ell(tip.X, tip.Y, tip.Z, 0.14, spec.w * 1.05, spec.w * 1.1, spec.c, M.SmoothPlastic, {name = "FeatherTip"}))
			end
		end
		k.anim("swing", parts, shoulder.X, shoulder.Y, shoulder.Z, {Axis = Vector3.xAxis, Amp = -7, Speed = 0.7, Run = 2.2})
	end)
	-- the entablature between the columns, with the great halo above
	k.box(0, 7.9, -7.1, 9.0, 0.5, 1.5, marble, M.Marble, {name = "Entablature"})
	k.box(0, 8.2, -7.1, 9.2, 0.12, 1.65, gold, M.Foil, {name = "Cornice"})
	local frieze = k.box(0, 7.9, -7.87, 6.0, 0.36, 0.04, marble, M.SmoothPlastic, {name = "Frieze"})
	k.text(frieze, "Front", "\u{2726} ABOVE ALL \u{2726}", deepGold, 40)
	local friezeBack = k.box(0, 7.9, -6.33, 6.0, 0.36, 0.04, marble, M.SmoothPlastic, {name = "Frieze"})
	k.text(friezeBack, "Back", "\u{2726} KEEP RISING \u{2726}", deepGold, 40)
	-- THE SUNBURST: rays turning behind the halo
	local cy, cz = 9.95, -7.6
	local rays = {}
	for i = 0, 11 do
		local a = i * 30
		local r = math.rad(a)
		local len = i % 2 == 0 and 1.28 or 0.85
		local dist = 1.18 + len / 2
		table.insert(rays, k.box(math.sin(r) * dist, cy + math.cos(r) * dist, cz, 0.24, len, 0.1, i % 2 == 0 and gold or rgb(255, 238, 170), i % 2 == 0 and M.Neon or M.SmoothPlastic, {rz = -a, name = "Ray"}))
	end
	k.anim("spin", rays, 0, cy, cz, {Axis = Vector3.zAxis, Speed = 0.3, Run = 2})
	local sun = k.ball(0, cy, cz, 1.7, rgb(255, 214, 110), M.Neon, {name = "Sun"})
	k.anim("pulse", sun, 0, 0, 0, {Speed = 1.2, ColorA = rgb(245, 180, 70), ColorB = rgb(255, 226, 130), Run = 2})
	k.light(sun, rgb(255, 230, 170), 12, 0.7)
	k.emit(sun, {tex = "glow", c1 = rgb(255, 215, 120), size = {2.6, 3.8}, alpha = {0.86, 1}, life = {1, 1.6}, speed = {0, 0}, rate = 2, spread = {0, 0}, light = 1})
	-- the great halo, tipped and turning, with a little cloud riding either side
	local halo = k.ring(0, cy, cz + 0.42, 2.05, 0.2, gold, M.Neon, "z", {n = 20, depth = 0.2, name = "Halo"})
	k.anim("spin", halo, 0, cy, cz + 0.42, {Axis = Vector3.zAxis, Speed = -0.35, Run = 2})
	k.m(function(s)
		local ride = {}
		for _, c in ipairs({{2.9, 8.9, 1.1}, {3.5, 9.15, 1.5}, {4.05, 8.9, 1.05}}) do
			puff(ride, s * c[1], c[2], -7.6, c[3])
		end
		k.anim("slide", ride, s * 3.4, 9, -7.6, {Offset = V(0, 0.2, 0), Speed = 0.8, Phase = s + 1, Run = 1.8})
	end)

	-- THE GATES, low in front: gilded leaves that swing open and shut, framed either side of the console
	k.m(function(s)
		local leaf = {}
		for i = 0, 4 do
			table.insert(leaf, k.box(s * (2.45 + i * 0.26), 1.5, -8.9, 0.07, 2.4, 0.07, gold, M.Foil, {name = "GateBar"}))
			local top = k.ball(s * (2.45 + i * 0.26), 2.8, -8.9, 0.14, gold, M.Foil, {name = "GateFinial"})
			table.insert(leaf, top)
		end
		table.insert(leaf, k.box(s * 2.97, 2.4, -8.9, 1.2, 0.08, 0.08, gold, M.Foil, {name = "GateRail"}))
		table.insert(leaf, k.box(s * 2.97, 0.55, -8.9, 1.2, 0.08, 0.08, gold, M.Foil, {name = "GateRail"}))
		k.anim("swing", leaf, s * 3.6, 1.5, -8.9, {Axis = Vector3.yAxis, Amp = s * 24, Speed = 0.6, Run = 1.8})
	end)

	-- THE HARP console, golden, strings shimmering, set in a marble plinth facing the runner
	k.box(0, 0.65, -5.65, 3.3, 1.3, 1.5, marble, M.Marble, {name = "HarpPlinth"})
	k.box(0, 1.36, -5.65, 3.6, 0.12, 1.75, gold, M.Foil, {name = "PlinthTop"})
	local plate = k.box(0, 0.7, -4.88, 2.6, 0.75, 0.03, deepGold, M.SmoothPlastic, {name = "PlinthPlate"})
	k.text(plate, "Back", "\u{266B} HIGHER \u{266B}", WHITE, 50)
	k.seg(V(-1.2, 1.42, -5.65), V(-1.5, 4.25, -5.65), 0.24, gold, M.Foil, {name = "HarpPillar"})
	k.seg(V(-1.2, 1.42, -5.65), V(1.2, 1.5, -5.65), 0.26, gold, M.Foil, {name = "HarpBase"})
	k.ring(-0.1, 2.75, -5.65, 1.65, 0.2, gold, M.Foil, "z", {n = 8, a0 = -22, a1 = -118, depth = 0.2, name = "HarpNeck"})
	k.ball(-1.5, 4.32, -5.65, 0.4, gold, M.Foil, {name = "HarpFinial"})
	local strings = {}
	for i = 0, 7 do
		local x = -1.0 + i * 0.3
		local top = 3.9 - i * 0.22
		table.insert(strings, k.box(x, (1.5 + top) / 2, -5.65, 0.04, top - 1.5, 0.04, rgb(255, 250, 215), M.Neon, {name = "HarpString" .. i}))
	end
	k.anim("pulse", strings, 0, 0, 0, {Speed = 4, Stagger = 0.8, Sharp = 2, ColorA = deepGold, ColorB = WHITE, Run = 2.5})
	k.emit(k.spot(0, 2.8, -5.65, 2.4, 1.8, 0.1), {tex = "sparkle", c1 = rgb(255, 240, 170), size = {0.34, 0}, life = {0.5, 1.1}, speed = {0.3, 0.8}, spread = {180, 180}, rate = 3, run = 14})

	-- DOVES: circling the top of the machine, wings up and down
	local doves = {}
	for i = 1, 4 do
		table.insert(doves, k.ell(0, 9, -7, 0.32, 0.3, 0.7, WHITE, M.SmoothPlastic, {name = "Dove" .. i}))
	end
	k.anim("travel", doves, 0, 0, 0, {Speed = 1.8, Run = 2, Wobble = 0.12, path = {V(-4.2, 9.6, -5.2), V(0, 12.0, -5.0), V(4.2, 9.6, -5.2), V(4.3, 10.4, -8.9), V(0, 12.1, -9.1), V(-4.3, 10.4, -8.9), V(-4.2, 9.6, -5.2)}})
	-- BEHIND: marble steps, a pair of low trumpets on stands, a gold star floor
	k.box(0, 0.16, 5.7, 5.4, 0.2, 1.0, marble, M.Marble, {name = "Step"})
	k.box(0, 0.1, 6.7, 6.2, 0.1, 1.0, shade, M.Marble, {name = "Step"})
	k.m(function(s)
		k.cyl(s * 3.5, 0.6, 6.5, 1.2, 0.28, gold, M.Foil, "y", {name = "TrumpetStand"})
		k.lathe(s * 3.5, 1.2, 6.5, {{0, 0.3}, {0.5, 0.2}, {0.85, 0.5}, {1.1, 1.05}}, gold, M.Foil, {name = "TrumpetBell"})
	end)
	-- feathers floating down, thick when someone's running
	k.emit(k.spot(0, 11.8, -4, 8.8, 0.2, 10), {tex = "sparkle", c1 = WHITE, c2 = rgb(255, 240, 210), size = {0.42, 0.28}, life = {3, 5}, speed = {0.7, 1.4}, rate = 2.5, run = 10, dir = "Bottom", spread = {25, 25}, rot = {0, 360}, spinV = {-70, 70}, light = 0.7})
end}

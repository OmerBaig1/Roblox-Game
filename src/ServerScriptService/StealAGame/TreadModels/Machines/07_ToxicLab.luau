-- A lab mid-experiment. The main vat is really full: glowing liquid with a moving surface, bubbles rising and growing through
-- it and a spinning stirrer. A clear pipe carries blobs overhead into a flask boiling over a blue burner, venting through a
-- glowing coil. A rack of bubbling test tubes, a flickering skull monitor, hazard barrels that leak, a warning beacon.
return {Name = "Toxic Lab", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://1075001850", 0.4, 1)
	local purple, dark, goo, hotGoo, steel, yellow, pinkGoo, ink = rgb(66, 30, 102), rgb(30, 22, 44), rgb(70, 235, 40), rgb(150, 255, 70), rgb(136, 142, 156), rgb(245, 205, 30), rgb(235, 20, 160), rgb(16, 14, 22)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, ink, M.DiamondPlate, {name = "LabFloor"})
	k.deck(5, purple, M.Metal)
	k.belt({rgb(36, 22, 54), rgb(44, 90, 40)}, M.SmoothPlastic, 4.2)
	-- hazard edge round the deck
	k.m(function(s)
		for i = 0, 6 do
			k.box(s * 2.72, 0.42, -4.8 + i * 1.6, 0.5, 0.56, 1.6, i % 2 == 0 and yellow or rgb(20, 20, 24), M.SmoothPlastic, {name = "HazardRail"})
		end
		-- glass channels beside the runner, with liquid racing along them
		k.glass(s * 3.55, 1.1, 0, 9.0, 0.92, rgb(190, 255, 190), "z", {name = "SideTube"})
		k.cyl(s * 3.55, 1.0, 0, 8.8, 0.62, goo, M.Neon, "z", {t = 0.45, name = "SideLiquid"})
		for _, z in ipairs({-4.5, 0, 4.5}) do
			k.cyl(s * 3.55, 1.1, z, 0.2, 1.08, steel, M.Metal, "z", {name = "TubeCollar"})
			k.box(s * 3.55, 0.35, z, 0.4, 0.7, 0.4, steel, M.Metal)
		end
		local blobs = {}
		for i = 1, 7 do
			table.insert(blobs, k.ball(s * 3.55, 1.08, 0, 0.42, hotGoo, M.Neon, {name = "Blob" .. i}))
		end
		k.anim("travel", blobs, s * 3.55, 1.08, 0, {Speed = 2.2, Idle = 0.5, Run = 2.8, path = {V(0, 0, -4.3), V(0, 0, 4.3)}})
	end)

	-- THE MAIN VAT, left front: the moving liquid
	local vx, vz, floorY, topY = -3.42, -7.1, 1.25, 8.2
	k.lathe(vx, 0.08, vz, {{0, 2.72}, {0.5, 2.6}, {1.15, 2.42}}, steel, M.Metal, {name = "VatBase"})
	k.cyl(vx, 1.05, vz, 0.12, 2.65, yellow, M.Metal, "y", {name = "VatBaseBand"})
	-- the column of liquid: rises and falls, and its surface sloshes
	local h = 4.9
	local liquid = k.cyl(vx, floorY + h / 2, vz, h, 2.2, goo, M.Neon, "y", {t = 0.5, name = "Liquid"})
	k.anim("gauge", liquid, 0, 0, 0, {GAxis = "X", Speed = 0.9, Amp = 0.05, Run = 2.2})
	local surface = {k.ell(vx, floorY + h, vz, 2.15, 0.42, 2.15, hotGoo, M.Neon, {t = 0.2, name = "Surface"})}
	for i = 0, 5 do
		local a = i * 1.05
		table.insert(surface, k.ball(vx + math.cos(a) * 0.7, floorY + h + 0.14, vz + math.sin(a) * 0.7, 0.24 + (i % 3) * 0.08, rgb(170, 255, 90), M.Neon, {name = "Foam"}))
	end
	k.anim("slide", surface, vx, floorY + h, vz, {Offset = V(0.03, 0.26, 0.03), Speed = 0.9, Run = 2.2, Phase = 0})
	-- bubbles: real parts, rising through the liquid and growing as they go
	local bubbles = {}
	for i = 1, 12 do
		table.insert(bubbles, k.ball(vx, floorY, vz, 0.2 + (i % 4) * 0.08, rgb(180, 255, 110), M.Neon, {name = "Bubble" .. string.format("%02d", i), shadow = false}))
	end
	k.anim("travel", bubbles, vx, 0, vz, {Speed = 1.15, Run = 2.3, Wobble = 0.55, Grow = 0.75, path = {V(0, floorY + 0.15, 0), V(0, floorY + h - 0.1, 0)}})
	-- the stirrer turning inside
	local stir = {k.cyl(vx, 5.2, vz, 5.4, 0.12, steel, M.Metal, "y", {name = "StirRod"})}
	for _, y in ipairs({2.2, 3.6, 5.0}) do
		table.insert(stir, k.box(vx, y, vz, 1.55, 0.3, 0.07, steel, M.Metal, {rx = 28, ry = y * 40, name = "Paddle"}))
	end
	k.anim("spin", stir, vx, 4, vz, {Axis = Vector3.yAxis, Speed = 1.6, Run = 2.6})
	k.glass(vx, 4.7, vz, 7.0, 2.42, rgb(190, 255, 200), "y", {t = 0.76, name = "VatGlass"})
	for _, y in ipairs({2.6, 4.7, 6.8}) do
		k.cyl(vx, y, vz, 0.1, 2.48, steel, M.Metal, "y", {name = "VatHoop"})
	end
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		k.cyl(vx + math.cos(a) * 1.2, 4.7, vz + math.sin(a) * 1.2, 7.1, 0.1, steel, M.Metal, "y", {name = "VatCageBar"})
	end
	k.lathe(vx, 8.2, vz, {{0, 2.6}, {0.4, 2.5}, {0.9, 1.3}, {1.25, 0.6}}, steel, M.Metal, {name = "VatLid"})
	k.cyl(vx, 8.25, vz, 0.1, 2.68, yellow, M.Metal, "y", {name = "LidBand"})
	k.light(liquid, goo, 14, 1)
	-- gas hissing out of the top
	k.emit(k.spot(vx, 9.5, vz, 0.4, 0.1, 0.4), {tex = "smoke", c1 = rgb(170, 255, 120), size = {0.5, 2.2}, alpha = {0.55, 1}, life = {1, 1.8}, speed = {1.5, 3}, rate = 2, run = 8, spread = {16, 16}, light = 0.4, accel = V(0, 0.6, 0)})
	-- warning beacon on the lid: a turning light
	k.cyl(vx, 9.55, vz, 0.2, 0.6, steel, M.Metal, "y")
	local beacon = {k.ball(vx, 9.85, vz, 0.48, rgb(255, 120, 30), M.Neon, {name = "Beacon"}), k.box(vx, 9.85, vz, 1.2, 0.06, 0.18, rgb(255, 200, 80), M.Neon, {t = 0.25, name = "BeaconBeam"}), k.box(vx, 9.85, vz, 0.18, 0.06, 1.2, rgb(255, 200, 80), M.Neon, {t = 0.25, name = "BeaconBeam"})}
	k.anim("spin", beacon, vx, 9.85, vz, {Axis = Vector3.yAxis, Speed = 3, Run = 2})

	-- THE PIPE: overhead from the vat to the flask, clear, with blobs travelling through it
	local p1, p2, p3, p4 = V(vx, 9.2, -7.0), V(-1.6, 10.2, -7.0), V(1.6, 10.2, -7.0), V(3.35, 9.2, -7.0)
	for _, pair in ipairs({{p1, p2}, {p2, p3}, {p3, p4}}) do
		k.seg(pair[1], pair[2], 0.72, rgb(190, 255, 200), M.SmoothPlastic, {t = 0.72, refl = 0.15, name = "ClearPipe"})
	end
	for _, p in ipairs({p2, p3}) do
		k.ball(p.X, p.Y, p.Z, 0.84, steel, M.Metal, {name = "PipeJoint"})
	end
	local flow = {}
	for i = 1, 9 do
		table.insert(flow, k.ball(0, 10, -7, 0.44, hotGoo, M.Neon, {name = "Flow" .. i, shadow = false}))
	end
	k.anim("travel", flow, 0, 0, 0, {Speed = 2.2, Run = 2.4, path = {p1, p2, p3, p4, V(3.35, 7.2, -7.0)}})
	-- a valve on the pipe, whose wheel spins
	local valve = k.ring(0, 10.2, -6.55, 0.4, 0.08, rgb(220, 50, 50), M.Metal, "z", {n = 10, depth = 0.08, name = "ValveWheel"})
	table.insert(valve, k.box(0, 10.2, -6.55, 0.08, 0.8, 0.06, rgb(220, 50, 50), M.Metal, {name = "ValveSpoke"}))
	table.insert(valve, k.box(0, 10.2, -6.55, 0.8, 0.08, 0.06, rgb(220, 50, 50), M.Metal, {name = "ValveSpoke"}))
	k.anim("swing", valve, 0, 10.2, -6.55, {Axis = Vector3.zAxis, Amp = 70, Speed = 0.6, Run = 2})
	k.cyl(0, 10.2, -6.8, 0.6, 0.22, steel, M.Metal, "z")
	k.cyl(0, 10.2, -7.0, 0.5, 0.82, steel, M.Metal, "x", {name = "ValveBody"})

	-- THE FLASK, right front: pink, boiling, on a burner
	local fx, fy, fz = 3.3, 3.25, -7.0
	k.cyl(fx, 0.4, fz, 0.7, 1.4, dark, M.Metal, "y", {name = "BurnerBase"})
	k.cyl(fx, 0.85, fz, 0.2, 0.5, steel, M.Metal, "y")
	local flame = {}
	for i = 0, 2 do
		table.insert(flame, k.cyl(fx + (i - 1) * 0.16, 1.15, fz, 0.42, 0.12, rgb(80, 170, 255), M.Neon, "y", {t = 0.15, name = "BurnerFlame" .. i, shadow = false}))
	end
	k.anim("gauge", flame, 0, 0, 0, {GAxis = "X", Speed = 14, Amp = 0.32, Stagger = 1.8})
	k.m(function(s)
		k.seg(V(fx + s * 1.1, 0.1, fz + 0.5), V(fx + s * 1.0, 1.75, fz + 0.5), 0.09, steel, M.Metal, {name = "TripodLeg"})
	end)
	k.seg(V(fx, 0.1, fz - 1.1), V(fx, 1.75, fz - 1.0), 0.09, steel, M.Metal, {name = "TripodLeg"})
	k.ring(fx, 1.75, fz, 1.05, 0.09, steel, M.Metal, "y", {n = 10, depth = 0.09, name = "TripodRing"})
	-- the pink liquid fills its lower half and heaves
	local pool = k.ell(fx, fy - 0.42, fz, 2.2, 1.65, 2.2, pinkGoo, M.Neon, {t = 0.42, name = "FlaskLiquid"})
	local poolTop = {k.ell(fx, fy + 0.32, fz, 2.02, 0.24, 2.02, rgb(255, 80, 200), M.Neon, {t = 0.15, name = "FlaskSurface"})}
	k.anim("slide", poolTop, fx, fy + 0.32, fz, {Offset = V(0, 0.09, 0), Speed = 5, Run = 1.8})
	local fb = {}
	for i = 1, 9 do
		table.insert(fb, k.ball(fx, fy, fz, 0.18 + (i % 3) * 0.07, rgb(255, 120, 215), M.Neon, {name = "Boil" .. i, shadow = false}))
	end
	k.anim("travel", fb, fx, 0, fz, {Speed = 1.5, Run = 2.2, Wobble = 0.58, Grow = 0.6, path = {V(0, fy - 1.05, 0), V(0, fy + 0.34, 0)}})
	k.ball(fx, fy, fz, 2.7, rgb(240, 225, 255), M.SmoothPlastic, {t = 0.75, refl = 0.2, name = "FlaskGlass"})
	k.glass(fx, fy + 2.4, fz, 2.4, 0.86, rgb(240, 225, 255), "y", {name = "FlaskNeck"})
	k.cyl(fx, fy + 3.62, fz, 0.14, 1.0, steel, M.Metal, "y", {name = "NeckRim"})
	k.light(pool, pinkGoo, 9, 0.6)
	-- the coil up the outside, glowing in sequence
	local coil = {}
	for i = 0, 5 do
		for _, p in ipairs(k.ring(fx, fy + 1.55 + i * 0.3, fz, 0.68, 0.08, rgb(160, 255, 120), M.Neon, "y", {n = 8, depth = 0.08, rz = 7, name = "Coil" .. i})) do
			table.insert(coil, p)
		end
	end
	k.anim("pulse", coil, 0, 0, 0, {Speed = 3.5, Stagger = 0.13, ColorA = rgb(30, 90, 30), ColorB = rgb(180, 255, 130), Run = 2})
	k.emit(k.spot(fx, fy + 3.72, fz, 0.5, 0.1, 0.5), {tex = "puff", c1 = rgb(255, 150, 240), c2 = rgb(170, 90, 255), size = {0.4, 1.3}, alpha = {0.4, 1}, life = {0.7, 1.2}, speed = {1.5, 3}, rate = 2, run = 8, spread = {18, 18}, light = 0.5})

	-- THE CONSOLE: monitor and test tube rack
	k.box(0, 1.05, -5.85, 3.3, 1.8, 1.3, dark, M.Metal, {name = "LabBench"})
	k.box(0, 2.0, -5.85, 3.5, 0.12, 1.45, steel, M.Metal, {name = "BenchTop"})
	local warn = k.box(0, 1.05, -6.52, 2.6, 1.1, 0.04, yellow, M.SmoothPlastic, {name = "WarningPanel"})
	k.text(warn, "Front", "\u{2623} TOXIC \u{2623}", BLACK, 44)
	k.box(0, 3.15, -5.95, 2.0, 1.4, 0.24, ink, M.Metal, {name = "Monitor"})
	k.box(0, 2.25, -5.95, 0.4, 0.4, 0.3, ink, M.Metal)
	local screen = k.glow(0, 3.15, -5.8, 1.72, 1.15, 0.03, rgb(16, 70, 22), {name = "Screen"})
	k.text(screen, "Back", "\u{2620}", goo, 90)
	k.anim("flicker", screen, 0, 0, 0, {Speed = 4, ColorA = rgb(8, 36, 12), ColorB = rgb(24, 110, 36)})
	-- the test tube rack on the bench, each with its own colour and level
	k.box(0, 2.42, -5.1, 3.2, 0.12, 0.42, steel, M.Metal, {name = "Rack"})
	k.box(0, 3.35, -5.1, 3.2, 0.08, 0.42, steel, M.Metal, {name = "Rack"})
	k.m(function(s)
		k.box(s * 1.56, 2.9, -5.1, 0.08, 1.0, 0.42, steel, M.Metal)
	end)
	local levels = {}
	for i, c in ipairs({goo, pinkGoo, rgb(70, 200, 255), rgb(255, 180, 40), rgb(190, 90, 255)}) do
		local x = -1.5 + i * 0.5
		k.glass(x, 2.95, -5.1, 1.5, 0.34, WHITE, "y", {name = "TestTube"})
		table.insert(levels, k.cyl(x, 2.62, -5.1, 0.72, 0.26, c, M.Neon, "y", {t = 0.15, name = "TubeLiquid" .. i}))
		k.cyl(x, 3.72, -5.1, 0.12, 0.38, rgb(190, 60, 60), M.SmoothPlastic, "y", {name = "TubeStopper"})
		local b = {}
		for j = 1, 3 do
			table.insert(b, k.ball(x, 2.3, -5.1, 0.07, WHITE, M.Neon, {name = "TubeBubble" .. j}))
		end
		k.anim("travel", b, x, 0, -5.1, {Speed = 0.8, Run = 2, path = {V(0, 2.32, 0), V(0, 3.0, 0)}, Phase = i})
	end
	k.anim("gauge", levels, 0, 0, 0, {GAxis = "X", Speed = 1.5, Amp = 0.2, Stagger = 1.3, Run = 2})

	-- THE BARRELS, behind: one standing and leaking, one tipped into a spreading pool
	local function barrel(x, y, z, axis, o)
		k.cyl(x, y, z, 1.7, 1.2, yellow, M.Metal, axis, o)
		local band = table.clone(o or {})
		for _, f in ipairs({-0.55, 0, 0.55}) do
			local dx, dy, dz = 0, 0, 0
			if axis == "x" then dx = f elseif axis == "y" then dy = f else dz = f end
			k.cyl(x + dx, y + dy, z + dz, 0.12, 1.26, BLACK, M.Metal, axis, {name = "BarrelBand"})
		end
	end
	barrel(-3.6, 1.0, 6.3, "y", {name = "Barrel"})
	local label = k.box(-3.6, 1.0, 5.68, 0.8, 0.8, 0.04, WHITE, M.SmoothPlastic, {name = "BarrelLabel"})
	k.text(label, "Front", "\u{2622}", BLACK, 60)
	k.text(label, "Back", "\u{2622}", BLACK, 60)
	barrel(3.1, 0.72, 6.5, "x", {name = "Barrel"})
	local pools = {
		k.ell(1.45, 0.09, 6.45, 1.6, 0.1, 1.2, goo, M.Neon, {name = "Pool1"}),
		k.ell(0.6, 0.09, 6.1, 1.0, 0.08, 0.8, goo, M.Neon, {name = "Pool2"}),
		k.ell(-3.0, 0.09, 5.8, 1.6, 0.08, 1.1, goo, M.Neon, {name = "Pool3"}),
		k.ell(-2.0, 0.09, -8.5, 2.0, 0.08, 1.2, goo, M.Neon, {name = "Pool4"}),
	}
	k.anim("pulse", pools, 0, 0, 0, {Speed = 1.8, Stagger = 1.1, ColorA = rgb(40, 150, 30), ColorB = rgb(140, 255, 90)})
	local drips = {}
	for i = 1, 3 do
		table.insert(drips, k.ball(2.2, 0.6, 6.5, 0.2, hotGoo, M.Neon, {name = "Drip" .. i}))
	end
	k.anim("travel", drips, 2.2, 0, 6.5, {Speed = 0.9, Run = 2, path = {V(0, 0.68, 0), V(-0.3, 0.14, 0)}})
	-- green motes drifting over the floor, thick when running
	k.emit(k.spot(0, 0.5, -1, 8, 0.2, 14), {tex = "sparkle", c1 = goo, c2 = hotGoo, size = {0.28, 0}, life = {1.2, 2.4}, speed = {0.4, 1}, rate = 3, run = 12, spread = {25, 25}, light = 0.9})
end}

-- A machine that farms lightning. Two great Tesla coils of wound copper stand at the front with turning toroids; real jagged
-- bolts leap between them over the runner's head and up into a thundercloud that flickers and rains. Spinning capacitor
-- banks beside the lane, a Jacob's ladder climbing behind, a turbine under a glass dome and a voltage dial facing the runner.
return {Name = "Storm Titan", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9112780680", 0.22, 1.3)
	local steel, dark, ink, electric, bolt, copper, cloud, cloudDark, warn = rgb(82, 92, 112), rgb(30, 34, 46), rgb(16, 18, 26), rgb(90, 190, 255), rgb(215, 240, 255), rgb(198, 118, 62), rgb(70, 72, 92), rgb(40, 40, 56), rgb(255, 215, 50)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, ink, M.DiamondPlate, {name = "Platform"})
	k.deck(5, dark, M.Metal)
	k.belt({rgb(26, 32, 50), rgb(46, 64, 100)}, M.Metal, 4.2)
	k.m(function(s)
		-- power rail: arcs crawl along it
		k.box(s * 2.62, 0.45, 0, 0.5, 0.6, 10.2, steel, M.Metal, {name = "PowerRail"})
		local rail = {}
		for i = 0, 10 do
			table.insert(rail, k.box(s * 2.62, 0.78, -5 + i, 0.2, 0.06, 0.86, electric, M.Neon, {name = "RailCell" .. string.format("%02d", i)}))
		end
		k.anim("pulse", rail, 0, 0, 0, {Speed = 5, Stagger = -0.85, Sharp = 4, ColorA = rgb(20, 40, 70), ColorB = bolt, Idle = 0.5, Run = 2.4})
		-- capacitor bank beside the runner: ring stacks that turn, charging from one end
		for _, z in ipairs({-2.6, 0.2, 3.0}) do
			k.cyl(s * 3.72, 0.3, z, 0.5, 1.55, dark, M.Metal, "y", {name = "CapBase"})
			local stack = {}
			local cells = {}
			for i = 0, 3 do
				table.insert(stack, k.cyl(s * 3.72, 0.8 + i * 0.5, z, 0.3, 1.05, steel, M.Metal, "y", {name = "CapPlate"}))
				table.insert(cells, k.cyl(s * 3.72, 1.03 + i * 0.5, z, 0.16, 0.85, electric, M.Neon, "y", {name = "CapCell" .. i}))
			end
			k.anim("pulse", cells, 0, 0, 0, {Speed = 3, Stagger = 0.8, Sharp = 2, ColorA = rgb(16, 36, 60), ColorB = bolt, Run = 2.2, Phase = z})
			k.ball(s * 3.72, 2.95, z, 0.34, electric, M.Neon, {name = "CapTerminal"})
		end

		-- A TESLA COIL: wound copper, a turning toroid and an orb
		local cx, cz = s * 3.5, -7.2
		k.lathe(cx, 0.08, cz, {{0, 2.2}, {0.6, 1.9}, {1.1, 1.05}}, dark, M.Metal, {name = "CoilBase"})
		k.cyl(cx, 1.1, cz, 0.12, 1.9, warn, M.Metal, "y", {name = "CoilBaseBand"})
		k.cyl(cx, 4.2, cz, 6.0, 0.72, rgb(28, 28, 32), M.SmoothPlastic, "y", {name = "CoilCore"})
		for i = 0, 18 do
			k.cyl(cx, 1.45 + i * 0.3, cz, 0.15, 0.82 + (i % 2) * 0.04, copper:Lerp(rgb(240, 170, 90), (i % 3) * 0.25), M.Metal, "y", {name = "CoilWinding"})
		end
		local toroid = k.ring(cx, 7.45, cz, 0.72, 0.42, steel, M.Metal, "y", {n = 12, depth = 0.42, name = "Toroid"})
		for i = 0, 3 do
			local a = math.rad(i * 90)
			table.insert(toroid, k.glow(cx + math.sin(a) * 0.74, 7.68, cz + math.cos(a) * 0.74, 0.18, 0.05, 0.18, electric, {name = "ToroidLight"}))
		end
		k.anim("spin", toroid, cx, 7.45, cz, {Axis = Vector3.yAxis, Speed = s * 1.6, Run = 2.8})
		k.cyl(cx, 7.65, cz, 0.5, 0.2, steel, M.Metal, "y")
		local orb = k.ball(cx, 8.15, cz, 0.85, bolt, M.Neon, {name = "CoilOrb"})
		k.anim("pulse", orb, 0, 0, 0, {Speed = 8, ColorA = electric, ColorB = WHITE, Run = 1.6})
		k.emit(orb, {tex = "sparks", c1 = bolt, c2 = electric, size = {0.28, 0.04}, life = {0.15, 0.4}, speed = {4, 10}, rate = 6, run = 20, spread = {180, 180}, light = 1})
		-- a bolt from each orb out to its grounding rod, outside the lane
		local gx, gz = s * 4.45, -5.0
		k.box(gx, 0.8, gz, 0.14, 1.6, 0.14, steel, M.Metal, {name = "GroundRod"})
		k.ball(gx, 1.62, gz, 0.26, electric, M.Neon)
		local side = {}
		for i = 1, 6 do
			table.insert(side, k.box(gx, 2 + i, gz, 0.5, 0.07, 0.07, bolt, M.Neon, {name = "SideBolt" .. i, shadow = false}))
		end
		k.anim("bolt", side, 0, 0, 0, {A = V(cx, 7.9, cz), B = V(gx, 1.7, gz), Jitter = 0.34, Hz = 9, Off = 0.55, Idle = 0.7, Run = 1.6})
		-- a storm cloud bank above each coil
		k.ball(cx, 10.6, cz - 0.3, 2.4, cloudDark, M.SmoothPlastic, {name = "Cloud"})
	end)
	for i, c in ipairs({{0, 11.2, -7.6, 2.2, cloud}, {-1.6, 11.3, -7.4, 1.9, cloud}, {1.7, 11.25, -7.3, 2.0, cloud}, {-0.9, 10.5, -6.8, 1.7, cloudDark}, {1.0, 10.5, -7.0, 1.7, cloudDark}, {-3.4, 11.4, -6.9, 1.6, cloud}, {3.4, 11.4, -7.1, 1.6, cloud}, {-2.4, 10.4, -8.1, 1.5, cloudDark}, {2.4, 10.45, -8.2, 1.5, cloudDark}, {0.2, 10.55, -8.6, 1.5, cloudDark}, {-0.8, 11.8, -6.7, 1.1, cloud}, {1.0, 11.8, -6.9, 1.1, cloud}}) do
		k.ball(c[1], c[2], c[3], c[4], c[5], M.SmoothPlastic, {name = "Cloud"})
	end
	-- the cloud lights up from inside
	local flashes = {}
	for i, c in ipairs({{-1.7, 10.6}, {0.2, 10.45}, {1.9, 10.7}}) do
		table.insert(flashes, k.ball(c[1], c[2], -6.2, 1.1, bolt, M.Neon, {t = 0.25, name = "Flash" .. i, shadow = false}))
	end
	k.anim("flicker", flashes, 0, 0, 0, {Speed = 6, TransA = 1, TransB = 0.1, Run = 2})
	k.light(flashes[2], rgb(170, 215, 255), 18, 1.6)
	-- THE MAIN BOLTS, coil to coil over the head (the two endpoints stay well above the runner), and up into the cloud
	local main, second, up = {}, {}, {}
	for i = 1, 8 do
		table.insert(main, k.box(0, 9, -7.2, 0.8, 0.16, 0.16, WHITE, M.Neon, {name = "MainBolt" .. i, shadow = false}))
		table.insert(second, k.box(0, 9, -7.2, 0.8, 0.08, 0.08, bolt, M.Neon, {name = "SecondBolt" .. i, shadow = false}))
	end
	for i = 1, 5 do
		table.insert(up, k.box(0, 9.3, -7.2, 0.4, 0.09, 0.09, bolt, M.Neon, {name = "UpBolt" .. i, shadow = false}))
	end
	k.anim("bolt", main, 0, 0, 0, {A = V(-3.5, 8.3, -7.2), B = V(3.5, 8.3, -7.2), Jitter = 0.5, Hz = 11, Off = 0.3, Idle = 0.8, Run = 1.6})
	k.anim("bolt", second, 0, 0, 0, {A = V(-3.5, 8.3, -7.2), B = V(3.5, 8.3, -7.2), Jitter = 0.75, Hz = 14, Off = 0.5, Idle = 0.8, Run = 1.6})
	k.anim("bolt", up, 0, 0, 0, {A = V(0, 8.4, -7.2), B = V(0.5, 10.2, -7.2), Jitter = 0.45, Hz = 8, Off = 0.6, Run = 1.6})
	-- rain falls from the cloud either side, leaving the runner clear
	k.m(function(s)
		k.emit(k.spot(s * 3.7, 9.6, -7.2, 1.8, 0.1, 2.8), {tex = "glow", c1 = rgb(170, 215, 255), size = {0.1, 0.06}, alpha = {0.25, 0.6}, life = {0.5, 0.7}, speed = {16, 20}, rate = 8, run = 22, dir = "Bottom", spread = {2, 2}, light = 0.5, rot = {0, 0}, spinV = {0, 0}})
	end)

	-- THE CONSOLE: a domed turbine and a voltage dial for the runner
	k.box(0, 0.95, -5.9, 3.4, 1.6, 1.3, steel, M.Metal, {name = "Generator"})
	local warnPlate = k.box(0, 0.95, -6.56, 2.9, 1.1, 0.03, warn, M.SmoothPlastic, {name = "WarnPlate"})
	k.text(warnPlate, "Front", "\u{26A1} HIGH VOLTAGE \u{26A1}", BLACK, 46)
	k.cyl(0, 1.85, -5.9, 0.2, 2.5, dark, M.Metal, "y", {name = "DomeRing"})
	local turbine = {}
	for i = 0, 5 do
		table.insert(turbine, k.box(0, 2.6, -5.9, 2.0, 0.5, 0.1, electric, M.Neon, {ry = i * 30, rx = 22, name = "TurbineBlade"}))
	end
	table.insert(turbine, k.cyl(0, 2.6, -5.9, 1.2, 0.34, WHITE, M.Neon, "y", {name = "TurbineCore"}))
	k.anim("spin", turbine, 0, 2.6, -5.9, {Axis = Vector3.yAxis, Speed = 3, Run = 3})
	k.ell(0, 2.0, -5.9, 2.4, 3.8, 2.4, rgb(180, 225, 255), M.SmoothPlastic, {t = 0.72, refl = 0.2, name = "Dome"})
	local dial = k.cyl(1.32, 2.55, -5.1, 0.08, 1.0, dark, M.Metal, "z", {name = "VoltDial"})
	k.cyl(1.32, 2.55, -5.05, 0.03, 0.84, rgb(232, 240, 250), M.SmoothPlastic, "z")
	local needle = k.box(1.32, 2.72, -5.02, 0.04, 0.34, 0.015, rgb(235, 40, 40), M.Neon, {name = "VoltNeedle"})
	k.anim("swing", needle, 1.32, 2.55, -5.02, {Axis = Vector3.zAxis, Amp = 50, Speed = 1.1, Idle = 0.6, Run = 3})
	k.box(1.32, 1.8, -5.08, 0.3, 0.6, 0.1, dark, M.Metal)
	local bars = {}
	for i = 0, 5 do
		table.insert(bars, k.glow(-1.7 + i * 0.2, 2.1, -5.2, 0.14, 0.34, 0.02, Color3.fromHSV(0.55 - i * 0.09, 0.8, 1), {name = "Volt" .. i}))
	end
	k.anim("gauge", bars, 0, 0, 0, {Speed = 7, Amp = 0.7, Stagger = 0.9, Idle = 0.6, Run = 1.8})
	k.box(-1.2, 2.1, -5.25, 1.3, 0.75, 0.04, dark, M.Metal, {name = "VoltPanel"})
	k.seg(V(-1.0, 3.05, -4.95), V(1.0, 3.05, -4.95), 0.08, steel, M.Metal)

	-- BEHIND: a Jacob's ladder: an arc climbing two rods, and a coil spring of cable
	k.m(function(s)
		k.seg(V(s * 0.45 - 2.8, 0.4, 6.5), V(s * 0.85 - 2.8, 2.35, 6.5), 0.1, rgb(220, 224, 232), M.Metal, {name = "LadderRod"})
	end)
	k.box(-2.8, 0.25, 6.5, 1.5, 0.4, 0.9, dark, M.Metal, {name = "LadderBase"})
	local arc = k.glow(-2.8, 0.6, 6.5, 0.85, 0.09, 0.09, bolt, {name = "LadderArc"})
	k.anim("travel", arc, -2.8, 0, 6.5, {Speed = 1.8, Run = 2.5, path = {V(0, 0.55, 0), V(0, 2.25, 0)}})
	k.box(3.1, 0.75, 6.4, 2.6, 1.3, 1.3, steel, M.Metal, {name = "TransformerBox"})
	k.box(3.1, 1.42, 6.4, 2.7, 0.1, 1.4, warn, M.Metal)
	for _, x in ipairs({2.3, 3.1, 3.9}) do
		k.lathe(x, 1.47, 6.4, {{0, 0.36}, {0.2, 0.18}, {0.4, 0.3}, {0.55, 0.15}}, rgb(232, 232, 240), M.SmoothPlastic, {name = "Insulator"})
		k.ball(x, 2.12, 6.4, 0.2, electric, M.Neon)
	end
	local tp = k.box(3.1, 0.75, 7.06, 2.0, 0.85, 0.03, dark, M.SmoothPlastic, {name = "TransformerSign"})
	k.text(tp, "Back", "1.21 GIGA", electric, 50)
	-- static crawling off the deck while someone's running
	k.emit(k.spot(0, 1.0, 0, 5.2, 0.1, 9.6), {tex = "sparks", c1 = bolt, c2 = electric, size = {0.28, 0.04}, life = {0.12, 0.3}, speed = {2, 6}, rate = 0, run = 16, spread = {180, 180}, light = 1})
end}

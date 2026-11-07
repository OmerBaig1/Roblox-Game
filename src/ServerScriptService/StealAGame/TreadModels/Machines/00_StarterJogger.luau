-- A real home-gym treadmill on a rubber mat: motor hood with vents, big console with a live heart monitor, safety key on
-- a cord, foam grips, cup holders with a bottle, a towel, a dumbbell rack, and a floor fan turning its head. Humble, tidy.
return {Name = "Starter Jogger", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local frame, dark, steel, blue, rubber, foam = rgb(232, 235, 240), rgb(46, 50, 60), rgb(165, 172, 184), rgb(70, 170, 255), rgb(38, 40, 46), rgb(26, 26, 30)
	k.box(0, 0.03, -0.8, 8.7, 0.06, 15.8, rubber, M.Rubber, {name = "GymMat"})
	k.deck(4.8, dark, M.SmoothPlastic)
	k.belt({rgb(34, 34, 40), rgb(44, 44, 52)}, M.Fabric, 4.3)
	-- motor hood
	k.box(0, 0.7, -5.65, 5.2, 1.3, 1.9, frame, M.SmoothPlastic, {solid = true, name = "MotorHood"})
	k.cyl(0, 0.75, -6.6, 5.2, 1.2, frame, M.SmoothPlastic, "x")
	k.box(0, 1.37, -5.5, 3.6, 0.05, 1.2, blue, M.SmoothPlastic, {name = "HoodStripe"})
	k.m(function(s)
		for i = 0, 4 do
			k.box(s * 2.62, 0.75, -6.3 + i * 0.36, 0.04, 0.7, 0.14, dark, M.SmoothPlastic, {name = "Vent"})
		end
		-- side rails with grip tape and a blue light
		k.box(s * 2.62, 0.42, 0, 0.5, 0.56, 10.1, frame, M.SmoothPlastic, {name = "SideRail"})
		k.box(s * 2.62, 0.71, 0, 0.42, 0.04, 9.6, rubber, M.DiamondPlate, {name = "GripTape"})
		k.glow(s * 2.88, 0.42, 0, 0.03, 0.09, 9.6, blue, {name = "RailLight"})
		-- rear roller cap and transport wheels
		k.cyl(s * 2.5, 0.4, 5.15, 0.3, 0.8, steel, M.Metal, "x")
		k.wheel(s * 2.95, 0.3, 5.0, 0.6, 0.3, rubber, steel, {spokes = 3})
		-- uprights lean toward the runner, with handrails coming back beside them
		k.seg(V(s * 2.62, 0.9, -5.4), V(s * 2.62, 3.3, -5.1), 0.38, steel, M.Metal, {name = "Upright"})
		k.seg(V(s * 2.62, 3.3, -5.1), V(s * 2.62, 4.0, -5.0), 0.34, steel, M.Metal)
		k.box(s * 2.62, 3.05, -2.9, 0.26, 0.2, 4.2, steel, M.Metal, {name = "Handrail"})
		k.cyl(s * 2.62, 3.05, -2.3, 2.3, 0.36, foam, M.Rubber, "z", {name = "FoamGrip"})
		k.cyl(s * 2.62, 3.05, -3.75, 0.7, 0.4, rgb(210, 215, 225), M.Metal, "z", {name = "PulseSensor"})
		k.ball(s * 2.62, 3.05, -0.8, 0.42, foam, M.Rubber)
		-- cup holders on the console ends
		k.cyl(s * 3.15, 3.55, -4.95, 0.5, 0.75, dark, M.SmoothPlastic, "y", {name = "CupHolder"})
	end)
	-- console, tipped toward the runner
	local rx = 18
	k.box(0, 3.95, -5.2, 5.6, 1.15, 0.5, frame, M.SmoothPlastic, {rx = rx, name = "Console"})
	k.box(0, 3.95, -5.0, 5.2, 0.9, 0.06, dark, M.SmoothPlastic, {rx = rx})
	local screen = k.glow(0, 4.03, -4.92, 2.4, 0.6, 0.04, rgb(14, 40, 70), {rx = rx, name = "Screen"})
	k.text(screen, "Back", "KEEP GOING!", rgb(120, 220, 255), 60)
	k.box(0, 4.46, -5.36, 5.6, 0.1, 0.4, blue, M.Neon, {rx = rx, name = "ConsoleEdge"})
	-- live heart monitor: a bar graph beside the screen and a beating heart
	local bars = {}
	for i = 0, 6 do
		table.insert(bars, k.glow(-2.3 + i * 0.13, 3.82, -4.97, 0.09, 0.28, 0.04, rgb(90, 255, 140), {name = "Bar" .. i}))
	end
	k.anim("gauge", bars, 0, 0, 0, {Speed = 5, Run = 2.4, Idle = 0.35, Amp = 0.8, Stagger = 0.9})
	local heart = k.ball(1.75, 4.0, -4.95, 0.3, rgb(255, 60, 90), M.Neon, {name = "Heart"})
	k.anim("pulse", heart, 0, 0, 0, {Speed = 3.2, Run = 2.6, Idle = 0.5, Sharp = 4, ColorA = rgb(90, 20, 35), ColorB = rgb(255, 70, 100)})
	-- buttons
	for i, c in ipairs({rgb(70, 220, 110), rgb(250, 200, 50), rgb(70, 170, 255), rgb(70, 170, 255)}) do
		k.cyl(-1.05 + i * 0.42, 3.52, -4.87, 0.05, 0.28, c, M.SmoothPlastic, "z", {rx = rx, name = "Button"})
	end
	-- safety key on a red cord, dangling and swaying with the running
	k.cyl(0, 3.42, -5.0, 0.1, 0.42, rgb(230, 40, 40), M.SmoothPlastic, "z", {name = "StopKey"})
	local cord = k.box(0, 2.95, -4.92, 0.05, 0.9, 0.05, rgb(230, 40, 40), M.Fabric, {name = "KeyCord"})
	local clip = k.box(0, 2.48, -4.92, 0.14, 0.14, 0.08, rgb(250, 250, 250), M.SmoothPlastic, {name = "KeyClip"})
	k.anim("swing", {cord, clip}, 0, 3.42, -4.92, {Axis = Vector3.xAxis, Amp = 7, Speed = 2.5, Run = 3, Idle = 0.5})
	-- a fan built into the console
	k.cyl(0, 2.6, -5.5, 0.1, 1.15, dark, M.SmoothPlastic, "z", {name = "FanHousing"})
	local mini = {}
	for i = 0, 2 do
		table.insert(mini, k.box(0, 2.6, -5.42, 0.2, 1.0, 0.03, steel, M.SmoothPlastic, {rz = i * 60, name = "FanBlade"}))
	end
	k.anim("spin", mini, 0, 2.6, -5.42, {Axis = Vector3.zAxis, Speed = 7, Idle = 0.3, Run = 2})
	-- a water bottle and a towel over the rail
	k.cyl(-3.15, 4.05, -4.95, 0.95, 0.55, rgb(120, 200, 255), M.SmoothPlastic, "y", {t = 0.3, name = "Bottle"})
	k.cyl(-3.15, 4.6, -4.95, 0.18, 0.4, blue, M.SmoothPlastic, "y")
	k.box(2.62, 2.62, -1.6, 0.42, 1.0, 1.05, rgb(255, 150, 120), M.Fabric, {name = "Towel"})
	k.box(2.62, 3.2, -1.6, 0.46, 0.12, 1.05, rgb(255, 150, 120), M.Fabric)
	k.box(2.62, 2.25, -1.6, 0.44, 0.1, 1.07, WHITE, M.Fabric)
	-- a floor fan at the front left: its head turns from side to side
	k.cyl(-3.75, 0.2, -7.6, 0.25, 1.5, dark, M.SmoothPlastic, "y", {name = "FanBase"})
	k.cyl(-3.75, 2.6, -7.6, 4.6, 0.22, steel, M.Metal, "y", {name = "FanPole"})
	local head = {
		k.cyl(-3.75, 5.2, -7.6, 0.5, 0.7, dark, M.SmoothPlastic, "z", {name = "FanMotor"}),
		k.cyl(-3.75, 5.2, -7.3, 0.08, 0.3, blue, M.Neon, "z", {name = "FanCap"}),
	}
	for _, ring in ipairs({k.ring(-3.75, 5.2, -7.28, 0.98, 0.07, steel, M.Metal, "z", {n = 14, depth = 0.08, name = "FanGuard"}), k.ring(-3.75, 5.2, -7.06, 0.98, 0.07, steel, M.Metal, "z", {n = 14, depth = 0.08, name = "FanGuard"})}) do
		for _, p in ipairs(ring) do
			table.insert(head, p)
		end
	end
	local blades = {}
	for i = 0, 3 do
		table.insert(blades, k.box(-3.75, 5.2, -7.18, 0.34, 1.75, 0.04, blue:Lerp(WHITE, 0.3), M.SmoothPlastic, {rz = i * 45, name = "Blade"}))
	end
	k.anim("spin", blades, -3.75, 5.2, -7.18, {Axis = Vector3.zAxis, Speed = 9, Idle = 0.8, Run = 1.5})
	k.anim("swing", head, -3.75, 5.2, -7.6, {Axis = Vector3.yAxis, Amp = 10, Speed = 0.8})
	local breeze = k.spot(-3.75, 5.2, -6.8, 1.4, 1.4, 0.2)
	k.emit(breeze, {tex = "glow", c1 = rgb(210, 240, 255), size = {0.5, 0.1}, alpha = {0.7, 1}, life = {0.5, 0.9}, speed = {5, 8}, rate = 0, run = 6, dir = "Back", light = 0.3})
	-- a motivation board, front right
	k.seg(V(3.85, 0, -8.2), V(3.85, 4.2, -8.2), 0.18, steel, M.Metal, {name = "BoardPost"})
	local board = k.box(3.85, 5.1, -8.2, 1.7, 2.0, 0.12, WHITE, M.SmoothPlastic, {name = "Board"})
	k.text(board, "Back", "YOU\nGOT\nTHIS!", rgb(40, 110, 220), 50)
	k.text(board, "Front", "DAY\n1", rgb(240, 80, 80), 50)
	k.ball(3.5, 1.05, -6.6, 2.0, rgb(90, 190, 255), M.SmoothPlastic, {name = "ExerciseBall"})
	k.box(-3.75, 0.15, -5.8, 1.5, 0.2, 2.8, rgb(150, 110, 240), M.Fabric, {name = "YogaMat"})
	k.cyl(-3.75, 0.5, -4.75, 1.5, 0.75, rgb(150, 110, 240), M.Fabric, "x")
	-- a dumbbell rack behind, kettlebell and sneakers on the mat
	k.box(3.3, 0.9, 6.5, 2.2, 0.12, 0.9, steel, M.Metal, {name = "Rack"})
	k.box(3.3, 0.5, 6.5, 2.2, 0.12, 0.9, steel, M.Metal, {name = "Rack"})
	k.m(function(s)
		k.box(3.3 + s * 1.05, 0.55, 6.5, 0.12, 1.1, 0.9, dark, M.SmoothPlastic)
	end)
	for i, c in ipairs({rgb(240, 80, 80), rgb(250, 190, 50), rgb(70, 170, 255)}) do
		local x = 2.3 + i * 0.5
		k.box(x, 1.1, 6.5, 0.1, 0.1, 0.65, steel, M.Metal, {name = "Dumbbell"})
		k.m(function(s)
			k.box(x, 1.1, 6.5 + s * 0.3, 0.32, 0.32, 0.14, c, M.SmoothPlastic)
		end)
	end
	k.ball(-3.4, 0.45, 6.4, 0.85, dark, M.Metal, {name = "Kettlebell"})
	k.ring(-3.4, 1.0, 6.4, 0.24, 0.09, steel, M.Metal, "z", {n = 7, a0 = -100, a1 = 100, depth = 0.09})
	k.m(function(s)
		k.ell(-1.0 + s * 0.3, 0.2, 6.3, 0.42, 0.34, 1.0, WHITE, M.SmoothPlastic, {name = "Sneaker"})
	end)
	-- breath of dust off the back of the belt when running
	k.emit(k.spot(0, 0.9, 5.0, 3.6, 0.1, 0.2), {tex = "smoke", c1 = rgb(200, 200, 205), size = {0.3, 1}, alpha = {0.6, 1}, life = {0.5, 1}, speed = {1, 2}, rate = 0, run = 5, dir = "Back", light = 0, lit = 1})
end}

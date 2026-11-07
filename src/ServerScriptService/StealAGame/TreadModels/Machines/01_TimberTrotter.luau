-- A working sawmill. A flume carries water from a tower tank over the runner's head onto a great waterwheel; the wheel
-- drives a circular saw that bites a log. Log rails, lanterns, a swinging sign, stump and axe, a tidy log pile.
return {Name = "Timber Trotter", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9120571336", 0.3, 1)
	local wood, light, bark, iron, water, cut = rgb(112, 72, 42), rgb(176, 124, 74), rgb(72, 48, 30), rgb(58, 58, 62), rgb(70, 170, 235), rgb(214, 172, 118)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, rgb(84, 112, 56), M.Grass, {name = "Ground"})
	k.deck(4.8, wood, M.WoodPlanks)
	k.belt({rgb(150, 105, 60), rgb(124, 86, 50)}, M.WoodPlanks, 4.2)
	k.m(function(s)
		-- split-log rails with cut ends and iron straps
		k.cyl(s * 2.75, 0.62, 0, 10.4, 0.85, bark, M.Wood, "z", {name = "LogRail"})
		k.cyl(s * 2.75, 0.62, 5.22, 0.06, 0.78, cut, M.Wood, "z")
		k.cyl(s * 2.75, 0.62, -5.22, 0.06, 0.78, cut, M.Wood, "z")
		for _, z in ipairs({-3.5, 0, 3.5}) do
			k.cyl(s * 2.75, 0.62, z, 0.16, 0.9, iron, M.Metal, "z", {name = "Strap"})
		end
		-- lantern posts beside the runner
		k.box(s * 3.9, 1.6, -1.4, 0.32, 3.2, 0.32, wood, M.Wood, {name = "LampPost"})
		k.box(s * 3.55, 3.05, -1.4, 0.7, 0.16, 0.16, wood, M.Wood)
		k.box(s * 3.3, 2.82, -1.4, 0.04, 0.3, 0.04, iron, M.Metal)
	end)
	local lamps = {}
	k.m(function(s)
		table.insert(lamps, k.glow(s * 3.3, 2.42, -1.4, 0.3, 0.42, 0.3, rgb(255, 190, 90), {name = "Flame" .. s}))
		k.box(s * 3.3, 2.68, -1.4, 0.42, 0.08, 0.42, iron, M.Metal)
		k.box(s * 3.3, 2.16, -1.4, 0.42, 0.08, 0.42, iron, M.Metal)
	end)
	k.light(lamps[1], rgb(255, 180, 100), 11, 1)
	k.anim("flicker", lamps, 0, 0, 0, {Speed = 5, ColorA = rgb(200, 110, 40), ColorB = rgb(255, 215, 130)})

	-- THE WATERWHEEL, left front
	local wx, wy, wz = -3.62, 3.2, -6.95
	local wheel = {}
	k.m(function(s)
		table.insert(wheel, k.ring(wx + s * 0.55, wy, wz, 2.0, 0.28, wood, M.Wood, "x", {n = 14, depth = 0.2, name = "WheelRim"}))
	end)
	for i = 0, 5 do
		table.insert(wheel, k.box(wx, wy, wz, 1.25, 4.0, 0.18, light, M.Wood, {rx = i * 30, name = "Spoke"}))
	end
	for i = 0, 11 do
		local a = math.rad(i * 30)
		table.insert(wheel, k.box(wx, wy + math.cos(a) * 2.1, wz + math.sin(a) * 2.1, 1.25, 0.55, 0.1, light, M.WoodPlanks, {rx = -i * 30 + 25, name = "Paddle"}))
	end
	table.insert(wheel, k.cyl(wx, wy, wz, 1.45, 0.7, iron, M.Metal, "x", {name = "Hub"}))
	k.anim("spin", wheel, wx, wy, wz, {Axis = Vector3.xAxis, Speed = -0.6, Run = 2.6, Idle = 1})
	k.cyl(wx + 0.9, wy, wz, 1.6, 0.34, iron, M.Metal, "x", {name = "Axle"})
	-- bearing frame and the catch basin
	k.seg(V(-2.75, 0.2, -5.2), V(-2.75, 3.2, -6.95), 0.3, wood, M.Wood, {box = true, name = "Bearing"})
	k.seg(V(-2.75, 0.2, -8.7), V(-2.75, 3.2, -6.95), 0.3, wood, M.Wood, {box = true, name = "Bearing"})
	k.box(wx, 0.42, wz, 2.2, 0.8, 4.0, wood, M.WoodPlanks, {name = "Basin"})
	k.box(wx, 0.72, wz, 1.9, 0.24, 3.7, water, M.SmoothPlastic, {t = 0.25, name = "BasinWater"})
	k.emit(k.spot(wx, 0.9, wz + 0.4, 1.2, 0.1, 1.6), {tex = "sparkle", c1 = rgb(210, 240, 255), size = {0.35, 0.05}, life = {0.3, 0.6}, speed = {2, 4}, spread = {30, 30}, rate = 16, run = 36, accel = V(0, -14, 0), light = 0.5})

	-- THE TOWER AND TANK, right front
	for _, p in ipairs({{3.0, -8.4}, {4.5, -8.4}, {3.0, -6.2}, {4.5, -6.2}}) do
		k.box(p[1], 4.05, p[2], 0.34, 8.1, 0.34, wood, M.Wood, {name = "TowerLeg"})
	end
	for _, y in ipairs({2.4, 5.2}) do
		k.seg(V(3.0, y - 1.3, -8.4), V(4.5, y + 1.3, -8.4), 0.14, light, M.Wood, {box = true, name = "Brace"})
		k.seg(V(4.5, y - 1.3, -6.2), V(3.0, y + 1.3, -6.2), 0.14, light, M.Wood, {box = true, name = "Brace"})
		k.box(3.75, y, -7.3, 1.8, 0.14, 2.4, light, M.Wood, {name = "TowerRail"})
	end
	k.box(3.75, 8.15, -7.3, 2.0, 0.2, 2.6, wood, M.WoodPlanks)
	k.cyl(3.62, 9.5, -7.3, 2.5, 2.2, light, M.WoodPlanks, "y", {name = "Tank"})
	for _, y in ipairs({8.6, 9.5, 10.4}) do
		k.cyl(3.62, y, -7.3, 0.14, 2.28, iron, M.Metal, "y", {name = "Hoop"})
	end
	k.cyl(3.62, 10.77, -7.3, 0.08, 2.0, water, M.SmoothPlastic, "y", {name = "TankWater"})
	-- a little conical shingled roof over the tank
	k.lathe(3.62, 11.0, -7.3, {{0, 2.25}, {0.35, 1.9}, {0.7, 1.2}, {1.05, 0.5}, {1.3, 0.12}}, bark, M.Wood)

	-- THE FLUME, overhead: tank to wheel, water running along it
	local a, b = V(2.9, 9.0, -7.0), V(-3.5, 7.6, -7.0)
	local dir = (b - a).Unit
	local tilt = math.deg(math.atan2(dir.Y, dir.X))
	k.box((a.X + b.X) / 2, (a.Y + b.Y) / 2 - 0.25, -7.0, (b - a).Magnitude, 0.12, 1.0, wood, M.WoodPlanks, {rz = tilt, name = "Flume"})
	k.m(function(s)
		k.box((a.X + b.X) / 2, (a.Y + b.Y) / 2 - 0.05, -7.0 + s * 0.5, (b - a).Magnitude, 0.45, 0.1, wood, M.WoodPlanks, {rz = tilt, name = "FlumeSide"})
	end)
	k.box((a.X + b.X) / 2, (a.Y + b.Y) / 2 - 0.14, -7.0, (b - a).Magnitude - 0.1, 0.06, 0.85, water, M.SmoothPlastic, {rz = tilt, t = 0.2, name = "FlumeWater"})
	local ripples = {}
	for i = 1, 9 do
		table.insert(ripples, k.box(0, 8, -7, 0.55, 0.05, 0.72, rgb(190, 235, 255), M.SmoothPlastic, {rz = tilt, t = 0.15, name = "R" .. i}))
	end
	k.anim("travel", ripples, 0, 0, 0, {Speed = 3, Run = 2.2, path = {a - V(0, 0.05, 0), b - V(0, 0.05, 0)}})
	-- trestle posts holding up the flume outside the runner's lane are the tower and the wheel frame; these hangers carry the sign
	local fall = k.spot(-3.5, 7.3, -7.0, 0.8, 0.1, 0.5)
	k.emit(fall, {tex = "sparkle", c1 = rgb(190, 230, 255), size = {0.5, 0.2}, alpha = {0.1, 0.8}, life = {0.2, 0.3}, speed = {6, 9}, rate = 30, dir = "Bottom", light = 0.35, spread = {6, 6}})
	-- the sign hangs under the flume and swings
	local sign = k.box(0, 7.6, -7.0, 3.0, 0.72, 0.14, light, M.WoodPlanks, {name = "Sign"})
	k.text(sign, "Front", "TROT ON!", rgb(66, 36, 18), 50)
	k.text(sign, "Back", "TROT ON!", rgb(66, 36, 18), 50)
	local chains = {sign}
	k.m(function(s)
		table.insert(chains, k.box(s * 1.2, 8.05, -7.0, 0.05, 0.3, 0.05, iron, M.Metal, {name = "Chain"}))
	end)
	k.anim("swing", chains, 0, 8.3, -7.0, {Axis = Vector3.xAxis, Amp = 5, Speed = 1.2, Run = 1.8})

	-- THE SAW, right of the console: a spinning blade biting a log
	k.box(3.0, 0.85, -4.6, 1.3, 1.5, 1.4, wood, M.WoodPlanks, {name = "SawBench"})
	k.box(3.0, 1.65, -4.6, 1.5, 0.12, 2.2, light, M.WoodPlanks)
	local blade = {k.cyl(3.0, 2.1, -4.9, 0.05, 1.5, rgb(205, 210, 220), M.Metal, "x", {name = "SawBlade"})}
	for _, p in ipairs(k.ring(3.0, 2.1, -4.9, 0.78, 0.14, rgb(235, 238, 245), M.Metal, "x", {n = 12, depth = 0.05, name = "SawTooth"})) do
		table.insert(blade, p)
	end
	table.insert(blade, k.cyl(3.0, 2.1, -4.9, 0.14, 0.34, iron, M.Metal, "x", {name = "SawHub"}))
	k.anim("spin", blade, 3.0, 2.1, -4.9, {Axis = Vector3.xAxis, Speed = 6, Idle = 0.25, Run = 3})
	local log = {k.cyl(3.0, 2.05, -3.4, 2.0, 0.72, bark, M.Wood, "z", {name = "FeedLog"}), k.cyl(3.0, 2.05, -4.42, 0.04, 0.66, cut, M.Wood, "z")}
	k.anim("slide", log, 3.0, 2.05, -3.4, {Offset = V(0, 0, 0.12), Speed = 1.2, Idle = 0.3, Run = 3})
	k.emit(k.spot(3.0, 1.9, -4.4, 0.2, 0.2, 0.2), {tex = "sparkle", c1 = cut, size = {0.26, 0.08}, life = {0.35, 0.7}, speed = {3, 6}, spread = {38, 38}, rate = 1, run = 26, dir = "Back", accel = V(0, -18, 0), light = 0.1, lit = 1})

	-- the console: a stack of crates with a tally board
	k.box(0, 1.15, -5.9, 3.0, 1.9, 1.5, light, M.WoodPlanks, {name = "Crate"})
	k.box(0, 2.14, -5.9, 3.1, 0.1, 1.6, wood, M.Wood)
	k.m(function(s)
		k.box(s * 1.45, 1.15, -5.15, 0.12, 1.95, 0.08, wood, M.Wood)
		k.box(s * 1.45, 1.15, -6.65, 0.12, 1.95, 0.08, wood, M.Wood)
	end)
	k.seg(V(-1.42, 0.25, -5.13), V(1.42, 2.05, -5.13), 0.1, wood, M.Wood, {box = true})
	local tally = k.box(0, 2.95, -5.5, 2.4, 1.4, 0.12, rgb(50, 54, 52), M.Slate, {rx = 12, name = "Tally"})
	k.text(tally, "Back", "LOGS CUT\n||||  ||||", rgb(240, 235, 215), 50)
	-- behind: a pyramid of logs, a stump with an axe in it, a bucket
	for row, n in ipairs({3, 2, 1}) do
		for i = 1, n do
			local x = 3.3 + (i - (n + 1) / 2) * 0.72
			local y = 0.42 + (row - 1) * 0.62
			k.cyl(x, y, 6.2, 2.2, 0.72, bark, M.Wood, "z", {name = "PileLog"})
			k.cyl(x, y, 7.32, 0.04, 0.66, cut, M.Wood, "z")
		end
	end
	k.cyl(-3.4, 0.55, 6.1, 1.1, 1.5, bark, M.Wood, "y", {name = "Stump"})
	k.cyl(-3.4, 1.11, 6.1, 0.04, 1.4, cut, M.Wood, "y")
	k.seg(V(-3.3, 1.1, 6.1), V(-2.6, 2.2, 6.7), 0.12, light, M.Wood, {name = "AxeHandle"})
	k.box(-3.42, 1.25, 6.0, 0.08, 0.5, 0.6, rgb(190, 195, 205), M.Metal, {rx = 40, name = "AxeHead"})
	k.cyl(-1.7, 0.42, 6.6, 0.8, 0.8, light, M.WoodPlanks, "y", {name = "Bucket"})
	k.cyl(-1.7, 0.74, 6.6, 0.05, 0.7, water, M.SmoothPlastic, "y")
	k.light(k.spot(0, 7.0, -7.0), rgb(180, 220, 255), 8, 0.4)
end}

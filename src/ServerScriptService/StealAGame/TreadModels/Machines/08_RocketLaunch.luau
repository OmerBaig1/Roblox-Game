-- T-minus ten. A real multi-stage rocket with boosters stands at the right on a flame trench, frost venting from its side;
-- a red steel service tower beside it with a moving elevator and an access arm over the runner. Mission control faces
-- the runner. On the throttle: the engines light, the trench fills with fire and smoke and the whole stack trembles.
return {Name = "Rocket Launch", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9120610374", 0.5, 0.45)
	local pad, hazard, white, red, iron, dark, blue, frost = rgb(112, 112, 122), rgb(250, 200, 30), rgb(244, 244, 248), rgb(222, 44, 44), rgb(66, 66, 72), rgb(24, 26, 34), rgb(40, 96, 200), rgb(220, 240, 255)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, pad, M.Concrete, {name = "LaunchPad"})
	k.deck(5, rgb(84, 84, 94), M.Concrete)
	k.belt({rgb(36, 36, 42), hazard}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.box(s * 2.72, 0.42, 0, 0.44, 0.56, 10.2, dark, M.Metal, {name = "SideRail"})
		-- chevron lights running toward the rocket
		local chev = {}
		for i = 0, 9 do
			table.insert(chev, k.glow(s * 2.72, 0.72, 4.5 - i, 0.28, 0.03, 0.42, hazard, {name = "Chev" .. i}))
		end
		k.anim("pulse", chev, 0, 0, 0, {Speed = 5, Stagger = -0.7, Sharp = 3, ColorA = rgb(60, 50, 10), ColorB = rgb(255, 215, 50), Idle = 0.4, Run = 2.2})
		-- service cables and low fuel lines beside the runner
		k.cyl(s * 3.6, 0.3, 0, 8.6, 0.34, rgb(220, 224, 232), M.Metal, "z", {name = "FuelLine"})
		k.cyl(s * 3.95, 0.25, 0, 8.6, 0.22, red, M.Metal, "z", {name = "FuelLine"})
		for _, z in ipairs({-3.5, 0, 3.5}) do
			k.box(s * 3.75, 0.45, z, 1.1, 0.2, 0.34, iron, M.Metal, {name = "PipeClamp"})
		end
	end)
	-- THE FLAME TRENCH under the rocket: a grate that glows from below
	local rx, rz = 3.15, -6.9
	local rocket = {}
	local function add(p)
		if typeof(p) == "Instance" then
			table.insert(rocket, p)
		else
			for _, q in ipairs(p) do
				add(q)
			end
		end
		return p
	end
	k.box(rx, 0.12, rz, 3.1, 0.18, 4.6, dark, M.DiamondPlate, {name = "Trench"})
	local trenchGlow = k.box(rx, 0.24, rz, 2.2, 0.04, 3.8, rgb(40, 20, 12), M.Neon, {name = "TrenchGlow"})
	k.anim("pulse", trenchGlow, 0, 0, 0, {Speed = 7, Idle = 0, Run = 1, Sharp = 1, ColorA = rgb(50, 26, 14), ColorB = rgb(255, 130, 30)})
	for i = 0, 5 do
		k.box(rx, 0.28, rz - 1.9 + i * 0.76, 2.4, 0.08, 0.1, iron, M.Metal, {name = "Grate"})
	end
	-- hold-down clamps, and the stack on them
	for _, off in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
		k.seg(V(rx + off[1] * 1.3, 0.3, rz + off[2] * 1.3), V(rx + off[1] * 0.72, 1.7, rz + off[2] * 0.72), 0.24, hazard, M.Metal, {box = true, name = "HoldDown"})
	end
	-- THE ROCKET: a stack of stages tapering to a red nose, with a roll pattern and windows
	add(k.cyl(rx, 4.6, rz, 5.4, 1.8, white, M.SmoothPlastic, "y", {name = "FirstStage"}))
	for _, y in ipairs({3.1, 5.9}) do
		add(k.cyl(rx, y, rz, 0.5, 1.84, BLACK, M.SmoothPlastic, "y", {name = "RollBand"}))
	end
	for _, q in ipairs({{0.5, 0.5}, {-0.5, -0.5}}) do
		add(k.box(rx + q[1], 4.55, rz + q[2], 0.72, 1.2, 0.72, BLACK, M.SmoothPlastic, {name = "RollPattern"}))
	end
	add(k.cyl(rx, 7.34, rz, 0.14, 1.86, red, M.SmoothPlastic, "y", {name = "StageRing"}))
	add(k.lathe(rx, 7.4, rz, {{0, 1.75}, {0.5, 1.4}, {1.8, 1.32}}, white, M.SmoothPlastic, {name = "SecondStage"}))
	add(k.cyl(rx, 9.2, rz, 0.12, 1.4, blue, M.SmoothPlastic, "y", {name = "StageRing"}))
	-- the capsule, with a lit window and an escape tower at the very top
	add(k.lathe(rx, 9.25, rz, {{0, 1.32}, {0.5, 1.15}, {1.0, 0.82}, {1.5, 0.45}, {1.85, 0.2}}, function(f)
		return f > 0.75 and red or white
	end, M.SmoothPlastic, {name = "Capsule"}))
	add(k.cyl(rx, 11.5, rz, 0.8, 0.08, iron, M.Metal, "y", {name = "EscapeTower"}))
	add(k.ball(rx, 11.95, rz, 0.2, red, M.Neon, {name = "NoseBeacon"}))
	for _, p in ipairs({{0.5, 9.75, 0.42}, {-0.5, 9.75, 0.42}}) do
		add(k.glow(rx + p[1], p[2], rz + p[3], 0.22, 0.22, 0.04, rgb(120, 220, 255), {name = "Window"}))
	end
	local wordmark = add(k.box(rx - 0.92, 4.7, rz, 0.04, 2.9, 0.42, red, M.SmoothPlastic, {name = "Wordmark"}))
	k.text(wordmark, "Left", "U\nP", WHITE, 40)
	-- fins, boosters and engines
	for _, f in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
		local bx, bz = rx + f[1] * 1.28, rz + f[2] * 1.28
		-- side boosters only where they stay on the pad and clear of the runner
		add(k.wedge(rx + f[1] * 1.15, 2.6, rz + f[2] * 1.15, 0.12, 1.5, 0.75, red, M.SmoothPlastic, {ry = f[1] > 0 and -90 or f[1] < 0 and 90 or f[2] > 0 and 180 or 0, name = "Fin"}))
	end
	for _, z in ipairs({-1.3, 1.3}) do
		add(k.lathe(rx, 1.9, rz + z, {{0, 0.72}, {2.8, 0.72}, {3.4, 0.5}, {3.8, 0.12}}, white, M.SmoothPlastic, {name = "Booster"}))
		add(k.cyl(rx, 3.3, rz + z, 0.1, 0.76, red, M.SmoothPlastic, "y", {name = "BoosterBand"}))
		add(k.cyl(rx, 1.75, rz + z, 0.32, 0.55, iron, M.Metal, "y", {name = "BoosterNozzle"}))
	end
	add(k.lathe(rx, 1.15, rz, {{0, 1.15}, {0.4, 0.95}, {0.8, 0.7}}, iron, M.Metal, {name = "EngineBell"}))
	k.anim("slide", rocket, rx, 4, rz, {Offset = V(0.022, 0.02, 0.015), Speed = 38, Idle = 0, Run = 1})
	-- FIRE: flames out of the engine bell and booster nozzles (length follows the throttle), and rolling smoke
	local flames = {}
	for i, z in ipairs({0, -1.3, 1.3}) do
		table.insert(flames, k.cyl(rx, 0.82, rz + z, 1.0, 0.32 + (i == 1 and 0.34 or 0), rgb(255, 200, 80), M.Neon, "y", {t = 0.1, name = "Flame" .. i, shadow = false}))
	end
	k.anim("gauge", flames, 0, 0, 0, {GAxis = "X", FromEnd = -1, Speed = 24, Amp = 0.35, Stagger = 1.7, Idle = 0, Run = 1})
	k.emit(k.spot(rx, 0.5, rz, 1.5, 0.1, 2.6), {tex = "fire", c1 = rgb(255, 225, 130), c2 = rgb(255, 90, 20), size = {1.2, 0.3}, alpha = {0.1, 1}, life = {0.18, 0.4}, speed = {2, 5}, rate = 0, run = 60, dir = "Top", spread = {25, 25}, light = 1})
	k.emit(k.spot(rx, 0.6, rz - 2.3, 2.2, 0.2, 0.2), {tex = "smoke", c1 = rgb(240, 240, 240), c2 = rgb(170, 170, 170), size = {1.2, 4.5}, alpha = {0.25, 1}, life = {1, 1.8}, speed = {5, 9}, rate = 0, run = 16, dir = "Front", spread = {30, 10}, light = 0, lit = 1, accel = V(0, 1.5, 0)})
	k.emit(k.spot(rx, 0.6, rz + 2.3, 2.2, 0.2, 0.2), {tex = "smoke", c1 = rgb(240, 240, 240), c2 = rgb(170, 170, 170), size = {1.0, 3.0}, alpha = {0.35, 1}, life = {0.6, 1.1}, speed = {3, 5}, rate = 0, run = 6, dir = "Right", spread = {30, 10}, light = 0, lit = 1, accel = V(0, 1.5, 0)})
	-- frost venting off the side of the rocket before launch, thinning when the engines are lit
	k.emit(k.spot(rx - 0.92, 6.8, rz, 0.1, 0.2, 0.5), {tex = "smoke", c1 = frost, size = {0.5, 2.0}, alpha = {0.35, 1}, life = {0.8, 1.4}, speed = {1.5, 3}, rate = 6, run = 2, dir = "Left", spread = {12, 12}, light = 0.3, lit = 0.5, accel = V(0, -1.4, 0)})

	-- THE SERVICE TOWER, left: a red lattice with decks, an elevator that rides up and down, and a floodlight
	local tx, tz = -3.45, -7.1
	for _, p in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
		k.box(tx + p[1] * 0.95, 5.5, tz + p[2] * 1.3, 0.22, 11.0, 0.22, red, M.Metal, {name = "TowerLeg"})
	end
	for i = 0, 5 do
		local y = 1.2 + i * 1.8
		k.box(tx, y, tz, 2.24, 0.12, 2.84, iron, M.DiamondPlate, {name = "TowerDeck"})
		k.seg(V(tx - 0.95, y, tz - 1.3), V(tx + 0.95, y + 1.8, tz - 1.3), 0.1, red, M.Metal, {box = true, name = "Brace"})
		k.seg(V(tx + 0.95, y, tz + 1.3), V(tx - 0.95, y + 1.8, tz + 1.3), 0.1, red, M.Metal, {box = true, name = "Brace"})
		k.seg(V(tx - 0.95, y, tz + 1.3), V(tx - 0.95, y + 1.8, tz - 1.3), 0.1, red, M.Metal, {box = true, name = "Brace"})
	end
	local lift = {k.box(tx, 0, tz, 1.3, 1.5, 1.3, rgb(250, 250, 250), M.Metal, {name = "Elevator"}), k.glow(tx, 0.25, tz + 0.66, 0.9, 0.5, 0.02, rgb(150, 230, 255), {name = "ElevatorWindow"})}
	lift[1].CFrame = lift[1].CFrame + lift[1].CFrame.UpVector * 6
	lift[2].CFrame = lift[2].CFrame + lift[2].CFrame.UpVector * 6
	k.anim("slide", lift, tx, 6, tz, {Offset = V(0, 3.9, 0), Speed = 0.35, Run = 1.6})
	k.box(tx, 11.1, tz, 2.4, 0.2, 3.0, iron, M.Metal, {name = "TowerTop"})
	k.cyl(tx, 11.7, tz, 1.2, 0.09, iron, M.Metal, "y", {name = "LightningRod"})
	local top = k.ball(tx, 12.2, tz, 0.26, red, M.Neon, {name = "TowerBeacon"})
	k.anim("pulse", top, 0, 0, 0, {Speed = 2.5, Sharp = 4, ColorA = rgb(60, 10, 10), ColorB = rgb(255, 40, 40)})
	local flood = k.glow(tx + 0.8, 10.6, tz + 1.42, 0.6, 0.36, 0.04, rgb(255, 245, 210), {name = "Floodlight"})
	k.light(flood, rgb(255, 240, 210), 13, 0.8)
	-- THE ACCESS ARM over the runner to the capsule, and a swinging umbilical
	local a, b = V(tx + 0.95, 9.45, -7.0), V(rx - 0.7, 9.45, -7.0)
	k.box((a.X + b.X) / 2, 9.45, -7.0, b.X - a.X, 0.34, 0.9, iron, M.DiamondPlate, {name = "AccessArm"})
	k.m(function(s)
		k.box((a.X + b.X) / 2, 9.85, -7.0 + s * 0.45, b.X - a.X, 0.08, 0.08, red, M.Metal, {name = "ArmRail"})
	end)
	for x = a.X + 0.7, b.X - 0.2, 1.2 do
		k.m(function(s)
			k.box(x, 9.65, -7.0 + s * 0.45, 0.06, 0.4, 0.06, red, M.Metal)
		end)
	end
	k.box(b.X, 9.45, -7.0, 0.8, 1.05, 1.05, white, M.Metal, {name = "WhiteRoom"})
	local gantrySign = k.box(0, 8.7, -7.0, 3.6, 0.75, 0.1, dark, M.SmoothPlastic, {name = "ArmSign"})
	k.text(gantrySign, "Front", "GO FOR LAUNCH", hazard, 50)
	k.text(gantrySign, "Back", "GO FOR LAUNCH", hazard, 50)
	k.m(function(s)
		k.box(s * 1.5, 9.1, -7.0, 0.06, 0.4, 0.06, iron, M.Metal)
	end)

	-- MISSION CONTROL facing the runner: three screens and the launch button
	k.box(0, 1.05, -5.75, 3.2, 1.7, 1.2, rgb(48, 52, 62), M.Metal, {name = "ControlDesk"})
	k.wedge(0, 2.12, -5.75, 3.2, 0.44, 1.2, rgb(70, 74, 84), M.Metal, {ry = 180, name = "ControlTop"})
	k.box(0, 3.15, -6.1, 3.2, 1.4, 0.2, dark, M.Metal, {name = "ScreenWall"})
	local cols = {rgb(14, 40, 26), rgb(10, 20, 44), rgb(14, 40, 26)}
	for i, label in ipairs({"FUEL\nOK", "T-10", "PAD\nGO"}) do
		local x = (i - 2) * 1.05
		local screen = k.glow(x, 3.15, -5.98, 0.96, 1.2, 0.03, cols[i], {name = "MissionScreen"})
		k.text(screen, "Back", label, i == 2 and rgb(255, 225, 90) or rgb(120, 255, 140), 60)
	end
	local meter = {}
	for i = 0, 5 do
		table.insert(meter, k.glow(-1.2 + i * 0.48, 2.28, -5.3, 0.3, 0.24, 0.3, rgb(120, 255, 150), {name = "Meter" .. i}))
	end
	k.anim("gauge", meter, 0, 0, 0, {Speed = 5, Amp = 0.6, Stagger = 1.1, Run = 2})
	local go = k.cyl(1.2, 2.65, -5.25, 0.2, 0.46, rgb(255, 40, 40), M.Neon, "y", {name = "LaunchButton"})
	k.anim("pulse", go, 0, 0, 0, {Speed = 4, Sharp = 2, ColorA = rgb(120, 15, 15), ColorB = rgb(255, 50, 50)})
	k.ring(1.2, 2.6, -5.25, 0.3, 0.06, hazard, M.Metal, "y", {n = 8, depth = 0.12, name = "ButtonGuard"})
	-- BEHIND: a radar dish that sweeps, spherical fuel tanks with frost
	local dish = {k.cyl(-3.1, 1.4, 6.15, 0.08, 1.9, white, M.Metal, "z", {rx = 28, name = "Dish"}), k.ring(-3.1, 1.4, 6.15, 0.95, 0.1, iron, M.Metal, "z", {n = 12, depth = 0.1, rx = 28, name = "DishRim"}), k.seg(V(-3.1, 1.4, 6.15), V(-3.1, 1.85, 5.5), 0.06, iron, M.Metal, {name = "DishFeed"})}
	k.anim("spin", dish, -3.1, 1.2, 6.2, {Axis = Vector3.yAxis, Speed = 0.9, Run = 2})
	k.cyl(-3.1, 0.55, 6.2, 1.1, 0.32, iron, M.Metal, "y", {name = "DishPost"})
	k.cyl(-3.1, 0.12, 6.2, 0.16, 1.3, dark, M.Metal, "y")
	for _, x in ipairs({2.2, 3.7}) do
		k.ball(x, 0.85, 6.3, 1.45, frost, M.SmoothPlastic, {name = "FuelTank"})
		k.cyl(x, 0.85, 6.3, 0.12, 1.5, blue, M.SmoothPlastic, "y", {name = "TankBand"})
		k.box(x, 0.12, 6.3, 1.2, 0.16, 0.9, iron, M.Metal)
	end
	k.seg(V(2.95, 0.85, 6.3), V(3.0, 0.85, 6.3), 0.2, iron, M.Metal)
end}

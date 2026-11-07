-- A Formula racing car at full scale for a runner in the cockpit. Layered front wing with endplates, a long low nose on
-- pillars, wishbones out to wide slicks with glowing brakes, sculpted sidepods with intakes, shark-fin engine cover,
-- rear wing with a working flap, a diffuser and a rain light. Exhausts spit flame and the wheels spin up on the throttle.
-- It stands on a starting grid under a five-light gantry.
return {Name = "Pit Lane Racer", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9112890980", 0.2, 1.7)
	local red, deep, carbon, silver, black, yellow, cyan = rgb(222, 22, 38), rgb(140, 12, 26), rgb(28, 28, 32), rgb(206, 212, 222), rgb(14, 14, 16), rgb(255, 214, 40), rgb(70, 225, 255)
	-- the grid: asphalt, a white box and kerbs
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, rgb(58, 58, 62), M.Asphalt, {name = "Asphalt"})
	k.m(function(s)
		for i = 0, 7 do
			k.box(s * 4.2, 0.1, -8.35 + i * 2.1, 0.5, 0.05, 2.1, i % 2 == 0 and rgb(225, 40, 40) or WHITE, M.SmoothPlastic, {name = "Kerb"})
		end
	end)
	k.deck(4.7, carbon, M.SmoothPlastic)
	k.belt({rgb(38, 38, 42), rgb(54, 54, 60)}, M.Asphalt, 4.2)
	-- the floor of the car
	k.box(0, 0.3, 0.5, 6.4, 0.14, 11, black, M.SmoothPlastic, {name = "Floor"})
	k.m(function(s)
		k.box(s * 3.15, 0.25, 0.5, 0.1, 0.3, 10.6, yellow, M.SmoothPlastic, {name = "FloorEdge"})
		-- monocoque wall beside the runner
		k.box(s * 2.46, 0.95, -1.2, 0.3, 1.2, 7.0, red, M.SmoothPlastic, {name = "Tub"})
		k.box(s * 2.46, 1.6, -1.2, 0.34, 0.1, 7.0, black, M.SmoothPlastic, {name = "TubEdge"})
		-- SIDEPOD: a smooth teardrop with an intake at the front and an undercut below
		k.ell(s * 3.1, 1.25, 0.4, 1.5, 1.75, 7.8, red, M.SmoothPlastic, {name = "Sidepod"})
		k.ell(s * 3.1, 1.55, 0.6, 1.32, 1.3, 7.2, deep, M.SmoothPlastic, {name = "PodShoulder"})
		k.ell(s * 3.14, 1.72, 0.3, 0.95, 0.72, 6.2, WHITE, M.SmoothPlastic, {name = "PodStripe"})
		k.box(s * 3.1, 1.35, -3.3, 1.45, 0.95, 0.5, black, M.SmoothPlastic, {name = "Intake"})
		k.box(s * 3.1, 1.86, -3.45, 1.55, 0.09, 0.42, carbon, M.SmoothPlastic, {name = "IntakeLip"})
		for i = 0, 2 do
			k.box(s * 3.1, 1.08 + i * 0.26, -3.58, 1.25, 0.04, 0.05, rgb(90, 90, 96), M.Metal, {name = "IntakeVane"})
		end
		-- a sponsor panel on each pod
		local panel = k.box(s * 3.84, 1.3, 0.6, 0.04, 0.55, 2.6, WHITE, M.SmoothPlastic, {name = "Sponsor"})
		k.text(panel, s < 0 and "Left" or "Right", "TURBO", red, 50)
		-- bargeboard and cooling louvres
		k.box(s * 2.85, 0.75, -4.1, 0.08, 0.9, 1.2, carbon, M.SmoothPlastic, {ry = s * 14, name = "Bargeboard"})
		for i = 0, 3 do
			k.box(s * 3.18, 2.08 - i * 0.03, 1.6 + i * 0.32, 0.8, 0.04, 0.16, black, M.SmoothPlastic, {rx = 25, name = "Louvre"})
		end

		-- FRONT WHEEL with a glowing brake disc, on upper and lower wishbones and a push rod
		local fx, fy, fz = s * 3.92, 1.15, -6.25
		local wheel = k.wheel(fx, fy, fz, 2.3, 1.45, black, rgb(40, 40, 44), {spokes = 5, spoke = silver, hub = red})
		table.insert(wheel, k.ring(fx + s * 0.74, fy, fz, 0.84, 0.09, yellow, M.SmoothPlastic, "x", {n = 14, depth = 0.03, name = "SidewallLine"}))
		k.anim("spin", wheel, fx, fy, fz, {Axis = Vector3.xAxis, Speed = -14, Idle = 0, Run = 1})
		local disc = k.cyl(fx - s * 0.74, fy, fz, 0.06, 1.15, rgb(120, 40, 20), M.Neon, "x", {name = "BrakeDisc"})
		k.anim("pulse", disc, 0, 0, 0, {Speed = 2, Idle = 0.3, Run = 2, ColorA = rgb(60, 50, 50), ColorB = rgb(255, 110, 30)})
		for _, z in ipairs({-6.95, -5.55}) do
			k.seg(V(s * 0.55, 1.55, z), V(fx - s * 0.75, fy + 0.45, fz), 0.11, carbon, M.Metal, {name = "UpperWishbone"})
			k.seg(V(s * 0.55, 0.85, z), V(fx - s * 0.75, fy - 0.45, fz), 0.11, carbon, M.Metal, {name = "LowerWishbone"})
		end
		k.seg(V(s * 0.6, 1.75, -6.2), V(fx - s * 0.75, fy - 0.4, fz), 0.07, silver, M.Metal, {name = "PushRod"})

		-- REAR WHEEL, wider
		local rx, ry, rz = s * 3.88, 1.18, 5.15
		local rear = k.wheel(rx, ry, rz, 2.36, 1.55, black, rgb(40, 40, 44), {spokes = 5, spoke = silver, hub = red})
		table.insert(rear, k.ring(rx + s * 0.79, ry, rz, 0.87, 0.09, yellow, M.SmoothPlastic, "x", {n = 14, depth = 0.03, name = "SidewallLine"}))
		k.anim("spin", rear, rx, ry, rz, {Axis = Vector3.xAxis, Speed = -14, Idle = 0, Run = 1})
		k.seg(V(s * 1.5, 1.5, 5.4), V(rx - s * 0.8, ry + 0.4, rz), 0.11, carbon, M.Metal, {name = "RearSuspension"})
		k.seg(V(s * 1.5, 0.75, 4.6), V(rx - s * 0.8, ry - 0.4, rz), 0.11, carbon, M.Metal, {name = "RearSuspension"})
		k.seg(V(s * 1.5, 0.75, 5.9), V(rx - s * 0.8, ry - 0.4, rz), 0.11, carbon, M.Metal, {name = "RearSuspension"})

		-- FRONT WING: three stepped elements between endplates
		k.box(s * 4.5, 0.6, -8.7, 0.1, 1.05, 1.35, red, M.SmoothPlastic, {name = "Endplate"})
		k.box(s * 4.5, 1.1, -8.7, 0.12, 0.08, 1.35, WHITE, M.SmoothPlastic)
		-- nose pillars
		k.seg(V(s * 0.3, 1.1, -8.3), V(s * 0.45, 0.42, -8.65), 0.1, carbon, M.SmoothPlastic, {box = true, name = "NosePillar"})
		-- ground sparks and speed streaks from the back of the car, running only
		k.emit(k.spot(rx, 0.15, 6.2, 1.4, 0.1, 0.2), {tex = "sparks", c1 = rgb(255, 220, 130), c2 = rgb(255, 110, 40), size = {0.35, 0.05}, life = {0.2, 0.45}, speed = {6, 12}, rate = 0, run = 12, dir = "Back", spread = {22, 14}, accel = V(0, -20, 0), light = 0.9})
		-- rear wing endplates
		k.box(s * 3.2, 1.45, 7.0, 0.1, 1.86, 1.1, red, M.SmoothPlastic, {name = "RearEndplate"})
		local plate = k.box(s * 3.26, 1.55, 7.0, 0.03, 0.8, 0.9, WHITE, M.SmoothPlastic, {name = "EndplateLogo"})
		k.text(plate, s < 0 and "Left" or "Right", "1", red, 50)
		-- pylons up from the gearbox
		k.seg(V(s * 0.55, 0.9, 6.3), V(s * 0.55, 2.05, 7.0), 0.1, carbon, M.Metal, {box = true, name = "WingPylon"})
		-- diffuser strakes
		for i = 0, 2 do
			k.box(s * (0.75 + i * 0.75), 0.42, 6.65, 0.05, 0.42, 1.2, carbon, M.SmoothPlastic, {rx = 12, name = "Strake"})
		end
	end)
	for i, e in ipairs({{-8.4, 0.34, 0.75, carbon, 4}, {-8.95, 0.48, 0.5, red, 14}, {-9.2, 0.66, 0.34, WHITE, 28}}) do
		k.box(0, e[2], e[1], 8.9, 0.07, e[3], e[4], M.SmoothPlastic, {rx = e[5], name = "FrontWing" .. i})
	end
	-- THE NOSE: long, flat and tapering down to the wing, on a raised chassis
	k.wedge(0, 1.22, -6.9, 1.5, 1.0, 3.9, red, M.SmoothPlastic, {name = "Nose"})
	k.wedge(0, 0.56, -6.9, 1.5, 0.34, 3.9, deep, M.SmoothPlastic, {rz = 180, name = "NoseBelly"})
	k.wedge(0, 1.25, -6.9, 0.56, 1.04, 3.92, WHITE, M.SmoothPlastic, {name = "NoseStripe"})
	k.m(function(s)
		k.corner(s * 0.97, 1.0, -5.9, 0.44, 0.9, 1.9, deep, M.SmoothPlastic, {ry = s > 0 and 180 or 90, name = "NoseShoulder"})
	end)
	k.ell(0, 0.72, -8.88, 1.45, 0.42, 0.95, red, M.SmoothPlastic, {name = "NoseTip"})
	k.box(0, 1.25, -4.95, 3.5, 1.55, 0.75, red, M.SmoothPlastic, {name = "Bulkhead"})
	k.box(0, 2.0, -4.95, 2.4, 0.05, 0.8, WHITE, M.SmoothPlastic, {name = "BulkheadStripe"})
	local numberTop = k.box(0, 1.28, -6.3, 0.6, 0.02, 0.6, WHITE, M.SmoothPlastic, {rx = 14, name = "Number"})
	k.text(numberTop, "Top", "1", red, 80)
	-- THE COCKPIT FACE: a real steering wheel with shift lights, facing the runner
	k.box(0, 2.25, -4.9, 2.7, 0.5, 0.6, carbon, M.SmoothPlastic, {name = "Dash"})
	k.cyl(0, 2.65, -4.85, 0.5, 0.2, silver, M.Metal, "z", {name = "SteeringColumn"})
	local sw = {k.box(0, 3.1, -4.62, 1.2, 0.72, 0.14, carbon, M.SmoothPlastic, {name = "Wheel"})}
	k.m(function(s)
		table.insert(sw, k.box(s * 0.68, 3.05, -4.62, 0.24, 0.95, 0.2, black, M.Rubber, {name = "WheelGrip"}))
	end)
	local wscreen = k.glow(0, 3.14, -4.54, 0.56, 0.34, 0.02, rgb(10, 30, 45), {name = "WheelScreen"})
	k.text(wscreen, "Back", "P1", cyan, 100)
	table.insert(sw, wscreen)
	k.anim("swing", sw, 0, 2.98, -4.62, {Axis = Vector3.zAxis, Amp = 7, Speed = 1.2, Idle = 0.2, Run = 2.2})
	local shift = {}
	for i = 0, 6 do
		table.insert(shift, k.glow(-0.42 + i * 0.14, 3.42, -4.53, 0.1, 0.07, 0.02, i < 3 and rgb(70, 255, 110) or i < 5 and yellow or rgb(255, 50, 50), {name = "Shift" .. i}))
	end
	k.anim("pulse", shift, 0, 0, 0, {Speed = 6, Stagger = -0.5, Sharp = 2, TransA = 0.8, TransB = 0, Idle = 0.15, Run = 1.6})
	-- ENGINE COVER and shark fin, low enough for the camera behind; it trembles with the engine
	local engine = {
		k.ell(0, 1.28, 6.05, 1.5, 1.95, 3.1, red, M.SmoothPlastic, {name = "EngineCover"}),
		k.ell(0, 1.3, 6.05, 0.5, 1.99, 3.0, WHITE, M.SmoothPlastic, {name = "CoverStripe"}),
		k.wedge(0, 1.85, 5.95, 0.08, 1.0, 2.5, deep, M.SmoothPlastic, {name = "SharkFin"}),
		k.cyl(0, 1.25, 7.2, 0.5, 0.52, carbon, M.Metal, "z", {name = "ExhaustPipe"}),
		k.cyl(0, 1.25, 7.46, 0.04, 0.34, rgb(255, 130, 30), M.Neon, "z", {name = "ExhaustCore"}),
	}
	k.anim("slide", engine, 0, 1.3, 5.7, {Offset = V(0.012, 0.02, 0), Speed = 42, Idle = 0.55, Run = 1.25})
	-- exhaust flame: blue at the root, orange at the tip, longer on the throttle
	local flame = k.cyl(0, 1.25, 7.5, 0.2, 0.26, rgb(120, 170, 255), M.Neon, "z", {t = 0.1, name = "ExhaustFlame", shadow = false})
	k.anim("gauge", flame, 0, 0, 0, {GAxis = "X", FromEnd = -1, Speed = 22, Amp = 0.7, Idle = 0.3, Run = 1})
	k.emit(k.spot(0, 1.25, 7.5, 0.24, 0.24, 0.1), {tex = "fire", c1 = rgb(255, 210, 110), c2 = rgb(255, 80, 20), size = {0.42, 0.08}, alpha = {0.05, 1}, life = {0.12, 0.24}, speed = {5, 9}, rate = 4, run = 45, dir = "Back", spread = {7, 7}, light = 1})
	k.emit(k.spot(0, 1.25, 7.55, 0.24, 0.24, 0.1), {tex = "smoke", c1 = rgb(140, 140, 148), size = {0.5, 1.8}, alpha = {0.6, 1}, life = {0.5, 0.9}, speed = {2, 4}, rate = 0, run = 7, dir = "Back", spread = {15, 15}, light = 0, lit = 1})
	-- REAR WING: a fixed plane and a flap that opens and closes
	k.box(0, 2.05, 6.9, 6.3, 0.09, 0.82, carbon, M.SmoothPlastic, {name = "RearWingPlane"})
	k.box(0, 2.0, 6.5, 6.3, 0.05, 0.1, red, M.SmoothPlastic)
	local flap = {k.box(0, 2.27, 7.2, 6.3, 0.07, 0.5, red, M.SmoothPlastic, {rx = -22, name = "DRSFlap"})}
	k.anim("swing", flap, 0, 2.2, 7.0, {Axis = Vector3.xAxis, Amp = 16, Speed = 0.7, Idle = 0, Run = 3})
	-- the rain light, blinking
	local rain = k.glow(0, 0.72, 7.4, 0.62, 0.18, 0.06, rgb(255, 30, 40), {name = "RainLight"})
	k.anim("pulse", rain, 0, 0, 0, {Speed = 7, Sharp = 4, ColorA = rgb(70, 10, 10), ColorB = rgb(255, 40, 50), Idle = 0.4, Run = 1.5})
	k.light(rain, rgb(255, 60, 60), 8, 0.7)

	-- THE GANTRY overhead: five red lights that light in order, then go out, and two track-side towers
	k.m(function(s)
		k.box(s * 4.5, 4.9, -9.05, 0.2, 9.8, 0.2, rgb(70, 72, 78), M.Metal, {name = "GantryLeg"})
		k.box(s * 4.5, 0.2, -9.05, 0.5, 0.2, 0.5, rgb(50, 50, 56), M.Metal)
	end)
	k.box(0, 9.7, -8.85, 9.0, 0.9, 0.6, carbon, M.Metal, {name = "GantryBeam"})
	local beamText = k.box(0, 10.6, -8.85, 6.0, 0.85, 0.12, WHITE, M.SmoothPlastic, {name = "GantrySign"})
	k.text(beamText, "Front", "START LINE", black, 40)
	k.text(beamText, "Back", "START LINE", black, 40)
	local fives = {}
	for i = 1, 5 do
		k.box(-3.2 + (i - 1) * 1.6, 9.7, -8.52, 0.72, 0.72, 0.05, black, M.SmoothPlastic, {name = "LightHousing"})
		table.insert(fives, k.ball(-3.2 + (i - 1) * 1.6, 9.7, -8.46, 0.5, rgb(255, 30, 30), M.Neon, {name = "StartLight" .. i}))
		k.ball(-3.2 + (i - 1) * 1.6, 9.7, -9.15, 0.42, rgb(90, 20, 20), M.SmoothPlastic, {name = "StartLightBack"})
	end
	k.anim("pulse", fives, 0, 0, 0, {Speed = 1.1, Stagger = -0.55, Sharp = 3, ColorA = rgb(70, 10, 10), ColorB = rgb(255, 30, 30), Run = 2.5})
	k.light(k.spot(0, 9.6, -8.3), rgb(255, 60, 60), 12, 0.6)
	-- a chequered flag, waving from the gantry's leg, above the runner's head
	local flag = {}
	for col = 0, 4 do
		for row = 0, 3 do
			table.insert(flag, k.box(-4.2 + col * 0.4, 7.45 + row * 0.4, -8.95, 0.4, 0.4, 0.05, (col + row) % 2 == 0 and WHITE or black, M.Fabric, {name = "Flag"}))
		end
	end
	k.anim("swing", flag, -4.4, 8.2, -8.95, {Axis = Vector3.yAxis, Amp = 20, Speed = 3.2, Idle = 0.5, Run = 1.5})
	-- pit boards and tyres, back corners
	for i = 0, 3 do
		k.cyl(-1.6, 0.24 + i * 0.44, 6.5, 0.42, 1.3, black, M.Rubber, "y", {name = "TyreStack"})
	end
	k.cyl(-1.6, 1.97, 6.5, 0.04, 1.34, yellow, M.SmoothPlastic, "y")
	-- speed lines streaming off the car while running
	k.emit(k.spot(0, 2.4, 7.3, 7, 1.8, 0.1), {tex = "glow", c1 = WHITE, size = {0.12, 0.02}, alpha = {0.5, 1}, life = {0.18, 0.35}, speed = {28, 44}, rate = 0, run = 18, dir = "Back", spread = {0, 0}, light = 1})
end}

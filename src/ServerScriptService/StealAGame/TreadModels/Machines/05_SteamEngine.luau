-- A locomotive with the runner on its footplate. The boiler runs out in front to a brass-banded smokebox and a cowcatcher;
-- twin stacks pour smoke. Great driving wheels turn with real coupling rods and pistons. Gauges, a firebox and levers on
-- the backhead face the runner, a coal tender glows behind, and the whole thing sits on a stretch of track.
return {Name = "Steam Engine", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9112760393", 0.3, 0.8)
	local black, boilerC, red, brass, copper, steel, coal = rgb(34, 34, 40), rgb(32, 92, 66), rgb(180, 30, 30), rgb(222, 172, 70), rgb(186, 110, 60), rgb(150, 155, 165), rgb(26, 24, 26)
	k.box(0, 0.05, -0.8, 8.8, 0.1, 15.9, rgb(94, 84, 74), M.Ground, {name = "Ballast"})
	for z = -8.6, 7, 1.3 do
		k.box(0, 0.12, z, 8.6, 0.12, 0.55, rgb(70, 48, 34), M.Wood, {name = "Sleeper"})
	end
	k.deck(4.6, black, M.DiamondPlate)
	k.belt({rgb(58, 48, 42), rgb(82, 66, 48)}, M.DiamondPlate, 4.1)
	k.m(function(s)
		k.box(s * 3.65, 0.22, -0.8, 0.26, 0.2, 15.8, steel, M.Metal, {name = "Rail"})
		-- the running board and valance over the wheels
		k.box(s * 2.55, 0.55, 0, 0.5, 0.9, 10.2, red, M.SmoothPlastic, {name = "Frame"})
		k.box(s * 3.2, 3.15, 0, 1.75, 0.12, 8.9, black, M.Metal, {name = "RunningBoard"})
		k.box(s * 3.2, 3.24, 0, 1.8, 0.05, 8.9, brass, M.Metal, {name = "BoardTrim"})
		-- three driving wheels and their shared coupling rod
		local zs = {-3.0, 0, 3.0}
		for i, z in ipairs(zs) do
			local parts = k.wheel(s * 3.65, 1.55, z, 2.85, 0.32, black, red, {spokes = 6, spoke = rgb(230, 225, 215), hub = brass})
			table.insert(parts, k.cyl(s * 3.65, 1.55, z, 0.34, 2.9, steel, M.Metal, "x", {name = "TyreSteel"}))
			parts[#parts].Size = V(0.1, 2.9, 2.9)
			-- crank pin
			table.insert(parts, k.cyl(s * 3.98, 1.55 + 0.72, z, 0.4, 0.22, brass, M.Metal, "x", {name = "CrankPin"}))
			k.anim("spin", parts, s * 3.65, 1.55, z, {Axis = Vector3.xAxis, Speed = -1.1, Idle = 0.15, Run = 2.8})
			k.seg(V(s * 2.9, 0.75, z), V(s * 2.9, 2.6, z), 0.36, black, M.Metal, {box = true, name = "Hornblock"})
			k.cyl(s * 3.4, 1.55, z, 1.05, 0.36, steel, M.Metal, "x", {name = "Axle"})
		end
		-- the coupling rod goes round with the crank pins, staying level
		local rod = {k.box(s * 4.16, 1.55, 0, 0.14, 0.26, 6.4, steel, M.Metal, {name = "CouplingRod"})}
		for _, z in ipairs(zs) do
			table.insert(rod, k.cyl(s * 4.16, 1.55, z, 0.18, 0.44, brass, M.Metal, "x", {name = "RodEye"}))
		end
		k.anim("orbit", rod, s * 4.16, 1.55, 0, {A = V(0, 0.72, 0), B = V(0, 0, 0.72), Speed = -1.1, Idle = 0.15, Run = 2.8})
		-- cylinder and piston at the front, driving forward of the wheels
		k.cyl(s * 3.72, 1.55, -6.65, 2.4, 1.35, black, M.Metal, "z", {name = "Cylinder"})
		for _, z in ipairs({-7.75, -5.55}) do
			k.cyl(s * 3.72, 1.55, z, 0.18, 1.5, brass, M.Metal, "z", {name = "CylinderBand"})
		end
		k.box(s * 3.72, 2.5, -6.65, 0.85, 0.65, 1.9, black, M.Metal, {name = "SteamChest"})
		local piston = {k.cyl(s * 3.98, 1.55, -4.75, 1.4, 0.2, rgb(220, 224, 232), M.Metal, "z", {name = "PistonRod"}), k.box(s * 3.98, 1.55, -4.05, 0.26, 0.42, 0.5, brass, M.Metal, {name = "Crosshead"})}
		k.anim("slide", piston, s * 3.98, 1.55, -4.4, {Offset = V(0, 0, 0.42), Speed = 1.1, Idle = 0.15, Run = 2.8})
		k.box(s * 3.98, 1.8, -4.4, 0.08, 0.05, 1.5, steel, M.Metal, {name = "Slidebar"})
		k.emit(k.spot(s * 3.72, 0.9, -5.4, 0.4, 0.1, 0.4), {tex = "smoke", c1 = WHITE, size = {0.5, 1.9}, alpha = {0.45, 1}, life = {0.4, 0.8}, speed = {1.5, 3}, rate = 0, run = 7, dir = "Bottom", spread = {35, 35}, light = 0.1, lit = 1})
		-- TWIN STACKS outside the lane, flared and capped
		k.seg(V(s * 1.5, 3.25, -7.2), V(s * 2.78, 3.85, -7.2), 0.62, black, M.Metal, {name = "Flue"})
		k.seg(V(s * 2.78, 3.85, -7.2), V(s * 2.95, 4.55, -7.2), 0.62, black, M.Metal, {name = "Flue"})
		k.lathe(s * 2.95, 4.5, -7.2, {{0, 0.75}, {3.0, 0.7}, {3.6, 1.05}, {4.2, 1.55}, {4.5, 1.7}}, black, M.Metal, {name = "Stack"})
		k.cyl(s * 2.95, 9.02, -7.2, 0.1, 1.74, brass, M.Metal, "y", {name = "StackRim"})
		k.cyl(s * 2.95, 5.5, -7.2, 0.14, 0.9, brass, M.Metal, "y")
		k.emit(k.spot(s * 2.95, 9.1, -7.2, 0.8, 0.1, 0.8), {tex = "smoke", c1 = rgb(235, 235, 235), c2 = rgb(150, 150, 155), size = {1.1, 3.8}, alpha = {0.3, 1}, life = {1.2, 2.2}, speed = {4, 6}, rate = 2.5, run = 11, spread = {14, 14}, light = 0, lit = 1, accel = V(0, 1, 2)})
	end)
	-- THE BOILER out in front of the runner, in green with brass bands
	local by = 2.5
	k.cyl(0, by, -6.7, 4.0, 3.5, boilerC, M.SmoothPlastic, "z", {name = "Boiler"})
	for _, z in ipairs({-8.1, -7.1, -6.1, -5.15}) do
		k.cyl(0, by, z, 0.14, 3.58, brass, M.Metal, "z", {name = "BoilerBand"})
	end
	k.cyl(0, by, -8.75, 0.5, 3.75, black, M.Metal, "z", {name = "Smokebox"})
	k.cyl(0, by, -9.08, 0.14, 3.05, black, M.Metal, "z", {name = "SmokeboxDoor"})
	k.cyl(0, by, -9.16, 0.06, 2.6, rgb(58, 58, 66), M.Metal, "z")
	for i = 0, 7 do
		local a = math.rad(i * 45)
		k.ball(math.sin(a) * 1.4, by + math.cos(a) * 1.4, -9.16, 0.14, brass, M.Metal, {name = "Rivet"})
	end
	local number = k.box(0, by - 0.1, -9.2, 1.6, 0.8, 0.04, red, M.SmoothPlastic, {name = "NumberPlate"})
	k.text(number, "Front", "No 5", rgb(255, 225, 130), 60)
	-- headlamp: a brass drum with a real glow
	k.cyl(0, 4.18, -8.7, 0.36, 0.78, brass, M.Metal, "z", {name = "Headlamp"})
	local lamp = k.cyl(0, 4.18, -8.92, 0.05, 0.62, rgb(255, 240, 190), M.Neon, "z", {name = "Lens"})
	k.light(lamp, rgb(255, 225, 160), 14, 1.3)
	-- a brass bell on the boiler, swinging when running
	k.box(0, 4.3, -7.2, 0.5, 0.12, 0.12, brass, M.Metal)
	k.m(function(s)
		k.box(s * 0.25, 4.45, -7.2, 0.06, 0.3, 0.06, brass, M.Metal)
	end)
	local bell = k.lathe(0, 4.05, -7.2, {{0.42, 0.14}, {0.24, 0.28}, {0, 0.48}}, brass, M.Metal, {name = "Bell"})
	k.anim("swing", bell, 0, 4.5, -7.2, {Axis = Vector3.xAxis, Amp = 18, Speed = 1, Idle = 0, Run = 4.5})
	k.ball(0, 4.3, -6.05, 0.5, brass, M.Metal, {name = "SteamDome"})
	k.cyl(0, 4.15, -6.05, 0.3, 0.75, brass, M.Metal, "y")
	-- COWCATCHER: a fan of bars that reaches past the smokebox
	k.m(function(s)
		for i = 0, 3 do
			k.seg(V(s * (0.3 + i * 0.5), 1.2, -8.75), V(s * (0.15 + i * 0.32), 0.18, -9.3), 0.12, red, M.Metal, {box = true, name = "Cowcatcher"})
		end
		k.seg(V(s * 1.9, 1.2, -8.6), V(s * 0.15, 1.2, -8.8), 0.1, brass, M.Metal)
		k.cyl(s * 2.05, 1.05, -9.05, 0.25, 0.42, brass, M.Metal, "z", {name = "Buffer"})
	end)
	-- THE BACKHEAD: everything the driver reads, facing the runner
	k.box(0, 1.5, -4.72, 3.6, 2.2, 0.08, black, M.Metal, {name = "BackheadPlate"})
	k.box(0, 3.38, -4.72, 3.6, 1.45, 0.08, black, M.Metal)
	local fire = k.glow(0, 1.1, -4.66, 1.5, 0.95, 0.04, rgb(255, 120, 30), {name = "Firebox"})
	k.anim("flicker", fire, 0, 0, 0, {Speed = 3, Run = 2.5, ColorA = rgb(160, 40, 10), ColorB = rgb(255, 170, 50)})
	k.light(fire, rgb(255, 130, 40), 9, 1)
	for i = 0, 3 do
		k.box(-0.55 + i * 0.37, 1.1, -4.62, 0.09, 0.95, 0.03, black, M.Metal, {name = "FireDoorBar"})
	end
	for _, x in ipairs({-1.1, 0, 1.1}) do
		k.cyl(x, 3.3, -4.66, 0.06, 0.92, brass, M.Metal, "z", {name = "GaugeRim"})
		k.cyl(x, 3.3, -4.63, 0.03, 0.78, rgb(248, 240, 215), M.SmoothPlastic, "z", {name = "GaugeFace"})
		local needle = k.box(x, 3.46, -4.6, 0.04, 0.34, 0.015, rgb(220, 40, 30), M.Neon, {name = "Needle"})
		k.anim("swing", needle, x, 3.3, -4.6, {Axis = Vector3.zAxis, Amp = 42, Speed = 0.9 + x * 0.3, Idle = 0.4, Run = 2.2, Phase = x})
	end
	local lever = {k.box(1.42, 2.55, -4.6, 0.1, 1.1, 0.1, steel, M.Metal, {name = "Lever"}), k.ball(1.42, 3.1, -4.6, 0.2, red, M.SmoothPlastic, {name = "LeverKnob"})}
	k.anim("swing", lever, 1.42, 2.05, -4.6, {Axis = Vector3.xAxis, Amp = 12, Speed = 1, Idle = 0.2, Run = 1.8})
	k.seg(V(-1.5, 2.15, -4.62), V(-1.5, 2.65, -4.62), 0.2, copper, M.Metal, {name = "Pipe"})
	k.seg(V(-1.5, 2.65, -4.62), V(-0.6, 2.65, -4.62), 0.14, copper, M.Metal, {name = "Pipe"})
	-- THE TENDER behind: coal heaped and glowing a little
	k.box(0, 0.75, 6.3, 5.6, 1.1, 2.2, black, M.Metal, {name = "Tender"})
	k.box(0, 1.2, 6.3, 5.8, 0.14, 2.3, brass, M.Metal)
	local tenderName = k.box(0, 0.75, 7.42, 3.4, 0.7, 0.04, red, M.SmoothPlastic, {name = "TenderPlate"})
	k.text(tenderName, "Back", "FULL STEAM", rgb(255, 225, 130), 60)
	for i, c in ipairs({{-1.8, 0.25, 0.9}, {-0.9, 0.05, 1.05}, {0, -0.15, 1.2}, {0.9, 0.1, 1.0}, {1.8, -0.1, 0.9}, {-1.3, -0.45, 0.72}, {1.3, 0.45, 0.72}, {0.4, 0.5, 0.78}}) do
		k.ball(c[1], 1.45 + (c[3] - 0.9) * 0.7, 6.3 + c[2], c[3], coal, M.Slate, {name = "Coal"})
	end
	local hot = k.ball(-0.15, 1.6, 6.0, 0.5, rgb(255, 110, 30), M.Neon, {name = "HotCoal"})
	k.anim("flicker", hot, 0, 0, 0, {Speed = 2.5, ColorA = rgb(120, 30, 10), ColorB = rgb(255, 140, 40), Run = 2})
	k.seg(V(-2.4, 1.3, 5.2), V(-2.4, 2.2, 5.2), 0.1, steel, M.Metal, {name = "CoalShovel"})
	k.box(-2.4, 2.25, 5.2, 0.5, 0.05, 0.4, rgb(70, 70, 76), M.Metal, {rx = 20})
end}

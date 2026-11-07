-- A sweet factory that went wrong in the best way. A candy-cane arch frames the path, a towering gumball machine with a
-- working crank and chute on the left, a spinning swirl lollipop on the right, wrapped sweets riding conveyors beside the
-- runner, a giant cupcake for a console and a gingerbread house with its lights on behind.
return {Name = "Candy Rush", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local pink, hot, red, mint, cream, choc, gold = rgb(255, 170, 210), rgb(255, 70, 160), rgb(235, 40, 60), rgb(130, 235, 200), rgb(255, 244, 225), rgb(96, 56, 36), rgb(255, 205, 80)
	local brights = {red, rgb(255, 170, 40), rgb(255, 225, 60), rgb(90, 220, 110), rgb(70, 170, 255), rgb(190, 100, 255), hot}
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, pink, M.SmoothPlastic, {name = "Frosting"})
	-- sprinkles over the frosting (a fixed scatter, so every player sees the same)
	for i = 1, 26 do
		local x, z = (i * 37 % 17) / 17 * 8.2 - 4.1, (i * 53 % 29) / 29 * 15 - 8.2
		if math.abs(x) > 2.9 then
			k.box(x, 0.1, z, 0.28, 0.06, 0.09, brights[i % #brights + 1], M.SmoothPlastic, {ry = i * 47, name = "Sprinkle"})
		end
	end
	k.deck(5, cream, M.SmoothPlastic)
	k.belt({WHITE, red}, M.SmoothPlastic, 4.2)
	k.m(function(s)
		k.box(s * 2.55, 0.48, 0, 0.5, 0.56, 10.2, choc, M.SmoothPlastic, {name = "ChocolateRail"})
		k.box(s * 2.55, 0.8, 0, 0.56, 0.12, 10.2, cream, M.SmoothPlastic, {name = "Icing"})
		for z = -4.5, 4.5, 1.5 do
			k.ell(s * 2.83, 0.6, z, 0.14, 0.5 + (z * 3 % 2) * 0.12, 0.42, cream, M.SmoothPlastic, {name = "IcingDrip"})
		end
		-- a conveyor beside the runner, with wrapped sweets riding it
		k.box(s * 3.72, 0.95, 0, 1.3, 0.2, 8.6, rgb(70, 66, 74), M.SmoothPlastic, {name = "Conveyor"})
		k.box(s * 3.72, 0.45, -3.6, 1.1, 0.8, 0.3, choc, M.SmoothPlastic)
		k.box(s * 3.72, 0.45, 3.6, 1.1, 0.8, 0.3, choc, M.SmoothPlastic)
		for _, z in ipairs({-4.3, 4.3}) do
			k.cyl(s * 3.72, 0.95, z, 1.3, 0.32, rgb(190, 195, 205), M.Metal, "x", {name = "Roller"})
		end
		local sweets = {}
		for i = 1, 5 do
			local c = brights[(i + (s > 0 and 3 or 0)) % #brights + 1]
			table.insert(sweets, k.ell(s * 3.72, 1.32, 0, 0.75, 0.55, 0.55, c, M.SmoothPlastic, {name = "Sweet" .. i}))
		end
		k.anim("travel", sweets, s * 3.72, 1.32, 0, {Speed = s, Idle = 0.8, Run = 2.2, path = {V(0, 0, -4.1 * s), V(0, 0, 4.1 * s)}})
		-- the arch legs: striped candy canes
		for i = 0, 6 do
			k.cyl(s * 3.55, 0.45 + i * 0.86, -5.4, 0.88, 0.72, i % 2 == 0 and red or WHITE, M.SmoothPlastic, "y", {name = "CaneLeg"})
		end
	end)
	-- the arch itself, candy-striped, clear of the runner's head
	k.ring(0, 5.4, -5.4, 3.55, 0.72, function(f)
		return math.floor(f * 14) % 2 == 0 and red or WHITE
	end, M.SmoothPlastic, "z", {n = 14, a0 = -88, a1 = 88, depth = 0.72, name = "CaneArch"})
	k.ball(0, 9.4, -5.4, 0.9, gold, M.Foil, {name = "ArchStar"})

	-- THE GUMBALL TOWER, left
	local gx, gz = -3.0, -7.5
	k.cyl(gx, 0.5, gz, 1.0, 2.8, red, M.SmoothPlastic, "y", {name = "GumballBase"})
	k.cyl(gx, 1.04, gz, 0.1, 2.9, gold, M.Foil, "y")
	k.lathe(gx, 1.0, gz, {{0, 2.4}, {1.4, 1.7}, {2.6, 1.45}, {5.4, 1.4}, {6.1, 1.5}}, red, M.SmoothPlastic, {name = "GumballColumn"})
	for _, y in ipairs({2.2, 3.5, 5.1}) do
		k.cyl(gx, y, gz, 0.12, 1.56, gold, M.Foil, "y", {name = "ColumnBand"})
	end
	local plate = k.box(gx, 2.1, gz + 1.05, 1.2, 0.9, 0.08, gold, M.Foil, {name = "CoinPlate"})
	k.text(plate, "Back", "25\u{00A2}", rgb(120, 60, 10), 50)
	local crank = {k.cyl(gx, 2.1, gz + 1.15, 0.12, 0.7, rgb(200, 205, 215), M.Metal, "z", {name = "CrankDisc"}), k.box(gx, 2.1, gz + 1.25, 0.14, 0.75, 0.1, rgb(200, 205, 215), M.Metal, {name = "CrankArm"}), k.ball(gx, 2.48, gz + 1.33, 0.22, hot, M.SmoothPlastic, {name = "CrankKnob"})}
	k.anim("spin", crank, gx, 2.1, gz + 1.15, {Axis = Vector3.zAxis, Speed = 1, Idle = 0.4, Run = 3})
	-- the chute and the tray, and gumballs rolling down it
	k.seg(V(gx + 0.6, 1.9, gz - 0.95), V(gx + 1.3, 0.5, gz - 1.45), 0.5, gold, M.Foil, {name = "Chute", box = true})
	k.box(gx + 1.2, 0.2, gz - 1.45, 1.0, 0.26, 0.85, red, M.SmoothPlastic, {name = "Tray"})
	local rollers = {}
	for i = 1, 3 do
		table.insert(rollers, k.ball(gx + 0.6, 2.2, gz - 0.95, 0.42, brights[i * 2], M.SmoothPlastic, {name = "Rolling" .. i}))
	end
	k.anim("travel", rollers, gx, 0, gz, {Speed = 0.8, Idle = 0.5, Run = 2.4, path = {V(0.6, 2.25, -0.95), V(1.3, 0.8, -1.45), V(1.35, 0.46, -1.5)}})
	-- the globe: clear, and full of gumballs that churn
	local gy = 9.1
	k.cyl(gx, 7.42, gz, 0.3, 2.2, gold, M.Foil, "y", {name = "GlobeCollar"})
	local balls = {}
	for i = 1, 22 do
		local a, h = i * 2.39996, (i / 22) * 2 - 1
		local r = math.sqrt(1 - h * h * 0.82) * 1.02
		table.insert(balls, k.ball(gx + math.cos(a) * r, gy - 0.1 + h * 0.98, gz + math.sin(a) * r, 0.68, brights[i % #brights + 1], M.SmoothPlastic, {name = "Gumball"}))
	end
	k.anim("spin", balls, gx, gy, gz, {Axis = Vector3.yAxis, Speed = 0.35, Run = 2.4})
	k.ball(gx, gy, gz, 3.2, rgb(230, 245, 255), M.SmoothPlastic, {t = 0.72, refl = 0.2, name = "Globe"})
	k.cyl(gx, gy + 1.62, gz, 0.26, 1.4, red, M.SmoothPlastic, "y", {name = "GlobeCap"})
	k.ball(gx, gy + 1.95, gz, 0.5, gold, M.Foil, {name = "GlobeKnob"})

	-- THE LOLLIPOP, right: the swirl turns
	local lx, ly, lz = 3.0, 9.05, -7.4
	k.cyl(lx, 3.6, lz, 7.2, 0.34, cream, M.SmoothPlastic, "y", {name = "LollipopStick"})
	local swirl = {k.cyl(lx, ly, lz, 0.5, 3.5, hot, M.SmoothPlastic, "z", {name = "LollipopDisc"})}
	for i = 0, 2 do
		local c = i % 2 == 0 and WHITE or mint
		for _, face in ipairs({-0.27, 0.27}) do
			for _, p in ipairs(k.ring(lx, ly, lz + face, 0.42 + i * 0.5, 0.26, c, M.SmoothPlastic, "z", {n = 9 + i * 3, a0 = 40 * i, a1 = 40 * i + 300, depth = 0.04, name = "Swirl"})) do
				table.insert(swirl, p)
			end
		end
	end
	k.anim("spin", swirl, lx, ly, lz, {Axis = Vector3.zAxis, Speed = 0.8, Run = 3})
	local bow = k.ell(lx, 7.15, lz, 1.5, 0.5, 0.3, hot, M.SmoothPlastic, {name = "Bow"})
	k.m(function(s)
		k.ell(lx + s * 0.42, 7.1, lz, 0.62, 0.7, 0.2, red, M.SmoothPlastic, {name = "BowLoop"})
	end)
	k.emit(k.spot(lx, ly, lz, 3, 3, 0.4), {tex = "sparkle", c1 = WHITE, c2 = rgb(255, 180, 230), size = {0.45, 0}, life = {0.6, 1.3}, speed = {0.3, 0.8}, spread = {180, 180}, rate = 4, run = 12})

	-- THE CUPCAKE console
	k.lathe(0, 0.45, -6.1, {{0, 2.2}, {1.4, 3.1}}, rgb(255, 225, 140), M.SmoothPlastic, {name = "CupcakeCase"})
	for i = 0, 11 do
		local a = math.rad(i * 30)
		k.box(math.sin(a) * 1.34, 1.15, -6.1 + math.cos(a) * 1.34, 0.12, 1.45, 0.1, rgb(255, 150, 190), M.SmoothPlastic, {ry = i * 30, name = "Pleat"})
	end
	for i, d in ipairs({{3.08, 1.0}, {2.4, 0.9}, {1.6, 0.8}}) do
		k.ell(0, 1.85 + i * 0.52, -6.1, d[1], d[2], d[1], i == 2 and WHITE or pink, M.SmoothPlastic, {name = "Frosted"})
	end
	local cherry = k.ball(0, 3.85, -6.1, 0.62, red, M.Neon, {name = "Cherry"})
	k.light(cherry, rgb(255, 120, 150), 10, 1)
	k.anim("pulse", cherry, 0, 0, 0, {Speed = 3, ColorA = rgb(170, 20, 40), ColorB = rgb(255, 70, 90), Run = 2})
	k.seg(V(0, 4.1, -6.1), V(0.3, 4.55, -6.25), 0.05, rgb(70, 140, 60), M.SmoothPlastic, {name = "CherryStem"})
	local wafer = k.box(0, 3.0, -4.75, 3.2, 0.9, 0.12, rgb(240, 200, 130), M.SmoothPlastic, {rx = 16, name = "Wafer"})
	k.text(wafer, "Back", "SUGAR RUSH!", hot, 50)
	k.m(function(s)
		k.box(s * 1.45, 1.75, -4.95, 0.14, 2.6, 0.14, cream, M.SmoothPlastic)
	end)

	-- THE GINGERBREAD HOUSE, back left, lit from inside
	local hx, hz = -3.05, 6.3
	local ginger, icing = rgb(170, 100, 50), WHITE
	k.box(hx, 0.7, hz, 2.3, 1.2, 1.9, ginger, M.SmoothPlastic, {name = "Gingerbread"})
	k.wedge(hx, 1.75, hz + 0.5, 2.5, 0.9, 1.1, ginger:Lerp(BLACK, 0.2), M.SmoothPlastic, {ry = 0, name = "Roof"})
	k.wedge(hx, 1.75, hz - 0.5, 2.5, 0.9, 1.1, ginger:Lerp(BLACK, 0.2), M.SmoothPlastic, {ry = 180, name = "Roof"})
	k.box(hx, 2.22, hz, 2.55, 0.1, 0.22, icing, M.SmoothPlastic, {name = "RoofIcing"})
	local win = {}
	for _, x in ipairs({-0.55, 0.55}) do
		table.insert(win, k.glow(hx + x, 0.82, hz + 0.97, 0.42, 0.42, 0.03, rgb(255, 210, 110), {name = "Window"}))
		k.box(hx + x, 0.82, hz + 0.99, 0.5, 0.05, 0.02, icing, M.SmoothPlastic)
		k.box(hx + x, 0.82, hz + 0.99, 0.05, 0.5, 0.02, icing, M.SmoothPlastic)
	end
	k.anim("flicker", win, 0, 0, 0, {Speed = 2.5, ColorA = rgb(220, 140, 60), ColorB = rgb(255, 225, 140)})
	k.box(hx, 0.55, hz - 0.97, 0.5, 0.85, 0.04, choc, M.SmoothPlastic, {name = "Door"})
	for i = 0, 3 do
		k.ball(hx - 0.9 + i * 0.6, 0.2, hz + 1.1, 0.34, brights[i + 1], M.SmoothPlastic, {name = "Gumdrop"})
	end
	-- macaron tower and a donut, back right
	for i, c in ipairs({mint, pink, rgb(255, 225, 120), rgb(190, 150, 255)}) do
		k.cyl(3.2, 0.12 + i * 0.42, 6.3, 0.2, 1.3 - i * 0.12, c, M.SmoothPlastic, "y", {name = "Macaron"})
		k.cyl(3.2, 0.32 + i * 0.42, 6.3, 0.08, 1.1 - i * 0.12, cream, M.SmoothPlastic, "y")
	end
	k.ring(1.2, 0.3, 6.5, 0.5, 0.42, choc, M.SmoothPlastic, "y", {n = 10, depth = 0.42, name = "Donut"})
	k.ring(1.2, 0.42, 6.5, 0.5, 0.34, hot, M.SmoothPlastic, "y", {n = 10, depth = 0.26, name = "DonutIcing"})
	-- sprinkles fall from the arch while running
	k.emit(k.spot(0, 8.8, -5.4, 5, 0.2, 0.6), {tex = "sparkle", c1 = hot, c2 = mint, size = {0.32, 0.12}, life = {0.8, 1.5}, speed = {1, 2}, rate = 1, run = 20, dir = "Bottom", spread = {20, 20}, accel = V(0, -8, 0)})
end}

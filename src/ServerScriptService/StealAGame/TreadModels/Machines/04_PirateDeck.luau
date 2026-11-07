-- A galleon under way. The runner's lane is the deck; the hull rises round it with gunports and cannons that kick, the
-- bow narrows to a golden figurehead over foaming water. A mast with a crow's nest and a billowing sail, the black flag
-- flapping, the ship's wheel turning, a treasure chest breathing open behind with gold glinting inside.
return {Name = "Pirate Deck", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	k.motor("rbxassetid://9112828911", 0.4, 1)
	local hull, plank, dark, gold, sail, iron, rope, sea = rgb(92, 56, 32), rgb(160, 112, 66), rgb(58, 36, 24), rgb(235, 185, 60), rgb(244, 232, 205), rgb(44, 44, 50), rgb(205, 175, 115), rgb(34, 130, 170)
	-- the sea, swelling, with foam at the waterline
	k.box(0, 0.05, -0.8, 8.9, 0.1, 15.9, sea, M.SmoothPlastic, {name = "Sea"})
	local waves = {}
	for i = 1, 6 do
		local s = i % 2 == 0 and 1 or -1
		table.insert(waves, k.ell(s * 4.25, 0.14, -7 + i * 2.1, 0.8, 0.14, 2.0, rgb(150, 225, 240), M.SmoothPlastic, {name = "Foam" .. i}))
	end
	k.anim("slide", waves, 0, 0, 0, {Offset = V(0.06, 0.04, 0.5), Speed = 1.1, Run = 2.4})
	k.deck(5, dark, M.WoodPlanks)
	k.belt({plank, rgb(134, 92, 54)}, M.WoodPlanks, 4.2)
	k.m(function(s)
		-- the hull's side, flared and planked, painted bands and gold trim
		k.box(s * 3.35, 1.2, 0, 1.9, 2.3, 10.4, hull, M.WoodPlanks, {name = "Hull"})
		k.box(s * 4.33, 0.75, 0, 0.1, 0.42, 10.4, rgb(150, 30, 34), M.SmoothPlastic, {name = "HullBand"})
		k.box(s * 3.35, 2.42, -0.4, 2.0, 0.16, 9.8, gold, M.Foil, {name = "GoldTrim"})
		k.box(s * 3.35, 2.75, -0.4, 1.3, 0.5, 9.75, plank, M.WoodPlanks, {name = "Bulwark"})
		for z = -4.5, 3.6, 1.8 do
			k.box(s * 2.75, 3.1, z, 0.16, 0.16, 0.16, gold, M.Foil, {name = "Stud"})
		end
		-- two cannons per side, sticking out of gunports; they kick back in turn
		for i, z in ipairs({-2.4, 1.8}) do
			k.box(s * 4.38, 1.55, z, 0.06, 1.0, 1.0, BLACK, M.SmoothPlastic, {name = "Gunport"})
			k.box(s * 4.42, 2.1, z, 0.06, 0.12, 1.2, gold, M.Foil)
			local barrel = {
				k.cyl(s * 4.3, 1.55, z, 1.0, 0.56, iron, M.Metal, "x", {name = "Cannon"}),
				k.cyl(s * 4.72, 1.55, z, 0.14, 0.68, iron, M.Metal, "x", {name = "Muzzle"}),
			}
			k.anim("slide", barrel, s * 4.3, 1.55, z, {Offset = V(s * 0.1, 0, 0), Speed = 1.4, Idle = 0, Run = 3.2, Phase = i * 1.5})
			k.emit(k.spot(s * 4.74, 1.55, z, 0.2, 0.3, 0.3), {tex = "smoke", c1 = rgb(225, 225, 225), size = {0.4, 1.4}, alpha = {0.45, 1}, life = {0.5, 1}, speed = {1, 2}, rate = 0, run = 1.5, dir = s > 0 and "Right" or "Left", light = 0, lit = 1})
		end
		-- the bow narrows forward: a solid planked prow, walled and railed
		k.wedge(s * 1.85, 1.2, -7.3, 2.3, 3.7, 4.0, hull, M.WoodPlanks, {rz = -s * 90, name = "Bow"})
		k.wedge(s * 1.85, 2.42, -7.3, 0.16, 3.7, 4.0, gold, M.Foil, {rz = -s * 90, name = "BowTrim"})
		k.wedge(s * 1.85, 0.75, -7.3, 0.42, 3.74, 4.04, rgb(150, 30, 34), M.SmoothPlastic, {rz = -s * 90, name = "BowBand"})
		local L = math.sqrt(3.5 ^ 2 + 3.9 ^ 2)
		k.box(s * 1.95, 2.75, -7.35, 0.3, 0.5, L, plank, M.WoodPlanks, {ry = s * math.deg(math.atan2(3.5, 3.9)), name = "BowRail"})
	end)
	k.box(0, 1.2, -5.0, 3.7, 2.3, 0.6, hull, M.WoodPlanks, {name = "Bulkhead"})
	k.box(0, 2.42, -5.0, 3.7, 0.16, 0.6, gold, M.Foil)
	-- bowsprit and figurehead: a golden seahorse leaning over the waves
	k.seg(V(0, 2.5, -7.4), V(0, 4.3, -9.2), 0.28, dark, M.Wood, {name = "Bowsprit"})
	k.ell(0, 2.8, -8.65, 0.8, 1.3, 0.8, gold, M.Foil, {rx = 25, name = "Figurehead"})
	k.ball(0, 3.5, -9.0, 0.62, gold, M.Foil, {name = "FigureheadHead"})
	k.wedge(0, 3.45, -9.28, 0.22, 0.2, 0.26, gold, M.Foil, {ry = 0, name = "FigureheadSnout"})
	k.m(function(s)
		k.glow(s * 0.2, 3.56, -9.27, 0.07, 0.07, 0.04, rgb(80, 220, 255), {name = "FigureheadEye"})
	end)

	-- the ship's wheel, turning one way and back, on a binnacle facing the runner
	k.box(0, 2.8, -5.05, 0.5, 0.9, 0.4, dark, M.Wood, {name = "Binnacle"})
	local wheel = {k.cyl(0, 3.65, -4.85, 0.22, 0.44, gold, M.Foil, "z", {name = "WheelHub"})}
	for _, list in ipairs({k.ring(0, 3.65, -4.85, 0.82, 0.18, plank, M.Wood, "z", {n = 14, depth = 0.18, name = "WheelRim"})}) do
		for _, p in ipairs(list) do
			table.insert(wheel, p)
		end
	end
	for i = 0, 3 do
		table.insert(wheel, k.box(0, 3.65, -4.85, 0.1, 1.86, 0.1, plank, M.Wood, {rz = i * 45, name = "Spoke"}))
	end
	k.anim("swing", wheel, 0, 3.65, -4.85, {Axis = Vector3.zAxis, Amp = 55, Speed = 0.7, Run = 2})

	-- THE MAST, left: yard along the ship so the sail never covers the runner
	local mx, mz = -3.55, -7.2
	k.cyl(mx, 0.2, mz, 0.4, 1.0, dark, M.Wood, "y")
	k.cyl(mx, 6.2, mz, 12.0, 0.48, plank:Lerp(dark, 0.4), M.Wood, "y", {name = "Mast"})
	k.cyl(mx, 8.9, mz, 0.34, 1.75, dark, M.WoodPlanks, "y", {name = "CrowsNestFloor"})
	k.ring(mx, 9.35, mz, 0.86, 0.1, plank, M.Wood, "y", {n = 10, depth = 0.65, name = "CrowsNest"})
	-- the yard and sail run along z, and the sail bellies out to the side
	k.seg(V(mx, 8.3, -9.25), V(mx, 8.3, -5.0), 0.2, dark, M.Wood, {name = "Yard"})
	local sailParts = {}
	for i = 1, 5 do
		local z = -9.2 + (i - 0.5) * 0.84
		local belly = math.sin((i - 0.5) / 5 * math.pi) * 0.42
		table.insert(sailParts, k.box(mx - belly - 0.05, 5.7, z, 0.1, 5.0, 0.88, i % 2 == 0 and sail or sail:Lerp(rgb(190, 40, 40), 0.75), M.Fabric, {ry = (i - 3) * -9, name = "Sail"}))
	end
	k.anim("swing", sailParts, mx, 8.3, -7.1, {Axis = Vector3.zAxis, Amp = 2.6, Speed = 1.1, Run = 2.6})
	-- rigging
	for _, p in ipairs({V(-2.7, 2.6, -4.6), V(-4.5, 2.6, -4.6), V(-2.6, 2.6, -9.0)}) do
		k.seg(V(mx, 8.8, mz), p, 0.05, rope, M.Fabric, {name = "Rigging"})
	end
	-- the flag at the very top, flapping
	local flag = {}
	for i = 1, 4 do
		table.insert(flag, k.box(mx, 11.7, mz + 0.05 + i * 0.36, 0.05, 0.95, 0.38, BLACK, M.Fabric, {name = "FlagCloth" .. i}))
	end
	local badge = k.box(mx, 11.7, mz + 0.95, 0.07, 0.72, 0.72, BLACK, M.Fabric, {name = "FlagSkull"})
	k.text(badge, "Left", "\u{2620}", WHITE, 60)
	k.text(badge, "Right", "\u{2620}", WHITE, 60)
	table.insert(flag, badge)
	k.anim("swing", flag, mx, 11.7, mz, {Axis = Vector3.yAxis, Amp = 16, Speed = 3.4, Run = 1.8})
	-- a hanging lantern on the yard, swaying
	local lamp = k.glow(mx + 0.35, 3.2, -5.05, 0.3, 0.42, 0.3, rgb(255, 190, 90), {name = "Lantern"})
	k.light(lamp, rgb(255, 180, 90), 10, 1)
	local hook = k.box(mx + 0.35, 5.7, -5.05, 0.04, 4.6, 0.04, iron, M.Metal, {name = "LanternCord"})
	k.anim("swing", {lamp, hook}, mx + 0.35, 8.0, -5.05, {Axis = Vector3.zAxis, Amp = 4, Speed = 1.1, Run = 2})

	-- second mast, right: a shorter one with a furled sail and a look-out spyglass
	local nx, nz = 3.55, -7.0
	k.cyl(nx, 4.7, nz, 9.0, 0.42, plank:Lerp(dark, 0.4), M.Wood, "y", {name = "Mizzen"})
	k.seg(V(nx, 7.0, -8.9), V(nx, 7.0, -5.1), 0.18, dark, M.Wood, {name = "Yard"})
	k.cyl(nx, 6.75, -7.0, 3.6, 0.38, sail, M.Fabric, "z", {name = "Furled"})
	for _, z in ipairs({-8.3, -7.0, -5.7}) do
		k.cyl(nx, 6.75, z, 0.08, 0.42, rope, M.Fabric, "z")
	end
	for _, p in ipairs({V(2.75, 2.6, -4.7), V(4.5, 2.6, -4.7), V(2.7, 2.6, -8.9)}) do
		k.seg(V(nx, 7.2, nz), p, 0.05, rope, M.Fabric, {name = "Rigging"})
	end
	-- cannonballs beside it
	for _, b in ipairs({{-1.1, -6.2}, {-0.6, -6.2}, {-0.85, -5.75}}) do
		k.ball(b[1], 2.7, b[2], 0.46, iron, M.Metal, {name = "Cannonball"})
	end
	k.ball(-0.85, 3.05, -6.05, 0.46, iron, M.Metal)

	-- THE TREASURE, back right: lid breathing open, gold shining out
	local cx, cz = 3.1, 6.3
	k.box(cx, 0.55, cz, 1.8, 0.9, 1.2, hull, M.WoodPlanks, {name = "Chest"})
	k.m(function(s)
		k.box(cx + s * 0.75, 0.55, cz, 0.12, 0.95, 1.25, gold, M.Foil)
	end)
	local lid = {k.cyl(cx, 1.05, cz + 0.28, 1.85, 0.62, hull, M.WoodPlanks, "x", {name = "ChestLid"}), k.box(cx, 1.05, cz + 0.28, 0.2, 0.68, 0.68, gold, M.Foil)}
	k.anim("swing", lid, cx, 1.0, cz + 0.58, {Axis = Vector3.xAxis, Amp = 14, Speed = 1, Run = 2})
	local hoard = k.ell(cx, 1.05, cz, 1.55, 0.55, 0.95, rgb(255, 205, 70), M.Neon, {name = "Hoard"})
	k.light(hoard, rgb(255, 200, 90), 8, 0.9)
	k.emit(k.spot(cx, 1.3, cz, 1.3, 0.1, 0.8), {tex = "sparkle", c1 = rgb(255, 235, 150), size = {0.42, 0}, life = {0.5, 1.1}, speed = {0.4, 1.2}, spread = {50, 50}, rate = 6, run = 12})
	for i = 1, 6 do
		k.cyl(cx - 1.25 + i * 0.3, 0.18, cz + 0.92 + (i % 2) * 0.22, 0.05, 0.3, gold, M.Foil, "y", {name = "Coin"})
	end
	-- anchor and rope coil, back left
	local ax, az = -3.3, 6.3
	k.cyl(ax, 0.22, az, 0.34, 1.5, rope, M.Fabric, "y", {name = "RopeCoil"})
	k.cyl(ax, 0.42, az, 0.1, 1.05, rope:Lerp(BLACK, 0.2), M.Fabric, "y")
	k.seg(V(ax - 0.1, 0.3, az - 0.2), V(ax + 0.1, 2.05, az + 0.5), 0.2, iron, M.Metal, {box = true, name = "Anchor"})
	k.ring(ax + 0.1, 2.1, az + 0.5, 0.16, 0.07, iron, M.Metal, "z", {n = 7, depth = 0.07})
	k.seg(V(ax - 0.6, 0.5, az - 0.25), V(ax + 0.5, 0.5, az - 0.15), 0.14, iron, M.Metal, {box = true})
	k.cyl(-1.5, 0.55, 6.7, 1.0, 0.8, plank, M.WoodPlanks, "y", {name = "RumBarrel"})
	k.cyl(-1.5, 0.3, 6.7, 0.08, 0.85, iron, M.Metal, "y")
	k.cyl(-1.5, 0.8, 6.7, 0.08, 0.85, iron, M.Metal, "y")
	-- spray kicking up from the bow when running
	k.emit(k.spot(0, 0.4, -9.2, 2.6, 0.1, 0.2), {tex = "sparkle", c1 = rgb(220, 245, 255), size = {0.4, 0.1}, life = {0.35, 0.7}, speed = {3, 6}, spread = {35, 35}, rate = 2, run = 26, accel = V(0, -16, 0), light = 0.4})
end}

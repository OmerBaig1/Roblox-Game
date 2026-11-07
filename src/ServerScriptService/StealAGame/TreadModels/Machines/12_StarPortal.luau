-- A ring gate left by a vanished people. An old stone circle stands over the path; inside it a rune band turns and a galaxy turns
-- the other way, see-through so the runner shows in it. Stars pour into the centre, blocks of the broken ring drift in the air,
-- blue fire burns on two pillars, crystals grow up the stonework and a floating key-crystal hangs over the console.
return {Name = "Star Portal", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local stone, stoneDark, moss, crystal, void, violet, rune, ink = rgb(150, 150, 165), rgb(96, 96, 112), rgb(90, 120, 84), rgb(120, 240, 255), rgb(30, 20, 96), rgb(170, 90, 255), rgb(110, 240, 255), rgb(22, 20, 36)
	k.box(0, 0.04, -0.8, 8.8, 0.08, 15.9, stoneDark, M.Cobblestone, {name = "Plaza"})
	k.deck(5, stone, M.Slate)
	k.belt({rgb(34, 40, 84), rgb(64, 82, 150)}, M.Slate, 4.2)
	k.m(function(s)
		k.box(s * 2.62, 0.48, 0, 0.5, 0.7, 10.2, stoneDark, M.Slate, {name = "StoneKerb"})
		-- runes down the kerb, lighting in a wave toward the gate
		local kerb = {}
		for i = 0, 9 do
			table.insert(kerb, k.glow(s * 2.62, 0.84, 4.5 - i, 0.26, 0.03, 0.56, rune, {name = "KerbRune" .. i}))
		end
		k.anim("pulse", kerb, 0, 0, 0, {Speed = 3, Stagger = -0.65, Sharp = 3, ColorA = rgb(20, 30, 70), ColorB = rune, Idle = 0.6, Run = 2.4})
		-- broken columns standing beside the runner, with blue fire
		k.cyl(s * 3.85, 1.15, -1.5, 2.3, 1.05, stone, M.Slate, "y", {name = "Pillar"})
		k.cyl(s * 3.85, 0.15, -1.5, 0.3, 1.4, stoneDark, M.Slate, "y")
		for i = 0, 7 do
			local a = math.rad(i * 45)
			k.box(s * 3.85 + math.sin(a) * 0.5, 1.1, -1.5 + math.cos(a) * 0.5, 0.1, 1.9, 0.1, stoneDark, M.Slate, {name = "Flute"})
		end
		k.cyl(s * 3.85, 2.4, -1.5, 0.22, 1.2, stoneDark, M.Slate, "y", {name = "BrazierBowl"})
		local flame = k.ell(s * 3.85, 2.8, -1.5, 0.55, 1.0, 0.55, rgb(90, 200, 255), M.Neon, {name = "BlueFlame", shadow = false})
		k.anim("gauge", flame, 0, 0, 0, {GAxis = "Y", Speed = 7, Amp = 0.2, Run = 1.6})
		k.emit(k.spot(s * 3.85, 2.75, -1.5, 0.5, 0.1, 0.5), {tex = "fire", c1 = rgb(170, 235, 255), c2 = rgb(70, 90, 255), size = {0.75, 0.15}, alpha = {0.1, 1}, life = {0.3, 0.6}, speed = {1.5, 3}, rate = 12, run = 24, spread = {12, 12}, light = 1})
		-- a short stack of rubble behind each
		k.box(s * 3.75, 0.5, 2.3, 1.2, 1.0, 1.2, stone, M.Cobblestone, {ry = s * 14, name = "Rubble"})
		k.box(s * 3.9, 1.3, 2.4, 0.8, 0.6, 0.8, stoneDark, M.Cobblestone, {ry = s * -22, rz = s * 8, name = "Rubble"})
		-- crystals growing from the plaza at the foot of the gate
		for i, c in ipairs({{3.45, -8.7, 1.5, 0.5, -14}, {4.3, -8.3, 2.0, 0.55, 10}, {4.35, -5.5, 1.3, 0.42, 16}}) do
			k.box(s * c[1], c[3] / 2, c[2], c[4], c[3], c[4], crystal, M.Glass, {t = 0.15, rz = s * c[5], ry = 45, name = "Crystal"})
			k.glow(s * c[1], c[3] / 2, c[2], c[4] * 0.4, c[3] * 0.85, c[4] * 0.4, crystal, {rz = s * c[5], ry = 45, name = "CrystalCore"})
		end
		-- behind: stone lions? no: little obelisk shards that hover
		local shard = {k.box(s * 3.3, 1.5, 6.3, 0.5, 1.5, 0.5, crystal, M.Glass, {t = 0.15, ry = 45, name = "HoverShard"}), k.glow(s * 3.3, 1.5, 6.3, 0.2, 1.25, 0.2, violet, {ry = 45, name = "HoverCore"})}
		k.anim("slide", shard, s * 3.3, 1.5, 6.3, {Offset = V(0, 0.3, 0), Speed = 1.2, Phase = s + 1, Run = 2})
		k.cyl(s * 3.3, 0.3, 6.3, 0.5, 1.2, stoneDark, M.Slate, "y", {name = "ShardBase"})
		k.glow(s * 3.3, 0.57, 6.3, 0.75, 0.04, 0.75, rune, {name = "ShardPad"})
	end)

	-- THE GATE: a ring of big stone blocks. Sides stand outside the runner's lane, the arch passes high overhead.
	local gy, gz, R = 5.45, -7.1, 4.0
	k.m(function(s)
		k.box(s * 3.9, 0.55, gz, 1.6, 1.1, 2.1, stoneDark, M.Slate, {name = "GateFoot"})
	end)
	local stones = 18
	for i = 0, stones - 1 do
		local a = (i + 0.5) / stones * 360
		local r = math.rad(a)
		-- the two blocks at the very bottom would hide the belt: the console stands there instead
		if math.abs(math.cos(r)) < 0.92 or math.cos(r) > 0 then
			local c = i % 2 == 0 and stone or stone:Lerp(stoneDark, 0.5)
			if i == 2 or i == 13 then
				c = moss
			end
			k.box(math.sin(r) * R, gy + math.cos(r) * R, gz, 1.42, 0.78, 1.25, c, M.Slate, {rz = -a, name = "GateStone"})
		end
	end
	-- the rune band: turns one way, its runes chasing
	local bandParts = k.ring(0, gy, gz, 3.4, 0.2, rgb(44, 44, 70), M.Metal, "z", {n = 22, depth = 0.4, name = "RuneBand", t = 0.0})
	local runes = {}
	for i = 0, 15 do
		local a = math.rad(i * 22.5)
		table.insert(runes, k.glow(math.sin(a) * 3.4, gy + math.cos(a) * 3.4, gz + 0.22, 0.34, 0.34, 0.03, rune, {rz = -i * 22.5, name = "RuneA" .. string.format("%02d", i)}))
		table.insert(runes, k.glow(math.sin(a) * 3.4, gy + math.cos(a) * 3.4, gz - 0.22, 0.34, 0.34, 0.03, rune, {rz = -i * 22.5, name = "RuneB" .. string.format("%02d", i)}))
	end
	-- only the top of a turning band may cross the lane, so it is see-through-safe: the band is thin and high at the sides
	for _, p in ipairs(bandParts) do
		local rel = p.Position
		p.Transparency = 0.62
	end
	for _, p in ipairs(runes) do
		p.Transparency = 0.62
	end
	k.anim("spin", {bandParts, runes}, 0, gy, gz, {Axis = Vector3.zAxis, Speed = 0.3, Run = 2.4})
	local glowBand = {}
	-- THE GALAXY: a see-through disc and spiral arms turning the other way
	local disc = k.cyl(0, gy, gz, 0.06, 6.4, void, M.Neon, "z", {t = 0.64, name = "VortexDisc", shadow = false})
	local arms = {}
	for arm = 0, 2 do
		for i = 1, 9 do
			local r = 0.28 + i * 0.32
			local a = math.rad(arm * 120 + i * 34)
			table.insert(arms, k.ball(math.sin(a) * r, gy + math.cos(a) * r, gz - 0.06, 0.42 - i * 0.022, crystal:Lerp(violet, i / 9), M.Neon, {t = 0.62, name = "GalaxyArm", shadow = false}))
		end
	end
	k.anim("spin", arms, 0, gy, gz, {Axis = Vector3.zAxis, Speed = -0.8, Run = 3.2})
	local core = k.ball(0, gy, gz + 0.02, 0.9, WHITE, M.Neon, {t = 0.62, name = "VortexCore", shadow = false})
	k.anim("pulse", core, 0, 0, 0, {Speed = 3, TransA = 0.8, TransB = 0.62, Run = 2})
	k.light(disc, rgb(120, 170, 255), 18, 1.8)
	-- stars streaming toward the centre: emitted on the rim, moving in
	k.emit(k.spot(0, gy, gz, 6.4, 6.4, 0.3), {tex = "sparkle", c1 = crystal, c2 = violet, size = {0.42, 0}, life = {0.8, 1.6}, speed = {0.3, 1}, spread = {180, 180}, rate = 16, run = 46})
	-- a keystone at the top with a crystal crown
	k.box(0, gy + R + 0.45, gz, 1.6, 1.45, 1.6, stone, M.Slate, {name = "Keystone"})
	k.wedge(0, gy + R + 1.4, gz + 0.4, 1.6, 0.5, 0.8, stoneDark, M.Slate, {name = "KeystoneCap"})
	k.wedge(0, gy + R + 1.4, gz - 0.4, 1.6, 0.5, 0.8, stoneDark, M.Slate, {ry = 180, name = "KeystoneCap"})
	local eye = k.glow(0, gy + R + 0.5, gz - 0.82, 0.8, 0.4, 0.03, rune, {name = "GateEye"})
	k.anim("pulse", eye, 0, 0, 0, {Speed = 1.6, ColorA = rgb(30, 80, 110), ColorB = rune, Run = 2})
	-- blocks of the broken outer ring, drifting
	for i, b in ipairs({{-3.6, 10.8, -8.4, 1.0, 0.7, 1.1, 15}, {3.5, 10.9, -8.3, 1.1, 0.8, 1.0, -18}, {-2.2, 11.4, -6.0, 0.8, 0.6, 0.8, 28}, {2.3, 11.5, -6.0, 0.7, 0.55, 0.8, -30}, {-4.2, 9.2, -5.9, 0.7, 0.6, 0.7, -12}, {4.2, 9.2, -5.9, 0.7, 0.6, 0.7, 14}}) do
		local block = {k.box(b[1], b[2], b[3], b[4], b[5], b[6], i % 2 == 0 and stone or stoneDark, M.Slate, {rz = b[7], rx = b[7] / 2, name = "DriftStone"}), k.glow(b[1], b[2] - b[5] / 2 - 0.03, b[3], b[4] * 0.6, 0.03, b[6] * 0.6, rune, {rz = b[7], rx = b[7] / 2, name = "DriftRune"})}
		k.anim("slide", block, b[1], b[2], b[3], {Offset = V(0, 0.28, 0), Speed = 0.9, Phase = i * 1.1, Run = 1.8})
	end

	-- THE CONSOLE: a carved altar with a key-crystal turning above it
	k.box(0, 0.75, -5.42, 3.0, 1.5, 1.4, stoneDark, M.Slate, {name = "Altar"})
	k.box(0, 1.56, -5.42, 3.3, 0.14, 1.65, stone, M.Slate, {name = "AltarTop"})
	k.box(0, 0.24, -5.42, 3.4, 0.2, 1.8, stone, M.Slate)
	local plate = k.box(0, 0.8, -4.7, 2.4, 0.95, 0.03, ink, M.SmoothPlastic, {name = "AltarPlate"})
	k.text(plate, "Back", "\u{2726} GATE OPEN \u{2726}", rune, 46)
	local key = {k.box(0, 3.05, -5.42, 0.68, 1.7, 0.68, crystal, M.Glass, {t = 0.15, ry = 45, name = "KeyCrystal"}), k.glow(0, 3.05, -5.42, 0.28, 1.4, 0.28, violet, {ry = 45, name = "KeyCore"})}
	k.anim("spin", key, 0, 3.05, -5.42, {Axis = Vector3.yAxis, Speed = 0.9, Run = 2.5})
	k.anim("spin", k.ring(0, 2.1, -5.42, 0.82, 0.07, rune, M.Neon, "y", {n = 12, depth = 0.05, name = "KeyHalo"}), 0, 2.1, -5.42, {Axis = Vector3.yAxis, Speed = -1, Run = 2})
	k.light(key[2], violet, 9, 0.9)
	-- BEHIND: a low stair down from the belt and a floor sigil that turns
	k.box(0, 0.16, 5.7, 5.4, 0.2, 0.9, stone, M.Slate, {name = "Stair"})
	k.box(0, 0.1, 6.6, 6.2, 0.1, 0.9, stoneDark, M.Slate, {name = "Stair"})
	local sigil = k.ring(0, 0.2, 6.45, 1.0, 0.07, rune, M.Neon, "y", {n = 14, depth = 0.04, name = "Sigil"})
	for i = 0, 2 do
		table.insert(sigil, k.glow(0, 0.2, 6.45, 0.07, 0.04, 1.9, rune, {ry = i * 60, name = "SigilLine"}))
	end
	k.anim("spin", sigil, 0, 0.2, 6.45, {Axis = Vector3.yAxis, Speed = 0.5, Run = 2.5})
end}

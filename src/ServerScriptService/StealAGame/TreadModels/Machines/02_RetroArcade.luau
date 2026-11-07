-- An 80s arcade blown up to full size. A real cabinet with a game playing on the screen, a giant marquee of chasing bulbs
-- with a pixel heart drifting along the top, speaker stacks that thump, an equaliser, a neon checker floor and token stacks.
return {Name = "Retro Arcade", Build = function(k)
	local rgb, M, WHITE, BLACK, V = k.rgb, k.M, k.WHITE, k.BLACK, k.V
	local cab, deep, pink, cyan, yellow, ink = rgb(62, 24, 130), rgb(30, 12, 70), rgb(255, 50, 170), rgb(50, 235, 240), rgb(255, 225, 60), rgb(14, 12, 24)
	k.deck(5, ink, M.SmoothPlastic)
	k.belt({rgb(16, 16, 22), rgb(235, 235, 240)}, M.SmoothPlastic, 4.2)
	-- neon checker floor round the machine
	for i = 0, 7 do
		for _, x in ipairs({-3.6, 3.6}) do
			k.box(x + ((i % 2 == 0) and -0.55 or 0.55), 0.03, -7.0 + i * 1.85, 1.05, 0.06, 1.85, i % 4 < 2 and pink:Lerp(ink, 0.45) or cyan:Lerp(ink, 0.45), M.SmoothPlastic, {name = "FloorTile"})
		end
	end
	k.m(function(s)
		k.box(s * 2.62, 0.45, 0, 0.5, 0.6, 10.2, deep, M.SmoothPlastic, {name = "SideRail"})
		local bulbs = {}
		for i = 0, 11 do
			table.insert(bulbs, k.ball(s * 2.62, 0.8, -4.95 + i * 0.9, 0.2, WHITE, M.Neon, {name = "Bulb" .. string.format("%02d", i)}))
		end
		k.anim("pulse", bulbs, 0, 0, 0, {Speed = 7, Stagger = -1.05, Sharp = 3, ColorA = deep, ColorB = s < 0 and pink or cyan, Run = 2.2})

		-- speaker stack, with cones that thump
		k.box(s * 3.75, 3.2, -6.7, 1.9, 6.4, 2.0, ink, M.SmoothPlastic, {name = "SpeakerStack"})
		k.box(s * 3.75, 6.45, -6.7, 2.0, 0.12, 2.1, s < 0 and pink or cyan, M.Neon)
		k.box(s * 3.75, 0.1, -6.7, 2.05, 0.2, 2.1, deep, M.SmoothPlastic)
		for i, d in ipairs({1.6, 1.25}) do
			local y = 1.6 + (i - 1) * 2.1
			for _, face in ipairs({{-7.72, -1}, {-5.68, 1}}) do
				k.cyl(s * 3.75, y, face[1], 0.05, d + 0.2, rgb(70, 70, 80), M.Metal, "z", {name = "SpeakerRim"})
				local cone = {k.cyl(s * 3.75, y, face[1] + face[2] * 0.04, 0.05, d, rgb(26, 26, 32), M.SmoothPlastic, "z", {name = "Cone"}), k.ball(s * 3.75, y, face[1] + face[2] * 0.06, d * 0.3, rgb(50, 50, 60), M.Metal, {name = "DustCap"})}
				k.anim("slide", cone, s * 3.75, y, face[1], {Offset = V(0, 0, face[2] * 0.07), Speed = 13, Idle = 0.5, Run = 1.2, Phase = i})
			end
		end
		-- equaliser up the stack's face
		local bars = {}
		for i = 0, 3 do
			table.insert(bars, k.glow(s * 3.75 - 0.54 + i * 0.36, 4.75, -5.66, 0.26, 0.6, 0.05, Color3.fromHSV(0.3 + i * 0.13, 0.85, 1), {name = "EqBar" .. i}))
		end
		k.anim("gauge", bars, 0, 0, 0, {Speed = 6, Run = 2, Idle = 0.6, Amp = 0.75, Stagger = 1.7})
		k.m(function() end)
	end)
	-- THE CABINET: the runner's console, playing pong for ever
	k.box(0, 1.95, -6.15, 3.2, 3.9, 1.9, cab, M.SmoothPlastic, {name = "Cabinet"})
	k.m(function(s)
		k.box(s * 1.64, 2.1, -6.1, 0.08, 4.2, 2.0, pink, M.SmoothPlastic, {name = "TMolding"})
	end)
	k.wedge(0, 4.12, -6.15, 3.2, 0.44, 1.9, deep, M.SmoothPlastic, {ry = 180, name = "CabinetTop"})
	k.box(0, 3.2, -5.17, 2.7, 1.5, 0.06, BLACK, M.SmoothPlastic, {name = "Bezel"})
	local screen = k.glow(0, 3.2, -5.13, 2.4, 1.25, 0.03, rgb(8, 24, 28), {name = "Screen"})
	local score = k.box(0, 3.72, -5.1, 1.4, 0.24, 0.02, rgb(8, 24, 28), M.SmoothPlastic, {t = 1, name = "Score"})
	k.text(score, "Back", "1UP  09800", yellow, 70)
	local paddleL = k.glow(-1.05, 3.2, -5.1, 0.06, 0.34, 0.02, WHITE, {name = "PaddleL"})
	local paddleR = k.glow(1.05, 3.2, -5.1, 0.06, 0.34, 0.02, WHITE, {name = "PaddleR"})
	k.anim("slide", paddleL, -1.05, 3.2, -5.1, {Offset = V(0, 0.32, 0), Speed = 2.3, Run = 1.6})
	k.anim("slide", paddleR, 1.05, 3.2, -5.1, {Offset = V(0, 0.32, 0), Speed = 2.3, Run = 1.6, Phase = 2.4})
	local ball = k.glow(0, 3.2, -5.09, 0.09, 0.09, 0.02, cyan, {name = "PongBall"})
	k.anim("travel", ball, 0, 0, 0, {Speed = 1.8, Run = 1.6, path = {V(-1, 3.1, -5.09), V(0, 3.45, -5.09), V(1, 3.0, -5.09), V(0, 2.8, -5.09), V(-1, 3.1, -5.09)}})
	k.light(screen, cyan, 7, 0.6)
	-- control deck: joystick that waggles, buttons that flash
	k.box(0, 2.4, -4.95, 3.2, 0.24, 0.9, ink, M.SmoothPlastic, {rx = -10, name = "ControlDeck"})
	local stick = {k.cyl(-0.9, 2.74, -4.9, 0.5, 0.09, rgb(200, 200, 205), M.Metal, "y", {name = "Stick"}), k.ball(-0.9, 3.03, -4.9, 0.3, rgb(235, 40, 40), M.SmoothPlastic, {name = "StickKnob"})}
	k.anim("swing", stick, -0.9, 2.5, -4.9, {Axis = Vector3.xAxis, Amp = 15, Speed = 4, Idle = 0.6, Run = 2})
	local buttons = {}
	for i, c in ipairs({yellow, cyan, rgb(90, 255, 110), pink}) do
		table.insert(buttons, k.cyl(-0.1 + i * 0.38, 2.57, -4.9, 0.08, 0.26, c, M.Neon, "y", {name = "Btn" .. i}))
	end
	k.anim("pulse", buttons, 0, 0, 0, {Speed = 5, Stagger = 1.6, Sharp = 2, TransA = 0.6, TransB = 0})
	-- the cabinet's outward face: art for the path
	local art = k.box(0, 1.95, -7.12, 3.0, 3.6, 0.04, deep, M.SmoothPlastic, {name = "SideArt"})
	k.text(art, "Front", "INSERT\nCOIN", cyan, 40)
	k.glow(-0.3, 0.8, -7.15, 0.18, 0.5, 0.03, yellow, {name = "CoinSlot"})
	k.glow(0.3, 0.8, -7.15, 0.18, 0.5, 0.03, yellow, {name = "CoinSlot"})
	-- THE MARQUEE overhead, from stack to stack
	local sign = k.box(0, 8.1, -6.7, 9.2, 1.7, 1.0, ink, M.SmoothPlastic, {name = "Marquee"})
	k.text(sign, "Front", "ARCADE", pink, 34)
	k.text(sign, "Back", "ARCADE", cyan, 34)
	k.m(function(s)
		k.box(s * 3.75, 6.95, -6.7, 0.5, 1.0, 0.5, deep, M.Metal, {name = "MarqueeLeg"})
	end)
	for _, z in ipairs({-7.24, -6.16}) do
		local chase = {}
		for i = 0, 15 do
			table.insert(chase, k.ball(-4.2 + i * 0.56, 9.0, z, 0.24, WHITE, M.Neon, {name = "Top" .. string.format("%02d", i)}))
			table.insert(chase, k.ball(-4.2 + i * 0.56, 7.36, z, 0.24, WHITE, M.Neon, {name = "Low" .. string.format("%02d", i)}))
		end
		k.anim("pulse", chase, 0, 0, 0, {Speed = 6, Stagger = 0.8, Sharp = 2, ColorA = deep, ColorB = yellow, Run = 2})
	end
	-- a pixel heart, one extra life, drifting along the top
	local shape = {
		".##...##.",
		"#w##.####",
		"#########",
		"#########",
		".#######.",
		"..#####..",
		"...###...",
		"....#....",
	}
	local cube = 0.3
	local heart = {}
	for row, line in ipairs(shape) do
		for col = 1, #line do
			local c = line:sub(col, col)
			if c ~= "." then
				table.insert(heart, k.box((col - 5) * cube, 9.3 + (#shape - row) * cube, -6.7, cube, cube, cube * 1.2, c == "w" and WHITE or rgb(235, 30, 80), c == "w" and M.SmoothPlastic or M.Neon, {name = "Pixel"}))
			end
		end
	end
	k.anim("slide", heart, 0, 0, 0, {Offset = V(2.5, 0, 0), Speed = 0.9, Run = 1.8})
	k.light(k.spot(0, 9.2, -6.7), pink, 14, 1)
	-- behind: stacks of tokens spinning on a plinth, a giant controller on the floor
	k.m(function(s)
		k.cyl(s * 3.4, 0.25, 6.2, 0.5, 1.6, deep, M.SmoothPlastic, "y", {name = "TokenPlinth"})
		local token = {k.cyl(s * 3.4, 1.35, 6.2, 0.14, 1.2, yellow, M.Foil, "z", {name = "Token"}), k.cyl(s * 3.4, 1.35, 6.2, 0.17, 0.75, rgb(255, 170, 30), M.Foil, "z", {name = "TokenFace"})}
		k.anim("spin", token, s * 3.4, 1.35, 6.2, {Axis = Vector3.yAxis, Speed = s * 1.6, Run = 2.5})
	end)
	k.box(0, 0.2, 6.3, 3.2, 0.3, 1.5, rgb(60, 62, 72), M.SmoothPlastic, {name = "Controller"})
	k.box(-0.95, 0.38, 6.3, 0.7, 0.08, 0.24, ink, M.SmoothPlastic)
	k.box(-0.95, 0.38, 6.3, 0.24, 0.08, 0.7, ink, M.SmoothPlastic)
	k.cyl(0.8, 0.4, 6.1, 0.1, 0.3, rgb(235, 40, 40), M.SmoothPlastic, "y")
	k.cyl(1.25, 0.4, 6.5, 0.1, 0.3, rgb(235, 40, 40), M.SmoothPlastic, "y")
	-- square pixel confetti while someone's running
	k.emit(k.spot(0, 9.8, -6.7, 8, 0.2, 0.6), {tex = "sparkle", c1 = pink, c2 = cyan, size = {0.3, 0.05}, life = {0.7, 1.4}, speed = {1, 2}, rate = 0, run = 12, dir = "Bottom", spread = {25, 25}, accel = V(0, -6, 0)})
end}

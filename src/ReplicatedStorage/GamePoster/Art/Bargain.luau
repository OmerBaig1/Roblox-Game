-- Bargain Basement posters (Common)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local A = {}

A["Pang"] = function(k)
	k.sky(rgb(12, 12, 22), rgb(28, 28, 45))
	for y = 0.06, 0.96, 0.1 do
		k.rect(0.5, y, 0.012, 0.05, W, {t = 0.5})
	end
	k.rect(0.08, 0.38, 0.03, 0.26, W)
	k.rect(0.92, 0.66, 0.03, 0.26, W)
	P.sq(k, 0.3, 0.5, 0.045, W)
	for i = 1, 3 do
		P.sq(k, 0.3 - i * 0.05, 0.5 - i * 0.05, 0.03, W, {t = 0.25 * i})
	end
	P.star(k, 0.68, 0.32, 0.34, rgb(255, 210, 50))
	k.text(0.68, 0.32, 0.26, 0.18, "PANG!", rgb(230, 40, 40))
end

A["Wee Sports Bowling"] = function(k)
	k.sky(rgb(150, 210, 255), rgb(235, 245, 255))
	k.rect(0.5, 0.8, 1.04, 0.42, rgb(220, 175, 115))
	k.rect(0.5, 0.6, 1.04, 0.03, rgb(170, 120, 70))
	for _, p in ipairs({{0.78, 0.53}, {0.74, 0.55}, {0.82, 0.55}, {0.7, 0.57}, {0.78, 0.57}, {0.86, 0.57}}) do
		k.ellipse(p[1], p[2], 0.025, 0.08, W)
		k.rect(p[1], p[2] - 0.015, 0.025, 0.01, rgb(220, 40, 40))
	end
	k.circle(0.3, 0.72, 0.17, rgb(50, 90, 220))
	for _, h in ipairs({{0.28, 0.68}, {0.33, 0.68}, {0.305, 0.74}}) do
		k.circle(h[1], h[2], 0.025, rgb(20, 30, 70))
	end
	k.text(0.4, 0.25, 0.5, 0.26, "wee!", rgb(255, 120, 60), {stroke = true})
end

A["Marco Kart"] = function(k)
	k.sky(rgb(100, 190, 255), rgb(205, 240, 255))
	k.ellipse(0.2, 0.62, 0.6, 0.3, rgb(90, 190, 90))
	k.ellipse(0.75, 0.64, 0.7, 0.32, rgb(70, 170, 80))
	local stripes = {rgb(255, 80, 80), rgb(255, 200, 60), rgb(80, 220, 120), rgb(80, 160, 255), rgb(180, 100, 255)}
	for i, c in ipairs(stripes) do
		k.rect(0.5, 0.72 + i * 0.05, 1.04, 0.05, c)
	end
	for i = 1, 3 do
		k.rect(0.12, 0.68 + i * 0.05, 0.14, 0.012, W, {t = 0.2})
	end
	P.kart(k, 0.5, 0.73, 1.4, rgb(230, 50, 50))
	P.flag(k, 0.85, 0.2, 1)
end

A["Flappy Bard"] = function(k)
	k.sky(rgb(120, 200, 255), rgb(205, 240, 255))
	local stone = rgb(150, 150, 160)
	k.rect(0.12, 0.12, 0.15, 0.3, stone)
	k.rect(0.12, 0.88, 0.15, 0.3, stone)
	k.rect(0.88, 0.18, 0.15, 0.4, stone)
	k.rect(0.88, 0.92, 0.15, 0.22, stone)
	local purple = rgb(150, 90, 220)
	k.ellipse(0.53, 0.68, 0.1, 0.13, rgb(150, 95, 50), {rot = 20})
	k.rect(0.6, 0.58, 0.015, 0.16, rgb(110, 70, 35), {rot = 40})
	k.circle(0.48, 0.52, 0.24, purple)
	k.ellipse(0.41, 0.55, 0.13, 0.08, purple:Lerp(W, 0.3), {rot = -20})
	k.rect(0.6, 0.53, 0.06, 0.05, rgb(255, 160, 40), {rot = 45})
	k.circle(0.53, 0.46, 0.06, W)
	k.circle(0.545, 0.46, 0.03, B)
	k.rect(0.46, 0.33, 0.16, 0.06, rgb(200, 40, 50), {rot = -8, round = 0.4})
	k.ellipse(0.4, 0.27, 0.035, 0.12, GOLD, {rot = -35})
	k.text(0.75, 0.42, 0.1, 0.14, "♪", W, {stroke = true})
end

A["Cookie Klicker"] = function(k)
	k.sky(rgb(70, 45, 35), rgb(130, 85, 55))
	k.circle(0.48, 0.52, 0.58, rgb(200, 140, 70))
	k.circle(0.48, 0.52, 0.52, rgb(225, 165, 95))
	for _, c in ipairs({{0.36, 0.38}, {0.55, 0.32}, {0.62, 0.52}, {0.42, 0.6}, {0.52, 0.72}, {0.32, 0.62}, {0.5, 0.48}, {0.66, 0.68}}) do
		k.circle(c[1], c[2], 0.05, rgb(75, 45, 25))
	end
	for _, t in ipairs({{0.85, 0.2}, {0.12, 0.25}, {0.88, 0.78}, {0.14, 0.86}}) do
		k.text(t[1], t[2], 0.16, 0.12, "+1", W, {stroke = true})
	end
end

A["Temple Ruin"] = function(k)
	k.sky(rgb(255, 170, 90), rgb(255, 230, 170))
	k.circle(0.75, 0.3, 0.2, rgb(255, 240, 180))
	local stone = rgb(185, 170, 140)
	k.rect(0.6, 0.83, 0.7, 0.08, stone:Lerp(B, 0.2))
	k.rect(0.6, 0.3, 0.62, 0.06, stone)
	for _, x in ipairs({0.36, 0.52, 0.68}) do
		k.rect(x, 0.56, 0.06, 0.46, stone)
	end
	k.rect(0.86, 0.65, 0.06, 0.32, stone, {rot = 25})
	for _, r in ipairs({{0.78, 0.82, 0.06}, {0.9, 0.84, 0.05}, {0.83, 0.86, 0.04}}) do
		k.circle(r[1], r[2], r[3], stone:Lerp(B, 0.3))
	end
	k.ellipse(0.5, 0.97, 1.1, 0.12, rgb(70, 140, 60))
	P.person(k, 0.14, 0.62, 0.9, rgb(230, 60, 60))
	for i = 1, 3 do
		k.rect(0.05 - i * 0.0, 0.58 + i * 0.04, 0.06, 0.01, W, {t = 0.3})
	end
end

A["FIFO Soccer 98"] = function(k)
	for i = 0, 5 do
		k.rect(0.083 + i * 0.167, 0.5, 0.167, 1.02, i % 2 == 0 and rgb(50, 150, 65) or rgb(40, 130, 55))
	end
	k.rect(0.93, 0.6, 0.012, 0.4, W)
	k.rect(0.87, 0.41, 0.12, 0.012, W)
	k.rect(0.87, 0.79, 0.12, 0.012, W)
	for x = 0.875, 0.93, 0.025 do
		k.rect(x, 0.6, 0.004, 0.37, W, {t = 0.6})
	end
	for i, x in ipairs({0.16, 0.38, 0.64}) do
		local d = 0.12 + i * 0.025
		k.circle(x, 0.62, d, W)
		P.sq(k, x, 0.62, d * 0.28, B, {rot = 45})
		for _, a in ipairs({0, 72, 144, 216, 288}) do
			k.circle(x + math.sin(math.rad(a)) * d * 0.42, 0.62 - math.cos(math.rad(a)) * d * 0.42 / 0.775, d * 0.16, B)
		end
	end
	for _, x in ipairs({0.27, 0.51, 0.78}) do
		k.text(x, 0.62, 0.06, 0.1, "→", W)
	end
	k.text(0.5, 0.17, 0.4, 0.26, "98", GOLD, {stroke = true})
end

A["Golf With Your Foes"] = function(k)
	k.sky(rgb(130, 200, 255), rgb(220, 245, 255))
	k.ellipse(0.5, 0.92, 1.3, 0.5, rgb(90, 190, 90))
	k.ellipse(0.78, 0.72, 0.1, 0.04, B)
	k.rect(0.79, 0.48, 0.01, 0.48, W)
	k.rect(0.84, 0.3, 0.1, 0.1, rgb(230, 50, 50))
	for _, b in ipairs({{0.25, 0.62}, {0.52, 0.66}}) do
		k.circle(b[1], b[2], 0.2, W)
		P.eyes(k, b[1], b[2] - 0.02, 0.05, 0.07, b[1] < 0.4 and 1 or -1)
		P.brows(k, b[1], b[2] - 0.08, 0.05, 0.07, 22)
		k.rect(b[1], b[2] + 0.06, 0.06, 0.015, B)
	end
	P.lightning(k, 0.39, 0.4, 0.8)
end

A["Rusty League"] = function(k)
	k.sky(rgb(255, 160, 90), rgb(255, 220, 160))
	for i = 0, 2 do
		k.ellipse(0.12, 0.85 - i * 0.07, 0.16, 0.08, rgb(35, 35, 40))
		k.ellipse(0.12, 0.85 - i * 0.07, 0.07, 0.03, rgb(90, 80, 70))
	end
	k.rect(0.5, 0.95, 1.04, 0.12, rgb(140, 110, 80))
	k.circle(0.7, 0.4, 0.34, W)
	for _, s in ipairs({{0.7, 0.4}, {0.6, 0.32}, {0.8, 0.32}, {0.62, 0.52}, {0.78, 0.52}}) do
		k.circle(s[1], s[2], 0.06, B)
	end
	local rust = rgb(170, 85, 40)
	k.rect(0.36, 0.73, 0.44, 0.13, rust, {round = 0.25})
	k.rect(0.42, 0.62, 0.18, 0.12, rust, {round = 0.2})
	k.rect(0.43, 0.62, 0.13, 0.07, rgb(150, 200, 230))
	for _, s in ipairs({{0.25, 0.7}, {0.3, 0.76}, {0.5, 0.72}}) do
		k.circle(s[1], s[2], 0.03, rgb(110, 55, 25))
	end
	for _, x in ipairs({0.24, 0.48}) do
		k.circle(x, 0.82, 0.1, B)
		k.circle(x, 0.82, 0.04, rgb(150, 150, 150))
	end
end

A["Saleway Surfers"] = function(k)
	k.sky(rgb(255, 120, 180), rgb(255, 205, 120))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(90, 90, 100))
	local metal = rgb(190, 195, 205)
	k.rect(0.45, 0.7, 0.36, 0.18, metal, {t = 0.1})
	for x = 0.3, 0.6, 0.06 do
		k.rect(x, 0.7, 0.008, 0.18, rgb(130, 135, 145))
	end
	k.rect(0.68, 0.6, 0.12, 0.012, metal, {rot = -30})
	for _, x in ipairs({0.32, 0.58}) do
		k.circle(x, 0.84, 0.06, B)
	end
	P.person(k, 0.44, 0.38, 1, rgb(60, 200, 255))
	k.rect(0.37, 0.4, 0.1, 0.02, P.SKIN, {rot = -30})
	k.rect(0.51, 0.4, 0.1, 0.02, P.SKIN, {rot = 30})
	for _, t in ipairs({{0.16, 0.25, -15}, {0.84, 0.3, 12}}) do
		k.rect(t[1], t[2], 0.2, 0.12, GOLD, {rot = t[3], round = 0.15})
		k.text(t[1], t[2], 0.17, 0.09, "50%", rgb(200, 30, 30), {rot = t[3]})
	end
	k.text(0.5, 0.1, 0.5, 0.14, "SALE!", W, {stroke = true})
end

A["Pac-Can"] = function(k)
	k.sky(rgb(10, 10, 40), rgb(15, 15, 55))
	local wall = rgb(50, 80, 255)
	k.rect(0.5, 0.05, 0.95, 0.02, wall)
	k.rect(0.5, 0.95, 0.95, 0.02, wall)
	k.rect(0.03, 0.5, 0.015, 0.9, wall)
	k.rect(0.97, 0.5, 0.015, 0.9, wall)
	k.rect(0.75, 0.3, 0.3, 0.02, wall)
	k.rect(0.75, 0.78, 0.3, 0.02, wall)
	for x = 0.55, 0.92, 0.09 do
		k.circle(x, 0.54, 0.03, rgb(255, 220, 120))
	end
	P.can(k, 0.3, 0.55, 0.26, 0.5, rgb(220, 60, 50), "CAN", W)
	k.ellipse(0.3, 0.26, 0.26, 0.08, rgb(205, 205, 215), {rot = -25})
	P.eyes(k, 0.3, 0.42, 0.06, 0.09, 1)
	k.ellipse(0.3, 0.7, 0.12, 0.08, B)
end

A["Tetrus"] = function(k)
	k.sky(rgb(30, 20, 60), rgb(60, 35, 100))
	local colors = {rgb(255, 80, 80), rgb(255, 200, 60), rgb(80, 220, 120), rgb(80, 170, 255), rgb(190, 110, 255), rgb(255, 140, 60)}
	local s = 0.1
	local heights = {3, 2, 4, 3, 1, 2, 3, 4, 2, 3}
	for col = 0, 9 do
		for row = 1, heights[col + 1] do
			P.sq(k, 0.05 + col * s, 1 - row * s / 0.775 + s / 0.775 / 2, s * 0.92, colors[(col * 3 + row) % #colors + 1])
		end
	end
	local c = colors[5]
	for _, p in ipairs({{0.45, 0.12}, {0.55, 0.12}, {0.65, 0.12}, {0.55, 0.25}}) do
		P.sq(k, p[1], p[2], s * 0.92, c)
	end
	k.rect(0.55, 0.36, 0.01, 0.08, W, {t = 0.5})
end

A["Monopawly"] = function(k)
	k.sky(rgb(200, 230, 200), rgb(170, 210, 170))
	local cells = {rgb(150, 80, 50), rgb(130, 200, 255), rgb(230, 80, 170), rgb(255, 150, 40), rgb(230, 40, 40), rgb(255, 230, 50), rgb(40, 170, 90), rgb(30, 70, 180)}
	for i = 0, 7 do
		k.rect(0.0625 + i * 0.125, 0.06, 0.12, 0.1, cells[i + 1])
		k.rect(0.0625 + i * 0.125, 0.94, 0.12, 0.1, cells[8 - i])
	end
	local paw = rgb(110, 70, 45)
	k.ellipse(0.38, 0.6, 0.2, 0.22, paw)
	for _, t in ipairs({{0.27, 0.42}, {0.34, 0.34}, {0.43, 0.34}, {0.5, 0.42}}) do
		k.circle(t[1], t[2], 0.07, paw)
	end
	for _, d in ipairs({{0.72, 0.45, 15}, {0.8, 0.65, -10}}) do
		P.sq(k, d[1], d[2], 0.13, W, {rot = d[3], round = 0.15})
		k.circle(d[1], d[2], 0.025, B)
	end
end

A["Trollercoaster Tycoon"] = function(k)
	k.sky(rgb(110, 190, 255), rgb(220, 240, 255))
	k.ellipse(0.5, 1, 1.2, 0.2, rgb(90, 180, 90))
	local track = rgb(200, 60, 60)
	for i = 0, 40 do
		local x = i / 40
		local y = 0.75 - math.sin(x * math.pi * 1.5) * 0.45
		if y < 0.85 then
			k.circle(x, y, 0.03, track)
			if i % 5 == 0 then
				k.rect(x, (y + 1) / 2, 0.01, 1 - y, rgb(150, 150, 160))
			end
		end
	end
	local x, y = 0.33, 0.75 - math.sin(0.33 * math.pi * 1.5) * 0.45
	k.rect(x, y - 0.06, 0.16, 0.08, rgb(255, 200, 40), {round = 0.3})
	local troll = rgb(110, 180, 80)
	k.ellipse(x - 0.07, y - 0.17, 0.06, 0.04, troll, {rot = -20})
	k.ellipse(x + 0.07, y - 0.17, 0.06, 0.04, troll, {rot = 20})
	k.circle(x, y - 0.16, 0.13, troll)
	k.rect(x, y - 0.28, 0.02, 0.06, rgb(255, 80, 150), {rot = 10})
	P.eyes(k, x, y - 0.18, 0.035, 0.05, 1)
	k.ellipse(x, y - 0.12, 0.07, 0.03, B)
end

A["Animal Bossing"] = function(k)
	k.sky(rgb(220, 210, 190), rgb(190, 175, 150))
	k.rect(0.78, 0.3, 0.22, 0.25, rgb(140, 200, 255))
	k.rect(0.78, 0.3, 0.01, 0.25, W)
	k.rect(0.42, 0.75, 0.6, 0.4, rgb(30, 45, 90), {round = 0.25})
	k.rect(0.42, 0.7, 0.04, 0.2, rgb(220, 40, 40))
	local fur = rgb(255, 160, 60)
	P.sq(k, 0.33, 0.24, 0.1, fur, {rot = 45})
	P.sq(k, 0.51, 0.24, 0.1, fur, {rot = 45})
	k.circle(0.42, 0.4, 0.3, fur)
	P.eyes(k, 0.42, 0.37, 0.06, 0.12)
	k.ellipse(0.42, 0.46, 0.04, 0.03, rgb(255, 120, 150))
	for _, w in ipairs({{0.3, 0.47, 10}, {0.54, 0.47, -10}}) do
		k.rect(w[1], w[2], 0.12, 0.008, B, {rot = w[3]})
	end
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(110, 70, 40))
	k.rect(0.82, 0.8, 0.12, 0.16, W, {round = 0.15})
	k.text(0.82, 0.8, 0.11, 0.07, "BOSS", rgb(200, 40, 40))
end

return A

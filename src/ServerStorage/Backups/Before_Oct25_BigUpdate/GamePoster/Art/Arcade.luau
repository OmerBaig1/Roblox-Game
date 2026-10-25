-- Retro Arcade posters (Uncommon)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local A = {}

local function pixelGrid(k, color)
	for i = 1, 9 do
		k.rect(i / 10, 0.5, 0.004, 1, color, {t = 0.8})
		k.rect(0.5, i / 10, 1, 0.005, color, {t = 0.8})
	end
end

A["Super Mario Bruhs"] = function(k)
	k.sky(rgb(255, 120, 60), rgb(255, 210, 110))
	pixelGrid(k, W)
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(120, 70, 40))
	P.person(k, 0.3, 0.55, 1.5, rgb(60, 120, 230))
	P.person(k, 0.68, 0.55, 1.5, rgb(240, 200, 40), rgb(140, 95, 60))
	k.rect(0.3, 0.44, 0.06, 0.012, B)
	k.rect(0.68, 0.44, 0.06, 0.012, B)
	k.rect(0.3, 0.38, 0.06, 0.012, B)
	k.rect(0.68, 0.38, 0.06, 0.012, B)
	P.bubble(k, 0.5, 0.17, 0.42, 0.2, "BRUH")
end

A["The Legend of Zelma"] = function(k)
	k.sky(rgb(90, 160, 90), rgb(40, 100, 60))
	k.ellipse(0.5, 0.98, 1.2, 0.25, rgb(70, 130, 60))
	local grey = rgb(200, 200, 210)
	k.rect(0.5, 0.65, 0.2, 0.3, rgb(170, 60, 120), {round = 0.25})
	k.circle(0.5, 0.4, 0.17, P.SKIN)
	k.circle(0.5, 0.28, 0.12, grey)
	k.circle(0.44, 0.4, 0.06, W, {t = 0.3})
	k.circle(0.56, 0.4, 0.06, W, {t = 0.3})
	k.rect(0.5, 0.4, 0.04, 0.008, B)
	k.circle(0.44, 0.4, 0.02, B)
	k.circle(0.56, 0.4, 0.02, B)
	k.ellipse(0.5, 0.47, 0.05, 0.02, rgb(200, 90, 90))
	k.rect(0.72, 0.5, 0.02, 0.4, rgb(220, 225, 235), {rot = 20})
	k.rect(0.66, 0.66, 0.08, 0.025, GOLD, {rot = 20})
	k.circle(0.3, 0.72, 0.1, rgb(240, 120, 160))
	k.rect(0.3, 0.72, 0.1, 0.006, rgb(200, 80, 120), {rot = 30})
	k.rect(0.36, 0.62, 0.006, 0.18, rgb(190, 160, 120), {rot = -30})
end

A["Pocketmon Red"] = function(k)
	k.sky(rgb(60, 90, 160), rgb(40, 60, 120))
	local denim = rgb(70, 110, 180)
	k.rect(0.5, 0.65, 0.7, 0.6, denim, {round = 0.1})
	k.rect(0.5, 0.42, 0.7, 0.012, rgb(230, 180, 80))
	k.rect(0.5, 0.92, 0.66, 0.012, rgb(230, 180, 80))
	k.circle(0.5, 0.4, 0.32, rgb(230, 50, 60))
	P.eyes(k, 0.5, 0.36, 0.08, 0.13)
	k.ellipse(0.5, 0.45, 0.06, 0.04, B)
	k.rect(0.5, 0.44, 0.74, 0.1, denim)
	k.rect(0.5, 0.4, 0.74, 0.015, rgb(230, 180, 80))
	k.circle(0.35, 0.42, 0.08, rgb(230, 50, 60))
	k.circle(0.65, 0.42, 0.08, rgb(230, 50, 60))
end

A["Sweet Fighter II"] = function(k)
	k.sky(rgb(255, 140, 200), rgb(255, 220, 150))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(200, 120, 200))
	k.rect(0.28, 0.75, 0.025, 0.3, W)
	k.circle(0.28, 0.45, 0.3, rgb(255, 80, 120))
	k.circle(0.28, 0.45, 0.2, rgb(255, 230, 240))
	k.circle(0.28, 0.45, 0.1, rgb(255, 80, 120))
	k.ellipse(0.74, 0.62, 0.3, 0.38, rgb(90, 220, 140))
	P.eyes(k, 0.74, 0.55, 0.06, 0.1, -1)
	P.brows(k, 0.74, 0.49, 0.06, 0.1)
	for _, g in ipairs({{0.46, 0.5}, {0.56, 0.5}}) do
		k.circle(g[1], g[2], 0.12, rgb(220, 30, 40))
	end
	k.text(0.5, 0.18, 0.3, 0.2, "VS", GOLD, {stroke = true})
end

A["Monkey Kong"] = function(k)
	k.sky(rgb(110, 30, 30), rgb(200, 80, 40))
	k.rect(0.68, 0.62, 0.02, 0.4, rgb(90, 60, 30))
	k.circle(0.68, 0.38, 0.5, rgb(230, 180, 60))
	k.circle(0.68, 0.38, 0.38, rgb(250, 210, 90))
	k.circle(0.68, 0.38, 0.08, rgb(200, 150, 40))
	local fur = rgb(120, 75, 40)
	k.ellipse(0.27, 0.72, 0.26, 0.34, fur)
	k.circle(0.27, 0.45, 0.22, fur)
	k.circle(0.17, 0.42, 0.07, fur)
	k.circle(0.37, 0.42, 0.07, fur)
	k.ellipse(0.27, 0.49, 0.14, 0.12, rgb(230, 190, 150))
	P.eyes(k, 0.27, 0.42, 0.04, 0.07, 1)
	k.rect(0.42, 0.5, 0.2, 0.02, rgb(160, 110, 60), {rot = -30})
	k.circle(0.51, 0.44, 0.05, rgb(150, 100, 50))
	P.star(k, 0.56, 0.36, 0.1, W)
end

A["Galagoo"] = function(k, rng)
	k.sky(rgb(5, 5, 25), rgb(20, 10, 50))
	k.stars(18, rng, 0.95)
	local goo = rgb(120, 255, 90)
	for _, g in ipairs({{0.25, 0.22}, {0.5, 0.18}, {0.75, 0.22}, {0.38, 0.38}, {0.62, 0.38}}) do
		k.ellipse(g[1], g[2], 0.14, 0.1, goo)
		k.circle(g[1] - 0.03, g[2] + 0.06, 0.03, goo)
		k.circle(g[1] + 0.04, g[2] + 0.07, 0.025, goo)
		P.eyes(k, g[1], g[2] - 0.01, 0.03, 0.045)
	end
	k.rect(0.5, 0.62, 0.012, 0.1, rgb(255, 240, 80))
	k.rect(0.5, 0.84, 0.18, 0.06, W, {round = 0.3})
	k.rect(0.5, 0.79, 0.05, 0.08, W)
	k.rect(0.44, 0.88, 0.04, 0.05, rgb(230, 50, 60))
	k.rect(0.56, 0.88, 0.04, 0.05, rgb(230, 50, 60))
end

A["Sanic the Hedgehog"] = function(k)
	k.sky(rgb(80, 180, 255), rgb(200, 240, 255))
	for i = 0, 4 do
		k.rect(0.18, 0.35 + i * 0.08, 0.3, 0.02, W, {t = 0.2 + i * 0.1})
	end
	k.rect(0.55, 0.62, 0.3, 0.5, rgb(140, 220, 255), {round = 0.15, t = 0.1})
	k.rect(0.55, 0.68, 0.3, 0.2, W)
	k.text(0.55, 0.68, 0.26, 0.12, "CLEAN", rgb(40, 120, 220))
	k.rect(0.55, 0.32, 0.1, 0.1, W)
	k.rect(0.6, 0.26, 0.12, 0.04, W)
	P.eyes(k, 0.55, 0.47, 0.05, 0.08, 1)
	k.ellipse(0.55, 0.55, 0.06, 0.025, B)
	for _, x in ipairs({0.48, 0.62}) do
		k.ellipse(x, 0.9, 0.1, 0.06, rgb(220, 40, 40))
	end
	P.star(k, 0.86, 0.2, 0.1, W)
end

A["Castlevanilla"] = function(k, rng)
	k.sky(rgb(40, 20, 70), rgb(120, 60, 120))
	k.stars(10, rng, 0.4)
	P.moon(k, 0.82, 0.18, 0.13)
	local cone = rgb(210, 160, 90)
	k.rect(0.5, 0.85, 0.5, 0.3, cone)
	for x = 0.3, 0.7, 0.08 do
		k.rect(x, 0.85, 0.008, 0.3, cone:Lerp(B, 0.25), {rot = 25})
	end
	local cream = rgb(255, 245, 215)
	for _, t in ipairs({{0.32, 0.52, 0.1, 0.3}, {0.68, 0.52, 0.1, 0.3}, {0.5, 0.46, 0.14, 0.4}}) do
		k.rect(t[1], t[2], t[3], t[4], cream)
		k.circle(t[1], t[2] - t[4] / 2, t[3] * 1.15, cream)
	end
	k.rect(0.5, 0.65, 0.5, 0.12, cream)
	for _, x in ipairs({0.3, 0.42, 0.58, 0.7}) do
		k.circle(x, 0.71, 0.08, cream)
	end
	k.rect(0.5, 0.62, 0.06, 0.1, rgb(120, 70, 40), {round = 0.5})
	k.circle(0.5, 0.18, 0.05, rgb(220, 30, 50))
end

A["Metro-Void"] = function(k)
	k.sky(rgb(40, 40, 55), rgb(70, 70, 85))
	k.circle(0.72, 0.48, 0.6, rgb(90, 30, 140))
	k.circle(0.72, 0.48, 0.45, rgb(40, 10, 70))
	k.circle(0.72, 0.48, 0.3, B)
	k.rect(0.5, 0.86, 1.04, 0.04, rgb(110, 110, 120))
	for x = 0.02, 1, 0.08 do
		k.rect(x, 0.9, 0.04, 0.03, rgb(90, 60, 40))
	end
	k.rect(0.32, 0.66, 0.52, 0.3, rgb(220, 220, 230), {round = 0.15})
	k.rect(0.32, 0.6, 0.48, 0.1, rgb(100, 180, 240))
	for x = 0.14, 0.52, 0.12 do
		k.rect(x, 0.6, 0.008, 0.1, rgb(220, 220, 230))
	end
	k.rect(0.32, 0.74, 0.52, 0.03, rgb(230, 60, 60))
	k.circle(0.56, 0.68, 0.05, rgb(255, 240, 150))
end

A["Space Raiders"] = function(k, rng)
	k.sky(rgb(10, 10, 35), rgb(40, 20, 70))
	k.stars(16, rng, 0.95)
	P.planet(k, 0.82, 0.22, 0.2, rgb(240, 150, 80), rgb(255, 220, 160))
	P.astronaut(k, 0.42, 0.52, 1.6, rgb(150, 150, 160))
	k.rect(0.42, 0.37, 0.18, 0.045, B, {round = 0.4})
	k.circle(0.38, 0.37, 0.025, W)
	k.circle(0.46, 0.37, 0.025, W)
	k.ellipse(0.66, 0.7, 0.2, 0.22, rgb(200, 180, 140))
	k.rect(0.66, 0.6, 0.06, 0.03, rgb(150, 120, 80))
	k.text(0.66, 0.72, 0.1, 0.12, "$", rgb(60, 140, 60))
end

A["Froggo"] = function(k)
	k.sky(rgb(60, 140, 200), rgb(40, 100, 160))
	local log = rgb(140, 95, 55)
	k.rect(0.25, 0.3, 0.45, 0.1, log, {round = 0.5})
	k.rect(0.72, 0.55, 0.5, 0.1, log, {round = 0.5})
	k.rect(0.3, 0.82, 0.5, 0.1, log, {round = 0.5})
	local frog = rgb(90, 200, 80)
	k.ellipse(0.55, 0.52, 0.24, 0.2, frog)
	k.circle(0.48, 0.42, 0.08, frog)
	k.circle(0.62, 0.42, 0.08, frog)
	k.circle(0.48, 0.42, 0.045, W)
	k.circle(0.62, 0.42, 0.045, W)
	k.circle(0.48, 0.42, 0.022, B)
	k.circle(0.62, 0.42, 0.022, B)
	k.ellipse(0.55, 0.55, 0.1, 0.02, rgb(40, 120, 40))
	k.ellipse(0.43, 0.6, 0.08, 0.04, frog, {rot = 30})
	k.ellipse(0.67, 0.6, 0.08, 0.04, frog, {rot = -30})
	k.rect(0.55, 0.35, 0.1, 0.03, GOLD)
	for _, x in ipairs({0.51, 0.55, 0.59}) do
		P.sq(k, x, 0.32, 0.025, GOLD, {rot = 45})
	end
end

A["Mega Dan"] = function(k)
	k.sky(rgb(40, 60, 140), rgb(90, 140, 220))
	P.star(k, 0.5, 0.45, 0.85, rgb(255, 210, 60))
	local skin, shirt = P.SKIN, rgb(230, 60, 60)
	k.rect(0.5, 0.65, 0.3, 0.3, shirt, {round = 0.25})
	k.ellipse(0.27, 0.48, 0.16, 0.12, skin)
	k.ellipse(0.73, 0.48, 0.16, 0.12, skin)
	k.rect(0.32, 0.58, 0.08, 0.16, skin, {rot = 20, round = 0.4})
	k.rect(0.68, 0.58, 0.08, 0.16, skin, {rot = -20, round = 0.4})
	k.circle(0.5, 0.38, 0.17, skin)
	k.rect(0.5, 0.3, 0.17, 0.06, rgb(120, 80, 40), {round = 0.5})
	P.eyes(k, 0.5, 0.38, 0.035, 0.06)
	k.ellipse(0.5, 0.45, 0.06, 0.025, B)
	k.text(0.5, 0.88, 0.5, 0.16, "MEGA", W, {stroke = true})
end

A["Prance Prance Revolution"] = function(k)
	k.sky(rgb(40, 10, 70), rgb(120, 30, 140))
	local tiles = {rgb(255, 80, 160), rgb(80, 200, 255), rgb(255, 220, 60), rgb(120, 255, 140)}
	for i = 0, 3 do
		for j = 0, 1 do
			k.rect(0.14 + i * 0.24, 0.78 + j * 0.13, 0.22, 0.12, tiles[(i + j) % 4 + 1], {t = 0.2})
		end
	end
	local horse = rgb(250, 245, 255)
	k.ellipse(0.5, 0.5, 0.36, 0.2, horse)
	for _, l in ipairs({{0.38, 0.66, 20}, {0.44, 0.67, -10}, {0.58, 0.66, 30}, {0.64, 0.64, -25}}) do
		k.rect(l[1], l[2], 0.03, 0.17, horse, {rot = l[3]})
	end
	k.rect(0.68, 0.37, 0.07, 0.2, horse, {rot = 30})
	k.ellipse(0.75, 0.27, 0.14, 0.09, horse, {rot = 20})
	k.circle(0.75, 0.25, 0.025, B)
	for i, c in ipairs({rgb(255, 80, 160), rgb(255, 220, 60), rgb(80, 200, 255)}) do
		k.ellipse(0.62 - i * 0.02, 0.27 + i * 0.05, 0.05, 0.1, c, {rot = 30})
	end
	k.ellipse(0.3, 0.48, 0.12, 0.06, rgb(255, 120, 200), {rot = -30})
	k.text(0.2, 0.18, 0.18, 0.18, "♫", GOLD)
end

A["Mortal Wombat"] = function(k)
	k.sky(rgb(60, 20, 20), rgb(200, 90, 30))
	k.circle(0.5, 0.42, 0.62, rgb(255, 160, 50), {t = 0.5})
	local fur = rgb(140, 105, 80)
	k.ellipse(0.5, 0.75, 0.46, 0.4, fur)
	k.circle(0.5, 0.45, 0.36, fur)
	k.circle(0.36, 0.3, 0.09, fur)
	k.circle(0.64, 0.3, 0.09, fur)
	k.ellipse(0.5, 0.53, 0.14, 0.09, rgb(70, 50, 40))
	k.rect(0.5, 0.36, 0.38, 0.05, rgb(220, 30, 40))
	k.rect(0.72, 0.42, 0.06, 0.12, rgb(220, 30, 40), {rot = -30})
	P.eyes(k, 0.5, 0.43, 0.05, 0.12)
	P.brows(k, 0.5, 0.39, 0.05, 0.12)
	k.text(0.5, 0.12, 0.5, 0.16, "FIGHT!", GOLD, {stroke = true})
end

A["Crash Bandicoop"] = function(k)
	k.sky(rgb(120, 200, 255), rgb(230, 245, 255))
	k.ellipse(0.5, 1, 1.2, 0.24, rgb(110, 190, 90))
	local wood = rgb(190, 60, 50)
	k.rect(0.45, 0.66, 0.42, 0.3, wood, {rot = -12})
	k.rect(0.45, 0.44, 0.48, 0.1, rgb(130, 40, 35), {rot = 20})
	k.rect(0.45, 0.68, 0.12, 0.16, rgb(60, 30, 20), {rot = -12})
	for _, c in ipairs({{0.2, 0.3, -20}, {0.78, 0.22, 25}, {0.84, 0.55, -10}}) do
		k.ellipse(c[1], c[2], 0.12, 0.13, W, {rot = c[3]})
		k.rect(c[1] + 0.05, c[2], 0.04, 0.025, rgb(255, 170, 40), {rot = c[3]})
		k.circle(c[1], c[2] - 0.06, 0.04, rgb(230, 40, 40))
		k.circle(c[1] + 0.02, c[2] - 0.01, 0.018, B)
	end
	for _, f in ipairs({{0.3, 0.15}, {0.62, 0.12}, {0.68, 0.38}}) do
		k.ellipse(f[1], f[2], 0.04, 0.02, W, {rot = 40})
	end
	P.star(k, 0.15, 0.75, 0.16, rgb(255, 220, 60))
end

return A

-- Dragon's Lair posters (Celestial)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local FIRE, EMBER = rgb(255, 120, 30), rgb(255, 210, 80)
local A = {}

local function flames(k, y, n, scale)
	scale = scale or 1
	for i = 0, n - 1 do
		local x = (i + 0.5) / n
		k.ellipse(x, y, 0.16 * scale, 0.3 * scale, FIRE, {t = 0.1})
		k.ellipse(x, y + 0.05 * scale, 0.08 * scale, 0.16 * scale, EMBER)
	end
end

local function dragonHead(k, x, y, s, color)
	k.rect(x - 0.08 * s, y - 0.17 * s, 0.04 * s, 0.14 * s, rgb(240, 230, 200), {rot = -20})
	k.rect(x + 0.08 * s, y - 0.17 * s, 0.04 * s, 0.14 * s, rgb(240, 230, 200), {rot = 20})
	k.circle(x, y, 0.3 * s, color)
	k.ellipse(x, y + 0.1 * s, 0.22 * s, 0.14 * s, color:Lerp(W, 0.2))
	k.circle(x - 0.05 * s, y + 0.1 * s, 0.02 * s, B)
	k.circle(x + 0.05 * s, y + 0.1 * s, 0.02 * s, B)
	k.ellipse(x - 0.07 * s, y - 0.04 * s, 0.06 * s, 0.07 * s, EMBER)
	k.ellipse(x + 0.07 * s, y - 0.04 * s, 0.06 * s, 0.07 * s, EMBER)
	k.ellipse(x - 0.07 * s, y - 0.04 * s, 0.015 * s, 0.06 * s, B)
	k.ellipse(x + 0.07 * s, y - 0.04 * s, 0.015 * s, 0.06 * s, B)
end

A["The Elder Trolls: Skyrim"] = function(k)
	k.sky(rgb(120, 160, 210), rgb(220, 235, 250))
	k.rect(0.3, 0.85, 0.6, 0.6, rgb(150, 160, 180), {rot = 45})
	k.rect(0.3, 0.6, 0.18, 0.18, W, {rot = 45})
	k.rect(0.8, 0.9, 0.5, 0.5, rgb(130, 140, 165), {rot = 45})
	k.rect(0.8, 0.7, 0.14, 0.14, W, {rot = 45})
	k.rect(0.5, 0.95, 1.04, 0.1, W)
	local troll = rgb(120, 170, 110)
	k.rect(0.55, 0.8, 0.22, 0.26, rgb(110, 80, 60), {round = 0.25})
	k.circle(0.55, 0.55, 0.2, troll)
	k.ellipse(0.43, 0.5, 0.07, 0.04, troll, {rot = -20})
	k.ellipse(0.67, 0.5, 0.07, 0.04, troll, {rot = 20})
	k.ellipse(0.55, 0.68, 0.16, 0.22, rgb(230, 230, 235))
	k.circle(0.5, 0.53, 0.02, B)
	k.circle(0.6, 0.53, 0.02, B)
	k.ellipse(0.55, 0.59, 0.05, 0.04, troll:Lerp(B, 0.2))
	k.rect(0.75, 0.72, 0.02, 0.4, rgb(110, 75, 45), {rot = 5})
	for _, f in ipairs({{0.15, 0.2}, {0.25, 0.4}, {0.85, 0.3}, {0.9, 0.12}, {0.4, 0.15}}) do
		k.circle(f[1], f[2], 0.02, W)
	end
end

A["Spyrow"] = function(k)
	k.sky(rgb(30, 30, 60), rgb(70, 60, 100))
	k.circle(0.5, 0.45, 0.8, rgb(255, 240, 180), {t = 0.75})
	k.rect(0.5, 0.88, 0.8, 0.03, rgb(110, 75, 45))
	local bird = rgb(160, 110, 70)
	k.ellipse(0.5, 0.65, 0.3, 0.36, bird)
	k.ellipse(0.5, 0.7, 0.18, 0.22, rgb(230, 210, 180))
	k.ellipse(0.36, 0.66, 0.12, 0.24, bird:Lerp(B, 0.2), {rot = 15})
	k.circle(0.5, 0.4, 0.22, bird)
	k.rect(0.5, 0.47, 0.05, 0.04, rgb(255, 180, 40), {rot = 45})
	k.rect(0.5, 0.38, 0.26, 0.06, B, {round = 0.3})
	k.rect(0.44, 0.38, 0.09, 0.05, rgb(60, 80, 120), {round = 0.3})
	k.rect(0.56, 0.38, 0.09, 0.05, rgb(60, 80, 120), {round = 0.3})
	k.ellipse(0.5, 0.24, 0.3, 0.06, rgb(40, 40, 50))
	k.rect(0.5, 0.2, 0.16, 0.08, rgb(40, 40, 50), {round = 0.3})
	k.rect(0.5, 0.94, 0.04, 0.06, rgb(255, 180, 40))
end

A["Dragon Quest-ion"] = function(k)
	k.sky(rgb(80, 160, 230), rgb(200, 235, 255))
	k.ellipse(0.5, 0.98, 1.2, 0.3, rgb(100, 180, 90))
	dragonHead(k, 0.35, 0.58, 1.3, rgb(90, 190, 100))
	k.text(0.75, 0.42, 0.34, 0.6, "?", rgb(255, 220, 60), {stroke = true})
end

A["Dark Soles"] = function(k)
	k.sky(rgb(15, 10, 10), rgb(50, 25, 15))
	flames(k, 0.95, 5, 0.9)
	local boot = rgb(60, 50, 45)
	for _, b in ipairs({{0.32, -12}, {0.68, 12}}) do
		k.ellipse(b[1], 0.48, 0.22, 0.56, boot, {rot = b[2]})
		k.ellipse(b[1], 0.48, 0.16, 0.48, rgb(30, 25, 22), {rot = b[2]})
		for i = -2, 2 do
			k.rect(b[1] + i * 0.012, 0.48 + i * 0.08, 0.1, 0.02, rgb(80, 70, 60), {rot = b[2]})
		end
	end
end

A["Elden Ding"] = function(k)
	k.sky(rgb(60, 40, 20), rgb(180, 130, 50))
	for i = 0, 5 do
		k.rect(0.5, 0.45, 0.04, 1.2, EMBER, {rot = i * 30, t = 0.7})
	end
	local bell = rgb(255, 200, 60)
	k.rect(0.5, 0.1, 0.02, 0.1, rgb(110, 80, 40))
	k.circle(0.5, 0.22, 0.16, bell)
	k.rect(0.5, 0.4, 0.3, 0.3, bell, {round = 0.2})
	k.ellipse(0.5, 0.58, 0.46, 0.1, bell:Lerp(B, 0.2))
	k.circle(0.5, 0.62, 0.07, rgb(150, 110, 40))
	for _, w in ipairs({{0.2, 0.4, 30}, {0.8, 0.4, -30}, {0.16, 0.55, 0}, {0.84, 0.55, 0}}) do
		k.rect(w[1], w[2], 0.08, 0.012, W, {rot = w[3]})
	end
	k.text(0.5, 0.86, 0.5, 0.16, "DING!", W, {stroke = true})
end

A["Cod of War"] = function(k)
	k.sky(rgb(60, 70, 90), rgb(140, 150, 170))
	k.waves(0.82, rgb(40, 80, 120), 0.12)
	local fish = rgb(150, 160, 170)
	k.rect(0.78, 0.55, 0.14, 0.2, fish, {rot = 45})
	k.ellipse(0.45, 0.55, 0.62, 0.36, fish)
	k.ellipse(0.45, 0.62, 0.5, 0.16, rgb(220, 225, 230))
	k.circle(0.25, 0.5, 0.07, W)
	k.circle(0.24, 0.5, 0.035, B)
	k.rect(0.26, 0.44, 0.08, 0.02, B, {rot = 20})
	k.rect(0.3, 0.33, 0.24, 0.1, rgb(150, 150, 160), {round = 0.5})
	k.rect(0.2, 0.28, 0.03, 0.1, rgb(240, 230, 200), {rot = -30})
	k.rect(0.4, 0.28, 0.03, 0.1, rgb(240, 230, 200), {rot = 30})
	k.rect(0.58, 0.32, 0.02, 0.3, rgb(120, 80, 45), {rot = 20})
	k.ellipse(0.62, 0.2, 0.12, 0.1, rgb(200, 205, 215), {rot = 20})
end

A["Monster Hunger"] = function(k)
	k.sky(rgb(255, 210, 160), rgb(255, 180, 120))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(170, 110, 70))
	local mon = rgb(140, 90, 200)
	k.ellipse(0.5, 0.6, 0.6, 0.66, mon)
	k.rect(0.32, 0.25, 0.04, 0.12, rgb(240, 230, 200), {rot = -15})
	k.rect(0.68, 0.25, 0.04, 0.12, rgb(240, 230, 200), {rot = 15})
	P.eyes(k, 0.5, 0.44, 0.09, 0.16)
	k.ellipse(0.5, 0.66, 0.3, 0.16, rgb(60, 20, 40))
	for x = 0.38, 0.62, 0.06 do
		P.sq(k, x, 0.6, 0.04, W, {rot = 45})
	end
	k.rect(0.12, 0.6, 0.02, 0.36, rgb(200, 205, 215))
	k.rect(0.12, 0.42, 0.06, 0.08, rgb(200, 205, 215))
	k.rect(0.88, 0.6, 0.02, 0.36, rgb(200, 205, 215))
	k.ellipse(0.88, 0.42, 0.05, 0.12, rgb(200, 205, 215))
	k.text(0.5, 0.88, 0.3, 0.1, "GRRR", W)
end

A["How to Drain Your Dragon"] = function(k)
	k.sky(rgb(200, 230, 240), rgb(170, 210, 225))
	for x = 0.1, 0.9, 0.2 do
		for y = 0.1, 0.5, 0.2 do
			k.rect(x, y, 0.19, 0.19, W, {t = 0.5})
		end
	end
	k.rect(0.5, 0.75, 0.84, 0.36, W, {round = 0.3})
	k.rect(0.5, 0.62, 0.78, 0.08, rgb(120, 200, 240))
	dragonHead(k, 0.3, 0.52, 0.8, rgb(220, 70, 60))
	k.ellipse(0.72, 0.5, 0.06, 0.16, rgb(220, 70, 60), {rot = 30})
	k.circle(0.82, 0.68, 0.06, rgb(60, 60, 70))
	for i = 0, 4 do
		k.circle(0.82 + math.cos(i * 1.3) * 0.04, 0.68 + math.sin(i * 1.3) * 0.05, 0.015, rgb(120, 200, 240))
	end
	for _, b in ipairs({{0.55, 0.3}, {0.6, 0.22}, {0.5, 0.18}}) do
		k.circle(b[1], b[2], 0.04, W, {t = 0.3})
	end
end

A["Dragon's Dog-ma"] = function(k)
	k.sky(rgb(120, 180, 255), rgb(230, 245, 255))
	k.ellipse(0.5, 0.98, 1.2, 0.26, rgb(100, 180, 90))
	local wing = rgb(200, 60, 60)
	k.ellipse(0.3, 0.42, 0.34, 0.2, wing, {rot = -25})
	k.ellipse(0.7, 0.42, 0.34, 0.2, wing, {rot = 25})
	local fur = rgb(220, 170, 110)
	k.ellipse(0.5, 0.66, 0.3, 0.24, fur)
	k.circle(0.5, 0.45, 0.24, fur)
	k.ellipse(0.39, 0.45, 0.08, 0.18, rgb(160, 110, 70), {rot = 20})
	k.ellipse(0.61, 0.45, 0.08, 0.18, rgb(160, 110, 70), {rot = -20})
	P.eyes(k, 0.5, 0.42, 0.045, 0.09)
	k.circle(0.5, 0.5, 0.035, B)
	k.ellipse(0.5, 0.57, 0.04, 0.05, rgb(255, 110, 130))
	for _, x in ipairs({0.42, 0.58}) do
		k.rect(x, 0.82, 0.04, 0.1, fur)
	end
end

A["Diablow"] = function(k)
	k.sky(rgb(80, 10, 10), rgb(180, 40, 20))
	flames(k, 1, 6, 0.7)
	local dryer = rgb(230, 40, 60)
	k.rect(0.4, 0.68, 0.08, 0.3, dryer, {rot = 10, round = 0.3})
	k.ellipse(0.42, 0.42, 0.3, 0.26, dryer)
	k.rect(0.6, 0.42, 0.18, 0.14, dryer, {round = 0.2})
	k.rect(0.7, 0.42, 0.04, 0.16, rgb(60, 60, 70))
	k.rect(0.33, 0.25, 0.06, 0.14, rgb(60, 10, 10), {rot = -25, round = 0.3})
	k.rect(0.51, 0.25, 0.06, 0.14, rgb(60, 10, 10), {rot = 25, round = 0.3})
	for i = 0, 2 do
		k.rect(0.84, 0.36 + i * 0.06, 0.14, 0.015, rgb(255, 230, 180), {t = 0.2})
	end
end

A["Shades"] = function(k)
	k.sky(rgb(40, 10, 30), rgb(150, 30, 40))
	flames(k, 0.95, 5, 1)
	k.rect(0.5, 0.42, 0.7, 0.04, B)
	for _, x in ipairs({0.32, 0.68}) do
		k.ellipse(x, 0.48, 0.28, 0.22, B)
		k.ellipse(x - 0.05, 0.43, 0.06, 0.04, W, {t = 0.5, rot = -20})
	end
	k.rect(0.5, 0.45, 0.08, 0.03, B, {round = 0.5})
	k.rect(0.12, 0.45, 0.06, 0.02, B, {rot = 15})
	k.rect(0.88, 0.45, 0.06, 0.02, B, {rot = -15})
end

A["Bald Dude's Gate 3"] = function(k)
	k.sky(rgb(50, 40, 60), rgb(120, 90, 110))
	local stone = rgb(120, 115, 125)
	k.rect(0.12, 0.6, 0.18, 0.8, stone)
	k.rect(0.88, 0.6, 0.18, 0.8, stone)
	k.rect(0.5, 0.2, 0.96, 0.12, stone)
	for x = 0.25, 0.75, 0.083 do
		k.rect(x, 0.62, 0.015, 0.72, rgb(60, 55, 60))
	end
	k.circle(0.5, 0.55, 0.38, P.SKIN)
	k.ellipse(0.44, 0.42, 0.1, 0.06, W, {t = 0.2, rot = -20})
	k.ellipse(0.31, 0.58, 0.06, 0.1, P.SKIN)
	k.ellipse(0.69, 0.58, 0.06, 0.1, P.SKIN)
	P.eyes(k, 0.5, 0.55, 0.05, 0.12)
	k.ellipse(0.5, 0.67, 0.1, 0.04, rgb(140, 70, 60))
	P.star(k, 0.62, 0.38, 0.06, W)
	k.text(0.5, 0.2, 0.12, 0.1, "3", GOLD)
end

A["World of Warcrafts"] = function(k)
	k.sky(rgb(30, 30, 70), rgb(70, 60, 120))
	k.circle(0.5, 0.55, 0.62, rgb(60, 140, 220))
	k.ellipse(0.38, 0.45, 0.2, 0.16, rgb(90, 190, 90))
	k.ellipse(0.62, 0.66, 0.24, 0.14, rgb(90, 190, 90))
	k.rect(0.75, 0.3, 0.025, 0.24, rgb(200, 205, 215), {rot = 30})
	k.rect(0.79, 0.3, 0.025, 0.24, rgb(200, 205, 215), {rot = -30})
	k.circle(0.72, 0.42, 0.05, rgb(230, 60, 60))
	k.circle(0.82, 0.42, 0.05, rgb(230, 60, 60))
	k.rect(0.22, 0.75, 0.08, 0.16, W, {rot = -20, round = 0.3})
	k.rect(0.22, 0.66, 0.04, 0.04, rgb(255, 140, 40), {rot = -20})
	k.circle(0.5, 0.88, 0.12, rgb(255, 120, 180))
	k.rect(0.5, 0.86, 0.16, 0.008, rgb(200, 80, 140), {rot = 30})
	k.rect(0.6, 0.8, 0.012, 0.12, rgb(200, 180, 140), {rot = -30})
end

A["Final Fanta-sea"] = function(k)
	k.sky(rgb(255, 160, 60), rgb(255, 210, 120))
	k.circle(0.8, 0.2, 0.16, rgb(255, 245, 200))
	P.can(k, 0.4, 0.42, 0.26, 0.44, rgb(255, 120, 30), "FIZZ", W)
	for _, b in ipairs({{0.32, 0.12}, {0.45, 0.08}, {0.38, 0.03}}) do
		k.circle(b[1], b[2], 0.025, W, {t = 0.3})
	end
	k.waves(0.68, rgb(255, 140, 40), 0.13)
	k.waves(0.8, rgb(255, 170, 60), 0.11)
	for _, b in ipairs({{0.7, 0.76}, {0.2, 0.85}, {0.85, 0.9}, {0.55, 0.88}}) do
		k.circle(b[1], b[2], 0.03, W, {t = 0.4})
	end
end

A["The Twitcher 3"] = function(k)
	k.sky(rgb(150, 210, 255), rgb(230, 245, 255))
	k.ellipse(0.5, 1, 1.2, 0.3, rgb(100, 170, 90))
	P.tree(k, 0.85, 0.85, 1.6)
	for _, b in ipairs({{0.7, 0.25}, {0.8, 0.35}, {0.62, 0.38}}) do
		k.ellipse(b[1], b[2], 0.06, 0.03, B, {rot = -15})
		k.ellipse(b[1] + 0.03, b[2] - 0.01, 0.06, 0.03, B, {rot = 15})
	end
	P.person(k, 0.3, 0.55, 1.6, rgb(90, 120, 70))
	k.rect(0.3, 0.43, 0.13, 0.06, rgb(40, 40, 45), {round = 0.3})
	k.circle(0.27, 0.43, 0.05, rgb(70, 140, 220))
	k.circle(0.33, 0.43, 0.05, rgb(70, 140, 220))
	k.rect(0.3, 0.31, 0.16, 0.04, rgb(140, 120, 70), {round = 0.5})
	k.text(0.12, 0.15, 0.14, 0.18, "3", rgb(60, 120, 60), {stroke = true})
end

return A

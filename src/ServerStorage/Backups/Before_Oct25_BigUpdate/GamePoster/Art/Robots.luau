-- Robot Factory posters (Secret)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local STEEL, DARK_STEEL = rgb(170, 175, 185), rgb(90, 95, 105)
local A = {}

local function robot(k, x, y, s, body, eye)
	body = body or STEEL
	eye = eye or rgb(0, 230, 255)
	k.rect(x - 0.06 * s, y + 0.2 * s, 0.05 * s, 0.15 * s, DARK_STEEL)
	k.rect(x + 0.06 * s, y + 0.2 * s, 0.05 * s, 0.15 * s, DARK_STEEL)
	k.rect(x, y + 0.05 * s, 0.22 * s, 0.2 * s, body, {round = 0.15})
	k.circle(x, y + 0.05 * s, 0.06 * s, eye, {t = 0.3})
	k.rect(x - 0.15 * s, y + 0.06 * s, 0.05 * s, 0.16 * s, DARK_STEEL, {round = 0.4})
	k.rect(x + 0.15 * s, y + 0.06 * s, 0.05 * s, 0.16 * s, DARK_STEEL, {round = 0.4})
	k.rect(x, y - 0.12 * s, 0.16 * s, 0.12 * s, body, {round = 0.2})
	k.rect(x, y - 0.12 * s, 0.12 * s, 0.04 * s, eye)
	k.rect(x, y - 0.21 * s, 0.01 * s, 0.06 * s, DARK_STEEL)
	k.circle(x, y - 0.24 * s, 0.025 * s, rgb(255, 60, 60))
end

local function factory(k)
	k.sky(rgb(60, 65, 75), rgb(110, 115, 125))
	for x = 0.1, 0.9, 0.2 do
		k.rect(x, 0.5, 0.006, 1, rgb(80, 85, 95))
	end
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(70, 70, 75))
	for x = 0.0, 1, 0.08 do
		k.rect(x, 0.94, 0.04, 0.12, rgb(255, 200, 40), {rot = 30, t = 0.4})
	end
end

A["Titanfail"] = function(k)
	k.sky(rgb(140, 200, 255), rgb(220, 240, 255))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(110, 110, 115))
	local body = rgb(120, 140, 160)
	k.rect(0.5, 0.6, 0.3, 0.28, body, {rot = -35, round = 0.15})
	k.rect(0.68, 0.38, 0.18, 0.14, body, {rot = -35, round = 0.2})
	k.rect(0.7, 0.37, 0.12, 0.04, rgb(255, 120, 40), {rot = -35})
	k.rect(0.3, 0.42, 0.08, 0.28, DARK_STEEL, {rot = 60, round = 0.4})
	k.rect(0.46, 0.84, 0.08, 0.2, DARK_STEEL, {rot = 10})
	k.rect(0.2, 0.7, 0.08, 0.26, DARK_STEEL, {rot = -70})
	k.ellipse(0.38, 0.9, 0.16, 0.05, rgb(255, 230, 60))
	k.ellipse(0.33, 0.88, 0.06, 0.04, rgb(255, 230, 60), {rot = -30})
	for _, s in ipairs({{0.85, 0.15}, {0.88, 0.25}, {0.15, 0.2}}) do
		P.star(k, s[1], s[2], 0.05, rgb(255, 230, 60))
	end
end

A["Armored Chore"] = function(k)
	k.sky(rgb(230, 220, 200), rgb(205, 190, 165))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(160, 120, 80))
	local armor = rgb(200, 205, 215)
	k.rect(0.4, 0.82, 0.05, 0.16, armor)
	k.rect(0.5, 0.82, 0.05, 0.16, armor)
	k.rect(0.45, 0.6, 0.2, 0.3, armor, {round = 0.2})
	k.circle(0.45, 0.33, 0.18, armor)
	k.rect(0.45, 0.33, 0.12, 0.015, B)
	k.rect(0.45, 0.2, 0.02, 0.08, RED or rgb(210, 40, 50))
	k.rect(0.62, 0.62, 0.02, 0.4, rgb(220, 60, 60), {rot = 25})
	k.rect(0.7, 0.86, 0.16, 0.06, rgb(220, 60, 60), {round = 0.3})
	for _, d in ipairs({{0.85, 0.85}, {0.9, 0.8}, {0.82, 0.78}}) do
		k.circle(d[1], d[2], 0.025, rgb(150, 140, 130), {t = 0.3})
	end
	k.rect(0.2, 0.3, 0.2, 0.26, W)
	for i = 0, 2 do
		k.rect(0.2, 0.22 + i * 0.07, 0.14, 0.012, rgb(150, 150, 160))
		k.rect(0.13, 0.22 + i * 0.07, 0.02, 0.025, rgb(80, 200, 100))
	end
end

A["Mechworrier"] = function(k)
	factory(k)
	robot(k, 0.5, 0.52, 2, rgb(150, 160, 190), rgb(120, 200, 255))
	k.rect(0.5, 0.25, 0.16, 0.06, B)
	k.circle(0.46, 0.28, 0.025, rgb(120, 200, 255))
	k.circle(0.54, 0.28, 0.025, rgb(120, 200, 255))
	k.ellipse(0.5, 0.3, 0.06, 0.02, B)
	for _, d in ipairs({{0.7, 0.22}, {0.74, 0.32}, {0.3, 0.25}}) do
		k.ellipse(d[1], d[2], 0.035, 0.07, rgb(120, 200, 255))
	end
	k.text(0.84, 0.12, 0.14, 0.16, "?!", rgb(255, 220, 60), {stroke = true})
end

A["Fractorio"] = function(k)
	factory(k)
	for i = 0, 2 do
		local y = 0.25 + i * 0.25
		k.rect(0.5, y, 1.04, 0.06, rgb(60, 60, 65))
		for x = 0.02, 1, 0.06 do
			k.rect(x, y, 0.01, 0.06, rgb(255, 200, 40))
		end
	end
	local function tri(x, y, s, d)
		if d == 0 then
			P.sq(k, x, y, s, rgb(120, 255, 200), {rot = 45})
			return
		end
		tri(x - s / 2, y, s / 2, d - 1)
		tri(x + s / 2, y, s / 2, d - 1)
		tri(x, y - s / 2 / 0.775, s / 2, d - 1)
	end
	tri(0.25, 0.22, 0.08, 1)
	tri(0.55, 0.47, 0.08, 1)
	tri(0.8, 0.72, 0.08, 1)
end

A["Satisfactoree"] = function(k)
	k.sky(rgb(255, 200, 120), rgb(255, 235, 190))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(110, 110, 120))
	k.rect(0.5, 0.72, 0.06, 0.4, DARK_STEEL)
	k.rect(0.4, 0.62, 0.2, 0.025, DARK_STEEL, {rot = 30})
	k.rect(0.6, 0.58, 0.2, 0.025, DARK_STEEL, {rot = -30})
	for _, g in ipairs({{0.5, 0.3, 0.22, rgb(90, 200, 100)}, {0.3, 0.42, 0.16, rgb(80, 180, 90)}, {0.7, 0.4, 0.17, rgb(100, 210, 110)}, {0.42, 0.18, 0.12, rgb(110, 220, 120)}, {0.6, 0.2, 0.13, rgb(80, 190, 95)}}) do
		P.gear(k, g[1], g[2], g[3], g[4], rgb(40, 110, 50))
	end
end

A["Bioshocked"] = function(k)
	k.sky(rgb(10, 50, 60), rgb(20, 100, 110))
	for _, b in ipairs({{0.15, 0.8, 0.04}, {0.85, 0.2, 0.05}, {0.2, 0.25, 0.03}, {0.82, 0.78, 0.03}}) do
		k.circle(b[1], b[2], b[3], W, {t = 0.5})
	end
	local cell = rgb(140, 255, 180)
	k.ellipse(0.5, 0.55, 0.5, 0.5, cell, {t = 0.3})
	k.ellipse(0.5, 0.55, 0.42, 0.42, cell:Lerp(W, 0.3), {t = 0.4})
	k.circle(0.55, 0.5, 0.14, rgb(80, 180, 120))
	P.eyes(k, 0.45, 0.55, 0.07, 0.11)
	k.ellipse(0.45, 0.68, 0.06, 0.06, B)
	P.lightning(k, 0.2, 0.4, 1.2)
	P.lightning(k, 0.82, 0.5, 1)
	k.ellipse(0.5, 0.55, 0.62, 0.62, rgb(255, 240, 80), {t = 0.85})
end

A["Transforkers"] = function(k)
	k.sky(rgb(40, 60, 120), rgb(100, 140, 200))
	local fork = rgb(210, 215, 225)
	k.rect(0.5, 0.75, 0.05, 0.4, fork)
	k.rect(0.5, 0.5, 0.2, 0.12, fork, {round = 0.3})
	for i = -1.5, 1.5 do
		k.rect(0.5 + i * 0.05, 0.36, 0.025, 0.18, fork, {round = 0.5})
	end
	k.rect(0.5, 0.5, 0.14, 0.04, rgb(80, 200, 255))
	k.rect(0.3, 0.52, 0.2, 0.04, fork, {rot = -20, round = 0.5})
	k.rect(0.7, 0.52, 0.2, 0.04, fork, {rot = 20, round = 0.5})
	k.rect(0.42, 0.88, 0.04, 0.12, fork, {rot = 15})
	k.rect(0.58, 0.88, 0.04, 0.12, fork, {rot = -15})
	for _, s in ipairs({{0.18, 0.3}, {0.82, 0.3}, {0.2, 0.75}, {0.8, 0.75}}) do
		P.star(k, s[1], s[2], 0.06, rgb(255, 230, 80))
	end
end

A["Gundumb Breaker"] = function(k)
	factory(k)
	local metal = rgb(60, 60, 70)
	k.rect(0.5, 0.42, 0.6, 0.04, rgb(180, 180, 190))
	for _, x in ipairs({0.22, 0.78}) do
		k.rect(x, 0.42, 0.08, 0.24, metal, {round = 0.2})
		k.rect(x + (x < 0.5 and 0.06 or -0.06), 0.42, 0.05, 0.18, metal, {round = 0.2})
	end
	robot(k, 0.5, 0.62, 1.2, W, rgb(255, 220, 60))
	k.rect(0.36, 0.5, 0.04, 0.14, DARK_STEEL, {rot = -20})
	k.rect(0.64, 0.5, 0.04, 0.14, DARK_STEEL, {rot = 20})
	for _, c in ipairs({{0.3, 0.88, 20}, {0.7, 0.88, -20}}) do
		k.rect(c[1], c[2], 0.12, 0.012, B, {rot = c[3]})
	end
end

A["Pacific Rimm"] = function(k)
	k.sky(rgb(255, 120, 80), rgb(255, 210, 150))
	k.waves(0.7, rgb(40, 110, 170), 0.12)
	k.circle(0.5, 0.52, 0.56, rgb(60, 60, 70))
	k.circle(0.5, 0.52, 0.42, rgb(200, 205, 215))
	for i = 0, 4 do
		k.rect(0.5, 0.52, 0.04, 0.5, rgb(170, 175, 185), {rot = i * 36})
	end
	k.circle(0.5, 0.52, 0.12, rgb(140, 145, 155))
	k.waves(0.82, rgb(40, 120, 180), 0.12)
	k.waves(0.9, rgb(60, 150, 210), 0.1)
end

A["Detroit: Become Toaster"] = function(k)
	k.sky(rgb(40, 50, 70), rgb(90, 110, 140))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(70, 70, 80))
	k.rect(0.5, 0.68, 0.56, 0.36, rgb(200, 205, 215), {round = 0.2})
	k.rect(0.5, 0.56, 0.4, 0.04, rgb(60, 60, 70))
	k.rect(0.4, 0.42, 0.12, 0.2, rgb(220, 170, 100), {round = 0.2})
	k.rect(0.6, 0.38, 0.12, 0.2, rgb(220, 170, 100), {round = 0.2})
	k.rect(0.8, 0.7, 0.04, 0.04, B)
	k.circle(0.5, 0.72, 0.08, rgb(80, 180, 255))
	k.circle(0.5, 0.72, 0.05, rgb(200, 240, 255))
	P.eyes(k, 0.5, 0.65, 0.05, 0.2)
	k.ellipse(0.5, 0.8, 0.12, 0.03, B)
end

A["Nearly: Automata"] = function(k)
	k.sky(rgb(220, 215, 200), rgb(190, 185, 170))
	robot(k, 0.32, 0.55, 1.6, rgb(230, 230, 225), rgb(40, 40, 40))
	k.rect(0.72, 0.5, 0.34, 0.36, rgb(250, 250, 245), {round = 0.05})
	for r = 0, 2 do
		for c = 0, 2 do
			if not (r == 2 and c == 2) then
				k.rect(0.62 + c * 0.1, 0.4 + r * 0.1, 0.09, 0.09, ({rgb(255, 120, 120), rgb(120, 200, 255), rgb(255, 220, 90)})[(r + c) % 3 + 1])
			end
		end
	end
	k.rect(0.5, 0.88, 0.8, 0.06, rgb(60, 60, 60), {round = 0.5})
	k.rect(0.495, 0.88, 0.79, 0.045, rgb(90, 220, 120), {round = 0.5})
	k.text(0.5, 0.88, 0.2, 0.05, "99%", B)
end

A["The Taco Principle"] = function(k)
	k.sky(rgb(255, 230, 170), rgb(250, 210, 140))
	local marble = rgb(240, 238, 230)
	k.rect(0.5, 0.8, 0.42, 0.06, marble)
	k.rect(0.5, 0.9, 0.5, 0.08, marble:Lerp(B, 0.1))
	for _, x in ipairs({0.08, 0.92}) do
		k.rect(x, 0.6, 0.08, 0.7, marble)
		k.rect(x, 0.25, 0.12, 0.04, marble)
		for dx = -0.025, 0.025, 0.025 do
			k.rect(x + dx, 0.6, 0.006, 0.65, marble:Lerp(B, 0.15))
		end
	end
	k.ellipse(0.5, 0.6, 0.42, 0.3, rgb(240, 190, 80))
	k.ellipse(0.5, 0.64, 0.38, 0.24, rgb(255, 225, 120))
	k.ellipse(0.4, 0.52, 0.08, 0.06, rgb(90, 200, 80))
	k.ellipse(0.52, 0.5, 0.08, 0.06, rgb(230, 60, 50))
	k.ellipse(0.62, 0.53, 0.07, 0.05, rgb(255, 230, 120))
	k.ellipse(0.5, 0.75, 0.42, 0.12, rgb(255, 230, 170))
	k.text(0.5, 0.18, 0.5, 0.14, "∴ TACO", rgb(120, 80, 40))
end

A["Mass Defect"] = function(k, rng)
	k.sky(rgb(10, 15, 35), rgb(30, 30, 70))
	k.stars(14, rng, 0.95)
	for _, p in ipairs({{0.3, 0.6, 0.14, 30}, {0.62, 0.7, 0.1, -20}, {0.72, 0.42, 0.08, 60}, {0.42, 0.82, 0.07, 10}}) do
		k.rect(p[1], p[2], p[3], p[3] * 1.2, STEEL, {rot = p[4], round = 0.15})
	end
	k.circle(0.45, 0.48, 0.12, STEEL)
	k.rect(0.45, 0.48, 0.08, 0.03, rgb(255, 60, 60))
	k.rect(0.5, 0.2, 0.3, 0.26, rgb(255, 210, 40), {rot = 45})
	k.rect(0.5, 0.2, 0.22, 0.19, rgb(40, 40, 40), {rot = 45})
	k.text(0.5, 0.21, 0.1, 0.16, "!", rgb(255, 210, 40))
	for _, s in ipairs({{0.2, 0.4}, {0.6, 0.55}, {0.85, 0.75}}) do
		P.lightning(k, s[1], s[2], 0.4, rgb(120, 200, 255))
	end
end

A["Horizon Zero Yawn"] = function(k)
	k.sky(rgb(255, 130, 80), rgb(255, 220, 150))
	k.circle(0.5, 0.72, 0.6, rgb(255, 230, 100))
	k.ellipse(0.4, 0.68, 0.08, 0.02, rgb(150, 80, 30))
	k.ellipse(0.6, 0.68, 0.08, 0.02, rgb(150, 80, 30))
	k.ellipse(0.5, 0.8, 0.16, 0.14, rgb(150, 60, 40))
	k.ellipse(0.25, 0.85, 0.3, 0.16, rgb(255, 200, 80), {t = 0.4})
	k.rect(0.5, 0.93, 1.04, 0.16, rgb(90, 70, 110))
	k.ellipse(0.2, 0.9, 0.5, 0.2, rgb(70, 55, 90))
	k.ellipse(0.85, 0.9, 0.5, 0.22, rgb(70, 55, 90))
	P.zzz(k, 0.72, 0.3, 1.2, W)
end

A["The Mattress"] = function(k, rng)
	k.sky(rgb(10, 20, 15), rgb(15, 40, 25))
	for _ = 1, 30 do
		k.text(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95), 0.04, 0.06, rng:NextNumber() < 0.5 and "0" or "1", rgb(80, 255, 140), {t = rng:NextNumber(0.3, 0.8), font = Enum.Font.Code})
	end
	k.rect(0.5, 0.6, 0.66, 0.2, rgb(240, 240, 250), {round = 0.2})
	k.rect(0.5, 0.68, 0.66, 0.05, rgb(120, 160, 230), {round = 0.2})
	for x = 0.25, 0.75, 0.1 do
		k.circle(x, 0.58, 0.02, rgb(200, 200, 215))
	end
	k.ellipse(0.27, 0.5, 0.16, 0.08, W)
	P.zzz(k, 0.72, 0.36, 1, W)
end

return A

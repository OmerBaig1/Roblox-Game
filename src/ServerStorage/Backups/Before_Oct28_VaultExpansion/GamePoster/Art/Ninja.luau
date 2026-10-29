-- Ninja Dojo posters (Godly)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local RED = rgb(210, 40, 50)
local A = {}

local function ninjaMask(k, x, y, s, cloth)
	cloth = cloth or rgb(30, 30, 40)
	k.rect(x, y, 0.2 * s, 0.07 * s, cloth)
	k.rect(x + 0.12 * s, y + 0.03 * s, 0.08 * s, 0.03 * s, cloth, {rot = 30})
	k.rect(x - 0.04 * s, y, 0.04 * s, 0.025 * s, W)
	k.rect(x + 0.04 * s, y, 0.04 * s, 0.025 * s, W)
	k.circle(x - 0.035 * s, y, 0.015 * s, B)
	k.circle(x + 0.045 * s, y, 0.015 * s, B)
end

local function blossoms(k, rng, n)
	for _ = 1, n do
		k.ellipse(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.05, 0.95), 0.035, 0.025, rgb(255, 180, 210), {rot = rng:NextNumber(0, 180)})
	end
end

A["Ghost of Sushima"] = function(k)
	k.sky(rgb(255, 140, 90), rgb(255, 210, 160))
	k.circle(0.5, 0.35, 0.4, rgb(255, 240, 200), {t = 0.2})
	for i = 0, 7 do
		k.rect(0.06 + i * 0.13, 0.88, 0.02, 0.24, rgb(230, 200, 120), {rot = 15})
	end
	local rice, nori = rgb(250, 250, 245), rgb(30, 50, 40)
	k.circle(0.5, 0.52, 0.36, nori)
	k.circle(0.5, 0.52, 0.29, rice)
	k.circle(0.5, 0.52, 0.12, rgb(255, 120, 90))
	k.ellipse(0.5, 0.26, 0.5, 0.06, rgb(210, 180, 110))
	k.rect(0.5, 0.22, 0.14, 0.06, rgb(210, 180, 110), {round = 0.5})
	k.ellipse(0.42, 0.45, 0.03, 0.05, B)
	k.ellipse(0.58, 0.45, 0.03, 0.05, B)
	for i = 0, 2 do
		k.rect(0.18 - i * 0.02, 0.4 + i * 0.12, 0.2, 0.012, W, {t = 0.3})
	end
end

A["Ninja Garden"] = function(k)
	k.sky(rgb(170, 230, 190), rgb(230, 250, 230))
	k.rect(0.5, 0.93, 1.04, 0.14, rgb(110, 80, 55))
	for _, f in ipairs({{0.15, rgb(255, 120, 160)}, {0.3, rgb(255, 220, 80)}, {0.85, rgb(180, 120, 255)}}) do
		k.rect(f[1], 0.8, 0.012, 0.16, rgb(70, 160, 70))
		k.circle(f[1], 0.7, 0.08, f[2])
		k.circle(f[1], 0.7, 0.03, GOLD)
	end
	P.person(k, 0.58, 0.48, 1.4, rgb(30, 30, 40), rgb(30, 30, 40), rgb(30, 30, 40))
	ninjaMask(k, 0.58, 0.41, 0.7)
	k.rect(0.7, 0.62, 0.14, 0.02, rgb(150, 150, 160), {rot = 40})
	P.sq(k, 0.76, 0.69, 0.05, rgb(170, 175, 185), {rot = 45})
	k.rect(0.42, 0.6, 0.1, 0.07, rgb(200, 120, 70), {round = 0.3})
end

A["Root Ninja"] = function(k)
	k.sky(rgb(120, 70, 40), rgb(80, 45, 25))
	k.rect(0.5, 0.12, 1.04, 0.24, rgb(120, 190, 255))
	k.rect(0.5, 0.25, 1.04, 0.04, rgb(80, 160, 70))
	for _, r in ipairs({{0.3, rgb(255, 130, 40)}, {0.7, rgb(240, 240, 230)}}) do
		k.ellipse(r[1], 0.55, 0.22, 0.52, r[2])
		for _, a in ipairs({-25, 0, 25}) do
			k.ellipse(r[1] + a * 0.002, 0.24, 0.04, 0.16, rgb(70, 170, 60), {rot = a})
		end
		ninjaMask(k, r[1], 0.48, 0.9)
		k.rect(r[1], 0.62, 0.08, 0.008, r[2]:Lerp(B, 0.2))
		k.rect(r[1], 0.72, 0.06, 0.008, r[2]:Lerp(B, 0.2))
	end
	P.star(k, 0.5, 0.82, 0.08, rgb(170, 175, 185))
end

A["Sekiwo: Shadows Die Thrice"] = function(k)
	k.sky(rgb(120, 20, 30), rgb(40, 10, 15))
	k.circle(0.5, 0.35, 0.5, rgb(230, 60, 50), {t = 0.2})
	for i, x in ipairs({0.25, 0.5, 0.75}) do
		local t = (i - 1) * 0.3
		P.person(k, x, 0.58, 1.3, B, B, B)
		k.rect(x + 0.06, 0.55, 0.02, 0.3, rgb(170, 170, 180), {rot = 30, t = t})
	end
	for i = 0, 2 do
		k.rect(0.42 + i * 0.08, 0.12, 0.02, 0.12, W)
	end
	k.rect(0.5, 0.12, 0.28, 0.02, W, {rot = -20})
end

A["Shadow Bite 2"] = function(k)
	local bg = rgb(250, 235, 200)
	k.sky(bg, bg)
	local shadow = rgb(30, 30, 40)
	k.rect(0.56, 0.5, 0.62, 0.12, shadow, {round = 0.4})
	k.rect(0.56, 0.62, 0.66, 0.06, shadow)
	k.rect(0.56, 0.72, 0.62, 0.12, shadow, {round = 0.4})
	local bread = rgb(230, 170, 90)
	k.rect(0.46, 0.4, 0.62, 0.14, bread, {round = 0.4})
	k.rect(0.46, 0.49, 0.66, 0.04, rgb(110, 200, 80), {round = 0.5})
	k.rect(0.46, 0.53, 0.6, 0.04, rgb(230, 60, 60))
	k.rect(0.46, 0.57, 0.62, 0.04, rgb(255, 210, 70))
	k.rect(0.46, 0.64, 0.62, 0.12, bread, {round = 0.4})
	for _, c in ipairs({{0.74, 0.44}, {0.77, 0.52}, {0.74, 0.62}}) do
		k.circle(c[1], c[2], 0.11, bg)
	end
	k.text(0.2, 0.18, 0.18, 0.22, "2", RED, {stroke = true})
end

A["Naru-toe Storm"] = function(k)
	k.sky(rgb(60, 70, 100), rgb(140, 150, 180))
	for i = 0, 4 do
		k.ellipse(0.5, 0.5, 0.95 - i * 0.15, 0.85 - i * 0.14, W, {t = 0.8})
	end
	P.lightning(k, 0.15, 0.25, 1)
	P.lightning(k, 0.85, 0.2, 0.8)
	local skin = P.SKIN
	k.ellipse(0.5, 0.62, 0.34, 0.5, skin)
	k.ellipse(0.5, 0.4, 0.26, 0.18, rgb(255, 230, 230))
	k.rect(0.5, 0.58, 0.36, 0.08, rgb(40, 60, 150))
	k.rect(0.5, 0.58, 0.12, 0.06, rgb(190, 190, 200))
	k.rect(0.7, 0.62, 0.1, 0.03, rgb(40, 60, 150), {rot = 30})
	k.ellipse(0.5, 0.75, 0.04, 0.03, rgb(220, 160, 130))
end

A["Okamee"] = function(k, rng)
	k.sky(rgb(250, 240, 220), rgb(235, 220, 195))
	k.circle(0.4, 0.4, 0.42, RED)
	for _ = 1, 6 do
		k.circle(rng:NextNumber(0.15, 0.65), rng:NextNumber(0.6, 0.85), rng:NextNumber(0.02, 0.04), B, {t = 0.2})
	end
	k.ellipse(0.35, 0.8, 0.5, 0.08, B, {rot = -8})
	k.rect(0.78, 0.45, 0.04, 0.5, rgb(150, 100, 60), {rot = -30})
	k.rect(0.68, 0.68, 0.06, 0.08, rgb(220, 200, 160), {rot = -30})
	k.ellipse(0.65, 0.75, 0.05, 0.08, B, {rot = -30})
	k.text(0.85, 0.15, 0.12, 0.2, "心", B)
end

A["Gemshin Impact"] = function(k)
	k.sky(rgb(120, 200, 255), rgb(240, 250, 255))
	k.ellipse(0.5, 0.96, 1.2, 0.3, rgb(120, 190, 100))
	for i = 0, 2 do
		k.ellipse(0.5, 0.82, 0.4 + i * 0.22, 0.08 + i * 0.04, W, {t = 0.4 + i * 0.2})
	end
	for _, r in ipairs({{0.25, 0.78, 30}, {0.75, 0.76, -30}, {0.35, 0.65, 50}, {0.68, 0.64, -50}}) do
		P.sq(k, r[1], r[2], 0.05, rgb(130, 110, 90), {rot = r[3]})
	end
	local gem = rgb(80, 220, 255)
	k.rect(0.5, 0.45, 0.26, 0.3, gem, {rot = 45})
	k.rect(0.5, 0.45, 0.16, 0.18, gem:Lerp(W, 0.5), {rot = 45})
	k.rect(0.46, 0.38, 0.05, 0.05, W, {rot = 45})
	for i = 0, 3 do
		k.rect(0.5, 0.12 - i * 0.0, 0.012, 0.15, W, {t = 0.3, rot = (i - 1.5) * 15})
	end
end

A["Cooking Mamma"] = function(k)
	k.sky(rgb(255, 230, 200), rgb(255, 205, 170))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(200, 150, 110))
	P.person(k, 0.38, 0.5, 1.6, rgb(255, 120, 150))
	k.rect(0.38, 0.55, 0.13, 0.2, W, {round = 0.2})
	k.rect(0.38, 0.25, 0.15, 0.08, W, {round = 0.3})
	k.circle(0.38, 0.19, 0.12, W)
	P.eyes(k, 0.38, 0.42, 0.03, 0.05)
	k.ellipse(0.38, 0.47, 0.04, 0.02, rgb(200, 80, 80))
	k.rect(0.62, 0.6, 0.2, 0.02, rgb(60, 60, 70))
	k.ellipse(0.72, 0.62, 0.22, 0.08, rgb(60, 60, 70))
	for _, d in ipairs({{0.68, 0.57}, {0.75, 0.56}, {0.71, 0.52}}) do
		k.ellipse(d[1], d[2], 0.07, 0.05, W)
	end
	for _, s in ipairs({0.66, 0.72, 0.78}) do
		k.ellipse(s, 0.4, 0.02, 0.07, W, {t = 0.5})
	end
end

A["Total Bore: Shogun"] = function(k)
	k.sky(rgb(240, 225, 190), rgb(220, 200, 160))
	k.rect(0.5, 0.5, 0.004, 1, rgb(150, 120, 80))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(170, 140, 90))
	local armor = RED
	k.rect(0.42, 0.7, 0.44, 0.34, armor, {round = 0.2})
	for y = 0.6, 0.82, 0.06 do
		k.rect(0.42, y, 0.44, 0.01, GOLD)
	end
	k.circle(0.42, 0.42, 0.24, P.SKIN)
	k.rect(0.42, 0.29, 0.3, 0.06, B, {round = 0.3})
	k.rect(0.36, 0.22, 0.03, 0.1, GOLD, {rot = -30})
	k.rect(0.48, 0.22, 0.03, 0.1, GOLD, {rot = 30})
	k.rect(0.37, 0.42, 0.05, 0.01, B)
	k.rect(0.47, 0.42, 0.05, 0.01, B)
	k.ellipse(0.42, 0.5, 0.05, 0.03, B)
	P.zzz(k, 0.68, 0.32, 1.3, rgb(80, 80, 120))
end

A["Samurai Slowdown"] = function(k)
	k.sky(rgb(255, 200, 150), rgb(255, 235, 200))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(140, 170, 100))
	local shell = rgb(170, 110, 60)
	k.ellipse(0.5, 0.82, 0.56, 0.12, rgb(200, 220, 160))
	k.circle(0.52, 0.62, 0.36, shell)
	k.circle(0.52, 0.62, 0.24, shell:Lerp(W, 0.2))
	k.circle(0.52, 0.62, 0.12, shell)
	k.ellipse(0.25, 0.72, 0.18, 0.12, rgb(200, 220, 160))
	k.rect(0.22, 0.58, 0.012, 0.1, rgb(200, 220, 160), {rot = -10})
	k.rect(0.27, 0.58, 0.012, 0.1, rgb(200, 220, 160), {rot = 10})
	k.circle(0.21, 0.52, 0.025, B)
	k.circle(0.28, 0.52, 0.025, B)
	k.rect(0.26, 0.64, 0.14, 0.04, RED, {round = 0.3})
	k.rect(0.26, 0.6, 0.02, 0.06, GOLD)
	k.text(0.75, 0.18, 0.3, 0.14, "...slow", rgb(120, 80, 50))
end

A["Ni-Oh No"] = function(k)
	k.sky(rgb(40, 10, 20), rgb(120, 30, 40))
	local mask = rgb(220, 50, 50)
	k.rect(0.32, 0.18, 0.06, 0.14, rgb(240, 230, 210), {rot = -20})
	k.rect(0.68, 0.18, 0.06, 0.14, rgb(240, 230, 210), {rot = 20})
	k.ellipse(0.5, 0.5, 0.5, 0.62, mask)
	P.eyes(k, 0.5, 0.42, 0.1, 0.18)
	P.brows(k, 0.5, 0.34, 0.1, 0.18, -15)
	k.ellipse(0.5, 0.66, 0.2, 0.12, B)
	k.rect(0.44, 0.62, 0.03, 0.05, W)
	k.rect(0.56, 0.62, 0.03, 0.05, W)
	k.ellipse(0.78, 0.38, 0.04, 0.07, rgb(120, 200, 255))
	k.text(0.5, 0.92, 0.5, 0.12, "OH NO", W, {stroke = true})
end

A["Tekkon 8"] = function(k)
	k.sky(rgb(30, 20, 20), rgb(150, 40, 20))
	for i = 0, 5 do
		k.ellipse(0.1 + i * 0.16, 0.88, 0.14, 0.24, rgb(255, 140, 30), {t = 0.2})
		k.ellipse(0.1 + i * 0.16, 0.92, 0.08, 0.14, rgb(255, 220, 80))
	end
	for _, g in ipairs({{0.3, rgb(220, 40, 40), 15}, {0.7, rgb(40, 80, 220), -15}}) do
		k.ellipse(g[1], 0.45, 0.26, 0.32, g[2], {rot = g[3]})
		k.ellipse(g[1] + (g[1] < 0.5 and 0.08 or -0.08), 0.42, 0.1, 0.14, g[2]:Lerp(B, 0.2), {rot = g[3]})
		k.rect(g[1], 0.66, 0.16, 0.08, W, {rot = g[3]})
	end
	P.star(k, 0.5, 0.4, 0.14, rgb(255, 230, 80))
	k.text(0.5, 0.12, 0.2, 0.2, "8", GOLD, {stroke = true})
end

A["Super Smush Bros"] = function(k)
	k.sky(rgb(130, 200, 255), rgb(230, 245, 255))
	k.rect(0.5, 0.88, 0.8, 0.06, rgb(120, 110, 140))
	k.rect(0.5, 0.94, 0.7, 0.06, rgb(90, 80, 110))
	k.ellipse(0.34, 0.66, 0.36, 0.28, rgb(255, 210, 220))
	k.ellipse(0.66, 0.66, 0.36, 0.28, rgb(210, 255, 210))
	for _, m in ipairs({0.3, 0.7}) do
		k.circle(m - 0.04, 0.62, 0.025, B)
		k.circle(m + 0.04, 0.62, 0.025, B)
		k.ellipse(m, 0.7, 0.05, 0.03, B)
	end
	P.star(k, 0.5, 0.48, 0.16, rgb(255, 230, 80))
	k.text(0.5, 0.18, 0.5, 0.18, "SMUSH!", rgb(230, 60, 60), {stroke = true})
end

A["Splatune"] = function(k, rng)
	k.sky(rgb(30, 30, 40), rgb(60, 50, 70))
	local inks = {rgb(255, 80, 200), rgb(120, 255, 60), rgb(255, 200, 40), rgb(60, 200, 255)}
	for i = 1, 4 do
		local x, y = 0.05 + i * 0.2, 0.25 + (i % 2) * 0.4
		k.circle(x, y, 0.2, inks[i])
		for _ = 1, 5 do
			k.circle(x + rng:NextNumber(-0.13, 0.13), y + rng:NextNumber(-0.15, 0.15), rng:NextNumber(0.03, 0.07), inks[i])
		end
		k.text(x, y, 0.14, 0.2, i % 2 == 0 and "♪" or "♫", B)
	end
end

return A

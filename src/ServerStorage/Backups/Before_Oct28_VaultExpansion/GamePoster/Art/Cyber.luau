-- Cyber City posters (Mythic)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local CYAN, PINK, PURPLE = rgb(0, 230, 255), rgb(255, 60, 200), rgb(130, 60, 255)
local A = {}

local function city(k, rng, color, windows)
	local x = 0
	while x < 1 do
		local w = rng:NextNumber(0.08, 0.16)
		local h = rng:NextNumber(0.25, 0.6)
		k.rect(x + w / 2, 1 - h / 2, w - 0.01, h, color)
		for wy = 1 - h + 0.05, 0.95, 0.07 do
			if rng:NextNumber() < 0.5 then
				k.rect(x + w / 2, wy, w * 0.5, 0.02, windows)
			end
		end
		x += w
	end
end

local function neonGrid(k, color)
	for i = 0, 5 do
		k.rect(0.5, 0.75 + i * 0.05, 1.04, 0.006, color, {t = 0.3})
	end
	for i = -4, 4 do
		k.rect(0.5 + i * 0.12, 0.87, 0.006, 0.26, color, {rot = i * 8, t = 0.3})
	end
end

A["Cyberpunk 2078"] = function(k, rng)
	k.sky(rgb(40, 0, 60), rgb(255, 60, 140))
	k.circle(0.5, 0.5, 0.5, rgb(255, 200, 60))
	for i = 0, 3 do
		k.rect(0.5, 0.48 + i * 0.06, 1.04, 0.02 + i * 0.006, rgb(140, 20, 100))
	end
	city(k, rng, rgb(25, 10, 40), CYAN)
	k.text(0.5, 0.14, 0.7, 0.2, "2078", CYAN, {stroke = true})
end

A["Ghostjogger"] = function(k)
	k.sky(rgb(10, 5, 30), rgb(40, 10, 70))
	neonGrid(k, PINK)
	P.ghost(k, 0.48, 0.38, 1.5, rgb(200, 255, 255))
	k.rect(0.48, 0.32, 0.34, 0.04, PINK)
	k.rect(0.32, 0.36, 0.08, 0.025, PINK, {rot = 30})
	for i = 0, 3 do
		k.rect(0.15, 0.4 + i * 0.07, 0.18 - i * 0.03, 0.012, CYAN, {t = 0.2 + i * 0.15})
	end
	k.ellipse(0.4, 0.82, 0.1, 0.05, rgb(255, 255, 255))
	k.ellipse(0.58, 0.8, 0.1, 0.05, rgb(255, 255, 255))
end

A["Deus Next"] = function(k)
	k.sky(rgb(20, 15, 10), rgb(70, 50, 20))
	for i = 0, 6 do
		k.rect(0.1 + i * 0.13, 0.5, 0.005, 1, GOLD, {t = 0.8})
		k.rect(0.5, 0.1 + i * 0.13, 1, 0.006, GOLD, {t = 0.8})
	end
	for _, c in ipairs({{0.23, 0.23}, {0.75, 0.36}, {0.36, 0.75}, {0.88, 0.62}}) do
		k.circle(c[1], c[2], 0.03, GOLD)
	end
	k.rect(0.5, 0.5, 0.6, 0.26, GOLD, {round = 0.5})
	k.rect(0.5, 0.5, 0.56, 0.21, rgb(40, 30, 10), {round = 0.5})
	k.text(0.5, 0.5, 0.45, 0.16, "NEXT ▶", GOLD)
end

A["Overwash"] = function(k)
	k.sky(rgb(180, 220, 255), rgb(240, 248, 255))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(140, 160, 190))
	k.rect(0.45, 0.6, 0.46, 0.6, rgb(235, 240, 245), {round = 0.08})
	k.rect(0.45, 0.35, 0.46, 0.08, rgb(200, 210, 220))
	k.circle(0.6, 0.35, 0.03, rgb(255, 80, 80))
	k.circle(0.45, 0.65, 0.32, rgb(150, 160, 175))
	k.circle(0.45, 0.65, 0.26, rgb(120, 200, 255))
	k.rect(0.45, 0.65, 0.14, 0.12, rgb(255, 120, 60), {rot = 30, round = 0.3})
	for _, b in ipairs({{0.25, 0.28, 0.12}, {0.35, 0.18, 0.15}, {0.55, 0.15, 0.13}, {0.7, 0.24, 0.16}, {0.82, 0.4, 0.12}, {0.78, 0.6, 0.1}}) do
		k.circle(b[1], b[2], b[3], W, {t = 0.1})
	end
	k.ellipse(0.2, 0.86, 0.14, 0.05, rgb(255, 80, 80))
	k.rect(0.78, 0.85, 0.12, 0.08, rgb(80, 120, 230), {round = 0.3})
end

A["Valorent"] = function(k, rng)
	k.sky(rgb(20, 20, 30), rgb(70, 30, 50))
	city(k, rng, rgb(35, 30, 45), rgb(255, 80, 90))
	k.rect(0.5, 0.42, 0.54, 0.28, W, {rot = -6, round = 0.08})
	k.rect(0.5, 0.42, 0.5, 0.24, rgb(230, 50, 60), {rot = -6, round = 0.06})
	k.text(0.5, 0.39, 0.42, 0.1, "FOR RENT", W, {rot = -6})
	k.text(0.5, 0.48, 0.3, 0.06, "$999/mo", GOLD, {rot = -6})
	k.circle(0.82, 0.18, 0.14, rgb(255, 80, 90), {t = 0.2})
	k.circle(0.82, 0.18, 0.1, rgb(20, 20, 30))
	k.rect(0.82, 0.18, 0.16, 0.008, rgb(255, 80, 90))
	k.rect(0.82, 0.18, 0.004, 0.2, rgb(255, 80, 90))
end

A["Apex Legendz"] = function(k)
	k.sky(rgb(255, 120, 60), rgb(255, 210, 140))
	k.rect(0.5, 0.75, 0.75, 0.75, rgb(120, 100, 140), {rot = 45})
	k.rect(0.2, 0.9, 0.5, 0.5, rgb(90, 80, 110), {rot = 45})
	k.rect(0.85, 0.92, 0.45, 0.45, rgb(90, 80, 110), {rot = 45})
	k.rect(0.5, 0.33, 0.15, 0.13, W, {rot = 45})
	k.rect(0.5, 0.18, 0.012, 0.14, rgb(80, 60, 40))
	k.rect(0.56, 0.13, 0.11, 0.07, rgb(230, 40, 40))
	k.text(0.56, 0.13, 0.08, 0.06, "Z", W)
end

A["Portul"] = function(k)
	k.sky(rgb(220, 225, 230), rgb(180, 185, 195))
	for x = 0.1, 0.9, 0.2 do
		k.rect(x, 0.5, 0.004, 1, rgb(150, 155, 165))
	end
	k.ellipse(0.22, 0.5, 0.18, 0.6, rgb(150, 60, 255))
	k.ellipse(0.22, 0.5, 0.12, 0.5, rgb(40, 10, 60))
	k.ellipse(0.78, 0.5, 0.18, 0.6, rgb(60, 255, 140))
	k.ellipse(0.78, 0.5, 0.12, 0.5, rgb(10, 60, 30))
	local duck = rgb(255, 220, 50)
	k.ellipse(0.27, 0.6, 0.12, 0.1, duck)
	k.ellipse(0.73, 0.4, 0.12, 0.1, duck)
	k.circle(0.71, 0.32, 0.07, duck)
	k.rect(0.665, 0.33, 0.04, 0.025, rgb(255, 140, 30), {round = 0.4})
	k.circle(0.715, 0.31, 0.015, B)
end

A["Half-Lite"] = function(k)
	k.sky(rgb(255, 150, 50), rgb(255, 220, 120))
	for i = 0, 5 do
		k.rect(0.5, 0.5, 0.06, 1.4, W, {rot = i * 30, t = 0.75})
	end
	P.can(k, 0.5, 0.55, 0.3, 0.55, rgb(255, 140, 30), "HALF", W)
	k.rect(0.5, 0.72, 0.3, 0.08, W)
	k.text(0.5, 0.72, 0.24, 0.06, "LITE", rgb(255, 140, 30))
	k.rect(0.5, 0.45, 0.3, 0.012, W, {t = 0.3})
end

A["Hallo"] = function(k)
	k.sky(rgb(110, 200, 255), rgb(230, 248, 255))
	k.ellipse(0.5, 0.22, 0.45, 0.1, GOLD)
	k.ellipse(0.5, 0.22, 0.35, 0.05, rgb(170, 230, 255))
	local skin = P.SKIN
	k.rect(0.5, 0.82, 0.14, 0.3, skin)
	k.rect(0.5, 0.58, 0.3, 0.26, skin, {round = 0.3})
	for i = 0, 3 do
		k.rect(0.39 + i * 0.075, 0.4, 0.06, 0.2, skin, {round = 1, rot = (i - 1.5) * 6})
	end
	k.rect(0.3, 0.6, 0.07, 0.16, skin, {round = 1, rot = -40})
	for _, m in ipairs({{0.2, 0.42, -30}, {0.8, 0.42, 30}}) do
		k.rect(m[1], m[2], 0.08, 0.012, W, {rot = m[3]})
	end
	k.text(0.5, 0.92, 0.4, 0.1, "HALLO!", rgb(40, 120, 220))
end

A["Watch Hogs"] = function(k)
	k.sky(rgb(10, 20, 25), rgb(20, 50, 55))
	for x = 0.05, 1, 0.1 do
		k.text(x, 0.5, 0.06, 1, "1\n0\n1\n1\n0\n1", rgb(60, 255, 150), {t = 0.75, font = Enum.Font.Code})
	end
	local pink = rgb(255, 160, 175)
	k.rect(0.5, 0.85, 0.5, 0.3, rgb(40, 40, 50), {round = 0.2})
	k.circle(0.5, 0.48, 0.42, rgb(40, 40, 50))
	k.circle(0.5, 0.52, 0.32, pink)
	k.ellipse(0.5, 0.6, 0.12, 0.08, rgb(230, 120, 140))
	k.circle(0.48, 0.6, 0.02, rgb(150, 60, 80))
	k.circle(0.52, 0.6, 0.02, rgb(150, 60, 80))
	k.rect(0.5, 0.47, 0.26, 0.06, B, {round = 0.3})
	k.rect(0.5, 0.47, 0.22, 0.03, rgb(60, 255, 150), {t = 0.4})
	k.rect(0.8, 0.82, 0.14, 0.08, rgb(80, 80, 90), {round = 0.2})
	k.rect(0.8, 0.82, 0.1, 0.05, rgb(60, 255, 150))
end

A["Counter-Stroke"] = function(k)
	k.sky(rgb(240, 235, 225), rgb(220, 210, 195))
	for x = 0.1, 0.9, 0.2 do
		for y = 0.1, 0.5, 0.2 do
			k.rect(x, y, 0.18, 0.18, rgb(255, 255, 255), {t = 0.4})
		end
	end
	k.rect(0.5, 0.68, 1.04, 0.08, rgb(120, 120, 130))
	k.rect(0.5, 0.86, 1.04, 0.3, rgb(170, 120, 80))
	k.rect(0.3, 0.86, 0.008, 0.28, rgb(130, 90, 60))
	k.rect(0.7, 0.86, 0.008, 0.28, rgb(130, 90, 60))
	k.ellipse(0.5, 0.65, 0.6, 0.05, rgb(230, 50, 80), {rot = -4})
	k.rect(0.84, 0.48, 0.03, 0.26, rgb(150, 100, 60), {rot = 40})
	k.rect(0.76, 0.58, 0.06, 0.06, rgb(180, 180, 190), {rot = 40})
	k.rect(0.72, 0.62, 0.06, 0.05, rgb(230, 50, 80), {rot = 40, round = 0.3})
end

A["Dentistry"] = function(k, rng)
	k.sky(rgb(10, 10, 35), rgb(40, 20, 80))
	k.stars(16, rng, 0.95)
	P.planet(k, 0.15, 0.2, 0.14, rgb(255, 150, 200))
	k.ellipse(0.5, 0.42, 0.4, 0.38, W)
	k.ellipse(0.4, 0.68, 0.12, 0.3, W, {rot = 10})
	k.ellipse(0.6, 0.68, 0.12, 0.3, W, {rot = -10})
	P.eyes(k, 0.5, 0.4, 0.06, 0.12)
	k.ellipse(0.5, 0.5, 0.08, 0.03, rgb(255, 120, 140))
	P.star(k, 0.36, 0.28, 0.06, rgb(200, 240, 255))
	k.rect(0.8, 0.6, 0.02, 0.35, rgb(180, 190, 200), {rot = 20})
	k.circle(0.76, 0.43, 0.08, rgb(200, 220, 240))
end

A["Hotline Maimi"] = function(k)
	k.sky(rgb(255, 80, 160), rgb(255, 200, 120))
	k.circle(0.5, 0.62, 0.55, rgb(255, 230, 120))
	for i = 0, 3 do
		k.rect(0.5, 0.56 + i * 0.07, 1.04, 0.02 + i * 0.008, rgb(255, 100, 170))
	end
	for _, p in ipairs({{0.12, 0.85}, {0.88, 0.8}}) do
		k.rect(p[1], p[2] - 0.2, 0.02, 0.4, rgb(60, 20, 60), {rot = p[1] < 0.5 and 5 or -5})
		for _, a in ipairs({-40, -10, 20, 50, 160, 190}) do
			k.ellipse(p[1] + math.cos(math.rad(a)) * 0.06, p[2] - 0.42 + math.sin(math.rad(a)) * 0.04, 0.14, 0.035, rgb(60, 20, 60), {rot = a})
		end
	end
	local phone = rgb(30, 220, 230)
	k.rect(0.5, 0.42, 0.3, 0.1, phone, {round = 0.5})
	k.rect(0.5, 0.52, 0.22, 0.12, phone, {round = 0.3})
	k.text(0.5, 0.25, 0.4, 0.1, "RING RING", W, {stroke = true})
end

A["Beet Saber"] = function(k)
	k.sky(rgb(10, 5, 25), rgb(30, 10, 60))
	neonGrid(k, CYAN)
	k.rect(0.25, 0.45, 0.025, 0.55, rgb(255, 60, 90), {rot = 25})
	k.rect(0.25, 0.45, 0.06, 0.55, rgb(255, 60, 90), {rot = 25, t = 0.75})
	k.rect(0.75, 0.45, 0.025, 0.55, CYAN, {rot = -25})
	k.rect(0.75, 0.45, 0.06, 0.55, CYAN, {rot = -25, t = 0.75})
	local beet = rgb(150, 20, 70)
	k.ellipse(0.42, 0.4, 0.16, 0.2, beet, {rot = -20})
	k.ellipse(0.58, 0.44, 0.16, 0.2, beet, {rot = 20})
	k.ellipse(0.4, 0.29, 0.03, 0.08, rgb(80, 180, 70), {rot = -30})
	k.ellipse(0.6, 0.33, 0.03, 0.08, rgb(80, 180, 70), {rot = 30})
	k.text(0.5, 0.15, 0.12, 0.14, "♫", W)
end

A["Geometry Splash"] = function(k)
	k.sky(rgb(80, 200, 255), rgb(200, 240, 255))
	k.waves(0.68, rgb(40, 130, 220), 0.12)
	P.sq(k, 0.3, 0.45, 0.16, rgb(255, 210, 50), {rot = 20})
	k.circle(0.55, 0.32, 0.14, rgb(255, 80, 120))
	k.rect(0.75, 0.5, 0.12, 0.12, rgb(120, 255, 120), {rot = 45})
	for _, d in ipairs({{0.2, 0.62}, {0.35, 0.6}, {0.62, 0.6}, {0.82, 0.62}, {0.5, 0.58}}) do
		k.circle(d[1], d[2], 0.05, W)
	end
	for _, d in ipairs({{0.25, 0.55}, {0.7, 0.55}, {0.45, 0.52}}) do
		k.circle(d[1], d[2], 0.03, rgb(180, 230, 255))
	end
end

return A

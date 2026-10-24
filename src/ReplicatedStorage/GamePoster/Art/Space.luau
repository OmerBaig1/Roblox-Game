-- Outer Space posters (Infinity)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local A = {}

local function space(k, rng, top, bottom)
	k.sky(top or rgb(5, 5, 25), bottom or rgb(35, 15, 70))
	k.stars(16, rng, 0.98)
end

A["No Man's Pie"] = function(k, rng)
	space(k, rng)
	k.circle(0.5, 0.55, 0.6, rgb(220, 160, 90))
	k.circle(0.5, 0.55, 0.5, rgb(170, 30, 60))
	for i = 0, 4 do
		k.rect(0.5, 0.55, 0.5, 0.025, rgb(230, 175, 100), {rot = i * 36})
	end
	k.circle(0.5, 0.55, 0.14, rgb(230, 175, 100))
	k.ellipse(0.5, 0.55, 0.9, 0.08, rgb(255, 200, 220), {rot = -12, t = 0.2})
	P.rocket(k, 0.85, 0.25, 0.5)
end

A["Starfeld"] = function(k, rng)
	space(k, rng, rgb(10, 10, 40), rgb(60, 30, 90))
	k.ellipse(0.5, 0.95, 1.4, 0.5, rgb(90, 70, 50))
	for row = 0, 2 do
		for col = 0, 4 do
			local x, y = 0.12 + col * 0.19 + row * 0.03, 0.7 + row * 0.09
			k.rect(x, y + 0.04, 0.01, 0.06, rgb(80, 170, 70))
			P.star(k, x, y, 0.06 + row * 0.01, GOLD)
		end
	end
	k.rect(0.12, 0.42, 0.015, 0.3, rgb(120, 80, 40))
	k.rect(0.12, 0.35, 0.12, 0.015, rgb(120, 80, 40))
	k.circle(0.12, 0.28, 0.06, rgb(240, 220, 160))
	k.ellipse(0.12, 0.24, 0.12, 0.04, rgb(200, 160, 90))
end

A["Star Bores"] = function(k, rng)
	space(k, rng)
	P.star(k, 0.5, 0.52, 0.6, rgb(255, 220, 80))
	k.circle(0.5, 0.52, 0.36, rgb(255, 230, 110))
	k.rect(0.42, 0.47, 0.07, 0.015, B)
	k.rect(0.58, 0.47, 0.07, 0.015, B)
	k.ellipse(0.42, 0.49, 0.07, 0.03, rgb(255, 230, 110))
	k.ellipse(0.5, 0.62, 0.08, 0.1, rgb(140, 70, 40))
	P.zzz(k, 0.78, 0.25, 1, W)
end

A["Among Bus"] = function(k, rng)
	space(k, rng)
	P.planet(k, 0.15, 0.18, 0.18, rgb(120, 200, 255), rgb(200, 230, 255))
	local yellow = rgb(255, 200, 30)
	k.rect(0.52, 0.58, 0.7, 0.3, yellow, {rot = -10, round = 0.15})
	k.rect(0.52, 0.52, 0.6, 0.1, rgb(140, 210, 255), {rot = -10})
	for i = -2, 2 do
		k.rect(0.52 + i * 0.12, 0.52 - i * 0.02, 0.01, 0.1, yellow, {rot = -10})
	end
	k.rect(0.52, 0.64, 0.66, 0.025, B, {rot = -10})
	k.circle(0.3, 0.76, 0.1, B)
	k.circle(0.72, 0.69, 0.1, B)
	k.text(0.5, 0.15, 0.45, 0.1, "SCHOOL BUS", GOLD)
end

A["Outer Mild"] = function(k, rng)
	space(k, rng)
	P.planet(k, 0.8, 0.8, 0.3, rgb(255, 140, 80))
	k.rect(0.45, 0.55, 0.32, 0.46, rgb(240, 240, 235), {round = 0.15, t = 0.1})
	k.rect(0.45, 0.6, 0.28, 0.32, rgb(240, 110, 60), {round = 0.1})
	k.rect(0.45, 0.3, 0.3, 0.08, rgb(60, 160, 70), {round = 0.2})
	k.rect(0.45, 0.55, 0.26, 0.1, W)
	k.text(0.45, 0.55, 0.22, 0.08, "MILD", rgb(60, 160, 70))
	for _, c in ipairs({{0.38, 0.72}, {0.5, 0.75}, {0.42, 0.82}, {0.53, 0.68}}) do
		k.circle(c[1], c[2], 0.03, rgb(255, 200, 120))
	end
end

A["Herbal Space Program"] = function(k, rng)
	space(k, rng)
	P.planet(k, 0.15, 0.85, 0.35, rgb(80, 160, 90))
	P.rocket(k, 0.55, 0.62, 1.3, rgb(235, 235, 240), rgb(60, 160, 80))
	k.rect(0.55, 0.28, 0.1, 0.07, rgb(200, 100, 60))
	for _, l in ipairs({{0.5, 0.2, -30}, {0.6, 0.2, 30}, {0.55, 0.16, 0}}) do
		k.ellipse(l[1], l[2], 0.05, 0.1, rgb(80, 200, 80), {rot = l[3]})
	end
end

A["Bed Space"] = function(k, rng)
	space(k, rng)
	P.planet(k, 0.82, 0.2, 0.2, rgb(200, 150, 255), rgb(255, 220, 255))
	local wood = rgb(140, 90, 55)
	k.rect(0.18, 0.55, 0.04, 0.3, wood)
	k.rect(0.82, 0.6, 0.04, 0.2, wood)
	k.rect(0.5, 0.65, 0.66, 0.12, wood)
	k.rect(0.5, 0.58, 0.62, 0.08, W, {round = 0.3})
	k.rect(0.56, 0.55, 0.5, 0.12, rgb(80, 120, 230), {round = 0.3})
	k.ellipse(0.27, 0.52, 0.14, 0.08, W)
	k.circle(0.3, 0.46, 0.08, P.SKIN)
	P.zzz(k, 0.4, 0.33, 0.9, W)
end

A["Hallo Infinite"] = function(k, rng)
	space(k, rng)
	local ring = rgb(120, 220, 255)
	for _, x in ipairs({0.36, 0.64}) do
		k.circle(x, 0.25, 0.26, ring)
		k.circle(x, 0.25, 0.18, rgb(15, 10, 40))
	end
	local skin = P.SKIN
	k.rect(0.5, 0.88, 0.14, 0.24, skin)
	k.rect(0.5, 0.68, 0.3, 0.22, skin, {round = 0.3})
	for i = 0, 3 do
		k.rect(0.39 + i * 0.075, 0.52, 0.06, 0.16, skin, {round = 1, rot = (i - 1.5) * 6})
	end
	k.rect(0.3, 0.7, 0.07, 0.14, skin, {round = 1, rot = -40})
end

A["Elite Dangerless"] = function(k, rng)
	space(k, rng)
	k.circle(0.5, 0.62, 0.5, rgb(255, 120, 60))
	k.circle(0.5, 0.62, 0.3, rgb(20, 10, 50))
	for i = 0, 3 do
		k.rect(0.5, 0.62, 0.5, 0.05, W, {rot = i * 45 + 22})
	end
	k.circle(0.5, 0.62, 0.3, rgb(20, 10, 50))
	P.astronaut(k, 0.5, 0.5, 1.3)
	k.ellipse(0.5, 0.29, 0.2, 0.05, rgb(255, 210, 40))
	k.rect(0.5, 0.26, 0.12, 0.06, rgb(255, 210, 40), {round = 0.4})
end

A["Super Marco Galaxy"] = function(k, rng)
	space(k, rng, rgb(20, 5, 40), rgb(60, 20, 90))
	for i = 0, 5 do
		k.ellipse(0.5, 0.5, 0.9 - i * 0.14, 0.6 - i * 0.09, ({rgb(160, 80, 255), rgb(255, 120, 200), rgb(120, 200, 255)})[i % 3 + 1], {rot = -20, t = 0.55})
	end
	k.circle(0.5, 0.5, 0.12, rgb(255, 245, 220))
	P.kart(k, 0.72, 0.28, 0.7, rgb(230, 50, 50))
	for i = 1, 4 do
		k.circle(0.72 - i * 0.05, 0.31 + i * 0.03, 0.02, GOLD, {t = i * 0.2})
	end
end

A["Ratchet & Crank"] = function(k, rng)
	space(k, rng)
	P.gear(k, 0.75, 0.75, 0.26, rgb(150, 155, 170))
	P.gear(k, 0.25, 0.25, 0.18, rgb(150, 155, 170))
	local steel = rgb(210, 215, 225)
	k.rect(0.5, 0.5, 0.06, 0.6, steel, {rot = 35, round = 0.3})
	k.circle(0.33, 0.25, 0.14, steel)
	k.circle(0.33, 0.25, 0.06, rgb(15, 10, 40))
	k.rect(0.5, 0.5, 0.05, 0.5, rgb(255, 200, 60), {rot = -35, round = 0.3})
	k.rect(0.66, 0.29, 0.12, 0.05, rgb(255, 200, 60), {rot = -35, round = 0.3})
	k.circle(0.35, 0.72, 0.06, rgb(230, 60, 60))
	k.text(0.5, 0.5, 0.1, 0.12, "&", W, {stroke = true})
end

A["Metro-Void Prime"] = function(k, rng)
	space(k, rng, rgb(5, 0, 15), rgb(30, 5, 50))
	for i = 0, 4 do
		k.circle(0.7, 0.4, 0.7 - i * 0.12, ({rgb(255, 120, 40), rgb(200, 60, 160), rgb(100, 40, 180)})[i % 3 + 1], {t = 0.3})
	end
	k.circle(0.7, 0.4, 0.18, B)
	local train = rgb(220, 220, 230)
	k.rect(0.3, 0.7, 0.5, 0.16, train, {rot = -25, round = 0.2})
	k.rect(0.3, 0.68, 0.44, 0.06, rgb(120, 200, 255), {rot = -25})
	k.rect(0.3, 0.73, 0.5, 0.025, rgb(230, 60, 60), {rot = -25})
	k.text(0.15, 0.15, 0.2, 0.18, "7", GOLD, {stroke = true})
end

A["Grand Theft Avocado VI"] = function(k, rng)
	space(k, rng, rgb(255, 120, 160), rgb(255, 200, 120))
	local skin, flesh = rgb(60, 110, 40), rgb(200, 230, 120)
	k.ellipse(0.45, 0.58, 0.42, 0.66, skin)
	k.ellipse(0.45, 0.6, 0.34, 0.56, flesh)
	k.circle(0.45, 0.7, 0.18, rgb(140, 90, 50))
	k.rect(0.45, 0.42, 0.34, 0.07, B)
	k.circle(0.4, 0.42, 0.03, W)
	k.circle(0.5, 0.42, 0.03, W)
	k.ellipse(0.78, 0.7, 0.26, 0.3, rgb(220, 210, 190))
	k.rect(0.78, 0.56, 0.06, 0.04, rgb(170, 160, 140))
	k.text(0.78, 0.72, 0.12, 0.14, "$", rgb(60, 140, 60))
	k.text(0.82, 0.2, 0.24, 0.2, "VI", W, {stroke = true})
end

A["Half-Lite 3"] = function(k, rng)
	space(k, rng)
	for i = 0, 7 do
		k.rect(0.5, 0.5, 0.04, 1.3, rgb(255, 200, 80), {rot = i * 22.5, t = 0.7})
	end
	P.can(k, 0.5, 0.52, 0.3, 0.55, rgb(255, 140, 30), "HALF", W)
	k.rect(0.5, 0.7, 0.3, 0.08, W)
	k.text(0.5, 0.7, 0.24, 0.06, "LITE 3", rgb(255, 140, 30))
	for _, s in ipairs({{0.2, 0.25}, {0.8, 0.3}, {0.25, 0.8}, {0.78, 0.82}}) do
		P.star(k, s[1], s[2], 0.07, rgb(255, 240, 160))
	end
end

A["Steal a Brainrut"] = function(k, rng)
	space(k, rng, rgb(30, 10, 50), rgb(90, 30, 110))
	k.rect(0.5, 0.88, 1.04, 0.26, rgb(110, 80, 60))
	k.ellipse(0.5, 0.8, 0.6, 0.12, rgb(70, 50, 40))
	P.brain(k, 0.5, 0.62, 2)
	P.eyes(k, 0.5, 0.6, 0.05, 0.1)
	k.ellipse(0.5, 0.7, 0.06, 0.03, B)
	k.ellipse(0.8, 0.45, 0.2, 0.24, rgb(220, 210, 190))
	k.rect(0.8, 0.33, 0.06, 0.04, rgb(170, 160, 140))
	k.text(0.8, 0.47, 0.1, 0.12, "$", rgb(60, 140, 60))
	k.text(0.22, 0.2, 0.3, 0.12, "STEAL!", GOLD, {stroke = true})
end

return A

-- Haunted Crypt posters (Legendary)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local NIGHT, NIGHT2 = rgb(18, 14, 40), rgb(60, 30, 80)
local ZOMBIE = rgb(130, 180, 110)
local A = {}

local function zombieHand(k, x, y, s)
	k.rect(x, y + 0.12 * s, 0.07 * s, 0.24 * s, ZOMBIE)
	k.ellipse(x, y, 0.12 * s, 0.1 * s, ZOMBIE)
	for i = -1, 2 do
		k.rect(x + i * 0.025 * s - 0.01 * s, y - 0.07 * s, 0.02 * s, 0.09 * s, ZOMBIE, {round = 1})
	end
	k.rect(x - 0.06 * s, y + 0.01 * s, 0.02 * s, 0.07 * s, ZOMBIE, {rot = -40, round = 1})
end

local function house(k, x, groundY, s, color)
	color = color or rgb(30, 25, 45)
	k.rect(x, groundY - 0.2 * s, 0.5 * s, 0.4 * s, color)
	k.rect(x, groundY - 0.43 * s, 0.4 * s, 0.1 * s, color)
	k.rect(x - 0.18 * s, groundY - 0.5 * s, 0.08 * s, 0.22 * s, color)
	for _, w in ipairs({{-0.12, -0.28}, {0.12, -0.28}, {-0.12, -0.13}, {0.12, -0.13}}) do
		k.rect(x + w[1] * s, groundY + w[2] * s, 0.07 * s, 0.08 * s, rgb(255, 210, 90))
	end
end

A["Resident Weevil"] = function(k)
	k.sky(NIGHT, NIGHT2)
	k.rect(0.5, 0.5, 0.5, 0.75, rgb(70, 50, 40))
	k.rect(0.5, 0.5, 0.42, 0.68, rgb(25, 18, 15))
	k.rect(0.5, 0.95, 1.04, 0.12, rgb(50, 40, 40))
	local shell = rgb(120, 70, 40)
	k.ellipse(0.5, 0.64, 0.34, 0.3, shell)
	k.rect(0.5, 0.64, 0.01, 0.3, shell:Lerp(B, 0.4))
	k.circle(0.5, 0.42, 0.16, shell:Lerp(B, 0.2))
	k.rect(0.5, 0.29, 0.03, 0.16, shell:Lerp(B, 0.2))
	k.circle(0.44, 0.42, 0.05, rgb(255, 80, 60))
	k.circle(0.56, 0.42, 0.05, rgb(255, 80, 60))
	for _, l in ipairs({{0.32, 0.6, 30}, {0.68, 0.6, -30}, {0.33, 0.72, -10}, {0.67, 0.72, 10}}) do
		k.rect(l[1], l[2], 0.1, 0.015, B, {rot = l[3]})
	end
	k.rect(0.5, 0.06, 0.5, 0.08, rgb(200, 30, 30))
	k.text(0.5, 0.06, 0.46, 0.06, "KEEP OUT", W)
end

A["Ghostdusters"] = function(k)
	k.sky(rgb(140, 120, 200), rgb(220, 200, 240))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(140, 100, 70))
	P.ghost(k, 0.45, 0.4, 1.6)
	k.ellipse(0.45, 0.55, 0.06, 0.04, rgb(255, 160, 170))
	k.rect(0.72, 0.4, 0.015, 0.36, rgb(140, 90, 50), {rot = 30})
	for i = 0, 4 do
		k.ellipse(0.8 + i * 0.012, 0.2 + i * 0.015, 0.05, 0.1, ({rgb(255, 120, 160), rgb(120, 200, 255), rgb(255, 220, 80)})[i % 3 + 1], {rot = 30 + i * 10})
	end
	for _, d in ipairs({{0.2, 0.8}, {0.3, 0.86}, {0.78, 0.82}, {0.88, 0.7}}) do
		P.star(k, d[1], d[2], 0.05, W)
	end
end

A["Luigo's Mansion"] = function(k, rng)
	k.sky(NIGHT, NIGHT2)
	k.stars(10, rng, 0.35)
	P.moon(k, 0.85, 0.15, 0.12)
	local brick = rgb(60, 140, 90)
	k.rect(0.5, 0.62, 0.62, 0.56, brick)
	for y = 0.4, 0.9, 0.09 do
		for x = 0.24, 0.78, 0.09 do
			k.circle(x, y, 0.035, brick:Lerp(W, 0.2))
		end
	end
	k.rect(0.5, 0.32, 0.7, 0.08, rgb(200, 50, 50))
	for x = 0.18, 0.82, 0.08 do
		k.circle(x, 0.27, 0.035, rgb(230, 70, 70))
	end
	k.rect(0.36, 0.55, 0.12, 0.14, rgb(255, 210, 90))
	k.rect(0.64, 0.55, 0.12, 0.14, rgb(255, 210, 90))
	P.ghost(k, 0.64, 0.53, 0.35)
	k.rect(0.5, 0.82, 0.12, 0.16, rgb(60, 35, 25))
end

A["Phasmophonia"] = function(k)
	k.sky(rgb(30, 40, 50), rgb(70, 90, 100))
	P.ghost(k, 0.4, 0.42, 1.5)
	local phone = rgb(200, 30, 40)
	k.ellipse(0.66, 0.4, 0.08, 0.2, phone, {rot = 20})
	k.rect(0.6, 0.48, 0.07, 0.05, phone, {rot = 20, round = 0.3})
	k.rect(0.72, 0.84, 0.36, 0.14, phone, {round = 0.3})
	k.rect(0.72, 0.84, 0.16, 0.1, rgb(240, 240, 240), {round = 0.5})
	for i = 0, 8 do
		k.circle(0.62 + i * 0.012, 0.6 + i * 0.025, 0.012, B)
	end
	k.text(0.84, 0.18, 0.2, 0.18, "?!", rgb(150, 255, 200), {stroke = true})
end

A["Dead by Midnight"] = function(k, rng)
	k.sky(rgb(10, 10, 30), rgb(40, 20, 60))
	k.stars(10, rng, 0.4)
	P.moon(k, 0.15, 0.15, 0.13)
	local stone = rgb(70, 60, 80)
	k.rect(0.55, 0.65, 0.32, 0.7, stone)
	k.rect(0.55, 0.28, 0.4, 0.06, stone:Lerp(B, 0.3))
	k.circle(0.55, 0.45, 0.26, rgb(240, 230, 200))
	k.circle(0.55, 0.45, 0.02, B)
	k.rect(0.55, 0.39, 0.012, 0.13, B)
	k.rect(0.55, 0.405, 0.012, 0.1, B, {rot = 5})
	for i = 0, 11 do
		local a = math.rad(i * 30)
		k.circle(0.55 + math.sin(a) * 0.11, 0.45 - math.cos(a) * 0.14, 0.012, B)
	end
	P.bat(k, 0.2, 0.45, 0.9)
	P.bat(k, 0.85, 0.35, 0.7)
	k.text(0.55, 0.85, 0.28, 0.1, "12:00", rgb(255, 80, 80))
end

A["Little Nightmarez"] = function(k)
	k.sky(rgb(15, 15, 30), rgb(30, 25, 50))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(60, 50, 70))
	k.circle(0.6, 0.45, 0.8, rgb(40, 20, 50), {t = 0.2})
	k.ellipse(0.62, 0.3, 0.1, 0.06, rgb(255, 60, 60))
	k.ellipse(0.78, 0.3, 0.1, 0.06, rgb(255, 60, 60))
	for i = 0, 4 do
		P.sq(k, 0.6 + i * 0.05, 0.46, 0.035, W, {rot = 45})
	end
	k.circle(0.25, 0.78, 0.22, rgb(255, 220, 120), {t = 0.5})
	k.rect(0.25, 0.83, 0.05, 0.1, rgb(240, 240, 240))
	k.ellipse(0.25, 0.75, 0.12, 0.1, rgb(255, 230, 140))
	k.rect(0.25, 0.88, 0.1, 0.02, rgb(180, 180, 190))
end

A["Left 4 Bread"] = function(k)
	k.sky(rgb(60, 60, 50), rgb(130, 120, 90))
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(70, 65, 60))
	local crust, inside = rgb(200, 130, 60), rgb(250, 225, 170)
	k.ellipse(0.4, 0.55, 0.38, 0.3, crust)
	k.rect(0.4, 0.68, 0.38, 0.14, crust)
	k.ellipse(0.4, 0.55, 0.32, 0.24, inside)
	P.eyes(k, 0.4, 0.52, 0.06, 0.1, -1)
	k.ellipse(0.4, 0.62, 0.06, 0.06, B)
	for _, l in ipairs({{0.32, 0.86, -20}, {0.48, 0.86, 20}}) do
		k.rect(l[1], l[2], 0.025, 0.12, crust, {rot = l[3]})
	end
	for i = 1, 3 do
		k.rect(0.15 - i * 0.0, 0.45 + i * 0.07, 0.08, 0.012, W, {t = 0.3})
	end
	zombieHand(k, 0.8, 0.6, 1.3)
	k.text(0.8, 0.14, 0.2, 0.2, "4", rgb(230, 40, 40), {stroke = true})
end

A["Pants vs. Zombies"] = function(k)
	k.sky(rgb(150, 210, 255), rgb(220, 240, 255))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.85, 0.2, 0.3, i % 2 == 0 and rgb(110, 190, 80) or rgb(95, 170, 70))
	end
	local denim = rgb(60, 100, 180)
	k.rect(0.28, 0.45, 0.24, 0.06, rgb(110, 75, 45))
	k.rect(0.22, 0.65, 0.1, 0.36, denim, {rot = 4})
	k.rect(0.34, 0.65, 0.1, 0.36, denim, {rot = -4})
	k.rect(0.28, 0.5, 0.22, 0.08, denim)
	P.eyes(k, 0.28, 0.53, 0.045, 0.08, 1)
	P.brows(k, 0.28, 0.49, 0.045, 0.08)
	zombieHand(k, 0.72, 0.52, 1.3)
	k.text(0.5, 0.15, 0.2, 0.16, "VS", rgb(230, 40, 40), {stroke = true})
end

A["Dying Lite"] = function(k)
	k.sky(rgb(10, 10, 15), rgb(30, 30, 35))
	k.rect(0.5, 0.06, 0.012, 0.14, rgb(90, 90, 90))
	k.rect(0.5, 0.16, 0.08, 0.06, rgb(150, 150, 155))
	k.circle(0.5, 0.32, 0.24, rgb(255, 230, 140), {t = 0.25})
	k.circle(0.5, 0.32, 0.14, rgb(255, 245, 200))
	k.rect(0.46, 0.3, 0.02, 0.06, rgb(200, 150, 60), {rot = 20})
	k.rect(0.54, 0.3, 0.02, 0.06, rgb(200, 150, 60), {rot = -20})
	k.rect(0.5, 0.75, 0.6, 0.5, rgb(255, 230, 140), {t = 0.85})
	local s = rgb(25, 25, 25)
	k.circle(0.3, 0.7, 0.1, s)
	k.rect(0.3, 0.86, 0.1, 0.22, s, {rot = 5})
	k.rect(0.38, 0.78, 0.12, 0.025, s, {rot = -10})
	k.circle(0.74, 0.72, 0.1, s)
	k.rect(0.74, 0.88, 0.1, 0.22, s, {rot = -5})
	k.rect(0.65, 0.8, 0.12, 0.025, s, {rot = 10})
end

A["Silent Bill"] = function(k)
	k.sky(rgb(150, 150, 150), rgb(200, 200, 195))
	for _, b in ipairs({{0.1, 0.2, 0.3}, {0.3, 0.15, 0.45}, {0.8, 0.22, 0.35}, {0.93, 0.15, 0.25}}) do
		k.rect(b[1], 1 - b[3] / 2, b[2], b[3], rgb(120, 120, 120), {t = 0.4})
	end
	local money = rgb(140, 200, 140)
	k.rect(0.5, 0.52, 0.66, 0.4, money, {round = 0.05})
	k.rect(0.5, 0.52, 0.6, 0.33, money:Lerp(B, 0.15))
	k.circle(0.5, 0.5, 0.2, money)
	P.eyes(k, 0.5, 0.45, 0.04, 0.07)
	k.rect(0.5, 0.56, 0.1, 0.02, B)
	for x = 0.46, 0.54, 0.02 do
		k.rect(x, 0.56, 0.006, 0.035, rgb(200, 200, 200))
	end
	k.text(0.27, 0.42, 0.07, 0.1, "$", rgb(40, 90, 40))
	k.text(0.73, 0.62, 0.07, 0.1, "$", rgb(40, 90, 40))
	k.rect(0.5, 0.85, 1.04, 0.3, W, {t = 0.5})
end

A["Outpast"] = function(k)
	k.sky(rgb(10, 40, 15), rgb(30, 90, 40))
	for y = 0.05, 1, 0.08 do
		k.rect(0.5, y, 1.04, 0.01, rgb(120, 255, 140), {t = 0.85})
	end
	k.circle(0.5, 0.5, 0.5, rgb(170, 255, 180), {t = 0.6})
	k.circle(0.5, 0.5, 0.42, rgb(20, 60, 25))
	k.rect(0.5, 0.42, 0.015, 0.16, rgb(170, 255, 180))
	k.rect(0.45, 0.5, 0.1, 0.015, rgb(170, 255, 180), {rot = 20})
	k.text(0.5, 0.88, 0.5, 0.12, "◄◄ REWIND", rgb(170, 255, 180))
	k.circle(0.88, 0.1, 0.04, rgb(255, 60, 60))
	k.text(0.13, 0.1, 0.14, 0.08, "REC", rgb(170, 255, 180))
end

A["Amnesiac"] = function(k)
	k.sky(rgb(20, 15, 30), rgb(50, 40, 60))
	for i = 0, 3 do
		k.rect(0.5, 0.5, 0.9 - i * 0.2, 0.9 - i * 0.2, rgb(60 - i * 10, 50 - i * 10, 70 - i * 10))
	end
	P.brain(k, 0.5, 0.45, 2)
	for _, q in ipairs({{0.18, 0.2, -15}, {0.82, 0.25, 15}, {0.2, 0.8, 10}, {0.82, 0.78, -10}}) do
		k.text(q[1], q[2], 0.12, 0.18, "?", rgb(255, 220, 120), {rot = q[3], stroke = true})
	end
end

A["Vampire Thrivers"] = function(k)
	k.sky(rgb(60, 20, 50), rgb(150, 60, 90))
	k.rect(0.5, 0.94, 1.04, 0.12, rgb(70, 45, 35))
	k.rect(0.68, 0.86, 0.18, 0.12, rgb(190, 90, 60))
	local stem = rgb(70, 170, 70)
	k.rect(0.68, 0.6, 0.02, 0.4, stem)
	for _, l in ipairs({{0.62, 0.62, -30}, {0.74, 0.55, 30}, {0.63, 0.45, -30}}) do
		k.ellipse(l[1], l[2], 0.1, 0.05, rgb(90, 200, 80), {rot = l[3]})
	end
	k.circle(0.68, 0.33, 0.14, rgb(230, 40, 80))
	k.circle(0.68, 0.33, 0.05, GOLD)
	P.bat(k, 0.28, 0.3, 1.8)
	k.circle(0.26, 0.29, 0.015, rgb(255, 60, 60))
	k.circle(0.3, 0.29, 0.015, rgb(255, 60, 60))
	k.rect(0.32, 0.45, 0.1, 0.06, rgb(150, 160, 180), {rot = 20, round = 0.3})
	for i = 0, 2 do
		k.circle(0.4 + i * 0.03, 0.5 + i * 0.03, 0.015, rgb(120, 200, 255))
	end
end

A["Floodborne"] = function(k)
	k.sky(rgb(20, 20, 40), rgb(60, 50, 80))
	P.moon(k, 0.75, 0.2, 0.2)
	local s = rgb(25, 20, 35)
	k.rect(0.25, 0.5, 0.2, 0.6, s)
	k.rect(0.25, 0.18, 0.06, 0.12, s)
	k.rect(0.25, 0.1, 0.012, 0.08, s)
	k.rect(0.5, 0.58, 0.16, 0.45, s)
	k.rect(0.5, 0.33, 0.1, 0.08, s, {rot = 45})
	k.rect(0.78, 0.6, 0.2, 0.4, s)
	for _, w in ipairs({{0.22, 0.45}, {0.28, 0.55}, {0.5, 0.55}, {0.75, 0.58}, {0.82, 0.62}}) do
		k.rect(w[1], w[2], 0.03, 0.05, rgb(255, 200, 80))
	end
	k.waves(0.72, rgb(30, 60, 100), 0.1, {t = 0.1})
	k.waves(0.82, rgb(40, 80, 130), 0.09)
end

A["Vampurr"] = function(k, rng)
	k.sky(NIGHT, NIGHT2)
	k.stars(8, rng, 0.3)
	P.moon(k, 0.82, 0.16, 0.14)
	k.rect(0.5, 0.8, 0.6, 0.4, rgb(150, 20, 40))
	k.rect(0.5, 0.8, 0.5, 0.4, rgb(40, 20, 40))
	local fur = rgb(40, 40, 50)
	P.sq(k, 0.36, 0.28, 0.12, fur, {rot = 45})
	P.sq(k, 0.64, 0.28, 0.12, fur, {rot = 45})
	k.circle(0.5, 0.48, 0.38, fur)
	k.ellipse(0.4, 0.44, 0.08, 0.1, rgb(255, 220, 60))
	k.ellipse(0.6, 0.44, 0.08, 0.1, rgb(255, 220, 60))
	k.ellipse(0.4, 0.44, 0.02, 0.08, B)
	k.ellipse(0.6, 0.44, 0.02, 0.08, B)
	k.ellipse(0.5, 0.53, 0.04, 0.025, rgb(255, 120, 150))
	k.rect(0.47, 0.6, 0.02, 0.05, W)
	k.rect(0.53, 0.6, 0.02, 0.05, W)
	for _, w in ipairs({{0.34, 0.55, 8}, {0.66, 0.55, -8}}) do
		k.rect(w[1], w[2], 0.14, 0.008, W, {rot = w[3], t = 0.3})
	end
end

return A

-- Toy Town posters (Rare)
local P = require(script.Parent.Parent.Pieces)
local rgb = Color3.fromRGB
local W, B, GOLD = P.WHITE, P.BLACK, P.GOLD
local A = {}

local function teddy(k, x, y, s, fur)
	fur = fur or rgb(190, 130, 80)
	k.ellipse(x, y + 0.17 * s, 0.24 * s, 0.26 * s, fur)
	k.circle(x - 0.09 * s, y - 0.1 * s, 0.08 * s, fur)
	k.circle(x + 0.09 * s, y - 0.1 * s, 0.08 * s, fur)
	k.circle(x, y, 0.2 * s, fur)
	k.ellipse(x, y + 0.04 * s, 0.08 * s, 0.06 * s, fur:Lerp(W, 0.4))
	k.circle(x, y + 0.025 * s, 0.025 * s, B)
	k.circle(x - 0.04 * s, y - 0.02 * s, 0.022 * s, B)
	k.circle(x + 0.04 * s, y - 0.02 * s, 0.022 * s, B)
end

A["Fall Toys"] = function(k)
	k.sky(rgb(255, 170, 90), rgb(255, 230, 180))
	k.rect(0.5, 0.15, 1.04, 0.04, rgb(140, 90, 50))
	for _, l in ipairs({{0.15, 0.3, 30}, {0.8, 0.4, -20}, {0.45, 0.85, 60}, {0.9, 0.8, 10}, {0.25, 0.65, -40}}) do
		k.ellipse(l[1], l[2], 0.06, 0.03, rgb(220, 90, 30), {rot = l[3]})
	end
	teddy(k, 0.3, 0.42, 0.9)
	P.sq(k, 0.62, 0.36, 0.12, rgb(80, 160, 255), {rot = 25})
	k.text(0.62, 0.36, 0.08, 0.08, "A", W, {rot = 25})
	k.circle(0.75, 0.62, 0.14, rgb(230, 50, 70))
	k.rect(0.75, 0.62, 0.14, 0.02, W)
	P.sq(k, 0.5, 0.75, 0.1, rgb(90, 200, 100), {rot = -30})
	k.text(0.5, 0.75, 0.07, 0.07, "B", W, {rot = -30})
	for _, m in ipairs({{0.3, 0.2}, {0.62, 0.22}, {0.75, 0.47}}) do
		k.rect(m[1], m[2], 0.01, 0.06, W, {t = 0.4})
	end
end

A["Puppy Playtime"] = function(k)
	k.sky(rgb(150, 220, 255), rgb(230, 250, 255))
	k.ellipse(0.5, 1, 1.2, 0.3, rgb(120, 200, 100))
	k.rect(0.8, 0.72, 0.26, 0.24, rgb(255, 200, 60))
	k.rect(0.8, 0.6, 0.28, 0.04, rgb(230, 150, 40))
	local fur = rgb(240, 200, 150)
	k.ellipse(0.4, 0.7, 0.32, 0.2, fur)
	k.rect(0.26, 0.6, 0.06, 0.04, fur, {rot = -40, round = 1})
	k.circle(0.55, 0.52, 0.22, fur)
	k.ellipse(0.46, 0.5, 0.07, 0.16, rgb(170, 120, 80), {rot = 15})
	k.ellipse(0.64, 0.5, 0.07, 0.16, rgb(170, 120, 80), {rot = -15})
	P.eyes(k, 0.55, 0.49, 0.04, 0.08)
	k.circle(0.55, 0.56, 0.03, B)
	k.ellipse(0.56, 0.62, 0.035, 0.05, rgb(255, 110, 130))
	k.circle(0.18, 0.82, 0.1, rgb(230, 60, 60))
	k.rect(0.18, 0.82, 0.1, 0.012, W, {rot = 30})
end

A["Kirbo's Dream Land"] = function(k, rng)
	k.sky(rgb(40, 30, 90), rgb(120, 80, 170))
	k.stars(12, rng, 0.5)
	k.rect(0.5, 0.92, 1.04, 0.16, rgb(70, 70, 80))
	local curb = rgb(190, 190, 200)
	k.rect(0.45, 0.76, 0.6, 0.14, curb)
	k.rect(0.45, 0.7, 0.6, 0.02, rgb(230, 230, 235))
	k.rect(0.36, 0.76, 0.06, 0.012, B, {rot = 10})
	k.rect(0.52, 0.76, 0.06, 0.012, B, {rot = -10})
	k.ellipse(0.44, 0.8, 0.04, 0.025, rgb(200, 90, 100))
	P.zzz(k, 0.72, 0.62, 1.2, W)
	for _, b in ipairs({{0.55, 0.52, 0.04}, {0.6, 0.44, 0.06}}) do
		k.circle(b[1], b[2], b[3], W, {t = 0.2})
	end
	k.ellipse(0.6, 0.25, 0.5, 0.3, W, {t = 0.1})
	P.star(k, 0.48, 0.25, 0.1, rgb(255, 220, 80))
	k.ellipse(0.65, 0.25, 0.12, 0.08, rgb(255, 160, 200))
	k.circle(0.74, 0.22, 0.05, rgb(255, 160, 200))
end

A["Minecrate"] = function(k)
	k.sky(rgb(70, 60, 55), rgb(40, 35, 32))
	k.rect(0.5, 0.9, 1.04, 0.025, rgb(120, 120, 130))
	for x = 0.04, 1, 0.1 do
		k.rect(x, 0.92, 0.04, 0.03, rgb(100, 70, 40))
	end
	k.rect(0.45, 0.72, 0.5, 0.2, rgb(110, 110, 120))
	k.circle(0.3, 0.85, 0.08, B)
	k.circle(0.6, 0.85, 0.08, B)
	local wood = rgb(200, 150, 90)
	k.rect(0.45, 0.5, 0.36, 0.3, wood)
	k.rect(0.45, 0.5, 0.42, 0.04, wood:Lerp(B, 0.3), {rot = 35})
	k.rect(0.45, 0.36, 0.36, 0.03, wood:Lerp(B, 0.3))
	k.rect(0.45, 0.64, 0.36, 0.03, wood:Lerp(B, 0.3))
	k.rect(0.78, 0.4, 0.025, 0.4, rgb(130, 90, 50), {rot = 30})
	k.rect(0.72, 0.26, 0.2, 0.05, rgb(170, 180, 190), {rot = 30, round = 0.5})
	for _, g in ipairs({{0.12, 0.2}, {0.2, 0.55}, {0.88, 0.75}}) do
		k.circle(g[1], g[2], 0.03, rgb(90, 230, 255))
	end
end

A["Blocko Galaxy Wars"] = function(k, rng)
	k.sky(rgb(5, 5, 25), rgb(25, 15, 55))
	k.stars(18, rng, 0.95)
	P.planet(k, 0.15, 0.8, 0.3, rgb(80, 160, 230))
	local function ship(x, y, c)
		P.sq(k, x, y, 0.08, c)
		P.sq(k, x - 0.08, y, 0.08, c:Lerp(B, 0.2))
		P.sq(k, x + 0.08, y, 0.08, c:Lerp(B, 0.2))
		P.sq(k, x, y - 0.1, 0.05, rgb(120, 200, 255))
		for _, dx in ipairs({-0.04, 0, 0.04, -0.12, -0.08, 0.08, 0.12}) do
			k.circle(x + dx, y - 0.06, 0.02, c)
		end
	end
	ship(0.35, 0.4, rgb(230, 60, 60))
	ship(0.72, 0.62, rgb(60, 120, 230))
	k.rect(0.5, 0.5, 0.25, 0.012, rgb(80, 255, 120), {rot = 35})
	k.rect(0.56, 0.38, 0.2, 0.012, rgb(255, 80, 80), {rot = 35})
end

-- Fortnut: a squad of three posing on a heap of crates and giant nuts as a purple storm rolls in, the storm's hands
-- reaching up out of the ground
local function squadHero(k, x, y, s, outfit, skin, hair, gear)
	local dark = outfit:Lerp(B, 0.35)
	k.rect(x - 0.03 * s, y + 0.17 * s, 0.04 * s, 0.16 * s, dark, {round = 0.3})
	k.rect(x + 0.03 * s, y + 0.17 * s, 0.04 * s, 0.16 * s, dark, {round = 0.3})
	k.rect(x, y + 0.03 * s, 0.11 * s, 0.17 * s, outfit, {round = 0.25})
	k.rect(x, y + 0.09 * s, 0.11 * s, 0.025 * s, rgb(90, 60, 30))
	k.rect(x - 0.07 * s, y + 0.02 * s, 0.03 * s, 0.13 * s, skin, {round = 0.5, rot = 12})
	if gear == "raised" then
		-- the giant nutcracker held up high
		k.rect(x + 0.07 * s, y - 0.07 * s, 0.03 * s, 0.14 * s, skin, {round = 0.5, rot = -20})
		k.rect(x + 0.1 * s, y - 0.2 * s, 0.022 * s, 0.22 * s, rgb(110, 110, 122), {rot = 15})
		k.rect(x + 0.13 * s, y - 0.31 * s, 0.09 * s, 0.07 * s, W, {round = 0.2, rot = 15, grad = {rgb(255, 225, 110), rgb(200, 140, 30), 90}})
	elseif gear == "hammer" then
		k.rect(x + 0.07 * s, y + 0.02 * s, 0.03 * s, 0.13 * s, skin, {round = 0.5, rot = -12})
		k.rect(x + 0.1 * s, y + 0.02 * s, 0.02 * s, 0.26 * s, rgb(90, 70, 50), {rot = -30})
		k.rect(x + 0.16 * s, y - 0.1 * s, 0.1 * s, 0.07 * s, W, {round = 0.2, rot = -30, grad = {rgb(215, 225, 240), rgb(110, 120, 140), 90}})
	else
		-- a slingshot drawn back
		k.rect(x + 0.07 * s, y - 0.02 * s, 0.03 * s, 0.12 * s, skin, {round = 0.5, rot = -60})
		k.rect(x + 0.13 * s, y - 0.06 * s, 0.012 * s, 0.08 * s, rgb(110, 70, 40), {rot = 20})
		k.rect(x + 0.155 * s, y - 0.06 * s, 0.012 * s, 0.08 * s, rgb(110, 70, 40), {rot = -20})
	end
	k.circle(x, y - 0.11 * s, 0.09 * s, skin)
	k.ellipse(x, y - 0.16 * s, 0.1 * s, 0.06 * s, hair)
	k.rect(x - 0.018 * s, y - 0.11 * s, 0.012 * s, 0.014 * s, B)
	k.rect(x + 0.018 * s, y - 0.11 * s, 0.012 * s, 0.014 * s, B)
	k.rect(x, y - 0.075 * s, 0.03 * s, 0.008 * s, rgb(120, 50, 50))
end
A["Fortnut"] = function(k, rng)
	k.sky(rgb(70, 130, 230), rgb(195, 228, 255))
	-- the storm rolling in over the top
	for i = 0, 6 do
		k.ellipse(i * 0.18, 0.03 + (i % 2) * 0.05, 0.3, 0.22, rgb(115, 55, 175))
	end
	for i = 0, 5 do
		k.ellipse(0.09 + i * 0.18, 0.13, 0.22, 0.12, rgb(170, 100, 220), {t = 0.2})
	end
	k.circle(0.5, 0.42, 0.55, rgb(255, 245, 200), {t = 0.55})
	-- the heap: crates with plank lines, and giant nuts
	local crate = rgb(170, 110, 60)
	for i, c in ipairs({{0.18, 0.88, 0.26}, {0.46, 0.86, 0.3}, {0.74, 0.89, 0.28}, {0.32, 0.72, 0.22}, {0.62, 0.73, 0.22}}) do
		local h = c[3] / 0.775 * 0.8
		k.rect(c[1], c[2], c[3], h, crate:Lerp(B, i % 2 * 0.12))
		k.rect(c[1], c[2], c[3], 0.015, crate:Lerp(B, 0.4))
		k.rect(c[1], c[2], 0.012, h, crate:Lerp(B, 0.4))
	end
	for _, n in ipairs({{0.06, 0.74}, {0.92, 0.7}, {0.88, 0.95}}) do
		k.ellipse(n[1], n[2], 0.12, 0.16, rgb(205, 150, 85))
		k.ellipse(n[1], n[2] - 0.07, 0.13, 0.06, rgb(120, 80, 45))
	end
	-- the squad, the leader in front and above
	squadHero(k, 0.24, 0.47, 0.85, rgb(70, 92, 145), rgb(150, 100, 70), rgb(30, 25, 30), "sling")
	squadHero(k, 0.76, 0.48, 0.85, rgb(135, 70, 60), rgb(255, 215, 180), rgb(250, 210, 90), "hammer")
	squadHero(k, 0.5, 0.4, 1, rgb(60, 112, 72), rgb(230, 175, 130), rgb(120, 70, 35), "raised")
	-- the storm's hands reaching up out of the ground
	for _, x in ipairs({0.08, 0.3, 0.62, 0.95}) do
		k.rect(x, 0.97, 0.04, 0.1, rgb(150, 170, 130))
		for f = -1, 1 do
			k.rect(x + f * 0.014, 0.91, 0.01, 0.04, rgb(150, 170, 130))
		end
	end
end

A["Bayblade Burst"] = function(k)
	k.sky(rgb(255, 190, 120), rgb(160, 220, 255))
	k.waves(0.6, rgb(50, 140, 200), 0.12)
	k.ellipse(0.5, 0.7, 0.6, 0.12, rgb(70, 170, 220))
	k.ellipse(0.5, 0.54, 0.4, 0.16, rgb(230, 60, 60))
	k.ellipse(0.5, 0.52, 0.3, 0.1, rgb(255, 200, 60))
	k.rect(0.5, 0.42, 0.05, 0.14, rgb(150, 150, 160))
	k.rect(0.5, 0.64, 0.03, 0.06, rgb(150, 150, 160))
	for i = 0, 3 do
		k.ellipse(0.5, 0.54, 0.62 + i * 0.08, 0.26 + i * 0.04, W, {t = 0.85})
	end
	k.text(0.5, 0.17, 0.6, 0.18, "BURST!", W, {stroke = true})
end

A["Super Donkey Ball"] = function(k)
	k.sky(rgb(120, 200, 255), rgb(240, 250, 255))
	local tile = rgb(240, 120, 60)
	k.rect(0.5, 0.86, 0.9, 0.08, tile)
	k.rect(0.5, 0.92, 0.9, 0.04, tile:Lerp(B, 0.3))
	k.circle(0.5, 0.52, 0.56, rgb(180, 230, 255), {t = 0.55})
	local grey = rgb(150, 145, 140)
	k.ellipse(0.5, 0.6, 0.24, 0.14, grey)
	k.ellipse(0.62, 0.46, 0.13, 0.1, grey, {rot = 20})
	k.rect(0.59, 0.36, 0.02, 0.08, grey, {rot = -10})
	k.rect(0.63, 0.36, 0.02, 0.08, grey, {rot = 15})
	k.circle(0.64, 0.44, 0.025, B)
	for _, x in ipairs({0.43, 0.47, 0.53, 0.57}) do
		k.rect(x, 0.7, 0.02, 0.07, grey)
	end
	k.circle(0.42, 0.36, 0.08, W, {t = 0.3})
end

A["Katamari Dramacy"] = function(k, rng)
	k.sky(rgb(255, 150, 200), rgb(255, 220, 140))
	k.ellipse(0.5, 1, 1.2, 0.26, rgb(120, 200, 100))
	k.circle(0.5, 0.58, 0.5, rgb(200, 90, 160))
	local junk = {rgb(255, 80, 80), rgb(80, 200, 255), rgb(255, 220, 60), rgb(120, 255, 140), rgb(255, 255, 255), rgb(150, 100, 60)}
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local x, y = 0.5 + math.cos(a) * 0.24, 0.58 + math.sin(a) * 0.3
		k.rect(x, y, rng:NextNumber(0.05, 0.1), rng:NextNumber(0.05, 0.1), junk[i % #junk + 1], {rot = rng:NextNumber(0, 90), round = rng:NextNumber() < 0.5 and 0.3 or nil})
	end
	k.ellipse(0.32, 0.18, 0.14, 0.16, W)
	k.ellipse(0.32, 0.16, 0.025, 0.03, B)
	k.ellipse(0.29, 0.16, 0.02, 0.02, B)
	k.ellipse(0.32, 0.22, 0.05, 0.02, B)
	k.ellipse(0.68, 0.18, 0.14, 0.16, GOLD)
	k.ellipse(0.65, 0.16, 0.02, 0.02, B)
	k.ellipse(0.71, 0.16, 0.02, 0.02, B)
	k.ellipse(0.68, 0.23, 0.06, 0.04, B)
end

-- Five Nights at Teddy's: a worn old animatronic bear leaning out of the dark of a night-shift office, one glassy
-- eye catching the light; a desk fan and a child's crayon drawing on the wall behind
A["Five Nights at Teddy's"] = function(k, rng)
	k.sky(rgb(14, 11, 14), rgb(30, 22, 22))
	-- the office: a crayon drawing pinned to the wall, the desk, the fan
	k.rect(0.17, 0.3, 0.2, 0.24, rgb(150, 140, 120), {rot = -4, t = 0.3})
	k.circle(0.13, 0.27, 0.05, rgb(70, 110, 200), {t = 0.35})
	k.rect(0.2, 0.32, 0.04, 0.08, rgb(200, 60, 60), {t = 0.35})
	k.rect(0.17, 0.39, 0.14, 0.012, rgb(90, 150, 70), {t = 0.35})
	k.rect(0.17, 0.19, 0.012, 0.03, rgb(140, 140, 145))
	k.rect(0.3, 0.86, 0.75, 0.05, rgb(42, 35, 30))
	k.rect(0.3, 0.95, 0.75, 0.14, rgb(22, 18, 16))
	local fx, fy = 0.17, 0.6
	k.rect(fx, 0.76, 0.025, 0.14, rgb(45, 45, 50))
	k.ellipse(fx, 0.84, 0.12, 0.03, rgb(35, 35, 40))
	k.circle(fx, fy, 0.2, rgb(62, 62, 68))
	k.circle(fx, fy, 0.175, rgb(20, 18, 20))
	for i = 0, 2 do
		k.ellipse(fx, fy, 0.05, 0.22, rgb(72, 72, 78), {rot = i * 60, t = 0.2})
	end
	k.circle(fx, fy, 0.04, rgb(85, 85, 90))
	-- the bear: an enormous head leaning in from the right, lit from the left and lost in shadow on the right
	local fur = rgb(112, 86, 58)
	k.circle(0.85, 0.14, 0.24, fur:Lerp(B, 0.4))
	k.circle(0.85, 0.14, 0.13, rgb(70, 50, 35))
	k.circle(0.7, 0.62, 0.9, W, {grad = {fur:Lerp(W, 0.12), fur:Lerp(B, 0.75), 0}})
	-- a battered top hat
	k.rect(0.76, 0.1, 0.46, 0.05, rgb(14, 12, 14))
	k.rect(0.78, 0.04, 0.3, 0.1, rgb(14, 12, 14))
	k.rect(0.78, 0.075, 0.3, 0.02, rgb(60, 20, 25))
	-- brow, the socket and the eye
	k.ellipse(0.6, 0.35, 0.34, 0.1, fur:Lerp(B, 0.5), {rot = -8})
	k.ellipse(0.6, 0.47, 0.25, 0.22, rgb(8, 6, 8))
	k.circle(0.59, 0.47, 0.13, W, {grad = {rgb(240, 244, 252), rgb(140, 155, 185), 90}})
	k.circle(0.6, 0.47, 0.065, rgb(105, 125, 170))
	k.circle(0.6, 0.47, 0.035, rgb(8, 8, 12))
	k.circle(0.575, 0.445, 0.02, W)
	-- muzzle and nose, the jaw hanging open a crack over old teeth
	k.ellipse(0.52, 0.76, 0.42, 0.3, W, {grad = {rgb(152, 122, 90), rgb(68, 50, 34), 0}})
	k.ellipse(0.47, 0.66, 0.12, 0.07, rgb(14, 10, 10))
	k.circle(0.45, 0.65, 0.018, rgb(85, 75, 75))
	k.rect(0.55, 0.92, 0.36, 0.06, rgb(10, 6, 6))
	for i = 0, 3 do
		k.rect(0.42 + i * 0.07, 0.9, 0.04, 0.04, rgb(215, 205, 180))
	end
	-- wear and tear in the fur
	for _ = 1, 9 do
		k.circle(rng:NextNumber(0.45, 0.95), rng:NextNumber(0.3, 0.95), rng:NextNumber(0.01, 0.025), rgb(40, 28, 20), {t = 0.4})
	end
	-- the dark swallowing the far side of his face
	k.ellipse(1.05, 0.6, 0.6, 1.3, B, {t = 0.25})
end

A["Plushmon Go"] = function(k)
	k.sky(rgb(120, 200, 150), rgb(90, 170, 120))
	for i = 1, 4 do
		k.rect(i * 0.2, 0.5, 0.03, 1, rgb(240, 240, 220), {t = 0.3})
		k.rect(0.5, i * 0.2, 1, 0.04, rgb(240, 240, 220), {t = 0.3})
	end
	k.rect(0.5, 0.52, 0.42, 0.92, B, {round = 0.12})
	k.rect(0.5, 0.52, 0.38, 0.84, rgb(140, 220, 160))
	k.rect(0.5, 0.75, 0.38, 0.05, rgb(240, 240, 220))
	local plush = rgb(255, 170, 200)
	k.ellipse(0.5, 0.5, 0.2, 0.26, plush)
	k.ellipse(0.43, 0.32, 0.05, 0.12, plush, {rot = -15})
	k.ellipse(0.57, 0.32, 0.05, 0.12, plush, {rot = 15})
	P.eyes(k, 0.5, 0.46, 0.035, 0.07)
	k.ellipse(0.5, 0.53, 0.03, 0.02, rgb(220, 90, 120))
	k.circle(0.5, 0.82, 0.07, rgb(230, 50, 50))
	k.circle(0.5, 0.82, 0.03, W)
end

A["Webkins Whirl"] = function(k)
	k.sky(rgb(255, 220, 240), rgb(200, 230, 255))
	k.rect(0.5, 0.48, 0.02, 0.7, GOLD)
	k.ellipse(0.5, 0.18, 0.7, 0.14, rgb(230, 70, 110))
	for x = 0.2, 0.8, 0.1 do
		k.circle(x, 0.24, 0.05, rgb(255, 255, 255))
	end
	k.ellipse(0.5, 0.86, 0.8, 0.12, rgb(200, 120, 220))
	local pals = {{0.24, 0.6, rgb(255, 180, 120)}, {0.5, 0.65, rgb(150, 220, 255)}, {0.76, 0.6, rgb(180, 255, 160)}}
	for _, p in ipairs(pals) do
		k.rect(p[1], 0.48, 0.01, 0.6, rgb(200, 200, 210))
		k.ellipse(p[1], p[2], 0.14, 0.14, p[3])
		k.circle(p[1] - 0.04, p[2] - 0.08, 0.05, p[3])
		k.circle(p[1] + 0.04, p[2] - 0.08, 0.05, p[3])
		k.circle(p[1] - 0.02, p[2] - 0.01, 0.02, B)
		k.circle(p[1] + 0.02, p[2] - 0.01, 0.02, B)
	end
	for i = 0, 2 do
		k.ellipse(0.5, 0.5, 0.95 - i * 0.05, 0.08, W, {t = 0.75, rot = -8})
	end
end

A["Cup Hat"] = function(k)
	k.sky(rgb(250, 230, 200), rgb(230, 200, 160))
	k.ellipse(0.5, 0.78, 0.7, 0.12, rgb(255, 255, 255))
	k.ellipse(0.5, 0.78, 0.55, 0.08, rgb(220, 230, 240))
	k.rect(0.5, 0.52, 0.4, 0.42, W, {round = 0.12})
	k.ellipse(0.5, 0.31, 0.4, 0.08, rgb(150, 90, 50))
	k.ellipse(0.73, 0.52, 0.14, 0.2, W)
	k.ellipse(0.73, 0.52, 0.07, 0.12, rgb(240, 220, 190))
	k.rect(0.5, 0.68, 0.4, 0.05, rgb(80, 120, 220))
	P.eyes(k, 0.5, 0.5, 0.06, 0.12)
	k.ellipse(0.5, 0.58, 0.08, 0.03, rgb(200, 90, 90))
	local hat = rgb(30, 30, 35)
	k.ellipse(0.5, 0.29, 0.5, 0.07, hat)
	k.rect(0.5, 0.16, 0.28, 0.24, hat, {round = 0.1})
	k.rect(0.5, 0.24, 0.28, 0.04, rgb(200, 40, 60))
	k.ellipse(0.6, 0.09, 0.05, 0.08, rgb(255, 210, 60), {rot = 30})
end

A["Wayman Legends"] = function(k)
	k.sky(rgb(140, 120, 220), rgb(255, 190, 150))
	k.ellipse(0.25, 0.85, 0.7, 0.3, rgb(90, 160, 100))
	k.ellipse(0.8, 0.88, 0.7, 0.32, rgb(70, 140, 90))
	k.rect(0.5, 0.88, 0.16, 0.3, rgb(220, 200, 150), {rot = 10})
	k.rect(0.72, 0.45, 0.02, 0.5, rgb(120, 85, 50))
	k.rect(0.78, 0.28, 0.2, 0.08, rgb(220, 180, 100), {rot = -5})
	k.text(0.78, 0.28, 0.16, 0.06, "WAY →", rgb(80, 50, 30), {rot = -5})
	k.rect(0.3, 0.6, 0.18, 0.25, rgb(220, 40, 60), {rot = -15})
	P.person(k, 0.33, 0.5, 1.1, rgb(240, 200, 60))
	k.rect(0.4, 0.44, 0.1, 0.02, P.SKIN, {rot = -50})
	P.star(k, 0.48, 0.32, 0.06, GOLD)
end

A["Little Big Plant"] = function(k)
	k.sky(rgb(140, 210, 255), rgb(230, 248, 255))
	k.rect(0.5, 0.95, 1.04, 0.1, rgb(140, 100, 70))
	k.rect(0.5, 0.84, 0.12, 0.1, rgb(200, 100, 60))
	k.rect(0.5, 0.78, 0.15, 0.03, rgb(170, 80, 50))
	local stem = rgb(70, 160, 70)
	k.rect(0.5, 0.44, 0.04, 0.7, stem)
	for _, l in ipairs({{0.38, 0.6, -30, 0.24}, {0.62, 0.48, 30, 0.26}, {0.36, 0.32, -25, 0.28}, {0.64, 0.2, 25, 0.24}}) do
		k.ellipse(l[1], l[2], l[4], 0.1, rgb(90, 190, 80), {rot = l[3]})
	end
	k.circle(0.5, 0.08, 0.14, rgb(255, 120, 160))
	k.circle(0.5, 0.08, 0.06, GOLD)
	P.person(k, 0.78, 0.8, 0.4, rgb(230, 60, 60))
end

return A

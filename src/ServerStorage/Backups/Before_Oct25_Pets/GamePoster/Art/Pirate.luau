--[[
	Pirate zone posters (Epic). One function per game, keyed by the game's exact name.
	Each gets a drawing kit (see GamePoster) and a Random seeded by the game's name.
]]

local rgb = Color3.fromRGB
local WHITE, BLACK = rgb(255, 255, 255), rgb(15, 15, 20)
local WOOD, DARK_WOOD = rgb(140, 90, 50), rgb(90, 55, 30)
local GOLD, BONE = rgb(255, 205, 60), rgb(240, 232, 210)
local SEA, DEEP = rgb(40, 120, 175), rgb(25, 80, 130)

-- Shared pieces ----------------------------------------------------

local function ship(k, cx, baseY, s, sail, hull)
	sail = sail or rgb(245, 240, 225)
	hull = hull or rgb(110, 65, 35)
	k.rect(cx - 0.08 * s, baseY - 0.25 * s, 0.022 * s, 0.5 * s, DARK_WOOD)
	k.rect(cx + 0.11 * s, baseY - 0.2 * s, 0.02 * s, 0.4 * s, DARK_WOOD)
	k.rect(cx - 0.05 * s, baseY - 0.48 * s, 0.07 * s, 0.05 * s, rgb(210, 40, 40))
	k.rect(cx - 0.08 * s, baseY - 0.3 * s, 0.22 * s, 0.24 * s, sail, {round = 0.12})
	k.rect(cx + 0.11 * s, baseY - 0.22 * s, 0.18 * s, 0.18 * s, sail, {round = 0.12})
	k.rect(cx, baseY - 0.02 * s, 0.52 * s, 0.09 * s, hull)
	k.ellipse(cx, baseY + 0.03 * s, 0.48 * s, 0.11 * s, hull)
	k.rect(cx, baseY - 0.035 * s, 0.52 * s, 0.018 * s, GOLD)
	for i = -1, 1 do
		k.circle(cx + i * 0.12 * s, baseY + 0.02 * s, 0.025 * s, BLACK)
	end
end

local function palm(k, x, groundY, s, color)
	color = color or rgb(60, 160, 70)
	k.rect(x, groundY - 0.17 * s, 0.025 * s, 0.34 * s, rgb(120, 80, 45), {rot = 6})
	local tx, ty = x + 0.018 * s, groundY - 0.34 * s
	for _, a in ipairs({-35, -10, 15, 40, 170}) do
		k.ellipse(tx + math.cos(math.rad(a)) * 0.06 * s, ty + math.sin(math.rad(a)) * 0.04 * s, 0.15 * s, 0.045 * s, color, {rot = a})
	end
	k.circle(tx - 0.01 * s, ty + 0.02 * s, 0.025 * s, rgb(110, 75, 40))
end

local function parrot(k, x, y, s, body, wing, angry)
	k.rect(x - 0.02 * s, y + 0.2 * s, 0.05 * s, 0.17 * s, wing, {rot = 12, round = 0.5})
	k.ellipse(x, y, 0.15 * s, 0.32 * s, body)
	k.ellipse(x - 0.03 * s, y + 0.03 * s, 0.09 * s, 0.22 * s, wing, {rot = 12})
	k.circle(x + 0.015 * s, y - 0.17 * s, 0.13 * s, body)
	k.rect(x + 0.08 * s, y - 0.15 * s, 0.045 * s, 0.06 * s, GOLD, {rot = 35, round = 0.3})
	k.circle(x + 0.035 * s, y - 0.2 * s, 0.05 * s, WHITE)
	k.circle(x + 0.042 * s, y - 0.2 * s, 0.025 * s, BLACK)
	if angry then
		k.rect(x + 0.035 * s, y - 0.25 * s, 0.07 * s, 0.018 * s, BLACK, {rot = 25})
	end
	k.rect(x - 0.01 * s, y + 0.17 * s, 0.015 * s, 0.05 * s, GOLD)
	k.rect(x + 0.03 * s, y + 0.17 * s, 0.015 * s, 0.05 * s, GOLD)
end

local function pirateHat(k, x, y, s)
	k.ellipse(x, y + 0.04 * s, 0.34 * s, 0.07 * s, BLACK)
	k.rect(x, y, 0.22 * s, 0.1 * s, BLACK, {round = 0.35})
	k.circle(x, y, 0.035 * s, BONE)
	k.rect(x, y + 0.035 * s, 0.24 * s, 0.012 * s, GOLD)
end

local function coin(k, x, y, d)
	k.circle(x, y, d, rgb(200, 150, 30))
	k.circle(x, y, d * 0.75, GOLD)
end

-- Posters --------------------------------------------------------

local A = {}

A["Sea of Robbers"] = function(k)
	k.sky(rgb(20, 24, 48), rgb(80, 85, 120))
	k.circle(0.82, 0.2, 0.15, rgb(235, 235, 205))
	k.ellipse(0.25, 0.16, 0.5, 0.1, rgb(45, 50, 78))
	k.ellipse(0.62, 0.1, 0.38, 0.08, rgb(40, 44, 70))
	k.rect(0.3, 0.3, 0.012, 0.22, rgb(255, 240, 150), {rot = 20})
	ship(k, 0.48, 0.64, 1.05, rgb(25, 25, 30))
	k.waves(0.8, DEEP, 0.15)
	k.waves(0.9, SEA, 0.12)
end

A["Assassin's Greed: Black Flag"] = function(k)
	k.sky(rgb(70, 40, 100), rgb(255, 150, 90))
	k.waves(0.82, DEEP, 0.12)
	k.ellipse(0.72, 0.86, 0.6, 0.18, rgb(230, 200, 140))
	for _, c in ipairs({{0.6, 0.78}, {0.7, 0.76}, {0.8, 0.78}, {0.65, 0.7}, {0.75, 0.69}, {0.7, 0.62}, {0.88, 0.8}}) do
		coin(k, c[1], c[2], 0.09)
	end
	k.rect(0.28, 0.48, 0.022, 0.72, DARK_WOOD)
	k.circle(0.28, 0.12, 0.04, GOLD)
	k.rect(0.46, 0.27, 0.34, 0.24, BLACK, {round = 0.05})
	k.rect(0.46, 0.27, 0.22, 0.03, BONE, {rot = 30})
	k.rect(0.46, 0.27, 0.22, 0.03, BONE, {rot = -30})
	k.circle(0.46, 0.25, 0.11, BLACK)
	k.text(0.46, 0.26, 0.12, 0.16, "$", GOLD)
end

A["Pirates of the Carrot-bean"] = function(k)
	k.sky(rgb(255, 120, 130), rgb(255, 190, 100))
	k.circle(0.5, 0.7, 0.55, rgb(255, 225, 130))
	k.waves(0.8, rgb(40, 150, 160), 0.13)
	k.ellipse(0.5, 0.55, 0.17, 0.62, rgb(255, 130, 30), {rot = 8})
	for i = 0, 3 do
		k.rect(0.49 + i * 0.012, 0.42 + i * 0.09, 0.05, 0.012, rgb(210, 90, 20), {rot = 8})
	end
	for _, a in ipairs({-25, 0, 25}) do
		k.ellipse(0.46 + a * 0.0015, 0.2, 0.04, 0.16, rgb(70, 170, 60), {rot = a})
	end
	pirateHat(k, 0.49, 0.29, 0.9)
	k.circle(0.53, 0.42, 0.06, WHITE)
	k.circle(0.54, 0.42, 0.03, BLACK)
	k.rect(0.47, 0.42, 0.14, 0.018, BLACK, {rot = -20})
	k.circle(0.46, 0.43, 0.05, BLACK)
end

A["Uncharred"] = function(k)
	k.sky(rgb(240, 222, 178), rgb(212, 182, 132))
	k.ellipse(0.25, 0.35, 0.22, 0.2, rgb(110, 165, 90), {t = 0.2})
	k.ellipse(0.7, 0.68, 0.26, 0.2, rgb(110, 165, 90), {t = 0.2})
	local path = {{0.12, 0.85}, {0.2, 0.75}, {0.3, 0.68}, {0.38, 0.6}, {0.42, 0.5}, {0.5, 0.42}, {0.6, 0.38}, {0.68, 0.33}}
	for _, p in ipairs(path) do
		k.circle(p[1], p[2], 0.025, rgb(110, 60, 30))
	end
	k.rect(0.77, 0.27, 0.13, 0.03, rgb(200, 30, 30), {rot = 45})
	k.rect(0.77, 0.27, 0.13, 0.03, rgb(200, 30, 30), {rot = -45})
	k.text(0.88, 0.82, 0.12, 0.14, "N", rgb(110, 60, 30))
	local char = rgb(50, 30, 18)
	k.rect(0.5, 0.025, 1, 0.07, char, {t = 0.15})
	k.rect(0.5, 0.975, 1, 0.07, char, {t = 0.15})
	k.rect(0.02, 0.5, 0.05, 1, char, {t = 0.15})
	k.rect(0.98, 0.5, 0.05, 1, char, {t = 0.15})
	for _, c in ipairs({{0.05, 0.08}, {0.95, 0.1}, {0.06, 0.92}, {0.93, 0.9}, {0.5, 0.04}, {0.04, 0.5}}) do
		k.circle(c[1], c[2], 0.12, char, {t = 0.25})
	end
	k.circle(0.92, 0.12, 0.05, rgb(255, 120, 30), {t = 0.2})
end

A["Skull and Phones"] = function(k)
	k.sky(rgb(20, 18, 40), rgb(70, 30, 80))
	k.rect(0.5, 0.66, 0.78, 0.05, BONE, {rot = 22, round = 1})
	k.rect(0.5, 0.66, 0.78, 0.05, BONE, {rot = -22, round = 1})
	k.circle(0.5, 0.42, 0.34, BONE)
	k.rect(0.5, 0.63, 0.2, 0.15, BONE, {round = 0.2})
	k.circle(0.43, 0.42, 0.085, BLACK)
	k.circle(0.57, 0.42, 0.085, BLACK)
	k.rect(0.5, 0.53, 0.04, 0.04, BLACK, {rot = 45})
	for i = -1, 1 do
		k.rect(0.5 + i * 0.05, 0.65, 0.012, 0.09, BLACK)
	end
	local red = rgb(230, 50, 70)
	k.rect(0.5, 0.13, 0.42, 0.04, red, {round = 1})
	k.rect(0.3, 0.27, 0.03, 0.26, red, {round = 1})
	k.rect(0.7, 0.27, 0.03, 0.26, red, {round = 1})
	k.ellipse(0.31, 0.44, 0.09, 0.2, red)
	k.ellipse(0.69, 0.44, 0.09, 0.2, red)
	k.text(0.13, 0.25, 0.14, 0.2, "♪", GOLD)
	k.text(0.87, 0.65, 0.14, 0.2, "♫", GOLD)
end

A["One Peace"] = function(k)
	k.sky(rgb(110, 190, 255), rgb(205, 236, 255))
	k.circle(0.15, 0.15, 0.14, rgb(255, 240, 150))
	k.ellipse(0.78, 0.82, 0.32, 0.12, rgb(235, 210, 150))
	palm(k, 0.78, 0.8, 0.7)
	k.waves(0.86, SEA, 0.11)
	k.rect(0.32, 0.42, 0.1, 0.06, WHITE, {rot = 20, round = 0.3})
	k.ellipse(0.46, 0.4, 0.28, 0.14, WHITE)
	k.ellipse(0.43, 0.29, 0.22, 0.09, rgb(225, 230, 240), {rot = -28})
	k.circle(0.6, 0.34, 0.09, WHITE)
	k.rect(0.66, 0.35, 0.04, 0.025, rgb(255, 160, 50), {round = 0.4})
	k.circle(0.62, 0.32, 0.018, BLACK)
	k.rect(0.71, 0.38, 0.1, 0.01, rgb(80, 120, 50), {rot = 15})
	for i = 0, 2 do
		k.ellipse(0.69 + i * 0.03, 0.36 + i * 0.012, 0.035, 0.03, rgb(110, 160, 60), {rot = 30})
	end
end

A["Subnaughtica"] = function(k, rng)
	k.sky(rgb(35, 150, 180), rgb(6, 28, 64))
	for _, x in ipairs({0.2, 0.45, 0.75}) do
		k.rect(x, 0.3, 0.07, 0.6, WHITE, {rot = 12, t = 0.88})
	end
	k.ellipse(0.5, 0.95, 1.1, 0.16, rgb(200, 180, 120))
	for _, x in ipairs({0.1, 0.16, 0.85, 0.92}) do
		k.rect(x, 0.82, 0.03, 0.24, rgb(50, 150, 80), {round = 1, rot = rng:NextNumber(-10, 10)})
	end
	local y = rgb(255, 210, 40)
	k.rect(0.53, 0.3, 0.012, 0.1, rgb(90, 90, 100))
	k.rect(0.52, 0.36, 0.11, 0.09, y, {round = 0.3})
	k.ellipse(0.5, 0.48, 0.44, 0.22, y)
	k.rect(0.26, 0.48, 0.03, 0.12, rgb(90, 90, 100))
	for _, x in ipairs({0.4, 0.5, 0.6}) do
		k.circle(x, 0.48, 0.065, rgb(60, 60, 70))
		k.circle(x, 0.48, 0.045, rgb(150, 220, 255))
	end
	for _, b in ipairs({{0.75, 0.35, 0.03}, {0.79, 0.27, 0.022}, {0.76, 0.19, 0.03}, {0.81, 0.12, 0.018}}) do
		k.circle(b[1], b[2], b[3], WHITE, {t = 0.45})
	end
	k.ellipse(0.2, 0.68, 0.08, 0.05, rgb(255, 130, 60))
	k.rect(0.25, 0.68, 0.03, 0.05, rgb(255, 130, 60), {rot = 45})
end

A["Daft Raft"] = function(k)
	k.sky(rgb(120, 200, 255), rgb(220, 240, 255))
	k.circle(0.82, 0.16, 0.13, rgb(255, 235, 120))
	k.ellipse(0.15, 0.68, 0.22, 0.08, rgb(235, 210, 150))
	palm(k, 0.15, 0.66, 0.45)
	k.waves(0.7, DEEP, 0.12)
	k.rect(0.86, 0.69, 0.08, 0.08, rgb(120, 130, 140), {rot = 45})
	k.rect(0.45, 0.42, 0.018, 0.4, DARK_WOOD)
	k.rect(0.53, 0.42, 0.16, 0.24, rgb(235, 225, 195), {rot = 3})
	k.rect(0.5, 0.36, 0.05, 0.05, rgb(200, 90, 90), {rot = 3})
	k.rect(0.57, 0.48, 0.05, 0.06, rgb(90, 140, 200), {rot = 3})
	for i = 0, 1 do
		k.rect(0.45, 0.66 + i * 0.05, 0.46, 0.055, i == 0 and WOOD or DARK_WOOD, {round = 1})
	end
	k.waves(0.78, SEA, 0.1)
end

A["Battleshrimp"] = function(k)
	k.sky(rgb(30, 90, 160), rgb(20, 55, 110))
	for i = 1, 7 do
		k.rect(i / 8, 0.5, 0.005, 1, WHITE, {t = 0.75})
		k.rect(0.5, i / 8, 1, 0.006, WHITE, {t = 0.75})
	end
	for _, p in ipairs({{1, 1}, {6, 2}, {2, 6}, {7, 6}, {5, 7}}) do
		k.circle(p[1] / 8, p[2] / 8, 0.04, p[1] % 2 == 0 and rgb(230, 50, 50) or WHITE)
	end
	local pink, deepPink = rgb(255, 130, 140), rgb(220, 90, 110)
	local body = {{0.36, 0.3, 0.13}, {0.45, 0.33, 0.13}, {0.53, 0.4, 0.12}, {0.58, 0.49, 0.11}, {0.58, 0.59, 0.09}, {0.54, 0.67, 0.075}, {0.48, 0.71, 0.06}}
	for i, b in ipairs(body) do
		k.circle(b[1], b[2], b[3], i % 2 == 0 and deepPink or pink)
	end
	k.rect(0.43, 0.74, 0.06, 0.03, deepPink, {rot = 30})
	k.rect(0.43, 0.69, 0.06, 0.03, deepPink, {rot = -30})
	k.circle(0.33, 0.27, 0.035, BLACK)
	k.rect(0.24, 0.2, 0.16, 0.008, deepPink, {rot = 25})
	k.rect(0.25, 0.26, 0.15, 0.008, deepPink, {rot = 10})
	k.rect(0.5, 0.24, 0.17, 0.05, rgb(60, 60, 70), {rot = -25, round = 0.3})
	k.circle(0.47, 0.3, 0.05, rgb(40, 40, 45))
end

A["Angry Parrots"] = function(k)
	k.sky(rgb(90, 180, 255), rgb(200, 235, 255))
	k.waves(0.88, SEA, 0.1)
	k.rect(0.2, 0.5, 0.035, 1, WOOD)
	k.rect(0.5, 0.8, 0.9, 0.04, WOOD, {round = 1})
	parrot(k, 0.55, 0.45, 1.7, rgb(230, 50, 50), rgb(40, 110, 220), true)
	k.text(0.84, 0.18, 0.22, 0.18, "!!", rgb(230, 50, 50), {stroke = true})
end

A["The Secret of Donkey Island"] = function(k, rng)
	k.sky(rgb(15, 20, 60), rgb(80, 40, 110))
	k.stars(14, rng, 0.45)
	k.circle(0.25, 0.25, 0.22, rgb(240, 235, 200), {t = 0.05})
	k.waves(0.82, rgb(20, 40, 90), 0.1)
	k.ellipse(0.55, 0.84, 0.75, 0.2, rgb(25, 20, 35))
	palm(k, 0.82, 0.78, 0.75, rgb(25, 20, 35))
	local s = rgb(25, 20, 35)
	for _, x in ipairs({0.42, 0.46, 0.56, 0.6}) do
		k.rect(x, 0.72, 0.018, 0.12, s)
	end
	k.ellipse(0.51, 0.63, 0.24, 0.13, s)
	k.rect(0.38, 0.55, 0.05, 0.14, s, {rot = 25})
	k.ellipse(0.33, 0.47, 0.1, 0.07, s, {rot = 30})
	k.rect(0.36, 0.39, 0.016, 0.08, s, {rot = 10})
	k.rect(0.39, 0.4, 0.016, 0.08, s, {rot = 25})
	k.rect(0.63, 0.62, 0.05, 0.012, s, {rot = 30})
	k.text(0.8, 0.22, 0.2, 0.3, "?", GOLD, {stroke = true})
end

A["Sid Meier's Parrots!"] = function(k)
	k.sky(rgb(255, 200, 110), rgb(255, 240, 200))
	k.waves(0.86, SEA, 0.1)
	k.rect(0.5, 0.74, 1.02, 0.045, WOOD)
	for _, x in ipairs({0.1, 0.37, 0.63, 0.9}) do
		k.rect(x, 0.82, 0.03, 0.14, DARK_WOOD)
	end
	parrot(k, 0.22, 0.48, 0.85, rgb(230, 50, 50), rgb(250, 200, 40))
	parrot(k, 0.5, 0.48, 0.85, rgb(40, 120, 230), rgb(255, 210, 60))
	parrot(k, 0.78, 0.48, 0.85, rgb(60, 180, 70), rgb(240, 90, 60))
end

A["Pirate 102"] = function(k)
	k.sky(rgb(40, 85, 60), rgb(30, 65, 48))
	local chalk = rgb(235, 240, 230)
	k.text(0.5, 0.18, 0.8, 0.2, "PIRATE 102", chalk, {font = Enum.Font.PermanentMarker})
	k.rect(0.5, 0.3, 0.6, 0.012, chalk, {t = 0.3})
	k.ellipse(0.32, 0.56, 0.3, 0.07, chalk, {t = 0.15})
	k.rect(0.32, 0.5, 0.18, 0.12, chalk, {t = 0.15, round = 0.35})
	k.text(0.55, 0.53, 0.08, 0.14, "+", chalk, {font = Enum.Font.PermanentMarker})
	k.rect(0.7, 0.53, 0.1, 0.02, chalk, {rot = 45})
	k.rect(0.7, 0.53, 0.1, 0.02, chalk, {rot = -45})
	k.text(0.83, 0.53, 0.14, 0.18, "=$", GOLD, {font = Enum.Font.PermanentMarker})
	local frame = rgb(150, 100, 55)
	k.rect(0.5, 0.02, 1, 0.05, frame)
	k.rect(0.02, 0.5, 0.04, 1, frame)
	k.rect(0.98, 0.5, 0.04, 1, frame)
	k.rect(0.5, 0.9, 1, 0.07, frame)
	k.rect(0.3, 0.86, 0.08, 0.025, chalk, {round = 1})
	k.circle(0.8, 0.83, 0.07, rgb(220, 40, 40))
	k.rect(0.81, 0.77, 0.01, 0.04, DARK_WOOD)
end

A["Port Royalty"] = function(k)
	k.sky(rgb(110, 60, 140), rgb(255, 160, 90))
	local colors = {rgb(230, 200, 150), rgb(200, 120, 90), rgb(240, 230, 210), rgb(170, 140, 110), rgb(210, 160, 120), rgb(230, 210, 170)}
	local x = 0.05
	for i, c in ipairs(colors) do
		local h = 0.16 + (i % 3) * 0.05
		k.rect(x + 0.07, 0.72 - h / 2, 0.14, h, c)
		k.rect(x + 0.07, 0.72 - h - 0.02, 0.15, 0.04, rgb(150, 60, 50))
		k.rect(x + 0.07, 0.72 - h / 2, 0.035, 0.05, rgb(255, 220, 110))
		x += 0.15
	end
	k.rect(0.5, 0.74, 1.02, 0.04, DARK_WOOD)
	k.waves(0.82, DEEP, 0.1)
	ship(k, 0.78, 0.78, 0.45)
	k.rect(0.5, 0.28, 0.32, 0.09, GOLD)
	for _, cx in ipairs({0.36, 0.5, 0.64}) do
		k.rect(cx, 0.2, 0.07, 0.07, GOLD, {rot = 45})
		k.circle(cx, 0.14, 0.035, GOLD)
	end
	k.circle(0.5, 0.28, 0.045, rgb(220, 40, 60))
	k.circle(0.4, 0.28, 0.03, rgb(60, 140, 230))
	k.circle(0.6, 0.28, 0.03, rgb(60, 200, 110))
end

A["Sea Hogs"] = function(k)
	k.sky(rgb(130, 200, 255), rgb(230, 245, 255))
	k.waves(0.8, DEEP, 0.12)
	local pink, darkPink = rgb(255, 170, 185), rgb(230, 120, 145)
	k.rect(0.37, 0.27, 0.08, 0.1, darkPink, {rot = -25, round = 0.3})
	k.rect(0.63, 0.27, 0.08, 0.1, darkPink, {rot = 25, round = 0.3})
	k.circle(0.5, 0.45, 0.34, pink)
	k.ellipse(0.5, 0.52, 0.15, 0.1, darkPink)
	k.circle(0.47, 0.52, 0.025, rgb(150, 60, 80))
	k.circle(0.53, 0.52, 0.025, rgb(150, 60, 80))
	k.circle(0.42, 0.42, 0.04, BLACK)
	k.rect(0.5, 0.38, 0.36, 0.015, BLACK, {rot = 25})
	k.circle(0.58, 0.42, 0.065, BLACK)
	pirateHat(k, 0.5, 0.22, 1)
	k.ellipse(0.5, 0.74, 0.52, 0.22, WOOD)
	for _, x in ipairs({0.34, 0.5, 0.66}) do
		k.rect(x, 0.74, 0.025, 0.2, DARK_WOOD)
	end
	k.waves(0.88, SEA, 0.1)
end

return A

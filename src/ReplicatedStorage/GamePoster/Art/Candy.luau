--[[
	Candy Kingdom posters (Gumdrop Galleria and Chocolate Factory). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(40, 20, 20)
local PINK, MINT, CHOC, CARAMEL = rgb(255, 150, 200), rgb(150, 240, 200), rgb(110, 60, 35), rgb(240, 170, 70)

local function candyland(k, rng, top, bottom)
	k.sky(top or rgb(255, 200, 230), bottom or rgb(200, 240, 255))
	k.waves(0.82, MINT, 0.22)
	for _ = 1, 10 do
		k.rect(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.85, 0.98), 0.03, 0.01, ({rgb(255, 90, 140), rgb(255, 220, 60), rgb(90, 160, 255)})[rng:NextInteger(1, 3)], {rot = rng:NextNumber(0, 180)})
	end
end
local function lollipop(k, x, groundY, s, color)
	k.rect(x, groundY - 0.15 * s, 0.015 * s, 0.3 * s, W)
	k.circle(x, groundY - 0.32 * s, 0.14 * s, color)
	k.circle(x, groundY - 0.32 * s, 0.08 * s, W)
	k.circle(x, groundY - 0.32 * s, 0.04 * s, color)
end
local function bear(k, x, y, s, color)
	k.circle(x, y, 0.22 * s, color, {t = 0.1})
	k.circle(x, y - 0.14 * s, 0.15 * s, color, {t = 0.1})
	k.circle(x - 0.06 * s, y - 0.22 * s, 0.06 * s, color)
	k.circle(x + 0.06 * s, y - 0.22 * s, 0.06 * s, color)
	P.eyes(k, x, y - 0.15 * s, 0.03 * s, 0.035 * s)
end

local A = {}

A["Candy Crash Saga"] = function(k, rng)
	-- a wall of bright sweets in a grid, three in a row exploding
	k.sky(rgb(120, 60, 160), rgb(255, 120, 190))
	local colors = {rgb(255, 80, 80), rgb(255, 210, 60), rgb(80, 200, 120), rgb(80, 150, 255), rgb(200, 100, 255)}
	for r = 0, 3 do
		for c = 0, 4 do
			k.circle(0.14 + c * 0.18, 0.25 + r * 0.17, 0.13, colors[(r * 3 + c) % #colors + 1])
		end
	end
	P.star(k, 0.5, 0.42, 0.3, W)
	k.text(0.5, 0.42, 0.25, 0.12, "CRASH!", rgb(255, 60, 140), {stroke = true})
end
A["Cookie Crunch Run"] = function(k, rng)
	-- a gingerbread runner fleeing across a cookie bridge, crumbs flying
	candyland(k, rng)
	k.rect(0.5, 0.72, 1, 0.08, rgb(200, 140, 70))
	for i = 0, 6 do
		k.circle(0.07 + i * 0.15, 0.72, 0.03, CHOC)
	end
	k.circle(0.45, 0.48, 0.12, rgb(200, 130, 60))
	k.rect(0.45, 0.6, 0.14, 0.14, rgb(200, 130, 60), {round = 0.3})
	k.rect(0.38, 0.68, 0.04, 0.1, rgb(200, 130, 60), {rot = 30})
	k.rect(0.52, 0.68, 0.04, 0.1, rgb(200, 130, 60), {rot = -30})
	P.smile(k, 0.45, 0.5, 0.05, W)
	for i = 0, 2 do
		k.rect(0.45, 0.58 + i * 0.03, 0.02, 0.02, rgb(255, 60, 60), {round = 1})
	end
end
A["Sugar Rush Racers"] = function(k, rng)
	-- go-karts racing down a candy-cane track
	candyland(k, rng, rgb(255, 170, 210), rgb(255, 230, 160))
	for i = 0, 9 do
		k.rect(0.05 + i * 0.1, 0.78, 0.1, 0.05, i % 2 == 0 and rgb(230, 40, 60) or W)
	end
	P.kart(k, 0.35, 0.7, 1.1, rgb(255, 80, 160))
	P.kart(k, 0.68, 0.66, 0.9, rgb(80, 180, 255))
	lollipop(k, 0.88, 0.75, 1, rgb(255, 210, 60))
end
A["Gummy Bear Grylls"] = function(k, rng)
	-- a survivalist gummy bear with a knife and backpack in a jelly jungle
	k.sky(rgb(120, 220, 140), rgb(40, 140, 80))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.4, 0.06, 0.8, rgb(90, 200, 110), {round = 0.5, t = 0.2})
	end
	bear(k, 0.5, 0.65, 1.6, rgb(255, 90, 110))
	k.rect(0.5, 0.55, 0.22, 0.04, rgb(110, 80, 40))
	k.rect(0.7, 0.6, 0.04, 0.16, rgb(200, 205, 215), {rot = -30})
end
A["Lollipop Chainsoar"] = function(k, rng)
	-- a cheerleader soaring on a giant lollipop, a chainsaw made of candy
	k.sky(rgb(255, 120, 190), rgb(255, 220, 240))
	lollipop(k, 0.42, 1.0, 2.2, rgb(255, 60, 140))
	P.person(k, 0.45, 0.35, 0.55, rgb(255, 210, 60), rgb(255, 210, 170), rgb(255, 90, 160))
	k.rect(0.7, 0.4, 0.2, 0.08, rgb(255, 60, 140), {round = 0.3})
	for i = 0, 5 do
		k.rect(0.62 + i * 0.03, 0.35, 0.02, 0.02, W)
	end
end
A["Kirbo's Snack Land"] = function(k, rng)
	-- a round pink puffball inhaling a whole cake
	candyland(k, rng, rgb(180, 230, 255), rgb(255, 230, 240))
	k.circle(0.32, 0.55, 0.36, PINK)
	P.eyes(k, 0.3, 0.5, 0.04, 0.06)
	k.circle(0.42, 0.6, 0.1, rgb(160, 40, 70))
	for i = 0, 3 do
		k.rect(0.55 + i * 0.05, 0.6, 0.06, 0.01, W, {t = 0.4})
	end
	k.rect(0.78, 0.6, 0.22, 0.16, rgb(255, 240, 220), {round = 0.2})
	k.rect(0.78, 0.52, 0.22, 0.04, rgb(255, 120, 160), {round = 0.5})
	k.rect(0.78, 0.46, 0.015, 0.06, rgb(255, 220, 120))
end
A["Willy's Wonka Kart"] = function(k, rng)
	-- a top-hatted chocolatier racing a kart across a chocolate river
	k.sky(rgb(255, 210, 140), rgb(170, 230, 150))
	k.waves(0.72, CHOC, 0.15)
	P.kart(k, 0.5, 0.66, 1.4, rgb(140, 60, 160))
	k.rect(0.5, 0.36, 0.1, 0.12, rgb(80, 40, 100))
	k.rect(0.5, 0.42, 0.16, 0.02, rgb(80, 40, 100))
	for i = 0, 2 do
		k.circle(0.15 + i * 0.35, 0.25 + (i % 2) * 0.1, 0.08, ({rgb(255, 80, 120), rgb(255, 210, 60), rgb(80, 200, 255)})[i + 1])
	end
end
A["Overbaked"] = function(k, rng)
	-- two chefs panicking around a cake that's on fire
	k.sky(rgb(255, 220, 190), rgb(240, 160, 120))
	k.rect(0.5, 0.82, 1, 0.3, rgb(240, 240, 240))
	k.rect(0.5, 0.62, 0.3, 0.18, rgb(255, 230, 200), {round = 0.2})
	for i = -2, 2 do
		k.ellipse(0.5 + i * 0.06, 0.45, 0.06, 0.14, i % 2 == 0 and rgb(255, 120, 30) or rgb(255, 210, 60))
	end
	P.person(k, 0.2, 0.8, 0.6, W, rgb(255, 210, 170), rgb(60, 60, 70))
	P.person(k, 0.8, 0.8, 0.6, W, rgb(200, 150, 110), rgb(60, 60, 70))
	k.text(0.5, 0.15, 0.4, 0.12, "!!", rgb(230, 40, 40), {stroke = true})
end
A["Choco Bombo"] = function(k, rng)
	-- a round chocolate bomb with a candle fuse, about to burst into sprinkles
	k.sky(rgb(255, 180, 120), rgb(120, 60, 40))
	k.circle(0.5, 0.58, 0.48, CHOC)
	k.circle(0.42, 0.5, 0.12, rgb(160, 100, 60), {t = 0.4})
	k.rect(0.5, 0.27, 0.04, 0.1, rgb(255, 240, 220))
	P.star(k, 0.5, 0.2, 0.12, rgb(255, 200, 60))
	for _ = 1, 12 do
		k.rect(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.9), 0.04, 0.012, ({rgb(255, 90, 140), rgb(255, 220, 60), rgb(90, 160, 255), W})[rng:NextInteger(1, 4)], {rot = rng:NextNumber(0, 180)})
	end
end
A["Marshmallow Mayhem"] = function(k, rng)
	-- a stampede of marshmallows charging over a campfire
	k.sky(rgb(40, 30, 80), rgb(255, 140, 90))
	k.stars(10, rng, 0.3)
	for i = 0, 4 do
		k.ellipse(0.5 + (i - 2) * 0.04, 0.85, 0.06, 0.16, i % 2 == 0 and rgb(255, 120, 30) or rgb(255, 210, 60))
	end
	for i = 0, 5 do
		local x, y = 0.1 + i * 0.16, 0.55 + (i % 2) * 0.1
		k.rect(x, y, 0.12, 0.1, W, {round = 0.4})
		P.eyes(k, x, y - 0.01, 0.02, 0.03)
	end
end
A["Sweet Tooth Twisted"] = function(k, rng)
	-- a giant molar with a sweet tooth, wrapped in licorice like a twisted villain
	k.sky(rgb(60, 20, 70), rgb(200, 60, 120))
	k.rect(0.5, 0.55, 0.36, 0.42, W, {round = 0.35})
	k.rect(0.42, 0.8, 0.08, 0.14, W, {round = 0.5})
	k.rect(0.58, 0.8, 0.08, 0.14, W, {round = 0.5})
	P.eyes(k, 0.5, 0.5, 0.05, 0.08)
	P.brows(k, 0.5, 0.44, 0.05, 0.08, 20)
	for i = 0, 3 do
		k.rect(0.5, 0.35 + i * 0.12, 0.5, 0.03, rgb(200, 20, 50), {rot = 20})
	end
end
A["Donut Countee"] = function(k, rng)
	-- a giant donut hole swallowing a whole town of sweets
	candyland(k, rng, rgb(150, 210, 255), rgb(240, 230, 255))
	k.circle(0.5, 0.6, 0.6, rgb(240, 170, 90))
	k.circle(0.5, 0.58, 0.54, PINK)
	k.circle(0.5, 0.6, 0.24, rgb(40, 20, 30))
	for _ = 1, 14 do
		k.rect(rng:NextNumber(0.25, 0.75), rng:NextNumber(0.4, 0.8), 0.04, 0.012, ({W, rgb(255, 220, 60), rgb(90, 160, 255)})[rng:NextInteger(1, 3)], {rot = rng:NextNumber(0, 180)})
	end
end

return A

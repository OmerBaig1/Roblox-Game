--[[
	Wild West posters (Dusty Saloon and Gold Rush Mine). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(30, 18, 10)
local GOLD, WOOD, DUST = rgb(255, 205, 60), rgb(140, 90, 50), rgb(235, 190, 130)

local function prairie(k, top, bottom)
	k.sky(top or rgb(255, 150, 80), bottom or rgb(255, 225, 160))
	k.circle(0.5, 0.62, 0.5, rgb(255, 230, 150), {t = 0.3})
	for i, x in ipairs({0.15, 0.85}) do
		k.rect(x, 0.66, 0.3, 0.22, rgb(200, 100, 60))
		k.rect(x, 0.54, 0.24, 0.04, rgb(170, 80, 50))
	end
	k.rect(0.5, 0.88, 1, 0.26, DUST)
end
local function cactus(k, x, groundY, s)
	local g = rgb(70, 150, 70)
	k.rect(x, groundY - 0.15 * s, 0.06 * s, 0.3 * s, g, {round = 0.5})
	k.rect(x - 0.05 * s, groundY - 0.18 * s, 0.03 * s, 0.1 * s, g, {round = 0.5})
	k.rect(x + 0.05 * s, groundY - 0.22 * s, 0.03 * s, 0.12 * s, g, {round = 0.5})
end
local function hat(k, x, y, s, color)
	k.ellipse(x, y, 0.22 * s, 0.05 * s, color or rgb(150, 100, 55))
	k.rect(x, y - 0.04 * s, 0.12 * s, 0.08 * s, color or rgb(150, 100, 55), {round = 0.3})
end
local function mine(k)
	k.sky(rgb(40, 28, 20), rgb(90, 60, 40))
	k.rect(0.5, 0.5, 0.8, 0.9, rgb(30, 20, 15), {round = 0.4})
	k.rect(0.1, 0.5, 0.06, 0.9, WOOD)
	k.rect(0.9, 0.5, 0.06, 0.9, WOOD)
	k.rect(0.5, 0.08, 0.9, 0.06, WOOD)
end

local A = {}

A["Red Dead Redemp-chin"] = function(k, rng)
	-- a cowboy with an enormous chin riding into a red sunset
	prairie(k, rgb(200, 40, 40), rgb(255, 170, 90))
	k.ellipse(0.45, 0.72, 0.4, 0.16, rgb(110, 60, 30))
	k.rect(0.62, 0.62, 0.08, 0.14, rgb(110, 60, 30), {rot = -20})
	P.person(k, 0.45, 0.55, 0.55, rgb(150, 30, 30), rgb(220, 170, 130), rgb(60, 50, 40))
	k.ellipse(0.47, 0.42, 0.1, 0.07, rgb(220, 170, 130))
	hat(k, 0.45, 0.31, 0.8)
end
A["Gun Slinger Slinky"] = function(k, rng)
	-- a slinky in a cowboy hat walking down the saloon steps, a toy pistol at its hip
	prairie(k)
	for i = 0, 3 do
		k.rect(0.5 - i * 0.05, 0.6 + i * 0.07, 0.4, 0.06, WOOD)
	end
	for i = 0, 8 do
		k.circle(0.38 + i * 0.03, 0.48 - math.sin(i / 8 * math.pi) * 0.12, 0.08, rgb(200, 200, 215), {t = 0.1})
	end
	hat(k, 0.38, 0.38, 0.6)
	k.rect(0.6, 0.52, 0.08, 0.03, rgb(60, 60, 70))
end
A["Oregon Trail Mix"] = function(k, rng)
	-- a covered wagon full of nuts and raisins rolling along the trail
	prairie(k, rgb(120, 180, 240), rgb(240, 220, 170))
	k.ellipse(0.5, 0.52, 0.42, 0.3, rgb(245, 240, 225))
	k.rect(0.5, 0.66, 0.46, 0.1, WOOD)
	for _, x in ipairs({0.33, 0.67}) do
		k.circle(x, 0.74, 0.14, rgb(90, 60, 30))
		k.circle(x, 0.74, 0.08, DUST)
	end
	for _ = 1, 10 do
		k.circle(rng:NextNumber(0.35, 0.65), rng:NextNumber(0.38, 0.55), 0.04, ({rgb(170, 110, 60), rgb(90, 40, 60), rgb(230, 200, 140)})[rng:NextInteger(1, 3)])
	end
end
A["Tumbleweed Tycoon"] = function(k, rng)
	-- a tumbleweed in a top hat counting a stack of cash
	prairie(k)
	cactus(k, 0.88, 0.86, 1.1)
	k.circle(0.45, 0.65, 0.4, rgb(180, 140, 80), {t = 0.2})
	for _ = 1, 10 do
		k.rect(0.45 + rng:NextNumber(-0.15, 0.15), 0.65 + rng:NextNumber(-0.15, 0.15), 0.12, 0.012, rgb(130, 90, 50), {rot = rng:NextNumber(0, 180)})
	end
	k.rect(0.45, 0.4, 0.12, 0.14, B)
	k.rect(0.45, 0.47, 0.2, 0.02, B)
	for i = 0, 3 do
		k.rect(0.78, 0.8 - i * 0.04, 0.16, 0.035, rgb(80, 170, 80))
	end
end
A["Wild Gun Fun"] = function(k, rng)
	-- two water-pistol duellists at high noon, a splash between them
	prairie(k, rgb(120, 190, 255), rgb(255, 230, 170))
	for _, s in ipairs({-1, 1}) do
		P.person(k, 0.5 + s * 0.3, 0.8, 0.6, s < 0 and rgb(60, 120, 230) or rgb(230, 60, 60), rgb(220, 170, 130), rgb(60, 50, 40))
		hat(k, 0.5 + s * 0.3, 0.48, 0.5)
	end
	k.circle(0.5, 0.6, 0.12, rgb(120, 210, 255), {t = 0.2})
	P.star(k, 0.5, 0.6, 0.08, W)
end
A["Saloon Showdown"] = function(k, rng)
	-- swinging saloon doors bursting open, a piano player diving for cover
	k.sky(rgb(80, 50, 30), rgb(160, 100, 60))
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.14, 0.55, 0.26, 0.4, WOOD, {rot = s * 15})
		for i = 0, 3 do
			k.rect(0.5 + s * 0.14, 0.42 + i * 0.08, 0.22, 0.015, rgb(100, 60, 30), {rot = s * 15})
		end
	end
	k.text(0.5, 0.15, 0.6, 0.14, "SALOON", GOLD, {stroke = true})
end
A["Gold Digger Deluxe"] = function(k, rng)
	-- a miner holding up a gold nugget the size of their head
	mine(k)
	P.person(k, 0.45, 0.82, 0.8, rgb(140, 70, 50), rgb(220, 175, 140), rgb(80, 70, 60))
	k.circle(0.62, 0.45, 0.2, GOLD)
	k.circle(0.58, 0.41, 0.06, rgb(255, 240, 170))
	P.star(k, 0.72, 0.36, 0.06, W)
end
A["Minecart Mania"] = function(k, rng)
	-- a minecart flying off the rails over a chasm, sparks everywhere
	mine(k)
	k.rect(0.3, 0.7, 0.5, 0.025, rgb(150, 150, 160), {rot = -15})
	k.rect(0.62, 0.45, 0.3, 0.16, rgb(120, 80, 50), {rot = -15})
	for _, x in ipairs({0.54, 0.7}) do
		k.circle(x, 0.55, 0.06, rgb(50, 50, 55))
	end
	for _ = 1, 8 do
		k.circle(rng:NextNumber(0.3, 0.55), rng:NextNumber(0.55, 0.75), 0.015, rgb(255, 200, 80))
	end
end
A["Dig Dug Deeper"] = function(k, rng)
	-- a cutaway of tunnels with a tiny digger, a dragon hiding deep down
	k.sky(rgb(130, 200, 255), rgb(130, 200, 255))
	for i = 0, 3 do
		k.rect(0.5, 0.3 + i * 0.18, 1, 0.18, ({rgb(200, 150, 90), rgb(170, 110, 60), rgb(140, 80, 45), rgb(110, 60, 35)})[i + 1])
	end
	k.rect(0.4, 0.45, 0.5, 0.06, rgb(30, 20, 15))
	k.rect(0.62, 0.65, 0.06, 0.4, rgb(30, 20, 15))
	P.person(k, 0.25, 0.47, 0.35, W, rgb(255, 210, 170), rgb(60, 120, 230))
	k.circle(0.7, 0.84, 0.12, rgb(80, 200, 90))
	P.eyes(k, 0.72, 0.83, 0.025, 0.035)
end
A["Deep Rock Garlic"] = function(k, rng)
	-- dwarves in a cave mining a giant glowing garlic bulb
	mine(k)
	k.circle(0.5, 0.55, 0.32, rgb(250, 245, 230))
	for i = -1, 1 do
		k.ellipse(0.5 + i * 0.08, 0.55, 0.12, 0.3, rgb(235, 225, 205))
	end
	k.rect(0.5, 0.35, 0.03, 0.08, rgb(160, 200, 120))
	for _, x in ipairs({0.2, 0.8}) do
		P.person(k, x, 0.84, 0.45, rgb(230, 140, 40), rgb(220, 175, 140), rgb(60, 60, 80))
	end
end
A["Steamworld Digg"] = function(k, rng)
	-- a steam-powered robot cowboy drilling down, steam puffing from its hat
	mine(k)
	k.rect(0.5, 0.55, 0.22, 0.26, rgb(190, 140, 60), {round = 0.2})
	k.circle(0.5, 0.38, 0.16, rgb(200, 150, 70))
	k.rect(0.47, 0.37, 0.05, 0.03, rgb(255, 80, 40))
	k.rect(0.54, 0.37, 0.05, 0.03, rgb(255, 80, 40))
	hat(k, 0.5, 0.29, 0.7, rgb(100, 60, 40))
	k.rect(0.5, 0.78, 0.08, 0.16, rgb(160, 160, 170))
	for i = 0, 2 do
		k.circle(0.6 + i * 0.05, 0.2 - i * 0.04, 0.06 + i * 0.02, W, {t = 0.4})
	end
end
A["Prospector's Paradise"] = function(k, rng)
	-- a prospector's pan heaped with gold, a river glittering behind
	prairie(k, rgb(120, 190, 240), rgb(240, 230, 190))
	k.waves(0.78, rgb(80, 170, 220), 0.12)
	k.ellipse(0.5, 0.62, 0.5, 0.18, rgb(110, 110, 120))
	k.ellipse(0.5, 0.6, 0.42, 0.13, rgb(80, 80, 90))
	for _ = 1, 9 do
		k.circle(rng:NextNumber(0.35, 0.65), rng:NextNumber(0.55, 0.64), rng:NextNumber(0.03, 0.06), GOLD)
	end
	P.star(k, 0.68, 0.5, 0.06, W)
end

return A

--[[
	Crystal Caverns posters (Geode Gallery and Prism Throne). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(15, 10, 25)
local AMETHYST, CYANG, PINKG, CAVE = rgb(180, 90, 255), rgb(90, 230, 255), rgb(255, 120, 220), rgb(50, 40, 70)

local function cavern(k, rng)
	k.sky(rgb(30, 20, 50), CAVE)
	for i = 0, 6 do
		k.rect(0.05 + i * 0.16, 0.05, 0.08, 0.2 + (i % 3) * 0.06, rgb(70, 60, 90), {rot = 45})
	end
	k.rect(0.5, 0.93, 1, 0.14, rgb(60, 50, 80))
end
local function crystal(k, x, groundY, s, color, rot)
	k.rect(x, groundY - 0.14 * s, 0.07 * s, 0.28 * s, color, {rot = rot or 0, t = 0.1})
	k.rect(x, groundY - 0.28 * s, 0.05 * s, 0.05 * s, color:Lerp(W, 0.4), {rot = 45 + (rot or 0)})
end
local function sparkle(k, rng, n)
	for _ = 1, n do
		P.star(k, rng:NextNumber(0.05, 0.95), rng:NextNumber(0.1, 0.85), rng:NextNumber(0.03, 0.06), W)
	end
end

local A = {}

A["Crystal Clash"] = function(k, rng)
	-- two crystal golems colliding, shards flying
	cavern(k, rng)
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.2, 0.6, 0.22, 0.36, s < 0 and AMETHYST or CYANG, {rot = s * 10, t = 0.1})
		k.rect(0.5 + s * 0.2, 0.36, 0.14, 0.14, s < 0 and AMETHYST or CYANG, {rot = 45})
	end
	sparkle(k, rng, 6)
end
A["Gem Miner Gem"] = function(k, rng)
	-- a miner with a pickaxe that's itself made of gems
	cavern(k, rng)
	P.person(k, 0.42, 0.85, 0.75, rgb(240, 180, 40), rgb(230, 190, 160), rgb(80, 70, 110))
	k.rect(0.62, 0.5, 0.02, 0.3, rgb(120, 90, 60), {rot = 30})
	k.rect(0.68, 0.38, 0.22, 0.05, PINKG, {rot = 30})
	crystal(k, 0.85, 0.9, 1, CYANG)
end
A["Spelunky Spunk"] = function(k, rng)
	-- an explorer dangling from a rope into a glittering cave
	cavern(k, rng)
	k.rect(0.5, 0.25, 0.01, 0.5, rgb(200, 170, 120))
	P.person(k, 0.5, 0.62, 0.55, rgb(200, 50, 50), rgb(230, 190, 160), rgb(80, 60, 40))
	for i = 0, 4 do
		crystal(k, 0.1 + i * 0.2, 0.93, 0.7 + (i % 2) * 0.3, ({AMETHYST, CYANG, PINKG})[i % 3 + 1], (i - 2) * 10)
	end
end
A["Mole Mania"] = function(k, rng)
	-- a mole in tiny glasses surrounded by dozens of mole holes
	cavern(k, rng)
	for i = 0, 5 do
		k.ellipse(0.15 + (i % 3) * 0.35, 0.6 + math.floor(i / 3) * 0.2, 0.18, 0.06, B)
	end
	k.circle(0.5, 0.45, 0.3, rgb(110, 85, 75))
	k.circle(0.5, 0.52, 0.08, rgb(255, 150, 170))
	for _, x in ipairs({0.44, 0.56}) do
		k.circle(x, 0.42, 0.06, rgb(40, 40, 50), {t = 0.2})
	end
end
A["Geode Golf"] = function(k, rng)
	-- a golf ball resting on the lip of a split geode, the hole glowing inside
	cavern(k, rng)
	k.circle(0.5, 0.6, 0.6, rgb(120, 110, 130))
	k.circle(0.5, 0.6, 0.48, AMETHYST)
	for i = 0, 7 do
		k.rect(0.5, 0.6, 0.06, 0.4, PINKG:Lerp(AMETHYST, i % 2), {rot = i * 22.5})
	end
	k.circle(0.5, 0.6, 0.1, B)
	k.circle(0.72, 0.32, 0.07, W)
	P.flag(k, 0.5, 0.42, 0.5)
end
A["Diamond Dash Deluxe"] = function(k, rng)
	-- a diamond with legs sprinting out of a mine, a trail of sparkles behind
	cavern(k, rng)
	k.rect(0.55, 0.5, 0.26, 0.26, CYANG, {rot = 45})
	k.rect(0.55, 0.42, 0.26, 0.04, W, {t = 0.4})
	P.eyes(k, 0.55, 0.5, 0.03, 0.05)
	for _, x in ipairs({0.5, 0.6}) do
		k.rect(x, 0.72, 0.025, 0.12, B, {rot = (x - 0.55) * 300})
	end
	sparkle(k, rng, 5)
end
A["Prismatic Palace"] = function(k, rng)
	-- a palace of prisms splitting light into rainbows
	k.sky(rgb(240, 230, 255), rgb(200, 220, 255))
	for i, c in ipairs({rgb(255, 80, 90), rgb(255, 170, 60), rgb(255, 230, 70), rgb(90, 220, 120), rgb(80, 160, 255), rgb(170, 100, 255)}) do
		k.rect(0.5, 0.15 + i * 0.04, 1.2, 0.04, c, {rot = -15, t = 0.4})
	end
	for i = -2, 2 do
		k.rect(0.5 + i * 0.15, 0.7 - math.abs(i) * -0.04, 0.12, 0.4 - math.abs(i) * 0.08, W, {t = 0.2})
		k.rect(0.5 + i * 0.15, 0.48 + math.abs(i) * 0.04, 0.09, 0.09, PINKG, {rot = 45})
	end
end
A["Hollow Knite"] = function(k, rng)
	-- a tiny masked knight with a needle-sword in a vast blue cave
	k.sky(rgb(20, 30, 60), rgb(50, 80, 120))
	for _ = 1, 10 do
		k.circle(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.1, 0.8), rng:NextNumber(0.01, 0.03), CYANG, {t = 0.3})
	end
	k.ellipse(0.5, 0.75, 0.16, 0.22, rgb(30, 30, 45))
	k.circle(0.5, 0.5, 0.18, W)
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.06, 0.38, 0.03, 0.12, W, {rot = s * 15})
		k.ellipse(0.5 + s * 0.04, 0.52, 0.035, 0.06, B)
	end
	k.rect(0.66, 0.72, 0.18, 0.012, rgb(220, 225, 235), {rot = -20})
end
A["Ori and the Bland Forest"] = function(k, rng)
	-- a glowing spirit in a forest of plain grey trees, the only colour around
	k.sky(rgb(150, 150, 160), rgb(110, 110, 120))
	for i = 0, 5 do
		P.tree(k, 0.08 + i * 0.17, 0.95, 0.8, rgb(140, 140, 145))
	end
	k.circle(0.5, 0.5, 0.3, CYANG, {t = 0.6})
	k.circle(0.5, 0.5, 0.12, W)
	P.eyes(k, 0.5, 0.49, 0.015, 0.025)
end
A["Crystal Chronicles"] = function(k, rng)
	-- a caravan escorting a giant glowing crystal chalice
	k.sky(rgb(90, 60, 140), rgb(230, 170, 220))
	k.rect(0.5, 0.88, 1, 0.2, rgb(110, 90, 80))
	k.rect(0.5, 0.62, 0.06, 0.24, rgb(200, 170, 90))
	k.rect(0.5, 0.35, 0.28, 0.2, CYANG, {rot = 45, t = 0.1})
	k.circle(0.5, 0.35, 0.3, W, {t = 0.8})
	for _, x in ipairs({0.2, 0.8}) do
		P.person(k, x, 0.84, 0.5, rgb(80, 120, 200), rgb(230, 190, 160), rgb(90, 60, 40))
	end
end
A["Monument Valet"] = function(k, rng)
	-- a valet parking a car on an impossible staircase that loops back on itself
	k.sky(rgb(255, 200, 190), rgb(200, 180, 255))
	for i = 0, 4 do
		k.rect(0.3 + i * 0.1, 0.8 - i * 0.1, 0.12, 0.06, rgb(240, 170, 180))
		k.rect(0.7 - i * 0.1, 0.4 - i * 0.06, 0.1, 0.05, rgb(180, 160, 230))
	end
	k.rect(0.75, 0.6, 0.12, 0.4, rgb(220, 200, 250))
	P.kart(k, 0.5, 0.52, 0.6, rgb(255, 120, 120))
	P.person(k, 0.25, 0.75, 0.35, W, rgb(230, 190, 160), B)
end
A["Kaleidoscope Kingdom"] = function(k, rng)
	-- a crown at the centre of a spinning kaleidoscope of crystals
	k.sky(rgb(40, 20, 80), rgb(120, 40, 140))
	for i = 0, 11 do
		k.rect(0.5, 0.48, 0.08, 0.7, ({AMETHYST, CYANG, PINKG, rgb(255, 220, 90)})[i % 4 + 1], {rot = i * 15, t = 0.35})
	end
	k.circle(0.5, 0.48, 0.24, rgb(255, 230, 120))
	for i = -2, 2 do
		k.rect(0.5 + i * 0.04, 0.42, 0.03, 0.08, rgb(255, 200, 40))
	end
	k.rect(0.5, 0.49, 0.2, 0.05, rgb(255, 200, 40))
end

return A

--[[
	Desert Pyramids posters (Oasis Bazaar and Tomb of Ra). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(20, 15, 10)
local GOLD, LAPIS, SAND, STONE = rgb(255, 205, 60), rgb(40, 70, 180), rgb(240, 205, 140), rgb(215, 180, 120)

local function desert(k, top, bottom)
	k.sky(top or rgb(255, 170, 90), bottom or rgb(255, 230, 170))
	k.circle(0.78, 0.22, 0.2, rgb(255, 240, 180))
	k.waves(0.8, SAND, 0.4)
end
local function pyramid(k, x, baseY, s, color)
	for i = 0, 5 do
		k.rect(x, baseY - i * 0.06 * s, (0.6 - i * 0.1) * s, 0.065 * s, (color or STONE):Lerp(B, i % 2 * 0.08))
	end
end
local function palm(k, x, groundY, s)
	k.rect(x, groundY - 0.17 * s, 0.025 * s, 0.34 * s, rgb(130, 90, 50), {rot = 6})
	for _, a in ipairs({-35, -10, 15, 40, 170}) do
		k.ellipse(x + math.cos(math.rad(a)) * 0.06 * s, groundY - 0.34 * s + math.sin(math.rad(a)) * 0.04 * s, 0.15 * s, 0.045 * s, rgb(60, 160, 70), {rot = a})
	end
end
local function eyeOfRa(k, x, y, s, color)
	k.ellipse(x, y, 0.22 * s, 0.1 * s, color or LAPIS)
	k.ellipse(x, y, 0.16 * s, 0.07 * s, W)
	k.circle(x, y, 0.06 * s, color or LAPIS)
	k.rect(x + 0.02 * s, y + 0.08 * s, 0.02 * s, 0.1 * s, color or LAPIS, {rot = -20})
end

local A = {}

-- Prince of Pursia: a prince leaping between rooftops with a stolen purse, a palace dome behind
A["Prince of Pursia"] = function(k, rng)
	desert(k, rgb(120, 60, 140), rgb(255, 150, 90))
	k.circle(0.7, 0.45, 0.35, rgb(240, 220, 160))
	k.rect(0.7, 0.75, 0.4, 0.4, rgb(230, 200, 140))
	k.rect(0.7, 0.24, 0.02, 0.1, GOLD)
	for _, x in ipairs({0.1, 0.3}) do
		k.rect(x, 0.8, 0.18, 0.4, rgb(200, 160, 110))
	end
	P.person(k, 0.42, 0.42, 0.55, rgb(80, 40, 160), rgb(210, 160, 120), rgb(230, 230, 230))
	k.circle(0.5, 0.36, 0.06, rgb(170, 60, 90))
	k.text(0.5, 0.36, 0.05, 0.05, "$", GOLD)
end
-- Tomb Rater: an explorer with a torch reviewing treasures in a tomb, a five-star rating card above
A["Tomb Rater"] = function(k, rng)
	k.sky(rgb(60, 40, 30), rgb(120, 80, 50))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.5, 0.18, 0.9, rgb(150, 110, 70):Lerp(B, (i % 2) * 0.15))
	end
	P.person(k, 0.35, 0.78, 0.7, rgb(60, 140, 120), rgb(220, 170, 130), rgb(90, 70, 50))
	k.circle(0.26, 0.5, 0.06, rgb(255, 170, 40))
	k.rect(0.68, 0.3, 0.38, 0.14, W, {round = 0.2})
	k.text(0.68, 0.3, 0.34, 0.1, "\u{2B50}\u{2B50}\u{2B50}\u{2B50}\u{2B50}", GOLD)
	k.rect(0.72, 0.75, 0.18, 0.14, GOLD, {round = 0.1})
end
-- Camel Kart: a camel in a go-kart racing past pyramids
A["Camel Kart"] = function(k, rng)
	desert(k)
	pyramid(k, 0.25, 0.75, 0.8)
	pyramid(k, 0.8, 0.72, 0.6)
	P.kart(k, 0.5, 0.72, 1.3, rgb(220, 60, 60))
	k.ellipse(0.5, 0.5, 0.2, 0.1, rgb(210, 160, 90))
	k.circle(0.47, 0.44, 0.07, rgb(200, 150, 80))
	k.rect(0.6, 0.42, 0.04, 0.14, rgb(210, 160, 90), {rot = -15})
	k.circle(0.62, 0.34, 0.06, rgb(210, 160, 90))
	k.circle(0.64, 0.33, 0.012, B)
end
-- Desert Strife: two tanks squaring off in a sandstorm
A["Desert Strife"] = function(k, rng)
	desert(k, rgb(230, 140, 70), rgb(250, 210, 150))
	for _, s in ipairs({-1, 1}) do
		local x = 0.5 + s * 0.25
		k.rect(x, 0.72, 0.28, 0.1, rgb(140, 120, 70), {round = 0.3})
		k.rect(x, 0.64, 0.16, 0.08, rgb(160, 140, 80), {round = 0.2})
		k.rect(x - s * 0.13, 0.62, 0.16, 0.025, rgb(110, 95, 60))
	end
	for _ = 1, 25 do
		k.rect(rng:NextNumber(0, 1), rng:NextNumber(0.1, 0.9), rng:NextNumber(0.05, 0.15), 0.008, W, {t = 0.5})
	end
	P.star(k, 0.5, 0.6, 0.12, rgb(255, 200, 60))
end
-- Oasis Odyssey: a caravan winding towards a lush oasis under the moon
A["Oasis Odyssey"] = function(k, rng)
	desert(k, rgb(40, 40, 110), rgb(230, 130, 110))
	k.stars(14, rng, 0.4)
	P.moon(k, 0.2, 0.18, 0.12, rgb(40, 40, 110))
	k.ellipse(0.65, 0.78, 0.4, 0.08, rgb(80, 180, 220))
	palm(k, 0.52, 0.78, 0.9)
	palm(k, 0.8, 0.78, 1.1)
	for i = 0, 3 do
		k.ellipse(0.12 + i * 0.08, 0.72, 0.06, 0.04, rgb(60, 40, 30))
		k.rect(0.12 + i * 0.08, 0.76, 0.01, 0.04, rgb(60, 40, 30))
	end
end
-- Assassin's Greed: Oranges: a hooded figure on an obelisk juggling oranges
A["Assassin's Greed: Oranges"] = function(k, rng)
	desert(k)
	k.rect(0.5, 0.6, 0.12, 0.7, STONE)
	k.rect(0.5, 0.22, 0.12, 0.06, GOLD, {rot = 45})
	P.person(k, 0.5, 0.2, 0.45, rgb(240, 240, 240), rgb(210, 160, 120), rgb(230, 230, 230))
	for i = 0, 4 do
		local a = i / 5 * math.pi
		k.circle(0.5 + math.cos(a) * 0.2, 0.12 - math.sin(a) * 0.06 + 0.06, 0.05, rgb(255, 150, 30))
	end
end
-- The Mummy's Cursor: a mummy hand reaching out of a sarcophagus for a giant mouse cursor
A["The Mummy's Cursor"] = function(k, rng)
	k.sky(rgb(40, 30, 50), rgb(90, 70, 60))
	k.rect(0.45, 0.7, 0.34, 0.5, GOLD, {round = 0.3})
	k.rect(0.45, 0.7, 0.26, 0.42, LAPIS, {round = 0.3})
	eyeOfRa(k, 0.45, 0.62, 0.8, GOLD)
	k.rect(0.62, 0.42, 0.06, 0.3, rgb(225, 215, 185), {rot = 30})
	for i = 0, 2 do
		k.rect(0.62, 0.36 + i * 0.07, 0.07, 0.015, rgb(190, 180, 150), {rot = 30})
	end
	k.rect(0.8, 0.2, 0.08, 0.14, W, {rot = -25})
	k.rect(0.8, 0.2, 0.06, 0.11, B, {rot = -25, t = 0.85})
end
-- Pharaoh Phone: a golden smartphone shaped like a sarcophagus, hieroglyph apps on the screen
A["Pharaoh Phone"] = function(k, rng)
	k.sky(rgb(255, 210, 120), rgb(190, 120, 60))
	k.rect(0.5, 0.52, 0.42, 0.78, GOLD, {round = 0.15})
	k.rect(0.5, 0.52, 0.34, 0.64, rgb(30, 40, 90), {round = 0.1})
	local glyphs = {"\u{1F441}", "\u{1F40D}", "\u{1F985}", "\u{2625}", "\u{1F33E}", "\u{2600}"}
	for i = 0, 5 do
		k.rect(0.41 + (i % 3) * 0.09, 0.38 + math.floor(i / 3) * 0.14, 0.07, 0.1, ({LAPIS, rgb(220, 90, 40), rgb(40, 170, 160)})[i % 3 + 1], {round = 0.3})
		k.text(0.41 + (i % 3) * 0.09, 0.38 + math.floor(i / 3) * 0.14, 0.06, 0.08, glyphs[i + 1], W)
	end
end
-- Pyramid Head Start: a runner bursting out of the blocks at the foot of a pyramid
A["Pyramid Head Start"] = function(k, rng)
	desert(k)
	pyramid(k, 0.55, 0.78, 1.5)
	k.rect(0.5, 0.85, 1, 0.04, W)
	P.person(k, 0.3, 0.82, 0.7, rgb(230, 60, 60), rgb(200, 150, 110), rgb(40, 40, 60))
	for i = 0, 2 do
		k.rect(0.12, 0.62 + i * 0.05, 0.12, 0.012, W, {t = 0.3})
	end
	k.text(0.75, 0.2, 0.3, 0.12, "GO!", rgb(230, 40, 40), {stroke = true})
end
-- Age of Mythologee: gods of the sun, sky and sea looming over a tiny city
A["Age of Mythologee"] = function(k, rng)
	k.sky(rgb(255, 150, 70), rgb(120, 160, 230))
	for i, c in ipairs({rgb(255, 180, 60), rgb(130, 180, 255), rgb(60, 170, 180)}) do
		local x = 0.2 + (i - 1) * 0.3
		k.circle(x, 0.35, 0.22, c, {t = 0.25})
		P.eyes(k, x, 0.35, 0.06, 0.08)
	end
	for i = 0, 6 do
		k.rect(0.1 + i * 0.13, 0.85, 0.1, 0.1 + (i % 3) * 0.05, STONE)
	end
end
-- Scarab Smash: a giant golden scarab beetle rolling a sun across the desert
A["Scarab Smash"] = function(k, rng)
	desert(k, rgb(255, 140, 60), rgb(255, 220, 160))
	k.circle(0.32, 0.58, 0.36, rgb(255, 120, 40))
	k.ellipse(0.66, 0.66, 0.3, 0.22, rgb(30, 120, 110))
	k.rect(0.66, 0.66, 0.01, 0.22, rgb(10, 60, 55))
	k.ellipse(0.8, 0.62, 0.1, 0.08, rgb(20, 90, 85))
	for i = -1, 1 do
		k.rect(0.6 + i * 0.07, 0.8, 0.012, 0.08, B, {rot = i * 20})
	end
	k.rect(0.66, 0.56, 0.2, 0.03, GOLD)
end
-- Sunsinger of Ra: a falcon-headed singer with a sun disc for a halo, notes rising into the sky
A["Sunsinger of Ra"] = function(k, rng)
	k.sky(rgb(255, 120, 60), rgb(255, 210, 120))
	k.circle(0.5, 0.3, 0.38, rgb(255, 80, 30))
	k.circle(0.5, 0.3, 0.28, rgb(255, 160, 50))
	k.rect(0.5, 0.75, 0.2, 0.36, LAPIS, {round = 0.3})
	k.circle(0.5, 0.45, 0.14, rgb(150, 110, 70))
	k.rect(0.56, 0.48, 0.06, 0.03, GOLD, {rot = 20})
	for i = 0, 3 do
		k.text(0.2 + i * 0.2, 0.15 + (i % 2) * 0.08, 0.08, 0.1, "\u{266A}", W)
	end
end

return A

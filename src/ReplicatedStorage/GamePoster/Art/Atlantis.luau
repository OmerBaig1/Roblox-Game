--[[
	Sunken Atlantis posters (Coral Reef Arcade and Poseidon's Throne Room). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(15, 15, 25)
local GOLD, SEA, DEEP, SAND = rgb(255, 205, 60), rgb(40, 150, 200), rgb(10, 50, 110), rgb(235, 215, 160)

-- underwater: deep blue fading down, light rays from the surface, a sandy floor and bubbles
local function underwater(k, rng, top, bottom)
	k.sky(top or rgb(70, 190, 230), bottom or DEEP)
	for i = 0, 3 do
		k.rect(0.15 + i * 0.25, 0.25, 0.08, 0.7, W, {rot = 15, t = 0.85})
	end
	k.waves(0.88, SAND, 0.18)
	for _ = 1, 7 do
		k.circle(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.1, 0.8), rng:NextNumber(0.015, 0.04), W, {t = 0.5})
	end
end
local function fish(k, x, y, s, color, flip)
	local d = flip and -1 or 1
	k.ellipse(x, y, 0.16 * s, 0.1 * s, color)
	k.rect(x - d * 0.09 * s, y, 0.06 * s, 0.09 * s, color, {rot = 45})
	k.circle(x + d * 0.045 * s, y - 0.015 * s, 0.025 * s, W)
	k.circle(x + d * 0.05 * s, y - 0.015 * s, 0.012 * s, B)
end
local function coral(k, x, groundY, s, color)
	for i = -1, 1 do
		k.rect(x + i * 0.04 * s, groundY - 0.1 * s, 0.03 * s, 0.22 * s, color, {rot = i * 20, round = 0.5})
		k.circle(x + i * 0.06 * s, groundY - 0.21 * s, 0.05 * s, color)
	end
end
local function trident(k, x, y, s)
	k.rect(x, y + 0.15 * s, 0.025 * s, 0.6 * s, GOLD)
	k.rect(x, y - 0.13 * s, 0.16 * s, 0.025 * s, GOLD)
	for i = -1, 1 do
		k.rect(x + i * 0.065 * s, y - 0.2 * s, 0.022 * s, 0.14 * s, GOLD)
	end
end
local function columns(k, color)
	for _, x in ipairs({0.08, 0.92}) do
		k.rect(x, 0.55, 0.1, 0.9, color or rgb(235, 240, 245))
		k.rect(x, 0.12, 0.14, 0.04, color or rgb(235, 240, 245))
		for i = -1, 1 do
			k.rect(x + i * 0.028, 0.55, 0.01, 0.85, rgb(200, 210, 220))
		end
	end
end

local A = {}

-- Finding Nemoji: a clownfish with a big emoji grin peeking out of a sea anemone
A["Finding Nemoji"] = function(k, rng)
	underwater(k, rng)
	coral(k, 0.3, 0.9, 1.4, rgb(255, 120, 160))
	coral(k, 0.75, 0.9, 1.1, rgb(200, 90, 230))
	fish(k, 0.52, 0.48, 2.2, rgb(255, 130, 40))
	for _, x in ipairs({0.46, 0.56}) do
		k.rect(x, 0.48, 0.025, 0.2, W)
	end
	P.smile(k, 0.6, 0.53, 0.08, B)
	k.text(0.75, 0.22, 0.25, 0.14, "\u{1F600}", W)
end
-- Subway Sharks: a shark in a cap surfing along a sunken subway track
A["Subway Sharks"] = function(k, rng)
	underwater(k, rng, rgb(60, 170, 220), rgb(20, 60, 120))
	for i = 0, 5 do
		k.rect(0.1 + i * 0.16, 0.86, 0.03, 0.06, rgb(120, 90, 60))
	end
	k.rect(0.5, 0.83, 1, 0.02, rgb(160, 160, 170))
	k.rect(0.5, 0.88, 1, 0.02, rgb(160, 160, 170))
	k.ellipse(0.5, 0.55, 0.5, 0.2, rgb(130, 150, 170))
	k.rect(0.5, 0.42, 0.07, 0.14, rgb(130, 150, 170), {rot = 20})
	k.ellipse(0.5, 0.6, 0.38, 0.08, rgb(235, 240, 245))
	k.rect(0.32, 0.6, 0.1, 0.02, B)
	k.rect(0.62, 0.45, 0.14, 0.05, rgb(230, 40, 50), {round = 0.4})
	k.circle(0.66, 0.53, 0.03, B)
end
-- Bioshark Infinite: a shark in a brass diving helmet in front of a glowing underwater city
A["Bioshark Infinite"] = function(k, rng)
	underwater(k, rng, rgb(30, 90, 120), rgb(5, 20, 45))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.62 - (i % 2) * 0.1, 0.1, 0.5 + (i % 2) * 0.2, rgb(40, 70, 90))
		k.rect(0.1 + i * 0.2, 0.5, 0.04, 0.04, rgb(255, 220, 120))
	end
	k.ellipse(0.5, 0.58, 0.48, 0.18, rgb(110, 125, 140))
	k.circle(0.62, 0.52, 0.2, rgb(200, 150, 60))
	k.circle(0.62, 0.52, 0.13, rgb(120, 200, 220), {t = 0.2})
	k.circle(0.64, 0.52, 0.03, rgb(255, 80, 60))
end
-- Abzoo: a diver gliding with a whale shark, a zoo sign on its tail
A["Abzoo"] = function(k, rng)
	underwater(k, rng, rgb(90, 210, 220), rgb(20, 80, 140))
	k.ellipse(0.48, 0.45, 0.7, 0.24, rgb(60, 90, 140))
	for _ = 1, 14 do
		k.circle(rng:NextNumber(0.2, 0.75), rng:NextNumber(0.38, 0.52), 0.015, W, {t = 0.2})
	end
	k.rect(0.86, 0.45, 0.1, 0.2, rgb(60, 90, 140), {rot = 30})
	k.rect(0.75, 0.38, 0.12, 0.06, GOLD)
	k.text(0.75, 0.38, 0.11, 0.05, "ZOO", B)
	P.person(k, 0.3, 0.7, 0.6, rgb(240, 120, 40), rgb(255, 210, 170), rgb(40, 40, 60))
end
-- Ecco the Dolphone: a dolphin leaping out of the sea, a smartphone held in its fin
A["Ecco the Dolphone"] = function(k, rng)
	k.sky(rgb(255, 180, 120), rgb(120, 190, 240))
	k.waves(0.72, SEA, 0.16)
	k.ellipse(0.48, 0.42, 0.48, 0.18, rgb(120, 160, 210), {rot = -25})
	k.rect(0.28, 0.58, 0.12, 0.06, rgb(120, 160, 210), {rot = 30})
	k.circle(0.62, 0.32, 0.03, B)
	k.rect(0.55, 0.52, 0.08, 0.13, B, {round = 0.2})
	k.rect(0.55, 0.52, 0.06, 0.1, rgb(120, 230, 255))
	k.text(0.5, 0.15, 0.3, 0.12, "\u{1F4F6}", W)
end
-- Feeding Frenzy Fries: a school of fish swarming a giant carton of fries
A["Feeding Frenzy Fries"] = function(k, rng)
	underwater(k, rng)
	k.rect(0.5, 0.66, 0.3, 0.3, rgb(220, 30, 40), {round = 0.1})
	for i = -3, 3 do
		k.rect(0.5 + i * 0.04, 0.45, 0.03, 0.2, rgb(255, 210, 60), {rot = i * 4})
	end
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		fish(k, 0.5 + math.cos(a) * 0.32, 0.5 + math.sin(a) * 0.25, 0.7, ({rgb(255, 200, 60), rgb(80, 220, 120), rgb(255, 120, 160)})[i % 3 + 1], math.cos(a) > 0)
	end
end
-- God of Water: the sea god rising from a whirlpool, trident raised
A["God of Water"] = function(k, rng)
	k.sky(rgb(30, 60, 120), rgb(70, 180, 220))
	for i = 0, 4 do
		k.ellipse(0.5, 0.82, 0.9 - i * 0.16, 0.18 - i * 0.03, i % 2 == 0 and rgb(40, 140, 200) or rgb(140, 220, 240))
	end
	k.rect(0.5, 0.55, 0.22, 0.3, rgb(240, 200, 170), {round = 0.3})
	k.circle(0.5, 0.32, 0.16, rgb(240, 200, 170))
	k.rect(0.5, 0.44, 0.18, 0.14, rgb(40, 80, 190), {round = 0.4})
	for i = -2, 2 do
		k.rect(0.5 + i * 0.03, 0.2, 0.02, 0.06, GOLD)
	end
	trident(k, 0.75, 0.3, 1)
	P.lightning(k, 0.2, 0.2, 0.8, rgb(255, 240, 150))
end
-- Trident Turismo: a racing car shaped like a trident speeding across the waves
A["Trident Turismo"] = function(k, rng)
	k.sky(rgb(255, 220, 140), rgb(90, 190, 240))
	k.waves(0.7, SEA, 0.15)
	P.kart(k, 0.45, 0.6, 1.4, rgb(40, 160, 170))
	trident(k, 0.45, 0.32, 0.6)
	for i = 0, 3 do
		k.rect(0.12, 0.55 + i * 0.04, 0.16 - i * 0.03, 0.015, W, {t = 0.3})
	end
	P.flag(k, 0.85, 0.35, 0.7)
end
-- Kraken Krossing: a frog-like boat hopping across the arms of a giant kraken
A["Kraken Krossing"] = function(k, rng)
	k.sky(rgb(80, 60, 120), rgb(30, 90, 140))
	k.waves(0.78, rgb(20, 70, 110), 0.14)
	for i = 0, 3 do
		k.rect(0.15 + i * 0.23, 0.7, 0.06, 0.34, rgb(170, 60, 120), {rot = (i - 1.5) * 18, round = 0.5})
		for j = 0, 2 do
			k.circle(0.15 + i * 0.23, 0.62 + j * 0.06, 0.02, rgb(240, 170, 200))
		end
	end
	P.eyes(k, 0.5, 0.25, 0.08, 0.12)
	k.ellipse(0.38, 0.5, 0.14, 0.06, rgb(140, 90, 50))
	k.rect(0.38, 0.44, 0.01, 0.1, rgb(240, 240, 230))
end
-- Assassin's Greed: Odd-yssey: a hooded hero leaping from a Greek temple with a bag of coins
A["Assassin's Greed: Odd-yssey"] = function(k, rng)
	k.sky(rgb(255, 200, 120), rgb(90, 170, 230))
	k.rect(0.5, 0.75, 0.7, 0.3, rgb(240, 235, 225))
	for i = 0, 5 do
		k.rect(0.2 + i * 0.12, 0.72, 0.05, 0.26, rgb(225, 220, 210))
	end
	k.rect(0.5, 0.56, 0.78, 0.06, rgb(225, 220, 210))
	k.rect(0.5, 0.18, 0.12, 0.2, rgb(230, 230, 235), {rot = -20, round = 0.3})
	k.ellipse(0.5, 0.1, 0.1, 0.08, rgb(200, 30, 40))
	k.circle(0.62, 0.26, 0.08, rgb(170, 130, 70))
	k.text(0.62, 0.26, 0.06, 0.06, "$", GOLD)
end
-- Tide Hunter Online: a party of heroes on a beach, a monstrous wave rising behind them
A["Tide Hunter Online"] = function(k, rng)
	k.sky(rgb(130, 200, 240), rgb(230, 240, 250))
	k.ellipse(0.5, 0.5, 1.4, 0.9, rgb(40, 130, 190))
	k.ellipse(0.5, 0.25, 1.2, 0.3, rgb(220, 245, 255))
	k.rect(0.5, 0.88, 1, 0.24, SAND)
	for i = 0, 2 do
		P.person(k, 0.3 + i * 0.2, 0.84, 0.5, ({rgb(220, 50, 50), rgb(50, 120, 230), rgb(60, 180, 90)})[i + 1], rgb(255, 210, 170), rgb(50, 40, 40))
	end
end
-- Tsunami Dash: a runner sprinting along a pier as a huge wave curls over him
A["Tsunami Dash"] = function(k, rng)
	k.sky(rgb(90, 160, 220), rgb(200, 230, 250))
	k.circle(0.25, 0.35, 1.0, rgb(30, 110, 180))
	k.circle(0.25, 0.35, 0.7, rgb(90, 190, 230))
	k.circle(0.32, 0.33, 0.45, rgb(200, 240, 255))
	k.rect(0.6, 0.86, 0.9, 0.06, rgb(150, 110, 70))
	P.person(k, 0.72, 0.8, 0.6, rgb(255, 210, 40), rgb(255, 210, 170), rgb(40, 60, 140))
	for i = 0, 2 do
		k.rect(0.86, 0.66 + i * 0.05, 0.08, 0.012, W, {t = 0.3})
	end
end

return A

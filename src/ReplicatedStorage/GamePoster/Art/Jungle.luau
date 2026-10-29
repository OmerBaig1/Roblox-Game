--[[
	Jungle Temple posters (Vine Vault and Idol Sanctum). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(15, 25, 15)
local GOLD, JADE, LEAF, STONE = rgb(255, 205, 60), rgb(40, 200, 120), rgb(60, 160, 70), rgb(160, 150, 115)

local function jungle(k, rng, top, bottom)
	k.sky(top or rgb(150, 220, 160), bottom or rgb(40, 110, 60))
	for i = 0, 5 do
		k.ellipse(0.08 + i * 0.18, 0.08, 0.3, 0.2, LEAF:Lerp(B, (i % 2) * 0.2))
	end
	for _ = 1, 6 do
		local x = rng:NextNumber(0.05, 0.95)
		k.rect(x, 0.2, 0.01, rng:NextNumber(0.2, 0.4), rgb(50, 120, 50))
	end
	k.rect(0.5, 0.92, 1, 0.16, rgb(80, 60, 40))
end
local function temple(k, x, baseY, s)
	for i = 0, 3 do
		k.rect(x, baseY - i * 0.08 * s, (0.6 - i * 0.12) * s, 0.08 * s, STONE:Lerp(B, (i % 2) * 0.1))
	end
	k.rect(x, baseY - 0.34 * s, 0.1 * s, 0.1 * s, rgb(30, 25, 20))
end
local function idol(k, x, y, s)
	k.rect(x, y, 0.12 * s, 0.18 * s, GOLD, {round = 0.2})
	k.circle(x, y - 0.13 * s, 0.1 * s, GOLD)
	P.eyes(k, x, y - 0.13 * s, 0.02 * s, 0.03 * s)
end

local A = {}

A["Jungle Jumble"] = function(k, rng)
	-- a pile of tumbling puzzle blocks carved with animals, vines everywhere
	jungle(k, rng)
	local icons = {"\u{1F412}", "\u{1F40D}", "\u{1F99C}", "\u{1F406}", "\u{1F40A}", "\u{1F98E}"}
	for i = 0, 5 do
		local x, y = 0.25 + (i % 3) * 0.25, 0.5 + math.floor(i / 3) * 0.2
		k.rect(x, y, 0.2, 0.17, STONE, {rot = (i - 2.5) * 6, round = 0.1})
		k.text(x, y, 0.14, 0.13, icons[i + 1], W)
	end
end
A["Pitfall Panic"] = function(k, rng)
	-- an explorer swinging on a vine over a crocodile pit
	jungle(k, rng)
	k.rect(0.5, 0.88, 0.5, 0.16, rgb(40, 90, 120))
	for _, x in ipairs({0.4, 0.6}) do
		k.ellipse(x, 0.82, 0.14, 0.05, rgb(60, 130, 60))
		P.eyes(k, x + 0.03, 0.8, 0.015, 0.02)
	end
	k.rect(0.45, 0.32, 0.01, 0.5, rgb(60, 120, 50), {rot = 20})
	P.person(k, 0.55, 0.62, 0.5, rgb(230, 200, 120), rgb(220, 170, 130), rgb(110, 80, 50))
end
A["Far Cry Baby"] = function(k, rng)
	-- a giant crying baby in camo on a jungle island, tears making waterfalls
	k.sky(rgb(120, 200, 240), rgb(200, 240, 220))
	k.waves(0.8, rgb(60, 160, 210), 0.14)
	k.ellipse(0.5, 0.78, 0.7, 0.2, LEAF)
	k.circle(0.5, 0.45, 0.34, rgb(255, 210, 180))
	k.rect(0.5, 0.3, 0.34, 0.08, rgb(90, 110, 60), {round = 0.5})
	for _, x in ipairs({0.42, 0.58}) do
		k.rect(x, 0.45, 0.06, 0.02, B)
		k.rect(x, 0.62, 0.03, 0.26, rgb(120, 210, 255), {t = 0.2})
	end
	k.ellipse(0.5, 0.55, 0.1, 0.06, rgb(180, 60, 60))
end
A["Snake Pass-word"] = function(k, rng)
	-- a snake coiled around a padlock, its tail typing a password
	jungle(k, rng, rgb(170, 230, 170), rgb(60, 130, 70))
	k.rect(0.5, 0.62, 0.3, 0.26, rgb(200, 200, 210), {round = 0.15})
	k.circle(0.5, 0.42, 0.22, rgb(200, 200, 210))
	k.circle(0.5, 0.42, 0.14, rgb(60, 130, 70))
	for i = 0, 4 do
		k.ellipse(0.5, 0.5 + i * 0.07, 0.42, 0.06, i % 2 == 0 and rgb(80, 200, 90) or rgb(255, 210, 60), {rot = (i % 2) * 10 - 5})
	end
	k.circle(0.75, 0.42, 0.08, rgb(80, 200, 90))
	P.eyes(k, 0.75, 0.41, 0.015, 0.025)
	k.text(0.5, 0.15, 0.4, 0.1, "****", W)
end
A["Banjo-Kazoomie"] = function(k, rng)
	-- a bear strumming a banjo, a bird popping out of his backpack with a kazoo
	jungle(k, rng)
	k.circle(0.45, 0.6, 0.34, rgb(150, 100, 60))
	k.circle(0.45, 0.4, 0.22, rgb(150, 100, 60))
	P.eyes(k, 0.45, 0.4, 0.03, 0.05)
	k.circle(0.45, 0.66, 0.14, rgb(240, 220, 170))
	k.rect(0.62, 0.55, 0.3, 0.02, rgb(120, 80, 40), {rot = -30})
	k.circle(0.72, 0.28, 0.1, rgb(230, 60, 60))
	k.rect(0.8, 0.28, 0.06, 0.02, GOLD)
end
A["Tarzan Tumble"] = function(k, rng)
	-- an ape-man tumbling head over heels through vines, monkeys cheering
	jungle(k, rng, rgb(255, 210, 150), rgb(60, 120, 70))
	k.rect(0.5, 0.45, 0.25, 0.25, rgb(200, 150, 110), {rot = 45, round = 0.4})
	k.circle(0.5, 0.3, 0.1, rgb(80, 50, 30))
	k.rect(0.5, 0.55, 0.12, 0.05, rgb(140, 90, 40), {rot = 45})
	for _, x in ipairs({0.15, 0.85}) do
		k.circle(x, 0.7, 0.1, rgb(120, 80, 50))
		k.circle(x, 0.72, 0.06, rgb(230, 190, 150))
	end
end
A["Indiana Bones"] = function(k, rng)
	-- a skeleton adventurer in a fedora cracking a whip before a temple
	jungle(k, rng)
	temple(k, 0.7, 0.85, 1.2)
	k.circle(0.3, 0.35, 0.14, rgb(240, 235, 220))
	P.eyes(k, 0.3, 0.35, 0.025, 0.04)
	k.ellipse(0.3, 0.26, 0.22, 0.04, rgb(120, 80, 40))
	k.rect(0.3, 0.23, 0.12, 0.06, rgb(120, 80, 40), {round = 0.3})
	k.rect(0.3, 0.6, 0.12, 0.3, rgb(240, 235, 220), {round = 0.3})
	k.rect(0.45, 0.45, 0.3, 0.01, rgb(90, 60, 30), {rot = -25})
end
A["Golden Idol Grab"] = function(k, rng)
	-- a hand snatching a golden idol off a pedestal as a boulder rolls in
	k.sky(rgb(70, 50, 30), rgb(130, 100, 60))
	k.rect(0.5, 0.75, 0.2, 0.3, STONE)
	idol(k, 0.5, 0.48, 1.3)
	k.rect(0.66, 0.42, 0.14, 0.06, rgb(220, 170, 130), {round = 0.5})
	k.circle(0.15, 0.55, 0.5, rgb(110, 95, 80))
	k.rect(0.15, 0.55, 0.2, 0.02, rgb(80, 70, 60), {rot = 30})
end
A["Tiki Torch Tag"] = function(k, rng)
	-- a ring of flaming tiki torches around a giggling tiki mask
	k.sky(rgb(40, 20, 60), rgb(220, 100, 60))
	k.rect(0.5, 0.55, 0.22, 0.5, rgb(140, 90, 50), {round = 0.1})
	for _, x in ipairs({0.45, 0.55}) do
		k.rect(x, 0.45, 0.05, 0.05, rgb(255, 230, 120))
	end
	k.rect(0.5, 0.6, 0.12, 0.04, B)
	for i = 0, 3 do
		local x = 0.1 + i * 0.27
		k.rect(x, 0.75, 0.025, 0.3, rgb(120, 80, 40))
		k.ellipse(x, 0.58, 0.06, 0.1, rgb(255, 160, 40))
	end
end
A["Shadow of the Tomb Rater"] = function(k, rng)
	-- a silhouette with a torch against a vast glowing temple, the rating stars carved overhead
	k.sky(rgb(30, 30, 60), rgb(255, 140, 70))
	temple(k, 0.5, 0.88, 1.6)
	k.circle(0.5, 0.35, 0.2, rgb(255, 210, 120), {t = 0.4})
	P.person(k, 0.3, 0.86, 0.6, B, B, B)
	k.text(0.5, 0.12, 0.5, 0.1, "\u{2B50}\u{2B50}\u{2B50}\u{2B50}\u{2606}", GOLD)
end
A["Aztec Attack"] = function(k, rng)
	-- a feathered serpent bursting out of a stepped pyramid
	k.sky(rgb(255, 180, 90), rgb(90, 180, 220))
	temple(k, 0.5, 0.9, 1.5)
	for i = 0, 6 do
		k.circle(0.3 + i * 0.07, 0.5 - math.sin(i * 0.8) * 0.12, 0.1, i % 2 == 0 and JADE or rgb(230, 60, 60))
	end
	k.circle(0.8, 0.36, 0.13, JADE)
	P.eyes(k, 0.82, 0.34, 0.02, 0.03)
	for i = -1, 1 do
		k.rect(0.8 + i * 0.05, 0.22, 0.03, 0.1, ({rgb(230, 60, 60), GOLD, rgb(80, 160, 255)})[i + 2], {rot = i * 15})
	end
end
A["Jungle Juice Jam"] = function(k, rng)
	-- fruit with faces playing drums made of coconuts
	jungle(k, rng, rgb(255, 230, 140), rgb(90, 180, 90))
	for i, c in ipairs({rgb(255, 150, 30), rgb(250, 220, 60), rgb(230, 60, 90)}) do
		local x = 0.2 + (i - 1) * 0.3
		k.circle(x, 0.55, 0.2, c)
		P.eyes(k, x, 0.53, 0.025, 0.04)
		P.smile(k, x, 0.6, 0.06, B)
		k.ellipse(x, 0.8, 0.16, 0.08, rgb(110, 70, 40))
	end
end

return A

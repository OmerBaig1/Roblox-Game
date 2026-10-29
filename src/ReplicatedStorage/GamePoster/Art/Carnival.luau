--[[
	Midnight Carnival posters (Funhouse Midway and Big Top Circus). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(20, 15, 30)
local RED, GOLD, NIGHT = rgb(220, 40, 60), rgb(255, 210, 60), rgb(30, 20, 70)

local function midway(k, rng)
	k.sky(NIGHT, rgb(120, 50, 140))
	k.stars(12, rng, 0.4)
	for i = 0, 12 do
		k.circle(i / 12, 0.08 + math.sin(i) * 0.02, 0.025, ({GOLD, rgb(255, 120, 200), rgb(120, 220, 255)})[i % 3 + 1])
	end
	k.rect(0.5, 0.92, 1, 0.16, rgb(70, 50, 40))
end
local function tent(k, x, baseY, s)
	for i = 0, 5 do
		k.rect(x - 0.25 * s + i * 0.1 * s, baseY - 0.15 * s, 0.1 * s, 0.3 * s, i % 2 == 0 and RED or W)
	end
	k.rect(x, baseY - 0.38 * s, 0.4 * s, 0.4 * s, RED, {rot = 45})
	k.rect(x, baseY - 0.62 * s, 0.015 * s, 0.1 * s, W)
end
local function clownFace(k, x, y, s)
	k.circle(x, y, 0.3 * s, W)
	P.eyes(k, x, y - 0.03 * s, 0.04 * s, 0.07 * s)
	k.circle(x, y + 0.03 * s, 0.06 * s, RED)
	P.smile(k, x, y + 0.09 * s, 0.14 * s, RED)
	k.circle(x - 0.15 * s, y - 0.06 * s, 0.1 * s, rgb(255, 120, 40))
	k.circle(x + 0.15 * s, y - 0.06 * s, 0.1 * s, rgb(255, 120, 40))
end

local A = {}

A["Carnival Clash"] = function(k, rng)
	-- two bumper cars crashing under the carnival lights
	midway(k, rng)
	P.kart(k, 0.33, 0.72, 1.2, rgb(255, 80, 120))
	P.kart(k, 0.67, 0.72, 1.2, rgb(80, 180, 255))
	P.star(k, 0.5, 0.62, 0.14, GOLD)
	k.text(0.5, 0.3, 0.4, 0.12, "BONK!", W, {stroke = true})
end
A["Whack-a-Moe"] = function(k, rng)
	-- a mallet coming down on a startled mole popping out of a hole
	midway(k, rng)
	k.rect(0.5, 0.8, 0.8, 0.14, rgb(200, 40, 60), {round = 0.2})
	for _, x in ipairs({0.25, 0.5, 0.75}) do
		k.ellipse(x, 0.76, 0.14, 0.05, B)
	end
	k.circle(0.5, 0.66, 0.14, rgb(140, 100, 80))
	P.eyes(k, 0.5, 0.64, 0.02, 0.035)
	k.rect(0.7, 0.4, 0.04, 0.3, rgb(140, 90, 50), {rot = -40})
	k.rect(0.6, 0.3, 0.16, 0.1, RED, {rot = -40, round = 0.2})
end
A["Funhouse Frenzy"] = function(k, rng)
	-- a giant laughing clown mouth as the funhouse door, the floor tilting
	midway(k, rng)
	clownFace(k, 0.5, 0.48, 1.4)
	k.rect(0.5, 0.86, 1.1, 0.12, rgb(255, 210, 60), {rot = 8})
end
A["Cotton Candy Crush"] = function(k, rng)
	-- a fluffy pink cotton-candy cloud squashing a ticket booth
	midway(k, rng)
	k.rect(0.5, 0.78, 0.3, 0.2, RED)
	for i = 0, 5 do
		k.circle(0.3 + i * 0.08, 0.5 + (i % 2) * 0.05, 0.22, rgb(255, 170, 220))
	end
	k.rect(0.5, 0.72, 0.015, 0.25, W)
end
A["Ring Toss Royale"] = function(k, rng)
	-- golden rings flying towards a crown of bottles
	midway(k, rng)
	for i = 0, 5 do
		k.rect(0.3 + i * 0.08, 0.7 - (i % 2) * 0.02, 0.05, 0.18, rgb(80, 200, 120), {round = 0.3, t = 0.1})
	end
	for i = 0, 2 do
		k.circle(0.25 + i * 0.22, 0.32 - i * 0.04, 0.12, GOLD)
		k.circle(0.25 + i * 0.22, 0.32 - i * 0.04, 0.08, NIGHT)
	end
	k.text(0.5, 0.12, 0.3, 0.1, "\u{1F451}", W)
end
A["Mirror Maze Madness"] = function(k, rng)
	-- a hero reflected a dozen times in a maze of mirrors
	k.sky(rgb(120, 200, 255), rgb(220, 150, 255))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.55, 0.16, 0.7, rgb(220, 240, 255), {t = 0.2})
		P.person(k, 0.1 + i * 0.2, 0.75, 0.45 - math.abs(i - 2) * 0.06, rgb(255, 90, 160), rgb(255, 210, 170), rgb(60, 60, 140))
	end
end
A["Circus Charlie Horse"] = function(k, rng)
	-- a horse in a tutu balancing on a giant ball
	k.sky(rgb(150, 40, 60), rgb(255, 180, 120))
	tent(k, 0.5, 0.9, 1.8)
	k.circle(0.5, 0.75, 0.3, rgb(80, 150, 255))
	k.ellipse(0.5, 0.48, 0.28, 0.12, rgb(140, 90, 60))
	k.circle(0.66, 0.38, 0.08, rgb(140, 90, 60))
	k.ellipse(0.5, 0.54, 0.32, 0.05, rgb(255, 170, 220))
end
A["Clown Car Kart"] = function(k, rng)
	-- a tiny car with far too many clowns spilling out
	k.sky(rgb(255, 210, 120), rgb(255, 150, 190))
	P.kart(k, 0.5, 0.75, 1.2, rgb(255, 210, 40))
	for i = 0, 4 do
		clownFace(k, 0.25 + i * 0.12, 0.45 - math.sin(i / 4 * math.pi) * 0.18, 0.4)
	end
end
A["Trapeze Tycoon"] = function(k, rng)
	-- an acrobat flying between trapezes, cash raining from the big top
	k.sky(rgb(60, 30, 100), rgb(170, 60, 120))
	for _, x in ipairs({0.2, 0.8}) do
		k.rect(x, 0.2, 0.01, 0.3, W)
		k.rect(x, 0.35, 0.12, 0.015, GOLD)
	end
	P.person(k, 0.5, 0.42, 0.45, rgb(255, 120, 200), rgb(255, 210, 170), rgb(255, 120, 200))
	for _ = 1, 8 do
		k.rect(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.55, 0.95), 0.06, 0.03, rgb(80, 180, 90), {rot = rng:NextNumber(-30, 30)})
	end
end
A["Juggle Juggernaut"] = function(k, rng)
	-- a huge strongman juggling cannonballs, flowers and a piano
	k.sky(rgb(255, 160, 80), rgb(150, 60, 110))
	k.rect(0.5, 0.75, 0.3, 0.4, rgb(230, 180, 150), {round = 0.3})
	k.rect(0.5, 0.7, 0.32, 0.06, RED)
	k.circle(0.5, 0.48, 0.14, rgb(230, 180, 150))
	k.rect(0.5, 0.5, 0.12, 0.03, B)
	for i = 0, 3 do
		local a = i / 4 * math.pi
		k.circle(0.5 + math.cos(a) * 0.32, 0.32 - math.sin(a) * 0.16, 0.1, ({rgb(40, 40, 50), rgb(255, 120, 200), GOLD, rgb(80, 180, 255)})[i + 1])
	end
end
A["Lion Tamer Legends"] = function(k, rng)
	-- a lion leaping through a flaming hoop, the tamer's whip cracking
	k.sky(rgb(120, 30, 50), rgb(255, 140, 70))
	k.circle(0.55, 0.45, 0.36, rgb(255, 140, 30))
	k.circle(0.55, 0.45, 0.28, rgb(120, 30, 50))
	k.circle(0.55, 0.45, 0.2, rgb(220, 140, 50))
	k.circle(0.55, 0.45, 0.12, rgb(240, 190, 90))
	P.eyes(k, 0.55, 0.43, 0.02, 0.035)
	P.person(k, 0.15, 0.85, 0.55, RED, rgb(230, 190, 160), W)
end
A["Human Cannonball Club"] = function(k, rng)
	-- a daredevil in a helmet blasting out of a striped cannon
	k.sky(rgb(80, 160, 240), rgb(255, 220, 160))
	k.rect(0.25, 0.75, 0.34, 0.14, RED, {rot = -35, round = 0.3})
	for i = 0, 2 do
		k.rect(0.2 + i * 0.07, 0.8 - i * 0.05, 0.03, 0.16, W, {rot = -35})
	end
	k.circle(0.5, 0.48, 0.2, rgb(255, 210, 60), {t = 0.3})
	P.person(k, 0.7, 0.32, 0.45, rgb(230, 230, 240), rgb(255, 210, 170), rgb(60, 120, 230))
	P.star(k, 0.45, 0.52, 0.12, W)
end

return A

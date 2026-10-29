--[[
	Cosmic Nexus posters (Time Warp Terminal and Throne of Infinity): the deepest games in the vault.
	One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(10, 10, 20)
local GOLD, TEAL, VOID = rgb(255, 215, 90), rgb(80, 255, 200), rgb(20, 10, 40)

local function cosmos(k, rng, top, bottom)
	k.sky(top or VOID, bottom or rgb(70, 30, 110))
	k.stars(22, rng, 0.95)
	k.circle(0.5, 0.5, 0.9, rgb(150, 80, 255), {t = 0.85})
end
local function clockFace(k, x, y, d, color)
	k.circle(x, y, d, color or W)
	k.circle(x, y, d * 0.88, rgb(30, 40, 60))
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		k.circle(x + math.cos(a) * d * 0.37, y + math.sin(a) * d * 0.37 / 0.775, d * 0.05, TEAL)
	end
	k.rect(x, y - d * 0.15, d * 0.03, d * 0.3, W)
	k.rect(x + d * 0.1, y, d * 0.22, d * 0.03, W, {rot = 20})
end

local A = {}

A["Chrono Trigger Happy"] = function(k, rng)
	-- a hero leaping through a swirling time portal, three eras shining through
	cosmos(k, rng)
	for i = 0, 3 do
		k.circle(0.5, 0.48, 0.8 - i * 0.18, ({TEAL, rgb(150, 80, 255), GOLD, W})[i + 1], {t = 0.5})
	end
	P.person(k, 0.5, 0.56, 0.55, rgb(230, 60, 60), rgb(230, 190, 160), rgb(40, 60, 140))
end
A["Braid Braid"] = function(k, rng)
	-- a giant golden braid tied in a knot through time, a little hero climbing it
	cosmos(k, rng, rgb(60, 40, 90), rgb(240, 160, 120))
	for i = 0, 7 do
		k.ellipse(0.5 + math.sin(i) * 0.05, 0.1 + i * 0.11, 0.14, 0.1, GOLD, {rot = (i % 2) * 40 - 20})
	end
	P.person(k, 0.6, 0.56, 0.35, rgb(60, 80, 160), rgb(230, 190, 160), B)
end
A["Superhot Sauce"] = function(k, rng)
	-- red crystal hot sauce bottles shattering in frozen slow motion
	k.sky(W, rgb(230, 230, 235))
	for i = -1, 1 do
		k.rect(0.5 + i * 0.25, 0.55, 0.12, 0.34, rgb(230, 40, 40), {round = 0.2})
		k.rect(0.5 + i * 0.25, 0.34, 0.05, 0.08, rgb(230, 40, 40))
	end
	for _ = 1, 16 do
		k.rect(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.9), 0.03, 0.05, rgb(240, 60, 60), {rot = rng:NextNumber(0, 180)})
	end
	k.text(0.5, 0.12, 0.6, 0.12, "SUPER HOT", rgb(220, 30, 30))
end
A["Life is Strange-r"] = function(k, rng)
	-- a girl with a camera rewinding a tornado over a lighthouse
	cosmos(k, rng, rgb(255, 160, 120), rgb(110, 90, 170))
	k.rect(0.8, 0.65, 0.08, 0.4, W)
	k.rect(0.8, 0.45, 0.1, 0.05, rgb(230, 60, 60))
	for i = 0, 5 do
		k.ellipse(0.35, 0.2 + i * 0.1, 0.36 - i * 0.05, 0.06, rgb(70, 60, 90), {t = 0.2})
	end
	P.person(k, 0.55, 0.85, 0.5, rgb(80, 110, 160), rgb(230, 190, 160), rgb(60, 60, 80))
	k.rect(0.6, 0.66, 0.06, 0.04, B)
end
A["Quantum Breaker"] = function(k, rng)
	-- a hero frozen mid-punch, a shockwave cracking time itself into shards
	cosmos(k, rng)
	for i = 0, 7 do
		k.rect(0.5, 0.48, 0.015, 0.9, TEAL, {rot = i * 22.5, t = 0.3})
	end
	k.circle(0.5, 0.48, 0.24, W, {t = 0.5})
	P.person(k, 0.5, 0.6, 0.55, rgb(40, 40, 50), rgb(230, 190, 160), rgb(40, 40, 50))
end
A["Timesplitters Splat"] = function(k, rng)
	-- three versions of the same hero from three eras splatted by paint
	cosmos(k, rng, rgb(30, 30, 60), rgb(90, 60, 120))
	for i, c in ipairs({rgb(200, 150, 90), rgb(80, 160, 230), rgb(200, 60, 200)}) do
		P.person(k, 0.2 + (i - 1) * 0.3, 0.8, 0.55, c, rgb(230, 190, 160), B)
		k.circle(0.2 + (i - 1) * 0.3, 0.45, 0.12, ({rgb(255, 80, 120), rgb(80, 255, 140), rgb(255, 210, 60)})[i], {t = 0.2})
	end
end
A["Infinity Gauntlet Run"] = function(k, rng)
	-- a glowing gauntlet set with six stones, a runner chasing it across space
	cosmos(k, rng)
	k.rect(0.6, 0.48, 0.3, 0.36, GOLD, {round = 0.2})
	for i, c in ipairs({rgb(255, 80, 80), rgb(255, 200, 60), rgb(80, 220, 120), rgb(80, 160, 255), rgb(200, 100, 255), rgb(255, 140, 40)}) do
		k.circle(0.5 + ((i - 1) % 3) * 0.1, 0.4 + math.floor((i - 1) / 3) * 0.12, 0.06, c)
	end
	P.person(k, 0.2, 0.82, 0.5, rgb(255, 255, 255), rgb(230, 190, 160), rgb(40, 40, 80))
end
A["The Last of Uz"] = function(k, rng)
	-- the last two players left in a ruined arcade, overgrown with vines, a lone screen glowing
	k.sky(rgb(110, 140, 130), rgb(60, 80, 70))
	for i = 0, 3 do
		k.rect(0.15 + i * 0.23, 0.6, 0.16, 0.5, rgb(70, 70, 80))
		k.rect(0.15 + i * 0.23, 0.48, 0.12, 0.1, i == 2 and TEAL or rgb(30, 30, 35))
	end
	for _ = 1, 8 do
		k.rect(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.3, 0.9), 0.01, 0.2, rgb(70, 130, 60))
	end
	P.person(k, 0.42, 0.9, 0.5, rgb(90, 70, 50), rgb(230, 190, 160), rgb(60, 70, 90))
	P.person(k, 0.55, 0.9, 0.4, rgb(150, 60, 60), rgb(230, 190, 160), rgb(60, 70, 90))
end
A["Mind Craft Infinite"] = function(k, rng)
	-- a block brain floating in space, building endless block worlds around it
	cosmos(k, rng)
	P.brain(k, 0.5, 0.45, 1.8)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P.sq(k, 0.5 + math.cos(a) * 0.36, 0.48 + math.sin(a) * 0.3, 0.07, ({rgb(110, 190, 80), rgb(140, 100, 60), rgb(150, 150, 160)})[i % 3 + 1])
	end
end
A["Final Boss Rush"] = function(k, rng)
	-- a line of every boss in silhouette, a tiny hero standing before them
	cosmos(k, rng, rgb(60, 0, 20), rgb(150, 30, 60))
	for i = 0, 5 do
		local x = 0.1 + i * 0.16
		k.ellipse(x, 0.6 - (i % 2) * 0.08, 0.14, 0.4 + (i % 3) * 0.1, B)
		P.eyes(k, x, 0.48 - (i % 2) * 0.08, 0.02, 0.03)
	end
	P.person(k, 0.5, 0.92, 0.4, W, rgb(230, 190, 160), rgb(60, 120, 230))
end
A["Game of the Year Edition"] = function(k, rng)
	-- a golden trophy shaped like a game controller, laurels and confetti
	cosmos(k, rng, rgb(40, 20, 60), rgb(120, 60, 30))
	k.rect(0.5, 0.82, 0.24, 0.08, GOLD)
	k.rect(0.5, 0.7, 0.06, 0.16, GOLD)
	k.rect(0.5, 0.45, 0.4, 0.2, GOLD, {round = 0.4})
	for _, s in ipairs({-1, 1}) do
		k.circle(0.5 + s * 0.13, 0.45, 0.06, rgb(200, 150, 40))
	end
	for _ = 1, 14 do
		k.rect(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.6), 0.03, 0.012, ({rgb(255, 80, 120), rgb(80, 200, 255), GOLD, W})[rng:NextInteger(1, 4)], {rot = rng:NextNumber(0, 180)})
	end
	k.text(0.5, 0.18, 0.5, 0.1, "GOTY", W, {stroke = true})
end
A["Steal a Game 2"] = function(k, rng)
	-- the sequel: the Game Vault itself floating in space, a hero running out with a glowing game case
	cosmos(k, rng, rgb(30, 10, 60), rgb(255, 120, 200))
	k.rect(0.5, 0.45, 0.5, 0.34, rgb(120, 95, 235))
	k.rect(0.5, 0.52, 0.16, 0.2, B)
	k.rect(0.5, 0.3, 0.3, 0.06, GOLD)
	k.text(0.5, 0.3, 0.28, 0.05, "VAULT 2", B)
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.29, 0.42, 0.08, 0.44, s < 0 and rgb(255, 85, 95) or rgb(70, 160, 255))
	end
	P.person(k, 0.3, 0.88, 0.5, rgb(255, 210, 40), rgb(230, 190, 160), rgb(60, 60, 140))
	k.rect(0.36, 0.72, 0.08, 0.1, TEAL, {round = 0.2})
	k.text(0.5, 0.1, 0.5, 0.1, "2", GOLD, {stroke = true})
end

return A

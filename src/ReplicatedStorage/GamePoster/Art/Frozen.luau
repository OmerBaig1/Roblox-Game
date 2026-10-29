--[[
	Frozen Tundra posters (Ice Cave Outlet and Yeti Peak Lodge). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(15, 20, 35)
local ICE, SNOW, NIGHT = rgb(170, 225, 255), rgb(245, 250, 255), rgb(30, 50, 100)

local function snowy(k, rng, top, bottom)
	k.sky(top or rgb(120, 180, 240), bottom or rgb(220, 240, 255))
	-- mountains with snowy caps
	for i, x in ipairs({0.2, 0.55, 0.85}) do
		local h = 0.35 + (i % 2) * 0.12
		k.rect(x, 0.8 - h / 2, h * 0.9, h * 0.9, rgb(140, 160, 200), {rot = 45})
		k.rect(x, 0.8 - h * 0.85, h * 0.32, h * 0.32, SNOW, {rot = 45})
	end
	k.waves(0.84, SNOW, 0.2)
	for _ = 1, 16 do
		k.circle(rng:NextNumber(0, 1), rng:NextNumber(0, 0.8), rng:NextNumber(0.008, 0.018), W, {t = 0.2})
	end
end
local function penguin(k, x, y, s)
	k.ellipse(x, y, 0.16 * s, 0.26 * s, rgb(30, 30, 45))
	k.ellipse(x, y + 0.03 * s, 0.1 * s, 0.18 * s, W)
	P.eyes(k, x, y - 0.08 * s, 0.025 * s, 0.035 * s)
	k.rect(x, y - 0.04 * s, 0.04 * s, 0.02 * s, rgb(255, 150, 40), {rot = 45})
end

local A = {}

A["Frostpunch"] = function(k, rng)
	-- a giant ice fist smashing through a frozen city's heat tower
	snowy(k, rng, rgb(60, 70, 110), rgb(160, 180, 220))
	k.rect(0.3, 0.6, 0.12, 0.5, rgb(90, 70, 60))
	k.circle(0.3, 0.33, 0.12, rgb(255, 150, 60))
	k.rect(0.65, 0.45, 0.32, 0.26, ICE, {round = 0.3, t = 0.1})
	for i = 0, 3 do
		k.rect(0.54 + i * 0.07, 0.34, 0.06, 0.08, ICE, {round = 0.4})
	end
	P.lightning(k, 0.45, 0.4, 0.6, W)
end
A["Ice Slippers"] = function(k, rng)
	-- two climbers skidding helplessly across a frozen lake in fluffy slippers
	snowy(k, rng)
	k.ellipse(0.5, 0.82, 0.9, 0.16, ICE)
	P.person(k, 0.35, 0.74, 0.55, rgb(80, 140, 255), rgb(255, 210, 170), rgb(240, 120, 160))
	P.person(k, 0.65, 0.72, 0.55, rgb(255, 120, 160), rgb(255, 210, 170), rgb(80, 140, 255))
	for _, x in ipairs({0.35, 0.65}) do
		k.ellipse(x, 0.8, 0.1, 0.04, rgb(255, 200, 230))
	end
end
A["The Long Darkish"] = function(k, rng)
	-- a lone hiker with a lantern in a not-quite-dark snowy forest
	k.sky(rgb(20, 30, 60), rgb(70, 90, 140))
	k.stars(16, rng, 0.45)
	for i = 0, 6 do
		P.tree(k, 0.05 + i * 0.15, 0.88, 0.7 + (i % 3) * 0.2, rgb(30, 60, 70))
	end
	k.waves(0.88, SNOW, 0.2)
	P.person(k, 0.5, 0.84, 0.6, rgb(140, 70, 40), rgb(230, 190, 160), rgb(50, 50, 60))
	k.circle(0.58, 0.68, 0.1, rgb(255, 210, 120), {t = 0.4})
	k.circle(0.58, 0.68, 0.04, rgb(255, 230, 150))
end
A["Snowboard Dudes"] = function(k, rng)
	-- a boarder flipping off a jump, goggles flashing
	snowy(k, rng, rgb(70, 160, 255), rgb(230, 245, 255))
	k.rect(0.3, 0.75, 0.6, 0.12, SNOW, {rot = -20})
	k.rect(0.62, 0.42, 0.28, 0.05, rgb(255, 90, 40), {rot = 25, round = 0.5})
	P.person(k, 0.62, 0.32, 0.55, rgb(255, 210, 40), rgb(230, 190, 160), rgb(40, 60, 140))
	k.rect(0.62, 0.15, 0.1, 0.03, rgb(120, 220, 255))
	for i = 0, 2 do
		k.rect(0.45 - i * 0.05, 0.5 + i * 0.04, 0.08, 0.01, W, {t = 0.3})
	end
end
A["Club Pengwin"] = function(k, rng)
	-- a penguin party on an ice floe, a disco ball overhead
	k.sky(rgb(50, 40, 110), rgb(90, 160, 230))
	k.waves(0.82, rgb(40, 90, 160), 0.14)
	k.ellipse(0.5, 0.82, 0.8, 0.12, ICE)
	for i, x in ipairs({0.25, 0.5, 0.75}) do
		penguin(k, x, 0.65, 0.9 + (i % 2) * 0.2)
	end
	k.circle(0.5, 0.15, 0.12, rgb(220, 225, 235))
	for i = 0, 5 do
		k.rect(0.5, 0.15, 0.6, 0.008, ({rgb(255, 120, 200), rgb(120, 220, 255), rgb(255, 230, 120)})[i % 3 + 1], {rot = i * 30, t = 0.4})
	end
end
A["Glacier Glide"] = function(k, rng)
	-- a seal sliding down a glittering glacier
	snowy(k, rng)
	k.rect(0.5, 0.6, 1.1, 0.3, ICE, {rot = 18})
	for _ = 1, 6 do
		P.star(k, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.4, 0.8), 0.04, W)
	end
	k.ellipse(0.55, 0.52, 0.26, 0.1, rgb(140, 150, 170), {rot = 18})
	k.circle(0.66, 0.48, 0.07, rgb(150, 160, 180))
	P.eyes(k, 0.67, 0.47, 0.02, 0.025)
end
A["Celestay"] = function(k, rng)
	-- a climber with red hair reaching the summit of a starry mountain, strawberries floating
	k.sky(rgb(40, 30, 90), rgb(180, 110, 200))
	k.stars(20, rng, 0.6)
	k.rect(0.5, 0.95, 0.9, 0.9, rgb(70, 60, 120), {rot = 45})
	P.person(k, 0.5, 0.5, 0.5, rgb(60, 120, 230), rgb(255, 210, 170), rgb(60, 50, 80))
	k.circle(0.5, 0.36, 0.08, rgb(230, 60, 60))
	for _, x in ipairs({0.25, 0.78}) do
		k.circle(x, 0.3, 0.07, rgb(230, 40, 60))
		k.rect(x, 0.26, 0.04, 0.02, rgb(80, 200, 90))
	end
end
A["Steep Slopes"] = function(k, rng)
	-- a skier bombing down an impossibly steep slope, pine trees blurring past
	k.sky(rgb(90, 170, 250), rgb(230, 245, 255))
	k.rect(0.5, 0.7, 1.4, 0.6, SNOW, {rot = 35})
	for i = 0, 3 do
		P.tree(k, 0.15 + i * 0.25, 0.4 + i * 0.15, 0.5, rgb(40, 110, 70))
	end
	P.person(k, 0.5, 0.55, 0.55, rgb(230, 50, 60), rgb(230, 190, 160), rgb(40, 40, 60))
	k.rect(0.5, 0.6, 0.3, 0.015, rgb(255, 210, 40), {rot = 35})
end
A["Yeti Spaghetti"] = function(k, rng)
	-- a yeti slurping a mountain of spaghetti in a cosy lodge
	k.sky(rgb(150, 90, 60), rgb(200, 130, 80))
	k.rect(0.5, 0.85, 1, 0.3, rgb(120, 70, 40))
	k.circle(0.5, 0.4, 0.4, rgb(235, 240, 250))
	k.ellipse(0.5, 0.42, 0.22, 0.2, rgb(130, 150, 180))
	P.eyes(k, 0.5, 0.38, 0.04, 0.06)
	k.ellipse(0.5, 0.75, 0.4, 0.14, W)
	k.ellipse(0.5, 0.7, 0.3, 0.12, rgb(255, 210, 120))
	k.circle(0.45, 0.66, 0.05, rgb(200, 40, 30))
	k.circle(0.56, 0.68, 0.05, rgb(200, 40, 30))
	k.rect(0.5, 0.55, 0.01, 0.15, rgb(255, 210, 120))
end
A["Frozen Throne Wars"] = function(k, rng)
	-- an ice throne on a peak, armies of snowmen marching towards it
	snowy(k, rng, rgb(40, 60, 120), rgb(140, 170, 220))
	k.rect(0.5, 0.35, 0.16, 0.24, ICE, {t = 0.1})
	for i = -1, 1 do
		k.rect(0.5 + i * 0.05, 0.2, 0.04, 0.12, ICE, {rot = i * 10})
	end
	for i = 0, 5 do
		local x = 0.1 + i * 0.16
		k.circle(x, 0.78, 0.07, SNOW)
		k.circle(x, 0.72, 0.05, SNOW)
		k.rect(x, 0.69, 0.04, 0.02, B)
	end
end
A["Avalanche Ave"] = function(k, rng)
	-- a wall of snow pouring down a village street, a mailbox flying
	k.sky(rgb(130, 190, 240), rgb(220, 235, 255))
	k.circle(0.5, -0.05, 1.2, SNOW)
	for i = 0, 3 do
		k.rect(0.12 + i * 0.25, 0.75, 0.18, 0.2, rgb(200, 100, 70))
		k.rect(0.12 + i * 0.25, 0.63, 0.22, 0.06, SNOW)
	end
	k.rect(0.7, 0.4, 0.06, 0.04, rgb(60, 90, 200), {rot = 40})
	k.text(0.3, 0.35, 0.3, 0.1, "RUMBLE", rgb(120, 140, 180), {stroke = true})
end
A["Abominable Snowball"] = function(k, rng)
	-- a giant snowball rolling downhill, a yeti's surprised face poking out
	snowy(k, rng)
	k.circle(0.5, 0.56, 0.6, SNOW)
	k.circle(0.45, 0.5, 0.1, rgb(130, 150, 180))
	P.eyes(k, 0.45, 0.48, 0.025, 0.035)
	k.circle(0.45, 0.54, 0.025, B)
	for i = 0, 2 do
		k.rect(0.88, 0.5 + i * 0.06, 0.1, 0.012, W, {t = 0.3})
	end
end

return A

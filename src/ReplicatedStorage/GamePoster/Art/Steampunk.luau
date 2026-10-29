--[[
	Steampunk Skyway posters (Brass Gearworks Deck and Captain's Sky Bridge). One function per game, keyed by name.
]]

local P = require(script.Parent.Parent:WaitForChild("Pieces"))
local rgb = Color3.fromRGB
local W, B = rgb(255, 255, 255), rgb(30, 20, 15)
local BRASS, COPPER, SKY = rgb(210, 160, 70), rgb(190, 110, 60), rgb(140, 200, 240)

local function skies(k, rng, top, bottom)
	k.sky(top or rgb(255, 190, 120), bottom or SKY)
	for _ = 1, 4 do
		local x, y = rng:NextNumber(0.1, 0.9), rng:NextNumber(0.55, 0.9)
		for i = -1, 1 do
			k.circle(x + i * 0.07, y - (i == 0 and 0.03 or 0), 0.12, W, {t = 0.2})
		end
	end
end
local function airship(k, x, y, s, color)
	k.ellipse(x, y, 0.5 * s, 0.2 * s, color or rgb(170, 70, 60))
	for i = -2, 2 do
		k.rect(x + i * 0.08 * s, y, 0.008 * s, 0.19 * s, B, {t = 0.6})
	end
	k.rect(x, y + 0.16 * s, 0.2 * s, 0.06 * s, rgb(110, 70, 40), {round = 0.3})
	k.rect(x - 0.27 * s, y, 0.05 * s, 0.12 * s, BRASS)
end
local function gearIcon(k, x, y, d, color)
	P.gear(k, x, y, d, color or BRASS, rgb(60, 40, 30))
end

local A = {}

A["Sky Pirates of Arcadia"] = function(k, rng)
	-- a pirate airship with jolly roger sails boarding a merchant zeppelin
	skies(k, rng)
	airship(k, 0.35, 0.35, 1.1, rgb(60, 50, 60))
	k.rect(0.35, 0.18, 0.12, 0.1, B)
	k.text(0.35, 0.18, 0.08, 0.08, "\u{2620}", W)
	airship(k, 0.72, 0.55, 0.8, rgb(220, 200, 150))
end
A["Steamworld Sky"] = function(k, rng)
	-- a little steam robot hanging from a balloon, cogs spinning
	skies(k, rng, rgb(255, 210, 160), rgb(160, 210, 245))
	k.circle(0.5, 0.25, 0.3, rgb(220, 70, 60))
	for i = -1, 1 do
		k.rect(0.5 + i * 0.05, 0.45, 0.005, 0.15, B)
	end
	k.rect(0.5, 0.6, 0.12, 0.14, BRASS, {round = 0.2})
	k.rect(0.5, 0.58, 0.06, 0.02, rgb(255, 80, 40))
	gearIcon(k, 0.25, 0.7, 0.12)
	gearIcon(k, 0.78, 0.3, 0.1, COPPER)
end
A["Airship Armada"] = function(k, rng)
	-- a fleet of airships sailing in formation through sunset clouds
	skies(k, rng, rgb(255, 140, 80), rgb(255, 210, 160))
	for i = 0, 4 do
		airship(k, 0.15 + i * 0.18, 0.25 + (i % 2) * 0.2, 0.4 + (i % 3) * 0.1, ({rgb(170, 70, 60), rgb(60, 90, 150), rgb(140, 120, 60)})[i % 3 + 1])
	end
end
A["Cloud Crusher"] = function(k, rng)
	-- a giant brass fist punching through a cloud bank
	skies(k, rng)
	k.rect(0.5, 0.45, 0.32, 0.26, BRASS, {round = 0.25})
	for i = 0, 3 do
		k.rect(0.38 + i * 0.08, 0.32, 0.07, 0.08, BRASS, {round = 0.4})
	end
	k.rect(0.5, 0.72, 0.18, 0.3, COPPER)
	for i = 0, 2 do
		k.circle(0.45 + i * 0.05, 0.48, 0.02, B)
	end
	P.star(k, 0.5, 0.2, 0.14, W)
end
A["Gear Grinder"] = function(k, rng)
	-- a hero running on a giant spinning cog, sparks flying
	k.sky(rgb(70, 50, 40), rgb(160, 110, 70))
	gearIcon(k, 0.5, 0.7, 0.7)
	P.person(k, 0.5, 0.36, 0.5, rgb(80, 120, 200), rgb(230, 190, 160), rgb(70, 55, 45))
	for _ = 1, 8 do
		k.circle(rng:NextNumber(0.2, 0.8), rng:NextNumber(0.3, 0.5), 0.015, rgb(255, 200, 80))
	end
end
A["Clockwork Clash"] = function(k, rng)
	-- two clockwork knights duelling on the face of a clock tower
	k.sky(rgb(120, 90, 140), rgb(230, 170, 120))
	k.circle(0.5, 0.45, 0.7, rgb(240, 230, 200))
	k.circle(0.5, 0.45, 0.66, rgb(250, 245, 225))
	k.rect(0.5, 0.33, 0.015, 0.24, B)
	k.rect(0.58, 0.45, 0.16, 0.015, B)
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.28, 0.72, 0.1, 0.2, s < 0 and BRASS or COPPER, {round = 0.2})
		k.circle(0.5 + s * 0.28, 0.58, 0.07, s < 0 and BRASS or COPPER)
		k.rect(0.5 + s * 0.18, 0.62, 0.15, 0.015, rgb(220, 225, 235), {rot = -s * 30})
	end
end
A["Zeppelin Zoom"] = function(k, rng)
	-- a racing zeppelin with rocket thrusters streaking past
	skies(k, rng, rgb(120, 190, 250), rgb(230, 240, 255))
	airship(k, 0.55, 0.45, 1.3, rgb(230, 60, 60))
	k.ellipse(0.2, 0.45, 0.16, 0.08, rgb(255, 170, 40))
	for i = 0, 3 do
		k.rect(0.12, 0.35 + i * 0.06, 0.16, 0.01, W, {t = 0.3})
	end
end
A["Aerostat Ace"] = function(k, rng)
	-- a goggled pilot saluting from a hot-air balloon basket
	skies(k, rng)
	k.circle(0.5, 0.3, 0.42, rgb(255, 200, 60))
	for i = -1, 1 do
		k.rect(0.5 + i * 0.12, 0.3, 0.05, 0.4, rgb(230, 70, 60), {round = 0.5})
	end
	k.rect(0.5, 0.74, 0.18, 0.12, rgb(140, 90, 50))
	k.circle(0.5, 0.62, 0.08, rgb(230, 190, 160))
	k.rect(0.5, 0.6, 0.1, 0.025, BRASS)
end
A["Sky Captain Smash"] = function(k, rng)
	-- a captain at the wheel steering the ship straight through a storm
	k.sky(rgb(40, 50, 80), rgb(110, 120, 150))
	P.lightning(k, 0.8, 0.25, 0.8, rgb(255, 240, 150))
	k.circle(0.5, 0.65, 0.4, rgb(130, 80, 40))
	k.circle(0.5, 0.65, 0.3, rgb(40, 50, 80))
	for i = 0, 3 do
		k.rect(0.5, 0.65, 0.5, 0.025, rgb(150, 95, 50), {rot = i * 45})
	end
	k.circle(0.5, 0.65, 0.08, BRASS)
	P.person(k, 0.5, 0.42, 0.45, rgb(40, 60, 120), rgb(230, 190, 160), rgb(40, 40, 50))
end
A["Pilotwings Pro"] = function(k, rng)
	-- a pilot on brass mechanical wings gliding over a patchwork landscape
	k.sky(rgb(120, 200, 255), rgb(200, 240, 200))
	for i = 0, 5 do
		k.rect(0.1 + i * 0.16, 0.88, 0.16, 0.2, ({rgb(120, 190, 90), rgb(200, 190, 100), rgb(90, 160, 80)})[i % 3 + 1])
	end
	for _, s in ipairs({-1, 1}) do
		k.rect(0.5 + s * 0.2, 0.4, 0.34, 0.06, BRASS, {rot = s * -10, round = 0.4})
	end
	P.person(k, 0.5, 0.48, 0.45, rgb(140, 75, 45), rgb(230, 190, 160), rgb(90, 70, 55))
end
A["Star Fax"] = function(k, rng)
	-- a fox pilot's biplane delivering a fax through the stars
	k.sky(rgb(20, 20, 60), rgb(90, 60, 140))
	k.stars(20, rng, 0.9)
	k.rect(0.5, 0.5, 0.36, 0.08, rgb(220, 220, 230), {round = 0.4})
	k.rect(0.5, 0.42, 0.5, 0.03, rgb(240, 120, 40))
	k.rect(0.5, 0.58, 0.5, 0.03, rgb(240, 120, 40))
	k.circle(0.45, 0.46, 0.06, rgb(240, 140, 60))
	k.rect(0.8, 0.3, 0.12, 0.15, W, {rot = 15})
end
A["Ace Combat Wombat"] = function(k, rng)
	-- a wombat in a flying helmet dogfighting in a tiny brass plane
	skies(k, rng, rgb(150, 210, 255), rgb(240, 245, 255))
	k.rect(0.5, 0.5, 0.4, 0.1, rgb(80, 120, 70), {round = 0.4, rot = -10})
	k.rect(0.5, 0.5, 0.08, 0.36, rgb(80, 120, 70), {rot = -10})
	k.circle(0.48, 0.42, 0.1, rgb(140, 110, 80))
	k.rect(0.48, 0.38, 0.12, 0.03, BRASS)
	for i = 0, 3 do
		k.rect(0.15, 0.4 + i * 0.05, 0.14, 0.01, W, {t = 0.3})
	end
end

return A

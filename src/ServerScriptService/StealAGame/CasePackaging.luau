--[[
	CasePackaging
	Every game is a boxed release for one of six made-up consoles. This dresses the case Part: its plastic, the front
	cover (the GamePoster art under the console's header band), its own back cover and the spines.

	The back is designed for the game, not cut from the front: a tagline, two gameplay screenshots drawn for its genre
	(a platformer level with a score, a race with a lap counter, fighters under health bars...), a short description,
	three feature callouts, player info, a rating badge, the publisher line and a barcode.

	Ratings use a made-up board ("GRB") and every back says it's a parody release, so nothing claims a real rating,
	console or publisher.

	CasePackaging.size(name) -> Vector3       the case's size for its console
	CasePackaging.plastic(name, hidden) -> Color3
	CasePackaging.dress(item, rec, hidden)    (re)builds the front, back and spines
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))

local CP = {}
local rgb = Color3.fromRGB
local W, B = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local F = Enum.Font

------------------------------------------------------------------
-- CONSOLES: the case's size and plastic, the cover's header band and mark, the back's paper insert
------------------------------------------------------------------
local PLATFORMS = {
	NOVA = {Mark = "NOVA", Sub = "STATION", Font = F.GothamBlack, Plastic = rgb(20, 20, 26), Band = rgb(28, 74, 196), Ink = W,
		Paper = rgb(14, 18, 34), Text = W, Muted = rgb(160, 175, 215), Accent = rgb(90, 160, 255), Size = Vector3.new(3.6, 4.6, 0.6), Code = "NVS"},
	XENO = {Mark = "XENO", Sub = "ONE", Font = F.Sarpanch, Plastic = rgb(18, 96, 38), Band = rgb(16, 124, 16), Ink = W,
		Paper = rgb(12, 20, 14), Text = W, Muted = rgb(160, 200, 165), Accent = rgb(110, 220, 90), Size = Vector3.new(3.6, 4.6, 0.6), Code = "XNO"},
	SWITCHBACK = {Mark = "SWITCHBACK", Sub = "", Font = F.GothamBlack, Plastic = rgb(205, 22, 32), Band = rgb(232, 0, 18), Ink = W,
		Paper = rgb(248, 248, 250), Text = rgb(30, 30, 36), Muted = rgb(100, 100, 112), Accent = rgb(225, 20, 35), Size = Vector3.new(3.3, 4.4, 0.45), Code = "SWB"},
	RETRO = {Mark = "RETRO-8", Sub = "ENTERTAINMENT SYSTEM", Font = F.Arcade, Plastic = rgb(70, 70, 76), Band = rgb(22, 22, 26), Ink = rgb(235, 60, 60),
		Paper = rgb(18, 18, 22), Text = W, Muted = rgb(180, 180, 190), Accent = rgb(235, 60, 60), Size = Vector3.new(3.8, 4.6, 0.85), Code = "R8", Stripes = true},
	PC = {Mark = "PC", Sub = "DVD-ROM", Font = F.Michroma, Plastic = rgb(46, 50, 60), Band = rgb(70, 76, 90), Ink = W,
		Paper = rgb(24, 26, 32), Text = W, Muted = rgb(170, 176, 190), Accent = rgb(255, 170, 40), Size = Vector3.new(3.8, 4.8, 0.7), Code = "PCD"},
	POCKET = {Mark = "POCKET", Sub = "PLAY", Font = F.FredokaOne, Plastic = rgb(232, 236, 244), Band = rgb(40, 168, 250), Ink = W,
		Paper = rgb(250, 251, 255), Text = rgb(30, 34, 48), Muted = rgb(100, 108, 128), Accent = rgb(30, 150, 240), Size = Vector3.new(3.1, 4.1, 0.4), Code = "PKT"},
}

-- made-up publishers, one per poster family
local PUBLISHER = {
	Arcade = "Bitwise Arcade Co.", Ninja = "Kumo Interactive", Haunted = "Hollow Lantern Games", Robots = "Ironclad Works",
	Toys = "Toybox Studios", Cyber = "Neon Circuit", Pirate = "Saltwater Games", Space = "Far Orbit Studios",
	Dragon = "Ember Crown Games", Bargain = "Bargain Bin Software",
}
-- when a game has no row of its own below
local FAMILY_DEFAULT = {
	Arcade = {"RETRO", "E", "platformer"}, Ninja = {"NOVA", "T", "fighting"}, Haunted = {"PC", "M", "horror"}, Robots = {"XENO", "T", "mech"},
	Toys = {"SWITCHBACK", "E", "party"}, Cyber = {"PC", "T", "shooter"}, Pirate = {"XENO", "T", "sea"}, Space = {"NOVA", "T", "space"},
	Dragon = {"NOVA", "T", "rpg"}, Bargain = {"POCKET", "E", "party"},
}

local RATING_NAME = {E = "EVERYONE", ["E10+"] = "EVERYONE 10+", T = "TEEN", M = "MATURE 17+"}
-- the small print under the badge, from the rating and what kind of game it is
local function descriptor(rating, genre)
	if rating == "M" then
		if genre == "horror" then return "Blood and Gore, Intense Violence" end
		if genre == "shooter" or genre == "mech" then return "Blood, Violence, Strong Language" end
		return "Blood, Violence"
	elseif rating == "T" then
		if genre == "horror" then return "Fantasy Violence, Frights" end
		if genre == "fighting" then return "Violence, Mild Blood" end
		return "Fantasy Violence"
	elseif rating == "E10+" then
		if genre == "shooter" then return "Cartoon Violence" end
		return "Fantasy Violence, Comic Mischief"
	end
	return "Comic Mischief"
end

local function hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

------------------------------------------------------------------
-- SCREENSHOTS: a gameplay scene per genre, in the game's own colours. k is GamePoster's drawing kit (positions are
-- centres in 0-1 of the panel; circle sizes are 0-1 of its width). Panels are wide: height is AR of the width.
------------------------------------------------------------------
local AR = 0.45
local function sq(k, x, y, d, c, o)
	return k.rect(x, y, d, d / AR, c, o)
end
local function hud(k, x, y, w, h, s, c)
	return k.text(x, y, w, h, s, c or W, {stroke = true, font = F.GothamBlack})
end
local function meter(k, x, y, w, frac, c)
	k.rect(x, y, w, 0.07, rgb(15, 15, 20), {t = 0.15})
	k.rect(x - w / 2 + w * frac / 2, y, w * frac, 0.05, c)
end
local function person(k, x, y, s, body, head)
	k.rect(x, y, 0.045 * s, 0.22 * s, body, {round = 0.4})
	k.circle(x, y - 0.17 * s, 0.045 * s, head or rgb(255, 210, 170))
end
local function car(k, x, y, s, c)
	k.rect(x, y, 0.2 * s, 0.13 * s, c, {round = 0.35})
	k.rect(x, y - 0.08 * s, 0.11 * s, 0.09 * s, c:Lerp(W, 0.35), {round = 0.35})
	for _, dx in ipairs({-0.07, 0.07}) do
		k.circle(x + dx * s, y + 0.07 * s, 0.05 * s, rgb(20, 20, 24))
	end
end

local SCENES = {}
function SCENES.platformer(k, r, p)
	k.sky(p.light, p.a:Lerp(W, 0.55))
	for _ = 1, 2 do
		k.ellipse(r:NextNumber(0.1, 0.9), r:NextNumber(0.15, 0.35), 0.16, 0.12, W, {t = 0.1})
	end
	for x = 0.04, 1, 0.08 do
		sq(k, x, 0.93, 0.08, p.b:Lerp(B, 0.35))
		sq(k, x, 0.86, 0.08, rgb(90, 190, 80))
	end
	local px = r:NextNumber(0.4, 0.6)
	for i = 0, 3 do
		sq(k, px + i * 0.07, 0.52, 0.07, rgb(210, 140, 60))
	end
	for i = 0, 2 do
		k.circle(px + 0.03 + i * 0.07, 0.36, 0.035, rgb(255, 215, 40))
	end
	k.rect(0.9, 0.72, 0.1, 0.28, rgb(40, 170, 70))
	k.rect(0.9, 0.58, 0.12, 0.06, rgb(30, 140, 60))
	person(k, 0.2, 0.7, 1, p.a, rgb(255, 215, 175))
	k.ellipse(0.7, 0.77, 0.08, 0.1, rgb(150, 90, 50))
	hud(k, 0.17, 0.1, 0.3, 0.13, "SCORE " .. r:NextInteger(1, 99) .. "," .. r:NextInteger(100, 999))
	hud(k, 0.85, 0.1, 0.22, 0.13, "x" .. r:NextInteger(10, 99), rgb(255, 225, 80))
end
function SCENES.racing(k, r, p)
	k.sky(p.light, W)
	k.ellipse(0.25, 0.45, 0.7, 0.3, rgb(90, 170, 90))
	k.ellipse(0.8, 0.45, 0.6, 0.25, rgb(70, 150, 80))
	for i = 0, 5 do
		local w = 0.22 + i * 0.16
		k.rect(0.5, 0.52 + i * 0.09, w + 0.06, 0.095, i % 2 == 0 and rgb(230, 40, 40) or W)
		k.rect(0.5, 0.52 + i * 0.09, w, 0.095, rgb(64, 64, 72))
		k.rect(0.5, 0.52 + i * 0.09, 0.012 + i * 0.004, 0.05, W)
	end
	car(k, r:NextNumber(0.35, 0.45), 0.6, 0.6, p.b)
	car(k, 0.52, 0.86, 1.2, p.a)
	hud(k, 0.12, 0.12, 0.2, 0.18, "1ST", rgb(255, 215, 40))
	hud(k, 0.85, 0.1, 0.25, 0.12, "LAP " .. r:NextInteger(1, 3) .. "/3")
	hud(k, 0.85, 0.88, 0.25, 0.12, r:NextInteger(140, 280) .. " KM/H")
end
function SCENES.fighting(k, r, p)
	k.sky(p.a:Lerp(B, 0.5), p.b:Lerp(W, 0.2))
	k.ellipse(0.5, 0.55, 0.7, 0.5, p.light, {t = 0.6})
	k.rect(0.5, 0.92, 1.04, 0.18, p.dark)
	for _, s in ipairs({-1, 1}) do
		local c = s < 0 and p.a or p.b
		local x = 0.5 + s * 0.17
		k.rect(x, 0.66, 0.07, 0.36, c, {round = 0.3})
		k.circle(x, 0.42, 0.06, rgb(240, 200, 160))
		k.rect(x - s * 0.07, 0.6, 0.1, 0.04, c, {round = 0.5})
		meter(k, 0.5 + s * 0.27, 0.09, 0.38, r:NextNumber(0.3, 0.95), rgb(255, 210, 40))
	end
	k.circle(0.5, 0.58, 0.07, rgb(255, 240, 120), {t = 0.15})
	hud(k, 0.5, 0.11, 0.1, 0.16, tostring(r:NextInteger(10, 99)))
	hud(k, 0.5, 0.28, 0.3, 0.13, "ROUND " .. r:NextInteger(1, 3), rgb(255, 225, 80))
end
function SCENES.shooter(k, r, p)
	k.sky(p.a:Lerp(B, 0.65), p.b:Lerp(B, 0.35))
	k.rect(0.08, 0.5, 0.2, 1.04, p.dark)
	k.rect(0.92, 0.5, 0.2, 1.04, p.dark)
	k.rect(0.5, 0.9, 1.04, 0.22, p.dark:Lerp(B, 0.3))
	for i = 1, 2 do
		local x = r:NextNumber(0.35, 0.65)
		k.rect(x, 0.56, 0.05, 0.2, p.b:Lerp(B, 0.6), {round = 0.3})
		k.circle(x, 0.43, 0.03, p.b:Lerp(B, 0.5))
	end
	k.rect(0.8, 0.86, 0.22, 0.12, rgb(40, 42, 48), {rot = -12, round = 0.2})
	k.rect(0.7, 0.78, 0.14, 0.05, rgb(30, 32, 36), {rot = -12})
	for _, o in ipairs({{-0.03, 0}, {0.03, 0}, {0, -0.06}, {0, 0.06}}) do
		k.rect(0.5 + o[1], 0.5 + o[2], o[1] == 0 and 0.004 or 0.025, o[1] == 0 and 0.05 or 0.012, W)
	end
	k.circle(0.9, 0.15, 0.13, rgb(10, 10, 14), {t = 0.2})
	k.circle(0.9, 0.15, 0.02, rgb(255, 60, 60))
	meter(k, 0.17, 0.92, 0.26, r:NextNumber(0.4, 1), rgb(90, 230, 100))
	hud(k, 0.82, 0.92, 0.22, 0.12, r:NextInteger(5, 30) .. " / " .. r:NextInteger(60, 180))
end
function SCENES.mech(k, r, p)
	SCENES.shooter(k, r, p)
	-- the cockpit around the view
	k.rect(0.5, 0.03, 1.04, 0.1, rgb(30, 32, 38))
	k.rect(0.06, 0.5, 0.06, 1.04, rgb(30, 32, 38))
	k.rect(0.94, 0.5, 0.06, 1.04, rgb(30, 32, 38))
	k.rect(0.12, 0.12, 0.2, 0.04, rgb(30, 32, 38), {rot = 35})
	k.rect(0.88, 0.12, 0.2, 0.04, rgb(30, 32, 38), {rot = -35})
	hud(k, 0.5, 0.15, 0.2, 0.1, "HEAT " .. r:NextInteger(20, 90) .. "%", rgb(255, 160, 60))
end
function SCENES.horror(k, r, p)
	k.sky(rgb(8, 8, 12), rgb(24, 20, 26))
	k.rect(0.5, 0.9, 1.04, 0.22, rgb(18, 15, 18))
	k.rect(r:NextNumber(0.6, 0.75), 0.5, 0.18, 0.62, rgb(4, 4, 6))
	k.ellipse(0.42, 0.58, 0.6, 0.85, rgb(255, 238, 200), {t = 0.82})
	k.ellipse(0.42, 0.58, 0.32, 0.5, rgb(255, 238, 200), {t = 0.78})
	local fx = r:NextNumber(0.62, 0.72)
	k.rect(fx, 0.55, 0.05, 0.3, B, {round = 0.3})
	k.circle(fx, 0.36, 0.035, B)
	k.circle(fx - 0.008, 0.35, 0.008, rgb(255, 40, 40))
	k.circle(fx + 0.008, 0.35, 0.008, rgb(255, 40, 40))
	hud(k, 0.17, 0.9, 0.3, 0.1, "BATTERY " .. r:NextInteger(3, 40) .. "%", rgb(255, 90, 80))
end
function SCENES.rpg(k, r, p)
	k.sky(p.light, W)
	for i = 0, 2 do
		k.rect(0.15 + i * 0.3, 0.55, 0.3, 0.3 / AR * 0.5, rgb(130, 135, 150), {rot = 45})
	end
	k.rect(0.5, 0.82, 1.04, 0.4, rgb(90, 165, 80))
	local cx = r:NextNumber(0.68, 0.8)
	k.rect(cx, 0.55, 0.16, 0.3, rgb(170, 170, 180))
	for _, dx in ipairs({-0.07, 0.07}) do
		k.rect(cx + dx, 0.42, 0.05, 0.36, rgb(150, 150, 162))
		k.rect(cx + dx, 0.22, 0.06, 0.06, p.b)
	end
	person(k, 0.22, 0.72, 1, p.a)
	k.rect(0.27, 0.62, 0.012, 0.18, rgb(220, 225, 235), {rot = 30})
	k.ellipse(0.45, 0.8, 0.1, 0.12, p.b)
	meter(k, 0.16, 0.08, 0.26, r:NextNumber(0.5, 1), rgb(230, 60, 60))
	meter(k, 0.16, 0.17, 0.26, r:NextNumber(0.3, 1), rgb(70, 120, 255))
	k.rect(0.5, 0.92, 0.9, 0.14, rgb(14, 16, 36), {t = 0.1, round = 0.3})
	local lines = {"A wild foe appears!", "You found a rusty key.", "Quest updated.", "The gate is sealed..."}
	hud(k, 0.5, 0.92, 0.8, 0.1, lines[r:NextInteger(1, #lines)])
end
function SCENES.space(k, r, p)
	k.sky(rgb(4, 4, 14), p.a:Lerp(B, 0.6))
	k.stars(14, r, 0.95)
	k.circle(r:NextNumber(0.7, 0.85), 0.35, 0.3, p.b)
	local sx = r:NextNumber(0.3, 0.42)
	k.rect(sx, 0.62, 0.14, 0.08, rgb(220, 225, 235), {round = 0.4})
	k.rect(sx - 0.02, 0.72, 0.1, 0.04, p.a, {rot = 20})
	k.rect(sx - 0.02, 0.52, 0.1, 0.04, p.a, {rot = -20})
	for i = 1, 3 do
		k.rect(sx + 0.15 + i * 0.1, 0.62 - i * 0.03, 0.08, 0.015, rgb(120, 255, 200))
	end
	k.circle(0.6, 0.45, 0.12, W, {t = 0.85})
	meter(k, 0.17, 0.92, 0.26, r:NextNumber(0.3, 1), rgb(90, 200, 255))
	hud(k, 0.83, 0.92, 0.26, 0.11, "SHIELD " .. r:NextInteger(20, 100) .. "%", rgb(140, 220, 255))
end
function SCENES.runner(k, r, p)
	k.sky(p.light, W)
	for i = 0, 5 do
		local w = 0.24 + i * 0.16
		k.rect(0.5, 0.5 + i * 0.1, w, 0.1, rgb(150, 120, 90))
		for _, f in ipairs({-1 / 3, 1 / 3}) do
			k.rect(0.5 + f * w / 2, 0.5 + i * 0.1, 0.01, 0.1, rgb(110, 110, 120))
		end
	end
	k.rect(r:NextNumber(0.35, 0.65), 0.58, 0.14, 0.08, rgb(240, 200, 40), {round = 0.2})
	for i = 0, 3 do
		k.circle(0.5, 0.86 - i * 0.08, 0.025 - i * 0.004, rgb(255, 215, 40))
	end
	person(k, 0.5, 0.82, 1.2, p.a)
	hud(k, 0.5, 0.1, 0.3, 0.14, r:NextInteger(1, 9) .. "," .. r:NextInteger(100, 999) .. "m")
	hud(k, 0.88, 0.1, 0.2, 0.12, tostring(r:NextInteger(50, 999)), rgb(255, 215, 40))
end
function SCENES.adventure(k, r, p)
	k.sky(p.light, p.a:Lerp(W, 0.6))
	for i = 0, 6 do
		local h = r:NextNumber(0.25, 0.6)
		k.rect(i * 0.17, 1 - h / 2, 0.15, h, p.dark:Lerp(p.a, 0.2))
	end
	k.rect(0.5, 0.95, 1.04, 0.1, p.dark)
	person(k, 0.38, 0.75, 1.5, p.b)
	local mx = r:NextNumber(0.6, 0.8)
	k.rect(mx, 0.3, 0.035, 0.035 / AR, rgb(255, 215, 40), {rot = 45})
	hud(k, mx, 0.42, 0.12, 0.09, r:NextInteger(40, 400) .. "m", rgb(255, 225, 80))
	k.circle(0.1, 0.82, 0.14, rgb(10, 12, 18), {t = 0.25})
	k.circle(0.1, 0.82, 0.015, rgb(255, 215, 40))
end
function SCENES.party(k, r, p)
	k.sky(p.light, p.a:Lerp(W, 0.3))
	k.ellipse(0.5, 0.95, 1.2, 0.6, p.b:Lerp(W, 0.3))
	for i = 0, 4 do
		local c = Color3.fromHSV((i * 0.19 + r:NextNumber()) % 1, 0.6, 1)
		local x, y = 0.14 + i * 0.18, r:NextNumber(0.62, 0.78)
		k.ellipse(x, y, 0.09, 0.28, c)
		k.ellipse(x, y - 0.06, 0.06, 0.07, W)
	end
	for _ = 1, 12 do
		k.rect(r:NextNumber(), r:NextNumber(0, 0.5), 0.015, 0.04, Color3.fromHSV(r:NextNumber(), 0.7, 1), {rot = r:NextInteger(0, 90)})
	end
	hud(k, 0.5, 0.1, 0.18, 0.14, "0:" .. r:NextInteger(10, 59))
end
function SCENES.sim(k, r, p)
	k.sky(rgb(110, 180, 90), rgb(90, 160, 80))
	for gx = 0, 9 do
		k.rect(gx * 0.1 + 0.05, 0.6, 0.004, 1, W, {t = 0.75})
	end
	for gy = 0, 4 do
		k.rect(0.5, 0.2 + gy * 0.2, 1, 0.008, W, {t = 0.75})
	end
	for _ = 1, 6 do
		local x, y = r:NextInteger(1, 9) / 10 - 0.05, r:NextInteger(2, 4) / 5
		k.rect(x, y, 0.08, 0.15, Color3.fromHSV(r:NextNumber(), 0.35, 0.95), {round = 0.15})
		k.rect(x, y - 0.06, 0.08, 0.04, p.b:Lerp(B, 0.3))
	end
	k.rect(0.5, 0.75, 0.9, 0.02, rgb(70, 70, 80))
	k.rect(0.5, 0.06, 1.04, 0.12, rgb(20, 22, 30), {t = 0.1})
	hud(k, 0.2, 0.06, 0.3, 0.09, "$ " .. r:NextInteger(1, 99) .. "," .. r:NextInteger(100, 999), rgb(140, 255, 150))
	hud(k, 0.75, 0.06, 0.3, 0.09, "POP " .. r:NextInteger(50, 999))
end
function SCENES.puzzle(k, r, p)
	k.sky(rgb(14, 14, 26), p.a:Lerp(B, 0.6))
	k.rect(0.4, 0.5, 0.42, 1.04, rgb(8, 8, 14))
	for col = 0, 6 do
		local h = r:NextInteger(1, 4)
		for row = 0, h - 1 do
			sq(k, 0.22 + col * 0.06, 0.94 - row * 0.13, 0.055, Color3.fromHSV((col * 0.14 + 0.05) % 1, 0.7, 0.95))
		end
	end
	for i = 0, 2 do
		sq(k, 0.34 + i * 0.06, 0.25, 0.055, p.b)
	end
	sq(k, 0.4, 0.38, 0.055, p.b)
	k.rect(0.8, 0.3, 0.2, 0.36, rgb(20, 20, 32))
	hud(k, 0.8, 0.16, 0.16, 0.09, "NEXT")
	hud(k, 0.8, 0.7, 0.24, 0.12, "LINES " .. r:NextInteger(10, 99), p.light)
end
function SCENES.sandbox(k, r, p)
	k.sky(rgb(110, 175, 255), rgb(200, 230, 255))
	for col = 0, 12 do
		local h = r:NextInteger(2, 4)
		for row = 0, h do
			sq(k, col * 0.08 + 0.04, 0.96 - row * 0.18, 0.08, row == h and rgb(95, 170, 70) or rgb(130, 90, 55))
		end
	end
	local tx = r:NextNumber(0.6, 0.85)
	k.rect(tx, 0.4, 0.035, 0.3, rgb(110, 75, 40))
	sq(k, tx, 0.22, 0.14, rgb(50, 140, 50))
	person(k, 0.3, 0.38, 1, p.a, rgb(220, 170, 130))
	for i = 0, 7 do
		sq(k, 0.29 + i * 0.06, 0.92, 0.055, i == 2 and rgb(255, 255, 255) or rgb(40, 40, 46), {t = i == 2 and 0 or 0.2})
	end
end
function SCENES.sea(k, r, p)
	k.sky(p.light, rgb(255, 220, 180))
	k.waves(0.62, rgb(30, 110, 170), 0.12)
	k.rect(0.5, 0.88, 1.04, 0.3, rgb(20, 80, 140))
	local sx = r:NextNumber(0.3, 0.45)
	k.rect(sx, 0.62, 0.3, 0.12, rgb(110, 70, 40), {round = 0.4})
	k.rect(sx, 0.38, 0.015, 0.4, rgb(80, 50, 30))
	k.rect(sx - 0.05, 0.36, 0.14, 0.28, rgb(245, 240, 225))
	k.rect(sx + 0.02, 0.2, 0.05, 0.05, B)
	k.rect(0.8, 0.54, 0.12, 0.05, rgb(90, 60, 40))
	k.rect(0.8, 0.45, 0.06, 0.12, rgb(230, 225, 210))
	for i = 1, 3 do
		k.circle(sx + 0.18 + i * 0.05, 0.56 - i * 0.03, 0.04, rgb(200, 200, 205), {t = 0.3})
	end
	k.circle(0.9, 0.15, 0.12, rgb(240, 225, 190), {t = 0.1})
	hud(k, 0.9, 0.15, 0.05, 0.1, "N", rgb(150, 30, 30))
end
function SCENES.rhythm(k, r, p)
	k.sky(rgb(10, 6, 24), p.a:Lerp(B, 0.5))
	local lanes = {rgb(255, 70, 120), rgb(70, 200, 255), rgb(120, 255, 120), rgb(255, 210, 60)}
	for i, c in ipairs(lanes) do
		local x = 0.26 + (i - 1) * 0.16
		k.rect(x, 0.5, 0.13, 1.04, c, {t = 0.88})
		for _ = 1, 2 do
			k.rect(x, r:NextNumber(0.1, 0.7), 0.11, 0.08, c, {round = 0.3})
		end
		k.rect(x, 0.86, 0.13, 0.03, W, {t = 0.3})
	end
	hud(k, 0.5, 0.3, 0.3, 0.14, "PERFECT!", rgb(255, 230, 90))
	hud(k, 0.88, 0.1, 0.22, 0.12, "x" .. r:NextInteger(20, 300))
end
function SCENES.sports(k, r, p)
	k.sky(rgb(80, 160, 70), rgb(60, 140, 60))
	for i = 0, 4 do
		k.rect(0.1 + i * 0.2, 0.55, 0.1, 1.04, W, {t = 0.92})
	end
	k.rect(0.5, 0.55, 0.006, 0.9, W)
	k.ellipse(0.5, 0.55, 0.2, 0.4, W, {t = 0.75})
	for i = 1, 4 do
		k.circle(r:NextNumber(0.1, 0.45), r:NextNumber(0.3, 0.9), 0.035, p.a)
		k.circle(r:NextNumber(0.55, 0.9), r:NextNumber(0.3, 0.9), 0.035, p.b)
	end
	k.circle(r:NextNumber(0.4, 0.6), r:NextNumber(0.4, 0.7), 0.025, W)
	k.rect(0.5, 0.08, 0.5, 0.13, rgb(15, 15, 20), {t = 0.1})
	hud(k, 0.5, 0.08, 0.45, 0.1, "HOME " .. r:NextInteger(0, 4) .. " - " .. r:NextInteger(0, 4) .. " AWAY  " .. r:NextInteger(1, 90) .. "'")
end

------------------------------------------------------------------
-- EVERY GAME: console, rating, genre (picks its screenshots), players, tagline, description, three features.
-- Written for each game's original so the back reads like its real box would, with our parody names.
------------------------------------------------------------------
local GAMES = {}
local function G(name, platform, rating, genre, players, tag, desc, feats)
	GAMES[name] = {Platform = platform, Rating = rating, Genre = genre, Players = players, Tag = tag, Desc = desc, Features = string.split(feats, "|")}
end

-- Arcade
G("Super Mario Bruhs", "RETRO", "E", "platformer", "1-2 PLAYERS", "The pipes are calling, bruh.", "Run, jump and stomp through eight worlds of pipes, coins and grumpy mushrooms to rescue the princess.", "8 worlds|Hidden warp pipes|2-player turns")
G("The Legend of Zelma", "RETRO", "E", "rpg", "1 PLAYER", "It's dangerous to go alone.", "Explore an overworld of secret dungeons, gather the eight shards of the Triforks and save the kingdom.", "Open overworld|8 dungeons|Battery save")
G("Pocketmon Red", "POCKET", "E", "rpg", "1 PLAYER • LINK TRADING", "Gotta catch 'em. Apparently.", "Catch, train and trade 151 pocket critters on your way to becoming the regional champion.", "151 critters|8 gym badges|Trade with friends")
G("Sweet Fighter II", "RETRO", "T", "fighting", "1-2 PLAYERS VERSUS", "Round one. Sugar rush!", "Eight world warriors trade special moves and sticky combos in the ultimate arcade tournament.", "8 fighters|Special moves|2-player versus")
G("Monkey Kong", "RETRO", "E", "platformer", "1-2 PLAYERS", "He's got barrels. You've got a hammer.", "Climb the girders, leap the rolling barrels and rescue the girl at the top of the building site.", "4 classic stages|Hammer power-up|High-score table")
G("Galagoo", "RETRO", "E", "space", "1-2 PLAYERS", "They come in waves. Of goo.", "Blast swooping alien swarms before they capture your ship, then win it back for double the firepower.", "Dual-ship mode|Challenge stages|Endless waves")
G("Sanic the Hedgehog", "RETRO", "E", "platformer", "1 PLAYER", "Gotta go way too fast.", "Spin-dash through loops, springs and ring-filled zones at speeds no hedgehog should legally reach.", "7 zones|Chaos gems|Speed shoes")
G("Castlevanilla", "RETRO", "T", "platformer", "1 PLAYER", "Die, monster. Then have dessert.", "Whip your way through a haunted castle of skeletons, bats and one very dramatic count.", "6 castle blocks|Sub-weapons|Boss gauntlet")
G("Metro-Void", "RETRO", "E10+", "platformer", "1 PLAYER", "Alone on a planet that wants you gone.", "Explore a maze of alien caverns, collect upgrades and open the way to the creature at the core.", "Huge connected map|Morph ball|Secret endings")
G("Space Raiders", "RETRO", "E", "space", "1-2 PLAYERS", "Defend the earth. Row by row.", "Hold the line as the invaders march lower and faster. Hide behind your bunkers while they last.", "Arcade classic|Mystery ship|2-player turns")
G("Froggo", "RETRO", "E", "runner", "1-2 PLAYERS", "Why did the frog cross the road?", "Hop across a busy highway and a log-filled river to bring five frogs safely home.", "Timed levels|Lily-pad homes|Arcade classic")
G("Mega Dan", "RETRO", "E", "platformer", "1 PLAYER", "Beat the boss. Take his power.", "Choose your stage, defeat eight robot masters and turn every weapon you win against the next.", "8 robot masters|Weapon swapping|Password saves")
G("Prance Prance Revolution", "NOVA", "E", "rhythm", "1-2 PLAYERS • DANCE MAT", "Feet first. Rhythm second.", "Step on the arrows in time with the music and chase a perfect combo across over fifty tracks.", "50+ songs|Dance mat support|Workout mode")
G("Mortal Wombat", "RETRO", "M", "fighting", "1-2 PLAYERS VERSUS", "Finish him. Gently.", "Seven marsupial warriors battle in a tournament of secret moves, hidden fighters and outrageous finishers.", "7 fighters|Secret moves|Tournament mode")
G("Crash Bandicoop", "NOVA", "E10+", "platformer", "1 PLAYER", "Spin first. Ask questions later.", "Spin through jungles, temples and boulder chases to stop a mad scientist and his animal army.", "30 levels|Gem hunting|Bonus rounds")

-- Ninja
G("Ghost of Sushima", "NOVA", "M", "adventure", "1 PLAYER", "Honour. Rice. Revenge.", "Ride across a beautiful island as a lone samurai, using steel and stealth to drive out the invaders.", "Open-world island|Standoff duels|Photo mode")
G("Ninja Garden", "XENO", "M", "fighting", "1 PLAYER", "The hardest garden you'll ever tend.", "A master ninja cuts through demons and rival clans in lightning-fast, merciless sword combat.", "Fast combo combat|Brutal bosses|Master difficulty")
G("Root Ninja", "POCKET", "E", "party", "1 PLAYER", "Slice. Splat. Repeat.", "Swipe through flying fruit for big combos and bigger scores. Just never, ever slice a bomb.", "Classic & arcade modes|Combo slicing|New blades")
G("Sekiwo: Shadows Die Thrice", "NOVA", "M", "fighting", "1 PLAYER", "Die. Learn. Die slightly better.", "A shinobi with a prosthetic arm hunts the warlord who took his master, one perfect deflect at a time.", "Posture combat|Grappling hook|Resurrection")
G("Shadow Bite 2", "POCKET", "T", "fighting", "1 PLAYER", "Fight the shadows. Bite back.", "A silhouette warrior battles through dojos and demon bosses, upgrading weapons and armour as he goes.", "Physics fighting|Weapon upgrades|Boss battles")
G("Naru-toe Storm", "NOVA", "T", "fighting", "1-2 PLAYERS", "Believe it. Probably.", "Unleash ninja jutsu in fast 3D battles featuring dozens of fighters from the hidden village.", "40+ ninjas|Team jutsu|Story mode")
G("Okamee", "SWITCHBACK", "T", "adventure", "1 PLAYER", "Paint the world back to life.", "As a white wolf goddess, use a celestial brush to bloom flowers, summon wind and banish the darkness.", "Celestial brush|Ink-wash art|Epic journey")
G("Gemshin Impact", "PC", "T", "rpg", "1 PLAYER • ONLINE CO-OP", "Seven nations. Infinite gacha.", "Explore a vast fantasy world, combine elemental powers and recruit a growing team of heroes.", "Elemental combat|Open world|4-player co-op")
G("Cooking Mamma", "SWITCHBACK", "E", "party", "1-2 PLAYERS", "Don't worry. Mamma will fix it!", "Chop, stir and fry your way through dozens of recipes in quick motion-control mini-games.", "75 recipes|Motion controls|Mamma's approval")
G("Total Bore: Shogun", "PC", "T", "sim", "1 PLAYER • ONLINE", "Unite Japan. Slowly.", "Command vast samurai armies on the battlefield and outwit rival clans on the campaign map.", "Real-time battles|Turn-based campaign|Clan diplomacy")
G("Samurai Slowdown", "RETRO", "T", "fighting", "1-2 PLAYERS", "Draw your blade. Take your time.", "Sword duels where one clean strike can end the round. Patience wins.", "12 swordsmen|Rage meter|Weapon clashes")
G("Ni-Oh No", "NOVA", "M", "fighting", "1 PLAYER • ONLINE CO-OP", "Yokai everywhere. Oh no.", "A sailor-turned-samurai fights demons across war-torn Japan with stances, spirits and stolen loot.", "Stance combat|Guardian spirits|Online co-op")
G("Tekkon 8", "XENO", "T", "fighting", "1-2 PLAYERS • ONLINE", "The king of iron fists returns.", "Juggle combos, heat moves and breakable stages in the next round of the iron fist tournament.", "32 fighters|Heat system|Online ranked")
G("Super Smush Bros", "SWITCHBACK", "E10+", "fighting", "1-8 PLAYERS", "Everyone is here. Again.", "Knock your friends off the stage with an enormous cast of fighters, items and chaotic arenas.", "80+ fighters|8-player smash|Spirit mode")
G("Splatune", "SWITCHBACK", "E10+", "shooter", "1-8 PLAYERS • ONLINE", "Stay fresh. Stay inky.", "Ink the most turf to win colourful team battles, then swim through your own colour to escape.", "4v4 turf war|Ink swimming|Salmon run")

-- Haunted
G("Resident Weevil", "NOVA", "M", "horror", "1 PLAYER", "Welcome to survival horror. And bugs.", "Trapped in a mansion overrun by mutant weevils, scrape together ammo, herbs and courage to escape.", "Classic horror|Puzzle mansion|Limited saves")
G("Ghostdusters", "XENO", "T", "shooter", "1-4 PLAYERS", "Who you gonna call? Them.", "Strap on a proton pack and wrangle ghosts across New York before the whole city gets slimed.", "Proton packs|Ghost trapping|4-player co-op")
G("Luigo's Mansion", "SWITCHBACK", "E", "horror", "1-2 PLAYERS", "Scaredy-cat. Ghost vacuum.", "A nervous plumber explores a haunted mansion, sucking up ghosts with a souped-up vacuum cleaner.", "Ghost vacuum|Floor-by-floor puzzles|Co-op mode")
G("Phasmophonia", "PC", "T", "horror", "1-4 PLAYERS ONLINE", "Say its name. Then run.", "Investigate haunted houses with your team, gather evidence and identify the ghost before it hunts.", "Voice recognition|Ghost evidence|4-player co-op")
G("Dead by Midnight", "XENO", "M", "horror", "1-5 PLAYERS ONLINE", "Four survivors. One killer. No dawn.", "Repair generators and escape, or play the killer hunting four survivors through the fog.", "4v1 online|Dozens of killers|Perk builds")
G("Little Nightmarez", "SWITCHBACK", "T", "horror", "1 PLAYER", "Small girl. Big hungry world.", "Sneak through a grotesque underwater resort full of giant guests in a tiny yellow raincoat.", "Stealth puzzles|Hand-crafted world|Unsettling chefs")
G("Left 4 Bread", "PC", "M", "shooter", "1-4 PLAYERS • ONLINE", "The infected want your sandwich.", "Fight across a zombie apocalypse with three friends as the AI Director throws hordes at your team.", "4-player co-op|AI Director|Versus mode")
G("Pants vs. Zombies", "POCKET", "E10+", "sim", "1 PLAYER", "Plant. Defend. Snack.", "Grow a garden of zombie-zapping plants to stop the shuffling undead from reaching your house.", "49 plants|Lawn defence|Zen garden")
G("Dying Lite", "XENO", "M", "adventure", "1-4 PLAYERS", "Good night. Good luck.", "Parkour across a quarantined city by day. By night, the things in the dark come out to hunt.", "Free-running|Day and night|4-player co-op")
G("Silent Bill", "NOVA", "M", "horror", "1 PLAYER", "The fog never lifts.", "Search a fog-drowned town for your missing daughter as the sirens sound and the world rusts away.", "Psychological horror|Radio static|Multiple endings")
G("Outpast", "PC", "M", "horror", "1 PLAYER", "You can run. You can hide. You can't fight.", "Armed only with a night-vision camera, uncover the secrets of a remote asylum. Batteries not included.", "Night-vision camera|No weapons|Found footage")
G("Amnesiac", "PC", "M", "horror", "1 PLAYER", "Remember nothing. Fear everything.", "Wake in a dark castle with no memory. Don't look at the monsters, and stay out of the dark.", "Sanity system|Physics puzzles|Lantern oil")
G("Vampire Thrivers", "PC", "T", "party", "1-4 PLAYERS LOCAL", "Survive thirty minutes. Then more.", "Wade through endless monster swarms as your weapons evolve into screen-filling chaos.", "Weapon evolutions|Endless waves|Local co-op")
G("Floodborne", "NOVA", "M", "horror", "1 PLAYER • ONLINE", "Fear the old blood. And the water.", "A hunter stalks the cursed streets of a gothic city, trading blows with beasts in vicious combat.", "Trick weapons|Gothic city|Chalice dungeons")
G("Vampurr", "XENO", "M", "rpg", "1 PLAYER", "A doctor. A vampire. A cat?", "A newly-turned vampire doctor must choose who to save and who to feed on in a plague-struck city.", "Choices matter|Feeding system|Gothic London")

-- Robots
G("Titanfail", "XENO", "M", "mech", "1 PLAYER • ONLINE 2-12", "Stand by for Titanfall. Mostly fall.", "Wall-run as an agile pilot, then call your giant Titan down from orbit to crush the opposition.", "Wall-running|Drop-in Titans|12-player online")
G("Armored Chore", "NOVA", "T", "mech", "1 PLAYER • ONLINE", "Build the mech. Do the chores.", "Assemble a combat mech from hundreds of parts and take on mercenary jobs across a ruined world.", "Mech building|Boss fights|Online arena")
G("Mechworrier", "PC", "T", "mech", "1 PLAYER • ONLINE", "Big robots. Big worries.", "Pilot towering battle mechs and manage your heat and your mercenary company in tactical campaigns.", "Heat management|Mercenary career|Online lances")
G("Fractorio", "PC", "E", "sim", "1 PLAYER • ONLINE CO-OP", "The factory must grow.", "Crash land, mine resources and automate everything into a sprawling factory that can launch a rocket.", "Total automation|Train networks|Online co-op")
G("Satisfactoree", "PC", "E10+", "sim", "1-4 PLAYERS ONLINE", "Build it bigger. Satisfyingly.", "Build a multi-storey factory on an alien planet with conveyors, trucks and very long belts.", "First-person building|Alien planet|4-player co-op")
G("Bioshocked", "XENO", "M", "shooter", "1 PLAYER", "Would you kindly buy this game?", "Explore an underwater city gone mad, mixing plasmid powers and guns against its broken inhabitants.", "Plasmid powers|Underwater city|Moral choices")
G("Transforkers", "XENO", "T", "mech", "1 PLAYER • ONLINE", "More than meets the fork.", "Transform from robot to vehicle mid-battle in the war for a mechanical home planet.", "Robot-vehicle swaps|Campaign|Online battles")
G("Gundumb Breaker", "NOVA", "T", "mech", "1-2 PLAYERS", "Build. Break. Build better.", "Break enemy suits apart, collect their parts and build your ultimate custom mobile suit.", "Part collecting|Custom builds|Co-op missions")
G("Pacific Rimm", "XENO", "T", "fighting", "1-2 PLAYERS", "To fight monsters, we built monsters.", "Pilot a giant robot in brutal one-on-one fights against city-sized sea monsters.", "Giant robots|Monster battles|Two-pilot co-op")
G("Detroit: Become Toaster", "NOVA", "M", "adventure", "1 PLAYER", "Your choices. Your toast.", "Three androids. One city. Every decision branches the story toward revolution, or burnt bread.", "Branching story|Multiple endings|Story flowchart")
G("Nearly: Automata", "NOVA", "M", "fighting", "1 PLAYER", "Glory to mankind. Nearly.", "Android soldiers fight machines in a ruined world, switching between swordplay and bullet hell.", "Fast action|Multiple endings|Pod support")
G("The Taco Principle", "PC", "E10+", "puzzle", "1 PLAYER", "Think. Therefore taco.", "Solve beautiful first-person laser puzzles while a mysterious voice asks what you really are.", "120+ puzzles|Philosophy|Hidden stars")
G("Mass Defect", "XENO", "M", "rpg", "1 PLAYER", "Save the galaxy. Read the codex.", "Command an elite starship crew across the galaxy, recruiting squadmates and making galaxy-shaking choices.", "Squad combat|Dialogue wheel|Big choices")
G("Horizon Zero Yawn", "NOVA", "T", "adventure", "1 PLAYER", "Hunt machines. Take a nap.", "Hunt mechanical beasts across a lush post-apocalyptic world with a bow, traps and plenty of focus.", "Machine hunting|Open world|Override beasts")
G("The Mattress", "XENO", "T", "shooter", "1 PLAYER", "There is no spoon. Only springs.", "Bend the rules of a simulated reality with bullet-time kung fu and gravity-defying gunfights.", "Bullet time|Kung fu combat|Film tie-in")

-- Toys
G("Fall Toys", "SWITCHBACK", "E", "party", "1-60 PLAYERS ONLINE", "Stumble. Tumble. Crown.", "Sixty clumsy contestants race through wild obstacle shows until one bean takes the crown.", "60-player shows|Mini-games|Costumes")
G("Puppy Playtime", "PC", "T", "horror", "1 PLAYER", "Want to play with me?", "Explore an abandoned toy factory with a grab-pack while a very tall, very friendly toy follows you.", "Grab-pack puzzles|Abandoned factory|Chapter one")
G("Kirbo's Dream Land", "POCKET", "E", "platformer", "1 PLAYER", "Inhale the competition.", "A round pink hero inhales enemies, floats over gaps and saves Dream Land's food from a greedy king.", "Float & inhale|5 worlds|Extra mode")
G("Minecrate", "PC", "E10+", "sandbox", "1-8 PLAYERS ONLINE", "Mine the crates. Craft the crates.", "Survive the night, mine blocks and build anything you can imagine in an endless blocky world.", "Infinite worlds|Survival & creative|Online servers")
G("Blocko Galaxy Wars", "XENO", "E10+", "platformer", "1-2 PLAYERS CO-OP", "A long time ago, in a box far away.", "Smash and rebuild your way through the galaxy's greatest battles as plastic brick heroes.", "2-player co-op|Free play|Studs to collect")
G("Fortnut", "XENO", "T", "shooter", "1-100 PLAYERS ONLINE", "Drop in. Build up. Crack open.", "Drop onto the island with ninety-nine others, build forts in seconds and be the last nut standing.", "100-player battle|Instant building|Storm circle")
G("Bayblade Burst", "SWITCHBACK", "E10+", "party", "1-2 PLAYERS", "3, 2, 1, let it rip!", "Customise your spinning top, launch it into the stadium and burst your rival's blade apart.", "Custom tops|Burst finishes|Tournaments")
G("Super Donkey Ball", "SWITCHBACK", "E", "platformer", "1-4 PLAYERS", "Tilt the world. Mind the edge.", "Tilt the stage to roll a donkey in a ball to the goal, then play party games with three friends.", "100+ stages|Party games|4-player local")
G("Katamari Dramacy", "NOVA", "E", "party", "1-2 PLAYERS", "Roll it all up. Dramatically.", "Roll a sticky ball over everything from paperclips to skyscrapers to put the stars back in the sky.", "Roll anything|Giant king|Catchy soundtrack")
G("Five Nights at Teddy's", "PC", "T", "horror", "1 PLAYER", "Can you survive five nights?", "Watch the cameras, save your power and keep the doors shut. The animatronics move at night.", "Security cameras|Limited power|5 nights")
G("Plushmon Go", "POCKET", "E", "rpg", "1 PLAYER • ONLINE", "Walk outside. Catch plushies.", "Explore your real neighbourhood to find, catch and battle plush critters with friends nearby.", "Real-world map|Raids with friends|Daily walks")
G("Webkins Whirl", "PC", "E", "party", "1 PLAYER ONLINE", "Adopt. Dress up. Spin to win.", "Look after your plush pet's online twin, decorate its room and spin the wheel for daily prizes.", "Virtual pet|Room decorating|Daily wheel")
G("Cup Hat", "XENO", "E10+", "platformer", "1-2 PLAYERS", "Don't deal with the devil.", "Run and gun through a hand-drawn 1930s cartoon world, one brutally hard boss fight at a time.", "Hand-drawn art|Boss rush|2-player co-op")
G("Wayman Legends", "SWITCHBACK", "E10+", "platformer", "1-4 PLAYERS", "No arms. No legs. No problem.", "Run, punch and sing through gorgeous musical levels with up to four friends.", "Musical levels|4-player co-op|120 levels")
G("Little Big Plant", "NOVA", "E", "platformer", "1-4 PLAYERS", "Play. Create. Share.", "Guide a stitched sack hero through crafty worlds, then build and share levels of your own.", "Level creator|4-player co-op|Costumes")

-- Cyber
G("Cyberpunk 2078", "PC", "M", "shooter", "1 PLAYER", "The future. Just one year late.", "A mercenary with a chip in their head chases immortality through a sprawling neon megacity.", "Open city|Cyberware|Branching quests")
G("Ghostjogger", "PC", "M", "runner", "1 PLAYER", "One hit. One kill. One jog.", "Wall-run, slow time and slice through a cyberpunk tower where a single hit means starting over.", "One-hit kills|Wall-running|Speedrun times")
G("Deus Next", "PC", "M", "adventure", "1 PLAYER", "You didn't ask for this.", "Choose stealth, hacking or augmented force to unravel a global conspiracy, one level at a time.", "Multiple paths|Augmentations|Hacking")
G("Overwash", "XENO", "T", "shooter", "ONLINE 5V5", "The world could always use more heroes.", "Pick a hero, combine abilities with your team and push the payload in fast 5v5 matches.", "40+ heroes|Team abilities|Ranked play")
G("Valorent", "PC", "T", "shooter", "ONLINE 5V5", "Defy the limits. Plant the spike.", "Precise gunplay meets agent abilities in tense 5v5 tactical rounds.", "Tactical 5v5|Agent abilities|Ranked")
G("Portul", "PC", "E10+", "puzzle", "1-2 PLAYERS CO-OP", "The cake is... available?", "Solve physics puzzles with a gun that opens two linked portals, guided by a very polite killer AI.", "Portal gun|Co-op chambers|Cake")
G("Apex Legendz", "XENO", "T", "shooter", "ONLINE SQUADS OF 3", "Become a legend. Or a z.", "Squad up with two friends in a fast battle royale built around unique legends and smart pings.", "Squads of 3|Ping system|Legend abilities")
G("Half-Lite", "PC", "M", "shooter", "1 PLAYER", "Rise and shine, Mr. Freemoon.", "A physicist with a crowbar fights through an alien incursion at a secret desert research lab.", "Story shooter|Crowbar|Alien invasion")
G("Hallo", "XENO", "M", "shooter", "1-4 PLAYERS • SPLIT SCREEN", "Wake me when you need me.", "A super soldier fights an alien alliance across a mysterious ring world.", "Campaign co-op|Vehicles|Split-screen")
G("Watch Hogs", "NOVA", "M", "adventure", "1 PLAYER • ONLINE", "Everything is connected. Even the pigs.", "Hack an entire city's systems from your phone to hunt the people who wronged your family.", "City hacking|Open world|Online invasions")
G("Counter-Stroke", "PC", "M", "shooter", "ONLINE 5V5", "Terrorists win. Or do they?", "The classic team shooter: buy your gear, hold the bombsite and win the round.", "5v5 competitive|Economy rounds|Classic maps")
G("Dentistry", "XENO", "T", "shooter", "1-6 PLAYERS ONLINE", "Become legend. Floss daily.", "A guardian of the last city fights across the solar system for loot, raids and the Light.", "Loot shooter|6-player raids|PvP")
G("Hotline Maimi", "PC", "M", "shooter", "1 PLAYER", "Do you like hurting other people?", "A neon-soaked top-down rampage where every room is a puzzle and one hit kills you too.", "Top-down action|Animal masks|Synth soundtrack")
G("Beet Saber", "PC", "E10+", "rhythm", "1 PLAYER • VR", "Slice to the beat. Of beets.", "Slash flying blocks in the right direction to the rhythm of an energetic soundtrack in VR.", "VR rhythm|Custom songs|Leaderboards")
G("Geometry Splash", "POCKET", "E", "runner", "1 PLAYER", "Jump. Fly. Flip. Splash.", "Tap to jump and fly through rhythm-based obstacle courses that get punishingly hard.", "Rhythm platforming|Level editor|Online levels")

-- Pirate
G("Sea of Robbers", "XENO", "T", "sea", "1-4 PLAYERS ONLINE", "A pirate's life for thee.", "Crew a ship with friends, hunt treasure, fight skeletons and steal from other pirate crews.", "Shared world|Ship crews|Treasure hunting")
G("Assassin's Greed: Black Flag", "NOVA", "M", "sea", "1 PLAYER", "Pirates. Assassins. Greed.", "Sail the Caribbean as a pirate-turned-assassin, boarding ships and hunting for gold.", "Naval combat|Open sea|Freerunning")
G("Pirates of the Carrot-bean", "NOVA", "T", "adventure", "1-2 PLAYERS", "Yo ho, a veggie's life for me.", "Swashbuckle across cursed islands with a slippery captain in the game of the movies.", "Sword fights|Cursed crew|Island hopping")
G("Uncharred", "NOVA", "T", "adventure", "1 PLAYER", "Fortune favours the slightly burnt.", "A treasure hunter climbs, shoots and wisecracks through ancient ruins in search of a lost city.", "Cinematic action|Climbing|Treasure hunt")
G("Skull and Phones", "XENO", "T", "sea", "1-6 PLAYERS ONLINE", "Rise from the tides. Answer the phone.", "Build a fleet, plunder trade routes and take on rival captains across the Indian Ocean.", "Ship building|Online plunder|Fleets")
G("One Peace", "NOVA", "T", "fighting", "1-2 PLAYERS", "The great pirate era begins.", "Stretch, punch and storm through hordes of marines as a rubbery pirate captain and his crew.", "40+ pirates|Crew combos|Story log")
G("Subnaughtica", "PC", "E10+", "sandbox", "1 PLAYER", "Dive in. Don't look down.", "Crash on an ocean planet and survive by exploring, crafting and building bases beneath the waves.", "Underwater bases|Survival|Deep biomes")
G("Daft Raft", "PC", "T", "sandbox", "1-8 PLAYERS ONLINE", "One raft. Too many sharks.", "Survive on a tiny raft, hook floating debris and grow it into a floating fortress with friends.", "Raft building|Shark trouble|Online co-op")
G("Battleshrimp", "RETRO", "E", "puzzle", "1-2 PLAYERS", "You sank my shrimp!", "Call your shots across the grid and sink the enemy fleet before they find yours.", "Classic grid|Salvo mode|Pass and play")
G("Angry Parrots", "POCKET", "E", "party", "1 PLAYER", "Fling first. Squawk later.", "Launch furious parrots at wobbly towers to knock out the pigs who stole their crackers.", "Slingshot physics|Hundreds of levels|Three stars")
G("The Secret of Donkey Island", "PC", "E10+", "adventure", "1 PLAYER", "Look behind you! A three-headed donkey!", "Become a mighty pirate with wit, insults and a rubber chicken with a pulley in the middle.", "Point and click|Insult sword fights|Classic humour")
G("Sid Meier's Parrots!", "PC", "E10+", "sea", "1 PLAYER", "Plunder. Duel. Retire a legend.", "Sail the Spanish Main, duel rival captains and dance with governors' daughters in a pirate sandbox.", "Open seas|Sword duels|Treasure maps")
G("Pirate 102", "PC", "E10+", "rpg", "1 PLAYER ONLINE", "Class is in session, matey.", "A turn-based pirate adventure online, with a crew of companions and a parrot that won't shut up.", "Turn-based battles|Companions|Online world")
G("Port Royalty", "PC", "E", "sim", "1 PLAYER", "Trade like a pirate. Live like a king.", "Build a trading empire across Caribbean ports, protect your convoys and grow your colonies.", "Trade routes|Convoys|Colony building")
G("Sea Hogs", "PC", "T", "sea", "1 PLAYER", "Pigs can sail. Barely.", "Captain your own ship through a living Caribbean of merchants, navies and rival pirates.", "Ship captaincy|Ports to visit|Naval battles")

-- Space
G("No Man's Pie", "NOVA", "T", "space", "1-4 PLAYERS ONLINE", "18 quintillion planets. One pie.", "Explore an endless generated universe, build bases and fly between planets with no loading screens.", "Endless planets|Base building|Online co-op")
G("Starfeld", "XENO", "M", "space", "1 PLAYER", "Into the starfeld.", "Join a guild of explorers and chart a thousand planets in a sprawling space role-playing game.", "1000 planets|Ship building|Factions")
G("Star Bores", "NOVA", "T", "space", "1-4 PLAYERS", "A long, long, long time ago.", "Fight across a galaxy of starfighters, laser swords and very long speeches.", "Starfighter battles|Galactic campaign|Online squads")
G("Among Bus", "POCKET", "E10+", "party", "4-15 PLAYERS ONLINE", "One of us is the driver.", "Fix the bus with your crewmates, but watch out: one of them is an impostor.", "4-15 players|Impostor role|Emergency meetings")
G("Outer Mild", "PC", "E10+", "space", "1 PLAYER", "Twenty-two minutes. Again.", "Explore a solar system stuck in a time loop to uncover its mystery before the sun explodes.", "Time loop|Hand-made planets|Mystery")
G("Herbal Space Program", "PC", "E", "sim", "1 PLAYER", "Rocket science, but leafier.", "Design rockets from parts, launch your little crew into orbit and try very hard not to explode.", "Rocket building|Real physics|Career mode")
G("Bed Space", "XENO", "M", "horror", "1 PLAYER", "Cut off their limbs. And their sleep.", "An engineer stranded on a mining ship fights twisted creatures with repurposed tools.", "Strategic dismemberment|Zero gravity|Built-in HUD")
G("Hallo Infinite", "XENO", "T", "shooter", "1 PLAYER • ONLINE 4V4", "The soldier returns. Infinitely.", "Grapple across an open ring world and battle an alien army in the next super-soldier saga.", "Open ring world|Grapple shot|Free multiplayer")
G("Elite Dangerless", "PC", "E", "space", "1 PLAYER ONLINE", "Trade. Fight. Explore. Safely.", "Fly through a life-size galaxy as a trader, bounty hunter or explorer in your own ship.", "Real galaxy|Flight combat|Trading")
G("Super Marco Galaxy", "SWITCHBACK", "E", "platformer", "1-2 PLAYERS", "Jump between planets.", "Leap from tiny planet to tiny planet with gravity-bending jumps to rescue the princess.", "Gravity jumping|Planetoid levels|Co-star mode")
G("Ratchet & Crank", "NOVA", "E10+", "adventure", "1 PLAYER", "Bigger guns. Smaller wrench.", "A mechanic and his robot pal hop across galaxies with an arsenal of absurd weapons.", "Crazy weapons|Planet hopping|Weapon upgrades")
G("Metro-Void Prime", "SWITCHBACK", "T", "shooter", "1 PLAYER", "See the void from inside the visor.", "Scan, shoot and morph through alien ruins in first person from inside a bounty hunter's helmet.", "First-person exploring|Scan visor|Morph ball")
G("Grand Theft Avocado VI", "NOVA", "M", "adventure", "1 PLAYER • ONLINE", "Finally out. Ripe at last.", "Two criminals take on a sun-soaked state in the most anticipated open world ever. Finally.", "Open world|Two heroes|Online mode")
G("Half-Lite 3", "PC", "M", "shooter", "1 PLAYER", "It finally exists. Somehow.", "The crowbar is back and the resistance needs you once more. Nobody believed this box was real.", "The sequel|Gravity gun|Third time lucky")
G("Steal a Brainrut", "PC", "E10+", "party", "ONLINE MULTIPLAYER", "Steal it before they steal you.", "Grab the strangest brainruts in town, run them back to your base and defend them from thieves.", "Steal & defend|Base upgrades|Rare brainruts")
G("Devil May Nubs V", "XENO", "M", "fighting", "1 PLAYER", "Jackpot!", "Three demon hunters slash, shoot and style their way through a city overrun by a demonic tree.", "Style rankings|3 hunters|Devil trigger")

-- Dragon
G("The Elder Trolls: Skyrim", "XENO", "M", "rpg", "1 PLAYER", "Fus. Roh. Troll.", "The dragonborn returns to a frozen province to shout down dragons and do whatever else they like.", "Dragon shouts|Open world|Hundreds of quests")
G("Spyrow", "NOVA", "E", "platformer", "1 PLAYER", "Small dragon. Big flame.", "A little purple dragon charges and flames through magical worlds to free his frozen elders.", "Glide & charge|6 homeworlds|Gem hunting")
G("Dragon Quest-ion", "SWITCHBACK", "E10+", "rpg", "1 PLAYER", "Are you the hero? Question mark.", "A classic turn-based quest with slimes, a silent hero and a party you'll grow to love.", "Turn-based battles|Slimes|Classic quest")
G("Dark Soles", "XENO", "M", "rpg", "1 PLAYER • ONLINE", "Prepare to die. On your feet.", "Explore a dying kingdom of interlocking paths and deadly bosses where every death teaches you something.", "Punishing bosses|Interlocking world|Online messages")
G("Elden Ding", "NOVA", "M", "rpg", "1 PLAYER • ONLINE", "Rise, tarnished. Ding!", "Ride across a vast open land of demigods and dungeons to claim the throne as Elden Lord.", "Open world|Spirit summons|Mounted combat")
G("Monster Hunger", "SWITCHBACK", "T", "rpg", "1-4 PLAYERS ONLINE", "Hunt. Carve. Eat. Repeat.", "Track enormous monsters, carve their parts and craft better gear to hunt even bigger ones.", "Giant monsters|Gear crafting|4-player hunts")
G("Cod of War", "NOVA", "M", "fighting", "1 PLAYER", "Boy! Fetch the fish.", "A furious god and his son journey across the Norse realms with an axe that always comes back.", "Returning axe|Norse realms|Father and son")
G("How to Drain Your Dragon", "NOVA", "E10+", "adventure", "1-2 PLAYERS", "Train hard. Fly harder.", "Raise and race your own dragon across the islands of the north in the game of the movie.", "Dragon training|Flight races|Arena battles")
G("Dragon's Dog-ma", "NOVA", "M", "rpg", "1 PLAYER • ONLINE PAWNS", "Who's a good dragon?", "Hunt the dragon that stole your heart, with AI companions borrowed from other players' worlds.", "Pawn companions|Climb monsters|Open world")
G("Diablow", "PC", "M", "rpg", "1-4 PLAYERS ONLINE", "Stay a while and loot.", "Descend into hell with your class of choice and hack through demons for legendary loot.", "Loot chase|Class builds|4-player co-op")
G("Shades", "SWITCHBACK", "T", "fighting", "1 PLAYER", "Escape the underworld. Again.", "Battle out of the underworld with gifts from the gods in a roguelike where every death moves the story.", "Roguelike runs|Gifts of the gods|Story on death")
G("Bald Dude's Gate 3", "PC", "M", "rpg", "1-4 PLAYERS ONLINE", "Roll for initiative. And hair.", "Gather a party, roll the dice and shape the story in a deep turn-based fantasy adventure.", "Turn-based tactics|Party co-op|Huge choices")
G("World of Warcrafts", "PC", "T", "rpg", "ONLINE MMO", "Millions of players. One more quest.", "Choose a faction, raid dungeons with friends and level up in a massive online world.", "Massive online world|Raids|Two factions")
G("Final Fanta-sea", "NOVA", "T", "rpg", "1 PLAYER", "A final fantasy. Again.", "Spiky-haired heroes, giant swords and summoned beasts in an epic turn-based saga by the sea.", "Turn-based battles|Summons|Epic story")
G("The Twitcher 3", "XENO", "M", "rpg", "1 PLAYER", "Hunt monsters. Stream it.", "A monster hunter for hire searches a war-torn land for his adopted daughter. Also cards.", "Monster contracts|Open world|Card game")

-- Bargain
G("Pang", "RETRO", "E", "sports", "1-2 PLAYERS", "The original bounce.", "Two paddles. One square ball. Infinite rematches.", "Classic paddles|2-player|Bleep bloop")
G("Wee Sports Bowling", "SWITCHBACK", "E", "sports", "1-4 PLAYERS", "Strike a pose. Then a pin.", "Swing your remote to bowl, then try tennis, golf and boxing with the whole family.", "Motion controls|5 sports|4-player")
G("Marco Kart", "SWITCHBACK", "E", "racing", "1-4 PLAYERS • ONLINE 12", "Blue shells end friendships.", "Race wild tracks with drifts, power-ups and very unfair items in the classic kart racer.", "48 tracks|Battle mode|Online races")
G("Flappy Bard", "POCKET", "E", "runner", "1 PLAYER", "Tap. Flap. Cry.", "Guide a bard through gaps in the pipes, one tap at a time, forever.", "One-button play|High score|Pure pain")
G("Cookie Klicker", "PC", "E", "sim", "1 PLAYER", "Click the cookie.", "Click a giant cookie, buy grandmas and factories and watch the numbers get impossibly big.", "Idle progress|Upgrades|Golden cookies")
G("Temple Ruin", "POCKET", "E10+", "runner", "1 PLAYER", "Don't look back.", "Grab the idol and run for your life from the demon monkeys. Swipe to turn, jump and slide.", "Endless running|Power-ups|Daily challenges")
G("FIFO Soccer 98", "NOVA", "E", "sports", "1-2 PLAYERS", "First in. First out. Into the cup.", "Lead your nation through qualifying all the way to the cup in the classic football game.", "172 teams|Road to the cup|Indoor mode")
G("Golf With Your Foes", "PC", "E", "sports", "1-12 PLAYERS ONLINE", "Mini golf. Major grudges.", "Putt through wacky courses with up to twelve players. Hats and bumpers included.", "12-player online|Wacky courses|Custom hats")
G("Saleway Surfers", "POCKET", "E10+", "runner", "1 PLAYER", "Dash as far as you can.", "Run along the train tracks, dodge oncoming trains and escape the grumpy inspector and his dog.", "Endless runner|Hoverboards|World tour")
G("Rusty League", "XENO", "E", "sports", "1-8 PLAYERS ONLINE", "Football. With rockets.", "Drive rocket-powered cars into a giant ball and score aerial goals in fast online matches.", "Rocket cars|Ranked|Car customising")
G("Pac-Can", "RETRO", "E", "puzzle", "1-2 PLAYERS", "Waka waka can.", "Eat every dot in the maze and run from the four ghosts. Grab a power pellet to turn the tables.", "Classic maze|Power pellets|Fruit bonuses")
G("Tetrus", "POCKET", "E", "puzzle", "1-2 PLAYERS • LINK", "Every line counts.", "Rotate and drop falling blocks to clear lines in the world's most famous puzzle game.", "Marathon mode|Versus link|Music A")
G("Monopawly", "PC", "E", "party", "2-6 PLAYERS", "Do not pass go. Do not collect paws.", "Buy streets, build houses and bankrupt your friends in the classic board game, now with pets.", "2-6 players|House rules|Pet tokens")
G("Trollercoaster Tycoon", "PC", "E", "sim", "1 PLAYER", "Build the ride. Trap the guests.", "Design rollercoasters, run a theme park and keep your guests happy. Or don't.", "Coaster designer|Park management|Scenarios")
G("Animal Bossing", "SWITCHBACK", "E", "sim", "1 PLAYER • ONLINE", "Your island. Your loans.", "Move to a deserted island, decorate your home and pay off a very patient raccoon.", "Island life|Real-time seasons|Visit friends")

------------------------------------------------------------------
-- BUILDING THE CASE
------------------------------------------------------------------
function CP.info(name)
	local g = GAMES[name]
	if g then
		return g
	end
	local d = FAMILY_DEFAULT[GamePoster.family(name)] or {"NOVA", "E", "party"}
	return {Platform = d[1], Rating = d[2], Genre = d[3], Players = "1 PLAYER", Tag = name, Desc = "", Features = {}}
end
function CP.size(name)
	return PLATFORMS[CP.info(name).Platform].Size
end
function CP.plastic(name)
	return PLATFORMS[CP.info(name).Platform].Plastic
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end
local function label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = F.GothamBold
	t.TextColor3 = W
	for k, v in pairs(props) do
		t[k] = v
	end
	t.Parent = parent
	return t
end
local function round(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(r or 0.15, 0)
	c.Parent = f
	return f
end
local function stroke(f, color, thickness, t)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.Transparency = color, thickness or 1, t or 0
	s.Parent = f
	return s
end
local function surface(item, face, pps)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Poster"
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps
	sg.LightInfluence = 0.25
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = item
	return sg
end
local function luminance(c)
	return c.R * 0.3 + c.G * 0.59 + c.B * 0.11
end

local function palette(name)
	local hue = (hash(name) % 360) / 360
	return {a = Color3.fromHSV(hue, 0.6, 0.9), b = Color3.fromHSV((hue + 0.42) % 1, 0.55, 1),
		dark = Color3.fromHSV(hue, 0.45, 0.22), light = Color3.fromHSV((hue + 0.05) % 1, 0.22, 1)}
end

-- the console's little mark, drawn from shapes (no real console logos)
local function glyph(band, plat)
	local g = frame(band, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.03, 0.5), Size = UDim2.fromScale(0.1, 0.7), BackgroundTransparency = 1})
	Instance.new("UIAspectRatioConstraint").Parent = g
	local ink, code = plat.Ink, plat.Code
	local center = {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)}
	local function at(props)
		for k, v in pairs(center) do
			if props[k] == nil then
				props[k] = v
			end
		end
		return frame(g, props)
	end
	if code == "NVS" then
		stroke(round(at({Size = UDim2.fromScale(0.92, 0.92), BackgroundTransparency = 1}), 1), ink, 2)
		round(at({Size = UDim2.fromScale(0.36, 0.36), BackgroundColor3 = ink}), 1)
	elseif code == "XNO" then
		round(at({Size = UDim2.fromScale(1, 1), BackgroundColor3 = ink}), 1)
		for _, r in ipairs({45, -45}) do
			at({Size = UDim2.fromScale(0.2, 0.78), BackgroundColor3 = plat.Band, Rotation = r})
		end
	elseif code == "SWB" then
		round(at({Position = UDim2.fromScale(0.25, 0.5), Size = UDim2.fromScale(0.42, 1), BackgroundColor3 = ink}), 0.45)
		stroke(round(at({Position = UDim2.fromScale(0.75, 0.5), Size = UDim2.fromScale(0.36, 0.92), BackgroundTransparency = 1}), 0.45), ink, 2)
	elseif code == "R8" then
		for i = 0, 2 do
			at({Position = UDim2.fromScale(0.17 + i * 0.33, 0.5), Size = UDim2.fromScale(0.26, 0.42), BackgroundColor3 = ink})
		end
	elseif code == "PCD" then
		stroke(at({Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.9, 0.6), BackgroundTransparency = 1}), ink, 2)
		at({Position = UDim2.fromScale(0.5, 0.88), Size = UDim2.fromScale(0.44, 0.1), BackgroundColor3 = ink})
	else
		round(at({Size = UDim2.fromScale(0.56, 1), BackgroundColor3 = ink}), 0.25)
		round(at({Size = UDim2.fromScale(0.4, 0.62), BackgroundColor3 = plat.Band}), 0.15)
	end
end

-- the console's header band: its mark on the left, a small line of text on the right
local function header(parent, plat, pos, size, right)
	local band = frame(parent, {Position = pos, Size = size, BackgroundColor3 = W, ClipsDescendants = true})
	local gl = Instance.new("UIGradient")
	gl.Color = ColorSequence.new(plat.Band:Lerp(W, 0.18), plat.Band:Lerp(B, 0.18))
	gl.Rotation = 90
	gl.Parent = band
	if plat.Stripes then
		-- the racing stripes sit between the mark and the right-hand text, never under either
		for i = 0, 2 do
			frame(band, {Position = UDim2.fromScale(0.5 + i * 0.05, 0), Size = UDim2.fromScale(0.022, 1), BackgroundColor3 = plat.Ink, BackgroundTransparency = 0.3})
		end
	end
	glyph(band, plat)
	label(band, {Position = UDim2.fromScale(0.16, 0.14), Size = UDim2.fromScale(plat.Stripes and 0.32 or 0.46, 0.72), Text = plat.Mark, TextXAlignment = Enum.TextXAlignment.Left, Font = plat.Font, TextColor3 = plat.Ink})
	if right and right ~= "" then
		label(band, {Position = UDim2.fromScale(plat.Stripes and 0.66 or 0.6, 0.28), Size = UDim2.fromScale(plat.Stripes and 0.31 or 0.37, 0.46), Text = right, TextXAlignment = Enum.TextXAlignment.Right, Font = F.GothamBold, TextColor3 = plat.Ink})
	end
	return band
end

-- a made-up ratings board's badge: the letter on white over a black strip
local function ratingBadge(parent, props, rating, thin)
	local badge = frame(parent, props)
	badge.BackgroundColor3 = W
	stroke(badge, B, thin and 1 or 2)
	label(badge, {Position = UDim2.fromScale(0.06, 0.04), Size = UDim2.fromScale(0.88, 0.62), Text = rating, TextColor3 = B, Font = F.GothamBlack})
	local foot = frame(badge, {Position = UDim2.fromScale(0, 0.72), Size = UDim2.fromScale(1, 0.28), BackgroundColor3 = B})
	label(foot, {Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.8, 0.8), Text = "GRB", Font = F.GothamBlack})
	return badge
end

local function screenshot(parent, props, name, genre, variant)
	local panel = frame(parent, props)
	panel.BackgroundColor3 = B
	panel.ClipsDescendants = true
	local ok, err = pcall(SCENES[genre] or SCENES.party, GamePoster.makeKit(panel), Random.new(hash(name) + variant * 7919), palette(name))
	if not ok then
		warn("[CasePackaging] Screenshot for " .. name .. " failed: " .. tostring(err))
	end
	stroke(panel, W, 1, 0.35)
	return panel
end

local GENRE_NAME = {platformer = "PLATFORMER", racing = "RACING", fighting = "ACTION", shooter = "SHOOTER", mech = "MECH ACTION",
	horror = "HORROR", rpg = "ROLE-PLAYING", space = "SPACE", runner = "ENDLESS RUNNER", adventure = "ADVENTURE", party = "PARTY",
	sim = "STRATEGY & SIM", puzzle = "PUZZLE", sandbox = "SANDBOX", sea = "PIRATE ADVENTURE", rhythm = "RHYTHM", sports = "SPORTS"}

function CP.dress(item, rec, hidden)
	for _, child in ipairs(item:GetChildren()) do
		if child:IsA("SurfaceGui") and child.Name == "Poster" then
			child:Destroy()
		end
	end
	local name = rec.Name
	local g = CP.info(name)
	local plat = PLATFORMS[g.Platform]
	local posterInfo = hidden and {Name = name, Rarity = "???", Color = rgb(150, 150, 165)} or rec

	-- FRONT: the console band over the cover art, the rating sticker in the corner
	local front = surface(item, Enum.NormalId.Front, 50)
	frame(front, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = plat.Plastic})
	header(front, plat, UDim2.fromScale(0.05, 0.022), UDim2.fromScale(0.9, 0.1), plat.Sub)
	local art = frame(front, {Position = UDim2.fromScale(0.05, 0.135), Size = UDim2.fromScale(0.9, 0.84), BackgroundColor3 = B, ClipsDescendants = true})
	GamePoster.Create(posterInfo).Parent = art
	-- top right of the art, clear of the title
	ratingBadge(front, {Position = UDim2.fromScale(0.8, 0.148), Size = UDim2.fromScale(0.12, 0.105), ZIndex = 20}, g.Rating, true)
	-- the clear sleeve over the insert catching the light
	local sheen = frame(front, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = W, ZIndex = 30})
	local sg = Instance.new("UIGradient")
	sg.Rotation = 60
	sg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)})
	sg.Parent = sheen

	-- BACK: its own printed insert
	local back = surface(item, Enum.NormalId.Back, 100)
	pcall(function()
		back.MaxDistance = 70 -- small print: nobody can read it from further away anyway
	end)
	frame(back, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = plat.Plastic})
	local sheet = frame(back, {Position = UDim2.fromScale(0.05, 0.022), Size = UDim2.fromScale(0.9, 0.956), BackgroundColor3 = plat.Paper, ClipsDescendants = true})
	header(sheet, plat, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.07), GENRE_NAME[g.Genre] or "")
	local left = Enum.TextXAlignment.Left
	label(sheet, {Position = UDim2.fromScale(0.05, 0.085), Size = UDim2.fromScale(0.9, 0.065), Text = string.upper(g.Tag), Font = F.GothamBlack, TextColor3 = plat.Text, TextXAlignment = left})
	screenshot(sheet, {Position = UDim2.fromScale(0.05, 0.165), Size = UDim2.fromScale(0.9, 0.28)}, name, g.Genre, 1)
	screenshot(sheet, {Position = UDim2.fromScale(0.05, 0.46), Size = UDim2.fromScale(0.43, 0.15)}, name, g.Genre, 2)
	for i, f in ipairs(g.Features) do
		if i > 3 then break end
		local y = 0.468 + (i - 1) * 0.05
		frame(sheet, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.535, y + 0.018), Size = UDim2.fromScale(0.022, 0.016), BackgroundColor3 = plat.Accent, Rotation = 45})
		label(sheet, {Position = UDim2.fromScale(0.565, y), Size = UDim2.fromScale(0.4, 0.036), Text = f, Font = F.GothamBold, TextColor3 = plat.Text, TextXAlignment = left})
	end
	label(sheet, {Position = UDim2.fromScale(0.05, 0.63), Size = UDim2.fromScale(0.9, 0.12), Text = g.Desc, Font = F.GothamMedium, TextWrapped = true,
		TextColor3 = plat.Muted:Lerp(plat.Text, 0.45), TextXAlignment = left, TextYAlignment = Enum.TextYAlignment.Top})
	label(sheet, {Position = UDim2.fromScale(0.05, 0.765), Size = UDim2.fromScale(0.58, 0.033), Text = g.Players, Font = F.GothamBlack, TextColor3 = plat.Accent, TextXAlignment = left})
	frame(sheet, {Position = UDim2.fromScale(0.05, 0.808), Size = UDim2.fromScale(0.9, 0.003), BackgroundColor3 = plat.Muted, BackgroundTransparency = 0.5})
	-- footer: rating, small print, barcode
	ratingBadge(sheet, {Position = UDim2.fromScale(0.05, 0.825), Size = UDim2.fromScale(0.13, 0.115)}, g.Rating)
	label(sheet, {Position = UDim2.fromScale(0.21, 0.826), Size = UDim2.fromScale(0.38, 0.03), Text = RATING_NAME[g.Rating] or "", Font = F.GothamBlack, TextColor3 = plat.Text, TextXAlignment = left})
	label(sheet, {Position = UDim2.fromScale(0.21, 0.858), Size = UDim2.fromScale(0.38, 0.024), Text = descriptor(g.Rating, g.Genre), Font = F.GothamMedium, TextColor3 = plat.Muted, TextXAlignment = left})
	label(sheet, {Position = UDim2.fromScale(0.21, 0.892), Size = UDim2.fromScale(0.39, 0.05), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = F.Gotham, TextColor3 = plat.Muted, TextXAlignment = left,
		Text = "\u{00A9} 2026 " .. (PUBLISHER[GamePoster.family(name)] or "Bargain Bin Software") .. ". A parody release: not affiliated with any real game, console or publisher. GRB ratings are fictional."})
	local h = hash(name)
	local code = frame(sheet, {Position = UDim2.fromScale(0.64, 0.826), Size = UDim2.fromScale(0.31, 0.085), BackgroundColor3 = W})
	local x = 0.06
	for i = 1, 22 do
		local w = ((h // (i * 7)) % 3 + 1) * 0.011
		if x + w > 0.94 then break end
		if i % 2 == 1 then
			frame(code, {Position = UDim2.fromScale(x, 0.08), Size = UDim2.fromScale(w, 0.84), BackgroundColor3 = B})
		end
		x += w + 0.012
	end
	local digits = string.format("%d %05d %05d %d", h % 10, (h // 10) % 100000, (h // 7) % 100000, (h // 3) % 10)
	label(sheet, {Position = UDim2.fromScale(0.64, 0.914), Size = UDim2.fromScale(0.31, 0.022), Text = digits, Font = F.RobotoMono, TextColor3 = plat.Text})
	label(sheet, {Position = UDim2.fromScale(0.64, 0.94), Size = UDim2.fromScale(0.31, 0.02), Text = plat.Code .. "-" .. string.format("%05d", h % 100000), Font = F.RobotoMono, TextColor3 = plat.Muted})

	-- SPINES: a printed strip with the console band, the title up the side and the rating at the foot
	local size = item.Size
	local ink = luminance(plat.Paper) > 0.6 and rgb(30, 30, 40) or W
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local spine = surface(item, face, 50)
		pcall(function()
			spine.MaxDistance = 90
		end)
		frame(spine, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = plat.Plastic})
		frame(spine, {Position = UDim2.fromScale(0.1, 0.02), Size = UDim2.fromScale(0.8, 0.11), BackgroundColor3 = plat.Band})
		local strip = frame(spine, {Position = UDim2.fromScale(0.1, 0.14), Size = UDim2.fromScale(0.8, 0.84), BackgroundColor3 = plat.Paper})
		label(strip, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(size.Y * 50 * 0.66, size.Z * 50 * 0.62), Rotation = 90,
			Text = name, Font = F.GothamBlack, TextColor3 = ink})
		label(strip, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.98), Size = UDim2.fromScale(0.9, 0.08), Text = g.Rating, Font = F.GothamBlack, TextColor3 = plat.Accent})
	end
end

return CP


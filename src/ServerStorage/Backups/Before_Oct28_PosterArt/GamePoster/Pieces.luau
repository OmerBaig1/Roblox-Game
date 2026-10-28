--[[
	Shared drawing pieces for the hand-made posters in GamePoster.Art.
	Every function takes the drawing kit (k) first. x/y are centers (0-1), s is a size multiplier.
]]

local rgb = Color3.fromRGB
local ASPECT = 0.775

local P = {}
P.WHITE, P.BLACK, P.GOLD = rgb(255, 255, 255), rgb(15, 15, 20), rgb(255, 205, 60)
P.SKIN = rgb(255, 210, 170)

-- A true square (same size across and down)
function P.sq(k, x, y, d, color, opts)
	return k.rect(x, y, d, d / ASPECT, color, opts)
end

-- 8-pointed burst
function P.star(k, x, y, d, color)
	P.sq(k, x, y, d * 0.7, color)
	P.sq(k, x, y, d * 0.7, color, {rot = 45})
end

function P.eyes(k, x, y, d, gap, look)
	gap = gap or d * 1.2
	for _, sx in ipairs({-1, 1}) do
		k.circle(x + sx * gap / 2, y, d, P.WHITE)
		k.circle(x + sx * gap / 2 + (look or 0) * d * 0.22, y, d * 0.5, P.BLACK)
	end
end

-- Angry eyebrows (call after eyes; y is the brow height)
function P.brows(k, x, y, d, gap, angle)
	gap = gap or d * 1.2
	angle = angle or 20
	k.rect(x - gap / 2, y, d * 1.1, d * 0.3 / ASPECT, P.BLACK, {rot = angle})
	k.rect(x + gap / 2, y, d * 1.1, d * 0.3 / ASPECT, P.BLACK, {rot = -angle})
end

function P.smile(k, x, y, w, color)
	k.ellipse(x, y, w, w * 0.6 / ASPECT, color or P.BLACK)
	k.ellipse(x, y - w * 0.18 / ASPECT, w * 1.05, w * 0.5 / ASPECT, k.bg or P.WHITE)
end

function P.ghost(k, x, y, s, color)
	color = color or rgb(240, 245, 255)
	k.circle(x, y, 0.22 * s, color)
	k.rect(x, y + 0.13 * s, 0.22 * s, 0.26 * s, color)
	for i = -1, 1 do
		k.circle(x + i * 0.073 * s, y + 0.26 * s, 0.077 * s, color)
	end
	k.ellipse(x - 0.04 * s, y - 0.01 * s, 0.035 * s, 0.07 * s, P.BLACK)
	k.ellipse(x + 0.04 * s, y - 0.01 * s, 0.035 * s, 0.07 * s, P.BLACK)
	k.ellipse(x, y + 0.08 * s, 0.05 * s, 0.05 * s, P.BLACK)
end

function P.bat(k, x, y, s)
	k.ellipse(x - 0.06 * s, y, 0.12 * s, 0.05 * s, P.BLACK, {rot = -18})
	k.ellipse(x + 0.06 * s, y, 0.12 * s, 0.05 * s, P.BLACK, {rot = 18})
	k.circle(x, y, 0.05 * s, P.BLACK)
end

function P.kart(k, x, y, s, color)
	k.circle(x - 0.03 * s, y - 0.1 * s, 0.1 * s, rgb(250, 250, 250))
	k.rect(x, y - 0.1 * s, 0.05 * s, 0.035 * s, rgb(60, 160, 255), {round = 0.3})
	k.rect(x + 0.07 * s, y - 0.06 * s, 0.014 * s, 0.09 * s, P.BLACK, {rot = 30})
	k.rect(x, y, 0.34 * s, 0.085 * s, color, {round = 0.4})
	k.rect(x - 0.16 * s, y - 0.045 * s, 0.045 * s, 0.09 * s, color:Lerp(P.BLACK, 0.3))
	for _, dx in ipairs({-0.12, 0.12}) do
		k.circle(x + dx * s, y + 0.06 * s, 0.095 * s, P.BLACK)
		k.circle(x + dx * s, y + 0.06 * s, 0.04 * s, rgb(170, 170, 180))
	end
end

function P.bubble(k, x, y, w, h, text, color)
	k.rect(x - w * 0.22, y + h * 0.42, w * 0.13, h * 0.32, P.WHITE, {rot = 30})
	k.ellipse(x, y, w, h, P.WHITE)
	k.text(x, y, w * 0.78, h * 0.65, text, color or P.BLACK)
end

function P.rocket(k, x, y, s, color, fin)
	k.ellipse(x, y + 0.22 * s, 0.08 * s, 0.16 * s, rgb(255, 150, 40))
	k.ellipse(x, y + 0.2 * s, 0.04 * s, 0.09 * s, rgb(255, 235, 100))
	fin = fin or rgb(220, 50, 50)
	k.rect(x - 0.06 * s, y + 0.1 * s, 0.05 * s, 0.11 * s, fin, {rot = 20, round = 0.3})
	k.rect(x + 0.06 * s, y + 0.1 * s, 0.05 * s, 0.11 * s, fin, {rot = -20, round = 0.3})
	k.ellipse(x, y, 0.12 * s, 0.34 * s, color or rgb(235, 235, 240))
	k.circle(x, y - 0.04 * s, 0.06 * s, rgb(70, 70, 90))
	k.circle(x, y - 0.04 * s, 0.045 * s, rgb(90, 180, 255))
end

function P.gear(k, x, y, d, color, hole)
	for i = 0, 7 do
		local a = math.rad(i * 45)
		P.sq(k, x + math.cos(a) * d * 0.5, y + math.sin(a) * d * 0.5 / ASPECT, d * 0.22, color, {rot = i * 45})
	end
	k.circle(x, y, d, color)
	k.circle(x, y, d * 0.35, hole or P.BLACK)
end

function P.can(k, x, y, w, h, color, label, labelColor)
	k.ellipse(x, y + h / 2, w, w * 0.35 / ASPECT, color:Lerp(P.BLACK, 0.35))
	k.rect(x, y, w, h, color)
	k.ellipse(x, y - h / 2, w, w * 0.35 / ASPECT, rgb(205, 205, 215))
	k.ellipse(x, y - h / 2, w * 0.7, w * 0.2 / ASPECT, rgb(160, 160, 170))
	if label then
		k.text(x, y + h * 0.05, w * 0.92, h * 0.5, label, labelColor or P.WHITE, {stroke = true})
	end
end

function P.person(k, x, y, s, shirt, skin, pants)
	skin = skin or P.SKIN
	pants = pants or rgb(40, 50, 90)
	k.rect(x - 0.025 * s, y + 0.2 * s, 0.03 * s, 0.14 * s, pants, {rot = 8})
	k.rect(x + 0.025 * s, y + 0.2 * s, 0.03 * s, 0.14 * s, pants, {rot = -8})
	k.rect(x, y + 0.07 * s, 0.1 * s, 0.16 * s, shirt, {round = 0.3})
	k.circle(x, y - 0.05 * s, 0.09 * s, skin)
end

function P.zzz(k, x, y, s, color)
	for i = 0, 2 do
		k.text(x + i * 0.05 * s, y - i * 0.08 * s, (0.06 + i * 0.02) * s, (0.08 + i * 0.03) * s, "z", color or P.WHITE, {stroke = true})
	end
end

function P.tree(k, x, groundY, s, leaf)
	leaf = leaf or rgb(60, 160, 70)
	k.rect(x, groundY - 0.08 * s, 0.03 * s, 0.16 * s, rgb(110, 75, 45))
	k.circle(x, groundY - 0.2 * s, 0.14 * s, leaf)
	k.circle(x - 0.04 * s, groundY - 0.15 * s, 0.1 * s, leaf)
	k.circle(x + 0.04 * s, groundY - 0.15 * s, 0.1 * s, leaf)
end

function P.brain(k, x, y, s)
	local pink, dark = rgb(255, 165, 185), rgb(220, 120, 150)
	for _, c in ipairs({{-0.07, 0.02}, {0, -0.04}, {0.07, 0.02}, {-0.04, 0.07}, {0.04, 0.07}, {0, 0.03}}) do
		k.circle(x + c[1] * s, y + c[2] * s, 0.13 * s, pink)
	end
	k.rect(x, y + 0.02 * s, 0.008 * s, 0.16 * s, dark)
	for _, c in ipairs({{-0.06, -0.01, 30}, {0.06, 0.04, -30}, {-0.05, 0.08, -20}, {0.05, -0.02, 20}}) do
		k.rect(x + c[1] * s, y + c[2] * s, 0.05 * s, 0.008 * s, dark, {rot = c[3]})
	end
end

-- Checkered flag
function P.flag(k, x, y, s)
	k.rect(x - 0.08 * s, y + 0.12 * s, 0.012 * s, 0.34 * s, rgb(80, 80, 90))
	for r = 0, 2 do
		for c = 0, 3 do
			k.rect(x - 0.06 * s + c * 0.04 * s, y - 0.03 * s + r * 0.045 * s, 0.04 * s, 0.045 * s, (r + c) % 2 == 0 and P.BLACK or P.WHITE)
		end
	end
end

function P.moon(k, x, y, d, bg)
	k.circle(x, y, d, rgb(245, 240, 205))
	if bg then
		k.circle(x + d * 0.3, y - d * 0.15, d * 0.85, bg)
	end
end

function P.lightning(k, x, y, s, color)
	color = color or rgb(255, 230, 60)
	k.rect(x, y - 0.08 * s, 0.03 * s, 0.17 * s, color, {rot = 25})
	k.rect(x + 0.01 * s, y, 0.07 * s, 0.025 * s, color, {rot = -10})
	k.rect(x + 0.03 * s, y + 0.09 * s, 0.03 * s, 0.17 * s, color, {rot = 25})
end

function P.planet(k, x, y, d, color, ring)
	k.circle(x, y, d, color)
	k.circle(x - d * 0.15, y - d * 0.15, d * 0.25, color:Lerp(P.WHITE, 0.3), {t = 0.3})
	if ring then
		k.ellipse(x, y, d * 1.7, d * 0.18 / ASPECT, ring, {rot = -12, t = 0.1})
	end
end

function P.astronaut(k, x, y, s, suit)
	suit = suit or rgb(240, 240, 245)
	k.rect(x - 0.03 * s, y + 0.18 * s, 0.045 * s, 0.13 * s, suit, {round = 0.4})
	k.rect(x + 0.03 * s, y + 0.18 * s, 0.045 * s, 0.13 * s, suit, {round = 0.4})
	k.rect(x, y + 0.06 * s, 0.13 * s, 0.17 * s, suit, {round = 0.35})
	k.circle(x, y - 0.08 * s, 0.14 * s, suit)
	k.ellipse(x, y - 0.08 * s, 0.1 * s, 0.09 * s, rgb(40, 60, 110))
	k.ellipse(x - 0.02 * s, y - 0.1 * s, 0.03 * s, 0.025 * s, P.WHITE, {t = 0.4})
end

return P

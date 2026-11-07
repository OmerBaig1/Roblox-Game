--[[
	VaultDecor: the sculpted pieces on the Game Vault's walls. Three designs for each of the 20 areas, all real 3D relief on a
	shaped wall plate, in the area's own colours. Each is about 13 studs across, centred on the spot it's given.
	In these drawings x is across the wall, y is up and z comes out of the wall toward the room.
]]
local VaultDecor = {}
local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local GOLD, BRASS, IRON, BONE = rgb(226, 176, 62), rgb(190, 140, 64), rgb(70, 72, 82), rgb(236, 226, 200)
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local DRAW = {
	-- 1 Bargain Basement
	{function(d) -- piggy bank
		d.ball(0, 0, 1.4, 7, 6, 5, rgb(245, 150, 170))
		d.disc(-3.5, -0.2, 2.8, 2.2, rgb(250, 175, 190))
		d.disc(-4.4, 0.2, 3.2, 0.5, rgb(170, 80, 100)); d.disc(-4.4, -0.7, 3.2, 0.5, rgb(170, 80, 100))
		d.ball(-1.8, 1.2, 3.4, 0.8, 0.8, 0.5, rgb(30, 25, 30))
		d.box(-1, 3, 2, 1.4, 1.6, 0.6, rgb(235, 130, 150), nil, 20); d.box(1.4, 3, 2, 1.4, 1.6, 0.6, rgb(235, 130, 150), nil, -20)
		d.box(0.6, 2.9, 3.2, 2, 0.3, 0.3, rgb(120, 60, 80))
		for _, x in ipairs({-2, 2}) do d.box(x, -3.4, 2, 1.2, 1.6, 1.2, rgb(235, 130, 150)) end
		d.disc(0.6, 4.6, 1.6, 2, GOLD, M.Metal)
	end, function(d) -- stacks of gold coins
		for i, s in ipairs({{-3.2, 6}, {0, 8}, {3.2, 4}}) do
			for n = 0, s[2] - 1 do
				d.box(s[1], -4.2 + n * 0.86, 1.3, 2.9, 0.72, 1.8, n % 2 == 0 and GOLD or rgb(246, 204, 96), M.Metal)
			end
		end
		d.disc(0, 4.6, 2, 2.6, rgb(246, 204, 96), M.Metal); d.text(0, 4.6, 2.4, 2, "$", rgb(120, 70, 10))
	end, function(d) -- shopping cart
		local steel = rgb(190, 196, 208)
		d.rod(-5, 4, -3.6, 4, 0.34, 1.5, steel); d.rod(-3.6, 4, -2.2, -2, 0.34, 1.5, steel)
		d.rod(-2.2, -2, 4, -2, 0.34, 1.5, steel); d.rod(4, -2, 5, 3, 0.34, 1.5, steel); d.rod(5, 3, -3.2, 3, 0.34, 1.5, steel)
		for i = 0, 4 do d.rod(-2.6 + i * 1.6, 3, -1.8 + i * 1.3, -2, 0.16, 1.4, steel) end
		d.rod(-3, 1, 4.6, 1, 0.16, 1.4, steel)
		d.box(0, -3.1, 1.4, 6, 0.3, 0.4, steel)
		for _, x in ipairs({-1.8, 3.2}) do d.disc(x, -4.3, 1.6, 1.3, rgb(40, 40, 46)); d.disc(x, -4.3, 1.8, 0.5, steel, M.Metal) end
		d.box(0.6, 1, 1.4, 2, 2, 0.8, rgb(235, 80, 80), nil, 8); d.box(2.5, 0.4, 1.3, 1.6, 1.4, 0.8, rgb(90, 170, 240), nil, -10)
	end},
	-- 2 Retro Arcade
	{function(d) -- joystick panel
		d.box(0, -1, 0.9, 11, 7, 0.7, rgb(28, 22, 48))
		d.box(0, -1, 1.3, 10, 6, 0.2, d.accent)
		d.disc(-2.6, -1.4, 1.5, 3, rgb(30, 30, 38)); d.rod(-2.6, -1.4, -2.6, 2, 0.5, 2.1, rgb(200, 204, 214), M.Metal); d.ball(-2.6, 2.6, 2.1, 1.9, 1.9, 1.9, rgb(235, 50, 60))
		for i, c in ipairs({rgb(255, 225, 60), rgb(70, 220, 110), rgb(70, 170, 255), rgb(255, 80, 180)}) do
			d.disc(1.2 + ((i - 1) % 2) * 2.1, -0.2 - (i > 2 and 2 or 0), 1.6, 1.5, c, M.Neon)
		end
	end, function(d) -- pixel heart
		local shape = {".##...##.", "####.####", "#########", "#########", ".#######.", "..#####..", "...###...", "....#...."}
		d.plate(11.5, 10.5, rgb(18, 14, 34))
		for r, line in ipairs(shape) do
			for c = 1, #line do
				if line:sub(c, c) == "#" then
					d.box((c - 5) * 1.1, (4.5 - r) * 1.1, 1.4, 1.02, 1.02, 0.7, (r == 2 and c == 2) and rgb(255, 225, 235) or rgb(235, 40, 90), M.Neon)
				end
			end
		end
	end, function(d) -- tiny cabinet
		d.box(0, -0.6, 1.2, 7.4, 11, 1.4, rgb(70, 30, 150))
		d.box(0, 4, 2, 7.8, 2, 0.6, rgb(250, 60, 170), M.Neon)
		d.box(0, 1, 2, 5.6, 4, 0.4, rgb(14, 14, 24)); d.box(0, 1, 2.3, 4.8, 3.2, 0.1, rgb(30, 200, 170), M.Neon)
		d.box(0, -2.1, 2.2, 6.6, 0.9, 1, rgb(30, 28, 40))
		d.ball(-1.8, -1.5, 2.5, 0.8, 0.8, 0.8, rgb(240, 60, 60)); d.disc(1, -1.8, 2.8, 0.7, rgb(255, 225, 60), M.Neon); d.disc(2.2, -1.8, 2.8, 0.7, rgb(70, 170, 255), M.Neon)
	end},
	-- 3 Toy Box
	{function(d) -- teddy bear
		local fur, pale = rgb(186, 128, 76), rgb(232, 196, 148)
		d.ball(0, -2, 1.4, 5.6, 5.6, 3, fur); d.ball(0, -2.2, 2.6, 3.2, 3.4, 1, pale)
		d.ball(0, 2.3, 1.8, 4.8, 4.4, 3, fur); d.ball(0, 1.6, 3.1, 2.2, 1.7, 1, pale)
		d.ball(0, 2, 3.7, 0.8, 0.6, 0.4, rgb(40, 28, 24))
		for _, s in ipairs({-1, 1}) do
			d.ball(s * 2.1, 4.4, 1.5, 1.9, 1.9, 1, fur); d.ball(s * 1, 3, 3.3, 0.6, 0.6, 0.3, rgb(30, 22, 20))
			d.ball(s * 3.4, -1.4, 1.5, 2, 3.2, 1.8, fur); d.ball(s * 2, -4.6, 1.8, 2.4, 2, 2, fur)
		end
	end, function(d) -- alphabet blocks
		for _, b in ipairs({{-2.6, -3, rgb(235, 70, 70), "G"}, {2.6, -3, rgb(70, 150, 240), "A"}, {0, 2.2, rgb(250, 200, 50), "M"}}) do
			d.box(b[1], b[2], 1.8, 5, 5, 2.4, b[3], nil, b[2] > 0 and 7 or 0)
			d.text(b[1], b[2], 3.05, 4, b[4], rgb(255, 255, 255))
		end
	end, function(d) -- toy rocket
		local hull = rgb(245, 245, 250)
		d.rod(0, -4, 0, 2.6, 3, 1.8, hull)
		d.wedge(0, 4, 1.8, 3, 2.8, 1, rgb(235, 60, 60))
		d.disc(0, 0.8, 3.4, 1.7, rgb(60, 170, 240), M.Glass); d.disc(0, 0.8, 3.3, 2.2, GOLD, M.Metal)
		for _, s in ipairs({-1, 1}) do d.box(s * 2.2, -3.8, 1.8, 1.6, 2.8, 0.7, rgb(235, 60, 60), nil, s * 22) end
		d.ball(0, -5.4, 1.8, 1.8, 1.4, 1, rgb(255, 170, 40), M.Neon)
	end},
	-- 4 Pirate Cove
	{function(d) -- ship's wheel
		local wood, pale = rgb(106, 66, 36), rgb(150, 100, 56)
		for i = 0, 11 do
			local a = i * math.pi / 6
			d.box(math.cos(a) * 4.8, math.sin(a) * 4.8, 1.4, 2.8, 0.9, 0.8, wood, M.Wood, math.deg(a) + 90)
		end
		for i = 0, 3 do
			d.box(0, 0, 1.5, 0.7, 9.4, 0.5, pale, M.Wood, i * 45)
			local a = i * math.pi / 4 + math.pi / 8
			for _, s in ipairs({-1, 1}) do d.rod(s * math.cos(a) * 5, s * math.sin(a) * 5, s * math.cos(a) * 6.4, s * math.sin(a) * 6.4, 0.5, 1.4, pale, M.Wood) end
		end
		d.disc(0, 0, 1.9, 2.4, GOLD, M.Metal); d.disc(0, 0, 2.2, 1, BRASS, M.Metal)
	end, function(d) -- anchor and rope
		d.rod(0, 4, 0, -4.4, 1, 1.5, IRON, M.Metal)
		d.box(0, 2.4, 1.5, 5, 0.8, 0.8, rgb(96, 64, 40), M.Wood)
		d.arc(0, 4.9, 1.5, 0.9, 0.4, 0, 360, 8, IRON, M.Metal)
		d.arc(0, -1.6, 1.5, 3.8, 0.8, 110, 250, 8, IRON, M.Metal)
		for _, s in ipairs({-1, 1}) do d.wedge(s * 4.2, -1.2, 1.5, 1.4, 1.8, 0.8, IRON, M.Metal) end
		d.arc(0, 0, 0.9, 6, 0.3, 0, 360, 14, rgb(205, 175, 115), M.Fabric)
	end, function(d) -- crossed cutlasses and skull
		for _, s in ipairs({-1, 1}) do
			d.box(s * 0.2, 0.4, 1.1, 0.7, 11, 0.25, rgb(214, 220, 230), M.Metal, s * 42)
			d.ball(-s * 3.8, -4, 1.3, 1.1, 1.1, 0.9, GOLD, M.Metal)
		end
		d.ball(0, 1, 2, 4.4, 4.2, 2.4, BONE); d.box(0, -1.4, 2, 2.4, 1.6, 1.8, BONE)
		for _, s in ipairs({-1, 1}) do d.ball(s * 0.95, 1, 3.05, 1.2, 1.3, 0.5, rgb(26, 22, 24)) end
		for i = -1, 1 do d.box(i * 0.65, -1.6, 2.95, 0.22, 0.9, 0.1, rgb(40, 34, 34)) end
	end},
	-- 5 Haunted Crypt (used on levels without niches)
	{function(d) -- bat
		local fur, wing = rgb(40, 30, 50), rgb(60, 40, 76)
		d.ball(0, 0, 1.6, 2.8, 3.6, 2, fur); d.ball(0, 2.4, 1.8, 2.3, 2.1, 1.8, fur)
		for _, s in ipairs({-1, 1}) do
			d.tri(s * 1, 1.4, s * 6.4, 2.4, s * 5, -1.4, wing); d.tri(s * 1, 1.4, s * 5, -1.4, s * 1, -0.8, wing)
			d.wedge(s * 0.8, 3.8, 1.8, 0.7, 1.2, 0.5, fur); d.ball(s * 0.55, 2.6, 2.6, 0.4, 0.4, 0.2, rgb(255, 60, 60), M.Neon)
		end
	end, function(d) -- tombstone
		local stone = rgb(120, 120, 130)
		d.box(0, -2, 1.3, 7, 7, 1.2, stone, M.Slate); d.rod(-3.5, 1.5, 3.5, 1.5, 7, 1.3, stone, M.Slate)
		d.box(0, -5.4, 1.5, 9, 1, 1.8, rgb(84, 84, 94), M.Slate)
		d.text(0, -1, 2, 5, "RIP", rgb(36, 36, 44))
	end, function(d) -- iron lantern
		d.rod(0, 5.4, 0, 3.4, 0.25, 1.4, IRON, M.Metal)
		d.box(0, 3.1, 1.6, 4, 0.5, 2.4, IRON, M.Metal); d.box(0, -3, 1.6, 4, 0.6, 2.4, IRON, M.Metal)
		d.box(0, 0, 1.6, 2.8, 5.4, 1.6, d.light, M.Neon)
		for _, s in ipairs({-1, 1}) do d.box(s * 1.75, 0, 2.5, 0.28, 5.8, 0.28, IRON, M.Metal) end
		d.box(0, 0, 2.6, 0.2, 5.6, 0.2, IRON, M.Metal)
	end},
	-- 6 Cyber City
	{function(d) -- circuit board
		d.plate(12, 11, rgb(14, 30, 34))
		for _, t in ipairs({{-5, 3, -1, 3}, {-1, 3, 1, 1}, {1, 1, 5, 1}, {-5, -1, -2, -1}, {-2, -1, 0, -3}, {0, -3, 5, -3}, {2, 4, 2, 1.5}}) do
			d.rod(t[1], t[2], t[3], t[4], 0.26, 1.3, d.accent, M.Neon)
		end
		d.box(0.5, 0, 1.6, 3.4, 3.4, 0.6, rgb(26, 28, 36)); d.box(0.5, 0, 1.95, 2, 2, 0.1, d.accent, M.Neon)
		for _, p in ipairs({{-5, 3}, {5, 1}, {-5, -1}, {5, -3}, {2, 4}}) do d.disc(p[1], p[2], 1.4, 0.8, GOLD, M.Metal) end
	end, function(d) -- chrome visor mask
		local chrome = rgb(170, 178, 196)
		d.ball(0, 0, 1.6, 8, 10, 2.6, chrome, M.Metal)
		d.box(0, 1, 2.9, 7.6, 1.5, 0.5, rgb(20, 20, 30)); d.box(0, 1, 3.15, 6.8, 0.8, 0.1, d.accent, M.Neon)
		for i = -2, 2 do d.box(i * 0.8, -3, 2.7, 0.3, 1.4, 0.3, rgb(30, 30, 40)) end
	end, function(d) -- server rack
		d.box(0, 0, 1.3, 7.6, 11.4, 1.4, rgb(22, 24, 32), M.Metal)
		for i = 0, 4 do
			d.box(0, -4.2 + i * 2.1, 2, 6.6, 1.6, 0.3, rgb(44, 48, 60), M.Metal)
			d.box(-1.8, -4.2 + i * 2.1, 2.2, 2.2, 0.3, 0.1, i % 2 == 0 and d.accent or rgb(60, 230, 255), M.Neon)
			d.disc(2.4, -4.2 + i * 2.1, 2.2, 0.5, rgb(90, 255, 120), M.Neon)
		end
	end},
	-- 7 Ninja Dojo
	{function(d) -- katana rack
		d.box(0, -4, 1, 11, 0.8, 0.8, rgb(60, 34, 26), M.Wood); d.box(0, 3.4, 1, 11, 0.8, 0.8, rgb(60, 34, 26), M.Wood)
		for i, y in ipairs({1.5, -1.4}) do
			d.box(1, y, 1.9, 8.6, 0.42, 0.3, i == 1 and rgb(220, 226, 236) or rgb(30, 26, 34), i == 1 and M.Metal or nil, 3)
			d.box(-4.4, y - 0.3, 1.9, 2.8, 0.55, 0.45, rgb(190, 40, 40), M.Fabric, 3)
			d.disc(-2.8, y - 0.2, 1.9, 1, GOLD, M.Metal)
		end
		for _, s in ipairs({-1, 1}) do d.box(s * 4.8, -0.3, 1.1, 0.7, 7, 0.7, rgb(60, 34, 26), M.Wood) end
	end, function(d) -- shuriken
		local steel = rgb(170, 176, 190)
		for i = 0, 3 do
			local a = i * 90
			local r = math.rad(a)
			d.tri(-math.sin(r) * 1.2 - math.cos(r) * 1.2, math.cos(r) * 1.2 - math.sin(r) * 1.2, -math.sin(r) * 5.6, math.cos(r) * 5.6, -math.sin(r) * 1.2 + math.cos(r) * 1.2, math.cos(r) * 1.2 + math.sin(r) * 1.2, steel, M.Metal)
		end
		d.disc(0, 0, 1.4, 3.2, rgb(70, 74, 86), M.Metal); d.disc(0, 0, 1.6, 1.1, rgb(20, 20, 26))
	end, function(d) -- paper lantern
		d.box(0, 5.4, 1.5, 3.4, 0.6, 2, rgb(30, 26, 26)); d.box(0, -5.4, 1.5, 3, 0.6, 2, rgb(30, 26, 26))
		d.ball(0, 0, 1.8, 7.4, 10, 3, d.accent:Lerp(rgb(255, 200, 120), 0.55))
		for _, y in ipairs({-3, -1, 1, 3}) do d.box(0, y, 3.2, 7 - math.abs(y) * 0.9, 0.2, 0.3, rgb(60, 26, 22)) end
	end},
	-- 8 Robot Factory
	{function(d) -- meshed gears
		d.gear(-1.8, 1.4, 3.6, 12, rgb(150, 156, 168)); d.gear(3.2, -2.6, 2.4, 9, rgb(120, 126, 138))
		d.disc(-1.8, 1.4, 2.2, 1.6, d.accent, M.Neon); d.disc(3.2, -2.6, 2, 1, d.accent, M.Neon)
	end, function(d) -- robot head
		local plate = rgb(200, 180, 60)
		d.box(0, -0.4, 1.6, 8, 7, 2.4, plate, M.Metal)
		for _, s in ipairs({-1, 1}) do d.disc(s * 1.9, 0.6, 2.9, 2.2, rgb(30, 30, 36)); d.disc(s * 1.9, 0.6, 3.05, 1.2, rgb(255, 60, 50), M.Neon); d.box(s * 4.5, 0, 1.6, 1, 2.6, 1.4, IRON, M.Metal) end
		for i = -2, 2 do d.box(i * 1, -2.8, 2.9, 0.6, 1, 0.2, rgb(30, 30, 36)) end
		d.rod(0, 3, 0, 5, 0.3, 1.6, IRON, M.Metal); d.ball(0, 5.2, 1.6, 0.9, 0.9, 0.9, rgb(255, 60, 50), M.Neon)
	end, function(d) -- crossed wrench and bolt
		local s1 = rgb(186, 192, 204)
		d.box(0, 0, 1.2, 1.2, 11, 0.5, s1, M.Metal, 40); d.box(3.5, 4.1, 1.2, 3, 2, 0.5, s1, M.Metal, 40); d.box(3.8, 4.5, 1.3, 1.2, 1.2, 0.6, rgb(50, 52, 60), nil, 40)
		d.box(0, 0, 1.6, 1.2, 10, 0.5, rgb(130, 136, 148), M.Metal, -40); d.disc(3.3, -3.9, 2, 2.6, rgb(150, 156, 168), M.Metal); d.disc(3.3, -3.9, 2.4, 1.1, d.accent, M.Neon)
	end},
	-- 9 Dragon's Keep
	{function(d) -- heraldic shield and swords
		for _, s in ipairs({-1, 1}) do d.box(0, 0, 1, 0.6, 12, 0.3, rgb(214, 220, 230), M.Metal, s * 40) end
		d.box(0, 1.4, 1.5, 7.4, 5.2, 0.9, d.accent); d.tri(-3.7, -1.2, 3.7, -1.2, 0, -5.2, d.accent, nil, 1.8)
		d.box(0, 4.1, 1.8, 7.8, 0.5, 0.8, GOLD, M.Metal); d.box(0, 0, 2.1, 0.8, 7.4, 0.4, GOLD, M.Metal); d.box(0, 1.4, 2.1, 6.6, 0.8, 0.4, GOLD, M.Metal)
	end, function(d) -- dragon's head
		local scale = d.accent:Lerp(rgb(30, 20, 20), 0.35)
		d.ball(0, 1, 1.8, 6, 5, 3, scale); d.box(0, -1.6, 2.6, 3.6, 3.4, 2.4, scale); d.box(0, -3.4, 2.5, 3, 1, 2.2, scale:Lerp(BONE, 0.4))
		for _, s in ipairs({-1, 1}) do
			d.rod(s * 1.8, 3, s * 3.6, 6, 0.7, 1.8, BONE); d.ball(s * 1.4, 1.2, 3.2, 1.1, 0.7, 0.4, rgb(255, 210, 50), M.Neon)
			d.disc(s * 0.8, -2.3, 3.85, 0.4, rgb(20, 14, 14)); d.wedge(s * 1, -4.3, 2.8, 0.5, 0.9, 0.4, BONE)
		end
	end, function(d) -- wall torch
		d.box(0, -3.6, 1.2, 2.2, 3, 1, IRON, M.Metal); d.rod(0, -4.5, 0, 1.2, 0.9, 2, rgb(96, 62, 36), M.Wood)
		d.arc(0, 1.6, 2, 1.1, 0.25, 0, 360, 8, IRON, M.Metal)
		d.ball(0, 3, 2, 2.2, 4, 2, rgb(255, 140, 40), M.Neon); d.ball(0, 2.6, 2.3, 1.2, 2.4, 1.2, rgb(255, 225, 120), M.Neon)
	end},
	-- 10 Space Station
	{function(d) -- ringed planet
		d.ball(0, 0, 1.8, 7, 7, 3.4, rgb(230, 150, 100))
		d.ball(0, 1.2, 3, 5.4, 1.4, 1, rgb(200, 110, 76)); d.ball(0, -1.2, 3, 5.4, 1, 1, rgb(250, 190, 140))
		d.arc(0, 0, 2.4, 5.4, 0.5, 60, 300, 14, rgb(230, 230, 250), nil, 0.34)
	end, function(d) -- rocket
		local hull = rgb(235, 238, 246)
		d.rod(0, -3.4, 0, 3, 3.4, 1.7, hull, M.Metal)
		d.wedge(0, 4.6, 1.7, 3.4, 3.2, 1, d.accent)
		d.disc(0, 1.4, 3.5, 1.8, rgb(60, 200, 255), M.Neon); d.disc(0, 1.4, 3.4, 2.4, IRON, M.Metal)
		for _, s in ipairs({-1, 1}) do d.box(s * 2.4, -3.6, 1.7, 1.8, 3, 0.7, d.accent, nil, s * 24) end
		d.ball(0, -5.2, 1.7, 2, 1.8, 1, rgb(255, 160, 40), M.Neon)
	end, function(d) -- satellite
		d.box(0, 0, 1.8, 3, 3, 2.2, rgb(200, 204, 216), M.Metal)
		for _, s in ipairs({-1, 1}) do
			d.rod(s * 1.5, 0, s * 2.4, 0, 0.3, 1.8, IRON, M.Metal); d.box(s * 4.4, 0, 1.6, 3.8, 5, 0.3, rgb(30, 50, 110), M.Metal)
			for i = -1, 1 do d.box(s * 4.4, i * 1.5, 1.8, 3.4, 0.14, 0.1, rgb(120, 170, 255), M.Neon) end
		end
		d.disc(0, 0, 3, 2, rgb(230, 230, 240)); d.rod(0, 1.5, 1.2, 4, 0.2, 2, IRON, M.Metal); d.ball(1.2, 4.2, 2, 0.6, 0.6, 0.6, rgb(255, 60, 60), M.Neon)
	end},
	-- 11 Sunken Atlantis
	{function(d) -- trident
		d.rod(0, -6, 0, 3, 0.8, 1.6, GOLD, M.Metal); d.box(0, 3, 1.6, 5.6, 0.8, 0.8, GOLD, M.Metal)
		for _, x in ipairs({-2.5, 0, 2.5}) do d.rod(x, 3, x, x == 0 and 6 or 5.4, 0.6, 1.6, GOLD, M.Metal); d.wedge(x, x == 0 and 6.3 or 5.7, 1.6, 0.9, 1, 0.6, BRASS, M.Metal) end
		d.disc(0, 1, 2.1, 1.6, rgb(60, 220, 230), M.Neon)
	end, function(d) -- scallop shell
		for i = -4, 4 do d.box(math.sin(math.rad(i * 18)) * 3.4, math.cos(math.rad(i * 18)) * 3.4 - 3, 1.2 + (4 - math.abs(i)) * 0.1, 1.5, 7.2, 0.6, i % 2 == 0 and rgb(255, 196, 200) or rgb(255, 222, 214), nil, -i * 18) end
		d.box(0, -3.8, 1.5, 3.2, 1.2, 0.9, rgb(240, 170, 170))
		d.ball(0, -1, 2.2, 1.6, 1.6, 1.4, rgb(240, 250, 255), M.Neon)
	end, function(d) -- coral
		local c = d.accent:Lerp(rgb(255, 110, 120), 0.6)
		for _, b in ipairs({{0, -5, 0, 0}, {0, 0, -3, 3}, {0, 0, 3, 2.4}, {-3, 3, -4, 5.4}, {-3, 3, -1.4, 5}, {3, 2.4, 4.4, 4.4}, {3, 2.4, 1.6, 4.8}, {0, -2, -2.6, -0.6}, {0, -3, 2.6, -1.4}}) do
			d.rod(b[1], b[2], b[3], b[4], 0.8, 1.5, c)
			d.ball(b[3], b[4], 1.5, 1, 1, 1, c)
		end
	end},
	-- 12 Desert Pyramids
	{function(d) -- ankh
		d.arc(0, 2.8, 1.6, 2.2, 0.9, 0, 360, 12, GOLD, M.Metal)
		d.box(0, -2.2, 1.6, 1.2, 7, 0.9, GOLD, M.Metal); d.box(0, 0.2, 1.6, 7, 1.1, 0.9, GOLD, M.Metal)
		d.disc(0, 0.2, 2.2, 1.2, rgb(30, 90, 190), M.Metal)
	end, function(d) -- pyramid and sun
		d.plate(12, 11, rgb(26, 44, 110))
		d.disc(2.6, 2.6, 1.4, 3, GOLD, M.Neon)
		for i = 0, 3 do d.box(0, -4.3 + i * 1.5, 1.6, 10 - i * 2.4, 1.4, 0.5 + i * 0.1, rgb(226, 194, 130), M.Sandstone) end
		d.box(0, 1.5, 1.8, 0.9, 1.2, 0.6, GOLD, M.Metal)
	end, function(d) -- canopic urn
		local clay = rgb(70, 110, 170)
		d.ball(0, -1, 1.7, 5.4, 7, 2.8, clay); d.box(0, 3, 1.8, 2.6, 1, 2, GOLD, M.Metal)
		d.ball(0, 4.6, 1.8, 2.8, 2.8, 2, GOLD, M.Metal)
		for _, s in ipairs({-1, 1}) do d.ball(s * 0.6, 4.8, 2.7, 0.5, 0.3, 0.2, rgb(20, 20, 30)) end
		for _, y in ipairs({0, -1.4, -2.8}) do d.box(0, y, 3, 4.2 - math.abs(y) * 0.3, 0.4, 0.2, GOLD, M.Metal) end
	end},
	-- 13 Candy Kingdom
	{function(d) -- swirl lollipop
		d.rod(0, -6, 0, -1, 0.7, 1.4, rgb(250, 248, 240))
		d.disc(0, 2, 1.6, 8, rgb(255, 80, 170))
		for i, r in ipairs({0.8, 1.9, 3}) do d.arc(0, 2, 1.8, r, 0.55, 40 * i, 40 * i + 290, 10 + i * 2, i % 2 == 0 and rgb(120, 230, 210) or rgb(255, 255, 255)) end
	end, function(d) -- wrapped sweet
		d.ball(0, 0, 1.8, 6.4, 4.8, 3, rgb(255, 170, 50))
		for _, s in ipairs({-1, 1}) do d.tri(s * 2.6, 0, s * 6, 2.2, s * 6, -2.2, rgb(255, 120, 190)) end
		for i = -1, 1 do d.box(i * 1.6, 0, 3.2, 0.6, 4, 0.2, rgb(255, 225, 140), nil, 20) end
	end, function(d) -- cupcake
		for i = -3, 3 do d.box(i * 0.86, -3.2, 1.6, 0.8, 4, 1, i % 2 == 0 and rgb(255, 150, 190) or rgb(255, 196, 220)) end
		d.ball(0, 0, 1.9, 8, 3, 2.6, rgb(255, 245, 235)); d.ball(0, 1.6, 2.1, 6, 2.6, 2.2, rgb(255, 190, 220)); d.ball(0, 3, 2.3, 3.4, 2.2, 1.8, rgb(255, 245, 235))
		d.ball(0, 4.6, 2.4, 1.5, 1.5, 1.5, rgb(230, 30, 60))
		for _, p in ipairs({{-2.4, 0.4}, {2.2, 0.6}, {-1, 1.8}, {1.4, 2.2}}) do d.box(p[1], p[2], 3.1, 0.6, 0.18, 0.15, rgb(90, 200, 250), nil, p[1] * 30) end
	end},
	-- 14 Frozen Tundra
	{function(d) -- snowflake
		local ice = rgb(170, 225, 255)
		for i = 0, 2 do
			d.box(0, 0, 1.5, 0.8, 12, 0.5, ice, M.Ice, i * 60)
			for _, s in ipairs({-1, 1}) do
				local r = math.rad(i * 60 + (s < 0 and 180 or 0))
				local cx, cy = -math.sin(r) * 3.6, math.cos(r) * 3.6
				for _, t in ipairs({-1, 1}) do
					d.box(cx - math.sin(r + t * 0.8) * 1.1, cy + math.cos(r + t * 0.8) * 1.1, 1.6, 0.5, 2.4, 0.4, ice, M.Ice, i * 60 + (s < 0 and 180 or 0) + t * 46)
				end
			end
		end
		d.disc(0, 0, 1.9, 2.2, rgb(220, 245, 255), M.Neon)
	end, function(d) -- ice crystals
		local ice = rgb(150, 215, 250)
		for _, c in ipairs({{0, -5, 9, 2.6, 0}, {-3, -5, 6.4, 2, -18}, {3, -5, 6, 2, 18}, {-5, -5, 3.6, 1.4, -32}, {5, -5, 3.4, 1.4, 32}}) do
			local r = math.rad(c[5])
			d.box(c[1] - math.sin(r) * c[3] / 2, c[2] + math.cos(r) * c[3] / 2, 1.8, c[4], c[3], c[4] * 0.7, ice, M.Ice, c[5])
		end
		d.box(0, -5.2, 1.8, 11, 1, 1.8, rgb(232, 244, 252), M.Snow)
	end, function(d) -- crossed skis and goggles
		for _, s in ipairs({-1, 1}) do d.box(0, 0, 1.1 + (s + 1) * 0.2, 1, 12.4, 0.3, s < 0 and rgb(235, 60, 60) or rgb(60, 130, 235), nil, s * 28) end
		d.box(0, 0, 2, 6.4, 2.8, 0.8, rgb(30, 30, 38)); d.box(0, 0, 2.5, 5.4, 1.9, 0.2, rgb(255, 150, 60), M.Neon)
	end},
	-- 15 Wild West
	{function(d) -- horseshoe
		d.arc(0, 0, 1.6, 4, 1.5, -130, 130, 12, rgb(150, 150, 158), M.Metal)
		for i = -3, 3 do
			if i ~= 0 then
				local a = math.rad(i * 34)
				d.ball(-math.sin(a) * 4, math.cos(a) * 4, 2.3, 0.45, 0.45, 0.3, rgb(60, 60, 66), M.Metal)
			end
		end
	end, function(d) -- sheriff's star
		for i = 0, 4 do
			local a = i * 72
			d.tri(-1.7, 0.6, 1.7, 0.6, 0, 5.8, GOLD, M.Metal, 1.5, a)
			local r = math.rad(a)
			d.ball(-math.sin(r) * 5.9, math.cos(r) * 5.9, 1.7, 0.9, 0.9, 0.9, GOLD, M.Metal)
		end
		d.disc(0, 0, 1.8, 4.6, BRASS, M.Metal); d.disc(0, 0, 2.05, 3.4, GOLD, M.Metal)
	end, function(d) -- cactus
		local g = rgb(70, 150, 86)
		d.rod(0, -5.4, 0, 3.6, 2.4, 1.6, g); d.ball(0, 4, 1.6, 2.4, 2.4, 2.4, g)
		d.rod(0, -0.6, -3.4, -0.6, 1.5, 1.6, g); d.rod(-3.4, -0.6, -3.4, 2.4, 1.5, 1.6, g); d.ball(-3.4, 2.6, 1.6, 1.5, 1.5, 1.5, g)
		d.rod(0, 0.8, 3.2, 0.8, 1.5, 1.6, g); d.rod(3.2, 0.8, 3.2, 4, 1.5, 1.6, g); d.ball(3.2, 4.2, 1.6, 1.5, 1.5, 1.5, g)
		d.box(0, -5.4, 1.6, 7, 1, 2, rgb(180, 130, 80), M.Sandstone)
		d.ball(0.6, 5.1, 1.8, 1, 1, 1, rgb(255, 110, 170))
	end},
	-- 16 Jungle Temple
	{function(d) -- tiki mask
		local w = rgb(120, 78, 44)
		d.box(0, -0.4, 1.6, 7.4, 11, 2, w, M.Wood)
		d.box(0, 4.8, 1.8, 9, 1.4, 2, rgb(220, 150, 50), M.Wood)
		for _, s in ipairs({-1, 1}) do d.disc(s * 1.8, 2, 2.7, 2.4, BONE); d.disc(s * 1.8, 2, 2.95, 1, rgb(24, 20, 16)); d.box(s * 1.6, 3.5, 2.9, 2.8, 0.6, 0.4, rgb(60, 36, 20), nil, s * -14) end
		d.wedge(0, 0.2, 3, 1.6, 2.6, 1, rgb(90, 56, 30))
		d.box(0, -2.6, 2.9, 4.6, 1.6, 0.5, rgb(24, 20, 16))
		for i = -2, 2 do d.box(i * 0.9, -2.5, 3.1, 0.5, 1.1, 0.2, BONE) end
	end, function(d) -- leaf fan
		for i = -3, 3 do
			local a = math.rad(i * 24)
			d.ball(-math.sin(a) * 3.6, math.cos(a) * 3.6 - 3, 1.3 + (3 - math.abs(i)) * 0.15, 2, 8, 0.5, (i % 2 == 0) and rgb(50, 140, 70) or rgb(76, 170, 84), nil, i * 24)
		end
		d.ball(0, -3.2, 2.2, 2.2, 2.2, 1.4, rgb(255, 90, 90)); d.ball(0, -3.2, 2.9, 0.9, 0.9, 0.5, rgb(255, 220, 90), M.Neon)
	end, function(d) -- stone calendar
		local stone = rgb(136, 138, 118)
		d.disc(0, 0, 1.2, 12, stone, M.Slate); d.disc(0, 0, 1.4, 9, stone:Lerp(rgb(70, 110, 60), 0.3), M.Slate); d.disc(0, 0, 1.6, 4, GOLD, M.Metal)
		for i = 0, 11 do local a = i * math.pi / 6; d.box(math.cos(a) * 5.2, math.sin(a) * 5.2, 1.6, 1, 1.2, 0.3, rgb(90, 92, 78), M.Slate, math.deg(a)) end
		for i = 0, 3 do d.box(0, 0, 1.9, 0.6, 3.4, 0.2, rgb(90, 56, 20), nil, i * 45) end
	end},
	-- 17 Midnight Carnival
	{function(d) -- ferris wheel
		d.arc(0, 0.6, 1.5, 5, 0.3, 0, 360, 16, d.accent, M.Neon)
		for i = 0, 3 do d.box(0, 0.6, 1.5, 0.22, 10, 0.2, rgb(220, 220, 235), M.Metal, i * 45) end
		for i = 0, 7 do local a = i * math.pi / 4; d.box(math.cos(a) * 5, math.sin(a) * 5 + 0.1, 1.9, 1.1, 1, 0.6, i % 2 == 0 and rgb(255, 80, 120) or rgb(255, 210, 70)) end
		for _, s in ipairs({-1, 1}) do d.rod(0, 0.6, s * 3.4, -5.6, 0.4, 1.2, rgb(150, 150, 170), M.Metal) end
		d.disc(0, 0.6, 2, 1.3, GOLD, M.Metal)
	end, function(d) -- balloons
		for i, b in ipairs({{-2.4, 2.4, rgb(255, 70, 110)}, {2.4, 2.8, rgb(70, 170, 255)}, {0, 4.2, rgb(255, 210, 60)}, {0, 0.6, rgb(170, 90, 255)}}) do
			d.ball(b[1], b[2], 1.8, 3.2, 4, 2.2, b[3]); d.ball(b[1] - 0.6, b[2] + 0.9, 2.8, 0.7, 1, 0.3, rgb(255, 255, 255))
			d.rod(b[1], b[2] - 2, 0, -5.4, 0.1, 1.4, rgb(230, 230, 240))
		end
		d.box(0, -5.6, 1.5, 1.8, 0.7, 0.6, GOLD, M.Metal)
	end, function(d) -- harlequin mask
		d.ball(0, 0, 1.6, 10.6, 5.6, 1.8, rgb(40, 18, 60))
		for _, s in ipairs({-1, 1}) do
			d.ball(s * 2.4, 0.4, 2.5, 2.8, 1.6, 0.5, rgb(16, 12, 20))
			d.tri(s * 4, 2, s * 6, 5.4, s * 2.4, 3, s < 0 and rgb(235, 60, 90) or rgb(255, 200, 60))
			d.ball(s * 6, 5.4, 1.8, 0.8, 0.8, 0.8, GOLD, M.Metal)
		end
		d.tri(-1.5, 2.6, 1.5, 2.6, 0, 6, rgb(70, 200, 230))
	end},
	-- 18 Steampunk Skyway
	{function(d) -- brass clockwork
		d.gear(-2, 1.2, 3.8, 12, BRASS); d.gear(3.4, -2.2, 2.6, 10, rgb(180, 110, 60)); d.gear(3, 3.8, 1.5, 8, GOLD)
		d.disc(-2, 1.2, 2.2, 1.8, IRON, M.Metal)
	end, function(d) -- pressure gauge on pipes
		local cu = rgb(190, 112, 60)
		d.rod(-6, -3, 6, -3, 1.3, 1.2, cu, M.Metal); d.rod(0, -3, 0, -1, 1, 1.4, cu, M.Metal)
		d.disc(0, 1.6, 1.6, 7.6, BRASS, M.Metal); d.disc(0, 1.6, 2, 6.2, rgb(245, 235, 210))
		for i = -3, 3 do local a = math.rad(i * 34); d.box(-math.sin(a) * 2.5, 1.6 + math.cos(a) * 2.5, 2.3, 0.14, 0.7, 0.05, rgb(30, 26, 22), nil, i * 34) end
		d.box(0.6, 2.8, 2.4, 0.2, 2.7, 0.08, rgb(220, 40, 30), M.Neon, -26); d.disc(0, 1.6, 2.5, 0.8, IRON, M.Metal)
		for _, x in ipairs({-4.6, 4.6}) do d.disc(x, -3, 1.8, 1.8, BRASS, M.Metal) end
	end, function(d) -- airship
		local env = rgb(160, 96, 60)
		d.ball(0, 1.6, 1.8, 12, 5.6, 3, env)
		for i = -2, 2 do d.box(i * 2, 1.6, 3.2, 0.25, 5 - math.abs(i) * 0.7, 0.2, BRASS, M.Metal) end
		d.box(0, -2.8, 1.8, 5, 1.4, 1.2, rgb(90, 56, 34), M.Wood)
		for _, s in ipairs({-1, 1}) do d.rod(s * 2, -2.2, s * 2.6, -0.8, 0.14, 1.8, IRON, M.Metal) end
		d.tri(5.4, 1.6, 7, 3.6, 7, -0.4, BRASS, M.Metal)
	end},
	-- 19 Crystal Caverns
	{function(d) -- crystal cluster
		for _, c in ipairs({{0, 9, 2.6, 0, d.accent}, {-2.8, 6.6, 2, -20, rgb(120, 230, 240)}, {2.8, 6.2, 2, 20, rgb(200, 130, 255)}, {-4.6, 3.8, 1.3, -34, d.accent}, {4.6, 3.6, 1.3, 34, rgb(120, 230, 240)}}) do
			local r = math.rad(c[4])
			d.box(c[1] - math.sin(r) * c[2] / 2, -5 + math.cos(r) * c[2] / 2, 1.7, c[3], c[2], c[3] * 0.7, c[5], M.Glass, c[4])
			d.box(c[1] - math.sin(r) * c[2] / 2, -5 + math.cos(r) * c[2] / 2, 1.7, c[3] * 0.4, c[2] * 0.85, c[3] * 0.3, c[5], M.Neon, c[4])
		end
		d.ball(0, -5.4, 1.6, 12, 2.4, 2.6, rgb(60, 50, 76), M.Slate)
	end, function(d) -- cut gem
		d.plate(10, 10, rgb(30, 22, 56))
		d.box(0, 0, 2, 6, 6, 1.6, d.accent, M.Glass, 45); d.box(0, 0, 2.4, 3, 3, 1.2, rgb(255, 255, 255), M.Neon, 45)
		for i = 0, 3 do d.tri(0, 0, -4.2, 0, 0, 4.2, d.accent:Lerp(rgb(255, 255, 255), 0.25), M.Glass, 2.6, i * 90) end
	end, function(d) -- geode
		d.disc(0, 0, 1.3, 11.6, rgb(62, 52, 72), M.Slate); d.disc(0, 0, 1.5, 9.4, rgb(120, 90, 170), M.Slate); d.disc(0, 0, 1.7, 6.6, d.accent, M.Neon)
		for i = 0, 15 do local a = i * math.pi / 8; d.box(math.cos(a) * 3.8, math.sin(a) * 3.8, 2.1, 1, 1.8, 0.8, i % 2 == 0 and rgb(220, 190, 255) or rgb(150, 240, 240), M.Glass, math.deg(a) + 90) end
	end},
	-- 20 Cosmic Nexus
	{function(d) -- hourglass
		d.box(0, 5.2, 1.5, 7.4, 1, 2, GOLD, M.Metal); d.box(0, -5.2, 1.5, 7.4, 1, 2, GOLD, M.Metal)
		for _, s in ipairs({-1, 1}) do d.box(s * 3.2, 0, 1.5, 0.6, 10, 0.6, GOLD, M.Metal) end
		d.ball(0, 2.4, 1.6, 5, 5, 2.2, rgb(150, 200, 255), nil, nil, 0.45); d.ball(0, -2.4, 1.6, 5, 5, 2.2, rgb(150, 200, 255), nil, nil, 0.45)
		d.ball(0, -3, 1.6, 4, 3.2, 1.6, rgb(255, 210, 90), M.Neon); d.box(0, 0, 1.6, 0.3, 4.6, 0.3, rgb(255, 225, 130), M.Neon)
	end, function(d) -- spiral galaxy
		d.disc(0, 0, 1.1, 12, rgb(14, 8, 34))
		for arm = 0, 1 do for i = 1, 12 do
			local a, r = arm * math.pi + i * 0.48, 0.5 + i * 0.42
			d.ball(math.cos(a) * r, math.sin(a) * r, 1.5, 1.1 - i * 0.05, 1.1 - i * 0.05, 0.5, d.accent:Lerp(rgb(255, 255, 255), 1 - i / 14), M.Neon)
		end end
		d.ball(0, 0, 1.7, 2, 2, 1, rgb(255, 240, 200), M.Neon); d.arc(0, 0, 1.3, 6, 0.3, 0, 360, 16, GOLD, M.Metal)
	end, function(d) -- star crown
		d.box(0, -2.6, 1.6, 9, 2.2, 1.4, GOLD, M.Metal)
		for i = -2, 2 do d.tri(i * 1.9 - 1, -1.6, i * 1.9 + 1, -1.6, i * 1.9, 2.6 - math.abs(i) * 0.7, GOLD, M.Metal); d.ball(i * 1.9, 2.8 - math.abs(i) * 0.7, 1.7, 0.9, 0.9, 0.9, i % 2 == 0 and rgb(255, 70, 110) or rgb(90, 200, 255), M.Neon) end
		d.disc(0, -2.6, 2.4, 1.4, d.accent, M.Neon)
		d.arc(0, 0, 0.9, 6.2, 0.2, 0, 360, 16, rgb(190, 150, 255), M.Neon)
	end},
}

-- builds one piece: decoPart makes each part (the vault's non-colliding decoration); cf is the wall spot, with local -Z pointing
-- out of the wall. k picks the design (1..3), Theme gives the colours, scale enlarges it.
local Kit_text
function VaultDecor.piece(decoPart, decoWedge, parent, cf, zone, k, T, scale)
	scale = scale or 1
	local designs = DRAW[zone] or DRAW[1]
	local accent, light = T.Accent, T.Light or T.Accent
	local function at(x, y, z, deg)
		return cf * CFrame.new(x * scale, y * scale, -z * scale) * CFrame.Angles(0, 0, math.rad(deg or 0))
	end
	local d = {accent = accent, light = light}
	local function p(props)
		props.Parent = nil
		return decoPart(parent, props)
	end
	-- deg turns it in the wall's plane
	function d.box(x, y, z, sx, sy, sz, color, mat, deg)
		return p({Name = "Sculpt", Size = Vector3.new(sx, sy, sz) * scale, CFrame = at(x, y, z, deg), Color = color, Material = mat or M.SmoothPlastic})
	end
	-- a stretched sphere
	function d.ball(x, y, z, sx, sy, sz, color, mat, deg, t)
		local b = p({Name = "Sculpt", Size = Vector3.new(sx, sy, sz) * scale, CFrame = at(x, y, z, deg), Color = color, Material = mat or M.SmoothPlastic, Transparency = t or 0})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = b
		return b
	end
	-- a round face toward the room
	function d.disc(x, y, z, dia, color, mat)
		return p({Name = "Sculpt", Shape = CYL, Size = Vector3.new(0.4 * scale, dia * scale, dia * scale), CFrame = at(x, y, z) * CFrame.Angles(0, math.pi / 2, 0), Color = color, Material = mat or M.SmoothPlastic})
	end
	-- a bar between two points on the wall
	function d.rod(x1, y1, x2, y2, th, z, color, mat)
		local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) + th * 0.4
		return p({Name = "Sculpt", Size = Vector3.new(len, th, th) * scale, CFrame = at((x1 + x2) / 2, (y1 + y2) / 2, z, math.deg(math.atan2(y2 - y1, x2 - x1))), Color = color, Material = mat or M.SmoothPlastic})
	end
	-- a pointed tip, up
	function d.wedge(x, y, z, sx, sy, sz, color, mat)
		return p({Name = "Sculpt", Shape = nil, Size = Vector3.new(sx, sy * 0.6, sz) * scale, CFrame = at(x, y - sy * 0.2, z), Color = color, Material = mat or M.SmoothPlastic}), d.tri(x - sx / 2, y + sy * 0.1, x + sx / 2, y + sy * 0.1, x, y + sy * 0.6, color, mat, z)
	end
	-- a flat triangle, 0.6 thick, on the wall plane (made of two wedges); deg turns all of it round the spot
	function d.tri(x1, y1, x2, y2, x3, y3, color, mat, z, deg)
		z = z or 1.6
		local base = cf * CFrame.new(0, 0, -z * scale) * CFrame.Angles(0, 0, math.rad(deg or 0))
		local a, b, c = Vector3.new(x1, y1, 0) * scale, Vector3.new(x2, y2, 0) * scale, Vector3.new(x3, y3, 0) * scale
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local h = math.abs(ab:Dot(up))
		local th = 0.6 * scale
		decoWedge(parent, {Name = "Sculpt", Size = Vector3.new(th, h, math.abs(ab:Dot(back))), CFrame = base * CFrame.fromMatrix((a + b) / 2, right, up, back), Color = color, Material = mat or M.SmoothPlastic})
		decoWedge(parent, {Name = "Sculpt", Size = Vector3.new(th, h, math.abs(ac:Dot(back))), CFrame = base * CFrame.fromMatrix((a + c) / 2, -right, up, -back), Color = color, Material = mat or M.SmoothPlastic})
	end
	-- a curve round (x, y): degrees run clockwise from the top; o tilts it in the wall's plane
	function d.arc(x, y, z, r, th, a0, a1, n, color, mat, squash)
		local step = (a1 - a0) / n
		local seg = r * math.rad(math.abs(step)) * 1.14
		for i = 0, n - 1 do
			local a = math.rad(a0 + (i + 0.5) * step)
			d.box(x + math.sin(a) * r, y + math.cos(a) * r * (squash or 1), z, seg, th, th, color, mat, -math.deg(a))
		end
	end
	-- a cog with its teeth
	function d.gear(x, y, r, teeth, color)
		d.disc(x, y, 1.5, r * 2, color, M.Metal)
		for i = 0, teeth - 1 do
			local a = i * 2 * math.pi / teeth
			d.box(x + math.sin(a) * (r + 0.2), y + math.cos(a) * (r + 0.2), 1.5, r * 0.34, 0.9, 0.4, color, M.Metal, -math.deg(a))
		end
	end
	-- raised lettering on the surface at height z
	function d.text(x, y, z, size, str, color)
		local face = p({Name = "SculptFace", Size = Vector3.new(size, size, 0.05) * scale, CFrame = at(x, y, z), Transparency = 1})
		local t = Kit_text(face, str, color)
		return t
	end
	-- a backing panel for a scene
	function d.plate(w, h, color)
		d.box(0, 0, 0.7, w, h, 0.5, color)
	end
	-- the wall mount every piece hangs on: a soft dark shadow plate and a trim ring, so it sits on the wall instead of floating
	d.box(0, 0, 0.1, 13, 13.4, 0.2, T.WallColor:Lerp(Color3.new(0, 0, 0), 0.62))
	d.box(0, 6.7, 0.28, 13.6, 0.5, 0.5, T.Trim, M.SmoothPlastic)
	d.box(0, -6.7, 0.28, 13.6, 0.5, 0.5, T.Trim, M.SmoothPlastic)
	d.box(-6.5, 0, 0.28, 0.5, 13.4, 0.5, T.Trim, M.SmoothPlastic)
	d.box(6.5, 0, 0.28, 0.5, 13.4, 0.5, T.Trim, M.SmoothPlastic)
	designs[(k - 1) % #designs + 1](d)
end

Kit_text = function(face, str, color)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 16
	sg.LightInfluence = 0.8
	sg.MaxDistance = 220
	sg.Parent = face
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color
	t.Text = str
	t.Parent = sg
	return t
end

return VaultDecor

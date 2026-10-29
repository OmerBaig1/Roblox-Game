-- Tests for the vault's game slots: exactly six per level, every one a real spot, laid out so none overlap, the
-- runner down the middle stays clear, and none sit on the shopkeeper's counter - on every level's actual size.
return function(t)
	local C = require(game:GetService("ServerScriptService").StealAGame.Config)
	local expect = t.expect
	local RING = 5.5 -- each slot's glowing ring

	t.test("six slots per level", function()
		expect.equal(C.PEDESTALS, 6)
		expect.equal(#C.PEDESTAL_LAYOUT, C.PEDESTALS)
	end)

	t.test("slots fit on every level", function()
		for level = 1, C.NUM_LEVELS do
			local L = C.LEVELS[level]
			local half = L.Width / 2
			local pts = {}
			for i, p in ipairs(C.PEDESTAL_LAYOUT) do
				local x, z = p[1] * half, p[2] * L.Len
				-- inside the walls, clear of the 26-stud runner, past the counter (30% in)
				expect.truthy(math.abs(x) + RING < half - 2)
				expect.truthy(math.abs(x) - RING >= 13)
				expect.truthy(z > L.Len * 0.3 + 20)
				pts[i] = Vector3.new(x, 0, z)
			end
			for i = 1, #pts do
				for j = i + 1, #pts do
					if (pts[i] - pts[j]).Magnitude < RING * 2 + 8 then
						error("slots " .. i .. " and " .. j .. " crowd each other on level " .. level)
					end
				end
			end
		end
	end)

	t.test("every level has at least six different games to show", function()
		for level = 1, C.NUM_LEVELS do
			expect.truthy(#C.LEVELS[level].Games >= C.PEDESTALS)
		end
	end)
end

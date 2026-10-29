-- Tests for the vault layout and the earning rules in Config.
-- The rule: a game from a deeper area earns more than any game from a shallower one, except
--   * a Legendary may earn up to 10% more than a Common from the very next area
--   * a premium rarity (Mythic and up) may beat the next area's Common and Uncommon, nothing better
return function(t)
	local C = require(game:GetService("ServerScriptService").StealAGame.Config)
	local expect = t.expect
	local LEGENDARY = 5

	t.test("40 levels: 2 per area, 20 areas", function()
		expect.equal(#C.ZONES, 20)
		expect.equal(C.NUM_LEVELS, 40)
		for zi, zone in ipairs(C.ZONES) do
			expect.equal(#zone.Levels, 2)
			expect.equal(zone.LastLevel - zone.FirstLevel, 1)
			expect.truthy(zi > 10 or #zone.Stores == 5)
		end
	end)

	t.test("every original game is still in the vault, once", function()
		local n = 0
		for old, names in pairs(C.LEGACY) do
			for _, name in ipairs(names) do
				n += 1
				local level = C.GAME_LEVEL[name]
				expect.truthy(level)
				-- same area as before
				expect.equal(C.LEVELS[level].ZoneIndex, math.ceil(old / 5))
			end
		end
		expect.equal(n, 151)
		local total = 0
		for _ in pairs(C.GAME_LEVEL) do
			total += 1
		end
		expect.equal(total, 151 + 120)
	end)

	t.test("original areas are 3.5 old sublevels long", function()
		for zi = 1, 10 do
			local z = C.ZONES[zi]
			expect.equal(C.LEVELS[z.FirstLevel].Len + C.LEVELS[z.LastLevel].Len, 3.5 * C.OLD_SEG_LEN)
		end
	end)

	t.test("premium rarities unlock one by one", function()
		local last = 0
		for r = 6, #C.RARITIES do
			expect.truthy(C.RARITIES[r].MinArea > last)
			last = C.RARITIES[r].MinArea
			expect.falsy(C.rarityAllowed(C.ZONES[last - 1].LastLevel, r))
			expect.truthy(C.rarityAllowed(C.ZONES[last].FirstLevel, r))
		end
	end)

	t.test("rarer copies of the same game earn more", function()
		for level = 1, C.NUM_LEVELS do
			for r = 2, #C.RARITIES do
				if C.rarityAllowed(level, r) then
					expect.truthy(C.gameIncome(level, r) >= C.gameIncome(level, r - 1))
				end
			end
		end
	end)

	t.test("deeper areas earn more (with only the allowed exceptions)", function()
		local bad = {}
		local legendaryBeats = 0
		for a = 1, C.NUM_LEVELS do
			for b = 1, C.NUM_LEVELS do
				local za, zb = C.LEVELS[a].ZoneIndex, C.LEVELS[b].ZoneIndex
				if zb > za then
					for r1 = 1, #C.RARITIES do
						for r2 = 1, #C.RARITIES do
							if C.rarityAllowed(a, r1) and C.rarityAllowed(b, r2) then
								local low, high = C.gameIncome(a, r1), C.gameIncome(b, r2)
								if low >= high then
									local nextArea = zb == za + 1
									local ok = nextArea and r1 == LEGENDARY and r2 == 1 and low <= high * 1.1
										or nextArea and r1 > LEGENDARY and r2 <= 2
									if ok and r1 == LEGENDARY then
										legendaryBeats += 1
									end
									if not ok then
										table.insert(bad, string.format("L%d %s $%d >= L%d %s $%d", a, C.RARITIES[r1].Name, low, b, C.RARITIES[r2].Name, high))
									end
								end
							end
						end
					end
				end
			end
		end
		if #bad > 0 then
			error(#bad .. " inversions, first: " .. table.concat(bad, "; ", 1, math.min(5, #bad)))
		end
		-- the Legendary exception exists, but only narrowly
		expect.truthy(legendaryBeats > 0)
	end)

	t.test("old saves map to the same game", function()
		expect.equal(C.LEGACY[1][1], "Pang")
		expect.equal(C.LEGACY[50][4], "Devil May Nubs V")
		expect.equal(C.GAME_LEVEL["Devil May Nubs V"], 20)
		expect.equal(C.LEGACY_BEST[1], 1)
		expect.equal(C.LEGACY_BEST[3], 2)
		expect.equal(C.LEGACY_BEST[50], 20)
	end)

	t.test("the deepest level stays escapable at max speed", function()
		local guard = C.realSpeed(C.guardPoints(C.NUM_LEVELS))
		expect.truthy(guard < C.MAX_REAL_SPEED)
		for level = 2, C.NUM_LEVELS do
			expect.truthy(C.guardPoints(level) > C.guardPoints(level - 1))
		end
	end)
end

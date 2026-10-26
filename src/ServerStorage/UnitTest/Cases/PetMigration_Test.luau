-- Tests for ServerScriptService.StealAGame.PetMigration against its contract in docs/pets/INTEGRATION.md
-- (Phase 3): every old pet survives, never lower in rarity or boost, the same old pet always becomes the same new
-- pet, migrating twice changes nothing, and a save keeps its pet ids and equipped list.
return function(t)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local OldData = require(ReplicatedStorage.PetData) -- the 105-pet catalog live saves were written with
	local Catalog = require(ReplicatedStorage.PetSystem.Catalog)
	local M = require(game:GetService("ServerScriptService").StealAGame.PetMigration)
	local expect = t.expect

	local function allOldKeys()
		local keys = {}
		for e = 1, 15 do
			for r = 1, 7 do
				table.insert(keys, e .. "-" .. r)
			end
		end
		return keys
	end

	-- an old-format save: pets with ids 1..n cycling through every old key, some equipped
	local function oldSave(n, eq)
		local keys = allOldKeys()
		local list = {}
		for i = 1, n do
			table.insert(list, {I = i, K = keys[(i - 1) % #keys + 1]})
		end
		return {List = list, Eq = eq or {}, Next = n + 1, Seen = true, Manual = false}
	end

	-- the old catalog really has the 105 keys these tests assume
	t.test("old catalog has 105 pets keyed egg-rarity", function()
		local n = 0
		for _, k in ipairs(allOldKeys()) do
			expect.truthy(OldData.PETS[k])
			n += 1
		end
		expect.equal(n, 105)
	end)

	-- every old key becomes a pet that exists in the new catalog
	t.test("every old key maps to an existing new pet", function()
		for _, k in ipairs(allOldKeys()) do
			local id = M.migrateKey(k)
			expect.truthy(id and Catalog.PETS[id])
		end
	end)

	-- a migrated pet is never a lower rarity than the one it replaces
	t.test("rarity is never lower", function()
		for _, k in ipairs(allOldKeys()) do
			expect.truthy(Catalog.PETS[M.migrateKey(k)].R >= OldData.PETS[k].R)
		end
	end)

	-- a migrated pet never gives less install speed than the one it replaces
	t.test("boost is never lower", function()
		for _, k in ipairs(allOldKeys()) do
			local old, new = OldData.PETS[k].Boost, Catalog.PETS[M.migrateKey(k)].Boost
			if new < old then
				error(string.format("%s: boost %d -> %d", k, old, new))
			end
		end
	end)

	-- old Secrets from eggs whose new egg has no Secret still become a Secret
	t.test("secrets without a secret in their new egg move up to one that has", function()
		for e = 1, 5 do
			local pet = Catalog.PETS[M.migrateKey(e .. "-7")]
			expect.equal(pet.R, 7)
			expect.equal(pet.Egg, 4) -- Frost is the first egg with a Secret
		end
	end)

	-- the same old key always gives the same new pet
	t.test("mapping is deterministic", function()
		for _, k in ipairs(allOldKeys()) do
			expect.equal(M.migrateKey(k), M.migrateKey(k))
		end
	end)

	-- migrating an already migrated key changes nothing
	t.test("migrating a new id returns it unchanged", function()
		for _, k in ipairs(allOldKeys()) do
			local id = M.migrateKey(k)
			expect.equal(M.migrateKey(id), id)
		end
	end)

	-- keys that never existed, and non-strings, give nil instead of erroring
	t.test("invalid keys give nil", function()
		for _, k in ipairs({"16-1", "0-3", "1-8", "1-0", "abc", "", "1-", "-1", "1-2-3"}) do
			expect.equal(M.migrateKey(k), nil)
		end
		expect.equal(M.migrateKey(nil), nil)
		expect.equal(M.migrateKey(12), nil)
		expect.equal(M.migrateKey({}), nil)
	end)

	-- a full bag of 250 old pets comes through whole: same count, same ids, same order, all valid new keys
	t.test("a full old save keeps every pet and its id", function()
		local saved = oldSave(250, {7, 99, 250})
		local out = M.migrateSave(saved)
		expect.equal(#out.List, 250)
		for i, p in ipairs(out.List) do
			expect.equal(p.I, saved.List[i].I)
			expect.equal(p.K, M.migrateKey(saved.List[i].K))
			expect.truthy(Catalog.PETS[p.K])
		end
	end)

	-- the equipped list and the rest of the save are kept, and the save is marked as migrated
	t.test("equipped list and other fields are kept, version is set", function()
		local saved = oldSave(20, {3, 11, 20})
		saved.Manual = true
		local out = M.migrateSave(saved)
		expect.deepEqual(out.Eq, {3, 11, 20})
		expect.equal(out.Next, 21)
		expect.equal(out.Seen, true)
		expect.equal(out.Manual, true)
		expect.equal(out.PetVersion, 2)
	end)

	-- the input save table isn't changed, so a failed load can't half-migrate it
	t.test("does not modify the input save", function()
		local saved = oldSave(5, {1})
		local before = saved.List[1].K
		M.migrateSave(saved)
		expect.equal(saved.List[1].K, before)
		expect.equal(saved.PetVersion, nil)
	end)

	-- running the migration twice gives exactly the result of running it once
	t.test("migrating twice equals migrating once", function()
		local once = M.migrateSave(oldSave(40, {2, 4}))
		local twice = M.migrateSave(once)
		expect.deepEqual(twice, once)
	end)

	-- a save already at version 2 is left alone, even if it contains odd keys
	t.test("a version 2 save is untouched", function()
		local saved = {List = {{I = 1, K = "coalpup"}, {I = 2, K = "1-1"}}, Eq = {1}, Next = 3, PetVersion = 2}
		expect.equal(M.migrateSave(saved), saved)
		expect.equal(saved.List[2].K, "1-1")
	end)

	-- entries that can't be pets are dropped; the good ones around them survive
	t.test("corrupt entries are dropped, the rest kept", function()
		local saved = {List = {{I = 1, K = "3-4"}, {I = 2, K = "99-1"}, "junk", {I = 4}, {I = 5, K = "15-7"}}, Eq = {1, 2, 5}, Next = 6}
		local out = M.migrateSave(saved)
		expect.equal(#out.List, 2)
		expect.equal(out.List[1].I, 1)
		expect.equal(out.List[2].I, 5)
		expect.equal(Catalog.PETS[out.List[2].K].R, 7)
	end)

	-- a brand-new player (no save) and saves without a pet list don't error
	t.test("empty and missing saves are safe", function()
		expect.equal(M.migrateSave(nil), nil)
		expect.equal(M.migrateSave("x"), "x")
		local out = M.migrateSave({})
		expect.equal(#out.List, 0)
		expect.equal(out.PetVersion, 2)
	end)

	-- the new catalog itself: 8 eggs, 60 pets, odds that add to 100 and match the tiers each egg has
	t.test("catalog odds add up and skip tiers an egg lacks", function()
		expect.equal(#Catalog.EGGS, 8)
		local n = 0
		for _ in pairs(Catalog.PETS) do
			n += 1
		end
		expect.equal(n, 60)
		for _, egg in ipairs(Catalog.EGGS) do
			local sum = 0
			for r = 1, 7 do
				sum += egg.Odds[r]
				expect.equal(egg.Odds[r] > 0, egg.Tiers[r] ~= nil)
			end
			expect.near(sum, 100, 1e-6)
		end
	end)

	-- egg 8's boosts match old egg 15's, so the top of the economy doesn't move
	t.test("top egg boost matches the old top egg", function()
		for r = 1, 7 do
			local pool = Catalog.EGGS[8].Tiers[r]
			if pool then
				expect.equal(pool[1].Boost, OldData.PETS["15-" .. r].Boost)
			end
		end
	end)

	-- rolling hits every tier at the right edges and only ever returns pets from that egg
	t.test("roll returns a pet of the egg at the odds boundaries", function()
		for _, egg in ipairs(Catalog.EGGS) do
			local low, high = Catalog.roll(egg, 0, 0), Catalog.roll(egg, 0.999999, 0.999999)
			expect.equal(low.Egg, egg.Index)
			expect.equal(low.R, 1)
			expect.equal(high.Egg, egg.Index)
			expect.equal(high.R, egg.Best.R) -- the very top of the roll is the egg's rarest tier
		end
	end)
end

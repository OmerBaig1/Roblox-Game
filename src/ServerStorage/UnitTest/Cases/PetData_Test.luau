-- Tests for ReplicatedStorage.PetData (the 8-egg premium catalog): odds add to 100 and skip missing tiers, a roll
-- always gives a pet from that egg, ids are unique, and every pet has its model in PetAssets.
return function(t)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local D = require(ReplicatedStorage.PetData)
	local expect = t.expect

	t.test("8 eggs, 60 unique pets, all with models", function()
		expect.equal(#D.EGGS, 8)
		local n = 0
		for id, pet in pairs(D.PETS) do
			n += 1
			expect.equal(pet.Key, id)
			expect.truthy(ReplicatedStorage.PetAssets:FindFirstChild(pet.Model))
		end
		expect.equal(n, 60)
	end)

	t.test("odds add to 100 and missing tiers get 0", function()
		for _, egg in ipairs(D.EGGS) do
			local sum = 0
			for r, chance in ipairs(egg.Odds) do
				sum += chance
				expect.equal(chance > 0, egg.Tiers[r] ~= nil)
			end
			expect.truthy(math.abs(sum - 100) < 1e-6)
		end
	end)

	t.test("rolls stay inside the egg, edges included", function()
		for _, egg in ipairs(D.EGGS) do
			for _, u in ipairs({0, 0.5, 0.999999, 1}) do
				local pet = D.roll(egg, u, u)
				expect.equal(pet.Egg, egg.Index)
			end
		end
		-- the very top of the range is the egg's rarest tier
		local last = D.EGGS[8]
		expect.equal(D.roll(last, 0.9999999, 0).R, 7)
	end)
end

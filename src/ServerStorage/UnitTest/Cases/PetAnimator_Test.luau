-- Tests for ReplicatedStorage.PetSystem.PetAnimator.pace: matches the old 0..1 ramp up to a walk, keeps rising for
-- this game's run speeds (~200 studs/s) and stops at 3.
return function(t)
	local PetAnimator = require(game:GetService("ReplicatedStorage").PetSystem.PetAnimator)
	local pace = PetAnimator.pace
	local expect = t.expect

	t.test("walk speeds keep the old ramp", function()
		expect.near(pace(0), 0)
		expect.near(pace(8), 0.5)
		expect.near(pace(16), 1)
	end)

	t.test("keeps rising past a walk, capped at 3", function()
		expect.near(pace(32), 2)
		expect.near(pace(64), 3)
		expect.near(pace(211), 3)
		expect.near(pace(1e6), 3)
		expect.truthy(pace(20) > pace(16) and pace(40) > pace(20))
	end)
end

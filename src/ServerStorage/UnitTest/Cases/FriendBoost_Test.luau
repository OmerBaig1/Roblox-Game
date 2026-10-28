-- Tests for Config.friendBoost: +10% for the first friend here, +2.5% for each one after, nothing with no friends.
return function(t)
	local C = require(game:GetService("ServerScriptService").StealAGame.Config)
	local expect = t.expect
	local function near(a, b)
		return math.abs(a - b) < 1e-9
	end

	t.test("first friend 10%, then 2.5% each", function()
		expect.equal(C.friendBoost(0), 0)
		expect.truthy(near(C.friendBoost(1), 0.10))
		expect.truthy(near(C.friendBoost(2), 0.125))
		expect.truthy(near(C.friendBoost(3), 0.15))
		expect.truthy(near(C.friendBoost(4), 0.175))
	end)

	t.test("each friend's share adds up to the total", function()
		local sum = 0
		for n = 1, 8 do
			sum += C.friendBoost(n) - C.friendBoost(n - 1)
		end
		expect.truthy(near(sum, C.friendBoost(8)))
	end)
end

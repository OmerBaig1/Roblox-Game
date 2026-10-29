-- Tests for GuardCatch: a guard catches only what its hands can reach, measured on the player's own screen (where
-- the guard really was a moment ago, from its history) and where the player is now. The "chasing at speed" cases
-- are the old false catch: close on the server, yards away on the screen of the player being chased.
return function(t)
	local SSS = game:GetService("ServerScriptService")
	local C = require(SSS.StealAGame.Config)
	local GC = require(SSS.StealAGame.GuardCatch)
	local expect = t.expect
	local V = Vector3.new
	local Z = Vector3.zero
	local REACH = 7

	-- a guard history: running at velocity v and ending at `now` at position p
	local function history(p, v, now)
		local h = {}
		for i = 16, 0, -1 do
			table.insert(h, {T = now - i * 0.05, P = p - v * (i * 0.05)})
		end
		return h
	end

	t.test("the history gives where the guard really was", function()
		local h = history(V(0, 0, 0), V(0, 0, -100), 10)
		expect.near(GC.shown(h, 9.8).Z, 20, 1e-6)
		expect.near(GC.shown(h, 9.825).Z, 17.5, 1e-6)
		expect.near(GC.shown(h, 10).Z, 0, 1e-6)
	end)

	t.test("standing still: only within reach", function()
		expect.truthy(GC.inReach(C, REACH, V(0, 10, 0), V(0, 10, 0), V(0, 3, -6), Z, 0.05))
		expect.falsy(GC.inReach(C, REACH, V(0, 10, 0), V(0, 10, 0), V(0, 3, -9), Z, 0.05))
	end)

	t.test("chasing at speed: close on the server is not enough", function()
		-- both running 100 studs/s along -Z, the guard 5 studs behind on the server, 100 ms ping: the player's
		-- screen still shows the guard where it was about 0.28 s ago. No catch.
		local v = V(0, 0, -100)
		local h = history(V(0, 10, 0), v, 10)
		local shown = GC.shown(h, 10 - GC.delay(C, 0.1))
		expect.falsy(GC.inReach(C, REACH, V(0, 10, 0), shown, V(0, 3, -5), v, 0.1))
		local _, screen = GC.gaps(C, V(0, 10, 0), shown, V(0, 3, -5), v, 0.1)
		expect.truthy(screen > 30)
	end)

	t.test("a guard that has just stopped is still shown where it was", function()
		-- it ran in at 100 studs/s and stopped 4 studs short a moment ago: the screen hasn't caught up yet
		local h = history(V(0, 10, 0), V(0, 0, -100), 10)
		for i = 1, 3 do
			table.insert(h, {T = 10 + i * 0.02, P = V(0, 10, 0)})
		end
		local shown = GC.shown(h, 10.06 - GC.delay(C, 0))
		expect.falsy(GC.inReach(C, REACH, V(0, 10, 0), shown, V(0, 3, -4), Z, 0))
		-- and once it has, the catch is fair
		local later = GC.shown(h, 10.06)
		expect.truthy(GC.inReach(C, REACH, V(0, 10, 0), later, V(0, 3, -4), Z, 0))
	end)

	t.test("chasing at speed: caught when the guard really closes in on the player's screen", function()
		local v = V(0, 0, -100)
		local tp = V(0, 3, -5)
		local aim = GC.aim(C, tp, v, 0.1)
		expect.truthy(aim.Z < tp.Z) -- it leads the player
		-- the guard ran at the aim point: on the player's screen it is now right behind them
		local d = GC.delay(C, 0.1)
		local gp = V(0, 10, GC.now(C, tp, v, 0.1).Z + v.Z * d + 4)
		local h = history(gp, v, 10)
		expect.truthy(GC.inReach(C, REACH, gp, GC.shown(h, 10 - d), tp, v, 0.1))
	end)

	t.test("a huge ping never stretches the reach", function()
		expect.near(GC.delay(C, 5), GC.delay(C, C.GUARD_LAG_MAX), 1e-6)
	end)

	t.test("reach comes from the body and is capped", function()
		local torso = {Position = V(0, 10, 0), Size = V(8, 10, 6)}
		expect.near(GC.reach(C, CFrame.new(0, 8, 0), torso), 3 + C.GUARD_GRAB_MARGIN, 1e-6)
		local huge = {Position = V(0, 10, 0), Size = V(8, 10, 60)}
		expect.equal(GC.reach(C, CFrame.new(0, 8, 0), huge), C.GUARD_REACH_MAX)
	end)
end

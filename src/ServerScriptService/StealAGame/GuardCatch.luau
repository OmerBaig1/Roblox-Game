--[[
	GuardCatch: the maths of a fair catch (pure functions, so the unit tests can check them).

	Why a guard used to "catch" people it was visibly short of: the server judged the guard against where it had
	last heard the player was, but a player's screen shows the guard where the server had it a moment ago (measured
	about 0.18 s in a playtest, plus their ping), and the server hears where the player is a moment late too
	(measured 0.16 s, plus ping). With both running, the gap the player SEES is bigger than the server's - several studs on the first level, tens of studs deep in the vault - and the reach was generous on top.

	Now:
	  shown   the server keeps a short history of where each guard has been, so it knows exactly where the player's
	          screen is showing it right now (no guessing from its speed: a guard that has just stopped or turned is
	          still shown where it really was)
	  inReach a catch needs BOTH gaps within reach: the player's own screen (where they are to where they see the
	          guard) and the server's (where they are now to where the guard really is). Lag never makes a reach
	          longer - the server's gap is only allowed the distance the guard itself really covered in that moment.
	  aim     the guard runs at where the player will be when its movement reaches their screen
	  reach   the front of the guard's body plus an arm's grab, from its measured size, at least what its arms can
	          reach for its scale, capped (a huge model never reaches further than C.GUARD_REACH_MAX)

	What used to let a runner get away with the guard on top of them: all of the above is an ESTIMATE of the player's
	screen, and its error grows with speed (0.05 s off at 200 studs/s is 10 studs). The guard, aiming at where the player
	will be, overtook them and settled just outside that estimate for as long as they kept running. So now:
	  the client reports the gap it really shows (GuardGap remote), which ends any argument about the screen
	  contact    the server's own backstop, needing nothing from the client: once the guard has really reached or passed
	             the player, the catch lands after contactTime (well after any honest report would have) unless they
	             have genuinely pulled away (escapeGap) by then
]]

local GC = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- how far the front of the body is from the guard's centre (torso front face, along its facing)
function GC.front(rootCF, torso)
	if not torso then
		return 3
	end
	local d = rootCF:PointToObjectSpace(torso.Position)
	return math.abs(d.Z) + torso.Size.Z / 2
end

-- the front of the body + a grab, capped
function GC.reach(C, rootCF, torso, scale)
	return math.min(math.max(GC.front(rootCF, torso) + C.GUARD_GRAB_MARGIN, (scale or 0) * C.GUARD_REACH_PER_SCALE), C.GUARD_REACH_MAX)
end

-- has the guard really reached the player, or run past them? (true positions, no estimates)
function GC.contact(reach, gp, tp, tv)
	local gap = flat(gp - tp)
	return gap.Magnitude <= reach or (flat(tv).Magnitude > 1 and gap:Dot(flat(tv)) > 0)
end

-- how far ahead or behind a guard that made contact can be before the player has truly got away
function GC.escapeGap(C, reach, tv, ping)
	return reach + flat(tv).Magnitude * (GC.delay(C, ping) + C.PLAYER_INTERP_DELAY + math.clamp(ping or 0, 0, C.GUARD_LAG_MAX)) * 1.3
end

-- how long the backstop waits. Contact on the server reaches the screen only once the guard has closed the lag gap, which
-- measured 1.2-1.5 s (L15 and L30); a working client has reported the catch by then, so this only ever meets a client that isn't reporting
function GC.contactTime(C, ping)
	return 2.5 + math.clamp(ping or 0, 0, C.GUARD_LAG_MAX)
end

-- where a guard closing in should stop: just in front of you (its centre never runs through you)
function GC.standoff(front)
	return front + 1.5
end

-- how long ago the player's screen is showing the guard
function GC.delay(C, ping)
	return math.clamp(ping or 0, 0, C.GUARD_LAG_MAX) + C.GUARD_INTERP_DELAY
end

-- where the guard was at time `at`, from its history ({T, P} oldest first)
function GC.shown(hist, at)
	if #hist == 0 then
		return nil
	end
	if at <= hist[1].T then
		return hist[1].P
	end
	for i = #hist, 1, -1 do
		local h = hist[i]
		if h.T <= at then
			local n = hist[i + 1]
			if not n then
				return h.P
			end
			return h.P:Lerp(n.P, (at - h.T) / (n.T - h.T))
		end
	end
	return hist[1].P
end

-- where the player really is now: the server hears about their movement a moment late
function GC.now(C, tp, tv, ping)
	return tp + flat(tv) * (math.clamp(ping or 0, 0, C.GUARD_LAG_MAX) + C.PLAYER_INTERP_DELAY)
end

-- the two gaps: the player's screen (player now to the guard as shown) and the server's (player now to guard now)
function GC.gaps(C, gp, shownGp, tp, tv, ping)
	local you = GC.now(C, tp, tv, ping)
	return flat(you - gp).Magnitude, flat(you - shownGp).Magnitude
end

function GC.inReach(C, reach, gp, shownGp, tp, tv, ping, slack)
	local server, screen = GC.gaps(C, gp, shownGp, tp, tv, ping)
	slack = slack or 1
	return screen <= reach * slack and server <= reach * slack + flat(gp - shownGp).Magnitude
end

-- where to run so the guard on the player's screen meets them: where they are now, plus how far they'll go before
-- the guard's movement reaches their screen
function GC.aim(C, tp, tv, ping)
	return GC.now(C, tp, tv, ping) + flat(tv) * GC.delay(C, ping)
end

return GC

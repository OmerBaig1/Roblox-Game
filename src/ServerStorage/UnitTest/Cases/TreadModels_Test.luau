-- Tests for TreadModels: one machine per treadmill level, each a different shape, all inside the
-- envelope that keeps the runner in view, each with a working belt and a modest part budget.
return function(t)
	local SSS = game:GetService("ServerScriptService")
	local C = require(SSS.StealAGame.Config)
	local TM = require(SSS.StealAGame.TreadModels)
	local E = TM.ENVELOPE
	local expect = t.expect
	local EPS = 0.02

	-- every machine, built once at the world origin (never parented into the game)
	local built = {}
	for level = 0, #TM.MODELS - 1 do
		local model = Instance.new("Model")
		local slats = TM.build(level, model, CFrame.new())
		built[level] = {Model = model, Slats = slats, Name = TM.MODELS[level + 1].Name}
	end

	-- a part's bounding box in design space
	local function bounds(p)
		local cf = TM.ORIGIN:ToObjectSpace(p.CFrame)
		local s = p.Size / 2
		-- a wedge only fills half its box: measure its six real corners
		if p:IsA("WedgePart") then
			local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
			for _, c in ipairs({{-1, -1, -1}, {1, -1, -1}, {-1, -1, 1}, {1, -1, 1}, {-1, 1, 1}, {1, 1, 1}}) do
				local v = cf:PointToWorldSpace(Vector3.new(c[1] * s.X, c[2] * s.Y, c[3] * s.Z))
				lo, hi = lo:Min(v), hi:Max(v)
			end
			return lo, hi
		end
		local ext = s
		if not (p:IsA("Part") and p.Shape == Enum.PartType.Ball) then
			local X, Y, Z = cf.XVector, cf.YVector, cf.ZVector
			ext = Vector3.new(
				math.abs(X.X) * s.X + math.abs(Y.X) * s.Y + math.abs(Z.X) * s.Z,
				math.abs(X.Y) * s.X + math.abs(Y.Y) * s.Y + math.abs(Z.Y) * s.Z,
				math.abs(X.Z) * s.X + math.abs(Y.Z) * s.Y + math.abs(Z.Z) * s.Z)
		end
		return cf.Position - ext, cf.Position + ext
	end

	-- everything that would hide the runner or hang off the pad
	local function problems(model)
		local out = {}
		for _, p in ipairs(model:GetDescendants()) do
			-- (fully invisible parts only carry effects, and can't hide anyone)
			if p:IsA("BasePart") and p.Name ~= "Slat" and p.Transparency < 1 then
				local lo, hi = bounds(p)
				local function bad(why)
					local c = (lo + hi) / 2
					table.insert(out, string.format("%s %s (centre %.1f, %.1f, %.1f, top %.2f)", p.Name, why, c.X, c.Y, c.Z, hi.Y))
				end
				local overBelt = lo.Z < E.BeltHalfL - EPS and hi.Z > -E.BeltHalfL + EPS
				local inLane = lo.X < E.RunnerHalfW - EPS and hi.X > -E.RunnerHalfW + EPS
				local outsideLane = lo.X < -E.RunnerHalfW - EPS or hi.X > E.RunnerHalfW + EPS
				if hi.X > E.HalfW + EPS or lo.X < -E.HalfW - EPS or lo.Z < E.FrontZ - EPS or hi.Z > E.BackZ + EPS or hi.Y > E.MaxY + EPS or lo.Y < -0.95 then -- props may sink into the 1-stud pad
					bad("sticks out of the treadmill's space")
				end
				if overBelt and inLane and hi.Y > TM.BELT_TOP + EPS then
					bad("is in the runner's space")
				end
				if overBelt and outsideLane and hi.Y > E.SideMaxY + EPS then
					bad("is too tall beside the runner")
				end
				if lo.Z < -E.BeltHalfL - EPS and inLane and p.Transparency < E.SeeThrough and hi.Y > E.FrontLowY + EPS and lo.Y < E.FrontHighY - EPS then
					bad("hides the runner from the front")
				end
				if hi.Z > E.BeltHalfL + EPS and hi.Y > E.BackMaxY + EPS then
					bad("is too tall behind the runner")
				end
			end
		end
		return out
	end

	t.test("one machine for every level, each with its own name", function()
		expect.equal(#TM.MODELS, C.TREAD_MAX_LEVEL + 1)
		local seen = {}
		for _, m in ipairs(TM.MODELS) do
			expect.falsy(seen[m.Name])
			seen[m.Name] = true
		end
	end)

	t.test("every machine has a full belt in the right place", function()
		for _, b in pairs(built) do
			expect.equal(#b.Slats, TM.SLAT_COUNT)
			for i, slat in ipairs(b.Slats) do
				local p = TM.ORIGIN:PointToObjectSpace(slat.Position)
				expect.near(p.Z, TM.BELT_START + (i - 1) * TM.SLAT_GAP, 1e-3)
				expect.near(p.Y + slat.Size.Y / 2, TM.BELT_TOP, 1e-3)
			end
		end
	end)

	t.test("every machine keeps the runner in view and fits on the pad", function()
		local report = {}
		for level = 0, #TM.MODELS - 1 do
			for _, line in ipairs(problems(built[level].Model)) do
				table.insert(report, string.format("L%d %s: %s", level, built[level].Name, line))
			end
		end
		if #report > 0 then
			error(#report .. " problems:\n" .. table.concat(report, "\n", 1, math.min(#report, 25)))
		end
	end)

	t.test("part, light and effect budget; only the deck is solid", function()
		for level, b in pairs(built) do
			local parts, lights, emitters, solid = 0, 0, 0, 0
			for _, d in ipairs(b.Model:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
					if d.CanCollide then
						solid += 1
					else
						expect.falsy(d.CanQuery)
					end
				elseif d:IsA("Light") then
					lights += 1
				elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
					emitters += 1
				end
			end
			if parts > E.MaxParts or lights > E.MaxLights or emitters > E.MaxEmitters or solid < 1 then
				error(string.format("L%d %s: %d parts, %d lights, %d effects, %d solid", level, b.Name, parts, lights, emitters, solid))
			end
		end
	end)

	t.test("every machine stands on its tier's stage, with one more rank light lit each level", function()
		local last = 0
		for level = 0, #TM.MODELS - 1 do
			local rims, lit = 0, 0
			for _, p in ipairs(built[level].Model:GetDescendants()) do
				if p.Name == "TierRim" then
					rims += 1
				elseif p.Name == "TierPip" and p.Material == Enum.Material.Neon then
					lit += 1
				end
			end
			expect.equal(rims, 4)
			expect.equal(lit, TM.rank(level) * 2)
			local tierIndex = table.find(TM.TIERS, TM.tier(level))
			expect.truthy(tierIndex >= last)
			last = tierIndex
		end
		expect.equal(TM.tier(#TM.MODELS - 1).Name, "MAX")
		expect.equal(TM.rank(0), 1)
		expect.equal(TM.rank(2), 3)
		expect.equal(TM.rank(3), 1)
		expect.equal(TM.rank(#TM.MODELS - 1), TM.LEVELS_PER_TIER)
	end)

	t.test("prices and speed rise at every step, and each step costs more per speed gained", function()
		expect.equal(#C.TREAD_GAINS, C.TREAD_MAX_LEVEL + 1)
		expect.equal(#C.TREAD_COSTS, C.TREAD_MAX_LEVEL)
		local lastRatio = 0
		for level = 0, C.TREAD_MAX_LEVEL - 1 do
			expect.truthy(C.treadGain(level + 1) > C.treadGain(level))
			local ratio = C.treadCost(level) / (C.treadGain(level + 1) - C.treadGain(level))
			expect.truthy(ratio > lastRatio)
			lastRatio = ratio
			if level > 0 then
				expect.truthy(C.treadCost(level) > C.treadCost(level - 1))
			end
		end
		-- no cheap first purchases: the old first three were $200, $400 and $800
		expect.truthy(C.treadCost(0) >= 2000)
	end)

	t.test("an old 0-40 save never trains slower on the new ladder", function()
		expect.equal(C.treadLevelFromOld(0), 0)
		expect.equal(C.treadLevelFromOld(40), C.TREAD_MAX_LEVEL)
		local last = 0
		for old = 0, 40 do
			local new = C.treadLevelFromOld(old)
			expect.truthy(new >= last)
			last = new
			expect.truthy(C.treadGain(new) >= 1.4 ^ old)
		end
	end)

	t.test("travelling parts follow paths that stay on the pad", function()
		local report = {}
		for level, b in pairs(built) do
			for _, d in ipairs(b.Model:GetDescendants()) do
				if d:HasTag("TreadAnim") and d:GetAttribute("Fx") == "travel" then
					local i = 1
					while d:GetAttribute("P" .. i) do
						local p = TM.ORIGIN:PointToObjectSpace(d:GetPivot():PointToWorldSpace(d:GetAttribute("P" .. i)))
						if math.abs(p.X) > E.HalfW + 0.3 or p.Z < E.FrontZ - 0.3 or p.Z > E.BackZ + 0.3 or p.Y > E.MaxY + 0.3 or p.Y < -0.5 then
							table.insert(report, string.format("L%d %s: %s point %d at (%.1f, %.1f, %.1f)", level, b.Name, d:GetChildren()[1].Name, i, p.X, p.Y, p.Z))
						end
						i += 1
					end
					expect.truthy(i > 2)
				end
			end
		end
		if #report > 0 then
			error(table.concat(report, "\n"))
		end
	end)

	t.test("everything that moves is marked with a kind the client knows", function()
		local kinds = {spin = true, swing = true, slide = true, orbit = true, travel = true, gauge = true, pulse = true, flicker = true, bolt = true}
		for level, b in pairs(built) do
			local n = 0
			for _, d in ipairs(b.Model:GetDescendants()) do
				if d:HasTag("TreadAnim") then
					n += 1
					expect.truthy(kinds[d:GetAttribute("Fx")])
					expect.truthy(#d:GetChildren() > 0)
				end
			end
			-- every machine has to be visibly alive, and the belt must stay directly under the machine for the client's belt loop
			if n < 5 then
				error(string.format("L%d %s only has %d moving groups", level, b.Name, n))
			end
			for _, slat in ipairs(b.Slats) do
				expect.equal(slat.Parent, b.Model)
			end
		end
	end)

	-- the multiset of part shapes and sizes, so a recolour or a copy with one extra piece gets caught
	-- (the shared tier stage is left out: it is meant to be the same across a tier)
	t.test("no two machines share most of their shapes", function()
		local bags = {}
		for level, b in pairs(built) do
			local bag = {}
			for _, p in ipairs(b.Model:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "Slat" and p.Name ~= "Deck" and p.Name:sub(1, 4) ~= "Tier" then
					local s = p.Size
					local key = string.format("%s%s %.1f %.1f %.1f", p.ClassName, p:IsA("Part") and p.Shape.Name or "", s.X, s.Y, s.Z)
					bag[key] = (bag[key] or 0) + 1
				end
			end
			bags[level] = bag
		end
		local report = {}
		for a = 0, #TM.MODELS - 1 do
			for b = a + 1, #TM.MODELS - 1 do
				local shared, total = 0, 0
				for key, n in pairs(bags[a]) do
					shared += math.min(n, bags[b][key] or 0)
					total += math.max(n, bags[b][key] or 0)
				end
				for key, n in pairs(bags[b]) do
					if not bags[a][key] then
						total += n
					end
				end
				if shared / total >= 0.35 then
					table.insert(report, string.format("L%d and L%d share %d%%", a, b, math.floor(shared / total * 100)))
				end
			end
		end
		if #report > 0 then
			error(table.concat(report, "; "))
		end
	end)
end

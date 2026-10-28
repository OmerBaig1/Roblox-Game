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
			if p:IsA("BasePart") and p.Name ~= "Slat" then
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

	-- the multiset of part shapes and sizes, so a recolour or a copy with one extra piece gets caught
	t.test("no two machines share most of their shapes", function()
		local bags = {}
		for level, b in pairs(built) do
			local bag = {}
			for _, p in ipairs(b.Model:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "Slat" and p.Name ~= "Deck" then
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

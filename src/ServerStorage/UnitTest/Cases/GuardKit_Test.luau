-- Tests for ReplicatedStorage.GuardKit against every real guard rig: joints on the right sides, every motion runs,
-- the solver keeps the lowest point of the body on the floor (nothing sinks in, nothing floats unless it's meant to),
-- a planted lean keeps the feet still, and every laugh recovers to the guard's normal posture.
return function(t)
	local K = require(game:GetService("ReplicatedStorage").GuardKit)
	local Guards = require(game:GetService("ServerScriptService").StealAGame.Guards)
	local models = game:GetService("ServerStorage").GuardModels
	local expect = t.expect

	local rigs = {}
	for level, g in ipairs(Guards.ROSTER) do
		local model = models[string.format("L%02d", level)]
		rigs[level] = {Model = model, Rig = K.measure(model), Key = g.Key}
	end

	t.test("every rig measures, with each limb on its own side", function()
		for level, r in ipairs(rigs) do
			if not r.Rig then
				error("level " .. level .. " has no usable rig")
			end
			local m = r.Model
			expect.truthy(m.LeftArm.Position.X < m.RightArm.Position.X)
			expect.truthy(m.LeftLeg.Position.X < m.RightLeg.Position.X)
		end
	end)

	-- runs a pose and checks the result: finite, and the lowest point exactly on the floor plus the pose's own air,
	-- minus its Sink (the only deliberate way under the floor: the shark and the mole, burrowing)
	local function check(r, label, fn)
		local p = K.newPose()
		fn(p)
		local tr, lift = K.solve(r.Rig, p)
		local R = tr.Root - tr.Root.Position
		local low = K.lowest(r.Rig, R, {LH = tr.LH, RH = tr.RH}, {LS = tr.LS, RS = tr.RS}, {LK = tr.LK, RK = tr.RK}) + tr.Root.Position.Y
		local air = (math.max(p.Off.Y, 0) - (p.Sink or 0)) * r.Rig.Scale
		if low ~= low or math.abs(low - (r.Rig.Rest + air)) > 1e-3 then
			error(string.format("%s %s: lowest point %.3f, floor %.3f", r.Key, label, low, r.Rig.Rest + air))
		end
	end

	t.test("every idle, stride, grab and laugh stays on the floor", function()
		for _, r in ipairs(rigs) do
			local m = K.MOTION[r.Key]
			for x = 0, 20, 0.37 do
				check(r, "idle", function(p) m.Idle(p, x) end)
			end
			for ph = 0, 4 * math.pi, 0.21 do
				check(r, "chase", function(p) m.Gait(p, ph, {Run = 1, T = ph}) end)
				check(r, "walk", function(p) m.Gait(p, ph, {Run = 0.6, T = ph}) end)
			end
			for a = 0, 2.2, 0.05 do
				check(r, "grab", function(p) m.Grab(p, a) end)
				check(r, "laugh", function(p) m.Laugh(p, a) end)
				check(r, "whiff", function(p) K.whiff(p, a) end)
			end
		end
	end)

	t.test("a planted lean bends over the legs instead of swinging the feet", function()
		for _, r in ipairs(rigs) do
			local rig = r.Rig
			local p = K.newPose()
			p.Root = Vector3.new(-0.35, 0, 0)
			local tr = K.solve(rig, p)
			local torso = rig.C0.Root * tr.Root * rig.C1i.Root
			local rest = rig.C0.Root * rig.C1i.Root
			for _, k in ipairs({"LH", "RH"}) do
				local now = torso * rig.C0[k] * tr[k] * rig.C1i[k] * rig.Feet[k][1]
				local was = rest * rig.C0[k] * rig.C1i[k] * rig.Feet[k][1]
				local slide = Vector3.new(now.X - was.X, 0, now.Z - was.Z).Magnitude
				if slide > 0.1 then
					error(string.format("%s: a lean slides the %s foot %.3f studs", r.Key, k, slide))
				end
			end
		end
	end)

	t.test("every laugh hands back to the normal posture", function()
		for _, r in ipairs(rigs) do
			local p = K.newPose()
			K.MOTION[r.Key].Laugh(p, 2.0)
			for _, k in ipairs({"Root", "Neck"}) do
				local v = p[k]
				-- (a whole turn counts as none)
				local x = math.abs((v.X + math.pi) % (2 * math.pi) - math.pi)
				if x > 0.05 or math.abs(v.Z) > 0.05 then
					error(r.Key .. "'s laugh ends tilted at " .. k)
				end
			end
		end
	end)
	t.test("Kage's katana: palm on the handle from the grip on, blade never in his torso or head", function()
		local model = game:GetService("ServerStorage").GuardModels.L13:Clone()
		local rig = K.measure(model)
		local M = K.MOTION.kage
		local d = K.drawSetup(model, rig, M.Carry)
		local blade, torso, head = model.Gear_Katana, model.Torso, model.Head
		local function inside(sword, cf, part)
			for i = -6, 6 do
				local pt = cf:PointToObjectSpace(sword * Vector3.new(0, i / 6 * blade.Size.Y / 2, 0))
				local h = part.Size * 0.4
				if math.abs(pt.X) < h.X and math.abs(pt.Y) < h.Y and math.abs(pt.Z) < h.Z then
					return true
				end
			end
			return false
		end
		local function check(pose)
			local tr = K.solve(rig, pose)
			local neck = rig.C0.Neck * tr.Neck * rig.C1i.Neck
			for p = 0, 1, 0.02 do
				local rs, el, sword = K.draw(d, tr.RS, p)
				expect.falsy(inside(sword, CFrame.identity, torso) or inside(sword, neck, head))
				if p >= 0.3 then
					local palm = (d.C0 * rs * d.C1i * d.EC0 * el * d.EC1i) * d.Hand
					expect.truthy((palm - sword * d.HandleOff).Magnitude < 0.02)
				end
			end
		end
		for x = 0, 6, 0.4 do
			local g, i = K.newPose(), K.newPose()
			M.Gait(g, x, {T = 0, Run = 1})
			M.Idle(i, x)
			check(g)
			check(i)
		end
		for a = 0, 0.6, 0.06 do
			local g = K.newPose()
			M.Grab(g, a)
			check(g)
		end
		for a = 0, 2, 0.2 do
			local l = K.newPose()
			M.Laugh(l, a)
			check(l)
		end
		model:Destroy()
	end)
end

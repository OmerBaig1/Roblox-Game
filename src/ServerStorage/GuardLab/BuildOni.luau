-- Studio-only: assembles the Oni Samurai rig from its generations in workspace._OniLab (BodyB: asset 88798933493467, HeadC: 111711097926842),
-- split by segment_mesh into upper and lower arms and legs.
return function(opts)
	opts = opts or {}
	local Lab = game.ServerStorage.GuardLab.Review_Nov06
	local b = Lab.BodyB
	local WX, WZ = opts.WX or 1.3, opts.WZ or 1.22 -- how much broader than the generated body: shoulders, chest and hips
	local LIMB = opts.Limb or 1.14 -- arms and legs are thickened this much on top, so they look heavy rather than just further apart
	local RK = require(game.ServerStorage.GuardLab.GuardRigKit:Clone())
	local M = Instance.new("Model")
	M.Name = "OniNew"
	local function take(p, name)
		local c = p:Clone()
		c.Name, c.Parent, c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.Massless, c.CastShadow = name, M, true, false, false, false, true, true
		return c
	end
	local T = take(b.torso.torso_geom, "Torso")
	-- segment_mesh hands each piece back turned 180 about the source's centre: put them back
	local function limb(folder, upper, lower, upName, loName)
		local u, f = folder[upper .. "_Node"][upper], folder[lower .. "_Node"][lower]
		local lo = (u.Position - u.Size / 2):Min(f.Position - f.Size / 2)
		local hi = (u.Position + u.Size / 2):Max(f.Position + f.Size / 2)
		local c = (lo + hi) / 2
		local function fix(p, name)
			local q = take(p, name)
			local rel = p.Position - c
			q.CFrame = CFrame.new(c + Vector3.new(-rel.X, rel.Y, -rel.Z)) * p.CFrame.Rotation * CFrame.Angles(0, math.pi, 0)
			return q
		end
		return fix(u, upName), fix(f, loName)
	end
	local AU, AL = "upper arm and shoulder above the elbow", "forearm and hand from the elbow down"
	local LU, LL = "upper leg above the knee", "lower leg from the knee down including boot"
	local LA, LF = limb(b.ArmL, AU, AL, "LeftArm", "LeftForearm")
	local RA, RF = limb(b.ArmR, AU, AL, "RightArm", "RightForearm")
	local LT, LS = limb(b.LegL, LU, LL, "LeftLeg", "LeftShin")
	local RT, RS = limb(b.LegR, LU, LL, "RightLeg", "RightShin")
	-- broaden the body about its centre line
	local cx, cz = T.Position.X, T.Position.Z
	for _, p in ipairs({T, LA, LF, RA, RF, LT, LS, RT, RS}) do
		local extra = p == T and 1 or LIMB
		local rot = p.CFrame.Rotation
		p.Size = Vector3.new(p.Size.X * WX * extra, p.Size.Y, p.Size.Z * WZ * extra)
		p.CFrame = CFrame.new(cx + (p.Position.X - cx) * WX, p.Position.Y, cz + (p.Position.Z - cz) * WZ) * rot
	end
	local src = Lab.HeadC:FindFirstChildWhichIsA("BasePart", true)
	local H = take(src, "Head")
	H.Size = H.Size * ((opts.HeadW or 3.7) / src.Size.X)
	local torsoTop = T.Position.Y + T.Size.Y / 2
	H.CFrame = CFrame.new(T.Position.X, torsoTop + H.Size.Y * (opts.HeadUp or 0.2), T.Position.Z - 0.2 * WZ) * src.CFrame.Rotation
	local cf, size = M:GetBoundingBox()
	M.PrimaryPart = T
	M:ScaleTo(5.6 / size.Y)
	cf, size = M:GetBoundingBox()
	M:PivotTo(M:GetPivot() + Vector3.new(-T.Position.X, size.Y / 2 - cf.Position.Y, -T.Position.Z))
	M.PrimaryPart = nil
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency, root.CanCollide, root.Anchored = "HumanoidRootPart", Vector3.new(2, 2, 1), 1, true, true
	root.Parent = M
	M.PrimaryPart = root
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.Parent = M
	RK.refit(M)
	local function joint(name, p0, p1, pivot)
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1 = name, p0, p1
		m.C0, m.C1 = p0.CFrame:Inverse() * CFrame.new(pivot), p1.CFrame:Inverse() * CFrame.new(pivot)
		m.Parent = p1
		return m
	end
	local function elbow(f)
		return Vector3.new(f.Position.X, f.Position.Y + f.Size.Y / 2 - 0.13 * f.Size.Y, f.Position.Z)
	end
	joint("LeftElbow", LA, LF, elbow(LF))
	joint("RightElbow", RA, RF, elbow(RF))
	-- a knee: where the shin's top meets the thigh's underside, on the shin's own line
	local function knee(up, shin)
		local y = ((up.Position.Y - up.Size.Y / 2) + (shin.Position.Y + shin.Size.Y / 2)) / 2
		return Vector3.new(shin.Position.X, y, shin.Position.Z)
	end
	-- pieces are open shells: a ball of the trouser colour closes each knee, so it can't show a hole when it bends
	local function cap(up, shin, at)
		local c = Instance.new("Part")
		c.Name = "Cap_Knee"
		c.Shape = Enum.PartType.Ball
		c.Size = Vector3.one * math.min(shin.Size.X, shin.Size.Z) * 0.5
		c.CFrame = CFrame.new(at)
		c.Color = Color3.fromRGB(150, 44, 42)
		c.Material = Enum.Material.Fabric
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.Massless = true, false, false, false, true
		local w = Instance.new("Weld")
		w.Part0, w.Part1, w.C0 = up, c, up.CFrame:Inverse() * c.CFrame
		w.Parent = c
		c.Parent = M
	end
	local lk, rk = knee(LT, LS), knee(RT, RS)
	joint("LeftKnee", LT, LS, lk)
	joint("RightKnee", RT, RS, rk)
	cap(LT, LS, lk)
	cap(RT, RS, rk)
	if opts.Hands then
		opts.Hands(M)
	end
	local old = game.ServerStorage:FindFirstChild("OniNew")
	if old then
		old:Destroy()
	end
	M.Parent = game.ServerStorage
	local prev = Lab:FindFirstChild("Prev")
	if prev then
		prev:Destroy()
	end
	local p = M:Clone()
	p.Name = "Prev"
	for _, d in ipairs(p:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	p.Parent = Lab
	p:PivotTo(CFrame.new(-20, 3000 + p:GetPivot().Y, 0))
	return M
end

-- Studio-only: the Oni's hand-built parts, added to the rig at rest. Everything held is welded to the forearm, so the grip
-- cannot drift in any animation: the fingers are modelled curling round the handle, and move only with the hand.
return function(M, o)
	o = o or {}
	local rgb = Color3.fromRGB
	local Mt = Enum.Material
	local RF, RA, LA, T, LF = M.RightForearm, M.RightArm, M.LeftArm, M.Torso, M.LeftForearm
	local SKIN, SKIN2, IRON, DARK, GOLD, STEEL, LEATHER, CORD = rgb(206, 44, 44), rgb(170, 28, 30), rgb(58, 60, 68), rgb(24, 24, 30), rgb(222, 170, 70), rgb(132, 136, 148), rgb(52, 30, 24), rgb(176, 30, 36)
	local function piece(name, size, cf, color, mat, parent, shape)
		local p = Instance.new("Part")
		p.Name = "Gear_" .. name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat or Mt.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = true, false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		local w = Instance.new("Weld")
		w.Name = "GearWeld"
		w.Part0, w.Part1 = parent, p
		w.C0, w.C1 = parent.CFrame:Inverse() * cf, CFrame.identity
		w.Parent = p
		p.Parent = M
		return p
	end
	local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

	----------------------------------------------------------------- THE GRIP FRAME
	-- F: where the handle passes through the right fist. X runs up the handle toward the club's head, Y toward the wrist, Z across
	local elbowW = RF.CFrame * CFrame.new(0, RF.Size.Y * 0.37, 0)
	local F = RF.Position + Vector3.new(0.127 * RF.Size.X, -0.28 * RF.Size.Y, -0.125 * RF.Size.Z) -- the middle of the sculpted fist
	local a = (o.Axis or Vector3.new(0.03, 0.58, -0.81)).Unit
	local n = (elbowW.Position - F).Unit
	local u = (n - a * a:Dot(n)).Unit
	local v = a:Cross(u)
	local G = CFrame.fromMatrix(F, a, u, v)
	local function g(x, y, z)
		return G * CFrame.new(x, y, z)
	end
	local ALONG = CFrame.identity -- a cylinder's length is its X, already along the handle

	----------------------------------------------------------------- THE KANABO
	local HR = 0.15 -- handle radius
	-- leather grip with cord bindings
	piece("Handle", Vector3.new(1.5, HR * 2, HR * 2), g(0.1, 0, 0), LEATHER, Mt.Fabric, RF, CYL)
	for i = 0, 6 do
		piece("HandleCord", Vector3.new(0.04, HR * 2 + 0.03, HR * 2 + 0.03), g(-0.55 + i * 0.22, 0, 0), CORD, Mt.Fabric, RF, CYL)
	end
	-- pommel with a hanging tassel
	piece("PommelCollar", Vector3.new(0.09, 0.32, 0.32), g(-0.66, 0, 0), GOLD, Mt.Metal, RF, CYL)
	piece("Pommel", Vector3.new(0.34, 0.34, 0.34), g(-0.8, 0, 0), DARK, Mt.Metal, RF, BALL)
	piece("PommelStud", Vector3.new(0.13, 0.13, 0.13), g(-0.97, 0, 0), GOLD, Mt.Metal, RF, BALL)
	for i = -1, 1 do
		piece("Tassel", Vector3.new(0.05, 0.5, 0.05), g(-0.9, -0.3 + i * 0.02, i * 0.06), CORD, Mt.Fabric, RF)
	end
	-- guard: a heavy collar where iron meets leather
	piece("Guard", Vector3.new(0.12, 0.5, 0.5), g(0.84, 0, 0), GOLD, Mt.Metal, RF, CYL)
	piece("GuardBack", Vector3.new(0.08, 0.42, 0.42), g(0.94, 0, 0), DARK, Mt.Metal, RF, CYL)
	-- the club: eight-sided iron swelling toward the head, with rows of studs and three gold bands
	local X0, X1, D0, D1 = 0.98, 3.6, 0.42, 0.72
	local slices = 8
	for i = 0, slices - 1 do
		local f = (i + 0.5) / slices
		local x = X0 + (X1 - X0) * f
		local d = D0 + (D1 - D0) * f
		piece("Club", Vector3.new((X1 - X0) / slices + 0.02, d, d), g(x, 0, 0), i % 2 == 0 and rgb(46, 44, 52) or rgb(38, 36, 44), Mt.Metal, RF, CYL)
	end
	for _, fr in ipairs({0.0, 0.5, 0.98}) do
		local x = X0 + (X1 - X0) * fr
		local d = D0 + (D1 - D0) * fr
		piece("ClubBand", Vector3.new(0.12, d + 0.09, d + 0.09), g(x, 0, 0), GOLD, Mt.Metal, RF, CYL)
	end
	for r = 0, 8 do
		local f = (r + 0.5) / 9
		local x = X0 + (X1 - X0) * (0.06 + f * 0.9)
		local rad = (D0 + (D1 - D0) * (0.06 + f * 0.9)) / 2
		for s = 0, 5 do
			local ang = (s + (r % 2) * 0.5) * math.pi / 3
			local dy, dz = math.cos(ang), math.sin(ang)
			-- a stud: a short tapered spike standing out of the iron
			local base = g(x, dy * (rad + 0.02), dz * (rad + 0.02))
			local look = CFrame.lookAt(base.Position, base.Position + (G.UpVector * dy + G.ZVector * dz))
			piece("Stud", Vector3.new(0.17, 0.17, 0.17), look * CFrame.new(0, 0, -0.02), STEEL, Mt.Metal, RF, BALL)
			piece("StudTip", Vector3.new(0.08, 0.08, 0.08), look * CFrame.new(0, 0, -0.1), rgb(196, 200, 212), Mt.Metal, RF, BALL)
		end
	end
	-- the crown of the club: a capped head and one great spike
	piece("ClubCap", Vector3.new(0.14, 0.62, 0.62), g(X1 + 0.05, 0, 0), DARK, Mt.Metal, RF, CYL)
	piece("ClubSpike", Vector3.new(0.3, 0.3, 0.3), g(X1 + 0.2, 0, 0), STEEL, Mt.Metal, RF, BALL)
	piece("ClubSpikeTip", Vector3.new(0.34, 0.12, 0.12), g(X1 + 0.42, 0, 0), rgb(190, 194, 206), Mt.Metal, RF)
	-- embers smouldering in the cracks of the iron
	for s = 0, 5 do
		local ang = s * 1.05 + 0.4
		local xc = X0 + 0.6 + (s * 0.37) % 1 * 2.2
		local fr = (xc - X0) / (X1 - X0)
		local mid = (D0 + (D1 - D0) * fr) / 2 + 0.006
		local c = piece("EmberCrack", Vector3.new(0.7, 0.02, 0.028), g(xc, math.cos(ang) * mid, math.sin(ang) * mid) * CFrame.Angles(ang, 0, 0) * CFrame.Angles(0, 0.3, 0), rgb(255, 80, 24), Mt.Neon, RF)
		c.CastShadow = false
	end

	----------------------------------------------------------------- THE FINGERS: each one a chain of segments round the handle
	local T_F, W_F = 0.135, 0.14
	local rm = HR + T_F / 2 + 0.05 -- just outside the sculpted fist, so the fingers sit on it
	-- a point at angle th round the handle (0 = toward the wrist, turning through +Z), at x along it
	local function around(x, th, r)
		return g(x, math.cos(th) * (r or rm), math.sin(th) * (r or rm))
	end
	-- a finger: rounded bones between rounded knuckles, following the curve round the handle
	local function curl(name, x, th0, th1, segs, thick, width, color, nail)
		local step = (th1 - th0) / segs
		for i = 0, segs do
			local at = around(x, th0 + i * step)
			piece(name .. "Joint", Vector3.one * thick * 1.08, at, i % 2 == 0 and color or SKIN2, Mt.SmoothPlastic, RF, BALL)
			if i < segs then
				local nextAt = around(x, th0 + (i + 1) * step)
				local mid = (at.Position + nextAt.Position) / 2
				local len = (nextAt.Position - at.Position).Magnitude
				piece(name, Vector3.new(len, thick, thick), CFrame.lookAt(mid, nextAt.Position) * CFrame.Angles(0, math.pi / 2, 0), color, Mt.SmoothPlastic, RF, CYL)
			end
		end
		if nail then
			local tip = around(x, th1, rm + thick * 0.3)
			piece(name .. "Nail", Vector3.one * thick * 0.72, tip, DARK, Mt.SmoothPlastic, RF, BALL)
		end
	end
	for i, x in ipairs({-0.23, -0.08, 0.07, 0.22}) do
		-- knuckle at the top of the back of the hand, then round the far side of the handle and back to the palm
		curl("Finger" .. i, x, math.rad(62), math.rad(300), 4, T_F, W_F, SKIN, true)
		piece("Knuckle", Vector3.one * 0.1, around(x, math.rad(62), rm + 0.05), IRON, Mt.Metal, RF, BALL)
	end
	-- the thumb locks over the fingers from the palm side
	curl("Thumb", 0.37, math.rad(-40), math.rad(-170), 3, 0.15, 0.15, SKIN, true)
	-- the palm closes the fist on the wrist side of the handle (the sculpted hand is the back of it)
	piece("Palm", Vector3.new(0.6, 0.18, 0.42), g(0, HR + 0.08, 0), SKIN, Mt.SmoothPlastic, RF)

	----------------------------------------------------------------- SHOULDERS: layered sode plates laced with red cord
	local function sode(arm, sx)
		local top = arm.Position + Vector3.new(sx * 0.3, arm.Size.Y * 0.38, 0)
		for row = 0, 3 do
			local y = top.Y - row * 0.15
			local w = 0.74 + row * 0.04
			local x = top.X + sx * (0.06 + row * 0.05)
			local tilt = CFrame.Angles(0, 0, -sx * math.rad(30 + row * 3))
			local cf = CFrame.new(x, y, top.Z) * tilt
			piece("Sode", Vector3.new(0.48, 0.1, w), cf, row % 2 == 0 and rgb(38, 36, 44) or rgb(50, 46, 54), Mt.Metal, arm)
			piece("SodeEdge", Vector3.new(0.04, 0.03, w + 0.01), cf * CFrame.new(sx * 0.24, -0.05, 0), GOLD, Mt.Metal, arm)
			for _, dz in ipairs({-0.24, 0.24}) do
				piece("SodeCord", Vector3.new(0.024, 0.12, 0.035), cf * CFrame.new(sx * 0.245, 0, dz), CORD, Mt.Fabric, arm)
			end
		end
	end
	sode(RA, 1)
	sode(LA, -1)

	----------------------------------------------------------------- THE WAR BANNER (sashimono) on his back: the silhouette
	local back = T.Position + Vector3.new(0, 0.3, T.Size.Z / 2 + 0.06)
	piece("BannerMount", Vector3.new(0.5, 0.55, 0.14), CFrame.new(back), DARK, Mt.Metal, T)
	piece("BannerPole", Vector3.new(3.2, 0.09, 0.09), CFrame.new(back + Vector3.new(0, 1.45, 0.06)) * CFrame.Angles(0, 0, math.pi / 2), rgb(60, 36, 26), Mt.Wood, T, CYL)
	piece("BannerFinial", Vector3.new(0.2, 0.2, 0.2), CFrame.new(back + Vector3.new(0, 3.1, 0.06)), GOLD, Mt.Metal, T, BALL)
	piece("BannerArm", Vector3.new(1.2, 0.06, 0.06), CFrame.new(back + Vector3.new(0, 2.85, 0.06)), rgb(60, 36, 26), Mt.Wood, T)
	local cloth = piece("BannerCloth", Vector3.new(1.1, 1.8, 0.03), CFrame.new(back + Vector3.new(0, 1.95, 0.1)), rgb(120, 16, 22), Mt.Fabric, T)
	piece("BannerEdge", Vector3.new(1.14, 0.07, 0.035), CFrame.new(back + Vector3.new(0, 1.06, 0.1)), GOLD, Mt.Fabric, T)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 60
		sg.LightInfluence = 0.7
		sg.MaxDistance = 320
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(0.9, 0.5)
		t.Position = UDim2.fromScale(0.05, 0.25)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.GothamBold
		t.Text = "\u{9B3C}"
		t.TextColor3 = rgb(250, 214, 120)
		t.Parent = sg
		sg.Parent = cloth
	end
	return G
end

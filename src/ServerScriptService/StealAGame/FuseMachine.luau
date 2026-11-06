--[[
	FuseMachine: the machine in the world, beside the Game Vault. Three feeder pods hold a game case each, tubes run into
	a glass chamber with a glowing core, and rings turn round it. The server only builds it; every client animates it
	(FuseUI), and the attribute FusedAt plays the whole fusion on it for everyone nearby.
]]
local FuseMachine = {}

-- Every measurement below is multiplied by this: at 0.6 the machine is about as wide as the Trail Shop (25 studs against 24).
-- FuseUI reads it from the model's Scale attribute, so the animation shrinks with it.
local S = 0.6

function FuseMachine.build(Kit, parent, cf)
	local rgb = Color3.fromRGB
	local M = {Metal = Enum.Material.Metal, Neon = Enum.Material.Neon, Glass = Enum.Material.Glass, Smooth = Enum.Material.SmoothPlastic}
	local DARK, MID, LIGHT = rgb(44, 34, 88), rgb(84, 62, 160), rgb(170, 150, 235)
	local CYAN, PINK, GOLD = rgb(70, 240, 255), rgb(255, 80, 190), rgb(255, 205, 70)
	local model = Instance.new("Model")
	model.Name = "FusingMachine"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local function at(x, y, z)
		return cf * CFrame.new(x * S, y * S, z * S)
	end
	local function part(props)
		props.Material = props.Material or M.Smooth
		props.Size = props.Size * S
		return Kit.part(model, props)
	end
	local function cyl(h, d, x, y, z, props)
		props.Material = props.Material or M.Smooth
		return Kit.cylinder(model, h * S, d * S, at(x, y, z), props)
	end
	local function deco(p)
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		return p
	end

	-- the stepped platform with a lit edge
	cyl(1.2, 42, 0, 0.6, 0, {Name = "Step1", Color = DARK})
	deco(cyl(0.3, 42.6, 0, 0.95, 0, {Name = "StepLight", Color = CYAN, Material = M.Neon}))
	cyl(1.2, 34, 0, 1.8, 0, {Name = "Step2", Color = MID})
	deco(cyl(0.3, 34.6, 0, 2.15, 0, {Name = "StepLight2", Color = PINK, Material = M.Neon}))
	local FLOOR = 2.4

	-- THE CHAMBER: a heavy base, a glass tube and a top cap
	cyl(2.2, 15, 0, FLOOR + 1.1, 0, {Name = "ChamberBase", Color = DARK, Material = M.Metal})
	deco(cyl(0.5, 15.6, 0, FLOOR + 1.9, 0, {Name = "BaseLight", Color = CYAN, Material = M.Neon}))
	local CY = FLOOR + 9.5 -- the chamber's centre
	deco(cyl(12, 12, 0, CY, 0, {Name = "ChamberGlass", Color = rgb(170, 235, 255), Material = M.Glass, Transparency = 0.72}))
	-- one collision column, so nobody walks through the middle
	cyl(12, 11, 0, CY, 0, {Name = "ChamberSolid", Transparency = 1})
	for i = 0, 2 do
		local a = math.rad(i * 120 + 60)
		part({Name = "ChamberRib", Size = Vector3.new(1.1, 12.6, 1.1), CFrame = at(math.sin(a) * 6.2, CY, -math.cos(a) * 6.2), Color = MID, Material = M.Metal})
	end
	cyl(1.6, 15, 0, CY + 6.6, 0, {Name = "ChamberCap", Color = DARK, Material = M.Metal})
	deco(cyl(0.5, 15.6, 0, CY + 6.1, 0, {Name = "CapLight", Color = PINK, Material = M.Neon}))
	cyl(2.4, 9, 0, CY + 8.6, 0, {Name = "Crown", Color = MID, Material = M.Metal})
	cyl(2.4, 1.2, 0, CY + 10.8, 0, {Name = "Antenna", Color = LIGHT, Material = M.Metal})
	local beacon = deco(part({Name = "FuseBeacon", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = at(0, CY + 12.6, 0), Color = GOLD, Material = M.Neon}))

	-- the core floating in the chamber, and what turns round it
	local core = deco(part({Name = "FuseCore", Shape = Enum.PartType.Ball, Size = Vector3.new(4.4, 4.4, 4.4), CFrame = at(0, CY, 0), Color = rgb(40, 170, 230), Material = M.Neon}))
	local light = Instance.new("PointLight")
	light.Name = "CoreLight"
	light.Color, light.Range, light.Brightness, light.Shadows = CYAN, 20 * S, 0.8, false
	light.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "CoreSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(CYAN, PINK)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.5 * S, 0)
	sparks.Lifetime = NumberRange.new(0.6, 1.1)
	sparks.Speed = NumberRange.new(1.5 * S, 3 * S)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 10
	sparks.Parent = core
	-- rings made of short segments (turned by the clients, so they cost the server nothing)
	local function ring(name, y, radius, color, n)
		local folder = Instance.new("Folder")
		folder.Name = name
		folder:SetAttribute("Y", y * S)
		folder.Parent = model
		for i = 1, n do
			local a = (i - 0.5) / n * 2 * math.pi
			local seg = deco(part({Name = "Seg", Size = Vector3.new(0.55, 0.55, 2 * math.pi * radius / n * 0.68), CFrame = at(math.cos(a) * radius, y, math.sin(a) * radius), Color = color, Material = M.Neon}))
			seg:SetAttribute("Angle", a)
			seg:SetAttribute("Radius", radius * S)
			seg.Parent = folder
		end
	end
	ring("RingA", CY + 2.6, 9.2, CYAN, 12)
	ring("RingB", CY - 2.6, 9.2, PINK, 12)

	-- THREE FEEDER PODS: a game case hovering in each; tubes run up into the chamber. Two stand either side of the front,
	-- one behind, so the front stays open to walk up to.
	for i, deg in ipairs({-125, 125, 0}) do
		-- deg is measured from the back of the machine, so 0 is straight behind the chamber
		local a = math.rad(deg)
		local dx, dz = math.sin(a), math.cos(a)
		local x, z = dx * 13.5, dz * 13.5
		cyl(5.2, 5.4, x, FLOOR + 2.6, z, {Name = "Pod", Color = DARK, Material = M.Metal})
		deco(cyl(0.45, 6, x, FLOOR + 5, z, {Name = "PodLight", Color = i == 2 and PINK or CYAN, Material = M.Neon}))
		-- the tube from the pod's shoulder to the chamber, one straight, slightly raised run
		local from, to = at(x, FLOOR + 4.2, z).Position, at(dx * 6.4, FLOOR + 6.2, dz * 6.4).Position
		deco(part({Name = "Tube", Size = Vector3.new(1.5, 1.5, (to - from).Magnitude / S + 1), CFrame = CFrame.lookAt((from + to) / 2, to), Color = rgb(150, 230, 255), Material = M.Glass, Transparency = 0.35}))
		-- the case
		local home = at(x, FLOOR + 8.6, z)
		local case = deco(part({Name = "FuseCase" .. i, Size = Vector3.new(3.5, 4.5, 0.65), CFrame = home * CFrame.Angles(0, math.rad(deg + 180), 0), Color = ({rgb(255, 90, 120), rgb(90, 170, 255), rgb(120, 225, 110)})[i], Material = M.Smooth}))
		deco(part({Name = "CaseArt" .. i, Size = Vector3.new(2.9, 3.6, 0.72), CFrame = case.CFrame * CFrame.new(0, -0.25 * S, 0), Color = rgb(255, 230, 150), Material = M.Smooth})).Parent = case
		case:SetAttribute("HomeX", x * S)
		case:SetAttribute("HomeY", (FLOOR + 8.6) * S)
		case:SetAttribute("HomeZ", z * S)
		case:SetAttribute("Deg", deg)
	end

	-- the fused game rises here (hidden until a fusion)
	local result = deco(part({Name = "FuseResult", Size = Vector3.new(4.2, 5.4, 0.8), CFrame = at(0, -30, 0), Color = GOLD, Material = M.Neon, Transparency = 1}))
	result:SetAttribute("Y", CY * S)
	-- the flash (hidden until a fusion)
	deco(part({Name = "FuseFlash", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), CFrame = at(0, -30, 0), Color = rgb(255, 255, 255), Material = M.Neon, Transparency = 1}))

	-- THE SIGN: a small board on two short legs, standing on the ground just in front of the platform. These are real studs
	-- (not scaled). Nothing on it collides, so it can't block anyone walking up to the machine.
	local signAt = cf * CFrame.new(0, 2.3, -15.2) * CFrame.Angles(math.rad(-12), 0, 0)
	for _, x in ipairs({-3.2, 3.2}) do
		deco(Kit.part(model, {Name = "SignLeg", Size = Vector3.new(0.45, 2.6, 0.45), CFrame = cf * CFrame.new(x, 1.3, -15), Color = DARK, Material = M.Metal}))
	end
	deco(Kit.part(model, {Name = "SignEdge", Size = Vector3.new(8.7, 2.7, 0.2), CFrame = signAt * CFrame.new(0, 0, 0.14), Color = PINK, Material = M.Neon}))
	deco(Kit.part(model, {Name = "SignBack", Size = Vector3.new(8.3, 2.3, 0.1), CFrame = signAt * CFrame.new(0, 0, 0.26), Color = DARK, Material = M.Smooth})) -- the edge stays a thin rim from behind too
	local board = deco(Kit.part(model, {Name = "FuseSign", Size = Vector3.new(8.3, 2.3, 0.3), CFrame = signAt, Color = DARK, Material = M.Smooth}))
	local title = Kit.surfaceText(board, Enum.NormalId.Front, "FUSING MACHINE", GOLD, 60)
	title.Font = Enum.Font.LuckiestGuy
	-- 3 cases + an arrow + one glowing case, on a panel in front of the chamber
	local panel = part({Name = "FusePanel", Size = Vector3.new(13, 5.4, 0.8), CFrame = at(0, FLOOR + 2.9, -9.6) * CFrame.Angles(math.rad(-16), 0, 0), Color = DARK, Material = M.Metal})
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Equation"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40 * S
	sg.LightInfluence = 0
	sg.Parent = panel
	local function box(x, w, h, color, parentGui)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, 0.42)
		f.Size = UDim2.fromOffset(w, h)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 8)
		cr.Parent = f
		local st = Instance.new("UIStroke")
		st.Color = rgb(255, 255, 255)
		st.Thickness = 4
		st.Parent = f
		f.Parent = parentGui
		return f
	end
	for k, c in ipairs({rgb(255, 90, 120), rgb(90, 170, 255), rgb(120, 225, 110)}) do
		box(0.1 + (k - 1) * 0.15, 56, 76, c, sg)
	end
	-- an arrow drawn from bars, pointing at the rarer game
	for _, r in ipairs({38, -38}) do
		local bar = box(0.655, 62, 16, CYAN, sg)
		bar.Rotation = r
		bar.Position = UDim2.new(0.655, 0, 0.42, r > 0 and -19 or 19)
		bar:FindFirstChildOfClass("UIStroke"):Destroy()
	end
	local shaft = box(0.59, 92, 16, CYAN, sg)
	shaft:FindFirstChildOfClass("UIStroke"):Destroy()
	box(0.86, 76, 100, GOLD, sg)
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.AnchorPoint = Vector2.new(0.5, 1)
	words.Position = UDim2.fromScale(0.5, 0.98)
	words.Size = UDim2.new(0.96, 0, 0.24, 0)
	words.Font = Enum.Font.GothamBlack
	words.Text = "3 COPIES  =  1 RARER COPY"
	words.TextScaled = true
	words.TextColor3 = rgb(255, 255, 255)
	words.Parent = sg

	-- where you talk to it: at the front, by the panel
	local anchor = deco(part({Name = "FuseAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, FLOOR + 4, -11), Transparency = 1}))
	local prompt = Kit.prompt(anchor, "Fuse Games", "Fusing Machine", 0, 20)

	model:SetAttribute("Scale", S)
	model:SetAttribute("CX", cf.X)
	model:SetAttribute("CZ", cf.Z)
	model:SetAttribute("CenterY", CY * S)
	model:SetAttribute("Frame", cf)
	model.Parent = parent
	return model, prompt
end

return FuseMachine

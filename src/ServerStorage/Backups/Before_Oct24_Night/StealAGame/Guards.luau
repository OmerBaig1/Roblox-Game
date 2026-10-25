--[[
	STEAL A GAME - SHOPKEEPER MODELS
	Builds the look of each level's shopkeeper (the AI lives in the main script).
]]

local Players = game:GetService("Players")

local Guards = {}

function Guards.create(C, Kit, level, parent, post)
	local rgb, M = Kit.rgb, Kit.M
	local L = C.LEVELS[level]
	local look = L.Zone.Guard
	local shirt = look.Shirt:Lerp(Color3.new(0, 0, 0), (L.Sub - 1) * 0.08)

	local function addHatPart(model, head, size, offset, color, props)
		props = props or {}
		local p = Instance.new("Part")
		p.Name = "Hat"
		p.Shape = props.Shape or Enum.PartType.Block
		p.Size = size
		p.Color = color
		p.Material = props.Material or M.SmoothPlastic
		p.Transparency = props.Transparency or 0
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = head.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = head
		w.Part1 = p
		w.Parent = p
		p.Parent = model
	end
	local CYL = {Shape = Enum.PartType.Cylinder}
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)
	local function addHat(model, head, kind, color)
		local s = head.Size.Y
		local top = s / 2
		if kind == "cap" then
			addHatPart(model, head, Vector3.new(s * 1.05, s * 0.35, s * 1.05), CFrame.new(0, top, 0), color)
			addHatPart(model, head, Vector3.new(s * 1.0, s * 0.1, s * 0.6), CFrame.new(0, top - s * 0.12, -s * 0.7), color)
		elseif kind == "headband" then
			addHatPart(model, head, Vector3.new(s * 1.08, s * 0.18, s * 1.08), CFrame.new(0, s * 0.2, 0), color, {Material = M.Neon})
		elseif kind == "tophat" then
			addHatPart(model, head, Vector3.new(s * 1.2, s * 0.85, s * 0.85), CFrame.new(0, top + s * 0.6, 0) * UPRIGHT, color, CYL)
			addHatPart(model, head, Vector3.new(s * 0.08, s * 1.35, s * 1.35), CFrame.new(0, top + s * 0.04, 0) * UPRIGHT, color, CYL)
		elseif kind == "pirate" then
			addHatPart(model, head, Vector3.new(s * 1.9, s * 0.5, s * 1.0), CFrame.new(0, top + s * 0.2, 0), color)
			addHatPart(model, head, Vector3.new(s * 0.35, s * 0.3, s * 0.05), CFrame.new(0, top + s * 0.2, -s * 0.52), rgb(240, 240, 240))
			addHatPart(model, head, Vector3.new(s * 0.35, s * 0.25, s * 0.05), CFrame.new(-s * 0.2, s * 0.08, -s * 0.5), rgb(15, 15, 15))
		elseif kind == "hood" then
			addHatPart(model, head, Vector3.new(s * 1.15, s * 1.15, s * 1.0), CFrame.new(0, s * 0.06, s * 0.12), color, {Material = M.Fabric})
			addHatPart(model, head, Vector3.new(s * 0.15, s * 0.1, s * 0.05), CFrame.new(-s * 0.2, s * 0.1, -s * 0.5), rgb(255, 60, 60), {Material = M.Neon})
			addHatPart(model, head, Vector3.new(s * 0.15, s * 0.1, s * 0.05), CFrame.new(s * 0.2, s * 0.1, -s * 0.5), rgb(255, 60, 60), {Material = M.Neon})
		elseif kind == "visor" then
			addHatPart(model, head, Vector3.new(s * 1.1, s * 0.25, s * 0.2), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
			addHatPart(model, head, Vector3.new(s * 1.08, s * 0.2, s * 1.08), CFrame.new(0, top - s * 0.05, 0), rgb(30, 30, 40))
		elseif kind == "antenna" then
			addHatPart(model, head, Vector3.new(s * 0.8, s * 0.08, s * 0.08), CFrame.new(0, top + s * 0.4, 0) * UPRIGHT, rgb(80, 80, 90), CYL)
			addHatPart(model, head, Vector3.one * s * 0.3, CFrame.new(0, top + s * 0.85, 0), color, {Shape = Enum.PartType.Ball, Material = M.Neon})
			addHatPart(model, head, Vector3.new(s * 0.9, s * 0.15, s * 0.1), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
		elseif kind == "horns" then
			addHatPart(model, head, Vector3.new(s * 1.1, s * 0.5, s * 1.1), CFrame.new(0, top - s * 0.05, 0), rgb(110, 110, 120), {Material = M.Metal})
			for _, sx in ipairs({-1, 1}) do
				addHatPart(model, head, Vector3.new(s * 0.2, s * 0.7, s * 0.2), CFrame.new(sx * s * 0.45, top + s * 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.4), color)
			end
		elseif kind == "helmet" then
			addHatPart(model, head, Vector3.one * s * 1.75, CFrame.new(0, 0, 0), color, {Shape = Enum.PartType.Ball, Material = M.Glass, Transparency = 0.5})
		end
	end

	local model
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Kit.SKIN
		desc.LeftArmColor = shirt
		desc.RightArmColor = shirt
		desc.TorsoColor = shirt
		desc.LeftLegColor = look.Pants
		desc.RightLegColor = look.Pants
		local scale = 1 + (level - 1) * 0.02 -- deeper shopkeepers are bigger
		desc.HeightScale = scale
		desc.WidthScale = scale
		desc.DepthScale = scale
		desc.HeadScale = scale
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		-- Simple block fallback
		model = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Color = shirt
		root.Parent = model
		model.PrimaryPart = root
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.2, 1.2, 1.2)
		head.Color = Kit.SKIN
		head.CanCollide = false
		head.Massless = true
		head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = head
		w.Parent = head
		head.Parent = model
		local hum = Instance.new("Humanoid")
		hum.HipHeight = 2
		hum.Parent = model
	end

	model.Name = string.format("%02d_%s", level, look.Title)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = C.GUARD_IDLE_REAL_SPEED
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	model.Parent = parent
	model:PivotTo(CFrame.new(post))

	local head = model:FindFirstChild("Head")
	if head then
		addHat(model, head, look.Hat, look.HatColor)
	end

	-- SCARINESS grows with depth (0 at level 1 to 1 at level 50)
	local scary = (level - 1) / math.max(1, C.NUM_LEVELS - 1)
	-- Glowing red eyes from level 16
	if head and level >= 16 then
		local s = head.Size.Y
		for _, sx in ipairs({-1, 1}) do
			addHatPart(model, head, Vector3.new(s * 0.16, s * 0.1, s * 0.05), CFrame.new(sx * s * 0.18, s * 0.12, -s * 0.52), Color3.fromRGB(255, 30, 30), {Material = M.Neon})
		end
	end
	-- A trail behind them, in their level's colour, getting darker and redder deeper in
	do
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.2, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		local c1 = L.Accent:Lerp(Color3.fromRGB(255, 30, 30), scary * 0.8)
		local c2 = L.Accent:Lerp(Color3.fromRGB(20, 0, 0), scary)
		trail.Color = ColorSequence.new(c1, c2)
		trail.Lifetime = 0.35 + scary * 0.9
		trail.WidthScale = NumberSequence.new(1 + scary * 1.5, 0.2)
		trail.Transparency = NumberSequence.new(0.15, 1)
		trail.LightEmission = 0.4 + scary * 0.6
		trail.FaceCamera = true
		trail.Parent = root
	end
	-- Dark smoke from level 26
	if level >= 26 then
		local smoke = Instance.new("ParticleEmitter")
		smoke.Color = ColorSequence.new(Color3.fromRGB(30, 10, 20), Color3.fromRGB(80, 0, 0))
		smoke.Size = NumberSequence.new(1.2, 3)
		smoke.Transparency = NumberSequence.new(0.4, 1)
		smoke.Lifetime = NumberRange.new(0.8, 1.4)
		smoke.Rate = 10 + scary * 20
		smoke.Speed = NumberRange.new(1, 3)
		smoke.SpreadAngle = Vector2.new(180, 180)
		smoke.Parent = root
	end
	-- Flames from level 41
	if level >= 41 then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 60, 20)
		fire.SecondaryColor = Color3.fromRGB(80, 0, 0)
		fire.Size = 6
		fire.Heat = 8
		fire.Parent = root
	end
	Kit.setGroup(model, "Guards")
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	-- Running animation that speeds up with the shopkeeper
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://913376220"
	local track
	pcall(function()
		track = animator:LoadAnimation(anim)
	end)
	hum.Running:Connect(function(runSpeed)
		if not track then return end
		if runSpeed > 0.5 then
			if not track.IsPlaying then
				track:Play()
			end
			track:AdjustSpeed(math.clamp(runSpeed / 16, 0.6, 8))
		elseif track.IsPlaying then
			track:Stop()
		end
	end)

	return model, hum, root, head, look
end

return Guards

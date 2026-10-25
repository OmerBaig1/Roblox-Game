--[[
	STEAL A GAME - SHOPKEEPER MODELS
	Builds each level's shopkeeper: a giant (4.2x to 5.6x a player's size) with
	armour, angry glowing eyes, a themed weapon, and animations (idle, run,
	a point when the chase starts, a laugh when they catch you).
	The AI lives in the main script; footstep thuds and screen shake are client-side.
]]

local Players = game:GetService("Players")

local Guards = {}

-- Roblox's standard R15 animations
local ANIM = {
	Idle = "rbxassetid://507766388",
	Run = "rbxassetid://913376220",
	Point = "rbxassetid://507770453",
	Laugh = "rbxassetid://507770818",
}

function Guards.create(C, Kit, level, parent, post)
	local rgb, M = Kit.rgb, Kit.M
	local L = C.LEVELS[level]
	local look = L.Zone.Guard
	local shirt = look.Shirt:Lerp(Color3.new(0, 0, 0), (L.Sub - 1) * 0.08)
	local scale = C.guardScale(level)
	local scary = (level - 1) / math.max(1, C.NUM_LEVELS - 1) -- 0 at level 1, 1 at level 50

	-- A decoration welded to a body part. offset is relative to that part.
	local function addOn(model, to, size, offset, color, props)
		props = props or {}
		local p = Instance.new("Part")
		p.Name = props.Name or "Gear"
		p.Shape = props.Shape or Enum.PartType.Block
		p.Size = size
		p.Color = color
		p.Material = props.Material or M.SmoothPlastic
		p.Transparency = props.Transparency or 0
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = props.CastShadow ~= false
		p.CFrame = to.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = p
		w.Parent = p
		p.Parent = model
		return p
	end
	local CYL = Enum.PartType.Cylinder
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

	local function addHat(model, head, kind, color)
		local s = head.Size.Y
		local top = s / 2
		local function hat(size, offset, c, props)
			props = props or {}
			props.Name = "Hat"
			return addOn(model, head, size, offset, c, props)
		end
		if kind == "cap" then
			hat(Vector3.new(s * 1.05, s * 0.35, s * 1.05), CFrame.new(0, top, 0), color)
			hat(Vector3.new(s * 1.0, s * 0.1, s * 0.6), CFrame.new(0, top - s * 0.12, -s * 0.7), color)
		elseif kind == "headband" then
			hat(Vector3.new(s * 1.08, s * 0.18, s * 1.08), CFrame.new(0, s * 0.2, 0), color, {Material = M.Neon})
		elseif kind == "tophat" then
			hat(Vector3.new(s * 1.2, s * 0.85, s * 0.85), CFrame.new(0, top + s * 0.6, 0) * UPRIGHT, color, {Shape = CYL})
			hat(Vector3.new(s * 0.08, s * 1.35, s * 1.35), CFrame.new(0, top + s * 0.04, 0) * UPRIGHT, color, {Shape = CYL})
			hat(Vector3.new(s * 0.2, s * 0.87, s * 0.87), CFrame.new(0, top + s * 0.25, 0) * UPRIGHT, rgb(200, 30, 40), {Shape = CYL})
		elseif kind == "pirate" then
			hat(Vector3.new(s * 1.9, s * 0.5, s * 1.0), CFrame.new(0, top + s * 0.2, 0), color)
			hat(Vector3.new(s * 0.35, s * 0.3, s * 0.05), CFrame.new(0, top + s * 0.2, -s * 0.52), rgb(240, 240, 240))
			hat(Vector3.new(s * 0.35, s * 0.25, s * 0.05), CFrame.new(-s * 0.2, s * 0.08, -s * 0.5), rgb(15, 15, 15))
		elseif kind == "hood" then
			hat(Vector3.new(s * 1.15, s * 1.15, s * 1.0), CFrame.new(0, s * 0.06, s * 0.12), color, {Material = M.Fabric})
		elseif kind == "visor" then
			hat(Vector3.new(s * 1.1, s * 0.25, s * 0.2), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
			hat(Vector3.new(s * 1.08, s * 0.2, s * 1.08), CFrame.new(0, top - s * 0.05, 0), rgb(30, 30, 40))
		elseif kind == "antenna" then
			hat(Vector3.new(s * 0.8, s * 0.08, s * 0.08), CFrame.new(0, top + s * 0.4, 0) * UPRIGHT, rgb(80, 80, 90), {Shape = CYL})
			hat(Vector3.one * s * 0.3, CFrame.new(0, top + s * 0.85, 0), color, {Shape = Enum.PartType.Ball, Material = M.Neon})
			hat(Vector3.new(s * 0.9, s * 0.15, s * 0.1), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
		elseif kind == "horns" then
			hat(Vector3.new(s * 1.1, s * 0.5, s * 1.1), CFrame.new(0, top - s * 0.05, 0), rgb(110, 110, 120), {Material = M.Metal})
			for _, sx in ipairs({-1, 1}) do
				hat(Vector3.new(s * 0.2, s * 0.7, s * 0.2), CFrame.new(sx * s * 0.45, top + s * 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.4), color)
			end
		elseif kind == "helmet" then
			hat(Vector3.one * s * 1.75, CFrame.new(0, 0, 0), color, {Shape = Enum.PartType.Ball, Material = M.Glass, Transparency = 0.5})
		end
	end

	-- A themed weapon held in the right hand, pointing forward
	local function addWeapon(model, hand, zi, accent)
		local u = scale -- 1 stud at a normal player's size
		local fwd = CFrame.Angles(math.rad(-80), 0, 0) -- along the hand, tipped forward
		local function piece(size, along, color, props, extra)
			return addOn(model, hand, size * u, fwd * CFrame.new(0, along * u, 0) * (extra or CFrame.new()), color, props)
		end
		local handle = rgb(60, 40, 30)
		if zi == 1 then -- giant SALE sign on a pole
			piece(Vector3.new(0.18, 2.4, 0.18), 1.1, rgb(200, 200, 205), {Material = M.Metal})
			local sign = piece(Vector3.new(1.6, 1, 0.12), 2.6, rgb(255, 225, 60))
			local t = Kit.surfaceText(sign, Enum.NormalId.Front, "SALE!", rgb(220, 30, 30), 8)
			t.TextStrokeTransparency = 1
			Kit.surfaceText(sign, Enum.NormalId.Back, "SALE!", rgb(220, 30, 30), 8).TextStrokeTransparency = 1
		elseif zi == 2 then -- joystick club
			piece(Vector3.new(0.22, 2.2, 0.22), 1, rgb(30, 30, 35))
			piece(Vector3.one * 0.75, 2.3, rgb(255, 50, 60), {Shape = Enum.PartType.Ball})
			piece(Vector3.new(0.6, 0.18, 0.6), 0.1, accent, {Material = M.Neon})
		elseif zi == 3 then -- toy drumstick sword
			piece(Vector3.new(0.2, 0.7, 0.2), 0.2, rgb(200, 30, 40))
			piece(Vector3.new(0.8, 0.12, 0.25), 0.55, rgb(255, 210, 60))
			piece(Vector3.new(0.3, 2.2, 0.1), 1.7, rgb(230, 190, 120), {Material = M.Wood})
		elseif zi == 4 then -- cutlass
			piece(Vector3.new(0.16, 0.6, 0.16), 0.15, handle)
			piece(Vector3.new(0.7, 0.14, 0.4), 0.5, rgb(255, 200, 40), {Material = M.Metal})
			piece(Vector3.new(0.3, 2.2, 0.06), 1.65, rgb(220, 225, 235), {Material = M.Metal})
		elseif zi == 5 then -- scythe
			piece(Vector3.new(0.14, 3.6, 0.14), 1.2, rgb(50, 40, 35), {Material = M.Wood})
			piece(Vector3.new(0.08, 0.4, 1.8), 2.9, rgb(180, 185, 195), {Material = M.Metal}, CFrame.new(0, 0, -0.8 * u) * CFrame.Angles(math.rad(-15), 0, 0))
			piece(Vector3.one * 0.3, 3, rgb(120, 255, 120), {Shape = Enum.PartType.Ball, Material = M.Neon})
		elseif zi == 6 then -- neon shock baton
			piece(Vector3.new(0.22, 0.7, 0.22), 0.2, rgb(25, 25, 30))
			piece(Vector3.new(0.16, 2, 0.16), 1.5, rgb(60, 230, 255), {Material = M.Neon})
		elseif zi == 7 then -- katana
			piece(Vector3.new(0.14, 0.8, 0.14), 0.25, rgb(25, 25, 30), {Material = M.Fabric})
			piece(Vector3.new(0.45, 0.06, 0.45), 0.66, rgb(255, 200, 60), {Shape = CYL}, UPRIGHT)
			piece(Vector3.new(0.14, 2.8, 0.04), 2.1, rgb(225, 230, 240), {Material = M.Metal})
		elseif zi == 8 then -- giant wrench
			piece(Vector3.new(0.25, 2.4, 0.14), 1.1, rgb(150, 155, 165), {Material = M.Metal})
			piece(Vector3.new(0.9, 0.5, 0.16), 2.4, rgb(150, 155, 165), {Material = M.Metal})
			piece(Vector3.new(0.3, 0.3, 0.17), 2.55, rgb(30, 30, 35))
		elseif zi == 9 then -- flaming sword
			piece(Vector3.new(0.18, 0.6, 0.18), 0.15, handle)
			piece(Vector3.new(0.9, 0.16, 0.3), 0.5, rgb(255, 200, 40), {Material = M.Metal})
			local blade = piece(Vector3.new(0.32, 2.6, 0.08), 1.9, rgb(255, 120, 40), {Material = M.Neon})
			local fire = Instance.new("Fire")
			fire.Size = 2 + u
			fire.Heat = 4
			fire.Color = rgb(255, 120, 20)
			fire.SecondaryColor = rgb(200, 30, 0)
			fire.Parent = blade
		else -- ray gun
			piece(Vector3.new(0.3, 0.6, 0.3), 0.1, rgb(220, 220, 230))
			piece(Vector3.new(0.4, 1.3, 0.4), 0.8, rgb(240, 240, 250), {Shape = CYL}, UPRIGHT)
			piece(Vector3.new(0.2, 0.3, 0.6), 1.5, accent, {Material = M.Neon})
			local tip = piece(Vector3.one * 0.35, 1.6, rgb(140, 255, 255), {Shape = Enum.PartType.Ball, Material = M.Neon})
			local glow = Instance.new("PointLight")
			glow.Color = rgb(140, 255, 255)
			glow.Range = 4 + u * 2
			glow.Parent = tip
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
		desc.WidthScale = 1.05 -- a little burlier than a player
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
	-- The stock Animate script never runs on a server-built model; remove it
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end

	model.Name = string.format("%02d_%s", level, look.Title)
	model:SetAttribute("Scale", scale)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = C.GUARD_IDLE_REAL_SPEED
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	pcall(function()
		model:ScaleTo(scale)
	end)
	-- Stand the giant on the floor (floor top is y = 0.2)
	local standY = 0.2 + hum.HipHeight + root.Size.Y / 2
	model:SetAttribute("StandY", standY)
	model:PivotTo(CFrame.new(post.X, standY, post.Z)) -- facing the vault entrance
	model.Parent = parent

	local head = model:FindFirstChild("Head")
	local accent = L.Accent
	if head then
		addHat(model, head, look.Hat, look.HatColor)
		-- Angry glowing eyes (white early on, red from level 16) under heavy brows
		local s = head.Size.Y
		local eyeColor = level >= 16 and rgb(255, 30, 30) or rgb(255, 255, 200)
		for _, sx in ipairs({-1, 1}) do
			addOn(model, head, Vector3.new(s * 0.18, s * 0.1, s * 0.05), CFrame.new(sx * s * 0.18, s * 0.1, -s * 0.52), eyeColor, {Name = "Eye", Material = M.Neon})
			addOn(model, head, Vector3.new(s * 0.3, s * 0.07, s * 0.06), CFrame.new(sx * s * 0.17, s * 0.24, -s * 0.53) * CFrame.Angles(0, 0, sx * 0.45), rgb(25, 18, 15), {Name = "Brow"})
		end
		-- a scowling mouth
		addOn(model, head, Vector3.new(s * 0.32, s * 0.05, s * 0.05), CFrame.new(0, -s * 0.2, -s * 0.52), rgb(40, 15, 15), {Name = "Mouth"})
		if level >= 16 then
			local glow = Instance.new("PointLight")
			glow.Color = eyeColor
			glow.Range = 4 + scale * 2
			glow.Brightness = 1.2
			glow.Parent = head
		end
	end

	-- Armour: shoulder pads, a chest plate with the area's colour, a belt with a gold buckle
	local upper = model:FindFirstChild("UpperTorso")
	local lower = model:FindFirstChild("LowerTorso")
	local armour = shirt:Lerp(Color3.new(0, 0, 0), 0.35)
	if upper then
		local w, h, d = upper.Size.X, upper.Size.Y, upper.Size.Z
		for _, sx in ipairs({-1, 1}) do
			addOn(model, upper, Vector3.new(w * 0.42, h * 0.22, d * 1.25), CFrame.new(sx * w * 0.55, h * 0.42, 0) * CFrame.Angles(0, 0, -sx * 0.25), armour, {Name = "ShoulderPad", Material = M.Metal})
			addOn(model, upper, Vector3.new(w * 0.44, h * 0.06, d * 1.27), CFrame.new(sx * w * 0.55, h * 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.25), accent, {Name = "PadTrim"})
		end
		addOn(model, upper, Vector3.new(w * 0.62, h * 0.5, d * 0.12), CFrame.new(0, h * 0.05, -d * 0.53), armour, {Name = "ChestPlate", Material = M.Metal})
		addOn(model, upper, Vector3.new(w * 0.3, h * 0.24, d * 0.13), CFrame.new(0, h * 0.08, -d * 0.55), accent, {Name = "Badge", Material = level >= 26 and M.Neon or M.SmoothPlastic})
	end
	if lower then
		local w, h, d = lower.Size.X, lower.Size.Y, lower.Size.Z
		addOn(model, lower, Vector3.new(w * 1.06, h * 0.32, d * 1.08), CFrame.new(0, h * 0.25, 0), rgb(40, 28, 20), {Name = "Belt"})
		addOn(model, lower, Vector3.new(w * 0.28, h * 0.36, d * 0.1), CFrame.new(0, h * 0.25, -d * 0.56), Kit.GOLD, {Name = "Buckle", Material = M.Metal})
	end
	local hand = model:FindFirstChild("RightHand")
	if hand then
		addWeapon(model, hand, L.ZoneIndex, accent)
	end

	-- A trail behind them, in their level's colour, darker and redder deeper in
	do
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, scale, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -scale * 1.2, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(accent:Lerp(Color3.fromRGB(255, 30, 30), scary * 0.8), accent:Lerp(Color3.fromRGB(20, 0, 0), scary))
		trail.Lifetime = 0.35 + scary * 0.9
		trail.WidthScale = NumberSequence.new(1, 0.2)
		trail.Transparency = NumberSequence.new(0.3, 1)
		trail.LightEmission = 0.4 + scary * 0.6
		trail.FaceCamera = true
		trail.Parent = root
	end
	-- Dust kicked up by every giant step, dark smoke from level 26, flames from level 41
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "StepDust"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(rgb(200, 190, 170))
	dust.Size = NumberSequence.new(scale * 0.6, scale * 1.4)
	dust.Transparency = NumberSequence.new(0.55, 1)
	dust.Lifetime = NumberRange.new(0.6, 1)
	dust.Rate = 0
	dust.Speed = NumberRange.new(scale, scale * 2)
	dust.SpreadAngle = Vector2.new(80, 10)
	dust.EmissionDirection = Enum.NormalId.Bottom
	dust.Parent = root
	if level >= 26 then
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(Color3.fromRGB(30, 10, 20), Color3.fromRGB(80, 0, 0))
		smoke.Size = NumberSequence.new(scale * 0.8, scale * 2)
		smoke.Transparency = NumberSequence.new(0.5, 1)
		smoke.Lifetime = NumberRange.new(0.8, 1.4)
		smoke.Rate = 8 + scary * 16
		smoke.Speed = NumberRange.new(1, 3)
		smoke.SpreadAngle = Vector2.new(180, 180)
		smoke.Parent = root
	end
	if level >= 41 then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 60, 20)
		fire.SecondaryColor = Color3.fromRGB(80, 0, 0)
		fire.Size = 6 + scale * 2
		fire.Heat = 8
		fire.Parent = root
	end
	Kit.setGroup(model, "Guards")
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	-- ANIMATIONS: breathing idle, a heavy run, a point when the chase starts, a laugh when they catch you
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	for name, id in pairs(ANIM) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		pcall(function()
			tracks[name] = animator:LoadAnimation(a)
		end)
	end
	local idle, run = tracks.Idle, tracks.Run
	if idle then
		idle.Looped = true
		idle.Priority = Enum.AnimationPriority.Idle
		idle:Play()
	end
	if run then
		run.Looped = true
		run.Priority = Enum.AnimationPriority.Movement
	end
	hum.Running:Connect(function(runSpeed)
		if not run then return end
		if runSpeed > 0.5 then
			if not run.IsPlaying then
				run:Play(0.2)
			end
			-- big legs take longer strides, so the animation runs slower than a player's
			run:AdjustSpeed(math.clamp(runSpeed / (14 * scale), 0.35, 6))
		elseif run.IsPlaying then
			run:Stop(0.3)
		end
	end)
	local function act(name, speed)
		local t = tracks[name]
		if t then
			t.Priority = Enum.AnimationPriority.Action
			t:Play(0.15)
			t:AdjustSpeed(speed or 1)
			task.delay(1.4, function()
				if t.IsPlaying then
					t:Stop(0.3)
				end
			end)
		end
	end
	local actions = {
		Taunt = function() act("Point", 1.3) end,
		Laugh = function() act("Laugh", 1.2) end,
		Stomp = function()
			dust:Emit(10)
		end,
	}

	return model, hum, root, head, look, actions
end

return Guards

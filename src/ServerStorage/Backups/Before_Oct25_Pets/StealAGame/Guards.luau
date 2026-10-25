--[[
	STEAL A GAME - SHOPKEEPER MODELS
	Builds each level's shopkeeper: a giant (4.2x to 5.6x a player's size) with
	armour, angry glowing eyes, a themed weapon, and animations (idle, run,
	a point when the chase starts, a laugh when they catch you).
	The AI lives in the main script; footstep thuds and screen shake are client-side.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
	-- Each of an area's 5 shopkeepers has a rank: its own title, more arm stripes and a tinted hat
	local RANKS = {"Rookie", "Senior", "Veteran", "Elite", "Boss"}
	local look = table.clone(L.Zone.Guard)
	look.Title = RANKS[L.Sub] .. " " .. look.Title
	look.HatColor = look.HatColor:Lerp(L.Accent, (L.Sub - 1) * 0.15)
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

	model.Name = string.format("%02d_%s", level, L.Zone.Guard.Title)
	model:SetAttribute("Scale", scale)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = C.GUARD_IDLE_REAL_SPEED
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	-- Giants never trip, ragdoll, climb or swim: those states caused the twisted, glitchy poses
	for _, st in ipairs({Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.PlatformStanding}) do
		hum:SetStateEnabled(st, false)
	end
	-- ScaleTo also bumps the body-scale values; with auto scaling on, Roblox can re-apply them
	-- on top of the giant size (the "massive shopkeeper" bug), so freeze the size first
	hum.AutomaticScalingEnabled = false
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
	local zi = L.ZoneIndex
	-- the toy soldier, robot and astronaut have their own outfits instead of armour
	local ownOutfit = zi == 3 or zi == 8 or zi == 10
	if upper and not ownOutfit then
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

	------------------------------------------------------------------
	-- COSTUMES: every shopkeeper gets a look you can recognise at a glance
	------------------------------------------------------------------
	local P = function(name) return model:FindFirstChild(name) end
	local function paint(names, color, mat)
		for _, n in ipairs(names) do
			local p = P(n)
			if p then
				p.Color = color
				if mat then
					p.Material = mat
				end
			end
		end
	end
	local ARMS = {"LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm"}
	local LEGS = {"LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}
	local FEET = {"LeftFoot", "RightFoot"}
	local HANDS = {"LeftHand", "RightHand"}
	local s = head and head.Size.Y or scale
	local function onHead(size, offset, color, props)
		return head and addOn(model, head, size * s, offset, color, props)
	end
	local function on(partName, size, offset, color, props)
		local p = P(partName)
		return p and addOn(model, p, size, offset, color, props)
	end
	local uw, uh, ud = 1, 1, 1
	if upper then
		uw, uh, ud = upper.Size.X, upper.Size.Y, upper.Size.Z
	end

	if zi == 1 then
		-- CLEARANCE BOUNCER: black tee, gold chain, dark shades, earpiece
		paint({"UpperTorso", "LowerTorso", unpack(ARMS)}, rgb(30, 30, 36))
		onHead(Vector3.new(0.95, 0.2, 0.08), CFrame.new(0, s * 0.1, -s * 0.55), rgb(10, 10, 12), {Name = "Shades", Material = M.Glass})
		onHead(Vector3.new(0.12, 0.2, 0.12), CFrame.new(s * 0.55, 0, 0), rgb(40, 40, 40), {Name = "Earpiece"})
		on("UpperTorso", Vector3.new(uw * 0.7, uh * 0.06, ud * 0.1), CFrame.new(0, uh * 0.3, -ud * 0.55) * CFrame.Angles(0, 0, 0), Kit.GOLD, {Name = "Chain", Material = M.Metal})
		on("UpperTorso", Vector3.new(uw * 0.25, uh * 0.25, ud * 0.1), CFrame.new(0, uh * 0.12, -ud * 0.56), Kit.GOLD, {Name = "Medallion", Material = M.Metal, Shape = Enum.PartType.Cylinder})
	elseif zi == 2 then
		-- PIXEL PATROL: blocky 8-bit helmet, pixel chest lights
		onHead(Vector3.new(1.25, 1.25, 1.25), CFrame.new(0, s * 0.05, 0), rgb(70, 60, 140), {Name = "PixelHelmet"})
		onHead(Vector3.new(0.9, 0.35, 0.05), CFrame.new(0, s * 0.08, -s * 0.64), rgb(120, 255, 140), {Name = "PixelVisor", Material = M.Neon})
		for k = 0, 5 do
			on("UpperTorso", Vector3.new(uw * 0.12, uw * 0.12, ud * 0.05), CFrame.new(-uw * 0.3 + (k % 3) * uw * 0.3, uh * 0.15 - math.floor(k / 3) * uh * 0.2, -ud * 0.56), ({rgb(255, 80, 80), rgb(80, 220, 120), rgb(80, 160, 255)})[k % 3 + 1], {Name = "Pixel", Material = M.Neon})
		end
	elseif zi == 3 then
		-- TOY SOLDIER: red coat, white cross-belts, gold buttons, tall black shako, wind-up key
		paint({"UpperTorso", unpack(ARMS)}, rgb(205, 30, 40))
		paint({"LowerTorso", unpack(LEGS)}, rgb(25, 35, 80))
		paint(FEET, rgb(15, 15, 18))
		paint(HANDS, rgb(250, 250, 250))
		if head then
			head.Color = rgb(255, 215, 180)
		end
		onHead(Vector3.new(1.6, 0.95, 0.95), CFrame.new(0, s * 1.1, 0) * UPRIGHT, rgb(20, 20, 25), {Name = "Shako", Shape = CYL})
		onHead(Vector3.new(0.05, 0.4, 0.4), CFrame.new(0, s * 1.05, -s * 0.47) * CFrame.Angles(0, math.pi / 2, 0), Kit.GOLD, {Name = "ShakoPlate", Shape = CYL, Material = M.Metal})
		onHead(Vector3.new(0.3, 0.6, 0.3), CFrame.new(0, s * 2, 0), rgb(230, 30, 40), {Name = "Plume", Shape = Enum.PartType.Ball})
		onHead(Vector3.new(0.08, 0.5, 0.08), CFrame.new(0, s * 0.45, -s * 0.5), rgb(20, 20, 25), {Name = "ChinStrap"})
		for _, cx in ipairs({-1, 1}) do
			onHead(Vector3.new(0.22, 0.22, 0.05), CFrame.new(cx * s * 0.32, -s * 0.08, -s * 0.5), rgb(255, 120, 130), {Name = "Cheek", Shape = Enum.PartType.Ball})
			onHead(Vector3.new(0.14, 0.14, 0.05), CFrame.new(cx * s * 0.18, s * 0.12, -s * 0.52), rgb(10, 10, 10), {Name = "PaintedEye", Shape = Enum.PartType.Ball})
			-- white cross-belts
			on("UpperTorso", Vector3.new(uw * 0.16, uh * 1.25, ud * 1.12), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, cx * 0.62), rgb(250, 250, 250), {Name = "CrossBelt"})
			-- gold epaulettes
			on("UpperTorso", Vector3.new(uw * 0.38, uh * 0.1, ud * 1.1), CFrame.new(cx * uw * 0.42, uh * 0.47, 0), Kit.GOLD, {Name = "Epaulette", Material = M.Metal})
		end
		for k = 0, 3 do
			for _, bx in ipairs({-0.18, 0.18}) do
				on("UpperTorso", Vector3.new(uw * 0.08, uw * 0.08, ud * 0.08), CFrame.new(uw * bx, uh * (0.32 - k * 0.2), -ud * 0.53), Kit.GOLD, {Name = "Button", Shape = Enum.PartType.Ball, Material = M.Metal})
			end
		end
		-- wind-up key on the back
		on("UpperTorso", Vector3.new(ud * 0.9, uw * 0.1, uw * 0.1), CFrame.new(0, uh * 0.05, ud * 0.9) * CFrame.Angles(0, math.pi / 2, 0), Kit.GOLD, {Name = "KeyShaft", Shape = CYL, Material = M.Metal})
		for _, kx in ipairs({-1, 1}) do
			on("UpperTorso", Vector3.new(uw * 0.08, uw * 0.35, uw * 0.35), CFrame.new(kx * uw * 0.2, uh * 0.05, ud * 1.35) * CFrame.Angles(0, math.pi / 2, 0), Kit.GOLD, {Name = "KeyWing", Shape = CYL, Material = M.Metal})
		end
	elseif zi == 4 then
		-- PIRATE CAPTAIN: long red coat with gold trim and a parrot on the shoulder
		paint({"UpperTorso", unpack(ARMS)}, rgb(150, 25, 30))
		if lower then
			local lw, lh, ld = lower.Size.X, lower.Size.Y, lower.Size.Z
			on("LowerTorso", Vector3.new(lw * 1.08, lh * 2.2, ld * 0.15), CFrame.new(0, -lh * 0.8, ld * 0.5), rgb(150, 25, 30), {Name = "CoatTail"})
			on("LowerTorso", Vector3.new(lw * 1.1, lh * 0.15, ld * 0.17), CFrame.new(0, -lh * 1.85, ld * 0.5), Kit.GOLD, {Name = "CoatTrim"})
		end
		local sh = Vector3.new(uw * 0.42, uh * 0.55, 0)
		local parrot = on("UpperTorso", Vector3.new(uw * 0.22, uh * 0.32, uw * 0.22), CFrame.new(-sh.X, sh.Y + uh * 0.12, 0), rgb(40, 190, 70), {Name = "Parrot", Shape = Enum.PartType.Ball})
		if parrot then
			addOn(model, parrot, Vector3.one * uw * 0.17, CFrame.new(0, uh * 0.18, -uw * 0.02), rgb(230, 40, 40), {Name = "ParrotHead", Shape = Enum.PartType.Ball})
			addOn(model, parrot, Vector3.new(uw * 0.05, uw * 0.05, uw * 0.1), CFrame.new(0, uh * 0.17, -uw * 0.12), rgb(255, 200, 40), {Name = "Beak"})
			addOn(model, parrot, Vector3.new(uw * 0.06, uh * 0.3, uw * 0.12), CFrame.new(0, -uh * 0.18, uw * 0.06) * CFrame.Angles(0.4, 0, 0), rgb(40, 110, 230), {Name = "ParrotTail"})
		end
	elseif zi == 5 then
		-- CRYPT KEEPER: skull face, flowing cape, chains, a lantern
		if head then
			head.Color = rgb(235, 230, 215)
		end
		for _, cx in ipairs({-1, 1}) do
			onHead(Vector3.new(0.3, 0.3, 0.05), CFrame.new(cx * s * 0.2, s * 0.08, -s * 0.53), rgb(10, 10, 10), {Name = "EyeSocket", Shape = Enum.PartType.Ball})
		end
		on("UpperTorso", Vector3.new(uw * 1.25, uh * 2.4, ud * 0.12), CFrame.new(0, -uh * 0.6, ud * 0.58), rgb(30, 20, 45), {Name = "Cape", Material = M.Fabric})
		on("UpperTorso", Vector3.new(uw * 1.15, uh * 0.08, ud * 1.15), CFrame.new(0, -uh * 0.1, 0) * CFrame.Angles(0, 0, 0.5), rgb(120, 120, 130), {Name = "Chain", Material = M.Metal})
		local lantern = on("LeftHand", Vector3.new(0.6, 0.8, 0.6) * scale, CFrame.new(0, -0.6 * scale, 0), rgb(80, 255, 120), {Name = "Lantern", Material = M.Neon, Transparency = 0.2})
		if lantern then
			local l = Instance.new("PointLight")
			l.Color = rgb(120, 255, 140)
			l.Range = 6 + scale * 2
			l.Parent = lantern
		end
	elseif zi == 6 then
		-- CYBER ENFORCER: glowing circuit lines, shoulder lights, battery pack
		for _, n in ipairs({"LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}) do
			local p = P(n)
			if p then
				addOn(model, p, Vector3.new(p.Size.X * 1.04, p.Size.Y * 0.1, p.Size.Z * 1.04), CFrame.new(0, 0, 0), rgb(60, 230, 255), {Name = "Circuit", Material = M.Neon})
			end
		end
		on("UpperTorso", Vector3.new(uw * 0.6, uh * 0.7, ud * 0.5), CFrame.new(0, 0, ud * 0.7), rgb(40, 40, 55), {Name = "Battery", Material = M.Metal})
		on("UpperTorso", Vector3.new(uw * 0.4, uh * 0.1, ud * 0.52), CFrame.new(0, uh * 0.2, ud * 0.71), rgb(60, 230, 255), {Name = "BatteryLight", Material = M.Neon})
	elseif zi == 7 then
		-- SHADOW NINJA: face mask, red sash, sword on the back
		paint({"UpperTorso", "LowerTorso", unpack(ARMS)}, rgb(25, 25, 32))
		paint(LEGS, rgb(25, 25, 32))
		onHead(Vector3.new(1.06, 0.5, 1.06), CFrame.new(0, -s * 0.22, 0), rgb(25, 25, 32), {Name = "Mask", Material = M.Fabric})
		on("LowerTorso", Vector3.new(lower and lower.Size.X * 1.1 or 1, lower and lower.Size.Y * 0.3 or 0.3, lower and lower.Size.Z * 1.1 or 1), CFrame.new(0, 0, 0), rgb(200, 30, 40), {Name = "Sash", Material = M.Fabric})
		on("UpperTorso", Vector3.new(uw * 0.12, uh * 2, ud * 0.12), CFrame.new(0, 0, ud * 0.65) * CFrame.Angles(0, 0, 0.7), rgb(30, 20, 15), {Name = "Sheath"})
		on("UpperTorso", Vector3.new(uw * 0.3, uh * 0.06, ud * 0.06), CFrame.new(uw * 0.55, uh * 0.75, ud * 0.65) * CFrame.Angles(0, 0, 0.7), Kit.GOLD, {Name = "Hilt"})
	elseif zi == 8 then
		-- SECURITY BOT: all metal, boxy head, chest panel with blinking lights, bolts
		paint({"UpperTorso", "LowerTorso", unpack(ARMS)}, rgb(150, 160, 175), M.Metal)
		paint(LEGS, rgb(120, 130, 145), M.Metal)
		paint(FEET, rgb(70, 75, 85), M.Metal)
		paint(HANDS, rgb(70, 75, 85), M.Metal)
		if head then
			head.Color = rgb(150, 160, 175)
			head.Material = M.Metal
		end
		onHead(Vector3.new(1.2, 1.05, 1.15), CFrame.new(0, 0, 0), rgb(165, 175, 190), {Name = "BotHead", Material = M.Metal})
		onHead(Vector3.new(0.9, 0.22, 0.05), CFrame.new(0, s * 0.1, -s * 0.6), rgb(255, 60, 60), {Name = "BotEyes", Material = M.Neon})
		on("UpperTorso", Vector3.new(uw * 0.6, uh * 0.45, ud * 0.1), CFrame.new(0, uh * 0.05, -ud * 0.55), rgb(40, 45, 55), {Name = "Panel"})
		for k = 0, 2 do
			on("UpperTorso", Vector3.new(uw * 0.1, uw * 0.1, ud * 0.06), CFrame.new(-uw * 0.18 + k * uw * 0.18, uh * 0.1, -ud * 0.62), ({rgb(255, 60, 60), rgb(255, 220, 60), rgb(60, 255, 120)})[k + 1], {Name = "PanelLight", Shape = Enum.PartType.Ball, Material = M.Neon})
		end
		for _, cx in ipairs({-1, 1}) do
			on("UpperTorso", Vector3.new(uw * 0.12, uw * 0.25, uw * 0.25), CFrame.new(cx * uw * 0.52, uh * 0.35, 0) * CFrame.Angles(0, 0, 0), rgb(255, 200, 40), {Name = "Bolt", Shape = CYL, Material = M.Metal})
		end
	elseif zi == 9 then
		-- DRAGON KNIGHT: wings, a long scaly tail, spiked shoulders
		local wing = rgb(140, 30, 30)
		for _, cx in ipairs({-1, 1}) do
			Kit.wedge(model, {Name = "Wing", Size = Vector3.new(uw * 0.08, uh * 1.8, uw * 1.4), CFrame = upper and upper.CFrame * CFrame.new(cx * uw * 0.7, uh * 0.4, ud * 0.9) * CFrame.Angles(0, cx * 0.6, cx * 0.35) or CFrame.new(), Color = wing, CanCollide = false, Massless = true})
			on("UpperTorso", Vector3.new(uw * 0.12, uw * 0.4, uw * 0.12), CFrame.new(cx * uw * 0.55, uh * 0.62, 0) * CFrame.Angles(0, 0, -cx * 0.4), rgb(255, 200, 60), {Name = "Spike", Material = M.Metal})
		end
		-- weld the wings to the body
		for _, w in ipairs(model:GetChildren()) do
			if w.Name == "Wing" and upper and not w:FindFirstChildOfClass("WeldConstraint") then
				w.CanQuery, w.CanTouch = false, false
				w.Anchored = false
				w.Massless = true
				local wc = Instance.new("WeldConstraint")
				wc.Part0 = upper
				wc.Part1 = w
				wc.Parent = w
			end
		end
		local prev = lower
		for k = 1, 5 do
			if prev then
				local sz = (1 - k * 0.15) * scale * 0.7
				prev = addOn(model, prev, Vector3.one * sz, CFrame.new(0, -sz * 0.35, sz * 0.85) * CFrame.Angles(0.25, 0, 0), wing:Lerp(rgb(255, 120, 40), k / 6), {Name = "Tail", Shape = Enum.PartType.Ball})
			end
		end
	elseif zi == 10 then
		-- ASTRONAUT: white spacesuit, big helmet with a gold visor, life-support backpack, chest panel
		paint({"UpperTorso", "LowerTorso", unpack(ARMS)}, rgb(240, 240, 245))
		paint(LEGS, rgb(235, 235, 240))
		paint(FEET, rgb(150, 155, 165))
		paint(HANDS, rgb(200, 205, 215))
		for _, d in ipairs(model:GetChildren()) do
			if d.Name == "Hat" then
				d:Destroy() -- replace the old glass bubble
			end
		end
		onHead(Vector3.new(1.55, 1.55, 1.55), CFrame.new(0, s * 0.08, 0), rgb(245, 245, 250), {Name = "SpaceHelmet", Shape = Enum.PartType.Ball})
		onHead(Vector3.new(1.0, 0.75, 0.6), CFrame.new(0, s * 0.08, -s * 0.5), rgb(255, 190, 60), {Name = "Visor", Material = M.Glass, Reflectance = 0.5})
		on("UpperTorso", Vector3.new(uw * 0.8, uh * 0.9, ud * 0.7), CFrame.new(0, uh * 0.05, ud * 0.85), rgb(230, 230, 238), {Name = "LifePack"})
		for _, cx in ipairs({-1, 1}) do
			on("UpperTorso", Vector3.new(uw * 0.12, uh * 0.7, uw * 0.12), CFrame.new(cx * uw * 0.3, uh * 0.45, ud * 0.25) * CFrame.Angles(0.5, 0, 0), rgb(120, 125, 135), {Name = "Tube", Shape = CYL})
		end
		on("UpperTorso", Vector3.new(uw * 0.45, uh * 0.3, ud * 0.1), CFrame.new(0, -uh * 0.05, -ud * 0.55), rgb(50, 55, 70), {Name = "ChestPanel"})
		for k = 0, 2 do
			on("UpperTorso", Vector3.new(uw * 0.08, uw * 0.08, ud * 0.06), CFrame.new(-uw * 0.12 + k * uw * 0.12, -uh * 0.05, -ud * 0.62), ({rgb(255, 60, 60), rgb(60, 160, 255), rgb(60, 255, 120)})[k + 1], {Name = "Button", Shape = Enum.PartType.Ball, Material = M.Neon})
		end
		on("LeftUpperArm", Vector3.new(0.05, 0.3, 0.45) * scale, CFrame.new(-0.5 * scale, 0.1 * scale, 0), rgb(40, 80, 200), {Name = "Patch"})
	end

	-- RANK STRIPES: gold bands around both upper arms, one per rank above Rookie
	for _, n in ipairs({"LeftUpperArm", "RightUpperArm"}) do
		local p = P(n)
		if p then
			for k = 1, L.Sub - 1 do
				addOn(model, p, Vector3.new(p.Size.X * 1.08, p.Size.Y * 0.06, p.Size.Z * 1.08), CFrame.new(0, p.Size.Y * (0.38 - (k - 1) * 0.11), 0), Kit.GOLD, {Name = "RankStripe", Material = M.Metal})
			end
		end
	end
	-- The area's Boss also gets a gold glow and drifting gold sparkles
	if L.Sub == 5 then
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "BossAura"
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = ColorSequence.new(Kit.GOLD, Color3.new(1, 1, 1))
		aura.LightEmission = 1
		aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, scale * 0.35), NumberSequenceKeypoint.new(1, 0)})
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Rate = 10
		aura.Speed = NumberRange.new(0.5, 1.5)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent = root
		local glow = Instance.new("PointLight")
		glow.Name = "BossGlow"
		glow.Color = Kit.GOLD
		glow.Range = 8 + scale * 2
		glow.Brightness = 0.8
		glow.Shadows = false
		glow.Parent = root
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
	-- The run animation follows how fast the giant REALLY moves (not Humanoid.Running,
	-- which never reports "stopped" after a teleport - that left guards running in place)
	local animConn
	animConn = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			animConn:Disconnect()
			return
		end
		if not run then return end
		local v = root.AssemblyLinearVelocity
		local flatSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
		-- MoveDirection stays 0 for server MoveTo, so judge by real speed only
		local moving = flatSpeed > 1.5
		if moving then
			if not run.IsPlaying then
				run:Play(0.2)
			end
			-- big legs take longer strides, so the animation runs slower than a player's
			run:AdjustSpeed(math.clamp(flatSpeed / (14 * scale), 0.35, 6))
		elseif run.IsPlaying then
			run:Stop(0.25)
		end
		if idle and not idle.IsPlaying then
			idle:Play(0.3)
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

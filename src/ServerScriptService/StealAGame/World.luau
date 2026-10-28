--[[
	STEAL A GAME - WORLD
	Builds the floating sky island (lobby), the giant tree wall around it, the
	one long Game Vault hallway, and the Trail Shop booth.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- A plain character model (used for the shop NPC and the trail pictures)
local function makeCharacter(shirt, pants, skin)
	local model
	pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = skin
		desc.LeftArmColor = skin
		desc.RightArmColor = skin
		desc.TorsoColor = shirt
		desc.LeftLegColor = pants
		desc.RightLegColor = pants
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if model then
		-- Only the root is anchored. The limbs stay joined by their Motor6Ds, so the body
		-- always holds together (anchoring every part froze them where they spawned, which
		-- is what stretched the Invite Friend character's neck) and it can be animated.
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = d.Name == "HumanoidRootPart"
				d.CanCollide = false
			end
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			for _, st in ipairs({Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead}) do
				hum:SetStateEnabled(st, false)
			end
		end
	end
	return model
end

-- A gentle idle, plus an occasional friendly wave
local function animateNpc(model, waveEvery)
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local function load(id)
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(a)
		end)
		return ok and track or nil
	end
	local idle = load("rbxassetid://507766388")
	if idle then
		idle.Looped = true
		idle.Priority = Enum.AnimationPriority.Idle
		idle:Play()
	end
	if waveEvery then
		local wave = load("rbxassetid://507770239")
		if wave then
			wave.Priority = Enum.AnimationPriority.Action
			task.spawn(function()
				while model.Parent do
					task.wait(waveEvery)
					wave:Play(0.3)
				end
			end)
		end
	end
end

local World = {}

function World.build(C, Kit)
	local rgb, M, rng = Kit.rgb, Kit.M, Kit.rng
	local part, cyl = Kit.part, Kit.cylinder
	local DARK = Kit.DARK

	local W = {Spots = {}, RestockLabels = {}, PlotCFrames = {}, SegModels = {}}
	local ENTRANCE = Vector3.new(0, 0, C.HALL_START_Z)
	W.Entrance = ENTRANCE

	local function segStart(level)
		return C.HALL_START_Z + (level - 1) * C.SEG_LEN
	end
	W.segStart = segStart
	local hallEnd = segStart(C.NUM_LEVELS) + C.SEG_LEN
	W.HallEnd = hallEnd

	-- Which vault level is this position in? (nil = outside the vault)
	function W.roomAt(pos)
		if math.abs(pos.X) > C.ROOM_W / 2 or pos.Y > C.WALL_H or pos.Z < C.HALL_START_Z or pos.Z > hallEnd then
			return nil
		end
		return math.clamp(math.floor((pos.Z - C.HALL_START_Z) / C.SEG_LEN) + 1, 1, C.NUM_LEVELS)
	end

	------------------------------------------------------------------
	-- FOLDERS
	------------------------------------------------------------------
	local old = workspace:FindFirstChild("StealAGameMap")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "StealAGameMap"
	-- the client tutorial points players here
	map:SetAttribute("VaultEntrance", ENTRANCE)
	map:SetAttribute("HallWidth", C.ROOM_W)
	map.Parent = workspace
	W.Map = map
	local function folder(name)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = map
		return f
	end
	W.GamesFolder = folder("VaultGames")
	W.GuardsFolder = folder("Shopkeepers")
	W.BasesFolder = folder("Bases")
	local lobby = folder("Lobby")
	local scenery = folder("Scenery")
	local vault = folder("Vault")

	------------------------------------------------------------------
	-- SKY
	------------------------------------------------------------------
	Lighting.ClockTime = 13
	Lighting.Brightness = 3.2
	Lighting.Ambient = rgb(130, 130, 140)
	Lighting.OutdoorAmbient = rgb(185, 185, 195)
	Lighting.ExposureCompensation = 0.15
	local grade = Lighting:FindFirstChild("WorldColor") or Instance.new("ColorCorrectionEffect")
	grade.Name = "WorldColor"
	grade.Saturation = 0.25
	grade.Brightness = 0.03
	grade.Contrast = 0.05
	grade.Parent = Lighting
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.12
	atmosphere.Offset = 0.1
	atmosphere.Haze = 0.8
	atmosphere.Color = rgb(190, 215, 255)
	atmosphere.Decay = rgb(120, 160, 230)
	atmosphere.Parent = Lighting
	workspace.Terrain:Clear()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	-- Clouds drifting below and around the island
	for _ = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(C.ISLAND_R * 0.6, 2600)
		local center = ENTRANCE + Vector3.new(math.cos(a) * r, rng:NextNumber(-260, -70), math.sin(a) * r + 900)
		local size = rng:NextNumber(50, 110)
		for i = 0, 2 do
			part(scenery, {
				Name = "Cloud", Shape = Enum.PartType.Ball, Size = Vector3.one * size * (1 - i * 0.2),
				CFrame = CFrame.new(center + Vector3.new((i - 1) * size * 0.6, i * size * 0.12, rng:NextNumber(-10, 10))),
				Color = rgb(250, 252, 255), Material = M.SmoothPlastic, Transparency = 0.15,
				CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			})
		end
	end

	------------------------------------------------------------------
	-- THE ISLAND
	------------------------------------------------------------------
	cyl(lobby, 12, C.ISLAND_R * 2, CFrame.new(ENTRANCE + Vector3.new(0, -6, 0)), {Name = "Island", Color = rgb(80, 210, 70), Material = M.Grass})
	cyl(lobby, 10, C.ISLAND_R * 2 + 8, CFrame.new(ENTRANCE + Vector3.new(0, -11, 0)), {Name = "IslandRim", Color = rgb(120, 85, 55), Material = M.Ground})
	for i = 1, 7 do
		local r = C.ISLAND_R * (1 - i * 0.125)
		cyl(lobby, 30, r * 2, CFrame.new(ENTRANCE + Vector3.new(0, -16 - (i - 0.5) * 28, 0)), {
			Name = "IslandRock", Color = rgb(110, 90, 75):Lerp(rgb(70, 65, 70), i / 7), Material = (i % 2 == 0) and M.Rock or M.Slate,
		})
	end
	for _ = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(C.ISLAND_R * 0.4, C.ISLAND_R * 0.85)
		part(lobby, {
			Name = "HangingRock", Size = Vector3.new(rng:NextNumber(30, 60), rng:NextNumber(40, 90), rng:NextNumber(30, 60)),
			CFrame = CFrame.new(ENTRANCE + Vector3.new(math.cos(a) * r, -60 - rng:NextNumber(0, 60), math.sin(a) * r)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)),
			Color = rgb(95, 85, 80), Material = M.Rock,
		})
	end

	-- Stone walkways: a loop in front of the bases, a main path to the vault, a short path to each base
	-- (each base sits back from the loop behind a front yard, where its treadmill stands)
	local PATH = rgb(200, 192, 176)
	local LOOP_R = C.LOOP_R
	local function inHall(pos, pad)
		return math.abs(pos.X) < C.ROOM_W / 2 + pad and pos.Z > C.HALL_START_Z - 2
	end
	do
		local pieces = 96
		local chord = 2 * LOOP_R * math.sin(math.pi / pieces)
		for i = 0, pieces - 1 do
			local a = (i + 0.5) / pieces * math.pi * 2
			local pos = ENTRANCE + Vector3.new(math.sin(a), 0, -math.cos(a)) * LOOP_R
			if not inHall(pos, 4) then
				part(lobby, {Name = "Walkway", Size = Vector3.new(chord + 0.4, 0.2, 14), CFrame = CFrame.lookAt(pos + Vector3.new(0, 0.1, 0), ENTRANCE + Vector3.new(0, 0.1, 0)), Color = PATH, Material = M.Pavement})
			end
		end
		local function path(r1, r2, angle, width)
			local dir = Vector3.new(math.sin(angle), 0, -math.cos(angle))
			local a, b = ENTRANCE + dir * r1, ENTRANCE + dir * r2
			part(lobby, {Name = "Walkway", Size = Vector3.new(width, 0.24, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.12, 0), b + Vector3.new(0, 0.12, 0)), Color = PATH, Material = M.Pavement})
		end
		path(12, LOOP_R - 7, 0, 24)
		for i = 1, C.NUM_PLOTS do
			path(LOOP_R + 7, C.BASE_RING_RADIUS - C.PLOT_D / 2, math.rad(-C.BASE_ARC / 2 + (i - 1) * C.BASE_ARC / (C.NUM_PLOTS - 1)), 12)
		end
		-- Lamp posts along the loop
		for i = 0, 19 do
			local a = (i + 0.5) / 20 * math.pi * 2
			local pos = ENTRANCE + Vector3.new(math.sin(a), 0, -math.cos(a)) * (LOOP_R - 10)
			if not inHall(pos, 10) and math.abs(math.sin(a)) > 0.06 then
				cyl(lobby, 12, 0.7, CFrame.new(pos + Vector3.new(0, 6, 0)), {Color = rgb(40, 40, 40), Material = M.Metal})
				local bulb = part(lobby, {Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 12.6, 0)), Color = rgb(255, 230, 170), Material = M.Neon})
				local light = Instance.new("PointLight")
				light.Color = rgb(255, 230, 170)
				light.Range = 22
				light.Shadows = false
				light.Parent = bulb
			end
		end
	end

	-- Hidden spawn pad (everyone is moved to their base right away)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("SpawnLocation") then
			obj.CFrame = CFrame.new(ENTRANCE + Vector3.new(0, 0.5, -90))
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CastShadow = false
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("Decal") or child:IsA("Texture") then
					child:Destroy()
				end
			end
		end
	end

	------------------------------------------------------------------
	-- FENCE + INVISIBLE WALL + GIANT TREES
	------------------------------------------------------------------
	local WALL_HEIGHT = 500
	local POST, RAIL = rgb(115, 78, 48), rgb(150, 105, 64)
	local function fencePiece(cf, len)
		part(lobby, {Name = "FencePost", Size = Vector3.new(1, 7, 1), CFrame = cf * CFrame.new(-len / 2, 3.5, 0), Color = POST, Material = M.Wood})
		for _, y in ipairs({2.4, 5.2}) do
			part(lobby, {Name = "FenceRail", Size = Vector3.new(len + 0.2, 0.6, 0.4), CFrame = cf * CFrame.new(0, y, 0), Color = RAIL, Material = M.WoodPlanks})
		end
		-- thick, so even the fastest runners can't slip through between physics steps
		part(lobby, {Name = "InvisibleWall", Size = Vector3.new(len + 2, WALL_HEIGHT, 12), CFrame = cf * CFrame.new(0, WALL_HEIGHT / 2, 0), Transparency = 1, CanQuery = false, CastShadow = false})
	end
	local segs = 260
	local segLen = 2 * C.FENCE_R * math.sin(math.pi / segs)
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi * 2
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local pos = ENTRANCE + dir * C.FENCE_R
		if not inHall(pos, 3) then
			fencePiece(CFrame.lookAt(pos, pos + dir), segLen)
		end
	end
	for _, sx in ipairs({-1, 1}) do
		local x = sx * (C.ROOM_W / 2 + 8)
		fencePiece(CFrame.new(x, 0, ENTRANCE.Z + math.sqrt(C.FENCE_R ^ 2 - x ^ 2)), 14)
	end

	local function giantTree(pos, s)
		cyl(scenery, 10 * s, 1.7 * s, CFrame.new(pos + Vector3.new(0, 5 * s, 0)), {Name = "Trunk", Color = rgb(105, 72, 45), Material = M.Wood})
		local leaf = rgb(45, rng:NextInteger(120, 165), 55)
		part(scenery, {Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * 10 * s, CFrame = CFrame.new(pos + Vector3.new(0, 11 * s, 0)), Color = leaf, Material = M.Grass, CastShadow = false})
		part(scenery, {Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * 7 * s, CFrame = CFrame.new(pos + Vector3.new(2.5 * s, 15 * s, 1 * s)), Color = leaf:Lerp(rgb(120, 200, 90), 0.25), Material = M.Grass, CastShadow = false})
	end
	for row = 0, 2 do
		local r = C.FENCE_R + 35 + row * 50
		local count = math.floor(2 * math.pi * r / 48)
		for i = 0, count - 1 do
			local a = (i + (row % 2) * 0.5 + rng:NextNumber(-0.2, 0.2)) / count * math.pi * 2
			local pos = ENTRANCE + Vector3.new(math.sin(a), 0, -math.cos(a)) * (r + rng:NextNumber(-8, 8))
			if not inHall(pos, 55) then
				giantTree(pos, rng:NextNumber(7, 11))
			end
		end
	end

	------------------------------------------------------------------
	-- PROPS
	------------------------------------------------------------------
	local function buildProp(parent, kind, pos, color)
		local face = CFrame.lookAt(pos, Vector3.new(0, pos.Y, pos.Z))
		if pos.X == 0 then
			face = CFrame.new(pos)
		end
		if kind == "crate" then
			part(parent, {Size = Vector3.new(6, 6, 6), CFrame = face * CFrame.new(0, 3, 0) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), Color = rgb(150, 105, 60), Material = M.WoodPlanks})
			part(parent, {Size = Vector3.new(4, 4, 4), CFrame = face * CFrame.new(0.5, 8, 0) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0), Color = rgb(170, 125, 75), Material = M.WoodPlanks})
		elseif kind == "barrel" then
			for i = 0, 1 do
				cyl(parent, 6, 4.5, face * CFrame.new(i * 5 - 2.5, 3, 0), {Color = rgb(115, 75, 40), Material = M.Wood})
			end
		elseif kind == "screen" then
			part(parent, {Size = Vector3.new(5, 10, 4), CFrame = face * CFrame.new(0, 5, 0), Color = rgb(30, 30, 40)})
			part(parent, {Size = Vector3.new(4, 3, 0.2), CFrame = face * CFrame.new(0, 7, -2.1), Color = color, Material = M.Neon})
		elseif kind == "lamp" then
			cyl(parent, 14, 0.8, face * CFrame.new(0, 7, 0), {Color = rgb(40, 40, 40), Material = M.Metal})
			local bulb = part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = face * CFrame.new(0, 14.5, 0), Color = color, Material = M.Neon})
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 20
			light.Shadows = false
			light.Parent = bulb
		elseif kind == "toyblock" then
			local colors = {rgb(255, 80, 80), rgb(80, 160, 255), rgb(255, 220, 60), rgb(90, 220, 110)}
			for i = 0, 2 do
				part(parent, {Size = Vector3.new(4, 4, 4), CFrame = face * CFrame.new(0, 2 + i * 4, 0) * CFrame.Angles(0, rng:NextNumber(-0.7, 0.7), 0), Color = colors[rng:NextInteger(1, #colors)]})
			end
		elseif kind == "cone" then
			for i, d in ipairs({3, 2.2, 1.4}) do
				cyl(parent, 1.6, d, face * CFrame.new(0, (i - 0.5) * 1.6, 0), {Color = (i == 2) and rgb(245, 245, 245) or rgb(255, 120, 20)})
			end
		elseif kind == "palm" then
			cyl(parent, 18, 1.6, face * CFrame.new(0, 9, 0), {Color = rgb(130, 95, 55), Material = M.Wood})
			for i = 0, 4 do
				part(parent, {Size = Vector3.new(10, 0.4, 2.4), CFrame = face * CFrame.new(0, 18, 0) * CFrame.Angles(0, i * math.pi * 2 / 5, -0.35) * CFrame.new(4.5, 0, 0), Color = rgb(60, 160, 60), Material = M.Grass, CanCollide = false})
			end
		elseif kind == "tombstone" then
			part(parent, {Size = Vector3.new(4, 5, 1.2), CFrame = face * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.1, 0.1)), Color = rgb(120, 120, 125), Material = M.Slate})
			part(parent, {Size = Vector3.new(4, 5, 1.2), CFrame = face * CFrame.new(5, 2, 2) * CFrame.Angles(0, 0, 0.15), Color = rgb(100, 100, 105), Material = M.Slate})
		elseif kind == "neonpillar" then
			cyl(parent, C.WALL_H - 4, 2.4, face * CFrame.new(0, (C.WALL_H - 4) / 2, 0), {Color = color, Material = M.Neon})
		elseif kind == "bamboo" then
			for i = -1, 1 do
				cyl(parent, 18 + i * 3, 1, face * CFrame.new(i * 1.4, 9 + i * 1.5, i * 0.7), {Color = rgb(110, 170, 70), Material = M.Wood})
			end
		elseif kind == "gear" then
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 11, 11), CFrame = face * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(150, 150, 160), Material = M.Metal})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.5, 3.5), CFrame = face * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.pi / 2, 0), Color = color, Material = M.Neon})
		elseif kind == "gold" then
			for _ = 1, 6 do
				local s = rng:NextNumber(1.5, 3.5)
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.one * s, CFrame = face * CFrame.new(rng:NextNumber(-3, 3), s / 2, rng:NextNumber(-2, 2)), Color = rgb(255, 200, 40), Material = M.Foil})
			end
		elseif kind == "rock" then
			part(parent, {Size = Vector3.new(rng:NextNumber(5, 8), rng:NextNumber(4, 7), rng:NextNumber(5, 8)), CFrame = face * CFrame.new(0, 2.5, 0) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), Color = color, Material = M.Basalt})
		elseif kind == "planet" then
			local planet = part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7), CFrame = face * CFrame.new(0, 16, 0), Color = color, Material = M.Neon, CanCollide = false})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 12, 12), CFrame = planet.CFrame * CFrame.Angles(0, 0, math.pi / 2 + 0.4), Color = rgb(220, 220, 255), Material = M.Glass, Transparency = 0.4, CanCollide = false})
		elseif kind == "crystal" then
			for i = 0, 2 do
				part(parent, {Size = Vector3.new(1.8, 6 + i * 2, 1.8), CFrame = face * CFrame.new(i * 1.6 - 1.6, 3 + i, 0) * CFrame.Angles(0, 0.78, (i - 1) * 0.3), Color = color, Material = M.Neon, Transparency = 0.2})
			end
		elseif kind == "pricetag" then
			part(parent, {Size = Vector3.new(0.6, 8, 0.6), CFrame = face * CFrame.new(0, 4, 0), Color = rgb(240, 240, 240)})
			local tag = part(parent, {Size = Vector3.new(7, 4.5, 0.4), CFrame = face * CFrame.new(0, 9, 0) * CFrame.Angles(0, 0, 0.12), Color = rgb(255, 225, 60)})
			local tt = Kit.surfaceText(tag, Enum.NormalId.Front, "SALE!", rgb(230, 40, 40), 30)
			tt.TextStrokeTransparency = 1
		elseif kind == "boxpile" then
			for i = 0, 4 do
				local s = rng:NextNumber(2.5, 4)
				part(parent, {Size = Vector3.new(s, s * 0.8, s), CFrame = face * CFrame.new(rng:NextNumber(-3, 3), s * 0.4 + (i >= 3 and 3 or 0), rng:NextNumber(-2, 2)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0), Color = rgb(200, 160, 110), Material = M.Cardboard})
			end
		elseif kind == "arcade" then
			part(parent, {Size = Vector3.new(4, 8, 3), CFrame = face * CFrame.new(0, 4, 0), Color = color:Lerp(rgb(20, 20, 30), 0.4)})
			part(parent, {Size = Vector3.new(3.2, 2.4, 0.2), CFrame = face * CFrame.new(0, 5.6, -1.55), Color = rgb(60, 220, 255), Material = M.Neon})
			part(parent, {Size = Vector3.new(4.2, 1.2, 3.2), CFrame = face * CFrame.new(0, 8.4, 0), Color = color, Material = M.Neon})
			part(parent, {Size = Vector3.new(3.6, 0.4, 1.4), CFrame = face * CFrame.new(0, 3.9, -2) * CFrame.Angles(-0.3, 0, 0), Color = rgb(30, 30, 40)})
			cyl(parent, 0.8, 0.3, face * CFrame.new(-0.8, 4.5, -2.1), {Color = rgb(30, 30, 30)})
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = face * CFrame.new(-0.8, 4.9, -2.1), Color = rgb(255, 50, 50)})
			for bi = 0, 2 do
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), CFrame = face * CFrame.new(0.3 + bi * 0.5, 4.2, -2.2), Color = ({rgb(255, 220, 50), rgb(80, 220, 90), rgb(70, 150, 255)})[bi + 1], Material = M.Neon})
			end
		elseif kind == "joystick" then
			part(parent, {Size = Vector3.new(6, 2, 6), CFrame = face * CFrame.new(0, 1, 0), Color = rgb(40, 40, 55)})
			cyl(parent, 6, 1, face * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, 0.25), {Color = rgb(30, 30, 30)})
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = face * CFrame.new(-0.8, 8.2, 0), Color = rgb(255, 50, 60)})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 1.6, 1.6), CFrame = face * CFrame.new(2, 2.2, -1.5) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 220, 50)})
		elseif kind == "teddy" then
			local fur = rgb(185, 125, 75)
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = face * CFrame.new(0, 2.5, 0), Color = fur, Material = M.Fabric})
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6), CFrame = face * CFrame.new(0, 6.3, 0), Color = fur, Material = M.Fabric})
			for _, ex in ipairs({-1, 1}) do
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = face * CFrame.new(ex * 1.4, 8, 0), Color = fur, Material = M.Fabric})
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), CFrame = face * CFrame.new(ex * 0.6, 6.7, -1.6), Color = rgb(20, 20, 20)})
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), CFrame = face * CFrame.new(ex * 2.4, 3, -0.5), Color = fur, Material = M.Fabric})
			end
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1, 1), CFrame = face * CFrame.new(0, 5.9, -1.6), Color = rgb(235, 200, 160), Material = M.Fabric})
			part(parent, {Size = Vector3.new(2.6, 0.6, 0.4), CFrame = face * CFrame.new(0, 4.6, -1.7), Color = rgb(230, 40, 60)})
		elseif kind == "bigball" then
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = face * CFrame.new(0, 3, 0), Color = rgb(255, 80, 80)})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 6.15, 6.15), CFrame = face * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, 0.5), Color = rgb(255, 255, 255)})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 6.2, 6.2), CFrame = face * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.pi / 2, 0.5), Color = rgb(60, 140, 255)})
		elseif kind == "chest" then
			part(parent, {Size = Vector3.new(6, 3.5, 4), CFrame = face * CFrame.new(0, 1.75, 0), Color = rgb(130, 80, 40), Material = M.WoodPlanks})
			part(parent, {Size = Vector3.new(6.2, 1.6, 4.2), CFrame = face * CFrame.new(0, 4.6, 1) * CFrame.Angles(-0.7, 0, 0), Color = rgb(150, 95, 50), Material = M.WoodPlanks})
			for _, bx in ipairs({-2.2, 2.2}) do
				part(parent, {Size = Vector3.new(0.5, 3.6, 4.1), CFrame = face * CFrame.new(bx, 1.8, 0), Color = rgb(255, 200, 40), Material = M.Metal})
			end
			for _ = 1, 5 do
				part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1, 1), CFrame = face * CFrame.new(rng:NextNumber(-2.5, 2.5), 3.6, rng:NextNumber(-1.5, 1)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 210, 50), Material = M.Foil})
			end
		elseif kind == "anchor" then
			local iron = rgb(70, 75, 85)
			part(parent, {Size = Vector3.new(1, 10, 1), CFrame = face * CFrame.new(0, 5.5, 0), Color = iron, Material = M.Metal})
			part(parent, {Size = Vector3.new(5, 0.8, 0.8), CFrame = face * CFrame.new(0, 9, 0), Color = iron, Material = M.Metal})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2.6, 2.6), CFrame = face * CFrame.new(0, 11.2, 0) * CFrame.Angles(0, math.pi / 2, 0), Color = iron, Material = M.Metal})
			for _, ax in ipairs({-1, 1}) do
				part(parent, {Size = Vector3.new(3.6, 0.9, 0.9), CFrame = face * CFrame.new(ax * 1.6, 1.6, 0) * CFrame.Angles(0, 0, ax * 0.6), Color = iron, Material = M.Metal})
			end
		elseif kind == "pumpkin" then
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(6, 4.6, 6), CFrame = face * CFrame.new(0, 2.3, 0), Color = rgb(255, 140, 30)})
			cyl(parent, 1.4, 0.7, face * CFrame.new(0, 5, 0), {Color = rgb(70, 140, 50)})
			for _, ex in ipairs({-1, 1}) do
				part(parent, {Size = Vector3.new(1, 1, 0.3), CFrame = face * CFrame.new(ex * 1.2, 3, -2.9) * CFrame.Angles(0, 0, math.pi / 4), Color = rgb(255, 230, 90), Material = M.Neon})
			end
			part(parent, {Size = Vector3.new(2.6, 0.5, 0.3), CFrame = face * CFrame.new(0, 1.6, -2.9), Color = rgb(255, 230, 90), Material = M.Neon})
		elseif kind == "ghost" then
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = face * CFrame.new(0, 9, 0), Color = rgb(245, 245, 255), Transparency = 0.15, CanCollide = false})
			cyl(parent, 4, 4, face * CFrame.new(0, 7, 0), {Color = rgb(245, 245, 255), Transparency = 0.15, CanCollide = false})
			for _, ex in ipairs({-1, 1}) do
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 1, 0.5), CFrame = face * CFrame.new(ex * 0.7, 9.3, -1.8), Color = rgb(20, 20, 30), CanCollide = false})
			end
		elseif kind == "holo" then
			cyl(parent, 1, 5, face * CFrame.new(0, 0.5, 0), {Color = rgb(40, 40, 60), Material = M.Metal})
			cyl(parent, 8, 4.4, face * CFrame.new(0, 5, 0), {Color = color, Material = M.Neon, Transparency = 0.75, CanCollide = false})
			part(parent, {Size = Vector3.new(2, 2, 2), CFrame = face * CFrame.new(0, 5.5, 0) * CFrame.Angles(0.6, 0.6, 0), Color = color, Material = M.Neon, Transparency = 0.2, CanCollide = false})
		elseif kind == "lantern" then
			cyl(parent, 10, 0.5, face * CFrame.new(0, 5, 0), {Color = rgb(60, 40, 30), Material = M.Wood})
			local lan = part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3.8, 3), CFrame = face * CFrame.new(0, 10.4, 0), Color = rgb(235, 50, 40), Material = M.Neon, Transparency = 0.1})
			for _, cy in ipairs({-1.9, 1.9}) do
				cyl(parent, 0.4, 1.8, face * CFrame.new(0, 10.4 + cy, 0), {Color = rgb(30, 30, 30)})
			end
			local l = Instance.new("PointLight")
			l.Color = rgb(255, 120, 80)
			l.Range = 12
			l.Shadows = false
			l.Parent = lan
		elseif kind == "torii" then
			local red = rgb(220, 40, 40)
			for _, tx in ipairs({-3.5, 3.5}) do
				cyl(parent, 12, 1.1, face * CFrame.new(tx, 6, 0), {Color = red})
			end
			part(parent, {Size = Vector3.new(11, 1, 1.4), CFrame = face * CFrame.new(0, 12.4, 0), Color = rgb(30, 30, 30)})
			part(parent, {Size = Vector3.new(9, 0.8, 1), CFrame = face * CFrame.new(0, 10.4, 0), Color = red})
		elseif kind == "robot" then
			local steel = rgb(170, 180, 195)
			part(parent, {Size = Vector3.new(4, 5, 3), CFrame = face * CFrame.new(0, 4, 0), Color = steel, Material = M.Metal})
			part(parent, {Size = Vector3.new(3, 2.4, 2.6), CFrame = face * CFrame.new(0, 7.8, 0), Color = steel, Material = M.Metal})
			for _, ex in ipairs({-1, 1}) do
				part(parent, {Size = Vector3.new(0.7, 0.5, 0.2), CFrame = face * CFrame.new(ex * 0.7, 8, -1.35), Color = color, Material = M.Neon})
				part(parent, {Size = Vector3.new(1, 3.6, 1), CFrame = face * CFrame.new(ex * 2.6, 4.4, 0), Color = steel:Lerp(rgb(0, 0, 0), 0.2), Material = M.Metal})
				part(parent, {Size = Vector3.new(1.2, 1.6, 1.2), CFrame = face * CFrame.new(ex * 1, 0.8, 0), Color = steel:Lerp(rgb(0, 0, 0), 0.3), Material = M.Metal})
			end
			cyl(parent, 1.4, 0.2, face * CFrame.new(0, 9.7, 0), {Color = rgb(60, 60, 60)})
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = face * CFrame.new(0, 10.5, 0), Color = rgb(255, 60, 60), Material = M.Neon})
		elseif kind == "egg" then
			for i = 0, 5 do
				part(parent, {Size = Vector3.new(4, 0.8, 0.8), CFrame = face * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, i * math.pi / 3, 0) * CFrame.new(1.6, 0, 0), Color = rgb(120, 85, 50), Material = M.Wood})
			end
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 5, 3.6), CFrame = face * CFrame.new(0, 3.4, 0), Color = color, Material = M.Glass, Reflectance = 0.2})
			for _ = 1, 5 do
				part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = face * CFrame.new(0, 3.4, 0) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(0, 6), 0) * CFrame.new(0, 0, -1.65), Color = rgb(255, 230, 120), Material = M.Neon, CanCollide = false})
			end
		elseif kind == "rocket" then
			cyl(parent, 10, 3, face * CFrame.new(0, 6, 0), {Color = rgb(240, 240, 250)})
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(3, 4, 3), CFrame = face * CFrame.new(0, 11.2, 0), Color = rgb(235, 50, 60)})
			part(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.4, 1.4), CFrame = face * CFrame.new(0, 8, -1.5) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(120, 200, 255), Material = M.Neon})
			for i = 0, 2 do
				Kit.wedge(parent, {Size = Vector3.new(0.4, 3, 2.4), CFrame = face * CFrame.new(0, 2, 0) * CFrame.Angles(0, i * math.pi * 2 / 3, 0) * CFrame.new(0, 0, -2.2), Color = rgb(235, 50, 60)})
			end
			part(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 1.6, 2.4), CFrame = face * CFrame.new(0, 0.6, 0), Color = rgb(255, 170, 40), Material = M.Neon, CanCollide = false})
		end
	end

	-- Extra themed decorations for every area (index = area number)
	local ZONE_DECOR = {
		{"pricetag", "boxpile", "crate"},      -- Bargain Basement
		{"arcade", "joystick", "arcade"},       -- Retro Arcade
		{"teddy", "bigball", "toyblock"},      -- Toys
		{"chest", "anchor", "barrel"},         -- Pirate Cove
		{"pumpkin", "ghost", "tombstone"},     -- Haunted
		{"holo", "screen", "robot"},           -- Cyber City
		{"lantern", "torii", "bamboo"},        -- Ninja
		{"robot", "gear", "holo"},             -- Robots
		{"egg", "crystal", "rock"},            -- Dragon
		{"rocket", "planet", "crystal"},       -- Space
	}
	local ZONE_EMBLEM = {"\u{1F4B0}", "\u{1F579}", "\u{1F9F8}", "\u{2693}", "\u{1F47B}", "\u{1F4BE}", "\u{1F3EE}", "\u{1F916}", "\u{1F409}", "\u{1F680}"}
	local DECOR_SPOTS = {{38, 0.22}, {-36, 0.5}, {42, 0.66}, {-22, 0.86}, {22, 0.86}, {46, 0.46}}

	local FLOOR_COLORS = {
		[M.Mud] = rgb(200, 150, 100), [M.Brick] = rgb(235, 120, 110), [M.LeafyGrass] = rgb(110, 210, 90),
		[M.Sand] = rgb(250, 225, 160), [M.Slate] = rgb(160, 150, 200), [M.Concrete] = rgb(170, 230, 235),
		[M.WoodPlanks] = rgb(225, 170, 110), [M.Pavement] = rgb(200, 210, 225), [M.CrackedLava] = rgb(240, 130, 90),
		[M.Basalt] = rgb(140, 140, 220),
	}

	------------------------------------------------------------------
	-- HIGH WALL DECOR: framed posters of the store's games, a themed piece
	-- mounted between them, and a painted frieze near the top of each wall
	------------------------------------------------------------------
	local ZONE_ART = {
		{"\u{1F4B8}", "\u{1F3F7}\u{FE0F}", "\u{1F6D2}", "\u{1F4B0}", "\u{1F4E6}"},             -- Bargain Basement
		{"\u{1F47E}", "\u{1F579}\u{FE0F}", "\u{1F352}", "\u{1F47B}", "\u{2B50}"},              -- Retro Arcade
		{"\u{1F9F8}", "\u{1F3B2}", "\u{1F682}", "\u{1F388}", "\u{1F3A0}"},                     -- Toy Town
		{"\u{1F3F4}\u{200D}\u{2620}\u{FE0F}", "\u{1F99C}", "\u{2693}", "\u{1F5FA}\u{FE0F}", "\u{1F980}"}, -- Pirate Cove
		{"\u{1F987}", "\u{1F480}", "\u{1F578}\u{FE0F}", "\u{1F383}", "\u{1F56F}\u{FE0F}"},       -- Haunted Crypt
		{"\u{1F4BE}", "\u{1F50C}", "\u{1F6F0}\u{FE0F}", "\u{1F4BF}", "\u{26A1}"},              -- Cyber City
		{"\u{26E9}\u{FE0F}", "\u{1F3EF}", "\u{1F338}", "\u{1F38B}", "\u{1F3EE}"},              -- Ninja Dojo
		{"\u{2699}\u{FE0F}", "\u{1F529}", "\u{1F916}", "\u{1F50B}", "\u{1F527}"},              -- Robot Factory
		{"\u{1F409}", "\u{1F525}", "\u{1F6E1}\u{FE0F}", "\u{1F48E}", "\u{1F5E1}\u{FE0F}"},       -- Dragon's Lair
		{"\u{1F315}", "\u{1F680}", "\u{1F30C}", "\u{1F47D}", "\u{2604}\u{FE0F}"},              -- Outer Space
	}
	local SALE_TEXT = {"SALE!", "50% OFF", "$1!"}
	local deco = {Name = "WallDecor", CanCollide = false, CanQuery = false, CastShadow = false}
	local function decoPart(parent, props)
		for k, v in pairs(deco) do
			if props[k] == nil then
				props[k] = v
			end
		end
		return part(parent, props)
	end
	-- A spot on the inside face of a wall, facing into the hallway (local -Z points into the room)
	local function wallCF(side, y, z)
		local pos = Vector3.new(side * (C.ROOM_W / 2 - 0.2), y, z)
		return CFrame.lookAt(pos, pos - Vector3.new(side, 0, 0))
	end
	local function wallGui(p, ppsd)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = ppsd
		sg.LightInfluence = 0.2
		sg.MaxDistance = 260
		sg.Parent = p
		return sg
	end
	local function guiLabel(parent, pos, size, text, color)
		local t = Instance.new("TextLabel")
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position, t.Size = pos, size
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = color or Color3.new(1, 1, 1)
		t.Text = text
		t.Parent = parent
		return t
	end

	-- A framed poster: a little scene with a big picture and the game's name underneath
	local function painting(parent, cf, icon, caption, top, bottom, frameColor)
		local w, h = 18, 13
		decoPart(parent, {Name = "PaintingFrame", Size = Vector3.new(w + 1.6, h + 1.6, 0.6), CFrame = cf * CFrame.new(0, 0, -0.3), Color = frameColor, Material = M.Wood})
		local canvas = decoPart(parent, {Name = "Painting", Size = Vector3.new(w, h, 0.2), CFrame = cf * CFrame.new(0, 0, -0.65), Color = bottom})
		local sg = wallGui(canvas, 12)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BorderSizePixel = 0
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		bg.Parent = sg
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(top, bottom)
		grad.Rotation = 90
		grad.Parent = bg
		local ground = Instance.new("Frame")
		ground.Position = UDim2.fromScale(0, 0.7)
		ground.Size = UDim2.fromScale(1, 0.3)
		ground.BorderSizePixel = 0
		ground.BackgroundColor3 = bottom:Lerp(Color3.new(0, 0, 0), 0.3)
		ground.Parent = bg
		local glow = Instance.new("Frame")
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromScale(0.5, 0.42)
		glow.Size = UDim2.fromScale(0.62, 0.62)
		glow.SizeConstraint = Enum.SizeConstraint.RelativeYY
		glow.BackgroundColor3 = Color3.new(1, 1, 1)
		glow.BackgroundTransparency = 0.55
		glow.Parent = bg
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = glow
		guiLabel(bg, UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.8, 0.58), icon)
		local cap = guiLabel(bg, UDim2.fromScale(0.5, 0.86), UDim2.fromScale(0.9, 0.2), string.upper(caption))
		cap.TextStrokeTransparency = 0
	end

	-- One themed piece mounted on the wall (k = 1..3 picks a variation)
	local function wallPiece(parent, zi, cf, accent, art, k)
		local at = function(x, y, z) return cf * CFrame.new(x, y, z) end
		local faceOut = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder so its flat face points into the room
		if zi == 1 then -- price tag on a string
			decoPart(parent, {Size = Vector3.new(0.15, 3.2, 0.15), CFrame = at(-1.2, 4.2, -0.3) * CFrame.Angles(0, 0, -0.35), Color = rgb(240, 240, 240)})
			local tag = decoPart(parent, {Size = Vector3.new(9, 5.5, 0.4), CFrame = at(0, 0, -0.45) * CFrame.Angles(0, 0, 0.12), Color = rgb(255, 225, 60)})
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 1, 1), CFrame = at(-3.4, 1.9, -0.55) * faceOut, Color = rgb(60, 50, 40)})
			local t = Kit.surfaceText(tag, Enum.NormalId.Front, SALE_TEXT[k], rgb(220, 40, 40), 20)
			t.TextStrokeTransparency = 1
		elseif zi == 2 or zi == 6 then -- glowing neon sign
			local glow = zi == 2 and accent or rgb(60, 230, 255)
			decoPart(parent, {Size = Vector3.new(10.8, 7.8, 0.2), CFrame = at(0, 0, -0.15), Color = glow, Material = M.Neon})
			local panel = decoPart(parent, {Size = Vector3.new(10, 7, 0.4), CFrame = at(0, 0, -0.45), Color = rgb(20, 18, 35)})
			guiLabel(wallGui(panel, 12), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.86, 0.86), art[k])
		elseif zi == 3 then -- kite with a bow tail
			decoPart(parent, {Size = Vector3.new(5.6, 5.6, 0.3), CFrame = at(0, 1.5, -0.45) * CFrame.Angles(0, 0, math.pi / 4), Color = accent})
			decoPart(parent, {Size = Vector3.new(0.25, 7.8, 0.2), CFrame = at(0, 1.5, -0.7), Color = rgb(130, 90, 50)})
			decoPart(parent, {Size = Vector3.new(7.8, 0.25, 0.2), CFrame = at(0, 1.5, -0.7), Color = rgb(130, 90, 50)})
			for b = 1, 3 do
				decoPart(parent, {Size = Vector3.new(1.4, 0.7, 0.2), CFrame = at((b % 2 == 0) and 0.5 or -0.5, -2.8 - b * 1.6, -0.45) * CFrame.Angles(0, 0, (b % 2 == 0) and 0.4 or -0.4), Color = ({rgb(80, 160, 255), rgb(90, 220, 110), rgb(255, 220, 60)})[b]})
			end
		elseif zi == 4 then -- ship's wheel
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 6.6, 6.6), CFrame = at(0, 0, -0.4) * faceOut, Color = rgb(120, 75, 40), Material = M.Wood})
			for s = 0, 3 do
				decoPart(parent, {Size = Vector3.new(0.55, 10, 0.55), CFrame = at(0, 0, -0.75) * CFrame.Angles(0, 0, s * math.pi / 4), Color = rgb(150, 100, 55), Material = M.Wood})
			end
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.8, 1.8), CFrame = at(0, 0, -1) * faceOut, Color = Kit.GOLD, Material = M.Metal})
		elseif zi == 5 then -- bat
			local s = 1.4
			decoPart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 2, 1) * s, CFrame = at(0, 0, -0.7), Color = rgb(35, 25, 45)})
			for _, sx in ipairs({-1, 1}) do
				decoPart(parent, {Size = Vector3.new(3.4, 1.4, 0.2) * s, CFrame = at(sx * 2.4 * s, 0.4, -0.5) * CFrame.Angles(0, 0, sx * 0.35), Color = rgb(45, 30, 60)})
				decoPart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.3) * s, CFrame = at(sx * 0.35 * s, 0.4 * s, -1.4), Color = rgb(255, 60, 60), Material = M.Neon})
			end
		elseif zi == 7 then -- hanging scroll
			decoPart(parent, {Size = Vector3.new(8, 0.6, 0.6), CFrame = at(0, 5.4, -0.4), Color = rgb(60, 35, 25), Material = M.Wood})
			local paper = decoPart(parent, {Size = Vector3.new(7, 10, 0.15), CFrame = at(0, 0, -0.35), Color = rgb(250, 240, 215), Material = M.Fabric})
			decoPart(parent, {Size = Vector3.new(8, 0.6, 0.6), CFrame = at(0, -5.4, -0.4), Color = rgb(60, 35, 25), Material = M.Wood})
			guiLabel(wallGui(paper, 10), UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.8, 0.6), art[k])
		elseif zi == 8 then -- spinning-gear look
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 7, 7), CFrame = at(0, 0, -0.45) * faceOut, Color = rgb(150, 155, 165), Material = M.Metal})
			for s = 0, 3 do
				decoPart(parent, {Size = Vector3.new(1.6, 9, 0.5), CFrame = at(0, 0, -0.45) * CFrame.Angles(0, 0, s * math.pi / 4), Color = rgb(130, 135, 145), Material = M.Metal})
			end
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.4, 2.4), CFrame = at(0, 0, -0.8) * faceOut, Color = accent, Material = M.Neon})
		elseif zi == 9 then -- shield over crossed swords
			for _, a in ipairs({-0.7, 0.7}) do
				decoPart(parent, {Size = Vector3.new(0.5, 12, 0.3), CFrame = at(0, 0, -0.2) * CFrame.Angles(0, 0, a), Color = rgb(210, 215, 225), Material = M.Metal})
			end
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 8.2, 8.2), CFrame = at(0, 0, -0.5) * faceOut, Color = Kit.GOLD, Material = M.Metal})
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 7.2, 7.2), CFrame = at(0, 0, -0.65) * faceOut, Color = accent})
			decoPart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), CFrame = at(0, 0, -0.95), Color = Kit.GOLD, Material = M.Metal})
		else -- glowing planet with a ring
			local colors = {rgb(255, 140, 90), rgb(110, 200, 255), rgb(200, 120, 255)}
			local planet = decoPart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = at(0, 0, -3), Color = colors[k], Material = M.Neon})
			decoPart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 9, 9), CFrame = planet.CFrame * CFrame.Angles(0.3, 0, math.pi / 2 + 0.5), Color = rgb(230, 230, 255), Material = M.Glass, Transparency = 0.35})
		end
	end

	local function buildWallArt(parent, L, z0)
		local zi = L.ZoneIndex
		local art = ZONE_ART[zi] or ZONE_ART[1]
		local accent = L.Accent
		local top, bottom = accent:Lerp(Color3.new(1, 1, 1), 0.45), L.Wall:Lerp(DARK, 0.35)
		local frameColor = zi >= 6 and Kit.GOLD or rgb(120, 80, 45)
		local captions = {{L.Games[1].Name, L.Games[2].Name}, {L.Games[3].Name, L.Store}}
		local friezeIcons = {}
		for _ = 1, 6 do
			for _, icon in ipairs(art) do
				table.insert(friezeIcons, icon)
			end
		end
		local friezeText = table.concat(friezeIcons, "   ")
		for si, side in ipairs({-1, 1}) do
			for pi, f in ipairs({0.3, 0.7}) do
				painting(parent, wallCF(side, 48, z0 + C.SEG_LEN * f), art[(L.Index + si + pi) % #art + 1], captions[si][pi], top, bottom, frameColor)
			end
			for k, f in ipairs({0.13, 0.5, 0.87}) do
				wallPiece(parent, zi, wallCF(side, 50, z0 + C.SEG_LEN * f), accent, art, k)
			end
			local frieze = decoPart(parent, {Name = "Frieze", Size = Vector3.new(C.SEG_LEN - 12, 5, 0.3), CFrame = wallCF(side, 85, z0 + C.SEG_LEN / 2) * CFrame.new(0, 0, -0.2), Color = accent:Lerp(Color3.new(1, 1, 1), 0.2)})
			guiLabel(wallGui(frieze, 6), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.98, 0.8), friezeText)
		end
	end

	local function buildShelf(parent, side, z, colors)
		local wallX = side * (C.ROOM_W / 2 - 0.3)
		local shelfX = side * (C.ROOM_W / 2 - 2.4)
		local wood, lightWood = rgb(70, 50, 35), rgb(115, 85, 55)
		-- One solid invisible block so fast runners can't slip in between the shelves
		part(parent, {Name = "ShelfCollider", Size = Vector3.new(5.2, 16, 19), CFrame = CFrame.new(side * (C.ROOM_W / 2 - 2.6), 8, z), Transparency = 1, CanCollide = true})
		part(parent, {Size = Vector3.new(0.6, 14, 18), CFrame = CFrame.new(wallX, 7, z), Color = wood, Material = M.Wood, CanCollide = false})
		for _, dz in ipairs({-9, 9}) do
			part(parent, {Size = Vector3.new(4, 14, 0.4), CFrame = CFrame.new(shelfX, 7, z + dz), Color = wood, Material = M.Wood, CanCollide = false})
		end
		for row = 0, 3 do
			local y = 1.5 + row * 3.4
			part(parent, {Size = Vector3.new(3.8, 0.3, 18), CFrame = CFrame.new(shelfX, y, z), Color = lightWood, Material = M.WoodPlanks, CanCollide = false})
			for b = 0, 4 do
				part(parent, {Size = Vector3.new(1.6, 2.4, 1.2), CFrame = CFrame.new(shelfX, y + 1.35, z - 6.4 + b * 3.2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color = colors[rng:NextInteger(1, #colors)], CanCollide = false})
			end
		end
	end

	------------------------------------------------------------------
	-- THE VAULT: one long hallway, split into levels by lines and signs
	------------------------------------------------------------------
	local HALF = C.ROOM_W / 2
	for level = 1, C.NUM_LEVELS do
		local L = C.LEVELS[level]
		local zone = L.Zone
		local z0 = segStart(level)
		local zMid = z0 + C.SEG_LEN / 2
		local accent = L.Accent
		local zoneStart = (L.Sub == 1)
		local COUNTER_Z, PED_Z = z0 + C.SEG_LEN * 0.32, z0 + C.SEG_LEN * 0.6

		local seg = Instance.new("Model")
		seg.Name = string.format("%02d_%s", level, L.Store)
		seg.Parent = vault
		W.SegModels[level] = seg
		local decor = Instance.new("Model")
		decor.Name = "Decor"
		decor.Parent = seg

		part(seg, {Name = "Floor", Size = Vector3.new(C.ROOM_W + 6, 8, C.SEG_LEN), CFrame = CFrame.new(0, -3.8, zMid), Color = FLOOR_COLORS[zone.Ground] or rgb(120, 120, 120), Material = zone.Ground})
		part(seg, {Name = "Underside", Size = Vector3.new(C.ROOM_W + 4, 24, C.SEG_LEN), CFrame = CFrame.new(0, -20, zMid), Color = rgb(80, 75, 75), Material = M.Slate})
		part(decor, {Name = "Carpet", Size = Vector3.new(30, 0.15, C.SEG_LEN), CFrame = CFrame.new(0, 0.28, zMid), Color = accent:Lerp(Color3.new(1, 1, 1), 0.25), Material = M.Fabric, CanCollide = false})

		for _, sx in ipairs({-1, 1}) do
			part(seg, {Name = "Wall", Size = Vector3.new(3, C.WALL_H, C.SEG_LEN), CFrame = CFrame.new(sx * (HALF + 1.5), C.WALL_H / 2, zMid), Color = L.Wall, Material = zone.WallMat})
			-- Bright painted stripes instead of neon
			part(seg, {Name = "Stripe", Size = Vector3.new(0.4, 3, C.SEG_LEN), CFrame = CFrame.new(sx * (HALF - 0.1), 18, zMid), Color = accent, Material = M.SmoothPlastic, CanCollide = false})
			part(seg, {Name = "Stripe", Size = Vector3.new(0.4, 1.5, C.SEG_LEN), CFrame = CFrame.new(sx * (HALF - 0.1), 21.5, zMid), Color = Color3.new(1, 1, 1), Material = M.SmoothPlastic, CanCollide = false})
			part(seg, {Name = "WallCap", Size = Vector3.new(5, 2, C.SEG_LEN), CFrame = CFrame.new(sx * (HALF + 1.5), C.WALL_H + 1, zMid), Color = accent, Material = M.SmoothPlastic})
			part(seg, {Name = "Baseboard", Size = Vector3.new(0.5, 1.6, C.SEG_LEN), CFrame = CFrame.new(sx * (HALF - 0.1), 0.8, zMid), Color = Color3.new(1, 1, 1)})
		end

		-- DIVIDER LINE + SIGN at the start of every level (bigger at the start of every area)
		local lineColor = zoneStart and L.Wall:Lerp(Color3.new(1, 1, 1), 0.2) or accent
		part(decor, {Name = "Divider", Size = Vector3.new(C.ROOM_W, 0.3, zoneStart and 5 or 1.5), CFrame = CFrame.new(0, 0.38, z0 + (zoneStart and 2.5 or 0.75)), Color = lineColor, Material = M.SmoothPlastic, CanCollide = false})
		-- A big colourful archway marks each new level (tall, so the giant shopkeepers fit under the signs)
		local archH = zoneStart and 80 or 70
		for _, sx in ipairs({-1, 1}) do
			part(decor, {Name = "ArchPillar", Size = Vector3.new(5, archH, 5), CFrame = CFrame.new(sx * (HALF - 2.5), archH / 2, z0 + 2.5), Color = lineColor, Material = M.SmoothPlastic})
			part(decor, {Name = "ArchBall", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(sx * (HALF - 2.5), archH + 3, z0 + 2.5), Color = Color3.new(1, 1, 1), Material = M.SmoothPlastic})
		end
		part(decor, {Name = "ArchBeam", Size = Vector3.new(C.ROOM_W, 4, 5), CFrame = CFrame.new(0, archH - 2, z0 + 2.5), Color = lineColor, Material = M.SmoothPlastic})
		local floorLabel = part(decor, {Name = "FloorLabel", Size = Vector3.new(9, 0.1, 60), CFrame = CFrame.new(0, 0.5, z0 + (zoneStart and 11 or 7)) * CFrame.Angles(0, math.pi / 2, 0), Transparency = 1, CanCollide = false})
		Kit.surfaceText(floorLabel, Enum.NormalId.Top, string.upper(L.Store), Color3.new(1, 1, 1), 20)
		local signW = zoneStart and C.ROOM_W - 20 or 64
		local signH = zoneStart and 12 or 8
		local signY = archH - 4 - signH / 2 - 1
		local sign = part(decor, {Name = "LevelSign", Size = Vector3.new(signW, signH, 0.8), CFrame = CFrame.new(0, signY, z0 + 0.2), Color = Color3.new(1, 1, 1)})
		part(decor, {Name = "LevelSignFrame", Size = Vector3.new(signW + 1.6, signH + 1.6, 0.5), CFrame = CFrame.new(0, signY, z0 + 0.6), Color = lineColor:Lerp(Color3.new(0, 0, 0), 0.15), Material = M.SmoothPlastic})
		local signText = zoneStart and string.upper(zone.Name) or string.upper(L.Store)
		local signLabel = Kit.surfaceText(sign, Enum.NormalId.Front, signText, lineColor:Lerp(Color3.new(0, 0, 0), 0.35), zoneStart and 14 or 20)
		signLabel.TextStrokeTransparency = 1

		-- Shelves and decorations along the walls
		local boxColors = {accent, zone.Color, accent:Lerp(Color3.new(1, 1, 1), 0.4), zone.Color:Lerp(DARK, 0.3), rgb(240, 240, 240), rgb(40, 40, 50)}
		for _, side in ipairs({-1, 1}) do
			for _, sz in ipairs({C.SEG_LEN * 0.15, C.SEG_LEN * 0.45, C.SEG_LEN * 0.8}) do
				buildShelf(decor, side, z0 + sz, boxColors)
			end
		end
		buildProp(decor, zone.Props[1], Vector3.new(48, 0, z0 + C.SEG_LEN * 0.3), accent)
		buildProp(decor, zone.Props[1], Vector3.new(-48, 0, z0 + C.SEG_LEN * 0.7), accent)
		buildProp(decor, zone.Props[2], Vector3.new(-50, 0, z0 + C.SEG_LEN * 0.94), accent)
		buildProp(decor, zone.Props[2], Vector3.new(50, 0, z0 + C.SEG_LEN * 0.94), accent)
		-- themed decorations for this area
		local kinds = ZONE_DECOR[L.ZoneIndex] or ZONE_DECOR[1]
		for i, spot in ipairs(DECOR_SPOTS) do
			buildProp(decor, kinds[(i + level) % #kinds + 1], Vector3.new(spot[1], 0, z0 + C.SEG_LEN * spot[2]), accent)
		end
		buildWallArt(decor, L, z0)

		-- OUTSIDE of the hallway: pilasters, colour bands, battlements and a big area emblem
		do
			local outsideColor = L.Wall:Lerp(Color3.new(1, 1, 1), 0.35)
			for _, sx in ipairs({-1, 1}) do
				local ox = sx * (HALF + 3)
				for _, by in ipairs({10, C.WALL_H - 10}) do
					part(decor, {Name = "OutBand", Size = Vector3.new(1, 4, C.SEG_LEN), CFrame = CFrame.new(ox + sx * 0.5, by, zMid), Color = accent, Material = M.SmoothPlastic})
				end
				for pz = 25, C.SEG_LEN, 50 do
					part(decor, {Name = "OutPilaster", Size = Vector3.new(2.4, C.WALL_H, 6), CFrame = CFrame.new(ox + sx * 1.2, C.WALL_H / 2, z0 + pz), Color = outsideColor, Material = M.SmoothPlastic})
				end
				for mz = 10, C.SEG_LEN, 20 do
					part(decor, {Name = "Merlon", Size = Vector3.new(5, 4, 8), CFrame = CFrame.new(sx * (HALF + 1.5), C.WALL_H + 4, z0 + mz), Color = accent, Material = M.SmoothPlastic})
				end
				-- big round emblem with the area's picture
				local ez = z0 + C.SEG_LEN * 0.5
				part(decor, {Name = "EmblemRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 34, 34), CFrame = CFrame.new(ox + sx * 0.6, 48, ez), Color = Color3.new(1, 1, 1), Material = M.SmoothPlastic})
				part(decor, {Name = "EmblemDisc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 29, 29), CFrame = CFrame.new(ox + sx * 0.8, 48, ez), Color = accent, Material = M.SmoothPlastic})
				local pic = part(decor, {Name = "Emblem", Size = Vector3.new(0.2, 18, 18), CFrame = CFrame.new(ox + sx * 1.3, 48, ez), Transparency = 1, CanCollide = false})
				local sg = Instance.new("SurfaceGui")
				sg.Face = sx > 0 and Enum.NormalId.Right or Enum.NormalId.Left
				sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				sg.PixelsPerStud = 12
				sg.LightInfluence = 0
				sg.Parent = pic
				local em = Instance.new("TextLabel")
				em.Size = UDim2.fromScale(1, 1)
				em.BackgroundTransparency = 1
				em.TextScaled = true
				em.Text = ZONE_EMBLEM[L.ZoneIndex] or "\u{1F3AE}"
				em.Parent = sg
			end
		end

		-- Checkout counter (the shopkeeper waits behind it)
		part(decor, {Name = "Counter", Size = Vector3.new(18, 3.6, 3), CFrame = CFrame.new(-42, 1.8, COUNTER_Z), Color = L.Wall:Lerp(rgb(255, 255, 255), 0.2), Material = zone.WallMat})
		part(decor, {Name = "CounterTop", Size = Vector3.new(18.6, 0.4, 3.6), CFrame = CFrame.new(-42, 3.8, COUNTER_Z), Color = accent, Material = M.SmoothPlastic})
		part(decor, {Name = "Register", Size = Vector3.new(2, 1.4, 1.6), CFrame = CFrame.new(-47, 4.6, COUNTER_Z), Color = rgb(40, 40, 45), Material = M.Metal})

		-- Three display pedestals
		for _, px in ipairs({-30, 0, 30}) do
			local ped = part(decor, {Name = "Pedestal", Size = Vector3.new(6, 2.4, 6), CFrame = CFrame.new(px, 1.2, PED_Z), Color = accent:Lerp(Color3.new(1, 1, 1), 0.55), Material = M.Marble})
			part(decor, {Name = "PedestalRing", Size = Vector3.new(7.6, 0.4, 7.6), CFrame = CFrame.new(px, 0.4, PED_Z), Color = accent, Material = M.SmoothPlastic, CanCollide = false})
			table.insert(W.Spots, {Pedestal = ped, Level = level, Item = nil, Data = nil, Carried = false})
		end
		local timerPart = part(decor, {Name = "RestockTimer", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 20, PED_Z), Transparency = 1, CanCollide = false})
		W.RestockLabels[level] = Kit.billboard(timerPart, 300, 56, 0, "IN STOCK", 140)

		-- Recommended speed: a smaller sign hanging on two chains under the level's name sign
		do
			local hangW, hangH = zoneStart and 40 or 34, zoneStart and 9.5 or 8.5
			local chainTop = signY - signH / 2 - 0.8
			local chainLen = 2.4
			local hy = chainTop - chainLen - hangH / 2
			for _, cx in ipairs({-hangW / 2 + 2.5, hangW / 2 - 2.5}) do
				part(decor, {Name = "SpeedSignChain", Size = Vector3.new(0.3, chainLen + 0.4, 0.3), CFrame = CFrame.new(cx, chainTop - chainLen / 2, z0 + 0.4), Color = rgb(70, 70, 80), Material = M.Metal, CanCollide = false})
			end
			local board = part(decor, {Name = "SpeedSign", Size = Vector3.new(hangW, hangH, 0.6), CFrame = CFrame.new(0, hy, z0 + 0.2), Color = rgb(30, 28, 45), CanCollide = false})
			part(decor, {Name = "SpeedSignFrame", Size = Vector3.new(hangW + 1, hangH + 1, 0.4), CFrame = CFrame.new(0, hy, z0 + 0.55), Color = lineColor:Lerp(Color3.new(0, 0, 0), 0.15), CanCollide = false})
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 20
			sg.LightInfluence = 0
			sg.Parent = board
			guiLabel(sg, UDim2.fromScale(0.5, 0.24), UDim2.fromScale(0.9, 0.3), "RECOMMENDED SPEED", rgb(200, 200, 220))
			local num = guiLabel(sg, UDim2.fromScale(0.5, 0.66), UDim2.fromScale(0.9, 0.52), "\u{1F45F} " .. Kit.fmt(C.recommendedSpeed(level)), rgb(120, 255, 140))
			num.TextStrokeTransparency = 0
		end

		Kit.setGroup(decor, "Decor")
	end
	local lastL = C.LEVELS[C.NUM_LEVELS]
	-- Invisible roof: sits right on top of the walls (no gap to climb into) and is thick
	-- and wider than the hallway, so nobody gets in or out over the top at any speed
	part(vault, {Name = "InvisibleRoof", Size = Vector3.new(C.ROOM_W + 24, 10, hallEnd - C.HALL_START_Z + 8), CFrame = CFrame.new(0, C.WALL_H + 2 + 5, (C.HALL_START_Z + hallEnd) / 2), Transparency = 1, CanCollide = true, CanQuery = false, CastShadow = false})
	part(vault, {Name = "VaultEnd", Size = Vector3.new(C.ROOM_W + 6, C.WALL_H, 3), CFrame = CFrame.new(0, C.WALL_H / 2, hallEnd + 1.5), Color = lastL.Wall, Material = lastL.Zone.WallMat})

	-- Grand entrance: a big, bright, game-themed gateway
	do
		local front = Instance.new("Model")
		front.Name = "VaultEntrance"
		front.Parent = vault
		local z = C.HALL_START_Z
		local EW, EH = C.ENTRANCE_W, C.ENTRANCE_H
		local sideW = (C.ROOM_W - EW) / 2 + 3
		local WHITE = Color3.new(1, 1, 1)
		local wallColor = rgb(120, 95, 235)
		local PALETTE = {rgb(255, 80, 80), rgb(255, 170, 40), rgb(255, 230, 60), rgb(90, 220, 90), rgb(70, 170, 255), rgb(190, 110, 255), rgb(255, 120, 200)}

		for _, sx in ipairs({-1, 1}) do
			part(front, {Name = "FrontWall", Size = Vector3.new(sideW, C.WALL_H, 4), CFrame = CFrame.new(sx * (EW / 2 + sideW / 2), C.WALL_H / 2, z), Color = wallColor, Material = M.SmoothPlastic})
		end
		part(front, {Name = "Lintel", Size = Vector3.new(EW, C.WALL_H - EH, 4), CFrame = CFrame.new(0, EH + (C.WALL_H - EH) / 2, z), Color = wallColor, Material = M.SmoothPlastic})
		-- Pixel squares sprinkled over the wall
		for i = 1, 60 do
			local sx = (i % 2 == 0) and 1 or -1
			-- only on the wall beyond the towers, never hidden inside them
			local x = sx * (EW / 2 + 21 + rng:NextNumber(0, math.max(0, sideW - 24)))
			part(front, {Name = "Pixel", Size = Vector3.new(3, 3, 0.4), CFrame = CFrame.new(x, rng:NextNumber(4, C.WALL_H - 4), z - 2.2), Color = PALETTE[rng:NextInteger(1, #PALETTE)], CanCollide = false})
		end

		-- Two giant game-console towers
		for _, sx in ipairs({-1, 1}) do
			local tx = sx * (EW / 2 + 10)
			local towerColor = sx < 0 and rgb(255, 85, 95) or rgb(70, 160, 255)
			local towerH = C.WALL_H + 22
			-- the tower stands just in front of the wall (it used to sink into it and flicker)
			part(front, {Name = "Tower", Size = Vector3.new(19.6, towerH, 14), CFrame = CFrame.new(tx + sx * 0.2, towerH / 2, z - 9.2), Color = towerColor, Material = M.SmoothPlastic})
			part(front, {Name = "TowerTop", Size = Vector3.new(21.6, 3, 16), CFrame = CFrame.new(tx + sx * 0.2, towerH + 1.5, z - 9.2), Color = WHITE})
			local fz = z - 16.6
			-- A/B/X/Y buttons
			for _, btn in ipairs({{0, 22, rgb(255, 230, 60)}, {4.5, 18, rgb(90, 220, 90)}, {-4.5, 18, rgb(70, 170, 255)}, {0, 14, rgb(255, 120, 200)}}) do
				part(front, {Name = "Button", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 4.6, 4.6), CFrame = CFrame.new(tx + btn[1], btn[2], fz) * CFrame.Angles(0, math.pi / 2, 0), Color = btn[3]})
			end
			-- D-pad
			part(front, {Name = "DPad", Size = Vector3.new(11, 3.6, 1), CFrame = CFrame.new(tx, 34, fz), Color = rgb(40, 40, 55)})
			part(front, {Name = "DPad", Size = Vector3.new(3.6, 11, 1), CFrame = CFrame.new(tx, 34, fz), Color = rgb(40, 40, 55)})
			-- Little screen
			local screen = part(front, {Name = "Screen", Size = Vector3.new(15, 9, 0.6), CFrame = CFrame.new(tx, 52, fz), Color = rgb(25, 25, 45)})
			Kit.surfaceText(screen, Enum.NormalId.Front, sx < 0 and "PLAY!" or "WIN!", rgb(120, 255, 140), 20)
			part(front, {Name = "ScreenFrame", Size = Vector3.new(17, 11, 0.4), CFrame = CFrame.new(tx, 52, fz + 0.3), Color = WHITE})
			-- Balloon bunch
			for bi = 1, 5 do
				local bx = tx + sx * 13 + rng:NextNumber(-3, 3)
				local by = 14 + bi * 2.2 + rng:NextNumber(0, 2)
				local bz = z - 14 + rng:NextNumber(-3, 3)
				part(front, {Name = "Balloon", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4.6, 4), CFrame = CFrame.new(bx, by, bz), Color = PALETTE[rng:NextInteger(1, #PALETTE)], CanCollide = false})
				part(front, {Name = "String", Size = Vector3.new(0.1, by - 2, 0.1), CFrame = CFrame.new(bx, (by - 2) / 2, bz), Color = WHITE, CanCollide = false})
			end
		end

		-- Rainbow arch around the doorway
		local bands = {rgb(255, 70, 70), rgb(255, 160, 40), rgb(255, 230, 60), rgb(90, 220, 90), rgb(70, 160, 255), rgb(150, 90, 255)}
		-- the rainbow sits on top of the doorway, between the towers (it used to cut into them)
		local cy = EH
		for bi, color in ipairs(bands) do
			local r = EW / 2 - 1.5 - (bi - 1) * 2.2
			local segs = 24
			for sgi = 0, segs - 1 do
				local ang = math.pi * (sgi + 0.5) / segs
				local pos = Vector3.new(math.cos(ang) * r, cy + math.sin(ang) * r, z - 3.4)
				part(front, {Name = "Rainbow", Size = Vector3.new(2.3, math.pi * r / segs * 1.15, 2), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, ang), Color = color, CanCollide = false})
			end
		end

		-- Marquee sign with light bulbs
		local signY = cy + 35 -- above the rainbow
		local signW, signH = EW - 14, 11
		local sign = part(front, {Name = "VaultSign", Size = Vector3.new(signW, signH, 1), CFrame = CFrame.new(0, signY, z - 4.6), Color = rgb(45, 30, 90)})
		local signText = Kit.surfaceText(sign, Enum.NormalId.Front, "THE GAME VAULT", Kit.GOLD, 20)
		signText.Size = UDim2.fromScale(0.84, 0.62)
		signText.Position = UDim2.fromScale(0.08, 0.19)
		part(front, {Name = "SignFrame", Size = Vector3.new(signW + 2, signH + 2, 0.6), CFrame = CFrame.new(0, signY, z - 4.2), Color = Kit.GOLD})
		local function bulb(x, y)
			part(front, {Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(x, y, z - 5.3), Color = rgb(255, 245, 190), Material = M.Neon, CanCollide = false})
		end
		for x = -signW / 2, signW / 2, 2.5 do
			bulb(x, signY + signH / 2 + 0.5)
			bulb(x, signY - signH / 2 - 0.5)
		end
		for y = -signH / 2 + 1.5, signH / 2 - 1.5, 2.5 do
			bulb(-signW / 2 - 0.5, signY + y)
			bulb(signW / 2 + 0.5, signY + y)
		end

		-- Giant controller on top of the gateway
		local cyTop = C.WALL_H + 9
		part(front, {Name = "ControllerBody", Size = Vector3.new(30, 11, 7), CFrame = CFrame.new(0, cyTop, z), Color = rgb(55, 55, 75)})
		for _, sx in ipairs({-1, 1}) do
			part(front, {Name = "ControllerGrip", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 14, 7), CFrame = CFrame.new(sx * 14, cyTop - 2, z), Color = rgb(55, 55, 75)})
		end
		part(front, {Name = "CDPad", Size = Vector3.new(6, 2, 1), CFrame = CFrame.new(-10, cyTop, z - 3.8), Color = rgb(20, 20, 30)})
		part(front, {Name = "CDPad", Size = Vector3.new(2, 6, 1), CFrame = CFrame.new(-10, cyTop, z - 3.8), Color = rgb(20, 20, 30)})
		for _, btn in ipairs({{10, 2, rgb(255, 230, 60)}, {12.5, 0, rgb(255, 80, 80)}, {7.5, 0, rgb(70, 170, 255)}, {10, -2, rgb(90, 220, 90)}}) do
			part(front, {Name = "CButton", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.2, 2.2), CFrame = CFrame.new(btn[1], cyTop + btn[2], z - 3.8) * CFrame.Angles(0, math.pi / 2, 0), Color = btn[3]})
		end

		-- Red carpet with gold rope posts
		part(front, {Name = "Carpet", Size = Vector3.new(EW - 8, 0.3, 60), CFrame = CFrame.new(0, 0.35, z - 32), Color = rgb(215, 35, 50), Material = M.Fabric, CanCollide = false})
		for _, sx in ipairs({-1, 1}) do
			local px = sx * (EW / 2 - 2)
			local last
			for pz = z - 4, z - 60, -8 do
				cyl(front, 4, 0.8, CFrame.new(px, 2, pz), {Name = "RopePost", Color = Kit.GOLD, Material = M.Metal})
				part(front, {Name = "PostTop", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(px, 4.3, pz), Color = Kit.GOLD, Material = M.Metal})
				if last then
					part(front, {Name = "Rope", Size = Vector3.new(0.35, 0.35, 8), CFrame = CFrame.new(px, 3.4, (pz + last) / 2), Color = rgb(200, 30, 50), Material = M.Fabric, CanCollide = false})
				end
				last = pz
			end
		end

		-- Flags along the main path
		local fi = 0
		for pz = z - 70, z - 200, -22 do
			for _, sx in ipairs({-1, 1}) do
				fi += 1
				local px = sx * 16
				cyl(front, 14, 0.5, CFrame.new(px, 7, pz), {Name = "FlagPole", Color = WHITE})
				Kit.wedge(front, {Name = "Flag", Size = Vector3.new(0.3, 4, 6), CFrame = CFrame.new(px - sx * 0.2, 12, pz - 3) * CFrame.Angles(0, 0, 0), Color = PALETTE[fi % #PALETTE + 1], CanCollide = false})
			end
		end
	end

	------------------------------------------------------------------
	-- TRAIL SHOP (beside the main path, near the vault entrance)
	------------------------------------------------------------------
	do
		local shop = Instance.new("Model")
		shop.Name = "TrailShop"
		shop.Parent = lobby
		-- Beside the vault entrance, facing the same way it does
		local pos = ENTRANCE + Vector3.new(-(C.ENTRANCE_W / 2 + 46), 0, -16)
		local cf = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
		local function at(x, y, z)
			return cf * CFrame.new(x, y, z)
		end
		part(shop, {Name = "Floor", Size = Vector3.new(26, 1, 18), CFrame = at(0, 0.5, 2), Color = rgb(70, 50, 90), Material = M.WoodPlanks})
		part(shop, {Name = "Counter", Size = Vector3.new(18, 4, 3), CFrame = at(0, 3, -4), Color = rgb(120, 70, 160), Material = M.WoodPlanks})
		part(shop, {Name = "CounterTop", Size = Vector3.new(18.6, 0.4, 3.6), CFrame = at(0, 5.2, -4), Color = rgb(255, 120, 230), Material = M.Neon})
		part(shop, {Name = "Back", Size = Vector3.new(26, 18, 1), CFrame = at(0, 10, 10.5), Color = rgb(60, 40, 80), Material = M.WoodPlanks})
		for _, sx in ipairs({-1, 1}) do
			part(shop, {Name = "Post", Size = Vector3.new(1.2, 18, 1.2), CFrame = at(sx * 12.4, 10, -6), Color = rgb(240, 240, 250), Material = M.Marble})
		end
		local stripes = {rgb(255, 80, 200), rgb(255, 255, 255)}
		for i = 0, 12 do
			part(shop, {Name = "Awning", Size = Vector3.new(2, 0.4, 19), CFrame = at(-12 + i * 2, 19.5, 1.5) * CFrame.Angles(math.rad(-12), 0, 0), Color = stripes[i % 2 + 1]})
		end
		local sign = part(shop, {Name = "Sign", Size = Vector3.new(22, 5, 0.6), CFrame = at(0, 23, -6.5), Color = rgb(30, 20, 40)})
		Kit.surfaceText(sign, Enum.NormalId.Front, "TRAIL SHOP", rgb(255, 150, 240), 30)
		part(shop, {Name = "SignFrame", Size = Vector3.new(23, 6, 0.4), CFrame = at(0, 23, -6.2), Color = rgb(255, 120, 230), Material = M.Neon})
		-- Glowing ribbons on the back wall (a hint of what's for sale)
		local ribbonColors = {rgb(90, 230, 255), rgb(255, 170, 60), rgb(160, 255, 80), rgb(190, 80, 255)}
		for i, c in ipairs(ribbonColors) do
			for j = 0, 5 do
				part(shop, {Name = "Ribbon", Size = Vector3.new(3.2, 0.6, 0.3), CFrame = at(-9 + i * 3.6 + math.sin(j) * 0.8, 8 + j * 1.4, 9.8) * CFrame.Angles(0, 0, math.sin(j * 1.3) * 0.5), Color = c, Material = M.Neon, CanCollide = false})
			end
		end
		local anchor = part(shop, {Name = "ShopAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, 6, -5), Transparency = 1, CanCollide = false})
		Kit.billboard(anchor, 300, 60, 22, '<font color="#ff96f0">TRAIL SHOP</font>\nCool trails for speed!', 200)

		-- The Trail Trader stands behind the counter
		local npc = makeCharacter(rgb(255, 120, 220), rgb(70, 50, 110), Kit.SKIN)
		if npc then
			npc.Name = "Trail Trader"
			npc.Parent = shop
			part(shop, {Name = "Step", Size = Vector3.new(8, 2.4, 5), CFrame = at(0, 2.2, 1.8), Color = rgb(90, 60, 120), Material = M.WoodPlanks})
			npc:PivotTo(at(0, 6.5, 1.8))
			local head = npc:FindFirstChild("Head")
			if head then
				local cap = part(npc, {Name = "Cap", Size = Vector3.new(1.3, 0.45, 1.3), CFrame = head.CFrame * CFrame.new(0, 0.6, 0), Color = rgb(90, 230, 255), CanCollide = false})
				local brim = part(npc, {Name = "CapBrim", Size = Vector3.new(1.2, 0.12, 0.8), CFrame = head.CFrame * CFrame.new(0, 0.45, -0.75), Color = rgb(90, 230, 255), CanCollide = false})
				Kit.billboard(head, 240, 50, 2.6, '<font color="#ff96f0">TRAIL TRADER</font>', 80)
				-- welded on so the cap moves with his head when he animates
				for _, p in ipairs({cap, brim}) do
					p.Anchored = false
					p.Massless = true
					local w = Instance.new("WeldConstraint")
					w.Part0 = head
					w.Part1 = p
					w.Parent = p
				end
				animateNpc(npc)
			end
			W.ShopPrompt = Kit.prompt(anchor, "Talk", "Trail Trader", 0, 14)
		else
			W.ShopPrompt = Kit.prompt(anchor, "Browse Trails", "Trail Shop", 0, 14)
		end

		-- A plain character the trail shop uses to picture each trail
		local dummy = makeCharacter(rgb(80, 150, 255), rgb(50, 60, 90), Kit.SKIN)
		local old = ReplicatedStorage:FindFirstChild("TrailDummy")
		if old then
			old:Destroy()
		end
		if dummy then
			dummy.Name = "TrailDummy"
			dummy:PivotTo(CFrame.new(0, 3, 0))
			dummy.Parent = ReplicatedStorage
		end
	end

	------------------------------------------------------------------
	-- LUCKY SPIN: a standalone prize wheel on a round stage (no hut)
	------------------------------------------------------------------
	do
		local spin = Instance.new("Model")
		spin.Name = "LuckySpin"
		spin.Parent = lobby
		local pos = ENTRANCE + Vector3.new(C.ENTRANCE_W / 2 + 46, 0, -16)
		local cf = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
		local function at(x, y, z)
			return cf * CFrame.new(x, y, z)
		end
		local WHITE = Color3.new(1, 1, 1)
		local FLAT = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder lying flat (round side up)
		local FACE = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder facing forward like a wheel
		-- Round two-step stage with a ring of bulbs
		part(spin, {Name = "Stage", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 30, 30), CFrame = at(0, 0.5, 0) * FLAT, Color = rgb(70, 45, 140)})
		part(spin, {Name = "StageTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 22, 22), CFrame = at(0, 1.5, 0) * FLAT, Color = rgb(120, 80, 230)})
		part(spin, {Name = "StageTrim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 30.4, 30.4), CFrame = at(0, 1.05, 0) * FLAT, Color = Kit.GOLD, Material = M.SmoothPlastic})
		for i = 0, 23 do
			local ang = i / 24 * math.pi * 2
			part(spin, {Name = "StageBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = at(math.cos(ang) * 14.2, 1.3, math.sin(ang) * 14.2), Color = i % 2 == 0 and WHITE or Kit.GOLD, Material = M.Neon, CanCollide = false})
		end
		-- White supports holding the wheel up, and two poles for the sign
		for _, sx in ipairs({-1, 1}) do
			part(spin, {Name = "Leg", Size = Vector3.new(1.6, 16, 1.6), CFrame = at(sx * 3.2, 9.5, 1.2) * CFrame.Angles(0, 0, sx * 0.32), Color = WHITE, Material = M.Marble})
			Kit.cylinder(spin, 27, 1, at(sx * 10.5, 15, 1.2), {Name = "SignPole", Color = WHITE, Material = M.Marble})
			part(spin, {Name = "PoleTop", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = at(sx * 10.5, 29.2, 1.2), Color = Kit.GOLD, Material = M.Neon, CanCollide = false})
		end
		-- The wheel (its own model; every player's game turns it, and spins it to their own prize).
		-- Each prize is a true pie slice: three thin triangles fanned from the centre. Neighbouring slices share their
		-- edges exactly and lie on one plane in front of the face, so no two colours ever overlap or flicker.
		spin.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- clients keep hold of these parts to turn them
		local wheel = Instance.new("Model")
		wheel.Name = "SpinWheel"
		wheel.Parent = spin
		local hub = at(0, 15, 0)
		local n = #C.SPIN_REWARDS
		local step = math.pi * 2 / n
		wheel:SetAttribute("Axis", hub.Position)
		wheel:SetAttribute("Facing", hub.LookVector)
		wheel:SetAttribute("Slices", n)
		part(wheel, {Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 22, 22), CFrame = hub * FACE, Color = Kit.GOLD, Material = M.Metal})
		part(wheel, {Name = "Face", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 20.6, 20.6), CFrame = hub * CFrame.new(0, 0, -0.05) * FACE, Color = rgb(34, 22, 66)})
		-- a point on the wheel: r studs out at angle a (clockwise from the top), z in front of the face
		local function onWheel(r, a, z)
			return (hub * CFrame.Angles(0, 0, -a) * CFrame.new(0, r, z)).Position
		end
		-- a flat triangle from two wedges (the usual right-angle split)
		local function triangle(parent, a, b, c, props)
			local ab, ac, bc = b - a, c - a, c - b
			local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
			if abd > acd and abd > bcd then
				c, a = a, c
			elseif acd > bcd and acd > abd then
				a, b = b, a
			end
			ab, ac, bc = b - a, c - a, c - b
			local right = ac:Cross(ab).Unit
			local up = bc:Cross(right).Unit
			local back = bc.Unit
			local height = math.abs(ab:Dot(up))
			local w1 = Kit.wedge(parent, props)
			w1.Size = Vector3.new(0.2, height, math.abs(ab:Dot(back)))
			w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
			local w2 = Kit.wedge(parent, props)
			w2.Size = Vector3.new(0.2, height, math.abs(ac:Dot(back)))
			w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
		end
		local R, Z = 9.9, -1.0
		for i, reward in ipairs(C.SPIN_REWARDS) do
			local mid = (i - 1) * step
			local props = {Name = "Slice", Color = reward.Color, Material = M.SmoothPlastic, CanCollide = false, CastShadow = false}
			for k = 0, 2 do
				local a0 = mid - step / 2 + k * step / 3
				triangle(wheel, onWheel(0, 0, Z), onWheel(R, a0, Z), onWheel(R, a0 + step / 3, Z), props)
			end
			for _, w in ipairs(wheel:GetChildren()) do
				if w.Name == "Slice" and not w:GetAttribute("Slice") then
					w:SetAttribute("Slice", i)
				end
			end
			-- the prize's icon and name, reading outwards along the slice
			local tag = part(wheel, {Name = "SliceLabel", Size = Vector3.new(3.4, 5.4, 0.05), CFrame = hub * CFrame.Angles(0, 0, -mid) * CFrame.new(0, 6.5, Z - 0.14), Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false})
			tag:SetAttribute("Slice", i)
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 40
			sg.LightInfluence = 0
			sg.MaxDistance = 220
			sg.Parent = tag
			local icon = Instance.new("TextLabel")
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.fromScale(1, 0.5)
			icon.Position = UDim2.fromScale(0, 0.02)
			icon.TextScaled = true
			icon.Text = reward.Icon
			icon.Parent = sg
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Size = UDim2.fromScale(0.9, 0.3)
			name.Position = UDim2.fromScale(0.05, 0.54)
			name.Font = Enum.Font.FredokaOne
			name.TextScaled = true
			name.TextWrapped = true
			name.TextColor3 = WHITE
			name.Text = string.upper(reward.Text)
			name.Parent = sg
			local ink = Instance.new("UIStroke")
			ink.Color = reward.Color:Lerp(Color3.new(), 0.65)
			ink.Thickness = 3
			ink.Parent = name
			-- gold divider on the edge between this slice and the next, with a peg the pointer clicks over
			local edge = mid + step / 2
			part(wheel, {Name = "Spoke", Size = Vector3.new(0.24, R - 1.6, 0.12), CFrame = hub * CFrame.Angles(0, 0, -edge) * CFrame.new(0, 1.6 + (R - 1.6) / 2, Z - 0.16), Color = Kit.GOLD, Material = M.Metal, CanCollide = false, CastShadow = false})
			part(wheel, {Name = "RimBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.85, 0.85, 0.85), CFrame = hub * CFrame.Angles(0, 0, -edge) * CFrame.new(0, 10.65, -0.8), Color = WHITE, Material = M.Neon, CanCollide = false})
			part(wheel, {Name = "RimBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = hub * CFrame.Angles(0, 0, -mid) * CFrame.new(0, 10.65, -0.8), Color = rgb(255, 225, 120), Material = M.Neon, CanCollide = false})
		end
		local hubCap = part(wheel, {Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3.6, 3.6), CFrame = hub * CFrame.new(0, 0, Z - 0.3) * FACE, Color = Kit.GOLD, Material = M.Metal, CanCollide = false})
		part(wheel, {Name = "HubDot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.6, 1.6), CFrame = hub * CFrame.new(0, 0, Z - 0.6) * FACE, Color = rgb(255, 245, 200), Material = M.Neon, CanCollide = false})
		local glow = Instance.new("PointLight")
		glow.Color = rgb(255, 230, 150)
		glow.Range = 20
		glow.Brightness = 1.2
		glow.Parent = hubCap
		-- Red pointer at the top (does not spin; each player's game flicks it as the pegs pass)
		Kit.wedge(spin, {Name = "Pointer", Size = Vector3.new(0.8, 2.6, 2.4), CFrame = hub * CFrame.new(0, 12, -1.3) * CFrame.Angles(math.pi / 2, 0, 0), Color = rgb(230, 40, 50)})
		-- SPIN board on the front of the stage: like the Top 10 board, it's always there and each player's game draws
		-- it (the SPIN button, the free-spin countdown, extra spins and buying one)
		part(spin, {Name = "SpinBoardStand", Size = Vector3.new(9.6, 2.6, 1.6), CFrame = at(0, 3.3, -9.2), Color = rgb(70, 45, 140)})
		part(spin, {Name = "SpinBoard", Size = Vector3.new(10.4, 4, 0.5), CFrame = at(0, 4.9, -9.4) * CFrame.Angles(math.rad(32), 0, 0), Color = rgb(30, 20, 60)})
		-- Sign across the top
		local sign = part(spin, {Name = "Sign", Size = Vector3.new(22, 4.4, 0.8), CFrame = at(0, 29.2, 1.2), Color = rgb(40, 25, 90)})
		local st = Kit.surfaceText(sign, Enum.NormalId.Front, "LUCKY SPIN", Kit.GOLD, 30)
		st.TextStrokeTransparency = 1
		part(spin, {Name = "SignFrame", Size = Vector3.new(23, 5.4, 0.5), CFrame = at(0, 29.2, 1.6), Color = Kit.GOLD})
		for x = -10.5, 10.5, 1.75 do
			for _, y in ipairs({31.9, 26.5}) do
				part(spin, {Name = "SignBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = at(x, y, 0.8), Color = rgb(255, 245, 190), Material = M.Neon, CanCollide = false})
			end
		end
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(rgb(255, 240, 160))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new(0.6, 0)
		sparkle.Lifetime = NumberRange.new(1, 1.6)
		sparkle.Rate = 8
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = hubCap
		-- Walk up to the front of the stage to spin
		local anchor = part(spin, {Name = "SpinAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, 4, -12), Transparency = 1, CanCollide = false})
		W.SpinPrompt = Kit.prompt(anchor, "Spin!", "Lucky Spin", 0, 16)
	end

	------------------------------------------------------------------
	-- TOP 10 LEADERBOARD board (players' games draw the board and its Money/Speed tabs)
	------------------------------------------------------------------
	do
		local lb = Instance.new("Model")
		lb.Name = "Leaderboard"
		lb.Parent = lobby
		local pos = ENTRANCE + Vector3.new(-34, 0, -75)
		local cf = CFrame.lookAt(pos, pos + Vector3.new(0.7, 0, -0.7))
		local function at(x, y, z)
			return cf * CFrame.new(x, y, z)
		end
		for _, sx in ipairs({-1, 1}) do
			part(lb, {Name = "Post", Size = Vector3.new(1.6, 26, 1.6), CFrame = at(sx * 12.6, 13, 0.8), Color = rgb(250, 250, 255), Material = M.Marble})
			part(lb, {Name = "PostTop", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(sx * 12.6, 26.6, 0.8), Color = Kit.GOLD, Material = M.Neon, CanCollide = false})
		end
		part(lb, {Name = "Frame", Size = Vector3.new(25, 21, 0.6), CFrame = at(0, 14.5, 0.5), Color = Kit.GOLD, Material = M.SmoothPlastic})
		local screen = part(lb, {Name = "LeaderboardScreen", Size = Vector3.new(23.6, 19.6, 0.4), CFrame = at(0, 14.5, 0), Color = rgb(30, 22, 60)})
		screen:SetAttribute("Leaderboard", true)
		part(lb, {Name = "Base", Size = Vector3.new(28, 1, 5), CFrame = at(0, 0.5, 0.8), Color = rgb(70, 45, 140)})
		W.LeaderboardScreen = screen
		W.Center = ENTRANCE -- the island's centre (the fence ring is measured from here)
	end

	------------------------------------------------------------------
	-- INVITE A FRIEND: a character on a glowing pad by the main path.
	-- Walking onto the pad opens Roblox's invite list (handled by the client).
	------------------------------------------------------------------
	do
		local inviteModel = Instance.new("Model")
		inviteModel.Name = "InviteFriend"
		inviteModel.Parent = lobby
		local pos = ENTRANCE + Vector3.new(30, 0, -75)
		local faceCF = CFrame.lookAt(pos, Vector3.new(0, 0, pos.Z))
		local pad = part(inviteModel, {Name = "InvitePad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 14, 14), CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = Kit.GOLD, Material = M.Neon, Transparency = 0.15, CanCollide = false})
		pad:SetAttribute("InvitePad", true)
		part(inviteModel, {Name = "InviteRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 16, 16), CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 255, 255), Material = M.SmoothPlastic})
		local touch = part(inviteModel, {Name = "InviteTouch", Size = Vector3.new(12, 6, 12), CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)), Transparency = 1, CanCollide = false})
		touch:SetAttribute("InviteTouch", true)
		local glow = Instance.new("PointLight")
		glow.Color = Kit.GOLD
		glow.Range = 16
		glow.Brightness = 1.5
		glow.Parent = pad
		local rays = Instance.new("ParticleEmitter")
		rays.Color = ColorSequence.new(Kit.GOLD)
		rays.LightEmission = 1
		rays.Size = NumberSequence.new(0.6, 0)
		rays.Lifetime = NumberRange.new(1, 1.6)
		rays.Rate = 25
		rays.Speed = NumberRange.new(3, 6)
		rays.EmissionDirection = Enum.NormalId.Right
		rays.SpreadAngle = Vector2.new(15, 15)
		rays.Parent = pad

		-- A big character stands on the pad. Each player's game swaps it for one of their own friends.
		local npc = makeCharacter(rgb(60, 200, 90), rgb(40, 60, 110), Kit.SKIN)
		local standH = 6
		if npc then
			npc.Name = "Inviter"
			npc:ScaleTo(C.INVITE_SCALE)
			-- stand the feet on the pad
			npc:PivotTo(faceCF)
			local box, size = npc:GetBoundingBox()
			npc:PivotTo(npc:GetPivot() + Vector3.new(0, pos.Y + 0.6 - (box.Position.Y - size.Y / 2), 0))
			standH = size.Y
			npc.Parent = inviteModel
			animateNpc(npc, 6)
		end
		-- The label floats on its own part, so swapping the character keeps it
		local labelPart = part(inviteModel, {Name = "InviteLabel", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, standH + 1.5, 0)), Transparency = 1, CanCollide = false, CanQuery = false})
		Kit.billboard(labelPart, 520, 130, 2.5, '<font color="#ffd23c">\u{1F465} INVITE FRIEND \u{1F465}</font>\n<font color="#78ff5a">1st Friend +10% Cash</font>', 160)
		-- the extra-friend bonus, smaller, under the main line
		local board = labelPart:FindFirstChildWhichIsA("BillboardGui")
		local main = board and board:FindFirstChildWhichIsA("TextLabel")
		if main then
			main.Size = UDim2.fromScale(1, 0.74)
			local sub = main:Clone()
			sub.Name = "Sub"
			sub.Text = "+2.5% each additional friend"
			sub.TextColor3 = Color3.fromRGB(200, 255, 190)
			sub.Position = UDim2.fromScale(0.15, 0.76)
			sub.Size = UDim2.fromScale(0.7, 0.22)
			sub.Parent = board
		end
		-- Cash bills that orbit the character (spun by each player's game)
		local orbit = Instance.new("Model")
		orbit.Name = "InviteCash"
		orbit.Parent = inviteModel
		for i = 1, 8 do
			local ang = i * math.pi / 4
			local bill = part(orbit, {Name = "Bill", Size = Vector3.new(1.8, 0.15, 0.9), CFrame = CFrame.new(pos + Vector3.new(math.cos(ang) * 6, 2.5 + (i % 3) * 2, math.sin(ang) * 6)) * CFrame.Angles(0.4, ang, 0.3), Color = rgb(80, 200, 90), CanCollide = false})
			part(orbit, {Name = "Band", Size = Vector3.new(0.35, 0.18, 0.95), CFrame = bill.CFrame, Color = rgb(255, 215, 60), CanCollide = false})
		end
		orbit:SetAttribute("Center", pos)
	end

	------------------------------------------------------------------
	-- AREA PREVIEWS (copies of each area's first level, shown in the Index)
	------------------------------------------------------------------
	do
		local previews = ReplicatedStorage:FindFirstChild("AreaPreviews")
		if previews then
			previews:Destroy()
		end
		previews = Instance.new("Folder")
		previews.Name = "AreaPreviews"
		for _, L in ipairs(C.LEVELS) do
			if L.Sub == 1 then
				local copy = W.SegModels[L.Index]:Clone()
				-- Keep it light: drop small details (shelf boxes, props) and anything that isn't a part
				for _, d in ipairs(copy:GetDescendants()) do
					if d:IsA("BasePart") then
						if d.Size.Magnitude < 6 then
							d:Destroy()
						end
					elseif not d:IsA("Model") and not d:IsA("SurfaceGui") and not d:IsA("TextLabel") then
						d:Destroy()
					end
				end
				copy.Name = tostring(L.ZoneIndex)
				copy:SetAttribute("Z0", segStart(L.Index))
				copy:SetAttribute("SegLen", C.SEG_LEN)
				copy.Parent = previews
			end
		end
		previews.Parent = ReplicatedStorage
	end

	------------------------------------------------------------------
	-- WHERE THE BASES GO
	------------------------------------------------------------------
	for i = 1, C.NUM_PLOTS do
		local angle = math.rad(-C.BASE_ARC / 2 + (i - 1) * C.BASE_ARC / (C.NUM_PLOTS - 1))
		local pos = ENTRANCE + Vector3.new(math.sin(angle), 0, -math.cos(angle)) * C.BASE_RING_RADIUS
		W.PlotCFrames[i] = CFrame.lookAt(pos, Vector3.new(ENTRANCE.X, 0, ENTRANCE.Z))
	end

	return W
end

return World

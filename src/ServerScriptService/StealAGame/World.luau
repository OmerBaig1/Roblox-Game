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
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	return model
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
	local PATH = rgb(200, 192, 176)
	local LOOP_R = C.BASE_RING_RADIUS - C.PLOT_D / 2 - 26
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
		part(lobby, {Name = "InvisibleWall", Size = Vector3.new(len + 1, WALL_HEIGHT, 2), CFrame = cf * CFrame.new(0, WALL_HEIGHT / 2, 0), Transparency = 1, CanQuery = false, CastShadow = false})
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
		end
	end

	local FLOOR_COLORS = {
		[M.Mud] = rgb(200, 150, 100), [M.Brick] = rgb(235, 120, 110), [M.LeafyGrass] = rgb(110, 210, 90),
		[M.Sand] = rgb(250, 225, 160), [M.Slate] = rgb(160, 150, 200), [M.Concrete] = rgb(170, 230, 235),
		[M.WoodPlanks] = rgb(225, 170, 110), [M.Pavement] = rgb(200, 210, 225), [M.CrackedLava] = rgb(240, 130, 90),
		[M.Basalt] = rgb(140, 140, 220),
	}

	local function buildShelf(parent, side, z, colors)
		local wallX = side * (C.ROOM_W / 2 - 0.3)
		local shelfX = side * (C.ROOM_W / 2 - 2.4)
		local wood, lightWood = rgb(70, 50, 35), rgb(115, 85, 55)
		part(parent, {Size = Vector3.new(0.6, 14, 18), CFrame = CFrame.new(wallX, 7, z), Color = wood, Material = M.Wood})
		for _, dz in ipairs({-9, 9}) do
			part(parent, {Size = Vector3.new(4, 14, 0.4), CFrame = CFrame.new(shelfX, 7, z + dz), Color = wood, Material = M.Wood})
		end
		for row = 0, 3 do
			local y = 1.5 + row * 3.4
			part(parent, {Size = Vector3.new(3.8, 0.3, 18), CFrame = CFrame.new(shelfX, y, z), Color = lightWood, Material = M.WoodPlanks})
			for b = 0, 4 do
				part(parent, {Size = Vector3.new(1.6, 2.4, 1.2), CFrame = CFrame.new(shelfX, y + 1.35, z - 6.4 + b * 3.2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color = colors[rng:NextInteger(1, #colors)]})
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
		-- A big colourful archway marks each new level
		local archH = zoneStart and 52 or 44
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
		local timerPart = part(decor, {Name = "RestockTimer", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 16, PED_Z), Transparency = 1, CanCollide = false})
		W.RestockLabels[level] = Kit.billboard(timerPart, 300, 56, 0, "IN STOCK", 140)

		-- Recommended speed for this level (shoe symbol + number), standing near the entrance of the level
		do
			local recommended = C.guardPoints(level) * 1.1
			local sx = HALF - 14
			part(decor, {Name = "SpeedSignPost", Size = Vector3.new(1, 9, 1), CFrame = CFrame.new(sx, 4.5, z0 + 16), Color = Color3.new(1, 1, 1)})
			local board = part(decor, {Name = "SpeedSign", Size = Vector3.new(14, 6, 0.6), CFrame = CFrame.new(sx, 10, z0 + 16), Color = Color3.new(1, 1, 1)})
			part(decor, {Name = "SpeedSignFrame", Size = Vector3.new(15, 7, 0.4), CFrame = CFrame.new(sx, 10, z0 + 16.3), Color = accent})
			local t = Kit.surfaceText(board, Enum.NormalId.Front, "\u{1F45F} " .. Kit.fmt(recommended), rgb(40, 40, 60), 24)
			t.TextStrokeTransparency = 1
		end

		Kit.setGroup(decor, "Decor")
	end
	local lastL = C.LEVELS[C.NUM_LEVELS]
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
			local x = sx * (EW / 2 + 2 + rng:NextNumber(0, sideW - 4))
			part(front, {Name = "Pixel", Size = Vector3.new(3, 3, 0.4), CFrame = CFrame.new(x, rng:NextNumber(4, C.WALL_H - 4), z - 2.2), Color = PALETTE[rng:NextInteger(1, #PALETTE)], CanCollide = false})
		end

		-- Two giant game-console towers
		for _, sx in ipairs({-1, 1}) do
			local tx = sx * (EW / 2 + 10)
			local towerColor = sx < 0 and rgb(255, 85, 95) or rgb(70, 160, 255)
			local towerH = C.WALL_H + 22
			part(front, {Name = "Tower", Size = Vector3.new(20, towerH, 16), CFrame = CFrame.new(tx, towerH / 2, z - 8), Color = towerColor, Material = M.SmoothPlastic})
			part(front, {Name = "TowerTop", Size = Vector3.new(22, 3, 18), CFrame = CFrame.new(tx, towerH + 1.5, z - 8), Color = WHITE})
			local fz = z - 16.4
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
		local cy = EH - 4
		for bi, color in ipairs(bands) do
			local r = EW / 2 + 1 + (bi - 1) * 2.2
			local segs = 24
			for sgi = 0, segs - 1 do
				local ang = math.pi * (sgi + 0.5) / segs
				local pos = Vector3.new(math.cos(ang) * r, cy + math.sin(ang) * r, z - 3.4)
				part(front, {Name = "Rainbow", Size = Vector3.new(2.3, math.pi * r / segs * 1.15, 2), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, ang), Color = color, CanCollide = false})
			end
		end

		-- Marquee sign with light bulbs
		local signY = cy + 18
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
				part(npc, {Name = "CapBrim", Size = Vector3.new(1.2, 0.12, 0.8), CFrame = head.CFrame * CFrame.new(0, 0.45, -0.75), Color = rgb(90, 230, 255), CanCollide = false})
				Kit.billboard(head, 240, 50, 2.6, '<font color="#ff96f0">TRAIL TRADER</font>', 80)
				cap.Anchored = true
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
	-- LUCKY SPIN booth (mirrors the Trail Shop on the other side of the entrance)
	------------------------------------------------------------------
	do
		local booth = Instance.new("Model")
		booth.Name = "LuckySpin"
		booth.Parent = lobby
		local pos = ENTRANCE + Vector3.new(C.ENTRANCE_W / 2 + 46, 0, -16)
		local cf = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
		local function at(x, y, z)
			return cf * CFrame.new(x, y, z)
		end
		local WHITE = Color3.new(1, 1, 1)
		part(booth, {Name = "Floor", Size = Vector3.new(26, 1, 18), CFrame = at(0, 0.5, 2), Color = rgb(40, 110, 200), Material = M.WoodPlanks})
		part(booth, {Name = "Counter", Size = Vector3.new(18, 4, 3), CFrame = at(0, 3, -4), Color = rgb(60, 150, 255), Material = M.WoodPlanks})
		part(booth, {Name = "CounterTop", Size = Vector3.new(18.6, 0.4, 3.6), CFrame = at(0, 5.2, -4), Color = rgb(255, 230, 60)})
		part(booth, {Name = "Back", Size = Vector3.new(26, 22, 1), CFrame = at(0, 12, 10.5), Color = rgb(40, 90, 180), Material = M.WoodPlanks})
		for _, sx in ipairs({-1, 1}) do
			part(booth, {Name = "Post", Size = Vector3.new(1.2, 20, 1.2), CFrame = at(sx * 12.4, 10, -6), Color = WHITE, Material = M.Marble})
		end
		local stripes = {rgb(255, 230, 60), WHITE}
		for i = 0, 12 do
			part(booth, {Name = "Awning", Size = Vector3.new(2, 0.4, 19), CFrame = at(-12 + i * 2, 21.5, 1.5) * CFrame.Angles(math.rad(-12), 0, 0), Color = stripes[i % 2 + 1]})
		end
		local sign = part(booth, {Name = "Sign", Size = Vector3.new(22, 5, 0.6), CFrame = at(0, 25, -6.5), Color = rgb(25, 40, 90)})
		Kit.surfaceText(sign, Enum.NormalId.Front, "LUCKY SPIN", rgb(255, 230, 60), 30)
		part(booth, {Name = "SignFrame", Size = Vector3.new(23, 6, 0.4), CFrame = at(0, 25, -6.2), Color = rgb(255, 230, 60)})

		-- The big prize wheel on the back wall
		local wheelCF = at(0, 12.5, 9.6)
		local colors = {rgb(255, 80, 80), rgb(255, 170, 40), rgb(255, 230, 60), rgb(90, 220, 90), rgb(70, 170, 255), rgb(150, 90, 255), rgb(255, 120, 200), rgb(40, 210, 200)}
		part(booth, {Name = "WheelRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 17, 17), CFrame = wheelCF * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(255, 230, 60)})
		part(booth, {Name = "WheelFace", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 15.4, 15.4), CFrame = wheelCF * CFrame.new(0, 0, -0.1) * CFrame.Angles(0, math.pi / 2, 0), Color = WHITE})
		for i = 0, 7 do
			local ang = i * math.pi / 4
			part(booth, {Name = "Slice", Size = Vector3.new(2.8, 7.2, 0.3), CFrame = wheelCF * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, 0, ang) * CFrame.new(0, 3.8, 0), Color = colors[i + 1], CanCollide = false})
			part(booth, {Name = "Peg", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = wheelCF * CFrame.new(0, 0, -0.7) * CFrame.Angles(0, 0, ang + math.pi / 8) * CFrame.new(0, 7.6, 0), Color = WHITE, CanCollide = false})
		end
		part(booth, {Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 3, 3), CFrame = wheelCF * CFrame.new(0, 0, -0.8) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(255, 230, 60)})
		Kit.wedge(booth, {Name = "Pointer", Size = Vector3.new(0.6, 2.4, 2), CFrame = wheelCF * CFrame.new(0, 9.4, -0.8) * CFrame.Angles(math.pi / 2, 0, 0), Color = rgb(230, 40, 50)})

		local anchor = part(booth, {Name = "SpinAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, 6, -5), Transparency = 1, CanCollide = false})
		W.SpinPrompt = Kit.prompt(anchor, "Spin the Wheel", "Lucky Spin", 0, 14)
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

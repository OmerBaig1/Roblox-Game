--[[
	Environment: how the lobby's ground and the trees round it look. Nothing here changes where anything is or how it plays:
	the paving is decoration on the flat, solid walkways World builds (so a fast runner has no block edges to clip), the grass is
	terrain with the same flat top as before, and the trees stand where the old ones did, out of reach behind the fence.
]]
local ServerStorage = game:GetService("ServerStorage")
local Environment = {}
local rgb = Color3.fromRGB
local M = Enum.Material

local assets = ServerStorage:WaitForChild("EnvironmentAssets")

------------------------------------------------------------------
-- TREES: copies of a few detailed meshes (copies of one mesh draw cheaply), mostly green with the odd blossom for colour
------------------------------------------------------------------
local TREES = {{"TreeLush", 40}, {"TreePine", 30}, {"TreeBirch", 20}, {"TreeBlossom", 10}}
local TREE_TOTAL = 100
function Environment.tree(parent, pos, rng, frontRow)
	local roll, name = rng:NextNumber(0, TREE_TOTAL), TREES[1][1]
	for _, t in ipairs(TREES) do
		roll -= t[2]
		if roll <= 0 then
			name = t[1]
			break
		end
	end
	local tree = assets[name]:Clone()
	tree.Size = tree.Size * (rng:NextNumber(115, 175) / tree.Size.Y)
	tree.CFrame = CFrame.new(pos + Vector3.new(0, tree.Size.Y / 2 - 1, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	tree.CastShadow = frontRow -- the rows behind are mostly hidden by the first
	tree.Parent = parent
	return tree
end

------------------------------------------------------------------
-- PAVING: running-bond blocks with a slate border, grout showing between them
------------------------------------------------------------------
local WARM = {rgb(224, 212, 184), rgb(208, 192, 160), rgb(192, 172, 142), rgb(216, 184, 154)}
local SLATE = {rgb(112, 120, 138), rgb(98, 106, 124), rgb(128, 134, 150)}
local GOLD = {rgb(224, 190, 110), rgb(208, 172, 96)}
local GAP = 0.22
local TOP = 0.32 -- every block's top, whatever it sits on

function Environment.paving(parent, C, entrance, inHall, rng)
	local folder = Instance.new("Folder")
	folder.Name = "Paving"
	folder.Parent = parent
	local function block(x, z, sideways, deep, yaw, palette, material)
		local p = Instance.new("Part")
		p.Name = "PaveBlock"
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size = Vector3.new(sideways, 0.2, deep)
		p.CFrame = CFrame.new(x, TOP - 0.1, z) * yaw
		p.Color = palette[rng:NextInteger(1, #palette)]
		p.Material = material
		p.Parent = folder
	end
	-- a ring of blocks round a centre: from angle a0 to a1, skipping anything skip() refuses
	local function ring(center, r, width, length, a0, a1, palette, material, phase, skip)
		local count = math.max(1, math.floor(r * (a1 - a0) / length + 0.5))
		local step = (a1 - a0) / count
		for i = 0, count - 1 do
			local a = a0 + (i + phase) * step
			local pos = center + Vector3.new(math.sin(a), 0, -math.cos(a)) * r
			if not skip(pos) then
				local yaw = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)).Rotation
				block(pos.X, pos.Z, r * step - GAP, width - GAP, yaw, palette, material)
			end
		end
	end
	-- the loop in front of the bases: four rows, the outer two slate
	local TAU = math.pi * 2
	for k, off in ipairs({-5.25, -1.75, 1.75, 5.25}) do
		local edge = k == 1 or k == 4
		ring(entrance, C.LOOP_R + off, 3.5, 5.5, 0, TAU, edge and SLATE or WARM, edge and M.Slate or M.Concrete, k % 2 * 0.5, function(pos)
			return inHall(pos, 4)
		end)
	end
	-- straight paths: rows of blocks along the path, bonded like brickwork, the outer rows slate
	local function strip(angle, r1, r2, width, cols, length)
		local dir = Vector3.new(math.sin(angle), 0, -math.cos(angle))
		local across = Vector3.new(dir.Z, 0, -dir.X)
		local lane = width / cols
		local yaw = CFrame.lookAt(Vector3.zero, across).Rotation
		for c = 1, cols do
			local edge = c == 1 or c == cols
			local x = (c - (cols + 1) / 2) * lane
			local r = r1
			local first = c % 2 == 0 and length / 2 or length
			while r < r2 - 0.5 do
				local l = math.min(r == r1 and first or length, r2 - r)
				local pos = entrance + dir * (r + l / 2) + across * x
				block(pos.X, pos.Z, l - GAP, lane - GAP, CFrame.lookAt(Vector3.zero, dir).Rotation * CFrame.Angles(0, math.pi / 2, 0), edge and SLATE or WARM, edge and M.Slate or M.Concrete)
				r += l
			end
		end
	end
	strip(0, 81, C.LOOP_R - 7, 30, 7, 5.5)
	for i = 1, C.NUM_PLOTS do
		strip(math.rad(-C.BASE_ARC / 2 + (i - 1) * C.BASE_ARC / (C.NUM_PLOTS - 1)), C.LOOP_R + 7, C.BASE_RING_RADIUS - C.PLOT_D / 2, 12, 3, 5.5)
	end
	-- the plaza's fan of rings round the vault door. The carpet covers its middle, so nothing's laid under that.
	local center = entrance + Vector3.new(0, 0, -10)
	local carpetBack = center.Z - 70
	for k = 1, 11 do
		local r = (k - 0.5) * 6.1
		local gold = k % 4 == 0
		ring(center, r, 6.1, 6.5, -math.pi / 2, math.pi / 2, gold and GOLD or WARM, M.Concrete, k % 2 * 0.5, function(pos)
			return math.abs(pos.X) < 37 and pos.Z > carpetBack
		end)
	end
end

------------------------------------------------------------------
-- VAULT FLOORS: each area's floor is laid in a pattern that suits its material, in its own colours, on both sides of the running
-- lane (the runner covers the middle, and the walls' border the edges). Decoration only: the flat floor under it is what's walked on.
------------------------------------------------------------------
local MID_X = 15 -- from the runner's edge...
local EDGE_GAP = 6.5 -- ...to the wall's border
local FLOOR_TOP = 0.26
local WOOD = {[M.Wood] = true, [M.WoodPlanks] = true}
local METAL = {[M.Metal] = true, [M.DiamondPlate] = true, [M.CorrodedMetal] = true, [M.Neon] = true, [M.Foil] = true, [M.Glass] = true}
local STONE = {[M.Cobblestone] = true, [M.Brick] = true, [M.Slate] = true, [M.Rock] = true, [M.Basalt] = true, [M.Sandstone] = true, [M.Limestone] = true}
local POLISHED = {[M.Marble] = true, [M.Granite] = true, [M.SmoothPlastic] = true, [M.Ice] = true, [M.Pebble] = true}

local function floorPattern(material, zone)
	if WOOD[material] then
		return "planks"
	elseif METAL[material] then
		return "chevrons"
	elseif STONE[material] then
		return "bricks"
	elseif POLISHED[material] then
		return "diamonds"
	end
	return ({"weave", "checker", "bricks", "diamonds", "chevrons"})[zone % 5 + 1]
end
Environment.floorPattern = floorPattern

function Environment.vaultFloor(parent, z0, len, half, T, zone)
	local base = T.FloorColor
	local light, dark = base:Lerp(Color3.new(1, 1, 1), 0.16), base:Lerp(Color3.new(0, 0, 0), 0.2)
	local trim = base:Lerp(T.Trim, 0.42)
	local fieldW = half - EDGE_GAP - MID_X
	local function tile(side, x, z, sx, sz, angle, color, material)
		local p = Instance.new("Part")
		p.Name = "FloorTile"
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size = Vector3.new(sx, 0.08, sz)
		p.CFrame = CFrame.new(side * (MID_X + x), FLOOR_TOP - 0.04, z0 + z) * CFrame.Angles(0, side * angle, 0)
		p.Color = color
		p.Material = material or T.Floor
		p.Parent = parent
	end
	local style = floorPattern(T.Floor, zone)
	for _, side in ipairs({-1, 1}) do
		if style == "planks" then
			-- long boards laid across, every other row offset
			local rows = math.floor(len / 9)
			for r = 0, rows - 1 do
				local z = (r + 0.5) * len / rows
				local offset = r % 2 == 0 and 0 or fieldW / 3
				local x = -offset
				for k = 1, 4 do
					local a, b = math.max(x, 0), math.min(x + fieldW / 1.5, fieldW)
					if b - a > 1 then
						tile(side, (a + b) / 2, z, b - a - 0.25, len / rows - 0.25, 0, (r + k) % 3 == 0 and dark or (r + k) % 3 == 1 and light or base)
					end
					x += fieldW / 1.5
				end
			end
		elseif style == "chevrons" then
			-- V-shaped bars running along the hall, with a lit bar every few
			local step = 11
			for i = 0, math.floor(len / step) - 1 do
				local color = i % 4 == 3 and trim or (i % 2 == 0 and light or dark)
				local mat = i % 4 == 3 and M.SmoothPlastic or nil
				local z = (i + 0.5) * step
				local w = fieldW / 2
				tile(side, w * 0.5, z, w * 1.12, 6.2, math.rad(24), color, mat)
				tile(side, w * 1.5, z, w * 1.12, 6.2, math.rad(-24), color, mat)
			end
		elseif style == "bricks" then
			-- big bonded blocks
			local rows, across = math.floor(len / 10), 3
			local w = fieldW / across
			for r = 0, rows - 1 do
				local z = (r + 0.5) * len / rows
				local shift = r % 2 == 0 and 0 or w / 2
				local x = -shift
				local c = 0
				while x < fieldW - 0.5 do
					local a, b = math.max(x, 0), math.min(x + w, fieldW)
					if b - a > 1 then
						c += 1
						tile(side, (a + b) / 2, z, b - a - 0.4, len / rows - 0.4, 0, (r * 2 + c) % 5 == 0 and trim or (r + c) % 2 == 0 and light or dark)
					end
					x += w
				end
			end
		elseif style == "diamonds" then
			-- turned squares on the plain floor, a small accent where four meet
			local step = 14
			local across = math.floor(fieldW / step)
			local inset = (fieldW - across * step) / 2
			for r = 0, math.floor(len / step) - 1 do
				for c = 0, across - 1 do
					local x, z = inset + (c + 0.5) * step, (r + 0.5) * step
					tile(side, x, z, step * 0.66, step * 0.66, math.rad(45), (r + c) % 2 == 0 and light or dark)
				end
				if r > 0 and across > 1 then
					for c = 1, across - 1 do
						tile(side, inset + c * step, r * step, 3.4, 3.4, math.rad(45), trim, M.SmoothPlastic)
					end
				end
			end
		elseif style == "weave" then
			-- basket weave: pairs of bars, each square turned from the last
			local step = 13
			local across = math.floor(fieldW / step)
			local inset = (fieldW - across * step) / 2
			for r = 0, math.floor(len / step) - 1 do
				for c = 0, across - 1 do
					local x, z = inset + (c + 0.5) * step, (r + 0.5) * step
					local turned = (r + c) % 2 == 0
					local color = turned and light or dark
					for k = -1, 1, 2 do
						if turned then
							tile(side, x, z + k * step / 4, step - 0.5, step / 2 - 0.5, 0, color)
						else
							tile(side, x + k * step / 4, z, step / 2 - 0.5, step - 0.5, 0, color)
						end
					end
				end
			end
		else
			-- a checkerboard with an accent every so often
			local step = 13
			local across = math.floor(fieldW / step)
			local inset = (fieldW - across * step) / 2
			for r = 0, math.floor(len / step) - 1 do
				for c = 0, across - 1 do
					local col = (r + c) % 2 == 0 and light or dark
					if (r + c * 3) % 7 == 0 then
						col = trim
					end
					tile(side, inset + (c + 0.5) * step, (r + 0.5) * step, step - 0.4, step - 0.4, 0, col)
				end
			end
		end
	end
end

------------------------------------------------------------------
-- GRASS: terrain, so it grows real blades (only the Grass material does, so it's all Grass: other materials read as flat patches).
-- Whatever stands on the ground gets soil under it, or blades would poke through its floor. Small wildflowers go wherever there's
-- nothing else.
------------------------------------------------------------------
-- FillBlock's surface lands 2 studs above the top you ask for (measured), and FillCylinder's jumps in 4-stud steps, so everything
-- is block rows asked to stop at -2.05: that puts the whole lawn just under y = 0, where the paths and floors sit.
local function lay(x, z, sx, sz, yaw, material)
	workspace.Terrain:FillBlock(CFrame.new(x, -6.05, z) * yaw, Vector3.new(sx, 8, sz), material)
end

-- A base's floor grows when its owner buys a bigger one (and shrinks when the plot is handed back): soil under what's there now,
-- grass again on the rest of the ground its largest size would take.
function Environment.baseFootprint(cf, width, front, back, maxBack)
	local function rect(a, b, material)
		if b - a > 2 then
			local middle = cf * Vector3.new(0, 0, (a + b) / 2)
			lay(middle.X, middle.Z, width - 2, b - a - 2, cf.Rotation, material)
		end
	end
	rect(back, maxBack, M.Grass)
	rect(front, back, M.Ground)
end

function Environment.ground(C, entrance, roots, rng, plots)
	local T = workspace.Terrain
	T:SetMaterialColor(M.Grass, rgb(104, 184, 76))
	T:SetMaterialColor(M.LeafyGrass, rgb(70, 152, 62))
	T:SetMaterialColor(M.Ground, rgb(104, 88, 60))
	local LEVEL = CFrame.new()
	local function disc(x, z, r, material)
		for dz = -r + 2, r - 2, 4 do
			lay(x, z + dz, 2 * math.sqrt(r * r - dz * dz), 4, LEVEL, material)
		end
	end
	local R = C.ISLAND_R - 4
	disc(entrance.X, entrance.Z, R, M.Grass)
	-- nothing under the vault: its own floor sits there
	local hallLength = C.ISLAND_R + 10
	T:FillBlock(CFrame.new(0, -6, C.HALL_START_Z - 6 + hallLength / 2), Vector3.new(C.ROOM_W + 24, 16, hallLength), M.Air)
	local function soil(p)
		local top, bottom = p.Position.Y + p.Size.Y / 2, p.Position.Y - p.Size.Y / 2
		if not p.Anchored or p.Transparency >= 1 or bottom > 2 or top < -0.5 then
			return
		end
		local sx, sz = p.Size.X, p.Size.Z
		if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
			-- upright discs (their axis is X): a square that fits inside the circle, so no soil shows round the edge
			if p.Size.Y ~= p.Size.Z or math.abs(p.CFrame.RightVector.Y) < 0.9 then
				return
			end
			sx, sz = p.Size.Z * 0.7, p.Size.Z * 0.7
			top, bottom = p.Position.Y + p.Size.X / 2, p.Position.Y - p.Size.X / 2
			if bottom > 2 or top < -0.5 then
				return
			end
		end
		if sx < 3 or sz < 3 or sx > 700 or sz > 700 then
			return
		end
		local look = p.CFrame.LookVector
		lay(p.Position.X, p.Position.Z, math.max(sx - 2, 2), math.max(sz - 2, 2), CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0), M.Ground)
	end
	for _, root in ipairs(roots) do
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") then
				soil(d)
			end
		end
	end
	-- wildflowers, only where nothing solid or paved stands
	local flowers = Instance.new("Folder")
	flowers.Name = "Flowers"
	flowers.Parent = roots[1]
	local patch = assets.FlowerPatch
	local check = OverlapParams.new()
	check.FilterType = Enum.RaycastFilterType.Include
	check.FilterDescendantsInstances = roots
	local placed = 0
	for _ = 1, 400 do
		if placed >= 160 then
			break
		end
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(50, C.FENCE_R - 12)
		local pos = entrance + Vector3.new(math.sin(a), 0, -math.cos(a)) * r
		local clear = pos.Z < C.HALL_START_Z - 12 or math.abs(pos.X) > C.ROOM_W / 2 + 16
		-- nor on any ground a base could grow over, or its yard (bases are built round their owner later)
		for _, plot in ipairs(plots) do
			local p = plot.CF:PointToObjectSpace(pos)
			if math.abs(p.X) < C.PLOT_W / 2 + 20 and p.Z > -C.PLOT_D / 2 - 45 and p.Z < C.PLOT_D + 130 then
				clear = false
			end
		end
		if clear then
			for _, hit in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 6, 0)), Vector3.new(18, 12, 18), check)) do
				if hit.Name ~= "Island" and hit.Name ~= "IslandRim" then
					clear = false
					break
				end
			end
		end
		if clear then
			local f = patch:Clone()
			f.Size = f.Size * rng:NextNumber(0.5, 0.8) -- small enough to sit down among the grass blades
			f.CFrame = CFrame.new(pos + Vector3.new(0, f.Size.Y / 2 - 0.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			f.CastShadow = false
			f.Parent = flowers
			placed += 1
		end
	end
	return placed
end

return Environment

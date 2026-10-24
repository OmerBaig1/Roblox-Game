--[[
	STEAL A GAME - BASES
	Builds a player base: the ground floor (treadmill, cash pad, lock, upgrade
	station, top-3 podium), extra floors with stairs on the side, and the glass
	display cases (4 along each side of every floor).
	The main script owns the rules; this file only builds and updates the parts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))

local Base = {}
local C, Kit

local PLOT_COLORS = {
	Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255), Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 200, 70),
	Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 140, 60), Color3.fromRGB(70, 220, 220), Color3.fromRGB(255, 120, 200),
}

local CASE_X = 24
local CASE_Z = {-16, -2, 12, 26}     -- evenly spaced rows of cases
local GAP_Z1, GAP_Z2 = -13, -5       -- doorway in the side wall where the stairs arrive (between rows 1 and 2)
local LOW_GAP_Z1, LOW_GAP_Z2 = -41, -35 -- doorway out to the next floor's stairs (front corner)
local STAIR_Z0, STAIR_Z1 = -43, -13

function Base.init(config, kit)
	C, Kit = config, kit
end

local function floorY(f)
	return (f - 1) * C.FLOOR_H
end
Base.floorY = floorY

local function stairSide(f)
	return (f % 2 == 0) and 1 or -1
end

-- Case p (1-8) on floor f: alternates left/right, front to back
function Base.caseLocal(f, p)
	local sx = (p % 2 == 1) and -1 or 1
	local row = math.ceil(p / 2)
	return sx, CFrame.new(sx * CASE_X, floorY(f) + 2, CASE_Z[row])
end

function Base.insidePlot(plot, position)
	local lp = plot.CF:PointToObjectSpace(position)
	return math.abs(lp.X) <= C.PLOT_W / 2 + 10 and math.abs(lp.Z) <= C.PLOT_D / 2 and lp.Y > -5 and lp.Y < C.MAX_FLOORS * C.FLOOR_H + 10
end

------------------------------------------------------------------
-- WALLS (shared by every floor)
------------------------------------------------------------------
local function buildWalls(parent, plot, f)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W, D = C.PLOT_W, C.PLOT_D
	local y0 = floorY(f)
	local at = function(x, y, z) return plot.CF * CFrame.new(x, y, z) end
	local wallColor, cap = rgb(46, 48, 60), rgb(225, 190, 90)
	local accent = plot.Accent
	local wallH = 14
	local wy = y0 + 1 + wallH / 2

	part(parent, {Name = "BackWall", Size = Vector3.new(W, wallH, 1), CFrame = at(0, wy, D / 2 - 0.5), Color = wallColor, Material = M.Brick})
	part(parent, {Name = "WallCap", Size = Vector3.new(W + 0.6, 0.6, 1.6), CFrame = at(0, y0 + 1 + wallH + 0.3, D / 2 - 0.5), Color = cap, Material = M.Metal})
	part(parent, {Name = "Glow", Size = Vector3.new(W - 2, 0.35, 0.2), CFrame = at(0, y0 + 3, D / 2 - 1.1), Color = accent, Material = M.Neon, CanCollide = false})

	-- Side walls run the whole length. Upper floors get a doorway where their stairs
	-- arrive, and a doorway out to the stairs for the floor above.
	local topGap = (f >= 2) and stairSide(f) or 0
	local lowGap = (f >= 2 and f < C.MAX_FLOORS) and stairSide(f + 1) or 0
	for _, sx in ipairs({-1, 1}) do
		local x = sx * (W / 2 - 0.5)
		local cuts = {}
		if sx == lowGap then
			table.insert(cuts, {LOW_GAP_Z1, LOW_GAP_Z2})
		end
		if sx == topGap then
			table.insert(cuts, {GAP_Z1, GAP_Z2})
		end
		local pieces = {}
		local start = -D / 2
		for _, cut in ipairs(cuts) do
			if cut[1] > start then
				table.insert(pieces, {start, cut[1]})
			end
			start = cut[2]
		end
		table.insert(pieces, {start, D / 2})
		if sx == lowGap then
			-- Glass panel blocks this doorway until the next floor (and its stairs) is built
			part(parent, {Name = "StairGapPanel", Size = Vector3.new(0.4, wallH, LOW_GAP_Z2 - LOW_GAP_Z1), CFrame = at(x, wy, (LOW_GAP_Z1 + LOW_GAP_Z2) / 2), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
		end
		for _, pz in ipairs(pieces) do
			local len, mid = pz[2] - pz[1], (pz[1] + pz[2]) / 2
			part(parent, {Name = "SideWall", Size = Vector3.new(1, wallH, len), CFrame = at(x, wy, mid), Color = wallColor, Material = M.Brick})
			part(parent, {Name = "WallCap", Size = Vector3.new(1.6, 0.6, len), CFrame = at(x, y0 + 1 + wallH + 0.3, mid), Color = cap, Material = M.Metal})
			part(parent, {Name = "Glow", Size = Vector3.new(0.2, 0.35, len - 1), CFrame = at(x - sx * 0.6, y0 + 3, mid), Color = accent, Material = M.Neon, CanCollide = false})
			part(parent, {Name = "Glow", Size = Vector3.new(0.2, 0.35, len - 1), CFrame = at(x - sx * 0.6, y0 + wallH, mid), Color = accent, Material = M.Neon, CanCollide = false})
		end
		-- Wall lamps
		for _, lz in ipairs({5, 19}) do
			local lamp = part(parent, {Name = "WallLamp", Size = Vector3.new(0.5, 1.6, 1.2), CFrame = at(x - sx * 0.75, y0 + 10, lz), Color = accent:Lerp(Color3.new(1, 1, 1), 0.35), Material = M.Neon, CanCollide = false})
			local glow = Instance.new("PointLight")
			glow.Color = accent
			glow.Range = 16
			glow.Brightness = 1.2
			glow.Shadows = false
			glow.Parent = lamp
		end
	end

	-- Corner pillars
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			Kit.cylinder(parent, C.FLOOR_H, 3, at(sx * W / 2, y0 + C.FLOOR_H / 2, sz * D / 2), {Name = "Pillar", Color = rgb(235, 232, 225), Material = M.Marble})
		end
	end
end

------------------------------------------------------------------
-- A NEW PLOT (ground floor)
------------------------------------------------------------------
function Base.new(index, cf, parent)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W, D = C.PLOT_W, C.PLOT_D
	local accent = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	local at = function(x, y, z) return cf * CFrame.new(x, y, z) end

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = parent

	local plot = {
		Index = index, CF = cf, Model = model, Accent = accent, Owner = nil,
		Slots = {}, Floors = 1, FloorModels = {}, Bank = 0, LockedUntil = 0,
		Runner = nil, SlatOffset = 0, Slats = {},
		TreadCF = cf * CFrame.new(0, 0, -14),
		Spawn = cf * CFrame.new(0, 4, -6),
		Podium = {},
	}

	-- Floor
	part(model, {Name = "Floor", Size = Vector3.new(W, 1, D), CFrame = at(0, 0.5, 0), Color = rgb(62, 64, 76), Material = M.Slate})
	part(model, {Name = "FloorTrim", Size = Vector3.new(W + 1, 0.4, D + 1), CFrame = at(0, 0.2, 0), Color = accent, Material = M.Neon})
	for col = 0, 7 do
		for row = 0, 3 do
			if (col + row) % 2 == 0 then
				part(model, {Name = "Tile", Size = Vector3.new(5, 0.06, 5), CFrame = at(-17.5 + col * 5, 1.03, -39.5 + row * 5), Color = rgb(88, 90, 104), Material = M.Marble, CanCollide = false})
			end
		end
	end
	part(model, {Name = "Runner", Size = Vector3.new(12, 0.08, 60), CFrame = at(0, 1.04, 8), Color = accent:Lerp(Color3.new(0, 0, 0), 0.55), Material = M.Fabric, CanCollide = false})

	buildWalls(model, plot, 1)

	-- Archway over the open front, and the lock lasers
	part(model, {Name = "Arch", Size = Vector3.new(W, 2.4, 1.4), CFrame = at(0, 16.2, -D / 2), Color = rgb(46, 48, 60), Material = M.Brick})
	part(model, {Name = "ArchGlow", Size = Vector3.new(W - 2, 0.35, 1.5), CFrame = at(0, 15, -D / 2), Color = accent, Material = M.Neon, CanCollide = false})
	plot.Barrier = part(model, {Name = "LaserBarrier", Size = Vector3.new(W, 14, 0.4), CFrame = at(0, 8, -D / 2), Color = rgb(255, 40, 40), Material = M.Neon, Transparency = 1, CanCollide = false})

	local signPart = part(model, {Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = at(0, 19, -D / 2), Transparency = 1, CanCollide = false})
	plot.SignLabel = Kit.billboard(signPart, 620, 110, 3, "Empty Base", 400)

	-- Potted bushes at the entrance
	for _, sx in ipairs({-1, 1}) do
		Kit.cylinder(model, 2.4, 3.4, at(sx * (W / 2 - 4), 2.2, -D / 2 + 4), {Name = "Pot", Color = rgb(170, 95, 60), Material = M.Concrete})
		part(model, {Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = at(sx * (W / 2 - 4), 4.8, -D / 2 + 4), Color = rgb(60, 145, 70), Material = M.Grass, CanCollide = false})
	end

	-- Cash pad
	plot.Pad = part(model, {Name = "CollectPad", Size = Vector3.new(9, 0.4, 9), CFrame = at(-18, 1.2, -34), Color = rgb(40, 220, 90), Material = M.Neon})
	plot.PadLabel = Kit.billboard(plot.Pad, 220, 70, 3.5, "$0")

	-- Lock pad: step on it to lock your base
	local lockButton = part(model, {Name = "LockPad", Size = Vector3.new(6, 0.5, 6), CFrame = at(14, 1.25, -36), Color = rgb(235, 60, 60), Material = M.Neon})
	part(model, {Name = "LockPadRim", Size = Vector3.new(7, 0.3, 7), CFrame = at(14, 1.1, -36), Color = rgb(255, 255, 255), Material = M.SmoothPlastic})
	plot.LockButton = lockButton
	plot.LockLabel = Kit.billboard(lockButton, 230, 60, 4.5, "LOCK BASE")

	-- Treadmill prompts live on an invisible part that never gets rebuilt
	local treadAnchor = part(model, {Name = "TreadmillAnchor", Size = Vector3.new(1, 1, 1), CFrame = plot.TreadCF * CFrame.new(0, 3, -10), Transparency = 1, CanCollide = false})
	plot.RunPrompt = Kit.prompt(treadAnchor, "Run on Treadmill", "Treadmill", 0, 9)
	plot.TreadUpgradePrompt = Kit.prompt(treadAnchor, "Upgrade Treadmill", "Treadmill", 0.3, 9)
	plot.TreadUpgradePrompt.KeyboardKeyCode = Enum.KeyCode.F
	plot.TreadUpgradePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	plot.TreadUpgradePrompt.UIOffset = Vector2.new(0, 70)
	local treadLabelPart = part(model, {Name = "TreadmillLabel", Size = Vector3.new(1, 1, 1), CFrame = plot.TreadCF * CFrame.new(0, 6.5, -17.5), Transparency = 1, CanCollide = false})
	plot.TreadLabel = Kit.billboard(treadLabelPart, 260, 64, 1, "TREADMILL", 90)

	-- TOP 3 podium against the back wall
	local podium = {{x = 0, h = 6, color = rgb(255, 210, 60)}, {x = -9.5, h = 4.5, color = rgb(210, 215, 225)}, {x = 9.5, h = 3, color = rgb(215, 140, 80)}}
	for rank, p in ipairs(podium) do
		local block = part(model, {Name = "Podium" .. rank, Size = Vector3.new(8.6, p.h, 6), CFrame = at(p.x, 1 + p.h / 2, 37.5), Color = p.color, Material = M.Marble})
		part(model, {Name = "PodiumTrim", Size = Vector3.new(8.8, 0.4, 6.2), CFrame = at(p.x, 1 + p.h, 37.5), Color = p.color:Lerp(Color3.new(1, 1, 1), 0.4), Material = M.Neon})
		local blockText = Kit.surfaceText(block, Enum.NormalId.Front, "#" .. rank, Color3.new(1, 1, 1), 30)
		local board = part(model, {Name = "PodiumBoard" .. rank, Size = Vector3.new(6, 7.5, 0.4), CFrame = at(p.x, 1 + p.h + 0.6 + 3.75, 40.6), Color = rgb(25, 25, 32)})
		part(model, {Name = "BoardFrame", Size = Vector3.new(6.6, 8.1, 0.3), CFrame = at(p.x, 1 + p.h + 0.6 + 3.75, 40.85), Color = p.color, Material = M.Neon})
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = board
		plot.Podium[rank] = {Gui = sg, Text = blockText, Key = ""}
	end
	local title = part(model, {Name = "PodiumTitle", Size = Vector3.new(14, 2.4, 0.3), CFrame = at(0, 18.6, 41.2), Color = rgb(25, 25, 32)})
	Kit.surfaceText(title, Enum.NormalId.Front, "TOP GAMES", Kit.GOLD, 30)

	plot.FloorModels[1] = model
	return plot
end

------------------------------------------------------------------
-- EXTRA FLOORS (with stairs up the side of the base)
------------------------------------------------------------------
local function buildFloor(plot, f)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W, D = C.PLOT_W, C.PLOT_D
	local y0 = floorY(f)
	local at = function(x, y, z) return plot.CF * CFrame.new(x, y, z) end
	local accent = plot.Accent

	local model = Instance.new("Model")
	model.Name = "Floor" .. f
	model.Parent = plot.Model

	part(model, {Name = "Slab", Size = Vector3.new(W, 1, D), CFrame = at(0, y0 + 0.5, 0), Color = rgb(62, 64, 76), Material = M.Slate})
	part(model, {Name = "SlabEdge", Size = Vector3.new(W + 0.6, 0.4, 0.6), CFrame = at(0, y0 + 0.2, -D / 2), Color = accent, Material = M.Neon})
	part(model, {Name = "Runner", Size = Vector3.new(12, 0.08, 60), CFrame = at(0, y0 + 1.04, 8), Color = accent:Lerp(Color3.new(0, 0, 0), 0.55), Material = M.Fabric, CanCollide = false})
	-- Glass railing along the whole front
	part(model, {Name = "Railing", Size = Vector3.new(W - 2, 3.5, 0.4), CFrame = at(0, y0 + 2.75, -D / 2 + 0.4), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
	part(model, {Name = "RailTop", Size = Vector3.new(W - 2, 0.4, 0.6), CFrame = at(0, y0 + 4.6, -D / 2 + 0.4), Color = rgb(225, 190, 90), Material = M.Metal})
	-- Open the doorway on the floor below that leads out to these stairs
	local below = plot.FloorModels[f - 1]
	local panel = below and below:FindFirstChild("StairGapPanel")
	if panel then
		panel:Destroy()
	end
	local floorSign = part(model, {Name = "FloorSign", Size = Vector3.new(12, 2.4, 0.3), CFrame = at(0, y0 + 18.2, D / 2 - 1.2), Color = rgb(25, 25, 32)})
	Kit.surfaceText(floorSign, Enum.NormalId.Front, "FLOOR " .. f, accent, 30)

	buildWalls(model, plot, f)

	-- Stairs from floor f-1 up to floor f, on the outside of one side wall
	local s = stairSide(f)
	local sx = s * (W / 2 + 4.5)
	local yb = floorY(f - 1) + 1
	local rise = C.FLOOR_H
	local run = STAIR_Z1 - STAIR_Z0
	local steps = 20
	for i = 1, steps do
		local z = STAIR_Z0 + (i - 0.5) * run / steps
		part(model, {Name = "Step", Size = Vector3.new(7, 0.8, run / steps + 0.1), CFrame = at(sx, yb + i * rise / steps - 0.4, z), Color = i % 2 == 0 and rgb(150, 105, 64) or rgb(170, 125, 80), Material = M.WoodPlanks, CanCollide = false})
	end
	-- An invisible ramp makes walking up smooth
	Kit.wedge(model, {Name = "StairRamp", Size = Vector3.new(7, rise, run), CFrame = at(sx, yb + rise / 2, (STAIR_Z0 + STAIR_Z1) / 2), Transparency = 1})
	local angle = math.atan2(rise, run)
	local railLen = math.sqrt(rise ^ 2 + run ^ 2)
	part(model, {Name = "StairRail", Size = Vector3.new(0.4, 0.4, railLen), CFrame = at(sx + s * 3.6, yb + rise / 2 + 3, (STAIR_Z0 + STAIR_Z1) / 2) * CFrame.Angles(-angle, 0, 0), Color = rgb(225, 190, 90), Material = M.Metal})
	part(model, {Name = "StairSide", Size = Vector3.new(0.6, 1.2, railLen), CFrame = at(sx + s * 3.6, yb + rise / 2 - 0.4, (STAIR_Z0 + STAIR_Z1) / 2) * CFrame.Angles(-angle, 0, 0), Color = accent, Material = M.Neon})
	-- Landing at the top, into the doorway in the side wall
	part(model, {Name = "Landing", Size = Vector3.new(9.5, 1, GAP_Z2 - STAIR_Z1 + 1), CFrame = at(s * (W / 2 + 4.25), y0 + 0.5, (STAIR_Z1 + GAP_Z2) / 2), Color = rgb(150, 105, 64), Material = M.WoodPlanks})
	part(model, {Name = "LandingRail", Size = Vector3.new(0.4, 3.5, GAP_Z2 - STAIR_Z1 + 1), CFrame = at(s * (W / 2 + 8.8), y0 + 2.75, (STAIR_Z1 + GAP_Z2) / 2), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
	-- Landing at the bottom when the stairs start on an upper floor
	if f >= 3 then
		part(model, {Name = "LowerLanding", Size = Vector3.new(10, 1, 14), CFrame = at(s * (W / 2 + 4.5), yb - 0.5, -42), Color = rgb(150, 105, 64), Material = M.WoodPlanks})
		part(model, {Name = "LowerRail", Size = Vector3.new(0.4, 3.5, 14), CFrame = at(s * (W / 2 + 9.3), yb + 1.75, -42), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
		part(model, {Name = "LowerRailFront", Size = Vector3.new(10, 3.5, 0.4), CFrame = at(s * (W / 2 + 4.5), yb + 1.75, -49), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
	end

	plot.FloorModels[f] = model
end

------------------------------------------------------------------
-- DISPLAY CASES
------------------------------------------------------------------
local function buildCase(plot, slotIndex, callbacks)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local f = math.ceil(slotIndex / C.CASES_PER_FLOOR)
	local p = (slotIndex - 1) % C.CASES_PER_FLOOR + 1
	local sx, lcf = Base.caseLocal(f, p)
	local cf = plot.CF * lcf
	local accent = plot.Accent

	local model = Instance.new("Model")
	model.Name = "Case" .. slotIndex
	model.Parent = plot.FloorModels[f] or plot.Model

	local ped = part(model, {Name = "Pedestal", Size = Vector3.new(5.5, 2, 5.5), CFrame = cf, Color = rgb(45, 45, 55), Material = M.Marble})
	part(model, {Name = "CaseBase", Size = Vector3.new(5.9, 0.3, 5.9), CFrame = cf * CFrame.new(0, 1.15, 0), Color = accent, Material = M.Neon})
	part(model, {Name = "CaseGlass", Size = Vector3.new(5.3, 6.4, 5.3), CFrame = cf * CFrame.new(0, 4.5, 0), Color = rgb(220, 240, 255), Material = M.SmoothPlastic, Transparency = 0.9, Reflectance = 0.1, CanCollide = false})
	for _, cx in ipairs({-2.7, 2.7}) do
		for _, cz in ipairs({-2.7, 2.7}) do
			part(model, {Name = "CasePost", Size = Vector3.new(0.3, 6.4, 0.3), CFrame = cf * CFrame.new(cx, 4.5, cz), Color = rgb(255, 205, 60), Material = M.Metal})
		end
	end
	local lid = part(model, {Name = "CaseLid", Size = Vector3.new(5.8, 0.3, 5.8), CFrame = cf * CFrame.new(0, 7.85, 0), Color = rgb(255, 205, 60), Material = M.Metal})
	local light = Instance.new("PointLight")
	light.Range = 7
	light.Brightness = 1
	light.Shadows = false
	light.Parent = lid
	local number = part(model, {Name = "CaseNumber", Size = Vector3.new(2.4, 1, 0.2), CFrame = cf * CFrame.new(-sx * 2.86, 0, 0) * CFrame.Angles(0, -sx * math.pi / 2, 0), Color = rgb(25, 25, 32)})
	Kit.surfaceText(number, Enum.NormalId.Front, tostring(slotIndex), accent, 30)

	local anchor = part(model, {Name = "CaseAnchor", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(-sx * 3, 3, 0), Transparency = 1, CanCollide = false})
	local mainPrompt = Kit.prompt(anchor, "Place game", "Case " .. slotIndex, 0.25, 8, "CasePrompt")
	local sellPrompt = Kit.prompt(anchor, "Sell", "", 1.2, 8, "SellPrompt")
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.F
	sellPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	sellPrompt.UIOffset = Vector2.new(0, 70)

	local slot = {
		Index = slotIndex, Floor = f, Side = sx, Model = model, Pedestal = ped,
		ItemCF = cf * CFrame.new(0, 3.8, 0) * CFrame.Angles(0, -sx * math.pi / 2, 0),
		MainPrompt = mainPrompt, SellPrompt = sellPrompt,
		Item = nil, Data = nil, Reserved = false,
	}
	for _, pr in ipairs({mainPrompt, sellPrompt}) do
		pr:SetAttribute("OwnerId", plot.Owner and plot.Owner.UserId or 0)
		pr:SetAttribute("HasGame", false)
	end
	mainPrompt.Triggered:Connect(function(player)
		callbacks.onCase(player, plot, slot)
	end)
	sellPrompt.Triggered:Connect(function(player)
		callbacks.onSell(player, plot, slot)
	end)
	plot.Slots[slotIndex] = slot
	return slot
end

-- Make the base have exactly this many floors and cases (adds or removes)
function Base.setLayout(plot, floors, cases, callbacks)
	for f = #plot.FloorModels, 2, -1 do
		if f > floors then
			plot.FloorModels[f]:Destroy()
			plot.FloorModels[f] = nil
		end
	end
	for i = #plot.Slots, 1, -1 do
		if i > cases then
			local slot = plot.Slots[i]
			if slot.Item then
				slot.Item:Destroy()
			end
			if slot.Model.Parent then
				slot.Model:Destroy()
			end
			plot.Slots[i] = nil
		end
	end
	for f = 2, floors do
		if not plot.FloorModels[f] then
			buildFloor(plot, f)
		end
	end
	for i = 1, cases do
		if not plot.Slots[i] then
			buildCase(plot, i, callbacks)
		end
	end
	plot.Floors, plot.Cases = floors, cases
end

------------------------------------------------------------------
-- UPGRADE SPOTS: a glowing outline wherever a future case goes (the next
-- one shows its price and can be bought right there), and ghost stairs
-- where the next floor's stairs will go once the current floors are full.
------------------------------------------------------------------
function Base.setPlaceholders(plot, nextKind, costText, onBuy)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	if plot.PlaceholderModel then
		plot.PlaceholderModel:Destroy()
		plot.PlaceholderModel = nil
	end
	if not plot.Owner then return end
	local model = Instance.new("Model")
	model.Name = "UpgradeSpots"
	model.Parent = plot.Model
	plot.PlaceholderModel = model
	local ownerId = plot.Owner.UserId

	local function buyPrompt(parent, action, object, distance)
		local pr = Kit.prompt(parent, action, object, 0.3, distance, "OwnerOnlyPrompt")
		pr:SetAttribute("OwnerId", ownerId)
		pr.Triggered:Connect(function(player)
			onBuy(player, plot)
		end)
	end

	for i = plot.Cases + 1, plot.Floors * C.CASES_PER_FLOOR do
		local f = math.ceil(i / C.CASES_PER_FLOOR)
		local p = (i - 1) % C.CASES_PER_FLOOR + 1
		local _, lcf = Base.caseLocal(f, p)
		local cf = plot.CF * lcf
		local isNext = (i == plot.Cases + 1) and nextKind == "case"
		local color = isNext and Kit.GOLD or rgb(130, 130, 150)
		local pad = part(model, {Name = "CaseSpot", Size = Vector3.new(5.6, 0.2, 5.6), CFrame = cf * CFrame.new(0, -0.9, 0), Color = color, Material = M.Neon, Transparency = isNext and 0.2 or 0.65, CanCollide = false})
		part(model, {Name = "CaseGhost", Size = Vector3.new(5.3, 7.5, 5.3), CFrame = cf * CFrame.new(0, 2.85, 0), Color = color, Material = M.ForceField, Transparency = isNext and 0.2 or 0.6, CanCollide = false, CanQuery = false})
		local text = isNext
			and string.format('<font color="#ffd23c">ADD CASE %d</font>\n%s', i, costText)
			or ('<font color="#9696aa">LOCKED</font>\nCase ' .. i)
		Kit.billboard(pad, 230, 70, 9, text, isNext and 80 or 22)
		if isNext then
			buyPrompt(pad, "Buy case (" .. costText .. ")", "Case " .. i, 9)
		end
	end

	if nextKind == "floor" then
		local f = plot.Floors + 1
		local s = stairSide(f)
		local sx = s * (C.PLOT_W / 2 + 4.5)
		local yb = floorY(f - 1) + 1
		Kit.wedge(model, {Name = "GhostStairs", Size = Vector3.new(7, C.FLOOR_H, STAIR_Z1 - STAIR_Z0), CFrame = plot.CF * CFrame.new(sx, yb + C.FLOOR_H / 2, (STAIR_Z0 + STAIR_Z1) / 2), Color = Kit.GOLD, Material = M.ForceField, Transparency = 0.3, CanCollide = false, CanQuery = false})
		local sign = part(model, {Name = "FloorSpot", Size = Vector3.new(7, 0.2, 6), CFrame = plot.CF * CFrame.new(sx, yb + 0.1, STAIR_Z0 - 4), Color = Kit.GOLD, Material = M.Neon, Transparency = 0.2, CanCollide = false})
		Kit.billboard(sign, 280, 80, 6, string.format('<font color="#ffd23c">BUILD FLOOR %d</font>\n%s', f, costText), 200)
		buyPrompt(sign, "Build floor " .. f .. " (" .. costText .. ")", "Floor " .. f, 12)
	end
end

------------------------------------------------------------------
-- TREADMILL LOOKS
------------------------------------------------------------------
local SLAT_COUNT, SLAT_GAP = 8, 1.55
Base.SLAT_COUNT, Base.SLAT_GAP = SLAT_COUNT, SLAT_GAP
Base.BELT_TOP = 1.9

function Base.rebuildTreadmill(plot, level, tier, labelText)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local at = function(x, y, z) return plot.TreadCF * CFrame.new(x, y, z) end
	if plot.TreadModel then
		plot.TreadModel:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Treadmill"
	model.Parent = plot.Model
	plot.TreadModel = model

	local wide = tier.Panels and 1 or 0
	part(model, {Name = "Frame", Size = Vector3.new(7 + wide, 0.6, 13.5), CFrame = at(0, 1.3, -10), Color = tier.Frame, Material = tier.FrameMat})
	plot.Slats = {}
	for i = 1, SLAT_COUNT do
		local slatColor = (tier.AccentMat == M.Neon and i % 2 == 0) and tier.Accent:Lerp(Kit.DARK, 0.65) or rgb(22, 22, 25)
		local slat = part(model, {Name = "Slat", Size = Vector3.new(6, 0.3, SLAT_GAP - 0.1), CFrame = at(0, Base.BELT_TOP - 0.15, -16 + (i - 1) * SLAT_GAP), Color = slatColor, Material = M.Fabric})
		table.insert(plot.Slats, slat)
	end
	for _, sx in ipairs({-1, 1}) do
		part(model, {Name = "Rail", Size = Vector3.new(0.4, 0.4, 10), CFrame = at(sx * 3.4, 4.4, -11), Color = tier.Accent, Material = tier.AccentMat})
		part(model, {Name = "RailPost", Size = Vector3.new(0.4, 2.8, 0.4), CFrame = at(sx * 3.4, 3, -15.8), Color = tier.Frame, Material = tier.FrameMat})
		if tier.Panels then
			part(model, {Name = "SidePanel", Size = Vector3.new(0.5, 1, 13.5), CFrame = at(sx * 4.1, 1.6, -10), Color = tier.Accent, Material = tier.AccentMat})
		end
	end
	local console = part(model, {Name = "Console", Size = Vector3.new(6, 3.5, 1), CFrame = at(0, 2.75, -17.5), Color = tier.Frame, Material = tier.FrameMat})
	part(model, {Name = "Screen", Size = Vector3.new(4, 1.4, 0.2), CFrame = at(0, 3.3, -17.05), Color = tier.Accent:Lerp(rgb(80, 170, 255), 0.4), Material = M.Neon})
	local n = C.TREAD_MAX_LEVEL
	local spacing = 5.4 / n
	for i = 1, n do
		local lit = i <= level
		part(model, {Name = "Meter", Size = Vector3.new(spacing * 0.7, 0.5, 0.15), CFrame = at(-2.7 + (i - 0.5) * spacing, 2.1, -16.95), Color = lit and tier.Accent or rgb(40, 40, 45), Material = lit and M.Neon or M.SmoothPlastic})
	end
	if tier.Light then
		local light = Instance.new("PointLight")
		light.Color = tier.Accent
		light.Range = 14
		light.Brightness = 2
		light.Parent = console
	end
	if tier.Sparkles then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = tier.Accent
		sparkles.Parent = console
	end
	if tier.Arch then
		for _, sx in ipairs({-1, 1}) do
			part(model, {Name = "ArchPost", Size = Vector3.new(0.6, 9, 0.6), CFrame = at(sx * 4.4, 5.5, -4), Color = tier.Accent, Material = M.Neon})
		end
		part(model, {Name = "ArchTop", Size = Vector3.new(9.4, 0.6, 0.6), CFrame = at(0, 10, -4), Color = tier.Accent, Material = M.Neon})
	end
	if tier.Rings then
		for i = 0, 1 do
			part(model, {Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 9, 9), CFrame = at(0, 5, -7 - i * 5) * CFrame.Angles(0, math.pi / 2, 0), Color = tier.Accent, Material = M.Neon, Transparency = 0.35, CanCollide = false})
		end
	end
	if tier.Fins then
		for _, sx in ipairs({-1, 1}) do
			Kit.wedge(model, {Name = "Fin", Size = Vector3.new(0.4, 4, 6), CFrame = at(sx * 4.6, 3.6, -15) * CFrame.Angles(0, math.pi, 0), Color = tier.Accent, Material = M.Neon})
		end
	end

	-- A little better every single level: one more glowing light bar on the console
	-- per level inside the current look, and a brighter glow
	local step = level % C.TREAD_LEVELS_PER_TIER
	for i = 1, step do
		part(model, {Name = "LevelBar", Size = Vector3.new(0.7, 0.5 + i * 0.35, 0.5), CFrame = at(-2.4 + (i - 1) * 1.2, 4.75 + (0.5 + i * 0.35) / 2, -17.5), Color = tier.Accent, Material = M.Neon})
	end
	if step > 0 then
		local glow = Instance.new("PointLight")
		glow.Color = tier.Accent
		glow.Range = 8 + step * 3
		glow.Brightness = 0.6 + step * 0.4
		glow.Shadows = false
		glow.Parent = console
	end
	plot.TreadLabel.Text = labelText
end

------------------------------------------------------------------
-- TOP 3 PODIUM
------------------------------------------------------------------
-- top = list of up to 3 {Name, Rarity, Color, IncomeText}
function Base.updatePodium(plot, top)
	for rank = 1, 3 do
		local spot = plot.Podium[rank]
		local g = top[rank]
		local key = g and (g.Name .. "|" .. g.IncomeText) or ""
		if spot.Key ~= key then
			spot.Key = key
			spot.Gui:ClearAllChildren()
			if g then
				GamePoster.Create({Name = g.Name, Rarity = g.Rarity, Color = g.Color}).Parent = spot.Gui
				spot.Text.Text = string.format('#%d\n<font color="#5aff78">%s</font>', rank, g.IncomeText)
			else
				local t = Instance.new("TextLabel")
				t.Size = UDim2.fromScale(1, 1)
				t.BackgroundTransparency = 1
				t.Font = Enum.Font.FredokaOne
				t.TextScaled = true
				t.TextColor3 = Color3.fromRGB(120, 120, 135)
				t.Text = "?"
				t.Parent = spot.Gui
				spot.Text.Text = "#" .. rank
			end
		end
	end
end

return Base

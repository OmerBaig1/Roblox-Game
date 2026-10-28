--[[
	STEAL A GAME - BASES
	Builds a player base. The FRONT of the base (treadmill, cash pad, lock pad,
	sign) never moves. Each base TIER (Starter, Deluxe, Mega, Ultimate) makes the
	base longer with more rows of cases, and gives it a nicer look. Every tier has
	2 floors; when both are full, the next upgrade is a whole-base revamp.
	The main script owns the rules; this file only builds and updates the parts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))

local Base = {}
local C, Kit
local FRONT -- local Z of the open front of every base

local PLOT_COLORS = {
	Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 160, 255), Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 200, 70),
	Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 140, 60), Color3.fromRGB(70, 220, 220), Color3.fromRGB(255, 120, 200),
}

local CASE_X = 24
local ROW_GAP = 14
local GAP_Z1, GAP_Z2, LOW_GAP_Z1, LOW_GAP_Z2, STAIR_Z0, STAIR_Z1

function Base.init(config, kit)
	C, Kit = config, kit
	FRONT = -C.PLOT_D / 2
	GAP_Z1, GAP_Z2 = FRONT + 29, FRONT + 37         -- doorway where the stairs arrive (between rows 1 and 2)
	LOW_GAP_Z1, LOW_GAP_Z2 = FRONT + 1, FRONT + 7   -- doorway out to the next floor's stairs (front corner)
	STAIR_Z0, STAIR_Z1 = FRONT - 1, FRONT + 29
end

local function floorY(f)
	return (f - 1) * C.FLOOR_H
end
Base.floorY = floorY

local function stairSide(f)
	return (f % 2 == 0) and 1 or -1
end

local function caseZ(row)
	return FRONT + 26 + (row - 1) * ROW_GAP
end

local function backZ(plot)
	return FRONT + plot.D
end

local function midZ(plot)
	return FRONT + plot.D / 2
end

-- Case p on floor f: alternates left/right, front to back
function Base.caseLocal(f, p)
	local sx = (p % 2 == 1) and -1 or 1
	local row = math.ceil(p / 2)
	return sx, CFrame.new(sx * CASE_X, floorY(f) + 2, caseZ(row))
end

function Base.insidePlot(plot, position)
	local lp = plot.CF:PointToObjectSpace(position)
	return math.abs(lp.X) <= C.PLOT_W / 2 + 10 and lp.Z >= FRONT and lp.Z <= backZ(plot) and lp.Y > -5 and lp.Y < (plot.Look and plot.Look.Floors or 2) * C.FLOOR_H + 10
end

-- Strictly inside the walls (not on the stairs or the treadmill outside)
function Base.insideCore(plot, position)
	local lp = plot.CF:PointToObjectSpace(position)
	return math.abs(lp.X) < C.PLOT_W / 2 - 1 and lp.Z > FRONT + 1 and lp.Z < backZ(plot) - 1 and lp.Y > -5 and lp.Y < (plot.Look and plot.Look.Floors or 2) * C.FLOOR_H + 10
end

-- Every lock wall of a base: the front, and the doorway at the top of each staircase
function Base.barriers(plot)
	local list = {plot.Barrier}
	for f, m in pairs(plot.FloorModels) do
		if f >= 2 and m.Parent then
			for _, d in ipairs(m:GetChildren()) do
				if d.Name == "DoorBarrier" then
					table.insert(list, d)
				end
			end
		end
	end
	return list
end

------------------------------------------------------------------
-- WALLS: panelled lower half, painted upper half, trim, pilasters, sconces
------------------------------------------------------------------
local function wallRun(parent, plot, f, cf, len, inward)
	-- cf: centre of the run at floor level, oriented so local X runs along the wall
	-- inward: +1/-1 = which local Z side faces into the base
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local L = plot.Look
	local y0 = floorY(f)
	local H = 14
	local at = function(x, y, z) return cf * CFrame.new(x, y0 + y, z) end
	part(parent, {Name = "Wall", Size = Vector3.new(len, H, 1), CFrame = at(0, 1 + H / 2, 0), Color = L.Wall, Material = L.WallMat})
	-- lower panelling and chair rail (inside face)
	part(parent, {Name = "Wainscot", Size = Vector3.new(len, 4.6, 0.3), CFrame = at(0, 1 + 2.3, inward * 0.62), Color = L.Wainscot, Material = L.WainscotMat})
	part(parent, {Name = "ChairRail", Size = Vector3.new(len, 0.45, 0.5), CFrame = at(0, 5.8, inward * 0.7), Color = L.Trim, Material = L.TrimMat})
	part(parent, {Name = "Baseboard", Size = Vector3.new(len, 0.8, 0.45), CFrame = at(0, 1.4, inward * 0.72), Color = L.Trim, Material = L.TrimMat})
	-- accent stripe in the plot's colour
	part(parent, {Name = "Stripe", Size = Vector3.new(len, 0.7, 0.2), CFrame = at(0, 11.6, inward * 0.6), Color = plot.Accent, Material = M.SmoothPlastic, CanCollide = false})
	-- cornice on top
	part(parent, {Name = "Cornice", Size = Vector3.new(len + 0.4, 0.9, 1.8), CFrame = at(0, 1 + H + 0.45, 0), Color = L.Trim, Material = L.TrimMat})
	if L.Glow then
		part(parent, {Name = "TopGlow", Size = Vector3.new(len, 0.25, 0.25), CFrame = at(0, 1 + H + 1, inward * 0.6), Color = plot.Accent, Material = M.Neon, CanCollide = false})
	end
end

local function addPilaster(parent, plot, f, cf, inward, lamp)
	local M, part = Kit.M, Kit.part
	local L = plot.Look
	local y0 = floorY(f)
	part(parent, {Name = "Pilaster", Size = Vector3.new(1.6, 14, 0.8), CFrame = cf * CFrame.new(0, y0 + 8, inward * 0.85), Color = L.Trim, Material = L.TrimMat})
	if lamp then
		local sconce = part(parent, {Name = "Sconce", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = cf * CFrame.new(0, y0 + 9.5, inward * 1.6), Color = Color3.fromRGB(255, 240, 200), Material = M.Neon, CanCollide = false})
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 235, 200)
		glow.Range = 12
		glow.Brightness = 0.45
		glow.Shadows = false
		glow.Parent = sconce
	end
end

local function buildWalls(parent, plot, f)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W = C.PLOT_W
	local L = plot.Look
	local at = function(x, z) return plot.CF * CFrame.new(x, 0, z) end
	local BACK = backZ(plot)

	-- Back wall (inside faces -Z)
	wallRun(parent, plot, f, at(0, BACK - 0.5), W, -1)

	-- Side walls run the whole length, with doorways for the stairs
	local topGap = (f >= 2) and stairSide(f) or 0
	-- a doorway out to the next floor's stairs, only if this base type has another floor above
	local lowGap = (f >= 2 and f < (plot.Look.Floors or 2)) and stairSide(f + 1) or 0
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
		local start = FRONT
		for _, cut in ipairs(cuts) do
			if cut[1] > start then
				table.insert(pieces, {start, cut[1]})
			end
			start = cut[2]
		end
		table.insert(pieces, {start, BACK})
		if sx == lowGap then
			part(parent, {Name = "StairGapPanel", Size = Vector3.new(0.4, 14, LOW_GAP_Z2 - LOW_GAP_Z1), CFrame = plot.CF * CFrame.new(x, floorY(f) + 8, (LOW_GAP_Z1 + LOW_GAP_Z2) / 2), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
		end
		-- a side wall runs along local Z, so turn the run 90 degrees; inward faces -sx
		local turn = CFrame.Angles(0, math.pi / 2, 0)
		for _, pz in ipairs(pieces) do
			local len, mid = pz[2] - pz[1], (pz[1] + pz[2]) / 2
			wallRun(parent, plot, f, at(x, mid) * turn, len, -sx)
			-- Windows on nicer bases
			if L.Windows then
				for r = 1, plot.Rows do
					local wz = caseZ(r)
					if wz - 3 > pz[1] and wz + 3 < pz[2] then
						part(parent, {Name = "Window", Size = Vector3.new(0.4, 3.4, 5), CFrame = plot.CF * CFrame.new(x, floorY(f) + 8.6, wz), Color = rgb(170, 220, 255), Material = M.Glass, Transparency = 0.35})
						part(parent, {Name = "WindowFrame", Size = Vector3.new(0.5, 3.9, 5.5), CFrame = plot.CF * CFrame.new(x - sx * 0.05, floorY(f) + 8.6, wz), Color = L.Trim, Material = L.TrimMat, Transparency = 0})
					end
				end
			end
		end
		-- Pilasters between the rows of cases (sconces on every other one)
		for r = 1, plot.Rows - 1 do
			local pzz = caseZ(r) + ROW_GAP / 2
			local blocked = false
			for _, cut in ipairs(cuts) do
				if pzz > cut[1] - 1 and pzz < cut[2] + 1 then
					blocked = true
				end
			end
			if not blocked then
				addPilaster(parent, plot, f, plot.CF * CFrame.new(x, 0, pzz) * CFrame.Angles(0, math.pi / 2, 0), -sx, r % 2 == 0)
			end
		end
	end

	-- Corner pillars
	for _, sx in ipairs({-1, 1}) do
		for _, z in ipairs({FRONT, BACK}) do
			Kit.cylinder(parent, C.FLOOR_H, 3, plot.CF * CFrame.new(sx * W / 2, floorY(f) + C.FLOOR_H / 2, z), {Name = "Pillar", Color = L.Pillar, Material = L.PillarMat})
			if L.Glow then
				part(parent, {Name = "PillarTop", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = plot.CF * CFrame.new(sx * W / 2, floorY(f) + C.FLOOR_H + 1, z), Color = plot.Accent, Material = M.Neon, CanCollide = false})
			end
		end
	end
end

------------------------------------------------------------------
-- THE SHELL: ground floor, walls, arch and podium (rebuilt on every revamp)
------------------------------------------------------------------
local function buildShell(plot)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W, D = C.PLOT_W, plot.D
	local L = plot.Look
	local accent = plot.Accent
	local at = function(x, y, z) return plot.CF * CFrame.new(x, y, z) end
	local MID, BACK = midZ(plot), backZ(plot)

	local model = Instance.new("Model")
	model.Name = "Shell"
	model.Parent = plot.Model
	plot.Shell = model

	-- Floor
	part(model, {Name = "Floor", Size = Vector3.new(W, 1, D), CFrame = at(0, 0.5, MID), Color = L.Floor, Material = L.FloorMat})
	part(model, {Name = "FloorTrim", Size = Vector3.new(W + 1, 0.4, D + 1), CFrame = at(0, 0.2, MID), Color = accent, Material = M.SmoothPlastic})
	-- checkered entrance area
	for col = 0, 7 do
		for row = 0, 3 do
			if (col + row) % 2 == 0 then
				part(model, {Name = "Tile", Size = Vector3.new(5, 0.06, 5), CFrame = at(-17.5 + col * 5, 1.03, FRONT + 2.5 + row * 5), Color = L.Tile, Material = L.FloorMat, CanCollide = false})
			end
		end
	end
	-- carpet runner down the middle, past every row of cases
	local runLen = D - 24
	part(model, {Name = "Runner", Size = Vector3.new(12, 0.08, runLen), CFrame = at(0, 1.04, FRONT + 20 + runLen / 2), Color = accent:Lerp(Color3.new(1, 1, 1), 0.15), Material = M.Fabric, CanCollide = false})
	part(model, {Name = "RunnerEdge", Size = Vector3.new(13, 0.06, runLen + 1), CFrame = at(0, 1.02, FRONT + 20 + runLen / 2), Color = L.Trim, Material = L.TrimMat, CanCollide = false})

	buildWalls(model, plot, 1)

	-- Archway over the open front, with the base tier's name
	part(model, {Name = "Arch", Size = Vector3.new(W, 2.6, 1.6), CFrame = at(0, 16.3, FRONT), Color = L.Trim, Material = L.TrimMat})
	part(model, {Name = "ArchStripe", Size = Vector3.new(W - 2, 0.6, 1.7), CFrame = at(0, 15.2, FRONT), Color = accent, Material = M.SmoothPlastic, CanCollide = false})
	local tierSign = part(model, {Name = "TierSign", Size = Vector3.new(20, 2.4, 0.4), CFrame = at(0, 16.3, FRONT - 0.95), Color = L.Wall})
	local t = Kit.surfaceText(tierSign, Enum.NormalId.Front, string.upper(L.Name), accent:Lerp(Color3.new(0, 0, 0), 0.25), 30)
	t.TextStrokeTransparency = 1

	-- Nicer bases get extra decorations at the entrance
	if L.Banners then
		for _, sx in ipairs({-1, 1}) do
			local banner = part(model, {Name = "Banner", Size = Vector3.new(4, 8, 0.3), CFrame = at(sx * (W / 2 - 4), 11, FRONT - 0.95), Color = accent, Material = M.Fabric, CanCollide = false})
			Kit.wedge(model, {Name = "BannerTail", Size = Vector3.new(0.3, 1.6, 2), CFrame = at(sx * (W / 2 - 4) - 1, 6.2, FRONT - 0.95) * CFrame.Angles(0, math.pi / 2, math.pi), Color = accent, CanCollide = false})
			Kit.wedge(model, {Name = "BannerTail", Size = Vector3.new(0.3, 1.6, 2), CFrame = at(sx * (W / 2 - 4) + 1, 6.2, FRONT - 0.95) * CFrame.Angles(0, -math.pi / 2, math.pi), Color = accent, CanCollide = false})
			local star = Kit.surfaceText(banner, Enum.NormalId.Front, "\u{2605}", L.Trim, 30)
			star.TextStrokeTransparency = 1
		end
	end
	if L.Statues then
		for _, sx in ipairs({-1, 1}) do
			-- well clear of every staircase (they used to stand at the foot of the stairs)
			local x = sx * (W / 2 + 15)
			part(model, {Name = "StatueBase", Size = Vector3.new(5, 3, 5), CFrame = at(x, 1.5, FRONT - 4), Color = rgb(245, 245, 250), Material = M.Marble})
			Kit.cylinder(model, 5, 1.2, at(x, 5.5, FRONT - 4), {Name = "TrophyStem", Color = Kit.GOLD, Material = M.Metal})
			part(model, {Name = "TrophyCup", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = at(x, 9.2, FRONT - 4), Color = Kit.GOLD, Material = M.Metal})
			local sparkle = Instance.new("Sparkles")
			sparkle.SparkleColor = Kit.GOLD
			sparkle.Parent = model:FindFirstChild("TrophyCup") or model
		end
	end

	-- TOP 3 podium against the back wall
	plot.Podium = {}
	local podium = {{x = 0, h = 6, color = rgb(255, 210, 60)}, {x = -9.5, h = 4.5, color = rgb(210, 215, 225)}, {x = 9.5, h = 3, color = rgb(215, 140, 80)}}
	for rank, p in ipairs(podium) do
		local block = part(model, {Name = "Podium" .. rank, Size = Vector3.new(8.6, p.h, 6), CFrame = at(p.x, 1 + p.h / 2, BACK - 4.5), Color = p.color, Material = M.Marble})
		part(model, {Name = "PodiumTrim", Size = Vector3.new(8.8, 0.4, 6.2), CFrame = at(p.x, 1 + p.h, BACK - 4.5), Color = p.color:Lerp(Color3.new(1, 1, 1), 0.4), Material = M.SmoothPlastic})
		local blockText = Kit.surfaceText(block, Enum.NormalId.Front, "#" .. rank, Color3.new(1, 1, 1), 30)
		local board = part(model, {Name = "PodiumBoard" .. rank, Size = Vector3.new(6, 7.5, 0.4), CFrame = at(p.x, 1 + p.h + 0.6 + 3.75, BACK - 1.4), Color = rgb(25, 25, 32)})
		part(model, {Name = "BoardFrame", Size = Vector3.new(6.6, 8.1, 0.3), CFrame = at(p.x, 1 + p.h + 0.6 + 3.75, BACK - 1.15), Color = p.color, Material = M.SmoothPlastic})
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = board
		plot.Podium[rank] = {Gui = sg, Text = blockText, Key = ""}
	end
	local title = part(model, {Name = "PodiumTitle", Size = Vector3.new(14, 2.4, 0.3), CFrame = at(0, 18.6, BACK - 0.8), Color = rgb(25, 25, 32)})
	Kit.surfaceText(title, Enum.NormalId.Front, "TOP GAMES", Kit.GOLD, 30)

	plot.FloorModels[1] = model
end

-- Switch the base to a tier (rebuilds the shell; the caller takes the games out first)
function Base.setTier(plot, t)
	if plot.Tier == t and plot.Shell then
		return false
	end
	local tier = C.BASE_TIERS[t]
	plot.Tier, plot.Look = t, tier
	plot.Rows = tier.Rows
	plot.PerFloor = tier.Rows * 2
	plot.D = C.PLOT_D + (tier.Rows - 4) * ROW_GAP
	for f = #plot.FloorModels, 2, -1 do
		plot.FloorModels[f]:Destroy()
		plot.FloorModels[f] = nil
	end
	for _, slot in pairs(plot.Slots) do
		if slot.Item then
			slot.Item:Destroy()
		end
		if slot.Model and slot.Model.Parent then
			slot.Model:Destroy()
		end
	end
	plot.Slots = {}
	plot.Floors, plot.Cases = 1, 0
	if plot.PlaceholderModel then
		plot.PlaceholderModel:Destroy()
		plot.PlaceholderModel = nil
	end
	if plot.Shell then
		plot.Shell:Destroy()
	end
	buildShell(plot)
	return true
end

------------------------------------------------------------------
-- A NEW PLOT (fixtures at the front that never move)
------------------------------------------------------------------
function Base.new(index, cf, parent)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W = C.PLOT_W
	local accent = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]
	local at = function(x, y, z) return cf * CFrame.new(x, y, z) end

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = parent

	local plot = {
		Index = index, CF = cf, Model = model, Accent = accent, Owner = nil,
		Slots = {}, Floors = 1, Cases = 0, FloorModels = {}, Bank = 0, LockedUntil = 0,
		Runner = nil, SlatOffset = 0, Slats = {},
		-- the treadmill sits in the front yard, a little to the right of the entrance,
		-- with its console facing out toward the lobby
		TreadCF = cf * CFrame.new(C.TREAD_OFFSET_X, 0, FRONT - 4),
		Spawn = cf * CFrame.new(0, 4, -6),
		Podium = {},
	}

	plot.Barrier = part(model, {Name = "LaserBarrier", Size = Vector3.new(W, 14, 0.4), CFrame = at(0, 8, FRONT), Color = rgb(255, 40, 40), Material = M.Neon, Transparency = 1, CanCollide = false})
	local signPart = part(model, {Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = at(0, 20, FRONT), Transparency = 1, CanCollide = false})
	plot.SignPart = signPart
	plot.SignLabel = Kit.billboard(signPart, 620, 110, 3, "Empty Base", 400)
	-- the treadmill stands on its own platform in the front yard
	local pad = part(model, {Name = "TreadPad", Size = Vector3.new(13, 1, 23), CFrame = plot.TreadCF * CFrame.new(0, 0.5, -10.5), Color = rgb(235, 235, 245), Material = M.Marble})
	part(model, {Name = "TreadPadTrim", Size = Vector3.new(13.6, 0.5, 23.6), CFrame = plot.TreadCF * CFrame.new(0, 0.25, -10.5), Color = accent, Material = M.SmoothPlastic})

	-- Potted bushes at the entrance
	for _, sx in ipairs({-1, 1}) do
		Kit.cylinder(model, 2.4, 3.4, at(sx * (W / 2 - 4), 2.2, FRONT + 4), {Name = "Pot", Color = rgb(170, 95, 60), Material = M.Concrete})
		part(model, {Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = at(sx * (W / 2 - 4), 4.8, FRONT + 4), Color = rgb(60, 175, 70), Material = M.Grass, CanCollide = false})
	end

	-- Cash pad
	plot.Pad = part(model, {Name = "CollectPad", Size = Vector3.new(9, 0.4, 9), CFrame = at(-18, 1.2, FRONT + 8), Color = rgb(40, 220, 90), Material = M.Neon})
	plot.PadLabel = Kit.billboard(plot.Pad, 220, 70, 3.5, "$0")

	-- Lock pad: step on it to lock your base
	local lockButton = part(model, {Name = "LockPad", Size = Vector3.new(6, 0.5, 6), CFrame = at(14, 1.25, FRONT + 6), Color = rgb(235, 60, 60), Material = M.Neon})
	part(model, {Name = "LockPadRim", Size = Vector3.new(7, 0.3, 7), CFrame = at(14, 1.1, FRONT + 6), Color = rgb(255, 255, 255), Material = M.SmoothPlastic})
	plot.LockButton = lockButton
	plot.LockLabel = Kit.billboard(lockButton, 230, 60, 4.5, "LOCK BASE")
	-- UNLOCK button on the wall beside it: hold E (or hold on a phone) to unlock early
	do
		-- wx is the wall's inner face; everything sits in front of it, above the chair rail and clear of the potted bush
		local wx = W / 2 - 1.0
		local uz = FRONT + 8.5
		local panel = part(model, {Name = "UnlockPanel", Size = Vector3.new(0.4, 4.2, 3.6), CFrame = at(wx - 0.35, 8.4, uz), Color = rgb(40, 40, 55)})
		part(model, {Name = "UnlockPanelTrim", Size = Vector3.new(0.3, 4.8, 4.2), CFrame = at(wx - 0.15, 8.4, uz), Color = rgb(255, 255, 255)})
		local btn = part(model, {Name = "UnlockButton", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.2, 2.2), CFrame = at(wx - 0.75, 8.7, uz), Color = rgb(70, 220, 110), Material = M.Neon})
		local sign = part(model, {Name = "UnlockSign", Size = Vector3.new(0.2, 0.9, 3.4), CFrame = at(wx - 0.65, 7.0, uz), Color = rgb(40, 40, 55)})
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Left
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.Parent = sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = "UNLOCK"
		t.Parent = sg
		plot.UnlockButton = btn
		plot.UnlockPrompt = Kit.prompt(btn, "Hold to Unlock", "Base Lock", 1.5, 8, "OwnerOnlyPrompt")
		plot.UnlockPrompt.MaxActivationDistance = 0 -- turned on only while the base is locked
	end

	-- Treadmill prompts live on an invisible part that never gets rebuilt
	local treadAnchor = part(model, {Name = "TreadmillAnchor", Size = Vector3.new(1, 1, 1), CFrame = plot.TreadCF * CFrame.new(0, 3, -10), Transparency = 1, CanCollide = false})
	plot.RunPrompt = Kit.prompt(treadAnchor, "Run on Treadmill", "Treadmill", 0, 9)
	plot.TreadUpgradePrompt = Kit.prompt(treadAnchor, "Upgrade Treadmill", "Treadmill", 0.3, 9)
	plot.TreadUpgradePrompt.KeyboardKeyCode = Enum.KeyCode.F
	plot.TreadUpgradePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	plot.TreadUpgradePrompt.UIOffset = Vector2.new(0, 70)
	local treadLabelPart = part(model, {Name = "TreadmillLabel", Size = Vector3.new(1, 1, 1), CFrame = plot.TreadCF * CFrame.new(0, 6.5, -17.5), Transparency = 1, CanCollide = false})
	plot.TreadLabel = Kit.billboard(treadLabelPart, 260, 64, 1, "TREADMILL", 90)

	Base.setTier(plot, 1)
	return plot
end

------------------------------------------------------------------
-- UPPER FLOORS (with stairs up the side of the base)
------------------------------------------------------------------
local function buildFloor(plot, f)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local W, D = C.PLOT_W, plot.D
	local L = plot.Look
	local y0 = floorY(f)
	local at = function(x, y, z) return plot.CF * CFrame.new(x, y, z) end
	local accent = plot.Accent
	local MID, BACK = midZ(plot), backZ(plot)

	local model = Instance.new("Model")
	model.Name = "Floor" .. f
	model.Parent = plot.Model

	part(model, {Name = "Slab", Size = Vector3.new(W, 1, D), CFrame = at(0, y0 + 0.5, MID), Color = L.Floor, Material = L.FloorMat})
	part(model, {Name = "SlabEdge", Size = Vector3.new(W + 0.6, 0.5, 0.6), CFrame = at(0, y0 + 0.2, FRONT), Color = accent, Material = M.SmoothPlastic})
	local runLen = D - 24
	part(model, {Name = "Runner", Size = Vector3.new(12, 0.08, runLen), CFrame = at(0, y0 + 1.04, FRONT + 20 + runLen / 2), Color = accent:Lerp(Color3.new(1, 1, 1), 0.15), Material = M.Fabric, CanCollide = false})
	part(model, {Name = "Railing", Size = Vector3.new(W - 2, 3.5, 0.4), CFrame = at(0, y0 + 2.75, FRONT + 0.4), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
	part(model, {Name = "RailTop", Size = Vector3.new(W - 2, 0.4, 0.6), CFrame = at(0, y0 + 4.6, FRONT + 0.4), Color = L.Trim, Material = L.TrimMat})
	-- Open the doorway on the floor below that leads out to these stairs
	local below = plot.FloorModels[f - 1]
	if below then
		for _, d in ipairs(below:GetChildren()) do
			if d.Name == "StairGapPanel" then
				d:Destroy()
			end
		end
	end
	-- Lock wall across this floor's doorway (stairs stay walkable)
	do
		local s = stairSide(f)
		part(model, {Name = "DoorBarrier", Size = Vector3.new(0.6, 14, GAP_Z2 - GAP_Z1), CFrame = at(s * (W / 2 - 0.5), y0 + 8, (GAP_Z1 + GAP_Z2) / 2), Color = rgb(255, 40, 40), Material = M.Neon, Transparency = 1, CanCollide = false})
	end
	local floorSign = part(model, {Name = "FloorSign", Size = Vector3.new(12, 2.4, 0.3), CFrame = at(0, y0 + 18.2, BACK - 1.2), Color = rgb(25, 25, 32)})
	Kit.surfaceText(floorSign, Enum.NormalId.Front, "FLOOR " .. f, accent, 30)

	buildWalls(model, plot, f)

	-- The floor below has 14-stud walls but floors are FLOOR_H apart: close that strip up to this slab
	-- (outer half of the wall only, so signs on the inside face stay visible), or thieves can climb
	-- these stairs and slip over the wall into the locked floor below
	do
		local fillH = C.FLOOR_H - 15
		local fy = floorY(f - 1) + 15 + fillH / 2
		part(model, {Name = "WallFill", Size = Vector3.new(W, fillH, 0.5), CFrame = at(0, fy, BACK - 0.25), Color = L.Wall, Material = L.WallMat})
		for _, side in ipairs({-1, 1}) do
			part(model, {Name = "WallFill", Size = Vector3.new(0.5, fillH, D), CFrame = at(side * (W / 2 - 0.25), fy, MID), Color = L.Wall, Material = L.WallMat})
		end
		if f == 2 then
			-- above the entrance arch
			part(model, {Name = "WallFill", Size = Vector3.new(W, C.FLOOR_H - 17.6, 0.5), CFrame = at(0, (17.6 + C.FLOOR_H) / 2, FRONT), Color = L.Trim, Material = L.TrimMat})
		end
	end

	-- Stairs from floor f-1 up to floor f, on the outside of one side wall
	local s = stairSide(f)
	local sx = s * (W / 2 + 4.5)
	local yb = floorY(f - 1) + 1
	local rise = C.FLOOR_H
	local run = STAIR_Z1 - STAIR_Z0
	local steps = 20
	for i = 1, steps do
		local z = STAIR_Z0 + (i - 0.5) * run / steps
		part(model, {Name = "Step", Size = Vector3.new(7, 0.8, run / steps + 0.1), CFrame = at(sx, yb + i * rise / steps - 0.4, z), Color = i % 2 == 0 and L.Trim or L.Wainscot, Material = M.SmoothPlastic, CanCollide = false})
	end
	Kit.wedge(model, {Name = "StairRamp", Size = Vector3.new(7, rise, run), CFrame = at(sx, yb + rise / 2, (STAIR_Z0 + STAIR_Z1) / 2), Transparency = 1})
	local angle = math.atan2(rise, run)
	local railLen = math.sqrt(rise ^ 2 + run ^ 2)
	part(model, {Name = "StairRail", Size = Vector3.new(0.4, 0.4, railLen), CFrame = at(sx + s * 3.6, yb + rise / 2 + 3, (STAIR_Z0 + STAIR_Z1) / 2) * CFrame.Angles(-angle, 0, 0), Color = L.Trim, Material = L.TrimMat})
	part(model, {Name = "StairSide", Size = Vector3.new(0.6, 1.2, railLen), CFrame = at(sx + s * 3.6, yb + rise / 2 - 0.4, (STAIR_Z0 + STAIR_Z1) / 2) * CFrame.Angles(-angle, 0, 0), Color = accent, Material = M.SmoothPlastic})
	part(model, {Name = "Landing", Size = Vector3.new(9.5, 1, GAP_Z2 - STAIR_Z1 + 1), CFrame = at(s * (W / 2 + 4.25), y0 + 0.5, (STAIR_Z1 + GAP_Z2) / 2), Color = L.Wainscot, Material = M.SmoothPlastic})
	part(model, {Name = "LandingRail", Size = Vector3.new(0.4, 3.5, GAP_Z2 - STAIR_Z1 + 1), CFrame = at(s * (W / 2 + 8.8), y0 + 2.75, (STAIR_Z1 + GAP_Z2) / 2), Color = rgb(200, 230, 255), Material = M.Glass, Transparency = 0.6})
	if f >= 3 then
		part(model, {Name = "LowerLanding", Size = Vector3.new(10, 1, 14), CFrame = at(s * (W / 2 + 4.5), yb - 0.5, FRONT), Color = L.Wainscot, Material = M.SmoothPlastic})
	end

	plot.FloorModels[f] = model
end

------------------------------------------------------------------
-- DISPLAY CASES
------------------------------------------------------------------
local function buildCase(plot, slotIndex, callbacks)
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local per = plot.PerFloor
	local f = math.ceil(slotIndex / per)
	local p = (slotIndex - 1) % per + 1
	local sx, lcf = Base.caseLocal(f, p)
	local cf = plot.CF * lcf
	local accent = plot.Accent
	local L = plot.Look

	local model = Instance.new("Model")
	model.Name = "Case" .. slotIndex
	model.Parent = plot.FloorModels[f] or plot.Model

	local ped = part(model, {Name = "Pedestal", Size = Vector3.new(5.5, 2, 5.5), CFrame = cf, Color = L.Pedestal, Material = M.Marble})
	part(model, {Name = "CaseBase", Size = Vector3.new(5.9, 0.3, 5.9), CFrame = cf * CFrame.new(0, 1.15, 0), Color = accent:Lerp(Color3.new(0, 0, 0), 0.15), Material = M.SmoothPlastic})
	part(model, {Name = "CaseGlass", Size = Vector3.new(5.3, 6.4, 5.3), CFrame = cf * CFrame.new(0, 4.5, 0), Color = rgb(220, 240, 255), Material = M.SmoothPlastic, Transparency = 0.9, Reflectance = 0.1, CanCollide = false})
	for _, cx in ipairs({-2.7, 2.7}) do
		for _, cz in ipairs({-2.7, 2.7}) do
			part(model, {Name = "CasePost", Size = Vector3.new(0.3, 6.4, 0.3), CFrame = cf * CFrame.new(cx, 4.5, cz), Color = L.Trim, Material = M.Metal})
		end
	end
	local lid = part(model, {Name = "CaseLid", Size = Vector3.new(5.8, 0.3, 5.8), CFrame = cf * CFrame.new(0, 7.85, 0), Color = L.Trim, Material = M.Metal})
	local light = Instance.new("PointLight")
	light.Range = 6
	light.Brightness = 0.35
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
		-- the cover faces into the aisle
		ItemCF = cf * CFrame.new(0, 3.8, 0) * CFrame.Angles(0, sx * math.pi / 2, 0),
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
	-- keep the owner's name above the top floor so the railing never hides it
	if plot.SignPart then
		plot.SignPart.CFrame = plot.CF * CFrame.new(0, 20 + (floors - 1) * C.FLOOR_H + 2, FRONT)
	end
end

------------------------------------------------------------------
-- UPGRADE SPOTS: glowing outlines where future cases go (the next one can
-- be bought right there), ghost stairs for the next floor, or a big
-- "UPGRADE BASE" spot when both floors are full.
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

	for i = plot.Cases + 1, plot.Floors * plot.PerFloor do
		local f = math.ceil(i / plot.PerFloor)
		local p = (i - 1) % plot.PerFloor + 1
		local _, lcf = Base.caseLocal(f, p)
		local cf = plot.CF * lcf
		local isNext = (i == plot.Cases + 1) and nextKind == "case"
		local color = isNext and Kit.GOLD or rgb(130, 130, 150)
		local pad = part(model, {Name = "CaseSpot", Size = Vector3.new(5.6, 0.2, 5.6), CFrame = cf * CFrame.new(0, -0.9, 0), Color = color, Material = isNext and M.Neon or M.SmoothPlastic, Transparency = isNext and 0.45 or 0.7, CanCollide = false})
		part(model, {Name = "CaseGhost", Size = Vector3.new(5.3, 7.5, 5.3), CFrame = cf * CFrame.new(0, 2.85, 0), Color = color, Material = M.ForceField, Transparency = isNext and 0.45 or 0.75, CanCollide = false, CanQuery = false})
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
	elseif nextKind == "tier" then
		-- Big glowing spot in the middle aisle of the ground floor
		local nextTier = C.BASE_TIERS[plot.Tier + 1]
		local spotCF = plot.CF * CFrame.new(0, 1.15, caseZ(2))
		local spot = part(model, {Name = "TierSpot", Size = Vector3.new(10, 0.3, 10), CFrame = spotCF, Color = Kit.GOLD, Material = M.Neon, Transparency = 0.15, CanCollide = false})
		part(model, {Name = "TierBeam", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 6, 6), CFrame = spotCF * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Kit.GOLD, Material = M.ForceField, Transparency = 0.3, CanCollide = false, CanQuery = false})
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = Kit.GOLD
		sp.Parent = spot
		Kit.billboard(spot, 340, 110, 9, string.format('<font color="#ffd23c">UPGRADE BASE</font>\n%s\n%s', string.upper(nextTier.Name), costText), 220)
		buyPrompt(spot, "Upgrade to " .. nextTier.Name .. " (" .. costText .. ")", "Base Upgrade", 12)
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
	-- one piece per level (C.TREAD_FEATURES); a piece stays once it's been added
	local function has(piece)
		return level >= C.TREAD_FEATURES[piece]
	end
	local fam = math.clamp(math.floor(level / C.TREAD_LEVELS_PER_TIER) + 1, 1, #C.TREAD_TIERS)
	local A, F, FM = tier.Accent, tier.Frame, tier.FrameMat
	local glowMat = tier.AccentMat == M.Neon and M.Neon or M.SmoothPlastic
	local white = Color3.new(1, 1, 1)
	local gold = rgb(255, 205, 70)
	-- pillars, beams and pylons (40: the whole structure turns to gold)
	local stone = has("Max") and gold or F:Lerp(Color3.new(0, 0, 0), 0.15)
	local SM = has("Max") and M.Foil or FM
	local wide = has("WideFrame") and 1 or 0
	local edgeX = 3.9 + wide / 2 -- the belt's side skirts
	local postX = 4.9 + wide / 2 -- the arch and rear gate pillars
	local gateH = 9 + fam * 0.6
	local top = 1 + gateH + 0.2 -- the arch beam (and canopy) height
	local ph = 3 + fam * 0.3 -- pylon height
	-- decorations never block anyone walking past
	local function deco(props)
		props.CanCollide = false
		return part(model, props)
	end
	local function glow(props)
		props.Material = props.Material or M.Neon
		props.Color = props.Color or A
		return deco(props)
	end
	-- a ring of 16 glowing segments: facing along the belt ("Z") or lying flat ("Y")
	local function ring(name, center, radius, axis, color, thick, transparency)
		local seg = 2 * math.pi * radius / 16 * 1.08
		for k = 0, 15 do
			local a = k / 16 * math.pi * 2
			local cf = axis == "Z" and center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a)
				or center * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -a, 0)
			glow({Name = name, Size = axis == "Z" and Vector3.new(thick, seg, thick) or Vector3.new(thick, thick, seg), CFrame = cf, Color = color, Transparency = transparency or 0})
		end
	end

	---------------------------------------------------------------- the machine every level has
	part(model, {Name = "Frame", Size = Vector3.new(7.4 + wide, 0.7, 14.5), CFrame = at(0, 1.35, -10), Color = F, Material = FM})
	for _, sx in ipairs({-1, 1}) do
		part(model, {Name = "Skirt", Size = Vector3.new(0.8, 1.1, 14.5), CFrame = at(sx * edgeX, 1.55, -10), Color = F:Lerp(Color3.new(0, 0, 0), 0.25), Material = FM})
		deco({Name = "BeltEdge", Size = Vector3.new(0.25, 0.12, 13.6), CFrame = at(sx * 3.15, Base.BELT_TOP + 0.02, -10), Color = A, Material = glowMat})
	end
	plot.Slats = {}
	for i = 1, SLAT_COUNT do
		local slatColor = (i % 2 == 0) and A:Lerp(Kit.DARK, 0.7) or rgb(22, 22, 28)
		table.insert(plot.Slats, part(model, {Name = "Slat", Size = Vector3.new(6, 0.3, SLAT_GAP - 0.1), CFrame = at(0, Base.BELT_TOP - 0.15, -16 + (i - 1) * SLAT_GAP), Color = slatColor, Material = M.Fabric}))
	end
	local console = part(model, {Name = "Console", Size = Vector3.new(6, 3.5, 1), CFrame = at(0, 2.85, -17.6), Color = F, Material = FM})
	deco({Name = "Screen", Size = Vector3.new(4, 1.4, 0.2), CFrame = at(0, 3.4, -17.05), Color = A:Lerp(rgb(80, 170, 255), 0.4), Material = M.Neon})
	local n = C.TREAD_MAX_LEVEL
	local spacing = 5.4 / n
	for i = 1, n do
		local lit = i <= level
		deco({Name = "Meter", Size = Vector3.new(spacing * 0.7, 0.5, 0.15), CFrame = at(-2.7 + (i - 0.5) * spacing, 2.2, -16.95), Color = lit and A or rgb(40, 40, 45), Material = lit and M.Neon or M.SmoothPlastic})
	end
	local neonRails = has("NeonRails")
	for _, sx in ipairs({-1, 1}) do
		local railW = neonRails and 0.6 or 0.45
		local rail = deco({Name = "Rail", Size = Vector3.new(railW, railW, 9), CFrame = at(sx * 3.5, 4.4, -12), Color = A, Material = neonRails and M.Neon or tier.AccentMat})
		part(model, {Name = "RailPost", Size = Vector3.new(0.45, 2.8, 0.45), CFrame = at(sx * 3.5, 3, -16.2), Color = F, Material = FM})
		if neonRails then
			glow({Name = "RailCap", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = at(sx * 3.5, 4.4, -7.4)})
		end
		if has("PlasmaRails") then
			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(A, white)
			sparks.LightEmission = 1
			sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
			sparks.Lifetime = NumberRange.new(0.3, 0.7)
			sparks.Speed = NumberRange.new(1, 4)
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.Rate = 40
			sparks.Parent = rail
			-- the rails themselves run white-hot inside a coloured glow
			rail.Color = A:Lerp(white, 0.6)
			glow({Name = "RailGlow", Size = Vector3.new(1.1, 1.1, 9.2), CFrame = at(sx * 3.5, 4.4, -12), Transparency = 0.7})
		end
	end
	if fam >= 3 then
		local light = Instance.new("PointLight")
		light.Color = A
		light.Range = 14
		light.Brightness = 1.5
		light.Parent = console
	end

	---------------------------------------------------------------- one new piece per level
	if has("SideGuards") then -- 1: panels along both sides of the belt
		for _, sx in ipairs({-1, 1}) do
			deco({Name = "Guard", Size = Vector3.new(0.3, 1.6, 10), CFrame = at(sx * (edgeX + 0.25), 2.9, -10.5), Color = F:Lerp(white, 0.15), Material = FM})
			deco({Name = "GuardStripe", Size = Vector3.new(0.35, 0.2, 10), CFrame = at(sx * (edgeX + 0.25), 3.75, -10.5), Color = A, Material = glowMat})
		end
	end
	if has("BigScreen") then -- 2: a big tilted screen over the console showing your level
		local tilt = at(0, 6.1, -17.6) * CFrame.Angles(math.rad(-12), 0, 0)
		part(model, {Name = "ScreenBezel", Size = Vector3.new(5.4, 3, 0.4), CFrame = tilt, Color = F, Material = FM})
		local screen = glow({Name = "BigScreen", Size = Vector3.new(4.8, 2.4, 0.1), CFrame = tilt * CFrame.new(0, 0, 0.22), Color = A:Lerp(rgb(30, 60, 120), 0.55)})
		local t = Kit.surfaceText(screen, Enum.NormalId.Back, "LV " .. level, white, 40)
		t.TextStrokeTransparency = 1
	end
	if has("Arch") then -- 3: the gateway arch over the front of the belt
		for _, sx in ipairs({-1, 1}) do
			local x = sx * postX
			part(model, {Name = "GatePillar", Size = Vector3.new(1.8, gateH, 1.8), CFrame = at(x, 1 + gateH / 2, -16.4), Color = stone, Material = SM})
			part(model, {Name = "GateBase", Size = Vector3.new(2.6, 1.2, 2.6), CFrame = at(x, 1.6, -16.4), Color = stone:Lerp(Color3.new(0, 0, 0), 0.2), Material = SM})
			deco({Name = "GateStrip", Size = Vector3.new(0.3, gateH - 2, 0.3), CFrame = at(x - sx * 0.95, 1 + gateH / 2, -15.5), Color = A, Material = glowMat})
		end
		part(model, {Name = "GateBeam", Size = Vector3.new(11.6 + wide, 1.6, 2.2), CFrame = at(0, top, -16.4), Color = stone, Material = SM})
		local plaque = deco({Name = "GatePlaque", Size = Vector3.new(7, 1.2, 0.2), CFrame = at(0, top, -15.25) * CFrame.Angles(0, math.pi, 0), Color = A:Lerp(Color3.new(0, 0, 0), 0.6)})
		local pt = Kit.surfaceText(plaque, Enum.NormalId.Front, string.upper(tier.Name), A:Lerp(white, 0.3), 30)
		pt.TextStrokeTransparency = 1
	end
	if has("ArchOrbs") then -- 4: glowing orbs on the arch pillars
		for _, sx in ipairs({-1, 1}) do
			local orb = glow({Name = "GateOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), CFrame = at(sx * postX, 2 + gateH, -16.4)})
			local l = Instance.new("PointLight")
			l.Color = A
			l.Range = 9
			l.Brightness = 0.8 + fam * 0.15
			l.Shadows = false
			l.Parent = orb
			if has("Max") then -- 40: the orbs burn
				local fire = Instance.new("Fire")
				fire.Color = gold
				fire.SecondaryColor = A
				fire.Size = 4
				fire.Heat = 6
				fire.Parent = orb
			end
		end
	end
	if has("RearRoller") then -- 5: a big roller and step at the back of the belt
		glow({Name = "RearRoller", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7.6 + wide, 1.2, 1.2), CFrame = at(0, 1.55, -2.6), Material = glowMat})
		part(model, {Name = "RearStep", Size = Vector3.new(7.4 + wide, 0.4, 1.4), CFrame = at(0, 1.1, -1.6), Color = stone, Material = FM})
	end
	local pylonZ = {}
	if has("Pylons") then -- 6: pylons with glowing panels beside the runner (12: a second pair further back)
		table.insert(pylonZ, -11)
	end
	if has("RearPylons") then
		table.insert(pylonZ, -5.5)
	end
	for _, sx in ipairs({-1, 1}) do
		for _, z in ipairs(pylonZ) do
			local px = sx * (5.4 + wide / 2)
			part(model, {Name = "Pylon", Size = Vector3.new(1.2, ph, 1.2), CFrame = at(px, 1 + ph / 2, z), Color = stone, Material = SM})
			glow({Name = "PylonGlow", Size = Vector3.new(0.4, 1.2, 0.8), CFrame = at(px + sx * 0.65, 1 + ph * 0.6, z)})
			if has("PylonCrystals") then -- 18: a crystal floats on every pylon
				glow({Name = "Crystal", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = at(px, 1 + ph + 1, z) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Material = M.Glass, Transparency = 0.15, Color = A:Lerp(white, 0.3)})
			end
			if has("LightBeams") then -- 29: beams of light shoot up from the pylons
				glow({Name = "LightBeam", Size = Vector3.new(0.5, 14, 0.5), CFrame = at(px, 1 + ph + 8.5, z), Transparency = 0.55})
			end
		end
	end
	if has("DeckRunes") then -- 7: glowing symbols on the belt deck
		local deck = deco({Name = "Deck", Size = Vector3.new(6, 0.05, 12.4), CFrame = at(0, Base.BELT_TOP + 0.05, -10), Transparency = 1})
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 20
		sg.LightInfluence = 0
		sg.Parent = deck
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Arcade
		label.TextScaled = true
		label.TextColor3 = A
		label.TextTransparency = 0.35
		label.Text = (fam % 2 == 1) and "1 0 1 1\n0 1 1 0\n1 1 0 1\n0 1 0 1" or "\u{2726} \u{25C7} \u{2726}\n\u{25C7} \u{2726} \u{25C7}\n\u{2726} \u{25C7} \u{2726}"
		label.Parent = sg
	end
	if has("RearGate") then -- 8: a second gate at the back, framing the runner
		for _, sx in ipairs({-1, 1}) do
			local x = sx * postX
			part(model, {Name = "RearPillar", Size = Vector3.new(1.4, gateH, 1.4), CFrame = at(x, 1 + gateH / 2, -3.2), Color = stone, Material = SM})
			deco({Name = "RearStrip", Size = Vector3.new(0.3, gateH - 2, 0.3), CFrame = at(x - sx * 0.75, 1 + gateH / 2, -2.45), Color = A, Material = glowMat})
		end
		part(model, {Name = "RearBeam", Size = Vector3.new(11 + wide, 1.2, 1.6), CFrame = at(0, top, -3.2), Color = stone, Material = SM})
	end
	if has("Canopy") then -- 9: beams joining the two gates, with glowing ribs across
		for _, sx in ipairs({-1, 1}) do
			part(model, {Name = "CanopyBeam", Size = Vector3.new(0.9, 0.9, 13.2), CFrame = at(sx * postX, top, -9.8), Color = stone, Material = SM})
		end
		for _, z in ipairs({-13, -9.8, -6.6}) do
			glow({Name = "CanopyRib", Size = Vector3.new(postX * 2, 0.5, 0.5), CFrame = at(0, top + 0.2, z), Material = glowMat})
		end
	end
	if has("WideFrame") then -- 10: a wider frame (above), and a glowing outline round the pad
		for _, sx in ipairs({-1, 1}) do
			glow({Name = "PadGlow", Size = Vector3.new(0.3, 0.12, 22.4), CFrame = at(sx * 6.2, 1.06, -10.5)})
		end
		for _, z in ipairs({-21.7, 0.7}) do
			glow({Name = "PadGlow", Size = Vector3.new(12.4, 0.12, 0.3), CFrame = at(0, 1.06, z)})
		end
	end
	-- 13, 19, 26: rings around the runner, one more each time
	for i, piece in ipairs({"Ring1", "Ring2", "Ring3"}) do
		if has(piece) then
			ring("Ring", at(0, 6.3, ({-8, -12.5, -4.6})[i]), 5.2, "Z", A, 0.35, 0.15)
		end
	end
	if has("Spotlights") then -- 14: big floodlights on the arch pillars, shining back at the runner
		for _, sx in ipairs({-1, 1}) do
			-- a cylinder points along X; turned a quarter round Y it faces along the belt, its -X end (Left) toward the runner
			local aim = at(sx * 3.5, 1 + gateH * 0.72, -15) * CFrame.Angles(0, math.pi / 2, 0)
			local lamp = deco({Name = "Floodlight", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 1.7, 1.7), CFrame = aim, Color = stone, Material = M.Metal})
			glow({Name = "FloodLens", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.4, 1.4), CFrame = aim * CFrame.new(-0.52, 0, 0), Color = A:Lerp(white, 0.6)})
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Left
			spot.Color = A:Lerp(white, 0.4)
			spot.Angle = 70
			spot.Range = 20
			spot.Brightness = 3
			spot.Parent = lamp
		end
	end
	if has("Fins") then -- 15: fins on both sides (27: much bigger)
		local big = has("BigFins")
		for _, sx in ipairs({-1, 1}) do
			Kit.wedge(model, {Name = "Fin", Size = big and Vector3.new(0.5, 5.5, 8) or Vector3.new(0.4, 3.4, 5), CFrame = at(sx * (6.2 + wide / 2), big and 3.75 or 2.7, -8.3) * CFrame.Angles(0, math.pi, 0), Color = A, Material = M.Neon, CanCollide = false})
		end
	end
	if has("HoloSign") then -- 16: a floating sign over the arch with the treadmill's name
		local sign = glow({Name = "HoloSign", Size = Vector3.new(5, 1.8, 0.2), CFrame = at(0, top + 3, -16.4), Material = M.Glass, Transparency = 0.35, Color = A:Lerp(Color3.new(0, 0, 0), 0.3)})
		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local t = Kit.surfaceText(sign, face, has("Max") and "MAX" or ("LV " .. level), has("Max") and gold or white, 40)
			t.TextStrokeTransparency = 0.6
		end
	end
	if has("Banners") then -- 17: banners hanging from the canopy
		for _, sx in ipairs({-1, 1}) do
			for _, z in ipairs({-12.4, -7.2}) do
				deco({Name = "Banner", Size = Vector3.new(0.12, 3, 1.6), CFrame = at(sx * postX, top - 2.1, z), Color = A, Material = M.Fabric})
				glow({Name = "BannerTip", Size = Vector3.new(0.16, 0.25, 1.6), CFrame = at(sx * postX, top - 3.55, z), Color = has("GoldTrim") and gold or A:Lerp(white, 0.4)})
			end
		end
	end
	if has("GoldTrim") then -- 20: gold trim along the frame, and sparkles
		for _, sx in ipairs({-1, 1}) do
			deco({Name = "GoldTrim", Size = Vector3.new(0.25, 0.25, 14.5), CFrame = at(sx * (edgeX + 0.45), 2.15, -10), Color = gold, Material = M.Foil})
		end
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = A
		sparkles.Parent = console
	end
	if has("ArchCrown") then -- 21: spires on the arch beam
		for _, x in ipairs({-3.3, -1.6, 1.6, 3.3}) do
			local h = math.abs(x) > 2 and 2.4 or 1.2
			deco({Name = "Spire", Size = Vector3.new(0.6, h, 0.6), CFrame = at(x, top + 0.8 + h / 2, -16.4), Color = stone, Material = FM})
			glow({Name = "SpireTip", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), CFrame = at(x, top + 0.8 + h, -16.4), Color = has("GoldTrim") and gold or A})
		end
	end
	if has("RearWings") then -- 22: wings flaring out from the rear gate
		for _, sx in ipairs({-1, 1}) do
			Kit.wedge(model, {Name = "RearWing", Size = Vector3.new(0.4, 4, 3), CFrame = at(sx * (postX + 1.9), 1 + gateH * 0.62, -3.2) * CFrame.Angles(0, sx * math.pi / 2, 0), Color = A, Material = M.Neon, CanCollide = false})
		end
	end
	if has("StartPad") then -- 23: a glowing start pad behind the belt
		glow({Name = "StartPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 3.2, 3.2), CFrame = at(0, 1.05, -0.4) * CFrame.Angles(0, 0, math.pi / 2), Color = A:Lerp(white, 0.2)})
	end
	if has("TwinScreens") then -- 24: two big screens on the rear gate, facing the runner's camera
		for _, sx in ipairs({-1, 1}) do
			part(model, {Name = "ScreenFrame", Size = Vector3.new(3, 1.9, 0.3), CFrame = at(sx * 3.1, top + 1.55, -3.2), Color = stone, Material = SM, CanCollide = false})
			local screen = glow({Name = "RearScreen", Size = Vector3.new(2.6, 1.5, 0.1), CFrame = at(sx * 3.1, top + 1.55, -3.0), Color = A:Lerp(rgb(30, 60, 120), 0.45)})
			local t = Kit.surfaceText(screen, Enum.NormalId.Back, sx < 0 and "LV " .. level or "\u{1F45F}", white, 40)
			t.TextStrokeTransparency = 1
		end
	end
	if has("InnerArch") then -- 25: a glowing inner arch inside the big one
		local h = gateH - 2.5
		for _, sx in ipairs({-1, 1}) do
			glow({Name = "InnerArch", Size = Vector3.new(0.5, h, 0.5), CFrame = at(sx * (edgeX + 0.2), 1 + h / 2, -15.6)})
		end
		glow({Name = "InnerArch", Size = Vector3.new((edgeX + 0.2) * 2 + 0.5, 0.5, 0.5), CFrame = at(0, 1 + h, -15.6)})
	end
	if has("FloatOrbs") then -- 28: orbs floating over the canopy
		for _, sx in ipairs({-1, 1}) do
			for _, z in ipairs({-13, -6.6}) do
				glow({Name = "FloatOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(sx * 2.5, top + 1.4, z), Color = A:Lerp(white, 0.35)})
			end
		end
	end
	if has("Halo") then -- 30: a halo over the runner (38: a second, golden one above it)
		ring("Halo", at(0, top + 3.6, -9.8), 3.2, "Y", A, 0.4)
		if has("GoldHalo") then
			ring("Halo", at(0, top + 4.8, -9.8), 2.2, "Y", gold, 0.35)
		end
	end
	if has("AngelWings") then -- 31: big wings on the arch
		for _, sx in ipairs({-1, 1}) do
			for i = 0, 2 do
				Kit.wedge(model, {Name = "Wing", Size = Vector3.new(0.3, 4.6 - i * 1.1, 2.4), CFrame = at(sx * (postX + 1.6 + i * 1.3), 1 + gateH * 0.7 + i * 0.6, -16.4) * CFrame.Angles(0, sx * math.pi / 2, 0),
					Color = white:Lerp(A, 0.25 + i * 0.15), Material = M.Neon, CanCollide = false})
			end
		end
	end
	if has("Medallion") then -- 32: a star medallion on the back of the rear gate, facing the runner's camera
		local disc = glow({Name = "Medallion", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.8, 2.8), CFrame = at(0, top, -2.25) * CFrame.Angles(0, math.pi / 2, 0), Color = has("Max") and gold or A:Lerp(white, 0.2), Material = M.Foil})
		local t = Kit.surfaceText(disc, Enum.NormalId.Left, "\u{2605}", has("Max") and A or gold, 40)
		t.TextStrokeTransparency = 1
	end
	if has("Portal") then -- 34: a glowing portal behind the console
		glow({Name = "Portal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 9, 9), CFrame = at(0, 7, -20.2) * CFrame.Angles(0, math.pi / 2, 0), Transparency = 0.35, Color = A:Lerp(rgb(120, 60, 255), 0.4)})
		ring("PortalRim", at(0, 7, -20.1), 4.6, "Z", A:Lerp(white, 0.3), 0.4)
	end
	if has("Planets") then -- 35: little planets round the top of the arch
		for _, p in ipairs({{-6.4, 2.5, -18.5, 1.8, rgb(255, 140, 90)}, {6.6, 1.2, -14.5, 1.3, rgb(120, 200, 255)}, {-2.2, 6.4, -19, 2.4, rgb(200, 150, 255)}}) do
			deco({Name = "Planet", Shape = Enum.PartType.Ball, Size = Vector3.new(p[4], p[4], p[4]), CFrame = at(p[1], top + p[2], p[3]), Color = p[5], Material = M.SmoothPlastic})
		end
		ring("PlanetRing", at(-2.2, top + 6.4, -19) * CFrame.Angles(math.rad(20), 0, math.rad(15)), 1.9, "Y", rgb(230, 210, 255), 0.18, 0.2)
	end
	if has("Nebula") then -- 36: glowing cosmic clouds over the treadmill, with mist drifting from them
		for _, c in ipairs({{-3.5, 2.6, -13, 4.5, rgb(170, 90, 255)}, {3.2, 3.2, -8.5, 5.2, A}, {-1, 4.2, -5.6, 3.8, rgb(255, 120, 220)}}) do
			glow({Name = "NebulaCloud", Shape = Enum.PartType.Ball, Size = Vector3.new(c[4], c[4] * 0.6, c[4]), CFrame = at(c[1], top + c[2], c[3]), Color = c[5], Transparency = 0.72})
		end
		local cloud = deco({Name = "Nebula", Size = Vector3.new(10, 1, 13), CFrame = at(0, top + 2, -9.8), Transparency = 1})
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(A, rgb(170, 90, 255))
		e.LightEmission = 0.6
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 6)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 1)})
		e.Lifetime = NumberRange.new(3, 4)
		e.Speed = NumberRange.new(0.3, 0.8)
		e.Rate = 5
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Parent = cloud
	end
	if has("StarRoof") then -- 37: a glass roof full of stars
		local roof = deco({Name = "StarRoof", Size = Vector3.new(postX * 2, 0.15, 13.2), CFrame = at(0, top + 0.55, -9.8), Color = F, Material = M.Glass, Transparency = 0.5})
		for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
			local t = Kit.surfaceText(roof, face, "\u{2726}  \u{00B7}  \u{2727}  \u{00B7}  \u{2726}\n\u{00B7}  \u{2727}  \u{00B7}  \u{2726}  \u{00B7}\n\u{2726}  \u{00B7}  \u{2727}  \u{00B7}  \u{2726}", A:Lerp(white, 0.5), 20)
			t.TextStrokeTransparency = 1
		end
	end
	if has("Aurora") then -- 39: ribbons of light behind the portal
		local colors = {A, rgb(255, 120, 220), rgb(120, 255, 200), rgb(140, 160, 255)}
		for i, x in ipairs({-6, -2.4, 2.4, 6}) do
			glow({Name = "Aurora", Size = Vector3.new(2.2, 14, 0.1), CFrame = at(x, 1 + 7 + (i % 2) * 1.5, -21.3) * CFrame.Angles(0, math.rad(i % 2 == 0 and 14 or -14), 0), Color = colors[i], Transparency = 0.5})
		end
	end
	plot.TreadLabel.Text = labelText
end

------------------------------------------------------------------
-- TOP 3 PODIUM
------------------------------------------------------------------
function Base.updatePodium(plot, top)
	for rank = 1, 3 do
		local spot = plot.Podium[rank]
		local g = top[rank]
		local key = g and (g.Name .. "|" .. g.IncomeText) or ""
		if spot and spot.Key ~= key then
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

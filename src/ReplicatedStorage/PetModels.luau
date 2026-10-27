--[[
	PetModels
	Builds every pet (and egg) out of soft rounded shapes: chibi proportions, big shiny eyes and rosy cheeks.
	The look comes from the pet's fields in PetData (body type, colours, ears, tail, wings, horns...).

	PetModels.build(pet)        -> a copy of the pet's premium model (ReplicatedStorage.PetAssets), Root at the origin
	PetModels.egg(egg)           -> a copy of the egg's premium model (ReplicatedStorage.EggAssets, built by PetLab EggForge)
	The chibi builder below (BODY, addEffects) is no longer used; it goes in Phase 6 of docs/pets/INTEGRATION.md.
]]

local PetData = require(script.Parent:WaitForChild("PetData"))

local M = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE, DARK, PINK = Color3.new(1, 1, 1), rgb(35, 25, 30), rgb(255, 140, 165)
local IVORY, GOLD = rgb(245, 235, 210), rgb(255, 205, 60)
local A = CFrame.Angles

local function hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

-- One builder per pet: keeps the model, root and default material
local function newBuilder(name, mat)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide, root.CanQuery, root.CanTouch = false, false, false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	local b = {Model = model, Root = root, Mat = mat}
	-- an ellipsoid (a block with a sphere mesh stretches to any size, unlike a Ball part)
	function b.E(size, cf, color, props)
		props = props or {}
		local p = Instance.new("Part")
		p.Name = props.Name or "Piece"
		p.Size = Vector3.new(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
		p.CFrame = cf
		p.Color = color
		p.Material = props.Mat or b.Mat or Enum.Material.SmoothPlastic
		p.Transparency = props.T or 0
		p.Reflectance = props.Refl or 0
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Massless = true
		p.Anchored = false
		if props.Block then
			-- plain box
		elseif props.Wedge then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Wedge
			mesh.Parent = p
		else
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		p.Parent = model
		return p
	end
	return b
end

local function at(x, y, z)
	return CFrame.new(x, y, z)
end

-- a flat spot lying on an ellipsoid's surface (dir is a direction from its centre)
local function surfaceSpot(b, center, radii, dir, size, color, props)
	dir = dir.Unit
	local pos = center + Vector3.new(dir.X * radii.X, dir.Y * radii.Y, dir.Z * radii.Z) * 0.5
	local normal = Vector3.new(dir.X / radii.X, dir.Y / radii.Y, dir.Z / radii.Z).Unit
	return b.E(size, CFrame.lookAt(pos, pos + normal), color, props)
end

------------------------------------------------------------------
-- FACES
------------------------------------------------------------------
local function face(b, pet, x, y, fz, s)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local eyes = pet.Eyes
	if pet.Mask then
		b.E(Vector3.new(1.05, 0.34, 0.12) * s, at(x, y + 0.08 * s, fz + 0.05 * s), c3)
	end
	if pet.Patches then
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.42, 0.52, 0.12) * s, at(x + sx * 0.3 * s, y + 0.05 * s, fz + 0.04 * s) * A(0, 0, sx * 0.45), c3)
		end
	end
	if pet.Face then
		b.E(Vector3.new(1.05, 0.95, 0.24) * s, at(x, y - 0.06 * s, fz + 0.08 * s), c2)
	end
	if pet.Markings then
		b.E(Vector3.new(0.12, 0.34, 0.06) * s, at(x, y + 0.48 * s, fz + 0.12 * s), pet.Markings, {Mat = Enum.Material.Neon})
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.3, 0.07, 0.06) * s, at(x + sx * 0.55 * s, y - 0.05 * s, fz + 0.15 * s) * A(0, 0, sx * 0.3), pet.Markings, {Mat = Enum.Material.Neon})
		end
	end
	-- eyes
	local ew, eh = 0.26, 0.36
	if eyes == "big" then
		ew, eh = 0.38, 0.46
	elseif eyes == "alien" then
		ew, eh = 0.42, 0.55
	end
	for _, sx in ipairs({-1, 1}) do
		local ex, ey = x + sx * 0.3 * s, y + 0.1 * s
		if eyes == "top" then
			-- frog eyes sitting on top of the head
			b.E(Vector3.new(0.5, 0.5, 0.5) * s, at(x + sx * 0.42 * s, y + 0.58 * s, fz + 0.4 * s), c1)
			b.E(Vector3.new(0.3, 0.34, 0.12) * s, at(x + sx * 0.42 * s, y + 0.62 * s, fz + 0.18 * s), DARK)
			b.E(Vector3.new(0.1, 0.12, 0.05) * s, at(x + sx * 0.42 * s + 0.06 * s, y + 0.7 * s, fz + 0.12 * s), WHITE, {Mat = Enum.Material.Neon})
		elseif eyes == "glow" then
			b.E(Vector3.new(ew, eh * 0.8, 0.12) * s, at(ex, ey, fz), c3, {Mat = Enum.Material.Neon})
			b.E(Vector3.new(0.08, 0.22, 0.05) * s, at(ex, ey, fz - 0.05 * s), DARK)
		else
			local rot = eyes == "alien" and A(0, 0, sx * -0.5) or CFrame.new()
			b.E(Vector3.new(ew, eh, 0.14) * s, at(ex, ey, fz) * rot, DARK)
			b.E(Vector3.new(0.11, 0.13, 0.05) * s, at(ex + 0.06 * s, ey + 0.09 * s, fz - 0.06 * s), WHITE, {Mat = Enum.Material.Neon})
			b.E(Vector3.new(0.05, 0.06, 0.04) * s, at(ex - 0.05 * s, ey - 0.07 * s, fz - 0.06 * s), WHITE, {Mat = Enum.Material.Neon})
		end
		-- rosy cheeks
		b.E(Vector3.new(0.26, 0.13, 0.06) * s, at(x + sx * 0.5 * s, y - 0.16 * s, fz + 0.13 * s), PINK, {T = 0.3})
	end
	-- snout / nose / mouth
	local sn = pet.Snout
	local noseC = DARK
	if sn == "long" then
		b.E(Vector3.new(0.62, 0.46, 0.6) * s, at(x, y - 0.2 * s, fz - 0.12 * s), c2)
		b.E(Vector3.new(0.22, 0.16, 0.14) * s, at(x, y - 0.08 * s, fz - 0.42 * s), noseC)
	elseif sn == "bear" then
		b.E(Vector3.new(0.6, 0.42, 0.36) * s, at(x, y - 0.22 * s, fz - 0.02 * s), c2)
		b.E(Vector3.new(0.22, 0.15, 0.12) * s, at(x, y - 0.14 * s, fz - 0.18 * s), noseC)
	elseif sn == "pig" or sn == "cow" or sn == "hippo" then
		local w = sn == "pig" and 0.5 or sn == "cow" and 0.78 or 1.0
		local col = sn == "hippo" and c2 or c3
		b.E(Vector3.new(w, w * 0.62, 0.3) * s, at(x, y - 0.24 * s, fz - 0.06 * s), col)
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.08, 0.12, 0.05) * s, at(x + sx * w * 0.22 * s, y - 0.22 * s, fz - 0.22 * s), DARK)
		end
	elseif sn == "croc" then
		b.E(Vector3.new(0.78, 0.42, 1.3) * s, at(x, y - 0.25 * s, fz - 0.5 * s), c1)
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.07, 0.06, 0.05) * s, at(x + sx * 0.12 * s, y - 0.06 * s, fz - 1.1 * s), DARK)
			for k = 0, 2 do
				b.E(Vector3.new(0.07, 0.14, 0.07) * s, at(x + sx * 0.36 * s, y - 0.44 * s, fz - (0.3 + k * 0.3) * s), WHITE)
			end
		end
	elseif sn == "trunk" then
		local pts = {{0, -0.2, -0.12, 0.42}, {0, -0.48, -0.3, 0.36}, {0, -0.78, -0.34, 0.31}, {0, -1.0, -0.24, 0.27}, {0, -1.1, -0.06, 0.22}}
		for _, p in ipairs(pts) do
			b.E(Vector3.new(p[4], p[4], p[4]) * s, at(x + p[1] * s, y + p[2] * s, fz + p[3] * s), c1)
		end
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.1, 0.5, 0.1) * s, at(x + sx * 0.32 * s, y - 0.5 * s, fz - 0.05 * s) * A(-0.6, 0, sx * 0.3), IVORY)
		end
	elseif sn == "beak" then
		b.E(Vector3.new(0.36, 0.32, 0.5) * s, at(x, y - 0.15 * s, fz - 0.15 * s), GOLD)
		b.E(Vector3.new(0.2, 0.22, 0.22) * s, at(x, y - 0.28 * s, fz - 0.36 * s), GOLD)
	elseif sn ~= "bird" and sn ~= "fish" and sn ~= "bug" then
		b.E(Vector3.new(0.17, 0.12, 0.1) * s, at(x, y - 0.12 * s, fz - 0.02 * s), noseC)
	end
	-- birds' beaks are their mouths
	if sn ~= "croc" and sn ~= "trunk" and sn ~= "beak" and sn ~= "bird" then
		b.E(Vector3.new(0.18, 0.07, 0.05) * s, at(x, y - 0.34 * s, fz + 0.02 * s), rgb(90, 40, 50))
	end
	if pet.Fangs or pet.Teeth then
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.07, 0.15, 0.06) * s, at(x + sx * 0.09 * s, y - 0.42 * s, fz - 0.02 * s), WHITE)
		end
	end
	if pet.Whiskers then
		for _, sx in ipairs({-1, 1}) do
			for k = -1, 1, 2 do
				b.E(Vector3.new(0.55, 0.03, 0.03) * s, at(x + sx * 0.55 * s, y - 0.2 * s + k * 0.05 * s, fz - 0.02 * s) * A(0, 0, sx * k * 0.15), DARK, {Block = true})
			end
		end
	end
end

-- ears, horns and hats for a head of size s centred at (x, y, z)
local function headTop(b, pet, x, y, z, s)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local ears = pet.Ears
	for _, sx in ipairs({-1, 1}) do
		if ears == "cat" or ears == "fennec" then
			local k = ears == "fennec" and 1.6 or 1
			local cf = at(x + sx * 0.44 * s, y + (0.6 + 0.12 * k) * s, z + 0.05 * s) * A(0, sx * math.pi / 2, sx * 0.2)
			b.E(Vector3.new(0.2, 0.55 * k, 0.48 * k) * s, cf, c1, {Wedge = true})
			b.E(Vector3.new(0.1, 0.36 * k, 0.3 * k) * s, cf * CFrame.new(0, -0.05 * s, 0) * CFrame.new(sx * 0.06 * s, 0, 0), PINK, {Wedge = true})
		elseif ears == "dog" then
			b.E(Vector3.new(0.34, 0.78, 0.46) * s, at(x + sx * 0.72 * s, y + 0.05 * s, z + 0.05 * s) * A(0, 0, sx * 0.35), c3)
		elseif ears == "bunny" then
			local cf = at(x + sx * 0.32 * s, y + 1.12 * s, z + 0.05 * s) * A(0, 0, sx * -0.12)
			b.E(Vector3.new(0.34, 1.15, 0.26) * s, cf, c1)
			b.E(Vector3.new(0.18, 0.82, 0.1) * s, cf * CFrame.new(0, 0, -0.1 * s), PINK)
		elseif ears == "round" then
			local col = pet.Patches and c3 or c1
			b.E(Vector3.new(0.5, 0.5, 0.26) * s, at(x + sx * 0.58 * s, y + 0.58 * s, z + 0.05 * s), col)
			b.E(Vector3.new(0.28, 0.28, 0.1) * s, at(x + sx * 0.58 * s, y + 0.56 * s, z - 0.06 * s), pet.Patches and DARK or PINK)
		elseif ears == "elephant" then
			local cf = at(x + sx * 0.88 * s, y + 0.05 * s, z + 0.18 * s) * A(0, sx * 0.4, 0)
			b.E(Vector3.new(0.16, 1.05, 0.95) * s, cf, c1)
			b.E(Vector3.new(0.08, 0.75, 0.65) * s, cf * CFrame.new(-sx * 0.04 * s, 0, -0.02 * s), c3)
		end
		-- horns
		local horns = pet.Horns
		if horns == "cow" then
			b.E(Vector3.new(0.2, 0.34, 0.2) * s, at(x + sx * 0.46 * s, y + 0.72 * s, z) * A(0, 0, -sx * 0.5), IVORY)
		elseif horns == "goat" or horns == "dragon" then
			local col = horns == "goat" and rgb(170, 155, 140) or IVORY
			-- curving up, then back over the head
			local path = {{0.36, 0.64, 0.05}, {0.42, 0.84, 0.25}, {0.46, 0.94, 0.5}, {0.48, 0.92, 0.72}}
			for k, pt in ipairs(path) do
				local sz = (0.27 - (k - 1) * 0.05) * s
				b.E(Vector3.new(sz, sz, sz * 1.3), at(x + sx * pt[1] * s, y + pt[2] * s, z + pt[3] * s), col)
			end
		elseif horns == "giraffe" then
			b.E(Vector3.new(0.12, 0.4, 0.12) * s, at(x + sx * 0.22 * s, y + 0.78 * s, z), c3)
			b.E(Vector3.new(0.2, 0.2, 0.2) * s, at(x + sx * 0.22 * s, y + 0.98 * s, z), c3)
		end
		if pet.Tufts then
			b.E(Vector3.new(0.18, 0.5, 0.2) * s, at(x + sx * 0.4 * s, y + 0.72 * s, z) * A(0, 0, -sx * 0.4), c1)
		end
		if pet.Gills then
			for k = -1, 1 do
				b.E(Vector3.new(0.12, 0.42, 0.12) * s, at(x + sx * 0.72 * s, y + (0.15 + k * 0.22) * s, z + 0.1 * s) * A(0, 0, -sx * (1 + k * 0.4)), c3)
			end
		end
	end
	if pet.Horn == "unicorn" then
		for k = 0, 3 do
			local sz = (0.26 - k * 0.055) * s
			b.E(Vector3.new(sz, sz * 1.5, sz), at(x, y + (0.68 + k * 0.22) * s, z - (0.3 + k * 0.08) * s), k % 2 == 0 and GOLD or WHITE, {Mat = Enum.Material.SmoothPlastic})
		end
	elseif pet.Horn == "bug" then
		b.E(Vector3.new(0.18, 0.6, 0.18) * s, at(x, y + 0.45 * s, z - 0.5 * s) * A(-0.6, 0, 0), pet.C[3])
	end
	if pet.Crest then
		for k = -1, 1 do
			b.E(Vector3.new(0.14, 0.45, 0.2) * s, at(x + k * 0.14 * s, y + 0.72 * s, z + 0.15 * s) * A(-0.3, 0, k * 0.3), c3)
		end
	end
	if pet.Comb then
		for k = -1, 1 do
			b.E(Vector3.new(0.16, 0.26, 0.26) * s, at(x, y + 0.66 * s, z + k * 0.17 * s), c3)
		end
	end
	if pet.Crown then
		b.E(Vector3.new(0.7, 0.16, 0.7) * s, at(x, y + 0.68 * s, z), GOLD, {Mat = Enum.Material.Foil})
		for k = 0, 4 do
			local ang = k / 5 * math.pi * 2
			b.E(Vector3.new(0.13, 0.24, 0.13) * s, at(x + math.cos(ang) * 0.3 * s, y + 0.82 * s, z + math.sin(ang) * 0.3 * s), GOLD, {Mat = Enum.Material.Foil})
		end
		b.E(Vector3.new(0.12, 0.12, 0.06) * s, at(x, y + 0.7 * s, z - 0.36 * s), rgb(255, 60, 90), {Mat = Enum.Material.Neon})
	end
	if pet.Halo then
		for k = 0, 11 do
			local ang = k / 12 * math.pi * 2
			b.E(Vector3.new(0.13, 0.13, 0.13) * s, at(x + math.cos(ang) * 0.45 * s, y + 1.0 * s, z + math.sin(ang) * 0.45 * s), rgb(255, 240, 150), {Mat = Enum.Material.Neon})
		end
	end
	if pet.Antenna then
		for _, sx in ipairs(pet.Antenna == "leaf" and {0} or {-1, 1}) do
			b.E(Vector3.new(0.06, 0.6, 0.06) * s, at(x + sx * 0.25 * s, y + 0.88 * s, z) * A(0, 0, -sx * 0.25), DARK, {Block = true})
			if pet.Antenna == "leaf" then
				b.E(Vector3.new(0.4, 0.14, 0.24) * s, at(x + 0.16 * s, y + 1.18 * s, z) * A(0, 0, 0.5), rgb(90, 200, 80))
			else
				b.E(Vector3.new(0.2, 0.2, 0.2) * s, at(x + sx * 0.33 * s, y + 1.18 * s, z), pet.C[3] == DARK and rgb(255, 80, 200) or rgb(255, 80, 200), {Mat = Enum.Material.Neon})
			end
		end
	end
	if pet.Helmet then
		b.E(Vector3.new(2.05, 1.95, 1.95) * s, at(x, y + 0.05 * s, z), rgb(200, 235, 255), {T = 0.7, Mat = Enum.Material.Glass, Refl = 0.2})
	end
	if pet.Headdress then
		for k = 0, 3 do
			b.E(Vector3.new(1.8 - k * 0.1, 0.25, 0.9) * s, at(x, y + (0.4 - k * 0.3) * s, z + 0.35 * s), k % 2 == 0 and GOLD or pet.C[3])
		end
	end
end

local function head(b, pet, x, y, z, s)
	local c1 = pet.C[1]
	b.E(Vector3.new(1.55, 1.42, 1.42) * s, at(x, y, z), c1, {Name = "Head"})
	if pet.Hood and pet.B ~= "ghost" then
		-- cobra hood fanning out behind the head
		b.E(Vector3.new(2.1, 1.7, 0.3) * s, at(x, y - 0.05 * s, z + 0.45 * s), c1)
		b.E(Vector3.new(1.5, 1.2, 0.1) * s, at(x, y - 0.05 * s, z + 0.3 * s), pet.C[2])
	end
	face(b, pet, x, y, z - 0.68 * s, s)
	headTop(b, pet, x, y, z, s)
end

------------------------------------------------------------------
-- BODY PARTS shared by several body types
------------------------------------------------------------------
local function wings(b, pet, y, z, size)
	local kind = pet.Wings
	if not kind then return end
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	size = size or 1
	for _, sx in ipairs({-1, 1}) do
		local base = at(sx * 0.75 * size, y, z) * A(0.25, sx * -0.35, sx * -0.75)
		if kind == "feather" then
			b.E(Vector3.new(0.14, 1.1, 1.7) * size, base * CFrame.new(0, 0.55 * size, 0.3 * size), c2)
			b.E(Vector3.new(0.12, 0.85, 1.35) * size, base * CFrame.new(sx * 0.05, 0.4 * size, 0.55 * size), c3)
		elseif kind == "dragon" or kind == "bat" then
			local mem = kind == "bat" and c2 or c3
			b.E(Vector3.new(0.08, 1.25, 1.6) * size, base * CFrame.new(0, 0.6 * size, 0.35 * size), mem, {T = 0.05})
			b.E(Vector3.new(0.14, 1.4, 0.14) * size, base * CFrame.new(0, 0.62 * size, -0.4 * size) * A(-0.3, 0, 0), c1)
			for k = 0, 2 do
				b.E(Vector3.new(0.1, 0.1, 0.9) * size, base * CFrame.new(0, (1.1 - k * 0.42) * size, 0.15 * size) * A(0.4 - k * 0.3, 0, 0), c1)
			end
		elseif kind == "fin" then
			b.E(Vector3.new(0.08, 0.6, 0.9) * size, base * CFrame.new(0, 0.3, 0.2), c3, {T = 0.1})
		end
	end
end

local function spikes(b, color, from, to, n, s)
	for k = 0, n - 1 do
		local p = from:Lerp(to, k / math.max(1, n - 1))
		b.E(Vector3.new(0.14, 0.34, 0.3) * s, CFrame.new(p) * A(-0.3, 0, 0), color)
	end
end

-- flat spots scattered over an ellipsoid
local function spots(b, pet, color, center, radii, count, size)
	local rng = Random.new(hash(pet.N))
	for _ = 1, count do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude > 0.1 then
			local sz = size * rng:NextNumber(0.7, 1.2)
			surfaceSpot(b, center, radii + Vector3.new(0.04, 0.04, 0.04), dir, Vector3.new(sz, sz * 0.85, 0.06), color)
		end
	end
end

------------------------------------------------------------------
-- BODY TYPES
------------------------------------------------------------------
local BODY = {}

-- four-legged chibi: cats, dogs, horses, dragons, everything with legs
function BODY.quad(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local squat = pet.Squat
	local by = squat and 0.72 or 0.95
	local bodySize = squat and Vector3.new(1.6, 1.05, 1.9) or Vector3.new(1.45, 1.25, 1.75)
	local bodyC = Vector3.new(0, by, 0.2)
	b.E(bodySize, CFrame.new(bodyC), c1, {Name = "Body"})
	b.E(bodySize * Vector3.new(0.72, 0.72, 0.68), at(0, by - 0.08, -0.15), c2)
	-- legs
	for _, sx in ipairs({-1, 1}) do
		for _, lz in ipairs({-0.38, 0.72}) do
			b.E(Vector3.new(0.46, squat and 0.36 or 0.6, 0.48), at(sx * 0.44, squat and 0.18 or 0.3, lz), c1)
			b.E(Vector3.new(0.4, 0.16, 0.44), at(sx * 0.44, 0.08, lz - 0.04), c2)
		end
	end
	if pet.Stripes then
		for _, sz in ipairs({-0.25, 0.2, 0.62}) do
			b.E(Vector3.new(bodySize.X + 0.05, bodySize.Y * 0.92 + 0.05, 0.16), at(0, by + 0.03, 0.2 + sz), pet.Stripes)
		end
	end
	if pet.Spots then
		spots(b, pet, pet.Spots, bodyC, bodySize, 7, 0.42)
	end
	if pet.Fluff then
		local rng = Random.new(hash(pet.N) + 7)
		for _ = 1, 9 do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0, 1), rng:NextNumber(-1, 1)).Unit
			b.E(Vector3.new(0.7, 0.62, 0.7), CFrame.new(bodyC + dir * Vector3.new(0.62, 0.5, 0.75)), c1)
		end
	end
	if pet.Bones then
		for k = 0, 2 do
			b.E(Vector3.new(bodySize.X + 0.04, 0.1, 0.12), at(0, by + 0.05, -0.15 + k * 0.32), c3)
		end
	end
	if pet.Shell then
		local sc = Vector3.new(0, by + 0.32, 0.2)
		local ss = Vector3.new(1.8, 1.05, 2.0)
		b.E(ss, CFrame.new(sc), pet.Shell, {Mat = pet.Glow and Enum.Material.Basalt or nil})
		spots(b, pet, pet.Glow and rgb(255, 120, 30) or pet.Shell:Lerp(WHITE, 0.3), sc, ss, 6, 0.55)
	end
	if pet.Hump then
		b.E(Vector3.new(0.9, 0.85, 0.9), at(0, by + 0.75, 0.35), c1)
	end
	if pet.Spikes then
		spikes(b, pet.Spikes, Vector3.new(0, by + 0.65, -0.35), Vector3.new(0, by + 0.5, 0.95), 4, 1)
	end
	wings(b, pet, by + 0.4, 0.3, 1)
	-- tail
	local tail = pet.Tail
	local tb = Vector3.new(0, by + 0.1, 1.05)
	if tail == "cat" then
		for k, p in ipairs({{0, 0.2, 0.15}, {0, 0.55, 0.32}, {0, 0.9, 0.3}, {0, 1.15, 0.15}}) do
			b.E(Vector3.new(0.28, 0.32, 0.28), CFrame.new(tb + Vector3.new(p[1], p[2], p[3])), k == 4 and (pet.Stripes or c1) or c1)
		end
	elseif tail == "fluffy" or tail == "ringed" then
		local cf = CFrame.new(tb + Vector3.new(0, 0.5, 0.3)) * A(0.6, 0, 0)
		b.E(Vector3.new(0.72, 1.15, 0.72), cf, c1)
		b.E(Vector3.new(0.5, 0.45, 0.5), cf * CFrame.new(0, 0.5, 0), tail == "ringed" and c3 or c2)
		if tail == "ringed" then
			b.E(Vector3.new(0.75, 0.16, 0.75), cf * CFrame.new(0, 0.05, 0), c3)
		end
	elseif tail == "short" then
		b.E(Vector3.new(0.36, 0.36, 0.36), CFrame.new(tb + Vector3.new(0, 0.12, 0.05)), c1)
	elseif tail == "puff" then
		b.E(Vector3.new(0.52, 0.52, 0.52), CFrame.new(tb + Vector3.new(0, 0.12, 0.05)), WHITE)
	elseif tail == "long" then
		for k = 0, 3 do
			local sz = 0.55 - k * 0.1
			b.E(Vector3.new(sz, sz, 0.55), CFrame.new(tb + Vector3.new(0, -0.15 - k * 0.08, 0.15 + k * 0.4)), c1)
		end
		if pet.Spikes then
			spikes(b, pet.Spikes, tb + Vector3.new(0, 0.15, 0.2), tb + Vector3.new(0, -0.15, 1.3), 3, 0.7)
		end
	elseif tail == "curl" then
		for k = 0, 5 do
			local ang = k * 0.9
			b.E(Vector3.new(0.26, 0.26, 0.26), CFrame.new(tb + Vector3.new(0, 0.2 + math.sin(ang) * 0.35 + k * 0.08, 0.25 + math.cos(ang) * 0.3)), c1)
		end
	elseif tail == "horse" then
		local col = pet.Mane or c1
		for k = 0, 2 do
			b.E(Vector3.new(0.42 - k * 0.06, 0.62, 0.38), CFrame.new(tb + Vector3.new(0, 0.1 - k * 0.38, 0.22 + k * 0.08)) * A(0.4, 0, 0), col)
		end
	elseif tail == "tuft" then
		b.E(Vector3.new(0.14, 0.14, 0.7), CFrame.new(tb + Vector3.new(0, 0.1, 0.3)) * A(-0.4, 0, 0), c1)
		b.E(Vector3.new(0.34, 0.4, 0.34), CFrame.new(tb + Vector3.new(0, 0.32, 0.62)), pet.Mane or c3)
	elseif tail == "nine" then
		for k = 0, 8 do
			local ang = (k - 4) * 0.28
			local cf = CFrame.new(tb + Vector3.new(0, 0.3, 0.2)) * A(0, 0, ang) * A(0.75, 0, 0) * CFrame.new(0, 0.55, 0)
			b.E(Vector3.new(0.4, 1.15, 0.4), cf, c1)
			b.E(Vector3.new(0.3, 0.36, 0.3), cf * CFrame.new(0, 0.52, 0), pet.Markings or c3, {Mat = pet.Glow and Enum.Material.Neon or nil})
		end
	end
	-- neck and head(s)
	local hy, hz = by + 1.0, -0.55
	if pet.Neck then
		for k = 1, 3 do
			b.E(Vector3.new(0.55, 0.6, 0.55), at(0, by + 0.35 + k * 0.38, -0.5 - k * 0.04), c1)
		end
		if pet.Spots then
			b.E(Vector3.new(0.35, 0.3, 0.06), at(0.1, by + 1.2, -0.79), pet.Spots)
		end
		hy, hz = by + 2.0, -0.75
	end
	if pet.Mane and tail ~= "horse" then
		-- lion mane: a ring of fluff around the face
		for k = 0, 11 do
			local ang = k / 12 * math.pi * 2
			b.E(Vector3.new(0.6, 0.6, 0.5), at(math.cos(ang) * 0.78, hy + math.sin(ang) * 0.72, hz + 0.25), pet.Mane)
		end
	elseif pet.Mane then
		for k = 0, 3 do
			b.E(Vector3.new(0.3, 0.55, 0.5), at(0, hy + 0.55 - k * 0.32, hz + 0.45 + k * 0.22) * A(0.5, 0, 0), pet.Mane)
		end
	end
	if pet.Heads and pet.Heads > 1 then
		for k = -1, 1 do
			local s = k == 0 and 0.82 or 0.7
			local x = k * 0.85
			local y = hy + (k == 0 and 0.35 or 0)
			b.E(Vector3.new(0.5, 0.8, 0.5), at(x * 0.6, (by + y) / 2 + 0.2, hz + 0.15) * A(0, 0, -k * 0.5), c1)
			head(b, pet, x, y, hz, s)
		end
	else
		head(b, pet, 0, hy, hz, 1)
	end
end

-- birds: a round body, a round head, wings and little feet
function BODY.bird(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	b.E(Vector3.new(1.45, 1.5, 1.45), at(0, 1.0, 0.05), c1, {Name = "Body"})
	b.E(pet.Belly and Vector3.new(1.15, 1.25, 0.9) or Vector3.new(1.0, 1.05, 0.6), at(0, 0.92, pet.Belly and -0.32 or -0.5), c2)
	for _, sx in ipairs({-1, 1}) do
		b.E(Vector3.new(0.32, 0.12, 0.45), at(sx * 0.3, 0.07, -0.2), rgb(255, 160, 40))
		if not pet.Wings then
			b.E(Vector3.new(0.26, 0.85, 0.72), at(sx * 0.74, 1.12, 0.1) * A(0, 0, sx * 0.3), pet.Swirl and c3 or c1)
		end
	end
	if pet.Swirl then
		for _, y in ipairs({0.6, 1.1}) do
			b.E(Vector3.new(1.48, 0.16, 1.48), at(0, y, 0.05) * A(0.25, 0, 0), c3)
		end
	end
	if pet.Spots then
		spots(b, pet, pet.Spots, Vector3.new(0, 1.0, 0.05), Vector3.new(1.45, 1.5, 1.45), 6, 0.25)
	end
	wings(b, pet, 1.3, 0.15, 0.9)
	local tail = pet.Tail
	if tail == "feathers" then
		for k = -1, 1 do
			b.E(Vector3.new(0.28, 0.14, 1.0), at(k * 0.22, 1.05 + math.abs(k) * -0.05, 0.95) * A(-0.5, k * 0.35, 0), ({c3, c2, c1})[k + 2])
		end
	elseif tail == "phoenix" then
		for k = -1, 1 do
			b.E(Vector3.new(0.3, 0.12, 1.9), at(k * 0.3, 0.9 - math.abs(k) * 0.1, 1.45) * A(-0.25, k * 0.3, 0), k == 0 and c3 or c1, {Mat = Enum.Material.Neon})
		end
	elseif tail ~= "none" then
		b.E(Vector3.new(0.5, 0.14, 0.5), at(0, 0.95, 0.78) * A(-0.4, 0, 0), c1)
	end
	-- neck (swans)
	local hy, hz = 2.0, -0.15
	if pet.Neck then
		for k = 1, 3 do
			b.E(Vector3.new(0.42, 0.5, 0.42), at(0, 1.45 + k * 0.32, -0.35 - k * 0.04), c1)
		end
		hy, hz = 2.65, -0.45
	end
	local s = 0.82
	b.E(Vector3.new(1.55, 1.42, 1.42) * s, at(0, hy, hz), c1, {Name = "Head"})
	local fz = hz - 0.68 * s
	local beakPet = setmetatable({Snout = "bird"}, {__index = pet})
	face(b, beakPet, 0, hy, fz, s)
	headTop(b, pet, 0, hy, hz, s)
	-- beak
	local beak = pet.Beak
	if beak == "duck" then
		b.E(Vector3.new(0.55, 0.18, 0.5) * s, at(0, hy - 0.2 * s, fz - 0.18 * s), rgb(255, 160, 40))
	elseif beak == "big" then
		b.E(Vector3.new(0.5, 0.45, 1.1) * s, at(0, hy - 0.12 * s, fz - 0.45 * s), c3)
		b.E(Vector3.new(0.3, 0.25, 0.3) * s, at(0, hy - 0.15 * s, fz - 0.95 * s), DARK)
	elseif beak == "hook" then
		b.E(Vector3.new(0.34, 0.4, 0.32) * s, at(0, hy - 0.15 * s, fz - 0.12 * s), rgb(255, 230, 120))
		b.E(Vector3.new(0.18, 0.2, 0.18) * s, at(0, hy - 0.33 * s, fz - 0.2 * s), rgb(255, 230, 120))
	elseif beak ~= "none" then
		b.E(Vector3.new(0.26, 0.22, 0.4) * s, at(0, hy - 0.14 * s, fz - 0.12 * s), rgb(255, 160, 40))
	end
	if pet.Comb then
		b.E(Vector3.new(0.16, 0.26, 0.16) * s, at(0, hy - 0.45 * s, fz), c3)
	end
end

-- fish and sea creatures: a long rounded body, fins and a tail
function BODY.fish(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local fins = pet.Fins
	local cy = 1.25
	local bs = Vector3.new(1.15, 1.25, 2.05)
	b.E(bs, at(0, cy, 0), c1, {Name = "Body"})
	b.E(Vector3.new(0.95, 0.8, 1.65), at(0, cy - 0.25, -0.05), c2)
	if pet.Stripes then
		for _, z in ipairs({-0.35, 0.45}) do
			b.E(Vector3.new(bs.X + 0.05, bs.Y * 0.95 + 0.04, 0.22), at(0, cy, z), pet.Stripes)
		end
	end
	if pet.Spots then
		spots(b, pet, pet.Spots, Vector3.new(0, cy, 0), bs, 8, 0.2)
	end
	-- tail
	if fins == "whale" or fins == "dolphin" or fins == "flipper" then
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.75, 0.12, 0.55), at(sx * 0.35, cy + 0.15, 1.3) * A(0, sx * 0.5, 0), c3)
		end
	else
		local big = fins == "fancy" and 1.5 or 1
		for _, k in ipairs({-1, 1}) do
			b.E(Vector3.new(0.12, 0.85 * big, 0.7 * big), at(0, cy + k * 0.3 * big, 1.2 + 0.1 * big) * A(-k * 0.6, 0, 0), c3, {T = fins == "fancy" and 0.15 or 0})
		end
	end
	-- dorsal fin
	if fins == "shark" then
		b.E(Vector3.new(0.16, 1.0, 0.9), at(0, cy + 0.78, 0.15), c1, {Wedge = true})
	elseif fins ~= "flipper" then
		b.E(Vector3.new(0.12, 0.55, 0.7), at(0, cy + 0.65, 0.15) * A(-0.4, 0, 0), c3, {T = fins == "fancy" and 0.15 or 0})
	end
	for _, sx in ipairs({-1, 1}) do
		b.E(Vector3.new(0.6, 0.1, 0.36), at(sx * 0.62, cy - 0.35, -0.2) * A(0, sx * -0.4, sx * 0.4), c3)
	end
	if pet.Spout then
		for k = 0, 2 do
			b.E(Vector3.new(0.18, 0.4, 0.18), at((k - 1) * 0.15, cy + 0.9 + k % 2 * 0.15, -0.2) * A(0, 0, (k - 1) * 0.4), rgb(160, 220, 255), {T = 0.3})
		end
	end
	local fishPet = setmetatable({Snout = pet.Snout or "fish"}, {__index = pet})
	if pet.Snout == "long" then
		b.E(Vector3.new(0.42, 0.36, 0.6), at(0, cy - 0.15, -1.15), c1)
	end
	face(b, fishPet, 0, cy + 0.12, -0.98, 0.78)
	if pet.Teeth then
		for k = -2, 2 do
			b.E(Vector3.new(0.07, 0.12, 0.06), at(k * 0.09, cy - 0.25, -1.0), WHITE)
		end
	end
end

-- octopuses: a big round head and eight curly arms
function BODY.octo(b, pet)
	local c1, c2 = pet.C[1], pet.C[2]
	local hc = Vector3.new(0, 1.7, 0.1)
	b.E(Vector3.new(1.65, 1.75, 1.6), CFrame.new(hc), c1, {Name = "Body"})
	spots(b, pet, c2, hc, Vector3.new(1.65, 1.75, 1.6), 6, 0.3)
	for i = 0, 7 do
		local ang = i / 8 * math.pi * 2
		local dx, dz = math.cos(ang), math.sin(ang)
		for k = 0, 2 do
			local r = 0.5 + k * 0.32
			local sz = 0.46 - k * 0.09
			b.E(Vector3.new(sz, sz, sz), at(dx * r, 0.85 - k * 0.27 + (k == 2 and 0.15 or 0), 0.1 + dz * r), c1)
		end
	end
	face(b, pet, 0, 1.55, hc.Z - 0.78, 0.95)
	headTop(b, pet, 0, 2.2, hc.Z, 1)
end

-- slimes and blobs: one squishy dome with a face
function BODY.blob(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local glassy = pet.Mat == "Glass"
	local bs = Vector3.new(1.85, 1.45, 1.85)
	b.E(bs, at(0, 0.74, 0), c1, {Name = "Body", T = glassy and 0.25 or 0})
	if glassy then
		b.E(Vector3.new(1.0, 0.75, 1.0), at(0, 0.62, 0.1), c3, {T = 0.35})
	end
	b.E(Vector3.new(0.45, 0.25, 0.25), at(-0.45, 1.25, -0.55) * A(0, 0, 0.4), WHITE, {T = 0.35, Mat = Enum.Material.SmoothPlastic})
	if pet.Pumpkin then
		for _, x in ipairs({-0.55, 0, 0.55}) do
			b.E(Vector3.new(0.6, bs.Y + 0.04, bs.Z * 0.9), at(x, 0.74, 0), c1:Lerp(DARK, 0.15))
		end
		b.E(Vector3.new(0.18, 0.4, 0.18), at(0, 1.55, 0) * A(0, 0, 0.3), c3, {Block = true})
	end
	if pet.Drips then
		for k = 0, 4 do
			local ang = k / 5 * math.pi * 2
			b.E(Vector3.new(0.25, 0.4, 0.25), at(math.cos(ang) * 0.85, 0.3, math.sin(ang) * 0.85), c2)
		end
	end
	face(b, pet, 0, 0.82, -0.88, 0.95)
	headTop(b, pet, 0, 0.95, 0, 1)
end

-- ghosts: a floating sheet with a wavy hem
function BODY.ghost(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	b.E(Vector3.new(1.55, 1.85, 1.55), at(0, 1.55, 0), c1, {Name = "Body", T = 0.12})
	for k = 0, 5 do
		local ang = k / 6 * math.pi * 2
		b.E(Vector3.new(0.55, 0.6, 0.55), at(math.cos(ang) * 0.5, 0.72, math.sin(ang) * 0.5), c1, {T = 0.12})
	end
	for _, sx in ipairs({-1, 1}) do
		b.E(Vector3.new(0.4, 0.55, 0.4), at(sx * 0.82, 1.4, -0.1) * A(0, 0, sx * 0.6), c1, {T = 0.12})
	end
	if pet.Hood then
		b.E(Vector3.new(1.75, 1.5, 1.7), at(0, 2.05, 0.08), c2)
		b.E(Vector3.new(1.2, 1.0, 0.3), at(0, 1.95, -0.72), DARK)
	end
	if pet.Scythe then
		b.E(Vector3.new(0.12, 2.6, 0.12), at(1.05, 1.5, -0.2) * A(0, 0, -0.2), rgb(70, 50, 40), {Block = true})
		b.E(Vector3.new(0.1, 0.4, 1.4), at(1.35, 2.75, 0.15) * A(0.3, 0, -0.2), rgb(200, 205, 220), {Mat = Enum.Material.Metal})
	end
	if pet.Antenna then
		headTop(b, pet, 0, 1.9, 0, 1)
	end
	face(b, pet, 0, 1.75, pet.Hood and -0.88 or -0.76, 0.95)
end

-- bugs and crabs: two round segments, little legs, and claws / stingers / wings
function BODY.bug(b, pet)
	local c1, c2, c3 = pet.C[1], pet.C[2], pet.C[3]
	local crab = pet.Claws
	local ab = b.E(Vector3.new(1.25, 1.0, 1.45), at(0, 0.82, 0.5), pet.Glow and c2 or c1, {Name = "Body", Mat = pet.Glow and Enum.Material.Neon or nil})
	b.E(Vector3.new(1.2, 1.1, 1.1), at(0, 1.0, -0.4), c1, {Name = "Head"})
	if pet.Mat == "Foil" then
		b.E(Vector3.new(0.05, 0.95, 1.35), at(0, 1.02, 0.52), c3)
	end
	for _, sx in ipairs({-1, 1}) do
		for k = -1, 1 do
			b.E(Vector3.new(0.7, 0.1, 0.12), at(sx * 0.7, 0.32, 0.1 + k * 0.38) * A(0, k * 0.3 * sx, sx * -0.5), DARK, {Block = true})
		end
		if crab then
			b.E(Vector3.new(0.35, 0.3, 0.7), at(sx * 0.85, 0.8, -0.85) * A(0, sx * 0.4, 0), c1)
			b.E(Vector3.new(0.55, 0.5, 0.5), at(sx * 1.05, 0.95, -1.3), c1)
			b.E(Vector3.new(0.18, 0.4, 0.18), at(sx * 0.95, 1.25, -1.45) * A(0, 0, sx * 0.5), c1)
		end
		if pet.BugWings then
			b.E(Vector3.new(0.1, 0.95, 1.25), at(sx * 0.5, 1.45, 0.45) * A(0.3, 0, sx * -0.6), rgb(220, 240, 255), {T = 0.45, Mat = Enum.Material.Glass})
		end
		if pet.Stalks then
			b.E(Vector3.new(0.1, 0.5, 0.1), at(sx * 0.28, 1.65, -0.6), c1, {Block = true})
		end
	end
	if pet.Stinger then
		for k = 0, 4 do
			local ang = k * 0.55
			local sz = 0.42 - k * 0.04
			b.E(Vector3.new(sz, sz, sz), at(0, 1.0 + math.sin(ang) * 1.0, 1.2 + math.cos(ang) * 0.4 - k * 0.12), k == 4 and c3 or c1)
		end
	elseif not crab then
		-- antennae
		for _, sx in ipairs({-1, 1}) do
			b.E(Vector3.new(0.06, 0.6, 0.06), at(sx * 0.25, 1.75, -0.6) * A(-0.3, 0, -sx * 0.35), DARK, {Block = true})
			b.E(Vector3.new(0.16, 0.16, 0.16), at(sx * 0.37, 2.02, -0.7), pet.Glow and c3 or c1, {Mat = pet.Glow and Enum.Material.Neon or nil})
		end
	end
	local facePet = setmetatable({Snout = "bug"}, {__index = pet})
	face(b, facePet, 0, 1.05, -0.95, 0.75)
	if pet.Horn then
		headTop(b, pet, 0, 1.0, -0.4, 1)
	end
end

------------------------------------------------------------------
-- PUBLIC
------------------------------------------------------------------
local MATS = {Foil = Enum.Material.Foil, Glass = Enum.Material.Glass}

local assets = script.Parent:WaitForChild("PetAssets")
local warned = {}
function M.build(pet)
	local src = assets:FindFirstChild(pet.Model or "")
	if not src then
		if not warned[pet.Key] then
			warned[pet.Key] = true
			warn("PetModels: no model in PetAssets for " .. tostring(pet.Key))
		end
		local p = Instance.new("Part")
		p.Name = "Root"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(2, 2, 2)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		local m = Instance.new("Model")
		p.Parent = m
		m.PrimaryPart = p
		m:SetAttribute("PetKey", pet.Key)
		return m
	end
	local m = src:Clone()
	m:PivotTo(CFrame.identity)
	m:SetAttribute("PetKey", pet.Key)
	return m
end

function M.buildChibi(pet)
	local b = newBuilder(pet.N, nil)
	-- whole-pet materials (gold, gummy glass); faces and eyes keep their own
	if pet.Mat == "Foil" then
		b.Mat = Enum.Material.Foil
	end
	;(BODY[pet.B] or BODY.quad)(b, pet)
	if pet.Mat == "Glass" and pet.B ~= "blob" then
		for _, p in ipairs(b.Model:GetChildren()) do
			if p:IsA("BasePart") and p.Material == Enum.Material.SmoothPlastic and p.Color == pet.C[1] then
				p.Material = MATS.Glass
				p.Transparency = math.max(p.Transparency, 0.15)
			end
		end
	end
	if pet.Big then
		b.Model:ScaleTo(1.2)
	end
	b.Model:SetAttribute("PetKey", pet.Key)
	return b.Model
end

-- Sparkles, glow and fire for pets out in the world. Better rarities get much more.
local TEX_SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
function M.addEffects(model, pet)
	local root = model.PrimaryPart
	local r = pet.R or 1
	local rc = PetData.RARITIES[r].Color
	local center = Instance.new("Attachment")
	center.Name = "FxCenter"
	center.Position = Vector3.new(0, 1.2, 0)
	center.Parent = root
	local function emitter(props)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = TEX_SPARKLE
		pe.LightEmission = 0.7
		pe.LockedToPart = false
		for k, v in pairs(props) do
			pe[k] = v
		end
		pe.Parent = center
		return pe
	end
	local rainbow = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 80, 80)), ColorSequenceKeypoint.new(0.25, rgb(255, 220, 60)), ColorSequenceKeypoint.new(0.5, rgb(80, 255, 120)),
		ColorSequenceKeypoint.new(0.75, rgb(80, 170, 255)), ColorSequenceKeypoint.new(1, rgb(200, 90, 255)),
	})
	local colors = (pet.Rainbow or r == 7) and rainbow or ColorSequence.new(rc, rc:Lerp(WHITE, 0.6))
	if r >= 3 then
		emitter({Color = colors, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.7, 1.2), Rate = 2 + r, Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(180, 180), Shape = Enum.ParticleEmitterShape.Sphere})
	end
	if r >= 4 or pet.Glow then
		local l = Instance.new("PointLight")
		l.Color = pet.Glow and pet.C[3] or rc
		l.Range = 6 + r
		l.Brightness = 0.6
		l.Shadows = false
		l.Parent = center
	end
	if r >= 5 then
		-- a glowing shell of light around the pet
		emitter({Color = colors, Size = NumberSequence.new(0.35, 0), Transparency = NumberSequence.new(0.2, 1), Lifetime = NumberRange.new(0.6, 1), Rate = 8 + r * 2, Speed = NumberRange.new(1, 1.6), Drag = 2,
			Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward})
	end
	if r >= 6 then
		-- wisps rising off it and big star twinkles
		emitter({Color = colors, Size = NumberSequence.new(0.4, 0), Lifetime = NumberRange.new(1, 1.5), Rate = 10, Speed = NumberRange.new(1.5, 2.5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(30, 30)})
		emitter({Color = ColorSequence.new(WHITE), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.5, 0.8), Rate = 3, Speed = NumberRange.new(0, 0.2), Rotation = NumberRange.new(0, 360), Shape = Enum.ParticleEmitterShape.Sphere})
	end
	if pet.Fire then
		local f = Instance.new("Fire")
		f.Size = 2.5
		f.Heat = 4
		f.Color = pet.C[3]
		f.SecondaryColor = pet.C[1]
		f.Parent = root
	end
	if pet.Spark then
		emitter({Color = ColorSequence.new(WHITE, rgb(255, 240, 120)), Size = NumberSequence.new(0.15, 0), Lifetime = NumberRange.new(0.1, 0.2), Rate = 25, Speed = NumberRange.new(6, 10), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = NumberSequence.new(3)})
	end
end

-- EGGS: a shiny oval shell with its own pattern
local function eggBasic(egg)
	local b = newBuilder(egg.Name, egg.Mat and Enum.Material[egg.Mat] or nil)
	local center, radii = Vector3.new(0, 1.4, 0), Vector3.new(2.2, 2.8, 2.2)
	b.E(radii, CFrame.new(center), egg.Color, {Name = "Shell"})
	b.Mat = nil
	local rng = Random.new(hash(egg.Name))
	local pat, spot = egg.Pattern, egg.Spot
	local function dot(size, color, props, minY)
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(minY or -0.7, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude > 0.1 then
			surfaceSpot(b, center, radii + Vector3.new(0.03, 0.03, 0.03), dir, size, color, props)
		end
	end
	if pat == "spots" then
		for _ = 1, 9 do
			local s = rng:NextNumber(0.35, 0.6)
			dot(Vector3.new(s, s, 0.06), spot)
		end
	elseif pat == "stripes" or pat == "waves" or pat == "zigzag" then
		for k, y in ipairs({-0.6, 0, 0.6}) do
			local w = math.sqrt(math.max(0.05, 1 - (y / 1.4) ^ 2))
			b.E(Vector3.new(2.25 * w, pat == "waves" and 0.18 or 0.28, 2.25 * w), CFrame.new(center + Vector3.new(0, y, 0)) * A(pat == "waves" and (k - 2) * 0.12 or 0, 0, pat == "zigzag" and (k % 2 == 0 and 0.2 or -0.2) or 0), spot)
		end
	elseif pat == "leaves" then
		for _ = 1, 10 do
			dot(Vector3.new(0.3, 0.55, 0.06), rng:NextNumber() < 0.5 and spot or Color3.fromRGB(120, 210, 90))
		end
	elseif pat == "sprinkles" then
		local cols = {rgb(255, 255, 255), rgb(255, 230, 80), rgb(120, 220, 255), rgb(150, 255, 150), rgb(255, 120, 120)}
		for _ = 1, 26 do
			dot(Vector3.new(0.1, 0.3, 0.06), cols[rng:NextInteger(1, #cols)])
		end
	elseif pat == "snow" then
		b.E(Vector3.new(1.95, 1.0, 1.95), CFrame.new(center + Vector3.new(0, 1.0, 0)), WHITE)
		for _ = 1, 10 do
			dot(Vector3.new(0.2, 0.2, 0.06), spot)
		end
	elseif pat == "drips" then
		b.E(Vector3.new(2.0, 1.0, 2.0), CFrame.new(center + Vector3.new(0, 0.95, 0)), spot)
		for k = 0, 5 do
			local ang = k / 6 * math.pi * 2
			b.E(Vector3.new(0.35, 0.7, 0.35), CFrame.new(center + Vector3.new(math.cos(ang) * 0.95, 0.4, math.sin(ang) * 0.95)), spot)
		end
	elseif pat == "cracks" then
		for _ = 1, 10 do
			dot(Vector3.new(0.1, rng:NextNumber(0.4, 0.8), 0.06), spot, {Mat = Enum.Material.Neon})
		end
	elseif pat == "stars" or pat == "galaxy" then
		for _ = 1, pat == "galaxy" and 22 or 12 do
			local s = rng:NextNumber(0.1, pat == "galaxy" and 0.2 or 0.35)
			dot(Vector3.new(s, s, 0.06), pat == "galaxy" and (rng:NextNumber() < 0.7 and spot or rgb(255, 120, 230)) or spot, {Mat = Enum.Material.Neon})
		end
		if pat == "galaxy" then
			b.E(Vector3.new(2.25, 0.35, 2.25), CFrame.new(center) * A(0.3, 0, 0.2), rgb(150, 80, 255), {T = 0.3, Mat = Enum.Material.Neon})
		end
	end
	-- a soft shine
	b.E(Vector3.new(0.45, 0.75, 0.2), CFrame.new(center + Vector3.new(-0.55, 0.55, -0.85)) * A(0, 0.5, 0.3), WHITE, {T = 0.45})
	return b.Model
end

-- the egg's premium model, standing on y = 0; the simple procedural egg only if its asset is missing
local eggAssets = script.Parent:WaitForChild("EggAssets")
function M.egg(egg)
	local src = eggAssets:FindFirstChild(egg.Name)
	if not src then
		return eggBasic(egg)
	end
	local m = src:Clone()
	m:PivotTo(CFrame.identity)
	return m
end

return M

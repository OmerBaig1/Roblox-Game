--[[
	PetModels
	PetModels.build(pet)        -> a copy of the pet's premium model (ReplicatedStorage.PetAssets), Root at the origin
	PetModels.egg(egg)           -> a copy of the egg's premium model (ReplicatedStorage.EggAssets, built by PetLab EggForge)
	The old chibi pet builder was removed on Oct 27 2026 (copy in ServerStorage.Backups.Before_Oct27_ChibiRemoval).
]]

local M = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE = Color3.new(1, 1, 1)
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

-- a flat spot lying on an ellipsoid's surface (dir is a direction from its centre)
local function surfaceSpot(b, center, radii, dir, size, color, props)
	dir = dir.Unit
	local pos = center + Vector3.new(dir.X * radii.X, dir.Y * radii.Y, dir.Z * radii.Z) * 0.5
	local normal = Vector3.new(dir.X / radii.X, dir.Y / radii.Y, dir.Z / radii.Z).Unit
	return b.E(size, CFrame.lookAt(pos, pos + normal), color, props)
end

------------------------------------------------------------------
-- PUBLIC
------------------------------------------------------------------
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

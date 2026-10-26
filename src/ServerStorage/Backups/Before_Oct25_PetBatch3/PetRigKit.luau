--[[
	PetRigKit (Studio edit-time only, used from the command bar / MCP; nothing requires it at runtime)
	Turns a raw mesh generation into a pet that meets the rig contract in docs/pets/PET_BIBLE.md §4.
	Require a fresh clone each time so edits are picked up: local Kit = require(PetLab.Code.PetRigKit:Clone())

	local pet = Kit.assemble({
		Name = "Coalpup", Raw = "Coalpup_raw2", Tier = 1,
		Parts = {["body and legs"] = "Body", head = "Head", ...}, -- raw part name substring -> contract name
		Face = {"Body", "Head"},  -- heading from the first part to the second becomes -Z (or Yaw = degrees)
		Height = 2.4,              -- optional, defaults to the tier height (or Length = studs along Z)
		Hover = 1.6,               -- optional, fliers: body raised above the Root
	})
	Kit.rig(pet, {Id = "coalpup", Mode = "Bound", Joints = {{"Neck", "Body", "Head", Vector3}, ...}, Props = {"Shard1"}})
	Joint positions are in pet space (studs from the Root, +X right, -Z forward); nil puts the joint at Part1's centre.
]]
local Kit = {}

Kit.TIERS = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
Kit.HEIGHT = {2.4, 2.6, 2.9, 3.3, 3.8, 4.3, 4.8}
Kit.INK = Color3.fromHex("14111F")
Kit.SPACING = 6

local lab = game:GetService("ServerStorage"):WaitForChild("PetLab")

-- where slot n (1-based, roster order within the tier) sits on its tier's gallery row
function Kit.slotPosition(tier, slot)
	local row = lab.Stage.GalleryPads["Row_" .. Kit.TIERS[tier]]
	local half = row.Size.X / 2 - 1
	return Vector3.new(row.Position.X + half - Kit.SPACING * (slot - 1), row.Position.Y + row.Size.Y / 2, row.Position.Z)
end

local function findPart(model, sub)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name:find(sub, 1, true) then
			return p
		end
	end
end

-- clone, rename, flatten, face -Z, scale, and stand it at `at` (feet centre); returns the model, unparented
function Kit.assemble(spec)
	local src = lab.RawGenerations[spec.Raw]:Clone()
	local pet = Instance.new("Model")
	pet.Name = spec.Name
	-- longest substrings first so "tail base" wins over "tail"
	local keys = {}
	for k in pairs(spec.Parts) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return #a > #b
	end)
	for _, k in ipairs(keys) do
		local p = findPart(src, '"' .. k .. '"') or findPart(src, k)
		assert(p, spec.Raw .. ": no part matching " .. k)
		p.Name = spec.Parts[k]
		p.Parent = pet
	end
	src:Destroy()

	local th = math.rad(spec.Yaw or 0)
	if spec.Face then
		local d = pet[spec.Face[2]].Position - pet[spec.Face[1]].Position
		th = math.pi - math.atan2(d.X, d.Z)
	end
	local cf = pet:GetBoundingBox()
	pet:PivotTo(CFrame.Angles(0, th, 0) * CFrame.new(-cf.Position) * pet:GetPivot())

	local _, size = pet:GetBoundingBox()
	local s = spec.Length and spec.Length / size.Z or (spec.Height or Kit.HEIGHT[spec.Tier]) / size.Y
	pet:ScaleTo(pet:GetScale() * s)

	-- feet centre to the origin, then out to the gallery slot (fliers hover above it)
	local bb, sz = pet:GetBoundingBox()
	local feet = Vector3.new(bb.Position.X, bb.Position.Y - sz.Y / 2, bb.Position.Z)
	local at = spec.At or Kit.slotPosition(spec.Tier, spec.Slot or 1)
	local offset = at - feet + Vector3.new(0, spec.Hover or 0, 0)
	for _, p in ipairs(pet:GetChildren()) do
		p.CFrame += offset
	end
	pet:SetAttribute("BuildAt", at)
	return pet
end

local function joint(name, p0, p1, at, prop)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0, m.Part1 = p0, p1
	m.C0 = p0.CFrame:Inverse() * CFrame.new(at)
	m.C1 = prop and CFrame.identity or p1.CFrame:Inverse() * CFrame.new(at)
	m.Parent = p1
	return m
end

-- adds Root, joints, part flags, outline and attributes
function Kit.rig(pet, spec)
	local at = pet:GetAttribute("BuildAt")
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.5, 0.5, 0.5)
	root.CFrame = CFrame.new(at)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide, root.CanQuery, root.CanTouch = false, false, false
	root.Parent = pet
	pet.PrimaryPart = root

	local props = {}
	for _, n in ipairs(spec.Props or {}) do
		props[n] = true
	end
	for _, p in ipairs(pet:GetChildren()) do
		if p:IsA("BasePart") and p ~= root then
			p.Anchored = false
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			p.Massless = true
			p.CastShadow = not props[p.Name]
		end
	end
	for _, j in ipairs(spec.Joints) do
		local p0, p1 = pet[j[2]], pet[j[3]]
		local pos = j[4] and at + j[4] or p1.Position
		joint(j[1], p0, p1, pos, props[j[3]])
	end

	local hl = Instance.new("Highlight")
	hl.Name = "Outline"
	hl.FillTransparency = 1
	hl.OutlineColor = Kit.INK
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = pet

	pet:SetAttribute("BuildAt", nil)
	pet:SetAttribute("PetId", spec.Id)
	pet:SetAttribute("Tier", spec.Tier)
	pet:SetAttribute("Mode", spec.Mode)
	pet.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return pet
end

-- an attachment at a pet-space position on a part
function Kit.attach(pet, partName, name, petPos)
	local p = pet[partName]
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = p.CFrame:PointToObjectSpace(pet.Root.Position + petPos)
	a.Parent = p
	return a
end

-- an effect instance with properties, e.g. Kit.make("ParticleEmitter", attachment, {Name = "Smoke", Rate = 3})
function Kit.make(class, parent, props)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

-- pet-space bounds of a part: centre and size (parts are axis-aligned after assemble only if the raw was)
function Kit.measure(pet, at)
	local out = {}
	for _, p in ipairs(pet:GetChildren()) do
		if p:IsA("BasePart") then
			local c = p.Position - at
			-- world-axis extents of the rotated box
			local r = p.CFrame
			local ex = Vector3.new(
				math.abs(r.RightVector.X) * p.Size.X + math.abs(r.UpVector.X) * p.Size.Y + math.abs(r.LookVector.X) * p.Size.Z,
				math.abs(r.RightVector.Y) * p.Size.X + math.abs(r.UpVector.Y) * p.Size.Y + math.abs(r.LookVector.Y) * p.Size.Z,
				math.abs(r.RightVector.Z) * p.Size.X + math.abs(r.UpVector.Z) * p.Size.Y + math.abs(r.LookVector.Z) * p.Size.Z
			) / 2
			table.insert(out, string.format("%-10s ctr(%.2f, %.2f, %.2f) min(%.2f, %.2f, %.2f) max(%.2f, %.2f, %.2f)", p.Name, c.X, c.Y, c.Z, c.X - ex.X, c.Y - ex.Y, c.Z - ex.Z, c.X + ex.X, c.Y + ex.Y, c.Z + ex.Z))
		end
	end
	table.sort(out)
	return table.concat(out, "\n")
end

return Kit

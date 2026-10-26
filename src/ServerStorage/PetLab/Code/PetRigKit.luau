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

-- Legendary and above must read as rare at a glance (owner feedback, Oct 25 2026): a tier-coloured outline
-- instead of ink, an aura of glowing motes around the body in the tier colour, and a soft tier-coloured light
-- when the tier's light budget has room. Rates and lights stay inside PET_BIBLE §6.
Kit.RARITY = {
	[5] = {Color = Color3.fromRGB(255, 190, 60), Rate = 6}, -- Legendary: gold
	[6] = {Color = Color3.fromRGB(255, 70, 120), Rate = 8}, -- Mythic: rose
	[7] = {Color = Color3.fromRGB(40, 255, 225), Rate = 10}, -- Secret: cyan
}
Kit.LIGHTS = {0, 0, 0, 1, 2, 2, 2}

-- owner feedback, Oct 26 2026: the aura is each pet's own element, finished in the tier colour, so no two
-- high-rarity pets share one. Keys are pet model names; anything missing gets the plain tier motes.
-- Mote = element colour, Move = how the motes travel (Rise, Fall, Drift, Crackle, Streak, Inward), Big = size scale
local C3 = Color3.fromRGB
Kit.AURAS = {
	ObsidianDrake = {Mote = C3(255, 110, 40), Move = "Rise", Texture = "fire"}, -- embers off the lava cracks
	MaelstromSerpent = {Mote = C3(120, 220, 255), Move = "Drift", Big = 1.4}, -- slow sea bubbles
	ElderhornSpirit = {Mote = C3(190, 255, 200), Move = "Drift", Big = 1.2}, -- forest wisps
	AuroraMammoth = {Mote = C3(120, 255, 200), Mote2 = C3(190, 130, 255), Move = "Fall"}, -- aurora-lit snow
	HighScoreDragon = {Mote = C3(0, 240, 255), Mote2 = C3(255, 60, 220), Move = "Crackle"}, -- arcade blips
	HyperdriveHawk = {Mote = C3(150, 220, 255), Move = "Streak"}, -- speed lines
	SolflareQilin = {Mote = C3(255, 200, 70), Move = "Rise", Texture = "fire"}, -- sun flecks
	CoralcrownLeviathan = {Mote = C3(90, 255, 230), Move = "Drift", Big = 1.3}, -- plankton glow
	WorldtreeTortoise = {Mote = C3(150, 240, 110), Mote2 = C3(255, 170, 210), Move = "Fall", Big = 1.2}, -- pollen and petals
	HailstormGriffin = {Mote = C3(220, 245, 255), Move = "Crackle"}, -- ice glints in the wind
	GlitchPhantom = {Mote = C3(80, 255, 150), Mote2 = C3(255, 50, 90), Move = "Crackle"}, -- dropped pixels
	MainframeBeetle = {Mote = C3(90, 255, 120), Move = "Streak"}, -- data rain
	CrystalHeartGolem = {Mote = C3(200, 240, 255), Mote2 = C3(255, 150, 230), Move = "Inward", Big = 1.2}, -- glints drawn to the heart
	FinalBoss = {Mote = C3(255, 60, 60), Move = "Crackle", Big = 1.2}, -- overload sparks
}

local MOVES = {
	Rise = {Lifetime = NumberRange.new(0.9, 1.5), Speed = NumberRange.new(0.3, 0.8), Acceleration = Vector3.new(0, 2.2, 0), Drag = 1},
	Fall = {Lifetime = NumberRange.new(1.6, 2.4), Speed = NumberRange.new(0.1, 0.3), Acceleration = Vector3.new(0, -0.5, 0), Drag = 0.5, RotSpeed = NumberRange.new(-90, 90)},
	Drift = {Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(0.1, 0.3), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.3},
	Crackle = {Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(1.5, 3), Acceleration = Vector3.zero, Drag = 6, RotSpeed = NumberRange.new(-360, 360)},
	Streak = {Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(1, 1.8), Acceleration = Vector3.new(0, 0.5, 0), Drag = 2, Squash = NumberSequence.new(-1.2)},
	Inward = {Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(0.8, 1.4), Acceleration = Vector3.zero, Drag = 0.5, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward},
}
local TEXTURES = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds"}

function Kit.rarity(pet)
	local tier = pet:GetAttribute("Tier")
	local r = Kit.RARITY[tier]
	if not r then
		return
	end
	pet.Outline.OutlineColor = r.Color
	local body = pet.Body
	local st = Kit.AURAS[pet.Name] or {Mote = Color3.new(1, 1, 1), Move = "Drift"}
	local big = (st.Big or 1) * 0.22
	local old = body:FindFirstChild("RarityAura")
	if old then
		old:Destroy()
	end
	local props = {Name = "RarityAura", Texture = TEXTURES[st.Texture or "spark"], Rate = r.Rate,
		Shape = st.Move == "Inward" and Enum.ParticleEmitterShape.Sphere or Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, LightEmission = 1, LightInfluence = 0,
		Color = ColorSequence.new({ColorSequenceKeypoint.new(0, st.Mote), ColorSequenceKeypoint.new(0.5, st.Mote2 or st.Mote:Lerp(r.Color, 0.5)), ColorSequenceKeypoint.new(1, r.Color)}),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, big), NumberSequenceKeypoint.new(1, 0)})}
	for k, v in pairs(MOVES[st.Move]) do
		props[k] = v
	end
	Kit.make("ParticleEmitter", body, props)
	-- Secret: a ring of light pulses out over the ground beneath it, like a summoning circle
	if tier == 7 and not pet.Root:FindFirstChild("RarityRing") then
		local a = Kit.make("Attachment", pet.Root, {Name = "RarityRing", Position = Vector3.new(0, 0.1, 0), Orientation = Vector3.new(0, 0, 90)})
		Kit.make("ParticleEmitter", a, {Name = "RarityRing", Texture = TEXTURES.spark, Rate = 14, EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(180, 0), Lifetime = NumberRange.new(0.9), Speed = NumberRange.new(2.4), Drag = 1.2,
			LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(st.Mote, r.Color),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.1)})})
	end
	local lights = 0
	for _, d in ipairs(pet:GetDescendants()) do
		if d:IsA("Light") then
			lights += 1
		end
	end
	if lights < Kit.LIGHTS[pet:GetAttribute("Tier")] and not pet:FindFirstChild("RarityGlow", true) then
		local a = Kit.make("Attachment", body, {Name = "RarityCore"})
		Kit.make("PointLight", a, {Name = "RarityGlow", Color = r.Color, Brightness = 0.9, Range = 9, Shadows = false})
	end
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

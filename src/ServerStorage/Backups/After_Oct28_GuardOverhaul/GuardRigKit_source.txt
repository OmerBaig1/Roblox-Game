--[[
	GuardRigKit (Studio-only build tool): turns a generated character mesh into a shopkeeper rig.

	The generator returns one sculpted body already split into head, torso, left/right arm and left/right leg.
	rig() renames those parts, scales the body to TARGET_H studs (the server scales it up to giant size), stands it
	on y = 0 facing -Z, adds an invisible HumanoidRootPart (the only solid part) and joins everything with Motor6Ds
	named like a Roblox rig: Root, Neck, LeftShoulder, RightShoulder, LeftHip, RightHip.

	Joint placement (joints()), shared by rig() and refit():
	  sides     come from where the parts really are (facing -Z, the left side is -X), never from the generator's
	            labels, which swap left and right on some meshes
	  Root      pivots at the pelvis (midway between the hip joints), so a lean bends the body over the legs instead of swinging the
	            legs through the floor
	  shoulder  the arm's top inner corner, but never above the torso's shoulder line or outside the torso's depth:
	            an arm that holds a lance or a sword has bounds far bigger than the arm itself
	  hip       top of the leg; neck = base of the head
	GuardMotion animates these joints on each player's screen.

	Usage (Edit, command bar):
	  require(GuardRigKit).rig(sourceModel, "L03")  -> new model in ServerStorage.GuardModels
	  require(GuardRigKit).refit(model)              -> re-places the joints of an existing rig
]]

local K = {}
K.TARGET_H = 5.2

local MAP = {
	{"left arm", "LeftArm"}, {"right arm", "RightArm"}, {"left leg", "LeftLeg"}, {"right leg", "RightLeg"},
	{"torso", "Torso"}, {"head", "Head"},
}

local function joint(name, p0, p1, pivot)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = p0.CFrame:Inverse() * CFrame.new(pivot)
	m.C1 = p1.CFrame:Inverse() * CFrame.new(pivot)
	m.Parent = p1
	return m
end

local function top(p) return p.Position.Y + p.Size.Y / 2 end
local function bottom(p) return p.Position.Y - p.Size.Y / 2 end

-- Builds every joint for a model standing at rest (facing -Z). Returns the hip line height above the feet.
local function joints(model)
	local P = {}
	for _, n in ipairs({"Torso", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "HumanoidRootPart"}) do
		P[n] = model:FindFirstChild(n)
		assert(P[n], model.Name .. ": missing " .. n)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("Weld") then
			d:Destroy()
		end
	end
	-- left is -X
	for _, pair in ipairs({{"LeftArm", "RightArm"}, {"LeftLeg", "RightLeg"}}) do
		if P[pair[1]].Position.X > P[pair[2]].Position.X then
			P[pair[1]], P[pair[2]] = P[pair[2]], P[pair[1]]
			P[pair[1]].Name, P[pair[2]].Name = pair[1], pair[2]
		end
	end
	local T, H, root = P.Torso, P.Head, P.HumanoidRootPart
	local LL, RL = P.LeftLeg, P.RightLeg
	local floor = math.min(bottom(LL), bottom(RL), bottom(T))
	local hipY = (top(LL) + top(RL)) / 2 - 0.1 * (LL.Size.Y + RL.Size.Y) / 2
	-- the pelvis: exactly between the two hip joints, so a lean turns about the hips themselves
	local hipL = Vector3.new(LL.Position.X, top(LL) - 0.1 * LL.Size.Y, LL.Position.Z)
	local hipR = Vector3.new(RL.Position.X, top(RL) - 0.1 * RL.Size.Y, RL.Position.Z)
	-- both hips on one axis through the pelvis (one generated leg can sit a little higher or further back than the
	-- other): then leaning turns each leg exactly in place
	local pelvis = (hipL + hipR) / 2
	hipL = Vector3.new(hipL.X, pelvis.Y, pelvis.Z)
	hipR = Vector3.new(hipR.X, pelvis.Y, pelvis.Z)
	root.CFrame = CFrame.new(T.Position.X, hipY + 1, T.Position.Z)
	joint("Root", root, T, pelvis)
	joint("Neck", T, H, Vector3.new(H.Position.X, bottom(H) + 0.15 * H.Size.Y, H.Position.Z))
	local shoulderLine = top(T) - 0.12 * T.Size.Y
	for _, side in ipairs({{P.LeftArm, -1, "LeftShoulder"}, {P.RightArm, 1, "RightShoulder"}}) do
		local arm, sx = side[1], side[2]
		local inner = arm.Position.X - sx * arm.Size.X / 2
		local x = inner + sx * math.min(arm.Size.X * 0.3, 0.35)
		local y = math.min(top(arm) - 0.12 * math.min(arm.Size.Y, 2.6), shoulderLine)
		local z = math.clamp(arm.Position.Z, T.Position.Z - T.Size.Z * 0.3, T.Position.Z + T.Size.Z * 0.3)
		joint(side[3], T, arm, Vector3.new(x, y, z))
	end
	joint("LeftHip", T, LL, hipL)
	joint("RightHip", T, RL, hipR)
	return hipY - floor
end

function K.rig(src, name)
	local copy = src:Clone()
	local parts = {}
	for _, p in ipairs(copy:GetDescendants()) do
		if p:IsA("BasePart") then
			local lname = p.Name:lower()
			for _, pair in ipairs(MAP) do
				if lname:find(pair[1], 1, true) and not parts[pair[2]] then
					parts[pair[2]] = p
					break
				end
			end
		end
	end
	for _, pair in ipairs(MAP) do
		assert(parts[pair[2]], name .. ": no " .. pair[1] .. " in the generated mesh")
	end
	-- scale to the standard height and stand on y = 0, centred on x = z = 0
	local model = Instance.new("Model")
	model.Name = name
	for nm, p in pairs(parts) do
		p.Name = nm
		p.Parent = model
	end
	copy:Destroy()
	local cf, size = model:GetBoundingBox()
	model:ScaleTo(K.TARGET_H / size.Y)
	cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(-cf.Position.X, size.Y / 2 - cf.Position.Y, -cf.Position.Z))
	for _, p in pairs(parts) do
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = true
	end
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = true
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root
	local hip = joints(model)
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = hip
	hum.Parent = model
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
		end
	end
	local store = game:GetService("ServerStorage"):FindFirstChild("GuardModels") or Instance.new("Folder")
	store.Name = "GuardModels"
	store.Parent = game:GetService("ServerStorage")
	local old = store:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model:PivotTo(CFrame.new(0, model:GetPivot().Position.Y, 0))
	model.Parent = store
	return model
end

-- Re-places the joints of an already rigged model (parts must be at rest, as stored). Keeps the root where it was.
function K.refit(model)
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(0, pivot.Y, 0))
	local hip = joints(model)
	model:FindFirstChildOfClass("Humanoid").HipHeight = hip
	model:PivotTo(CFrame.new(pivot.Position.X, model:GetPivot().Y, pivot.Position.Z))
	return model
end

return K

--[[
	PoseView (Studio-only): poses an anchored copy of a guard exactly as GuardMotion would on a player's screen, so
	poses can be checked from any angle in Edit mode. PoseView.show(level, poseFn, cframe) -> model in
	workspace.GuardGallery; poseFn(p) fills a GuardKit pose.
]]
local K = require(game:GetService("ReplicatedStorage").GuardKit)
local PV = {}

function PV.apply(model, pose)
	local rig = K.measure(model)
	local tr = K.solve(rig, pose)
	local J = rig.J
	local function place(key)
		local j = J[key]
		j.Part1.CFrame = j.Part0.CFrame * j.C0 * tr[key] * j.C1:Inverse()
	end
	place("Root")
	for _, key in ipairs({"Neck", "LS", "RS", "LH", "RH"}) do
		place(key)
	end
end

function PV.show(level, poseFn, cf)
	local folder = workspace:FindFirstChild("GuardGallery") or Instance.new("Folder")
	folder.Name = "GuardGallery"
	folder.Parent = workspace
	local m = game:GetService("ServerStorage").GuardModels[string.format("L%02d", level)]:Clone()
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	m:PivotTo(cf * CFrame.new(0, m:GetPivot().Y, 0))
	m.Parent = folder
	local pose = K.newPose()
	poseFn(pose)
	PV.apply(m, pose)
	return m
end

function PV.floor(center, size)
	local folder = workspace:FindFirstChild("GuardGallery")
	local f = Instance.new("Part")
	f.Anchored = true
	f.Size = Vector3.new(size.X, 0.2, size.Z)
	f.CFrame = CFrame.new(center.X, -0.1, center.Z)
	f.Color = Color3.fromRGB(90, 95, 110)
	f.Material = Enum.Material.SmoothPlastic
	f.Transparency = 0.15
	f.Parent = folder
	return f
end

return PV

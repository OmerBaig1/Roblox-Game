--[[
	STEAL A GAME - KIT
	Small helpers shared by every server module: making parts, labels, prompts,
	number formatting, and the remote events the client listens to.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

local Kit = {}
Kit.M = Enum.Material
Kit.rng = Random.new(2026)
Kit.DARK = Color3.fromRGB(35, 35, 45)
Kit.SKIN = Color3.fromRGB(255, 204, 153)
Kit.RED = Color3.fromRGB(255, 80, 80)
Kit.GREEN = Color3.fromRGB(90, 255, 120)
Kit.GOLD = Color3.fromRGB(255, 210, 60)
Kit.BLUE = Color3.fromRGB(80, 170, 255)

function Kit.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

------------------------------------------------------------------
-- REMOTES
------------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("StealAGameRemotes")
if remotes then
	remotes:Destroy()
end
remotes = Instance.new("Folder")
remotes.Name = "StealAGameRemotes"
remotes.Parent = ReplicatedStorage
Kit.Remotes = remotes

function Kit.event(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

function Kit.func(name)
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotes
	return r
end

Kit.NotifyEvent = Kit.event("Notify")

function Kit.notify(player, text, color)
	if player and player.Parent then
		Kit.NotifyEvent:FireClient(player, text, color or Color3.new(1, 1, 1))
	end
end

-- Shopkeepers walk through decorations so they never get stuck on them
pcall(function() PhysicsService:RegisterCollisionGroup("Guards") end)
pcall(function() PhysicsService:RegisterCollisionGroup("Decor") end)
pcall(function() PhysicsService:CollisionGroupSetCollidable("Guards", "Decor", false) end)
-- Players pass through shopkeepers (catching is by distance), so bumping one never knocks its body apart
pcall(function() PhysicsService:RegisterCollisionGroup("Players") end)
pcall(function() PhysicsService:CollisionGroupSetCollidable("Guards", "Players", false) end)

------------------------------------------------------------------
-- NUMBERS
------------------------------------------------------------------
local SUFFIXES = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
function Kit.fmt(n)
	n = tonumber(n) or 0
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = math.min(#SUFFIXES, math.floor(math.log10(n) / 3))
	local v = n / 10 ^ (i * 3)
	return (v >= 100 and string.format("%d", math.floor(v)) or string.format("%.1f", math.floor(v * 10) / 10)) .. SUFFIXES[i]
end

function Kit.fmtTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor(seconds % 3600 / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

------------------------------------------------------------------
-- PARTS
------------------------------------------------------------------
function Kit.part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

-- Vertical cylinder (Roblox cylinders point along X, so we tip them up)
function Kit.cylinder(parent, height, diameter, cf, props)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	return Kit.part(parent, props)
end

function Kit.wedge(parent, props)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	for key, value in pairs(props) do
		w[key] = value
	end
	w.Parent = parent
	return w
end

-- Floating labels are sized in studs so they behave like real signs
-- (width/height are "pixels" at 28 per stud)
function Kit.billboard(adornee, width, height, offsetY, text, maxDistance)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(width / 28, 0, height / 28, 0)
	bb.LightInfluence = 0
	bb.StudsOffset = Vector3.new(0, offsetY, 0)
	bb.MaxDistance = maxDistance or 150
	bb.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.RichText = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = bb
	bb.Parent = adornee
	return label
end

function Kit.surfaceText(part, face, text, color, pixelsPerStud)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pixelsPerStud or 40
	sg.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(0.92, 0.8)
	t.Position = UDim2.fromScale(0.04, 0.1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.RichText = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = sg
	sg.Parent = part
	return t
end

function Kit.prompt(parent, action, object, hold, distance, tag)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object or ""
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = distance or 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	if tag then
		CollectionService:AddTag(prompt, tag)
	end
	return prompt
end

function Kit.setGroup(root, group)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = group
		end
	end
end

return Kit

--[[
	Vip: how a VIP owner looks, to everyone: a crown and a gold shimmer on the character, a VIP title beside their name, and a dressed-up
	base. Only looks: the money and speed bonuses are in the StealAGame script's moneyMult and refreshMultipliers, once each. Everything
	here clears what it made before making it again, so calling it twice can't double anything. Nothing here collides.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vip = {}
local GOLD, DEEP = Color3.fromRGB(255, 205, 70), Color3.fromRGB(214, 140, 20)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local function clear(parent, name)
	local old = parent and parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

function Vip.character(player, on)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	if not (hum and root and head) then
		return
	end
	clear(char, "VipLook")
	clear(root, "VipAura")
	clear(root, "VipRing")
	hum.DisplayDistanceType = on and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
	if not on then
		return
	end
	local look = Instance.new("Folder")
	look.Name = "VipLook"
	look.Parent = char
	-- the crown floats just over the head, clear of hats, and goes wherever the head goes
	local crown = ReplicatedStorage.VipCrown:Clone()
	crown.Size = crown.Size * (2.3 / crown.Size.X) -- a set size: avatars' heads vary, and it has to read from a distance
	crown.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + crown.Size.Y / 2 + 0.45, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = head, crown
	weld.Parent = crown
	crown.Parent = look
	-- the title beside the name, in place of the usual name tag
	local tag = Instance.new("BillboardGui")
	tag.Name = "VipTitle"
	tag.Adornee = head
	tag.Size = UDim2.fromOffset(340, 34)
	tag.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + crown.Size.Y + 1.3, 0)
	tag.MaxDistance = 110
	tag.AlwaysOnTop = false -- on top, it didn't draw in play captures; off also keeps names from showing through walls
	tag.Parent = look
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 6)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = tag
	local pill = Instance.new("TextLabel")
	pill.LayoutOrder = 1
	pill.Size = UDim2.fromOffset(46, 24)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	pill.Font = Enum.Font.FredokaOne
	pill.Text = "VIP"
	pill.TextSize = 18
	pill.TextColor3 = Color3.fromRGB(70, 34, 0)
	pill.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = pill
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(Color3.fromRGB(255, 236, 140), DEEP)
	shine.Parent = pill
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(90, 46, 0)
	edge.Thickness = 1.5
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = pill
	local name = Instance.new("TextLabel")
	name.LayoutOrder = 2
	name.AutomaticSize = Enum.AutomaticSize.X
	name.Size = UDim2.fromOffset(0, 28)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = player.DisplayName
	name.TextSize = 20
	name.TextColor3 = Color3.fromRGB(255, 240, 190)
	name.TextStrokeTransparency = 0.35
	name.Parent = tag
	-- a slow gold shimmer round the body, and a soft ring of it at the feet
	local aura = Instance.new("Attachment")
	aura.Name = "VipAura"
	aura.Parent = root
	local shimmer = Instance.new("ParticleEmitter")
	shimmer.Texture = SPARK
	shimmer.Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), GOLD)
	shimmer.LightEmission = 0.4
	shimmer.LightInfluence = 0
	shimmer.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.42), NumberSequenceKeypoint.new(1, 0)})
	shimmer.Lifetime = NumberRange.new(0.7, 1.3)
	shimmer.Rate = 11
	shimmer.Speed = NumberRange.new(1.5, 3)
	shimmer.SpreadAngle = Vector2.new(180, 180)
	shimmer.Acceleration = Vector3.new(0, 2, 0)
	shimmer.Parent = aura
	local ring = Instance.new("Attachment")
	ring.Name = "VipRing"
	ring.Position = Vector3.new(0, -2.7, 0)
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Parent = root
	local foot = Instance.new("ParticleEmitter")
	foot.Texture = SPARK
	foot.Color = ColorSequence.new(GOLD, DEEP)
	foot.LightEmission = 0.3
	foot.LightInfluence = 0
	foot.Size = NumberSequence.new(0.35, 0)
	foot.Lifetime = NumberRange.new(0.45, 0.7)
	foot.Rate = 16
	foot.Speed = NumberRange.new(4, 5.5)
	foot.SpreadAngle = Vector2.new(180, 0)
	foot.EmissionDirection = Enum.NormalId.Top
	foot.Parent = ring
end

-- A VIP's base: gold along the gate, a pair of gold columns with lamps either side of it, gold edging up the path to it and a big
-- crown over the entrance. Plain decoration on the plot itself, so it survives a bigger base being bought.
function Vip.base(plot, C, Kit, player, on)
	clear(plot.Model, "VipDecor")
	if plot.SignLabel and player then
		plot.SignLabel.Text = (on and '<font color="#ffcd46">VIP</font> ' or "") .. player.DisplayName .. "'s Base"
	end
	if not on then
		return
	end
	local decor = Instance.new("Folder")
	decor.Name = "VipDecor"
	decor.Parent = plot.Model
	local front = -C.PLOT_D / 2
	local width = C.PLOT_W
	local function piece(props)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Parent = decor
		return p
	end
	local function at(x, y, z)
		return plot.CF * CFrame.new(x, y, z)
	end
	-- along the gate
	for _, y in ipairs({14.7, 18}) do
		piece({Name = "VipGateTrim", Size = Vector3.new(width + 1, 0.5, 0.5), CFrame = at(0, y, front - 1.1), Color = GOLD, Material = Enum.Material.Neon})
	end
	-- the columns
	for _, sx in ipairs({-1, 1}) do
		local x = sx * (width / 2 + 3)
		piece({Name = "VipColumn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(19, 2.6, 2.6), CFrame = at(x, 9.5, front - 3) * CFrame.Angles(0, 0, math.pi / 2), Color = GOLD, Material = Enum.Material.Metal})
		piece({Name = "VipColumnFoot", Size = Vector3.new(4, 1.2, 4), CFrame = at(x, 0.6, front - 3), Color = DEEP, Material = Enum.Material.Metal})
		piece({Name = "VipColumnCap", Size = Vector3.new(3.6, 0.8, 3.6), CFrame = at(x, 19.4, front - 3), Color = DEEP, Material = Enum.Material.Metal})
		local lamp = piece({Name = "VipLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = at(x, 21.3, front - 3), Color = Color3.fromRGB(255, 225, 130), Material = Enum.Material.Neon})
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = GOLD, 26, 1, false
		light.Parent = lamp
		-- gold edging up the path
		piece({Name = "VipPathEdge", Size = Vector3.new(0.7, 0.1, C.BASE_YARD), CFrame = at(sx * 7.1, 0.34, front - C.BASE_YARD / 2), Color = GOLD, Material = Enum.Material.Neon})
	end
	-- the crown over the entrance
	local crown = ReplicatedStorage.VipCrown:Clone()
	crown.Anchored = true
	crown.Size = crown.Size * (11 / crown.Size.X)
	crown.CFrame = at(0, 19 + crown.Size.Y / 2, front - 1.5)
	crown.Parent = decor
end

return Vip

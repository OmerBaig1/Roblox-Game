--[[
	RarityFx: each rarity from Epic up has its own signature effect on the game case. The server only tags the case (RarityFx,
	with its rarity in FxRarity, and never while a Vault game's rarity is still a secret). The effects are built here, only for
	the nearest few cases, and removed again when you walk away, so a full base stays cheap.
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local NEAR, FAR = 130, 160 -- studs from the camera: built inside NEAR, removed beyond FAR
local MAX_ACTIVE = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and 8 or 18

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)
local TAU = 2 * math.pi

local function seq(a, b)
	return ColorSequence.new(a, b or a)
end
local function num(...)
	local args, points = {...}, {}
	for i, v in ipairs(args) do
		points[i] = NumberSequenceKeypoint.new((i - 1) / (#args - 1), v)
	end
	return NumberSequence.new(points)
end
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 70, 90)), ColorSequenceKeypoint.new(0.2, rgb(255, 190, 60)), ColorSequenceKeypoint.new(0.4, rgb(120, 255, 110)),
	ColorSequenceKeypoint.new(0.6, rgb(70, 225, 255)), ColorSequenceKeypoint.new(0.8, rgb(130, 110, 255)), ColorSequenceKeypoint.new(1, rgb(255, 110, 230)),
})

-- one case's effect: everything it makes goes in a list so it can be removed in one go, and steps runs every frame
local function newKit(item)
	local kit = {Parts = {}, Steps = {}, Item = item, H = item.Size.Y / 2, W = math.max(item.Size.X, item.Size.Y) / 2}
	function kit.add(class, props)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Name = "RarityFx"
		table.insert(kit.Parts, o)
		return o
	end
	function kit.point(pos)
		return kit.add("Attachment", {Position = pos or Vector3.zero, Parent = item})
	end
	-- particles from a point on the case
	function kit.emit(pos, props)
		props.LightEmission = props.LightEmission or 0
		props.LightInfluence = 0
		props.Parent = kit.point(pos)
		props.Texture = props.Texture or SPARK
		return kit.add("ParticleEmitter", props)
	end
	-- the same from both side edges of the case. Effects must start clear of its body (which is solid and hides whatever is
	-- inside it), and this keeps the cover readable too.
	function kit.sides(y, props)
		local x = item.Size.X / 2 + 0.25
		for _, sx in ipairs({-1, 1}) do
			local copy = table.clone(props)
			kit.emit(Vector3.new(sx * x, y, 0), copy)
		end
	end
	-- a glowing streak that follows path(t), a point relative to the case. A Life equal to the path's period draws the whole
	-- shape as one unbroken line; a short Life makes a comet.
	function kit.streak(path, o)
		local a, b = kit.point(), kit.point()
		kit.add("Trail", {Attachment0 = a, Attachment1 = b, Lifetime = o.Life, Color = o.Color, LightEmission = 0, LightInfluence = 0, FaceCamera = true, MinLength = 0.05,
			WidthScale = o.Taper and num(1, 0.1) or num(1, 1), Transparency = o.Fade or num(0, 1), Parent = item})
		local half = Vector3.new(0, o.Width * 0.8, 0) -- bold enough to read from across the base
		table.insert(kit.Steps, function(t)
			local p = path(t)
			a.Position, b.Position = p + half, p - half
		end)
		if o.Head then
			local e = kit.add("ParticleEmitter", {Texture = SPARK, Color = seq(o.Head), LightEmission = 0, LightInfluence = 0, Rate = 30, Size = num((o.HeadSize or 0.7) * 1.5, 0), Lifetime = NumberRange.new(0.18, 0.3), Speed = NumberRange.new(0, 0.3), Parent = a})
			return e
		end
	end
	-- a straight beam between two points; moving either is up to the caller
	function kit.beam(a, b, o)
		return kit.add("Beam", {Attachment0 = a, Attachment1 = b, Color = o.Color, Width0 = o.W0, Width1 = o.W1, Transparency = o.Fade, LightEmission = 0, LightInfluence = 0, FaceCamera = true, Segments = 4, Parent = item})
	end
	-- a soft column of light rising through the case (hidden while it's carried: it would stand in the carrier's face)
	function kit.pillar(color, width, height)
		local low, high = kit.point(Vector3.new(0, -kit.H, 0)), kit.point(Vector3.new(0, kit.H + height, 0))
		local beam = kit.beam(low, high, {Color = color, W0 = width, W1 = width * 0.45, Fade = num(0.55, 0.72, 1)})
		table.insert(kit.Steps, function(t)
			beam.Enabled = item.Anchored
		end)
	end
	return kit
end

local function circle(radius, y, speed, phase, tilt)
	tilt = tilt or 0
	return function(t)
		local a = t * speed + (phase or 0)
		local x, z = math.cos(a) * radius, math.sin(a) * radius
		return Vector3.new(x, y + x * math.tan(tilt), z)
	end
end

-- the stage each rarity stands on: a neon frame round the case and a dark backdrop, so the effects read against any wall
local LOOK = {
	[4] = {Frame = rgb(90, 20, 255), Back = rgb(22, 8, 62)},
	[5] = {Frame = rgb(255, 95, 0), Back = rgb(58, 24, 2)},
	[6] = {Frame = rgb(255, 35, 65), Back = rgb(48, 6, 12)},
	[7] = {Frame = rgb(255, 235, 90), Back = rgb(70, 44, 6)},
	[8] = {Frame = rgb(0, 255, 215), Back = rgb(2, 30, 42)},
	[9] = {Frame = rgb(255, 90, 235), Back = rgb(20, 8, 52)},
	[10] = {Frame = rgb(255, 255, 255), Back = rgb(8, 6, 22)},
}

local FX = {}

-- EPIC: two comets on crossing orbits
FX[4] = function(k)
	local a, b = rgb(190, 90, 255), rgb(95, 20, 235)
	local r = k.W + 0.9
	for i = 0, 1 do
		k.streak(circle(r, 0, 2.6, i * math.pi, i == 0 and 0.4 or -0.4), {Life = 1.25, Width = 0.6, Color = seq(a, b), Taper = true, Fade = num(0, 0.55), Head = a, HeadSize = 1.2})
	end
end

-- LEGENDARY: a gold crown ring over the case, a pillar of light and embers floating up
FX[5] = function(k)
	local gold, deep = rgb(255, 195, 30), rgb(255, 120, 0)
	k.pillar(seq(gold, deep), 3.4, 9)
	k.streak(circle(k.W * 0.9, k.H + 1.2, 2.2, 0), {Life = TAU / 2.2, Width = 0.32, Color = seq(gold), Fade = num(0, 0.15), Head = gold, HeadSize = 1.1})
	k.streak(circle(k.W + 0.8, -k.H + 0.3, -1.3, 1), {Life = 1.3, Width = 0.35, Color = seq(gold, deep), Taper = true})
	k.sides(-k.H, {Color = seq(gold, deep), Rate = 14, Size = num(0.55, 0.4, 0), Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, 1.5, 0)})
end

-- MYTHIC: the case is on fire: flames licking up, embers thrown out, and a burning ring round its foot
FX[6] = function(k)
	local hot, red = rgb(255, 170, 60), rgb(255, 30, 60)
	local flames = {Texture = FIRE, Color = seq(hot, red), LightEmission = 0.3, Rate = 24, Size = num(1.7, 2.3, 0.3), Transparency = num(0.05, 0.2, 1), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(5, 8), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90)}
	k.sides(-k.H, flames)
	k.emit(Vector3.new(0, k.H, 0), table.clone(flames))
	k.emit(Vector3.new(0, k.H, 0), {Color = seq(hot, red), Rate = 22, Size = num(0.42, 0), Lifetime = NumberRange.new(0.8, 1.5), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -5, 0)})
	k.emit(Vector3.new(0, k.H, 0), {Texture = SMOKE, LightEmission = 0.1, Color = seq(rgb(90, 25, 25), rgb(30, 20, 20)), Rate = 4, Size = num(1, 3), Transparency = num(0.65, 1), Lifetime = NumberRange.new(1.5, 2.2), Speed = NumberRange.new(2, 3), EmissionDirection = Enum.NormalId.Top})
	k.streak(circle(k.W + 0.6, -k.H + 0.2, 3.1, 0), {Life = TAU / 3.1, Width = 0.34, Color = seq(hot, red), Fade = num(0, 0.3)})
end

-- GODLY: a sun: long rays turning behind the cover, a halo over it and a blazing pillar
FX[7] = function(k)
	local sun, pale = rgb(255, 170, 0), rgb(255, 235, 60)
	k.pillar(seq(pale, sun), 4.4, 11)
	local center = k.point(Vector3.new(0, 0, 0.8))
	local RAYS = 8
	for i = 1, RAYS do
		local tip = k.point()
		k.beam(center, tip, {Color = seq(pale, sun), W0 = 2, W1 = 0.15, Fade = num(0, 0.5)})
		local base = (i - 1) / RAYS * TAU
		local length = k.W + (i % 2 == 0 and 2.2 or 3.4)
		table.insert(k.Steps, function(t)
			local a = base + t * 0.55
			local l = length + math.sin(t * 3 + i) * 0.35
			tip.Position = Vector3.new(math.cos(a) * l, math.sin(a) * l, 0.8)
		end)
	end
	k.streak(circle(k.W * 0.85, k.H + 1.4, 2.6, 0), {Life = TAU / 2.6, Width = 0.42, Color = seq(pale, sun), Fade = num(0, 0.1), Head = pale, HeadSize = 1.3})
end

-- SECRET: it isn't quite real: scan rings sliding up and down it, pixels rising off it, and now and then a burst of glitch
FX[8] = function(k)
	local cyan, deep = rgb(0, 235, 215), rgb(0, 110, 255)
	local r = k.W + 0.6
	for i = 0, 1 do
		local spin = circle(r, 0, 5, i * math.pi)
		k.streak(function(t)
			local p = spin(t)
			return Vector3.new(p.X, math.sin(t * 1.5 + i * math.pi) * (k.H + 0.6), p.Z)
		end, {Life = TAU / 5, Width = 0.2, Color = seq(cyan, deep), Fade = num(0, 0.15)})
	end
	-- no texture: plain squares, like pixels
	k.sides(-k.H * 0.4, {Texture = "", Color = seq(cyan, deep), Rate = 18, Size = NumberSequence.new(0.3), Transparency = num(0, 0.1, 1), Lifetime = NumberRange.new(0.9, 1.7), Speed = NumberRange.new(1.5, 3.5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(6, 6)})
	local glitch = k.emit(Vector3.zero, {Texture = "", Color = seq(deep, cyan), Rate = 0, Size = NumberSequence.new(0.45), Transparency = num(0, 1), Lifetime = NumberRange.new(0.15, 0.4), Speed = NumberRange.new(5, 11), SpreadAngle = Vector2.new(180, 8), Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = NumberSequence.new(1.5)})
	local nextGlitch = 0
	table.insert(k.Steps, function(t)
		if t >= nextGlitch then
			nextGlitch = t + 0.7 + math.random() * 1.4
			glitch:Emit(16)
		end
	end)
end

-- CELESTIAL: a pocket of space: a soft nebula, big slow stars, and three small worlds on tilted orbits
FX[9] = function(k)
	local pink, blue = rgb(255, 60, 210), rgb(70, 70, 255)
	k.emit(Vector3.new(0, 0, 1), {Texture = SMOKE, LightEmission = 0.2, Color = seq(pink, blue), Rate = 10, Size = num(2.6, 5), Transparency = num(0.55, 0.45, 1), Lifetime = NumberRange.new(2, 3.2), Speed = NumberRange.new(0.2, 0.7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-25, 25), ZOffset = -1})
	k.emit(Vector3.new(0, 0, -0.7), {Color = seq(rgb(255, 225, 90)), Rate = 8, Size = num(0, 1.5, 0), Lifetime = NumberRange.new(0.7, 1.3), Speed = NumberRange.new(2, 4.5), SpreadAngle = Vector2.new(180, 180), Drag = 3, Rotation = NumberRange.new(0, 360)})
	for i, o in ipairs({{R = 1, S = 1.5, T = 0.35, C = pink}, {R = 1.9, S = -1.05, T = -0.5, C = blue}, {R = 2.8, S = 0.72, T = 0.15, C = rgb(255, 170, 40)}}) do
		k.streak(circle(k.W + o.R, 0, o.S, i * 2.1, o.T), {Life = 1.5, Width = 0.34, Color = seq(o.C), Taper = true, Head = o.C, HeadSize = 1.4})
	end
end

-- INFINITY: a rainbow infinity sign endlessly redrawn in the air over the case, a rainbow ring and a shifting prism pillar
FX[10] = function(k)
	local PERIOD, a = 2.6, k.W + 1.3
	local y = k.H + 2.7
	local function lemniscate(phase)
		return function(t)
			local u = t / PERIOD * TAU + phase
			local d = 1 + math.sin(u) ^ 2
			return Vector3.new(a * math.cos(u) / d, y + a * math.sin(u) * math.cos(u) / d, 0)
		end
	end
	k.streak(lemniscate(0), {Life = PERIOD, Width = 0.5, Color = RAINBOW, Fade = num(0, 0.12), Head = rgb(255, 80, 200), HeadSize = 1.2})
	k.streak(lemniscate(math.pi), {Life = PERIOD * 0.4, Width = 0.32, Color = RAINBOW, Taper = true})
	k.streak(circle(k.W + 0.9, -k.H + 0.3, 2.4, 0), {Life = TAU / 2.4, Width = 0.36, Color = RAINBOW, Fade = num(0, 0.15)})
	local low, high = k.point(Vector3.new(0, -k.H, 0)), k.point(Vector3.new(0, k.H + 12, 0))
	local pillar = k.beam(low, high, {Color = seq(WHITE), W0 = 4.6, W1 = 1.8, Fade = num(0.45, 0.7, 1)})
	local prism = k.emit(Vector3.zero, {Color = RAINBOW, Rate = 34, Size = num(0, 0.8, 0), Lifetime = NumberRange.new(0.7, 1.4), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360)})
	local shade = -1
	table.insert(k.Steps, function(t)
		pillar.Enabled = k.Item.Anchored
		-- a new colour ten times a second is smooth enough, and saves making a sequence every frame
		if math.floor(t * 10) ~= shade then
			shade = math.floor(t * 10)
			local h = (t * 0.22) % 1
			pillar.Color = seq(Color3.fromHSV(h, 0.85, 1), Color3.fromHSV((h + 0.25) % 1, 0.85, 1))
			for _, f in ipairs(k.Frame) do
				f.Part.Color = Color3.fromHSV((h + f.Part.Position.Y * 0.01 + f.Part.Position.X * 0.03) % 1, 0.8, 1)
			end
		end
		prism.Parent.Position = Vector3.new(0, math.sin(t * 2) * k.H * 0.5, -0.7)
	end)
end

-- which cases have an effect right now
local active = {}
local function remove(item)
	local k = active[item]
	if not k then
		return
	end
	active[item] = nil
	for _, o in ipairs(k.Parts) do
		o:Destroy()
	end
	for _, f in ipairs(k.Frame) do
		f.Part.Color, f.Part.Material = f.Color, f.Material
	end
end
local function build(item)
	local make = FX[item:GetAttribute("FxRarity")]
	if make then
		local k = newKit(item)
		k.Frame, k.Case = {}, item.Parent
		-- in a display case: light its frame and hang the backdrop behind the game (not while it's being carried)
		local look = LOOK[item:GetAttribute("FxRarity")]
		local lid = k.Case and k.Case:FindFirstChild("CaseLid")
		local floor = k.Case and k.Case:FindFirstChild("CaseBase")
		if lid and floor then
			for _, p in ipairs(k.Case:GetChildren()) do
				if p:IsA("BasePart") and (p.Name == "CasePost" or p.Name == "CaseLid") then
					table.insert(k.Frame, {Part = p, Color = p.Color, Material = p.Material})
					p.Color, p.Material = look.Frame, Enum.Material.Neon
				end
			end
			-- square to the case, on the side away from the walkway. The number plate faces the walkway; the game itself is no
			-- guide, since it angles in towards the middle of the row.
			local plate = k.Case:FindFirstChild("CaseNumber")
			local back, frame = plate and (lid.Position - plate.Position) * Vector3.new(1, 0, 1) or item.CFrame.ZVector, lid.CFrame
			local axis = math.abs(back:Dot(frame.XVector)) > math.abs(back:Dot(frame.ZVector)) and frame.XVector or frame.ZVector
			axis = back:Dot(axis) < 0 and -axis or axis
			local middle = Vector3.new(lid.Position.X, (lid.Position.Y + floor.Position.Y) / 2, lid.Position.Z) + axis * 2.5
			k.add("Part", {Size = Vector3.new(5, lid.Position.Y - floor.Position.Y, 0.1), CFrame = CFrame.lookAt(middle, middle + axis), Color = look.Back, Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = k.Case})
		end
		make(k)
		active[item] = k
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, k in pairs(active) do
		for _, step in ipairs(k.Steps) do
			step(t)
		end
	end
end)

-- twice a second: the rarest, then nearest, cases within range get an effect; the rest lose theirs
local candidates = {}
while true do
	task.wait(0.5)
	local cam = workspace.CurrentCamera
	if cam then
		local from = cam.CFrame.Position
		table.clear(candidates)
		local seen = {}
		for _, item in ipairs(CollectionService:GetTagged("RarityFx")) do
			if item:IsA("BasePart") and item:IsDescendantOf(workspace) then
				local d = (item.Position - from).Magnitude
				if d <= (active[item] and FAR or NEAR) then
					table.insert(candidates, {Item = item, D = d, R = item:GetAttribute("FxRarity") or 0})
				end
			end
		end
		table.sort(candidates, function(a, b)
			if a.R ~= b.R then
				return a.R > b.R
			end
			return a.D < b.D
		end)
		for i = 1, math.min(MAX_ACTIVE, #candidates) do
			seen[candidates[i].Item] = true
		end
		for item, k in pairs(active) do
			if not seen[item] or item.Parent ~= k.Case then
				remove(item)
			end
		end
		for item in pairs(seen) do
			if not active[item] then
				build(item)
			end
		end
	end
end

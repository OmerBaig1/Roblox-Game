--[[
	TREADMILL EFFECTS (client only)
	Moves everything on the treadmills that TreadModels marks with k.anim, so the server sends nothing per frame.
	Each "TreadAnim" model holds its parts and says how they move:
	  spin    turns round Axis at Speed
	  swing   rocks round Axis by Amp degrees
	  slide   moves back and forth along Offset
	  orbit   circles without turning: A at phase 0, B a quarter later (coupling rods)
	  travel  parts follow the path P1, P2... and start again (bubbles, liquid in a pipe); Wobble, Grow
	  gauge   a part grows and shrinks from one end along its GAxis (liquid level, flames, meters); Amp, Stagger
	  pulse   parts breathe from ColorA to ColorB; Stagger makes a chase, Sharp makes it blink; TransA, TransB
	  flicker like pulse, but uneven (flames, lanterns, bad bulbs)
	  bolt    parts are laid as a jagged line from A to B, redrawn Hz times a second (lightning); Jitter, Off
	Speed is multiplied by Idle with nobody on the belt and Run with someone on it (both ease), so a machine comes
	alive when used. A ParticleEmitter with a RunRate attribute uses that rate while running.
	The upgrade: the old machine (tag TreadOld) breaks apart, the new one (RevealAt attribute) rises out of the ground, and
	everyone nearby sees its name.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end)

local FAR, MID = 260, 90 -- studs: beyond FAR nothing moves, beyond MID it updates less often
local REVEAL_WINDOW = 4 -- a machine that arrives later than this after its purchase just appears

local home = setmetatable({}, {__mode = "k"}) -- where the server put each part, read before anything here moves it
local function homeOf(p)
	local cf = home[p]
	if not cf then
		cf = p.CFrame
		home[p] = cf
	end
	return cf
end

local machines = {} -- the Treadmill model -> {Running, Dist, Hold, Emitters}
local groups = {}   -- each TreadAnim model -> its state

local function machineOf(model)
	local root = model
	while root.Parent and root.Parent:IsA("Model") and root.Name ~= "Treadmill" and root.Name ~= "OldTreadmill" do
		root = root.Parent
	end
	local m = machines[root]
	if not m then
		m = {Model = root, Running = false, Dist = 0, Hold = false, Emitters = nil}
		machines[root] = m
	end
	return m
end

local function attr(m, name, default)
	local v = m:GetAttribute(name)
	if v == nil then
		return default
	end
	return v
end

local function refresh(g)
	g.Dirty = false
	g.Parts = {}
	for _, c in ipairs(g.Model:GetChildren()) do
		if c:IsA("BasePart") then
			table.insert(g.Parts, c)
		end
	end
	table.sort(g.Parts, function(a, b)
		return a.Name < b.Name
	end)
	g.Rel, g.Sizes, g.Lights, g.BaseBright = {}, {}, {}, {}
	for i, p in ipairs(g.Parts) do
		g.Rel[i] = g.Pivot:ToObjectSpace(homeOf(p))
		g.Sizes[i] = p.Size
		local l = p:FindFirstChildOfClass("PointLight")
		if l then
			g.Lights[i] = l
			g.BaseBright[i] = l.Brightness
		end
	end
end

local function register(model)
	if groups[model] then
		return
	end
	local g = {
		Model = model,
		Kind = attr(model, "Fx", "spin"),
		Pivot = model:GetPivot(),
		Machine = machineOf(model),
		Speed = attr(model, "Speed", 1),
		Idle = attr(model, "Idle", 1),
		Run = attr(model, "Run", 1),
		Phase = attr(model, "Phase", 0),
		Mul = attr(model, "Idle", 1),
		Axis = attr(model, "Axis", Vector3.yAxis),
		Amp = attr(model, "Amp", 1),
		Offset = attr(model, "Offset", Vector3.yAxis),
		A = attr(model, "A", Vector3.zero),
		B = attr(model, "B", Vector3.zero),
		Stagger = attr(model, "Stagger", 0),
		Sharp = attr(model, "Sharp", 1),
		Jitter = attr(model, "Jitter", 0.4),
		Off = attr(model, "Off", 0.1),
		Hz = attr(model, "Hz", 12),
		Wobble = attr(model, "Wobble", 0),
		Grow = attr(model, "Grow", 0),
		ColorA = model:GetAttribute("ColorA"),
		ColorB = model:GetAttribute("ColorB"),
		TransA = model:GetAttribute("TransA"),
		TransB = model:GetAttribute("TransB"),
		GAxis = attr(model, "GAxis", "Y"),
		FromEnd = attr(model, "FromEnd", 1),
		Acc = 0,
		NextBolt = 0,
		Dirty = true,
	}
	if g.Kind == "travel" then
		local pts, lens, total = {}, {}, 0
		while model:GetAttribute("P" .. (#pts + 1)) do
			table.insert(pts, model:GetAttribute("P" .. (#pts + 1)))
		end
		for i = 2, #pts do
			lens[i] = (pts[i] - pts[i - 1]).Magnitude
			total += lens[i]
		end
		g.Pts, g.Lens, g.Total = pts, lens, math.max(total, 0.01)
	end
	groups[model] = g
	g.Conns = {
		model.ChildAdded:Connect(function()
			g.Dirty = true
		end),
		model.ChildRemoved:Connect(function()
			g.Dirty = true
		end),
	}
end

local function unregister(model)
	local g = groups[model]
	if g then
		for _, c in ipairs(g.Conns) do
			c:Disconnect()
		end
		groups[model] = nil
	end
end

CollectionService:GetInstanceAddedSignal("TreadAnim"):Connect(register)
CollectionService:GetInstanceRemovedSignal("TreadAnim"):Connect(unregister)
for _, m in ipairs(CollectionService:GetTagged("TreadAnim")) do
	register(m)
end

------------------------------------------------------------------
-- MOVING
------------------------------------------------------------------
local function pointAt(g, t)
	local d = t * g.Total
	for i = 2, #g.Pts do
		if d <= g.Lens[i] or i == #g.Pts then
			return g.Pts[i - 1]:Lerp(g.Pts[i], math.clamp(d / math.max(g.Lens[i], 0.001), 0, 1))
		end
		d -= g.Lens[i]
	end
	return g.Pts[1]
end

local moveParts, moveCFs = {}, {}
local function move(p, cf)
	local n = #moveParts + 1
	moveParts[n] = p
	moveCFs[n] = cf
end

local AXES = {X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis}

local function step(g, dt, now)
	local kind, parts, rel, pivot = g.Kind, g.Parts, g.Rel, g.Pivot
	g.Phase += g.Speed * g.Mul * dt
	local phase = g.Phase
	if kind == "spin" or kind == "swing" or kind == "slide" or kind == "orbit" then
		local cf
		if kind == "spin" then
			cf = pivot * CFrame.fromAxisAngle(g.Axis, phase)
		elseif kind == "swing" then
			cf = pivot * CFrame.fromAxisAngle(g.Axis, math.rad(g.Amp) * math.sin(phase))
		elseif kind == "slide" then
			cf = pivot * CFrame.new(g.Offset * math.sin(phase))
		else
			cf = pivot * CFrame.new(g.A * math.cos(phase) + g.B * math.sin(phase))
		end
		for i, p in ipairs(parts) do
			move(p, cf * rel[i])
		end
	elseif kind == "travel" then
		local n = #parts
		for i, p in ipairs(parts) do
			local t = (phase / g.Total + (i - 1) / n) % 1
			local pos = pointAt(g, t)
			if g.Wobble > 0 then
				pos += Vector3.new(math.sin(phase * 2.3 + i * 2.1), 0, math.cos(phase * 1.9 + i * 1.3)) * g.Wobble
			end
			if g.Grow > 0 then
				p.Size = g.Sizes[i] * (1 + g.Grow * (t - 0.5))
			end
			move(p, pivot * CFrame.new(pos) * (rel[i] - rel[i].Position))
		end
	elseif kind == "gauge" then
		local axis = AXES[g.GAxis]
		for i, p in ipairs(parts) do
			local base = g.Sizes[i]
			local h0 = base[g.GAxis]
			local wave = math.sin(phase + (i - 1) * g.Stagger) + 0.35 * math.sin(phase * 2.7 + i)
			local h = math.max(h0 * (1 + g.Amp * wave), 0.02)
			p.Size = base + axis * (h - h0)
			move(p, pivot * rel[i] * CFrame.new(axis * (h - h0) / 2 * g.FromEnd))
		end
	elseif kind == "pulse" or kind == "flicker" then
		for i, p in ipairs(parts) do
			local v
			if kind == "pulse" then
				v = (0.5 + 0.5 * math.sin(phase + (i - 1) * g.Stagger)) ^ g.Sharp
			else
				v = math.clamp(0.5 + math.noise(phase, i * 7.3) * 1.6, 0, 1)
			end
			if g.ColorA and g.ColorB then
				p.Color = g.ColorA:Lerp(g.ColorB, v)
			end
			if g.TransA then
				p.Transparency = g.TransA + (g.TransB - g.TransA) * v
			end
			local l = g.Lights[i]
			if l then
				l.Brightness = g.BaseBright[i] * (0.35 + 0.65 * v)
			end
		end
	elseif kind == "bolt" then
		if now >= g.NextBolt then
			g.NextBolt = now + 1 / math.max(g.Hz * g.Mul, 0.5)
			local n = #parts
			local off = math.random() < g.Off
			local last = g.A
			for i, p in ipairs(parts) do
				local f = i / n
				local target = g.A:Lerp(g.B, f)
				if i < n then
					target += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2 * g.Jitter * math.sin(f * math.pi)
				end
				local len = (target - last).Magnitude
				p.Transparency = off and 1 or 0
				if len > 0.01 then
					p.Size = Vector3.new(len + 0.04, g.Sizes[i].Y, g.Sizes[i].Z)
					move(p, pivot * CFrame.lookAt((last + target) / 2, target) * CFrame.Angles(0, math.pi / 2, 0))
				end
				last = target
			end
			local l = g.Lights[1]
			if l then
				l.Enabled = not off
			end
		end
	end
end

local function setRunning(m, running)
	m.Running = running
	if not m.Emitters then
		m.Emitters = {}
		for _, d in ipairs(m.Model:GetDescendants()) do
			if d:IsA("ParticleEmitter") and d:GetAttribute("RunRate") then
				table.insert(m.Emitters, {E = d, Idle = d.Rate, Run = d:GetAttribute("RunRate")})
			end
		end
	end
	for _, e in ipairs(m.Emitters) do
		e.E.Rate = running and e.Run or e.Idle
	end
end

local frame, nextDistCheck = 0, 0
RunService.RenderStepped:Connect(function(dt)
	frame += 1
	local now = os.clock()
	if now >= nextDistCheck then
		nextDistCheck = now + 0.5
		local camPos = camera.CFrame.Position
		for model, m in pairs(machines) do
			if not model.Parent then
				machines[model] = nil
			else
				local running = (model:GetAttribute("BeltSpeed") or 0) > 0
				if running ~= m.Running then
					setRunning(m, running)
				end
				local pivot = model:FindFirstChild("Deck")
				m.Dist = pivot and (pivot.Position - camPos).Magnitude or 0
			end
		end
	end
	table.clear(moveParts)
	table.clear(moveCFs)
	for _, g in pairs(groups) do
		local m = g.Machine
		if not m.Hold and m.Dist < FAR and g.Model.Parent then
			if g.Dirty then
				refresh(g)
			end
			local goal = m.Running and g.Run or g.Idle
			g.Mul += (goal - g.Mul) * math.min(1, dt * 2.5)
			g.Acc += dt
			local every = m.Dist > MID and 4 or (g.Kind == "pulse" or g.Kind == "flicker") and 2 or 1
			if frame % every == 0 then
				step(g, g.Acc, now)
				g.Acc = 0
			end
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

------------------------------------------------------------------
-- THE UPGRADE
------------------------------------------------------------------
local function backOut(t)
	local c = 1.4
	t -= 1
	return t * t * ((c + 1) * t + c) + 1
end

-- the bought-over machine: flies outward and drops through the floor (the server removes it after 1 s)
local function breakOld(model)
	local parts, from, dirs = {}, {}, {}
	local centre = model:GetPivot().Position
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(from, d.CFrame)
			local away = d.Position - centre
			table.insert(dirs, Vector3.new(away.X, 0, away.Z).Unit * (3 + math.random() * 4))
		elseif d:IsA("ParticleEmitter") or d:IsA("Fire") then
			d.Enabled = false
		end
	end
	local m = machineOf(model)
	m.Hold = true
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			conn:Disconnect()
			return
		end
		local t = math.min((os.clock() - start) / 0.65, 1)
		local cfs = {}
		for i, cf in ipairs(from) do
			local dir = dirs[i]
			if dir.X ~= dir.X then
				dir = Vector3.zero -- a part dead centre has no way out
			end
			cfs[i] = (cf + dir * t + Vector3.new(0, 5 * t - 26 * t * t, 0)) * CFrame.Angles(t * 2.2, 0, t * (i % 3 - 1) * 2)
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		if t >= 1 then
			conn:Disconnect()
		end
	end)
end

local function bigMoment(model, centre)
	local root = Instance.new("Part")
	root.Name = "TreadReveal"
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.Transparency = 1
	root.Size = Vector3.one
	root.CFrame = CFrame.new(centre + Vector3.new(0, 7, 0))
	root.Parent = workspace

	-- a shock ring along the ground
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 240, 180)
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Size = Vector3.new(0.15, 2, 2)
	ring.CFrame = CFrame.new(centre + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Transparency = 0.6
	ring.Parent = root
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.15, 44, 44), Transparency = 1}):Play()

	-- a burst of sparks
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Color = ColorSequence.new(Color3.fromRGB(255, 225, 120), Color3.new(1, 1, 1))
	burst.Size = NumberSequence.new(1.1, 0)
	burst.Lifetime = NumberRange.new(0.7, 1.5)
	burst.Speed = NumberRange.new(14, 34)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Acceleration = Vector3.new(0, -24, 0)
	burst.LightEmission = 0.9
	burst.Rate = 0
	burst.Parent = root
	burst:Emit(70)

	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://117728785646872" -- the game's reward sting (UIKit "reward")
	s.Volume = 0.7
	s.RollOffMaxDistance = 140
	s.Parent = root
	s:Play()

	-- the name, for everyone standing nearby to read
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(0, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 170
	gui.LightInfluence = 0
	gui.Parent = root
	local function label(text, y, h, color)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, h)
		t.Position = UDim2.fromScale(0, y)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = color
		t.TextStrokeTransparency = 0
		t.Text = text
		t.Parent = gui
	end
	label("NEW TREADMILL!", 0, 0.32, Color3.fromRGB(255, 225, 90))
	label(string.upper(model:GetAttribute("MachineName") or ""), 0.32, 0.68, Color3.new(1, 1, 1))
	TweenService:Create(gui, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(20, 5.5)}):Play()
	task.delay(2.6, function()
		if gui.Parent then
			TweenService:Create(gui, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
		end
	end)
	task.delay(3.2, function()
		root:Destroy()
	end)
end

-- the bought machine rises out of the ground from the bottom up, and everything starts moving once it's whole
local function reveal(model)
	local at = model:GetAttribute("RevealAt")
	if not at or workspace:GetServerTimeNow() - at > REVEAL_WINDOW then
		return
	end
	local m = machineOf(model)
	m.Hold = true
	local parts, homes, delays = {}, {}, {}
	local emitters = {}
	local lowest, highest, centre = math.huge, -math.huge, nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf = homeOf(d)
			if d.Name == "Deck" then
				centre = cf.Position
			end
			-- the deck and belt stay: someone may be running on them
			if not d.CanCollide and d.Name ~= "Slat" then
				table.insert(parts, d)
				table.insert(homes, cf)
				lowest = math.min(lowest, cf.Position.Y)
				highest = math.max(highest, cf.Position.Y)
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Fire") then
			if d.Enabled then
				d.Enabled = false
				table.insert(emitters, d)
			end
		end
	end
	if #parts == 0 then
		m.Hold = false
		return
	end
	local span = math.max(highest - lowest, 1)
	local down = {}
	for i, cf in ipairs(homes) do
		delays[i] = 0.5 * (cf.Position.Y - lowest) / span + math.random() * 0.1
		down[i] = cf - Vector3.new(0, span + 8, 0)
	end
	workspace:BulkMoveTo(parts, down, Enum.BulkMoveMode.FireCFrameChanged)
	local start = os.clock() + 0.45 -- the old machine goes first
	local DUR = 0.6
	local moment = false
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			conn:Disconnect()
			return
		end
		local elapsed = os.clock() - start
		if elapsed < 0 then
			return
		end
		if not moment then
			moment = true
			bigMoment(model, centre or homes[1].Position)
		end
		local cfs, finished = {}, true
		for i, cf in ipairs(homes) do
			local t = math.clamp((elapsed - delays[i]) / DUR, 0, 1)
			if t < 1 then
				finished = false
				cfs[i] = cf - Vector3.new(0, (span + 8) * (1 - backOut(t)), 0)
			else
				cfs[i] = cf
			end
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		if finished then
			conn:Disconnect()
			m.Hold = false
			for _, e in ipairs(emitters) do
				if e.Parent then
					e.Enabled = true
				end
			end
		end
	end)
end

CollectionService:GetInstanceAddedSignal("TreadOld"):Connect(breakOld)
CollectionService:GetInstanceAddedSignal("TreadBelt"):Connect(reveal)

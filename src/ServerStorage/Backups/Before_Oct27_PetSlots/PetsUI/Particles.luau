--[[
	Particles: a small 2D particle layer for the hatching show (ParticleEmitters don't render in ViewportFrames).
	Stepped by the show's frame loop and capped at MAX alive, so a 10-egg hatch can't flood the screen.
	  fx = Particles.new(layerFrame)
	  fx:emit({At = Vector2 (px in the layer), Count, Shape = dot | square | ring | any glyph string,
	           Colors = {...}, Size = {min, max}, Grow = end size multiplier, Speed = {min, max}, Dir = {minDeg, maxDeg}
	           (0 = up, 90 = right), Spread = px of random start offset, Gravity = px/s^2 (+ = down), Drag, Life = {min, max},
	           Spin = {min, max} deg/s, Alpha = start transparency, Target = Vector2 (flies there over its life), Squash, Z})
	  fx:step(dt)   fx:clear()
	fx.Scale multiplies sizes and distances (small eggs in the 10-egg grid), fx.Amount multiplies counts.
]]
local Particles = {}
Particles.__index = Particles
local MAX = 240

local function pick(r, rng)
	if type(r) == "table" then
		return r[1] + (r[2] - r[1]) * rng:NextNumber()
	end
	return r or 0
end

function Particles.new(layer)
	return setmetatable({Layer = layer, List = {}, Rng = Random.new(), Scale = 1, Amount = 1}, Particles)
end

function Particles:emit(def)
	local rng = self.Rng
	local want = (def.Count or 1) * (def.Amount or self.Amount)
	local n = math.floor(want) + (rng:NextNumber() < want % 1 and 1 or 0)
	local sc = def.Scale or self.Scale
	for _ = 1, n do
		if #self.List >= MAX then
			return
		end
		local size = pick(def.Size or {8, 12}, rng) * sc
		local color = def.Colors and def.Colors[rng:NextInteger(1, #def.Colors)] or Color3.new(1, 1, 1)
		local shape = def.Shape or "dot"
		local g, stroke
		if shape == "dot" or shape == "square" then
			g = Instance.new("Frame")
			g.BackgroundColor3 = color
			g.BorderSizePixel = 0
			if shape == "dot" then
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(1, 0)
				c.Parent = g
			end
		elseif shape == "ring" then
			g = Instance.new("Frame")
			g.BackgroundTransparency = 1
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = g
			stroke = Instance.new("UIStroke")
			stroke.Color = color
			stroke.Thickness = math.max(1, size * 0.12)
			stroke.Parent = g
		else
			g = Instance.new("TextLabel")
			g.BackgroundTransparency = 1
			g.Text = shape
			g.TextColor3 = color
			g.TextScaled = true
			g.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		end
		local at = def.At or Vector2.zero
		local spread = (def.Spread or 0) * sc
		if spread > 0 then
			at += Vector2.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * spread
		end
		local life = pick(def.Life or {0.6, 1}, rng)
		local vel
		if def.Target then
			vel = (def.Target - at) / life
		else
			local dir = math.rad(pick(def.Dir or {0, 360}, rng))
			vel = Vector2.new(math.sin(dir), -math.cos(dir)) * pick(def.Speed or {60, 120}, rng) * sc
		end
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Size = UDim2.fromOffset(size, size * (def.Squash or 1))
		g.Position = UDim2.fromOffset(at.X, at.Y)
		g.Rotation = rng:NextNumber(0, 360)
		g.ZIndex = def.Z or 20
		g.Parent = self.Layer
		table.insert(self.List, {
			G = g, Stroke = stroke, Pos = at, Vel = vel, Age = 0, Life = life, Size = size, Grow = def.Grow or 1,
			Gravity = (def.Gravity or 0) * sc, Drag = def.Drag or 0, Spin = pick(def.Spin or {0, 0}, rng), Alpha = def.Alpha or 0,
			Glyph = g:IsA("TextLabel"), Squash = def.Squash or 1, Target = def.Target,
		})
	end
end

function Particles:step(dt)
	local list = self.List
	for i = #list, 1, -1 do
		local p = list[i]
		p.Age += dt
		local k = p.Age / p.Life
		if k >= 1 or not p.G.Parent then
			p.G:Destroy()
			table.remove(list, i)
		else
			if not p.Target then
				p.Vel = p.Vel * math.max(0, 1 - p.Drag * dt) + Vector2.new(0, p.Gravity * dt)
			end
			p.Pos += p.Vel * dt
			local s = p.Size * (1 + (p.Grow - 1) * k)
			p.G.Position = UDim2.fromOffset(p.Pos.X, p.Pos.Y)
			p.G.Size = UDim2.fromOffset(s, s * p.Squash)
			p.G.Rotation += p.Spin * dt
			-- holds, then fades out over the last part of its life
			local a = p.Alpha + (1 - p.Alpha) * math.clamp((k - 0.45) / 0.55, 0, 1) ^ 1.5
			if p.Stroke then
				p.Stroke.Transparency = a
			elseif p.Glyph then
				p.G.TextTransparency = a
			else
				p.G.BackgroundTransparency = a
			end
		end
	end
end

function Particles:clear()
	for _, p in ipairs(self.List) do
		p.G:Destroy()
	end
	table.clear(self.List)
end

return Particles

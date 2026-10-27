--[[
	EggRig: animates an egg from ReplicatedStorage.EggAssets part by part (the contract is in PetLab.Code.EggForge).
	It works inside a ViewportFrame, where nothing simulates, so every part is placed by CFrame on each step.
	  rig = EggRig.new(model)
	  rig.Pose                 the whole egg, in egg space (identity = standing at the origin)
	  rig.Piece.Top / .Bottom / .Free   an extra transform for that piece, in egg space
	  rig.OrbitSpeed, rig.TwinkleSpeed  how fast orbiting ornaments circle and stars twinkle
	  rig.Grow                 0..1: how much of the vine has grown (Fx Grow, by Order)
	  rig:step(dt)             advances orbits, floats and twinkles and places every part
  rig:step(dt, true)       only the orbiting, floating and twinkling parts (Pose and Piece must stay put): far
                           cheaper, as every part moved in a ViewportFrame makes it redraw
	  rig:paint(key, color, a) lerps the parts with that Fx ("Shell" = the two shell halves) toward a colour
	  rig:light(key, k, dim)   the first k (0..1) of those parts by Order at full colour, the rest dimmed
	  rig:reveal(key, k)       the first k of those parts visible, the rest hidden (seam cracks)
	  rig:fade(t, piece)       every part (or one piece's) toward invisible, t = 0..1
]]
local EggRig = {}
EggRig.__index = EggRig

local ID = CFrame.identity

function EggRig.new(model)
	local base = model:GetPivot()
	local self = setmetatable({
		Model = model, Base = base, Pose = ID, Piece = {Top = ID, Bottom = ID, Free = ID},
		Mid = model:GetAttribute("Mid") or 1.25, Seam = model:GetAttribute("Seam") or 1.8,
		OrbitSpeed = 1, TwinkleSpeed = 1, Grow = 1, Orbit = 0, Twinkle = 0, T = 0, Parts = {}, ByFx = {},
	}, EggRig)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= model.PrimaryPart then
			local e = {
				P = p, Off = base:ToObjectSpace(p.CFrame), Size = p.Size, Color = p.Color, T = p.Transparency,
				Piece = p:GetAttribute("Piece") or "Bottom", Fx = p:GetAttribute("Fx"), Order = p:GetAttribute("Order") or 0,
				Axis = p:GetAttribute("Axis"), Speed = p:GetAttribute("Speed") or 1, Phase = math.random() * 6.283,
			}
			table.insert(self.Parts, e)
			local key = (p.Name == "ShellTop" or p.Name == "ShellBottom") and "Shell" or e.Fx
			if key then
				self.ByFx[key] = self.ByFx[key] or {}
				table.insert(self.ByFx[key], e)
			end
		end
	end
	for _, list in pairs(self.ByFx) do
		table.sort(list, function(a, b)
			return a.Order < b.Order
		end)
	end
	return self
end

local MOVING = {Orbit = true, Float = true, Twinkle = true}

function EggRig:step(dt, movingOnly)
	self.T += dt
	self.Orbit += dt * self.OrbitSpeed
	self.Twinkle += dt * self.TwinkleSpeed
	local mid = CFrame.new(0, self.Mid, 0)
	local midInv = mid:Inverse()
	local root = self.Base * self.Pose
	for _, e in ipairs(self.Parts) do
		local off = e.Off
		local fx = e.Fx
		if movingOnly and not MOVING[fx] then
			continue
		end
		if fx == "Orbit" and e.Axis then
			off = mid * CFrame.fromAxisAngle(e.Axis, self.Orbit * e.Speed) * midInv * off
		elseif fx == "Float" then
			off = CFrame.new(0, math.sin(self.T * 1.7 + e.Phase) * 0.09, 0) * off
		elseif fx == "Twinkle" and not e.Held then
			e.P.Transparency = e.T + (0.5 + 0.5 * math.sin(self.Twinkle * 3 + e.Phase * 5)) * 0.75
		elseif fx == "Grow" then
			local k = math.clamp((self.Grow * 1.15 - e.Order) / 0.15, 0, 1)
			if k ~= e.Grown then
				e.Grown = k
				e.P.Size = e.Size * math.max(k, 0.02)
				e.P.Transparency = k < 0.02 and 1 or e.T
			end
		end
		e.P.CFrame = root * self.Piece[e.Piece] * off
	end
end

function EggRig:paint(key, color, a)
	for _, e in ipairs(self.ByFx[key] or {}) do
		e.P.Color = e.Color:Lerp(color, math.clamp(a, 0, 1))
	end
end

function EggRig:light(key, k, dim)
	local list = self.ByFx[key] or {}
	local n = math.floor(#list * math.clamp(k, 0, 1) + 0.5)
	for i, e in ipairs(list) do
		e.P.Color = i <= n and e.Color or e.Color:Lerp(Color3.new(), dim or 0.75)
	end
end

function EggRig:reveal(key, k, color)
	local list = self.ByFx[key] or {}
	local n = math.floor(#list * math.clamp(k, 0, 1) + 0.5)
	for i, e in ipairs(list) do
		e.P.Transparency = i <= n and 0 or 1
		if color then
			e.P.Color = color
		end
	end
end

function EggRig:fade(t, piece)
	for _, e in ipairs(self.Parts) do
		if not piece or e.Piece == piece then
			e.Held = true
			local from = e.Fx == "Crack" and e.P.Transparency or e.T
			e.P.Transparency = math.max(from, e.T + (1 - e.T) * math.clamp(t, 0, 1))
		end
	end
end

return EggRig

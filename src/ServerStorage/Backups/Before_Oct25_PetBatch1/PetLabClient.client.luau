--[[
	PetLabClient (Studio only)
	The server copies this into your PlayerGui during Studio playtests. It never runs on live servers.
	  P  - jump to the Pet Lab, press again to go back
	  L  - a copy of the lab's test pet follows you anywhere (press again to dismiss)
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local lab = workspace:WaitForChild("PetLab")
local code = lab:WaitForChild("Code")
local PetAnimator = require(code:WaitForChild("PetAnimator"))
local Configs = require(code:WaitForChild("PetConfigs"))
local O = lab:GetAttribute("Origin")

-- hint in the corner so you know the keys
local gui = Instance.new("ScreenGui")
gui.Name = "PetLabHint"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 12, 1, -12)
hint.Size = UDim2.fromOffset(330, 26)
hint.BackgroundColor3 = Color3.fromRGB(20, 17, 31)
hint.BackgroundTransparency = 0.2
hint.TextColor3 = Color3.fromRGB(255, 179, 122)
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 14
hint.Text = "PET LAB (Studio only)  ·  P: lab  ·  L: test pet follows"
hint.Parent = gui
Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 6)

-- pets on display spin slowly on the turntable and run their idle
local showcase = {}
for _, m in ipairs(lab:WaitForChild("Pets"):GetChildren()) do
	m:WaitForChild("Root")
	for _, part in ipairs({"Body", "Head", "Tail"}) do
		m:WaitForChild(part)
	end
	if not m.PrimaryPart then
		m.PrimaryPart = m.Root
	end
	local cfg = Configs[m.Name]
	if cfg and m.PrimaryPart then
		table.insert(showcase, {Model = m, Anim = PetAnimator.new(m, cfg), Base = m.PrimaryPart.CFrame})
	end
end

-- the follower
local follower, anim, pos, lastPos, yaw, speed = nil, nil, nil, nil, 0, 0
local SLOT = Vector3.new(-3.6, 0, 1.6) -- left side, clear of the game's own pet slots
local function toggleFollower()
	if follower then
		follower:Destroy()
		follower = nil
		return
	end
	local src = showcase[1] and showcase[1].Model
	if not src then
		return
	end
	follower = src:Clone()
	follower.Name = "PetLabFollower"
	follower.Parent = workspace
	anim = PetAnimator.new(follower, Configs[src.Name])
	pos, lastPos, speed = nil, nil, 0
end

-- the server does the trip (see PetLabDev) so the game's fence check knows you're in the lab
local travel = code:WaitForChild("PetLabTravel")
local function toggleLab()
	travel:FireServer()
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.P then
		toggleLab()
	elseif input.KeyCode == Enum.KeyCode.L then
		toggleFollower()
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, s in ipairs(showcase) do
		s.Model.PrimaryPart.CFrame = s.Base * CFrame.Angles(0, t * 0.35, 0)
		s.Anim:Step(dt, t, 0, 0)
	end
	if not follower then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then
		return
	end
	local feetY = hrp.Position.Y - hum.HipHeight - hrp.Size.Y / 2
	local _, pYaw = hrp.CFrame:ToEulerAnglesYXZ()
	local goal = Vector3.new(hrp.Position.X, feetY, hrp.Position.Z) + CFrame.Angles(0, pYaw, 0):VectorToWorldSpace(SLOT)
	pos = pos and pos:Lerp(goal, 1 - math.exp(-dt * 8)) or goal
	if (pos - goal).Magnitude > 40 then
		pos = goal -- teleported: snap
		lastPos = nil
	end
	local vel = lastPos and (pos - lastPos) / math.max(dt, 1 / 240) or Vector3.zero
	lastPos = pos
	local flat = Vector3.new(vel.X, 0, vel.Z)
	speed += (flat.Magnitude - speed) * (1 - math.exp(-dt * 10))
	-- face where it's going while moving, otherwise the way you face
	local want = speed > 1.5 and math.atan2(-flat.X, -flat.Z) or pYaw
	local d = (want - yaw + math.pi) % (2 * math.pi) - math.pi
	yaw += d * (1 - math.exp(-dt * 8))
	follower.PrimaryPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	anim:Step(dt, t, speed, math.clamp(-d * 1.5, -1, 1))
end)

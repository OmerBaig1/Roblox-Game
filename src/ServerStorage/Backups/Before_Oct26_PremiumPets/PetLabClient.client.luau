--[[
	PetLabClient (Studio only)
	The server copies this into your PlayerGui during Studio playtests. It never runs on live servers.
	  P  - jump to the Pet Lab, press again to go back
	  L  - the next lab pet (roster order) follows you anywhere; after the last one the follower goes away
	  K  - put the selected pet on the turntable
	Every pet in PetLab.Pets idles in place on its gallery row, with the same distance LOD the game will use.
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
hint.Size = UDim2.fromOffset(520, 26)
hint.BackgroundColor3 = Color3.fromRGB(20, 17, 31)
hint.BackgroundTransparency = 0.2
hint.TextColor3 = Color3.fromRGB(255, 179, 122)
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 14
hint.Parent = gui
Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 6)

-- every pet on display idles in place on its gallery row. Pets stream in one by one, so each is added once it
-- has fully arrived.
local gallery = {}
local selected = 0 -- index into gallery, 0 = none
local showHint
local function addPet(m)
	while #m:GetDescendants() < (m:GetAttribute("Descendants") or 0) do
		task.wait()
	end
	m:WaitForChild("Root")
	if not m.PrimaryPart then
		m.PrimaryPart = m.Root
	end
	local cfg = Configs[m.Name]
	if not cfg then
		return
	end
	local cur = gallery[selected]
	table.insert(gallery, {Model = m, Cfg = cfg, Anim = PetAnimator.new(m, cfg)})
	table.sort(gallery, function(a, b)
		return (a.Cfg.No or math.huge) < (b.Cfg.No or math.huge)
	end)
	selected = cur and table.find(gallery, cur) or 0
	showHint()
end

function showHint()
	local g = gallery[selected]
	hint.Text = "PET LAB (Studio only)  ·  P: lab  ·  L: next follower"
		.. (g and string.format(" [%s %d/%d]", g.Model.Name, selected, #gallery) or "")
		.. "  ·  K: turntable"
end
showHint()
local petsFolder = lab:WaitForChild("Pets")
petsFolder.ChildAdded:Connect(addPet)
for _, m in ipairs(petsFolder:GetChildren()) do
	task.spawn(addPet, m)
end

local function spawnCopy(src, name)
	local m = src.Model:Clone()
	m.Name = name
	m.Parent = workspace
	return m, PetAnimator.new(m, src.Cfg)
end

-- the turntable copy (the stage streams in only near the lab, so it's looked up when K is pressed)
local spot, shown, shownAnim
local function toTurntable()
	if shown then
		shown:Destroy()
		shown = nil
	end
	local tt = lab:FindFirstChild("Stage") and lab.Stage:FindFirstChild("Turntable")
	spot = tt and tt:FindFirstChild("PetSpot")
	if spot and gallery[selected] then
		shown, shownAnim = spawnCopy(gallery[selected], "PetLabTurntable")
	end
end

-- the follower
local follower, anim, pos, lastPos, yaw, speed = nil, nil, nil, nil, 0, 0
local SLOT = Vector3.new(-3.6, 0, 1.6) -- left side, clear of the game's own pet slots
local function nextFollower()
	if follower then
		follower:Destroy()
		follower = nil
	end
	selected = selected < #gallery and selected + 1 or 0
	showHint()
	if selected > 0 then
		follower, anim = spawnCopy(gallery[selected], "PetLabFollower")
		pos, lastPos, speed = nil, nil, 0
	end
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
		nextFollower()
	elseif input.KeyCode == Enum.KeyCode.K then
		toTurntable()
	end
end)

local camera = workspace.CurrentCamera
local function camDist(m)
	return (camera.CFrame.Position - m.PrimaryPart.Position).Magnitude
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, g in ipairs(gallery) do
		g.Anim:Step(dt, t, 0, 0, camDist(g.Model))
	end
	if shown then
		shown.PrimaryPart.CFrame = CFrame.new(spot.WorldPosition) * CFrame.Angles(0, t * 0.35, 0)
		shownAnim:Step(dt, t, 0, 0, camDist(shown))
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
	anim:Step(dt, t, speed, math.clamp(-d * 1.5, -1, 1), camDist(follower))
end)

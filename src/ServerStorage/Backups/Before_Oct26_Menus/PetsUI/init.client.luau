--[[
	PetsUI
	The MY PETS bag, the PETS button and the pets that follow every player around. The Pet Hatchery shop
	and the hatching show are in the Hatchery module beside this script.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UI = require(ReplicatedStorage:WaitForChild("UIKit"))
local PetData = require(ReplicatedStorage:WaitForChild("PetData"))
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))
local remotes = ReplicatedStorage:WaitForChild("StealAGameRemotes")
local petFunc = remotes:WaitForChild("Pets")
local player = Players.LocalPlayer
local new, label, fmt = UI.new, UI.label, UI.fmt
local WHITE, BLACK = UI.WHITE, UI.BLACK
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local gui = new("ScreenGui", {Name = "PetsUI", ResetOnSpawn = false, DisplayOrder = 7, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})

------------------------------------------------------------------
-- STATE from the server's attributes
------------------------------------------------------------------
local function decode(name, default)
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute(name) or default)
	end)
	return ok and type(t) == "table" and t or HttpService:JSONDecode(default)
end
local discovered = {} -- pet keys you've ever had this session (the info pages show these in colour)
local function owned()
	local list = decode("PetsOwned", "[]")
	for _, p in ipairs(list) do
		discovered[p.K] = true
	end
	return list
end
owned()

------------------------------------------------------------------
-- 3D PICTURES (ViewportFrames)
------------------------------------------------------------------
local spinning = {} -- [viewport] = {Model, Speed, Base}
local function viewport(parent, model, props)
	local vp = new("ViewportFrame", {
		BackgroundTransparency = 1, Ambient = rgb(200, 200, 210), LightColor = WHITE, LightDirection = Vector3.new(0.4, -1, 0.8),
		Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero, ZIndex = props.ZIndex or 2, Parent = parent,
	})
	model.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local cf, size = model:GetBoundingBox()
	local r = math.max(size.X, size.Y, size.Z)
	local dist = r / (2 * math.tan(math.rad(15))) * (props.Zoom or 1.05)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.3, dist * 0.2, -dist), cf.Position)
	if props.Spin then
		spinning[vp] = {Model = model, Speed = props.Spin, Angle = math.random() * 6}
	end
	if props.Silhouette then
		vp.ImageColor3 = rgb(15, 12, 25)
	end
	return vp
end
RunService.RenderStepped:Connect(function(dt)
	for vp, s in pairs(spinning) do
		if not vp.Parent then
			spinning[vp] = nil
		elseif vp.Visible and UI.shown(vp) then
			s.Angle += dt * s.Speed
			s.Model:PivotTo(CFrame.Angles(0, math.sin(s.Angle) * 0.6, 0))
		end
	end
end)

-- light rays turning behind a picture (rarity coloured)
local raySets = {}
local function rays(parent, color, size, count)
	local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size, BackgroundTransparency = 1, ZIndex = 1, Parent = parent})
	for i = 0, (count or 6) - 1 do
		local ray = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.12, 0, 1, 0), Rotation = i * 180 / (count or 6), BackgroundColor3 = color, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 1, Parent = f}, {UI.corner(1, true)})
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 1)}), Parent = ray})
	end
	local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = color:Lerp(WHITE, 0.4), BackgroundTransparency = 0.7, ZIndex = 1, Parent = f}, {UI.corner(1, true)})
	raySets[f] = {Speed = 25}
	return f, glow
end
RunService.RenderStepped:Connect(function(dt)
	for f, s in pairs(raySets) do
		if not f.Parent then
			raySets[f] = nil
		elseif UI.shown(f) then
			f.Rotation = (f.Rotation + dt * s.Speed) % 360
		end
	end
end)

local function rarityOf(pet)
	return PetData.RARITIES[pet.R]
end

------------------------------------------------------------------
-- THE PET HATCHERY: the shop and the hatching show live in the Hatchery module
------------------------------------------------------------------
require(script:WaitForChild("Hatchery")).init({
	Gui = gui, PetFunc = petFunc, Discovered = discovered, Owned = owned,
	OpenEvent = remotes:WaitForChild("OpenHatchery"),
})

------------------------------------------------------------------
-- MY PETS (pets of the same kind stack together)
------------------------------------------------------------------
local bag = UI.panel(gui, {Name = "MyPets", Title = "MY PETS", Icon = "\u{1F43E}", Color = rgb(255, 160, 60), MaxSize = Vector2.new(940, 640), Size = UDim2.fromScale(0.7, 0.82)})
local bagStats = label({Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -260, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Text = "", Outline = 2.5, Parent = bag.Body})
local bestBtn = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 2), Size = UDim2.fromOffset(200, 40), Text = "EQUIP BEST", Parent = bag.Body}, UI.GREEN)
bestBtn.Activated:Connect(function()
	petFunc:InvokeServer("best")
end)
local bagHint = label({Position = UDim2.fromOffset(20, 36), Size = UDim2.new(1, -260, 0, 18), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rgb(210, 205, 235), Text = "Hatch more at the Pet Hatchery next to the Trail Shop!", Outline = 1.5, Parent = bag.Body})
local bagGrid = UI.scroller(bag.Body, UDim2.fromOffset(14, 62), UDim2.new(1, -28, 1, -72))
new("UIGridLayout", {CellSize = UDim2.fromOffset(158, 222), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bagGrid})
new("UIPadding", {PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = bagGrid})
local bagCards = {}

local function stacks()
	local list = owned()
	local eq = {}
	for _, id in ipairs(decode("PetsEquipped", "[]")) do
		eq[id] = true
	end
	local byKey = {}
	for _, p in ipairs(list) do
		local s = byKey[p.K]
		if not s then
			s = {Key = p.K, Ids = {}, Equipped = {}, Free = {}}
			byKey[p.K] = s
		end
		table.insert(s.Ids, p.I)
		table.insert(eq[p.I] and s.Equipped or s.Free, p.I)
	end
	return byKey, #list
end

local function refreshBag()
	local byKey, count = stacks()
	bagStats.Text = string.format('<font color="#7dff8c">+%s%%</font> install speed   \u{2022}   %d / %d out   \u{2022}   %d / %d pets', fmt(player:GetAttribute("PetBoost") or 0), #decode("PetsEquipped", "[]"), PetData.EQUIP_MAX, count, PetData.MAX_PETS)
	for key, card in pairs(bagCards) do
		if not byKey[key] then
			card.Frame:Destroy()
			bagCards[key] = nil
		end
	end
	for key, s in pairs(byKey) do
		local pet = PetData.PETS[key]
		local rar = rarityOf(pet)
		local card = bagCards[key]
		if not card then
			local f = new("Frame", {BackgroundColor3 = WHITE, Parent = bagGrid}, {UI.corner(14), UI.stroke(BLACK, 3)})
			UI.gradient(f, rar.Color:Lerp(BLACK, 0.2), rar.Color:Lerp(BLACK, 0.7), 90)
			local pic = new("Frame", {Position = UDim2.fromOffset(9, 6), Size = UDim2.fromOffset(140, 112), BackgroundTransparency = 1, Parent = f})
			rays(pic, rar.Color, UDim2.fromScale(1, 1.2), 4)
			viewport(pic, PetModels.build(pet), {Size = UDim2.fromScale(1, 1), Spin = 0.8, ZIndex = 3})
			label({Position = UDim2.fromOffset(6, 118), Size = UDim2.new(1, -12, 0, 24), Text = pet.N, Outline = 2.5, Parent = f})
			label({Position = UDim2.fromOffset(6, 142), Size = UDim2.new(1, -12, 0, 16), Text = string.upper(rar.Name) .. "  \u{2022}  +" .. pet.Boost .. "%", TextColor3 = rar.Color:Lerp(WHITE, 0.4), Outline = 2, Parent = f})
			local countLbl = label({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(50, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Right, Outline = 2.5, ZIndex = 5, Parent = f})
			local eqBadge = new("Frame", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = UI.GREEN, ZIndex = 5, Visible = false, Parent = f}, {UI.corner(1, true), UI.stroke(BLACK, 2.5)})
			label({Size = UDim2.fromScale(1, 1), Text = "\u{2713}", Outline = 2, ZIndex = 6, Parent = eqBadge})
			local eqB, eqT, eqC = UI.actionButton({Position = UDim2.fromOffset(6, 164), Size = UDim2.new(1, -52, 0, 50), Text = "EQUIP", Parent = f}, UI.GREEN)
			local del, delT, delC = UI.actionButton({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 164), Size = UDim2.fromOffset(40, 50), Text = "X", Parent = f}, UI.RED)
			card = {Frame = f, Count = countLbl, Badge = eqBadge, EqText = eqT, EqColor = eqC, DelText = delT, DelColor = delC, Sure = 0}
			bagCards[key] = card
			eqB.Activated:Connect(function()
				local st = card.Stack
				if #st.Free > 0 then
					local ok, msg = petFunc:InvokeServer("equip", st.Free[1])
					if not ok then
						bagHint.Text = msg
						bagHint.TextColor3 = rgb(255, 140, 140)
					end
				elseif #st.Equipped > 0 then
					petFunc:InvokeServer("unequip", st.Equipped[1])
				end
			end)
			del.Activated:Connect(function()
				-- tap twice to delete (so you never lose a pet by accident)
				local st = card.Stack
				if os.clock() - card.Sure > 2.5 then
					card.Sure = os.clock()
					delT.Text = "?"
					task.delay(2.5, function()
						delT.Text = "X"
					end)
					return
				end
				card.Sure = 0
				delT.Text = "X"
				local id = st.Free[1] or st.Equipped[1]
				if id then
					petFunc:InvokeServer("delete", id)
				end
			end)
		end
		card.Stack = s
		card.Count.Text = #s.Ids > 1 and ("x" .. #s.Ids) or ""
		card.Badge.Visible = #s.Equipped > 0
		local canEquip = #s.Free > 0
		card.EqText.Text = canEquip and (#s.Equipped > 0 and "EQUIP +1" or "EQUIP") or "UNEQUIP"
		card.EqColor(canEquip and UI.GREEN or rgb(230, 140, 40))
		-- equipped first, then the strongest
		card.Frame.LayoutOrder = (#s.Equipped > 0 and 0 or 100000) - pet.Boost
	end
end
player:GetAttributeChangedSignal("PetsOwned"):Connect(function()
	if bag.Frame.Visible then
		refreshBag()
	end
end)
player:GetAttributeChangedSignal("PetsEquipped"):Connect(function()
	if bag.Frame.Visible then
		refreshBag()
	end
end)

------------------------------------------------------------------
-- PETS button: above DOWNLOADS, only once you own a pet (with a "!" the first time)
------------------------------------------------------------------
local petsBtn, petsRefs = UI.fancyButton({Name = "PETS", Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 0.5, -152), Size = UDim2.fromOffset(128, 104), Color = rgb(255, 150, 60), Icon = "\u{1F43E}", Text = "PETS", SparkleEvery = 0.5})
petsBtn.Visible = false
petsRefs.BadgeText.Text = "!"
local function refreshButton()
	local count = #owned()
	petsBtn.Visible = count > 0
	petsRefs.Badge.Visible = count > 0 and not player:GetAttribute("PetsSeen")
end
player:GetAttributeChangedSignal("PetsOwned"):Connect(refreshButton)
player:GetAttributeChangedSignal("PetsSeen"):Connect(refreshButton)
refreshButton()
-- the badge bounces so you notice it
task.spawn(function()
	local s = new("UIScale", {Parent = petsRefs.Badge})
	while true do
		if petsRefs.Badge.Visible then
			tween(s, 0.3, {Scale = 1.3}, Enum.EasingStyle.Sine)
			task.wait(0.3)
			tween(s, 0.3, {Scale = 1}, Enum.EasingStyle.Sine)
		end
		task.wait(0.4)
	end
end)
petsBtn.Activated:Connect(function()
	if bag.Frame.Visible then
		bag.Frame.Visible = false
		return
	end
	if not player:GetAttribute("PetsSeen") then
		task.spawn(petFunc.InvokeServer, petFunc, "seen")
	end
	bagHint.Text = "Hatch more at the Pet Hatchery next to the Trail Shop!"
	bagHint.TextColor3 = rgb(210, 205, 235)
	refreshBag()
	UI.open(bag)
end)

------------------------------------------------------------------
-- PETS IN THE WORLD: everyone's equipped pets follow them around
------------------------------------------------------------------
local petFolder = Instance.new("Folder")
petFolder.Name = "FollowPets"
petFolder.Parent = workspace
local followers = {} -- [player] = {Key = "1-1,2-3", Pets = {{Model, Pet, CF}}}
local FLYERS = {bird = true, ghost = true, fish = true, octo = true}
local SLOTS = {
	[1] = {Vector3.new(2.8, 0, 3)},
	[2] = {Vector3.new(-2.6, 0, 3), Vector3.new(2.6, 0, 3)},
	[3] = {Vector3.new(-3.2, 0, 2.4), Vector3.new(0, 0, 4.4), Vector3.new(3.2, 0, 2.4)},
}
local PET_SCALE = 0.75

local function clearFollower(f)
	for _, p in ipairs(f.Pets) do
		p.Model:Destroy()
	end
	f.Pets = {}
end

local function syncFollower(plr)
	local key = plr:GetAttribute("PetsOut") or ""
	local f = followers[plr]
	if not f then
		f = {Key = nil, Pets = {}}
		followers[plr] = f
	end
	if f.Key == key then return end
	f.Key = key
	clearFollower(f)
	for k in string.gmatch(key, "[^,]+") do
		local pet = PetData.PETS[k]
		if pet then
			local m = PetModels.build(pet)
			m:ScaleTo(m:GetScale() * PET_SCALE)
			m.Parent = petFolder
			table.insert(f.Pets, {Model = m, Pet = pet, CF = nil, Phase = math.random() * 6})
		end
	end
end

local function watch(plr)
	plr:GetAttributeChangedSignal("PetsOut"):Connect(function()
		syncFollower(plr)
	end)
	syncFollower(plr)
end
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(watch, plr)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(plr)
	local f = followers[plr]
	if f then
		clearFollower(f)
		followers[plr] = nil
	end
end)

local giantEgg, giantBase
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for plr, f in pairs(followers) do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local n = #f.Pets
		if root and hum and n > 0 and (root.Position - camPos).Magnitude < 250 then
			local feetY = root.Position.Y - hum.HipHeight - root.Size.Y / 2
			local vel = root.AssemblyLinearVelocity
			local moving = Vector3.new(vel.X, 0, vel.Z).Magnitude > 2
			local _, yaw = root.CFrame:ToEulerAnglesYXZ()
			local facing = CFrame.Angles(0, yaw, 0)
			local slots = SLOTS[math.min(n, 3)]
			for i, p in ipairs(f.Pets) do
				local off = slots[i] or slots[#slots]
				local ground = Vector3.new(root.Position.X, feetY, root.Position.Z) + facing:VectorToWorldSpace(off)
				local lift
				if FLYERS[p.Pet.B] then
					lift = 1.6 + math.sin(t * 2.2 + p.Phase) * 0.35
				else
					-- little hops while you run, a gentle bounce while you stand
					lift = moving and math.abs(math.sin(t * 9 + p.Phase)) * 0.7 or math.abs(math.sin(t * 2 + p.Phase)) * 0.12
				end
				local target = CFrame.new(ground + Vector3.new(0, lift, 0)) * facing
				p.CF = p.CF and p.CF:Lerp(target, 1 - math.exp(-dt * 12)) or target
				if (p.CF.Position - target.Position).Magnitude > 40 then
					p.CF = target -- teleported: catch up at once
				end
				p.Model:PivotTo(p.CF)
			end
		end
	end
	-- the giant egg at the Hatchery turns slowly
	if not giantEgg then
		local map = workspace:FindFirstChild("StealAGameMap")
		local h = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("PetHatchery")
		giantEgg = h and h:FindFirstChild("GiantEgg")
		giantBase = giantEgg and giantEgg:GetPivot()
	elseif giantEgg.Parent then
		giantEgg:PivotTo(giantBase * CFrame.new(0, math.sin(t * 1.5) * 0.4, 0) * CFrame.Angles(0, t * 0.4, 0))
	end
end)

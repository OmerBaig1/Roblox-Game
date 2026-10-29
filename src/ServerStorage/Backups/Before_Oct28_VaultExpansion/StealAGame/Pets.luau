--[[
	STEAL A GAME - PETS (server)
	Buying and hatching eggs, owning / equipping pets, saving them, and the Pet Hatchery stand.
	Equipped pets add their Boost (%) to how fast your games install (Pets.installMult).
	The client (PetsUI) draws the shop, the hatching and the pets following everyone around.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PetData = require(ReplicatedStorage:WaitForChild("PetData"))
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))

local Pets = {}
-- Eq is one entry per pet slot (PetData.EQUIP_MAX of them): a pet id, or 0 for an empty slot
local state = {} -- [player] = {List = {{I = id, K = key}}, Eq = {id or 0, ...}, Next = n, Seen = bool, Manual = bool}
local deps

local function find(st, id)
	for i, p in ipairs(st.List) do
		if p.I == id then
			return p, i
		end
	end
end

local function emptySlot(st)
	return table.find(st.Eq, 0)
end

local function boostOf(st)
	local total = 0
	for _, id in ipairs(st.Eq) do
		local p = find(st, id)
		local pet = p and PetData.PETS[p.K]
		if pet then
			total += pet.Boost
		end
	end
	return total
end

-- Everything the client needs lives in attributes
local function push(player)
	local st = state[player]
	if not st then return end
	local keys = {}
	for _, id in ipairs(st.Eq) do
		local p = find(st, id)
		if p then
			table.insert(keys, p.K)
		end
	end
	player:SetAttribute("PetsOwned", HttpService:JSONEncode(st.List))
	player:SetAttribute("PetsEquipped", HttpService:JSONEncode(st.Eq))
	player:SetAttribute("PetsOut", table.concat(keys, ",")) -- read by every player's game to draw your pets
	player:SetAttribute("PetBoost", boostOf(st))
	player:SetAttribute("PetsSeen", st.Seen == true)
end

function Pets.installMult(player)
	local st = state[player]
	return st and 1 + boostOf(st) / 100 or 1
end

function Pets.load(player, saved)
	local st = {List = {}, Eq = table.create(PetData.EQUIP_MAX, 0), Next = 1, Seen = false}
	if type(saved) == "table" then
		st.Next = math.max(1, math.floor(tonumber(saved.Next) or 1))
		st.Seen = saved.Seen == true
		st.Manual = saved.Manual == true
		if type(saved.List) == "table" then
			for _, p in ipairs(saved.List) do
				local id = tonumber(type(p) == "table" and p.I)
				if id and PetData.PETS[p.K] and #st.List < PetData.MAX_PETS then
					table.insert(st.List, {I = id, K = p.K})
					st.Next = math.max(st.Next, id + 1)
				end
			end
		end
		-- slots keep their places; older saves had 3 pets out, the third is put back in the bag
		if type(saved.Eq) == "table" then
			for slot = 1, PetData.EQUIP_MAX do
				local id = tonumber(saved.Eq[slot])
				if id and find(st, id) and not table.find(st.Eq, id) then
					st.Eq[slot] = id
				end
			end
		end
	end
	state[player] = st
	push(player)
end

function Pets.save(player)
	local st = state[player]
	if not st then return nil end
	return {List = st.List, Eq = st.Eq, Next = st.Next, Seen = st.Seen, Manual = st.Manual}
end

function Pets.remove(player)
	state[player] = nil
end

-- equip the strongest pets you own
local function equipBest(st)
	local sorted = table.clone(st.List)
	table.sort(sorted, function(a, b)
		return PetData.PETS[a.K].Boost > PetData.PETS[b.K].Boost
	end)
	for slot = 1, PetData.EQUIP_MAX do
		st.Eq[slot] = sorted[slot] and sorted[slot].I or 0
	end
end

local function onRequest(player, action, a, b)
	local st = state[player]
	if not st then
		return false, "Try again in a moment"
	end
	if action == "buy" then
		local egg = PetData.EGGS[tonumber(a) or 0]
		local count = tonumber(b) == PetData.HATCH_MANY and PetData.HATCH_MANY or 1
		if not egg then
			return false, "That egg doesn't exist"
		end
		if #st.List + count > PetData.MAX_PETS then
			return false, "Your pet bag is full! Delete some pets first."
		end
		local cash = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")
		local cost = egg.Price * count
		if not cash or cash.Value < cost then
			return false, "You need $" .. deps.fmt(cost)
		end
		cash.Value -= cost
		local results = {}
		for _ = 1, count do
			local key = PetData.roll(egg, math.random(), math.random()).Key
			local id = st.Next
			st.Next += 1
			table.insert(st.List, {I = id, K = key})
			table.insert(results, {I = id, K = key})
		end
		-- your strongest pets come out automatically, until you pick pets yourself
		if not st.Manual then
			equipBest(st)
		else
			for _, res in ipairs(results) do
				local slot = emptySlot(st)
				if slot then
					st.Eq[slot] = res.I
				end
			end
		end
		push(player)
		return true, results
	elseif action == "equip" or action == "unequip" then
		local id = tonumber(a)
		if not id or not find(st, id) then
			return false, "You don't have that pet"
		end
		st.Manual = true
		local at = table.find(st.Eq, id)
		if action == "unequip" then
			if at then
				st.Eq[at] = 0
			end
		elseif not at then
			local slot = emptySlot(st)
			if not slot then
				return false, "Both pet slots are full. Pick a slot to swap into."
			end
			st.Eq[slot] = id
		end
		push(player)
		return true
	elseif action == "slot" then
		-- put pet id (0 = nobody) in a slot; a pet already in the other slot swaps places with what was here
		local slot, id = tonumber(a), tonumber(b) or 0
		if not slot or not st.Eq[slot] then
			return false, "That slot doesn't exist"
		end
		if id ~= 0 and not find(st, id) then
			return false, "You don't have that pet"
		end
		st.Manual = true
		local from = id ~= 0 and table.find(st.Eq, id)
		if from then
			st.Eq[from] = st.Eq[slot]
		end
		st.Eq[slot] = id
		push(player)
		return true
	elseif action == "best" then
		st.Manual = false
		equipBest(st)
		push(player)
		return true
	elseif action == "delete" then
		local id = tonumber(a)
		local _, i = find(st, id or -1)
		if not i then
			return false, "You don't have that pet"
		end
		table.remove(st.List, i)
		local at = table.find(st.Eq, id)
		if at then
			st.Eq[at] = 0
		end
		push(player)
		return true
	elseif action == "seen" then
		st.Seen = true
		push(player)
		return true
	end
	return false, "Unknown request"
end

------------------------------------------------------------------
-- THE PET HATCHERY: a round stage with a giant egg under a glass dome,
-- ringed by little nests holding every egg you can buy
------------------------------------------------------------------
local function buildHatchery(lobby, cf)
	local Kit = deps.Kit
	local rgb, M, part = Kit.rgb, Kit.M, Kit.part
	local model = Instance.new("Model")
	model.Name = "PetHatchery"
	model.Parent = lobby
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	local FLAT = CFrame.Angles(0, 0, math.pi / 2)
	part(model, {Name = "Stage", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 34, 34), CFrame = at(0, 0.5, 0) * FLAT, Color = rgb(255, 225, 160), Material = M.Sand})
	part(model, {Name = "StageTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 26, 26), CFrame = at(0, 1, 0) * FLAT, Color = rgb(140, 220, 120), Material = M.Grass})
	part(model, {Name = "StageTrim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 34.4, 34.4), CFrame = at(0, 1.05, 0) * FLAT, Color = rgb(255, 170, 60)})
	-- the giant egg in its nest, under a glass dome
	part(model, {Name = "Nest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 11, 11), CFrame = at(0, 2.6, 0) * FLAT, Color = rgb(170, 120, 70), Material = M.WoodPlanks})
	local big = PetModels.egg(PetData.EGGS[#PetData.EGGS])
	big.Name = "GiantEgg"
	big:ScaleTo(3)
	big:PivotTo(at(0, 3.4, 0))
	-- every player's game turns it slowly (PetsUI). It streams in as one piece, and its home spot is stored so a client
	-- never takes a half-turned or half-streamed egg as its starting point.
	big.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	big:SetAttribute("Spin", 0.32)
	big:SetAttribute("Bob", 0.35)
	big:SetAttribute("Base", big:GetPivot())
	big.Parent = model
	part(model, {Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(15, 15, 15), CFrame = at(0, 6.5, 0), Color = rgb(200, 240, 255), Material = M.Glass, Transparency = 0.75, CanCollide = false})
	local glow = Instance.new("PointLight")
	glow.Color = rgb(255, 200, 255)
	glow.Range = 18
	glow.Brightness = 1
	glow.Parent = big.PrimaryPart
	-- every egg on its own little nest around the edge (front half is left open as the way in)
	local n = #PetData.EGGS
	for i, egg in ipairs(PetData.EGGS) do
		local ang = math.rad(-150 + (i - 1) * 300 / (n - 1)) + math.pi / 2
		local x, z = math.cos(ang) * 11, math.sin(ang) * 11
		part(model, {Name = "MiniNest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 3, 3), CFrame = at(x, 2, z) * FLAT, Color = rgb(170, 120, 70), Material = M.WoodPlanks})
		-- a rim lit in the egg's colour, like its stand in the shop (kept below the nest's top so only the edge shows)
		part(model, {Name = "NestGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 3.14, 3.14), CFrame = at(x, 2.3, z) * FLAT, Color = egg.Spot, Material = M.Neon, CanCollide = false})
		local e = PetModels.egg(egg)
		e.Name = "NestEgg"
		e:ScaleTo(0.7)
		e:PivotTo(at(x, 2.4, z) * CFrame.Angles(0, ang + math.pi / 2, 0))
		e.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		-- each nest egg turns at its own gentle speed, alternating direction
		e:SetAttribute("Spin", (0.42 + (i % 3) * 0.08) * (i % 2 == 0 and 1 or -1))
		e:SetAttribute("Bob", 0.08)
		e:SetAttribute("Base", e:GetPivot())
		e.Parent = model
	end
	-- big arch sign over the entrance
	for _, sx in ipairs({-1, 1}) do
		Kit.cylinder(model, 20, 1.4, at(sx * 9, 11, -15), {Name = "ArchPost", Color = rgb(255, 255, 255), Material = M.Marble})
		part(model, {Name = "ArchTop", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(sx * 9, 21.5, -15), Color = rgb(255, 120, 200), Material = M.Neon, CanCollide = false})
	end
	-- dark board with bright lettering (white on pink washed out in the sun)
	local sign = part(model, {Name = "Sign", Size = Vector3.new(19, 4.6, 0.6), CFrame = at(0, 19, -15), Color = rgb(60, 25, 70)})
	Kit.surfaceText(sign, Enum.NormalId.Front, "PET HATCHERY", rgb(255, 160, 220), 30)
	Kit.surfaceText(sign, Enum.NormalId.Back, "PET HATCHERY", rgb(255, 160, 220), 30)
	part(model, {Name = "SignFrame", Size = Vector3.new(20, 5.6, 0.4), CFrame = at(0, 19, -14.7), Color = rgb(255, 220, 100), Material = M.Neon})
	local anchor = part(model, {Name = "HatchAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, 4, -9), Transparency = 1, CanCollide = false})
	Kit.billboard(anchor, 320, 64, 15, '<font color="#ff9be0">PET HATCHERY</font>\nPets make your games install faster!', 200)
	local prompt = Kit.prompt(anchor, "Hatch Eggs", "Pet Hatchery", 0, 16)
	prompt.Triggered:Connect(function(player)
		deps.OpenEvent:FireClient(player)
	end)
	return model
end

function Pets.init(d)
	deps = d
	deps.OpenEvent = d.Kit.event("OpenHatchery")
	d.Kit.func("Pets").OnServerInvoke = onRequest
	-- the Hatchery stands beside the Trail Shop (on the side away from the vault), facing the same way
	local shop = d.lobby and d.lobby:FindFirstChild("TrailShop")
	local floor = shop and shop:FindFirstChild("Floor")
	if floor then
		-- the shop's floor sits 0.5 up and 2 back from the shop's own origin
		local shopCF = floor.CFrame * CFrame.new(0, -0.5, -2)
		buildHatchery(d.lobby, shopCF * CFrame.new(-42, 0, 4))
	end
end

return Pets

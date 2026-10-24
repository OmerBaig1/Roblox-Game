--[[
	STEAL A GAME  —  SERVER SCRIPT  (Game Vault, 50 stores)
	Put this in ServerScriptService as a normal Script (not a LocalScript).
	Start from a Baseplate place. It builds the whole world by itself.

	How the game works:
	- The Game Vault is one long straight hallway of 50 stores in 10 themed
	  zones. The further in you go, the rarer and more valuable the games.
	- Each store has 3 pedestals. Every game has its own spawn chance.
	- Once a game is taken from a store, that store restocks after 3 minutes
	  (the countdown floats above the store's pedestals).
	- Grab a game and carry it ALL the way back to your base.
	- Only the shopkeeper of the store you stole from chases you, and they
	  chase you all the way home. Deeper shopkeepers are much faster.
	- Hop on your treadmill to run in place and get permanently faster.
	  Every upgrade makes you gain speed quicker and makes the treadmill look better.
	- Games in your base earn cash every second. Collect it on the green pad.
	- You can steal from other players' bases too. Owners can slap thieves.
	- Red button = lock your base for 30 seconds. Hold E on your own game to sell it.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GamePoster = require(ReplicatedStorage:WaitForChild("GamePoster"))
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local DataStoreService = game:GetService("DataStoreService")

------------------------------------------------------------------
-- SETTINGS (change these to balance the game)
------------------------------------------------------------------
local START_CASH = 0
local RESTOCK_TIME = 180          -- seconds for a store to restock (3 minutes)
local LOCK_TIME = 30              -- seconds a base stays locked
local SELL_MULTIPLIER = 30        -- selling gives (income per second x this)

-- Game income: store N's cheapest game earns INCOME_BASE x INCOME_GROWTH^(N-1) per second
local INCOME_BASE = 1.8
local INCOME_GROWTH = 1.33
local GAME_MULTIPLIERS = {1, 1.5, 2.2}  -- the 3 games in a store (rarest earns most)
local CHANCE_SETS = {               -- spawn chances (%) for the 3 games, varies per store
	{55, 33, 12}, {50, 35, 15}, {58, 30, 12}, {45, 40, 15},
	{52, 33, 15}, {48, 38, 14}, {60, 30, 10}, {47, 41, 12},
}

-- Player speed
local SPEED_SCALE = 2             -- multiplies EVERY speed (players, treadmill, shopkeepers): same balance, bigger numbers
local BASE_SPEED = 16 * SPEED_SCALE  -- walk speed with no treadmill training
local START_SPEED_SHOWN = 1000     -- the speed number a brand-new player sees
local SPEED_DISPLAY = START_SPEED_SHOWN / BASE_SPEED -- every speed on screen = real speed x this
ReplicatedStorage:SetAttribute("BaseSpeed", BASE_SPEED)
ReplicatedStorage:SetAttribute("SpeedDisplay", SPEED_DISPLAY)
local CARRY_MULTIPLIER = 0.85     -- you run at 85% speed while carrying a game
local MAX_SPEED_BONUS = 70 * SPEED_SCALE  -- most speed the treadmill can give you

-- Treadmill
local TREADMILL_BASE_RATE = 1 / SPEED_DISPLAY  -- treadmill at level 0 shows +1 speed per second
local TREADMILL_RATE_GROWTH = 1.2 -- each upgrade multiplies the rate by this
local TREADMILL_MAX_LEVEL = 25
local TREADMILL_COST_BASE = 50    -- first upgrade price
local TREADMILL_COST_GROWTH = 2.15

-- Shopkeepers
local GUARD_SPEED_START = 11 * SPEED_SCALE    -- store 1 shopkeeper speed
local GUARD_SPEED_PER_LEVEL = 1 * SPEED_SCALE -- added for every store deeper
local GUARD_REACTION = 0.6        -- seconds before a shopkeeper starts running
local GUARD_GIVE_UP = 90          -- seconds before a shopkeeper gives up a chase
local GUARD_IDLE_SPEED = 12 * SPEED_SCALE

local SLAP_COOLDOWN = 0.8
local SLAP_RANGE = 8

-- Layout
local ROOM_W = 90                 -- width of each store
local ROOM_LEN = 60               -- length of each store
local WALL_H = 42
local DOOR_W = 30
local DOOR_H = 22
local HALL_START_Z = 20           -- the vault entrance
local BASE_RING_RADIUS = 185      -- distance from the entrance to the bases
local BASE_ARC = 150              -- degrees the ring of bases covers (in front of the entrance)
local GROUND_Y = -4               -- grass terrain height; everything you walk on is a part at y = 0

local RED = Color3.fromRGB(255, 80, 80)
local GREEN = Color3.fromRGB(90, 255, 120)
local GOLD = Color3.fromRGB(255, 210, 60)
local BLUE = Color3.fromRGB(80, 170, 255)

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local M = Enum.Material

--[[
	ZONES: 10 themes, 5 stores each = 50 stores.
	Ground = terrain floor, Props = decorations (see buildProp),
	Guard Hat options: cap, headband, tophat, pirate, hood, visor, antenna, horns, crown, helmet, halo
]]
local ZONES = {
	{
		Name = "Bargain Basement", Rarity = "Common", Color = rgb(190, 190, 190),
		Ground = M.Mud, Wall = rgb(150, 110, 70), WallMat = M.WoodPlanks, Accent = rgb(255, 210, 60), Props = {"crate", "barrel"},
		Guard = {Title = "Clearance Bouncer", Shirt = rgb(230, 120, 40), Pants = rgb(90, 60, 40), Hat = "cap", HatColor = rgb(255, 210, 60)},
		Stores = {
			{"Bargain Bin", {"Pang", "Wee Sports Bowling", "Marco Kart"}},
			{"Dollar Disc Depot", {"Flappy Bard", "Cookie Klicker", "Temple Ruin"}},
			{"Thrift Game Shack", {"FIFO Soccer 98", "Golf With Your Foes", "Rusty League"}},
			{"Clearance Corner", {"Saleway Surfers", "Pac-Can", "Tetrus"}},
			{"Pawn and Play", {"Monopawly", "Trollercoaster Tycoon", "Animal Bossing"}},
		},
	},
	{
		Name = "Retro Arcade", Rarity = "Uncommon", Color = rgb(85, 200, 90),
		Ground = M.Brick, Wall = rgb(70, 40, 110), WallMat = M.SmoothPlastic, Accent = rgb(255, 60, 200), Props = {"screen", "lamp"},
		Guard = {Title = "Pixel Patrol", Shirt = rgb(255, 60, 200), Pants = rgb(40, 30, 60), Hat = "headband", HatColor = rgb(0, 230, 255)},
		Stores = {
			{"Retro Pixel Shop", {"Super Mario Bruhs", "The Legend of Zelma", "Pocketmon Red"}},
			{"Joystick Junction", {"Sweet Fighter II", "Monkey Kong", "Galagoo"}},
			{"Cartridge Castle", {"Sanic the Hedgehog", "Castlevanilla", "Metro-Void"}},
			{"High Score Hall", {"Space Raiders", "Froggo", "Mega Dan"}},
			{"Neon Arcade Alley", {"Prance Prance Revolution", "Mortal Wombat", "Crash Bandicoop"}},
		},
	},
	{
		Name = "Toy Town", Rarity = "Rare", Color = rgb(60, 130, 255),
		Ground = M.LeafyGrass, Wall = rgb(255, 230, 120), WallMat = M.SmoothPlastic, Accent = rgb(255, 90, 90), Props = {"toyblock", "cone"},
		Guard = {Title = "Toy Soldier", Shirt = rgb(200, 30, 40), Pants = rgb(30, 50, 140), Hat = "tophat", HatColor = rgb(20, 20, 20)},
		Stores = {
			{"Toy Box Arcade", {"Fall Toys", "Puppy Playtime", "Kirbo's Dream Land"}},
			{"Brick Builder Bazaar", {"Minecrate", "Blocko Galaxy Wars", "Fortnut"}},
			{"Marble Run Mart", {"Bayblade Burst", "Super Donkey Ball", "Katamari Dramacy"}},
			{"Plushie Palace", {"Five Nights at Teddy's", "Plushmon Go", "Webkins Whirl"}},
			{"Wind-Up Workshop", {"Cup Hat", "Wayman Legends", "Little Big Plant"}},
		},
	},
	{
		Name = "Pirate Cove", Rarity = "Epic", Color = rgb(170, 70, 255),
		Ground = M.Sand, Wall = rgb(120, 80, 45), WallMat = M.WoodPlanks, Accent = rgb(60, 170, 220), Props = {"barrel", "palm"},
		Guard = {Title = "Pirate Captain", Shirt = rgb(170, 30, 30), Pants = rgb(50, 35, 25), Hat = "pirate", HatColor = rgb(20, 20, 20)},
		Stores = {
			{"Pirate Cove Games", {"Sea of Robbers", "Assassin's Greed: Black Flag", "Pirates of the Carrot-bean"}},
			{"Treasure Map Traders", {"Uncharred", "Skull and Phones", "One Peace"}},
			{"Shipwreck Shop", {"Subnaughtica", "Daft Raft", "Battleshrimp"}},
			{"Parrot's Perch", {"Angry Parrots", "The Secret of Donkey Island", "Sid Meier's Parrots!"}},
			{"Black Flag Bazaar", {"Pirate 102", "Port Royalty", "Sea Hogs"}},
		},
	},
	{
		Name = "Haunted Crypt", Rarity = "Legendary", Color = rgb(255, 170, 0),
		Ground = M.Slate, Wall = rgb(60, 65, 70), WallMat = M.Cobblestone, Accent = rgb(120, 255, 120), Props = {"tombstone", "lamp"},
		Guard = {Title = "Crypt Keeper", Shirt = rgb(50, 70, 50), Pants = rgb(30, 30, 30), Hat = "hood", HatColor = rgb(90, 90, 100)},
		Stores = {
			{"Haunted Game Crypt", {"Resident Weevil", "Ghostdusters", "Luigo's Mansion"}},
			{"Spooky Swap Shop", {"Phasmophonia", "Dead by Midnight", "Little Nightmarez"}},
			{"Graveyard Games", {"Left 4 Bread", "Pants vs. Zombies", "Dying Lite"}},
			{"Phantom Pixels", {"Silent Bill", "Outpast", "Amnesiac"}},
			{"Vampire Vault", {"Vampire Thrivers", "Floodborne", "Vampurr"}},
		},
	},
	{
		Name = "Cyber City", Rarity = "Mythic", Color = rgb(255, 50, 90),
		Ground = M.Concrete, Wall = rgb(25, 25, 40), WallMat = M.DiamondPlate, Accent = rgb(0, 230, 255), Props = {"neonpillar", "screen"},
		Guard = {Title = "Cyber Enforcer", Shirt = rgb(20, 20, 30), Pants = rgb(20, 40, 90), Hat = "visor", HatColor = rgb(0, 230, 255)},
		Stores = {
			{"Neon Cyber Mart", {"Cyberpunk 2078", "Ghostjogger", "Deus Next"}},
			{"Circuit City Games", {"Overwash", "Valorent", "Apex Legendz"}},
			{"Hologram House", {"Portul", "Half-Lite", "Hallo"}},
			{"Data Stream Depot", {"Watch Hogs", "Counter-Stroke", "Dentistry"}},
			{"Synthwave Store", {"Hotline Maimi", "Beet Saber", "Geometry Splash"}},
		},
	},
	{
		Name = "Ninja Dojo", Rarity = "Godly", Color = rgb(255, 230, 80),
		Ground = M.WoodPlanks, Wall = rgb(200, 60, 50), WallMat = M.Wood, Accent = rgb(255, 120, 150), Props = {"lamp", "bamboo"},
		Guard = {Title = "Shadow Ninja", Shirt = rgb(25, 25, 30), Pants = rgb(25, 25, 30), Hat = "hood", HatColor = rgb(20, 20, 25)},
		Stores = {
			{"Ninja Dojo Games", {"Ghost of Sushima", "Ninja Garden", "Root Ninja"}},
			{"Bamboo Blade Shop", {"Sekiwo: Shadows Die Thrice", "Shadow Bite 2", "Naru-toe Storm"}},
			{"Lantern Lane Games", {"Okamee", "Gemshin Impact", "Cooking Mamma"}},
			{"Shogun Supply", {"Total Bore: Shogun", "Samurai Slowdown", "Ni-Oh No"}},
			{"Cherry Blossom Shop", {"Tekkon 8", "Super Smush Bros", "Splatune"}},
		},
	},
	{
		Name = "Robot Factory", Rarity = "Secret", Color = rgb(20, 255, 220),
		Ground = M.Pavement, Wall = rgb(120, 125, 135), WallMat = M.Metal, Accent = rgb(255, 170, 0), Props = {"gear", "crate"},
		Guard = {Title = "Security Bot", Shirt = rgb(170, 175, 185), Pants = rgb(90, 95, 105), Hat = "antenna", HatColor = rgb(255, 40, 40)},
		Stores = {
			{"Robo Factory Store", {"Titanfail", "Armored Chore", "Mechworrier"}},
			{"Gearworks Games", {"Fractorio", "Satisfactoree", "Bioshocked"}},
			{"Mech Bay Market", {"Transforkers", "Gundumb Breaker", "Pacific Rimm"}},
			{"Circuit Assembly", {"Detroit: Become Toaster", "Nearly: Automata", "The Taco Principle"}},
			{"AI Arcade", {"Mass Defect", "Horizon Zero Yawn", "The Mattress"}},
		},
	},
	{
		Name = "Dragon's Lair", Rarity = "Celestial", Color = rgb(255, 150, 255),
		Ground = M.CrackedLava, Wall = rgb(70, 30, 25), WallMat = M.Basalt, Accent = rgb(255, 100, 20), Props = {"gold", "rock"},
		Guard = {Title = "Dragon Knight", Shirt = rgb(150, 20, 20), Pants = rgb(60, 20, 20), Hat = "horns", HatColor = rgb(240, 230, 200)},
		Stores = {
			{"Dragon's Hoard", {"The Elder Trolls: Skyrim", "Spyrow", "Dragon Quest-ion"}},
			{"Lava Lair Games", {"Dark Soles", "Elden Ding", "Cod of War"}},
			{"Wyvern Wares", {"Monster Hunger", "How to Drain Your Dragon", "Dragon's Dog-ma"}},
			{"Ember Emporium", {"Diablow", "Shades", "Bald Dude's Gate 3"}},
			{"Hoard Keeper's Haven", {"World of Warcrafts", "Final Fanta-sea", "The Twitcher 3"}},
		},
	},
	{
		Name = "Outer Space", Rarity = "Infinity", Color = rgb(255, 255, 255),
		Ground = M.Basalt, Wall = rgb(30, 30, 60), WallMat = M.Metal, Accent = rgb(170, 90, 255), Props = {"planet", "crystal"},
		Guard = {Title = "Space Ranger", Shirt = rgb(240, 240, 245), Pants = rgb(200, 200, 210), Hat = "helmet", HatColor = rgb(160, 220, 255)},
		Stores = {
			{"Galactic Game Station", {"No Man's Pie", "Starfeld", "Star Bores"}},
			{"Nebula Nook", {"Among Bus", "Outer Mild", "Herbal Space Program"}},
			{"Black Hole Bazaar", {"Bed Space", "Hallo Infinite", "Elite Dangerless"}},
			{"Starlight Archive", {"Super Marco Galaxy", "Ratchet & Crank", "Metro-Void Prime"}},
			{"The Forbidden Archive", {"Grand Theft Avocado VI", "Half-Lite 3", "Steal a Brainrut"}},
		},
	},
}

-- Treadmill looks, one per 5 upgrade levels
local TREAD_TIERS = {
	{Name = "Basic",     Frame = rgb(110, 110, 120), FrameMat = M.Metal,         Accent = rgb(170, 170, 180), AccentMat = M.Metal},
	{Name = "Sport",     Frame = rgb(40, 90, 200),   FrameMat = M.SmoothPlastic, Accent = rgb(80, 170, 255),  AccentMat = M.Neon},
	{Name = "Pro",       Frame = rgb(25, 25, 30),    FrameMat = M.DiamondPlate,  Accent = rgb(60, 255, 120),  AccentMat = M.Neon, Light = true},
	{Name = "Elite",     Frame = rgb(60, 20, 90),    FrameMat = M.SmoothPlastic, Accent = rgb(200, 80, 255),  AccentMat = M.Neon, Light = true, Panels = true},
	{Name = "Champion",  Frame = rgb(255, 195, 40),  FrameMat = M.Foil,          Accent = rgb(255, 140, 30),  AccentMat = M.Neon, Light = true, Panels = true, Sparkles = true},
	{Name = "Legendary", Frame = rgb(120, 240, 255), FrameMat = M.Glass,         Accent = rgb(255, 255, 255), AccentMat = M.Neon, Light = true, Panels = true, Sparkles = true, Arch = true},
}

------------------------------------------------------------------
-- BUILD THE STORE LIST (50 levels)
------------------------------------------------------------------
local function niceRound(n)
	if n < 10 then
		return math.max(1, math.floor(n + 0.5))
	end
	local mag = 10 ^ (math.floor(math.log10(n)) - 1)
	return math.floor(n / mag + 0.5) * mag
end

local LEVELS = {}
for zi, zone in ipairs(ZONES) do
	for si, store in ipairs(zone.Stores) do
		local i = #LEVELS + 1
		local chances = CHANCE_SETS[(i - 1) % #CHANCE_SETS + 1]
		local base = INCOME_BASE * INCOME_GROWTH ^ (i - 1)
		local games = {}
		for gi, name in ipairs(store[2]) do
			table.insert(games, {
				Name = name, Rarity = zone.Rarity, Color = zone.Color,
				Income = niceRound(base * GAME_MULTIPLIERS[gi]), Chance = chances[gi],
			})
		end
		table.insert(LEVELS, {
			Index = i, Zone = zone, ZoneIndex = zi, Sub = si, Store = store[1], Games = games,
			Accent = zone.Accent:Lerp(Color3.new(1, 1, 1), (si - 1) * 0.1),
			Wall = zone.Wall:Lerp(Color3.new(0, 0, 0), (si - 1) * 0.07),
		})
	end
end
local NUM_LEVELS = #LEVELS

-- Share the full game list with players for the Index
do
	local index = {}
	for _, zone in ipairs(ZONES) do
		table.insert(index, {Area = zone.Name, Rarity = zone.Rarity, Color = zone.Color:ToHex(), Accent = zone.Accent:ToHex(), Games = {}})
	end
	for _, lvl in ipairs(LEVELS) do
		for _, g in ipairs(lvl.Games) do
			table.insert(index[lvl.ZoneIndex].Games, {Name = g.Name, Income = g.Income, Chance = g.Chance, Store = lvl.Store, StoreNumber = lvl.Index})
		end
	end
	local value = ReplicatedStorage:FindFirstChild("GameIndexData") or Instance.new("StringValue")
	value.Name = "GameIndexData"
	value.Value = HttpService:JSONEncode(index)
	value.Parent = ReplicatedStorage
end

-- Every game gets a save id like "12:3" (store 12, game 3)
local GAME_IDS = {}
for _, lvl in ipairs(LEVELS) do
	for gi, g in ipairs(lvl.Games) do
		GAME_IDS[g] = lvl.Index .. ":" .. gi
	end
end

local function gameFromId(id)
	local level, gi = string.match(tostring(id), "^(%d+):(%d+)$")
	local lvl = LEVELS[tonumber(level)]
	return lvl and lvl.Games[tonumber(gi)]
end

------------------------------------------------------------------
-- REMOTES + COLLISION GROUPS
------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "StealAGameRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local notifyEvent = makeRemote("Notify")
local knockEvent = makeRemote("Knockback")
local chaseEvent = makeRemote("Chase")
local treadmillEvent = makeRemote("Treadmill")
local treadmillStopEvent = makeRemote("TreadmillStop")

-- Shopkeepers walk through decorations so they never get stuck on them
pcall(function() PhysicsService:RegisterCollisionGroup("Guards") end)
pcall(function() PhysicsService:RegisterCollisionGroup("Decor") end)
pcall(function() PhysicsService:CollisionGroupSetCollidable("Guards", "Decor", false) end)

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------
local plots = {}          -- list of all plots
local playerPlots = {}    -- player -> plot
local carrying = {}       -- player -> info about the game they are carrying
local spots = {}          -- every pedestal in the vault
local guards = {}         -- level -> shopkeeper
local restockAt = {}      -- level -> time the store restocks (nil = no countdown)
local restockLabels = {}  -- level -> countdown label

local PLOT_W, PLOT_D = 36, 44
local DARK = rgb(35, 35, 45)
local SKIN = rgb(255, 204, 153)
local ENTRANCE = Vector3.new(0, 0, HALL_START_Z)

------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------
local function fmt(n)
	n = math.floor(n)
	if n >= 1e12 then
		return string.format("%.1fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function fmtTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function roomStart(level)
	return HALL_START_Z + (level - 1) * ROOM_LEN
end

local function guardSpeed(level)
	return GUARD_SPEED_START + (level - 1) * GUARD_SPEED_PER_LEVEL
end

local function makePart(parent, props)
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
local function makeCylinder(parent, height, diameter, cf, props)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	return makePart(parent, props)
end

-- Floating labels are sized in studs, so they behave like real signs:
-- smaller when far away, bigger up close (width/height are given in "pixels" at 28 per stud)
local LABEL_PIXELS_PER_STUD = 28
local function makeBillboard(adornee, width, height, offsetY, text, maxDistance)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(width / LABEL_PIXELS_PER_STUD, 0, height / LABEL_PIXELS_PER_STUD, 0)
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

local function makeSurfaceText(part, face, text, color, pixelsPerStud)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pixelsPerStud or 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(0.92, 0.8)
	t.Position = UDim2.fromScale(0.04, 0.1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = sg
	sg.Parent = part
	return t
end

local function makePrompt(parent, action, object, hold, distance)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function setGroup(root, group)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = group
		end
	end
end

local function notify(player, text, color)
	if player and player.Parent then
		notifyEvent:FireClient(player, text, color or Color3.new(1, 1, 1))
	end
end

local function getRoot(player)
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function updateSpeed(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local speed = BASE_SPEED + (player:GetAttribute("SpeedBonus") or 0)
		if carrying[player] then
			speed *= CARRY_MULTIPLIER
		end
		hum.WalkSpeed = speed
	end
end

local function treadmillRate(level)
	return TREADMILL_BASE_RATE * TREADMILL_RATE_GROWTH ^ level
end

local function treadmillCost(level)
	return math.floor(TREADMILL_COST_BASE * TREADMILL_COST_GROWTH ^ level)
end

local function getFreeSlot(plot)
	for _, slot in ipairs(plot.Slots) do
		if not slot.Item and not slot.Reserved then
			return slot
		end
	end
	return nil
end

local function insidePlot(plot, position)
	local localPos = plot.CF:PointToObjectSpace(position)
	return math.abs(localPos.X) <= PLOT_W / 2
		and math.abs(localPos.Z) <= PLOT_D / 2
		and localPos.Y < 25
end

-- Which store is this position in? (nil = outside the vault)
local function roomAt(pos)
	if math.abs(pos.X) > ROOM_W / 2 or pos.Y > WALL_H then
		return nil
	end
	local level = math.floor((pos.Z - HALL_START_Z) / ROOM_LEN) + 1
	if level >= 1 and level <= NUM_LEVELS then
		return level
	end
	return nil
end

local function pickGame(level)
	local list = LEVELS[level].Games
	local total = 0
	for _, g in ipairs(list) do
		total += g.Chance
	end
	local roll = math.random() * total
	for _, g in ipairs(list) do
		roll -= g.Chance
		if roll <= 0 then
			return g
		end
	end
	return list[#list]
end

------------------------------------------------------------------
-- GAME ITEMS (the "game cartridges")
------------------------------------------------------------------
local function createItem(data)
	local item = Instance.new("Part")
	item.Name = data.Name
	item.Size = Vector3.new(4, 5, 1)
	item.Anchored = true
	item.CanCollide = false
	item.Color = data.Color
	item.Material = Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth

	-- Poster on both sides
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local sg = Instance.new("SurfaceGui")
		sg.Name = "Poster"
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.LightInfluence = 0.3
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		GamePoster.Create(data).Parent = sg
		sg.Parent = item
	end

	local text = string.format(
		'<font color="#%s">%s</font>\n%s\n+$%s/s  |  %d%% chance',
		data.Color:ToHex(), data.Rarity, data.Name, fmt(data.Income), data.Chance
	)
	makeBillboard(item, 240, 90, 4.5, text, 70)

	local light = Instance.new("PointLight")
	light.Color = data.Color
	light.Range = 10
	light.Brightness = 1.5
	light.Shadows = false
	light.Parent = item
	if data.Rarity == "Mythic" or data.Rarity == "Godly" or data.Rarity == "Secret"
		or data.Rarity == "Celestial" or data.Rarity == "Infinity" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = data.Color
		sparkles.Parent = item
	end

	return item
end

local function clearItemExtras(item)
	for _, child in ipairs(item:GetChildren()) do
		if child:IsA("WeldConstraint") or child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	item.Anchored = true
	item.Massless = false
end

local function attachToPlayer(item, root)
	item.CFrame = root.CFrame * CFrame.new(0, 5, 0)
	item.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = item
	weld.Parent = item
	item.Anchored = false
	item.Parent = workspace
end

------------------------------------------------------------------
-- BASE SLOTS
------------------------------------------------------------------
local onSlotPrompt -- defined further down

local function placeInSlot(plot, slot, item, data, animate)
	clearItemExtras(item)
	item.Parent = plot.Model
	slot.Item, slot.Data, slot.Reserved = item, data, false

	local target = slot.Pedestal.CFrame * CFrame.new(0, 3.8, 0)
	if animate then
		TweenService:Create(item, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = target}):Play()
	else
		item.CFrame = target
	end

	-- The client script shows "Sell" to the owner and "Steal" to everyone else
	local prompt = makePrompt(item, "Steal", data.Name, 1, 7)
	prompt:SetAttribute("OwnerId", plot.Owner and plot.Owner.UserId or 0)
	prompt:SetAttribute("SellText", "Sell for $" .. fmt(data.Income * SELL_MULTIPLIER))
	prompt.Triggered:Connect(function(player)
		onSlotPrompt(player, plot, slot)
	end)
end

------------------------------------------------------------------
-- VAULT GAMES
------------------------------------------------------------------
local gamesFolder -- created with the map
local grabFromVault -- defined below

local function putOnSpot(spot, item, data)
	clearItemExtras(item)
	item.CFrame = spot.Pedestal.CFrame * CFrame.new(0, 3.5, 0)
	item.Parent = gamesFolder
	spot.Item, spot.Data, spot.Carried = item, data, false

	local prompt = makePrompt(item, "Steal", data.Name .. "  (+$" .. fmt(data.Income) .. "/s)", 0.8, 8)
	prompt.Triggered:Connect(function(player)
		grabFromVault(player, spot)
	end)
end

local function spawnSpot(spot)
	if spot.Item or spot.Carried then return end
	local data = pickGame(spot.Level)
	putOnSpot(spot, createItem(data), data)
end

local function canCarry(player)
	if carrying[player] then
		notify(player, "You're already carrying a game!", RED)
		return false
	end
	local myPlot = playerPlots[player]
	if not myPlot then
		notify(player, "You don't have a base!", RED)
		return false
	end
	if myPlot.Runner == player then
		notify(player, "Get off the treadmill first!", RED)
		return false
	end
	if not getFreeSlot(myPlot) then
		notify(player, "Your base is full! Sell something first.", RED)
		return false
	end
	return true
end

grabFromVault = function(player, spot)
	if not spot.Item or not canCarry(player) then return end
	local root = getRoot(player)
	if not root then return end

	local item, data = spot.Item, spot.Data
	spot.Item, spot.Data, spot.Carried = nil, nil, true
	clearItemExtras(item)
	attachToPlayer(item, root)

	carrying[player] = {Item = item, Data = data, Spot = spot}
	updateSpeed(player)
	notify(player, "You grabbed " .. data.Name .. "! Get it home!", GOLD)
end

------------------------------------------------------------------
-- CARRYING: RETURN OR DELIVER
------------------------------------------------------------------
local function returnCarried(player)
	local c = carrying[player]
	if not c then return end
	carrying[player] = nil
	updateSpeed(player)

	if c.Spot then
		putOnSpot(c.Spot, c.Item, c.Data)
		return
	end

	c.FromSlot.Reserved = false
	if c.FromOwner and c.FromPlot.Owner == c.FromOwner and not c.FromSlot.Item then
		placeInSlot(c.FromPlot, c.FromSlot, c.Item, c.Data, true)
		notify(c.FromOwner, "Your " .. c.Data.Name .. " was returned!", GREEN)
	else
		c.Item:Destroy()
	end
end

local function deliverCarried(player)
	local c = carrying[player]
	if not c then return end
	local myPlot = playerPlots[player]
	local slot = myPlot and getFreeSlot(myPlot)
	if not slot then
		notify(player, "Your base is full! The game went back.", RED)
		returnCarried(player)
		return
	end
	carrying[player] = nil
	updateSpeed(player)
	placeInSlot(myPlot, slot, c.Item, c.Data, false)
	notify(player, "You got " .. c.Data.Name .. "! +$" .. fmt(c.Data.Income) .. "/s", GREEN)

	if c.Spot then
		c.Spot.Carried = false
		local level = c.Spot.Level
		if not restockAt[level] then
			restockAt[level] = os.clock() + RESTOCK_TIME
		end
	else
		c.FromSlot.Reserved = false
		if c.FromOwner and c.FromOwner.Parent then
			notify(c.FromOwner, player.DisplayName .. " stole your " .. c.Data.Name .. "!", RED)
		end
	end
end

------------------------------------------------------------------
-- STEALING FROM / SELLING IN A BASE
------------------------------------------------------------------
onSlotPrompt = function(player, plot, slot)
	if not slot.Data then return end

	if plot.Owner == player then
		local value = slot.Data.Income * SELL_MULTIPLIER
		player.leaderstats.Cash.Value += value
		notify(player, "Sold " .. slot.Data.Name .. " for $" .. fmt(value), GREEN)
		slot.Item:Destroy()
		slot.Item, slot.Data = nil, nil
		return
	end

	if os.clock() < plot.LockedUntil then
		notify(player, "This base is locked!", RED)
		return
	end
	if not canCarry(player) then return end
	local root = getRoot(player)
	if not root then return end

	local item, data = slot.Item, slot.Data
	slot.Item, slot.Data, slot.Reserved = nil, nil, true
	clearItemExtras(item)
	attachToPlayer(item, root)

	carrying[player] = {Item = item, Data = data, FromPlot = plot, FromSlot = slot, FromOwner = plot.Owner}
	updateSpeed(player)

	notify(player, "You grabbed " .. data.Name .. "! Run back to your base!", GOLD)
	if plot.Owner then
		notify(plot.Owner, player.DisplayName .. " is stealing your " .. data.Name .. "! Slap them!", RED)
	end
end

------------------------------------------------------------------
-- WORLD: LIGHTING + TERRAIN
------------------------------------------------------------------
local map = Instance.new("Folder")
map.Name = "StealAGameMap"
map.Parent = workspace

gamesFolder = Instance.new("Folder")
gamesFolder.Name = "VaultGames"
gamesFolder.Parent = map

local guardsFolder = Instance.new("Folder")
guardsFolder.Name = "Shopkeepers"
guardsFolder.Parent = map

local scenery = Instance.new("Folder")
scenery.Name = "Scenery"
scenery.Parent = map

Lighting.ClockTime = 14.5
Lighting.Brightness = 2.5
Lighting.Ambient = rgb(70, 70, 80)
Lighting.OutdoorAmbient = rgb(140, 140, 150)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Haze = 1.5
atmosphere.Color = rgb(200, 215, 255)
atmosphere.Parent = Lighting

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local hallEnd = roomStart(NUM_LEVELS) + ROOM_LEN
local worldMinZ, worldMaxZ = -560, hallEnd + 80
local worldMidZ, worldLenZ = (worldMinZ + worldMaxZ) / 2, worldMaxZ - worldMinZ

-- Grass terrain sits BELOW the play area (top at GROUND_Y). Everything you walk on
-- (the plaza, the bases, the store floors) is a solid part with its top at y = 0,
-- so nothing can end up buried in terrain.
Terrain:Clear()
Terrain:FillBlock(CFrame.new(0, GROUND_Y - 4, worldMidZ), Vector3.new(1400, 8, worldLenZ), M.Grass)

-- Raised grassy lawn around the vault entrance where the bases sit
makeCylinder(map, 8, (BASE_RING_RADIUS + 50) * 2, CFrame.new(ENTRANCE + Vector3.new(0, -4, 0)), {Name = "Plaza", Color = rgb(98, 165, 74), Material = M.Grass})
makeCylinder(map, 7.6, (BASE_RING_RADIUS + 53) * 2, CFrame.new(ENTRANCE + Vector3.new(0, -4.2, 0)), {Name = "PlazaEdge", Color = rgb(125, 115, 100), Material = M.Cobblestone})

-- Stone walkways: a loop in front of the bases, a main path to the vault, and a short path to each base
do
	local PATH_COLOR = rgb(200, 192, 176)
	local LOOP_R = BASE_RING_RADIUS - PLOT_D / 2 - 18
	local pieces = 72
	local chord = 2 * LOOP_R * math.sin(math.pi / pieces)
	for i = 0, pieces - 1 do
		local a = (i + 0.5) / pieces * math.pi * 2
		local pos = ENTRANCE + Vector3.new(math.sin(a), 0, -math.cos(a)) * LOOP_R
		if not (math.abs(pos.X) < ROOM_W / 2 + 4 and pos.Z > HALL_START_Z - 4) then
			makePart(map, {Name = "Walkway", Size = Vector3.new(chord + 0.4, 0.2, 10), CFrame = CFrame.lookAt(pos + Vector3.new(0, 0.1, 0), ENTRANCE + Vector3.new(0, 0.1, 0)), Color = PATH_COLOR, Material = M.Pavement})
		end
	end
	local function path(r1, r2, angle, width)
		local dir = Vector3.new(math.sin(angle), 0, -math.cos(angle))
		local a, b = ENTRANCE + dir * r1, ENTRANCE + dir * r2
		makePart(map, {Name = "Walkway", Size = Vector3.new(width, 0.24, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.12, 0), b + Vector3.new(0, 0.12, 0)), Color = PATH_COLOR, Material = M.Pavement})
	end
	path(18, LOOP_R - 5, 0, 16)
	for i = 1, 8 do
		path(LOOP_R + 5, BASE_RING_RADIUS - PLOT_D / 2, math.rad(-BASE_ARC / 2 + (i - 1) * BASE_ARC / 7), 8)
	end
end

local rng = Random.new(2026)

-- Hills far from the plaza and the vault
local function hillOK(pos, radius)
	local flat = Vector3.new(pos.X, 0, pos.Z)
	return (flat - ENTRANCE).Magnitude - radius > BASE_RING_RADIUS + 120
		and math.abs(pos.X) - radius > ROOM_W / 2 + 60
end
for _ = 1, 40 do
	local radius = rng:NextNumber(45, 85)
	local pos = Vector3.new(rng:NextNumber(-650, 650), GROUND_Y - radius * 0.45, rng:NextNumber(worldMinZ + 40, worldMaxZ - 40))
	if hillOK(pos, radius) then
		Terrain:FillBall(pos, radius, M.Grass)
	end
end

------------------------------------------------------------------
-- PROPS (decorations)
------------------------------------------------------------------
local function buildProp(parent, kind, pos, color)
	-- Props face the middle of the hallway
	local face = CFrame.lookAt(pos, Vector3.new(0, pos.Y, pos.Z))
	if pos.X == 0 then
		face = CFrame.new(pos)
	end

	if kind == "crate" then
		makePart(parent, {Size = Vector3.new(5, 5, 5), CFrame = face * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), Color = rgb(150, 105, 60), Material = M.WoodPlanks})
		makePart(parent, {Size = Vector3.new(3.5, 3.5, 3.5), CFrame = face * CFrame.new(0.5, 6.75, 0) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0), Color = rgb(170, 125, 75), Material = M.WoodPlanks})
	elseif kind == "barrel" then
		for i = 0, 1 do
			makeCylinder(parent, 5, 4, face * CFrame.new(i * 4.5 - 2, 2.5, 0), {Color = rgb(115, 75, 40), Material = M.Wood})
		end
	elseif kind == "screen" then
		makePart(parent, {Size = Vector3.new(4, 8, 3), CFrame = face * CFrame.new(0, 4, 0), Color = rgb(30, 30, 40)})
		makePart(parent, {Size = Vector3.new(3, 2.5, 0.2), CFrame = face * CFrame.new(0, 5.5, -1.6), Color = color, Material = M.Neon})
		makePart(parent, {Size = Vector3.new(4, 0.6, 1.4), CFrame = face * CFrame.new(0, 3.5, -2), Color = rgb(60, 60, 75)})
	elseif kind == "lamp" then
		makeCylinder(parent, 10, 0.6, face * CFrame.new(0, 5, 0), {Color = rgb(40, 40, 40), Material = M.Metal})
		local bulb = makePart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = face * CFrame.new(0, 10.5, 0), Color = color, Material = M.Neon})
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 18
		light.Brightness = 1.5
		light.Shadows = false
		light.Parent = bulb
	elseif kind == "toyblock" then
		local colors = {rgb(255, 80, 80), rgb(80, 160, 255), rgb(255, 220, 60), rgb(90, 220, 110)}
		for i = 0, 2 do
			makePart(parent, {Size = Vector3.new(3, 3, 3), CFrame = face * CFrame.new(0, 1.5 + i * 3, 0) * CFrame.Angles(0, rng:NextNumber(-0.7, 0.7), 0), Color = colors[rng:NextInteger(1, #colors)]})
		end
		makePart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = face * CFrame.new(4, 2, 0), Color = colors[rng:NextInteger(1, #colors)]})
	elseif kind == "tire" then
		for i = 0, 2 do
			makeCylinder(parent, 1.6, 4.5, face * CFrame.new(0, 0.8 + i * 1.6, 0), {Color = rgb(25, 25, 25), Material = M.Fabric})
		end
	elseif kind == "cone" then
		makePart(parent, {Size = Vector3.new(3, 0.4, 3), CFrame = face * CFrame.new(0, 0.2, 0), Color = rgb(255, 120, 20)})
		for i, d in ipairs({2.2, 1.6, 1.0}) do
			makeCylinder(parent, 1.2, d, face * CFrame.new(0, 0.4 + (i - 0.5) * 1.2, 0), {Color = (i == 2) and rgb(245, 245, 245) or rgb(255, 120, 20)})
		end
	elseif kind == "palm" then
		makeCylinder(parent, 14, 1.4, face * CFrame.new(0, 7, 0) * CFrame.Angles(0.1, 0, 0), {Color = rgb(130, 95, 55), Material = M.Wood})
		for i = 0, 4 do
			makePart(parent, {Size = Vector3.new(8, 0.4, 2), CFrame = face * CFrame.new(0, 14, 0) * CFrame.Angles(0, i * math.pi * 2 / 5, -0.35) * CFrame.new(3.5, 0, 0), Color = rgb(60, 160, 60), Material = M.Grass, CanCollide = false})
		end
	elseif kind == "tombstone" then
		makePart(parent, {Size = Vector3.new(3, 4, 1), CFrame = face * CFrame.new(0, 2, 0) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, rng:NextNumber(-0.1, 0.1)), Color = rgb(120, 120, 125), Material = M.Slate})
		makePart(parent, {Size = Vector3.new(3, 4, 1), CFrame = face * CFrame.new(4, 1.6, 2) * CFrame.Angles(0, 0, 0.15), Color = rgb(100, 100, 105), Material = M.Slate})
	elseif kind == "neonpillar" then
		makeCylinder(parent, WALL_H - 4, 2, face * CFrame.new(0, (WALL_H - 4) / 2, 0), {Color = color, Material = M.Neon})
	elseif kind == "pillar" then
		makePart(parent, {Size = Vector3.new(5, 1.5, 5), CFrame = face * CFrame.new(0, 0.75, 0), Color = rgb(220, 220, 225), Material = M.Marble})
		makeCylinder(parent, WALL_H - 2, 3.5, face * CFrame.new(0, (WALL_H - 2) / 2 + 1, 0), {Color = rgb(235, 235, 240), Material = M.Marble})
	elseif kind == "bamboo" then
		for i = -1, 1 do
			makeCylinder(parent, 14 + i * 2, 0.8, face * CFrame.new(i * 1.2, 7 + i, i * 0.6), {Color = rgb(110, 170, 70), Material = M.Wood})
		end
	elseif kind == "gear" then
		makePart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 9, 9), CFrame = face * CFrame.new(0, 5, 0) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(150, 150, 160), Material = M.Metal})
		for i = 0, 7 do
			makePart(parent, {Size = Vector3.new(1, 1.6, 1.4), CFrame = face * CFrame.new(0, 5, 0) * CFrame.Angles(i * math.pi / 4, 0, 0) * CFrame.new(0, 4.8, 0), Color = rgb(150, 150, 160), Material = M.Metal})
		end
		makePart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 3, 3), CFrame = face * CFrame.new(0, 5, 0) * CFrame.Angles(0, math.pi / 2, 0), Color = color, Material = M.Neon})
	elseif kind == "gold" then
		for _ = 1, 6 do
			local s = rng:NextNumber(1.5, 3.5)
			makePart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), CFrame = face * CFrame.new(rng:NextNumber(-3, 3), s / 2, rng:NextNumber(-2, 2)), Color = rgb(255, 200, 40), Material = M.Foil})
		end
	elseif kind == "rock" then
		makePart(parent, {Size = Vector3.new(rng:NextNumber(4, 7), rng:NextNumber(3, 6), rng:NextNumber(4, 7)), CFrame = face * CFrame.new(0, 2, 0) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), Color = color, Material = M.Basalt})
	elseif kind == "planet" then
		local planet = makePart(parent, {Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), CFrame = face * CFrame.new(0, 12, 0), Color = color, Material = M.Neon, CanCollide = false})
		makePart(parent, {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 10, 10), CFrame = planet.CFrame * CFrame.Angles(0, 0, math.pi / 2 + 0.4), Color = rgb(220, 220, 255), Material = M.Glass, Transparency = 0.4, CanCollide = false})
	elseif kind == "crystal" then
		for i = 0, 2 do
			makePart(parent, {Size = Vector3.new(1.6, 5 + i * 2, 1.6), CFrame = face * CFrame.new(i * 1.4 - 1.4, 2.5 + i, 0) * CFrame.Angles(0, 0.78, (i - 1) * 0.3), Color = color, Material = M.Neon, Transparency = 0.2})
		end
	end
end

-- Store floor colors for each floor material
local FLOOR_COLORS = {
	[M.Mud] = rgb(105, 80, 55), [M.Brick] = rgb(150, 70, 55), [M.LeafyGrass] = rgb(95, 150, 70),
	[M.Sand] = rgb(225, 205, 155), [M.Slate] = rgb(85, 90, 95), [M.Concrete] = rgb(120, 120, 130),
	[M.WoodPlanks] = rgb(160, 115, 70), [M.Pavement] = rgb(125, 125, 130), [M.CrackedLava] = rgb(70, 40, 35),
	[M.Basalt] = rgb(45, 45, 60),
}

-- Wall shelf full of game boxes
local function buildShelf(parent, side, z, colors)
	local wallX = side * (ROOM_W / 2 - 0.3)
	local shelfX = side * (ROOM_W / 2 - 2.1)
	local wood, lightWood = rgb(70, 50, 35), rgb(115, 85, 55)
	makePart(parent, {Size = Vector3.new(0.6, 11, 14), CFrame = CFrame.new(wallX, 5.5, z), Color = wood, Material = M.Wood})
	for _, dz in ipairs({-7, 7}) do
		makePart(parent, {Size = Vector3.new(3.6, 11, 0.4), CFrame = CFrame.new(shelfX, 5.5, z + dz), Color = wood, Material = M.Wood})
	end
	for row = 0, 2 do
		local y = 1.5 + row * 3.4
		makePart(parent, {Size = Vector3.new(3.4, 0.3, 14), CFrame = CFrame.new(shelfX, y, z), Color = lightWood, Material = M.WoodPlanks})
		for b = 0, 3 do
			makePart(parent, {
				Size = Vector3.new(1.6, 2.4, 1.2),
				CFrame = CFrame.new(shelfX, y + 1.35, z - 4.8 + b * 3.2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0),
				Color = colors[rng:NextInteger(1, #colors)],
			})
		end
	end
end

------------------------------------------------------------------
-- THE VAULT (hallway of 50 stores)
------------------------------------------------------------------
local function buildRoom(level)
	local L = LEVELS[level]
	local zone = L.Zone
	local z0 = roomStart(level)
	local zMid = z0 + ROOM_LEN / 2
	local accent = L.Accent

	local room = Instance.new("Model")
	room.Name = string.format("%02d_%s", level, L.Store)
	room.Parent = map
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = room

	-- Floor terrain unique to the zone, plus a carpet runner down the middle
	makePart(room, {Name = "Floor", Size = Vector3.new(ROOM_W + 4, 8, ROOM_LEN), CFrame = CFrame.new(0, -3.9, zMid), Color = FLOOR_COLORS[zone.Ground] or rgb(120, 120, 120), Material = zone.Ground})
	makePart(decor, {Name = "Carpet", Size = Vector3.new(DOOR_W - 6, 0.15, ROOM_LEN - 4), CFrame = CFrame.new(0, 0.18, zMid), Color = accent:Lerp(DARK, 0.55), Material = M.Fabric, CanCollide = false})
	for _, sx in ipairs({-1, 1}) do
		makePart(decor, {Name = "CarpetEdge", Size = Vector3.new(0.6, 0.18, ROOM_LEN - 4), CFrame = CFrame.new(sx * (DOOR_W / 2 - 3), 0.2, zMid), Color = accent, Material = M.Neon, CanCollide = false})
	end

	-- Side walls with glowing trim, and the roof
	for _, sx in ipairs({-1, 1}) do
		makePart(room, {Name = "Wall", Size = Vector3.new(2, WALL_H, ROOM_LEN), CFrame = CFrame.new(sx * (ROOM_W / 2 + 1), WALL_H / 2, zMid), Color = L.Wall, Material = zone.WallMat})
		makePart(room, {Name = "Trim", Size = Vector3.new(0.4, 0.8, ROOM_LEN), CFrame = CFrame.new(sx * (ROOM_W / 2 - 0.1), WALL_H - 1.5, zMid), Color = accent, Material = M.Neon, CanCollide = false})
		makePart(room, {Name = "Baseboard", Size = Vector3.new(0.5, 1, ROOM_LEN), CFrame = CFrame.new(sx * (ROOM_W / 2 - 0.1), 0.5, zMid), Color = L.Wall:Lerp(DARK, 0.5), Material = M.SmoothPlastic})
	end
	makePart(room, {Name = "Roof", Size = Vector3.new(ROOM_W + 6, 1.5, ROOM_LEN + 0.2), CFrame = CFrame.new(0, WALL_H + 0.75, zMid), Color = L.Wall:Lerp(DARK, 0.4), Material = zone.WallMat})
	for _, bz in ipairs({10, 30, 50}) do
		makePart(room, {Name = "Beam", Size = Vector3.new(ROOM_W, 1.2, 1.2), CFrame = CFrame.new(0, WALL_H - 0.6, z0 + bz), Color = L.Wall:Lerp(DARK, 0.6), Material = zone.WallMat})
	end

	-- Ceiling lights
	for _, lz in ipairs({18, 42}) do
		local panel = makePart(room, {Name = "CeilingLight", Size = Vector3.new(12, 0.4, 4), CFrame = CFrame.new(0, WALL_H - 0.2, z0 + lz), Color = accent:Lerp(Color3.new(1, 1, 1), 0.6), Material = M.Neon, CanCollide = false})
		local light = Instance.new("PointLight")
		light.Range = 50
		light.Brightness = 1.3
		light.Color = accent:Lerp(Color3.new(1, 1, 1), 0.7)
		light.Shadows = false
		light.Parent = panel
	end

	-- Front wall with a doorway and the store sign
	local sideW = (ROOM_W - DOOR_W) / 2
	for _, sx in ipairs({-1, 1}) do
		makePart(room, {Name = "FrontWall", Size = Vector3.new(sideW + 2, WALL_H, 2), CFrame = CFrame.new(sx * (DOOR_W / 2 + sideW / 2 + 1), WALL_H / 2, z0), Color = L.Wall, Material = zone.WallMat})
		makePart(room, {Name = "DoorFrame", Size = Vector3.new(1, DOOR_H, 2.4), CFrame = CFrame.new(sx * (DOOR_W / 2 + 0.5), DOOR_H / 2, z0), Color = accent, Material = M.Neon})
	end
	makePart(room, {Name = "Lintel", Size = Vector3.new(DOOR_W, WALL_H - DOOR_H, 2), CFrame = CFrame.new(0, DOOR_H + (WALL_H - DOOR_H) / 2, z0), Color = L.Wall, Material = zone.WallMat})
	makePart(room, {Name = "DoorTop", Size = Vector3.new(DOOR_W + 2, 1, 2.4), CFrame = CFrame.new(0, DOOR_H + 0.5, z0), Color = accent, Material = M.Neon})

	local sign = makePart(room, {Name = "StoreSign", Size = Vector3.new(DOOR_W + 8, 6.5, 0.6), CFrame = CFrame.new(0, DOOR_H + 4.8, z0 - 1.4), Color = rgb(20, 20, 25)})
	makeSurfaceText(sign, Enum.NormalId.Front, string.upper(L.Store), accent, 40)
	local signLight = Instance.new("SurfaceLight")
	signLight.Face = Enum.NormalId.Front
	signLight.Color = accent
	signLight.Range = 12
	signLight.Parent = sign
	makePart(room, {Name = "SignFrame", Size = Vector3.new(DOOR_W + 9, 7.5, 0.4), CFrame = CFrame.new(0, DOOR_H + 4.8, z0 - 1.15), Color = accent, Material = M.Neon})

	-- Shelves of games along both walls, with posters above
	local boxColors = {accent, zone.Color, accent:Lerp(Color3.new(1, 1, 1), 0.4), zone.Color:Lerp(DARK, 0.3), rgb(240, 240, 240), rgb(40, 40, 50)}
	for _, side in ipairs({-1, 1}) do
		for pi, sz in ipairs({12, 48}) do
			buildShelf(decor, side, z0 + sz, boxColors)
			local poster = makePart(decor, {Name = "Poster", Size = Vector3.new(0.2, 7, 12), CFrame = CFrame.new(side * (ROOM_W / 2 - 0.2), 16, z0 + sz), Color = accent:Lerp(DARK, 0.7), Material = M.SmoothPlastic})
			local posterText = (pi == 1) and L.Games[(side == 1) and 1 or 2].Name or L.Games[3].Name
			makeSurfaceText(poster, (side == 1) and Enum.NormalId.Left or Enum.NormalId.Right, posterText, accent, 30)
			makePart(decor, {Name = "PosterFrame", Size = Vector3.new(0.15, 7.6, 12.6), CFrame = CFrame.new(side * (ROOM_W / 2 - 0.12), 16, z0 + sz), Color = accent, Material = M.Neon})
		end
	end

	-- Themed decorations
	buildProp(decor, zone.Props[1], Vector3.new(38, 0, z0 + 30), accent)
	buildProp(decor, zone.Props[2], Vector3.new(-38, 0, z0 + 6), accent)
	buildProp(decor, zone.Props[2], Vector3.new(38, 0, z0 + 6), accent)

	-- Checkout counter in front of the shopkeeper (middle right of the store)
	makePart(decor, {Name = "Counter", Size = Vector3.new(14, 3.5, 3), CFrame = CFrame.new(-22, 1.75, z0 + 24), Color = L.Wall:Lerp(rgb(255, 255, 255), 0.2), Material = zone.WallMat})
	makePart(decor, {Name = "CounterTop", Size = Vector3.new(14.6, 0.3, 3.6), CFrame = CFrame.new(-22, 3.65, z0 + 24), Color = accent, Material = M.Neon})
	makePart(decor, {Name = "Register", Size = Vector3.new(2, 1.4, 1.6), CFrame = CFrame.new(-26, 4.5, z0 + 24), Color = rgb(40, 40, 45), Material = M.Metal})

	-- Three display pedestals
	for _, px in ipairs({-24, 0, 24}) do
		local ped = makePart(decor, {
			Name = "Pedestal", Size = Vector3.new(5, 2, 5), CFrame = CFrame.new(px, 1, z0 + 46),
			Color = accent:Lerp(Color3.new(1, 1, 1), 0.55), Material = M.Marble,
		})
		makePart(decor, {Name = "PedestalRing", Size = Vector3.new(6.4, 0.3, 6.4), CFrame = CFrame.new(px, 0.25, z0 + 46), Color = accent, Material = M.Neon, CanCollide = false})
		makePart(decor, {Name = "Spotlight", Size = Vector3.new(2, 0.6, 2), CFrame = CFrame.new(px, WALL_H - 0.3, z0 + 46), Color = rgb(250, 250, 230), Material = M.Neon, CanCollide = false})
		table.insert(spots, {Pedestal = ped, Level = level, Item = nil, Data = nil, Carried = false})
	end

	-- Restock countdown floating above the pedestals
	local timerPart = makePart(decor, {Name = "RestockTimer", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(0, 13, z0 + 46), Transparency = 1, CanCollide = false})
	restockLabels[level] = makeBillboard(timerPart, 260, 50, 0, "IN STOCK", 110)

	setGroup(decor, "Decor")
end

for level = 1, NUM_LEVELS do
	buildRoom(level)
end

makePart(map, {Name = "VaultEnd", Size = Vector3.new(ROOM_W + 4, WALL_H, 2), CFrame = CFrame.new(0, WALL_H / 2, hallEnd), Color = LEVELS[NUM_LEVELS].Wall, Material = LEVELS[NUM_LEVELS].Zone.WallMat})

-- Grand entrance
do
	local front = Instance.new("Model")
	front.Name = "VaultEntrance"
	front.Parent = map
	for _, sx in ipairs({-1, 1}) do
		makePart(front, {Name = "Tower", Size = Vector3.new(10, WALL_H + 10, 10), CFrame = CFrame.new(sx * (DOOR_W / 2 + 6), (WALL_H + 10) / 2, HALL_START_Z - 4), Color = rgb(70, 60, 55), Material = M.Cobblestone})
		makePart(front, {Name = "TowerCap", Size = Vector3.new(12, 2, 12), CFrame = CFrame.new(sx * (DOOR_W / 2 + 6), WALL_H + 11, HALL_START_Z - 4), Color = rgb(255, 210, 60), Material = M.Neon})
		makeCylinder(front, 8, 1.2, CFrame.new(sx * (DOOR_W / 2 + 6), 4, HALL_START_Z - 10), {Color = rgb(60, 45, 30), Material = M.Wood})
		local flame = makePart(front, {Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(sx * (DOOR_W / 2 + 6), 8.5, HALL_START_Z - 10), Color = rgb(255, 140, 30), Material = M.Neon, CanCollide = false})
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Parent = flame
	end
	local sign = makePart(front, {Name = "VaultSign", Size = Vector3.new(DOOR_W + 22, 8, 1), CFrame = CFrame.new(0, WALL_H + 5, HALL_START_Z - 4), Color = rgb(25, 20, 20)})
	makeSurfaceText(sign, Enum.NormalId.Front, "THE GAME VAULT", rgb(255, 210, 60), 30)
	-- Welcome mat
	makePart(front, {Name = "Mat", Size = Vector3.new(DOOR_W, 0.2, 14), CFrame = CFrame.new(0, 0.1, HALL_START_Z - 9), Color = rgb(150, 30, 30), Material = M.Fabric, CanCollide = false})
end

------------------------------------------------------------------
-- OUTDOOR SCENERY
------------------------------------------------------------------
local function buildTree(pos, scale)
	makeCylinder(scenery, 10 * scale, 1.6 * scale, CFrame.new(pos + Vector3.new(0, 5 * scale, 0)), {Color = rgb(110, 75, 45), Material = M.Wood})
	local leafColor = rgb(50, rng:NextInteger(130, 170), 60)
	makePart(scenery, {Shape = Enum.PartType.Ball, Size = Vector3.one * 9 * scale, CFrame = CFrame.new(pos + Vector3.new(0, 11 * scale, 0)), Color = leafColor, Material = M.Grass})
	makePart(scenery, {Shape = Enum.PartType.Ball, Size = Vector3.one * 6 * scale, CFrame = CFrame.new(pos + Vector3.new(2 * scale, 14 * scale, 1 * scale)), Color = leafColor:Lerp(rgb(120, 200, 90), 0.3), Material = M.Grass})
end

local placed, tries = 0, 0
while placed < 140 and tries < 1500 do
	tries += 1
	local x = rng:NextNumber(-650, 650)
	local z = rng:NextNumber(worldMinZ + 20, worldMaxZ - 20)
	local nearHall = math.abs(x) < ROOM_W / 2 + 30 and z > HALL_START_Z - 30
	local nearPlaza = (Vector3.new(x, 0, z) - ENTRANCE).Magnitude < BASE_RING_RADIUS + 60
	if not nearHall and not nearPlaza then
		placed += 1
		if rng:NextNumber() < 0.8 then
			buildTree(Vector3.new(x, GROUND_Y, z), rng:NextNumber(0.8, 1.6))
		else
			buildProp(scenery, "rock", Vector3.new(x, GROUND_Y, z), rgb(110, 110, 105))
		end
	end
end

-- Lamp posts and flower beds around the plaza
for i = 0, 15 do
	local angle = math.rad(-110 + i * 220 / 15)
	local pos = ENTRANCE + Vector3.new(math.sin(angle), 0, -math.cos(angle)) * (BASE_RING_RADIUS + 38)
	buildProp(scenery, "lamp", pos, rgb(255, 230, 170))
end
-- The spawn pad stays (players need somewhere to appear) but is hidden; everyone is moved to their base right away
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("SpawnLocation") then
		obj.CFrame = CFrame.new(ENTRANCE + Vector3.new(0, 0.5, -60))
		obj.Transparency = 1
		obj.CanCollide = false
		obj.CanQuery = false
		obj.CastShadow = false
		for _, child in ipairs(obj:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:Destroy()
			end
		end
	end
end

-- LOBBY BORDER: wooden fence on the edge of the lawn, thick forest behind it,
-- and an invisible wall so nobody can jump over the fence
do
	local border = Instance.new("Folder")
	border.Name = "LobbyBorder"
	border.Parent = map
	local FENCE_R = BASE_RING_RADIUS + 48
	local WALL_HEIGHT = 150
	local POST, RAIL = rgb(115, 78, 48), rgb(150, 105, 64)
	local function inHall(pos, pad)
		return math.abs(pos.X) < ROOM_W / 2 + pad and pos.Z > HALL_START_Z - 2
	end
	local function fencePiece(cf, len)
		-- cf: X axis runs along the fence
		makePart(border, {Name = "FencePost", Size = Vector3.new(0.9, 6, 0.9), CFrame = cf * CFrame.new(-len / 2, 3, 0), Color = POST, Material = M.Wood})
		for _, y in ipairs({2, 4.4}) do
			makePart(border, {Name = "FenceRail", Size = Vector3.new(len + 0.2, 0.55, 0.35), CFrame = cf * CFrame.new(0, y, 0), Color = RAIL, Material = M.WoodPlanks})
		end
		makePart(border, {Name = "InvisibleWall", Size = Vector3.new(len + 1, WALL_HEIGHT, 2), CFrame = cf * CFrame.new(0, WALL_HEIGHT / 2, 0), Transparency = 1, CanQuery = false, CastShadow = false})
	end

	local segs = 200
	local segLen = 2 * FENCE_R * math.sin(math.pi / segs)
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi * 2
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local pos = ENTRANCE + dir * FENCE_R
		if not inHall(pos, 2) then
			fencePiece(CFrame.lookAt(pos, pos + dir), segLen)
		end
	end
	-- Close the small gaps where the fence meets the vault walls
	for _, sx in ipairs({-1, 1}) do
		local x = sx * (ROOM_W / 2 + 6)
		local z = ENTRANCE.Z + math.sqrt(FENCE_R ^ 2 - x ^ 2)
		fencePiece(CFrame.new(x, 0, z), 12)
	end

	-- Dense forest just outside the fence
	for row = 0, 2 do
		local r = FENCE_R + 12 + row * 12
		local count = math.floor(2 * math.pi * r / 11)
		for i = 0, count - 1 do
			local a = (i + (row % 2) * 0.5 + rng:NextNumber(-0.25, 0.25)) / count * math.pi * 2
			local pos = ENTRANCE + Vector3.new(math.sin(a), 0, -math.cos(a)) * (r + rng:NextNumber(-3, 3))
			if not inHall(pos, 8) then
				buildTree(Vector3.new(pos.X, GROUND_Y, pos.Z), rng:NextNumber(1.3, 2.1))
			end
		end
	end
end

------------------------------------------------------------------
-- TREADMILL (rebuilt with better looks on every upgrade)
------------------------------------------------------------------
local SLAT_COUNT, SLAT_GAP = 8, 1.55
local BELT_TOP = 1.9

local function rebuildTreadmill(plot)
	local owner = plot.Owner
	local level = owner and (owner:GetAttribute("TreadLevel") or 0) or 0
	local tier = TREAD_TIERS[math.min(#TREAD_TIERS, math.floor(level / 5) + 1)]
	local function at(x, y, z)
		return plot.CF * CFrame.new(x, y, z)
	end

	if plot.TreadModel then
		plot.TreadModel:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Treadmill"
	model.Parent = plot.Model
	plot.TreadModel = model

	local wide = tier.Panels and 1 or 0
	makePart(model, {Name = "Frame", Size = Vector3.new(7 + wide, 0.6, 13.5), CFrame = at(0, 1.3, -10), Color = tier.Frame, Material = tier.FrameMat})

	-- Belt slats (they slide backwards while someone is running)
	plot.Slats = {}
	for i = 1, SLAT_COUNT do
		local slatColor = (tier.AccentMat == M.Neon and i % 2 == 0) and tier.Accent:Lerp(DARK, 0.65) or rgb(22, 22, 25)
		local slat = makePart(model, {Name = "Slat", Size = Vector3.new(6, 0.3, SLAT_GAP - 0.1), CFrame = at(0, BELT_TOP - 0.15, -16 + (i - 1) * SLAT_GAP), Color = slatColor, Material = M.Fabric})
		table.insert(plot.Slats, slat)
	end

	for _, sx in ipairs({-1, 1}) do
		makePart(model, {Name = "Rail", Size = Vector3.new(0.4, 0.4, 10), CFrame = at(sx * 3.4, 4.4, -11), Color = tier.Accent, Material = tier.AccentMat})
		makePart(model, {Name = "RailPost", Size = Vector3.new(0.4, 2.8, 0.4), CFrame = at(sx * 3.4, 3, -15.8), Color = tier.Frame, Material = tier.FrameMat})
		if tier.Panels then
			makePart(model, {Name = "SidePanel", Size = Vector3.new(0.5, 1, 13.5), CFrame = at(sx * 4.1, 1.6, -10), Color = tier.Accent, Material = tier.AccentMat})
		end
	end

	-- Console with an upgrade meter: one light per level
	local console = makePart(model, {Name = "Console", Size = Vector3.new(6, 3.5, 1), CFrame = at(0, 2.75, -17.5), Color = tier.Frame, Material = tier.FrameMat})
	makePart(model, {Name = "Screen", Size = Vector3.new(4, 1.4, 0.2), CFrame = at(0, 3.3, -17.05), Color = tier.Accent:Lerp(rgb(80, 170, 255), 0.4), Material = M.Neon})
	for i = 1, TREADMILL_MAX_LEVEL do
		local lit = i <= level
		makePart(model, {
			Name = "Meter", Size = Vector3.new(0.18, 0.5, 0.15),
			CFrame = at(-2.76 + (i - 1) * 0.23, 2.1, -16.95),
			Color = lit and tier.Accent or rgb(40, 40, 45), Material = lit and M.Neon or M.SmoothPlastic,
		})
	end
	if tier.Light then
		local light = Instance.new("PointLight")
		light.Color = tier.Accent
		light.Range = 14
		light.Brightness = 2
		light.Parent = console
	end
	if tier.Sparkles then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = tier.Accent
		sparkles.Parent = console
	end
	if tier.Arch then
		for _, sx in ipairs({-1, 1}) do
			makePart(model, {Name = "ArchPost", Size = Vector3.new(0.6, 9, 0.6), CFrame = at(sx * 4.4, 5.5, -4), Color = tier.Accent, Material = M.Neon})
		end
		makePart(model, {Name = "ArchTop", Size = Vector3.new(9.4, 0.6, 0.6), CFrame = at(0, 10, -4), Color = tier.Accent, Material = M.Neon})
	end

	plot.TreadLabel.Text = string.format("%s TREADMILL  Lv %d\n+%.1f speed/s", string.upper(tier.Name), level, treadmillRate(level) * SPEED_DISPLAY)
	if not owner then
		plot.UpgradePrompt.ActionText = "Upgrade Treadmill"
	elseif level >= TREADMILL_MAX_LEVEL then
		plot.UpgradePrompt.ActionText = "Treadmill maxed!"
	else
		plot.UpgradePrompt.ActionText = "Upgrade ($" .. fmt(treadmillCost(level)) .. ")"
	end
end

local function stopTreadmill(plot)
	local runner = plot.Runner
	if not runner then return end
	plot.Runner = nil
	plot.RunPrompt.ActionText = "Run on Treadmill"
	local root = runner.Character and runner.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
		root.CFrame = plot.CF * CFrame.new(0, 4, -1)
	end
	if runner.Parent then
		treadmillEvent:FireClient(runner, false)
	end
end

local function startTreadmill(plot, player)
	local char = player.Character
	local root = getRoot(player)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	local height = hum.RigType == Enum.HumanoidRigType.R6 and 3 or (hum.HipHeight + root.Size.Y / 2)
	plot.Runner = player
	plot.RunPrompt.ActionText = "Stop Running"
	root.Anchored = true
	root.CFrame = plot.CF * CFrame.new(0, BELT_TOP + height, -10)
	treadmillEvent:FireClient(player, true)
end

------------------------------------------------------------------
-- BASES (a ring in front of the vault entrance)
------------------------------------------------------------------
local PLOT_COLORS = {
	rgb(255, 90, 90), rgb(90, 160, 255), rgb(90, 220, 120), rgb(255, 200, 70),
	rgb(190, 110, 255), rgb(255, 140, 60), rgb(70, 220, 220), rgb(255, 120, 200),
}

local function buildPlot(index, pos)
	-- The plot's open front faces the vault entrance
	local cf = CFrame.lookAt(pos, Vector3.new(ENTRANCE.X, pos.Y, ENTRANCE.Z))
	local function at(x, y, zz)
		return cf * CFrame.new(x, y, zz)
	end
	local accent = PLOT_COLORS[index]

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = map

	local wallColor = rgb(46, 48, 60)
	local deep = accent:Lerp(Color3.new(0, 0, 0), 0.55)
	local soft = accent:Lerp(Color3.new(1, 1, 1), 0.35)

	-- Floor: dark slate, a checkered front area, and a rug under the display cases
	makePart(model, {Name = "Floor", Size = Vector3.new(PLOT_W, 1, PLOT_D), CFrame = at(0, 0.5, 0), Color = rgb(62, 64, 76), Material = M.Slate})
	makePart(model, {Name = "FloorTrim", Size = Vector3.new(PLOT_W + 1, 0.4, PLOT_D + 1), CFrame = at(0, 0.2, 0), Color = accent, Material = M.Neon})
	for col = 0, 7 do
		for row = 0, 4 do
			if (col + row) % 2 == 0 then
				makePart(model, {Name = "Tile", Size = Vector3.new(4, 0.06, 4), CFrame = at(-14 + col * 4, 1.03, -20 + row * 4), Color = rgb(88, 90, 104), Material = M.Marble, CanCollide = false})
			end
		end
	end
	makePart(model, {Name = "Rug", Size = Vector3.new(PLOT_W - 4, 0.08, 18), CFrame = at(0, 1.04, 12), Color = deep, Material = M.Fabric, CanCollide = false})
	makePart(model, {Name = "RugEdge", Size = Vector3.new(PLOT_W - 3, 0.06, 19), CFrame = at(0, 1.02, 12), Color = soft, Material = M.Fabric, CanCollide = false})

	-- Brick walls with glowing trim and metal caps
	local walls = {
		{"BackWall", Vector3.new(PLOT_W, 14, 1), Vector3.new(0, 8, PLOT_D / 2 - 0.5)},
		{"LeftWall", Vector3.new(1, 14, PLOT_D), Vector3.new(-PLOT_W / 2 + 0.5, 8, 0)},
		{"RightWall", Vector3.new(1, 14, PLOT_D), Vector3.new(PLOT_W / 2 - 0.5, 8, 0)},
	}
	for _, w in ipairs(walls) do
		local size, p = w[2], w[3]
		makePart(model, {Name = w[1], Size = size, CFrame = at(p.X, p.Y, p.Z), Color = wallColor, Material = M.Brick})
		makePart(model, {Name = "WallCap", Size = size + Vector3.new(0.6, 0, 0.6) * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6 - size.Y, 0), CFrame = at(p.X, 15.3, p.Z), Color = rgb(225, 190, 90), Material = M.Metal})
	end
	for _, y in ipairs({3, 13.8}) do
		makePart(model, {Name = "Glow", Size = Vector3.new(PLOT_W - 2, 0.35, 0.2), CFrame = at(0, y, PLOT_D / 2 - 1.1), Color = accent, Material = M.Neon, CanCollide = false})
		for _, sx in ipairs({-1, 1}) do
			makePart(model, {Name = "Glow", Size = Vector3.new(0.2, 0.35, PLOT_D - 2), CFrame = at(sx * (PLOT_W / 2 - 1.1), y, 0), Color = accent, Material = M.Neon, CanCollide = false})
		end
	end

	-- Banner on the back wall
	local banner = makePart(model, {Name = "Banner", Size = Vector3.new(PLOT_W - 8, 2.6, 0.2), CFrame = at(0, 11.6, PLOT_D / 2 - 1.15), Color = rgb(20, 20, 28), CanCollide = false})
	makeSurfaceText(banner, Enum.NormalId.Front, "HALL OF GAMES", soft, 40)

	-- Wall lamps
	for _, sx in ipairs({-1, 1}) do
		for _, zz in ipairs({-8, 6}) do
			local lamp = makePart(model, {Name = "WallLamp", Size = Vector3.new(0.5, 1.6, 1.2), CFrame = at(sx * (PLOT_W / 2 - 1.25), 9, zz), Color = soft, Material = M.Neon, CanCollide = false})
			local glow = Instance.new("PointLight")
			glow.Color = accent
			glow.Range = 12
			glow.Brightness = 1.2
			glow.Shadows = false
			glow.Parent = lamp
		end
	end

	-- Corner pillars with glowing orbs, and an archway over the open front
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			local px, pz = sx * (PLOT_W / 2), sz * (PLOT_D / 2)
			makeCylinder(model, 17, 3, at(px, 8.5, pz), {Name = "Pillar", Color = rgb(235, 232, 225), Material = M.Marble})
			makeCylinder(model, 0.8, 3.8, at(px, 17.4, pz), {Name = "PillarTop", Color = rgb(225, 190, 90), Material = M.Metal})
			local orb = makePart(model, {Name = "Orb", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = at(px, 19, pz), Color = accent, Material = M.Neon, CanCollide = false})
			local light = Instance.new("PointLight")
			light.Color = accent
			light.Range = 16
			light.Brightness = 1.5
			light.Shadows = false
			light.Parent = orb
		end
	end
	makePart(model, {Name = "Arch", Size = Vector3.new(PLOT_W, 2, 1.4), CFrame = at(0, 16.4, -PLOT_D / 2), Color = wallColor, Material = M.Brick})
	makePart(model, {Name = "ArchGlow", Size = Vector3.new(PLOT_W - 2, 0.35, 1.5), CFrame = at(0, 15.4, -PLOT_D / 2), Color = accent, Material = M.Neon, CanCollide = false})

	-- Potted bushes beside the entrance
	for _, sx in ipairs({-1, 1}) do
		local px = sx * (PLOT_W / 2 - 3)
		makeCylinder(model, 2.2, 3, at(px, 2.1, -PLOT_D / 2 + 3), {Name = "Pot", Color = rgb(170, 95, 60), Material = M.Concrete})
		makePart(model, {Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6), CFrame = at(px, 4.4, -PLOT_D / 2 + 3), Color = rgb(60, 145, 70), Material = M.Grass, CanCollide = false})
	end
	local barrier = makePart(model, {
		Name = "LaserBarrier", Size = Vector3.new(PLOT_W, 12, 0.4), CFrame = at(0, 7, -PLOT_D / 2),
		Color = rgb(255, 40, 40), Material = M.Neon, Transparency = 1, CanCollide = false,
	})

	local signPart = makePart(model, {Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = at(0, 13, PLOT_D / 2 - 0.5), Transparency = 1, CanCollide = false})
	local signLabel = makeBillboard(signPart, 520, 96, 3, "Empty Base", 250)

	-- 10 pedestals at the back
	local slots = {}
	for _, zz in ipairs({8, 16}) do
		for _, x in ipairs({-14, -7, 0, 7, 14}) do
			local ped = makePart(model, {
				Name = "Pedestal", Size = Vector3.new(5, 2, 5), CFrame = at(x, 2, zz),
				Color = rgb(45, 45, 55), Material = M.Marble,
			})
			-- Glass display case around each slot
			makePart(model, {Name = "CaseBase", Size = Vector3.new(5.4, 0.3, 5.4), CFrame = at(x, 3.15, zz), Color = accent, Material = M.Neon})
			makePart(model, {Name = "CaseGlass", Size = Vector3.new(4.8, 6, 4.8), CFrame = at(x, 6.3, zz), Color = rgb(210, 235, 255), Material = M.Glass, Transparency = 0.8, Reflectance = 0.1})
			for _, cx in ipairs({-2.45, 2.45}) do
				for _, cz in ipairs({-2.45, 2.45}) do
					makePart(model, {Name = "CasePost", Size = Vector3.new(0.3, 6, 0.3), CFrame = at(x + cx, 6.3, zz + cz), Color = rgb(255, 205, 60), Material = M.Metal})
				end
			end
			local lid = makePart(model, {Name = "CaseLid", Size = Vector3.new(5.3, 0.3, 5.3), CFrame = at(x, 9.45, zz), Color = rgb(255, 205, 60), Material = M.Metal})
			local caseLight = Instance.new("PointLight")
			caseLight.Range = 6
			caseLight.Brightness = 1
			caseLight.Shadows = false
			caseLight.Parent = lid
			table.insert(slots, {Pedestal = ped, Item = nil, Data = nil, Reserved = false})
		end
	end

	local pad = makePart(model, {
		Name = "CollectPad", Size = Vector3.new(8, 0.4, 8), CFrame = at(-11, 1.2, -12),
		Color = rgb(40, 220, 90), Material = M.Neon,
	})
	local padLabel = makeBillboard(pad, 200, 60, 3, "$0")

	-- Treadmill prompts live on an invisible part that never gets rebuilt
	local treadAnchor = makePart(model, {Name = "TreadmillAnchor", Size = Vector3.new(1, 1, 1), CFrame = at(0, 3, -10), Transparency = 1, CanCollide = false})
	local runPrompt = makePrompt(treadAnchor, "Run on Treadmill", "Treadmill", 0, 9)
	local upgradePrompt = makePrompt(treadAnchor, "Upgrade Treadmill", "Treadmill", 0.3, 9)
	upgradePrompt.KeyboardKeyCode = Enum.KeyCode.F
	upgradePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	upgradePrompt.UIOffset = Vector2.new(0, 70)
	local treadLabelPart = makePart(model, {Name = "TreadmillLabel", Size = Vector3.new(1, 1, 1), CFrame = at(0, 6, -17.5), Transparency = 1, CanCollide = false})
	local treadLabel = makeBillboard(treadLabelPart, 240, 60, 1, "TREADMILL", 80)

	local lockButton = makePart(model, {
		Name = "LockButton", Size = Vector3.new(4, 1, 4), CFrame = at(11, 1.5, -12),
		Color = rgb(220, 50, 50), Material = M.Neon,
	})
	local lockLabel = makeBillboard(lockButton, 200, 50, 3, "LOCK BASE")
	local lockPrompt = makePrompt(lockButton, "Lock Base", "Lasers", 0.5, 8)

	local plot = {
		Index = index, CF = cf, Model = model, Owner = nil, Slots = slots,
		Barrier = barrier, SignLabel = signLabel, PadLabel = padLabel, LockLabel = lockLabel,
		TreadLabel = treadLabel, RunPrompt = runPrompt, UpgradePrompt = upgradePrompt,
		Runner = nil, SlatOffset = 0, Slats = {},
		Bank = 0, LockedUntil = 0, Spawn = at(0, 4, 1),
	}
	rebuildTreadmill(plot)

	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player == plot.Owner and plot.Bank > 0 then
			player.leaderstats.Cash.Value += plot.Bank
			notify(player, "Collected $" .. fmt(plot.Bank) .. "!", GREEN)
			plot.Bank = 0
			plot.PadLabel.Text = "$0"
		end
	end)

	runPrompt.Triggered:Connect(function(player)
		if plot.Owner ~= player then
			notify(player, "That's not your treadmill!", RED)
			return
		end
		if plot.Runner then
			stopTreadmill(plot)
		elseif carrying[player] then
			notify(player, "Drop off your game first!", RED)
		else
			startTreadmill(plot, player)
		end
	end)

	upgradePrompt.Triggered:Connect(function(player)
		if plot.Owner ~= player then
			notify(player, "That's not your treadmill!", RED)
			return
		end
		local level = player:GetAttribute("TreadLevel") or 0
		if level >= TREADMILL_MAX_LEVEL then
			notify(player, "Your treadmill is already maxed!")
			return
		end
		local cost = treadmillCost(level)
		local cash = player.leaderstats.Cash
		if cash.Value < cost then
			notify(player, "You need $" .. fmt(cost) .. " to upgrade the treadmill", RED)
			return
		end
		cash.Value -= cost
		player:SetAttribute("TreadLevel", level + 1)
		rebuildTreadmill(plot)
		notify(player, string.format("Treadmill upgraded! Now +%.1f speed/s", treadmillRate(level + 1) * SPEED_DISPLAY), BLUE)
	end)

	lockPrompt.Triggered:Connect(function(player)
		if plot.Owner ~= player then
			notify(player, "That's not your base!", RED)
			return
		end
		if os.clock() < plot.LockedUntil then
			notify(player, "Your base is already locked!")
			return
		end
		plot.LockedUntil = os.clock() + LOCK_TIME
		plot.Barrier.Transparency = 0.45
		notify(player, "Base locked for " .. LOCK_TIME .. " seconds!", GREEN)
	end)

	table.insert(plots, plot)
end

for i = 1, 8 do
	local angle = math.rad(-BASE_ARC / 2 + (i - 1) * BASE_ARC / 7)
	buildPlot(i, ENTRANCE + Vector3.new(math.sin(angle), 0, -math.cos(angle)) * BASE_RING_RADIUS)
end

treadmillStopEvent.OnServerEvent:Connect(function(player)
	local plot = playerPlots[player]
	if plot and plot.Runner == player then
		stopTreadmill(plot)
	end
end)

------------------------------------------------------------------
-- SHOPKEEPERS
------------------------------------------------------------------
local function addHatPart(model, head, size, offset, color, props)
	props = props or {}
	local p = Instance.new("Part")
	p.Name = "Hat"
	p.Shape = props.Shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = props.Material or M.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = head.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = head
	w.Part1 = p
	w.Parent = p
	p.Parent = model
end

local CYL = {Shape = Enum.PartType.Cylinder}
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

local function addHat(model, head, kind, color)
	local s = head.Size.Y
	local top = s / 2
	if kind == "cap" then
		addHatPart(model, head, Vector3.new(s * 1.05, s * 0.35, s * 1.05), CFrame.new(0, top, 0), color)
		addHatPart(model, head, Vector3.new(s * 1.0, s * 0.1, s * 0.6), CFrame.new(0, top - s * 0.12, -s * 0.7), color)
	elseif kind == "headband" then
		addHatPart(model, head, Vector3.new(s * 1.08, s * 0.18, s * 1.08), CFrame.new(0, s * 0.2, 0), color, {Material = M.Neon})
	elseif kind == "tophat" then
		addHatPart(model, head, Vector3.new(s * 1.2, s * 0.85, s * 0.85), CFrame.new(0, top + s * 0.6, 0) * UPRIGHT, color, CYL)
		addHatPart(model, head, Vector3.new(s * 0.08, s * 1.35, s * 1.35), CFrame.new(0, top + s * 0.04, 0) * UPRIGHT, color, CYL)
	elseif kind == "pirate" then
		addHatPart(model, head, Vector3.new(s * 1.9, s * 0.5, s * 1.0), CFrame.new(0, top + s * 0.2, 0), color)
		addHatPart(model, head, Vector3.new(s * 0.35, s * 0.3, s * 0.05), CFrame.new(0, top + s * 0.2, -s * 0.52), rgb(240, 240, 240))
		addHatPart(model, head, Vector3.new(s * 0.35, s * 0.25, s * 0.05), CFrame.new(-s * 0.2, s * 0.08, -s * 0.5), rgb(15, 15, 15))
	elseif kind == "hood" then
		addHatPart(model, head, Vector3.new(s * 1.15, s * 1.15, s * 1.0), CFrame.new(0, s * 0.06, s * 0.12), color, {Material = M.Fabric})
		addHatPart(model, head, Vector3.new(s * 0.15, s * 0.1, s * 0.05), CFrame.new(-s * 0.2, s * 0.1, -s * 0.5), rgb(255, 60, 60), {Material = M.Neon})
		addHatPart(model, head, Vector3.new(s * 0.15, s * 0.1, s * 0.05), CFrame.new(s * 0.2, s * 0.1, -s * 0.5), rgb(255, 60, 60), {Material = M.Neon})
	elseif kind == "visor" then
		addHatPart(model, head, Vector3.new(s * 1.1, s * 0.25, s * 0.2), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
		addHatPart(model, head, Vector3.new(s * 1.08, s * 0.2, s * 1.08), CFrame.new(0, top - s * 0.05, 0), rgb(30, 30, 40))
	elseif kind == "antenna" then
		addHatPart(model, head, Vector3.new(s * 0.8, s * 0.08, s * 0.08), CFrame.new(0, top + s * 0.4, 0) * UPRIGHT, rgb(80, 80, 90), CYL)
		addHatPart(model, head, Vector3.one * s * 0.3, CFrame.new(0, top + s * 0.85, 0), color, {Shape = Enum.PartType.Ball, Material = M.Neon})
		addHatPart(model, head, Vector3.new(s * 0.9, s * 0.15, s * 0.1), CFrame.new(0, s * 0.1, -s * 0.5), color, {Material = M.Neon})
	elseif kind == "horns" then
		addHatPart(model, head, Vector3.new(s * 1.1, s * 0.5, s * 1.1), CFrame.new(0, top - s * 0.05, 0), rgb(110, 110, 120), {Material = M.Metal})
		for _, sx in ipairs({-1, 1}) do
			addHatPart(model, head, Vector3.new(s * 0.2, s * 0.7, s * 0.2), CFrame.new(sx * s * 0.45, top + s * 0.3, 0) * CFrame.Angles(0, 0, -sx * 0.4), color)
		end
	elseif kind == "crown" then
		addHatPart(model, head, Vector3.new(s * 0.3, s * 1.0, s * 1.0), CFrame.new(0, top + s * 0.1, 0) * UPRIGHT, color, {Shape = Enum.PartType.Cylinder, Material = M.Foil})
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			addHatPart(model, head, Vector3.new(s * 0.16, s * 0.3, s * 0.16), CFrame.new(math.cos(a) * s * 0.42, top + s * 0.38, math.sin(a) * s * 0.42), color, {Material = M.Foil})
		end
	elseif kind == "helmet" then
		addHatPart(model, head, Vector3.one * s * 1.75, CFrame.new(0, 0, 0), color, {Shape = Enum.PartType.Ball, Material = M.Glass, Transparency = 0.5})
	elseif kind == "halo" then
		addHatPart(model, head, Vector3.new(s * 0.08, s * 1.2, s * 1.2), CFrame.new(0, top + s * 0.45, 0) * UPRIGHT, color, {Shape = Enum.PartType.Cylinder, Material = M.Neon})
	end
end

-- Simple block shopkeeper, used only if the normal character can't be made
local function makeBlockGuard(shirt, pants)
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Color = shirt
	root.Parent = model
	model.PrimaryPart = root

	local function attach(name, size, offset, partColor)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = partColor
		p.CanCollide = false
		p.Massless = true
		p.CFrame = root.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		p.Parent = model
	end
	attach("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 1.6, 0), SKIN)
	attach("LeftLeg", Vector3.new(0.9, 2, 1), CFrame.new(-0.5, -2, 0), pants)
	attach("RightLeg", Vector3.new(0.9, 2, 1), CFrame.new(0.5, -2, 0), pants)

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2
	hum.Parent = model
	return model
end

local function buildGuard(level)
	local L = LEVELS[level]
	local look = L.Zone.Guard
	local shirt = look.Shirt:Lerp(Color3.new(0, 0, 0), (L.Sub - 1) * 0.08)
	local model
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = SKIN
		desc.LeftArmColor = shirt
		desc.RightArmColor = shirt
		desc.TorsoColor = shirt
		desc.LeftLegColor = look.Pants
		desc.RightLegColor = look.Pants
		local scale = 1 + (level - 1) * 0.012   -- deeper shopkeepers are bigger
		desc.HeightScale = scale
		desc.WidthScale = scale
		desc.DepthScale = scale
		desc.HeadScale = scale
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = makeBlockGuard(shirt, look.Pants)
	end

	model.Name = string.format("%02d_%s", level, look.Title)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = GUARD_IDLE_SPEED
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	-- Middle right of the store, behind the counter
	local post = Vector3.new(-22, 3, roomStart(level) + 29)
	model.Parent = guardsFolder
	model:PivotTo(CFrame.new(post))

	local head = model:FindFirstChild("Head")
	if head then
		addHat(model, head, look.Hat, look.HatColor)
	end
	setGroup(model, "Guards")
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local speed = guardSpeed(level)
	local idleText = string.format('<font color="#%s">%s</font>\nSpeed %d', L.Accent:ToHex(), string.upper(look.Title), math.floor(speed * SPEED_DISPLAY))
	local label = makeBillboard(head or root, 280, 70, 3, idleText, 90)

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://913376220"
	local track
	pcall(function()
		track = animator:LoadAnimation(anim)
	end)
	hum.Running:Connect(function(runSpeed)
		if not track then return end
		if runSpeed > 0.5 then
			if not track.IsPlaying then
				track:Play()
			end
			track:AdjustSpeed(math.clamp(runSpeed / 16, 0.6, 3 * SPEED_SCALE))
		elseif track.IsPlaying then
			track:Stop()
		end
	end)

	guards[level] = {
		Level = level, Model = model, Humanoid = hum, Root = root, Post = post,
		Speed = speed, Label = label, IdleText = idleText, Title = look.Title,
		CatchDistance = 4.5 + (level - 1) * 0.04,
		Target = nil, ChaseAt = 0, ChaseStart = 0, PauseUntil = 0,
		CheckPos = root.Position, CheckTime = os.clock(),
	}
end

-- Shopkeepers load in the background so the world is ready right away
for level = 1, NUM_LEVELS do
	task.spawn(buildGuard, level)
end

-- Where a shopkeeper should walk to reach `goal`, going through the store doorways
local function navigate(from, goal)
	local a, b = roomAt(from), roomAt(goal)
	if a == b then
		return goal
	end
	if not a then
		return Vector3.new(0, from.Y, HALL_START_Z + 8)
	end
	local doorZ, dir
	if b and b > a then
		doorZ, dir = roomStart(a + 1), 1
	else
		doorZ, dir = roomStart(a), -1
	end
	if math.abs(from.X) > DOOR_W / 2 - 4 and math.abs(from.Z - doorZ) < 14 then
		return Vector3.new(0, from.Y, doorZ - dir * 8)
	end
	return Vector3.new(0, from.Y, doorZ + dir * 8)
end

local function setGuardTarget(g, player, now)
	if g.Target == player then return end
	if g.Target and g.Target.Parent then
		chaseEvent:FireClient(g.Target, false)
	end
	g.Target = player
	if player then
		g.ChaseAt = now + GUARD_REACTION
		g.ChaseStart = now
		chaseEvent:FireClient(player, true)
		notify(player, "The " .. g.Title .. " is chasing you! RUN!", RED)
	end
end

local function catchPlayer(g, player)
	local tr = getRoot(player)
	setGuardTarget(g, nil, os.clock())
	returnCarried(player)
	notify(player, "The " .. g.Title .. " caught you! The game went back.", RED)
	if tr then
		local away = tr.Position - g.Root.Position
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude < 0.1 then
			away = Vector3.new(0, 0, -1)
		end
		knockEvent:FireClient(player, away.Unit * 45 + Vector3.new(0, 30, 0))
	end
	g.PauseUntil = os.clock() + 1.5
end

local function updateGuard(g, now)
	local root, hum = g.Root, g.Humanoid
	if not root.Parent then return end
	if now < g.PauseUntil then
		hum:MoveTo(root.Position)
		return
	end

	-- Only chase a player carrying a game from THIS store
	local t = g.Target
	if t then
		local c = carrying[t]
		local tr = t.Parent and getRoot(t)
		local valid = c and c.Spot and c.Spot.Level == g.Level and not c.Escaped and tr
		-- Shopkeepers stop at the vault entrance
		if valid and not roomAt(tr.Position) then
			c.Escaped = true
			notify(t, "You escaped the Vault! The " .. g.Title .. " stopped chasing.", GREEN)
			valid = false
		end
		if valid and now - g.ChaseStart > GUARD_GIVE_UP then
			c.Escaped = true
			notify(t, "The " .. g.Title .. " gave up!", GREEN)
			valid = false
		end
		if not valid then
			setGuardTarget(g, nil, now)
			t = nil
		end
	end
	if not t then
		for p, c in pairs(carrying) do
			if c.Spot and c.Spot.Level == g.Level and not c.Escaped and getRoot(p) then
				setGuardTarget(g, p, now)
				t = p
				break
			end
		end
	end

	if t then
		g.Label.Text = '<font color="#ff4040">!!! ' .. string.upper(g.Title) .. ' !!!</font>'
		if now < g.ChaseAt then
			hum:MoveTo(root.Position)
			return
		end
		hum.WalkSpeed = g.Speed
		local tp = getRoot(t).Position
		hum:MoveTo(navigate(root.Position, tp))
		if (tp - root.Position).Magnitude <= g.CatchDistance then
			catchPlayer(g, t)
		end
	else
		g.Label.Text = g.IdleText
		hum.WalkSpeed = math.max(GUARD_IDLE_SPEED, g.Speed * 0.6)
		local flat = Vector3.new(g.Post.X - root.Position.X, 0, g.Post.Z - root.Position.Z)
		if flat.Magnitude > 2 then
			hum:MoveTo(navigate(root.Position, g.Post))
			-- If stuck for a while on the way back, pop back behind the counter
			if now - g.CheckTime > 3 then
				if (root.Position - g.CheckPos).Magnitude < 1 then
					g.Model:PivotTo(CFrame.new(g.Post))
				end
				g.CheckPos, g.CheckTime = root.Position, now
			end
		end
	end
end

------------------------------------------------------------------
-- PLAYERS
------------------------------------------------------------------
------------------------------------------------------------------
-- SAVING (cash, speed, treadmill level, uncollected cash, games in your base)
------------------------------------------------------------------
local AUTOSAVE_TIME = 60
local saveStore
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("StealAGameSave_v1")
	end)
	if ok then
		saveStore = result
	else
		warn("[Saving] DataStores unavailable: " .. tostring(result))
	end
end

-- Only players whose save loaded OK get saved, so a failed load never wipes real progress
local loadedData = {}

local function collectSave(player)
	local plot = playerPlots[player]
	local games = {}
	if plot then
		for i, slot in ipairs(plot.Slots) do
			if slot.Data and GAME_IDS[slot.Data] then
				games[tostring(i)] = GAME_IDS[slot.Data]
			end
		end
	end
	return {
		Cash = player.leaderstats.Cash.Value,
		SpeedBonus = player:GetAttribute("SpeedBonus") or 0,
		TreadLevel = player:GetAttribute("TreadLevel") or 0,
		Bank = plot and plot.Bank or 0,
		Games = games,
	}
end

local function writeSave(player, data)
	if not saveStore then return false end
	local key = "Player_" .. player.UserId
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			saveStore:SetAsync(key, data, {player.UserId})
		end)
		if ok then
			return true
		end
		warn("[Saving] Save failed for " .. player.Name .. " (try " .. attempt .. "): " .. tostring(err))
		task.wait(1)
	end
	return false
end

local function savePlayer(player)
	if not loadedData[player] or not player:FindFirstChild("leaderstats") then return end
	writeSave(player, collectSave(player))
end

local function loadSave(player)
	if not saveStore then return nil, false end
	local key = "Player_" .. player.UserId
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return saveStore:GetAsync(key)
		end)
		if ok then
			return result, true
		end
		warn("[Saving] Load failed for " .. player.Name .. " (try " .. attempt .. "): " .. tostring(result))
		task.wait(1)
	end
	return nil, false
end

local function restoreBase(plot, data)
	if not plot or type(data) ~= "table" then return end
	plot.Bank = tonumber(data.Bank) or 0
	plot.PadLabel.Text = "$" .. fmt(plot.Bank)
	if type(data.Games) ~= "table" then return end
	for index, id in pairs(data.Games) do
		local gameData = gameFromId(id)
		if gameData then
			local slot = plot.Slots[tonumber(index)]
			if not slot or slot.Item or slot.Reserved then
				slot = getFreeSlot(plot)
			end
			if slot then
				placeInSlot(plot, slot, createItem(gameData), gameData, false)
			end
		end
	end
end

local function claimPlot(player)
	for _, plot in ipairs(plots) do
		if not plot.Owner then
			plot.Owner = player
			plot.Bank = 0
			plot.LockedUntil = 0
			plot.SignLabel.Text = player.DisplayName .. "'s Base"
			playerPlots[player] = plot
			rebuildTreadmill(plot)
			return plot
		end
	end
	return nil
end

local function releasePlot(player)
	local plot = playerPlots[player]
	if not plot then return end
	stopTreadmill(plot)
	playerPlots[player] = nil
	for _, slot in ipairs(plot.Slots) do
		if slot.Item then slot.Item:Destroy() end
		slot.Item, slot.Data, slot.Reserved = nil, nil, false
	end
	plot.Owner = nil
	plot.Bank = 0
	plot.LockedUntil = 0
	plot.SignLabel.Text = "Empty Base"
	plot.PadLabel.Text = "$0"
	rebuildTreadmill(plot)
end

local function giveSlap(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or backpack:FindFirstChild("Slap") then return end

	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.CanBeDropped = false
	tool.ToolTip = "Slap thieves to make them drop your game!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 3, 0.6)
	handle.Color = rgb(255, 200, 150)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local lastSlap = 0
	tool.Activated:Connect(function()
		if os.clock() - lastSlap < SLAP_COOLDOWN then return end
		lastSlap = os.clock()
		local root = getRoot(player)
		if not root then return end

		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local otherRoot = getRoot(other)
				if otherRoot and not otherRoot.Anchored then
					local offset = otherRoot.Position - root.Position
					if offset.Magnitude <= SLAP_RANGE and root.CFrame.LookVector:Dot(offset.Unit) > 0.2 then
						knockEvent:FireClient(other, root.CFrame.LookVector * 70 + Vector3.new(0, 35, 0))
						if carrying[other] then
							notify(other, player.DisplayName .. " slapped you! You dropped it.", RED)
							notify(player, "You made " .. other.DisplayName .. " drop it!", GREEN)
							returnCarried(other)
						end
					end
				end
			end
		end
	end)

	tool.Parent = backpack
end

local function onCharacter(player, char)
	char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	updateSpeed(player)
	hum.Died:Connect(function()
		returnCarried(player)
		local plot = playerPlots[player]
		if plot and plot.Runner == player then
			stopTreadmill(plot)
		end
	end)

	task.wait(0.2)
	giveSlap(player)
	local plot = playerPlots[player]
	if plot and char.Parent then
		char:PivotTo(plot.Spawn)
	end
end

local function onPlayerAdded(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = START_CASH
	cash.Parent = stats
	stats.Parent = player
	player:SetAttribute("SpeedBonus", 0)
	player:SetAttribute("TreadLevel", 0)

	-- Load saved progress
	local saved, loadedOK = loadSave(player)
	if not player.Parent then return end
	if loadedOK then
		loadedData[player] = true
		if type(saved) == "table" then
			cash.Value = tonumber(saved.Cash) or START_CASH
			player:SetAttribute("SpeedBonus", math.clamp(tonumber(saved.SpeedBonus) or 0, 0, MAX_SPEED_BONUS))
			player:SetAttribute("TreadLevel", math.clamp(math.floor(tonumber(saved.TreadLevel) or 0), 0, TREADMILL_MAX_LEVEL))
		end
	else
		task.delay(3, notify, player, "Couldn't load your save. Progress won't be saved this time.", RED)
	end
	updateSpeed(player)

	local plot = claimPlot(player)
	if loadedOK then
		restoreBase(plot, saved)
	end
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	if not plot then
		task.delay(3, notify, player, "No free base on this server, sorry!", RED)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	returnCarried(player)
	-- Grab the save before the base is cleared, then write it
	local data = loadedData[player] and player:FindFirstChild("leaderstats") and collectSave(player)
	loadedData[player] = nil
	releasePlot(player)
	if data then
		writeSave(player, data)
	end
end)

-- Autosave everyone every minute
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_TIME)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(savePlayer, player)
		end
	end
end)

-- Save everyone when the server shuts down (also when you stop a Studio playtest)
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait()
	end
end)

------------------------------------------------------------------
-- START + LOOPS
------------------------------------------------------------------
for _, spot in ipairs(spots) do
	spawnSpot(spot)
end

-- Shopkeepers think 10 times a second
task.spawn(function()
	while true do
		task.wait(0.1)
		local now = os.clock()
		for _, g in pairs(guards) do
			updateGuard(g, now)
		end
	end
end)

-- Every second: income, restocks, timers
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()

		for _, plot in ipairs(plots) do
			if plot.Owner then
				local income = 0
				for _, slot in ipairs(plot.Slots) do
					if slot.Data then
						income += slot.Data.Income
					end
				end
				plot.Bank += income
				plot.PadLabel.Text = "$" .. fmt(plot.Bank) .. "\n+$" .. fmt(income) .. "/s"
			end
			local left = plot.LockedUntil - now
			if left > 0 then
				plot.LockLabel.Text = "LOCKED " .. math.ceil(left) .. "s"
				plot.Barrier.Transparency = 0.45
			else
				plot.LockLabel.Text = "LOCK BASE"
				plot.Barrier.Transparency = 1
			end
		end

		-- Restock stores whose countdown finished
		for level, t in pairs(restockAt) do
			if now >= t then
				restockAt[level] = nil
				for _, spot in ipairs(spots) do
					if spot.Level == level then
						spawnSpot(spot)
					end
				end
			end
		end
		for level, label in pairs(restockLabels) do
			local t = restockAt[level]
			if t then
				label.Text = '<font color="#ffd23c">RESTOCK IN ' .. fmtTime(t - now) .. '</font>'
			else
				label.Text = '<font color="#5aff78">IN STOCK</font>'
			end
		end
	end
end)

-- Every frame: moving treadmill belts
-- Every 0.1s: treadmill speed gains, deliveries, locked bases
local checkTimer = 0
RunService.Heartbeat:Connect(function(dt)
	for _, plot in ipairs(plots) do
		local runner = plot.Runner
		if runner and #plot.Slats > 0 then
			local beltSpeed = 6 + (runner:GetAttribute("SpeedBonus") or 0) * 0.25 / SPEED_SCALE
			plot.SlatOffset = (plot.SlatOffset + beltSpeed * dt) % (SLAT_COUNT * SLAT_GAP)
			for i, slat in ipairs(plot.Slats) do
				local z = -16 + ((i - 1) * SLAT_GAP + plot.SlatOffset) % (SLAT_COUNT * SLAT_GAP)
				slat.CFrame = plot.CF * CFrame.new(0, BELT_TOP - 0.15, z)
			end
		end
	end

	checkTimer += dt
	if checkTimer < 0.1 then return end
	local step = checkTimer
	checkTimer = 0

	for _, plot in ipairs(plots) do
		local runner = plot.Runner
		if runner then
			if not runner.Parent or not getRoot(runner) then
				stopTreadmill(plot)
			else
				local bonus = runner:GetAttribute("SpeedBonus") or 0
				if bonus < MAX_SPEED_BONUS then
					local rate = treadmillRate(runner:GetAttribute("TreadLevel") or 0)
					bonus = math.min(MAX_SPEED_BONUS, bonus + rate * step)
					runner:SetAttribute("SpeedBonus", bonus)
					updateSpeed(runner)
					if bonus >= MAX_SPEED_BONUS then
						notify(runner, "You've reached max speed!", BLUE)
					end
				end
			end
		end
	end

	for player in pairs(carrying) do
		local root = getRoot(player)
		local myPlot = playerPlots[player]
		if root and myPlot and insidePlot(myPlot, root.Position) then
			deliverCarried(player)
		end
	end

	local now = os.clock()
	for _, plot in ipairs(plots) do
		if plot.Owner and now < plot.LockedUntil then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= plot.Owner then
					local root = getRoot(player)
					if root and insidePlot(plot, root.Position) then
						player.Character:PivotTo(plot.CF * CFrame.new(0, 4, -PLOT_D / 2 - 8))
						notify(player, "That base is locked!", RED)
					end
				end
			end
		end
	end
end)
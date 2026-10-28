--[[
	STEAL A GAME - CONFIG
	Every balance number lives here. Change these to tune the game.
]]

local C = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material

------------------------------------------------------------------
-- GENERAL
------------------------------------------------------------------
C.START_CASH = 0
C.ROTATE_TIME = 420             -- every 7 minutes every vault level gets 3 brand-new random games
C.LOCK_TIME = 90                -- seconds a base stays locked (the timer pauses while you're being chased)
C.SELL_MULTIPLIER = 30          -- an installed game sells for (income per second x this)
C.UNINSTALLED_SELL = 10         -- a game that isn't installed yet sells for (its level's base income x this)
C.MAX_HELD = 1                  -- games a player can hold at once
C.MAX_HELD_PASS = 2             -- ...with the 2x Steal game pass
C.SAVE_STORE = "StealAGameSave_v3" -- v3: full reset Oct 28 (v2 still holds everyone's old saves)
C.AUTOSAVE_TIME = 60

------------------------------------------------------------------
-- GAME INCOME (random for every copy, hidden until installed)
------------------------------------------------------------------
-- Level N's typical income = INCOME_BASE x INCOME_GROWTH^(N-1) per second.
-- Each copy rolls a random multiplier around that (lower and upper bounds below).
C.INCOME_BASE = 1.8
C.INCOME_GROWTH = 1.33
C.INCOME_SPREAD = 0.4
C.INCOME_MIN_MULT = 0.5
C.INCOME_MAX_MULT = 2.5

-- Spawn chances (%) for the 3 games in a level (varies per level)
C.CHANCE_SETS = {
	{55, 33, 12}, {50, 35, 15}, {58, 30, 12}, {45, 40, 15},
	{52, 33, 15}, {48, 38, 14}, {60, 30, 10}, {47, 41, 12},
}
C.EXTRA_CHANCE = 5              -- spawn chance of a level's bonus 4th game (only the last level has one)

------------------------------------------------------------------
-- RARITY (rolled for every copy of a game)
------------------------------------------------------------------
-- Common to Legendary can show up at ANY level, but the rarer ones are much,
-- much harder to get at low levels. The top rarities only appear deep in the vault.
C.RARITIES = {
	{Name = "Common",    Color = rgb(190, 190, 190), MinLevel = 1},
	{Name = "Uncommon",  Color = rgb(85, 200, 90),   MinLevel = 1},
	{Name = "Rare",      Color = rgb(60, 130, 255),  MinLevel = 1},
	{Name = "Epic",      Color = rgb(170, 70, 255),  MinLevel = 1},
	{Name = "Legendary", Color = rgb(255, 170, 0),   MinLevel = 1},
	{Name = "Mythic",    Color = rgb(255, 50, 90),   MinLevel = 11},
	{Name = "Godly",     Color = rgb(255, 230, 80),  MinLevel = 21},
	{Name = "Secret",    Color = rgb(20, 255, 220),  MinLevel = 31},
	{Name = "Celestial", Color = rgb(255, 150, 255), MinLevel = 41},
	{Name = "Infinity",  Color = rgb(255, 255, 255), MinLevel = 46},
}
C.RARITY_INCOME_MULT = 1.6      -- each rarity step earns this much more
C.RARITY_INSTALL_MULT = 1.25    -- ...and takes this much longer to install
-- How likely each step up in rarity is, from level 1 (tiny) to level 50 (much better)
C.RARITY_RATIO_LOW = 0.12
C.RARITY_RATIO_HIGH = 0.6

function C.rarityWeights(level)
	local t = (level - 1) / math.max(1, C.NUM_LEVELS - 1)
	local ratio = C.RARITY_RATIO_LOW + (C.RARITY_RATIO_HIGH - C.RARITY_RATIO_LOW) * t
	local weights = {}
	for r, info in ipairs(C.RARITIES) do
		weights[r] = level >= info.MinLevel and ratio ^ (r - 1) or 0
	end
	return weights
end

------------------------------------------------------------------
-- INDEX REWARDS (claim each game the first time you find it)
------------------------------------------------------------------
function C.indexReward(level, r)
	local L = C.LEVELS[level]
	return {
		Cash = math.floor(L.IncomeBase * 50 * C.RARITY_INCOME_MULT ^ (r - 1)),
		Speed = math.floor(C.guardPoints(level) * 0.04 * (1 + (r - 1) * 0.25)),
	}
end

------------------------------------------------------------------
-- DAILY LOGIN (7-day streak; missing a day starts it over)
------------------------------------------------------------------
C.DAILY = {
	{Kind = "cash", Amount = 500, Text = "$500"},
	{Kind = "game", Rarity = 4, Levels = {4, 10}, Text = "Epic Game"},
	{Kind = "cash", Amount = 2500, Text = "$2,500"},
	{Kind = "speed", Amount = 1500, Text = "+1,500 Speed"},
	{Kind = "cash", Amount = 15000, Text = "$15,000"},
	{Kind = "speed", Amount = 5000, Text = "+5,000 Speed"},
	{Kind = "game", Rarity = 5, Levels = {8, 15}, Cash = 50000, Text = "Legendary Game + $50K"},
}

------------------------------------------------------------------
-- ROBUX SHOP
-- Create these in the Creator Hub (your experience > Monetization), then paste
-- each ID below. Items with Id = 0 show in the shop as "Coming soon".
------------------------------------------------------------------
C.GAMEPASSES = {
	{Key = "DoubleMoney", Id = 0, Name = "2x Money", Desc = "Every game in your base earns double!", Price = 199},
	{Key = "DoubleSpeed", Id = 0, Name = "2x Speed", Desc = "Run twice as fast as everyone else!", Price = 149},
	{Key = "DoubleSteal", Id = 0, Name = "2x Steal", Desc = "Carry 2 games at once, forever!", Price = 250},
}
-- Spin the Lucky Wheel again without waiting a day
C.SPIN_PRODUCT = {Key = "Spin", Id = 0, Name = "Extra Spin", Price = 25}
-- Collect every playtime reward right now
C.PLAYTIME_SKIP_PRODUCT = {Key = "SkipPlaytime", Id = 0, Name = "Skip All", Price = 150}
-- Install a game instantly: 9 Robux for every 30 minutes it still needs.
-- Make one developer product per price below (Steps x 9 Robux) and paste its ID.
C.SKIP_SECONDS_PER_STEP = 1800
-- These accounts (and anyone testing in Studio) install instantly for free
C.ADMIN_USER_IDS = {560259012} -- FaZeghostcamox
C.SKIP_ROBUX_PER_STEP = 9
C.SKIP_PRODUCTS = {
	{Steps = 1, Id = 0}, {Steps = 2, Id = 0}, {Steps = 3, Id = 0}, {Steps = 4, Id = 0},
	{Steps = 6, Id = 0}, {Steps = 8, Id = 0}, {Steps = 12, Id = 0}, {Steps = 16, Id = 0},
	{Steps = 24, Id = 0}, {Steps = 48, Id = 0},
}

C.PRODUCTS = {
	-- Section decides where it shows in the shop: "featured", "boost", "speed" or "cash"
	{Key = "Starter", Section = "featured", Id = 0, Name = "Starter Pack", Desc = "$25K, +5,000 speed and an Epic game (once per player)", Price = 99, OneTime = true},
	{Key = "Treadmill", Section = "boost", Id = 0, Name = "Treadmill Upgrade", Desc = "+1 treadmill level instantly", Price = 49},
	-- SPEED PACKS: a fixed amount of speed (same units as the speed counter)
	{Key = "SpeedS", Section = "speed", Id = 0, Name = "Speed Snack", Amount = 10000, Price = 9},
	{Key = "SpeedM", Section = "speed", Id = 0, Name = "Speed Boost", Amount = 100000, Price = 29},
	{Key = "SpeedL", Section = "speed", Id = 0, Name = "Speed Surge", Amount = 1000000, Price = 79},
	{Key = "SpeedXL", Section = "speed", Id = 0, Name = "Speed Storm", Amount = 10000000, Price = 199},
	{Key = "SpeedXXL", Section = "speed", Id = 0, Name = "Speed Supernova", Amount = 100000000, Price = 449},
	-- CASH PACKS: minutes of your base's income (the shop shows the exact amount you'd get), never less than Min.
	-- Sized against what upgrades cost: the next case/floor costs ~5-70 minutes of income at every stage, so even the
	-- Handful buys an upgrade or two. Costs grow x1.55 per case, so a pack buys only a handful of steps however big
	-- your base is. Bigger packs give more cash per Robux (3.3 -> 10 minutes per Robux).
	{Key = "Cash5", Section = "cash", Id = 0, Name = "Cash Handful", Minutes = 30, Min = 5000, Price = 9},
	{Key = "CashS", Section = "cash", Id = 0, Name = "Cash Stack", Minutes = 120, Min = 25000, Price = 25},
	{Key = "CashL", Section = "cash", Id = 0, Name = "Cash Vault", Minutes = 480, Min = 150000, Price = 79},
	{Key = "CashXL", Section = "cash", Id = 0, Name = "Cash Mountain", Minutes = 2160, Min = 1000000, Price = 249},
	{Key = "CashXXL", Section = "cash", Id = 0, Name = "Cash Planet", Minutes = 7200, Min = 5000000, Price = 699},
}

------------------------------------------------------------------
-- LUCKY SPIN (free once a day, at the booth beside the vault entrance)
------------------------------------------------------------------
C.SPIN_COOLDOWN = 86400
-- Wheel order (clockwise from the top): warm and cool colours alternate so neighbouring slices never look alike.
-- Weight is the chance (out of the total, 100); the order doesn't change the odds.
C.SPIN_REWARDS = {
	{Text = "Cash",           Kind = "cash",  Minutes = 5,  Min = 1000,  Weight = 28, Color = rgb(30, 165, 70),   Icon = "\u{1F4B5}"},
	{Text = "Money x2",       Kind = "boost", Stat = "Money", Mult = 2, Minutes = 10, Weight = 9,  Color = rgb(230, 40, 120), Icon = "\u{1F911}"},
	{Text = "+5% Speed",      Kind = "speed", Percent = 5,  Min = 300,   Weight = 24, Color = rgb(30, 100, 235),  Icon = "\u{1F45F}"},
	{Text = "Big Cash",       Kind = "cash",  Minutes = 25, Min = 6000,  Weight = 12, Color = rgb(250, 185, 20),  Icon = "\u{1F4B0}"},
	{Text = "Epic Game",      Kind = "game",  Rarity = 4,                Weight = 5,  Color = rgb(125, 40, 215),  Icon = "\u{1F3AE}"},
	{Text = "Speed x1.5",     Kind = "boost", Stat = "Speed", Mult = 1.5, Minutes = 10, Weight = 14, Color = rgb(0, 165, 170), Icon = "\u{26A1}"},
	{Text = "Legendary Game", Kind = "game",  Rarity = 5,                Weight = 1,  Color = rgb(235, 80, 10),  Icon = "\u{1F451}"},
	{Text = "+15% Speed",     Kind = "speed", Percent = 15, Min = 1000,  Weight = 7,  Color = rgb(70, 45, 190),  Icon = "\u{1F680}"},
}

------------------------------------------------------------------
-- PLAYTIME REWARDS (every 10 minutes you play, each session)
------------------------------------------------------------------
C.PLAYTIME = {
	{Minute = 10, Text = "+3% Speed",          Kind = "speed", Percent = 3,  Min = 200,  Icon = "\u{1F45F}", Color = rgb(80, 170, 255)},
	{Minute = 20, Text = "Cash",               Kind = "cash",  Minutes = 8,  Min = 2000, Icon = "\u{1F4B0}", Color = rgb(255, 210, 60)},
	{Minute = 30, Text = "1.35x Speed 10 min", Kind = "boost", Stat = "Speed", Mult = 1.35, Minutes = 10, Icon = "\u{26A1}", Color = rgb(0, 200, 255)},
	{Minute = 40, Text = "Big Cash",           Kind = "cash",  Minutes = 20, Min = 6000, Icon = "\u{1F4B5}", Color = rgb(90, 220, 90)},
	{Minute = 50, Text = "2x Money 10 min",    Kind = "boost", Stat = "Money", Mult = 2, Minutes = 10, Icon = "\u{1F911}", Color = rgb(255, 150, 40)},
	{Minute = 60, Text = "Mystery Game",       Kind = "game",  Rarity = 4, Mystery = true, Icon = "\u{2753}", Color = rgb(190, 90, 255)},
}

------------------------------------------------------------------
-- AREA COMPLETION (find all 15 games in an area for a big reward)
------------------------------------------------------------------
function C.areaReward(zi)
	local last = zi * 5
	local L = C.LEVELS[last]
	return {
		Cash = math.floor(L.IncomeBase * 3000),
		Speed = math.floor(C.guardPoints(last) * 0.25),
	}
end

------------------------------------------------------------------
-- INSTALLING (downloads)
------------------------------------------------------------------
-- Level N's typical install time = INSTALL_BASE x INSTALL_GROWTH^(N-1) seconds.
-- Rarer games (lower spawn chance) and higher-earning copies take longer.
C.INSTALL_BASE = 20
C.INSTALL_GROWTH = 1.09
C.ONLINE_INSTALL_RATE = 1       -- install seconds gained per real second while you're in the game
C.OFFLINE_INSTALL_RATE = 0.5    -- ...and while you're offline
C.OFFLINE_CASH_RATE = 0.5       -- share of your games' income earned while you're offline (time away is capped at 30 days)

------------------------------------------------------------------
-- SPEED  (the number on screen is "speed points")
------------------------------------------------------------------
-- Players start at START_SPEED points. Your real walk speed grows with the
-- points, but more slowly, so millions of points are still playable:
-- real speed = REAL_BASE_SPEED x (points / START_SPEED) ^ REAL_SPEED_POWER
C.START_SPEED = 1000
C.REAL_BASE_SPEED = 32
C.REAL_SPEED_POWER = 0.165      -- tuned so level 50's recommended speed (~7.7B) lands just under MAX_REAL_SPEED
C.MAX_REAL_SPEED = 450
C.CARRY_MULTIPLIER = 1          -- speed while carrying a stolen game (1 = no slowdown, so your speed number vs the shopkeeper's decides who wins)

function C.realSpeed(points)
	points = math.max(points or C.START_SPEED, 1)
	return math.min(C.MAX_REAL_SPEED, C.REAL_BASE_SPEED * (points / C.START_SPEED) ^ C.REAL_SPEED_POWER)
end

-- Treadmill: level 0 gives +1 speed point per second, each upgrade multiplies that.
-- Rate grows slower than cost (and slower than the shopkeepers), so every vault level takes real
-- training: roughly L5 ~10 min, L10 ~25 min, L20 ~1.5 h, L30 ~4 h, L50 ~40 h of active play.
C.TREAD_BASE_RATE = 1
C.TREAD_RATE_GROWTH = 1.4
C.TREAD_MAX_LEVEL = 40
-- Upgrade prices follow the economy. The price of level T is a stretch of the income a player training at that
-- level typically has (stealing around vault level T + 3, owning 12 -> 96 cases as they go, with better rarities).
-- The stretch grows from 20 seconds of income for the first upgrade to 6 hours for the last, so each step costs
-- about 1.7x the one before. The early levels keep their old doubling prices (200, 400, 800...) where those are
-- cheaper, so new players level up fast. (The old doubling all the way up asked ~580 hours of income for the last.)
C.TREAD_COST_BASE = 200
C.TREAD_COST_GROWTH = 2.0
C.TREAD_COST_FIRST_MINUTES = 1 / 3
C.TREAD_COST_LAST_MINUTES = 360

function C.treadRate(level)
	return C.TREAD_BASE_RATE * C.TREAD_RATE_GROWTH ^ level
end
function C.treadCost(level)
	local early = C.TREAD_COST_BASE * C.TREAD_COST_GROWTH ^ level
	local V = math.clamp(level + 3, 1, C.NUM_LEVELS)
	local income = C.LEVELS[V].IncomeBase * (12 * 8 ^ ((V - 1) / 49)) * (1.5 + 2.5 * (V - 1) / 49)
	local minutes = C.TREAD_COST_FIRST_MINUTES * (C.TREAD_COST_LAST_MINUTES / C.TREAD_COST_FIRST_MINUTES) ^ (level / (C.TREAD_MAX_LEVEL - 1))
	local cost = math.min(early, income * 60 * minutes)
	-- two significant figures, so prices read cleanly
	local e = 10 ^ (math.floor(math.log10(cost)) - 1)
	return math.floor(cost / e + 0.5) * e
end
-- The exact amount the treadmill gives every second (rounded so the label and the pop-ups always match)
function C.treadGain(level)
	local r = C.treadRate(level)
	return r < 10 and math.floor(r * 10 + 0.5) / 10 or math.floor(r)
end

-- Shopkeepers (speed points, same scale as players)
C.GUARD_START_POINTS = 700
C.GUARD_POINT_GROWTH = 1.32     -- each level deeper is this much faster
C.GUARD_ZONE_JUMP = 1.25        -- ...and the first level of every new area is this much faster again (level 50 is about 7 billion)
C.GUARD_IDLE_REAL_SPEED = 20
C.GUARD_RETURN_SPEED = 90       -- how fast a shopkeeper walks back to their post after a chase
C.GUARD_REACTION = 0.6
C.GUARD_GIVE_UP = 120
C.GUARD_LATE_LEVEL = 25         -- past this level shopkeepers get an extra speed-up
C.GUARD_LATE_GROWTH = 1.02
-- Shopkeepers are giants: this many times a player's size (level 1 up to level 50). Max fits under the level signs.
C.GUARD_SCALE_MIN = 4.2
C.GUARD_SCALE_MAX = 5.6
function C.guardScale(level)
	return C.GUARD_SCALE_MIN + (C.GUARD_SCALE_MAX - C.GUARD_SCALE_MIN) * (level - 1) / math.max(1, C.NUM_LEVELS - 1)
end
function C.guardPoints(level)
	local late = math.max(0, level - C.GUARD_LATE_LEVEL)
	local zone = math.floor((level - 1) / 5)
	return C.GUARD_START_POINTS * C.GUARD_POINT_GROWTH ^ (level - 1) * C.GUARD_ZONE_JUMP ^ zone * C.GUARD_LATE_GROWTH ^ late
end

-- The speed shown on each level's hanging sign: a little faster than its shopkeeper,
-- rounded up to 2 significant digits so it reads cleanly (e.g. 1,234 -> 1,300)
C.RECOMMENDED_MARGIN = 1.1
function C.recommendedSpeed(level)
	local v = C.guardPoints(level) * C.RECOMMENDED_MARGIN
	local step = 10 ^ math.max(0, math.floor(math.log10(v)) - 1)
	return math.ceil(v / step) * step
end

C.SLAP_COOLDOWN = 0.8
C.SLAP_HIT_DELAY = 0.12        -- the slap lands as the arm swings across (matches the animation)
C.STEAL_LEVEL_GRACE = 2         -- stolen games earn fully up to (deepest vault level you've stolen from + this)
C.ESCAPE_CONFIRM_TIME = 0.6     -- seconds you must stay out of the vault before the chase ends
C.FALL_RETURN_Y = -40           -- falling below this height returns any stolen games
-- Friends in the same server boost your cash: the first friend +10%, every friend after that +2.5% more.
-- It follows who is here right now, so a friend leaving and rejoining can never stack it twice.
C.FRIEND_FIRST_BOOST = 0.1
C.FRIEND_EXTRA_BOOST = 0.025
function C.friendBoost(n)
	return n > 0 and C.FRIEND_FIRST_BOOST + C.FRIEND_EXTRA_BOOST * (n - 1) or 0
end
C.SLAP_RANGE = 8

------------------------------------------------------------------
-- BASES
------------------------------------------------------------------
C.PLOT_W = 64
C.PLOT_D = 84
C.FLOOR_H = 20
C.CASES_PER_FLOOR = 8           -- on the Starter base (4 on each side); bigger bases have more
C.START_CASES = 4
C.MAX_FLOORS = 4                -- the biggest base type has 4 floors
C.CASE_COST_BASE = 150          -- price of case #5, each case after costs CASE_COST_GROWTH times more
C.CASE_COST_GROWTH = 1.55
C.CASE_COST_AFTER_8 = 25        -- cases 9+ cost this many times more
C.FLOOR_COST = 250000           -- price of the 2nd floor
C.FLOOR_COSTS = {[2] = 250000, [3] = 1e12, [4] = 3e13} -- price of each extra floor

-- BASE TIERS: after both floors are full, the next upgrade revamps the whole
-- base: longer, more rows of cases on every floor, and a nicer look.
C.BASE_TIERS = {
	{Name = "Starter Base", Rows = 4, Floors = 2, Cost = 0,
		Wall = rgb(255, 246, 228), WallMat = M.SmoothPlastic, Wainscot = rgb(150, 105, 70), WainscotMat = M.WoodPlanks,
		Trim = rgb(255, 255, 255), TrimMat = M.SmoothPlastic, Floor = rgb(215, 190, 150), FloorMat = M.WoodPlanks, Tile = rgb(195, 165, 125),
		Pillar = rgb(255, 255, 255), PillarMat = M.Marble, Pedestal = rgb(70, 70, 85)},
	{Name = "Deluxe Base", Rows = 6, Floors = 2, Cost = 5e6,
		Wall = rgb(225, 238, 255), WallMat = M.SmoothPlastic, Wainscot = rgb(60, 95, 180), WainscotMat = M.SmoothPlastic,
		Trim = rgb(255, 205, 60), TrimMat = M.Metal, Floor = rgb(235, 235, 245), FloorMat = M.Marble, Tile = rgb(195, 205, 230),
		Pillar = rgb(245, 245, 250), PillarMat = M.Marble, Pedestal = rgb(50, 70, 140), Windows = true, Banners = true},
	{Name = "Mega Base", Rows = 8, Floors = 2, Cost = 2e8,
		Wall = rgb(240, 225, 255), WallMat = M.SmoothPlastic, Wainscot = rgb(120, 60, 200), WainscotMat = M.SmoothPlastic,
		Trim = rgb(255, 255, 255), TrimMat = M.Marble, Floor = rgb(245, 240, 255), FloorMat = M.Marble, Tile = rgb(215, 195, 250),
		Pillar = rgb(170, 110, 255), PillarMat = M.SmoothPlastic, Pedestal = rgb(90, 50, 160), Windows = true, Banners = true, Glow = true},
	{Name = "Ultimate Base", Rows = 10, Floors = 2, Cost = 5e9,
		Wall = rgb(255, 255, 255), WallMat = M.Marble, Wainscot = rgb(255, 200, 50), WainscotMat = M.Metal,
		Trim = rgb(255, 215, 80), TrimMat = M.Metal, Floor = rgb(255, 250, 235), FloorMat = M.Marble, Tile = rgb(255, 225, 140),
		Pillar = rgb(255, 215, 80), PillarMat = M.Metal, Pedestal = rgb(40, 40, 50), Windows = true, Banners = true, Glow = true, Statues = true},
	-- Late game: even longer bases with extra floors (stairs keep alternating sides)
	{Name = "Legendary Base", Rows = 12, Floors = 3, Cost = 2e11,
		Wall = rgb(255, 245, 225), WallMat = M.Marble, Wainscot = rgb(255, 150, 40), WainscotMat = M.Metal,
		Trim = rgb(255, 215, 80), TrimMat = M.Metal, Floor = rgb(255, 248, 235), FloorMat = M.Marble, Tile = rgb(255, 200, 120),
		Pillar = rgb(255, 170, 40), PillarMat = M.Metal, Pedestal = rgb(60, 40, 30), Windows = true, Banners = true, Glow = true, Statues = true},
	{Name = "Galaxy Base", Rows = 12, Floors = 4, Cost = 8e12,
		Wall = rgb(235, 230, 255), WallMat = M.SmoothPlastic, Wainscot = rgb(80, 50, 200), WainscotMat = M.SmoothPlastic,
		Trim = rgb(170, 230, 255), TrimMat = M.SmoothPlastic, Floor = rgb(240, 238, 255), FloorMat = M.Marble, Tile = rgb(190, 170, 255),
		Pillar = rgb(130, 90, 255), PillarMat = M.SmoothPlastic, Pedestal = rgb(30, 25, 60), Windows = true, Banners = true, Glow = true, Statues = true},
}

local function caseCost(n)
	local cost = C.CASE_COST_BASE * C.CASE_COST_GROWTH ^ (n - 5)
	if n > 8 then
		cost *= C.CASE_COST_AFTER_8
	end
	return math.floor(cost)
end

-- Turn a number of bought upgrades into floors, cases and base tier.
-- Upgrades go: cases until the floor is full, the 2nd floor, cases, then a base revamp...
function C.baseLayout(upgrades)
	local floors, cases, tier = 1, C.START_CASES, 1
	for _ = 1, upgrades or 0 do
		local per = C.BASE_TIERS[tier].Rows * 2
		if cases < floors * per then
			cases += 1
		elseif floors < (C.BASE_TIERS[tier].Floors or 2) then
			floors += 1
		elseif tier < #C.BASE_TIERS then
			tier += 1
		else
			break
		end
	end
	return floors, cases, tier
end

-- What the next upgrade is: "case", "floor" or "tier" and its price (nil when maxed)
function C.nextUpgrade(floors, cases, tier)
	tier = tier or 1
	local per = C.BASE_TIERS[tier].Rows * 2
	if cases < floors * per then
		return "case", caseCost(cases + 1)
	elseif floors < (C.BASE_TIERS[tier].Floors or 2) then
		return "floor", C.FLOOR_COSTS[floors + 1] or C.FLOOR_COST
	elseif tier < #C.BASE_TIERS then
		return "tier", C.BASE_TIERS[tier + 1].Cost
	end
	return nil, nil
end

do
	local n = 0
	while true do
		local f, c, t = C.baseLayout(n)
		if not C.nextUpgrade(f, c, t) then break end
		n += 1
	end
	C.MAX_UPGRADES = n
end

------------------------------------------------------------------
-- WORLD LAYOUT
------------------------------------------------------------------
C.ROOM_W = 120                  -- width of the vault hallway
C.SEG_LEN = 200                 -- length of each vault level
C.WALL_H = 90
C.ENTRANCE_W = 56
C.ENTRANCE_H = 38
C.HALL_START_Z = 20             -- the vault entrance
C.BASE_RING_RADIUS = 297        -- distance from the entrance to the bases
C.BASE_YARD = 36                -- open front yard between the walkway loop and each base (the treadmill stands here)
C.LOOP_R = C.BASE_RING_RADIUS - C.PLOT_D / 2 - 7 - C.BASE_YARD -- radius of the walkway loop
C.TREAD_OFFSET_X = 20           -- treadmill sits in the front yard, this far to the right of the base's centre
C.TREAD_OFFSET_Z = 12           -- and this far out from the base's open front, leaving room to walk by
C.BASE_ARC = 150
C.FENCE_R = 450                 -- leaves room for the biggest bases
C.ISLAND_R = 640
C.NUM_PLOTS = 8
C.INVITE_SCALE = 1.5            -- size of the character on the Invite Friend pad

------------------------------------------------------------------
-- TRAILS (cosmetic, sold at the Trail Shop by the vault entrance)
------------------------------------------------------------------
C.TRAILS = {
	-- Speed = multiplies your speed while equipped.  Fx = extra effects on higher trails.
	{Name = "Dust",      Rarity = "Common",    Speed = 1.1,  Price = 500,       Colors = {rgb(220, 220, 220), rgb(130, 130, 130)}, Width = 1.0, Life = 0.4},
	{Name = "Bubblegum", Rarity = "Common",    Speed = 1.2,  Price = 5000,      Colors = {rgb(255, 150, 210), rgb(255, 210, 235)}, Width = 1.2, Life = 0.5},
	{Name = "Ocean",     Rarity = "Uncommon",  Speed = 1.3,  Price = 25000,     Colors = {rgb(30, 120, 255), rgb(90, 230, 255)}, Width = 1.4, Life = 0.6, Light = 0.3},
	{Name = "Sunset",    Rarity = "Uncommon",  Speed = 1.4,  Price = 100000,    Colors = {rgb(255, 170, 60), rgb(255, 80, 120), rgb(150, 60, 220)}, Width = 1.6, Life = 0.7, Light = 0.5},
	{Name = "Toxic",     Rarity = "Rare",      Speed = 1.5,  Price = 500000,    Colors = {rgb(140, 255, 60), rgb(30, 160, 40)}, Width = 1.8, Life = 0.8, Light = 0.8, Particles = rgb(160, 255, 80)},
	{Name = "Lava",      Rarity = "Rare",      Speed = 1.65, Price = 2500000,   Colors = {rgb(255, 240, 120), rgb(255, 120, 20), rgb(180, 20, 10)}, Width = 2.0, Life = 0.9, Light = 1, Particles = rgb(255, 140, 30), Fx = "fire"},
	{Name = "Galaxy",    Rarity = "Epic",      Speed = 1.8,  Price = 15000000,  Colors = {rgb(255, 120, 230), rgb(120, 60, 255), rgb(20, 20, 90)}, Width = 2.4, Life = 1.0, Light = 1, Particles = rgb(255, 255, 255), Fx = "stars"},
	{Name = "Rainbow",   Rarity = "Epic",      Speed = 2.0,  Price = 100000000, Colors = {rgb(255, 60, 60), rgb(255, 200, 40), rgb(60, 230, 90), rgb(50, 150, 255), rgb(190, 80, 255)}, Width = 2.8, Life = 1.2, Light = 1, Particles = rgb(255, 255, 200), Fx = "stars"},
	{Name = "Aurora",    Rarity = "Legendary", Speed = 2.25, Price = 1e9,       Colors = {rgb(80, 255, 170), rgb(60, 200, 255), rgb(170, 90, 255)}, Width = 3.2, Life = 1.5, Light = 1, Particles = rgb(150, 255, 230), Fx = "glow"},
	{Name = "Lightning", Rarity = "Legendary", Speed = 2.5,  Price = 3e9,       Colors = {rgb(255, 250, 200), rgb(255, 200, 60), rgb(255, 140, 20)}, Width = 3.0, Life = 1.2, Light = 1, Particles = rgb(255, 230, 120), Fx = "lightning"},
	{Name = "Plasma",    Rarity = "Mythic",    Speed = 2.75, Price = 8e9,       Colors = {rgb(120, 255, 255), rgb(40, 140, 255), rgb(150, 60, 255)}, Width = 3.4, Life = 1.3, Light = 1, Particles = rgb(140, 240, 255), Fx = "lightning"},
	{Name = "Inferno",   Rarity = "Mythic",    Speed = 3.0,  Price = 2e10,      Colors = {rgb(255, 255, 150), rgb(255, 90, 20), rgb(120, 0, 0)}, Width = 3.6, Life = 1.4, Light = 1, Particles = rgb(255, 120, 30), Fx = "fire"},
	{Name = "Frost",     Rarity = "Godly",     Speed = 3.25, Price = 5e10,      Colors = {rgb(255, 255, 255), rgb(170, 230, 255), rgb(80, 160, 255)}, Width = 3.6, Life = 1.5, Light = 1, Particles = rgb(220, 245, 255), Fx = "snow"},
	{Name = "Void",      Rarity = "Godly",     Speed = 3.5,  Price = 1.25e11,   Colors = {rgb(170, 60, 255), rgb(60, 0, 120), rgb(10, 0, 20)}, Width = 3.8, Life = 1.6, Light = 0.6, Particles = rgb(200, 120, 255), Fx = "void"},
	{Name = "Celestial", Rarity = "Celestial", Speed = 3.75, Price = 3e11,      Colors = {rgb(255, 200, 255), rgb(255, 240, 180), rgb(180, 220, 255)}, Width = 4.0, Life = 1.7, Light = 1, Particles = rgb(255, 240, 255), Fx = "stars"},
	{Name = "Infinity",  Rarity = "Infinity",  Speed = 4.0,  Price = 1e12,      Colors = {rgb(255, 255, 255), rgb(255, 215, 80), rgb(255, 255, 255)}, Width = 4.2, Life = 1.8, Light = 1, Particles = rgb(255, 230, 120), Animated = true, Fx = "lightning"},
}

-- TRAILS FOR ROBUX: trail number -> its Developer Product ID (Creator Dashboard > your experience > Monetization >
-- Developer Products). 0 = not made yet: that trail has no Robux button. The button shows the product's real price
-- from Roblox, so set the price there. Buying one works exactly like buying it with cash.
C.TRAIL_PRODUCTS = {
	[1] = 0,  -- Dust
	[2] = 0,  -- Bubblegum
	[3] = 0,  -- Ocean
	[4] = 0,  -- Sunset
	[5] = 0,  -- Toxic
	[6] = 0,  -- Lava
	[7] = 0,  -- Galaxy
	[8] = 0,  -- Rainbow
	[9] = 0,  -- Aurora
	[10] = 0, -- Lightning
	[11] = 0, -- Plasma
	[12] = 0, -- Inferno
	[13] = 0, -- Frost
	[14] = 0, -- Void
	[15] = 0, -- Celestial
	[16] = 0, -- Infinity
}

------------------------------------------------------------------
-- AREAS: 10 themes x 5 levels = 50 vault levels
------------------------------------------------------------------
C.ZONES = {
	{
		Name = "Bargain Basement", Rarity = "Common", Color = rgb(190, 190, 190),
		Ground = M.Mud, Wall = rgb(255, 190, 110), WallMat = M.WoodPlanks, Accent = rgb(255, 210, 60), Props = {"crate", "barrel"},
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
		Ground = M.Brick, Wall = rgb(150, 120, 255), WallMat = M.SmoothPlastic, Accent = rgb(255, 60, 200), Props = {"screen", "lamp"},
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
		Ground = M.LeafyGrass, Wall = rgb(255, 225, 90), WallMat = M.SmoothPlastic, Accent = rgb(255, 90, 90), Props = {"toyblock", "cone"},
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
		Ground = M.Sand, Wall = rgb(90, 200, 255), WallMat = M.WoodPlanks, Accent = rgb(60, 170, 220), Props = {"barrel", "palm"},
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
		Ground = M.Slate, Wall = rgb(175, 135, 235), WallMat = M.SmoothPlastic, Accent = rgb(120, 255, 120), Props = {"tombstone", "lamp"},
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
		Ground = M.Concrete, Wall = rgb(80, 115, 200), WallMat = M.SmoothPlastic, Accent = rgb(150, 120, 255), Props = {"neonpillar", "screen"},
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
		Ground = M.WoodPlanks, Wall = rgb(255, 130, 130), WallMat = M.Wood, Accent = rgb(255, 120, 150), Props = {"lamp", "bamboo"},
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
		Ground = M.Pavement, Wall = rgb(185, 200, 220), WallMat = M.SmoothPlastic, Accent = rgb(255, 170, 0), Props = {"gear", "crate"},
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
		Ground = M.CrackedLava, Wall = rgb(255, 145, 80), WallMat = M.SmoothPlastic, Accent = rgb(255, 100, 20), Props = {"gold", "rock"},
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
		Ground = M.Basalt, Wall = rgb(115, 125, 255), WallMat = M.SmoothPlastic, Accent = rgb(170, 90, 255), Props = {"planet", "crystal"},
		Guard = {Title = "Space Ranger", Shirt = rgb(240, 240, 245), Pants = rgb(200, 200, 210), Hat = "helmet", HatColor = rgb(160, 220, 255)},
		Stores = {
			{"Galactic Game Station", {"No Man's Pie", "Starfeld", "Star Bores"}},
			{"Nebula Nook", {"Among Bus", "Outer Mild", "Herbal Space Program"}},
			{"Black Hole Bazaar", {"Bed Space", "Hallo Infinite", "Elite Dangerless"}},
			{"Starlight Archive", {"Super Marco Galaxy", "Ratchet & Crank", "Metro-Void Prime"}},
			-- the 4th game is the rarest in the whole vault (see EXTRA_CHANCE)
			{"The Forbidden Archive", {"Grand Theft Avocado VI", "Half-Lite 3", "Steal a Brainrut", "Devil May Nubs V"}},
		},
	},
}

------------------------------------------------------------------
-- BUILD THE LEVEL LIST
------------------------------------------------------------------
C.LEVELS = {}
for zi, zone in ipairs(C.ZONES) do
	for si, store in ipairs(zone.Stores) do
		local i = #C.LEVELS + 1
		local chances = C.CHANCE_SETS[(i - 1) % #C.CHANCE_SETS + 1]
		local games = {}
		for gi, name in ipairs(store[2]) do
			table.insert(games, {Name = name, Rarity = zone.Rarity, Color = zone.Color, Chance = chances[gi] or C.EXTRA_CHANCE, GI = gi})
		end
		table.insert(C.LEVELS, {
			Index = i, Zone = zone, ZoneIndex = zi, Sub = si, Store = store[1], Games = games,
			IncomeBase = C.INCOME_BASE * C.INCOME_GROWTH ^ (i - 1),
			InstallBase = C.INSTALL_BASE * C.INSTALL_GROWTH ^ (i - 1),
			Accent = zone.Accent:Lerp(Color3.new(1, 1, 1), (si - 1) * 0.1),
			Wall = zone.Wall:Lerp(Color3.new(1, 1, 1), (si - 1) * 0.06),
		})
	end
end
C.NUM_LEVELS = #C.LEVELS

-- Which level each game name comes from (for the Index)
C.GAME_LEVEL = {}
for _, L in ipairs(C.LEVELS) do
	for _, g in ipairs(L.Games) do
		C.GAME_LEVEL[g.Name] = L.Index
	end
end

return C

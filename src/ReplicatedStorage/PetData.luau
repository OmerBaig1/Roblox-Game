--[[
	PetData
	Every egg and every pet: 8 eggs, 60 premium pets (docs/pets/ROSTER.md). Shared by the server (hatching, boosts)
	and the client (shop, hatching, pets). Each equipped pet adds its Boost (%) to your install speed.
	Each pet's Id is its save key (Key = Id). R = rarity tier 1-7, Model = its model in ReplicatedStorage.PetAssets,
	Mode = its follow style in PetSystem.PetAnimator. An egg's Pets is a pool: several pets can share a tier, and an
	egg can have no pet of some tier (no Secrets in the first three). Eggs keep Color/Spot/Pattern for PetModels.egg().
]]

local D = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

D.EQUIP_MAX = 2 -- pet slots: PetsEquipped is one id per slot, 0 = empty
D.MAX_PETS = 250
D.HATCH_MANY = 10

D.RARITIES = {
	{Name = "Common",    Color = rgb(200, 200, 205), Mult = 1},
	{Name = "Uncommon",  Color = rgb(90, 210, 95),   Mult = 1.5},
	{Name = "Rare",      Color = rgb(60, 140, 255),  Mult = 2.2},
	{Name = "Epic",      Color = rgb(175, 80, 255),  Mult = 3.2},
	{Name = "Legendary", Color = rgb(255, 175, 20),  Mult = 5},
	{Name = "Mythic",    Color = rgb(255, 60, 100),  Mult = 8},
	{Name = "Secret",    Color = rgb(30, 255, 225),  Mult = 14},
}
local BASE_ODDS = {50, 27, 13, 6.5, 2.6, 0.75, 0.15}

-- prices are the old prices of eggs 1, 3, 5 ... 15, so the economy curve doesn't move.
-- Tagline is the line under its name in the shop.
D.EGGS = {
	{Name = "Ember Egg", Tagline = "Still warm from the heart of the volcano", Price = 500, Color = rgb(70, 40, 35), Spot = rgb(255, 110, 40), Pattern = "cracks", Mat = "CrackedLava"},
	{Name = "Tide Egg", Tagline = "Washed ashore, pearl and all", Price = 25000, Color = rgb(40, 120, 200), Spot = rgb(140, 230, 255), Pattern = "waves"},
	{Name = "Grove Egg", Tagline = "Grown, not laid, in the oldest wood", Price = 500000, Color = rgb(70, 150, 70), Spot = rgb(200, 240, 140), Pattern = "leaves"},
	{Name = "Frost Egg", Tagline = "Frozen solid for a thousand winters", Price = 15e6, Color = rgb(215, 240, 255), Spot = rgb(120, 200, 255), Pattern = "snow"},
	{Name = "Arcade Egg", Tagline = "Insert coin. Hatch to continue.", Price = 1e9, Color = rgb(120, 60, 200), Spot = rgb(255, 230, 80), Pattern = "sprinkles"},
	{Name = "Circuit Egg", Tagline = "Encrypted. Something inside is booting up.", Price = 8e9, Color = rgb(30, 50, 90), Spot = rgb(60, 230, 255), Pattern = "stripes"},
	{Name = "Phantom Egg", Tagline = "It was here before the lights went out", Price = 5e10, Color = rgb(60, 30, 90), Spot = rgb(170, 120, 255), Pattern = "zigzag"},
	{Name = "Celestial Egg", Tagline = "Fell from a star that isn't there any more", Price = 1e12, Color = rgb(20, 20, 60), Spot = rgb(255, 240, 200), Pattern = "galaxy"},
}

local POOLS = {
	[1] = {
		{No = 1, Id = "coalpup", N = "Coalpup", R = 1, Model = "Coalpup", Mode = "Bound"},
		{No = 2, Id = "flicker_moth", N = "Flicker Moth", R = 1, Model = "FlickerMoth", Mode = "Hover"},
		{No = 3, Id = "magma_toad", N = "Magma Toad", R = 2, Model = "MagmaToad", Mode = "Hop"},
		{No = 4, Id = "pyre_salamander", N = "Pyre Salamander", R = 3, Model = "PyreSalamander", Mode = "Slither"},
		{No = 5, Id = "cinder_lynx", N = "Cinder Lynx", R = 4, Model = "CinderLynx", Mode = "Bound"},
		{No = 6, Id = "obsidian_drake", N = "Obsidian Drake", R = 5, Model = "ObsidianDrake", Mode = "Hover"},
		{No = 7, Id = "solflare_qilin", N = "Solflare Qilin", R = 6, Model = "SolflareQilin", Mode = "Bound"},
	},
	[2] = {
		{No = 8, Id = "bubblefin", N = "Bubblefin", R = 1, Model = "Bubblefin", Mode = "Glide"},
		{No = 9, Id = "coral_crab", N = "Coral Crab", R = 1, Model = "CoralCrab", Mode = "Scuttle"},
		{No = 10, Id = "lantern_eel", N = "Lantern Eel", R = 2, Model = "LanternEel", Mode = "Slither"},
		{No = 11, Id = "surf_otter", N = "Surf Otter", R = 3, Model = "SurfOtter", Mode = "Glide"},
		{No = 12, Id = "reefguard_manta", N = "Reefguard Manta", R = 4, Model = "ReefguardManta", Mode = "Glide"},
		{No = 13, Id = "maelstrom_serpent", N = "Maelstrom Serpent", R = 5, Model = "MaelstromSerpent", Mode = "Slither"},
		{No = 14, Id = "coralcrown_leviathan", N = "Coralcrown Leviathan", R = 6, Model = "CoralcrownLeviathan", Mode = "Glide"},
	},
	[3] = {
		{No = 15, Id = "mosscap_bunny", N = "Mosscap Bunny", R = 1, Model = "MosscapBunny", Mode = "Hop"},
		{No = 16, Id = "bramblehog", N = "Bramblehog", R = 2, Model = "Bramblehog", Mode = "Roll"},
		{No = 17, Id = "petal_sprite", N = "Petal Sprite", R = 2, Model = "PetalSprite", Mode = "Hover"},
		{No = 18, Id = "glimmerwood_fawn", N = "Glimmerwood Fawn", R = 3, Model = "GlimmerwoodFawn", Mode = "Bound"},
		{No = 19, Id = "runebark_owl", N = "Runebark Owl", R = 4, Model = "RunebarkOwl", Mode = "Hover"},
		{No = 20, Id = "elderhorn_spirit", N = "Elderhorn Spirit", R = 5, Model = "ElderhornSpirit", Mode = "Bound"},
		{No = 21, Id = "worldtree_tortoise", N = "Worldtree Tortoise", R = 6, Model = "WorldtreeTortoise", Mode = "Waddle"},
	},
	[4] = {
		{No = 22, Id = "snowpuff_seal", N = "Snowpuff Seal", R = 1, Model = "SnowpuffSeal", Mode = "Waddle"},
		{No = 23, Id = "icicle_bat", N = "Icicle Bat", R = 2, Model = "IcicleBat", Mode = "Hover"},
		{No = 24, Id = "rimeback_ram", N = "Rimeback Ram", R = 3, Model = "RimebackRam", Mode = "Bound"},
		{No = 25, Id = "prism_wyrmling", N = "Prism Wyrmling", R = 4, Model = "PrismWyrmling", Mode = "Hover"},
		{No = 26, Id = "aurora_mammoth", N = "Aurora Mammoth", R = 5, Model = "AuroraMammoth", Mode = "Bound"},
		{No = 27, Id = "hailstorm_griffin", N = "Hailstorm Griffin", R = 6, Model = "HailstormGriffin", Mode = "Hover"},
		{No = 28, Id = "crystal_heart_golem", N = "Crystal Heart Golem", R = 7, Model = "CrystalHeartGolem", Mode = "Glide"},
	},
	[5] = {
		{No = 29, Id = "pixel_pup", N = "Pixel Pup", R = 1, Model = "PixelPup", Mode = "Bound"},
		{No = 30, Id = "coin_hopper", N = "Coin Hopper", R = 2, Model = "CoinHopper", Mode = "Roll"},
		{No = 31, Id = "joystick_critter", N = "Joystick Critter", R = 3, Model = "JoystickCritter", Mode = "Hop"},
		{No = 32, Id = "cartridge_crab", N = "Cartridge Crab", R = 3, Model = "CartridgeCrab", Mode = "Scuttle"},
		{No = 33, Id = "claw_machine_octo", N = "Claw Machine Octo", R = 4, Model = "ClawMachineOcto", Mode = "Glide"},
		{No = 34, Id = "high_score_dragon", N = "High Score Dragon", R = 5, Model = "HighScoreDragon", Mode = "Slither"},
		{No = 35, Id = "glitch_phantom", N = "Glitch Phantom", R = 6, Model = "GlitchPhantom", Mode = "Glide"},
		{No = 36, Id = "final_boss", N = "The Final Boss", R = 7, Model = "FinalBoss", Mode = "Bound"},
	},
	[6] = {
		{No = 37, Id = "bolt_bug", N = "Bolt Bug", R = 1, Model = "BoltBug", Mode = "Scuttle"},
		{No = 38, Id = "drone_pup", N = "Drone Pup", R = 2, Model = "DronePup", Mode = "Hover"},
		{No = 39, Id = "synth_slime", N = "Synth Slime", R = 2, Model = "SynthSlime", Mode = "Hop"},
		{No = 40, Id = "mech_raptor", N = "Mech Raptor", R = 3, Model = "MechRaptor", Mode = "Bound"},
		{No = 41, Id = "chrome_panther", N = "Chrome Panther", R = 4, Model = "ChromePanther", Mode = "Bound"},
		{No = 42, Id = "hyperdrive_hawk", N = "Hyperdrive Hawk", R = 5, Model = "HyperdriveHawk", Mode = "Hover"},
		{No = 43, Id = "mainframe_beetle", N = "Mainframe Beetle", R = 6, Model = "MainframeBeetle", Mode = "Scuttle"},
		{No = 44, Id = "quantum_core_wyrm", N = "Quantum Core Wyrm", R = 7, Model = "QuantumCoreWyrm", Mode = "Slither"},
	},
	[7] = {
		{No = 45, Id = "wisp_kit", N = "Wisp Kit", R = 1, Model = "WispKit", Mode = "Glide"},
		{No = 46, Id = "lantern_imp", N = "Lantern Imp", R = 2, Model = "LanternImp", Mode = "Hover"},
		{No = 47, Id = "bone_raven", N = "Bone Raven", R = 3, Model = "BoneRaven", Mode = "Hover"},
		{No = 48, Id = "haunted_armor_hound", N = "Haunted Armor Hound", R = 4, Model = "HauntedArmorHound", Mode = "Bound"},
		{No = 49, Id = "specter_jelly", N = "Specter Jelly", R = 4, Model = "SpecterJelly", Mode = "Glide"},
		{No = 50, Id = "eclipse_nightmare", N = "Eclipse Nightmare", R = 5, Model = "EclipseNightmare", Mode = "Bound"},
		{No = 51, Id = "soulbinder_chimera", N = "Soulbinder Chimera", R = 6, Model = "SoulbinderChimera", Mode = "Bound"},
		{No = 52, Id = "void_cat", N = "The Void Cat", R = 7, Model = "VoidCat", Mode = "Bound"},
	},
	[8] = {
		{No = 53, Id = "starling_chick", N = "Starling Chick", R = 1, Model = "StarlingChick", Mode = "Hover"},
		{No = 54, Id = "satellite_snail", N = "Satellite Snail", R = 2, Model = "SatelliteSnail", Mode = "Glide"},
		{No = 55, Id = "constellation_cub", N = "Constellation Cub", R = 3, Model = "ConstellationCub", Mode = "Bound"},
		{No = 56, Id = "celestial_koi", N = "Celestial Koi", R = 4, Model = "CelestialKoi", Mode = "Glide"},
		{No = 57, Id = "starforge_pegasus", N = "Starforge Pegasus", R = 5, Model = "StarforgePegasus", Mode = "Hover"},
		{No = 58, Id = "ringed_skywhale", N = "Ringed Skywhale", R = 5, Model = "RingedSkywhale", Mode = "Glide"},
		{No = 59, Id = "supernova_seraph", N = "Supernova Seraph", R = 6, Model = "SupernovaSeraph", Mode = "Hover"},
		{No = 60, Id = "starloom_weaver", N = "Starloom Weaver", R = 7, Model = "StarloomWeaver", Mode = "Scuttle"},
	},
}

-- every pet's egg, key and boost; every egg's odds by tier (tiers it has no pet of get 0, the rest renormalise)
D.PETS = {}
for e, egg in ipairs(D.EGGS) do
	egg.Index = e
	egg.Pets = POOLS[e]
	egg.Tiers = {} -- [tier] = the pets of that tier, in roster order
	for _, pet in ipairs(egg.Pets) do
		pet.Key = pet.Id
		pet.Egg = e
		-- install speed bonus (%): egg 8 matches the old egg 15, so boosts keep the same curve
		pet.Boost = math.floor(2 * 1.26 ^ ((e - 1) * 2) * D.RARITIES[pet.R].Mult + 0.5)
		egg.Tiers[pet.R] = egg.Tiers[pet.R] or {}
		table.insert(egg.Tiers[pet.R], pet)
		D.PETS[pet.Id] = pet
	end
	egg.Odds = {}
	local shift = 1 + 0.09 * (e - 1)
	local total = 0
	for r, base in ipairs(BASE_ODDS) do
		egg.Odds[r] = egg.Tiers[r] and base * shift ^ (r - 1) or 0
		total += egg.Odds[r]
	end
	for r = 1, #BASE_ODDS do
		egg.Odds[r] = egg.Odds[r] / total * 100
	end
	-- its rarest pet, for "up to +X%" on the shop card
	egg.Best = egg.Pets[#egg.Pets]
end

-- one hatch from an egg: a tier by the odds (u1 in [0, 1)), then one of that tier's pets uniformly (u2 in [0, 1))
function D.roll(egg, u1, u2)
	local x = u1 * 100
	local tier
	for r, chance in ipairs(egg.Odds) do
		if chance > 0 then
			tier = r
			x -= chance
			if x <= 0 then
				break
			end
		end
	end
	local pool = egg.Tiers[tier]
	return pool[math.min(#pool, math.floor(u2 * #pool) + 1)]
end

function D.oddsText(p)
	if p < 1 then
		return string.format("%.2f%%", p)
	end
	return string.format("%.1f%%", p)
end

return D

--[[
	PetData
	Every egg and every pet. Shared by the server (hatching, boosts) and the client (shop, hatching, pets).
	Pets make your games install faster: each equipped pet adds its Boost (%) to your install speed.
	Every egg can hatch every rarity; pricier eggs have better odds and far stronger pets.

	Pet look fields (read by PetModels): B = body (quad, bird, fish, octo, blob, ghost, bug),
	C = {main, belly, accent} colours, then optional: Ears, Tail, Snout, Eyes, and extras like Wings,
	Horn, Mane, Stripes, Spots, Shell, Hump, Neck, Heads, Tails9, Halo, Crown, Antenna, Fire, Glow, Mat.
]]

local D = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

D.EQUIP_MAX = 3          -- pets you can have out at once
D.MAX_PETS = 250         -- pets you can own
D.HATCH_MANY = 10        -- the "Buy 10" button

D.RARITIES = {
	{Name = "Common",    Color = rgb(200, 200, 205), Mult = 1},
	{Name = "Uncommon",  Color = rgb(90, 210, 95),   Mult = 1.5},
	{Name = "Rare",      Color = rgb(60, 140, 255),  Mult = 2.2},
	{Name = "Epic",      Color = rgb(175, 80, 255),  Mult = 3.2},
	{Name = "Legendary", Color = rgb(255, 175, 20),  Mult = 5},
	{Name = "Mythic",    Color = rgb(255, 60, 100),  Mult = 8},
	{Name = "Secret",    Color = rgb(30, 255, 225),  Mult = 14},
}
-- base odds (%) for the first egg; better eggs shift them toward the rarer pets
local BASE_ODDS = {50, 27, 13, 6.5, 2.6, 0.75, 0.15}

-- {Name, price, shell colour, spot colour, pattern, material, pets (Common .. Secret)}
local W, BK = rgb(255, 255, 255), rgb(30, 25, 30)
D.EGGS = {
	{Name = "Meadow Egg", Price = 500, Color = rgb(150, 230, 120), Spot = rgb(255, 250, 200), Pattern = "spots", Pets = {
		{N = "Kitty", B = "quad", C = {rgb(255, 180, 110), rgb(255, 240, 220), rgb(255, 140, 160)}, Ears = "cat", Tail = "cat", Stripes = rgb(225, 130, 70)},
		{N = "Puppy", B = "quad", C = {rgb(205, 150, 95), rgb(255, 235, 210), rgb(120, 80, 50)}, Ears = "dog", Tail = "short", Snout = "long"},
		{N = "Bunny", B = "quad", C = {rgb(250, 250, 255), rgb(255, 225, 235), rgb(255, 150, 190)}, Ears = "bunny", Tail = "puff"},
		{N = "Hamster", B = "quad", C = {rgb(240, 175, 90), rgb(255, 245, 225), rgb(255, 160, 170)}, Ears = "round", Tail = "none"},
		{N = "Chick", B = "bird", C = {rgb(255, 225, 70), rgb(255, 245, 160), rgb(255, 150, 40)}, Tail = "none"},
		{N = "Piglet", B = "quad", C = {rgb(255, 175, 195), rgb(255, 215, 225), rgb(240, 120, 150)}, Ears = "cat", Tail = "short", Snout = "pig"},
		{N = "Lucky Cat", B = "quad", C = {rgb(255, 255, 255), rgb(255, 245, 235), rgb(230, 40, 50)}, Ears = "cat", Tail = "cat", Crown = true, Spots = rgb(255, 170, 60)},
	}},
	{Name = "Farm Egg", Price = 5000, Color = rgb(240, 200, 120), Spot = rgb(170, 110, 60), Pattern = "spots", Pets = {
		{N = "Calf", B = "quad", C = {W, rgb(255, 230, 235), rgb(255, 160, 170)}, Ears = "round", Horns = "cow", Tail = "short", Snout = "cow", Spots = BK},
		{N = "Lamb", B = "quad", C = {rgb(250, 250, 245), rgb(70, 60, 60), rgb(255, 170, 180)}, Ears = "dog", Tail = "puff", Fluff = true},
		{N = "Duckling", B = "bird", C = {rgb(255, 240, 120), rgb(255, 250, 200), rgb(255, 140, 30)}, Beak = "duck"},
		{N = "Goat", B = "quad", C = {rgb(235, 225, 210), rgb(255, 250, 240), rgb(150, 140, 130)}, Ears = "dog", Horns = "goat", Tail = "short", Snout = "long"},
		{N = "Pony", B = "quad", C = {rgb(170, 110, 70), rgb(230, 190, 150), rgb(60, 40, 30)}, Ears = "cat", Tail = "horse", Snout = "long", Mane = rgb(60, 40, 30)},
		{N = "Rooster", B = "bird", C = {rgb(250, 245, 235), rgb(255, 255, 255), rgb(230, 40, 40)}, Comb = true, Tail = "feathers"},
		{N = "Golden Goose", B = "bird", C = {rgb(255, 210, 60), rgb(255, 240, 150), rgb(255, 150, 30)}, Beak = "duck", Mat = "Foil", Crown = true},
	}},
	{Name = "Forest Egg", Price = 25000, Color = rgb(70, 150, 70), Spot = rgb(150, 100, 60), Pattern = "leaves", Pets = {
		{N = "Fox", B = "quad", C = {rgb(240, 120, 40), W, rgb(40, 30, 30)}, Ears = "cat", Tail = "fluffy", Snout = "long"},
		{N = "Fawn", B = "quad", C = {rgb(190, 120, 70), rgb(250, 230, 200), rgb(60, 40, 30)}, Ears = "dog", Tail = "short", Snout = "long", Spots = W},
		{N = "Raccoon", B = "quad", C = {rgb(140, 140, 150), rgb(230, 230, 235), rgb(40, 40, 45)}, Ears = "round", Tail = "ringed", Mask = true},
		{N = "Squirrel", B = "quad", C = {rgb(200, 110, 50), rgb(250, 225, 190), rgb(120, 60, 30)}, Ears = "cat", Tail = "fluffy"},
		{N = "Owl", B = "bird", C = {rgb(150, 105, 70), rgb(240, 220, 180), rgb(255, 190, 40)}, Tufts = true, Eyes = "big"},
		{N = "Bear Cub", B = "quad", C = {rgb(120, 75, 45), rgb(210, 170, 120), rgb(60, 35, 20)}, Ears = "round", Tail = "short", Snout = "bear"},
		{N = "Forest Spirit", B = "ghost", C = {rgb(150, 255, 170), rgb(220, 255, 230), rgb(60, 200, 90)}, Glow = true, Antenna = "leaf"},
	}},
	{Name = "Pond Egg", Price = 100000, Color = rgb(80, 190, 230), Spot = rgb(200, 245, 255), Pattern = "waves", Pets = {
		{N = "Froggy", B = "quad", C = {rgb(110, 210, 80), rgb(220, 250, 180), rgb(255, 130, 150)}, Ears = "none", Tail = "none", Eyes = "top", Squat = true},
		{N = "Turtle", B = "quad", C = {rgb(130, 200, 110), rgb(230, 240, 180), rgb(90, 130, 60)}, Ears = "none", Tail = "short", Shell = rgb(110, 150, 70)},
		{N = "Goldfish", B = "fish", C = {rgb(255, 140, 40), rgb(255, 210, 140), rgb(255, 90, 30)}, Fins = "fancy"},
		{N = "Otter", B = "quad", C = {rgb(140, 95, 60), rgb(230, 200, 160), rgb(60, 40, 30)}, Ears = "round", Tail = "long", Snout = "bear"},
		{N = "Swan", B = "bird", C = {W, rgb(255, 255, 255), rgb(255, 130, 40)}, Neck = true, Beak = "duck"},
		{N = "Axolotl", B = "quad", C = {rgb(255, 180, 210), rgb(255, 225, 235), rgb(255, 90, 150)}, Ears = "none", Tail = "long", Gills = true},
		{N = "Koi Dragon", B = "quad", C = {W, rgb(255, 240, 230), rgb(255, 80, 40)}, Ears = "none", Horns = "dragon", Tail = "long", Snout = "long", Wings = "fin", Spots = rgb(255, 80, 40), Whiskers = true},
	}},
	{Name = "Jungle Egg", Price = 500000, Color = rgb(50, 170, 90), Spot = rgb(255, 210, 60), Pattern = "stripes", Pets = {
		{N = "Monkey", B = "quad", C = {rgb(140, 90, 55), rgb(240, 205, 165), rgb(90, 55, 30)}, Ears = "round", Tail = "curl", Face = true},
		{N = "Parrot", B = "bird", C = {rgb(230, 40, 40), rgb(255, 220, 60), rgb(40, 120, 255)}, Tail = "feathers", Beak = "hook"},
		{N = "Toucan", B = "bird", C = {rgb(35, 35, 40), rgb(255, 250, 230), rgb(255, 150, 30)}, Beak = "big"},
		{N = "Panda", B = "quad", C = {W, rgb(255, 255, 255), rgb(30, 30, 35)}, Ears = "round", Tail = "short", Patches = true, Snout = "bear"},
		{N = "Tiger", B = "quad", C = {rgb(255, 150, 40), W, rgb(30, 25, 25)}, Ears = "round", Tail = "cat", Stripes = rgb(30, 25, 25)},
		{N = "Gorilla", B = "quad", C = {rgb(60, 60, 70), rgb(120, 115, 125), rgb(30, 30, 35)}, Ears = "round", Tail = "none", Face = true, Big = true},
		{N = "Golden Tiger", B = "quad", C = {rgb(255, 210, 60), rgb(255, 250, 210), rgb(200, 110, 20)}, Ears = "round", Tail = "cat", Stripes = rgb(220, 120, 20), Mat = "Foil", Crown = true},
	}},
	{Name = "Savanna Egg", Price = 2500000, Color = rgb(240, 180, 80), Spot = rgb(150, 90, 40), Pattern = "spots", Pets = {
		{N = "Lion Cub", B = "quad", C = {rgb(240, 180, 90), rgb(255, 235, 200), rgb(170, 100, 40)}, Ears = "round", Tail = "tuft"},
		{N = "Zebra", B = "quad", C = {W, rgb(255, 255, 255), rgb(30, 30, 35)}, Ears = "cat", Tail = "horse", Snout = "long", Stripes = rgb(30, 30, 35), Mane = rgb(30, 30, 35)},
		{N = "Giraffe", B = "quad", C = {rgb(250, 200, 90), rgb(255, 240, 200), rgb(160, 100, 40)}, Ears = "cat", Horns = "giraffe", Tail = "tuft", Neck = true, Spots = rgb(170, 100, 40)},
		{N = "Elephant", B = "quad", C = {rgb(160, 165, 180), rgb(200, 205, 215), rgb(255, 170, 190)}, Ears = "elephant", Tail = "short", Snout = "trunk", Big = true},
		{N = "Hippo", B = "quad", C = {rgb(170, 140, 190), rgb(230, 190, 210), rgb(255, 150, 180)}, Ears = "round", Tail = "short", Snout = "hippo", Big = true},
		{N = "Rhino", B = "quad", C = {rgb(150, 150, 160), rgb(200, 200, 205), rgb(240, 235, 220)}, Ears = "cat", Tail = "short", Snout = "bear", Horn = "nose", Big = true},
		{N = "King Lion", B = "quad", C = {rgb(255, 200, 80), rgb(255, 240, 200), rgb(200, 90, 20)}, Ears = "round", Tail = "tuft", Mane = rgb(200, 90, 20), Crown = true},
	}},
	{Name = "Ocean Egg", Price = 15000000, Color = rgb(40, 120, 230), Spot = rgb(120, 230, 255), Pattern = "waves", Pets = {
		{N = "Clownfish", B = "fish", C = {rgb(255, 120, 30), W, rgb(30, 30, 30)}, Stripes = W},
		{N = "Crab", B = "bug", C = {rgb(240, 70, 50), rgb(255, 160, 120), rgb(255, 255, 255)}, Claws = true, Stalks = true},
		{N = "Dolphin", B = "fish", C = {rgb(110, 170, 230), rgb(220, 240, 255), rgb(70, 120, 200)}, Snout = "long", Fins = "dolphin"},
		{N = "Octopus", B = "octo", C = {rgb(230, 100, 180), rgb(255, 190, 225), rgb(170, 60, 140)}},
		{N = "Shark", B = "fish", C = {rgb(110, 130, 160), rgb(235, 240, 245), rgb(70, 85, 110)}, Fins = "shark", Teeth = true},
		{N = "Whale", B = "fish", C = {rgb(60, 90, 200), rgb(210, 225, 255), rgb(40, 60, 150)}, Fins = "whale", Big = true, Spout = true},
		{N = "Kraken", B = "octo", C = {rgb(120, 40, 150), rgb(200, 120, 230), rgb(60, 255, 200)}, Big = true, Glow = true, Crown = true},
	}},
	{Name = "Swamp Egg", Price = 100000000, Color = rgb(90, 120, 60), Spot = rgb(180, 220, 90), Pattern = "drips", Pets = {
		{N = "Toad", B = "quad", C = {rgb(140, 150, 70), rgb(220, 220, 150), rgb(110, 80, 50)}, Ears = "none", Tail = "none", Eyes = "top", Squat = true, Spots = rgb(100, 110, 50)},
		{N = "Firefly", B = "bug", C = {rgb(50, 50, 60), rgb(255, 255, 120), rgb(255, 230, 60)}, BugWings = true, Glow = true},
		{N = "Lizard", B = "quad", C = {rgb(120, 200, 80), rgb(220, 240, 160), rgb(60, 130, 40)}, Ears = "none", Tail = "long", Squat = true},
		{N = "Chameleon", B = "quad", C = {rgb(80, 210, 170), rgb(220, 255, 200), rgb(255, 120, 200)}, Ears = "none", Tail = "curl", Eyes = "big", Crest = true},
		{N = "Crocodile", B = "quad", C = {rgb(80, 140, 60), rgb(210, 220, 150), rgb(50, 90, 40)}, Ears = "none", Tail = "long", Snout = "croc", Squat = true, Spikes = rgb(50, 90, 40)},
		{N = "Bog Monster", B = "blob", C = {rgb(90, 110, 50), rgb(160, 190, 80), rgb(60, 70, 30)}, Antenna = "leaf", Drips = true},
		{N = "Swamp Hydra", B = "quad", C = {rgb(60, 130, 90), rgb(180, 220, 150), rgb(255, 220, 60)}, Ears = "none", Tail = "long", Heads = 3, Horns = "dragon", Spikes = rgb(255, 220, 60)},
	}},
	{Name = "Arctic Egg", Price = 1e9, Color = rgb(220, 240, 255), Spot = rgb(130, 200, 255), Pattern = "snow", Pets = {
		{N = "Penguin", B = "bird", C = {rgb(35, 40, 55), W, rgb(255, 170, 40)}, Belly = true, Tail = "none"},
		{N = "Seal Pup", B = "fish", C = {rgb(235, 240, 245), W, rgb(40, 40, 45)}, Whiskers = true, Fins = "flipper"},
		{N = "Arctic Fox", B = "quad", C = {W, rgb(255, 255, 255), rgb(130, 190, 255)}, Ears = "cat", Tail = "fluffy", Snout = "long"},
		{N = "Snowy Owl", B = "bird", C = {W, rgb(255, 255, 255), rgb(255, 200, 40)}, Tufts = true, Eyes = "big", Spots = rgb(60, 60, 70)},
		{N = "Polar Bear", B = "quad", C = {rgb(245, 248, 255), W, rgb(40, 40, 50)}, Ears = "round", Tail = "short", Snout = "bear", Big = true},
		{N = "Yeti", B = "quad", C = {rgb(230, 240, 255), rgb(150, 200, 255), rgb(90, 150, 230)}, Ears = "none", Tail = "none", Horns = "goat", Fluff = true, Face = true, Big = true},
		{N = "Ice Dragon", B = "quad", C = {rgb(150, 220, 255), rgb(230, 250, 255), rgb(60, 140, 255)}, Ears = "none", Horns = "dragon", Tail = "long", Snout = "long", Wings = "dragon", Spikes = W, Mat = "Glass"},
	}},
	{Name = "Desert Egg", Price = 3e9, Color = rgb(250, 210, 130), Spot = rgb(210, 140, 60), Pattern = "zigzag", Pets = {
		{N = "Camel", B = "quad", C = {rgb(215, 170, 110), rgb(245, 220, 180), rgb(120, 80, 40)}, Ears = "round", Tail = "short", Snout = "long", Hump = true, Neck = true},
		{N = "Meerkat", B = "quad", C = {rgb(210, 170, 120), rgb(245, 225, 190), rgb(60, 45, 35)}, Ears = "round", Tail = "long", Mask = true},
		{N = "Fennec Fox", B = "quad", C = {rgb(245, 200, 140), W, rgb(255, 160, 150)}, Ears = "fennec", Tail = "fluffy", Snout = "long"},
		{N = "Scorpion", B = "bug", C = {rgb(60, 40, 30), rgb(120, 80, 50), rgb(255, 80, 40)}, Claws = true, Stinger = true},
		{N = "Cobra", B = "quad", C = {rgb(200, 170, 60), rgb(255, 240, 170), rgb(90, 70, 30)}, Ears = "none", Tail = "long", Hood = true, Squat = true},
		{N = "Sphinx Cat", B = "quad", C = {rgb(240, 200, 150), rgb(255, 230, 200), rgb(40, 110, 230)}, Ears = "cat", Tail = "cat", Crown = true, Headdress = true},
		{N = "Golden Scarab", B = "bug", C = {rgb(255, 200, 50), rgb(255, 240, 150), rgb(60, 220, 160)}, Horn = "bug", Mat = "Foil"},
	}},
	{Name = "Candy Egg", Price = 8e9, Color = rgb(255, 150, 210), Spot = rgb(130, 220, 255), Pattern = "sprinkles", Pets = {
		{N = "Gummy Bear", B = "quad", C = {rgb(255, 80, 90), rgb(255, 150, 150), rgb(255, 40, 60)}, Ears = "round", Tail = "short", Mat = "Glass"},
		{N = "Jelly Slime", B = "blob", C = {rgb(120, 220, 255), rgb(200, 245, 255), rgb(255, 120, 200)}, Mat = "Glass"},
		{N = "Cotton Sheep", B = "quad", C = {rgb(255, 190, 230), rgb(255, 240, 250), rgb(150, 220, 255)}, Ears = "dog", Tail = "puff", Fluff = true},
		{N = "Choco Bunny", B = "quad", C = {rgb(120, 70, 40), rgb(200, 150, 100), rgb(255, 200, 230)}, Ears = "bunny", Tail = "puff"},
		{N = "Lollipop Bird", B = "bird", C = {rgb(255, 100, 180), rgb(255, 240, 120), rgb(120, 220, 255)}, Tail = "feathers", Swirl = true},
		{N = "Sprinkle Unicorn", B = "quad", C = {W, rgb(255, 230, 245), rgb(255, 120, 220)}, Ears = "cat", Tail = "horse", Snout = "long", Horn = "unicorn", Mane = rgb(150, 200, 255), Spots = rgb(255, 120, 220)},
		{N = "Candy Dragon", B = "quad", C = {rgb(255, 150, 220), rgb(255, 240, 200), rgb(130, 230, 255)}, Ears = "none", Horns = "dragon", Tail = "long", Snout = "long", Wings = "dragon", Spikes = rgb(130, 230, 255)},
	}},
	{Name = "Spooky Egg", Price = 2e10, Color = rgb(90, 50, 130), Spot = rgb(255, 140, 40), Pattern = "zigzag", Pets = {
		{N = "Bat", B = "bird", C = {rgb(70, 55, 90), rgb(130, 110, 150), rgb(255, 80, 120)}, Ears = "cat", Wings = "bat", Beak = "none", Fangs = true},
		{N = "Ghosty", B = "ghost", C = {W, rgb(255, 255, 255), rgb(150, 220, 255)}},
		{N = "Black Cat", B = "quad", C = {rgb(35, 30, 45), rgb(60, 55, 75), rgb(255, 220, 40)}, Ears = "cat", Tail = "cat", Eyes = "glow"},
		{N = "Pumpkin Slime", B = "blob", C = {rgb(255, 140, 30), rgb(255, 190, 90), rgb(60, 140, 40)}, Pumpkin = true, Eyes = "glow"},
		{N = "Bone Pup", B = "quad", C = {rgb(240, 235, 220), rgb(250, 245, 235), rgb(40, 30, 40)}, Ears = "dog", Tail = "short", Snout = "long", Bones = true, Eyes = "glow"},
		{N = "Werewolf", B = "quad", C = {rgb(90, 80, 90), rgb(160, 150, 160), rgb(255, 230, 80)}, Ears = "cat", Tail = "fluffy", Snout = "long", Fangs = true, Eyes = "glow", Fluff = true, Big = true},
		{N = "Shadow Reaper", B = "ghost", C = {rgb(30, 20, 45), rgb(60, 40, 90), rgb(170, 80, 255)}, Hood = true, Scythe = true, Eyes = "glow", Glow = true},
	}},
	{Name = "Volcano Egg", Price = 5e10, Color = rgb(70, 30, 25), Spot = rgb(255, 110, 30), Pattern = "cracks", Mat = "CrackedLava", Pets = {
		{N = "Lava Slime", B = "blob", C = {rgb(255, 100, 30), rgb(255, 200, 80), rgb(120, 30, 10)}, Glow = true},
		{N = "Salamander", B = "quad", C = {rgb(255, 80, 40), rgb(255, 210, 90), rgb(120, 30, 20)}, Ears = "none", Tail = "long", Squat = true, Spots = rgb(255, 210, 60), Fire = true},
		{N = "Magma Turtle", B = "quad", C = {rgb(90, 50, 40), rgb(200, 120, 80), rgb(255, 110, 30)}, Ears = "none", Tail = "short", Shell = rgb(60, 30, 25), Glow = true},
		{N = "Ember Fox", B = "quad", C = {rgb(255, 90, 30), rgb(255, 220, 120), rgb(255, 200, 40)}, Ears = "cat", Tail = "fluffy", Snout = "long", Fire = true},
		{N = "Phoenix", B = "bird", C = {rgb(255, 120, 30), rgb(255, 220, 80), rgb(255, 60, 30)}, Tail = "phoenix", Wings = "feather", Fire = true, Crest = true},
		{N = "Inferno Dragon", B = "quad", C = {rgb(200, 30, 30), rgb(255, 180, 60), rgb(255, 120, 20)}, Ears = "none", Horns = "dragon", Tail = "long", Snout = "long", Wings = "dragon", Spikes = rgb(255, 200, 60), Fire = true},
		{N = "Magma Titan", B = "blob", C = {rgb(60, 25, 20), rgb(255, 120, 30), rgb(255, 220, 80)}, Big = true, Horns = "dragon", Fire = true, Glow = true, Crown = true},
	}},
	{Name = "Mythic Egg", Price = 1.25e11, Color = rgb(200, 120, 255), Spot = rgb(255, 230, 120), Pattern = "stars", Pets = {
		{N = "Griffin", B = "quad", C = {rgb(220, 170, 90), W, rgb(255, 180, 40)}, Ears = "none", Tail = "tuft", Snout = "beak", Wings = "feather", Tufts = true},
		{N = "Pegasus", B = "quad", C = {W, rgb(240, 245, 255), rgb(150, 200, 255)}, Ears = "cat", Tail = "horse", Snout = "long", Wings = "feather", Mane = rgb(150, 200, 255)},
		{N = "Unicorn", B = "quad", C = {W, rgb(255, 240, 250), rgb(255, 200, 60)}, Ears = "cat", Tail = "horse", Snout = "long", Horn = "unicorn", Mane = rgb(255, 130, 220)},
		{N = "Cerberus", B = "quad", C = {rgb(60, 50, 60), rgb(110, 90, 100), rgb(255, 80, 40)}, Ears = "cat", Tail = "long", Snout = "long", Heads = 3, Eyes = "glow", Fire = true},
		{N = "Kitsune", B = "quad", C = {W, rgb(255, 245, 240), rgb(255, 60, 80)}, Ears = "cat", Tail = "nine", Snout = "long", Markings = rgb(255, 60, 80), Glow = true},
		{N = "Hydra", B = "quad", C = {rgb(40, 120, 160), rgb(160, 230, 230), rgb(255, 210, 60)}, Ears = "none", Tail = "long", Heads = 3, Horns = "dragon", Wings = "dragon", Spikes = rgb(255, 210, 60)},
		{N = "Thunderbird", B = "bird", C = {rgb(40, 60, 160), rgb(130, 200, 255), rgb(255, 240, 80)}, Wings = "feather", Tail = "phoenix", Crest = true, Glow = true, Spark = true},
	}},
	{Name = "Cosmic Egg", Price = 1e12, Color = rgb(30, 20, 70), Spot = rgb(255, 255, 255), Pattern = "galaxy", Pets = {
		{N = "Space Cat", B = "quad", C = {rgb(120, 90, 230), rgb(200, 180, 255), rgb(255, 255, 255)}, Ears = "cat", Tail = "cat", Helmet = true},
		{N = "Alien", B = "blob", C = {rgb(120, 255, 120), rgb(200, 255, 200), rgb(40, 40, 60)}, Antenna = "ball", Eyes = "alien"},
		{N = "Star Bunny", B = "quad", C = {rgb(255, 240, 150), rgb(255, 255, 220), rgb(255, 160, 220)}, Ears = "bunny", Tail = "puff", Glow = true, Halo = true},
		{N = "Moon Wolf", B = "quad", C = {rgb(150, 160, 220), rgb(230, 235, 255), rgb(255, 245, 170)}, Ears = "cat", Tail = "fluffy", Snout = "long", Markings = rgb(255, 245, 170), Glow = true},
		{N = "Nebula Whale", B = "fish", C = {rgb(90, 40, 170), rgb(255, 150, 230), rgb(120, 230, 255)}, Fins = "whale", Big = true, Spots = W, Glow = true},
		{N = "Galaxy Dragon", B = "quad", C = {rgb(40, 20, 90), rgb(160, 110, 255), rgb(255, 120, 230)}, Ears = "none", Horns = "dragon", Tail = "long", Snout = "long", Wings = "dragon", Spikes = rgb(120, 230, 255), Spots = W, Glow = true},
		{N = "Infinity Phoenix", B = "bird", C = {rgb(255, 255, 255), rgb(255, 230, 140), rgb(120, 230, 255)}, Wings = "feather", Tail = "phoenix", Crest = true, Halo = true, Fire = true, Glow = true, Rainbow = true},
	}},
}

-- Fill in every pet's egg, rarity, boost and a unique key "egg-slot"
D.PETS = {}
for e, egg in ipairs(D.EGGS) do
	egg.Index = e
	egg.Odds = {}
	local shift = 1 + 0.045 * (e - 1)
	local total = 0
	for r, base in ipairs(BASE_ODDS) do
		egg.Odds[r] = base * shift ^ (r - 1)
		total += egg.Odds[r]
	end
	for r = 1, #BASE_ODDS do
		egg.Odds[r] = egg.Odds[r] / total * 100
	end
	for r, pet in ipairs(egg.Pets) do
		pet.Key = e .. "-" .. r
		pet.Egg = e
		pet.R = r
		-- install speed bonus (%): grows with the egg, and a lot with rarity
		pet.Boost = math.floor(2 * 1.26 ^ (e - 1) * D.RARITIES[r].Mult + 0.5)
		D.PETS[pet.Key] = pet
	end
end

-- Odds shown as text, e.g. 0.15% or 12.3%
function D.oddsText(p)
	if p < 1 then
		return string.format("%.2f%%", p)
	end
	return string.format("%.1f%%", p)
end

return D

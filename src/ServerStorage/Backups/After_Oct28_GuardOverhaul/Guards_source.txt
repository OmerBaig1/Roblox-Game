--[[
	STEAL A GAME - SHOPKEEPERS
	One giant shopkeeper guards every vault level, and every one is a complete character: a sculpted body (generated
	as one cohesive mesh, then rigged - see ServerStorage.GuardLab.GuardRigKit), a personality, and its own motion.
	ROSTER (by level number) is the design sheet: concept, silhouette, face, palette, motion and laugh.

	The rigged bodies live in ServerStorage.GuardModels (L01..L40). The server clones the level's body, scales it to
	giant size and tells everyone what it's doing through model attributes:
	  Motion                 the guard's key: GuardMotion (client) draws its idle, chase gait and catch reaction
	  Chasing, Returning     what the AI is up to
	  Act, ActAt             a one-off reaction ("taunt", "grab", "laugh", "whiff"; "" = none) and when it started
	The laugh is a 3D Sound in the head, played by the server so everyone nearby hears it.
	No uploaded animations are used: every pose is computed from these attributes on each player's screen.
]]

local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local Guards = {}

local function laugh(id, pitch, cut)
	return {Id = "rbxassetid://" .. id, Pitch = pitch, Cut = cut or 3}
end

-- The design roster. Laughs are Pro Sound Effects recordings unless noted (user uploads already in the game).
-- Step = footstep pitch (0 = it glides, rolls or floats: no footsteps). Size scales the giant up or down a little.
Guards.ROSTER = {
	-- 1 BARGAIN BASEMENT: discount-store muscle
	{Key = "brutus", Name = "Brutus", Title = "Head of Security", Size = 1.05, Step = 0.32, Laugh = laugh(9116452672, 0.72),
		Concept = "A hulking human security chief who takes 'no refunds' personally",
		Silhouette = "V-shaped wall of a man: huge shoulders and chest, thick neck, short legs planted wide",
		Face = "buzz cut, square stubbled jaw, cheek scar, wraparound shades", Palette = "black tactical jacket, gold badge"},
	{Key = "tusk", Name = "Tusk", Title = "Pawnshop Boar", Size = 1.05, Step = 0.36, Laugh = laugh(9116452936, 0.6, 3.5),
		Concept = "A warthog pawnbroker who weighs everything you own and shoves you out the door",
		Silhouette = "barrel body, heavy forward-hanging head, stubby legs",
		Face = "long curved tusks, bristly mane, small mean eyes", Palette = "leather apron, striped vest, gold rings"},
	-- 2 RETRO ARCADE
	{Key = "kong", Name = "Kong", Title = "Arcade Bouncer", Size = 1.15, Step = 0.28, Laugh = laugh(9116455856, 0.55, 3.4),
		Concept = "A silverback gorilla who has thrown out every cheater since 1981",
		Silhouette = "massive hunched shoulders, very long arms, short bowed legs",
		Face = "heavy brow ridge, glowing orange eyes, small horns", Palette = "blue-grey fur, black-and-yellow referee vest"},
	{Key = "static", Name = "Static", Title = "Jackal DJ", Size = 1.0, Step = 0.6, Laugh = laugh(9116452741, 1.12),
		Concept = "A sly jackal DJ who chases you to his own beat",
		Silhouette = "lean and tall, long tall ears, narrow waist",
		Face = "pointed muzzle, sharp grin, glowing cyan eyes", Palette = "sandy fur, black hoodie with neon trim, cyan headphones"},
	-- 3 TOY TOWN
	{Key = "tin", Name = "Sergeant Tin", Title = "Toy Soldier", Size = 1.05, Step = 0.6, Laugh = laugh(9116452494, 1.6),
		Concept = "A wind-up tin soldier, stiff, proud and always marching",
		Silhouette = "tall and straight as a ruler, towering bearskin hat",
		Face = "painted stern face, rosy cheeks, curled moustache", Palette = "glossy red tunic, white cross belts, gold buttons"},
	{Key = "stitches", Name = "Stitches", Title = "Plush Brute", Size = 1.1, Step = 0.7, Laugh = laugh(9116452923, 1.25, 3.2),
		Concept = "A patched-up giant teddy bear who bounces after you like he's still on a spring",
		Silhouette = "round soft belly, stubby paws, one sewn-back ear",
		Face = "mismatched button eyes, grumpy stitched mouth", Palette = "patched brown fabric, red bow tie"},
	-- 4 PIRATE COVE
	{Key = "calico", Name = "Captain Calico", Title = "Undead Pirate", Size = 1.05, Step = 0.4, Laugh = laugh(95889123106297, 1), -- user upload
		Concept = "A cursed pirate captain who never stopped counting his gold",
		Silhouette = "long coat flaring at the hem, wide tricorn, one peg leg",
		Face = "grey-green rotting skin, glowing green eyes, ragged beard", Palette = "crimson coat with gold trim, black tricorn"},
	{Key = "brine", Name = "Brineback", Title = "Shark Bosun", Size = 1.1, Step = 0.33, Laugh = laugh(9116239333, 0.8),
		Concept = "A hammerhead first mate who keeps the deck - and the vault - clear",
		Silhouette = "wide hammer head, broad chest, thick arms",
		Face = "hammerhead with eyes on the ends, rows of teeth", Palette = "grey-blue skin, white belly, striped sailor top"},
	-- 5 HAUNTED CRYPT
	{Key = "mortimer", Name = "Mortimer", Title = "Crypt Keeper", Size = 1.05, Step = 0.65, Laugh = laugh(130665625557386, 0.9), -- user upload
		Concept = "A giggling skeleton who sneaks up on thieves with his lantern",
		Silhouette = "tall, hooded, bony and stooped",
		Face = "skull with glowing green sockets", Palette = "tattered purple robe, green lantern glow"},
	{Key = "fangula", Name = "Count Fangula", Title = "Vampire Lord", Size = 1.1, Step = 0, Laugh = laugh(9116239118, 0.9),
		Concept = "A gaunt aristocrat of the night who glides rather than walks",
		Silhouette = "thin and tall, high collar, cape spreading like wings",
		Face = "pale grey skin, red eyes, fangs, slicked hair", Palette = "black and crimson"},
	-- 6 CYBER CITY
	{Key = "vex", Name = "Unit Vex", Title = "Cyber Enforcer", Size = 1.05, Step = 0.45, Laugh = laugh(9118542198, 0.9),
		Concept = "A by-the-book riot enforcer with a glitching visor",
		Silhouette = "armoured plates, wide pauldrons, athletic build",
		Face = "full helmet, glowing cyan visor", Palette = "matte black armour, cyan light lines"},
	{Key = "vapor", Name = "Vapor", Title = "Cyber Wolf", Size = 1.05, Step = 0.7, Laugh = laugh(9114398144, 0.7),
		Concept = "A chrome-limbed wolf runner from the neon streets",
		Silhouette = "lean, long-legged, pointed ears, cybernetic arm",
		Face = "wolf muzzle, glowing magenta eyes", Palette = "dark fur, chrome, magenta neon"},
	-- 7 NINJA DOJO
	{Key = "kage", Name = "Kage", Title = "Shadow Ninja", Size = 1.0, Step = 0.8, Laugh = laugh(82098286607079, 0.95), -- user upload
		Concept = "A silent ninja who runs with his arms flung back",
		Silhouette = "lean, crouched, scarf tails, katana on the back",
		Face = "masked, only fierce eyes showing", Palette = "dark navy wraps, red sash"},
	{Key = "oni", Name = "Taiho", Title = "Oni Samurai", Size = 1.15, Step = 0.28, Laugh = laugh(9125650858, 0.7, 3.2),
		Concept = "A horned red demon in samurai armour who stomps the ground flat",
		Silhouette = "massive, horned, armoured shoulders, spiked club",
		Face = "red skin, fangs, wild white mane, two horns", Palette = "red skin, black lacquered armour"},
	-- 8 ROBOT FACTORY
	{Key = "sb9000", Name = "SB-9000", Title = "Security Mech", Size = 1.1, Step = 0.5, Laugh = laugh(100272190583394, 1), -- user upload
		Concept = "An industrial security mech that moves in exact, ticking steps",
		Silhouette = "blocky industrial chassis, hydraulic arms, squat legs",
		Face = "single red eye", Palette = "yellow and grey plating, hazard stripes"},
	{Key = "model7", Name = "Model-7", Title = "Android Sentinel", Size = 1.05, Step = 0.5, Laugh = laugh(9118542750, 1.2),
		Concept = "A sleek android whose movement skips like a corrupted video",
		Silhouette = "slender, smooth, long limbs",
		Face = "faceless black visor with a blue light bar", Palette = "glossy white plating, blue joints"},
	-- 9 DRAGON'S LAIR
	{Key = "scorch", Name = "Sir Scorch", Title = "Dragon Knight", Size = 1.1, Step = 0.35, Laugh = laugh(9114628818, 0.85),
		Concept = "A knight in dragon-scale armour who charges sword first",
		Silhouette = "plate armour, horned dragon helm, folded wings",
		Face = "dragon-head helm with glowing orange eyes", Palette = "dark crimson scale armour, flame-orange sword"},
	{Key = "magmor", Name = "Magmor", Title = "Lava Golem", Size = 1.15, Step = 0.25, Laugh = laugh(9116239334, 0.55, 4),
		Concept = "A slow-burning golem of cooled rock and glowing magma",
		Silhouette = "boulder shoulders, enormous fists, tiny head",
		Face = "glowing eyes in a rock face", Palette = "black basalt, orange magma seams"},
	-- 10 OUTER SPACE
	{Key = "nova", Name = "Commander Nova", Title = "Space Ranger", Size = 1.05, Step = 0.45, Laugh = laugh(9116452733, 1.0),
		Concept = "A space ranger who still runs like he's on the Moon",
		Silhouette = "integrated armoured suit, big rounded helmet, jetpack",
		Face = "gold reflective visor", Palette = "white and blue armour"},
	{Key = "zorp", Name = "Zorp", Title = "Alien Overlord", Size = 1.1, Step = 0.9, Laugh = laugh(9113090712, 1),
		Concept = "A noodle-limbed alien overlord who wobbles like jelly",
		Silhouette = "huge bulb head, thin long limbs, high-collared robe",
		Face = "large black almond eyes", Palette = "grey-green skin, purple robe"},
	-- 11 SUNKEN ATLANTIS
	{Key = "dex", Name = "Dex", Title = "Deep-Sea Diver", Size = 1.05, Step = 0.3, Laugh = laugh(9116452853, 0.75),
		Concept = "A diver in a brass helmet who wades along as if underwater",
		Silhouette = "round brass helmet, bulky suit, heavy boots",
		Face = "round porthole faceplate", Palette = "brass, worn canvas"},
	{Key = "tridentus", Name = "King Tridentus", Title = "Lord of the Sea", Size = 1.15, Step = 0.32, Laugh = laugh(9116239130, 0.7),
		Concept = "The sea king from the throne room reference, surging after you behind his trident",
		Silhouette = "god-like musculature, crown, flowing beard, trident",
		Face = "golden crown, flowing blue beard and hair", Palette = "teal sash, gold jewellery"},
	-- 12 DESERT PYRAMIDS
	{Key = "mumbles", Name = "Mumbles", Title = "Tomb Mummy", Size = 1.1, Step = 0.5, Laugh = laugh(9114571613, 0.8),
		Concept = "A hulking mummy, arms out, trailing bandages",
		Silhouette = "hunched powerful shoulders, wrapped limbs",
		Face = "glowing yellow eyes through the wraps", Palette = "dirty linen, gold scarab"},
	{Key = "anubis", Name = "Anubis", Title = "Jackal God", Size = 1.15, Step = 0.38, Laugh = laugh(9125650549, 0.85, 3.4),
		Concept = "The jackal-headed god from the Ra reference, guarding the tomb with a golden staff",
		Silhouette = "tall ears, broad gold collar, kilt, staff",
		Face = "black jackal head, gold-lined eyes", Palette = "black, gold and lapis blue"},
	-- 13 CANDY KINGDOM
	{Key = "peppermint", Name = "Sir Peppermint", Title = "Candy Cane Knight", Size = 1.1, Step = 0.55, Laugh = laugh(9119956929, 1.3),
		Concept = "A peppermint knight sworn to guard the Gumdrop Galleria, lance always levelled",
		Silhouette = "striped plate armour, round swirl shield, long candy-cane lance",
		Face = "closed helm with a dark visor slit and a peppermint crest", Palette = "red and white stripes, chocolate brown"},
	{Key = "bonbon", Name = "Baron von Bonbon", Title = "Gingerbread Chef", Size = 1.1, Step = 0.6, Laugh = laugh(9116453058, 1.1, 3.2),
		Concept = "A sinister gingerbread chef who skips with delight",
		Silhouette = "round cookie body, tall chef hat",
		Face = "icing grin, gumdrop eyes", Palette = "baked brown, white icing, candy buttons"},
	-- 14 FROZEN TUNDRA
	{Key = "pemberton", Name = "Pemberton", Title = "Penguin Butler", Size = 0.95, Step = 0.85, Laugh = laugh(9113090497, 1.5, 2.6),
		Concept = "An emperor penguin butler with a frantic waddle",
		Silhouette = "egg-shaped body, flippers, tailcoat",
		Face = "beak, yellow neck patch, monocle", Palette = "black and white, red bow tie"},
	{Key = "yuki", Name = "Yuki", Title = "Mountain Yeti", Size = 1.2, Step = 0.27, Laugh = laugh(9113090321, 0.55, 3),
		Concept = "A shaggy yeti who gallops on its knuckles",
		Silhouette = "huge furry ape body, curved horns",
		Face = "blue-grey face, glowing icy eyes", Palette = "white fur, blue skin"},
	-- 15 WILD WEST
	{Key = "sheriff", Name = "Sheriff Tumbleweed", Title = "Town Sheriff", Size = 1.05, Step = 0.55, Laugh = laugh(9125650142, 0.95, 3.2),
		Concept = "A grizzled sheriff who gallops after you on an invisible horse",
		Silhouette = "wide-brim hat, long duster coat, bow legs",
		Face = "weathered face, thick moustache", Palette = "dust brown, star badge"},
	{Key = "rattler", Name = "Rattler", Title = "Snake Bandit", Size = 1.05, Step = 0.5, Laugh = laugh(9116453135, 1.2, 3.2),
		Concept = "A rattlesnake outlaw who slithers side to side as he runs",
		Silhouette = "long neck and snake head, poncho, rattle tail",
		Face = "fangs, slit yellow eyes", Palette = "patterned scales, red bandana"},
	-- 16 JUNGLE TEMPLE
	{Key = "tiki", Name = "Tiki Tok", Title = "Tiki Golem", Size = 1.1, Step = 0.45, Laugh = laugh(9114572131, 0.7),
		Concept = "A carved tiki spirit that hops in a war-dance stomp",
		Silhouette = "tall carved mask head, leaf skirt, feather crest",
		Face = "carved mask, glowing eyes, big teeth", Palette = "warm wood, leaf green"},
	{Key = "itza", Name = "Itza", Title = "Jaguar Warrior", Size = 1.05, Step = 0.85, Laugh = laugh(9114396841, 0.9),
		Concept = "A temple warrior jaguar who prowls low and fast",
		Silhouette = "athletic cat body, feathered headdress",
		Face = "jaguar face, golden eyes", Palette = "spotted gold fur, jade and feathers"},
	-- 17 MIDNIGHT CARNIVAL
	{Key = "wobbles", Name = "Wobbles", Title = "Carnival Clown", Size = 1.05, Step = 0.55, Laugh = laugh(9125650555, 1.3, 3.4),
		Concept = "A grinning carnival clown who never stops moving",
		Silhouette = "baggy suit, ruffled collar, oversized shoes",
		Face = "white paint, sinister red grin, wild green hair", Palette = "polka dots, red and yellow"},
	{Key = "taurus", Name = "Taurus", Title = "Minotaur Strongman", Size = 1.15, Step = 0.3, Laugh = laugh(9125650546, 0.6, 3.4),
		Concept = "The circus strongman is a minotaur, and he charges",
		Silhouette = "massive shoulders, curved horns, hooves",
		Face = "bull head, nose ring, angry brow", Palette = "dark brown fur, red-and-white leotard, gold belt"},
	-- 18 STEAMPUNK SKYWAY
	{Key = "jenny", Name = "Jetpack Jenny", Title = "Sky Courier", Size = 1.0, Step = 0, Laugh = laugh(9114398346, 1.0),
		Concept = "A goggled aviator who skims along on her jetpack",
		Silhouette = "flight jacket, scarf, twin brass tanks",
		Face = "goggles pushed up, confident grin", Palette = "leather brown, brass, white scarf"},
	{Key = "ironclad", Name = "Ironclad", Title = "Steam Automaton", Size = 1.15, Step = 0.4, Laugh = laugh(9118539547, 0.7),
		Concept = "A riveted automaton whose pistons hiss with every stride",
		Silhouette = "furnace chest, smokestack shoulders, piston arms",
		Face = "grilled faceplate, glowing furnace eyes", Palette = "copper and brass, orange glow"},
	-- 19 CRYSTAL CAVERNS
	{Key = "moe", Name = "Moe", Title = "Mole Miner", Size = 0.95, Step = 0.95, Laugh = laugh(9113090742, 0.9, 2.8),
		Concept = "A short-sighted giant mole who scurries with his claws digging the air",
		Silhouette = "round, low, enormous digging claws",
		Face = "pink star nose, tiny eyes, hard hat lamp", Palette = "dark velvet fur, miner yellow"},
	{Key = "lumina", Name = "Queen Lumina", Title = "Crystal Sorceress", Size = 1.1, Step = 0.55, Laugh = laugh(9114398155, 1.1),
		Concept = "A crystal sorceress who leaps after you like a prima ballerina",
		Silhouette = "tall, crystal crown, flowing gown",
		Face = "regal, glowing violet eyes", Palette = "lavender and violet crystal"},
	-- 20 COSMIC NEXUS
	{Key = "chronos", Name = "Chronos", Title = "Time Wizard", Size = 1.1, Step = 0.5, Laugh = laugh(9114571545, 0.85),
		Concept = "An ancient time wizard who stutters forward in skipped frames",
		Silhouette = "long robe, tall pointed hat, hourglass",
		Face = "long white beard, glowing eyes", Palette = "deep blue robe with clock faces"},
	{Key = "gamemaster", Name = "The Game Master", Title = "Final Boss", Size = 1.2, Step = 0, Laugh = laugh(9113091011, 0.5, 4),
		Concept = "The vault's mastermind: floats above the floor, arms raised",
		Silhouette = "tall armoured overlord, spiked crown, flowing cape",
		Face = "glowing purple eyes under a crown", Palette = "black and purple armour, glowing sceptre"},
}

-- How briskly each walks home after a chase (1 = normal): heavy ones lumber, nimble ones hurry
local PACE = {brutus = 0.9, tusk = 0.9, kong = 0.85, static = 1.15, tin = 1.0, stitches = 1.1, calico = 0.9, brine = 0.9,
	mortimer = 1.1, fangula = 1.2, vex = 1.1, vapor = 1.25, kage = 1.3, oni = 0.8, sb9000 = 0.85, model7 = 1.1, scorch = 0.95,
	magmor = 0.75, nova = 1.0, zorp = 1.05, dex = 0.75, tridentus = 0.9, mumbles = 0.7, anubis = 0.95, peppermint = 1.0,
	bonbon = 1.1, pemberton = 1.15, yuki = 0.9, sheriff = 1.1, rattler = 1.15, tiki = 0.95, itza = 1.3, wobbles = 1.1,
	taurus = 0.9, jenny = 1.3, ironclad = 0.8, moe = 1.05, lumina = 1.15, chronos = 0.9, gamemaster = 1.0}
for _, R in ipairs(Guards.ROSTER) do
	R.Pace = PACE[R.Key] or 1
end

function Guards.create(C, Kit, level, parent, post)
	local L = C.LEVELS[level]
	local R = Guards.ROSTER[level]
	assert(R, "no shopkeeper in the roster for level " .. level)
	local template = ServerStorage:WaitForChild("GuardModels"):FindFirstChild(string.format("L%02d", level))
	assert(template, "no rigged body for level " .. level .. " in ServerStorage.GuardModels")
	local accent = L.Accent
	local scale = C.guardScale(level) * (R.Size or 1)
	local scary = (level - 1) / math.max(1, C.NUM_LEVELS - 1) -- 0 at level 1, 1 at the deepest level

	local model = template:Clone()
	model.Name = string.format("%02d_%s", level, R.Name)
	model:SetAttribute("Scale", scale)
	model:SetAttribute("GuardName", R.Name)
	model:SetAttribute("Motion", R.Key)
	model:SetAttribute("StepPitch", R.Step)
	model:SetAttribute("Chasing", false)
	model:SetAttribute("Returning", false)
	-- streamed to players whole, so their game never animates a half-arrived body
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	local hip = hum.HipHeight
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = C.GUARD_IDLE_REAL_SPEED
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	-- Giants never trip, ragdoll, climb or swim
	for _, st in ipairs({Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.PlatformStanding}) do
		hum:SetStateEnabled(st, false)
	end
	hum.AutomaticScalingEnabled = false
	model:ScaleTo(scale)
	hum.HipHeight = hip * scale
	-- Stand the giant on the floor (floor top is y = 0.2), facing the vault entrance
	local standY = 0.2 + hum.HipHeight + root.Size.Y / 2
	model:SetAttribute("StandY", standY)
	model:PivotTo(CFrame.new(post.X, standY, post.Z))
	model.Parent = parent
	local head = model:FindFirstChild("Head")

	-- A trail behind them in their level's colour, longer and redder deeper in
	do
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, scale, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -scale * 1.2, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(accent:Lerp(Color3.fromRGB(255, 30, 30), scary * 0.8), accent:Lerp(Color3.fromRGB(20, 0, 0), scary))
		trail.Lifetime = 0.35 + scary * 0.9
		trail.WidthScale = NumberSequence.new(1, 0.2)
		trail.Transparency = NumberSequence.new(0.3, 1)
		trail.LightEmission = 0.4 + scary * 0.6
		trail.FaceCamera = true
		trail.Parent = root
	end
	-- Dust kicked up by every step (none for the ones who glide, roll or float)
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "StepDust"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 190, 170))
	dust.Size = NumberSequence.new(scale * 0.6, scale * 1.4)
	dust.Transparency = NumberSequence.new(0.55, 1)
	dust.Lifetime = NumberRange.new(0.6, 1)
	dust.Rate = 0
	dust.Speed = NumberRange.new(scale, scale * 2)
	dust.SpreadAngle = Vector2.new(80, 10)
	dust.EmissionDirection = Enum.NormalId.Bottom
	dust.Parent = root
	Kit.setGroup(model, "Guards")
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	-- the laugh is a 3D sound in their head, so everyone nearby hears it, and it's theirs alone
	local laughSound = Instance.new("Sound")
	laughSound.Name = "Laugh"
	laughSound.SoundId = R.Laugh.Id
	laughSound.PlaybackSpeed = R.Laugh.Pitch
	laughSound.Volume = 1
	laughSound.RollOffMode = Enum.RollOffMode.InverseTapered
	laughSound.RollOffMinDistance = 20
	laughSound.RollOffMaxDistance = 220
	laughSound.Parent = head or root
	local laughToken = 0
	local lastLaugh = -math.huge

	local function act(name)
		model:SetAttribute("Act", name)
		model:SetAttribute("ActAt", workspace:GetServerTimeNow())
	end
	local actions = {
		-- any one-off reaction GuardMotion knows ("grab", "whiff", "" to end one)
		Act = function(name)
			act(name)
		end,
		Taunt = function()
			act("taunt")
		end,
		Laugh = function()
			act("laugh")
			-- one laugh per catch: a second catch inside the cooldown (two players at once) keeps the first going
			local now = os.clock()
			if now - lastLaugh < 1.5 then return end
			lastLaugh = now
			laughToken += 1
			local my = laughToken
			laughSound.TimePosition = 0
			laughSound:Play()
			-- trim the long takes to the laugh itself
			task.delay(R.Laugh.Cut, function()
				if my == laughToken and laughSound.IsPlaying then
					laughSound:Stop()
				end
			end)
		end,
		Stomp = function()
			if (R.Step or 0) > 0 then
				dust:Emit(10)
			end
		end,
		Poof = function()
			-- a puff of smoke where they vanish (they reappear at their post)
			local puff = Instance.new("Part")
			puff.Anchored = true
			puff.CanCollide = false
			puff.CanQuery = false
			puff.Transparency = 1
			puff.Size = Vector3.one
			puff.CFrame = root.CFrame
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(accent:Lerp(Color3.new(1, 1, 1), 0.5))
			smoke.Size = NumberSequence.new(scale * 2, scale * 4)
			smoke.Transparency = NumberSequence.new(0.2, 1)
			smoke.Lifetime = NumberRange.new(0.6, 0.9)
			smoke.Speed = NumberRange.new(scale * 2, scale * 4)
			smoke.SpreadAngle = Vector2.new(180, 180)
			smoke.Rate = 0
			smoke.Parent = puff
			puff.Parent = workspace
			smoke:Emit(30)
			Debris:AddItem(puff, 1.5)
			act("poof")
		end,
	}
	local look = {Title = R.Title, Name = R.Name}
	return model, hum, root, head, look, actions
end

return Guards

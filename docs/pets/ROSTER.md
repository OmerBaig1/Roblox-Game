# Roster: 60 premium pets

8 eggs replace the old 15. Eggs 1–3 have 7 pets, eggs 4–8 have 8. Secrets only hatch from eggs 4–8.
About 16 pets are arcade or tech themed (the Arcade and Circuit eggs), so the game's "stealing games" theme runs
through every tier. Pet numbers are the build order in STATUS.md.

| # | Egg | Theme | Pets | Tiers in egg |
|---|---|---|---|---|
| 1 | Ember Egg | volcano, ash, embers | 7 | C C U R E L M |
| 2 | Tide Egg | reef, abyss, currents | 7 | C C U R E L M |
| 3 | Grove Egg | enchanted forest, spirits | 7 | C U U R E L M |
| 4 | Frost Egg | glaciers, crystal, aurora | 7 | C U R E L M S |
| 5 | Arcade Egg | retro coin-op, pixels, cartridges | 8 | C U R R E L M S |
| 6 | Circuit Egg | robots, synthwave, data | 8 | C U U R E L M S |
| 7 | Phantom Egg | ghosts, haunted, shadow | 8 | C U R E E L M S |
| 8 | Celestial Egg | stars, planets, light | 8 | C U R E L L M S |

Totals: Common 10 · Uncommon 10 · Rare 9 · Epic 9 · Legendary 9 · Mythic 8 · Secret 5 = **60**.

Each entry has: concept · hero feature · **Prompt** (append the house style suffix from PET_BIBLE §1) · **Parts**
(exact `partNames` for the generator, max 8 per call) · extra generations/props · motion · signature (Epic+) · effects.

---

## Egg 1: Ember Egg

### 1. Coalpup · `coalpup` · Common · Bound
Ash-grey puppy whose fur is cracked charcoal with faint orange heat in the cracks. Clumsy, eager. **Hero:** oversized floppy ears.
- **Prompt:** small puppy made of charcoal, dark ash-grey body with thin glowing orange cracks, big floppy ears, stubby tail, round amber eyes, eager expression
- **Parts:** body and legs, head, left ear, right ear, tail
- **Motion:** idle: tail wags in bursts, ears flop on head tilts. Follow: short bouncy bound, ears flap with each hop.
- **FX:** none (glowing cracks are texture only).

### 2. Flicker Moth · `flicker_moth` · Common · Hover
Soot-black moth with ember-orange eyespots on its wings, drawn to the player like a flame. **Hero:** big round wings.
- **Prompt:** fuzzy round moth, soot black body, large rounded wings with orange ember eyespot patterns, feathery antennae, cute big eyes
- **Parts:** body, left wing, right wing, antennae
- **Motion:** idle: lazy wing flutter, drifts in small figure-eights. Follow: fast flapping, banks into turns.
- **FX:** none.

### 3. Magma Toad · `magma_toad` · Uncommon · Hop
Squat basalt toad with bubbling lava blisters on its back. Grumpy. **Hero:** inflating throat sac.
- **Prompt:** squat grumpy toad, dark basalt rock skin, glowing lava blisters on its back, big orange throat sac, heavy brow
- **Parts:** body and legs, head, throat sac, back blisters
- **Motion:** idle: throat sac pushes out and in (offset forward/back) with a croak rhythm. Follow: heavy hops with a pause, back blisters jiggle on landing.
- **FX:** tiny ember pop from the blisters on each landing (Emit 3).

### 4. Pyre Salamander · `pyre_salamander` · Rare · Slither
Long salamander with a frill of flame-shaped fins down its spine. Quick and curious. **Hero:** spine frill.
- **Prompt:** long sleek salamander, deep red and black banded skin, row of flame-shaped orange fins along its spine, four short legs, golden eyes
- **Parts:** head, front body, back body, tail base, tail tip, spine frill
- **Motion:** idle: looks around, frill ripples (small per-segment rotation). Follow: segment-chain sine wiggle across the ground.
- **FX:** embers drift off the frill (≤ 8/s), short heat trail from the tail tip while moving.

### 5. Cinder Lynx · `cinder_lynx` · Epic · Bound **(DONE: the reference pet)**
Plum lynx with ember glyphs, flame-tipped ears and tail, three cyan shards orbiting. See `ServerStorage.PetLab.Pets.CinderLynx`.
- **Signature:** Ember Flick. Glances back, flicks its tail high, and throws off 30 embers while the tail glow flares.

### 6. Obsidian Drake · `obsidian_drake` · Legendary · Hover
Young dragon armoured in black glass plates, with lava running in the seams. Proud. **Hero:** huge spiked wings.
- **Prompt:** young dragon with glossy black obsidian armor plates, glowing lava veins between the plates, huge spiked bat-like wings, curved horns, long tail with a spade tip
- **Parts:** body, head, left wing, right wing, tail, horns, jaw
- **2nd gen:** `obsidian ring segment, floating volcanic glass shard ring` (segmentation none). Clone it into a 3-piece broken halo that orbits behind its head.
- **Motion:** idle: slow wingbeats while hovering, jaw opens to exhale smoke. Follow: powerful flaps, glides between beats, banks hard.
- **Signature:** Heat Roar. Rears back, wings spread wide, jaw open, and a ring-shaped heat shockwave (expanding Beam ring or ring of particles) rolls out along the ground.
- **FX:** smoke wisps from the jaw, lava-glow PointLight in the chest, ember trail from the wingtips.

### 7. Solflare Qilin · `solflare_qilin` · Mythic · Bound
A qilin with scales of beaten gold, a mane of living flame ribbons, and a sun disc floating behind it. Regal. **Hero:** ribbon mane.
- **Prompt:** qilin, deer-like body with golden scales, single curved antler horn, flowing mane made of orange and gold flame ribbons, cloven hooves wreathed in fire, regal face
- **Parts:** body and legs, head, mane, tail, horn, hooves
- **2nd gen:** `ornate golden sun disc with flame rays, flat medallion` → floats behind its shoulders, rotating.
- **Motion:** idle: mane ribbons sway in layers, sun disc turns slowly. Follow: elegant floating bound, hooves leave fading fire prints.
- **Signature (transformation):** Solar Ascension. The mane ignites into a full blaze (mane part swaps colour to Neon-bright, flame emitters rise), the sun disc expands behind it, and a burst of light rays (Beams) fans out before it all settles back.
- **FX:** hoof-print particles while moving, two lights (mane, disc), light-ray Beams during the signature.

## Egg 2: Tide Egg

### 8. Bubblefin · `bubblefin` · Common · Glide
Round little reef fish that swims through the air. Easily startled. **Hero:** perfectly round body.
- **Prompt:** small perfectly round fish, turquoise body with coral-pink stripes, big frilly tail fin, tiny side fins, huge surprised eyes
- **Parts:** body, tail fin, left fin, right fin
- **Motion:** idle: tail swishes, fins paddle, occasional startled wiggle. Follow: swims after the player at waist height.
- **FX:** none.

### 9. Coral Crab · `coral_crab` · Common · Scuttle
Crab wearing a chunk of living coral as its shell. Busy. **Hero:** coral crown shell.
- **Prompt:** small crab with a shell made of branching pink and purple coral, sandy orange claws, eyes on stalks
- **Parts:** body, coral shell, left claw, right claw, eye stalks
- **Motion:** idle: claws click in turn, eye stalks look around. Follow: scuttles **sideways** (yaw offset 90° while moving), claws raised.
- **FX:** none.

### 10. Lantern Eel · `lantern_eel` · Uncommon · Slither
Deep-sea eel with a glowing lure dangling over its head. **Hero:** lure.
- **Prompt:** slender deep sea eel, dark navy body with faint bioluminescent dots, long dangling glowing cyan lure on a stalk above its head, toothy grin
- **Parts:** head, body front, body middle, tail, lure
- **Motion:** idle: coils in an S, lure swings like a pendulum. Follow: swims through the air in a wave, lure trails behind.
- **FX:** soft glow motes from the lure (≤ 4/s).

### 11. Surf Otter · `surf_otter` · Rare · Glide
Otter lounging on its back on a floating ball of water. Chill. **Hero:** water orb.
- **Prompt:** sea otter lying on its back, brown fur with cream belly, holding a shell, floating on a ball of clear blue water
- **Parts:** body, head, tail, paws and shell, water orb
- **Motion:** idle: belly-up float, cracks shell on tummy. Follow: sits up and surfs the orb, leaning into turns.
- **FX:** water droplets and a foam trail from the orb while moving, orb in Glass material, slightly transparent.

### 12. Reefguard Manta · `reefguard_manta` · Epic · Glide
Midnight-blue manta with glowing spots, escorted by two remora fish. **Hero:** wide wingspan.
- **Prompt:** manta ray, midnight blue top with glowing cyan spot pattern, white underside, wide pointed wings, curled head lobes, long thin tail
- **Parts:** body, left wing, right wing, tail, head lobes
- **Props:** 2 small remora fish (generate `small sleek remora fish`, none) orbit under it.
- **Motion:** idle: slow wing undulation (wing tips lag body). Follow: graceful glide, banks deep into turns.
- **Signature:** Barrel Roll. A full roll around its length while releasing a ring of bubbles.
- **FX:** bubble trail, spot glow light, bubble ring burst during the signature.

### 13. Maelstrom Serpent · `maelstrom_serpent` · Legendary · Slither (airborne)
Sea serpent wrapped in its own spinning whirlpool. **Hero:** long coiling body.
- **Prompt:** sea serpent, teal and deep green scales, pale belly, fin crest along the back, fierce head with whiskers and fins
- **Parts:** head, segment 1, segment 2, segment 3, segment 4, segment 5, tail fin, crest
- **2nd gen:** `swirling water ring, translucent whirlpool band` → rotating ring around its body.
- **Motion:** idle: coils in a slow spiral. Follow: S-wave through the air, segment chain.
- **Signature:** Rising Tide. Spirals upward into a tight coil while the whirlpool ring speeds up and sprays.
- **FX:** spray particles, a spiral water Beam, foam trail.

### 14. Coralcrown Leviathan · `coralcrown_leviathan` · Mythic · Glide
Whale-like leviathan calf carrying a glowing coral castle on its back, lit by floating jellyfish lanterns. **Hero:** castle on its back.
- **Prompt:** baby leviathan whale, deep blue body with barnacle patterns, a small glowing coral castle growing on its back, long elegant fins
- **Parts:** body, head, tail fluke, left fin, right fin, coral castle
- **2nd gen:** `small glowing jellyfish lantern` (none) → 3 copies orbit the castle.
- **Motion:** idle: slow roll and bob, jellyfish lanterns pulse. Follow: majestic glide, fluke sweeps.
- **Signature (transformation):** Bioluminant Tide. The whole body lights up in a wave of bioluminescence (a pattern-overlay part fades to Neon from head to tail), the castle windows blaze, and a blowhole spout of light fires.
- **FX:** two lights, spout particles, glowing wake Beam.

## Egg 3: Grove Egg

### 15. Mosscap Bunny · `mosscap_bunny` · Common · Hop
Bunny with a red-spotted mushroom cap growing on its head. Shy. **Hero:** mushroom cap.
- **Prompt:** small bunny with soft moss-green fur, a red and white spotted mushroom cap growing on its head, long ears poking through, tiny leaf tail
- **Parts:** body, head, left ear, right ear, mushroom cap
- **Motion:** idle: nose twitch (head micro-bob), ears swivel. Follow: quick hops, cap wobbles.
- **FX:** none.

### 16. Bramblehog · `bramblehog` · Uncommon · Roll
Hedgehog whose quills are thorny brambles with berries. **Hero:** bramble ball.
- **Prompt:** round hedgehog, quills made of dark green thorny brambles with small red berries, soft brown face, tiny paws
- **Parts:** body and quills, head, feet
- **Motion:** idle: sniffs around, quills ruffle. Follow: curls into a ball and **rolls** (spin with distance travelled), uncurls when it stops.
- **FX:** a few leaves shed while rolling (≤ 4/s).

### 17. Petal Sprite · `petal_sprite` · Uncommon · Hover
Tiny flower fairy with petal wings and a petal skirt. Giggly. **Hero:** petal wings.
- **Prompt:** tiny flower fairy creature, pale green body, four translucent pink petal wings, skirt of petals, flower bud head with a sweet face
- **Parts:** body, head, left wings, right wings, petal skirt
- **Motion:** idle: twirls, skirt sways. Follow: quick fluttery darting flight.
- **FX:** soft pollen motes (≤ 5/s).

### 18. Glimmerwood Fawn · `glimmerwood_fawn` · Rare · Bound
Fawn whose budding antlers are little branches hung with glowing fruit. **Hero:** fruit-lantern antlers.
- **Prompt:** delicate fawn, warm brown fur with white spots, small antlers shaped like branches with glowing golden fruit hanging from them, big gentle eyes
- **Parts:** body and legs, head, antlers, left ear, right ear, tail
- **Props:** 1 firefly orb that circles it.
- **Motion:** idle: grazes (head dips), ears flick. Follow: light springing bound.
- **FX:** firefly motes (≤ 10/s), short golden trail.

### 19. Runebark Owl · `runebark_owl` · Epic · Hover
Owl with a mossy cloak and a carved bark mask etched with glowing runes. Wise. **Hero:** rune mask.
- **Prompt:** owl, mossy green feather cloak, carved wooden bark mask over its face with glowing green rune carvings, large round eyes behind the mask, talons
- **Parts:** body, head, left wing, right wing, mask, talons, tail feathers
- **Props:** 3 floating rune stones orbit it.
- **Motion:** idle: perched hover, slow blinks, head tilts. Follow: silent swooping flight.
- **Signature:** Owl Turn. Head swivels a full 180° to look at the player, the runes flash, and it swivels back.
- **FX:** rune-glow light, leaf trail, rune flash particles.

### 20. Elderhorn Spirit · `elderhorn_spirit` · Legendary · Bound (floating)
Translucent forest-spirit elk whose enormous antlers hold drifting spirit lights. Ancient. **Hero:** giant antlers.
- **Prompt:** ghostly forest spirit elk, translucent pale green body, enormous branching antlers with small glowing spirit lights caught in them, flowing mossy beard
- **Parts:** body and legs, head, antlers, beard, tail
- **2nd gen:** `ring of small white flowers and leaves, floating wreath` → wreath hovering under its hooves.
- **Motion:** idle: stands proud, antler lights drift. Follow: walks on air with slow strides, hooves never quite touching the ground.
- **Signature:** Bloom. Antlers burst into blossoms (petal emitters) and a ring of flowers ripples out on the ground.
- **FX:** body slightly transparent, spirit motes, flower particles at hoofsteps, a Beam of light between antler tips.

### 21. Worldtree Tortoise · `worldtree_tortoise` · Mythic · Waddle
Ancient tortoise carrying a tiny glowing world-tree on its shell, with floating islands circling. **Hero:** tree on its shell.
- **Prompt:** ancient tortoise, stone-grey wrinkled skin, mossy shell with a small glowing magical tree growing from the top, roots wrapping the shell
- **Parts:** body and legs, head, shell, tree, tail
- **2nd gen:** `tiny floating island with grass and a waterfall` (none) → 3 copies orbit the tree.
- **Motion:** idle: slow blink, tree sways. Follow: steady waddle, islands bob.
- **Signature (transformation):** Season Turn. The tree cycles through spring blossom, autumn gold and winter frost (leaf emitter colour and tree tint change in sequence), then returns to summer.
- **FX:** leaf fall, two lights, waterfall mist from the islands.

## Egg 4: Frost Egg

### 22. Snowpuff Seal · `snowpuff_seal` · Common · Waddle
Fluffy white seal pup. Sleepy. **Hero:** puffball body.
- **Prompt:** fluffy round white seal pup, pale blue shading, big dark sleepy eyes, small flippers, little whiskers
- **Parts:** body, head, left flipper, right flipper, tail flippers
- **Motion:** idle: yawns (head tilt back), flipper pats. Follow: belly-slides with a wobble.
- **FX:** none.

### 23. Icicle Bat · `icicle_bat` · Uncommon · Hover
Bat with wings of frosted ice membrane. Mischievous. **Hero:** crystal wings.
- **Prompt:** small bat, dark blue fur, wings made of translucent frosted ice crystal membrane, icicle fangs, big ears
- **Parts:** body, head, left wing, right wing, ears
- **Motion:** idle: hangs upside-down in the air, swaying. Follow: erratic fluttering flight.
- **FX:** a few snowflakes from the wings (≤ 4/s).

### 24. Rimeback Ram · `rimeback_ram` · Rare · Bound
Ram with spiralling horns of clear ice and a frosted wool coat. Stubborn. **Hero:** ice horns.
- **Prompt:** sturdy ram, thick frosted white-blue wool, large spiralling horns made of clear blue ice, dark face, frost on its hooves
- **Parts:** body and legs, head, horns, wool coat, tail
- **Props:** 1 floating snowflake crystal.
- **Motion:** idle: paws the ground, shakes off frost. Follow: heavy bound with head down.
- **FX:** frost breath puffs, snow trail.

### 25. Prism Wyrmling · `prism_wyrmling` · Epic · Hover
Small wyvern made of faceted crystal, whose wings split light into rainbows. **Hero:** prism wings.
- **Prompt:** small wyvern made of faceted clear crystal, icy white and pale blue, prism-like crystal wings, gem eyes, crystal spikes along its back
- **Parts:** body, head, left wing, right wing, tail, back spikes
- **Props:** 2 floating prism shards.
- **Motion:** idle: hovering, wings refract (shimmer by tilting). Follow: darting flight.
- **Signature:** Refraction. Spreads its wings and casts a fan of rainbow light Beams onto the ground.
- **FX:** Glass material wings, sparkle emitters, light, rainbow Beams during the signature.

### 26. Aurora Mammoth · `aurora_mammoth` · Legendary · Bound (heavy)
Mammoth calf whose tusks trail ribbons of aurora light. Gentle giant. **Hero:** aurora ribbons.
- **Prompt:** baby woolly mammoth, shaggy deep blue and white fur, long curved tusks tipped with glowing green crystal, small ears, trunk
- **Parts:** body and legs, head, trunk, left tusk, right tusk, ears, tail
- **2nd gen:** `ornate silver and blue saddle blanket with hanging crystals` → draped on its back.
- **Motion:** idle: trunk curls and sways, ears fan. Follow: slow, heavy stride. The world seems to bounce with it.
- **Signature:** Aurora Call. Raises its trunk and trumpets, and aurora ribbons (Beams, green to purple) stream up into the sky.
- **FX:** aurora Beams from tusk tips (always on, gently waving), snow puffs at steps.

### 27. Hailstorm Griffin · `hailstorm_griffin` · Mythic · Hover
Griffin with ice-feathered wings that rides its own small storm cloud. **Hero:** storm cloud.
- **Prompt:** griffin, eagle front with silver-white ice feathers, lion back with pale grey fur, large wings with ice crystal feather tips, fierce golden eyes
- **Parts:** body, head, left wing, right wing, tail, front talons, back legs
- **2nd gen:** `small dark storm cloud` (none) → floats under it.
- **Motion:** idle: perched on the cloud, preening. Follow: powerful flight with the cloud trailing behind.
- **Signature (transformation):** Blizzard. Feathers frost over and glow (a wing overlay turns Neon), the cloud darkens and swells, hail and lightning (thin Beams) burst out, and then it clears.
- **FX:** snow from the cloud, two lights, lightning Beams during the signature.

### 28. Crystal Heart Golem · `crystal_heart_golem` · Secret · Glide
A creature made of floating crystal shards, held together by a beating crystal heart. **Hero:** the floating-shard body.
- **Prompt (gen A):** large glowing pink-violet crystal heart, faceted gem (none). **Gen B:** `crystal golem body pieces` with parts: head shard, chest shard, left arm shard, right arm shard, left leg shard, right leg shard, back spikes
- **Motion:** all pieces hover in formation around the heart with small independent drift. The heart "beats" (Motor offsets pulse outward). Follow: the formation glides, pieces lagging slightly behind each other.
- **Signature (unique mechanic):** Shatter & Reform. The shards rattle, burst out around the heart, circle it once together, then fly home and lock back into the golem shape.
- **FX:** heart PointLight pulsing, Beams linking the heart to each shard, sparkle.

## Egg 5: Arcade Egg

### 29. Pixel Pup · `pixel_pup` · Common · Bound + Stepped
An 8-bit dog straight out of a retro game. **Hero:** blocky voxel shape.
- **Prompt:** voxel 8-bit pixel art style dog, blocky cubes, bright retro colors, orange body, white muzzle, square eyes
- **Parts:** body and legs, head, ears, tail
- **Motion:** like Coalpup, but every transform snaps at 12 fps (Stepped).
- **FX:** none.

### 30. Coin Hopper · `coin_hopper` · Uncommon · Roll
A living arcade token with little legs and big eyes. **Hero:** coin body.
- **Prompt:** living gold arcade token coin creature, star engraved on the face, big cartoon eyes, tiny stubby legs and arms
- **Parts:** coin body, eyes, legs, arms
- **Motion:** idle: flips itself in the air and lands. Follow: rolls on its edge like a wheel.
- **FX:** a sparkle when it lands a flip.

### 31. Joystick Critter · `joystick_critter` · Rare · Hop
Creature shaped like an arcade joystick. Its ball top is the head, and it has buttons on its base. **Hero:** joystick body.
- **Prompt:** cute creature shaped like a red arcade joystick, ball top as its head with a face, black stick neck, square base body with colored arcade buttons, four tiny legs
- **Parts:** ball head, stick neck, base body, buttons, legs
- **Props:** 1 floating pixel heart.
- **Motion:** idle: wobbles as if being steered (neck tilts in 8 directions in turn), buttons press down. Follow: hops.
- **FX:** pixel particles (square sparkle), short neon trail.

### 32. Cartridge Crab · `cartridge_crab` · Rare · Scuttle
Crab whose shell is an old game cartridge. Its claws are a D-pad and A/B buttons. **Hero:** cartridge shell.
- **Prompt:** crab with a shell made of a retro grey game cartridge with a colorful label, one claw shaped like a D-pad, one claw shaped like round A and B buttons, eye stalks
- **Parts:** body, cartridge shell, left claw, right claw, legs, eye stalks
- **Motion:** idle: blows into its own cartridge (dust puff), clicks claws. Follow: sideways scuttle.
- **FX:** dust puff, pixel sparkle trail.

### 33. Claw Machine Octo · `claw_machine_octo` · Epic · Glide
Octopus whose head is a claw-machine glass dome with a tiny claw inside. **Hero:** glass dome head.
- **Prompt:** cute octopus with a clear glass dome head like a claw machine with a small metal claw and a plush toy inside, magenta tentacles with suction cups, neon trim
- **Parts:** dome head, claw, prize plush, tentacles left, tentacles right, base ring
- **Motion:** idle: tentacles curl in waves, claw sways inside. Follow: glides, tentacles trailing.
- **Signature:** Grab! The claw drops, grabs the plush, lifts it, and then drops it (of course) with a sad droop.
- **FX:** neon light, coin sparkles, Glass dome.

### 34. High Score Dragon · `high_score_dragon` · Legendary · Slither (airborne)
Dragon drawn in glowing vector lines like a classic arcade screen, with floating score digits. **Hero:** neon line body.
- **Prompt:** dragon made of glowing neon vector lines and dark glass panels, cyan and magenta outlines, retro arcade vector graphics style, segmented body
- **Parts:** head, segment 1, segment 2, segment 3, segment 4, tail, wings
- **2nd gen:** `glowing neon digital number digits` → 3–4 digit props floating above it.
- **Motion:** idle: coils, digits tick up. Follow: S-wave flight.
- **Signature:** New High Score. A digit burst, a "+1UP" style pixel firework, and a quick loop-de-loop.
- **FX:** Neon materials, segment Beams, pixel trail.

### 35. Glitch Phantom · `glitch_phantom` · Mythic · Glide
A cat-like spirit corrupted by a buggy game. It flickers and duplicates. **Hero:** glitch effect.
- **Prompt:** sleek cat creature made of corrupted digital data, black and electric green, pixelated broken edges, scanline pattern, glowing eyes
- **Parts:** body, head, tail, ears, legs
- **2nd gen:** `glitched pixel cube, broken data block` → 3 orbiting blocks.
- **Motion:** idle: parts jitter by small random offsets for 1–2 frames at a time. Faint red and blue offset copies (cloned transparent parts) flicker. Follow: teleport-steps (snaps forward in short jumps).
- **Signature (transformation):** Corrupt. It glitches into a floating cube form (cat parts collapse into the cube) and then back.
- **FX:** chromatic copies, square particles, two lights.

### 36. The Final Boss · `final_boss` · Secret · Bound (heavy)
Mini arcade boss: an armoured mech-beast. **Hero:** boss presence and its armour. (Health bar removed, owner feedback Oct 26 2026.)
- **Prompt (gen A):** armored arcade boss monster, heavy purple and gold armor plates, glowing red core in its chest, horned helmet, big clawed arms. Parts: body, head helmet, left arm, right arm, legs, chest core, back spikes.
- **Gen B:** `exposed glowing robot core frame` (inner form)
- **Motion:** idle: menacing breathing, core pulses. Follow: heavy stomping bound, a small screen-shake-like bob.
- **Signature (unique mechanic):** Phase 2. The armour rattles, bursts off and circles the exposed glowing core on energy arcs, then flies home and locks back on.
- **FX:** core light, steam vents, orbiting armour during phase 2.

## Egg 6: Circuit Egg

### 37. Bolt Bug · `bolt_bug` · Common · Scuttle
Little beetle robot with a spark-plug antenna. **Hero:** antenna spark.
- **Prompt:** tiny round robot beetle, glossy teal metal shell with rivets, single spark plug antenna, six thin legs, LED eyes
- **Parts:** shell body, head, antenna, legs
- **Motion:** idle: antenna sparks (tilt twitch). Follow: quick scuttle.
- **FX:** none.

### 38. Drone Pup · `drone_pup` · Uncommon · Hover
Puppy-faced quadcopter drone. **Hero:** four rotors.
- **Prompt:** cute robot puppy drone, white and orange plastic body, puppy face screen, floppy ear antennas, four small propeller rotors on arms
- **Parts:** body, face screen, rotor 1, rotor 2, rotor 3, rotor 4, ears
- **Motion:** rotors spin continuously (fast Y rotation). Idle: hovers with a tilt-wobble. Follow: tilts forward into the direction of travel.
- **FX:** one LED glow detail.

### 39. Synth Slime · `synth_slime` · Uncommon · Hop
A gel cube with equalizer bars bouncing inside it. **Hero:** equalizer bars.
- **Prompt:** translucent purple gel cube slime with a cute face, glowing neon equalizer bars inside its body, synthwave style
- **Parts:** gel body, face, equalizer bars
- **Motion:** idle: equalizer bars bounce up and down to a beat (offsets), the body jiggles. Follow: squishy hops in time with the beat.
- **FX:** gel body in Glass material, faint neon glow.

### 40. Mech Raptor · `mech_raptor` · Rare · Bound (walking)
Small robotic raptor with piston legs. This is the walk-cycle showcase. **Hero:** legs.
- **Prompt:** small robotic velociraptor, gunmetal and orange armor panels, exposed piston legs, glowing yellow visor eye, long segmented metal tail
- **Parts:** body, head, left leg, right leg, tail, arms
- **Props:** 1 hovering scanner orb.
- **Motion:** legs swing in an alternating **walk cycle** (thigh rotation) instead of bounding. Head stays level like a bird's. Tail balances.
- **FX:** visor glow, exhaust puffs, short trail.

### 41. Chrome Panther · `chrome_panther` · Epic · Bound
Sleek chrome panther with neon circuit lines and a holographic visor. **Hero:** circuit lines.
- **Prompt:** sleek panther with mirror chrome metal body, glowing magenta neon circuit lines, holographic cyan visor over its eyes, long tail
- **Parts:** body and legs, head, visor, tail, ears
- **Props:** 2 orbiting holo-cubes.
- **Motion:** idle: tail lash, visor flickers. Follow: low, fast prowling bound.
- **Signature:** Holo Scan. The visor projects a scanning beam that sweeps across the ground (a Beam fan rotating).
- **FX:** Metal material and reflectance, neon light, magenta trail.

### 42. Hyperdrive Hawk · `hyperdrive_hawk` · Legendary · Hover (jet flight)
Mech hawk with jet engines and afterburner trails. **Hero:** jet engines.
- **Prompt:** mechanical hawk, white and blue armor plating, two jet engines on its back, swept-back blade wings, golden visor eyes, sharp beak
- **Parts:** body, head, left wing, right wing, tail fan, jet engines
- **2nd gen:** `thin glowing energy wing blades` → extra wing blades that slide out when boosting.
- **Motion:** idle: hovering on jet thrust, small corrections. Follow: banking jet flight, wings swept back at speed.
- **Signature:** Boost. Energy blades extend and the afterburner flares, it dashes ahead in a quick loop, and returns.
- **FX:** afterburner flame emitters, two long trails, a Beam burst on the boost.

### 43. Mainframe Beetle · `mainframe_beetle` · Mythic · Scuttle (heavy)
Huge rhino beetle whose shell is a server rack, with data streams flowing over it. **Hero:** server-rack shell.
- **Prompt:** large rhino beetle, black shell made of server rack panels with blinking green status lights, big horn, glowing data cables, chrome legs
- **Parts:** body, shell left, shell right, horn, head, legs, wings
- **2nd gen:** `glowing green data cube` → orbiting data cubes.
- **Motion:** idle: status lights blink (Neon toggles), horn tilts. Follow: heavy scuttle.
- **Signature (transformation):** Overclock. The shell halves open (rotate apart), translucent wings unfold and buzz, data Beams spiral up, and then it closes again.
- **FX:** data Beams, two lights, green particles.

### 44. Quantum Core Wyrm · `quantum_core_wyrm` · Secret · Slither (airborne)
A wyrm made of holographic rings around a tiny singularity core. **Hero:** ring body.
- **Prompt (gen A):** sleek holographic wyrm head with glowing white eyes and fin crest, translucent cyan and violet. **Gen B:** `glowing holographic ring segment` (none) → cloned 8× as the body. **Gen C:** `small black singularity sphere with bright accretion ring`.
- **Motion:** the rings follow the head in a chain, each slightly rotated. The core floats inside the middle ring. Follow: smooth chain flight.
- **Signature (unique mechanic):** Phase Shift. It fades out (transparency) and reappears on the player's other side, with a bright ring-shaped flash at both points.
- **FX:** Beams linking the rings, core light, particles drawn into the core.

## Egg 7: Phantom Egg

### 45. Wisp Kit · `wisp_kit` · Common · Glide
A tiny kitten-shaped ghost wisp. **Hero:** wispy tail.
- **Prompt:** tiny ghost kitten, translucent pale lavender body, cat ears, body that fades into a wispy curled tail, big friendly eyes
- **Parts:** body, head, ears, tail wisp
- **Motion:** idle: curls its tail and blinks. Follow: floats after the player at a low height.
- **FX:** none (slight transparency only).

### 46. Lantern Imp · `lantern_imp` · Uncommon · Hover
Little imp carrying a swinging lantern with a ghost flame. **Hero:** lantern.
- **Prompt:** little imp, dark purple skin, tiny bat wings, pointy ears, mischievous grin, holding a small iron lantern with a green ghost flame
- **Parts:** body, head, left wing, right wing, lantern, tail
- **Motion:** idle: swings the lantern on a pendulum. Follow: flaps, the lantern lags behind.
- **FX:** a ghost-flame emitter in the lantern.

### 47. Bone Raven · `bone_raven` · Rare · Hover
Skeletal raven wrapped in violet ghost fire. **Hero:** ribcage glow.
- **Prompt:** skeletal raven, bone-white skull and beak, black tattered feather wings, violet ghost fire glowing inside its ribcage
- **Parts:** body, skull head, left wing, right wing, tail feathers, talons
- **Props:** 1 floating violet soul wisp.
- **Motion:** idle: head tilts, skull jaw clacks. Follow: ragged flapping flight.
- **FX:** violet ghost-fire emitter (≤ 10/s), feather trail.

### 48. Haunted Armor Hound · `haunted_armor_hound` · Epic · Bound
Empty suit of knight armour shaped like a hound, filled with blue ghost flame. **Hero:** helmet visor glow.
- **Prompt:** hound made of empty dark steel knight armor plates, blue ghost flame glowing through the gaps, knight helmet head with a glowing visor slit, plume
- **Parts:** body and legs, helmet head, plume, tail, armor plates
- **Props:** 2 floating ghost-flame orbs.
- **Motion:** idle: armour plates rattle (small offsets), plume sways. Follow: clanking bound.
- **Signature:** Lost My Head. The helmet pops off, floats, spins, and clunks back on, while a ghost flame flares from the empty neck.
- **FX:** blue flame emitters, light, Metal material.

### 49. Specter Jelly · `specter_jelly` · Epic · Glide
Translucent ghost jellyfish with long tentacles and drifting soul orbs. **Hero:** tentacles.
- **Prompt:** ghost jellyfish, translucent white and teal bell with a glowing inner pattern, long flowing ribbon tentacles
- **Parts:** bell, inner glow, tentacle 1, tentacle 2, tentacle 3, tentacle 4
- **Props:** 3 soul orbs drift around it.
- **Motion:** idle: bell pulses (offset up/down), tentacles wave with delays. Follow: pulse-swims.
- **Signature:** Pulse Dash. One big contraction that propels it forward, releasing a ring of light.
- **FX:** Glass or transparent bell, a Beam ring on the dash.

### 50. Eclipse Nightmare · `eclipse_nightmare` · Legendary · Bound (gallop)
Shadow horse with a mane and tail of smoke and hooves of violet fire. **Hero:** smoke mane.
- **Prompt:** nightmare horse, jet black body with subtle purple sheen, mane and tail made of flowing dark smoke, violet fire on its hooves, glowing white eyes
- **Parts:** body and legs, head, mane, tail, hooves
- **2nd gen:** `black eclipse halo ring with bright corona` → floats behind its head.
- **Motion:** idle: stamps a hoof, mane drifts like smoke. Follow: true gallop rhythm (stronger pitch, longer bound).
- **Signature:** Eclipse. Rears up and the halo flares into a full eclipse corona, lighting dims around it (a dark particle burst).
- **FX:** smoke emitters on the mane and tail, violet hoof fire, a Beam corona.

### 51. Soulbinder Chimera · `soulbinder_chimera` · Mythic · Bound
Spirit chimera with lion, goat and serpent heads, each burning with a different flame colour. **Hero:** three heads.
- **Prompt:** spirit chimera, translucent dark violet lion body, three heads: a lion head, a goat head and a serpent tail head, each glowing with different colored spirit fire (violet, teal, crimson)
- **Parts:** body and legs, lion head, goat head, serpent tail, mane, wings
- **2nd gen:** `chain of floating spirit runes` → a rune ring.
- **Motion:** idle: each head looks around independently. Follow: prowling bound, serpent tail weaving.
- **Signature (transformation):** Soul Rotation. The heads take turns "awakening": each blazes with its colour (lights and emitters swap) and the body's flame colour follows, cycling through all three.
- **FX:** three-colour flames, two lights, rune Beams.

### 52. The Void Cat · `void_cat` · Secret · Bound
A cat-shaped hole in reality: pure black with a starfield inside and only its eyes showing. **Hero:** the void silhouette.
- **Prompt:** cat silhouette made of pure black void with a faint starfield inside it, glowing violet rim outline, two bright white eyes, long tail
- **Parts:** body and legs, head, tail, ears, eyes
- **Motion:** idle: sits, tail curls, blinks slowly. Follow: silent, smooth bound.
- **Signature (unique mechanic):** Event Horizon. Nearby particles (its own emitters placed around it) get pulled **inward** into its body, the outline flares, and the eyes widen.
- **FX:** body Neon black or very dark, starfield particles inside, inward-pull emitters (negative speed / attraction), violet rim Highlight.

## Egg 8: Celestial Egg

### 53. Starling Chick · `starling_chick` · Common · Hover
A round chick shaped like a five-pointed star. **Hero:** star shape.
- **Prompt:** round fluffy chick shaped like a five pointed star, pale yellow with tiny white sparkle spots, little wings, small beak
- **Parts:** body, left wing, right wing, beak and eyes
- **Motion:** idle: bobs and spins slowly. Follow: flutters.
- **FX:** none.

### 54. Satellite Snail · `satellite_snail` · Uncommon · Waddle
Snail whose shell is a satellite dish that beeps. **Hero:** dish shell.
- **Prompt:** cute snail with a white satellite dish shell with solar panels and a blinking antenna, soft lavender body, eye stalks
- **Parts:** body, shell dish, antenna, eye stalks
- **Motion:** idle: dish swivels and scans the sky. Follow: slow glide. It's always slightly behind, then catches up with a small zoom.
- **FX:** blinking antenna light (Neon toggle).

### 55. Constellation Cub · `constellation_cub` · Rare · Bound
Lion cub with a star-map pattern whose stars are joined by glowing lines. **Hero:** constellation pattern.
- **Prompt:** lion cub with deep navy blue fur covered in a constellation star-map pattern, small golden mane tuft, starry eyes
- **Parts:** body and legs, head, mane tuft, tail
- **Props:** 1 tiny orbiting star.
- **Motion:** idle: pounces at the orbiting star. Follow: playful bound.
- **FX:** thin Beams joining 4–5 "star" attachments on its body (its constellation), star trail.

### 56. Celestial Koi · `celestial_koi` · Epic · Glide
Floating koi with nebula fins, orbited by two little moons. **Hero:** nebula fins.
- **Prompt:** elegant koi fish, white and gold scales, long flowing translucent fins with a purple and blue nebula pattern, long whiskers
- **Parts:** body, head, tail fin, left fin, right fin, dorsal fin
- **Props:** 2 small moons orbit.
- **Motion:** idle: slow swim in place, fins ripple. Follow: weaving glide.
- **Signature:** Portal Leap. A glowing ring opens ahead, it leaps through it, and another ring catches it.
- **FX:** star-dust trail, moon glow, ring Beams on the leap.

### 57. Starforge Pegasus · `starforge_pegasus` · Legendary · Hover
Pegasus with wings of molten-gold plate feathers and a comet tail. **Hero:** gold plate wings.
- **Prompt:** pegasus, pearl white body, wings made of overlapping molten gold metal plate feathers, mane and tail of blue star fire, golden hooves
- **Parts:** body and legs, head, left wing, right wing, mane, tail
- **2nd gen:** `small blazing comet` (none) → rides in its wake.
- **Motion:** idle: hovering with slow wing beats, mane flickers. Follow: galloping flight.
- **Signature:** Comet Dive. Wings fold, it dives in an arc with a comet trail, and pulls up beside the player.
- **FX:** star-fire mane emitters, a long comet trail, gold light.

### 58. Ringed Skywhale · `ringed_skywhale` · Legendary · Glide
Whale encircled by a slowly turning planetary ring, with tiny moons. **Hero:** planetary ring.
- **Prompt:** gentle sky whale, dusky pink and orange planet-like banded skin, small fins, kind eyes
- **Parts:** body, head, tail fluke, left fin, right fin
- **2nd gen:** `flat planetary ring of ice and dust, like Saturn's rings` → an angled ring around it, rotating slowly.
- **Motion:** idle: slow roll, the ring turns. Follow: drifts majestically.
- **Signature:** Moonrise. Three tiny moons rise from the ring and orbit once before sinking back.
- **FX:** ring sparkle, soft light, a dust Beam from the fluke.

### 59. Supernova Seraph · `supernova_seraph` · Mythic · Hover
Winged lion with six wings of light and a sun halo. **Hero:** six wings.
- **Prompt:** majestic lion with radiant white and gold fur, six feathered wings made of light, glowing sun halo behind its head, serene face
- **Parts:** body and legs, head, mane, wings upper, wings middle, wings lower, tail
- **2nd gen:** `ornate radiant sun halo ring with spokes` → behind its head.
- **Motion:** idle: the three wing pairs beat out of phase, halo turns. Follow: stately flight.
- **Signature (transformation):** Supernova. Wings flare fully open, the body brightens to Neon white-gold, a radiant burst (light-ray Beams and an expanding sphere of particles) goes off, and it fades back.
- **FX:** two lights, light Beams, feather-of-light particles.

### 60. Starloom Weaver · `starloom_weaver` · Secret · Scuttle (floating)
Cute celestial jumping-spider weaver whose abdomen holds a galaxy. It weaves constellations as it moves. **Hero:** constellation threads.
- **Prompt (gen A):** cute celestial jumping spider, round fuzzy dark blue body, big shiny eyes, abdomen like a swirling galaxy with stars, eight slender legs with golden tips. Parts: head, abdomen, legs left, legs right, fangs.
- **Gen B:** `small bright floating star point` (none) → 6 star props.
- **Motion:** idle: tilts its head curiously, legs tap. Follow: floats just above the ground, legs paddling.
- **Signature (unique mechanic):** Weave. Places its star props in the air around the player and joins them with glowing threads (Beams) into a constellation shape that hangs there for a few seconds, then unravels.
- **FX:** galaxy particles in the abdomen, thread Beams, two lights.

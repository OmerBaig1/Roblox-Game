# Pet Bible: the standard every pet is built to

The reference is **Cinder Lynx** (`ServerStorage.PetLab.Pets.CinderLynx`). When this document and the Lynx disagree, ask.

---

## 1. Art direction: "Sleek Mythic, segmented toon"

The collection replaces the game's chibi pets entirely. Pets have the proportions of the reference art (sleek, cool,
mythic creatures, plus arcade and tech creatures) and are built from **separate generated mesh pieces**. That suits
this pipeline: separate pieces animate without any Blender work.

Six rules every pet follows:

1. **One hero feature.** Each pet exaggerates exactly one thing: ears, wingspan, antlers, tail, a shell, a lure. It's what a player recognises at 30 studs.
2. **Light is earned.** Bodies stay deep, saturated or matte. Glow lives only on tips, markings, eyes, orbs and cores. The amount of glowing surface goes up with tier.
3. **One opposing accent.** A warm pet gets a cool accent (Cinder Lynx: plum + ember, with cyan crystals). A cool pet gets gold or warm. At most three colour families per pet.
4. **Pattern, not flat colour.** Every generator prompt names a surface motif: glyphs, swirls, scales, circuitry, star-maps, pixels, wood grain, coral.
5. **Things that float.** Orbs, shards, rings, lanterns, leaves, coins. Detached pieces animate cheaply and are the main way higher tiers look rarer.
6. **Dark outline.** An outline from the Highlight object (see §6 for when it's allowed). Ink colour `#14111F`.

House palette anchors (use them in prompts and effects): Ink `#14111F` · Dusk `#5B3E5E` · Ember `#FF6A2B` ·
Celestial `#2747C9` · Accent gold `#F2C14E` · Crystal `#7FE3FF`.

**House style suffix**: append to every mesh generator prompt:
> `, stylized game-ready creature, sleek fantasy proportions, clean readable toon shapes, deep saturated base colors with glowing accent markings, distinct silhouette, facing forward, no text, no base or pedestal`

---

## 2. Rarity tiers: visual standards

Seven tiers, matching `PetData.RARITIES`. The step from one tier to the next must be visible at a glance, but Commons should still look good: clean shapes, a face with personality, and at least one moving part.

| | Common | Uncommon | Rare | Epic | Legendary | Mythic | Secret |
|---|---|---|---|---|---|---|---|
| Target height (studs) | 2.4 | 2.6 | 2.9 | 3.3 | 3.8 | 4.3 | 4.8 |
| Mesh generations | 1 | 1 | 1 | 1 + props | 2 | 2–3 | 2–3 |
| Generated parts | 3–5 | 4–6 | 5–7 | 6–8 | 8 + accessory set | up to ~14 | up to ~16 |
| Moving joints | 1–2 | 2–3 | 3–4 | 5–8 | 7–10 | 8–12 | 10–14 |
| Floating props | 0 | 0–1 | 1 | 1–3 | 2–4 | 3–6 | any |
| Glow | eyes only | eyes + 1 marking | markings | markings + one hot spot | several hot spots | large glowing areas | whole-body treatment |
| Particle rate (total/s) | 0 | ≤ 5 | ≤ 12 | ≤ 25 | ≤ 40 | ≤ 60 | ≤ 80 |
| Lights | 0 | 0 | 0 | 1 | 1–2 | 2 | 2 |
| Trail / Beam | – | – | trail while moving | trail | trail + 1 Beam | Beams | Beams |
| Signature move | – | – | – | every 7–12 s idle | + a unique follow style | + a transformation | + a mechanic no other pet has |
| Hatch reveal | default | default | default | short sting | custom colour burst | custom sequence | full-screen moment |

What separates each tier from the one below:

- **Uncommon > Common:** a second moving feature, and one small glowing accent with a tiny ambient emitter.
- **Rare > Uncommon:** glowing markings, a first floating prop, and a trail while moving.
- **Epic > Rare:** a signature move it performs on its own when idle, a light source, and several floating pieces.
- **Legendary > Epic:** a second generation (accessory set: halo, rings, armour, banners), a follow style of its own
  (flies, surfs, glides instead of bounding), and a Beam effect (ribbons, rings, light shafts).
- **Mythic > Legendary:** a **transformation**, a visible state change during the signature move (mane ignites, shell
  opens, glitches into another form), plus large glowing areas.
- **Secret > Mythic:** a mechanic unique to that one pet (assembles from shards, sheds and re-locks its armour, bends nearby
  particles inward). No overhead UI on pets (owner feedback, Oct 26 2026: the boss health bar was removed), and it's the biggest.

Never make a tier "rarer" just by adding particles. Each step adds a new kind of thing.

**Rarity presence (owner feedback, Oct 25 2026):** Legendary and above must look obviously high-rarity. Every such pet
gets `PetRigKit.rarity(pet)`: the outline in the tier colour instead of ink (Legendary gold, Mythic rose, Secret cyan),
a `RarityAura` of glowing motes around the body, and a `RarityGlow` light when the tier's light budget has room.
The aura is the pet's own element finished in the tier colour (`PetRigKit.AURAS`: embers rise off the Drake, snow
falls through the Mammoth's, glints are drawn into the Golem's heart), never the same motes on two pets. Add the new
pet's entry there before calling `rarity`. Secrets also get `RarityRing`, a ring of light pulsing over the ground.
On top of that, push glow, floating props and effects toward the top of the tier's budget rather than the minimum.

---

## 3. Body plans and follow modes

`PetConfigs[name].Mode` picks the follow style. PetAnimator should grow these modes as reusable code (Cinder Lynx uses `Bound`):

| Mode | Used for | Movement |
|---|---|---|
| `Bound` | quadrupeds | hop arc tied to speed, pitch, lean into turns (done, see Lynx) |
| `Hover` | birds, bats, insects, drones | floats 1.5–2.5 studs up, wings flap faster when moving, banks into turns |
| `Glide` | fish, rays, whales, jellies, ghosts | floats, slow sine bob, body pitches with climb, fins/tentacles trail |
| `Slither` | serpents, eels, dragons with segments | segment chain: each segment follows the one ahead with delayed sine yaw |
| `Scuttle` | crabs, beetles, spiders | sideways or quick multi-step jitter, legs/claws alternate |
| `Roll` | hedgehogs, coin, orb creatures | body spins around X with distance travelled, uncurls when idle |
| `Hop` | blobs, toads, small round pets | discrete hops with squash-like pitch, pause between hops |
| `Waddle` | seals, penguins, snails | side-to-side roll, slow |
| `Stepped` | pixel/arcade pets | any mode, but transforms snap at 12 fps for an 8-bit feel |

Facing: pets face their travel direction while moving and the player's facing when idle (see PetLabClient).

---

## 4. Rig contract: every pet model looks like this

```
<PetName> (Model)                        -- PascalCase, matches ROSTER name without spaces; PrimaryPart = Root
  Attributes: PetId = "snake_case_id", Tier = 1..7, Mode = "Bound"|...
  ModelStreamingMode = Persistent        -- (lab only; required with StreamingEnabled)
  Root (Part, 0.5³, Transparency 1, Anchored, no collide/query/touch)   -- at the feet centre (fliers: at ground below them)
  Body (MeshPart)  <- Motor6D "Body"  (Part0 Root)
  Head (MeshPart)  <- Motor6D "Neck"  (Part0 Body)
  ...each other part is a MeshPart named by role (EarL, EarR, WingL, WingR, Tail, Tail1..TailN, Jaw, Crown, Shard1..N...)
  Outline (Highlight)  -- FillTransparency 1, OutlineColor #14111F, DepthMode Occluded
```

- **Orientation:** the pet faces **−Z**, with +X to its right and +Y up. The pivot is at Root with an identity rotation.
- **Joints:** Motor6D, parented to Part1, named after the joint (`Neck`, `EarL`, `WingR`, `Tail2`...). The joint frame sits at the anatomical pivot (wing root, neck base, tail base) with **pet-space axes** (identity rotation). Build it as:
  `m.C0 = part0.CFrame:Inverse() * CFrame.new(jointWorldPos)` and `m.C1 = part1.CFrame:Inverse() * CFrame.new(jointWorldPos)`.
  Floating props: `C1 = identity` (the prop sits at the joint origin, and Transform places it).
- **Every non-Root part:** Anchored false, CanCollide/CanQuery/CanTouch false, Massless true. CastShadow true for body parts, false for props and FX pieces.
- **Effect attachments**, named by role: `TailTip`, `AuraCenter`, `TrailA`/`TrailB`, `Mouth`, `Core`, `FootL`/`FootR`...
- **Emitter, light and trail names** are what PetAnimator looks up (`Embers`, `TailGlow`, `EmberTrail`...). Keep them meaningful and unique within the pet.
- **No Animation assets, ever.** All motion is code through `Motor6D.Transform` (the place is owned by a friend's account, so uploaded animations may not play there).
- **No welds or physics.** Only the Root moves the pet. Never PivotTo a rigged pet each frame; set `Root.CFrame`.

---

## 5. Build recipe for one pet

1. **Generate.** Use `generate_mesh` with `segmentation = "explicit"`, `partNames` = the ROSTER part list (≤ 8 per call),
   prompt = ROSTER prompt + house style suffix, `maxTriangles` = tier budget (§6), and `size` roughly the pet's proportions.
   Use `async: true` and run the next pet's generation while rigging the current one. Legendary and above get a second call for their accessory set (`segmentation: "explicit"` with the accessory part names, or `"none"` for a single prop that you then clone).
2. **Collect.** The result lands in Workspace with a long prompt name, plus Assistant tags. Move it into `ServerStorage.PetLab.RawGenerations` as `<PetName>_raw` (keep raws for regeneration comparisons). Part names come back wrapped in quotes and brackets (`"head"_geom`): match on the substring and rename to contract names.
3. **Inspect before rigging.** Screenshot it front and 3/4 on the lab turntable. Reject and regenerate (max 3 tries) if parts are merged that must move, the face is broken, the palette is off, or it looks like another pet in the roster.
4. **Orient and scale.** Generated models face a random direction. Compute heading from the Body to the Head centre (or the tail-to-head axis), rotate about Y so the head points −Z, recentre so the feet centre is at the origin, and `ScaleTo` the target tier height. Re-check the bounding box: width should be on X and length on Z.
5. **Rig.** Add Root, the Motor6Ds at measured pivots (read each part's position and size and put the pivot at the base edge), props, and attachments. The Lynx build script pattern (C0/C1 from world joint positions) works for everything.
6. **Effects.** To tier budget, using built-in textures (`rbxasset://textures/particles/sparkles_main.dds`, `fire_main.dds`, `smoke_main.dds`) or ones uploaded later. Use `LightEmission` 1 for glow. Emitters go on named attachments. Add a Trail on two attachments for Rare and above, and Beams for Legendary and above.
7. **Config.** Add the `PetConfigs` entry: `Id, Tier, Mode`, per-joint motion params, `Orbit`, `Special`. If the pet needs a new mode or signature move, add it to PetAnimator as a **named, reusable function** (`Modes.Hover`, `Specials.BarrelRoll`), not an `if name == "X"`.
8. **Place it.** Put the pet in `ServerStorage.PetLab.Pets`, standing on its tier's gallery row (`Stage.GalleryPads.Row_<Tier>`), spaced 6 studs apart. Set ModelStreamingMode to Persistent.
9. **Test in a playtest** (stop editing first): P to go to the lab, check idle and the signature move on the gallery, then use the follower (L) on the real map. Walk, sprint, turn hard, stop, jump, and stand on the treadmill. Check the Output for errors.
10. **QC** (§7) and **update STATUS.md**.

**Lab improvements to make in batch 1** (the lab currently only handles one pet):
- PetLabClient: animate **every** pet in `PetLab.Pets` in place on its row (don't spin them all around one turntable).
  `L` cycles the follower through the pets in roster order (show its name in the hint). `K` puts the selected pet on the turntable.
- Add a small distance-based LOD to the animator call (see §6) and use it in the lab too, so it gets tested.

---

## 6. Performance budgets

Each client animates every visible player's pets: up to 3 pets × every player nearby. Budgets per pet:

| | Common | Uncommon | Rare | Epic | Legendary | Mythic | Secret |
|---|---|---|---|---|---|---|---|
| Triangles (all generations) | 3k | 4k | 5k | 8k | 10k | 14k | 18k |
| Parts (incl. props) | ≤ 6 | ≤ 7 | ≤ 9 | ≤ 12 | ≤ 16 | ≤ 20 | ≤ 24 |

- **LOD:** under 60 studs, everything runs. From 60 to 140 studs, skip the animator every other frame, disable trails and beams, and cut particle rates in half. Past 140 studs, no animator and no emitters (the root still follows). Past 250 studs, the pet isn't drawn at all (the existing cull).
- **Outline:** Roblox renders only about 31 Highlights at once. Enable `Outline` only on the local player's own pets and the nearest ~12 others, and toggle it from the follow loop.
- **No per-frame instance creation,** no `:GetDescendants()` in Step, no `FindFirstChild` in hot loops: cache everything in `PetAnimator.new`.
- **Lights:** `Shadows = false` always.

---

## 7. QC checklist (all must pass before G4 counts)

- [ ] Silhouette reads as its concept at 30 studs, from front, side and back, and doesn't resemble another roster pet.
- [ ] Its hero feature is the most visible thing about it.
- [ ] Palette follows the ROSTER, with at most 3 colour families and glow only where the tier allows.
- [ ] Faces −Z, feet on the ground (fliers hover at the right height), nothing floating off the body by accident.
- [ ] Every listed moving part moves, with nothing popping or detaching and no joint spinning around the wrong pivot.
- [ ] Idle reads as personality, not just bobbing. Follow reads as the right Mode at walk and sprint speeds, with no jitter, no clipping into the player, and no sliding when stopped.
- [ ] The signature move (Epic+) fires on its own and returns cleanly to idle, and it's interrupted correctly if the player starts moving.
- [ ] Effects match the ROSTER and stay inside the tier budget (count emitter `Rate`s).
- [ ] Next to the other pets of its tier on the gallery row, it looks the same size and quality, clearly better than the tier below and clearly short of the tier above.
- [ ] Triangles and parts are inside budget, and the Output shows no errors or warnings from pet code.

---

## 8. Known gotchas (found while building Cinder Lynx)

- Generated models face a random direction, and the parts carry the rotation. Fix the heading before rigging.
- `Motor6D.Transform` only shows while the game is simulating (playtest), not in edit mode.
- The place uses **StreamingEnabled**. Lab models need `ModelStreamingMode = Persistent`, or the client sees half a pet.
- The game's fence check pulls players back inside the map. The lab trip is server-side (`PetLabTravel`) and marks
  the player `InPetLab` so the fence check skips them. Keep using it, and never teleport the character from the client.
- ViewportFrames don't run joints. Any UI preview of a rigged pet needs a `WorldModel` inside the ViewportFrame.
- An unrelated warning about `rbxassetid://203785492` appears in every playtest. It's pre-existing and not pet code.
- Mesh generations are published assets on whoever's account runs Studio. They're fine to use in the place.

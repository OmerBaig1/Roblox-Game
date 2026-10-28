# Integration: replacing the 105 old pets with the 60 premium pets

Do this only after all 60 pets reach G4 in STATUS.md. Work phase by phase. Back up every script you touch into
`ServerStorage.Backups/Before_<date>_PremiumPets` first, and stop, playtest and report after each phase.

## What exists today (read these before changing anything)

| Script | Role | What changes |
|---|---|---|
| `ReplicatedStorage.PetData` | catalog: 15 eggs × 7 pets (one per rarity), keys `"egg-slot"`, odds, Boost | new 8-egg catalog with pools and stable ids |
| `ReplicatedStorage.PetModels` | builds chibi pets from spheres at runtime, `addEffects`, `egg()` | `build()` clones authored models; `egg()` stays |
| `ServerScriptService.StealAGame.Pets` | hatch roll, Cash, equip, save and load, Hatchery stand | roll from pools, **save migration** |
| `StarterPlayerScripts.PetsUI` | shop, hatch reveal, bag, follow loop (`RenderStepped`, `PivotTo`) | follow loop drives PetAnimator; UI previews |
| `ServerStorage.PetLab` + `ServerScriptService.PetLabDev` | Studio-only lab | becomes the QA gallery, reading from PetAssets |

Before writing code, grep every script for uses of `PetData.PETS`, `PetData.EGGS`, `egg.Pets[`, `pet.B`, `pet.C`, `pet.R`, `pet.N`,
`pet.Key`, `.Boost`, `PetModels.build` and `addEffects`, and list them. Keep every public field that other code uses
working (`N`, `R`, `Egg`, `Key`, `Boost`, `RARITIES`, `EQUIP_MAX`, `MAX_PETS`, `HATCH_MANY`, `oddsText`).

---

## Progress

- Oct 26 2026: migration groundwork done and tested before any live change. `ReplicatedStorage.PetSystem.Catalog`
  (new 8-egg catalog), `ServerScriptService.StealAGame.PetMigration` (migrateKey, migrateSave) and
  `ServerStorage.UnitTest.Cases.PetMigration_Test` (18 tests, all pass). Nothing live requires them yet.
  Open question for the owner: old Secrets from eggs 1-5 become the Crystal Heart Golem (boost 28-71% -> 112%), per the
  rule below. Next: Phase 1.
- Oct 26 2026: the owner said wiping everyone's pets is fine (the game isn't published yet). Phase 3's migration is
  no longer needed and the Secret question is moot. Old keys will simply be dropped by `Pets.load`.
- Oct 26 2026: **Phase 1 done.** `PetAnimator` and `PetConfigs` moved to `ReplicatedStorage.PetSystem`. The 60 models are in
  `ReplicatedStorage.PetAssets` (streaming overrides removed). `PetLabDev` clones them into the lab gallery at playtest
  start (Persistent there). New `PetSystem.PetFx.outlines` keeps at most 24 Outlines lit (own pets first, then nearest);
  the lab uses it. LOD stays inside `PetAnimator:Step`. Backups: `ServerStorage.Backups.Before_Oct26_PremiumPets`.
  Tests 20/20 (new `PetFx_Test`). Playtest: 60 gallery pets, all animate in the lab, 24 outlines lit. Next: Phase 2.
- Oct 26 2026: **Phase 2 done (Phase 3 dropped).** `PetData` is now the 8-egg catalog (the old `PetSystem.Catalog`
  moved into it). `PetMigration` and its tests are deleted. The server rolls with `PetData.roll`. The shop's "up to" uses
  `egg.Best`, and the info page shows each pool pet with its share of the tier odds. Part of Phase 4 had to come
  forward so nothing crashes: `PetModels.build` clones `PetAssets` (placeholder plus one warn if missing), the old
  builder is kept as `buildChibi` until Phase 6, and the followers no longer call `addEffects`. Followers are still
  static, PET_SCALE 0.75, with no hover by Mode (Phase 4). Backups are in `Before_Oct26_PremiumPets`. Tests 5/5
  (new `PetData_Test`). Playtest: shop shows 8 eggs, info page OK, 3 followers spawn as premium models, no errors.
  20k rolls of egg 8 match the shown odds. No purchase tested (Studio saves to the live DataStore).
- Oct 26 2026: **Phase 3.5 (owner request): egg shop and hatching overhaul.**
  - Eggs: `ServerStorage.PetLab.Code.EggForge` builds the 8 eggs into `ReplicatedStorage.EggAssets` with CSG. Each has
    a hollow shell, a narrower top, a zigzag seam split into Top and Bottom pieces, hidden seam cracks, a light inside,
    and themed ornaments that grow more elaborate egg by egg. `PetModels.egg` clones them; the old procedural egg is
    the fallback.
  - Shop: `PetsUI.Hatchery` with `ShopKit` replaces the old shop. It has a showcase with a 3D stand, the pets each egg
    can hatch with their odds, a row of every egg with drawn chevrons, and buttons that grey out with a "need $X" toast
    when you can't afford them. One UIScale fits it to the screen.
  - Hatching: each egg's own sequence in `PetsUI.HatchStyles`, played on `PetSystem.EggRig` with a 2D `Particles` layer.
  - World hatchery: nests got rims lit in each egg's colour.
  - Backups are in `Before_Oct26_EggShop`. In Studio only, `PlayerGui.HatchUI.HatchPreview` plays a hatch with made-up results.
  - Tested: every egg's single hatch, 10-egg grids, Skip, close-up, spam, and the not-enough-cash path; 50+ fps in a
    10-egg hatch. Not tested: a real purchase, and real phone screens.
- Oct 27 2026: **Phase 4 done.** In the PetsUI follow loop, every follower runs its own `PetAnimator`. The loop moves
  `Root.CFrame` and turns pets the way PetLabClient does. Hovering comes from each pet's Mode, so `FLYERS` is gone.
  `PET_SCALE` is gone too, so pets are now Lab size, about a third bigger than before. Mythic and Secret slots sit 1 stud
  further out. Outlines come from `PetFx.outlines`, which keeps your own pets first. The 250-stud cull and the teleport
  snap stay. Backup: `Before_Oct27_PetFollow`. Cost: about 0.01 ms per pet per frame on average, 0.045 ms for the
  heaviest (Supernova Seraph). Playtest: 3 followers animate (22 of 26 joints moving), and there are no new errors.
- Oct 27 2026: **Phase 5 done.** `petView` (Hatchery) and `viewport` (PetsUI) take `Animate`: the model goes in a
  `WorldModel` and idles with its PetAnimator, and the sway moves `Root.CFrame` instead of calling PivotTo. Three pictures
  animate: the single-hatch reveal, the batch close-up and the selected My Pets pet. Grid cards and 10-egg grid
  cells stay still. On a Mythic or Secret reveal, `Special = 0.5` starts the signature move half a second after the pet
  appears. The tier effects (ring, flash, blackout, SECRET! banner) were already in `TIERS` and are unchanged. Particle
  bursts from specials don't show in ViewportFrames, which is a Roblox limit. Backup: `Before_Oct27_PetPreviews`. Playtest:
  the Quantum Core Wyrm and Supernova Seraph reveals animate (11 of 13 joints), the Seraph's move plays, the My Pets
  Starloom Weaver animates, and there are no new errors. Not tested: the batch close-up by clicking.
- Oct 27 2026: **Phase 6 done (with limits).**
  - Stress test: the MCP can't start a 4-player local server, so it was simulated as 3 own followers plus 9 Mythic or
    Secret pets around the player, each moved and stepped every frame like a follower. The animator code for 12 pets
    came to about 0.6 ms per frame (0.43 ms for the 9 extras), under the 1.5 ms target. Studio ran at about 15 fps
    (window in the background), so the GPU numbers from that run don't count.
  - Outlines: in a Studio playtest, the PetLab gallery (24) and the followers each call `PetFx.outlines` with their own
    budget, so together they can go over 31. Live servers have no PetLab.
  - Hatch previews: 1 and 10 for all 8 eggs completed, with no errors.
  - Rejoin: 70 pets, the same 3 out, boost 1282, and the followers and hatchery eggs come back.
  - Not tested: Equip Best and delete. Both write the live save from Studio, and their server code is unchanged since
    Phase 2.
  - Old code removed: the chibi builder, `buildChibi` and `addEffects` are gone from `PetModels` (910 -> 184 lines).
    Only `build` and `egg` (with its procedural fallback) remain. Backup: `Before_Oct27_ChibiRemoval`. Unit tests 7/7.
  - README pet line updated.
- Oct 27 2026: **Running fix (PetAnimator).** Pets slid instead of running because players move at ~211 studs/s and the
  animator was tuned around 16. Gait rates topped out at 16 studs/s, and `Wobble` (which drives most wings, legs, fins
  and tails) ran on a fixed clock, so moving only made its swing bigger, never faster. Now:
  - New `PetAnimator.pace(speed)`: 0..1 up to 16 studs/s, then +1 per doubling of speed, up to 3. Bound, Waddle,
    Scuttle and Slither use it.
  - Wobbles marked `Moving` cycle `1 + 0.75 * mv * pace` times faster. The cycle position builds up frame by frame
    (`self.WobPh`), so rate changes never jump. Idle-only wobbles are unchanged.
  - Roll spin is capped at 30 studs/s so it doesn't strobe.
  - Backup: `Before_Oct27_PetRunPace`. New test `PetAnimator_Test` (tests 9/9).
  - In game while running: Seraph wings 0.5 -> 1.7 cycles/s, Weaver legs 1.4 -> 4.4, Koi tail 0.5 -> 1.7.
  - Still open: 14 pets have leg or claw joints and 9 have wing or fin joints that no block drives at all (for example
    BoltBug Legs, FinalBoss Legs, HighScoreDragon Wings, MainframeBeetle Wings), so those parts never move.
- Oct 27 2026: **Limb batches (6 pets each, owner's request).** A full scan, standing and running, found 37 pets with a
  joint that never moves. Most are rigid parts (shells, horns, visors), so only the moving limbs are being animated.
  Several wobbles on one joint now combine instead of the last one winning (`self.WobCf`). Before this, no pet had two.
  - Batch 1 done: BoltBug, CartridgeCrab and MainframeBeetle legs scurry. MainframeBeetle wings buzz. FinalBoss hips
    march. HighScoreDragon legs paddle. EclipseNightmare hooves rock in a gallop. All are `Wobble` entries with
    `Idle = 0, Moving = 1`; the legs are single merged meshes, so they can't step one at a time. All 60 pets step
    without errors. Tests 9/9. Backup of PetConfigs: `Before_Oct27_PetRunPace`.
  - Batch 2 done:
    - HailstormGriffin talons and legs, and RunebarkOwl talons, dangle and tuck back in flight.
    - JoystickCritter legs kick while hopping, and its head bobbles on landing (`Land`).
    - HyperdriveHawk jets rumble and tilt back under thrust. Its blades are left for its special.
    - ChromePanther had a dead `Ears` block (that block needs EarL/EarR, the model has one `Ears` joint), so it's now a
      wobble: a twitch, flattened back while running.
    - WispKit ears sweep back while moving.
    - Skipped: ElderhornSpirit's "Head" and "Tail" are tiny face bits, and Bramblehog's "Feet" are a hidden speck.
    - Directions checked from the joint math: tips move toward the tail. All 60 pets step without errors. Tests 9/9.
  - Batch 3: VoidCat ears; MaelstromSerpent (Seg2, TailFin); ConstellationCub mane; RimebackRam wool; then a
    rescan for anything left.

## Phase 1: shared runtime

- Move `PetAnimator` and `PetConfigs` from `ServerStorage.PetLab.Code` into a new `ReplicatedStorage.PetSystem` folder.
  The lab then requires them from there, so the lab and the game always run the same code.
- Add `ReplicatedStorage.PetSystem.PetFx`. It owns the LOD from PET_BIBLE §6 (rates, trails, animator skipping by
  camera distance) and the **outline manager** (Highlight only on your own pets plus the nearest ~12, so the total stays under ~31).
- Move the 60 finished models into `ReplicatedStorage.PetAssets` (Folder, one Model each, named by the ROSTER name).
  Remove `ModelStreamingMode` overrides there, because ReplicatedStorage isn't streamed. The lab gallery then clones from PetAssets.

## Phase 2: new catalog (`PetData`)

- **Eggs** (in this order, matching ROSTER): Ember, Tide, Grove, Frost, Arcade, Circuit, Phantom, Celestial.
  Prices are the old prices of eggs 1, 3, 5, 7, 9, 11, 13 and 15: **500 · 25,000 · 500,000 · 15M · 1B · 8B · 50B · 1T**.
  Keep `Color/Spot/Pattern` so `PetModels.egg()` still draws them. Suggested patterns: cracks (+`Mat = "CrackedLava"`), waves,
  leaves, snow, sprinkles, stripes, zigzag, galaxy.
- **Pets:** each egg has a `Pets` **pool**. Every pet has `Id` (snake_case from ROSTER, and this is now the save key and `Key`),
  `N` (display name), `R` (tier 1–7), `Model` (PetAssets name) and `Mode`.
- **Odds:** keep `BASE_ODDS = {50, 27, 13, 6.5, 2.6, 0.75, 0.15}`. Use shift `1 + 0.09 * (egg - 1)` (8 eggs now span what 15 did).
  If an egg has no pet of some tier (no Secrets in eggs 1–3), drop that tier and renormalise. The shop must show the real odds.
- **Roll:** pick a tier by odds, then pick uniformly among the egg's pets of that tier.
- **Boost:** `floor(2 * 1.26 ^ ((egg - 1) * 2) * RARITIES[r].Mult + 0.5)`. This makes egg 8 match old egg 15, so the economy curve stays the same.

## Phase 3: save migration (the part that must not go wrong)

Saved pets are `{I = id, K = "egg-slot"}`. `Pets.load` currently **drops** any pet whose `K` isn't in `PetData.PETS`.
Shipping the new catalog without migration would **delete every player's pets**.

- Add `ServerScriptService.StealAGame.PetMigration` with `migrateKey(oldKey) -> newId`:
  - old `"e-r"` (e = 1..15, r = 1..7) → new egg `k = min(8, floor(e / 2) + 1)`. This never gives a player a lower Boost than they had.
  - pick a pet of tier `r` in egg `k`. If there are several, choose by a stable rule (`(e % 2) + 1`, wrapped) so the same old pet always becomes the same new pet.
  - if egg `k` has no tier `r` (Secrets in eggs 1–3), use the lowest egg above `k` that has it.
- In `Pets.load`, migrate keys **before** validation, keep `I` and the equipped list as they are, and set `saved.PetVersion = 2`.
  Migrate only when `PetVersion` is missing or < 2.
- **Test first:** write unit tests (the Studio MCP `rbx-unit-test` skill) that run all 105 old keys through `migrateKey`. Check that every
  result exists, the tier is never lower, the Boost is never lower, and running it twice gives the same result. Then playtest with
  a fake old save. Don't touch the live DataStore from Studio unless I say so.

## Phase 4: models and following (`PetModels`, `PetsUI`)

- `PetModels.build(pet)`: clone `PetAssets[pet.Model]`. If it's missing, return a simple placeholder and `warn` once. Keep the attribute `PetKey`.
  `addEffects` goes away, because effects live in the models.
- Follow loop in PetsUI:
  - one `PetAnimator` per follower, `Step(dt, t, speed, turn)`
  - move the pet by setting `Root.CFrame`, never `PivotTo` (that fights the joints)
  - face the travel direction while moving and the player's facing when idle (copy PetLabClient)
  - get the hover height from the pet's `Mode`, replacing the old `FLYERS` table keyed on `pet.B`
  - widen `SLOTS` because the new pets are bigger: about 1 stud more per slot at Mythic and Secret
  - apply the PetFx LOD and the outline manager
- Keep the 250-stud cull and the teleport snap.

## Phase 5: UI previews and the hatch moment

> Oct 26 2026: the hatch sequence in PetsUI is already rebuilt (fly-in, build-up, crack, themed opening, reveal,
> HATCH AGAIN). It is driven by two tables there: `THEMES` keyed by egg `Pattern` (all eight new-egg patterns already
> have entries) and `TIERS` keyed by rarity. When the premium pets go in, keep those tables and only swap the reveal's
> pet viewport for a `WorldModel` one that runs the animator, so Mythic and Secret can also play their signature move.

- Every ViewportFrame showing a rigged pet (shop odds list, hatch reveal, bag) needs a `WorldModel` inside it.
  Run the animator in idle for the hatch reveal and the selected bag pet only, not for every slot in the bag.
- Hatch reveal by tier (PET_BIBLE §2): Epic gets a short sting, Legendary a colour burst in its palette, Mythic plays its signature
  transformation in the viewport, Secret gets a full-screen moment. Reuse UIKit and existing tweens.

## Phase 6: performance and final checks

- Studio local server with 4 players, each with 3 Secret or Mythic pets out, all in one spot. Check frame time with the
  MicroProfiler (`rbx-perf-profiling` skill). The pet code should cost under ~1.5 ms per frame on the client.
- Check the Output is clean, Equip Best works, hatching 1 and 10 works for every egg, deleting works, and saves and rejoins keep pets.
- Only after all of that, move the old chibi builder code (`BODY.*`, `face`, `headTop`...) into a backup copy and remove it from `PetModels`.
- Update the README feature list.

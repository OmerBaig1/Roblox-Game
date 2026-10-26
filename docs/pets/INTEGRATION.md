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

# Premium Pets: start here

This folder is the full handoff for building the 60-pet collection that replaces the game's 105 chibi pets.
One pet already exists as the reference: **Cinder Lynx** (Epic), in Studio at `ServerStorage.PetLab.Pets.CinderLynx`.

| File | What it is |
|---|---|
| `START_HERE.md` | This file. The prompts to paste into Claude Code, in order. |
| `PET_BIBLE.md` | Art direction, rarity-tier standards, the rig contract, performance budgets, and the step-by-step build recipe for one pet. |
| `ROSTER.md` | All 60 pets: egg, tier, concept, generator prompt, part names, motion, effects and signature move. |
| `INTEGRATION.md` | How the new pets replace the old ones in the real game: the catalog, save migration, follow code, UI previews. |
| `STATUS.md` | The tracker. Claude Code updates it after every pet. |

## Before you start

1. Open the place in Roblox Studio and make sure Claude Code is connected to Studio through the Roblox Studio MCP. It's the same connection described in `CLAUDE.md`.
2. Run Claude Code from this repo folder so it reads `CLAUDE.md` and these docs.
3. Let Claude Code work during a quiet time. The mesh generator is slow (1–3 minutes per call), and your friend will see changes appear in Team Create.

---

## Prompt 1: build the pets (paste this first)

```text
Read CLAUDE.md, then every file in docs/pets/ (START_HERE, PET_BIBLE, ROSTER, INTEGRATION, STATUS) before doing anything.

We're building the premium pet collection for Steal a Game in Roblox Studio, through the Roblox Studio MCP tools only
(never edit src/, never use Rojo serve/build/upload). One finished reference pet already exists:
ServerStorage.PetLab.Pets.CinderLynx, with its animation code in ServerStorage.PetLab.Code (PetAnimator, PetConfigs,
PetLabClient) and the Studio-only lab loader in ServerScriptService.PetLabDev. Inspect those first and match their quality,
structure and naming exactly.

Your job in this session: build the next batch of pets from ROSTER.md into the Pet Lab, following the
"Build recipe for one pet" in PET_BIBLE.md step by step for each pet. Work through STATUS.md in order and take the first
6 pets that are not yet at G4. For each pet:
  - generate the mesh with the Studio mesh generator using the ROSTER prompt + the house style suffix and the exact
    part names; if a generation is poor (wrong facing that can't be fixed, merged parts, off-palette, broken face),
    regenerate, up to 3 tries, and keep the best in ServerStorage.PetLab.RawGenerations
  - clean, orient, scale and rig it to the rig contract; add its effects to its tier standard; add its PetConfigs entry
    (and any new motion "Mode" or signature move to PetAnimator in a reusable way)
  - place it on its gallery row in the lab (one row per tier)
  - playtest: no errors in the output, idle + follow + signature all work (use the L-key follower), and it passes
    the QC checklist in PET_BIBLE.md
  - update STATUS.md with the gates it really reached and one line of notes. Never mark a gate you didn't verify.

Rules:
  - Do not touch the live pet system (PetData, PetModels, Pets, PetsUI) in this phase. Everything stays in the Pet Lab.
  - Back up PetAnimator and PetConfigs into ServerStorage.Backups (a dated folder) before changing them.
  - Keep every pet distinct: if a generation comes out looking like an existing pet, change the prompt and regenerate.
  - Stay inside the tier budgets in PET_BIBLE.md.
  - Stop the playtest before editing, playtest after.
When the batch is done, stop and give me: a list of the 6 pets with what each reached, screenshots of the gallery rows,
anything that failed or that you think needs my eye, and any changes you made to PetAnimator.
```

## Prompt 2: every later batch

```text
Read CLAUDE.md and docs/pets/ again (STATUS.md especially). Continue the premium pet build: take the next 6 pets in
STATUS.md that are not at G4 and build them exactly as in the previous batches, following PET_BIBLE.md. Before starting,
apply any feedback I give below. Same rules and the same report at the end.

Feedback from the last batch: <write your notes here, or "none">
```

Run Prompt 2 about 9 more times to finish all 59 pets. After the first two batches, compare the pets on the gallery rows
side by side (press P in a playtest) and give feedback before going further. That's the cheapest moment to change the style.

## Prompt 3: put them in the real game (only once all 60 are at G4 and you're happy)

```text
Read CLAUDE.md and docs/pets/INTEGRATION.md. All 60 premium pets are built in the Pet Lab (see STATUS.md). Now replace
the old 105-pet system with them, following INTEGRATION.md phase by phase. Back up every script you change into
ServerStorage.Backups first. Do not delete any old pet code until the migration has been tested. Stop after each phase,
playtest, and report before starting the next one. Test the save migration with fake old save data before anything else.
```

## Prompt 4: pet fix-ups (whenever you want one changed)

```text
Read CLAUDE.md and docs/pets/PET_BIBLE.md. In the Pet Lab, rework <PET NAME> (see ROSTER.md): <what's wrong>.
Regenerate or adjust as needed, keep it inside its tier standard, playtest, and update STATUS.md.
```

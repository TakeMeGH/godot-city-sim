# Test Evidence: Day and night

> **Story**: `production/epics/shinobi-station/story-006-day-and-night.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-11-16
> **Tester**: Claude (build-all-stories run); sign-off below is yours
> **Build / Commit**: uncommitted working tree on `main` (after a5d2a33)

---

## What Was Tested

Four Movie Maker captures (last frame kept) at fixed times of day through the `--time`
user argument, with the camera fixed through `--cam`: dusk, full night at the village
centre, full night at the station with the train stopped (`--train-at=stopped`), and
dawn. A headless run of 50 s of game time from 0.74 crossed dusk with no errors.

**Acceptance criteria covered**: AC-2, AC-3, AC-4, AC-5, AC-7 (stills); AC-1 and AC-6 need play

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Daylight fades smoothly through dawn and dusk, dark at night | NOT SEEN | The fade is motion; the stills show its three states |
| AC-2 | Night tint and warm dusk/dawn glow over the whole view, strength in data | PASS (stills) | 01-dusk and 04-dawn warm, 02-night blue-purple; `night_strength` 0.62 as in the prototype |
| AC-3 | Buildings switch to lit-window frames when dark | PASS | 02-night, 03-night-train |
| AC-4 | Soft additive glow from lanterns, windows and the headlamp, brighter when darker | PASS (stills) | Glow on its own layer above the tint, so the tint does not darken it |
| AC-5 | Train uses its lit night frames after dark | PASS | 03-night-train |
| AC-6 | One full day plays through with no end state | NOT SEEN | Needs a full watched day |
| AC-7 | Only tint and glow are made in code | PASS | Glow textures are generated radial gradients; every other sprite is from the sheets |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-006-day-and-night/01-dusk.png` | Dusk at 0.77: warm cast over the village | AC-2 |
| 2 | `story-006-day-and-night/02-night.png` | Night at 0.90: tint, lit windows, lantern and window glow | AC-2, AC-3, AC-4 |
| 3 | `story-006-day-and-night/03-night-train.png` | Night at the station: train night frames and headlamp glow | AC-4, AC-5 |
| 4 | `story-006-day-and-night/04-dawn.png` | Dawn at 0.24: warm cast, windows still lit | AC-2 |

---

## Test Conditions

- **Game state at start**: fresh launch, `-- --time=<t> --cam=x,y` (plus `--train-at=stopped` for 3)
- **Platform / hardware**: Windows 11, Godot 4.7.2 (D3D12), Movie Maker at 480x270
- **Framerate during test**: fixed 60 fps (Movie Maker)

---

## Observations

- The night is fairly light (`night_strength` 0.62, the prototype's value); the village still reads clearly. Raise it in `village_tuning.json` for a darker night.
- Windows light when daylight falls below 0.5, a little after the clock's dusk signal, not on the signal itself.
- A HUD in story 007 needs a canvas layer above 1 to sit over the glow.

---

## Sign-Off

A **Visual/Feel** story needs your sign-off before `/story-done` marks it COMPLETE. Look at
the four screenshots (and a day in the running game), then tick the box.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | Project owner (approved in chat) | 2026-11-16 | [x] Approved |

---

*Template: `.claude/docs/templates/test-evidence.md`*

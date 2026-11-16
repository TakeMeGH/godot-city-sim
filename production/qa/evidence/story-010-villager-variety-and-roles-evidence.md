# Test Evidence: Villager variety and new roles

> **Story**: `production/epics/shinobi-station/story-010-villager-variety-and-roles.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-11-16
> **Tester**: Claude (build-all-stories run); sign-off below is yours
> **Build / Commit**: uncommitted working tree on `main` (after 99dd9a7)

---

## What Was Tested

Residents, kids and the rooftop runner now wear looks picked from 8 sheets per body by the
seeded generator, and 8 role villagers (2 gate guards, 2 academy teachers, 3 shopkeepers,
1 ramen cook) were added to the 30 residents. Movie Maker captures (last frame kept): the
plaza crowd, a crowd by the station, and the click label on a guard and on a shopkeeper. The
four role sheets are shown at 6x as contact sheets, since the teachers and the cook are at
home at the start of the captures. Headless runs (5400 and 7800 frames) printed no errors and
logged a spar, the hawk and the cat; startup prints "30 distinct looks in use (38 residents)".

**Acceptance criteria covered**: AC-1 to AC-8

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | 4+ hair, 3 skin, 3 outfits per body, drawn or remapped in Aseprite | PASS | 8 looks per body; hair in 4-5 colours and 2 styles each (new style redrawn on every frame); light / medium / deep skin; 3-4 outfit colours |
| AC-2 | Four roles, own silhouettes | PASS | 10-13 sheets: masked guard with a spear, teacher with glasses and long vest, shopkeeper in apron and headscarf, cook in whites with a towel |
| AC-3 | Same frame layout and anchor as the base body | PASS | Checked per sheet against its base; `look1` is pixel-identical to the original |
| AC-4 | Seeded looks, 12+ distinct at once, no two in one house alike | PASS | 23 distinct looks visible at the start, 30 in total; 0 house clashes (no houses are shared) |
| AC-5 | Roles spawn with a name and a home and follow routines | PASS | 8 role villagers, names and doors continue the resident counter |
| AC-6 | Click label shows the role | PASS | 03 "Chiyo, gate guard: looking around"; 04 "Tama, shopkeeper: looking around" |
| AC-7 | Kids and runners use the new sheets; story 004 unchanged | PASS | Kids and the rooftop runner draw from the same look decks; tag and dash ran in the headless runs |
| AC-8 | Look tables and role counts in data | PASS | `looks` and `roles` in `village_tuning.json` |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-010-villager-variety-and-roles/01-plaza-crowd.png` | The plaza crowd: mixed hair, skin and outfits | AC-1, AC-4 |
| 2 | `story-010-villager-variety-and-roles/02-crowd-close.png` | A crowd by the station | AC-1, AC-4, AC-7 |
| 3 | `story-010-villager-variety-and-roles/03-label-guard.png` | Click label on a gate guard | AC-6 |
| 4 | `story-010-villager-variety-and-roles/04-label-shopkeeper.png` | Click label on a shopkeeper | AC-6 |
| 10-13 | `story-010-villager-variety-and-roles/1x-role-*-sheet.png` | The four role sheets at 6x, every frame | AC-2, AC-3 |

---

## Test Conditions

- **Game state at start**: fresh launch, `-- --skip-title --time=0.42 --cam=x,y [--select-nearest=x,y]`
- **Platform / hardware**: Windows 11, Godot 4.7.2 (D3D12), Movie Maker at 480x270
- **Framerate during test**: fixed 60 fps (Movie Maker)

---

## Observations (this run's review)

- The village reads as many different people now; at 1x the hair colour and outfit carry most of the difference.
- In 03 the guard herself stands behind a building; her label is placed above the roof line.
- Artist's notes: the deep skin tone lowers contrast around the eyes; the elder's dark-grey hair reads as a heavy block from behind (cook and look 3); the guard's spear grip does not follow the arm swing; the teacher's coat hem covers the top of the kicking leg in the kick frame.
- Role villagers can be picked by events for now (a guard sparred, a teacher took the hawk's message); stories 011-013 station them.

---

## Sign-Off

A **Visual/Feel** story needs your sign-off before `/story-done` marks it COMPLETE. Look at
the screenshots (and the running game), then tick the box.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

---

*Template: `.claude/docs/templates/test-evidence.md`*

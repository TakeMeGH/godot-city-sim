# Test Evidence: Building variety

> **Story**: `production/epics/shinobi-station/story-009-building-variety.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-11-16
> **Tester**: Claude (build-all-stories run); sign-off below is yours
> **Build / Commit**: uncommitted working tree on `main` (after 99dd9a7)

---

## What Was Tested

The 50 houses, blocks, towers and shops of the 20x20 village (story 008) were re-skinned in
place with the new variant sheets and rooftop details. Five Movie Maker captures (90 frames,
last frame kept) with the camera fixed through `--cam`: the village centre (compare with the
"before" shot taken for story 008), a street of mixed buildings by day and at night, a
rooftop close-up, and the front row by the station. Headless runs by day (3600 frames, with a
rooftop dash) and at night (600 frames) printed no errors and no identical-neighbour or
bad-detail messages.

**Acceptance criteria covered**: AC-1 to AC-9 (AC-6's walking-behind is seen in stills only)

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | 3 roof and 3 wall colours, drawn in Aseprite, warm range main | PASS | Roofs terra 24 / red 18 / slate 8; walls cream 17 / ochre 17 / white 16; recolours are layer exports, no tint in code |
| AC-2 | 2- and 3-storey versions with day and night frames | PASS | Blocks and hips s1-s3, towers s1-s2; 25 / 17 / 8 buildings by storeys |
| AC-3 | Rooftop details picked per building from data | PASS | 55 details: 28 tanks (3 shapes), 19 laundry lines, 8 signs (04-rooftops) |
| AC-4 | Art rules followed, anchors in the sprite table | PASS | 86 table entries from the artist's manifest; lint clean apart from the originals' deliberate window glints |
| AC-5 | No identical neighbours (startup check) | PASS | Check runs at startup; proven to fire by the agent with a deliberate clash, then restored |
| AC-6 | Tall buildings hide villagers behind them; dash heights | PASS (stills) | Sorting looks right in 01, 02, 05; the dash reads roof heights from the table |
| AC-7 | Night switch and window glow on every new building | PASS | 03-mixed-street-night: lit windows on every storey |
| AC-8 | Sources in `assets/art/src/`, sheets imported unfiltered | PASS | `<type>_s<n>.aseprite` sources; project default filter is nearest |
| AC-9 | Before-and-after screenshots, nothing clipped | PASS | 00-before-centre and 01-after-centre |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 0 | `story-009-building-variety/00-before-centre.png` | Before: story 008's centre with the old four house sprites | AC-9 |
| 1 | `story-009-building-variety/01-after-centre.png` | After: the same view with variants | AC-1, AC-2, AC-9 |
| 2 | `story-009-building-variety/02-mixed-street.png` | A street of mixed walls, roofs and heights by day | AC-1, AC-2, AC-3, AC-6 |
| 3 | `story-009-building-variety/03-mixed-street-night.png` | The same street at night | AC-7 |
| 4 | `story-009-building-variety/04-rooftops.png` | Rooftop tanks, laundry and signs | AC-3 |
| 5 | `story-009-building-variety/05-front-row.png` | The front row by the station | AC-2, AC-6 |

---

## Test Conditions

- **Game state at start**: fresh launch, `-- --skip-title --time=0.45 --cam=x,y` (0.90 for night)
- **Platform / hardware**: Windows 11, Godot 4.7.2 (D3D12), Movie Maker at 480x270
- **Framerate during test**: fixed 60 fps (Movie Maker)

---

## Observations (this run's review)

- The village no longer repeats: walls, roofs and heights change from house to house, and the rooftop tanks and laundry carry the brief's signature detail.
- The `red` roof's lightest step reads slightly salmon at the hip apex (artist's note).
- `white` walls pair a warm lit face with a fairly blue shadow face: strong contrast, by the cool-shadow rule.
- Rooftop details do not raise the rooftop dash's height, so a dashing ninja passes through tanks.
- On tall buildings the per-storey window glows overlap a little; judge it at night in the running game.
- Re-running `tools/art/gen_village.py` (story 008) would rebuild the layout without the variants; `tools/art/variety.py` re-applies them.

---

## Sign-Off

A **Visual/Feel** story needs your sign-off before `/story-done` marks it COMPLETE. Look at
the screenshots (and the running game), then tick the box.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

---

*Template: `.claude/docs/templates/test-evidence.md`*

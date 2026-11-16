# Test Evidence: Isometric village scene

> **Story**: `production/epics/shinobi-station/story-001-isometric-village-scene.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-11-16
> **Tester**: Claude (build-all-stories run); sign-off below is yours
> **Build / Commit**: uncommitted working tree on `main` (after 4159aa4)

---

## What Was Tested

The Godot main scene boots straight into the isometric village. Three Movie Maker
captures (60 frames each, last frame kept) were taken with the camera fixed through the
`--cam=x,y` user argument: the start position and the two farthest corners of the camera
range. They cover the ground tiles, the placements and their anchors, depth order between
buildings, trees and props, the 480x270 native size, and the camera range.

**Acceptance criteria covered**: AC-1, AC-2, AC-3, AC-4 (buildings and props only), AC-5 (stills only), AC-8, AC-9

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | Aseprite sheets imported, filtering off | PASS | 25 PNGs in `assets/art/` imported clean; sources in `assets/art/src/`; nearest filter set in `project.godot` |
| AC-2 | Map built from a data file | PASS | `assets/data/village_layout.json` |
| AC-3 | Placements on their tiles at the prototype's anchors | PASS | 01-centre matches the prototype's iteration-1 play shot |
| AC-4 | Correct depth sorting for anything added later | PASS for what exists | Buildings, trees and props sort correctly; villagers arrive in story 003, where walking behind a house is seen |
| AC-5 | Native 480x270, whole-number scaling, no shimmer | PASS (stills) | Recorded at 480x270; shimmer while moving is a feel check: watch it when you play |
| AC-6 | Camera drifts, pans by drag and arrows, stays in range | PARTLY SEEN | Range clamp seen in 02 and 03; drift and panning were not observed in a still |
| AC-7 | Lanterns unlit/lit frames and `set_lit()` | NOT SEEN | Exists in code; seen once story 005 lights them |
| AC-8 | Look matches the prototype | PASS | After fix round 1 (`ground_margin` 6 → 10) no dark clear colour shows at the range corners |
| AC-9 | Layout and camera values in data files | PASS | `village_layout.json`, `village_tuning.json`; no gameplay literals in the scripts |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-001-isometric-village-scene/01-centre.png` | The village at the start camera: houses, towers, shops, station, streets, lanterns, track | AC-2, AC-3, AC-4, AC-5, AC-8 |
| 2 | `story-001-isometric-village-scene/02-corner-left.png` | The top-left edge of the camera range: forest ring and track | AC-6 (range), AC-8 |
| 3 | `story-001-isometric-village-scene/03-corner-right.png` | The bottom-right edge of the camera range | AC-6 (range), AC-8 |

---

## Test Conditions

- **Game state at start**: fresh launch of the main scene, camera fixed with `-- --cam=x,y`
- **Platform / hardware**: Windows 11, Godot 4.7.2 (D3D12), Movie Maker at 480x270
- **Framerate during test**: fixed 60 fps (Movie Maker)
- **Any special setup required**: none beyond the `--cam` user argument

---

## Observations

- Window opens at 960x540 (2x); fullscreen or resized windows scale by whole numbers only.
- Camera drift starts 6 s after launch (the prototype drifts at once).

---

## Sign-Off

A **Visual/Feel** story needs your sign-off before `/story-done` marks it COMPLETE. Look at
the three screenshots (and the running game), then tick the box.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

---

*Template: `.claude/docs/templates/test-evidence.md`*

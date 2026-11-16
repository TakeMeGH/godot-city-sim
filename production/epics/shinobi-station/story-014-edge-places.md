# Story 014: Edge places

> **Epic**: Shinobi Station
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 14

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 14 and the sparring match of story 005:*

- [ ] The training ground is a sand yard with three wooden posts and a memorial stone (new sprites drawn in Aseprite), replacing the current target; training and the sparring match (story 005) use it, with the spar and crowd tiles moved in tuning
- [ ] A fenced forest sits at one edge: darker forest tiles, fence pieces and a warning sign; no villager's path enters it
- [ ] A river crosses one side of the map with an arched wooden bridge; villager paths cross the water only at the bridge
- [ ] A multi-storey hospital has its own sprite, a lit night frame and a door tile; "visiting the hospital" is a new activity mostly for elders, with its weight in tuning
- [ ] Depth sorting is right for the bridge, fence, posts and hospital
- [ ] The editor preview shows the new ground tiles after Rebuild preview
- [ ] Positions, tile names and weights live in data files, never in code

---

## Implementation Notes

- Water and forest are blocked tiles in the path grid; the bridge tiles are walkable (a `bridge` tile name in the legend)
- The memorial stone is a place a trainer may pause at before training, as an activity text
- Spar and crowd tiles are keys already in `village_tuning.json` (`spar_tile_a`, `spar_watch_tiles` and the others); change values, not code

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the map and the wall
- Stories 011 to 013: the gate, market and academy

---

## Files

- `assets/art/training_post.png`, `memorial_stone.png`, `fence_i.png`, `fence_j.png`, `fence_corner.png`, `warning_sign.png`, `bridge.png`, `hospital.png` and their `assets/art/src/*.aseprite` — created
- `assets/art/tiles.png`, `assets/art/src/tiles.aseprite` — modified (frames 9 forest_dark and 10 riverbank appended; the first 9 frames unchanged)
- `assets/data/village_layout.json` — modified (training ground with three posts and the memorial stone; river at i=16-17, j=7-14 with a riverside path at i=18 and the bridge at (16-17, 12); fenced dark forest at i=1-6, j=13-14 with a warning sign; hospital 2x2 at (3-4, 8-9) with its door at (4,10); `tile_frames` bridge alias; lots resized; four props moved)
- `assets/data/village_tuning.json` — modified (training post spots, memorial linger, hospital activity and weights, spar tiles, walk tiles, check lists)
- `src/village/village_scene.gd` — modified (tile-frame aliases, optional `sort_y` per sprite, tile-frame check)
- `src/villagers/villager_routines.gd` — modified (train at a free post, memorial pause, hospital visits)
- `tools/art/landmarks_b.json`, `tools/art/edge14.py` — created (art manifest and the layout edit script)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the training ground, the bridge, the fenced forest and the hospital in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-003-villager-routines.md`, `production/epics/shinobi-station/story-005-small-events-and-log.md`, `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 6/7 passing, 1 deferred. Passing: AC-1 training ground with three posts and the memorial stone, and a sparring match starting in the new yard (01-training-spar and its log), AC-2 fenced dark forest with a warning sign (03), AC-3 river crossed only at the arched bridge (02; every other water tile is blocked in the path grid), AC-4 hospital by day and lit at night (04, 05), AC-6 editor preview reads the same layout, AC-7 values in data. Deferred: AC-5 depth sorting of villagers crossing the bridge and walking behind the hospital (motion; the bridge's `sort_y` puts crossers above the deck)
**Deviations**: ADVISORY — the forest lot is only 2 tiles deep, so the fence runs on the lot's boundary lines rather than its border tiles, and houses in row 15 hide much of it from the default views. ADVISORY — the river runs j=7-14, not to j=15, because row 15 holds houses. ADVISORY — the hospital has no window-glow offsets of its own; its night frame lights the windows. ADVISORY — the training yard sits at the camera's right limit, so the spar is seen at the edge of the view
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-014-edge-places/`
**Reviewed by**: self, no independent review
**Built out of order**: before stories 011-013, while their art was still being drawn (logged)

## Calls beyond the design
- the river moved one column west (water i=17, riverbank i=16) with a dirt riverside path at i=18 so the bridge connects two walkable places; academy and market lots shrank to make room · kept 2026-11-16
- the bridge is a walkable "bridge" tile drawn with the water frame (`tile_frames`), sorted 36 px early so people crossing draw on top · kept 2026-11-16
- trainers face a free post; with all three taken they use spare sand tiles · kept 2026-11-16
- 35% of trainers pause at the memorial stone for 3-6 s first · kept 2026-11-16
- hospital visits: elders 16%, kunoichi 4%, ninjas 2% of choices, 8-16 s · kept 2026-11-16
- two lanterns, a bench and a crate pile moved off the bridge, fence and hospital path · kept 2026-11-16

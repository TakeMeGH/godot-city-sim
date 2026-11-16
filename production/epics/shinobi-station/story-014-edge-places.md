# Story 014: Edge places

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `assets/art/training_post.png`, `memorial_stone.png`, `fence.png`, `bridge.png`, `hospital.png`, `assets/art/tiles.png` (water and forest variants), `assets/art/src/*.aseprite`
- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/villagers/village_paths.gd`
- `src/villagers/villager_routines.gd`
- `src/events/spar_event.gd`
- `tests/integration/village/edge_places_test.gd`

---

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

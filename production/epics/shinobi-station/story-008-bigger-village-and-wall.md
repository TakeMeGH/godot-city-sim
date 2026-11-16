# Story 008: Bigger village in districts, ringed by a wall

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
**Requirement**: Brief MVP feature 8

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 8 and its Look (a hidden village in a forest valley):*

- [ ] The map in `village_layout.json` is 20x20 tiles, laid out in districts: a main street from the gate gap to a central plaza, side streets between housing blocks, and the station and track kept along one edge
- [ ] A wall ring, drawn from the layout data, runs around the village edge with one gap reserved for the gate (story 011)
- [ ] Every building keeps its ground anchor and door tile, and every door is reachable by street from the plaza (a startup check reports any unreachable door)
- [ ] Villager paths are rebuilt for the 20x20 map: villagers walk the street, plaza and platform tiles only, by shortest path, as in story 003
- [ ] The resident count is raised to fill the bigger village (values in tuning), each with a name and a home door
- [ ] Every tile coordinate that stories 002 to 005 put in the tuning data (platform and stop point, kid square, spar tiles, hawk perch and collect tile, cat row, rooftop rows, roof heights) points at a valid place on the new map, and each event still runs through to its log line
- [ ] The camera range, start position and drift scale to the new size; the camera stays inside the village and no dark clear colour shows at the range corners
- [ ] Depth sorting is still correct at the larger size, and the scene still renders at native 480x270 with whole-number scaling
- [ ] The editor preview (story 001's tool script) shows the bigger village after Rebuild preview
- [ ] Layout and tuning values live in data files, never in code

---

## Implementation Notes

- The map comes first: stories 009 to 014 all place things on it, so keep the layout data easy to extend (named districts, reserved tiles for the gate, market, academy and edge places)
- Wall pieces are a small sprite set drawn in Aseprite and placed from the layout like any other building
- Check every `[i, j]` pair in `village_tuning.json` against the new map at startup, and name the key that is off

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: new building looks and rooftop details
- Story 011: the gate building, guards and the village name
- Stories 012 to 014: the market, academy and edge places (reserve their tiles only)

---

## Files

- `assets/data/village_layout.json` — regenerated (20x20 map: main street i=9 from the gate gap (9,0) to the cobble plaza (7-11, 7-11), cross streets j=2, 4, 6, 12, platform j=16, track j=17; 51 buildings, 53 doors, 20 lanterns, wall ring, ~118 trees outside; `lots` for gate, training, academy, hospital, market, forest, river)
- `assets/data/village_tuning.json` — modified (camera range and drift, train stop and platform, 30 residents and 3 night watchers, kid homes and tag centre, rooftop rows, spar, hawk and cat tiles; check key lists)
- `src/village/village_scene.gd` — modified (`lots` loaded; startup check that lots stay on the map, apart and off the streets)
- `src/villagers/villager_routines.gd` — modified (startup checks: every door reachable from the plaza, every tuned tile key valid)
- `src/villagers/rooftop_dash.gd` — modified (startup error when a rooftop row has no roof)
- `src/village/camera_rig.gd` — modified (doc comment only)
- `assets/art/wall_i.png`, `wall_j.png`, `wall_corner.png`, `assets/art/src/wall_*.aseprite` — created (wall segments and the corner post)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the centre and both camera corners in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-001-isometric-village-scene.md`, `production/epics/shinobi-station/story-003-villager-routines.md`, `production/epics/shinobi-station/story-004-npcs-running-around.md`, `production/epics/shinobi-station/story-005-small-events-and-log.md`
- Unlocks: `production/epics/shinobi-station/story-009-building-variety.md`, `production/epics/shinobi-station/story-011-wall-and-main-gate.md`

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 9/10 passing, 1 deferred. Passing: AC-1 20x20 districts (01-centre), AC-2 wall ring with the gate gap and track gaps (02-05), AC-3 doors reachable (startup check, and the engine check re-ran it on the data: 53 of 53), AC-5 30 residents (01-centre), AC-6 tile keys re-pointed (a 150 s run here logged the spar, hawk, cat and lantern round through to their end lines), AC-7 camera range (02-05 after fix round 1), AC-8 depth sorting and 480x270 (stills), AC-9 editor preview (the @tool script reads the same layout), AC-10 values in data. Deferred: AC-4 walking by shortest path over the new streets (motion; the startup path check passes)
**Deviations**: ADVISORY — 51 buildings against the story's 45-50. ADVISORY — every door faces south onto a street, so the blocks are single rows between streets rather than double-deep blocks. ADVISORY — the wall is 21 px tall, not 26, to fit its 64x48 canvas
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-008-bigger-village-and-wall/` (centre and four corners)
**Reviewed by**: self, no independent review; engine check by godot-gdscript-specialist: no problems found
**Fix rounds**: 2 — (1) camera range 320x185 → 240x140 and drift 250x115 → 200x100: the corners showed mostly forest outside the wall; (2) found in the run-end full-day check: the lantern round (21 lanterns, a 201-tile walk) outlasted the night and ended at dawn without its log line — `lantern_walk_mult` 1.2 → 2.5 and `lantern_round_timeout` 90 → 110 (shorter than the 117.6 s night); the timeout and dawn endings now log a line; a startup check reports unreachable lantern approach tiles. The round now takes about 95-98 s and logs "Every lantern is lit"

## Calls beyond the design
- the gate gap tile (9,0) is dirt, so villagers can walk into it (`village_layout.json`) · kept 2026-11-16
- about 20% of building slots hold street clutter or a small tree instead (`gen_village.py` in the agent's scratchpad) · kept 2026-11-16
- the wall skips the two tiles where the track crosses it (0,17) and (19,17) · kept 2026-11-16
- the cat row is j=6, open now; buildings later placed in the academy or hospital lots may hide parts of it · kept 2026-11-16
- startup checks for lots, doors, tile keys and rooftop rows log errors and do not quit · kept 2026-11-16

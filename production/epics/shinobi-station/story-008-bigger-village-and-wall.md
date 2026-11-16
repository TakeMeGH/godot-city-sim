# Story 008: Bigger village in districts, ringed by a wall

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

- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/village/village_scene.gd`
- `src/village/camera_rig.gd`
- `src/villagers/village_paths.gd`
- `src/villagers/villager_routines.gd`
- `assets/art/wall.png`, `assets/art/src/wall.aseprite`
- `tests/integration/village/bigger_village_test.gd`

---

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

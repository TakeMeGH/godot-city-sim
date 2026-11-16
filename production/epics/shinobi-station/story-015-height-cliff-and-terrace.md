# Story 015: Height: a cliff and a raised terrace

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
**Requirement**: Brief MVP feature 15

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 15, its Look (a tall plain cliff behind) and its Avoid list (no carved faces):*

- [ ] A plain rock cliff runs along the back of the village behind the wall, drawn in Aseprite, with no carvings or faces; from the default camera it frames the village and always sorts behind everything in front of it
- [ ] One district stands on a raised terrace about one storey high, with retaining-wall faces on its open sides, drawn in Aseprite
- [ ] Stairs join the terrace to the street; villagers walk up and down them as part of their paths and stand at the terrace's height when on top
- [ ] Buildings, lanterns, props and villagers on the terrace stand at its height, and depth sorting with the terrace, its walls and the stairs is right from every camera position
- [ ] Paths treat the terrace edges as blocked except at the stairs, and all startup checks (doors reachable, lots, tile keys, stations) still pass
- [ ] The terrace and cliff can be edited in the editor: the terrace ground and the wall and stair pieces are saved in the scene like the other objects
- [ ] Heights and offsets live in data files, never in code

---

## Implementation Notes

- Heights are a per-tile value (a second TileMapLayer for the terrace top, or a height custom-data layer on the ground) read by the path grid and by the y offset of anything standing on it
- Raising a sprite by the terrace height must not change its sort point, or it will sort wrongly against the street in front

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 016: shadows cast onto the terrace and from its walls
- Story 017: ground detail on the terrace top

---

## Files

- `assets/art/cliff_*.png`, `terrace_wall_*.png`, `stairs_*.png`, `assets/art/src/*.aseprite`
- `assets/tiles/village_tiles.tres`
- `src/village/village_scene.tscn`
- `src/village/village_scene.gd`
- `src/villagers/village_paths.gd`
- `src/villagers/villager.gd`
- `assets/data/village_tuning.json`
- `tests/integration/village/terrace_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the cliff, the terrace and a villager on the stairs in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`
- Unlocks: `production/epics/shinobi-station/story-016-cast-shadows.md`, `production/epics/shinobi-station/story-017-ground-detail.md`

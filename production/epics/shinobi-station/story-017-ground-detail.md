# Story 017: Ground detail

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 17

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 17 and its References (Potion Permit's rich ground detail; Moonlighter's textured materials and street clutter):*

- [ ] Where grass meets dirt, cobble, sand and the riverbank, the edge is a soft drawn transition (terrain tiles drawn in Aseprite), so tile edges no longer read as diamonds
- [ ] A detail layer scatters grass tufts, pebbles, small flowers, fallen leaves and puddles, densest at path edges and under trees and never in the middle of a street
- [ ] Streets have worn edges where dirt frays into grass
- [ ] The transitions and the detail are painted in the editor (TileSet terrains and a detail TileMapLayer or placed decals), saved in the scene
- [ ] Villagers' paths are unchanged: the detail layer has no effect on walkable tiles
- [ ] Every new tile and decal follows the art rules (hue-shifted ramps, top-left light, no anti-aliasing)
- [ ] Before-and-after screenshots show the change at the same camera positions

---

## Implementation Notes

- Godot TileSet terrains (match corners and sides) for the transitions; the existing ground TileMapLayer keeps its tile names for the path grid
- The detail layer sits above the ground and below the y-sorted World

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 018: animated water and falling leaves
- Story 015: terrace walls and stairs

---

## Files

- `assets/art/tiles*.png`, `assets/art/ground_detail.png`, `assets/art/src/*.aseprite`
- `assets/tiles/village_tiles.tres`
- `src/village/village_scene.tscn`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (before and after at the centre and two other views) + sign-off in `production/qa/evidence/story-017-ground-detail-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-015-height-cliff-and-terrace.md`
- Unlocks: `production/epics/shinobi-station/story-019-lighting-and-colour.md`

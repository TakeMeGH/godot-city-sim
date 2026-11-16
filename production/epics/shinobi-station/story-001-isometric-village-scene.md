# Story 001: Isometric village scene

> **Epic**: Shinobi Station
> **Status**: In Progress
> **Layer**: Foundation
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 1, its Look and references and its Camera line:*

- [ ] The Aseprite sheets in `prototypes/shinobi-station/assets/` are imported into the Godot project (PNG sheets plus the `.aseprite` sources under `assets/`), with texture filtering off so pixels stay sharp
- [ ] The village map (12x12 tiles of 64x32: grass, dirt streets, cobble plazas, sand training ground, platform, track, water, forest floor) is built from a data file, not hard-coded
- [ ] Houses, towers, shops, the station, trees, lanterns and street props sit on their tiles at the same ground anchors as the prototype
- [ ] Everything depth-sorts correctly: a villager walking behind a house is hidden by it, in front of it is drawn over it, at any position
- [ ] The scene renders at a native 480x270 and scales by whole numbers, with no sub-pixel shimmer while the camera moves
- [ ] The camera drifts slowly over the village after 6 s without input, pans by drag or arrow keys, and stays inside the village's range
- [ ] Lanterns have an unlit and a lit frame, and a `set_lit(bool)` call to switch them
- [ ] The look matches the prototype's iteration-1 screenshots (`prototypes/shinobi-station/evidence/iteration-1-*.png`): nothing missing, clipped or out of order
- [ ] Layout and camera values live in a data file, never in code

---

## Implementation Notes

- The prototype is the reference, not the source: write the Godot code fresh in GDScript (brief, Out of scope)
- Read `docs/engine-reference/godot/` before using an API: 4.7 is past the model's training data
- Sort order: a `Node2D` with `y_sort_enabled`, each sprite's origin on its ground anchor (`ax`, `ay` in the prototype's sprite table)
- Pixel look: project settings with 480x270 viewport, `canvas_items` stretch, `keep` aspect, integer scale; nearest texture filter

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the train, the track's moving parts
- Story 003: villagers and the day clock
- Story 006: the night tint, window glow and lantern glow
- Story 007: the HUD, pause and speed

---

## Files

- `src/village/village_scene.tscn` — created (main scene: Ground, y-sorted World, CameraRig)
- `src/village/village_scene.gd` — created (map, ground tiles, placements, Lantern.set_lit, add_entity, tile_to_world)
- `src/village/camera_rig.gd` — created (drift, drag and arrow-key pan, clamp, --cam / --freeze-camera)
- `assets/data/village_layout.json` — created (map, legend, placements, doors, sprite table)
- `assets/data/village_tuning.json` — created (camera values)
- `assets/art/*.png`, `assets/art/src/*.aseprite` — created (25 sheets and sources from the prototype)
- `project.godot` — modified (main scene, 480x270 viewport, integer scaling, nearest filter, pixel snap)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (the village by day, and the camera panned to two corners) + sign-off in `production/qa/evidence/story-001-isometric-village-scene-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/shinobi-station/story-002-steam-train-and-station.md`, `production/epics/shinobi-station/story-003-villager-routines.md`

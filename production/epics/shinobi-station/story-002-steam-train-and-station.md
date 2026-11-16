# Story 002: Steam train and station

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 2 and its First minute:*

- [ ] A steam locomotive and 2 carriages run along the track and loop: the first train arrives 6 s after the scene starts, then every 45 s
- [ ] The train slows into the station, stops with its front at the platform stop point, waits 9 s, then pulls out and leaves the screen
- [ ] The locomotive and carriage sprites depth-sort against the villagers and buildings like any other sprite
- [ ] Wheels turn (two frames, swapped by distance travelled, not by time), and the night frames are used when story 006's night flag is set
- [ ] Smoke puffs rise from the chimney, more often while moving and less while stopped, and fade out
- [ ] The train emits `arrived(platform_tiles)` and `departing()` signals; boarding and stepping off is built in story 003 on top of them
- [ ] A short whistle plays at arrival and departure through Web Audio-style one-shot audio, and mute silences it
- [ ] Train timing and speed values live in the tuning data file

---

## Implementation Notes

- One `Train` node that owns the locomotive and carriages as child sprites, moved along the track line in tile units
- Keep logic on the physics step, never on a real-time timer, so speed 2 and 3 in story 007 scale it correctly

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: villagers boarding and stepping off
- Story 005: the messenger hawk
- Story 006: night tint and the train's headlamp glow

---

## Files

- `src/train/train.gd`
- `src/train/train.tscn`
- `src/train/smoke_puff.gd`
- `assets/data/village_tuning.json`
- `tests/integration/train/train_station_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-001-isometric-village-scene.md`
- Unlocks: `production/epics/shinobi-station/story-003-villager-routines.md`

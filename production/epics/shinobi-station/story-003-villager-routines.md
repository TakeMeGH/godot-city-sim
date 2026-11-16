# Story 003: Villager routines

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3 (and Your systems: village simulation, train in the village)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 3, its Core loop and its Goal & fail state (no goal, no failure):*

- [ ] A day clock runs from the start time, with a configurable day length, and emits `dawn`, `dusk` and `new_day` signals
- [ ] 18 villagers (ninjas, kunoichi and elders) each have a home door and a name
- [ ] After dawn they leave home on a stagger; after dusk they walk home and disappear indoors; a few stay out as the night watch
- [ ] Villagers choose among training ground, the station, the shop, the square and a walk, with weights per villager type, and linger there for 3 to 10 s
- [ ] They walk the street and plaza tiles only, by shortest path, never through buildings, with front and back walk cycles mirrored for all four diagonals
- [ ] At the training ground they train with punch and kick poses
- [ ] Waiting at the platform, they board on the train's `departing` signal; passengers step off at `arrived` and stand on the platform for a moment, then carry on
- [ ] Each villager's current activity is available as text for story 007
- [ ] Walk speeds, counts, weights and linger times live in the tuning data file

---

## Implementation Notes

- A small state machine per villager (`home`, `walk`, `idle`, `wait`), with `AStarGrid2D` on the tile grid for paths
- Randomness through one seeded generator, never the engine's global one
- Villager sprites depth-sort with the world from story 001

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: kids, errand sprinting and the rooftop dash
- Story 005: events
- Story 006: night tint and lit windows
- Story 007: clicking a villager and the HUD

---

## Files

- `src/village/day_clock.gd`
- `src/villagers/villager.gd`
- `src/villagers/villager.tscn`
- `src/villagers/villager_routines.gd`
- `src/villagers/village_paths.gd`
- `assets/data/village_tuning.json`
- `tests/unit/villagers/villager_routines_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Test: waived at qa.level minimal

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-001-isometric-village-scene.md`, `production/epics/shinobi-station/story-002-steam-train-and-station.md`
- Unlocks: `production/epics/shinobi-station/story-004-npcs-running-around.md`, `production/epics/shinobi-station/story-005-small-events-and-log.md`

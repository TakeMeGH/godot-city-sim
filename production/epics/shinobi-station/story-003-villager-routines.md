# Story 003: Villager routines

> **Epic**: Shinobi Station
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

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

- `src/village/day_clock.gd` — created (DayClock: time of day, day count, dawn / dusk / new_day, --time user arg)
- `src/villagers/village_paths.gd` — created (AStarGrid2D over street, plaza, platform and sand tiles)
- `src/villagers/villager.gd` — created (Villager: path following, walk cycle by distance, four facings, punch and kick poses, lock, activity text)
- `src/villagers/villager.tscn` — created
- `src/villagers/villager_routines.gd` — created (VillagerRoutines: 18 residents, schedules, activities, night watch, boarding and stepping off, find_nearest)
- `src/village/village_scene.tscn` — modified (DayClock and VillagerRoutines nodes)
- `assets/data/village_tuning.json` — modified (day, villager and routine values)

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

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 4/9 passing, 5 deferred (AC-1 clock signals, AC-3 leaving and going home over a day, AC-4 activity choice and linger, AC-6 training poses, AC-7 boarding and stepping off: they happen over time and need play; a headless run reported them working, which is the agent's run, not an observation here)
**Deviations**: ADVISORY — kunoichi have no punch or kick frames (their sheet has 8 frames), so they train by stepping in place; only ninjas show the poses. ADVISORY — `day_clock.gd:81` integer division raises an INTEGER_DIVISION warning (harmless)
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-003-villager-routines/`
**Reviewed by**: self, no independent review

## Calls beyond the design
- kunoichi train by stepping in place; elders never train (`villager_routines.gd`, `villager.gd`) · kept 2026-11-16
- every lingering activity uses idle_min..idle_max (3-10 s) (`villager_routines.gd` `next_activity`) · kept 2026-11-16
- 2 night watchers picked from the ninjas by the seeded generator (`_spawn`) · kept 2026-11-16
- 9 ninjas, 5 kunoichi, 4 elders; 15 home doors, so 3 houses have two residents (`village_tuning.json`) · kept 2026-11-16
- a 0-25 s leave stagger every morning; dusk cuts lingering to 0-8 s (`village_tuning.json`) · kept 2026-11-16
- a villager reaching the platform after dusk goes home; waiting gives up after 40-70 s · kept 2026-11-16
- about 70% of awake villagers start outside (`start_outside_chance`) · kept 2026-11-16
- lock holds timers and boarding but lets walking finish (`villager.gd`) · kept 2026-11-16
- no diagonal moves in pathfinding (`village_paths.gd`) · kept 2026-11-16
- signals named dawn, dusk, new_day as the story says, not past tense (`day_clock.gd`) · kept 2026-11-16

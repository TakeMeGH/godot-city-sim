# Story 004: NPCs running around

> **Epic**: Shinobi Station
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4 (and Your systems: npc running around)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 4 and its First minute:*

- [ ] 3 kids live in the village and play tag in the square and nearby streets during the day, and go home at dusk
- [ ] One kid is "it": they chase the nearest other kid; on a touch, "it" passes on, and the new "it" freezes for about 1 s
- [ ] The kid being chased picks the free tile farthest from "it", so the chase keeps moving
- [ ] A log line appears now and then when "it" changes (hands over to story 007's log display)
- [ ] A share of ninja errands run at the running speed instead of walking, with a catching-breath pause at the end
- [ ] A ninja dashes across the rooftops every 22 s on average: hops from roof to roof along one of the back rows with afterimages, then leaves the screen
- [ ] Kids and runners use the same pathfinding and depth sorting as story 003's villagers
- [ ] Kid speed, errand chance, dash gap and dash speed live in the tuning data file

---

## Implementation Notes

- Kids are a villager variant with their own routine; tag is a small standalone state machine
- Roof heights per building type come from the prototype's roof-height table, kept as data

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the sparring match, hawk, cat and lantern round
- Story 007: showing names and activities on click

---

## Files

- `src/villagers/kid_tag.gd` — created (KidTag: 3 kids, day out and home at dusk, tag state machine, chase nearest, flee to the farthest of 6 tiles, freeze on hand-over, tag_changed signal)
- `src/villagers/rooftop_dash.gd` — created (RooftopDash: a ninja hops roof to roof along a back row with two afterimages, every 22 s on average, dashed signal, --dash-now user arg)
- `src/villagers/villager_routines.gd` — modified (a share of errands run at run_speed with a catching-breath pause; rng made public for the kids and the dash)
- `src/village/village_scene.tscn` — modified (KidTag and RooftopDash nodes after VillagerRoutines)
- `assets/data/village_tuning.json` — modified (kid, tag, errand and rooftop values, the roof-height table)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: Test: waived at qa.level minimal

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-003-villager-routines.md`
- Unlocks: `production/epics/shinobi-station/story-005-small-events-and-log.md`

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 3/8 passing, 5 deferred (AC-1 kids out by day and home at dusk, AC-2 the chase and the 1 s freeze, AC-3 fleeing to the farthest tile, AC-5 running errands with a catching-breath pause, AC-6 dash timing and afterimages: they happen over time and need play; a headless run reported hand-overs, dashes and running errands, which is the agent's run, not an observation here). Passing: AC-4 (tag_changed is emitted for story 007's log), AC-7 (same paths and depth sorting, seen in the stills), AC-8 (values in `village_tuning.json`)
**Deviations**: ADVISORY — the hand-over freeze is 1.2 s (`tag_freeze`), where the criterion says "about 1 s". ADVISORY — kids use one sprite for all three (`kid`), told apart by name only
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-004-npcs-running-around/`
**Reviewed by**: self, no independent review; engine check by godot-gdscript-specialist: no problems found

## Calls beyond the design
- kids are not in VillagerRoutines.villagers: they never board or take an activity (`kid_tag.gd`) · kept 2026-11-16
- tag happens within 5 tiles (Manhattan) of the square at (4,7); "it" runs 8% faster than the others (`village_tuning.json`) · kept 2026-11-16
- with "it" at home, the first kid outside becomes "it" silently, without a log line (`kid_tag.gd`) · kept 2026-11-16
- 18% of errands run at 2.8 tiles/s (`errand_chance`, `run_speed`) · kept 2026-11-16
- the first dash comes 8 s after start, then gaps of 0.6x to 1.4x the 22 s average, along back rows 0, 2, 5 or 6 (`village_tuning.json`) · kept 2026-11-16
- dashing ninjas are a separate sprite, not a resident leaving the routine (`rooftop_dash.gd`) · kept 2026-11-16

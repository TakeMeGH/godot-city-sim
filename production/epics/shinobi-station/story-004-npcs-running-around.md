# Story 004: NPCs running around

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `src/villagers/kid_tag.gd`
- `src/villagers/rooftop_dash.gd`
- `src/villagers/villager_routines.gd`
- `assets/data/village_tuning.json`
- `tests/unit/villagers/kid_tag_test.gd`

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

- Depends on: `production/epics/shinobi-station/story-003-villager-routines.md`
- Unlocks: `production/epics/shinobi-station/story-005-small-events-and-log.md`

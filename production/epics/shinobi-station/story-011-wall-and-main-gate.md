# Story 011: Wall and main gate

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
**Requirement**: Brief MVP feature 11

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 11 and its Avoid list (our own village name; no leaf symbol or named gate):*

- [ ] A gate building stands in the wall gap, drawn in Aseprite, with a sign showing the village name from the data file (not Konoha's name or the leaf symbol)
- [ ] The gate has a day frame and a lit night frame, with lantern glow at night through story 006's glow
- [ ] Two masked guards stand on duty at the gate by day; at dusk one goes home and one stays on watch
- [ ] Villagers sometimes take a walk out through the gate and back (a new activity with a weight in tuning), by street path
- [ ] Depth sorting is right when a villager walks through the gate or behind the wall
- [ ] The guards' activity text reads as a guard's ("guarding the gate") for story 007's label
- [ ] Gate position, guard counts, the village name and weights live in data files, never in code

---

## Implementation Notes

- The gap and the main-street end were reserved by story 008; place the gate on that tile and give the path grid a walkable gate tile
- Guards are story 010's gate-guard role, held with `lock` like the event villagers so routines leave them alone
- "Out through the gate" is a short walk to a point just outside and back, not a leave-the-map

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the wall ring itself
- Story 010: the guard sprites

---

## Files

- `assets/art/gate.png`, `assets/art/src/gate.aseprite`
- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/villagers/villager_routines.gd`
- `src/village/village_scene.gd`
- `tests/integration/village/gate_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the gate by day and at night in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`, `production/epics/shinobi-station/story-010-villager-variety-and-roles.md`
- Unlocks: None

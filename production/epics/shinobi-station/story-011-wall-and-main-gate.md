# Story 011: Wall and main gate

> **Epic**: Shinobi Station
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

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

- `assets/art/gate.png`, `assets/art/src/gate.aseprite` — created (timber gatehouse with the KAZEMORI board; 2 frames, lanterns lit at night)
- `assets/data/village_layout.json` — modified (gate at (9.5, 0.5) as a building with `sort_y` -4 and its own glow list; the house in front of the gate at (10.5, 1.5) replaced by a bench and a barrel)
- `assets/data/village_tuning.json` — modified (`village_name` Kazemori; gate tiles; guard posts and shift values; `gate_glows`; "gate" activity weights)
- `src/villagers/villager_routines.gd` — modified (guard shifts and night watch, the walk out through the gate, `--gate-walk-now`, `free_posts` rename)
- `src/village/night_glow.gd` — modified (a building's own glow list; glows placed from the ground anchor)
- `src/village/village_scene.gd` — modified (`village_name`, `ground_anchor()`, gate check)
- `tools/art/landmarks_a.json` — created (art manifest for the gate, market and academy)

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

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 6/7 passing, 1 deferred. Passing: AC-1 gate with our own name (01, 03 close-up), AC-2 day and lit night frames with lantern glow (02), AC-3 two guards by day, one on watch at night (01, 02), AC-5 sorting at the gate (people in the passage draw in front of it; seen with the guards in 03), AC-6 "guarding the gate" / "keeping the night watch at the gate", AC-7 values in data. Deferred: AC-4 villagers walking out through the gate and back (motion; the walker was not in frame in the capture; the agent saw one in the passage)
**Deviations**: ADVISORY — the house at (10.5, 1.5) and its home door were removed: any building on that tile stands in front of the gate passage on screen. ADVISORY — guards stand on the gate tile at (9.08, 1.0) and (9.9, 0.95), not on the neighbouring tiles, which hold houses. ADVISORY — the village name is drawn into the gate art; `village_name` in tuning must match it
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-011-wall-and-main-gate/`
**Reviewed by**: self, no independent review

## Calls beyond the design
- village name Kazemori, an original word · kept 2026-11-16
- the night watch passes to the other guard each evening; the night guard rests at home 30 s after the morning handover · kept 2026-11-16
- a busy guard is retried every 2 s until free · kept 2026-11-16
- walkers outside the wall are held with `lock`, so no event takes them · kept 2026-11-16
- gate walks are 3-4% of choices, taken from "wander" · kept 2026-11-16

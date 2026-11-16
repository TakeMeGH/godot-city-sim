# Story 013: Academy with a swing tree

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
**Requirement**: Brief MVP feature 13

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 13 and story 004's kids playing tag:*

- [ ] An academy building (2 or 3 storeys, day and lit night frames) with a yard stands on the map, drawn in Aseprite, with a swing tree beside it (a tree sprite with a hanging swing, two swing frames)
- [ ] Academy teachers are stationed in the yard by day and go home at dusk
- [ ] The kids gather at the academy by day: their game of tag (story 004) is played in the yard and the streets next to it (tag centre and radius moved in tuning)
- [ ] One kid at a time takes a turn on the swing, with a 2-frame animation, then goes back to play
- [ ] Kids go home at dusk as before, and "it" hand-overs still reach the log
- [ ] Depth sorting around the academy, the yard and the swing tree is right
- [ ] Positions, swing timing and counts live in data files, never in code

---

## Implementation Notes

- Tag already takes a centre and radius from tuning (`tag_centre`, `tag_radius`): move them to the yard and widen the street tiles it may use
- The swing is a kid state in `kid_tag.gd`: walk to the seat tile, swing for a few seconds, release back to tag
- Teachers are story 010's role, held with `lock` while stationed

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 010: the teacher sprites
- Story 008: the map

---

## Files

- `assets/art/academy.png`, `assets/art/swing_tree.png` and their `assets/art/src/*.aseprite` — created
- `assets/data/village_layout.json` — modified (academy 2x2 at footprint i 13-14, j 7-8, door (14,9); sand yard on (13-15, 9) and (12-15, 10) joined to the plaza; swing tree at (12.5, 9.5); a lantern moved to the yard edge; two hips at (14.5, 11.5) and (15.5, 11.5) lowered from 3 to 2 storeys)
- `assets/data/village_tuning.json` — modified (`academy_stations`, `academy_glows`, tag centre (13, 9) radius 4, swing timing and log chance, swing approach point, check lists)
- `src/villagers/kid_tag.gd` — modified (tag in the yard; one kid at a time takes the swing; `swing_taken` signal and log line; `--swing-now`; yard and swing checks)
- `src/villagers/villager_routines.gd` — modified (teacher stations)
- `src/village/village_scene.gd` — modified (`placed_sprites()` lookup)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the academy yard with kids and a teacher, and a kid on the swing, in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-004-npcs-running-around.md`, `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`, `production/epics/shinobi-station/story-010-villager-variety-and-roles.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 7/7 passing. AC-1 academy with a yard and the swing tree (01, 03), AC-2 teachers stationed in the yard by day (01; home at dusk through the station release), AC-3 tag in the yard (kids in the yard in 01; tag hand-overs logged), AC-4 one kid at a time on the swing (02, and "little Tobi takes a turn on the swing" in its log), AC-5 kids home at dusk, hand-overs still logged, AC-6 depth sorting around the academy and tree (01-03; the swinging kid is a child of the tree, drawn in front of it), AC-7 values in data
**Deviations**: ADVISORY — the swing tree stands in the yard at (12.5, 9.5), not the lot's back corner, where the academy would hide it. ADVISORY — two neighbouring houses were lowered from 3 to 2 storeys so they do not hide the yard (changes story 009's skyline). ADVISORY — kid_tag adds the swing log line itself through VillageLog; wiring it in village_log.gd would be cleaner
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-013-academy-and-swing-tree/`
**Reviewed by**: self, no independent review

## Calls beyond the design
- the academy has its own 16 window glows measured from its night frame, not per-storey copies · kept 2026-11-16
- tag area: centre (13, 9), radius 4, reachable tiles only · kept 2026-11-16
- a swing every 15-35 s for 5-9 s; 60% of swings reach the log · kept 2026-11-16
- the swinging kid is left out of tag, never "it" or frozen · kept 2026-11-16

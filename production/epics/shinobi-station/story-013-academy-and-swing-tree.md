# Story 013: Academy with a swing tree

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

- `assets/art/academy.png`, `assets/art/swing_tree.png`, `assets/art/src/*.aseprite`
- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/villagers/kid_tag.gd`
- `src/villagers/villager_routines.gd`
- `tests/integration/village/academy_test.gd`

---

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

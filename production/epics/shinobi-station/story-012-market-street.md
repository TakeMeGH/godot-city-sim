# Story 012: Market street

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
**Requirement**: Brief MVP feature 12

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 12 and its Look (cloth banners, street clutter):*

- [ ] A market street is laid along a street in the layout, with a ramen stand (counter, banner, steam in two frames), a flower shop and a tea house, each with its own sign, all drawn in Aseprite
- [ ] Market props (crates, baskets, a parasol or two) sit along the street at measured ground anchors, and the shops have day and lit night frames
- [ ] The ramen cook and the shopkeepers are stationed at their places by day and go home at dusk
- [ ] Two new activities, "eat ramen" (sit at the stand) and "browse the market", join the villagers' choices with weights per villager type in tuning
- [ ] The current "shop" activity now goes to the market shops
- [ ] The stand closes at dusk: steam off and its lantern lit
- [ ] Activity texts read well in story 007's label ("eating ramen", "browsing the market")
- [ ] Positions, weights and linger times live in data files, never in code

---

## Implementation Notes

- The street and its shop tiles were reserved by story 008; roles come from story 010
- Steam is a 2-frame sprite swapped on a timer, like the train's smoke, drawn above the stall
- Seat points at the stand are tile points in the layout data, one villager per seat

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: house and block variants
- Story 010: the cook and shopkeeper sprites

---

## Files

- `assets/art/ramen_stand.png`, `flower_shop.png`, `tea_house.png`, market props, `assets/art/src/*.aseprite`
- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/villagers/villager_routines.gd`
- `src/village/village_scene.gd`
- `tests/integration/village/market_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in); retained screenshots of the market by day and at night in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`, `production/epics/shinobi-station/story-009-building-variety.md`, `production/epics/shinobi-station/story-010-villager-variety-and-roles.md`
- Unlocks: None

# Story 012: Market street

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

- `assets/art/ramen_stand.png`, `ramen_steam.png`, `flower_shop.png`, `tea_house.png`, `prop_basket.png`, `prop_parasol.png`, `prop_buckets.png`, `prop_stool.png` and their `assets/art/src/*.aseprite` — created
- `assets/data/village_layout.json` — modified (market lane on row 14, i 10-15, joined to the main street; flower shop (11.5,13.5), tea house (13.5,13.5), ramen stand (15.5,13.5); stall props; two lanterns; `ramen_seats`; buildings in `building_sprites`)
- `assets/data/village_tuning.json` — modified (`market_stations`, eat-ramen and browse activities and weights, browse spots, `ramen_glows`, check lists)
- `src/villagers/villager_routines.gd` — modified (cook and shopkeepers stationed by day; eat ramen at a free stool; browse; shop goes to the market doors)
- `src/village/village_scene.gd` — modified (steam attached to the stand; steam check)
- `src/village/ramen_steam.gd` — created (RamenSteam: frame swap by day, hidden when the stand closes)

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

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 7/8 passing, 1 deferred. Passing: AC-1 market lane with the ramen stand (banner, steam), flower shop and tea house (01), AC-2 props and night frames (01, 02), AC-3 cook and shopkeepers stationed by day (cook behind the counter in 01; the agent's probe showed all four at their places and home at dusk), AC-4 eat-ramen and browse activities (a customer at the counter and browsers in the lane in 01), AC-5 shop activity goes to the market doors, AC-6 the stand closed at night with its lantern lit (02), AC-8 values in data. Deferred: AC-7 how the activity texts read in the click label (not captured)
**Deviations**: ADVISORY — customers stand at the stools; the villager sheets have no sitting frame. ADVISORY — the row-15 houses and the station stand in front of the market lane, so the default camera sees the lane only in part. ADVISORY — every run ends with a "2 ObjectDB instances leaked at exit" warning, also seen before this story (the train's whistle `AudioStreamWAV`, per story 009's run)
**Test Evidence**: waived at qa.level minimal; run observed in `production/qa/evidence/story-012-market-street/`
**Reviewed by**: self, no independent review

## Calls beyond the design
- the market is its own lane on row 14 with the shops facing it, rather than shops on street j=12 · kept 2026-11-16
- ramen can be chosen only while the cook is on duty; a full or closed stand falls back to browsing, then wandering · kept 2026-11-16
- the third shopkeeper minds the old shop at (12, 11) · kept 2026-11-16
- the cook sorts behind the stand, so only his head shows over the counter · kept 2026-11-16
- the lantern hidden behind the stand moved to the lane's east end · kept 2026-11-16

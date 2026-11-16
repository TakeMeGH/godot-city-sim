# Story 009: Building variety

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 9

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 9 and its Look (rooftop water tanks and washing lines are the signature detail):*

- [ ] At least 3 roof colours and 3 wall colours exist across the buildings, as separate sprite sheets drawn in Aseprite (no tint or modulate in code), with warm terracotta and red-orange staying the main range
- [ ] The house and block sprites also come in 2-storey and 3-storey versions, each with a day frame and a lit-window night frame
- [ ] Rooftop details are drawn in Aseprite and picked per building from the layout data: at least 3 water-tank shapes, laundry lines, and signs or banners
- [ ] Every new sprite follows the art rules: hue-shifted ramps (8 to 16 colours per material), 1 px dark outline, top-left light, no anti-aliasing, and a measured ground anchor entered in the sprite table
- [ ] The layout data picks a variant for each placement, and no two neighbouring buildings share the same roof, wall and storeys (a startup check reports identical neighbours)
- [ ] Tall buildings hide villagers walking behind them correctly, and the rooftop-dash roof-height table has an entry for every new building type
- [ ] The night switch and window glow from story 006 work for every new building
- [ ] The `.aseprite` sources are kept in `assets/art/src/` and the sheets in `assets/art/`, imported with filtering off
- [ ] Before-and-after screenshots show the variety, with nothing clipped, missing or out of order

---

## Implementation Notes

- Follow the Aseprite guide the brief points to: palette ramps first, coarse to fine, view after each pass, lint each sprite
- Build the variants from layered sources (wall layer, roof layer, detail layer) so colour variants are exports, not redraws
- Window positions on the new storeys need glow offsets in the tuning data (story 006's `window_glows`)

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the map and where buildings stand
- Stories 011 to 014: the gate, market shops, academy and hospital (their own sprites)

---

## Files

- `assets/art/*.png` (new house, block, tower and shop variants), `assets/art/src/*.aseprite`
- `assets/data/village_layout.json`
- `assets/data/village_tuning.json`
- `src/village/village_scene.gd`
- `src/village/night_glow.gd`
- `src/village/daylight.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (the village by day, close-ups of the variants, and a night view) + sign-off in `production/qa/evidence/story-009-building-variety-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-008-bigger-village-and-wall.md`
- Unlocks: `production/epics/shinobi-station/story-012-market-street.md`

# Story 009: Building variety

> **Epic**: Shinobi Station
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

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

- `assets/art/<type>_s<n>_<roof>_<wall>.png` — created (81 sheets: house_block and house_hip s1-s3, tower s1-s2, shop s1; roofs terra / red / slate, walls cream / ochre / white; 2 frames day / night)
- `assets/art/roof_tank_round.png`, `roof_tank_square.png`, `roof_tank_barrel.png`, `roof_laundry.png`, `roof_sign.png` — created (rooftop details)
- `assets/art/src/<type>_s<n>.aseprite`, `assets/art/src/roof_*.aseprite` — created (layered sources; colours are layer exports)
- `assets/data/village_layout.json` — modified (86 sprite-table entries with storeys, roof height and detail points; building placements re-skinned in place with variants and `details`)
- `assets/data/village_tuning.json` — modified (`storey_px`)
- `src/village/village_scene.gd` — modified (sprite_info, is_building, building_sprite, building_storeys; rooftop details as child sprites; startup check for identical neighbours and bad detail points)
- `src/village/night_glow.gd` — modified (window glows per storey)
- `src/village/daylight.gd` — modified (doc comment)
- `src/villagers/rooftop_dash.gd` — modified (roof height from the sprite table)
- `tools/art/build_variants.lua`, `build_details.lua`, `variety.py`, `building_variants.json` — created (the generators, kept out of the scratchpad)

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

## Story-done check (2026-11-16)
**Verdict**: BLOCKED — Visual/Feel sign-off in `production/qa/evidence/story-009-building-variety-evidence.md` is not ticked; it is yours
**Criteria**: 9/9 pass in stills and runs; AC-6 (villagers hidden behind tall buildings) is seen in stills only
**Deviations**: ADVISORY — the `red` roof's lightest step reads slightly salmon at the hip apex. ADVISORY — rooftop details do not raise the dash height, so a dashing ninja passes through tanks. ADVISORY — re-running story 008's `gen_village.py` would drop the variants; `variety.py` re-applies them
**Reviewed by**: self, no independent review

## Calls beyond the design
- the block's and shop's built-in water tank became the `roof_tank_round` detail, put back on 25 of 30 blocks and shops · kept 2026-11-16
- on blocks and shops "roof colour" recolours the parapet and trim; the flat roof stays grey concrete · kept 2026-11-16
- the shop's original sand walls became the `ochre` ramp for every type · kept 2026-11-16
- `building_sprites` kept; a sprite whose table `type` is in it counts as a building · kept 2026-11-16
- each storey repeats the s1 window glows 14 px higher · kept 2026-11-16
- variant choice is fixed data from a seeded script (`variety.py`, seed 9), no runtime randomness · kept 2026-11-16

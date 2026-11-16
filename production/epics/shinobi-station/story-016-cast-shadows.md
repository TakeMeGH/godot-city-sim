# Story 016: Cast shadows and wall shading

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 16

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 16 and its Look (warm sun, cool blue shadows; Kingdom Two Crowns and Potion Permit's layered light and shadow):*

- [ ] Buildings, trees, wall and fence pieces, landmarks, props and villagers cast soft-edged shadows onto the ground, all from one sun direction
- [ ] The sun's direction and the shadows' length follow the day clock: long in the morning and evening, short at midday, fading out at dusk and absent at night
- [ ] Shadows fall on the ground and the terrace top only: never over the sprite that casts them, and never over things standing in front of the caster
- [ ] A darker band shades the ground where building and wall bases meet it
- [ ] Shadow colour is a cool, semi-transparent tone, not black, and strength, softness and length are tuning values
- [ ] The editor shows the shadows (or a still preview of them) so placement can be judged
- [ ] A full day at speed x3 holds the frame rate (the measured fps is recorded; no frame budget is set for the project)

---

## Implementation Notes

- Code is fine here (the brief allows code where it is the better way): a shadow pass under the y-sorted World, e.g. each caster's own silhouette sheared along the sun direction and drawn into one shadow layer, or footprint-and-height polygons
- Use the sprite table (footprint, storeys, roof height) for heights; villagers use their sprite height

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 018: drifting cloud shadows
- Story 019: colour grading and night lighting

---

## Files

- `src/village/shadows.gd`
- `src/village/village_scene.tscn`
- `src/village/village_scene.gd`
- `assets/data/village_tuning.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (morning, midday and evening, and a close-up of a street) + sign-off in `production/qa/evidence/story-016-cast-shadows-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-015-height-cliff-and-terrace.md`
- Unlocks: `production/epics/shinobi-station/story-018-ambient-motion.md`, `production/epics/shinobi-station/story-019-lighting-and-colour.md`

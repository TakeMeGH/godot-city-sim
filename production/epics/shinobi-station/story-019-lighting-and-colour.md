# Story 019: Lighting and colour

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
**Requirement**: Brief MVP feature 19

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 19 and its Look (warm afternoon sun, cool blue shadows, lit windows and lantern glow at night):*

- [ ] Colour grading follows the time of day: golden light in the morning and evening, neutral at midday, cool blue shadows, blending smoothly into story 006's night tint
- [ ] A light haze fades the back of the village and the forest ring a little toward the sky colour, so the view has depth
- [ ] A soft vignette darkens the screen corners without touching the HUD
- [ ] At night lanterns, lit windows and the train's headlamp bloom softly and throw warm light pools on the ground
- [ ] Night stays readable: villagers and streets can still be made out
- [ ] Every effect's strength is a tuning value, and each can be switched off
- [ ] Morning, midday, dusk and night screenshots show the grading before and after

---

## Implementation Notes

- Code and shaders are fine: a screen-space grading pass (CanvasLayer with a full-screen shader, or WorldEnvironment glow with HDR 2D on Forward+), checked against Godot 4.7's 2D rendering notes in `docs/engine-reference/godot/`
- Replace or extend `daylight.gd`'s CanvasModulate rather than stacking a second tint on it

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 016: cast shadows
- Story 018: ambient motion

---

## Files

- `src/village/daylight.gd`
- `src/village/night_glow.gd`
- `assets/shaders/grade.gdshader`
- `src/village/village_scene.tscn`
- `assets/data/village_tuning.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (morning, midday, dusk and night, before and after) + sign-off in `production/qa/evidence/story-019-lighting-and-colour-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-016-cast-shadows.md`, `production/epics/shinobi-station/story-017-ground-detail.md`, `production/epics/shinobi-station/story-018-ambient-motion.md`
- Unlocks: None

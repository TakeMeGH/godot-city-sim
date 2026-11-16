# Story 018: Ambient motion

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
**Requirement**: Brief MVP feature 18

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 18 and its References (Kingdom Two Crowns and Potion Permit's ambient motion):*

- [ ] Soft cloud shadows drift slowly across the ground and roofs, at a speed and density set in tuning
- [ ] Trees sway gently, each on its own phase so the forest never moves in sync; only the leaf clusters move, trunks stay put
- [ ] The river and pond water shimmers with moving light glints
- [ ] Banners, laundry and noren curtains flutter
- [ ] Some houses send up chimney smoke at times (mornings and evenings)
- [ ] A flock of birds crosses now and then, leaves fall from the big trees, and fireflies drift over grass and the river at night
- [ ] All motion follows the game speed and stops when paused, and a reduced-motion setting in tuning turns the decorative motion off
- [ ] A full day at speed x3 holds the frame rate (the measured fps is recorded)

---

## Implementation Notes

- Code and shaders are fine (the brief allows them where better): a vertex-sway shader on tree sprites with a per-instance phase, a scrolling noise texture for cloud shadows, animated water through the TileSet or a shader
- Drawn frames from Aseprite where motion is a shape change (banners, birds, leaves)

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 016: cast shadows from the sun
- Story 019: lighting and colour grading

---

## Files

- `src/village/ambient_motion.gd`
- `assets/shaders/sway.gdshader`, `assets/shaders/cloud_shadows.gdshader`, `assets/shaders/water.gdshader`
- `assets/art/bird.png`, `leaf.png`, `firefly.png`, `assets/art/src/*.aseprite`
- `src/village/village_scene.tscn`
- `assets/data/village_tuning.json`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (cloud shadows over a street, the river, a night view with fireflies; motion itself is judged in play) + sign-off in `production/qa/evidence/story-018-ambient-motion-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-016-cast-shadows.md`
- Unlocks: `production/epics/shinobi-station/story-019-lighting-and-colour.md`

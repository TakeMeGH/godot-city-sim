# Story 006: Day and night

> **Epic**: Shinobi Station
> **Status**: In Progress
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6 (and Your systems: day and night)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 6, its Challenge and its Goal & fail state:*

- [ ] A daylight value from the day clock (story 003) fades smoothly through dawn and dusk and is fully dark at night
- [ ] A night tint (multiply, blue-purple) and a warm dusk and dawn glow cover the whole view, at a strength set in the tuning data file
- [ ] Buildings, towers, shops and the station switch to their lit-window frames once it is dark
- [ ] Lit lanterns, windows and the train's headlamp cast a soft additive glow on the ground and walls, brighter as it gets darker
- [ ] The train runs with its lit night frames after dark
- [ ] One full day plays through morning commute, midday training, dusk lanterns, night quiet and back to morning, with no end state and no game over
- [ ] The tint and glow are the only art made in code: every sprite still comes from the Aseprite sheets

---

## Implementation Notes

- A `CanvasModulate` for the tint and additive `PointLight2D` or glow sprites for the lamps, checked against Godot 4.7's 2D lighting notes in `docs/engine-reference/godot/`
- Window frames are the second frame of each building sheet; swap on the clock's `dusk` / `dawn` signals

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the lantern round that lights the lanterns
- Story 007: the clock HUD and speed control

---

## Files

- `src/village/daylight.gd` — created (Daylight: daylight and warmth from the clock, CanvasModulate night tint and dusk/dawn warmth, building lit-window frames and train night frames below 0.5 daylight)
- `src/village/night_glow.gd` — created (NightGlow: additive radial glow for lit lanterns, building windows and the train headlamp on a canvas layer above the tint)
- `src/train/train.gd` — modified (is_running and front_position for the headlamp glow)
- `src/village/village_scene.tscn` — modified (NightTint, Daylight and NightGlow nodes)
- `assets/data/village_tuning.json` — modified (night tint, warmth, daylight curve and glow values)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (dawn, midday, dusk and deep night) + sign-off in `production/qa/evidence/story-006-day-and-night-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-005-small-events-and-log.md`
- Unlocks: `production/epics/shinobi-station/story-007-idle-controls-and-hud.md`

## Story-done check (2026-11-16)
**Verdict**: BLOCKED — Visual/Feel sign-off in `production/qa/evidence/story-006-day-and-night-evidence.md` is not ticked; it is yours
**Criteria**: 5/7 passing in stills (AC-2, AC-3, AC-4, AC-5, AC-7), 2 need play (AC-1 the smooth fade, AC-6 a full day)
**Deviations**: ADVISORY — windows light when daylight drops below 0.5 (the prototype's rule), not on the clock's dusk / dawn signals as the Implementation Notes suggest. ADVISORY — the night is fairly light at the prototype's `night_strength` 0.62
**Reviewed by**: self, no independent review

## Calls beyond the design
- glow drawn on CanvasLayer 1 following the camera, so the tint cannot darken it; story 007's HUD goes above it (`village_scene.tscn`) · kept 2026-11-16
- window glow on every building in the layout's building_sprites list, two glows each as in the prototype (`night_glow.gd`) · kept 2026-11-16
- the four existing-file edits were applied by the orchestrating session after the agent's write guard stopped it (`train.gd`, `village_scene.tscn`, `village_tuning.json`) · kept 2026-11-16

# Story 006: Day and night

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- `src/village/daylight.gd`
- `src/village/night_glow.gd`
- `assets/data/village_tuning.json`

---

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

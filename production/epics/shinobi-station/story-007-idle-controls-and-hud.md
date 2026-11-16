# Story 007: Idle controls and HUD

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 7

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 7 and its Controls:*

- [ ] Space pauses and resumes; a "Paused" panel shows while paused
- [ ] Keys 1, 2 and 3 set the simulation speed to x1, x2 and x3 (the values from the tuning data file); the whole village, train and clock scale with it
- [ ] A title screen shows the name and the controls, and Enter, Space or a click starts the day
- [ ] Clicking a villager (and not dragging) selects the nearest one and shows a label with their name and what they're doing, which follows them and clears after a few seconds
- [ ] A small HUD shows the day, time and part of the day, the speed, and the next-train countdown
- [ ] The log from story 005 shows as up to 4 recent lines that fade after about 9 s
- [ ] H hides and shows the HUD, M mutes, and R starts a new day
- [ ] All HUD text is at least 14 px at 1080p with 3:1 contrast, and none overlaps another text
- [ ] Controls are shown on screen, with standard defaults and nothing inverted

---

## Implementation Notes

- A `CanvasLayer` HUD over the pixel viewport; use the Control nodes and Theme resources, not hand-drawn text
- Speed is a multiplier on the simulation step, never a change to the physics step itself

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: camera drag and arrow-key panning
- Story 005: creating the log lines

---

## Files

- `src/ui/hud.tscn`
- `src/ui/hud.gd`
- `src/ui/title_screen.tscn`
- `src/ui/villager_label.gd`
- `src/village/simulation_speed.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched (title, play with HUD and log, paused, a selected villager) in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-005-small-events-and-log.md`, `production/epics/shinobi-station/story-006-day-and-night.md`
- Unlocks: None

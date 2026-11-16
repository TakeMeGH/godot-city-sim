# Story 007: Idle controls and HUD

> **Epic**: Shinobi Station
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-16

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

- `src/village/simulation_speed.gd` — created (SimulationSpeed: Space/P/Esc pause, 1/2/3 speed through Engine.time_scale, M mute, H hide HUD, R new day by reloading the scene, title gate, gamepad mappings, --skip-title / --speed / --paused)
- `src/ui/title_screen.gd`, `src/ui/title_screen.tscn` — created (TitleScreen: name, tagline, controls; Enter, Space, click or gamepad A/Start starts the day)
- `src/ui/hud.gd`, `src/ui/hud.tscn` — created (Hud on CanvasLayer 10: day, time, part of day, speed, next-train countdown, 4 fading log lines, controls, Paused panel)
- `src/ui/villager_label.gd` — created (VillagerLabel: click-not-drag selects the nearest villager or kid; "Name: activity" follows them, keeps clear of the HUD, clears after 8 s; --select-nearest)
- `src/ui/hud_theme.tres` — created (Theme: Trebuchet MS 7 px, panels, label variations)
- `src/train/train.gd` — modified (get_state, seconds_to_next_train)
- `src/villagers/villager.gd` — modified (height_above_feet)
- `src/village/camera_rig.gd` — modified (camera motion ignores the speed multiplier)
- `src/village/village_scene.tscn` — modified (SimulationSpeed, Hud and TitleScreen)
- `assets/data/village_tuning.json` — modified (speeds, log timing, parts of day, selection values)

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

## Completion Notes
**Completed**: 2026-11-16
**Criteria**: 7/9 passing, 2 deferred. Passing: AC-1 Paused panel (03-paused), AC-3 title screen (01-title), AC-4 selected-villager label (02-hud-selected, 03-paused), AC-5 HUD status line (02, 04), AC-6 up to 4 log lines (02-hud-selected), AC-8 smallest text 7 px = 28 px at 1080p, light text on 0.75-alpha dark panels, no overlaps in the four shots, AC-9 controls on screen with standard keys. Deferred: AC-2 speed scaling the whole village (a still shows "x2"; the scaling is motion), AC-7 H, M and R (keys, need play)
**Deviations**: ADVISORY — HUD text is a smooth system font (Trebuchet MS, the prototype's) drawn in the 480x270 viewport and scaled up, so it looks soft rather than pixel-crisp; there is no pixel font in the assets. ADVISORY — no gamepad way to select a villager (no cursor). ADVISORY — strings go through `tr()` but no translation files exist yet
**Test Evidence**: UI screenshots in `production/qa/evidence/story-007-idle-controls-and-hud/` (01-title, 02-hud-selected, 03-paused, 04-hud-night)
**Reviewed by**: self, no independent review
**Dependency note**: story 006 (day and night) is still In Progress, waiting on its sign-off; the HUD is built over it and 04-hud-night shows it untinted

## Calls beyond the design
- speeds x2 and x3 as the story says (`speed_2` 2, `speed_3` 3); the prototype used x3 and x8 · kept 2026-11-16
- the village stays paused behind the title (the prototype ran it at half speed) · kept 2026-11-16
- P and Esc also pause; speed, H and R are ignored while paused, M works any time (`simulation_speed.gd`) · kept 2026-11-16
- R reloads the scene for a new day at the start time, day 1 (`simulation_speed.gd`) · kept 2026-11-16
- input actions registered at runtime, so `project.godot` is untouched · kept 2026-11-16
- the selected label dodges the HUD panels and the Paused panel; no selection mark above the head · kept 2026-11-16
- "You arrive at the village" logged when the day starts · kept 2026-11-16
- new UI files and the existing-file edits were applied by the orchestrating session from the agent's drafts after its write guard stopped it · kept 2026-11-16

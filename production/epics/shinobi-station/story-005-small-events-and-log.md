# Story 005: Small events and the log

> **Epic**: Shinobi Station
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Build step**: core
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5 (and Your systems: small events)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 5 and its First minute:*

- [ ] An event director starts one small event at a time during the day, about every 28 s, rotating through the events; the first one starts 10 s in
- [ ] Sparring: two ninjas run to the training ground, trade punches and kicks for 16 s while up to 4 villagers gather and watch, then one wins and the crowd disperses
- [ ] Messenger hawk: a hawk flies in, lands on the station roof, a ninja sprints to collect the message, and the hawk flies off
- [ ] Cat and sparrow: a sparrow lands on the main street, a cat stalks it, the sparrow escapes over the roofs, and the cat wanders home
- [ ] Evening lantern round: at dusk an elder walks to each lantern in order and lights it with `set_lit(true)` from story 001
- [ ] Each event writes its own one-line log message (what starts, what happens, how it ends) to a log that story 007 displays
- [ ] An event never leaves a villager stuck: whatever ends an event also releases every villager it held
- [ ] Event timing and durations live in the tuning data file

---

## Implementation Notes

- Events are small state machines owned by one director node; each locks the villagers it uses and releases them on end
- Log messages carry the clock time from story 003's day clock

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: lantern and window glow at night
- Story 007: drawing the log

---

## Files

- `src/events/event_director.gd`
- `src/events/spar_event.gd`
- `src/events/hawk_event.gd`
- `src/events/cat_event.gd`
- `src/events/lantern_round.gd`
- `src/village/village_log.gd`
- `assets/data/village_tuning.json`
- `tests/integration/events/event_director_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: Test: waived at qa.level minimal (a playtest note may stand in)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-003-villager-routines.md`, `production/epics/shinobi-station/story-004-npcs-running-around.md`
- Unlocks: `production/epics/shinobi-station/story-006-day-and-night.md`, `production/epics/shinobi-station/story-007-idle-controls-and-hud.md`

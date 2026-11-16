# Story 010: Villager variety and new roles

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
**Requirement**: Brief MVP feature 10

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief's Features item 10 and its Look (each villager type with its own silhouette):*

- [ ] The ninja, kunoichi, elder and kid bodies each come in at least 4 hair styles or colours, 3 skin tones and 3 outfit colours, as sprite sheets drawn or remapped in Aseprite (no tint or modulate in code)
- [ ] Four new roles each have their own silhouette and sheet: shopkeeper, masked gate guard, ramen cook, academy teacher
- [ ] Every sheet keeps the frame layout and ground anchor of its base body, so the four-direction walk cycles, mirroring and poses work unchanged
- [ ] Each resident's look is picked from the seeded generator, the village shows at least 12 distinct looks at once, and no two residents of one house look the same
- [ ] Role villagers spawn with a name and a home and follow the normal routines until stories 011 to 013 station them
- [ ] Clicking a villager shows their role with name and activity (for example "Hoshi, ramen cook: ...")
- [ ] The tag kids and the errand runners use the new sheets too, and story 004's behaviour is unchanged
- [ ] Look tables, role counts and weights live in data files, never in code

---

## Implementation Notes

- One body sheet plus a remap per variant keeps the frames identical; export every variant from the `.aseprite` source
- A look is a record in the data file (body, hair, skin, outfit); the seeded generator picks one per resident
- Roles are a villager type with their own sheet and, for now, the ordinary routine table

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 011 to 013: stationing guards, the cook, shopkeepers and teachers at their places
- Story 009: buildings

---

## Files

- `assets/art/*.png` (variant and role sheets), `assets/art/src/*.aseprite`
- `assets/data/village_layout.json` (sprite table)
- `assets/data/village_tuning.json` (looks, role counts)
- `src/villagers/villager.gd`
- `src/villagers/villager_routines.gd`
- `src/villagers/kid_tag.gd`
- `src/ui/villager_label.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` (a crowd close-up, each role, and the click label) + sign-off in `production/qa/evidence/story-010-villager-variety-and-roles-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/shinobi-station/story-003-villager-routines.md`, `production/epics/shinobi-station/story-004-npcs-running-around.md`, `production/epics/shinobi-station/story-007-idle-controls-and-hud.md`
- Unlocks: `production/epics/shinobi-station/story-011-wall-and-main-gate.md`, `production/epics/shinobi-station/story-012-market-street.md`, `production/epics/shinobi-station/story-013-academy-and-swing-tree.md`

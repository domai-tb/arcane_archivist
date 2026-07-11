# AI Agent Guardrails Specification

This specification converts the setup review into operating rules for AI agents working on **Arcane Archivist**. It complements the development process spec and should be treated as required context for coding, scene editing, validation, and release preparation.

## Purpose

AI agents should help build a nicely playable indie game that can eventually ship on Steam. The main risk is not a lack of ideas. The main risk is expanding systems faster than the game loop, validation, content pipeline, and release process can support.

Agents must therefore prefer:

- playable vertical slices over broad partial systems
- data-backed content over hardcoded content sprawl
- deterministic validation over confidence from inspection
- release-aware constraints over prototype-only shortcuts
- small, reversible changes over sweeping rewrites

## Current Setup Assessment

The project has several strong foundations:

- a Godot 4.7 project that launches through `scenes/bootstrap/Main.tscn`
- a clear knowledge base and living-spec ladder
- the Godot AI plugin installed and the Codex client configured
- useful core scene/script folders for hub, dungeon, player, enemies, rooms, UI, and data definitions
- save, content, run, hub, dungeon, and UI scaffolding

The current setup also has release-risk gaps:

- no `res://tests` suites are present
- no `.github` CI workflow is present
- no `export_presets.cfg` is present
- no top-level project README or game license is present
- `data/` and `resources/` are empty while content is built inside `scripts/core/content_db.gd`
- `scripts/core/app_state.gd`, `scripts/core/content_db.gd`, and `scripts/ui/hub_hud.gd` are already large enough to slow safe AI edits
- several systems from later milestones are present before the first playable slice is locked
- save writes currently go directly to the save path rather than a temp-and-rename flow

## Active Milestone Discipline

Agents must identify the active living spec version before implementing features. Until explicitly changed, assume the project should stabilize the `0.1` loop before further expansion.

For `0.1`, the acceptance target is:

- launch into the library without manual editor setup
- inspect one active request
- start a dungeon dive
- traverse a short procedural floor
- use a starter deck with movement, offense, defense, and utility
- recover the requested tome or fail
- return to the library
- visibly complete or preserve the request state
- persist completed request and archive state across relaunch

Later systems such as broad progression, curses, faction chains, modding, base defense, and generalized tooling should be deferred unless the user explicitly asks to work on them.

## Architecture Guardrails

### State

Keep persistent state, transient run state, and presentation state separate.

Recommended direction:

- `SaveManager`: disk IO, defaults, migration, backup/recovery
- `AppState`: thin coordinator for persistent game state
- request service: active request, queue, deadlines, completion
- archive service: owned tomes/relics, slots, bonuses
- deck service: owned cards, active deck, validation, rewards
- run service/state: current run seed, room sequence, player run values

Avoid adding more responsibilities to `AppState` unless the change is very small and clearly transitional.

### Content

Growing content should not live as large hardcoded tables in scripts.

Preferred path:

1. Keep existing content definitions stable while the loop is being locked.
2. Define a resource or data layout for cards, enemies, rooms, requests, tomes, relics, and research entries.
3. Move one content family first, ideally cards or rooms.
4. Add validation before moving more families.
5. Keep stable IDs forever once saves depend on them.

Content validation should catch:

- missing IDs
- duplicate IDs
- broken references
- invalid reward IDs
- deck role coverage failures
- room templates without reachable progression
- request requirements that cannot be satisfied by available content

### Scenes

Scenes should stay compositional and understandable:

- `scenes/bootstrap`: boot and high-level scene transitions
- `scenes/hub`: hub composition
- `scenes/dungeon`: run controller
- `scenes/rooms`: room templates and runtime rooms
- `scenes/player`: player controller scene
- `scenes/enemies`: enemy scenes
- `scenes/ui`: reusable HUDs and panels
- `scenes/cards`: card UI components

Avoid monolithic scenes and avoid duplicating scenes for content variants that should be data-driven.

### UI

The game should be designed for Steam Deck readability and controller viability early:

- support 1280x800 layouts
- keep the smallest important text at readable size
- avoid mouse-only flows for core gameplay
- avoid UI text overflow in buttons and panels
- define clear focus paths for controller navigation
- plan glyph switching rather than hardcoding keyboard prompts everywhere

## AI Harness Workflow

When using the Godot AI bridge:

1. `session_manage(op="list")` or `editor_state`
2. ensure the intended editor is ready
3. clear editor/game logs before validation when judging fresh errors
4. run `test_run` if tests exist
5. run `project_run` for runtime checks
6. read `logs_read(source="editor", include_details=true)`
7. read `logs_read(source="game", include_details=true)`
8. stop the running game with `project_manage(op="stop")`

If the bridge reports a parse error but direct disk inspection looks valid, run an independent Godot parser/import check before editing around a possibly stale in-memory error.

For command-line validation in this environment, Godot may need normal filesystem access to write its user logs. If a sandboxed headless run crashes while opening `user://logs`, rerun with approved escalation rather than treating that crash as a project failure.

## Required Validation Layers

The project should gain these validation layers as soon as practical:

### Launch Smoke Test

Confirms the main scene launches, the hub appears, and no editor/game errors are emitted.

### Content Validation Test

Confirms content registries load and all references resolve.

### Save/Load Test

Confirms request completion, archive contents, deck state, and settings survive save/load. Include corrupt and older-version fixture saves once migrations matter.

### Dungeon Generation Test

Confirms required rooms exist, the tome room is reachable, seed behavior is deterministic, and generated sequences satisfy the active milestone.

### Gameplay Sanity Test

Confirms the player can complete a minimal loop under controlled conditions. This can start as a scripted/headless smoke path and later become a richer playtest checklist.

## Development Workflow For Agents

For every task:

1. Read the active spec and nearby code.
2. Decide whether the request is within the active milestone.
3. If it is outside the active milestone, either defer it in docs or ask for explicit scope override.
4. Make the smallest coherent change.
5. Add or update validation when the change touches systems, saves, generation, or content.
6. Run the relevant validation.
7. Report what changed, what was validated, and any residual risk.

Do not call a milestone complete because code exists. A milestone is complete only when the acceptance criteria are playable and validated.

## Recommended Near-Term Backlog

Priority order:

1. Add `res://tests` with a minimal Godot AI test suite.
2. Add content validation tests around the current `ContentDB`.
3. Add an automated save/load test using temporary save paths or dependency injection.
4. Add deterministic dungeon generation assertions.
5. Add a top-level README with run, test, and validation instructions.
6. Add export presets for Windows and Linux.
7. Add a CI workflow that runs Godot import/check/test commands.
8. Move one content family out of `ContentDB` into resources or structured data.
9. Split the largest state/UI scripts only when tests protect the current behavior.
10. Create a Steam release checklist tied to `living_spec/0.9.md` and `living_spec/1.0.md`.

## Steam Readiness Guardrails

Use official Steamworks documentation for current release-process details. As of the setup review on 2026-07-11:

- Steam Direct requires a per-app fee and onboarding through Steamworks.
- Valve reviews the store presence and product build before release.
- Review commonly takes several business days, so release plans need buffer.
- Store pages should only show launch-available features and gameplay screenshots.
- Builds must launch on every OS listed on the store page.
- Steam Deck and Steam Machine compatibility emphasizes controller support, correct glyphs, readable display, playable framerate, seamless startup, and Proton/native compatibility.

Official references:

- https://partner.steamgames.com/doc/gettingstarted/appfee
- https://partner.steamgames.com/doc/store/review_process
- https://partner.steamgames.com/doc/steamhardware/compat

## Definition Of Done For Agent Work

A change is ready to hand back when:

- it matches the active living spec or an explicitly requested override
- it is playable or inspectable in context
- content references remain valid
- save/load behavior is considered when persistence is touched
- relevant validation has run or the reason it could not run is documented
- Godot editor/game logs have been checked for runtime work
- no unrelated user changes were reverted
- docs are updated when process, architecture, or release assumptions change


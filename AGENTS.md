# Arcane Archivist Agent Guardrails

This repository is a Godot game project targeting a polished indie release on Steam. AI agents working here must optimize for a playable, testable game rather than speculative system growth.

## Source Of Truth

Read these files before making material gameplay, architecture, or process changes:

1. `knowledge_base/arcane_archivist_design.md`
2. `knowledge_base/development_process_spec.md`
3. `knowledge_base/living_spec/README.md`
4. The active living spec version, starting with `knowledge_base/living_spec/0.1.md`
5. `knowledge_base/ai_agent_guardrails.md`

If the long-term design and the active living spec conflict, the active living spec wins.

## Current Development Posture

Treat the project as pre-release and milestone-driven. The immediate priority is to lock a thin playable loop:

- launch into the library
- inspect the active request
- enter a short dungeon
- use cards in meaningful encounters
- recover the requested tome or fail
- return to the library
- persist the resulting state across relaunch

Do not expand later milestone systems until this loop is testable and stable.

## Hard Rules

- Do not add broad new systems unless they are required by the active living spec.
- Do not mix large refactors with feature work unless the coupling is unavoidable.
- Do not hardcode growing content tables into gameplay scripts when a data/resource path is practical.
- Do not rely only on manual playtesting for milestone completion.
- Do not mark a feature done unless it is playable in context.
- Do not list Steam store features before they are implemented in the current build.
- Do not leave the Godot editor/game running after validation unless explicitly asked.

## Preferred Implementation Shape

- Godot scenes compose gameplay units.
- Scripts hold focused behavior.
- Repeat content belongs in `resources/` or `data/`, loaded and validated by code.
- Persistent library state and transient run state remain separate.
- Save writes should be atomic and migration-aware before save complexity grows further.
- Input actions should be project-defined and testable, not only patched at runtime.

## Validation Expectations

Every meaningful change should include the narrowest useful validation:

- parser/import check for touched GDScript
- content validation for cards, enemies, rooms, requests, tomes, relics, and rewards
- save/load validation when persistence changes
- deterministic generation checks when dungeon structure changes
- Godot AI or headless smoke launch for scene/runtime changes

If validation cannot be run, state that clearly in the final response.

## Godot AI Harness Use

Prefer the Godot AI MCP bridge for editor-aware work when available:

1. Check the editor session and readiness.
2. Clear stale editor/game logs before a validation run.
3. Run the project or tests.
4. Read fresh editor and game logs.
5. Treat retained errors carefully. If a bridge error conflicts with disk state, verify with a direct Godot parser/import check.
6. Stop the running project after validation.

Codex is currently the configured client. OpenCode may be installed but is not configured unless verified again.

## Steam Release Bias

Keep Steam constraints visible throughout development:

- the build must launch cleanly on every listed platform
- store page screenshots and trailers should show real gameplay only
- all listed store features must exist in the submitted build
- controller support, readable 1280x800 UI, no launcher, and stable 30 FPS are important for Steam Deck compatibility
- release review needs schedule buffer

Use official Steamworks documentation when making release-process claims.


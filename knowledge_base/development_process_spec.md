# Arcane Archivist Development Process Specification

This document defines the practical development process for creating **Arcane Archivist** in the current Godot project. It assumes:

- this repository is the canonical game project
- the game is built in Godot
- code and scene work can be performed directly in the project
- required art, audio, and other assets can be requested and integrated when needed
- the living spec in [living_spec](./living_spec/) is the authoritative scope ladder

## Purpose

The process exists to prevent two common failure modes:

- building too much before the core loop is proven
- accumulating scenes, scripts, and data with no stable structure

The correct approach is to build **one thin, playable vertical slice at a time**, lock it, and only then expand content and systems.

## Source Of Truth

The project should be developed against the following document hierarchy:

1. [arcane_archivist_design.md](./arcane_archivist_design.md)
2. [living_spec/README.md](./living_spec/README.md)
3. the current target version inside [living_spec](./living_spec/)
4. implementation notes and technical decisions created during development

Rules:

- the design doc defines the long-term vision
- the living spec defines the current shipping scope
- if the design doc and the current living spec conflict, the living spec wins for implementation
- features outside the active living spec version are deferred, not partially implemented

## Development Principles

The game should be built under these constraints:

- playable first, expandable second
- data-driven where repeat content will grow
- simple systems before flexible systems
- deterministic and debuggable systems over clever hidden behavior
- one responsibility per scene or script where practical
- placeholder content is acceptable if mechanics are readable

The game should avoid:

- premature content tooling
- speculative architecture for post-1.0 features
- hardcoded content tables spread across scripts
- manual scene duplication as a primary authoring model

## Production Model

Development proceeds in versioned milestones aligned to the living spec ladder.

### Phase 1: Foundation

Goal:

- create a runnable Godot project with a clear scene tree, input map, save path, and core folder structure

Deliverables:

- main scene and bootstrap flow
- shared singleton or service layer only where clearly justified
- input actions for movement, interaction, UI, and cards
- base UI framework
- save/load scaffolding
- debug logging and simple developer commands

Exit criteria:

- the project launches without manual editor setup
- scene loading and state transitions work reliably
- save files can be written and reloaded safely

### Phase 2: Vertical Slice 0.1

Goal:

- implement the full minimum loop described in [living_spec/0.1.md](./living_spec/0.1.md)

Deliverables:

- library hub
- one request flow
- one dungeon generation path
- player controller
- basic enemy logic
- starter insight deck
- tome retrieval and return flow
- persistence for request completion and archive state

Exit criteria:

- the player can complete the loop from hub to dungeon and back
- failure and retry work
- the game state persists correctly across relaunch

### Phase 3: System Expansion

Goal:

- grow the game by moving upward through the living spec versions one at a time

Deliverables by milestone:

- `0.2`: archive combinations and stronger persistence
- `0.3`: deck refinement and synergy depth
- `0.4`: patron requests and research loop
- `0.5`: integrated library-dive-archive loop
- `0.6`: progression, curses, replayability
- `0.7`: content-complete core loops
- `0.8`: polish and balance
- `0.9`: production hardening
- `1.0`: release-ready feature set

Exit criteria:

- each version is complete before the next begins
- unresolved bugs from a lower version are fixed before adding higher-scope systems

### Phase 4: Content Multiplication

Goal:

- expand cards, relics, room templates, enemies, requests, and library modules without destabilizing the core game

Rules:

- new content should enter through data, not bespoke code branches
- each new content family needs validation rules and test cases
- content additions should prove they interact correctly with existing systems

### Phase 5: Production Hardening

Goal:

- make the game robust enough to ship

Deliverables:

- save compatibility checks
- crash-resistant loading paths
- performance budgets
- accessibility passes
- platform-specific export checks
- telemetry or debug summaries for balancing

## Recommended Project Structure

The exact folder names can vary, but the repository should converge on a consistent layout similar to:

```text
scenes/
  bootstrap/
  hub/
  dungeon/
  player/
  enemies/
  ui/
scripts/
  core/
  systems/
  components/
  data/
resources/
  cards/
  relics/
  requests/
  rooms/
assets/
  art/
  audio/
  ui/
tests/
knowledge_base/
```

Guidelines:

- scenes hold composition
- scripts hold behavior
- resources hold authorable game data
- assets remain separate from gameplay definitions
- tests target deterministic systems, generators, save logic, and data validation

## System Implementation Order

Within each milestone, systems should usually be implemented in this order:

1. state model
2. data definitions
3. scene scaffolding
4. gameplay logic
5. UI presentation
6. save/load integration
7. debug hooks
8. balancing pass

This order matters because it reduces rework. For example, cards should not be authored as UI-first button scripts. They should start as data plus effect execution rules, with UI binding added afterward.

## Technical Standards

### Scene standards

- each major gameplay unit should have a dedicated root scene
- scene ownership should be obvious from the folder structure
- avoid large monolithic scenes when composition can express the same behavior cleanly

### Script standards

- prefer small scripts with explicit interfaces
- keep state transitions visible and named
- avoid hidden dependencies between unrelated nodes
- use shared utilities only after repeated need is proven

### Data standards

- cards, relics, enemies, requests, room templates, and progression entries should be externalized
- data should use stable identifiers, not scene-path assumptions
- validation errors should fail loudly in development

### Save standards

- persistent library state and transient run state must be separated
- migrations should be planned once persistence becomes non-trivial
- save writes should be atomic where practical

### Debug standards

- every core system should expose enough information to diagnose failures quickly
- procedural generation should support seed logging
- combat and card systems should support event traces in development builds

## Asset Integration Process

Because assets may be provided on request, asset integration should follow a contract:

1. define the asset requirement before requesting it
2. specify format, dimensions, naming, pivot/origin, and intended in-game use
3. integrate the asset behind an existing placeholder-friendly scene or data slot
4. verify readability in the actual game context

Rules:

- gameplay work should not block on final art when placeholders can preserve progress
- assets should plug into stable scene/data contracts rather than force structural rewrites

## Testing And Validation

The game should not rely only on manual playtesting. Each milestone needs explicit validation.

Required validation layers:

- launch test: game boots to the expected entry flow
- save/load test: critical persistent state survives relaunch
- content validation: cards, enemies, rooms, and requests load without broken references
- procedural validation: generated runs satisfy basic structural guarantees
- gameplay sanity test: player can complete the main loop under normal conditions

Where possible, create:

- deterministic test seeds
- reproducible combat scenarios
- fixture saves
- lightweight assertions around content data

## Milestone Workflow

Each living-spec version should be developed with the same loop:

1. choose the active target version
2. extract implementation tasks from that version only
3. build the minimum functional slice
4. run validation and fix blocking defects
5. document technical decisions or scope changes
6. freeze the milestone before advancing

A milestone is not complete when code exists. It is complete when:

- the version’s acceptance criteria are satisfied
- obvious regressions are fixed
- the result is stable enough to serve as the next foundation

## Change Control

Changes should be categorized before implementation:

- `feature`: adds scoped behavior required by the active milestone
- `fix`: corrects behavior already expected by the active milestone
- `refactor`: improves structure without changing behavior
- `content`: adds cards, rooms, enemies, requests, audio, or art
- `tech`: build, tooling, test, export, or debug infrastructure

Rules:

- do not mix major feature work and large refactors unless the coupling is unavoidable
- refactors must preserve milestone behavior
- if a requested feature belongs to a later milestone, record it and defer it

## Definition Of Done

A feature or milestone is done only when all of the following are true:

- the implementation matches the active living spec
- the feature is playable in context, not only present in code
- required data and scene references are stable
- save/load behavior is correct if persistence is involved
- obvious failure cases have been tested
- temporary debug scaffolding is either retained intentionally or removed cleanly
- the knowledge base is updated where the process or architecture changed materially

## What Not To Build Early

The following should be deferred until demanded by the living spec:

- co-op
- modding APIs
- generalized plugin systems
- overly abstract combat effect graphs
- elaborate room editors
- live-service style backend assumptions
- broad optimization work before representative content exists

## Practical Summary

Arcane Archivist should be built as a sequence of locked, playable milestones. The team should prove the smallest real game first, then expand depth, content, and polish in the order already defined by the living spec. Godot scenes should be used for composition, scripts for behavior, and externalized data for scalable content. Every milestone should end in a stable playable build, not a pile of partial systems.

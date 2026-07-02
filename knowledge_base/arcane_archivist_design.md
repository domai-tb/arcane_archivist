# Arcane Archivist – Design Document

This document outlines the core concept and gameplay mechanics for **Arcane Archivist**, a proposed indie game that draws inspiration from recent indie hits while charting its own path.  The project will be implemented entirely using the **Godot** engine.

## Core Concept

Players assume the role of a **magical librarian** responsible for maintaining a sprawling arcane library situated above a shifting dungeon.  Adventurers visit the library seeking knowledge, depositing relics and requesting research.  To satisfy their needs and expand the collection, the player must venture into procedurally generated labyrinths to retrieve forbidden tomes.  The game blends cosy management with roguelike dungeon exploration and deck‑building mechanics.

## High‑Level Goals

1. **Create a unique hybrid of genres** (management, roguelike action, deck‑building) with a coherent theme.
2. **Encourage experimentation and emergent strategies** through systems‑driven design, drawing on lessons from Balatro, Slay the Spire II and Brotato.
3. **Support streaming and social sharing** with memorable, shareable moments analogous to Lethal Company and Content Warning.
4. **Offer modding support** and robust content tools, leveraging Godot’s open‑source nature to foster a community around the game.

## Gameplay Pillars

### 1. Library Management
The library acts as a **persistent hub** where players arrange rooms, stacks and research facilities.  Each placement provides bonuses or unlocks spells.  The layout system takes inspiration from **Backpack Battles**’ adjacency synergies.  Visitors request specific tomes or relics, forcing players to prioritise research tasks and allocate resources.  The hub also houses workshops for crafting new cards and items.

### 2. Procedural Dives
When descending into the labyrinth, the game shifts to a **top‑down roguelike**.  Each run features procedurally generated chambers filled with puzzles, traps and monsters.  The player brings a **deck of “insight cards”** representing actions, spells and skills.  Using cards consumes insight points; players must balance offensive, defensive and utility cards to survive.  The environment includes hidden alcoves, secret passages and optional challenges that reward exploration.

### 3. Combinatorial Systems
- **Relic and Tome Combinations:** Artifacts retrieved from the dungeon slot into archives in the library.  Different combinations grant permanent passive bonuses or unlock new spells.  With dozens of relic categories and thousands of possible combinations, players can customise their playstyle.
- **Card Synergies:** Deck‑building allows players to create powerful combos.  Cards can interact with relics to produce unexpected effects.  Balancing synergy potential against risk (e.g., cards that exhaust when played) adds strategic depth.

### 4. Base Defence Events
At certain points, the library comes under attack by hostile entities.  During these events, players must **defend the library** while continuing research.  They switch between controlling their character in real time (using the same insight cards) and assigning tasks to library staff or automated defences.  Success yields rare rewards; failure may destroy rooms and permanently remove relics.

### 5. Progression and Meta Systems
- **Meta Currency:** Essence gathered from runs is spent on permanent upgrades, new card types and library expansions.
- **Difficulty Modifiers:** Players can enable curses or challenges that increase difficulty in exchange for greater rewards, similar to **Palworld**’s risk–reward and **Hades II**’s Heat system.  
- **Narrative Unfolding:** The game features an overarching story about the origin of the library and the nature of the labyrinth.  Characters evolve through repeat visits, with dialogues unlocking based on player choices and progress.

## Technical Plan

- **Engine Choice – Godot:**  Godot’s scene and node system suits the modular structure of the library and the procedural generation of the labyrinth.  GDScript or C# will be used for rapid iteration on card logic, relic interactions and AI behaviours.  The open‑source license facilitates modding; custom resources (cards, relics, rooms) can be defined in external data files.

- **Procedural Generation:**  The dungeon will be built from reusable room templates connected via procedural algorithms.  Each room can contain puzzle elements, enemies or resource caches.  Algorithms will ensure varied but coherent layouts.

- **Card and Relic Data:**  Cards and relics will be defined in JSON or YAML files loaded at runtime.  Each entry will include properties (cost, effects, triggers) and be easily modifiable.  Designing the data layer early will simplify adding new content and allow the community to create mods.

- **Save System:**  Runs will be saved in progress to allow players to resume mid‑dive.  Meta progression and library layout will be saved using Godot’s built‑in serialization.

- **UI and UX:**  The interface will be clean and inviting, with clear iconography and tooltips.  Accessibility options (colourblind modes, adjustable text sizes) will be included from the start.

## Future Extensions

- **Co‑operative Mode:**  Post‑launch, a co‑op mode could allow two players to explore the labyrinth together, combining decks and coordinating moves.  This would build on the streaming appeal seen in **Lethal Company** and **Content Warning**.
- **Modding API:**  Exposing APIs for custom relics, cards, rooms and quests will empower the community to expand the game.  Documentation and examples will be provided.

## Conclusion

Arcane Archivist aims to synthesise the strengths of recent indie successes—deep systems, compelling hooks, replayability and community engagement—into an original concept.  By leveraging Godot, the project will remain accessible for a small team while delivering a polished and moddable experience.  With careful planning and iterative development, it has the potential to become the next big hit on Steam.

# Arcane Archivist

Arcane Archivist is a Godot 4.7 project about running a magical library above a shifting dungeon.

## Current Focus

- Launch into the library hub
- Inspect the active request
- Dive for the requested tome
- Return to the archive and persist the result

## Run

Open the project in Godot and run `scenes/bootstrap/Main.tscn`.

## Validation

Use the headless smoke checks while developing:

```bash
godot --headless --path . --check-only --script res://scripts/core/app_state.gd
godot --headless --path . --quit-after 3
```

Release-gate tests live in `res://tests/` and are run through the Godot AI test runner in the editor.

## Notes

- Save data is stored under `user://`.
- The active living spec is the version ladder in `knowledge_base/living_spec/`.

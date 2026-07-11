# Arcane Archivist Release Checklist

This checklist tracks the release-readiness work required by `living_spec/0.9.md` and `living_spec/1.0.md`.

## Supported Target Matrix

- Desktop
  - Linux
  - Windows
- Browser
  - Modern desktop browsers
- Mobile
  - Touch-first portrait/landscape layouts must be verified before release

## Smoke Test Matrix

- Launch the project into the library hub
- Inspect the active request
- Start a dive from the hub
- Complete or fail a short dungeon run
- Return to the library
- Verify the request queue, archive contents, and settings survive relaunch
- Verify accessibility settings persist and alter presentation
- Verify content validation passes with no broken references

## Validation Commands

```bash
godot --headless --path . --check-only --script res://scripts/core/app_state.gd
godot --headless --path . --quit-after 3
```

## Release Gate Notes

- Keep save migration and recovery tests green.
- Keep the content database validation green.
- Keep deterministic dungeon generation checks green.
- Document any unsupported target or flow before release.

# 0.1 Validation Matrix

This matrix records the current evidence for the active living specification.

| Requirement | Evidence | Status |
| --- | --- | --- |
| Launch into the library | Live Godot smoke launch; `LibraryHub` scene tree and rendered hub | Verified |
| Inspect an active request | Live hub HUD and request-board interaction | Verified |
| Enter a short procedural dungeon | Live `LibraryHub` → `Prepare the Dive` → `DungeonRun` transition | Verified |
| Use cards with visible state | Live `DiveHud` shows five cards, costs/readiness, objective, health and shield; release tests cover card verbs | Verified |
| Required room roles and varied layouts | `test_dungeon_layout_contains_required_room_roles`, deterministic and varied-seed tests | Verified |
| Failure returns without completing request | Live Escape return; request remained `State: active`; `test_run_outcomes_update_request_and_archive_state` | Verified |
| Success archives tome and persists state | `test_run_outcomes_update_request_and_archive_state`, save round-trip and archive ownership tests | Automated |
| Archive placement and passive pairings | Archive pairing, removal, reload, and runtime modifier tests | Automated |
| Asset formats and priorities documented | [`asset_requirements.md`](asset_requirements.md) | Verified |

The release gate currently reports 23 passing tests. Runtime smoke checks should
leave the Godot game stopped.

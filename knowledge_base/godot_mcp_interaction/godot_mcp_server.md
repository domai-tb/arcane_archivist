# Godot MCP Servers: Availability and Interaction Surface

This note documents the two Godot-related MCP servers available in the current Codex session for **Arcane Archivist** and summarizes what they can actually do.

Verified on **July 2, 2026**.

## Availability

Both servers are available and callable in this environment.

### `mcp__godot_ai`

This is the full editor-attached server. It works against a live Godot editor session and exposes scene, script, runtime, and project editing operations.

Verified live:

- `session_manage(op="list")` returned one active session: `arcane-archivist@d1a8`
- session metadata reported Godot `4.7-stable (arch_linux)`, project path `/home/domai/Coding/arcane_archivist/`, and `readiness="ready"`
- `editor_state()` reported project name `Arcane Archivist` and current scene `res://scenes/cards/CardHotbar.tscn`
- `scene_manage(op="get_roots")` reported two open scenes:
  - `res://scenes/bootstrap/Main.tscn`
  - `res://scenes/cards/CardHotbar.tscn`
- `input_map_manage(op="list")` returned `count: 0`

### `mcp__godot_mcp`

This is the smaller utility server. It is project-path based rather than editor-session based and mainly exposes version, project metadata, UID maintenance, and stop controls.

Verified live:

- `get_godot_version()` returned `4.7.stable.arch_linux.5b4e0cb0f`
- `get_project_info("/home/domai/Coding/arcane_archivist")` returned:
  - name: `arcane_archivist`
  - scenes: `10`
  - scripts: `133`
  - assets: `1`
  - other: `161`

## Summary

- `mcp__godot_ai` is the main server for real work inside Godot. It can inspect and mutate the editor state, open and save scenes, edit nodes, create scripts, manage resources, run the project, run tests, inspect the runtime, simulate input, and read logs.
- `mcp__godot_mcp` is a narrow utility layer. It is useful for version checks, project metadata, Godot 4.4+ UID workflows, and stopping a running Godot project.
- For this repository, `mcp__godot_ai` is the server to use for day-to-day agent-driven development. `mcp__godot_mcp` is complementary, not a replacement.

## Reverse-Engineered Interaction Model

### 1. `mcp__godot_ai`: session-driven editor automation

This server follows a clear workflow:

1. Discover or select a live editor session with `session_manage` or `session_activate`.
2. Check readiness with `editor_state`.
3. Inspect the current scene, nodes, scripts, files, resources, or project settings.
4. Apply mutations through scene, node, script, UI, resource, or project tools.
5. Run the game or tests, then inspect logs, runtime nodes, UI, or input behavior.
6. Save the scene or persist project settings when needed.

In practice, it behaves like an agent-facing control plane for the running Godot editor.

### 2. `mcp__godot_mcp`: stateless project utilities

This server does not expose the same editor-integrated workflow. Its interaction pattern is simpler:

1. Pass a project path into metadata or UID functions.
2. Read version or project structure information.
3. Use UID tools when Godot 4.4+ resource reference maintenance is needed.
4. Use `stop_project()` when a currently running Godot project must be stopped.

It is best understood as a support utility, not as a full editor automation layer.

## What `mcp__godot_ai` Can Do

The available interaction surface can be grouped into these areas.

### Session and editor state

- `session_manage`, `session_activate`
- `editor_state`, `editor_manage(state, selection_get, selection_set, monitors_get, quit, logs_clear, game_eval)`
- `editor_reload_plugin`
- `client_manage(status, configure, remove)`

Use this layer to discover active editors, pick the target session, inspect readiness, inspect performance, manage selection, or reconfigure client integrations.

### Scene and node authoring

- `scene_open`, `scene_save`, `scene_manage(create, save_as, get_roots)`
- `scene_get_hierarchy`
- `node_create`, `node_set_property`, `node_get_properties`, `node_find`
- `node_manage(get_children, get_groups, delete, duplicate, rename, move, reparent, add_to_group, remove_from_group)`
- `batch_execute`

This is the core scene editing surface. It supports both inspection and mutation of the edited scene tree.

### Scripts, files, and Godot API inspection

- `script_create`, `script_attach`, `script_patch`
- `script_manage(read, detach, find_symbols)`
- `filesystem_manage(read_text, write_text, reimport, scan, search)`
- `api_manage(get_class)`

This allows both code generation and code-aware editor operations, plus direct reads and writes through Godot's own filesystem view.

### Project settings and persistent project structure

- `project_manage(stop, settings_get, settings_set)`
- `autoload_manage(list, add, remove)`
- `input_map_manage(list, add_action, remove_action, bind_event)`

This is the layer for modifying `project.godot`-backed configuration, singleton setup, and input definitions.

### Resources and content authoring

- `resource_manage(search, load, assign, get_info, create, curve_set_points, environment_create, physics_shape_autofit, gradient_texture_create, noise_texture_create)`
- `material_manage(create, set_param, set_shader_param, get, list, assign, apply_to_node, apply_preset)`
- `theme_manage(create, set_color, set_constant, set_font_size, set_stylebox_flat, apply)`

This covers reusable assets and editor-visible content resources, not just scene tree nodes.

### UI, animation, audio, particles, and cameras

- `ui_manage(set_anchor_preset, set_text, build_layout, draw_recipe)`
- `animation_create`
- `animation_manage(player_create, delete, validate, add_property_track, add_method_track, set_autoplay, play, stop, list, get, create_simple, preset_fade, preset_slide, preset_shake, preset_pulse)`
- `audio_manage(player_create, player_set_stream, player_set_playback, play, stop, list)`
- `particle_manage(create, set_main, set_process, set_draw_pass, restart, get, apply_preset)`
- `camera_manage(create, configure, set_limits_2d, set_damping_2d, follow_2d, get, list, apply_preset)`
- `signal_manage(list, connect, disconnect)`

This makes the server useful for both gameplay scenes and editor-built presentation work.

### Run, test, inspect, and debug

- `project_run`
- `test_run`, `test_manage(results_get)`
- `logs_read`
- `game_manage(get_scene_tree, get_node_info, get_ui_elements, input_key, input_mouse, input_gamepad, input_state)`
- `editor_screenshot`

This is the runtime-facing side of the server. It can launch the project, inspect the running tree, drive input, capture screenshots, and read plugin, editor, or game logs.

## What `mcp__godot_mcp` Can Do

The second server currently exposes a much smaller surface:

- `get_godot_version()`
- `get_project_info(projectPath)`
- `get_uid(projectPath, filePath)`
- `update_project_uids(projectPath)`
- `stop_project()`

Practical use cases:

- confirm the installed Godot version
- inspect coarse project structure from a filesystem path
- inspect or refresh resource UIDs for Godot `4.4+`
- stop a currently running project

## Practical Recommendation

For **Arcane Archivist**, the two servers should be treated like this:

- use `mcp__godot_ai` for building the game
- use `mcp__godot_mcp` for lightweight project introspection and UID maintenance

If future documentation refers to a generic "Godot MCP server", it should be split explicitly between these two namespaces because they serve different roles and have very different interaction depth.

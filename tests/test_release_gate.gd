@tool
extends McpTestSuite

var _content_db: Node = null
var _save_manager: Node = null
var _app_state: Node = null
var _temp_dir: String = ""
var _save_path: String = ""
var _backup_path: String = ""
var _temp_path: String = ""


func suite_name() -> String:
	return "release_gate"


func suite_setup(_ctx: Dictionary) -> void:
	var content_script: Script = load("res://scripts/core/content_db.gd")
	var save_script: Script = load("res://scripts/core/save_manager.gd")
	var app_state_script: Script = load("res://scripts/core/app_state.gd")
	if content_script == null or save_script == null or app_state_script == null:
		fail_setup("Core scripts failed to load")
		return

	_content_db = content_script.new()
	_save_manager = save_script.new()
	_app_state = app_state_script.new()

	if _content_db == null or _save_manager == null or _app_state == null:
		fail_setup("Core services failed to instantiate")
		return

	_content_db._build_content()
	_temp_dir = "/tmp/arcane_archivist_tests/%d/release_gate" % OS.get_process_id()
	var dir_error := DirAccess.make_dir_recursive_absolute(_temp_dir)
	if dir_error != OK:
		fail_setup("Unable to create temporary test directory: %s" % _temp_dir)
		return

	_save_path = _temp_dir + "/save.json"
	_backup_path = _temp_dir + "/save.bak.json"
	_temp_path = _temp_dir + "/save.tmp.json"
	_save_manager.set_save_path_overrides(_save_path, _backup_path, _temp_path)
	_app_state.save_manager = _save_manager
	_app_state.content_db = _content_db
	_app_state.initialize()
	_app_state.ensure_input_actions()


func suite_teardown() -> void:
	_cleanup_temp_files()
	if _save_manager != null and _save_manager.has_method("clear_save_path_overrides"):
		_save_manager.clear_save_path_overrides()
	if _app_state != null and is_instance_valid(_app_state):
		_app_state.free()
	if _save_manager != null and is_instance_valid(_save_manager):
		_save_manager.free()
	if _content_db != null and is_instance_valid(_content_db):
		_content_db.free()


func test_content_validation() -> void:
	var errors: Array = _content_db.validate_content()
	assert_eq(errors.size(), 0, "Content database should validate cleanly.")


func test_starter_deck_covers_core_card_verbs() -> void:
	var starter_deck: Array[String] = _content_db.get_starter_deck()
	assert_true(starter_deck.size() >= 5 and starter_deck.size() <= 7, "The starter deck should contain 5-7 cards.")

	var roles := {}
	var kinds := {}
	for card_id in starter_deck:
		var card = _content_db.get_card(card_id)
		assert_true(card != null, "Every starter card ID should resolve to content.")
		if card != null:
			roles[card.role] = true
			kinds[card.kind] = true

	for required_role in ["movement", "offense", "defense", "utility"]:
		assert_true(roles.has(required_role), "The starter deck should cover the %s role." % required_role)
	assert_true(kinds.size() >= 3, "The starter deck should provide at least three distinct card verbs.")

	var dash = _content_db.get_card("swift_step")
	var strike = _content_db.get_card("arc_strike")
	var ward = _content_db.get_card("ward_sign")
	var study = _content_db.get_card("study_note")
	assert_gt(float(dash.move_bonus), 0.0, "Movement card should provide a nonzero dash effect.")
	assert_gt(float(strike.power), 0.0, "Offense card should provide nonzero damage.")
	assert_gt(float(strike.reach), 0.0, "Offense card should provide a usable reach.")
	assert_gt(int(ward.shield), 0, "Defense card should provide a nonzero shield.")
	assert_gt(int(study.insight_restore), 0, "Utility card should restore insight.")


func test_project_input_actions_cover_core_loop() -> void:
	var required_actions := [
		"move_up", "move_down", "move_left", "move_right",
		"interact", "card_1", "card_2", "card_3", "card_4", "card_5",
	]
	for action_name in required_actions:
		assert_true(InputMap.has_action(action_name), "Project input map should define %s." % action_name)

	var expected_bindings := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
		"card_1": [KEY_1],
		"card_2": [KEY_2],
		"card_3": [KEY_3],
		"card_4": [KEY_4],
		"card_5": [KEY_5],
	}
	for action_name in expected_bindings.keys():
		var actual_keycodes: Array[int] = []
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey:
				actual_keycodes.append(event.keycode)
		for keycode in expected_bindings[action_name]:
			assert_true(actual_keycodes.has(keycode), "%s should bind keycode %d." % [action_name, keycode])


func test_dungeon_layout_is_deterministic() -> void:
	var request_id: String = _content_db.get_default_request_id()
	var seed_value: int = 1729
	var layout_a: Array = _content_db.build_dungeon_layout(seed_value, request_id)
	var layout_b: Array = _content_db.build_dungeon_layout(seed_value, request_id)
	assert_eq(layout_a, layout_b, "Dungeon layout should be deterministic for the same seed and request.")
	assert_true(not layout_a.is_empty(), "Dungeon layout should not be empty.")
	assert_eq(str(layout_a.back().get("role", "")), "tome", "Dungeon layout should end with the tome room.")


func test_dungeon_layout_varies_between_seeds() -> void:
	var request_id: String = _content_db.get_default_request_id()
	var reference: Array = _content_db.build_dungeon_layout(100, request_id)
	var found_variation := false
	for seed_value in range(101, 121):
		var candidate: Array = _content_db.build_dungeon_layout(seed_value, request_id)
		assert_eq(str(candidate.front().get("role", "")), "entrance", "Every generated layout should start at the entrance.")
		assert_eq(str(candidate.back().get("role", "")), "tome", "Every generated layout should end at the tome room.")
		if candidate != reference:
			found_variation = true
	assert_true(found_variation, "Different seeds should produce more than one readable room route.")


func test_dungeon_layout_contains_required_room_roles() -> void:
	var request_id: String = _content_db.get_default_request_id()
	var layout: Array = _content_db.build_dungeon_layout(1729, request_id)
	var roles: Array[String] = []
	for room in layout:
		roles.append(str(room.get("role", "")))

	assert_true(roles.has("entrance"), "Every playable route needs an entrance room.")
	assert_true(roles.has("reward"), "Every playable route needs a reward room.")
	assert_true(roles.has("tome"), "Every playable route needs a tome room.")
	var encounter_count := 0
	for role in roles:
		if role == "encounter" or role == "elite":
			encounter_count += 1
	assert_true(encounter_count >= 2, "Every playable route needs at least two encounter rooms.")
	for room in layout:
		var role := str(room.get("role", ""))
		if role == "encounter" or role == "elite":
			var template = _content_db.get_room(str(room.get("room_id", "")))
			assert_true(template != null and template.enemy_ids.size() > 0, "Every encounter room should contain at least one enemy.")


func test_optional_rooms_and_request_pool_are_available() -> void:
	var request_pool: Array[String] = _content_db.get_request_pool()
	assert_true(request_pool.size() >= 2, "The 0.2 request pool should contain at least two requests.")
	var optional_seen := false
	for seed_value in range(100, 140):
		for room in _content_db.build_dungeon_layout(seed_value, _content_db.get_default_request_id()):
			if str(room.get("role", "")) == "optional":
				optional_seen = true
	assert_true(optional_seen, "At least one generated route should contain an optional room.")
	var optional_template_ids := ["optional_cache", "optional_hazard", "optional_guard", "optional_card_choice", "optional_relic_cache", "optional_puzzle_nook"]
	for room_id in optional_template_ids:
		var template = _content_db.get_room(room_id)
		assert_true(template != null, "Optional room %s should resolve to content." % room_id)
		if template == null:
			continue
		assert_eq(template.room_type, "optional", "Optional room %s should be tagged optional." % room_id)
		assert_true(template.reward_kind != "" or template.hazard_kind != "" or template.enemy_ids.size() > 0, "Optional room %s should expose a risk or reward." % room_id)


func test_archive_bonus_content_has_multiple_card_synergies() -> void:
	var synergy_count := 0
	for bonus in _content_db.get_archive_bonuses():
		var modifiers: Dictionary = bonus.get("modifiers", {})
		if not modifiers.get("card_modifiers", []).is_empty():
			synergy_count += 1
	assert_true(synergy_count >= 3, "Archive content should provide at least three card synergies.")


func test_archive_card_modifier_pipeline_changes_runtime_values() -> void:
	var bonus := {
		"id": "test_ward_pair",
		"name": "Test Ward Pair",
		"modifiers": {"card_modifiers": [{"tag": "ward", "shield_bonus": 1}]},
	}
	var base_runtime: Dictionary = _content_db.get_card_runtime_data("ward_sign", [])
	var boosted_runtime: Dictionary = _content_db.get_card_runtime_data("ward_sign", [bonus])
	assert_eq(int(base_runtime.get("shield", 0)), 2, "Ward Sign should keep its base shield value.")
	assert_eq(int(boosted_runtime.get("shield", 0)), 3, "Archive card modifiers should change the runtime shield value.")


func test_reward_pool_has_nonstarter_cards() -> void:
	var starter_ids: Array[String] = _content_db.get_starter_deck()
	var reward_ids: Array[String] = _content_db.get_reward_card_pool()
	var nonstarter_count := 0
	for card_id in reward_ids:
		assert_true(_content_db.get_card(card_id) != null, "Reward card %s should resolve to content." % card_id)
		if not starter_ids.has(card_id):
			nonstarter_count += 1
	assert_true(nonstarter_count >= 5, "The reward pool should contain at least five non-starter cards.")


func test_request_pool_supports_replayable_0_3_scope() -> void:
	var request_ids: Array[String] = _content_db.get_request_pool()
	assert_true(request_ids.size() >= 4, "The request pool should support at least four early-game requests.")
	for request_id in request_ids:
		assert_true(_content_db.get_request(request_id) != null, "Request %s should resolve to content." % request_id)


func test_extended_route_variant_has_elite_and_reachable_tome() -> void:
	var route: Array = _content_db.build_0_3_dungeon_layout(1729)
	assert_true(route.size() >= 6, "The extended route should remain short but add meaningful depth.")
	assert_eq(str(route.front().get("role", "")), "entrance", "The extended route should start at the entrance.")
	assert_eq(str(route.back().get("role", "")), "tome", "The extended route should end at the tome room.")
	var elite_seen := false
	for room in route:
		if str(room.get("role", "")) == "elite":
			elite_seen = true
	assert_true(elite_seen, "The extended route should include an elite-style encounter.")


func test_room_enemy_spawn_points_are_local_to_room() -> void:
	var room_script: Script = load("res://scripts/rooms/dungeon_room.gd")
	assert_true(room_script != null, "Dungeon room script should load for spawn validation.")
	if room_script == null:
		return
	var room = track(room_script.new())
	room.room_index = 3
	room.room_bounds = Rect2(Vector2(2460.0, 120.0), Vector2(720.0, 420.0))
	var spawn: Vector2 = room.call("_pick_spawn_point", 0)
	assert_true(spawn.x >= 0.0 and spawn.x <= 720.0, "Enemy spawn X should be local to the room bounds.")
	assert_true(spawn.y >= 0.0 and spawn.y <= 420.0, "Enemy spawn Y should be local to the room bounds.")


func test_run_outcomes_update_request_and_archive_state() -> void:
	assert_true(_save_manager.save_save(_save_manager.default_save_data()), "The run outcome test should reset its temporary save.")
	_app_state.initialize()
	var request_id: String = _app_state.get_active_request_id()
	var request = _app_state.get_active_request()
	assert_true(request != null, "A default request should be available for the run outcome test.")
	assert_true(_content_db.get_relic_reward_pool().size() > 0, "The relic reward pool should contain at least one reward.")
	var tome_id: String = _app_state.get_active_request_tome_id()

	var failed_run = _app_state.start_run()
	assert_true(failed_run != null, "A valid deck should start the failure-path run.")
	_app_state.finish_run(false)
	assert_false(_app_state.is_request_completed(request_id), "A failed dive must leave the request incomplete.")
	assert_false(_app_state.get_archive_tomes().has(tome_id), "A failed dive must not archive the requested tome.")

	var successful_run = _app_state.start_run()
	assert_true(successful_run != null, "The player should be able to retry after failure.")
	_app_state.finish_run(true, tome_id)
	assert_true(_app_state.is_request_completed(request_id), "A successful dive must complete the request.")
	assert_true(_app_state.get_archive_tomes().has(tome_id), "A successful dive must archive the requested tome.")
	assert_true(_app_state.has_pending_card_reward_options(), "A successful dive should expose its card reward choice.")
	assert_true(_app_state.start_run() == null, "A pending card reward should be resolved before another dive starts.")

	var relaunched_state = preload("res://scripts/core/app_state.gd").new()
	relaunched_state.save_manager = _save_manager
	relaunched_state.content_db = _content_db
	relaunched_state.initialize()
	assert_true(relaunched_state.is_request_completed(request_id), "A relaunched app state should preserve request completion.")
	assert_true(relaunched_state.get_archive_tomes().has(tome_id), "A relaunched app state should preserve the archived tome.")
	relaunched_state.free()

	var reward_options: Array = _app_state.get_pending_card_reward_options()
	assert_true(reward_options.size() > 0, "The successful run should retain at least one reward option to resolve.")
	assert_true(_app_state.choose_pending_card_reward(str(reward_options[0])), "Choosing a pending reward should succeed.")
	assert_false(_app_state.has_pending_card_reward_options(), "Choosing a reward should clear the pending reward gate.")


func test_relic_ownership_round_trip() -> void:
	_app_state.grant_relic("glass_lens")
	assert_true(_app_state.get_archive_relics().has("glass_lens"), "Granting a relic should update archive ownership.")
	var reloaded = preload("res://scripts/core/app_state.gd").new()
	reloaded.save_manager = _save_manager
	reloaded.content_db = _content_db
	reloaded.initialize()
	assert_true(reloaded.get_archive_relics().has("glass_lens"), "Granted relic ownership should survive reload.")
	reloaded.free()


func test_card_collection_and_valid_deck_swap_persist() -> void:
	assert_true(_app_state.grant_card_to_collection("ember_lance"), "A reward card should be addable to the collection.")
	var offense_slot := -1
	for entry in _app_state.get_active_deck_entries():
		if str(entry.get("role", "")) == "offense":
			offense_slot = int(entry.get("slot_index", -1))
			break
	assert_true(offense_slot >= 0, "The starter deck should expose an offense slot for refinement.")
	assert_true(_app_state.set_active_deck_slot(offense_slot, "ember_lance"), "The refined deck should remain valid after an offense swap.")
	var reloaded = preload("res://scripts/core/app_state.gd").new()
	reloaded.save_manager = _save_manager
	reloaded.content_db = _content_db
	reloaded.initialize()
	assert_true(reloaded.get_owned_card_ids().has("ember_lance"), "The reward card should persist in the collection.")
	assert_true(reloaded.get_active_deck_ids().has("ember_lance"), "The refined active deck should persist after reload.")
	reloaded.free()


func test_invalid_deck_refinement_is_rejected() -> void:
	assert_true(_save_manager.save_save(_save_manager.default_save_data()), "The invalid deck test should reset its temporary save.")
	_app_state.initialize()
	var starter_deck: Array = _app_state.get_active_deck_ids()
	assert_true(starter_deck.size() >= 5, "The active deck should be large enough for validation.")
	if starter_deck.size() < 5:
		return
	var invalid_deck := starter_deck.duplicate()
	invalid_deck[0] = invalid_deck[1]
	invalid_deck[1] = invalid_deck[2]
	invalid_deck[2] = invalid_deck[3]
	invalid_deck[3] = invalid_deck[4]
	assert_false(_app_state.set_active_deck(invalid_deck), "A deck without all required roles should be rejected.")
	assert_eq(_app_state.get_active_deck_ids(), starter_deck, "Rejecting an invalid deck should preserve the valid active deck.")


func test_archive_pair_activation_and_removal() -> void:
	_app_state.grant_tome("ashen_index")
	_app_state.grant_relic("glass_lens")
	assert_true(_app_state.place_archive_item("tome", "ashen_index", 0), "The tome should be placeable.")
	assert_true(_app_state.place_archive_item("relic", "glass_lens", 1), "The relic should be placeable beside the tome.")
	var active_ids: Array[String] = []
	for bonus in _app_state.get_active_archive_bonuses():
		active_ids.append(str(bonus.get("id", "")))
	assert_true(active_ids.has("ashen_lens_guard"), "Adjacent Ashen Index and Glass Lens should activate their bonus.")
	assert_true(_app_state.remove_archive_item(1), "The relic should be removable from its archive slot.")
	var after_removal: Array[String] = []
	for bonus in _app_state.get_active_archive_bonuses():
		after_removal.append(str(bonus.get("id", "")))
	assert_false(after_removal.has("ashen_lens_guard"), "Removing the relic should deactivate the pairing bonus.")
	assert_true(_app_state.place_archive_item("relic", "glass_lens", 1), "The relic should be placeable again for reload validation.")
	var reloaded = preload("res://scripts/core/app_state.gd").new()
	reloaded.save_manager = _save_manager
	reloaded.content_db = _content_db
	reloaded.initialize()
	var reloaded_ids: Array[String] = []
	for bonus in reloaded.get_active_archive_bonuses():
		reloaded_ids.append(str(bonus.get("id", "")))
	assert_true(reloaded_ids.has("ashen_lens_guard"), "Reload should recompute the pairing bonus from archive placement.")
	reloaded.free()


func test_request_completion_rotates_to_another_request() -> void:
	assert_true(_save_manager.save_save(_save_manager.default_save_data()), "The request rotation test should reset its temporary save.")
	_app_state.initialize()
	var first_request_id: String = _app_state.get_active_request_id()
	var first_tome_id: String = _app_state.get_active_request_tome_id()
	assert_true(_app_state.start_run() != null, "The first request should be playable.")
	_app_state.finish_run(true, first_tome_id, "glass_lens")
	_app_state.clear_pending_card_reward_options()
	var second_request_id: String = _app_state.get_active_request_id()
	assert_true(second_request_id != "" and second_request_id != first_request_id, "Completing a request should rotate to another request.")
	assert_true(_app_state.get_active_request() != null, "The rotated request should resolve to content.")
	assert_true(_app_state.start_run() != null, "The rotated request should remain playable.")
	_app_state.finish_run(false)


func test_save_round_trip_and_backup_recovery() -> void:
	var payload: Dictionary = _save_manager.default_save_data()
	var payload_settings: Dictionary = payload.get("settings", {})
	payload["essence"] = 12
	payload["active_request_id"] = "recover_ashen_index"
	payload_settings["text_scale"] = 1.15
	payload_settings["contrast_mode"] = "high"
	payload_settings["palette_mode"] = "accessible"
	payload["settings"] = payload_settings

	assert_true(_save_manager.save_save(payload), "The temporary save should write successfully.")
	var loaded: Dictionary = _save_manager.load_save()
	var loaded_settings: Dictionary = loaded.get("settings", {})
	assert_eq(int(loaded.get("essence", -1)), 12, "Round-tripped save should preserve essence.")
	assert_eq(str(loaded.get("active_request_id", "")), "recover_ashen_index", "Round-tripped save should preserve the active request.")
	assert_eq(float(loaded_settings.get("text_scale", 0.0)), 1.15, "Round-tripped save should preserve text scale.")

	var save_file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	assert_true(save_file != null, "The save file should be writable for the corruption check.")
	if save_file != null:
		save_file.store_string("{ invalid json")

	var recovered: Dictionary = _save_manager.load_save()
	var recovered_settings: Dictionary = recovered.get("settings", {})
	assert_eq(int(recovered.get("essence", -1)), 12, "Backup recovery should restore the last valid save.")
	assert_eq(str(recovered.get("active_request_id", "")), "recover_ashen_index", "Backup recovery should restore the active request.")
	assert_eq(str(recovered_settings.get("palette_mode", "")), "accessible", "Backup recovery should preserve accessibility settings.")


func test_archive_breach_expires_into_damage() -> void:
	_app_state.grant_tome("ashen_index")
	assert_true(_app_state.get_archive_tomes().has("ashen_index"), "The test should be able to own the tome.")
	assert_true(_app_state.place_archive_item("tome", "ashen_index", 0), "The tome should be placeable in the archive.")
	var essence_before: int = _app_state.get_essence()
	_app_state.save_data["essence"] = max(1, essence_before)
	_app_state.save_data["pressure_event"] = {
		"event_id": "archive_breach",
		"source_request_id": "recover_ashen_index",
		"turn": 1,
		"turns_remaining": 1,
	}
	_app_state.advance_library_turn("library")

	assert_false(_app_state.has_pending_pressure_event(), "The breach should clear after expiring.")
	assert_eq(str(_app_state.get_archive_slots()[0].get("item_id", "")), "", "The breach should clear the damaged archive slot.")
	assert_true(_app_state.get_archive_tomes().has("ashen_index"), "The breach should not revoke archive ownership.")
	assert_eq(_app_state.get_essence(), max(0, max(1, essence_before) - 1), "The breach should cost one essence when possible.")


func test_narrative_unlock_records_story_beats() -> void:
	_app_state.save_data["replay_records"] = []
	_app_state.save_data["narrative_unlock_ids"] = []
	_app_state.record_replay_entry(
		"wing_upgrade",
		"Wing Upgrade",
		"Opened a new wing path.",
		{"wing_id": "astral_wing"},
		""
	)

	var narrative_unlocks: Array[String] = _app_state.get_narrative_unlock_ids()
	assert_true(narrative_unlocks.has("first_wing_upgrade"), "Wing upgrades should unlock a story beat.")
	assert_contains(_app_state.get_narrative_unlock_text(), "First Wing Specialization", "The story beat should be visible in the narrative summary.")

	var reloaded: Dictionary = _save_manager.load_save()
	var reloaded_narrative: Array = reloaded.get("narrative_unlock_ids", [])
	assert_true(reloaded_narrative.has("first_wing_upgrade"), "Narrative unlocks should persist in the save file.")


func test_touch_helpers_drive_existing_input_actions() -> void:
	var dive_hud_script: Script = load("res://scripts/ui/dive_hud.gd")
	var hub_hud_script: Script = load("res://scripts/ui/hub_hud.gd")
	assert_true(dive_hud_script != null, "Dive HUD script should load.")
	assert_true(hub_hud_script != null, "Hub HUD script should load.")

	var dive_hud = track(dive_hud_script.new())
	var hub_hud = track(hub_hud_script.new())
	assert_true(dive_hud != null, "Dive HUD should instantiate.")
	assert_true(hub_hud != null, "Hub HUD should instantiate.")

	dive_hud.call("_build_ui")
	hub_hud.call("_build_ui")
	assert_true(dive_hud.get("touch_panel") != null, "Dive HUD should create a touch panel.")
	assert_true(hub_hud.get("touch_panel") != null, "Hub HUD should create a touch panel.")

	var dive_touch_buttons: Dictionary = dive_hud.get("touch_buttons")
	var hub_touch_buttons: Dictionary = hub_hud.get("touch_buttons")
	assert_true(dive_touch_buttons.has("move_up"), "Dive HUD should register a move_up touch button.")
	assert_true(hub_touch_buttons.has("interact"), "Hub HUD should register an interact touch button.")

	var dive_up_button: Button = dive_touch_buttons.get("move_up")
	var hub_interact_button: Button = hub_touch_buttons.get("interact")
	assert_true(dive_up_button != null, "Dive HUD move_up button should exist.")
	assert_true(hub_interact_button != null, "Hub HUD interact button should exist.")
	assert_gt(dive_up_button.get_signal_connection_list("button_down").size(), 0, "Dive HUD move_up button should wire button_down.")
	assert_gt(dive_up_button.get_signal_connection_list("button_up").size(), 0, "Dive HUD move_up button should wire button_up.")
	assert_gt(hub_interact_button.get_signal_connection_list("button_down").size(), 0, "Hub HUD interact button should wire button_down.")
	assert_gt(hub_interact_button.get_signal_connection_list("button_up").size(), 0, "Hub HUD interact button should wire button_up.")


func _cleanup_temp_files() -> void:
	if _save_path != "" and FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	if _backup_path != "" and FileAccess.file_exists(_backup_path):
		DirAccess.remove_absolute(_backup_path)
	if _temp_path != "" and FileAccess.file_exists(_temp_path):
		DirAccess.remove_absolute(_temp_path)
	if _temp_dir != "":
		DirAccess.remove_absolute(_temp_dir)

extends Node

signal save_changed
signal run_started
signal run_finished(success: bool, tome_id: String)
signal archive_changed
signal progression_changed

var save_data: Dictionary = {}
var current_run = null
var save_manager: Node = null
var content_db: Node = null

const ARCHIVE_GRID_COLUMNS := 3
const ARCHIVE_GRID_ROWS := 2
const ARCHIVE_SLOT_COUNT := ARCHIVE_GRID_COLUMNS * ARCHIVE_GRID_ROWS
const REQUEST_QUEUE_SIZE := 3
const RESEARCH_TURNS_BASE := 2
const DECK_SORT_MODES := ["manual", "role", "name", "cost"]
const ARCHIVE_FILTER_MODES := ["all", "tomes", "relics", "placed", "unplaced"]
const TEXT_SCALE_OPTIONS := [0.9, 1.0, 1.15, 1.3]
const CONTRAST_MODES := ["normal", "high"]
const PALETTE_MODES := ["default", "accessible"]
const NARRATIVE_BEAT_ORDER := [
	"first_request_complete",
	"first_faction_milestone",
	"first_wing_upgrade",
	"first_curse_clear",
	"first_request_chain",
	"first_defense_event",
	"first_meta_unlock",
]
const NARRATIVE_BEAT_DEFINITIONS := {
	"first_request_complete": {
		"name": "First Patron Satisfied",
		"description": "A first request is completed and the archive starts to feel alive.",
		"trigger_record_types": ["request_completion"],
	},
	"first_faction_milestone": {
		"name": "First Faction Milestone",
		"description": "A patron faction notices the archive's progress.",
		"trigger_record_types": ["faction_milestone"],
	},
	"first_wing_upgrade": {
		"name": "First Wing Specialization",
		"description": "The library commits to a stronger archive wing path.",
		"trigger_record_types": ["wing_upgrade"],
	},
	"first_curse_clear": {
		"name": "First Curse Cleared",
		"description": "The library survives a run shaped by an optional challenge.",
		"trigger_record_types": ["curse_clear"],
	},
	"first_request_chain": {
		"name": "First Request Chain",
		"description": "A related sequence of patron requests is completed.",
		"trigger_record_types": ["request_chain", "recorded_request_chain"],
	},
	"first_defense_event": {
		"name": "First Defense Event",
		"description": "The archive endures its first direct pressure event.",
		"trigger_record_types": ["pressure_response", "pressure_failure"],
		"trigger_pressure_event_ids": ["archive_breach", "shelf_shift", "relic_drift", "queue_clog", "station_stutter", "visitor_rush"],
	},
	"first_meta_unlock": {
		"name": "First Meta Unlock",
		"description": "Long-term archive planning begins to reshape the library.",
		"trigger_record_types": ["meta_unlock"],
	},
}

const STATION_LAYOUTS := {
	"balanced": {
		"name": "Balanced Layout",
		"description": "Default spacing. Research takes the normal amount of library turns.",
		"research_turns_modifier": 0,
		"essence_bonus": 0,
	},
	"shelf_adjacent": {
		"name": "Shelf Adjacent",
		"description": "Archive shelf beside the research desk. Research takes 1 fewer library turn.",
		"research_turns_modifier": -1,
		"essence_bonus": 0,
	},
	"lamp_focus": {
		"name": "Lamp Focus",
		"description": "The essence lamp is tuned to patron work. Completed research grants +1 essence.",
		"research_turns_modifier": 0,
		"essence_bonus": 1,
	},
}

const WING_DEFINITIONS := {
	"astral_wing": {
		"name": "Astral Wing",
		"description": "Build around foresight, bonus card choices, and lighter cooldown pressure.",
		"knowledge_tags": ["astral_theory"],
		"unlocked_by_default": true,
		"upgrades": [
			{
				"id": "astral_wing_observation",
				"name": "Observation Gallery",
				"description": "Adds one extra pre-dive card preview and a little more reward choice flexibility.",
				"essence_cost": 2,
				"modifiers": {"reward_choice_bonus_count": 1},
			},
			{
				"id": "astral_wing_star_map",
				"name": "Star Map Vault",
				"description": "Improves cooldown recovery for study-heavy dive plans.",
				"essence_cost": 4,
				"modifiers": {"cooldown_reduction_bonus": 0.25, "reward_heal_bonus": 1},
			},
			{
				"id": "astral_wing_lens_lane",
				"name": "Lens Lane",
				"description": "Rewards careful card ordering with a small damage and insight bump.",
				"essence_cost": 6,
				"modifiers": {"card_damage_bonus": 1, "reward_heal_bonus": 1},
			},
		],
	},
	"beast_wing": {
		"name": "Beast Wing",
		"description": "Build around survival, pressure relief, and stronger close-range dives.",
		"knowledge_tags": ["beast_lore"],
		"unlocked_by_default": false,
		"upgrades": [
			{
				"id": "beast_wing_trail",
				"name": "Trail Chamber",
				"description": "Start dives with extra shield and better recovery from risky rooms.",
				"essence_cost": 2,
				"modifiers": {"starting_shield": 1, "reward_heal_bonus": 1},
			},
			{
				"id": "beast_wing_trap",
				"name": "Trap Gallery",
				"description": "Improves room-clearing power against durable threats.",
				"essence_cost": 4,
				"modifiers": {"card_damage_bonus": 1, "bonus_vs_enemy_kind": "melee", "bonus_vs_enemy_kind_damage": 1},
			},
			{
				"id": "beast_wing_hunt",
				"name": "Hunt Wing",
				"description": "Makes hard dives more forgiving and unlocks a wider reward spread.",
				"essence_cost": 6,
				"modifiers": {"starting_shield": 1, "reward_choice_bonus_count": 1},
			},
		],
	},
	"ward_wing": {
		"name": "Ward Wing",
		"description": "Build around protection, control, and steadier library planning.",
		"knowledge_tags": ["wardcraft", "forbidden_history"],
		"unlocked_by_default": false,
		"upgrades": [
			{
				"id": "ward_wing_seal",
				"name": "Seal Bay",
				"description": "Stations settle better and the run starts with more protection.",
				"essence_cost": 2,
				"modifiers": {"starting_shield": 2},
			},
			{
				"id": "ward_wing_lattice",
				"name": "Lattice Alcove",
				"description": "Lower cooldown pressure and sharpen defensive cards.",
				"essence_cost": 4,
				"modifiers": {"cooldown_reduction_bonus": 0.25, "card_damage_bonus": 1},
			},
			{
				"id": "ward_wing_archive",
				"name": "Archive Lock",
				"description": "Increases reward reliability and library resilience.",
				"essence_cost": 6,
				"modifiers": {"reward_choice_bonus_count": 1, "reward_heal_bonus": 1},
			},
		],
	},
}

const FACTION_DEFINITIONS := {
	"scholars": {
		"name": "Scholars of the Quiet Stack",
		"description": "Respond to forbidden history, complex records, and archival recovery.",
		"tracked_tags": ["forbidden_history"],
		"reputation_thresholds": [3, 6, 10],
		"tier_modifiers": [
			{"reward_choice_bonus_count": 1},
			{"cooldown_reduction_bonus": 0.25},
			{"card_damage_bonus": 1},
		],
	},
	"wardens": {
		"name": "Wardens of the Measuring Seal",
		"description": "Respond to wardcraft, containment, and library defense work.",
		"tracked_tags": ["wardcraft"],
		"reputation_thresholds": [3, 6, 10],
		"tier_modifiers": [
			{"starting_shield": 1},
			{"reward_heal_bonus": 1},
			{"bonus_vs_enemy_kind": "melee", "bonus_vs_enemy_kind_damage": 1},
		],
	},
	"fieldwardens": {
		"name": "Fieldwardens of the Living Shelf",
		"description": "Respond to beast lore, salvage, and resilient recovery.",
		"tracked_tags": ["beast_lore", "astral_theory"],
		"reputation_thresholds": [3, 6, 10],
		"tier_modifiers": [
			{"reward_heal_bonus": 1},
			{"starting_shield": 1},
			{"reward_choice_bonus_count": 1},
		],
	},
}

const CURSE_DEFINITIONS := {
	"glass_family": {
		"name": "Glass Family",
		"description": "Sharper rewards, brittle margins.",
		"unlocked_by_default": true,
		"curses": [
			{
				"id": "glass_shards",
				"name": "Glass Shards",
				"description": "Enemies hit harder, but dive rewards improve.",
				"run_modifiers": {"card_damage_bonus": 1},
				"reward_modifiers": {"reward_choice_bonus_count": 1},
				"clear_rewards": {"essence": 1},
			},
			{
				"id": "glass_reflection",
				"name": "Reflection Loss",
				"description": "Cooldowns recover slower, but the archive learns faster.",
				"run_modifiers": {"cooldown_reduction_bonus": -0.25},
				"reward_modifiers": {"reward_heal_bonus": 1},
				"clear_rewards": {"reputation": {"scholars": 1}},
			},
		],
	},
	"ink_family": {
		"name": "Ink Family",
		"description": "Archive pressure and black-archive bargains.",
		"unlocked_by_default": false,
		"curses": [
			{
				"id": "ink_tide",
				"name": "Ink Tide",
				"description": "The dive starts with less certainty and a wider reward spread.",
				"run_modifiers": {"starting_shield": -1},
				"reward_modifiers": {"reward_choice_bonus_count": 1},
				"clear_rewards": {"essence": 2},
			},
			{
				"id": "ink_echo",
				"name": "Ink Echo",
				"description": "Card recovery is noisier, but rare relics surface more often.",
				"run_modifiers": {"reward_heal_bonus": -1},
				"reward_modifiers": {"card_damage_bonus": 1},
				"clear_rewards": {"relic_bias": 1},
			},
		],
	},
	"bone_family": {
		"name": "Bone Family",
		"description": "Pressure through attrition and sacrifice.",
		"unlocked_by_default": false,
		"curses": [
			{
				"id": "bone_drain",
				"name": "Bone Drain",
				"description": "The run opens with less shield, but the archive records the win.",
				"run_modifiers": {"starting_shield": -1},
				"reward_modifiers": {"reward_choice_bonus_count": 1},
				"clear_rewards": {"record": "curse_clear"},
			},
			{
				"id": "bone_patience",
				"name": "Bone Patience",
				"description": "Longer cooldowns, steadier essence.",
				"run_modifiers": {"cooldown_reduction_bonus": -0.25},
				"reward_modifiers": {"reward_heal_bonus": 1},
				"clear_rewards": {"essence": 2},
			},
		],
	},
}

const META_UPGRADE_DEFINITIONS := {
	"unlock_second_wing": {
		"name": "Open the Second Wing",
		"description": "Unlock one additional archive wing specialization path.",
		"essence_cost": 3,
		"unlock_wing_ids": ["beast_wing"],
	},
	"unlock_third_wing": {
		"name": "Open the Third Wing",
		"description": "Unlock the final wing specialization path for this version.",
		"essence_cost": 5,
		"unlock_wing_ids": ["ward_wing"],
	},
	"unlock_ink_family": {
		"name": "Ink Oath",
		"description": "Unlock the ink curse family for before-dive selection.",
		"essence_cost": 4,
		"unlock_curse_families": ["ink_family"],
	},
	"unlock_bone_family": {
		"name": "Bone Oath",
		"description": "Unlock the bone curse family for before-dive selection.",
		"essence_cost": 4,
		"unlock_curse_families": ["bone_family"],
	},
	"archive_record_archive": {
		"name": "Archive Ledger",
		"description": "Unlock additional replay record capacity and text summaries.",
		"essence_cost": 2,
		"record_capacity_bonus": 12,
	},
}

const REPLAY_RECORD_LIMIT := 48

func _ready() -> void:
	ensure_input_actions()
	save_manager = get_node_or_null("/root/SaveManager")
	content_db = get_node_or_null("/root/ContentDB")
	initialize()

func initialize() -> void:
	if save_manager == null:
		save_manager = get_node_or_null("/root/SaveManager")
	if content_db == null:
		content_db = get_node_or_null("/root/ContentDB")
	if save_manager == null or content_db == null:
		push_error("Arcane Archivist autoloads are not ready.")
		return
	var content_errors: Array[String] = content_db.validate_content()
	for error_text in content_errors:
		push_warning(error_text)
	save_data = save_manager.load_save()
	if save_data.get("active_request_id", "") == "":
		save_data["active_request_id"] = content_db.get_default_request_id()
	_normalize_essence_state()
	_normalize_request_state()
	_normalize_research_job_state()
	_normalize_archive_state()
	_normalize_card_state()
	_normalize_progression_state()
	_normalize_pressure_state()
	_save()

func ensure_input_actions() -> void:
	_add_action_key("move_up", KEY_W)
	_add_action_key("move_up", KEY_UP)
	_add_action_key("move_down", KEY_S)
	_add_action_key("move_down", KEY_DOWN)
	_add_action_key("move_left", KEY_A)
	_add_action_key("move_left", KEY_LEFT)
	_add_action_key("move_right", KEY_D)
	_add_action_key("move_right", KEY_RIGHT)
	_add_action_key("interact", KEY_E)
	_add_action_key("interact", KEY_ENTER)
	_add_action_key("interact", KEY_SPACE)
	_add_action_key("ui_cancel", KEY_ESCAPE)
	_add_action_key("card_1", KEY_1)
	_add_action_key("card_2", KEY_2)
	_add_action_key("card_3", KEY_3)
	_add_action_key("card_4", KEY_4)
	_add_action_key("card_5", KEY_5)

func _add_action_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func get_active_request_id() -> String:
	return save_data.get("active_request_id", "")

func get_active_request():
	var request_id: String = get_active_request_id()
	if request_id == "":
		return null
	return content_db.get_request(request_id)

func get_active_request_tome_id() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.tome_id

func get_active_request_name() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.name

func get_active_request_objective() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.objective_text

func get_active_request_reward_text() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.reward_text

func get_dungeon_theme_preview_data(request_id: String = "") -> Dictionary:
	if request_id == "":
		request_id = get_active_request_id()
	if content_db == null:
		return {}
	return content_db.get_dungeon_theme_preview_data(request_id)

func get_dungeon_theme_preview_text(request_id: String = "") -> String:
	if request_id == "":
		request_id = get_active_request_id()
	if content_db == null:
		return "Dungeon theme: Wardline Vault"
	return content_db.get_dungeon_theme_preview_text(request_id)

func get_dungeon_theme_name(request_id: String = "") -> String:
	var data := get_dungeon_theme_preview_data(request_id)
	if data.is_empty():
		return "Wardline Vault"
	return str(data.get("name", "Wardline Vault"))

func get_text_scale() -> float:
	var settings: Dictionary = _get_ui_settings()
	var scale: float = float(settings.get("text_scale", 1.0))
	if scale <= 0.0:
		return 1.0
	return scale

func get_text_scale_label() -> String:
	return "%d%%" % int(round(get_text_scale() * 100.0))

func set_text_scale(scale: float) -> bool:
	var normalized: float = 1.0
	var closest_delta: float = INF
	for option in TEXT_SCALE_OPTIONS:
		var candidate: float = float(option)
		var delta: float = abs(candidate - scale)
		if delta < closest_delta:
			closest_delta = delta
			normalized = candidate
	var settings: Dictionary = _get_ui_settings()
	if float(settings.get("text_scale", 1.0)) == normalized:
		return false
	settings["text_scale"] = normalized
	_commit_ui_settings(settings)
	return true

func cycle_text_scale() -> float:
	var current: float = get_text_scale()
	var index: int = TEXT_SCALE_OPTIONS.find(current)
	if index < 0:
		index = 0
	var next_scale: float = float(TEXT_SCALE_OPTIONS[(index + 1) % TEXT_SCALE_OPTIONS.size()])
	set_text_scale(next_scale)
	return next_scale

func get_contrast_mode() -> String:
	var settings: Dictionary = _get_ui_settings()
	var mode: String = str(settings.get("contrast_mode", "normal"))
	if not CONTRAST_MODES.has(mode):
		return "normal"
	return mode

func get_contrast_mode_label() -> String:
	match get_contrast_mode():
		"high":
			return "High"
		_:
			return "Normal"

func cycle_contrast_mode() -> String:
	var mode: String = get_contrast_mode()
	var index: int = CONTRAST_MODES.find(mode)
	if index < 0:
		index = 0
	var next_mode: String = CONTRAST_MODES[(index + 1) % CONTRAST_MODES.size()]
	var settings: Dictionary = _get_ui_settings()
	settings["contrast_mode"] = next_mode
	_commit_ui_settings(settings)
	return next_mode

func get_palette_mode() -> String:
	var settings: Dictionary = _get_ui_settings()
	var mode: String = str(settings.get("palette_mode", "default"))
	if not PALETTE_MODES.has(mode):
		return "default"
	return mode

func get_palette_mode_label() -> String:
	match get_palette_mode():
		"accessible":
			return "Accessible"
		_:
			return "Standard"

func cycle_palette_mode() -> String:
	var mode: String = get_palette_mode()
	var index: int = PALETTE_MODES.find(mode)
	if index < 0:
		index = 0
	var next_mode: String = PALETTE_MODES[(index + 1) % PALETTE_MODES.size()]
	var settings: Dictionary = _get_ui_settings()
	settings["palette_mode"] = next_mode
	_commit_ui_settings(settings)
	return next_mode

func get_accessibility_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Accessibility:")
	lines.append("Text scale: %s" % get_text_scale_label())
	lines.append("Contrast: %s" % get_contrast_mode_label())
	lines.append("Palette: %s" % get_palette_mode_label())
	return "\n".join(lines)

func get_show_tooltips_enabled() -> bool:
	var settings: Dictionary = _get_ui_settings()
	return bool(settings.get("show_tooltips", true))

func set_show_tooltips_enabled(enabled: bool) -> void:
	var settings: Dictionary = _get_ui_settings()
	if bool(settings.get("show_tooltips", true)) == enabled:
		return
	settings["show_tooltips"] = enabled
	_commit_ui_settings(settings)

func toggle_show_tooltips() -> bool:
	var enabled := not get_show_tooltips_enabled()
	set_show_tooltips_enabled(enabled)
	return enabled

func get_deck_sort_mode() -> String:
	var settings: Dictionary = _get_ui_settings()
	var mode := str(settings.get("deck_sort_mode", "manual"))
	if not DECK_SORT_MODES.has(mode):
		return "manual"
	return mode

func get_deck_sort_mode_label() -> String:
	match get_deck_sort_mode():
		"role":
			return "Role"
		"name":
			return "Name"
		"cost":
			return "Cost"
		_:
			return "Manual"

func cycle_deck_sort_mode() -> String:
	var mode := get_deck_sort_mode()
	var index := DECK_SORT_MODES.find(mode)
	if index < 0:
		index = 0
	var next_mode: String = DECK_SORT_MODES[(index + 1) % DECK_SORT_MODES.size()]
	sort_active_deck(next_mode)
	var settings: Dictionary = _get_ui_settings()
	settings["deck_sort_mode"] = next_mode
	_commit_ui_settings(settings)
	return next_mode

func sort_active_deck(sort_mode: String = "") -> bool:
	var mode := sort_mode if sort_mode != "" else get_deck_sort_mode()
	if not DECK_SORT_MODES.has(mode):
		mode = "manual"
	var deck_ids := get_active_deck_ids()
	if deck_ids.is_empty():
		return true
	if mode == "manual":
		return true

	var entries: Array[Dictionary] = []
	for index in range(deck_ids.size()):
		var card_id := str(deck_ids[index])
		var card = content_db.get_card(card_id)
		if card == null:
			continue
		entries.append({
			"card_id": card_id,
			"name": str(card.name),
			"role": str(card.role),
			"cost": int(card.cost),
			"original_index": index,
		})

	for i in range(entries.size()):
		for j in range(i + 1, entries.size()):
			if _should_swap_deck_entries(entries[i], entries[j], mode):
				var temp: Dictionary = entries[i]
				entries[i] = entries[j]
				entries[j] = temp

	var sorted_ids: Array[String] = []
	for entry in entries:
		sorted_ids.append(str(entry.get("card_id", "")))
	if sorted_ids.is_empty():
		return false
	return set_active_deck(sorted_ids)

func get_archive_filter_mode() -> String:
	var settings: Dictionary = _get_ui_settings()
	var mode := str(settings.get("archive_filter_mode", "all"))
	if not ARCHIVE_FILTER_MODES.has(mode):
		return "all"
	return mode

func get_archive_filter_mode_label() -> String:
	match get_archive_filter_mode():
		"tomes":
			return "Tomes"
		"relics":
			return "Relics"
		"placed":
			return "Placed"
		"unplaced":
			return "Unplaced"
		_:
			return "All"

func cycle_archive_filter_mode() -> String:
	var mode := get_archive_filter_mode()
	var index := ARCHIVE_FILTER_MODES.find(mode)
	if index < 0:
		index = 0
	var next_mode: String = ARCHIVE_FILTER_MODES[(index + 1) % ARCHIVE_FILTER_MODES.size()]
	var settings: Dictionary = _get_ui_settings()
	settings["archive_filter_mode"] = next_mode
	_commit_ui_settings(settings)
	return next_mode

func get_tracked_request_id() -> String:
	var settings: Dictionary = _get_ui_settings()
	var request_id := str(settings.get("tracked_request_id", ""))
	if request_id != "" and content_db.get_request(request_id) == null:
		return ""
	return request_id

func set_tracked_request_id(request_id: String) -> bool:
	if request_id != "" and content_db.get_request(request_id) == null:
		return false
	var settings: Dictionary = _get_ui_settings()
	if str(settings.get("tracked_request_id", "")) == request_id:
		return true
	settings["tracked_request_id"] = request_id
	_commit_ui_settings(settings)
	return true

func clear_tracked_request() -> bool:
	return set_tracked_request_id("")

func track_active_request() -> bool:
	return set_tracked_request_id(get_active_request_id())

func track_next_request() -> bool:
	var current_id: String = get_tracked_request_id()
	if current_id == "":
		current_id = get_active_request_id()
	var next_id: String = content_db.get_next_request_id(
		current_id,
		_copy_string_array(save_data.get("completed_request_ids", []))
	)
	if next_id == "":
		return false
	return set_tracked_request_id(next_id)

func get_tracked_request_text() -> String:
	var request_id := get_tracked_request_id()
	if request_id == "":
		return "Tracked request: none."
	var request = content_db.get_request(request_id)
	if request == null:
		return "Tracked request: none."
	var entry: Dictionary = get_request_entry(request_id)
	var state := str(entry.get("state", "tracked"))
	var deadline_kind := str(entry.get("deadline_kind", "dive"))
	var deadline_remaining := int(entry.get("deadline_turns_remaining", 0))
	var lines: Array[String] = []
	lines.append("Tracked request: %s" % str(request.name))
	lines.append(_shorten_text(str(request.objective_text), 120))
	lines.append("State: %s | Deadline: %d %s turns" % [state, deadline_remaining, deadline_kind])
	return "\n".join(lines)

func _get_ui_settings() -> Dictionary:
	var settings: Dictionary = save_data.get("settings", {})
	if typeof(settings) != TYPE_DICTIONARY:
		return {}
	return settings.duplicate(true)

func _commit_ui_settings(settings: Dictionary) -> void:
	var current_settings: Dictionary = _get_ui_settings()
	if current_settings == settings:
		return
	save_data["settings"] = settings.duplicate(true)
	save_changed.emit()
	_save()

func _shorten_text(text: String, max_chars: int) -> String:
	var clean := text.replace("\n", " ").strip_edges()
	if clean.length() <= max_chars:
		return clean
	return clean.substr(0, max_chars - 1).strip_edges() + "…"

func _role_sort_rank(role: String) -> int:
	match role:
		"movement":
			return 0
		"offense":
			return 1
		"defense":
			return 2
		"utility":
			return 3
		_:
			return 4

func _should_swap_deck_entries(left: Dictionary, right: Dictionary, mode: String) -> bool:
	var left_name := str(left.get("name", ""))
	var right_name := str(right.get("name", ""))
	var left_role := str(left.get("role", ""))
	var right_role := str(right.get("role", ""))
	var left_cost := int(left.get("cost", 0))
	var right_cost := int(right.get("cost", 0))
	match mode:
		"role":
			var left_rank := _role_sort_rank(left_role)
			var right_rank := _role_sort_rank(right_role)
			if left_rank != right_rank:
				return left_rank > right_rank
			if left_name.to_lower() != right_name.to_lower():
				return left_name.to_lower() > right_name.to_lower()
		"name":
			if left_name.to_lower() != right_name.to_lower():
				return left_name.to_lower() > right_name.to_lower()
			if left_cost != right_cost:
				return left_cost > right_cost
		"cost":
			if left_cost != right_cost:
				return left_cost > right_cost
			if left_name.to_lower() != right_name.to_lower():
				return left_name.to_lower() > right_name.to_lower()
		_:
			return false
	var left_index := int(left.get("original_index", 0))
	var right_index := int(right.get("original_index", 0))
	return left_index > right_index

func _archive_inventory_entry_matches_filter(entry: Dictionary, mode: String) -> bool:
	match mode:
		"tomes":
			return str(entry.get("item_type", "")) == "tome"
		"relics":
			return str(entry.get("item_type", "")) == "relic"
		"placed":
			return bool(entry.get("placed", false))
		"unplaced":
			return not bool(entry.get("placed", false))
		_:
			return true

func _should_swap_inventory_entries(left: Dictionary, right: Dictionary) -> bool:
	var left_type_rank := 0 if str(left.get("item_type", "")) == "tome" else 1
	var right_type_rank := 0 if str(right.get("item_type", "")) == "tome" else 1
	if left_type_rank != right_type_rank:
		return left_type_rank > right_type_rank
	var left_placed := bool(left.get("placed", false))
	var right_placed := bool(right.get("placed", false))
	if left_placed != right_placed:
		return not left_placed and right_placed
	var left_name := str(left.get("name", "")).to_lower()
	var right_name := str(right.get("name", "")).to_lower()
	if left_name != right_name:
		return left_name > right_name
	return str(left.get("item_id", "")) > str(right.get("item_id", ""))

func get_active_wing_name() -> String:
	var wing_id := get_active_wing_id()
	if wing_id == "":
		return "None"
	var wing_def := get_wing_definition(wing_id)
	if wing_def.is_empty():
		return wing_id
	return str(wing_def.get("name", wing_id))

func get_active_build_summary_text() -> String:
	var role_counts: Dictionary = {
		"movement": 0,
		"offense": 0,
		"defense": 0,
		"utility": 0,
	}
	for entry in get_active_deck_entries():
		var role := str(entry.get("role", ""))
		if role_counts.has(role):
			role_counts[role] = int(role_counts.get(role, 0)) + 1

	var focus_role := "balanced"
	var focus_count := -1
	var weak_role := ""
	var weak_count := 999
	for role in role_counts.keys():
		var count := int(role_counts[role])
		if count > focus_count:
			focus_count = count
			focus_role = str(role)
		if count < weak_count:
			weak_count = count
			weak_role = str(role)

	var role_label := focus_role
	if focus_count <= 0:
		role_label = "unclassified"
	elif focus_count > 1:
		role_label = "%s-leaning" % role_label

	var station_name := get_station_layout_text().split("\n", false, 2)[0]
	var archive_bonus_count := get_active_archive_bonuses().size()
	var lines: Array[String] = []
	lines.append("Build summary:")
	lines.append("Deck: %s (%d movement, %d offense, %d defense, %d utility)." % [
		role_label,
		int(role_counts.get("movement", 0)),
		int(role_counts.get("offense", 0)),
		int(role_counts.get("defense", 0)),
		int(role_counts.get("utility", 0)),
	])
	if weak_role != "":
		lines.append("Weakest role: %s." % weak_role)
	lines.append("Wing: %s." % get_active_wing_name())
	lines.append("Station: %s." % station_name)
	lines.append("Archive bonuses: %d active." % archive_bonus_count)
	return "\n".join(lines)

func get_pressure_event() -> Dictionary:
	return _duplicate_pressure_event(save_data.get("pressure_event", {}))

func has_pending_pressure_event() -> bool:
	return not get_pressure_event().is_empty()

func get_pressure_event_name() -> String:
	var event := get_pressure_event()
	if event.is_empty():
		return ""
	var event_id: String = str(event.get("event_id", ""))
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	if event_data.is_empty():
		return event_id
	return str(event_data.get("name", event_id))

func get_pressure_summary_text() -> String:
	var event := get_pressure_event()
	if event.is_empty():
		return "Pressure: calm."
	var event_id: String = str(event.get("event_id", ""))
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	if event_data.is_empty():
		return "Pressure alert: %s" % event_id
	var lines: Array[String] = []
	var threat_kind := str(event_data.get("threat_kind", "pressure"))
	var prefix := "Defense alert" if threat_kind == "attack" else "Pressure alert"
	lines.append("%s: %s" % [prefix, str(event_data.get("name", event_id))])
	lines.append(str(event_data.get("description", "")))
	if event.has("turns_remaining"):
		lines.append("Resolve in: %d turns" % max(0, int(event.get("turns_remaining", 0))))
	var assets: Array = event_data.get("threat_assets", [])
	if not assets.is_empty():
		lines.append("Threatened assets: %s" % ", ".join(assets))
	var options: Array = event_data.get("response_options", [])
	if not options.is_empty():
		var option_names: Array[String] = []
		for option in options:
			if typeof(option) != TYPE_DICTIONARY:
				continue
			var option_name := str(option.get("name", option.get("id", "")))
			var essence_cost := int(option.get("essence_cost", 0))
			if essence_cost > 0:
				option_name += " (%d essence)" % essence_cost
			option_names.append(option_name)
		if not option_names.is_empty():
			lines.append("Responses: %s" % "; ".join(option_names))
	return "\n".join(lines)

func get_essence() -> int:
	return int(save_data.get("essence", 0))

func add_essence(amount: int) -> void:
	if amount == 0:
		return
	save_data["essence"] = max(0, get_essence() + amount)
	save_changed.emit()
	_save()

func spend_essence(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_essence() < amount:
		return false
	save_data["essence"] = get_essence() - amount
	save_changed.emit()
	_save()
	return true

func get_progression_screen_data() -> Dictionary:
	return {
		"wings": get_wing_progression_entries(),
		"factions": get_faction_progression_entries(),
		"curses": get_curse_selection_data(),
		"meta": get_meta_progression_data(),
		"records": get_replay_records(),
	}

func get_wing_definition_ids() -> Array[String]:
	var ids: Array[String] = []
	for wing_id in WING_DEFINITIONS.keys():
		ids.append(str(wing_id))
	if content_db != null and content_db.has_method("get_wing_definition_ids"):
		var content_ids: Array = content_db.get_wing_definition_ids()
		if typeof(content_ids) == TYPE_ARRAY and not content_ids.is_empty():
			return _copy_string_array(content_ids)
	return ids

func get_wing_definition(wing_id: String) -> Dictionary:
	if content_db != null and content_db.has_method("get_wing_runtime_data"):
		var runtime: Dictionary = content_db.get_wing_runtime_data(wing_id)
		if typeof(runtime) == TYPE_DICTIONARY and not runtime.is_empty():
			return runtime
	var wing: Dictionary = WING_DEFINITIONS.get(wing_id, {})
	if wing.is_empty():
		return {}
	return wing.duplicate(true)

func get_wing_progression_state(wing_id: String) -> Dictionary:
	var wings: Dictionary = save_data.get("wing_progression", {})
	var wing_state: Dictionary = wings.get(wing_id, {})
	if wing_state.is_empty():
		var wing_def: Dictionary = get_wing_definition(wing_id)
		if wing_def.is_empty():
			return {}
		wing_state = {
			"wing_id": wing_id,
			"unlocked": bool(wing_def.get("unlocked_by_default", false)),
			"tier": 0,
			"purchased_upgrade_ids": [],
		}
	return {
		"wing_id": wing_id,
		"unlocked": bool(wing_state.get("unlocked", false)),
		"tier": max(0, int(wing_state.get("tier", 0))),
		"purchased_upgrade_ids": _copy_string_array(wing_state.get("purchased_upgrade_ids", [])),
	}

func get_wing_progression_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for wing_id in get_wing_definition_ids():
		var wing_def: Dictionary = get_wing_definition(wing_id)
		if wing_def.is_empty():
			continue
		var wing_state := get_wing_progression_state(wing_id)
		if wing_state.is_empty():
			continue
		entries.append({
			"wing_id": wing_id,
			"name": str(wing_def.get("name", wing_id)),
			"description": str(wing_def.get("description", "")),
			"unlocked": bool(wing_state.get("unlocked", false)),
			"tier": int(wing_state.get("tier", 0)),
			"max_tier": int(wing_def.get("upgrades", []).size()),
			"is_active": get_active_wing_id() == wing_id,
			"upgrades": get_wing_upgrade_entries(wing_id),
			"modifiers": get_wing_modifiers(wing_id),
		})
	return entries

func get_wing_upgrade_entries(wing_id: String) -> Array[Dictionary]:
	var wing_def: Dictionary = get_wing_definition(wing_id)
	if wing_def.is_empty():
		return []
	var wing_state := get_wing_progression_state(wing_id)
	var purchased_ids: Array[String] = _copy_string_array(wing_state.get("purchased_upgrade_ids", []))
	var entries: Array[Dictionary] = []
	for upgrade in wing_def.get("upgrades", []):
		if typeof(upgrade) != TYPE_DICTIONARY:
			continue
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id == "":
			continue
		entries.append({
			"id": upgrade_id,
			"name": str(upgrade.get("name", upgrade_id)),
			"description": str(upgrade.get("description", "")),
			"essence_cost": int(upgrade.get("essence_cost", 0)),
			"purchased": purchased_ids.has(upgrade_id),
			"modifiers": upgrade.get("modifiers", {}).duplicate(true),
		})
	return entries

func get_wing_modifiers(wing_id: String) -> Array[Dictionary]:
	var wing_def: Dictionary = get_wing_definition(wing_id)
	if wing_def.is_empty():
		return []
	var state := get_wing_progression_state(wing_id)
	var modifiers: Array[Dictionary] = []
	for upgrade in wing_def.get("upgrades", []):
		if typeof(upgrade) != TYPE_DICTIONARY:
			continue
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id == "":
			continue
		if not _copy_string_array(state.get("purchased_upgrade_ids", [])).has(upgrade_id):
			continue
		var modifier: Dictionary = {
			"id": upgrade_id,
			"name": str(upgrade.get("name", upgrade_id)),
			"description": str(upgrade.get("description", "")),
			"source_type": "wing",
			"source_id": wing_id,
			"modifiers": upgrade.get("modifiers", {}).duplicate(true),
		}
		modifiers.append(modifier)
	return modifiers

func get_active_wing_id() -> String:
	var wing_id := str(save_data.get("active_wing_id", ""))
	if wing_id != "" and is_wing_unlocked(wing_id):
		return wing_id
	for candidate_id in get_wing_definition_ids():
		if is_wing_unlocked(candidate_id):
			return candidate_id
	return ""

func is_wing_unlocked(wing_id: String) -> bool:
	var wing_state := get_wing_progression_state(wing_id)
	if wing_state.is_empty():
		return false
	return bool(wing_state.get("unlocked", false))

func unlock_wing(wing_id: String, emit_changes: bool = true) -> bool:
	var wing_def := get_wing_definition(wing_id)
	if wing_def.is_empty():
		return false
	var wings: Dictionary = save_data.get("wing_progression", {})
	var wing_state := get_wing_progression_state(wing_id)
	if wing_state.is_empty():
		wing_state = {
			"wing_id": wing_id,
			"unlocked": true,
			"tier": 0,
			"purchased_upgrade_ids": [],
		}
	else:
		wing_state["unlocked"] = true
	wings[wing_id] = wing_state
	save_data["wing_progression"] = wings
	if save_data.get("active_wing_id", "") == "":
		save_data["active_wing_id"] = wing_id
	if emit_changes:
		progression_changed.emit()
		save_changed.emit()
		_save()
	return true

func set_active_wing(wing_id: String) -> bool:
	if wing_id == "":
		return false
	if not is_wing_unlocked(wing_id):
		return false
	if get_active_wing_id() == wing_id:
		return true
	save_data["active_wing_id"] = wing_id
	progression_changed.emit()
	save_changed.emit()
	_save()
	return true

func can_upgrade_wing(wing_id: String) -> bool:
	var wing_def := get_wing_definition(wing_id)
	var wing_state := get_wing_progression_state(wing_id)
	if wing_def.is_empty() or wing_state.is_empty() or not bool(wing_state.get("unlocked", false)):
		return false
	var tier := int(wing_state.get("tier", 0))
	return tier < int(wing_def.get("upgrades", []).size())

func purchase_wing_upgrade(wing_id: String) -> bool:
	if not can_upgrade_wing(wing_id):
		return false
	var wing_def := get_wing_definition(wing_id)
	var wing_state := get_wing_progression_state(wing_id)
	var tier := int(wing_state.get("tier", 0))
	var upgrades: Array = wing_def.get("upgrades", [])
	if tier < 0 or tier >= upgrades.size():
		return false
	var upgrade: Dictionary = upgrades[tier]
	var cost: int = max(0, int(upgrade.get("essence_cost", 0)))
	if not spend_essence(cost):
		return false
	var purchased_ids: Array[String] = _copy_string_array(wing_state.get("purchased_upgrade_ids", []))
	var upgrade_id := str(upgrade.get("id", ""))
	if upgrade_id != "" and not purchased_ids.has(upgrade_id):
		purchased_ids.append(upgrade_id)
	wing_state["tier"] = tier + 1
	wing_state["purchased_upgrade_ids"] = purchased_ids
	var wings: Dictionary = save_data.get("wing_progression", {})
	wings[wing_id] = wing_state
	save_data["wing_progression"] = wings
	record_replay_entry("wing_upgrade", str(wing_def.get("name", wing_id)), str(upgrade.get("description", "")), {
		"wing_id": wing_id,
		"upgrade_id": upgrade_id,
		"tier": tier + 1,
	}, "")
	progression_changed.emit()
	save_changed.emit()
	_save()
	return true

func get_faction_definition_ids() -> Array[String]:
	var ids: Array[String] = []
	for faction_id in FACTION_DEFINITIONS.keys():
		ids.append(str(faction_id))
	return ids

func get_faction_definition(faction_id: String) -> Dictionary:
	var faction: Dictionary = FACTION_DEFINITIONS.get(faction_id, {})
	if faction.is_empty():
		return {}
	return faction.duplicate(true)

func get_faction_reputation(faction_id: String) -> int:
	var reputation: Dictionary = save_data.get("faction_reputation", {})
	return max(0, int(reputation.get(faction_id, 0)))

func get_faction_tier(faction_id: String) -> int:
	var faction := get_faction_definition(faction_id)
	if faction.is_empty():
		return 0
	var thresholds: Array = faction.get("reputation_thresholds", [])
	var rep := get_faction_reputation(faction_id)
	var tier := 0
	for threshold in thresholds:
		if rep >= int(threshold):
			tier += 1
	return tier

func get_faction_modifiers(faction_id: String) -> Array[Dictionary]:
	var faction := get_faction_definition(faction_id)
	if faction.is_empty():
		return []
	var tier := get_faction_tier(faction_id)
	var modifiers: Array[Dictionary] = []
	for index in range(min(tier, faction.get("tier_modifiers", []).size())):
		var modifier: Dictionary = {
			"id": "%s_tier_%d" % [faction_id, index + 1],
			"name": str(faction.get("name", faction_id)),
			"description": "Faction tier %d" % [index + 1],
			"source_type": "faction",
			"source_id": faction_id,
			"modifiers": faction.get("tier_modifiers", [])[index].duplicate(true),
		}
		modifiers.append(modifier)
	return modifiers

func get_faction_progression_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for faction_id in get_faction_definition_ids():
		var faction := get_faction_definition(faction_id)
		if faction.is_empty():
			continue
		entries.append({
			"id": faction_id,
			"name": str(faction.get("name", faction_id)),
			"description": str(faction.get("description", "")),
			"reputation": get_faction_reputation(faction_id),
			"tier": get_faction_tier(faction_id),
			"tracked_tags": _copy_string_array(faction.get("tracked_tags", [])),
			"modifiers": get_faction_modifiers(faction_id),
		})
	return entries

func add_faction_reputation(faction_id: String, amount: int, source: String = "") -> void:
	if faction_id == "" or amount == 0 or get_faction_definition(faction_id).is_empty():
		return
	var reputation: Dictionary = save_data.get("faction_reputation", {})
	var previous_rep: int = max(0, int(reputation.get(faction_id, 0)))
	var new_rep: int = max(0, previous_rep + amount)
	reputation[faction_id] = new_rep
	save_data["faction_reputation"] = reputation
	var previous_tier := get_faction_tier_from_value(faction_id, previous_rep)
	var new_tier := get_faction_tier(faction_id)
	if new_tier > previous_tier:
		record_replay_entry("faction_milestone", str(get_faction_definition(faction_id).get("name", faction_id)), "Reached reputation tier %d." % new_tier, {
			"faction_id": faction_id,
			"reputation": new_rep,
			"source": source,
		})
	progression_changed.emit()
	save_changed.emit()
	_save()

func get_faction_tier_from_value(faction_id: String, reputation_value: int) -> int:
	var faction := get_faction_definition(faction_id)
	if faction.is_empty():
		return 0
	var thresholds: Array = faction.get("reputation_thresholds", [])
	var tier := 0
	for threshold in thresholds:
		if reputation_value >= int(threshold):
			tier += 1
	return tier

func get_curse_family_ids() -> Array[String]:
	var ids: Array[String] = []
	for family_id in CURSE_DEFINITIONS.keys():
		ids.append(str(family_id))
	return ids

func get_curse_family_definition(family_id: String) -> Dictionary:
	var family: Dictionary = CURSE_DEFINITIONS.get(family_id, {})
	if family.is_empty():
		return {}
	return family.duplicate(true)

func is_curse_family_unlocked(family_id: String) -> bool:
	var family := get_curse_family_definition(family_id)
	if family.is_empty():
		return false
	if bool(family.get("unlocked_by_default", false)):
		return true
	return _copy_string_array(save_data.get("meta_unlock_ids", [])).has("unlock_%s" % family_id)

func get_available_curse_family_ids() -> Array[String]:
	var ids: Array[String] = []
	for family_id in get_curse_family_ids():
		if is_curse_family_unlocked(family_id):
			ids.append(family_id)
	return ids

func get_curse_definition_ids() -> Array[String]:
	var ids: Array[String] = []
	for family_id in get_curse_family_ids():
		var family := get_curse_family_definition(family_id)
		for curse in family.get("curses", []):
			if typeof(curse) != TYPE_DICTIONARY:
				continue
			var curse_id := str(curse.get("id", ""))
			if curse_id != "":
				ids.append(curse_id)
	return ids

func get_curse_definition(curse_id: String) -> Dictionary:
	for family_id in get_curse_family_ids():
		var family := get_curse_family_definition(family_id)
		for curse in family.get("curses", []):
			if typeof(curse) != TYPE_DICTIONARY:
				continue
			if str(curse.get("id", "")) == curse_id:
				return curse.duplicate(true)
	return {}

func get_curse_family_for_curse(curse_id: String) -> String:
	for family_id in get_curse_family_ids():
		var family := get_curse_family_definition(family_id)
		for curse in family.get("curses", []):
			if typeof(curse) != TYPE_DICTIONARY:
				continue
			if str(curse.get("id", "")) == curse_id:
				return family_id
	return ""

func get_available_curse_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for family_id in get_available_curse_family_ids():
		var family := get_curse_family_definition(family_id)
		for curse in family.get("curses", []):
			if typeof(curse) != TYPE_DICTIONARY:
				continue
			var curse_id := str(curse.get("id", ""))
			if curse_id == "":
				continue
			if not _copy_string_array(save_data.get("unlocked_curse_ids", [])).has(curse_id) and not bool(curse.get("unlocked_by_default", false)):
				continue
			options.append({
				"id": curse_id,
				"family_id": family_id,
				"name": str(curse.get("name", curse_id)),
				"description": str(curse.get("description", "")),
				"run_modifiers": curse.get("run_modifiers", {}).duplicate(true),
				"reward_modifiers": curse.get("reward_modifiers", {}).duplicate(true),
				"clear_rewards": curse.get("clear_rewards", {}).duplicate(true),
			})
	return options

func get_selected_curse_family_id() -> String:
	var family_id := str(save_data.get("selected_curse_family_id", ""))
	if family_id != "" and is_curse_family_unlocked(family_id):
		return family_id
	return ""

func get_selected_curse_ids() -> Array[String]:
	var selected: Array[String] = []
	var family_id := get_selected_curse_family_id()
	if family_id == "":
		return selected
	var stored_ids := _copy_string_array(save_data.get("selected_curse_ids", []))
	var single_id := str(save_data.get("selected_curse_id", ""))
	if single_id != "" and not stored_ids.has(single_id):
		stored_ids.append(single_id)
	for curse_id in stored_ids:
		if get_curse_family_for_curse(curse_id) == family_id:
			selected.append(curse_id)
	return selected

func get_curse_selection_data() -> Dictionary:
	var family_id := get_selected_curse_family_id()
	var family_name := ""
	if family_id != "":
		family_name = str(get_curse_family_definition(family_id).get("name", family_id))
	return {
		"selected_family_id": family_id,
		"selected_family_name": family_name,
		"selected_curse_ids": get_selected_curse_ids(),
		"available_families": get_available_curse_family_ids(),
		"available_curses": get_available_curse_options(),
	}

func set_selected_curse_family(family_id: String) -> bool:
	if family_id != "" and not is_curse_family_unlocked(family_id):
		return false
	save_data["selected_curse_family_id"] = family_id
	if family_id == "":
		save_data["selected_curse_ids"] = []
		save_data["selected_curse_id"] = ""
	else:
		save_data["selected_curse_ids"] = _filter_curses_for_family(_copy_string_array(save_data.get("selected_curse_ids", [])), family_id)
		save_data["selected_curse_id"] = save_data["selected_curse_ids"].front() if not save_data["selected_curse_ids"].is_empty() else ""
	progression_changed.emit()
	save_changed.emit()
	_save()
	return true

func set_selected_curse_ids(curse_ids: Array) -> bool:
	var family_id := get_selected_curse_family_id()
	if family_id == "":
		if curse_ids.is_empty():
			save_data["selected_curse_ids"] = []
			save_data["selected_curse_id"] = ""
			progression_changed.emit()
			save_changed.emit()
			_save()
			return true
		family_id = get_curse_family_for_curse(str(curse_ids[0]))
		if family_id == "" or not is_curse_family_unlocked(family_id):
			return false
		save_data["selected_curse_family_id"] = family_id
	var selected: Array[String] = []
	for curse_id in curse_ids:
		var curse_text := str(curse_id)
		if curse_text == "":
			continue
		if get_curse_family_for_curse(curse_text) != family_id:
			return false
		if not selected.has(curse_text):
			selected.append(curse_text)
	save_data["selected_curse_ids"] = selected
	save_data["selected_curse_id"] = selected.front() if not selected.is_empty() else ""
	progression_changed.emit()
	save_changed.emit()
	_save()
	return true

func clear_selected_curse_selection() -> void:
	save_data["selected_curse_family_id"] = ""
	save_data["selected_curse_ids"] = []
	save_data["selected_curse_id"] = ""
	progression_changed.emit()
	save_changed.emit()
	_save()

func get_selected_curse_modifiers() -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	for curse_id in get_selected_curse_ids():
		var curse: Dictionary = get_curse_definition(curse_id)
		if curse.is_empty():
			continue
		modifiers.append({
			"id": curse_id,
			"name": str(curse.get("name", curse_id)),
			"description": str(curse.get("description", "")),
			"source_type": "curse",
			"source_id": get_curse_family_for_curse(curse_id),
			"modifiers": curse.get("run_modifiers", {}).duplicate(true),
			"reward_modifiers": curse.get("reward_modifiers", {}).duplicate(true),
			"clear_rewards": curse.get("clear_rewards", {}).duplicate(true),
		})
	return modifiers

func get_selected_curse_summary_text() -> String:
	var data := get_curse_selection_data()
	if data.get("selected_family_id", "") == "":
		return "No curse family selected."
	var lines: Array[String] = []
	lines.append("Curse family: %s" % str(data.get("selected_family_name", data.get("selected_family_id", ""))))
	if data.get("selected_curse_ids", []).is_empty():
		lines.append("No curses selected.")
	else:
		for curse_id in data.get("selected_curse_ids", []):
			var curse: Dictionary = get_curse_definition(str(curse_id))
			lines.append("- %s: %s" % [str(curse.get("name", curse_id)), str(curse.get("description", ""))])
	return "\n".join(lines)

func get_meta_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for upgrade_id in META_UPGRADE_DEFINITIONS.keys():
		ids.append(str(upgrade_id))
	return ids

func get_meta_upgrade_definition(upgrade_id: String) -> Dictionary:
	var upgrade: Dictionary = META_UPGRADE_DEFINITIONS.get(upgrade_id, {})
	if upgrade.is_empty():
		return {}
	return upgrade.duplicate(true)

func get_meta_upgrade_entries() -> Array[Dictionary]:
	var purchased: Array[String] = _copy_string_array(save_data.get("meta_unlock_ids", []))
	var entries: Array[Dictionary] = []
	for upgrade_id in get_meta_upgrade_ids():
		var upgrade := get_meta_upgrade_definition(upgrade_id)
		if upgrade.is_empty():
			continue
		entries.append({
			"id": upgrade_id,
			"name": str(upgrade.get("name", upgrade_id)),
			"description": str(upgrade.get("description", "")),
			"essence_cost": int(upgrade.get("essence_cost", 0)),
			"purchased": purchased.has(upgrade_id),
		})
	return entries

func get_meta_progression_data() -> Dictionary:
	return {
		"spent_essence": int(save_data.get("meta_spent_essence", 0)),
		"purchased_ids": _copy_string_array(save_data.get("meta_unlock_ids", [])),
		"record_capacity": get_replay_record_capacity(),
		"upgrades": get_meta_upgrade_entries(),
	}

func can_purchase_meta_upgrade(upgrade_id: String) -> bool:
	var upgrade := get_meta_upgrade_definition(upgrade_id)
	if upgrade.is_empty():
		return false
	if _copy_string_array(save_data.get("meta_unlock_ids", [])).has(upgrade_id):
		return false
	return get_essence() >= int(upgrade.get("essence_cost", 0))

func purchase_meta_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_meta_upgrade(upgrade_id):
		return false
	var upgrade := get_meta_upgrade_definition(upgrade_id)
	if not spend_essence(int(upgrade.get("essence_cost", 0))):
		return false
	var purchased: Array[String] = _copy_string_array(save_data.get("meta_unlock_ids", []))
	purchased.append(upgrade_id)
	save_data["meta_unlock_ids"] = _unique_string_array(purchased)
	save_data["meta_spent_essence"] = int(save_data.get("meta_spent_essence", 0)) + int(upgrade.get("essence_cost", 0))
	for wing_id in _copy_string_array(upgrade.get("unlock_wing_ids", [])):
		unlock_wing(wing_id, false)
	for family_id in _copy_string_array(upgrade.get("unlock_curse_families", [])):
		_unlock_curse_family(family_id)
	record_replay_entry("meta_unlock", str(upgrade.get("name", upgrade_id)), str(upgrade.get("description", "")), {
		"upgrade_id": upgrade_id,
		"essence_cost": int(upgrade.get("essence_cost", 0)),
	}, "")
	progression_changed.emit()
	save_changed.emit()
	_save()
	return true

func get_replay_record_capacity() -> int:
	var base_capacity := REPLAY_RECORD_LIMIT
	for upgrade_id in _copy_string_array(save_data.get("meta_unlock_ids", [])):
		var upgrade := get_meta_upgrade_definition(upgrade_id)
		base_capacity += int(upgrade.get("record_capacity_bonus", 0))
	return base_capacity

func get_replay_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record in save_data.get("replay_records", []):
		if typeof(record) != TYPE_DICTIONARY:
			continue
		records.append(record.duplicate(true))
	return records

func get_replay_records_text(limit: int = 12) -> String:
	var records := get_replay_records()
	if records.is_empty():
		return "No archive records yet."
	var lines: Array[String] = []
	var start_index: int = max(0, records.size() - limit)
	for index in range(start_index, records.size()):
		var record: Dictionary = records[index]
		lines.append("%s - %s" % [str(record.get("type", "record")), str(record.get("summary", ""))])
	return "Archive records:\n- " + "\n- ".join(lines)

func get_narrative_unlock_ids() -> Array[String]:
	return _unique_string_array(_copy_string_array(save_data.get("narrative_unlock_ids", [])))

func get_narrative_unlock_text(limit: int = 6) -> String:
	var unlock_ids := get_narrative_unlock_ids()
	if unlock_ids.is_empty():
		return "No story beats unlocked yet."
	var lines: Array[String] = []
	var start_index: int = max(0, unlock_ids.size() - limit)
	for index in range(start_index, unlock_ids.size()):
		var beat_id := unlock_ids[index]
		var beat := _get_narrative_beat_definition(beat_id)
		if beat.is_empty():
			continue
		lines.append("%s - %s" % [str(beat.get("name", beat_id)), str(beat.get("description", ""))])
	if lines.is_empty():
		return "No story beats unlocked yet."
	return "Story beats:\n- " + "\n- ".join(lines)

func get_narrative_unlock_summary_text() -> String:
	var unlock_ids := get_narrative_unlock_ids()
	if unlock_ids.is_empty():
		return "Story beats: none unlocked yet."
	return "Story beats unlocked: %d" % unlock_ids.size()

func record_replay_entry(record_type: String, title: String, summary: String, payload: Dictionary = {}, request_id: String = "") -> void:
	if record_type == "":
		return
	var records := get_replay_records()
	records.append({
		"type": record_type,
		"title": title,
		"summary": summary,
		"turn": int(save_data.get("library_turn_count", 0)),
		"request_id": request_id if request_id != "" else get_active_request_id(),
		"payload": payload.duplicate(true),
	})
	var unlocked_narrative := _unlock_narrative_beats_for_record(record_type, payload)
	while records.size() > get_replay_record_capacity():
		records.pop_front()
	save_data["replay_records"] = records
	if unlocked_narrative:
		save_data["narrative_unlock_ids"] = get_narrative_unlock_ids()
	progression_changed.emit()
	save_changed.emit()
	_save()

func get_progression_summary_text() -> String:
	var lines: Array[String] = []
	lines.append(get_wing_progression_text())
	lines.append("")
	lines.append(get_faction_progression_text())
	lines.append("")
	lines.append(get_selected_curse_summary_text())
	lines.append("")
	lines.append(get_meta_progression_text())
	lines.append("")
	lines.append(get_narrative_unlock_summary_text())
	lines.append("")
	lines.append(get_narrative_unlock_text())
	lines.append("")
	lines.append(get_replay_records_text())
	return "\n".join(lines)

func get_wing_progression_text() -> String:
	var lines: Array[String] = []
	lines.append("Wings:")
	for entry in get_wing_progression_entries():
		lines.append("- %s: tier %d%s" % [
			str(entry.get("name", entry.get("wing_id", ""))),
			int(entry.get("tier", 0)),
			" (active)" if bool(entry.get("is_active", false)) else "",
		])
	return "\n".join(lines)

func get_faction_progression_text() -> String:
	var lines: Array[String] = []
	lines.append("Factions:")
	for entry in get_faction_progression_entries():
		lines.append("- %s: rep %d, tier %d" % [
			str(entry.get("name", entry.get("id", ""))),
			int(entry.get("reputation", 0)),
			int(entry.get("tier", 0)),
		])
	return "\n".join(lines)

func get_meta_progression_text() -> String:
	var lines: Array[String] = []
	lines.append("Meta progression:")
	lines.append("Essence spent: %d" % int(save_data.get("meta_spent_essence", 0)))
	for entry in get_meta_upgrade_entries():
		lines.append("- %s%s" % [
			str(entry.get("name", entry.get("id", ""))),
			" (purchased)" if bool(entry.get("purchased", false)) else "",
		])
	return "\n".join(lines)

func get_station_layout_id() -> String:
	var layout_id := str(save_data.get("station_layout_id", "balanced"))
	if not STATION_LAYOUTS.has(layout_id):
		return "balanced"
	return layout_id

func get_station_layout_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for layout_id in STATION_LAYOUTS.keys():
		var layout: Dictionary = STATION_LAYOUTS[layout_id]
		options.append({
			"id": layout_id,
			"name": str(layout.get("name", layout_id)),
			"description": str(layout.get("description", "")),
			"research_turns_modifier": int(layout.get("research_turns_modifier", 0)),
			"essence_bonus": int(layout.get("essence_bonus", 0)),
		})
	return options

func get_station_layout_text() -> String:
	var layout_id := get_station_layout_id()
	var layout: Dictionary = STATION_LAYOUTS.get(layout_id, STATION_LAYOUTS["balanced"])
	return "%s\n%s" % [str(layout.get("name", layout_id)), str(layout.get("description", ""))]

func set_station_layout(layout_id: String) -> bool:
	if not STATION_LAYOUTS.has(layout_id):
		return false
	if get_station_layout_id() == layout_id:
		return true
	if not spend_essence(1):
		return false
	save_data["station_layout_id"] = layout_id
	advance_library_turn()
	save_changed.emit()
	_save()
	return true

func resolve_pressure_event(option_id: String) -> bool:
	var event := get_pressure_event()
	if event.is_empty():
		return false
	var event_id := str(event.get("event_id", ""))
	if event_id == "":
		return false
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	if event_data.is_empty():
		return false

	var chosen_option: Dictionary = {}
	for option in event_data.get("response_options", []):
		if typeof(option) != TYPE_DICTIONARY:
			continue
		if str(option.get("id", "")) == option_id:
			chosen_option = option
			break
	if chosen_option.is_empty():
		return false

	var effect_type := str(chosen_option.get("effect_type", ""))
	if not (effect_type in ["clear", "remove_archive_item", "delay_request", "set_station_layout"]):
		return false

	var essence_cost: int = max(0, int(chosen_option.get("essence_cost", 0)))
	if essence_cost > 0 and get_essence() < essence_cost:
		return false
	if essence_cost > 0:
		spend_essence(essence_cost)

	match effect_type:
		"clear":
			pass
		"remove_archive_item":
			var item_type := str(chosen_option.get("item_type", ""))
			_remove_first_archive_item_of_type(item_type)
		"delay_request":
			_delay_active_request(max(1, int(chosen_option.get("delay_turns", 1))))
		"set_station_layout":
			var layout_id := str(chosen_option.get("layout_id", "balanced"))
			if STATION_LAYOUTS.has(layout_id):
				save_data["station_layout_id"] = layout_id
		_:
			return false

	save_data["pressure_event"] = {}
	_unlock_narrative_beat("first_defense_event")
	save_changed.emit()
	_save()
	return true

func get_request_queue_entries() -> Array:
	var tracked_request_id := get_tracked_request_id()
	var queue := _duplicate_request_queue(save_data.get("request_queue", []))
	for index in range(queue.size()):
		var entry: Dictionary = queue[index]
		entry["is_tracked"] = str(entry.get("request_id", "")) == tracked_request_id
		queue[index] = entry
	return queue

func get_active_request_entry():
	var queue := get_request_queue_entries()
	if queue.is_empty():
		return {}
	return queue[0]

func get_request_entry(request_id: String):
	for entry in get_request_queue_entries():
		if str(entry.get("request_id", "")) == request_id:
			return entry
	return {}

func get_request_queue_text() -> String:
	var queue := get_request_queue_entries()
	if queue.is_empty():
		return "Request queue is empty."

	var lines: Array[String] = []
	lines.append("Patron queue:")
	for index in range(queue.size()):
		var entry: Dictionary = queue[index]
		var request_id: String = str(entry.get("request_id", ""))
		var request = content_db.get_request(request_id)
		var title := str(request.name if request != null else request_id)
		if bool(entry.get("is_tracked", false)):
			title = "★ %s" % title
		var state := str(entry.get("state", "queued"))
		var deadline_kind := str(entry.get("deadline_kind", "dive"))
		var deadline_remaining := int(entry.get("deadline_turns_remaining", 0))
		var deadline_total := int(entry.get("deadline_turns_total", 0))
		lines.append("%d. %s [%s] - %d/%d %s turns" % [
			index + 1,
			title,
			state,
			deadline_remaining,
			deadline_total,
			deadline_kind,
		])
	return "\n".join(lines)

func get_research_job():
	return _duplicate_research_job(save_data.get("research_job", {}))

func has_pending_research_job() -> bool:
	var job: Dictionary = get_research_job()
	return not job.is_empty() and str(job.get("state", "")) in ["pending", "researching"]

func has_active_research_job() -> bool:
	var job: Dictionary = get_research_job()
	return not job.is_empty() and str(job.get("state", "")) == "researching"

func get_research_job_text() -> String:
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return "No research job is waiting."

	var request_id: String = str(job.get("request_id", ""))
	var request = content_db.get_request(request_id)
	var title: String = str(request.name if request != null else request_id)
	var state: String = str(job.get("state", "pending"))
	var turns_remaining: int = int(job.get("turns_remaining", 0))
	var turns_total: int = int(job.get("turns_total", RESEARCH_TURNS_BASE))
	var essence_reward: int = int(job.get("essence_reward", 0))
	var source_tome: String = str(job.get("tome_id", ""))
	var source_relic: String = str(job.get("relic_id", ""))
	var lines: Array[String] = []
	lines.append("Research job: %s" % title)
	lines.append("State: %s" % state)
	lines.append("Time: %d/%d library turns remaining" % [turns_remaining, turns_total])
	if source_tome != "":
		lines.append("Tome: %s" % source_tome)
	if source_relic != "":
		lines.append("Relic: %s" % source_relic)
	lines.append("Essence on completion: %d" % essence_reward)
	return "\n".join(lines)

func get_request_state_summary() -> String:
	var active_entry: Dictionary = get_active_request_entry()
	if active_entry.is_empty():
		return "No active request."

	var request_id: String = str(active_entry.get("request_id", ""))
	var request = content_db.get_request(request_id)
	if request == null:
		return "No active request."

	var state: String = str(active_entry.get("state", "active"))
	var deadline_kind: String = str(active_entry.get("deadline_kind", "dive"))
	var deadline_remaining: int = int(active_entry.get("deadline_turns_remaining", 0))
	var deadline_total: int = int(active_entry.get("deadline_turns_total", 0))
	return "%s\nState: %s\nDeadline: %d/%d %s turns" % [
		str(request.name),
		state,
		deadline_remaining,
		deadline_total,
		deadline_kind,
	]

func set_active_request(request_id: String) -> bool:
	if request_id == "":
		return false
	var queue := _duplicate_request_queue(save_data.get("request_queue", []))
	var request_index: int = _find_request_queue_index(queue, request_id)
	if request_index < 0:
		return false
	var entry: Dictionary = queue[request_index]
	if str(entry.get("state", "")) in ["completed", "expired"]:
		return false

	queue.remove_at(request_index)
	entry["state"] = "active"
	queue.insert(0, entry)
	save_data["active_request_id"] = request_id
	save_data["request_queue"] = queue
	_save_request_queue(queue)
	return true

func get_request_progress_text(request_id: String = "") -> String:
	var entry: Dictionary = {}
	if request_id == "":
		entry = get_active_request_entry()
	else:
		entry = get_request_entry(request_id)
	if entry.is_empty():
		return "No request progress available."

	var progress: int = int(entry.get("progress", 0))
	var progress_total: int = max(1, int(entry.get("progress_total", 1)))
	var state: String = str(entry.get("state", "queued"))
	return "Progress: %d/%d\nState: %s" % [progress, progress_total, state]

func get_request_board_text() -> String:
	var lines: Array[String] = []
	lines.append(get_request_queue_text())
	lines.append("")
	lines.append("Active request:")
	lines.append(get_request_state_summary())
	return "\n".join(lines)

func can_start_research_job(request_id: String = "") -> bool:
	if has_active_research_job():
		return false
	if request_id == "":
		request_id = get_active_request_id()
	return request_id != "" and content_db.get_request(request_id) != null

func start_research_job(request_id: String = "") -> bool:
	if request_id == "":
		request_id = get_active_request_id()
	if not can_start_research_job(request_id):
		return false
	_queue_research_job(request_id, "", "")
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return false
	job["state"] = "researching"
	save_data["research_job"] = job
	save_changed.emit()
	_save()
	return true

func work_research_job() -> bool:
	if not has_pending_research_job():
		return false
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return false
	job["state"] = "researching"
	save_data["research_job"] = job
	advance_library_turn()
	return true

func get_station_layout_effect_text() -> String:
	var layout: Dictionary = STATION_LAYOUTS.get(get_station_layout_id(), STATION_LAYOUTS["balanced"])
	return "%s\n%s" % [str(layout.get("name", "balanced")), str(layout.get("description", ""))]

func advance_library_turn(turn_kind: String = "library") -> void:
	save_data["library_turn_count"] = max(0, int(save_data.get("library_turn_count", 0)) + 1)
	var pressure_failed := false
	if has_pending_pressure_event():
		var pressure_event: Dictionary = get_pressure_event()
		var remaining_turns: int = int(pressure_event.get("turns_remaining", 1)) - 1
		pressure_event["turns_remaining"] = remaining_turns
		if remaining_turns <= 0:
			_apply_pressure_event_failure(pressure_event)
			save_data["pressure_event"] = {}
			pressure_failed = true
		else:
			save_data["pressure_event"] = pressure_event
	var queue := get_request_queue_entries()
	if not queue.is_empty():
		var active_entry: Dictionary = queue[0]
		if str(active_entry.get("state", "")) in ["active", "in_progress"]:
			if str(active_entry.get("deadline_kind", "")) == turn_kind:
				var remaining := int(active_entry.get("deadline_turns_remaining", 0)) - 1
				active_entry["deadline_turns_remaining"] = max(0, remaining)
				queue[0] = active_entry
				if remaining <= 0 and str(active_entry.get("state", "")) != "completed":
					_expire_active_request(queue)
					return
		save_data["request_queue"] = queue

	var job: Dictionary = get_research_job()
	if turn_kind != "dive" and not job.is_empty() and str(job.get("state", "")) == "researching":
		job["turns_remaining"] = max(0, int(job.get("turns_remaining", 0)) - 1)
		if int(job.get("turns_remaining", 0)) <= 0:
			_complete_research_job(job)
		else:
			save_data["research_job"] = job

	if not pressure_failed:
		_maybe_queue_pressure_event(turn_kind)
	save_changed.emit()
	_save()

func advance_dive_turn() -> void:
	advance_library_turn("dive")

func _normalize_research_job_state() -> void:
	var job: Dictionary = _duplicate_research_job(save_data.get("research_job", {}))
	if job.is_empty():
		save_data["research_job"] = {}
		return
	var job_state: String = str(job.get("state", "pending"))
	if not (job_state in ["pending", "researching", "completed", "expired"]):
		job["state"] = "pending"
	job["turns_total"] = max(1, int(job.get("turns_total", RESEARCH_TURNS_BASE)))
	job["turns_remaining"] = clamp(int(job.get("turns_remaining", job.get("turns_total", RESEARCH_TURNS_BASE))), 0, int(job.get("turns_total", RESEARCH_TURNS_BASE)))
	job["essence_reward"] = max(0, int(job.get("essence_reward", 0)))
	save_data["research_job"] = job

func _normalize_archive_state() -> void:
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))
	if slots.is_empty():
		slots = _make_empty_archive_slots()
	save_data["archive_slots"] = slots
	var tome_ids: Array = save_data.get("archived_tome_ids", [])
	var relic_ids: Array = save_data.get("archived_relic_ids", [])
	save_data["archived_tome_ids"] = tome_ids
	save_data["archived_relic_ids"] = relic_ids
	_rebuild_owned_items_from_slots()
	_recompute_archive_bonuses()

func _normalize_card_state() -> void:
	var owned_cards: Array[String] = []
	for card_id in save_data.get("owned_card_ids", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if not owned_cards.has(card_id_text):
			owned_cards.append(card_id_text)
	for starter_card_id in content_db.get_starter_deck():
		if not owned_cards.has(starter_card_id) and content_db.get_card(starter_card_id) != null:
			owned_cards.append(starter_card_id)
	save_data["owned_card_ids"] = owned_cards

	var active_deck: Array = save_data.get("active_deck_ids", [])
	if active_deck.is_empty():
		active_deck = content_db.get_starter_deck()
	var validation: Dictionary = content_db.validate_deck(active_deck, owned_cards)
	if not bool(validation.get("valid", false)):
		active_deck = content_db.build_valid_deck(owned_cards, active_deck)
		validation = content_db.validate_deck(active_deck, owned_cards)
	if not bool(validation.get("valid", false)):
		active_deck = content_db.get_starter_deck()
	save_data["active_deck_ids"] = active_deck

	var unlocked_cards: Array[String] = []
	for card_id in save_data.get("unlocked_reward_card_ids", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if not unlocked_cards.has(card_id_text):
			unlocked_cards.append(card_id_text)
	save_data["unlocked_reward_card_ids"] = unlocked_cards

	var pending_options: Array[String] = []
	for card_id in save_data.get("pending_card_reward_options", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if pending_options.has(card_id_text):
			continue
		pending_options.append(card_id_text)
	save_data["pending_card_reward_options"] = pending_options
	if pending_options.is_empty():
		save_data["pending_card_reward_source"] = ""

func _sanitize_request_entry(entry: Dictionary, request_data: Dictionary = {}) -> Dictionary:
	if request_data.is_empty():
		var request_id: String = str(entry.get("request_id", ""))
		request_data = content_db.get_request_runtime_data(request_id)
	if request_data.is_empty():
		return {}
	var progress_total: int = max(1, int(entry.get("progress_total", 0)))
	if progress_total <= 1:
		progress_total = max(
			1,
			request_data.get("required_knowledge_tags", []).size() +
			request_data.get("required_tome_ids", []).size() +
			request_data.get("required_relic_ids", []).size()
		)
	var deadline_total: int = int(entry.get("deadline_turns_total", 0))
	if deadline_total <= 0:
		deadline_total = max(2, int(request_data.get("deadline_turns", 0)))
	return {
		"request_id": str(request_data.get("id", entry.get("request_id", ""))),
		"state": str(entry.get("state", "queued")),
		"deadline_kind": str(entry.get("deadline_kind", _get_request_deadline_kind(request_data))),
		"deadline_turns_total": deadline_total,
		"deadline_turns_remaining": max(0, int(entry.get("deadline_turns_remaining", deadline_total))),
		"progress": max(0, int(entry.get("progress", 0))),
		"progress_total": progress_total,
		"tome_id": str(request_data.get("tome_id", "")),
		"required_knowledge_tags": _copy_string_array(request_data.get("required_knowledge_tags", [])),
		"required_tome_ids": _copy_string_array(request_data.get("required_tome_ids", [])),
		"required_relic_ids": _copy_string_array(request_data.get("required_relic_ids", [])),
		"required_essence": max(0, int(request_data.get("required_essence", 0))),
		"reward_essence": max(0, int(request_data.get("reward_essence", 0))),
		"reward_card_ids": _copy_string_array(request_data.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(request_data.get("reward_room_ids", [])),
		"unlock_card_ids": _copy_string_array(request_data.get("unlock_card_ids", [])),
		"unlock_room_ids": _copy_string_array(request_data.get("unlock_room_ids", [])),
	}

func _find_next_request_id_for_queue(queue: Array) -> String:
	var request_ids: Array[String] = content_db.get_request_pool()
	if request_ids.is_empty():
		return ""
	var completed_request_ids: Array = save_data.get("completed_request_ids", [])
	var used_ids: Array[String] = []
	for entry in queue:
		var request_id: String = str(entry.get("request_id", ""))
		if request_id != "":
			used_ids.append(request_id)
	var start_index: int = request_ids.find(get_active_request_id())
	if start_index < 0:
		start_index = 0
	for offset in range(request_ids.size()):
		var candidate_id: String = request_ids[(start_index + offset) % request_ids.size()]
		if candidate_id == "" or completed_request_ids.has(candidate_id) or used_ids.has(candidate_id):
			continue
		return candidate_id
	return ""

func _complete_request_entry(entry: Dictionary, source: String = "") -> void:
	var request_id: String = str(entry.get("request_id", ""))
	if request_id == "":
		return
	var queue: Array = get_request_queue_entries()
	var index: int = _find_request_queue_index(queue, request_id)
	if index >= 0:
		queue.remove_at(index)
	var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
	if int(request_data.get("required_essence", 0)) > 0:
		spend_essence(int(request_data.get("required_essence", 0)))
	add_essence(int(request_data.get("reward_essence", 0)))
	for card_id in request_data.get("unlock_card_ids", []):
		grant_card_to_collection(str(card_id))
	for room_id in request_data.get("unlock_room_ids", []):
		var unlocked_rooms: Array = save_data.get("unlocked_room_blueprint_ids", [])
		var room_id_text: String = str(room_id)
		if room_id_text != "" and not unlocked_rooms.has(room_id_text):
			unlocked_rooms.append(room_id_text)
			save_data["unlocked_room_blueprint_ids"] = unlocked_rooms
	grant_card_to_collection(str(request_data.get("reward_card_ids", []).front() if not request_data.get("reward_card_ids", []).is_empty() else ""))
	_award_faction_reputation_for_request(request_data, source)
	_apply_request_progression_rewards(request_data, request_id, source)
	var active_request_id: String = _refill_request_queue_after_removal(queue)
	save_data["request_queue"] = queue
	save_data["active_request_id"] = active_request_id
	save_data["completed_request_ids"] = _unique_string_array(save_data.get("completed_request_ids", []) + [request_id])
	record_replay_entry("request_completion", str(content_db.get_request(request_id).name if content_db.get_request(request_id) != null else request_id), str(request_data.get("archive_reward_text", "")), {
		"request_id": request_id,
		"source": source,
	}, request_id)
	_record_request_history(request_id, "completed", source)
	save_changed.emit()
	_save()

func _apply_request_progression_rewards(request_data: Dictionary, request_id: String, source: String = "") -> void:
	if request_data.is_empty():
		return
	var progression_rewards: Dictionary = request_data.get("progression_rewards", {})
	if progression_rewards.is_empty():
		return

	for wing_id in _copy_string_array(progression_rewards.get("unlock_wing_ids", [])):
		unlock_wing(wing_id, false)

	if progression_rewards.has("wing_progression") and typeof(progression_rewards.get("wing_progression", {})) == TYPE_DICTIONARY:
		for wing_id in progression_rewards.get("wing_progression", {}).keys():
			_apply_wing_progression_reward(str(wing_id), int(progression_rewards.get("wing_progression", {}).get(wing_id, 0)))

	for family_id in _copy_string_array(progression_rewards.get("unlock_curse_families", [])):
		_unlock_curse_family(family_id)

	for unlock_id in _copy_string_array(progression_rewards.get("meta_unlock_ids", [])):
		var unlock_ids: Array[String] = _copy_string_array(save_data.get("meta_unlock_ids", []))
		if not unlock_ids.has(unlock_id):
			unlock_ids.append(unlock_id)
			save_data["meta_unlock_ids"] = _unique_string_array(unlock_ids)

	var record_kind := str(progression_rewards.get("record_kind", ""))
	if record_kind != "":
		var request_name := str(request_data.get("name", request_id))
		record_replay_entry(
			record_kind,
			request_name,
			str(request_data.get("archive_reward_text", "")),
			{
				"request_id": request_id,
				"source": source,
				"record_kind": record_kind,
			},
			request_id
		)

func _apply_wing_progression_reward(wing_id: String, target_tier: int) -> void:
	var wing_def := get_wing_definition(wing_id)
	if wing_def.is_empty():
		return
	var wings: Dictionary = save_data.get("wing_progression", {})
	var wing_state := get_wing_progression_state(wing_id)
	if wing_state.is_empty():
		wing_state = {
			"wing_id": wing_id,
			"unlocked": true,
			"tier": 0,
			"purchased_upgrade_ids": [],
		}
	var upgrades: Array = wing_def.get("upgrades", [])
	var tier: int = clamp(target_tier, 0, upgrades.size())
	wing_state["unlocked"] = true
	wing_state["tier"] = max(int(wing_state.get("tier", 0)), tier)
	var purchased_ids := _copy_string_array(wing_state.get("purchased_upgrade_ids", []))
	for index in range(min(tier, upgrades.size())):
		var upgrade: Dictionary = upgrades[index]
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id != "" and not purchased_ids.has(upgrade_id):
			purchased_ids.append(upgrade_id)
	wing_state["purchased_upgrade_ids"] = purchased_ids
	wings[wing_id] = wing_state
	save_data["wing_progression"] = wings
	if save_data.get("active_wing_id", "") == "" or not bool(get_wing_progression_state(str(save_data.get("active_wing_id", ""))).get("unlocked", false)):
		save_data["active_wing_id"] = wing_id
	progression_changed.emit()

func get_archive_tomes() -> Array:
	return save_data.get("archived_tome_ids", []).duplicate()

func get_archive_relics() -> Array:
	return save_data.get("archived_relic_ids", []).duplicate()

func get_archive_slots() -> Array:
	return _duplicate_archive_slots(save_data.get("archive_slots", []))

func get_archive_slot(slot_index: int) -> Dictionary:
	var slots := get_archive_slots()
	if slot_index < 0 or slot_index >= slots.size():
		return {"item_type": "", "item_id": ""}
	return slots[slot_index]

func get_owned_archive_item_ids(item_type: String) -> Array:
	if item_type == "tome":
		return get_archive_tomes()
	if item_type == "relic":
		return get_archive_relics()
	return []

func get_archive_inventory(filter_mode: String = "") -> Array:
	var mode := filter_mode if filter_mode != "" else get_archive_filter_mode()
	if not ARCHIVE_FILTER_MODES.has(mode):
		mode = "all"
	var inventory: Array = []
	var slots := get_archive_slots()

	for tome_id in get_archive_tomes():
		var tome_entry := {
			"item_type": "tome",
			"item_id": tome_id,
			"name": _get_item_name("tome", tome_id),
			"placed": _find_slot_index("tome", tome_id, slots) >= 0,
			"slot_index": _find_slot_index("tome", tome_id, slots),
		}
		if _archive_inventory_entry_matches_filter(tome_entry, mode):
			inventory.append(tome_entry)

	for relic_id in get_archive_relics():
		var relic_entry := {
			"item_type": "relic",
			"item_id": relic_id,
			"name": _get_item_name("relic", relic_id),
			"placed": _find_slot_index("relic", relic_id, slots) >= 0,
			"slot_index": _find_slot_index("relic", relic_id, slots),
		}
		if _archive_inventory_entry_matches_filter(relic_entry, mode):
			inventory.append(relic_entry)

	for i in range(inventory.size()):
		for j in range(i + 1, inventory.size()):
			if _should_swap_inventory_entries(inventory[i], inventory[j]):
				var temp: Dictionary = inventory[i]
				inventory[i] = inventory[j]
				inventory[j] = temp

	return inventory

func get_owned_card_ids() -> Array[String]:
	return _copy_string_array(save_data.get("owned_card_ids", []))

func get_active_deck_ids() -> Array[String]:
	return _copy_string_array(save_data.get("active_deck_ids", []))

func get_pending_card_reward_options() -> Array[String]:
	return _copy_string_array(save_data.get("pending_card_reward_options", []))

func has_pending_card_reward_options() -> bool:
	return not get_pending_card_reward_options().is_empty()

func get_unlocked_reward_card_ids() -> Array[String]:
	return _copy_string_array(save_data.get("unlocked_reward_card_ids", []))

func get_active_deck_validation() -> Dictionary:
	return content_db.validate_deck(get_active_deck_ids(), get_owned_card_ids())

func is_active_deck_valid() -> bool:
	return bool(get_active_deck_validation().get("valid", false))

func get_card_collection() -> Array:
	var collection: Array = []
	var active_deck := get_active_deck_ids()
	for card_id in get_owned_card_ids():
		var card = content_db.get_card(card_id)
		if card == null:
			continue
		collection.append({
			"card_id": card_id,
			"name": card.name,
			"role": card.role,
			"tags": content_db.get_card_tags(card_id),
			"starter": content_db.get_starter_deck().has(card_id),
			"active": active_deck.has(card_id),
			"summary": content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses()),
		})
	return collection

func get_active_deck_entries() -> Array:
	var deck: Array = []
	var deck_ids := get_active_deck_ids()
	for index in range(deck_ids.size()):
		var card_id := deck_ids[index]
		var card = content_db.get_card(card_id)
		if card == null:
			continue
		deck.append({
			"slot_index": index,
			"card_id": card_id,
			"name": card.name,
			"role": card.role,
			"tags": content_db.get_card_tags(card_id),
			"summary": content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses()),
		})
	return deck

func get_active_archive_bonuses() -> Array[Dictionary]:
	return save_data.get("active_archive_bonuses", []).duplicate(true)

func get_active_run_bonuses() -> Array[Dictionary]:
	var bonuses: Array[Dictionary] = []
	for bonus in get_active_archive_bonuses():
		bonuses.append(bonus.duplicate(true))
	for wing_bonus in get_wing_modifiers(get_active_wing_id()):
		bonuses.append(wing_bonus.duplicate(true))
	for faction_bonus in get_faction_run_modifiers():
		bonuses.append(faction_bonus.duplicate(true))
	for curse_bonus in get_selected_curse_modifiers():
		bonuses.append(curse_bonus.duplicate(true))
	for meta_bonus in get_meta_run_modifiers():
		bonuses.append(meta_bonus.duplicate(true))
	return bonuses

func get_faction_run_modifiers() -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	for faction_id in get_faction_definition_ids():
		modifiers.append_array(get_faction_modifiers(faction_id))
	return modifiers

func get_meta_run_modifiers() -> Array[Dictionary]:
	return []

func get_active_archive_bonus_text() -> String:
	var bonuses := get_active_archive_bonuses()
	if bonuses.is_empty():
		return "No active archive bonuses yet."

	var lines: Array[String] = []
	for bonus in bonuses:
		lines.append("%s: %s" % [bonus.get("name", bonus.get("id", "")), bonus.get("description", "")])
	return "Active bonuses:\n- " + "\n- ".join(lines)

func get_active_run_bonus_text() -> String:
	var bonuses := get_active_run_bonuses()
	if bonuses.is_empty():
		return "No active run modifiers yet."
	var lines: Array[String] = []
	for bonus in bonuses:
		lines.append("%s: %s" % [str(bonus.get("name", bonus.get("id", ""))), str(bonus.get("description", ""))])
	return "Active run modifiers:\n- " + "\n- ".join(lines)

func get_active_deck_text() -> String:
	var validation := get_active_deck_validation()
	var lines: Array[String] = []
	lines.append("Deck status: %s" % ("valid" if bool(validation.get("valid", false)) else "invalid"))
	if not bool(validation.get("errors", []).is_empty()):
		lines.append("Deck check: %s" % "; ".join(validation.get("errors", [])))
	var deck_entries := get_active_deck_entries()
	for entry in deck_entries:
		lines.append("%d. %s" % [int(entry.get("slot_index", 0)) + 1, str(entry.get("summary", ""))])
	return "\n".join(lines)

func get_active_deck_brief_text() -> String:
	var validation := get_active_deck_validation()
	var deck_ids := get_active_deck_ids()
	var lines: Array[String] = []
	lines.append("Active deck (%d/%d): %s" % [deck_ids.size(), content_db.get_starter_deck().size(), "valid" if bool(validation.get("valid", false)) else "needs repair"])
	for entry in get_active_deck_entries():
		lines.append("- %s" % str(entry.get("name", entry.get("card_id", ""))))
	return "\n".join(lines)

func get_card_detail_text(card_id: String) -> String:
	return content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses())

func is_request_completed(request_id: String) -> bool:
	return request_id in save_data.get("completed_request_ids", [])

func set_active_deck_slot(slot_index: int, card_id: String) -> bool:
	var deck_ids := get_active_deck_ids()
	if slot_index < 0 or slot_index >= deck_ids.size():
		return false
	if card_id == "" or not get_owned_card_ids().has(card_id):
		return false
	deck_ids[slot_index] = card_id
	return set_active_deck(deck_ids)

func set_active_deck(deck_ids: Array) -> bool:
	var validation: Dictionary = content_db.validate_deck(deck_ids, get_owned_card_ids())
	if not bool(validation.get("valid", false)):
		return false
	save_data["active_deck_ids"] = validation.get("deck_ids", [])
	save_changed.emit()
	_save()
	return true

func grant_card_to_collection(card_id: String) -> bool:
	if card_id == "":
		return false
	var card = content_db.get_card(card_id)
	if card == null:
		return false
	var owned_cards: Array = get_owned_card_ids()
	var changed := false
	if not owned_cards.has(card_id):
		owned_cards.append(card_id)
		save_data["owned_card_ids"] = owned_cards
		changed = true
	if not content_db.get_starter_deck().has(card_id):
		var unlocked_cards: Array = get_unlocked_reward_card_ids()
		if not unlocked_cards.has(card_id):
			unlocked_cards.append(card_id)
			save_data["unlocked_reward_card_ids"] = unlocked_cards
			changed = true
	_normalize_card_state()
	if changed:
		save_changed.emit()
		_save()
	return true

func queue_card_reward_options(option_ids: Array, source: String) -> void:
	var cleaned: Array[String] = []
	for option_id in option_ids:
		var card_id := str(option_id)
		if card_id == "":
			continue
		if content_db.get_card(card_id) == null:
			continue
		if cleaned.has(card_id):
			continue
		if content_db.get_reward_card_pool().has(card_id):
			cleaned.append(card_id)
	save_data["pending_card_reward_options"] = cleaned
	save_data["pending_card_reward_source"] = source
	save_changed.emit()
	_save()

func choose_pending_card_reward(card_id: String) -> bool:
	if card_id == "":
		return false
	var options: Array[String] = get_pending_card_reward_options()
	if not options.has(card_id):
		return false
	if not grant_card_to_collection(card_id):
		return false
	clear_pending_card_reward_options()
	return true

func clear_pending_card_reward_options() -> void:
	save_data["pending_card_reward_options"] = []
	save_data["pending_card_reward_source"] = ""
	save_changed.emit()
	_save()

func place_archive_item(item_type: String, item_id: String, slot_index: int) -> bool:
	if not _is_valid_archive_item(item_type, item_id):
		return false
	if slot_index < 0 or slot_index >= ARCHIVE_SLOT_COUNT:
		return false

	var slots := get_archive_slots()
	slots = _remove_archive_item_from_slots(item_type, item_id, slots)
	slots[slot_index] = {
		"item_type": item_type,
		"item_id": item_id,
	}

	_commit_archive_slots(slots)
	return true

func remove_archive_item(slot_index: int) -> bool:
	var slots := get_archive_slots()
	if slot_index < 0 or slot_index >= slots.size():
		return false

	slots[slot_index] = {
		"item_type": "",
		"item_id": "",
	}
	_commit_archive_slots(slots)
	return true

func clear_archive_slot(slot_index: int) -> bool:
	return remove_archive_item(slot_index)

func start_run():
	if has_pending_card_reward_options():
		push_warning("Cannot start a dive while a card reward is pending.")
		return null
	current_run = preload("res://scripts/core/run_state.gd").new()
	current_run.request_id = get_active_request_id()
	current_run.theme_id = content_db.get_dungeon_theme_id_for_request(current_run.request_id)
	current_run.run_seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_msec())
	if not is_active_deck_valid():
		_normalize_card_state()
	current_run.deck_ids = get_active_deck_ids()
	current_run.room_sequence = content_db.build_dungeon_layout(current_run.run_seed, current_run.request_id)
	current_run.player_hp = 5
	current_run.player_max_hp = 5
	current_run.insight = 3
	current_run.shield = 0
	current_run.current_room_index = 0
	current_run.room_cleared = false
	current_run.reward_relic_id = ""
	current_run.reward_choice_bonus_count = 0
	current_run.active_wing_id = get_active_wing_id()
	current_run.selected_curse_family_id = get_selected_curse_family_id()
	current_run.selected_curse_ids = get_selected_curse_ids()
	current_run.active_meta_unlock_ids = _copy_string_array(save_data.get("meta_unlock_ids", []))
	current_run.faction_reputation_snapshot = _get_faction_reputation_snapshot()
	current_run.run_modifiers = get_active_run_bonuses()
	current_run.active_bonuses = current_run.run_modifiers.duplicate(true)
	_apply_active_bonuses_to_run(current_run)
	run_started.emit()
	return current_run

func finish_run(success: bool, tome_id: String = "", relic_id: String = "") -> void:
	if current_run != null:
		current_run.completed = success
		current_run.failed = not success

	if success and tome_id != "":
		grant_tome(tome_id)
	if success and relic_id != "":
		grant_relic(relic_id)
	if success and current_run != null and current_run.reward_relic_id != "":
		grant_relic(current_run.reward_relic_id)

	if success:
		var current_request_id := get_active_request_id()
		if current_request_id != "":
			mark_request_completed(current_request_id, tome_id)
			_rotate_request_queue_after_completion(current_request_id)
			_queue_research_job(current_request_id, tome_id, relic_id)
		var reward_count := 3
		var reward_seed := Time.get_ticks_msec()
		if current_run != null:
			reward_count += max(0, int(current_run.reward_choice_bonus_count))
			reward_seed = int(current_run.run_seed)
		var reward_options: Array[String] = content_db.build_card_reward_options(
			reward_seed,
			get_owned_card_ids(),
			[],
			reward_count
		)
		queue_card_reward_options(reward_options, "dive")
		if current_run != null:
			_apply_curse_completion_rewards(current_run)
	else:
		clear_pending_card_reward_options()

	if current_run != null:
		current_run.replay_summary = {
			"success": success,
			"request_id": current_run.request_id,
			"theme_id": current_run.theme_id,
			"tome_id": tome_id,
			"relic_id": relic_id,
			"wing_id": current_run.active_wing_id,
			"curse_family_id": current_run.selected_curse_family_id,
			"curse_ids": current_run.selected_curse_ids.duplicate(),
		}
		record_replay_entry(
			"dive_success" if success else "dive_failure",
			str(current_run.request_id),
			("Completed dive for %s." % current_run.request_id) if success else ("Dive failed for %s." % current_run.request_id),
			current_run.replay_summary,
			current_run.request_id
		)
		current_run = null

	advance_dive_turn()

	clear_selected_curse_selection()
	run_finished.emit(success, tome_id)
	_save()

func grant_tome(tome_id: String) -> void:
	if tome_id == "":
		return
	var tomes: Array = save_data.get("archived_tome_ids", [])
	if not tomes.has(tome_id):
		tomes.append(tome_id)
		save_data["archived_tome_ids"] = tomes
		archive_changed.emit()

func grant_relic(relic_id: String) -> void:
	if relic_id == "":
		return
	var relics: Array = save_data.get("archived_relic_ids", [])
	if not relics.has(relic_id):
		relics.append(relic_id)
		save_data["archived_relic_ids"] = relics
		archive_changed.emit()

func mark_request_completed(request_id: String, tome_id: String) -> void:
	var completed: Array = save_data.get("completed_request_ids", [])
	if request_id != "" and not completed.has(request_id):
		completed.append(request_id)
		save_data["completed_request_ids"] = completed

	if tome_id != "":
		grant_tome(tome_id)

	save_changed.emit()

func clear_research_job() -> void:
	save_data["research_job"] = {}
	save_changed.emit()
	_save()

func set_research_job_from_run(request_id: String, tome_id: String, relic_id: String, turns_total: int, essence_reward: int) -> void:
	var normalized_turns: int = max(1, turns_total)
	save_data["research_job"] = {
		"request_id": request_id,
		"tome_id": tome_id,
		"relic_id": relic_id,
		"state": "pending",
		"turns_total": normalized_turns,
		"turns_remaining": normalized_turns,
		"essence_reward": max(0, essence_reward),
	}
	save_changed.emit()
	_save()

func _expire_active_request(queue: Array) -> void:
	if queue.is_empty():
		return
	var active_entry: Dictionary = queue[0]
	active_entry["state"] = "expired"
	active_entry["deadline_turns_remaining"] = 0
	queue[0] = active_entry
	_rotate_request_queue_after_expiry(queue)

func _rotate_request_queue_after_expiry(queue: Array) -> void:
	if not queue.is_empty():
		queue.pop_front()
	while queue.size() < REQUEST_QUEUE_SIZE:
		var next_request_id := _next_queue_request_id("", queue)
		if next_request_id == "":
			break
		queue.append(_make_request_entry(next_request_id, "queued", queue.size()))
	_save_request_queue(queue)

func _next_queue_request_id(after_request_id: String, queue: Array) -> String:
	var completed_ids: Array = save_data.get("completed_request_ids", [])
	var request_id: String = content_db.get_next_request_id(after_request_id, completed_ids)
	if request_id == "":
		return ""
	while _queue_has_request_id(queue, request_id) and request_id != "":
		var next_id: String = content_db.get_next_request_id(request_id, completed_ids)
		if next_id == request_id:
			break
		request_id = next_id
		if request_id == "":
			break
	return request_id

func _queue_has_request_id(queue: Array, request_id: String) -> bool:
	for entry in queue:
		if str(entry.get("request_id", "")) == request_id:
			return true
	return false

func _make_request_entry(request_id: String, state: String, position: int) -> Dictionary:
	var request = content_db.get_request(request_id)
	if request == null:
		return {}
	var deadline_kind := "dive" if position % 2 == 0 else "library"
	var deadline_turns := 2 if deadline_kind == "dive" else 3
	var queue_state := state if state != "" else "queued"
	if position == 0 and queue_state == "queued":
		queue_state = "active"
	return {
		"request_id": request_id,
		"state": queue_state,
		"deadline_kind": deadline_kind,
		"deadline_turns_total": deadline_turns,
		"deadline_turns_remaining": deadline_turns,
	}

func _build_request_queue(active_request_id: String = "") -> Array:
	var queue: Array = []
	var request_pool: Array[String] = content_db.get_request_pool()
	if request_pool.is_empty():
		return queue
	var start_id: String = active_request_id
	if start_id == "":
		start_id = content_db.get_default_request_id()
	var start_index: int = request_pool.find(start_id)
	if start_index < 0:
		start_index = 0
	for offset in range(min(REQUEST_QUEUE_SIZE, request_pool.size())):
		var request_id: String = request_pool[(start_index + offset) % request_pool.size()]
		if _queue_has_request_id(queue, request_id):
			continue
		queue.append(_make_request_entry(request_id, "active" if offset == 0 else "queued", queue.size()))
	return queue

func _save_request_queue(queue: Array) -> void:
	var normalized := _duplicate_request_queue(queue)
	for index in range(normalized.size()):
		var entry: Dictionary = normalized[index]
		if index == 0 and not entry.is_empty():
			var entry_state := str(entry.get("state", "active"))
			entry["state"] = "active" if not (entry_state in ["completed", "expired"]) else entry_state
			entry["deadline_turns_remaining"] = int(entry.get("deadline_turns_total", 0))
		elif not entry.is_empty() and str(entry.get("state", "")) in ["active", "in_progress"]:
			entry["state"] = "queued"
		normalized[index] = entry
	if not normalized.is_empty():
		save_data["active_request_id"] = str(normalized[0].get("request_id", ""))
	save_data["request_queue"] = normalized
	save_changed.emit()
	_save()

func _apply_active_bonuses_to_run(run_state) -> void:
	run_state.bonus_shield = 0
	run_state.bonus_damage = 0
	run_state.bonus_cooldown_reduction = 0.0
	run_state.bonus_reward_heal = 0
	run_state.bonus_vs_enemy_kind = ""
	run_state.bonus_vs_enemy_kind_damage = 0
	var bonus_hp := 0
	var bonus_insight := 0

	for bonus in get_active_run_bonuses():
		var modifiers: Dictionary = bonus.get("modifiers", {})
		run_state.bonus_shield += int(modifiers.get("starting_shield", 0))
		run_state.bonus_damage += int(modifiers.get("card_damage_bonus", 0))
		run_state.bonus_cooldown_reduction += float(modifiers.get("cooldown_reduction_bonus", 0.0))
		run_state.bonus_reward_heal += int(modifiers.get("reward_heal_bonus", 0))
		run_state.reward_choice_bonus_count += int(modifiers.get("reward_choice_bonus_count", 0))
		bonus_hp += int(modifiers.get("starting_hp", 0))
		bonus_insight += int(modifiers.get("starting_insight", 0))

		var enemy_kind := str(modifiers.get("bonus_vs_enemy_kind", ""))
		if enemy_kind != "":
			run_state.bonus_vs_enemy_kind = enemy_kind
			run_state.bonus_vs_enemy_kind_damage = max(
				run_state.bonus_vs_enemy_kind_damage,
				int(modifiers.get("bonus_vs_enemy_kind_damage", 0))
			)

	run_state.shield = max(0, int(run_state.shield) + run_state.bonus_shield)
	if bonus_hp != 0:
		run_state.player_max_hp = max(1, int(run_state.player_max_hp) + bonus_hp)
		run_state.player_hp = clamp(int(run_state.player_hp) + bonus_hp, 1, run_state.player_max_hp)
	if bonus_insight != 0:
		run_state.insight = max(0, int(run_state.insight) + bonus_insight)
	run_state.reward_choice_bonus_count = max(0, int(run_state.reward_choice_bonus_count))

func _get_faction_reputation_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for faction_id in get_faction_definition_ids():
		snapshot[faction_id] = get_faction_reputation(faction_id)
	return snapshot

func _apply_curse_completion_rewards(run_state) -> void:
	if run_state == null:
		return
	var curse_ids: Array[String] = _copy_string_array(run_state.selected_curse_ids)
	if curse_ids.is_empty():
		return
	for curse_id in curse_ids:
		var curse: Dictionary = get_curse_definition(curse_id)
		if curse.is_empty():
			continue
		var clear_rewards: Dictionary = curse.get("clear_rewards", {})
		if clear_rewards.is_empty():
			continue
		if int(clear_rewards.get("essence", 0)) != 0:
			add_essence(int(clear_rewards.get("essence", 0)))
		if int(clear_rewards.get("relic_bias", 0)) > 0:
			var relic_id: String = content_db.pick_relic_reward(int(run_state.run_seed) + int(clear_rewards.get("relic_bias", 0)), get_archive_relics())
			if relic_id != "":
				grant_relic(relic_id)
		if clear_rewards.has("reputation") and typeof(clear_rewards.get("reputation", {})) == TYPE_DICTIONARY:
			for faction_id in clear_rewards.get("reputation", {}).keys():
				add_faction_reputation(str(faction_id), int(clear_rewards.get("reputation", {}).get(faction_id, 0)), curse_id)
		var record_type := str(clear_rewards.get("record", ""))
		if record_type != "":
			record_replay_entry(record_type, str(curse.get("name", curse_id)), str(curse.get("description", "")), {
				"curse_id": curse_id,
				"family_id": get_curse_family_for_curse(curse_id),
			}, run_state.request_id)

func _commit_archive_slots(slots: Array) -> void:
	save_data["archive_slots"] = _duplicate_archive_slots(slots)
	_rebuild_owned_items_from_slots()
	_recompute_archive_bonuses()
	save_changed.emit()
	archive_changed.emit()
	_save()

func _rebuild_owned_items_from_slots() -> void:
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))
	var tome_ids: Array = save_data.get("archived_tome_ids", [])
	var relic_ids: Array = save_data.get("archived_relic_ids", [])

	for slot in slots:
		var item_type := str(slot.get("item_type", ""))
		var item_id := str(slot.get("item_id", ""))
		if item_type == "tome" and item_id != "":
			if not tome_ids.has(item_id):
				tome_ids.append(item_id)
		elif item_type == "relic" and item_id != "":
			if not relic_ids.has(item_id):
				relic_ids.append(item_id)

	save_data["archived_tome_ids"] = tome_ids
	save_data["archived_relic_ids"] = relic_ids

func _recompute_archive_bonuses() -> void:
	var bonuses: Array[Dictionary] = []
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))

	for bonus in content_db.get_archive_bonuses():
		var tome_id := str(bonus.get("tome_id", ""))
		var relic_id := str(bonus.get("relic_id", ""))
		var tome_slot := _find_slot_index("tome", tome_id, slots)
		var relic_slot := _find_slot_index("relic", relic_id, slots)
		if tome_slot >= 0 and relic_slot >= 0 and _slots_are_adjacent(tome_slot, relic_slot):
			bonuses.append(bonus.duplicate(true))

	save_data["active_archive_bonuses"] = bonuses
	var bonus_ids: Array[String] = []
	for bonus in bonuses:
		bonus_ids.append(str(bonus.get("id", "")))
	save_data["active_archive_bonus_ids"] = bonus_ids

func _copy_string_array(source: Array) -> Array[String]:
	var values: Array[String] = []
	for value in source:
		var value_text := str(value)
		if value_text != "":
			values.append(value_text)
	return values

func _unique_string_array(values: Array) -> Array[String]:
	var unique: Array[String] = []
	for value in values:
		var value_text := str(value)
		if value_text != "" and not unique.has(value_text):
			unique.append(value_text)
	return unique

func _record_request_history(request_id: String, state: String, note: String = "") -> void:
	if request_id == "":
		return
	var history: Array = save_data.get("request_history", [])
	history.append({
		"request_id": request_id,
		"state": state,
		"turn": int(save_data.get("library_turn_count", 0)),
		"note": note,
	})
	save_data["request_history"] = history

func _duplicate_pressure_event(source_event: Dictionary) -> Dictionary:
	if source_event.is_empty():
		return {}
	var event_id := str(source_event.get("event_id", ""))
	if event_id == "" or content_db == null or content_db.get_pressure_event_runtime_data(event_id).is_empty():
		return {}
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	var event := {
		"event_id": event_id,
		"source_request_id": str(source_event.get("source_request_id", "")),
		"turn": max(0, int(source_event.get("turn", 0))),
		"turns_remaining": max(1, int(source_event.get("turns_remaining", _get_pressure_event_duration(event_data)))),
	}
	return event

func _maybe_queue_pressure_event(turn_kind: String) -> void:
	if turn_kind == "dive" and current_run != null:
		return
	if has_pending_pressure_event():
		return
	var turn_index := int(save_data.get("library_turn_count", 0))
	if turn_index < 3 or turn_index % 3 != 0:
		return
	var request_id := get_active_request_id()
	var event_id: String = content_db.get_pressure_event_id_for_request(request_id, turn_index)
	if event_id == "":
		return
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	save_data["pressure_event"] = {
		"event_id": event_id,
		"source_request_id": request_id,
		"turn": turn_index,
		"turns_remaining": _get_pressure_event_duration(event_data),
	}

func _get_pressure_event_duration(event_data: Dictionary) -> int:
	if event_data.is_empty():
		return 2
	var threat_kind := str(event_data.get("threat_kind", "pressure"))
	if threat_kind == "attack":
		return 1
	return 2

func _apply_pressure_event_failure(event: Dictionary) -> void:
	if event.is_empty():
		return
	var event_id := str(event.get("event_id", ""))
	match event_id:
		"archive_breach":
			if not _remove_first_archive_item_of_type("tome"):
				_remove_first_archive_item_of_type("relic")
			if get_essence() > 0:
				spend_essence(1)
		"shelf_shift":
			if not _remove_first_archive_item_of_type("tome"):
				_remove_first_archive_item_of_type("relic")
		"relic_drift":
			_remove_first_archive_item_of_type("relic")
		"queue_clog":
			_delay_active_request(1)
		"station_stutter":
			save_data["station_layout_id"] = "balanced"
		"visitor_rush":
			_delay_active_request(1)
			if get_essence() > 0:
				spend_essence(1)
	_unlock_narrative_beat("first_defense_event")
	save_changed.emit()
	_save()

func _get_narrative_beat_definition(beat_id: String) -> Dictionary:
	var beat: Dictionary = NARRATIVE_BEAT_DEFINITIONS.get(beat_id, {})
	if beat.is_empty():
		return {}
	return beat.duplicate(true)

func _unlock_narrative_beat(beat_id: String) -> bool:
	if beat_id == "":
		return false
	if _get_narrative_beat_definition(beat_id).is_empty():
		return false
	var unlock_ids: Array[String] = get_narrative_unlock_ids()
	if unlock_ids.has(beat_id):
		return false
	unlock_ids.append(beat_id)
	save_data["narrative_unlock_ids"] = _unique_string_array(unlock_ids)
	return true

func _unlock_narrative_beats_for_record(record_type: String, _payload: Dictionary = {}) -> bool:
	var changed := false
	for beat_id in NARRATIVE_BEAT_ORDER:
		var beat: Dictionary = _get_narrative_beat_definition(beat_id)
		if beat.is_empty():
			continue
		var trigger_types: Array = beat.get("trigger_record_types", [])
		if trigger_types.has(record_type):
			changed = _unlock_narrative_beat(beat_id) or changed
	return changed

func _remove_first_archive_item_of_type(item_type: String) -> bool:
	if item_type == "":
		return false
	var slots := get_archive_slots()
	for slot_index in range(slots.size()):
		var slot: Dictionary = slots[slot_index]
		if str(slot.get("item_type", "")) == item_type and str(slot.get("item_id", "")) != "":
			return remove_archive_item(slot_index)
	return false

func _delay_active_request(turns: int) -> bool:
	if turns <= 0:
		return false
	var queue := get_request_queue_entries()
	if queue.is_empty():
		return false
	var entry: Dictionary = queue[0]
	entry["deadline_turns_remaining"] = max(0, int(entry.get("deadline_turns_remaining", 0)) + turns)
	entry["deadline_turns_total"] = max(0, int(entry.get("deadline_turns_total", 0)) + turns)
	queue[0] = entry
	save_data["request_queue"] = queue
	return true

func _make_empty_archive_slots() -> Array:
	var slots: Array = []
	for _i in range(ARCHIVE_SLOT_COUNT):
		slots.append({"item_type": "", "item_id": ""})
	return slots

func _duplicate_archive_slots(source_slots: Array) -> Array:
	var slots: Array = []
	if source_slots.is_empty():
		return _make_empty_archive_slots()

	for index in range(ARCHIVE_SLOT_COUNT):
		var slot: Dictionary = {}
		if index < source_slots.size() and typeof(source_slots[index]) == TYPE_DICTIONARY:
			slot = source_slots[index].duplicate(true)
		slot = {
			"item_type": str(slot.get("item_type", "")),
			"item_id": str(slot.get("item_id", "")),
		}
		slots.append(slot)
	return slots

func _remove_archive_item_from_slots(item_type: String, item_id: String, source_slots: Array) -> Array:
	var slots := _duplicate_archive_slots(source_slots)
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		if slot.get("item_type", "") == item_type and slot.get("item_id", "") == item_id:
			slots[index] = {"item_type": "", "item_id": ""}
	return slots

func _find_slot_index(item_type: String, item_id: String, source_slots: Array) -> int:
	for index in range(source_slots.size()):
		var slot: Dictionary = source_slots[index]
		if slot.get("item_type", "") == item_type and slot.get("item_id", "") == item_id:
			return index
	return -1

func _slots_are_adjacent(first_index: int, second_index: int) -> bool:
	var first_x := first_index % ARCHIVE_GRID_COLUMNS
	var first_y := float(first_index) / float(ARCHIVE_GRID_COLUMNS)
	var second_x := second_index % ARCHIVE_GRID_COLUMNS
	var second_y := float(second_index) / float(ARCHIVE_GRID_COLUMNS)
	return abs(first_x - second_x) + abs(first_y - second_y) == 1

func _is_valid_archive_item(item_type: String, item_id: String) -> bool:
	if item_type == "tome":
		return content_db.get_tome(item_id) != null and get_archive_tomes().has(item_id)
	if item_type == "relic":
		return content_db.get_relic(item_id) != null and get_archive_relics().has(item_id)
	return false

func _get_item_name(item_type: String, item_id: String) -> String:
	if item_type == "tome":
		var tome = content_db.get_tome(item_id)
		if tome != null:
			return tome.name
	if item_type == "relic":
		var relic = content_db.get_relic(item_id)
		if relic != null:
			return relic.name
	return item_id

func _save() -> void:
	save_now()

func save_now() -> bool:
	if save_manager == null:
		return false
	var saved: bool = save_manager.save_save(save_data)
	if saved:
		save_changed.emit()
	return saved

func _normalize_essence_state() -> void:
	save_data["essence"] = max(0, int(save_data.get("essence", 0)))
	save_data["library_turn_count"] = max(0, int(save_data.get("library_turn_count", 0)))
	save_data["patron_reroll_count"] = max(0, int(save_data.get("patron_reroll_count", 0)))
	var layout_id := str(save_data.get("station_layout_id", "balanced"))
	if not STATION_LAYOUTS.has(layout_id):
		save_data["station_layout_id"] = "balanced"

func _normalize_progression_state() -> void:
	var wings: Dictionary = save_data.get("wing_progression", {})
	var normalized_wings: Dictionary = {}
	var unlocked_curse_ids: Array[String] = _copy_string_array(save_data.get("unlocked_curse_ids", []))
	for wing_id in get_wing_definition_ids():
		var wing_def := get_wing_definition(wing_id)
		if wing_def.is_empty():
			continue
		var wing_state: Dictionary = {}
		if typeof(wings.get(wing_id, {})) == TYPE_DICTIONARY:
			wing_state = wings.get(wing_id, {}).duplicate(true)
		if wing_state.is_empty():
			wing_state = {
				"wing_id": wing_id,
				"unlocked": bool(wing_def.get("unlocked_by_default", false)),
				"tier": 0,
				"purchased_upgrade_ids": [],
			}
		wing_state["wing_id"] = wing_id
		wing_state["unlocked"] = bool(wing_state.get("unlocked", false)) or bool(wing_def.get("unlocked_by_default", false))
		wing_state["tier"] = int(clamp(int(wing_state.get("tier", 0)), 0, int(wing_def.get("upgrades", []).size())))
		wing_state["purchased_upgrade_ids"] = _unique_string_array(_copy_string_array(wing_state.get("purchased_upgrade_ids", [])))
		normalized_wings[wing_id] = wing_state
	save_data["wing_progression"] = normalized_wings

	var active_wing_id := str(save_data.get("active_wing_id", ""))
	if active_wing_id == "" or not bool(normalized_wings.get(active_wing_id, {}).get("unlocked", false)):
		active_wing_id = ""
		for wing_id in get_wing_definition_ids():
			if bool(normalized_wings.get(wing_id, {}).get("unlocked", false)):
				active_wing_id = wing_id
				break
	save_data["active_wing_id"] = active_wing_id

	var faction_reputation: Dictionary = save_data.get("faction_reputation", {})
	var normalized_reputation: Dictionary = {}
	for faction_id in get_faction_definition_ids():
		normalized_reputation[faction_id] = max(0, int(faction_reputation.get(faction_id, 0)))
	save_data["faction_reputation"] = normalized_reputation

	var meta_unlock_ids: Array[String] = _unique_string_array(_copy_string_array(save_data.get("meta_unlock_ids", [])))
	save_data["meta_unlock_ids"] = meta_unlock_ids
	save_data["meta_spent_essence"] = max(0, int(save_data.get("meta_spent_essence", 0)))

	var unlocked_family_ids: Array[String] = []
	for family_id in get_curse_family_ids():
		var family := get_curse_family_definition(family_id)
		if family.is_empty():
			continue
		if bool(family.get("unlocked_by_default", false)) or meta_unlock_ids.has("unlock_%s" % family_id):
			unlocked_family_ids.append(family_id)
			for curse in family.get("curses", []):
				if typeof(curse) != TYPE_DICTIONARY:
					continue
				var curse_id := str(curse.get("id", ""))
				if curse_id != "" and not unlocked_curse_ids.has(curse_id):
					unlocked_curse_ids.append(curse_id)
	save_data["unlocked_curse_ids"] = _unique_string_array(unlocked_curse_ids)

	var selected_family_id := str(save_data.get("selected_curse_family_id", ""))
	if selected_family_id != "" and not unlocked_family_ids.has(selected_family_id):
		selected_family_id = ""
	var selected_curse_ids: Array[String] = []
	var selected_curse_id := str(save_data.get("selected_curse_id", ""))
	if selected_family_id != "":
		selected_curse_ids = _filter_curses_for_family(_copy_string_array(save_data.get("selected_curse_ids", [])), selected_family_id)
		if selected_curse_id != "" and get_curse_family_for_curse(selected_curse_id) == selected_family_id and not selected_curse_ids.has(selected_curse_id):
			selected_curse_ids.append(selected_curse_id)
	if selected_curse_ids.is_empty() and selected_curse_id != "":
		var selected_family_from_id := get_curse_family_for_curse(selected_curse_id)
		if selected_family_from_id != "" and unlocked_family_ids.has(selected_family_from_id):
			selected_family_id = selected_family_from_id
			selected_curse_ids = [selected_curse_id]
	save_data["selected_curse_family_id"] = selected_family_id
	save_data["selected_curse_ids"] = selected_curse_ids
	save_data["selected_curse_id"] = selected_curse_ids.front() if not selected_curse_ids.is_empty() else ""

	var records: Array[Dictionary] = []
	for record in save_data.get("replay_records", []):
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var payload: Dictionary = {}
		if typeof(record.get("payload", {})) == TYPE_DICTIONARY:
			payload = record.get("payload", {}).duplicate(true)
		records.append({
			"type": str(record.get("type", "")),
			"title": str(record.get("title", "")),
			"summary": str(record.get("summary", "")),
			"turn": max(0, int(record.get("turn", 0))),
			"request_id": str(record.get("request_id", "")),
			"payload": payload,
		})
	while records.size() > get_replay_record_capacity():
		records.pop_front()
	save_data["replay_records"] = records

func _normalize_pressure_state() -> void:
	save_data["pressure_event"] = _duplicate_pressure_event(save_data.get("pressure_event", {}))

func _normalize_request_state() -> void:
	var queue := _duplicate_request_queue(save_data.get("request_queue", []))
	if queue.is_empty():
		queue = _build_initial_request_queue()
	else:
		queue = _normalize_request_queue(queue)
	save_data["request_queue"] = queue
	var active_request_id := str(save_data.get("active_request_id", ""))
	if active_request_id == "" or _find_request_queue_index(queue, active_request_id) < 0:
		active_request_id = str(queue[0].get("request_id", "")) if not queue.is_empty() else content_db.get_default_request_id()
	save_data["active_request_id"] = active_request_id
	var research_job := _duplicate_research_job(save_data.get("research_job", {}))
	if not research_job.is_empty():
		var request_id := str(research_job.get("request_id", ""))
		if request_id == "" or _find_request_queue_index(queue, request_id) < 0:
			research_job = {}
	save_data["research_job"] = research_job

func _duplicate_request_queue(source_queue: Array) -> Array:
	var queue: Array = []
	for entry in source_queue:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var request_id := str(entry.get("request_id", ""))
		if request_id == "":
			continue
		var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
		if request_data.is_empty():
			continue
		queue.append(_sanitize_request_entry(entry, request_data))
	return queue

func _duplicate_research_job(source_job: Dictionary) -> Dictionary:
	if source_job.is_empty():
		return {}
	return {
		"request_id": str(source_job.get("request_id", "")),
		"state": str(source_job.get("state", "pending")),
		"turns_total": max(0, int(source_job.get("turns_total", 0))),
		"turns_remaining": max(0, int(source_job.get("turns_remaining", 0))),
		"tome_id": str(source_job.get("tome_id", "")),
		"relic_id": str(source_job.get("relic_id", "")),
		"progress": max(0, int(source_job.get("progress", 0))),
		"progress_total": max(1, int(source_job.get("progress_total", 1))),
		"essence_reward": max(0, int(source_job.get("essence_reward", 0))),
		"essence_cost": max(0, int(source_job.get("essence_cost", 0))),
		"paid": bool(source_job.get("paid", false)),
		"reward_card_ids": _copy_string_array(source_job.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(source_job.get("reward_room_ids", [])),
		"knowledge_tags": _copy_string_array(source_job.get("knowledge_tags", [])),
	}

func _find_request_queue_index(queue: Array, request_id: String) -> int:
	for index in range(queue.size()):
		var entry: Dictionary = queue[index]
		if str(entry.get("request_id", "")) == request_id:
			return index
	return -1

func _get_request_deadline_kind(request_data: Dictionary) -> String:
	if int(request_data.get("required_essence", 0)) > 0:
		return "library"
	if request_data.get("required_knowledge_tags", []).size() > 0:
		return "library"
	return "dive"

func _award_faction_reputation_for_request(request_data: Dictionary, source: String = "") -> void:
	var faction_id := _resolve_faction_id_for_request(request_data)
	if faction_id == "":
		return
	var request_name := str(request_data.get("name", request_data.get("id", "")))
	add_faction_reputation(faction_id, 1, request_name if source == "" else source)

func _resolve_faction_id_for_request(request_data: Dictionary) -> String:
	var tags: Array[String] = _copy_string_array(request_data.get("required_knowledge_tags", []))
	var request_id := str(request_data.get("id", request_data.get("request_id", "")))
	if tags.is_empty() and request_id != "":
		var request = content_db.get_request(request_id)
		if request != null:
			tags = _copy_string_array(request.required_knowledge_tags)
	for faction_id in get_faction_definition_ids():
		var faction := get_faction_definition(faction_id)
		for tag in tags:
			if _copy_string_array(faction.get("tracked_tags", [])).has(tag):
				return faction_id
	return ""

func _unlock_curse_family(family_id: String) -> void:
	if family_id == "":
		return
	var token := "unlock_%s" % family_id
	var unlock_ids: Array[String] = _copy_string_array(save_data.get("meta_unlock_ids", []))
	if not unlock_ids.has(token):
		unlock_ids.append(token)
	save_data["meta_unlock_ids"] = _unique_string_array(unlock_ids)
	var unlocked_curse_ids: Array[String] = _copy_string_array(save_data.get("unlocked_curse_ids", []))
	var family := get_curse_family_definition(family_id)
	for curse in family.get("curses", []):
		if typeof(curse) != TYPE_DICTIONARY:
			continue
		var curse_id := str(curse.get("id", ""))
		if curse_id != "" and not unlocked_curse_ids.has(curse_id):
			unlocked_curse_ids.append(curse_id)
	save_data["unlocked_curse_ids"] = _unique_string_array(unlocked_curse_ids)

func _filter_curses_for_family(curse_ids: Array, family_id: String) -> Array[String]:
	var selected: Array[String] = []
	for curse_id in curse_ids:
		var curse_text := str(curse_id)
		if curse_text == "":
			continue
		if get_curse_family_for_curse(curse_text) != family_id:
			continue
		if not selected.has(curse_text):
			selected.append(curse_text)
	return selected

func _get_request_queue_entry_for_id(request_id: String) -> Dictionary:
	var queue := get_request_queue_entries()
	for entry in queue:
		if str(entry.get("request_id", "")) == request_id:
			return entry
	return {}

func _pick_research_definition(request_data: Dictionary) -> Dictionary:
	var research_ids: Array[String] = content_db.get_research_definition_ids()
	if research_ids.is_empty():
		return {}
	var request_key := str(request_data.get("id", request_data.get("request_id", "")))
	var index: int = abs(hash(request_key)) % research_ids.size()
	return content_db.get_research_runtime_data(research_ids[index])

func _normalize_request_queue(queue: Array) -> Array:
	var normalized: Array = []
	var completed_request_ids: Array = save_data.get("completed_request_ids", [])
	for entry in queue:
		var sanitized := _sanitize_request_entry(entry)
		if sanitized.is_empty():
			continue
		var request_id := str(sanitized.get("request_id", ""))
		if request_id == "" or completed_request_ids.has(request_id):
			continue
		if int(sanitized.get("deadline_turns_remaining", 0)) <= 0 and str(sanitized.get("state", "")) not in ["completed", "expired"]:
			sanitized["state"] = "expired"
		normalized.append(sanitized)
	if normalized.is_empty():
		return _build_initial_request_queue()
	normalized[0]["state"] = "active"
	for index in range(1, normalized.size()):
		if str(normalized[index].get("state", "")) == "active":
			normalized[index]["state"] = "queued"
	return normalized

func _build_initial_request_queue() -> Array:
	var queue: Array = []
	var request_ids: Array[String] = content_db.get_request_pool()
	if request_ids.is_empty():
		return queue
	var active_request_id := str(save_data.get("active_request_id", ""))
	var start_index := request_ids.find(active_request_id)
	if start_index < 0:
		start_index = 0
	for offset in range(request_ids.size()):
		if queue.size() >= REQUEST_QUEUE_SIZE:
			break
		var candidate_id := request_ids[(start_index + offset) % request_ids.size()]
		if candidate_id == "" or _find_request_queue_index(queue, candidate_id) >= 0:
			continue
		queue.append(_make_request_queue_entry(candidate_id, "active" if queue.is_empty() else "queued"))
	return queue

func _make_request_queue_entry(request_id: String, state: String) -> Dictionary:
	var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
	if request_data.is_empty():
		return {}
	var entry: Dictionary = _sanitize_request_entry({
		"request_id": request_id,
		"state": state,
		"deadline_turns_remaining": max(2, int(request_data.get("deadline_turns", 0))),
		"deadline_turns_total": max(2, int(request_data.get("deadline_turns", 0))),
		"progress": 0,
		"progress_total": 1,
	}, request_data)
	entry["progress_total"] = max(
		1,
		int(request_data.get("required_knowledge_tags", []).size()) +
		int(request_data.get("required_tome_ids", []).size()) +
		int(request_data.get("required_relic_ids", []).size())
	)
	return entry

func _queue_research_job(request_id: String, tome_id: String, relic_id: String) -> void:
	if request_id == "":
		return
	var research_def: Dictionary = _pick_research_definition(content_db.get_request_runtime_data(request_id))
	save_data["research_job"] = {
		"request_id": request_id,
		"state": "pending",
		"turns_total": max(1, int(research_def.get("turn_cost", RESEARCH_TURNS_BASE))),
		"turns_remaining": max(1, int(research_def.get("turn_cost", RESEARCH_TURNS_BASE))),
		"tome_id": tome_id,
		"relic_id": relic_id,
		"progress": 0,
		"progress_total": 1,
		"essence_reward": int(research_def.get("essence_reward", 0)),
		"essence_cost": int(research_def.get("essence_cost", 0)),
		"paid": false,
		"reward_card_ids": _copy_string_array(research_def.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(research_def.get("reward_room_ids", [])),
		"knowledge_tags": _copy_string_array(research_def.get("knowledge_tags", [])),
	}
	save_changed.emit()
	_save()

func _advance_research_job_turn() -> void:
	var job: Dictionary = _duplicate_research_job(save_data.get("research_job", {}))
	if job.is_empty() or str(job.get("state", "")) != "researching":
		return
	job["turns_remaining"] = max(0, int(job.get("turns_remaining", 0)) - 1)
	if int(job.get("turns_remaining", 0)) <= 0:
		_complete_research_job(job)
		return
	save_data["research_job"] = job

func _complete_research_job(job: Dictionary) -> void:
	if job.is_empty():
		return
	if not bool(job.get("paid", false)) and int(job.get("essence_cost", 0)) > 0:
		if not spend_essence(int(job.get("essence_cost", 0))):
			return
		job["paid"] = true
	var request_id := str(job.get("request_id", ""))
	if request_id != "":
		var entry := _get_request_queue_entry_for_id(request_id)
		if not entry.is_empty():
			_complete_request_entry(entry, "research")
			return
	if int(job.get("essence_reward", 0)) > 0:
		add_essence(int(job.get("essence_reward", 0)))
	for card_id in job.get("reward_card_ids", []):
		grant_card_to_collection(str(card_id))
	save_data["research_job"] = {}
	save_changed.emit()
	_save()

func _rotate_request_queue_after_completion(request_id: String) -> void:
	if request_id == "":
		return
	var queue := get_request_queue_entries()
	var index := _find_request_queue_index(queue, request_id)
	if index >= 0:
		queue.remove_at(index)
	_refill_request_queue_after_removal(queue)
	_commit_request_queue(queue)

func _refill_request_queue_after_removal(queue: Array) -> String:
	while queue.size() < REQUEST_QUEUE_SIZE:
		var next_request_id := _find_next_request_id_for_queue(queue)
		if next_request_id == "":
			break
		queue.append(_make_request_queue_entry(next_request_id, "queued"))
	if not queue.is_empty():
		queue[0]["state"] = "active"
		for index in range(1, queue.size()):
			if str(queue[index].get("state", "")) == "active":
				queue[index]["state"] = "queued"
		return str(queue[0].get("request_id", ""))
	return content_db.get_default_request_id()

func _commit_request_queue(queue: Array) -> void:
	var normalized: Array = _duplicate_request_queue(queue)
	if normalized.is_empty():
		normalized = _build_initial_request_queue()
	else:
		normalized = _normalize_request_queue(normalized)
	save_data["request_queue"] = normalized
	if normalized.is_empty():
		save_data["active_request_id"] = content_db.get_default_request_id()
	else:
		save_data["active_request_id"] = str(normalized[0].get("request_id", ""))
	save_changed.emit()
	_save()

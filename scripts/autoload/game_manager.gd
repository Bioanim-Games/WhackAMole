extends Node

## Central progression, Points & Coins balance, Audio Settings, PvZ-style lane unlock,
## triangular mole unlock (+1, +2, +3, +4 matches), and store inventory manager.

signal state_changed

const SAVE_PATH: String = "user://save_data.cfg"
const STARTING_POINTS: int = 0
const STARTING_COINS: int = 250

const MOLE_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "casco",
		"name_key": "MOLE_CASCO_NAME",
		"desc_key": "MOLE_CASCO_DESC",
		"required_matches": 0,
		"first_game_number": 1,
		"accent_color": Color("#FFB800"),
	},
	{
		"id": "escudo",
		"name_key": "MOLE_ESCUDO_NAME",
		"desc_key": "MOLE_ESCUDO_DESC",
		"required_matches": 1,
		"first_game_number": 2,
		"accent_color": Color("#4A90E2"),
	},
	{
		"id": "ninja",
		"name_key": "MOLE_NINJA_NAME",
		"desc_key": "MOLE_NINJA_DESC",
		"required_matches": 3,
		"first_game_number": 4,
		"accent_color": Color("#E74C3C"),
	},
	{
		"id": "payaso",
		"name_key": "MOLE_PAYASO_NAME",
		"desc_key": "MOLE_PAYASO_DESC",
		"required_matches": 6,
		"first_game_number": 7,
		"accent_color": Color("#AF7AC5"),
	},
	{
		"id": "dorado",
		"name_key": "MOLE_DORADO_NAME",
		"desc_key": "MOLE_DORADO_DESC",
		"required_matches": 10,
		"first_game_number": 11,
		"accent_color": Color("#FFD700"),
	},
]

const TOOL_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "drill",
		"name_key": "TOOL_DRILL_NAME",
		"desc_key": "TOOL_DRILL_DESC",
		"cost": 200,
		"accent_color": Color("#F39C12"),
	},
	{
		"id": "air_pump",
		"name_key": "TOOL_AIRPUMP_NAME",
		"desc_key": "TOOL_AIRPUMP_DESC",
		"cost": 250,
		"accent_color": Color("#E74C3C"),
	},
	{
		"id": "multi_hammer",
		"name_key": "TOOL_MULTIHAMMER_NAME",
		"desc_key": "TOOL_MULTIHAMMER_DESC",
		"cost": 350,
		"accent_color": Color("#9B59B6"),
	},
	{
		"id": "water_hose",
		"name_key": "TOOL_WATER_NAME",
		"desc_key": "TOOL_WATER_DESC",
		"cost": 150,
		"accent_color": Color("#3498DB"),
	},
]

const HAMMER_PATTERNS: Array[Dictionary] = [
	{"id": "HORIZONTAL", "label_key": "PATTERN_HORIZONTAL"},
	{"id": "VERTICAL", "label_key": "PATTERN_VERTICAL"},
	{"id": "DIAGONAL", "label_key": "PATTERN_DIAGONAL"},
	{"id": "V_SHAPE", "label_key": "PATTERN_V"},
	{"id": "INV_V", "label_key": "PATTERN_INV_V"},
]

var player_rank: int = 1
var total_points: int = STARTING_POINTS
var total_coins: int = STARTING_COINS
var matches_completed: int = 0
var owned_tools: Array[String] = []
var equipped_tool: String = ""
var multihammer_pattern: String = "HORIZONTAL"

var music_enabled: bool = true
var music_volume: float = 0.80
var sfx_enabled: bool = true
var sfx_volume: float = 0.90


func _ready() -> void:
	load_progress()


func get_current_stage_number() -> int:
	return matches_completed + 1


func get_unlocked_lanes_count() -> int:
	if matches_completed <= 1:
		return 1
	elif matches_completed <= 4:
		return 2
	return 3


func get_active_lane_rows() -> Array[bool]:
	var lanes: int = get_unlocked_lanes_count()
	if lanes == 1:
		return [false, true, false]
	elif lanes == 2:
		return [false, true, true]
	return [true, true, true]


func get_active_holes_count() -> int:
	return get_unlocked_lanes_count() * 3


func get_current_mole_exposure_seconds() -> float:
	var duration: float = 5.0 - float(player_rank - 1) * 0.25
	return snappedf(maxf(1.8, duration), 0.1)


func is_mole_unlocked(mole_id: String) -> bool:
	for mole_def: Dictionary in MOLE_DEFINITIONS:
		if mole_def["id"] == mole_id:
			return matches_completed >= int(mole_def["required_matches"])
	return false


func get_featured_mole_for_current_stage() -> Dictionary:
	var best_unlocked: Dictionary = MOLE_DEFINITIONS[0]
	for mole_def: Dictionary in MOLE_DEFINITIONS:
		if matches_completed >= int(mole_def["required_matches"]):
			best_unlocked = mole_def
	return best_unlocked


func get_next_locked_mole_info() -> Dictionary:
	for mole_def: Dictionary in MOLE_DEFINITIONS:
		var req: int = int(mole_def["required_matches"])
		if matches_completed < req:
			return {
				"mole": mole_def,
				"matches_remaining": req - matches_completed,
			}
	return {}


func is_tool_owned(tool_id: String) -> bool:
	return owned_tools.has(tool_id)


func can_afford_tool(tool_id: String) -> bool:
	for t: Dictionary in TOOL_DEFINITIONS:
		if t["id"] == tool_id:
			return total_coins >= int(t["cost"])
	return false


func buy_tool(tool_id: String) -> bool:
	if is_tool_owned(tool_id):
		return false
	for t: Dictionary in TOOL_DEFINITIONS:
		if t["id"] == tool_id:
			var cost: int = int(t["cost"])
			if total_coins >= cost:
				total_coins -= cost
				owned_tools.append(tool_id)
				equipped_tool = tool_id
				save_progress()
				state_changed.emit()
				return true
	return false


func equip_tool(tool_id: String) -> void:
	if tool_id == "" or is_tool_owned(tool_id):
		equipped_tool = tool_id
		save_progress()
		state_changed.emit()


func set_hammer_pattern(pattern_id: String) -> void:
	multihammer_pattern = pattern_id
	save_progress()
	state_changed.emit()


func get_equipped_tool_display_name() -> String:
	if equipped_tool == "":
		return LocalizationManager.t("TOOL_NONE")
	for t: Dictionary in TOOL_DEFINITIONS:
		if t["id"] == equipped_tool:
			return LocalizationManager.t(String(t["name_key"]))
	return LocalizationManager.t("TOOL_NONE")


func record_match_completed(points_earned: int = 100, coins_earned: int = 150) -> void:
	matches_completed += 1
	total_points += points_earned
	total_coins += coins_earned
	player_rank = 1 + matches_completed
	save_progress()
	state_changed.emit()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	save_progress()
	state_changed.emit()


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	save_progress()
	state_changed.emit()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	save_progress()
	state_changed.emit()


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	save_progress()
	state_changed.emit()


func reset_progress() -> void:
	player_rank = 1
	total_points = STARTING_POINTS
	total_coins = STARTING_COINS
	matches_completed = 0
	owned_tools.clear()
	equipped_tool = ""
	multihammer_pattern = "HORIZONTAL"
	save_progress()
	state_changed.emit()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "player_rank", player_rank)
	cfg.set_value("progress", "total_points", total_points)
	cfg.set_value("progress", "total_coins", total_coins)
	cfg.set_value("progress", "matches_completed", matches_completed)
	cfg.set_value("progress", "owned_tools", owned_tools)
	cfg.set_value("progress", "equipped_tool", equipped_tool)
	cfg.set_value("progress", "multihammer_pattern", multihammer_pattern)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_rank = int(cfg.get_value("progress", "player_rank", 1))
	total_points = int(cfg.get_value("progress", "total_points", STARTING_POINTS))
	total_coins = int(cfg.get_value("progress", "total_coins", STARTING_COINS))
	matches_completed = int(cfg.get_value("progress", "matches_completed", 0))
	var saved_tools: Variant = cfg.get_value("progress", "owned_tools", [])
	owned_tools.clear()
	if saved_tools is Array:
		for item: Variant in saved_tools:
			owned_tools.append(String(item))
	equipped_tool = String(cfg.get_value("progress", "equipped_tool", ""))
	multihammer_pattern = String(cfg.get_value("progress", "multihammer_pattern", "HORIZONTAL"))
	music_enabled = bool(cfg.get_value("audio", "music_enabled", true))
	music_volume = float(cfg.get_value("audio", "music_volume", 0.80))
	sfx_enabled = bool(cfg.get_value("audio", "sfx_enabled", true))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", 0.90))

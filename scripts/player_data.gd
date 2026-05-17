extends Node

const SAVE_PATH := "user://player_data.cfg"
const SECTION := "player"
const KEY_DISPLAY_NAME := "display_name"

const MIN_NAME_LENGTH := 3
const MAX_NAME_LENGTH := 30

var display_name := ""
var difficulty := DifficultySettings.DEFAULT_DIFFICULTY
var _session_name_confirmed := false


func _ready() -> void:
	_load()


func get_display_name() -> StringName:
	return display_name


func has_name() -> bool:
	return display_name.strip_edges().length() >= MIN_NAME_LENGTH


func has_session_name() -> bool:
	return _session_name_confirmed


func save_name(new_name: String) -> bool:
	var sanitized := new_name.strip_edges()
	if sanitized.length() < MIN_NAME_LENGTH:
		return false
	if sanitized.length() > MAX_NAME_LENGTH:
		sanitized = sanitized.substr(0, MAX_NAME_LENGTH)
	display_name = sanitized

	var config := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		config.load(SAVE_PATH)
	config.set_value(SECTION, KEY_DISPLAY_NAME, display_name)
	return config.save(SAVE_PATH) == OK


func set_difficulty(d: String) -> void:
	difficulty = DifficultySettings.normalize_difficulty(d)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		display_name = ""
		return
	display_name = String(config.get_value(SECTION, KEY_DISPLAY_NAME, ""))

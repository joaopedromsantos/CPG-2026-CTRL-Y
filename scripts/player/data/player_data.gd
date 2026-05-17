extends Node

const PLAYER_PROFILE_STORE_SCRIPT = preload("res://scripts/player/data/player_profile_store.gd")
const DIFFICULTY_SETTINGS_SCRIPT = preload("res://scripts/settings/difficulty_settings.gd")

const SAVE_PATH := "user://player_data.cfg"
const SECTION := "player"
const KEY_DISPLAY_NAME := "display_name"

const MIN_NAME_LENGTH := 3
const MAX_NAME_LENGTH := 30

var save_path := SAVE_PATH
var display_name := ""
var difficulty := DIFFICULTY_SETTINGS_SCRIPT.DEFAULT_DIFFICULTY
var _session_name_confirmed := false
var _store = PLAYER_PROFILE_STORE_SCRIPT.new()


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
	return _store.save_display_name(save_path, SECTION, KEY_DISPLAY_NAME, display_name)


func set_difficulty(new_difficulty: String) -> void:
	difficulty = DIFFICULTY_SETTINGS_SCRIPT.normalize_difficulty(new_difficulty)


func _load() -> void:
	display_name = _store.load_display_name(save_path, SECTION, KEY_DISPLAY_NAME)

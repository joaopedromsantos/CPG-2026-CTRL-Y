extends GutTest

const PLAYER_DATA_SCRIPT = preload("res://scripts/player/data/player_data.gd")

var _player_data


func before_each() -> void:
	_player_data = PLAYER_DATA_SCRIPT.new()
	_player_data.save_path = "user://test_player_data.cfg"
	add_child_autoqfree(_player_data)


func after_each() -> void:
	if FileAccess.file_exists(_player_data.save_path):
		DirAccess.remove_absolute(_player_data.save_path)


func test_save_name_trims_and_persists_valid_name() -> void:
	assert_true(_player_data.save_name("  Ada  "))

	assert_eq(String(_player_data.get_display_name()), "Ada")
	assert_true(_player_data.has_name())


func test_save_name_rejects_short_name() -> void:
	assert_false(_player_data.save_name("Al"))

	assert_eq(String(_player_data.get_display_name()), "")
	assert_false(_player_data.has_name())


func test_save_name_truncates_long_name() -> void:
	var long_name := "abcdefghijklmnopqrstuvwxyz1234567890"

	assert_true(_player_data.save_name(long_name))

	assert_eq(String(_player_data.get_display_name()).length(), _player_data.MAX_NAME_LENGTH)


func test_set_difficulty_normalizes_invalid_value() -> void:
	_player_data.set_difficulty("invalid")

	assert_eq(_player_data.difficulty, DifficultySettings.DEFAULT_DIFFICULTY)

extends GutTest

const PLAYER_RECORD_SCRIPT = preload("res://scripts/player/record/player_record.gd")

var _player_record


func before_each() -> void:
	_player_record = PLAYER_RECORD_SCRIPT.new()
	_player_record.save_path = "user://test_player_record.cfg"
	add_child_autoqfree(_player_record)


func after_each() -> void:
	if FileAccess.file_exists(_player_record.save_path):
		DirAccess.remove_absolute(_player_record.save_path)


func test_update_high_score_saves_larger_score() -> void:
	assert_true(_player_record.update_high_score(42))

	assert_eq(_player_record.high_score, 42)
	assert_eq(_player_record.get_high_score_text(), "HS: 42")


func test_update_high_score_rejects_lower_score() -> void:
	assert_true(_player_record.update_high_score(42))

	assert_false(_player_record.update_high_score(10))

	assert_eq(_player_record.high_score, 42)


func test_update_high_score_rejects_negative_score() -> void:
	assert_false(_player_record.update_high_score(-5))

	assert_eq(_player_record.high_score, 0)


func test_load_high_score_defaults_to_zero_when_file_is_missing() -> void:
	_player_record.load_high_score()

	assert_eq(_player_record.high_score, 0)

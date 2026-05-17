extends GutTest

const DIFFICULTY_SETTINGS_SCRIPT = preload("res://scripts/settings/difficulty_settings.gd")
const SOUND_SETTINGS_SCRIPT = preload("res://scripts/settings/sound_settings.gd")


func test_difficulty_settings_normalizes_valid_and_invalid_values() -> void:
	assert_eq(DIFFICULTY_SETTINGS_SCRIPT.normalize_difficulty("hard"), "hard")
	assert_eq(DIFFICULTY_SETTINGS_SCRIPT.normalize_difficulty("invalid"), "easy")


func test_difficulty_settings_returns_labels_and_lives() -> void:
	assert_eq(DIFFICULTY_SETTINGS_SCRIPT.get_label("medium"), "Médio")
	assert_eq(DIFFICULTY_SETTINGS_SCRIPT.get_max_lives("impossible"), 3)


func test_sound_settings_clamps_volume_and_converts_silent_to_db_floor() -> void:
	assert_eq(SOUND_SETTINGS_SCRIPT.normalize_volume(-1), 0)
	assert_eq(SOUND_SETTINGS_SCRIPT.normalize_volume(20), 10)
	assert_eq(SOUND_SETTINGS_SCRIPT.volume_to_db(0), SOUND_SETTINGS_SCRIPT.SILENT_DB)


func test_sound_settings_apply_ignores_null_player() -> void:
	SOUND_SETTINGS_SCRIPT.apply_sfx_volume(null, 5)

	assert_true(true)

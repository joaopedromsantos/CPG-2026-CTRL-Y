extends GutTest

const MAIN_SCRIPT = preload("res://scripts/game/main.gd")
const POINTER_CURSOR_MANAGER_SCRIPT = preload("res://scripts/game/pointer_cursor_manager.gd")


func test_game_scripts_load_from_context_folder() -> void:
	assert_not_null(MAIN_SCRIPT)
	assert_not_null(POINTER_CURSOR_MANAGER_SCRIPT)

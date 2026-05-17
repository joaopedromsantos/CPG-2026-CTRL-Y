extends GutTest

const ABOUT_SCREEN_SCRIPT = preload("res://scripts/screens/about/about_screen.gd")
const HELP_SCREEN_SCRIPT = preload("res://scripts/screens/help/help_screen.gd")
const INTRO_SCREEN_SCRIPT = preload("res://scripts/screens/intro/intro_screen.gd")
const NAME_INPUT_SCREEN_SCRIPT = preload("res://scripts/screens/name_input/name_input_screen.gd")
const PAUSE_SCREEN_SCRIPT = preload("res://scripts/screens/pause/pause_screen.gd")
const SETTINGS_SCREEN_SCRIPT = preload("res://scripts/screens/settings/settings_screen.gd")
const START_ABOUT_BUTTON_SCRIPT = preload("res://scripts/screens/start/start_about_button.gd")
const START_HELP_BUTTON_SCRIPT = preload("res://scripts/screens/start/start_help_button.gd")


func test_screen_scripts_load_from_context_folders() -> void:
	assert_not_null(ABOUT_SCREEN_SCRIPT)
	assert_not_null(HELP_SCREEN_SCRIPT)
	assert_not_null(INTRO_SCREEN_SCRIPT)
	assert_not_null(NAME_INPUT_SCREEN_SCRIPT)
	assert_not_null(PAUSE_SCREEN_SCRIPT)
	assert_not_null(SETTINGS_SCREEN_SCRIPT)
	assert_not_null(START_ABOUT_BUTTON_SCRIPT)
	assert_not_null(START_HELP_BUTTON_SCRIPT)

extends GutTest

const RANKING_API_SCRIPT = preload("res://scripts/ranking/ranking_api.gd")
const RANKING_SCREEN_SCRIPT = preload("res://scripts/ranking/ranking_screen.gd")


func test_ranking_scripts_load_from_context_folder() -> void:
	assert_not_null(RANKING_API_SCRIPT)
	assert_not_null(RANKING_SCREEN_SCRIPT)

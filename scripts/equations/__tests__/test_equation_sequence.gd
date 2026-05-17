extends GutTest

const EQUATION_SEQUENCE_SCRIPT = preload("res://scripts/equations/equation_sequence.gd")


func test_load_from_missing_file_returns_false() -> void:
	var sequence = EQUATION_SEQUENCE_SCRIPT.new()

	assert_false(sequence.load_from_file("res://missing-equations.json"))
	assert_push_error("Could not open equations file")


func test_start_without_loaded_questions_returns_empty_equation() -> void:
	var sequence = EQUATION_SEQUENCE_SCRIPT.new()

	assert_eq(sequence.start(), {})


func test_invalid_difficulty_falls_back_to_easy_without_error() -> void:
	var sequence = EQUATION_SEQUENCE_SCRIPT.new()

	sequence.set_difficulty("invalid")

	assert_eq(sequence.current_equation(), {})

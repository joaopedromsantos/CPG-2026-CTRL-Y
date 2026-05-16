extends Node

const DIFFICULTY_EASY := "easy"
const DIFFICULTY_MEDIUM := "medium"
const DIFFICULTY_HARD := "hard"
const VALID_DIFFICULTIES := [DIFFICULTY_EASY, DIFFICULTY_MEDIUM, DIFFICULTY_HARD]

var selected_difficulty := DIFFICULTY_EASY


func set_difficulty(difficulty: String) -> void:
	if difficulty in VALID_DIFFICULTIES:
		selected_difficulty = difficulty
	else:
		push_warning("Invalid difficulty '%s'. Keeping '%s'." % [difficulty, selected_difficulty])

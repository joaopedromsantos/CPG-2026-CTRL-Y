class_name DifficultySettings
extends RefCounted

const DIFFICULTY_EASY := "easy"
const DIFFICULTY_MEDIUM := "medium"
const DIFFICULTY_HARD := "hard"
const DIFFICULTY_IMPOSSIBLE := "impossible"
const DEFAULT_DIFFICULTY := DIFFICULTY_EASY
const VALID_DIFFICULTIES := [DIFFICULTY_EASY, DIFFICULTY_MEDIUM, DIFFICULTY_HARD, DIFFICULTY_IMPOSSIBLE]
const LABELS := {
	DIFFICULTY_EASY: "Fácil",
	DIFFICULTY_MEDIUM: "Médio",
	DIFFICULTY_HARD: "Difícil",
	DIFFICULTY_IMPOSSIBLE: "Impossível",
}
const MAX_LIVES := {
	DIFFICULTY_EASY: 6,
	DIFFICULTY_MEDIUM: 5,
	DIFFICULTY_HARD: 4,
	DIFFICULTY_IMPOSSIBLE: 3,
}


static func normalize_difficulty(difficulty: String) -> String:
	if difficulty in VALID_DIFFICULTIES:
		return difficulty

	push_warning("Invalid difficulty '%s'. Falling back to '%s'." % [difficulty, DEFAULT_DIFFICULTY])
	return DEFAULT_DIFFICULTY


static func get_label(difficulty: String) -> String:
	return String(LABELS.get(normalize_difficulty(difficulty), LABELS[DEFAULT_DIFFICULTY]))


static func get_max_lives(difficulty: String) -> int:
	return int(MAX_LIVES.get(normalize_difficulty(difficulty), MAX_LIVES[DEFAULT_DIFFICULTY]))


static func get_difficulty_for_index(index: int) -> String:
	if index < 0 or index >= VALID_DIFFICULTIES.size():
		return DEFAULT_DIFFICULTY

	return String(VALID_DIFFICULTIES[index])


static func get_index(difficulty: String) -> int:
	var normalized := normalize_difficulty(difficulty)
	return VALID_DIFFICULTIES.find(normalized)

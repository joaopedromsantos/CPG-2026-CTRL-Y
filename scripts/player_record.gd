extends Node

const SAVE_PATH := "user://player_record.cfg"
const SECTION := "player"
const KEY_HIGH_SCORE := "high_score"

var high_score := 0


func _ready() -> void:
	load_high_score()


func load_high_score() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		high_score = 0
		return

	high_score = int(config.get_value(SECTION, KEY_HIGH_SCORE, 0))


func update_high_score(score: int) -> bool:
	var normalized_score := maxi(score, 0)
	if normalized_score <= high_score:
		return false

	high_score = normalized_score
	return _save()


func get_high_score_text() -> String:
	return "HS: %d" % high_score


func _save() -> bool:
	var config := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		config.load(SAVE_PATH)

	config.set_value(SECTION, KEY_HIGH_SCORE, high_score)
	return config.save(SAVE_PATH) == OK

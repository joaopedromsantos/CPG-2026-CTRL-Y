extends Node

const PLAYER_RECORD_STORE_SCRIPT = preload("res://scripts/player/record/player_record_store.gd")

const SAVE_PATH := "user://player_record.cfg"
const SECTION := "player"
const KEY_HIGH_SCORE := "high_score"

var save_path := SAVE_PATH
var high_score := 0
var _store = PLAYER_RECORD_STORE_SCRIPT.new()


func _ready() -> void:
	load_high_score()


func load_high_score() -> void:
	high_score = _store.load_high_score(save_path, SECTION, KEY_HIGH_SCORE)


func update_high_score(score: int) -> bool:
	var normalized_score := maxi(score, 0)
	if normalized_score <= high_score:
		return false

	high_score = normalized_score
	return _save()


func get_high_score_text() -> String:
	return "HS: %d" % high_score


func _save() -> bool:
	return _store.save_high_score(save_path, SECTION, KEY_HIGH_SCORE, high_score)

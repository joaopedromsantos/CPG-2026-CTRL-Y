class_name EquationSequence
extends RefCounted

const DEFAULT_JSON_PATH := "res://data/equations.json"
const EASY_LIMIT := 10
const MEDIUM_LIMIT := 10

var _rng := RandomNumberGenerator.new()
var _easy_equations: Array[Dictionary] = []
var _medium_equations: Array[Dictionary] = []
var _hard_equations: Array[Dictionary] = []
var _shown_count := 0


func _init() -> void:
	_rng.randomize()


func load_from_file(path := DEFAULT_JSON_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open equations file: %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("Invalid equations JSON root: %s" % path)
		return false

	var root := parsed as Dictionary
	if not (root.get("equations", []) is Array):
		push_error("Invalid equations JSON list: %s" % path)
		return false

	_reset_buckets(root["equations"])
	return true


func reset() -> void:
	_shown_count = 0
	_shuffle_bucket(_easy_equations)
	_shuffle_bucket(_medium_equations)
	_shuffle_bucket(_hard_equations)


func next_equation() -> Dictionary:
	var bucket := _current_bucket()
	if bucket.is_empty():
		return {}

	_shown_count += 1
	return bucket.pop_back()


func _reset_buckets(equations: Array) -> void:
	_easy_equations.clear()
	_medium_equations.clear()
	_hard_equations.clear()
	_shown_count = 0

	for item in equations:
		if not (item is Dictionary):
			continue

		var equation := item as Dictionary
		match String(equation.get("level", "")):
			"easy":
				_easy_equations.append(equation)
			"medium":
				_medium_equations.append(equation)
			"hard":
				_hard_equations.append(equation)

	_shuffle_bucket(_easy_equations)
	_shuffle_bucket(_medium_equations)
	_shuffle_bucket(_hard_equations)


func _current_bucket() -> Array[Dictionary]:
	if _shown_count < EASY_LIMIT and not _easy_equations.is_empty():
		return _easy_equations

	if _shown_count < EASY_LIMIT + MEDIUM_LIMIT and not _medium_equations.is_empty():
		return _medium_equations

	return _hard_equations


func _shuffle_bucket(bucket: Array[Dictionary]) -> void:
	for i in range(bucket.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp := bucket[i]
		bucket[i] = bucket[j]
		bucket[j] = temp

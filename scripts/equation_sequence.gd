class_name EquationSequence
extends RefCounted

const DEFAULT_JSON_PATH := "res://data/equations.json"
const EASY_LIMIT := 10
const MEDIUM_LIMIT := 10
const DEFAULT_QUEUE_SIZE := 3

var _rng := RandomNumberGenerator.new()
var _easy_equations: Array[Dictionary] = []
var _medium_equations: Array[Dictionary] = []
var _hard_equations: Array[Dictionary] = []
var _source_equations: Array = []
var _equation_queue: Array[Dictionary] = []
var _current_equation: Dictionary = {}
var _shown_count := 0
var _queue_size := DEFAULT_QUEUE_SIZE


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

	_source_equations = (root["equations"] as Array).duplicate(true)
	_reset_buckets(_source_equations)
	return true


func reset() -> void:
	_current_equation = {}
	_equation_queue.clear()
	_reset_buckets(_source_equations)
	_fill_queue()


func start(queue_size := DEFAULT_QUEUE_SIZE) -> Dictionary:
	_queue_size = queue_size
	reset()
	return advance()


func advance() -> Dictionary:
	_fill_queue()
	if _equation_queue.is_empty():
		_current_equation = {}
		return _current_equation

	_current_equation = _equation_queue.pop_front()
	_fill_queue()
	return _current_equation


func current_equation() -> Dictionary:
	return _current_equation


func next_equation() -> Dictionary:
	var bucket := _current_bucket()
	if bucket.is_empty():
		return {}

	_shown_count += 1
	return bucket.pop_back()


func _fill_queue() -> void:
	while _equation_queue.size() < _queue_size:
		var equation := next_equation()
		if equation.is_empty():
			return

		_equation_queue.append(_prepare_queued_equation(equation))


func _prepare_queued_equation(equation: Dictionary) -> Dictionary:
	var queued := equation.duplicate(true)
	var options: Array = queued.get("options", [])
	var queued_options := options.duplicate()
	_shuffle_options(queued_options)
	queued["queued_options"] = queued_options
	return queued


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


func _shuffle_options(options: Array) -> void:
	for i in range(options.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = options[i]
		options[i] = options[j]
		options[j] = temp

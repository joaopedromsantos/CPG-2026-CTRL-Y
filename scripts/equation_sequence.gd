class_name EquationSequence
extends RefCounted

const DEFAULT_JSON_PATH := "res://data/equations.json"
const DEFAULT_QUEUE_SIZE := 3
const VALID_DIFFICULTIES := ["easy", "medium", "hard", "impossible"]

var _rng := RandomNumberGenerator.new()
var _source_equations: Array = []
var _difficulty_equations: Array[Dictionary] = []
var _equation_queue: Array[Dictionary] = []
var _current_equation: Dictionary = {}
var _queue_size := DEFAULT_QUEUE_SIZE
var _difficulty := "easy"


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
	if not root.has("questions") or not (root.get("questions") is Array):
		push_error("Invalid questions JSON list: %s" % path)
		return false

	_source_equations = (root["questions"] as Array).duplicate(true)
	_reset_questions(_source_equations)
	return true


func set_difficulty(difficulty: String) -> void:
	if not (difficulty in VALID_DIFFICULTIES):
		push_warning("Invalid difficulty '%s'. Falling back to easy." % difficulty)
		_difficulty = "easy"
	else:
		_difficulty = difficulty
	reset()


func reset() -> void:
	_current_equation = {}
	_equation_queue.clear()
	_reset_questions(_source_equations)
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
	if _difficulty_equations.is_empty():
		return {}

	return _difficulty_equations.pop_back()


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


func _reset_questions(equations: Array) -> void:
	_difficulty_equations.clear()

	for item in equations:
		if not (item is Dictionary):
			continue

		var equation := item as Dictionary
		if not _is_valid_question(equation):
			continue
		if String(equation.get("difficulty", "")) == _difficulty:
			_difficulty_equations.append(equation)

	_shuffle_bucket(_difficulty_equations)


func _is_valid_question(question: Dictionary) -> bool:
	if not (question.get("id", null) is float or question.get("id", null) is int):
		return false
	if not (String(question.get("difficulty", "")) in VALID_DIFFICULTIES):
		return false
	if not (question.get("topic", null) is String):
		return false
	if not (String(question.get("type", "")) in ["single_answer", "multiple_answer"]):
		return false
	if not (question.get("equation", null) is String):
		return false
	if not (question.get("correctAnswers", null) is Array):
		return false
	if not (question.get("options", null) is Array):
		return false

	var correct_answers := question.get("correctAnswers", []) as Array
	if correct_answers.is_empty():
		return false
	for answer in correct_answers:
		if not (answer is float or answer is int):
			return false

	var options := question.get("options", []) as Array
	if options.size() < 1:
		return false
	for option in options:
		if not (option is Dictionary):
			return false
		var option_dict := option as Dictionary
		if not (option_dict.get("value", null) is float or option_dict.get("value", null) is int):
			return false
		if not (option_dict.get("isCorrect", null) is bool):
			return false

	return true


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

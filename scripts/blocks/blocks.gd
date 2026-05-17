class_name RunnerBlocks
extends Node3D

signal answer_selected(is_correct: bool, selected_answer: int)

var world_speed := 8.0
var steps_per_spawn := 20
var step_distance := 1.0
var floor_back_z := -18.0
var floor_front_z := 11.6

var _lane_positions: Array[float] = []
var _distance_since_spawn := 0.0
var _block_rows: Array[Node3D] = []
var _current_options: Array = []
var _current_correct_answers: Array = []
var _highlight_correct_answers := false
var _auto_correct_rows := false
var _pending_lightning_mark := false
var _last_player_z := 0.0
var _drawer := RunnerBlockDrawer.new()
var _logic := RunnerBlockLogic.new()


func setup(lane_positions: Array[float]) -> void:
	name = "BlocosNumerados"
	_lane_positions = lane_positions
	_drawer.setup()
	reset()


func reset() -> void:
	for row in _block_rows:
		row.queue_free()

	_block_rows.clear()
	_distance_since_spawn = 0.0
	_pending_lightning_mark = false


func set_equation_options(options: Array, correct_answers: Array) -> void:
	_current_options = options.duplicate()
	_current_correct_answers = correct_answers.duplicate()


func set_equation(equation: Dictionary) -> void:
	_current_options = equation.get("queued_options", equation.get("options", [])).duplicate()
	_current_correct_answers = equation.get("correctAnswers", []).duplicate()


func get_active_row_z_positions() -> Array[float]:
	var positions: Array[float] = []
	for row in _block_rows:
		positions.append(row.position.z)
	return positions


func get_distance_to_next_spawn() -> float:
	return maxf(float(steps_per_spawn) * step_distance - _distance_since_spawn, 0.0)


func set_correct_answers_highlighted(enabled: bool) -> void:
	_highlight_correct_answers = enabled
	for row in _block_rows:
		for block in row.get_children():
			_drawer.apply_block_highlight(block as Node3D, bool(block.get_meta("answer_is_correct", false)), _highlight_correct_answers)


func set_auto_correct_rows(enabled: bool) -> void:
	_auto_correct_rows = enabled


func mark_closest_wrong_block_destroyed() -> bool:
	if _try_mark_closest_unresolved_row():
		return true
	_pending_lightning_mark = true
	return true


func tick(delta: float, player_position: Vector3) -> void:
	_last_player_z = player_position.z
	_distance_since_spawn += world_speed * delta
	if _distance_since_spawn >= float(steps_per_spawn) * step_distance:
		if _spawn_block_row():
			_distance_since_spawn = 0.0

	for row in _block_rows.duplicate():
		row.position.z += world_speed * delta
		for block in row.get_children():
			_drawer.animate_block(block as Node3D, delta)
		if row.position.z >= player_position.z and not bool(row.get_meta("resolved", false)):
			_resolve_row(row, player_position)
			continue
		if row.position.z > floor_front_z:
			_block_rows.erase(row)
			row.queue_free()


func _spawn_block_row() -> bool:
	if _current_options.is_empty() or _logic.has_unresolved_row(_block_rows):
		return false

	var row := Node3D.new()
	row.name = "LinhaBlocos"
	row.position.z = floor_back_z
	row.set_meta("resolved", false)
	row.set_meta("correct_answers", _current_correct_answers)
	add_child(row)
	_block_rows.append(row)

	var options := _logic.options_for_row(_current_options, _lane_positions.size())
	if options.size() < _lane_positions.size():
		_block_rows.erase(row)
		row.queue_free()
		return false

	for lane_index in _lane_positions.size():
		var option := options[lane_index] as Dictionary
		var option_value := int(option.get("value", 0))
		var block := _drawer.make_number_block(str(option_value))
		var is_correct := bool(option.get("isCorrect", false))
		block.set_meta("answer_value", option_value)
		block.set_meta("answer_is_correct", is_correct)
		_drawer.apply_block_highlight(block, is_correct, _highlight_correct_answers)
		block.position = Vector3(_lane_positions[lane_index], 1.2, 0.0)
		block.set_meta("base_y", block.position.y)
		row.add_child(block)

	if _pending_lightning_mark and _mark_one_wrong_block_in_row(row):
		_pending_lightning_mark = false

	return true


func _try_mark_closest_unresolved_row() -> bool:
	var target_row: Node3D = null
	var target_z := -INF
	for row in _block_rows:
		if bool(row.get_meta("resolved", false)):
			continue
		if row.position.z >= _last_player_z:
			continue
		if row.position.z > target_z:
			target_z = row.position.z
			target_row = row

	if target_row == null:
		return false

	return _mark_one_wrong_block_in_row(target_row)


func _mark_one_wrong_block_in_row(row: Node3D) -> bool:
	for block in row.get_children():
		var node := block as Node3D
		if node == null:
			continue
		if bool(node.get_meta("answer_is_correct", false)):
			continue
		if bool(node.get_meta("is_destroyed", false)):
			continue
		_drawer.apply_block_destroyed_visual(node)
		return true
	return false


func _resolve_row(row: Node3D, player_position: Vector3) -> void:
	row.set_meta("resolved", true)
	var lane_index := _logic.closest_lane_index(_lane_positions, player_position.x)
	if lane_index < 0 or lane_index >= row.get_child_count():
		return

	var block := row.get_child(lane_index)
	var selected_answer := int(block.get_meta("answer_value", 0))
	var option_is_correct := bool(block.get_meta("answer_is_correct", false))
	var correct_answers := row.get_meta("correct_answers", _current_correct_answers) as Array
	if _auto_correct_rows:
		if not correct_answers.is_empty():
			selected_answer = int(correct_answers[0])
		answer_selected.emit(true, selected_answer)
	else:
		answer_selected.emit(option_is_correct or _logic.contains_correct_answer(correct_answers, selected_answer), selected_answer)
	_block_rows.erase(row)
	row.queue_free()

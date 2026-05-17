class_name RunnerBlockLogic
extends RefCounted


func has_unresolved_row(block_rows: Array) -> bool:
	for row in block_rows:
		if not bool(row.get_meta("resolved", false)):
			return true

	return false


func options_for_row(current_options: Array, lane_count: int) -> Array:
	var options := current_options.duplicate()
	return options.slice(0, lane_count)


func contains_correct_answer(correct_answers: Array, selected_answer: int) -> bool:
	for answer in correct_answers:
		if int(answer) == selected_answer:
			return true

	return false


func closest_lane_index(lane_positions: Array[float], x_position: float) -> int:
	if lane_positions.is_empty():
		return -1

	var closest_index := 0
	var closest_distance := INF
	for lane_index in lane_positions.size():
		var distance := absf(lane_positions[lane_index] - x_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = lane_index

	return closest_index

extends GutTest


func test_options_for_row_returns_only_lane_count() -> void:
	var logic := RunnerBlockLogic.new()
	var options := [
		{"value": 1, "isCorrect": false},
		{"value": 2, "isCorrect": true},
		{"value": 3, "isCorrect": false},
		{"value": 4, "isCorrect": false},
	]

	var row_options := logic.options_for_row(options, 3)

	assert_eq(row_options.size(), 3)
	assert_eq(row_options[0]["value"], 1)
	assert_eq(row_options[2]["value"], 3)


func test_contains_correct_answer_returns_true_for_matching_int() -> void:
	var logic := RunnerBlockLogic.new()

	assert_true(logic.contains_correct_answer([2, 4, 8], 4))


func test_contains_correct_answer_returns_false_for_missing_int() -> void:
	var logic := RunnerBlockLogic.new()

	assert_false(logic.contains_correct_answer([2, 4, 8], 5))


func test_closest_lane_index_returns_expected_lane() -> void:
	var logic := RunnerBlockLogic.new()
	var lane_positions: Array[float] = [-2.8, 0.0, 2.8]

	assert_eq(logic.closest_lane_index(lane_positions, -4.0), 0)
	assert_eq(logic.closest_lane_index(lane_positions, 0.4), 1)
	assert_eq(logic.closest_lane_index(lane_positions, 9.0), 2)


func test_closest_lane_index_returns_minus_one_without_lanes() -> void:
	var logic := RunnerBlockLogic.new()
	var lane_positions: Array[float] = []

	assert_eq(logic.closest_lane_index(lane_positions, 1.0), -1)


func test_has_unresolved_row_detects_unresolved_row() -> void:
	var logic := RunnerBlockLogic.new()
	var resolved_row := Node3D.new()
	var unresolved_row := Node3D.new()
	resolved_row.set_meta("resolved", true)
	unresolved_row.set_meta("resolved", false)
	add_child_autoqfree(resolved_row)
	add_child_autoqfree(unresolved_row)

	assert_true(logic.has_unresolved_row([resolved_row, unresolved_row]))


func test_has_unresolved_row_returns_false_when_all_resolved() -> void:
	var logic := RunnerBlockLogic.new()
	var row := Node3D.new()
	row.set_meta("resolved", true)
	add_child_autoqfree(row)

	assert_false(logic.has_unresolved_row([row]))

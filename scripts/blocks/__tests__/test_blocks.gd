extends GutTest

const LANES: Array[float] = [-2.8, 0.0, 2.8]

var _blocks: RunnerBlocks


func before_each() -> void:
	_blocks = RunnerBlocks.new()
	_blocks.world_speed = 10.0
	_blocks.steps_per_spawn = 1
	_blocks.step_distance = 1.0
	_blocks.floor_back_z = -10.0
	_blocks.floor_front_z = 12.0
	add_child_autoqfree(_blocks)
	_blocks.setup(LANES)


func test_setup_starts_without_active_rows() -> void:
	assert_eq(_blocks.get_active_row_z_positions(), [])
	assert_eq(_blocks.get_distance_to_next_spawn(), 1.0)


func test_tick_spawns_row_when_options_are_available() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])

	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	assert_eq(_blocks.get_active_row_z_positions().size(), 1)
	assert_eq(_blocks.get_child_count(), 1)
	assert_eq(_blocks.get_child(0).get_child_count(), 3)


func test_tick_does_not_spawn_without_options() -> void:
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	assert_eq(_blocks.get_active_row_z_positions().size(), 0)


func test_tick_does_not_keep_row_when_options_are_insufficient() -> void:
	_blocks.set_equation_options([
		{"value": 10, "isCorrect": true},
		{"value": 20, "isCorrect": false},
	], [10])

	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))
	await wait_idle_frames(1)

	assert_eq(_blocks.get_active_row_z_positions().size(), 0)
	assert_eq(_blocks.get_child_count(), 0)


func test_tick_does_not_spawn_second_row_while_one_is_unresolved() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])

	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	assert_eq(_blocks.get_active_row_z_positions().size(), 1)


func test_correct_selection_emits_success() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	watch_signals(_blocks)

	_spawn_and_resolve(Vector3(0.0, 1.0, -9.0))

	assert_signal_emitted_with_parameters(_blocks, "answer_selected", [true, 20])
	assert_eq(_blocks.get_active_row_z_positions().size(), 0)


func test_wrong_selection_emits_failure() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	watch_signals(_blocks)

	_spawn_and_resolve(Vector3(-2.8, 1.0, -9.0))

	assert_signal_emitted_with_parameters(_blocks, "answer_selected", [false, 10])
	assert_eq(_blocks.get_active_row_z_positions().size(), 0)


func test_extreme_player_position_resolves_nearest_lane_without_error() -> void:
	_blocks.set_equation_options(_options_with_correct_value(30), [30])
	watch_signals(_blocks)

	_spawn_and_resolve(Vector3(99.0, 1.0, -9.0))

	assert_signal_emitted_with_parameters(_blocks, "answer_selected", [true, 30])


func test_auto_correct_rows_emit_first_correct_answer() -> void:
	_blocks.set_auto_correct_rows(true)
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	watch_signals(_blocks)

	_spawn_and_resolve(Vector3(-2.8, 1.0, -9.0))

	assert_signal_emitted_with_parameters(_blocks, "answer_selected", [true, 20])


func test_highlight_applies_correct_material_only_to_correct_blocks() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))
	_blocks.set_correct_answers_highlighted(true)

	var row := _blocks.get_child(0)
	var wrong_mesh := row.get_child(0).get_node("Bloco") as MeshInstance3D
	var correct_mesh := row.get_child(1).get_node("Bloco") as MeshInstance3D

	assert_ne(wrong_mesh.get_surface_override_material(0), correct_mesh.get_surface_override_material(0))


func test_reset_removes_active_rows_and_resets_spawn_distance() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	_blocks.reset()

	assert_eq(_blocks.get_active_row_z_positions(), [])
	assert_eq(_blocks.get_distance_to_next_spawn(), 1.0)


func test_mark_closest_wrong_block_destroys_one_wrong_and_keeps_correct() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	assert_true(_blocks.mark_closest_wrong_block_destroyed())

	var row := _blocks.get_child(0)
	var destroyed_count := 0
	for block in row.get_children():
		if bool((block as Node3D).get_meta("is_destroyed", false)):
			destroyed_count += 1
			assert_false(bool((block as Node3D).get_meta("answer_is_correct", false)))
	assert_eq(destroyed_count, 1)


func test_mark_closest_wrong_block_when_no_row_marks_next_spawn() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])

	assert_true(_blocks.mark_closest_wrong_block_destroyed())
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	var row := _blocks.get_child(0)
	var destroyed_count := 0
	for block in row.get_children():
		if bool((block as Node3D).get_meta("is_destroyed", false)):
			destroyed_count += 1
			assert_false(bool((block as Node3D).get_meta("answer_is_correct", false)))
	assert_eq(destroyed_count, 1)


func test_mark_closest_wrong_block_twice_marks_both_wrong_blocks() -> void:
	_blocks.set_equation_options(_options_with_correct_value(20), [20])
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))

	_blocks.mark_closest_wrong_block_destroyed()
	_blocks.mark_closest_wrong_block_destroyed()

	var row := _blocks.get_child(0)
	var destroyed_count := 0
	for block in row.get_children():
		if bool((block as Node3D).get_meta("is_destroyed", false)):
			destroyed_count += 1
	assert_eq(destroyed_count, 2)


func _spawn_and_resolve(player_position: Vector3) -> void:
	_blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))
	_blocks.tick(0.1, player_position)


func _options_with_correct_value(correct_value: int) -> Array:
	return [
		{"value": 10, "isCorrect": correct_value == 10},
		{"value": 20, "isCorrect": correct_value == 20},
		{"value": 30, "isCorrect": correct_value == 30},
	]

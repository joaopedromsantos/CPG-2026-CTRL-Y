extends GutTest

const SCENARIO_LOGIC_SCRIPT = preload("res://scripts/scenario/scenario_logic.gd")


func test_actual_row_count_covers_visible_depth() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	var rows := logic.actual_row_count(18, -18.0, 11.6, 1.4)

	assert_eq(rows, 25)


func test_actual_row_count_keeps_configured_rows_when_larger() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	var rows := logic.actual_row_count(30, -18.0, 11.6, 1.4)

	assert_eq(rows, 30)


func test_wrap_z_uses_front_plus_tile_size() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	assert_eq(logic.wrap_z(11.6, 1.4), 13.0)


func test_wrapped_z_moves_node_back_by_depth_after_front_edge() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	var next_z := logic.wrapped_z(13.2, 24, 1.4, 11.6)

	assert_almost_eq(next_z, -20.4, 0.001)


func test_wrapped_z_keeps_node_when_inside_front_edge() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	var next_z := logic.wrapped_z(12.9, 24, 1.4, 11.6)

	assert_eq(next_z, 12.9)


func test_light_pole_rotation_for_square_variant() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	assert_eq(logic.light_pole_rotation(-1, true), Vector3(0.0, 0.0, 0.0))
	assert_eq(logic.light_pole_rotation(1, true), Vector3(0.0, 180.0, 0.0))


func test_light_pole_rotation_for_curved_variant() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	assert_eq(logic.light_pole_rotation(-1, false), Vector3(0.0, -90.0, 0.0))
	assert_eq(logic.light_pole_rotation(1, false), Vector3(0.0, 90.0, 0.0))


func test_side_prop_spawn_chance_wave_is_clamped() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()

	assert_almost_eq(logic.side_prop_spawn_chance(0, 0.58), 0.70, 0.001)
	assert_almost_eq(logic.side_prop_spawn_chance(1, 0.58), 0.48, 0.001)
	assert_almost_eq(logic.side_prop_spawn_chance(2, 0.58), 0.58, 0.001)
	assert_almost_eq(logic.side_prop_spawn_chance(0, 0.80), 0.85, 0.001)
	assert_almost_eq(logic.side_prop_spawn_chance(1, 0.20), 0.25, 0.001)


func test_pick_light_pole_variant_avoids_previous_when_possible() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91277

	var first_variant := logic.pick_light_pole_variant(rng, -1, 6)
	var second_variant := logic.pick_light_pole_variant(rng, first_variant, 6)

	assert_ne(second_variant, first_variant)


func test_pick_light_pole_variant_returns_zero_with_single_variant() -> void:
	var logic := SCENARIO_LOGIC_SCRIPT.new()
	var rng := RandomNumberGenerator.new()

	assert_eq(logic.pick_light_pole_variant(rng, 0, 1), 0)

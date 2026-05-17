extends GutTest

const SCENARIO_SCRIPT = preload("res://scripts/scenario/scenario.gd")

var _scenario


func before_each() -> void:
	_scenario = SCENARIO_SCRIPT.new()
	_scenario.world_speed = 10.0
	_scenario.lane_width = 2.8
	_scenario.floor_tile_size = 1.4
	_scenario.floor_rows = 18
	_scenario.floor_cols = 9
	_scenario.floor_back_z = -18.0
	_scenario.floor_front_z = 11.6
	add_child_autoqfree(_scenario)
	_scenario.setup()


func test_setup_builds_named_scenario_root() -> void:
	assert_eq(_scenario.name, "Cenario")


func test_setup_builds_floor_tiles_for_actual_rows_and_columns() -> void:
	var floor_tiles := _children_with_mesh_height(_scenario, 0.06, -0.06)

	assert_eq(floor_tiles.size(), 225)


func test_setup_builds_side_ground_tiles_for_both_sides() -> void:
	var side_tiles := _children_with_mesh_height(_scenario, 0.06, -0.08)

	assert_eq(side_tiles.size(), 900)


func test_setup_builds_lane_markers() -> void:
	var lane_markers := _children_with_mesh_height(_scenario, 0.02)

	assert_eq(lane_markers.size(), 100)


func test_setup_builds_camera_and_lighting() -> void:
	assert_not_null(_scenario.get_node_or_null("Camera3D"))
	assert_not_null(_scenario.get_node_or_null("Sun"))
	assert_true(_scenario.get_children().any(func(child: Node) -> bool: return child is WorldEnvironment))


func test_tick_moves_floor_tiles_forward() -> void:
	var floor_tile := _children_with_mesh_height(_scenario, 0.06, -0.06)[0] as MeshInstance3D
	var start_z := floor_tile.position.z

	_scenario.tick(0.1)

	assert_almost_eq(floor_tile.position.z, start_z + 1.0, 0.001)


func test_tick_wraps_floor_tile_after_front_edge() -> void:
	var floor_tile := _children_with_mesh_height(_scenario, 0.06, -0.06)[0] as MeshInstance3D
	floor_tile.position.z = 12.9

	_scenario.tick(0.1)

	assert_almost_eq(floor_tile.position.z, -21.1, 0.001)


func test_tick_removes_light_pole_after_front_edge() -> void:
	var light_pole := _scenario.get_node_or_null("LightPole") as Node3D
	assert_not_null(light_pole)
	light_pole.position.z = 12.9

	_scenario.tick(0.1)
	await wait_idle_frames(1)

	assert_false(is_instance_valid(light_pole))


func test_tick_spawns_new_light_pole_after_interval() -> void:
	var initial_count: int = _scenario._light_poles.size()

	_scenario.tick(2.0)

	assert_eq(_scenario._light_poles.size(), initial_count + 1)


func _children_with_mesh_height(parent: Node, height: float, y_position := INF) -> Array:
	var matches := []
	for child in parent.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null:
			continue
		var box_mesh := mesh_instance.mesh as BoxMesh
		if box_mesh == null:
			continue
		if not is_equal_approx(box_mesh.size.y, height):
			continue
		if y_position != INF and not is_equal_approx(mesh_instance.position.y, y_position):
			continue
		matches.append(mesh_instance)
	return matches

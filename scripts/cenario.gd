class_name RunnerScenario
extends Node3D

var world_speed := 8.0
var lane_width := 2.8
var floor_tile_size := 1.4
var floor_rows := 18
var floor_cols := 9
var floor_back_z := -18.0
var floor_front_z := 11.6

var _floor_tiles: Array[MeshInstance3D] = []
var _lane_markers: Array[MeshInstance3D] = []
var _mat_floor_light: StandardMaterial3D
var _mat_floor_dark: StandardMaterial3D
var _mat_lane: StandardMaterial3D
var _rows_actual := 0


func setup() -> void:
	name = "Cenario"
	_build_materials()
	_build_floor()
	_build_lane_markers()
	_build_camera()
	_build_lighting()


func tick(delta: float) -> void:
	var depth := float(_rows_actual) * floor_tile_size

	for tile in _floor_tiles:
		tile.position.z += world_speed * delta
		if tile.position.z > floor_front_z:
			tile.position.z -= depth

	for marker in _lane_markers:
		marker.position.z += world_speed * delta
		if marker.position.z > floor_front_z:
			marker.position.z -= depth


func _build_materials() -> void:
	# Match the environment background for the floor so it blends with the scene
	var bg_color := Color(0.08, 0.1, 0.13)
	_mat_floor_light = _make_material(bg_color, 0.9, 0.0)
	_mat_floor_dark = _make_material(bg_color, 0.9, 0.0)
	_mat_lane = _make_material(Color(1.0, 1.0, 1.0), 0.2, 0.0)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _build_floor() -> void:
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(floor_tile_size, 0.06, floor_tile_size)

	# Compute how many rows are needed to fully cover visible area and have extra for wrapping
	var visible_depth := floor_front_z - floor_back_z + floor_tile_size
	var needed_rows := int(ceil(visible_depth / floor_tile_size))
	_rows_actual = max(floor_rows, needed_rows + 1)

	var start_x := -float(floor_cols - 1) * floor_tile_size * 0.5
	for row in range(_rows_actual):
		for col in range(floor_cols):
			var tile := MeshInstance3D.new()
			tile.mesh = floor_mesh
			tile.material_override = _mat_floor_dark
			tile.position = Vector3(
				start_x + col * floor_tile_size,
				-0.06,
				floor_back_z + row * floor_tile_size
			)
			add_child(tile)
			_floor_tiles.append(tile)


func _build_lane_markers() -> void:
	# Create segmented white strips for each lane, one segment per floor tile row
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(lane_width * 0.6, 0.02, floor_tile_size + 0.02)

	var lane_x := [-lane_width, 0.0, lane_width]
	for x in lane_x:
		for row in range(_rows_actual):
			var marker := MeshInstance3D.new()
			marker.mesh = marker_mesh
			marker.material_override = _mat_lane
			marker.position = Vector3(x, 0.01, floor_back_z + row * floor_tile_size)
			add_child(marker)
			_lane_markers.append(marker)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 6.4, 11.0)
	camera.rotation_degrees = Vector3(-56.0, 0.0, 0.0)
	camera.fov = 55.0
	camera.current = true
	add_child(camera)


func _build_lighting() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.light_energy = 2.6
	add_child(light)

	var ambient := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.1, 0.13)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.7)
	environment.ambient_light_energy = 0.65
	ambient.environment = environment
	add_child(ambient)

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
	_build_scenery()
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


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 73519

	var building_mat := StandardMaterial3D.new()
	building_mat.albedo_color = Color(0.03, 0.04, 0.07)
	building_mat.roughness = 1.0
	building_mat.metallic = 0.0

	var window_mat := StandardMaterial3D.new()
	window_mat.albedo_color = Color(1.0, 0.85, 0.45)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.85, 0.45)
	window_mat.emission_energy_multiplier = 3.0
	window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color(0.95, 0.97, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.95, 0.97, 1.0)
	star_mat.emission_energy_multiplier = 2.5
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Faixa "off road" começa após o final da estrada (largura 9 * 1.4 / 2 = 6.3)
	var road_half_width := float(floor_cols) * floor_tile_size * 0.5
	var side_offset := road_half_width + 4.0
	var scenery_depth := floor_front_z - floor_back_z
	var buildings_per_side := 9

	for side in [-1, 1]:
		for i in range(buildings_per_side):
			var width := rng.randf_range(2.0, 3.4)
			var height := rng.randf_range(3.5, 8.5)
			var depth := rng.randf_range(2.2, 3.6)
			var jitter_x := rng.randf_range(0.0, 5.0)
			var x_pos := float(side) * (side_offset + jitter_x)
			var z_pos := floor_back_z + (float(i) + 0.5) * (scenery_depth / float(buildings_per_side)) + rng.randf_range(-0.8, 0.8)

			var building := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(width, height, depth)
			building.mesh = box
			building.material_override = building_mat
			building.position = Vector3(x_pos, height * 0.5 - 0.1, z_pos)
			add_child(building)

			# Janelas iluminadas na face voltada à estrada
			var face_z := (depth * 0.5 + 0.02) * (-1.0 if side > 0 else 1.0)
			var win_cols := 2
			var win_rows := int(clamp(height / 0.9, 2, 8))
			for r in range(win_rows):
				for c in range(win_cols):
					if rng.randf() < 0.35:
						continue
					var window_node := MeshInstance3D.new()
					var win_mesh := BoxMesh.new()
					win_mesh.size = Vector3(0.25, 0.35, 0.04)
					window_node.mesh = win_mesh
					window_node.material_override = window_mat
					var win_x := (float(c) - float(win_cols - 1) * 0.5) * (width * 0.35)
					var win_y := (float(r) + 0.5) * (height / float(win_rows)) - height * 0.5
					window_node.position = Vector3(win_x, win_y, face_z)
					building.add_child(window_node)

	# Estrelas dispersas no céu ao fundo
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.08
	star_mesh.height = 0.16
	star_mesh.radial_segments = 6
	star_mesh.rings = 4
	for _i in range(60):
		var star := MeshInstance3D.new()
		star.mesh = star_mesh
		star.material_override = star_mat
		var sx := rng.randf_range(-28.0, 28.0)
		var sy := rng.randf_range(10.0, 18.0)
		var sz := rng.randf_range(floor_back_z - 12.0, floor_back_z - 4.0)
		star.position = Vector3(sx, sy, sz)
		add_child(star)


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

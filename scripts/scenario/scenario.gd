class_name RunnerScenario
extends Node3D

const SCENARIO_DRAWING_SCRIPT = preload("res://scripts/scenario/scenario_drawing.gd")
const SCENARIO_LOGIC_SCRIPT = preload("res://scripts/scenario/scenario_logic.gd")
const LIGHT_POLE_VARIANTS := [
	{
		"scene": preload("res://assets/city-kit-roads/models/light-curved.glb"),
		"is_square": false,
	},
	{
		"scene": preload("res://assets/city-kit-roads/models/light-curved-double.glb"),
		"is_square": false,
	},
	{
		"scene": preload("res://assets/city-kit-roads/models/light-curved-cross.glb"),
		"is_square": false,
	},
	{
		"scene": preload("res://assets/city-kit-roads/models/light-square.glb"),
		"is_square": true,
	},
	{
		"scene": preload("res://assets/city-kit-roads/models/light-square-double.glb"),
		"is_square": true,
	},
	{
		"scene": preload("res://assets/city-kit-roads/models/light-square-cross.glb"),
		"is_square": true,
	},
]
const LIGHT_POLE_SPAWN_INTERVAL := 2.0
const LIGHT_POLE_SCALE := 11.5
const SIDE_GROUND_COLS := 18
const MODULAR_BUILDING_GROUND_COLS := 7
const BUILDING_VARIANTS := [
	preload("res://assets/modular-buildings/models/building-sample-house-a.glb"),
	preload("res://assets/modular-buildings/models/building-sample-house-b.glb"),
	preload("res://assets/modular-buildings/models/building-sample-house-c.glb"),
	preload("res://assets/modular-buildings/models/building-sample-tower-a.glb"),
	preload("res://assets/modular-buildings/models/building-sample-tower-b.glb"),
	preload("res://assets/modular-buildings/models/building-sample-tower-c.glb"),
	preload("res://assets/modular-buildings/models/building-sample-tower-d.glb"),
]
const BUILDING_COLORMAP: Texture2D = preload("res://assets/modular-buildings/models/Textures/colormap.png")
const SIDE_PROP_VARIANTS := [
	{
		"type": "tree",
		"weight": 0.34,
	},
	{
		"type": "bench",
		"weight": 0.22,
	},
	{
		"type": "sign",
		"scene": preload("res://assets/city-kit-roads/models/sign-highway.glb"),
		"weight": 0.14,
	},
	{
		"type": "wide_sign",
		"scene": preload("res://assets/city-kit-roads/models/sign-highway-wide.glb"),
		"weight": 0.08,
	},
	{
		"type": "barrier",
		"scene": preload("res://assets/city-kit-roads/models/construction-barrier.glb"),
		"weight": 0.12,
	},
	{
		"type": "cone",
		"scene": preload("res://assets/city-kit-roads/models/construction-cone.glb"),
		"weight": 0.10,
	},
]
const SIDE_PROP_SPAWN_CHANCE := 0.58
const SIDE_PROP_MIN_PER_SIDE := 4

var world_speed := 8.0
var lane_width := 2.8
var floor_tile_size := 1.4
var floor_rows := 18
var floor_cols := 9
var floor_back_z := -18.0
var floor_front_z := 11.6

var _floor_tiles: Array[MeshInstance3D] = []
var _side_ground_tiles: Array[MeshInstance3D] = []
var _lane_markers: Array[MeshInstance3D] = []
var _light_poles: Array[Node3D] = []
var _buildings: Array[Node3D] = []
var _side_props: Array[Node3D] = []
var _mat_floor_light: StandardMaterial3D
var _mat_floor_dark: StandardMaterial3D
var _mat_side_ground: StandardMaterial3D
var _mat_lane: StandardMaterial3D
var _rows_actual := 0
var _road_half_width := 0.0
var _light_pole_rng := RandomNumberGenerator.new()
var _light_pole_spawn_timer := 0.0
var _next_light_pole_side := 1
var _last_light_pole_variant_idx := -1
var _drawing := SCENARIO_DRAWING_SCRIPT.new()
var _logic := SCENARIO_LOGIC_SCRIPT.new()


func setup() -> void:
	name = "Cenario"
	_build_materials()
	_build_floor()
	_build_lane_markers()
	_build_scenery()
	_build_camera()
	_build_lighting()


func tick(delta: float) -> void:
	for tile in _floor_tiles:
		tile.position.z += world_speed * delta
		tile.position.z = _logic.wrapped_z(tile.position.z, _rows_actual, floor_tile_size, floor_front_z)

	for tile in _side_ground_tiles:
		tile.position.z += world_speed * delta
		tile.position.z = _logic.wrapped_z(tile.position.z, _rows_actual, floor_tile_size, floor_front_z)

	for marker in _lane_markers:
		marker.position.z += world_speed * delta
		marker.position.z = _logic.wrapped_z(marker.position.z, _rows_actual, floor_tile_size, floor_front_z)

	for building in _buildings:
		building.position.z += world_speed * delta
		building.position.z = _logic.wrapped_z(building.position.z, _rows_actual, floor_tile_size, floor_front_z)

	for i in range(_light_poles.size() - 1, -1, -1):
		var pole := _light_poles[i]
		pole.position.z += world_speed * delta
		if pole.position.z > _logic.wrap_z(floor_front_z, floor_tile_size):
			_light_poles.remove_at(i)
			pole.queue_free()

	_update_light_pole_spawner(delta)

	for prop in _side_props:
		prop.position.z += world_speed * delta
		prop.position.z = _logic.wrapped_z(prop.position.z, _rows_actual, floor_tile_size, floor_front_z)


func _build_materials() -> void:
	_drawing.setup_materials()
	_mat_floor_light = _drawing.mat_floor_light
	_mat_floor_dark = _drawing.mat_floor_dark
	_mat_side_ground = _drawing.mat_side_ground
	_mat_lane = _drawing.mat_lane


func _build_floor() -> void:
	var floor_mesh := _drawing.make_floor_mesh(floor_tile_size)

	# Compute how many rows are needed to fully cover visible area and have extra for wrapping
	_rows_actual = _logic.actual_row_count(floor_rows, floor_back_z, floor_front_z, floor_tile_size)

	var start_x := -float(floor_cols - 1) * floor_tile_size * 0.5
	for row in range(_rows_actual):
		for col in range(floor_cols):
			var is_shoulder := col == 0 or col == floor_cols - 1
			var tile := MeshInstance3D.new()
			tile.mesh = floor_mesh
			tile.material_override = _mat_floor_light if is_shoulder else _mat_floor_dark
			tile.position = Vector3(
				start_x + col * floor_tile_size,
				-0.06,
				floor_back_z + row * floor_tile_size
			)
			add_child(tile)
			_floor_tiles.append(tile)

	var road_half_width := float(floor_cols) * floor_tile_size * 0.5
	for side in [-1, 1]:
		for row in range(_rows_actual):
			for col in range(SIDE_GROUND_COLS):
				var tile := MeshInstance3D.new()
				tile.mesh = floor_mesh
				tile.material_override = _mat_side_ground
				tile.position = Vector3(
					float(side) * (road_half_width + floor_tile_size * (float(col) + 0.5)),
					-0.08,
					floor_back_z + row * floor_tile_size
				)
				add_child(tile)
				_side_ground_tiles.append(tile)


func _build_lane_markers() -> void:
	# Faixas tracejadas entre as pistas (divisores) e sólidas nas bordas da rua
	var dash_mesh := _drawing.make_dash_mesh(floor_tile_size)

	var divider_xs := [-lane_width * 0.5, lane_width * 0.5]
	for x in divider_xs:
		for row in range(_rows_actual):
			var marker := MeshInstance3D.new()
			marker.mesh = dash_mesh
			marker.material_override = _mat_lane
			marker.position = Vector3(x, 0.01, floor_back_z + row * floor_tile_size)
			add_child(marker)
			_lane_markers.append(marker)

	var edge_mesh := _drawing.make_edge_mesh(floor_tile_size)

	var edge_xs := [-lane_width * 1.5, lane_width * 1.5]
	for x in edge_xs:
		for row in range(_rows_actual):
			var marker := MeshInstance3D.new()
			marker.mesh = edge_mesh
			marker.material_override = _mat_lane
			marker.position = Vector3(x, 0.01, floor_back_z + row * floor_tile_size)
			add_child(marker)
			_lane_markers.append(marker)


func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 73519

	var star_mat := _drawing.make_star_material()

	# Faixa "off road" começa após o final da estrada (largura 9 * 1.4 / 2 = 6.3)
	_road_half_width = float(floor_cols) * floor_tile_size * 0.5
	var side_offset := _road_half_width + floor_tile_size * float(MODULAR_BUILDING_GROUND_COLS) - 3.2
	var scenery_depth := floor_front_z - floor_back_z
	var buildings_per_side := 9

	for side in [-1, 1]:
		for i in range(buildings_per_side):
			var jitter_x := rng.randf_range(0.0, 2.0)
			var x_pos := float(side) * (side_offset + jitter_x)
			var z_pos := floor_back_z + (float(i) + 0.5) * (scenery_depth / float(buildings_per_side)) + rng.randf_range(-0.8, 0.8)
			var building := _create_modular_building(side, rng)
			building.position = Vector3(x_pos, 0.0, z_pos)
			add_child(building)
			_buildings.append(building)

	# Estrelas dispersas no céu ao fundo
	var star_mesh := _drawing.make_star_mesh()
	for _i in range(60):
		var star := MeshInstance3D.new()
		star.mesh = star_mesh
		star.material_override = star_mat
		var sx := rng.randf_range(-28.0, 28.0)
		var sy := rng.randf_range(10.0, 18.0)
		var sz := rng.randf_range(floor_back_z - 12.0, floor_back_z - 4.0)
		star.position = Vector3(sx, sy, sz)
		add_child(star)

	_build_pixel_skyline()
	_setup_light_pole_spawner()
	_build_side_props(_road_half_width, scenery_depth)


func _build_pixel_skyline() -> void:
	var building_mat := StandardMaterial3D.new()
	building_mat.albedo_color = Color(0.025, 0.03, 0.04)
	building_mat.roughness = 1.0

	var side_mat := StandardMaterial3D.new()
	side_mat.albedo_color = Color(0.09, 0.10, 0.13)
	side_mat.roughness = 1.0

	var window_mat := StandardMaterial3D.new()
	window_mat.albedo_color = Color(1.0, 0.95, 0.42)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.92, 0.30)
	window_mat.emission_energy_multiplier = 1.6
	window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var side_specs := [
		Vector4(-31.0, -16.6, 4.2, 8.8),
		Vector4(-28.0, -16.2, 3.6, 7.8),
		Vector4(-24.4, -15.9, 3.4, 7.2),
		Vector4(-20.6, -15.6, 2.8, 7.4),
		Vector4(-18.4, -15.0, 2.1, 5.8),
		Vector4(-16.6, -14.7, 2.6, 6.4),
		Vector4(-14.8, -14.5, 2.2, 6.8),
		Vector4(-30.0, -13.6, 3.8, 7.6),
		Vector4(-26.1, -13.3, 3.0, 6.2),
		Vector4(-19.4, -12.8, 2.2, 5.2),
		Vector4(-17.2, -12.3, 2.5, 7.0),
		Vector4(-14.8, -11.8, 1.8, 5.2),
		Vector4(-31.2, -10.9, 4.0, 8.2),
		Vector4(-27.0, -10.5, 3.2, 6.8),
		Vector4(-23.2, -10.3, 2.8, 6.0),
		Vector4(-19.8, -10.1, 2.8, 7.8),
		Vector4(-17.4, -9.6, 2.0, 5.6),
		Vector4(-14.8, -9.1, 2.4, 7.7),
		Vector4(-30.4, -7.8, 3.6, 7.0),
		Vector4(-26.4, -7.6, 3.0, 6.4),
		Vector4(-22.6, -7.4, 2.6, 5.8),
		Vector4(-18.8, -7.2, 2.6, 6.7),
		Vector4(-16.6, -6.8, 2.2, 5.8),
		Vector4(-14.8, -6.2, 2.0, 4.9),
		Vector4(-31.0, -5.2, 4.4, 8.4),
		Vector4(-27.0, -4.9, 3.4, 7.0),
		Vector4(-23.2, -4.6, 2.8, 5.8),
		Vector4(-19.2, -4.4, 2.4, 6.0),
		Vector4(-17.0, -4.0, 2.8, 7.2),
		Vector4(-14.8, -3.4, 2.2, 6.1),
		Vector4(14.8, -14.5, 2.2, 6.8),
		Vector4(16.6, -14.7, 2.6, 6.4),
		Vector4(18.4, -15.0, 2.1, 5.8),
		Vector4(20.6, -15.6, 2.8, 7.4),
		Vector4(24.4, -15.9, 3.4, 7.2),
		Vector4(28.0, -16.2, 3.6, 7.8),
		Vector4(31.0, -16.6, 4.2, 8.8),
		Vector4(14.8, -14.7, 2.2, 6.8),
		Vector4(16.6, -15.0, 2.6, 6.4),
		Vector4(18.4, -15.3, 2.1, 5.8),
		Vector4(20.6, -15.8, 2.8, 7.4),
		Vector4(14.8, -14.5, 2.2, 6.8),
		Vector4(14.8, -12.0, 1.8, 5.2),
		Vector4(17.2, -12.6, 2.5, 7.0),
		Vector4(19.4, -13.0, 2.2, 5.2),
		Vector4(26.1, -13.3, 3.0, 6.2),
		Vector4(30.0, -13.6, 3.8, 7.6),
		Vector4(14.8, -11.8, 1.8, 5.2),
		Vector4(14.8, -9.4, 2.4, 7.7),
		Vector4(17.4, -9.8, 2.0, 5.6),
		Vector4(19.8, -10.3, 2.8, 7.8),
		Vector4(23.2, -10.3, 2.8, 6.0),
		Vector4(27.0, -10.5, 3.2, 6.8),
		Vector4(31.2, -10.9, 4.0, 8.2),
		Vector4(14.8, -9.1, 2.4, 7.7),
		Vector4(14.8, -6.4, 2.0, 4.9),
		Vector4(16.6, -7.0, 2.2, 5.8),
		Vector4(18.8, -7.4, 2.6, 6.7),
		Vector4(22.6, -7.4, 2.6, 5.8),
		Vector4(26.4, -7.6, 3.0, 6.4),
		Vector4(30.4, -7.8, 3.6, 7.0),
		Vector4(14.8, -6.2, 2.0, 4.9),
		Vector4(14.8, -3.6, 2.2, 6.1),
		Vector4(17.0, -4.2, 2.8, 7.2),
		Vector4(19.2, -4.6, 2.4, 6.0),
		Vector4(23.2, -4.6, 2.8, 5.8),
		Vector4(27.0, -4.9, 3.4, 7.0),
		Vector4(31.0, -5.2, 4.4, 8.4),
		Vector4(14.8, -3.4, 2.2, 6.1),
	]

	for spec in side_specs:
		var typed_spec := spec as Vector4
		var node := _drawing.create_pixel_building(typed_spec.z, typed_spec.w, building_mat, side_mat, window_mat)
		node.position = Vector3(typed_spec.x, 0.0, typed_spec.y)
		node.rotation_degrees.y = -90.0 if typed_spec.x < 0.0 else 90.0
		add_child(node)


func _setup_light_pole_spawner() -> void:
	_light_pole_rng.seed = 91277
	_light_pole_spawn_timer = 0.0
	_next_light_pole_side = 1
	_last_light_pole_variant_idx = -1
	_spawn_light_pole(_next_light_pole_side)
	_next_light_pole_side *= -1


func _update_light_pole_spawner(delta: float) -> void:
	_light_pole_spawn_timer += delta
	while _light_pole_spawn_timer >= LIGHT_POLE_SPAWN_INTERVAL:
		_light_pole_spawn_timer -= LIGHT_POLE_SPAWN_INTERVAL
		_spawn_light_pole(_next_light_pole_side)
		_next_light_pole_side *= -1


func _spawn_light_pole(side: int) -> void:
	var pole_x := _road_half_width + 1.05
	var spawn_z := floor_back_z + floor_tile_size * 0.6
	var variant_idx := _logic.pick_light_pole_variant(_light_pole_rng, _last_light_pole_variant_idx, LIGHT_POLE_VARIANTS.size())
	_last_light_pole_variant_idx = variant_idx
	var variant: Dictionary = LIGHT_POLE_VARIANTS[variant_idx]
	var scene := variant["scene"] as PackedScene
	var pole := scene.instantiate() as Node3D
	pole.name = "LightPole"
	pole.position = Vector3(float(side) * pole_x, 0.0, spawn_z)
	pole.rotation_degrees = _logic.light_pole_rotation(side, variant["is_square"] as bool)
	pole.scale = Vector3.ONE * LIGHT_POLE_SCALE
	add_child(pole)
	_light_poles.append(pole)


func _create_modular_building(side: int, rng: RandomNumberGenerator) -> Node3D:
	var scene := BUILDING_VARIANTS[rng.randi_range(0, BUILDING_VARIANTS.size() - 1)] as PackedScene
	var building := scene.instantiate() as Node3D
	building.name = "ModularBuilding"
	building.rotation_degrees.y = -90.0 if side < 0 else 90.0
	building.rotation_degrees.y += rng.randf_range(-7.0, 7.0)
	building.scale = Vector3.ONE * rng.randf_range(1.25, 1.85)
	_apply_building_colormap(building)
	return building


func _apply_building_colormap(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_texture = BUILDING_COLORMAP
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.roughness = 0.9
		material.metallic = 0.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if mesh_instance.mesh != null:
			for surface_idx in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(surface_idx, material)

	for child in node.get_children():
		_apply_building_colormap(child)


func _build_side_props(road_half_width: float, scenery_depth: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 48261
	var slots_per_side := 12
	var first_z := floor_back_z + floor_tile_size * 0.35
	var z_step := scenery_depth / float(slots_per_side)

	for side in [-1, 1]:
		var spawned_on_side := 0
		for i in range(slots_per_side):
			var remaining_slots := slots_per_side - i
			var remaining_required := SIDE_PROP_MIN_PER_SIDE - spawned_on_side
			var should_spawn := remaining_required >= remaining_slots or rng.randf() <= _logic.side_prop_spawn_chance(i, SIDE_PROP_SPAWN_CHANCE)
			if not should_spawn:
				continue

			var variant := _pick_side_prop_variant(rng)
			var prop := _create_side_prop(variant, side, rng)
			var x_offset := rng.randf_range(1.5, 4.6)
			var z_jitter := rng.randf_range(-0.55, 0.55)
			prop.position = Vector3(
				float(side) * (road_half_width + x_offset),
				0.0,
				first_z + float(i) * z_step + z_jitter
			)
			prop.rotation_degrees.y += rng.randf_range(-10.0, 10.0)
			add_child(prop)
			_side_props.append(prop)
			spawned_on_side += 1


func _pick_side_prop_variant(rng: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0.0
	for variant in SIDE_PROP_VARIANTS:
		var entry := variant as Dictionary
		total_weight += entry["weight"] as float

	var target := rng.randf() * total_weight
	var accumulated := 0.0
	for variant in SIDE_PROP_VARIANTS:
		var entry := variant as Dictionary
		accumulated += entry["weight"] as float
		if target <= accumulated:
			return entry

	return SIDE_PROP_VARIANTS[0] as Dictionary


func _create_side_prop(variant: Dictionary, side: int, rng: RandomNumberGenerator) -> Node3D:
	var prop_type := variant["type"] as String
	match prop_type:
		"tree":
			return _drawing.create_tree_prop(rng)
		"bench":
			return _drawing.create_bench_prop(side, rng)
		_:
			return _create_model_prop(variant, side, rng)


func _create_model_prop(variant: Dictionary, side: int, rng: RandomNumberGenerator) -> Node3D:
	var scene := variant["scene"] as PackedScene
	var prop := scene.instantiate() as Node3D
	prop.name = "SideProp"
	prop.rotation_degrees.y = -90.0 if side < 0 else 90.0

	var prop_type := variant["type"] as String
	match prop_type:
		"barrier":
			prop.scale = Vector3.ONE * rng.randf_range(0.9, 1.15)
		"cone":
			prop.scale = Vector3.ONE * rng.randf_range(0.75, 1.05)
		_:
			prop.scale = Vector3.ONE * rng.randf_range(1.0, 1.35)

	return prop


func _build_camera() -> void:
	add_child(_drawing.create_camera())


func _build_lighting() -> void:
	add_child(_drawing.create_sun())
	add_child(_drawing.create_world_environment())

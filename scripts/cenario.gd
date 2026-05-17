class_name RunnerScenario
extends Node3D

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
var _mat_tree_trunk: StandardMaterial3D
var _mat_tree_leaf: StandardMaterial3D
var _mat_bench_wood: StandardMaterial3D
var _mat_bench_metal: StandardMaterial3D
var _rows_actual := 0
var _road_half_width := 0.0
var _light_pole_rng := RandomNumberGenerator.new()
var _light_pole_spawn_timer := 0.0
var _next_light_pole_side := 1
var _last_light_pole_variant_idx := -1


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
	# Só dá wrap quando o tile sai inteiro do campo de visão, não no centro,
	# senão a borda da frente pisca ao reciclar.
	var wrap_z := floor_front_z + floor_tile_size

	for tile in _floor_tiles:
		tile.position.z += world_speed * delta
		if tile.position.z > wrap_z:
			tile.position.z -= depth

	for tile in _side_ground_tiles:
		tile.position.z += world_speed * delta
		if tile.position.z > wrap_z:
			tile.position.z -= depth

	for marker in _lane_markers:
		marker.position.z += world_speed * delta
		if marker.position.z > wrap_z:
			marker.position.z -= depth

	for building in _buildings:
		building.position.z += world_speed * delta
		if building.position.z > wrap_z:
			building.position.z -= depth

	for i in range(_light_poles.size() - 1, -1, -1):
		var pole := _light_poles[i]
		pole.position.z += world_speed * delta
		if pole.position.z > wrap_z:
			_light_poles.remove_at(i)
			pole.queue_free()

	_update_light_pole_spawner(delta)

	for prop in _side_props:
		prop.position.z += world_speed * delta
		if prop.position.z > wrap_z:
			prop.position.z -= depth


func _build_materials() -> void:
	var asphalt_color := Color(0.05, 0.06, 0.08)
	var sidewalk_color := Color(0.11, 0.12, 0.14)
	_mat_floor_light = _make_material(sidewalk_color, 1.0, 0.0)
	_mat_floor_dark = _make_material(asphalt_color, 0.95, 0.0)
	_mat_side_ground = _make_material(Color(0.07, 0.12, 0.08), 1.0, 0.0)
	_mat_lane = _make_material(Color(0.96, 0.93, 0.78), 0.35, 0.0)
	_mat_lane.emission_enabled = true
	_mat_lane.emission = Color(0.96, 0.93, 0.78)
	_mat_lane.emission_energy_multiplier = 0.5
	_mat_tree_trunk = _make_material(Color(0.34, 0.18, 0.08), 0.9, 0.0)
	_mat_tree_leaf = _make_material(Color(0.08, 0.34, 0.16), 0.95, 0.0)
	_mat_bench_wood = _make_material(Color(0.48, 0.25, 0.11), 0.85, 0.0)
	_mat_bench_metal = _make_material(Color(0.16, 0.17, 0.18), 0.65, 0.1)


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
	var visible_depth := floor_front_z - floor_back_z + floor_tile_size * 2.0
	var needed_rows := int(ceil(visible_depth / floor_tile_size))
	_rows_actual = max(floor_rows, needed_rows + 1)

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
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.18, 0.02, floor_tile_size * 0.55)

	var divider_xs := [-lane_width * 0.5, lane_width * 0.5]
	for x in divider_xs:
		for row in range(_rows_actual):
			var marker := MeshInstance3D.new()
			marker.mesh = dash_mesh
			marker.material_override = _mat_lane
			marker.position = Vector3(x, 0.01, floor_back_z + row * floor_tile_size)
			add_child(marker)
			_lane_markers.append(marker)

	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.22, 0.02, floor_tile_size + 0.02)

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

	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color(0.95, 0.97, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.95, 0.97, 1.0)
	star_mat.emission_energy_multiplier = 2.5
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

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
		var node := _create_pixel_building(typed_spec.z, typed_spec.w, building_mat, side_mat, window_mat)
		node.position = Vector3(typed_spec.x, 0.0, typed_spec.y)
		node.rotation_degrees.y = -90.0 if typed_spec.x < 0.0 else 90.0
		add_child(node)


func _create_pixel_building(
	width: float,
	height: float,
	building_mat: StandardMaterial3D,
	side_mat: StandardMaterial3D,
	window_mat: StandardMaterial3D
) -> Node3D:
	var root := Node3D.new()
	root.name = "PixelSkylineBuilding"

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(width, height, 1.0)
	body.mesh = body_mesh
	body.material_override = building_mat
	body.position.y = height * 0.5
	root.add_child(body)

	var side := MeshInstance3D.new()
	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(0.28, height, 1.04)
	side.mesh = side_mesh
	side.material_override = side_mat
	side.position = Vector3(width * 0.5 + 0.14, height * 0.5, 0.0)
	root.add_child(side)

	var cols := maxi(1, int(width / 0.55))
	var rows := maxi(2, int(height / 0.9))
	for row in range(rows):
		for col in range(cols):
			if (row + col) % 3 == 0:
				continue
			var window := MeshInstance3D.new()
			var window_mesh := BoxMesh.new()
			window_mesh.size = Vector3(0.18, 0.28, 0.04)
			window.mesh = window_mesh
			window.material_override = window_mat
			window.position = Vector3(
				(float(col) - float(cols - 1) * 0.5) * 0.46,
				0.8 + float(row) * 0.68,
				-0.53
			)
			root.add_child(window)

	return root


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
	var variant_idx := _pick_light_pole_variant(_light_pole_rng, _last_light_pole_variant_idx)
	_last_light_pole_variant_idx = variant_idx
	var variant: Dictionary = LIGHT_POLE_VARIANTS[variant_idx]
	var scene := variant["scene"] as PackedScene
	var pole := scene.instantiate() as Node3D
	pole.name = "LightPole"
	pole.position = Vector3(float(side) * pole_x, 0.0, spawn_z)
	pole.rotation_degrees = _get_light_pole_rotation(side, variant["is_square"] as bool)
	pole.scale = Vector3.ONE * LIGHT_POLE_SCALE
	add_child(pole)
	_light_poles.append(pole)


func _pick_light_pole_variant(rng: RandomNumberGenerator, previous_variant_idx: int) -> int:
	var variant_count := LIGHT_POLE_VARIANTS.size()
	if variant_count <= 1:
		return 0

	var variant_idx := rng.randi_range(0, variant_count - 1)
	if variant_idx == previous_variant_idx:
		variant_idx = (variant_idx + rng.randi_range(1, variant_count - 1)) % variant_count

	return variant_idx


func _get_light_pole_rotation(side: int, is_square: bool) -> Vector3:
	if is_square:
		return Vector3(0.0, 0.0 if side < 0 else 180.0, 0.0)

	return Vector3(0.0, -90.0 if side < 0 else 90.0, 0.0)


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
			var should_spawn := remaining_required >= remaining_slots or rng.randf() <= _get_side_prop_spawn_chance(i)
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


func _get_side_prop_spawn_chance(slot_idx: int) -> float:
	var wave := 0.12 if slot_idx % 3 == 0 else (-0.10 if slot_idx % 3 == 1 else 0.0)
	return clampf(SIDE_PROP_SPAWN_CHANCE + wave, 0.25, 0.85)


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
			return _create_tree_prop(rng)
		"bench":
			return _create_bench_prop(side, rng)
		_:
			return _create_model_prop(variant, side, rng)


func _create_tree_prop(rng: RandomNumberGenerator) -> Node3D:
	var tree := Node3D.new()
	tree.name = "SideTree"

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.13
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = rng.randf_range(1.0, 1.45)
	trunk_mesh.radial_segments = 8
	trunk.mesh = trunk_mesh
	trunk.material_override = _mat_tree_trunk
	trunk.position.y = trunk_mesh.height * 0.5
	tree.add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = rng.randf_range(0.65, 0.9)
	leaf_mesh.height = leaf_mesh.radius * rng.randf_range(1.55, 1.9)
	leaf_mesh.radial_segments = 10
	leaf_mesh.rings = 5
	leaves.mesh = leaf_mesh
	leaves.material_override = _mat_tree_leaf
	leaves.position = Vector3(0.0, trunk_mesh.height + leaf_mesh.height * 0.32, 0.0)
	tree.add_child(leaves)

	tree.scale = Vector3.ONE * rng.randf_range(1.6, 2.2)
	return tree


func _create_bench_prop(side: int, rng: RandomNumberGenerator) -> Node3D:
	var bench := Node3D.new()
	bench.name = "SideBench"
	bench.rotation_degrees.y = 90.0 if side < 0 else -90.0

	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(1.25, 0.16, 0.42)
	seat.mesh = seat_mesh
	seat.material_override = _mat_bench_wood
	seat.position.y = 0.45
	bench.add_child(seat)

	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(1.25, 0.48, 0.12)
	back.mesh = back_mesh
	back.material_override = _mat_bench_wood
	back.position = Vector3(0.0, 0.72, -0.24)
	bench.add_child(back)

	for leg_x in [-0.48, 0.48]:
		for leg_z in [-0.13, 0.13]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.08, 0.45, 0.08)
			leg.mesh = leg_mesh
			leg.material_override = _mat_bench_metal
			leg.position = Vector3(leg_x, 0.22, leg_z)
			bench.add_child(leg)

	bench.scale = Vector3.ONE * rng.randf_range(1.35, 1.7)
	return bench


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

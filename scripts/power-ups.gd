class_name RunnerPowerUps
extends Node3D

const ASSET_DIR := "res://assets/power-ups/"

const FALLBACK_ASSETS := [
	"res://assets/power-ups/magnifying_glass.glb",
	"res://assets/power-ups/cutscene_model.glb",
	"res://assets/power-ups/heart_emoji.glb",
	"res://assets/power-ups/Lightning Bolt.glb",
	"res://assets/power-ups/transparent_glass_hourglass.glb",
]

# Per-asset uniform scale to normalize visual size across power-ups.
const ASSET_SCALES := {
	"res://assets/power-ups/magnifying_glass.glb": 0.5,
	"res://assets/power-ups/cutscene_model.glb": 0.8,
	"res://assets/power-ups/heart_emoji.glb": 0.005,
	"res://assets/power-ups/Lightning Bolt.glb": 1.6,
	"res://assets/power-ups/transparent_glass_hourglass.glb": 0.03,
}
const DEFAULT_SCALE := 0.1

var world_speed := 8.0
var floor_back_z := -18.0
var floor_front_z := 11.6
var spawn_interval := 4.0
var spawn_chance := 0.5

# Floating animation
var float_amplitude := 0.28
var float_speed := 3.6
var float_rotation_speed := 48.0

var _asset_paths: Array[String] = []
var _powerups: Array = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _lane_positions: Array = []

func setup(lane_positions: Array) -> void:
	name = "PowerUps"
	_lane_positions = lane_positions
	_rng.randomize()
	_collect_assets()

func reset() -> void:
	for _item in _powerups:
		var p := _item as Node3D
		if p:
			p.queue_free()
	_powerups.clear()
	_time = 0.0

func tick(delta: float, player_pos: Vector3) -> void:
	_time += delta
	if _time >= spawn_interval:
		_time = 0.0
		_try_spawn_row()

	for _item in _powerups.duplicate():
		var p := _item as Node3D
		if not p:
			continue

		p.position.z += world_speed * delta

		var phase: float = p.get_meta("float_phase", 0.0)
		phase += float_speed * delta
		p.set_meta("float_phase", phase)
		var base_y: float = p.get_meta("base_y", 0.5)
		p.position.y = base_y + sin(phase) * float_amplitude

		var rs_x: float = p.get_meta("rot_speed_x", float_rotation_speed)
		var rs_y: float = p.get_meta("rot_speed_y", float_rotation_speed)
		var rs_z: float = p.get_meta("rot_speed_z", float_rotation_speed)
		var rd_x: float = p.get_meta("rot_dir_x", 1.0)
		var rd_y: float = p.get_meta("rot_dir_y", 1.0)
		var rd_z: float = p.get_meta("rot_dir_z", 1.0)
		p.rotation_degrees.x += rs_x * delta * rd_x
		p.rotation_degrees.y += rs_y * delta * rd_y
		p.rotation_degrees.z += rs_z * delta * rd_z

		if player_pos.distance_to(p.position) < 1.2:
			_powerups.erase(_item)
			p.queue_free()
			continue

		if p.position.z > floor_front_z:
			_powerups.erase(_item)
			p.queue_free()

func _collect_assets() -> void:
	_asset_paths.clear()
	var dir := DirAccess.open(ASSET_DIR)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.to_lower().ends_with(".glb"):
				_asset_paths.append(ASSET_DIR + fname)
			fname = dir.get_next()
		dir.list_dir_end()

	# Exported builds may not list res:// directories — fall back to the known list.
	if _asset_paths.is_empty():
		for path in FALLBACK_ASSETS:
			if ResourceLoader.exists(path):
				_asset_paths.append(path)

func _try_spawn_row() -> void:
	if _rng.randf() > spawn_chance:
		return

	for existing in _powerups:
		if absf(existing.position.z - floor_back_z) < 1.0:
			return

	if _lane_positions.size() == 0 or _asset_paths.size() == 0:
		return

	var lane_index := _rng.randi_range(0, _lane_positions.size() - 1)
	var p := _make_powerup() as Node3D
	if not p:
		return
	p.position = Vector3(_lane_positions[lane_index], 0.5, floor_back_z)
	add_child(p)
	_powerups.append(p)

func _make_powerup() -> Node3D:
	var idx := _rng.randi_range(0, _asset_paths.size() - 1)
	var path: String = _asset_paths[idx]
	var res := ResourceLoader.load(path)
	if res and res is PackedScene:
		var inst := (res as PackedScene).instantiate()
		if inst and inst is Node3D:
			var node := inst as Node3D
			node.name = "PowerUp"
			var s: float = ASSET_SCALES.get(path, DEFAULT_SCALE)
			node.scale = Vector3.ONE * s
			_init_powerup_meta(node)
			return node

	# fallback simple sphere if asset failed to load
	var root := Node3D.new()
	root.name = "PowerUp"
	var mesh_i := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.25
	sph.radial_segments = 12
	sph.rings = 6
	mesh_i.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.7, 0.3)
	mesh_i.material_override = mat
	root.add_child(mesh_i)
	_init_powerup_meta(root)
	return root

func _init_powerup_meta(node: Node3D) -> void:
	node.set_meta("float_phase", _rng.randf() * TAU)
	node.set_meta("base_y", 0.5)
	var dir_x := 1.0 if _rng.randi_range(0, 1) == 1 else -1.0
	var dir_y := 1.0 if _rng.randi_range(0, 1) == 1 else -1.0
	var dir_z := 1.0 if _rng.randi_range(0, 1) == 1 else -1.0
	node.set_meta("rot_dir_x", dir_x)
	node.set_meta("rot_dir_y", dir_y)
	node.set_meta("rot_dir_z", dir_z)
	node.set_meta("rot_speed_x", float_rotation_speed * _rng.randf_range(0.8, 1.3))
	node.set_meta("rot_speed_y", float_rotation_speed * _rng.randf_range(0.8, 1.3))
	node.set_meta("rot_speed_z", float_rotation_speed * _rng.randf_range(0.8, 1.3))

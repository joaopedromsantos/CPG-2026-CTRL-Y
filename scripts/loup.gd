class_name RunnerLoup
extends Node3D

var world_speed := 8.0
var floor_back_z := -18.0
var floor_front_z := 11.6
var spawn_interval := 4.0 # seconds between spawn attempts (increased = less frequent)
var spawn_chance := 0.45 # overall chance to spawn one lupa when interval elapses

# Floating animation parameters
var float_amplitude := 0.28
var float_speed := 4.2
var float_rotation_speed := 52.0 # degrees per second (increased rotation intensity)
var _lane_positions = []
var _loupes = []
var _rng = RandomNumberGenerator.new()
var _time = 0.0

func setup(lane_positions):
	name = "Loupes"
	_lane_positions = lane_positions
	_rng.randomize()

func reset():
	for _item in _loupes:
		var l = _item as Node3D
		if l:
			l.queue_free()
	_loupes.clear()
	_time = 0.0

func tick(delta, player_pos):
	_time += delta
	if _time >= spawn_interval:
		_time = 0.0
		_try_spawn_row()

	for _item in _loupes.duplicate():
		var l = _item as Node3D
		if not l:
			continue

		# move forward
		l.position.z += world_speed * delta

		# floating animation (update phase and vertical bob)
		var phase = 0.0
		if l.has_meta("float_phase"):
			phase = l.get_meta("float_phase")
		phase += float_speed * delta
		l.set_meta("float_phase", phase)
		var base_y = 0.5
		if l.has_meta("base_y"):
			base_y = l.get_meta("base_y")
		l.position.y = base_y + sin(phase) * float_amplitude

		# gentle rotation on all axes (per-lupa speeds and directions stored in meta)
		var rs_x = float_rotation_speed
		var rs_y = float_rotation_speed
		var rs_z = float_rotation_speed
		var rd_x = 1.0
		var rd_y = 1.0
		var rd_z = 1.0
		if l.has_meta("rot_speed_x"):
			rs_x = l.get_meta("rot_speed_x")
		if l.has_meta("rot_speed_y"):
			rs_y = l.get_meta("rot_speed_y")
		if l.has_meta("rot_speed_z"):
			rs_z = l.get_meta("rot_speed_z")
		if l.has_meta("rot_dir_x"):
			rd_x = l.get_meta("rot_dir_x")
		if l.has_meta("rot_dir_y"):
			rd_y = l.get_meta("rot_dir_y")
		if l.has_meta("rot_dir_z"):
			rd_z = l.get_meta("rot_dir_z")
		l.rotation_degrees.x += rs_x * delta * rd_x
		l.rotation_degrees.y += rs_y * delta * rd_y
		l.rotation_degrees.z += rs_z * delta * rd_z

		# collision: simple distance check to player
		if player_pos.distance_to(l.position) < 1.2:
			_loupes.erase(_item)
			l.queue_free()
			continue

		if l.position.z > floor_front_z:
			_loupes.erase(_item)
			l.queue_free()

func _try_spawn_row():
	# At each interval, spawn at most one lupa (prevents two together)
	if _rng.randf() > spawn_chance:
		return

	# don't spawn if there is already a lupa very near the spawn line
	for existing in _loupes:
		if absf(existing.position.z - floor_back_z) < 1.0:
			return

	if _lane_positions.size() == 0:
		return

	var lane_index = _rng.randi_range(0, _lane_positions.size() - 1)
	var l = _make_lupa() as Node3D
	if not l:
		return
	l.position = Vector3(_lane_positions[lane_index], 0.5, floor_back_z)
	add_child(l)
	_loupes.append(l)

func _make_lupa():
	# Prefer instancing the scene asset if it exists for exact design
	var scene_path = "res://scenes/lupa.tscn"
	if ResourceLoader.exists(scene_path):
		var res = ResourceLoader.load(scene_path)
		if res and res is PackedScene:
			var packed_scene = res
			var inst = packed_scene.instantiate()
			if inst and inst is Node3D:
				return inst

	var root := Node3D.new()
	root.name = "Lupa"

	# Lens
	var lens := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.3
	sph.radial_segments = 16
	sph.rings = 8
	lens.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 1.0)
	mat.metallic = 0.0
	mat.roughness = 0.3
	lens.material_override = mat
	lens.position = Vector3(0, 0.2, 0)
	root.add_child(lens)

	# Handle
	var handle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 0.6
	cyl.radial_segments = 8
	handle.mesh = cyl
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color(0.2, 0.2, 0.2)
	handle.material_override = mat2
	handle.position = Vector3(0.35, -0.15, 0)
	handle.rotation_degrees = Vector3(0, 0, 70)
	root.add_child(handle)

	# initialize floating metadata
	root.set_meta("float_phase", _rng.randf() * TAU)
	root.set_meta("base_y", 0.5)
	# per-axis rotation directions and speeds
	var dir_x := 1.0
	var dir_y := 1.0
	var dir_z := 1.0
	if _rng.randi_range(0, 1) == 0:
		dir_x = -1.0
	if _rng.randi_range(0, 1) == 0:
		dir_y = -1.0
	if _rng.randi_range(0, 1) == 0:
		dir_z = -1.0
	root.set_meta("rot_dir_x", dir_x)
	root.set_meta("rot_dir_y", dir_y)
	root.set_meta("rot_dir_z", dir_z)
	# give each axis a slightly different speed multiplier
	root.set_meta("rot_speed_x", float_rotation_speed * (_rng.randf_range(0.8, 1.3)))
	root.set_meta("rot_speed_y", float_rotation_speed * (_rng.randf_range(0.8, 1.3)))
	root.set_meta("rot_speed_z", float_rotation_speed * (_rng.randf_range(0.8, 1.3)))

	return root

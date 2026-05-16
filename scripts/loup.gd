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
var float_rotation_speed := 45.0 # degrees per second
var _lane_positions: Array = []
var _loupes: Array = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0

func setup(lane_positions: Array[float]) -> void:
	name = "Loupes"
	_lane_positions = lane_positions
	_rng.randomize()

func reset() -> void:
	for l in _loupes:
		l.queue_free()
	_loupes.clear()
	_time = 0.0

func tick(delta: float, player_pos: Vector3) -> void:
	_time += delta
	if _time >= spawn_interval:
		_time = 0.0
		_try_spawn_row()

	for l in _loupes.duplicate():
		# move forward
		l.position.z += world_speed * delta

		# floating animation (update phase and vertical bob)
		var phase := 0.0
		if l.has_meta("float_phase"):
			phase = l.get_meta("float_phase")
		phase += float_speed * delta
		l.set_meta("float_phase", phase)
		var base_y := 0.5
		if l.has_meta("base_y"):
			base_y = l.get_meta("base_y")
		l.position.y = base_y + sin(phase) * float_amplitude

		# gentle rotation
		var rot_dir := 1.0
		if l.has_meta("rot_dir"):
			rot_dir = l.get_meta("rot_dir")
		l.rotation_degrees.y += float_rotation_speed * delta * rot_dir

		# collision: simple distance check to player
		if player_pos.distance_to(l.position) < 1.2:
			_loupes.erase(l)
			l.queue_free()
			continue

		if l.position.z > floor_front_z:
			_loupes.erase(l)
			l.queue_free()

func _try_spawn_row() -> void:
	# At each interval, spawn at most one lupa (prevents two together)
	if _rng.randf() > spawn_chance:
		return

	# don't spawn if there is already a lupa very near the spawn line
	for existing in _loupes:
		if absf(existing.position.z - floor_back_z) < 1.0:
			return

	if _lane_positions.size() == 0:
		return

	var lane_index := _rng.randi_range(0, _lane_positions.size() - 1)
	var l := _make_lupa()
	l.position = Vector3(_lane_positions[lane_index], 0.5, floor_back_z)
	add_child(l)
	_loupes.append(l)

func _make_lupa() -> Node3D:
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
	if _rng.randi_range(0, 1) == 0:
		root.set_meta("rot_dir", -1.0)
	else:
		root.set_meta("rot_dir", 1.0)

	return root

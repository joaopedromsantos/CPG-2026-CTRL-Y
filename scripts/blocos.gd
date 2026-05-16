class_name RunnerBlocos
extends Node3D

var world_speed := 8.0
var steps_per_spawn := 10
var step_distance := 1.0
var floor_back_z := -18.0
var floor_front_z := 11.6

var _lane_positions: Array[float] = []
var _distance_since_spawn := 0.0
var _number_rows: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var _mat_number: StandardMaterial3D
var _mat_number_side: StandardMaterial3D
var _mat_number_border: StandardMaterial3D


func setup(lane_positions: Array[float]) -> void:
	name = "Numeros"
	_lane_positions = lane_positions
	_rng.randomize()
	_build_materials()
	reset()


func reset() -> void:
	for row in _number_rows:
		row.queue_free()

	_number_rows.clear()
	_distance_since_spawn = 0.0


func tick(delta: float, _player_position: Vector3) -> void:
	_distance_since_spawn += world_speed * delta
	if _distance_since_spawn >= float(steps_per_spawn) * step_distance:
		_spawn_number_row()
		_distance_since_spawn = 0.0

	for row in _number_rows.duplicate():
		row.position.z += world_speed * delta
		if row.position.z > floor_front_z:
			_number_rows.erase(row)
			row.queue_free()


func _spawn_number_row() -> void:
	var row := Node3D.new()
	row.name = "LinhaNumeros"
	row.position.z = floor_back_z
	add_child(row)
	_number_rows.append(row)

	for lane_index in _lane_positions.size():
		var number_label := _make_number_label(str(_rng.randi_range(0, 9)))
		number_label.position = Vector3(_lane_positions[lane_index], 0.85, 0.0)
		row.add_child(number_label)

		if lane_index < _lane_positions.size() - 1:
			var separator_label := _make_number_label("|")
			separator_label.position = Vector3(
				(_lane_positions[lane_index] + _lane_positions[lane_index + 1]) * 0.5,
				0.85,
				0.0
			)
			row.add_child(separator_label)


func _build_materials() -> void:
	_mat_number = StandardMaterial3D.new()
	_mat_number.albedo_color = Color.WHITE
	_mat_number.roughness = 0.32

	_mat_number_side = StandardMaterial3D.new()
	_mat_number_side.albedo_color = Color(0.04, 0.04, 0.05)
	_mat_number_side.roughness = 0.45

	_mat_number_border = StandardMaterial3D.new()
	_mat_number_border.albedo_color = Color.BLACK
	_mat_number_border.roughness = 0.4


func _make_number_label(text: String) -> Node3D:
	var root := Node3D.new()

	var border := _make_text_mesh(text)
	border.name = "Borda"
	border.scale = Vector3(1.18, 1.18, 1.0)
	border.position.z = -0.04
	border.set_surface_override_material(0, _mat_number_border)
	border.set_surface_override_material(1, _mat_number_border)
	root.add_child(border)

	var front := _make_text_mesh(text)
	front.name = "Frente"
	front.position.z = 0.03
	front.set_surface_override_material(0, _mat_number)
	front.set_surface_override_material(1, _mat_number_side)
	root.add_child(front)

	return root


func _make_text_mesh(text: String) -> MeshInstance3D:
	var text_mesh := TextMesh.new()
	text_mesh.text = text
	text_mesh.font_size = 96
	text_mesh.pixel_size = 0.013
	text_mesh.depth = 0.18
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var mesh := MeshInstance3D.new()
	mesh.mesh = text_mesh
	return mesh

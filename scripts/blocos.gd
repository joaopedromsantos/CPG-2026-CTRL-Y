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


func setup(lane_positions: Array[float]) -> void:
	name = "Numeros"
	_lane_positions = lane_positions
	_rng.randomize()
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


func _make_number_label(text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.013
	label.modulate = Color.WHITE
	label.outline_size = 10
	label.outline_modulate = Color.BLACK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

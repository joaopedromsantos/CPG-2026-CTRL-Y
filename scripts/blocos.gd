class_name RunnerBlocos
extends Node3D

var world_speed := 8.0
var steps_per_spawn := 20
var step_distance := 1.0
var floor_back_z := -18.0
var floor_front_z := 11.6

var _lane_positions: Array[float] = []
var _distance_since_spawn := 0.0
var _block_rows: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var _mat_block: StandardMaterial3D
var _mat_block_side: StandardMaterial3D
var _mat_number: StandardMaterial3D
var _block_mesh: ArrayMesh


func setup(lane_positions: Array[float]) -> void:
	name = "BlocosNumerados"
	_lane_positions = lane_positions
	_rng.randomize()
	_build_materials()
	_block_mesh = _make_rounded_box_mesh(Vector3(2.3, 2.4, 1.0), 0.25, 4)
	reset()


func reset() -> void:
	for row in _block_rows:
		row.queue_free()

	_block_rows.clear()
	_distance_since_spawn = 0.0


func tick(delta: float, _player_position: Vector3) -> void:
	_distance_since_spawn += world_speed * delta
	if _distance_since_spawn >= float(steps_per_spawn) * step_distance:
		_spawn_block_row()
		_distance_since_spawn = 0.0

	for row in _block_rows.duplicate():
		row.position.z += world_speed * delta
		if row.position.z > floor_front_z:
			_block_rows.erase(row)
			row.queue_free()


func _spawn_block_row() -> void:
	var row := Node3D.new()
	row.name = "LinhaBlocos"
	row.position.z = floor_back_z
	add_child(row)
	_block_rows.append(row)

	for lane_index in _lane_positions.size():
		var block := _make_number_block(str(_rng.randi_range(0, 9)))
		block.position = Vector3(_lane_positions[lane_index], 1.2, 0.0)
		row.add_child(block)


func _build_materials() -> void:
	_mat_block = StandardMaterial3D.new()
	_mat_block.albedo_color = Color(1.0, 0.66, 0.22)
	_mat_block.roughness = 0.42
	_mat_block.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_block_side = StandardMaterial3D.new()
	_mat_block_side.albedo_color = Color(0.95, 0.48, 0.12)
	_mat_block_side.roughness = 0.5
	_mat_block_side.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_number = StandardMaterial3D.new()
	_mat_number.albedo_color = Color.WHITE
	_mat_number.roughness = 0.28


func _make_number_block(text: String) -> Node3D:
	var root := Node3D.new()

	var block := MeshInstance3D.new()
	block.name = "Bloco"
	block.mesh = _block_mesh
	block.set_surface_override_material(0, _mat_block)
	root.add_child(block)

	var number := _make_text_mesh(text)
	number.name = "Numero"
	number.position = Vector3(0.0, 0.0, 0.55)
	root.add_child(number)

	return root


func _make_text_mesh(text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 300
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_rounded_box_mesh(size: Vector3, radius: float, segments: int) -> ArrayMesh:
	var half_size := size * 0.5
	var rounded_radius := minf(radius, minf(minf(half_size.x, half_size.y), half_size.z) - 0.01)
	var inner_size := half_size - Vector3.ONE * rounded_radius
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.RIGHT)
	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.LEFT)
	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.UP)
	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.DOWN)
	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.BACK)
	_add_rounded_face(vertices, normals, indices, half_size, inner_size, rounded_radius, segments, Vector3.FORWARD)

	_add_surface(mesh, vertices, normals, indices)

	return mesh


func _add_rounded_face(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array,
	half_size: Vector3,
	inner_size: Vector3,
	radius: float,
	segments: int,
	face_normal: Vector3
) -> void:
	var start_index := vertices.size()
	var axis := _dominant_axis(face_normal)

	for row in segments + 1:
		for col in segments + 1:
			var u := -1.0 + 2.0 * float(col) / float(segments)
			var v := -1.0 + 2.0 * float(row) / float(segments)
			var box_point := _face_point(axis, face_normal, u, v, half_size)
			var rounded_point := _round_box_point(box_point, inner_size, radius)
			vertices.append(rounded_point)
			normals.append(_round_box_normal(box_point, inner_size, face_normal))

	for row in segments:
		for col in segments:
			var a := start_index + row * (segments + 1) + col
			var b := a + 1
			var c := a + segments + 1
			var d := c + 1

			if face_normal.x + face_normal.y + face_normal.z > 0.0:
				indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
			else:
				indices.append_array(PackedInt32Array([a, b, c, b, d, c]))


func _dominant_axis(normal: Vector3) -> int:
	if absf(normal.x) > 0.5:
		return 0
	if absf(normal.y) > 0.5:
		return 1
	return 2


func _face_point(axis: int, normal: Vector3, u: float, v: float, half_size: Vector3) -> Vector3:
	match axis:
		0:
			return Vector3(normal.x * half_size.x, u * half_size.y, v * half_size.z)
		1:
			return Vector3(u * half_size.x, normal.y * half_size.y, v * half_size.z)
		_:
			return Vector3(u * half_size.x, v * half_size.y, normal.z * half_size.z)


func _round_box_point(point: Vector3, inner_size: Vector3, radius: float) -> Vector3:
	var closest := Vector3(
		clampf(point.x, -inner_size.x, inner_size.x),
		clampf(point.y, -inner_size.y, inner_size.y),
		clampf(point.z, -inner_size.z, inner_size.z)
	)
	var offset := point - closest
	if offset.length_squared() == 0.0:
		return point

	return closest + offset.normalized() * radius


func _round_box_normal(point: Vector3, inner_size: Vector3, fallback: Vector3) -> Vector3:
	var closest := Vector3(
		clampf(point.x, -inner_size.x, inner_size.x),
		clampf(point.y, -inner_size.y, inner_size.y),
		clampf(point.z, -inner_size.z, inner_size.z)
	)
	var offset := point - closest
	if offset.length_squared() == 0.0:
		return fallback

	return offset.normalized()


func _add_surface(mesh: ArrayMesh, vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

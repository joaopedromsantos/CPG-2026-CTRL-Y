class_name RunnerBlocos
extends Node3D

var world_speed := 8.0
var steps_per_spawn := 10
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


func setup(lane_positions: Array[float]) -> void:
	name = "BlocosNumerados"
	_lane_positions = lane_positions
	_rng.randomize()
	_build_materials()
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
		block.position = Vector3(_lane_positions[lane_index], 0.68, 0.0)
		row.add_child(block)


func _build_materials() -> void:
	_mat_block = StandardMaterial3D.new()
	_mat_block.albedo_color = Color(1.0, 0.48, 0.08)
	_mat_block.roughness = 0.42
	_mat_block.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_block_side = StandardMaterial3D.new()
	_mat_block_side.albedo_color = Color(0.82, 0.31, 0.03)
	_mat_block_side.roughness = 0.5
	_mat_block_side.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_number = StandardMaterial3D.new()
	_mat_number.albedo_color = Color.WHITE
	_mat_number.roughness = 0.28


func _make_number_block(text: String) -> Node3D:
	var root := Node3D.new()

	var block := MeshInstance3D.new()
	block.name = "Bloco"
	block.mesh = _make_rounded_box_mesh(Vector3(1.15, 1.35, 0.62), 0.18, 6)
	block.set_surface_override_material(0, _mat_block)
	block.set_surface_override_material(1, _mat_block)
	block.set_surface_override_material(2, _mat_block_side)
	root.add_child(block)

	var number := _make_text_mesh(text)
	number.name = "Numero"
	number.position = Vector3(0.0, 0.0, 0.39)
	number.set_surface_override_material(0, _mat_number)
	number.set_surface_override_material(1, _mat_number)
	root.add_child(number)

	return root


func _make_text_mesh(text: String) -> MeshInstance3D:
	var text_mesh := TextMesh.new()
	text_mesh.text = text
	text_mesh.font_size = 96
	text_mesh.pixel_size = 0.011
	text_mesh.depth = 0.035
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var mesh := MeshInstance3D.new()
	mesh.mesh = text_mesh
	return mesh


func _make_rounded_box_mesh(size: Vector3, radius: float, segments: int) -> ArrayMesh:
	var half_width := size.x * 0.5
	var half_height := size.y * 0.5
	var half_depth := size.z * 0.5
	var rounded_radius := minf(radius, minf(half_width, half_height) - 0.01)
	var points := _make_rounded_rect_points(half_width, half_height, rounded_radius, segments)
	var triangles := Geometry2D.triangulate_polygon(points)
	var mesh := ArrayMesh.new()

	var front_vertices := PackedVector3Array()
	var front_normals := PackedVector3Array()
	var front_indices := PackedInt32Array()
	for point in points:
		front_vertices.append(Vector3(point.x, point.y, half_depth))
		front_normals.append(Vector3.BACK)
	for index in triangles:
		front_indices.append(index)
	_add_surface(mesh, front_vertices, front_normals, front_indices)

	var back_vertices := PackedVector3Array()
	var back_normals := PackedVector3Array()
	var back_indices := PackedInt32Array()
	for point in points:
		back_vertices.append(Vector3(point.x, point.y, -half_depth))
		back_normals.append(Vector3.FORWARD)
	for triangle_index in range(triangles.size() - 1, -1, -1):
		back_indices.append(triangles[triangle_index])
	_add_surface(mesh, back_vertices, back_normals, back_indices)

	var side_vertices := PackedVector3Array()
	var side_normals := PackedVector3Array()
	var side_indices := PackedInt32Array()
	for index in points.size():
		var next_index := (index + 1) % points.size()
		var current := points[index]
		var next := points[next_index]
		var start := side_vertices.size()
		var normal := Vector3(next.y - current.y, current.x - next.x, 0.0).normalized()

		side_vertices.append(Vector3(current.x, current.y, half_depth))
		side_vertices.append(Vector3(next.x, next.y, half_depth))
		side_vertices.append(Vector3(next.x, next.y, -half_depth))
		side_vertices.append(Vector3(current.x, current.y, -half_depth))

		for vertex in 4:
			side_normals.append(normal)

		side_indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	_add_surface(mesh, side_vertices, side_normals, side_indices)

	return mesh


func _make_rounded_rect_points(half_width: float, half_height: float, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers := [
		Vector2(half_width - radius, half_height - radius),
		Vector2(-half_width + radius, half_height - radius),
		Vector2(-half_width + radius, -half_height + radius),
		Vector2(half_width - radius, -half_height + radius),
	]
	var angle_starts: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]

	for corner in 4:
		for segment in segments + 1:
			var angle := angle_starts[corner] + (float(segment) / float(segments)) * PI * 0.5
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)

	return points


func _add_surface(mesh: ArrayMesh, vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

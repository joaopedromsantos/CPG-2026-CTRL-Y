class_name RunnerBlockDrawer
extends RefCounted

const BLOCK_SIDE := 2.0
const BLOCK_CORNER_RADIUS := 0.08
const BLOCK_CORNER_SEGMENTS := 6
const BLOCK_TEXT_FRONT_OFFSET := BLOCK_SIDE * 0.5 + 0.04
const BLOCK_NUMBER_FONT_SIZE := 280
const BLOCK_FLOAT_AMPLITUDE := 0.22
const BLOCK_FLOAT_SPEED := 2.6
const BLOCK_TILT_DEGREES := 20.0
const BLOCK_TILT_SPEED := 2.4

var _rng := RandomNumberGenerator.new()
var _mat_block: StandardMaterial3D
var _mat_block_correct: StandardMaterial3D
var _mat_block_side: StandardMaterial3D
var _mat_number: StandardMaterial3D
var _block_mesh: Mesh


func setup() -> void:
	_rng.randomize()
	_build_materials()
	_block_mesh = _make_rounded_cube_mesh()


func make_number_block(text: String) -> Node3D:
	var root := Node3D.new()

	var block := MeshInstance3D.new()
	block.name = "Bloco"
	block.mesh = _block_mesh
	block.set_surface_override_material(0, _mat_block)
	root.add_child(block)

	var number := _make_text_mesh(text)
	number.name = "Numero"
	number.position = Vector3(0.0, 0.0, BLOCK_TEXT_FRONT_OFFSET)
	root.add_child(number)

	root.set_meta("float_phase", _rng.randf() * TAU)
	root.set_meta("tilt_phase", -PI * 0.5)

	return root


func apply_block_highlight(block: Node3D, is_correct: bool, highlight_correct_answers: bool) -> void:
	if block == null:
		return

	var mesh_instance := block.get_node_or_null("Bloco") as MeshInstance3D
	if mesh_instance == null:
		return

	if highlight_correct_answers and is_correct:
		mesh_instance.set_surface_override_material(0, _mat_block_correct)
	else:
		mesh_instance.set_surface_override_material(0, _mat_block)


func animate_block(block: Node3D, delta: float) -> void:
	if block == null:
		return

	var float_phase := float(block.get_meta("float_phase", 0.0)) + BLOCK_FLOAT_SPEED * delta
	var tilt_phase := float(block.get_meta("tilt_phase", -PI * 0.5)) + BLOCK_TILT_SPEED * delta
	var base_y := float(block.get_meta("base_y", block.position.y))

	block.set_meta("float_phase", float_phase)
	block.set_meta("tilt_phase", tilt_phase)
	block.position.y = base_y + sin(float_phase) * BLOCK_FLOAT_AMPLITUDE
	block.rotation.y = deg_to_rad(sin(tilt_phase) * BLOCK_TILT_DEGREES)


func _build_materials() -> void:
	_mat_block = StandardMaterial3D.new()
	_mat_block.albedo_color = Color(1.0, 0.66, 0.22)
	_mat_block.roughness = 0.42
	_mat_block.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_block_correct = StandardMaterial3D.new()
	_mat_block_correct.albedo_color = Color(0.18, 0.88, 0.36)
	_mat_block_correct.emission_enabled = true
	_mat_block_correct.emission = Color(0.12, 0.65, 0.28)
	_mat_block_correct.emission_energy_multiplier = 0.45
	_mat_block_correct.roughness = 0.35
	_mat_block_correct.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_block_side = StandardMaterial3D.new()
	_mat_block_side.albedo_color = Color(0.95, 0.48, 0.12)
	_mat_block_side.roughness = 0.5
	_mat_block_side.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_number = StandardMaterial3D.new()
	_mat_number.albedo_color = Color.WHITE
	_mat_number.roughness = 0.28


func _make_rounded_cube_mesh() -> ArrayMesh:
	return _make_rounded_box_mesh(
		Vector3.ONE * BLOCK_SIDE,
		BLOCK_CORNER_RADIUS,
		BLOCK_CORNER_SEGMENTS
	)


func _make_text_mesh(text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = BLOCK_NUMBER_FONT_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.outline_size = 18
	label.outline_modulate = Color(0.18, 0.1, 0.02, 0.85)
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

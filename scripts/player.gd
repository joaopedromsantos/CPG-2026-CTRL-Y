class_name RunnerPlayer
extends Node3D

const PLAYER_SCENE := preload("res://assets/player/UAL1_Standard.glb")

var lane_change_speed := 12.0
var player_y := 0.0
var player_z := 5.8
var player_scale := Vector3(0.85, 0.85, 0.85)

var _lane_positions: Array[float] = []
var _current_lane := 1
var _target_x := 0.0
var _model: Node3D
var _fallback_material: StandardMaterial3D


func setup(lane_positions: Array[float], start_lane: int) -> void:
	_lane_positions = lane_positions
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]

	_build_fallback_material()
	_build_model()
	reset(_current_lane)


func reset(start_lane: int) -> void:
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	position = Vector3(_target_x, player_y, player_z)
	rotation_degrees = Vector3.ZERO

	if _model:
		_model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		_play_running_animation(_model)


func change_lane(direction: int) -> void:
	_current_lane = clampi(_current_lane + direction, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]


func tick(delta: float) -> void:
	var weight := 1.0 - exp(-lane_change_speed * delta)
	position.x = lerpf(position.x, _target_x, weight)
	_animate_player()


func get_runner_position() -> Vector3:
	return position


func _build_fallback_material() -> void:
	_fallback_material = StandardMaterial3D.new()
	_fallback_material.albedo_color = Color(0.15, 0.55, 1.0)
	_fallback_material.roughness = 0.18
	_fallback_material.metallic = 0.35


func _build_model() -> void:
	_model = PLAYER_SCENE.instantiate() as Node3D
	if _model == null:
		_model = _make_fallback_model()

	_model.name = "Model"
	_model.scale = player_scale
	add_child(_model)


func _make_fallback_model() -> Node3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1

	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = _fallback_material
	mesh.position.y = 0.55
	return mesh


func _play_running_animation(root: Node) -> void:
	for child in root.get_children():
		if child is AnimationPlayer:
			var animation_player := child as AnimationPlayer
			var animations := animation_player.get_animation_list()
			if animations.is_empty():
				continue

			var selected := animations[0]
			for animation_name in animations:
				var lower_name := String(animation_name).to_lower()
				if lower_name.contains("run") or lower_name.contains("walk"):
					selected = animation_name
					break

			animation_player.play(selected)
			return

		_play_running_animation(child)


func _animate_player() -> void:
	if _model == null:
		return

	_model.rotation_degrees.y = 180.0 + sin(Time.get_ticks_msec() * 0.008) * 2.0
	position.y = player_y + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.035

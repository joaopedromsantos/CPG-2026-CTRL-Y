class_name RunnerCones
extends Node3D

signal cone_hit

const CONE_SCENE: PackedScene = preload("res://assets/city-kit-roads/models/construction-cone.glb")

var world_speed := 8.0
var floor_back_z := -18.0
var floor_front_z := 11.6
var spawn_interval := 1.2
var spawn_chance := 0.4

var _cones: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _lane_positions: Array[float] = []


func setup(lane_positions: Array[float]) -> void:
	name = "Cones"
	_lane_positions = lane_positions
	_rng.randomize()


func reset() -> void:
	for cone in _cones:
		cone.queue_free()

	_cones.clear()
	_time = 0.0


func tick(delta: float, player_position: Vector3) -> void:
	_time += delta
	if _time >= spawn_interval:
		_time = 0.0
		_try_spawn_cone()

	for active_cone in _cones.duplicate():
		active_cone.position.z += world_speed * delta
		if active_cone.position.z >= player_position.z and _is_player_in_cone_lane(active_cone, player_position):
			_cones.erase(active_cone)
			active_cone.queue_free()
			cone_hit.emit()
			continue
		if active_cone.position.z > floor_front_z:
			_cones.erase(active_cone)
			active_cone.queue_free()


func _try_spawn_cone() -> void:
	if _rng.randf() > spawn_chance:
		return
	if _lane_positions.is_empty():
		return
	for existing_cone in _cones:
		if absf(existing_cone.position.z - floor_back_z) < 2.0:
			return

	var lane_index := _rng.randi_range(0, _lane_positions.size() - 1)
	var cone := _make_cone()
	cone.position = Vector3(_lane_positions[lane_index], 0.0, floor_back_z)
	add_child(cone)
	_cones.append(cone)


func _make_cone() -> Node3D:
	var cone := CONE_SCENE.instantiate() as Node3D
	cone.name = "Cone"
	cone.scale = Vector3.ONE * 12.1
	cone.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	return cone


func _is_player_in_cone_lane(cone: Node3D, player_position: Vector3) -> bool:
	return absf(cone.position.x - player_position.x) <= 1.0

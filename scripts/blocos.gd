class_name RunnerBlocos
extends Node3D

signal player_hit

var world_speed := 8.0
var spawn_time := 1.05
var floor_back_z := -18.0
var floor_front_z := 11.6

var _lane_positions: Array[float] = []
var _spawn_timer := 0.0
var _obstacles: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _mat_obstacle: StandardMaterial3D


func setup(lane_positions: Array[float]) -> void:
	name = "Blocos"
	_lane_positions = lane_positions
	_rng.randomize()
	_build_material()
	reset()


func reset() -> void:
	for obstacle in _obstacles:
		obstacle.queue_free()

	_obstacles.clear()
	_spawn_timer = 0.35


func tick(delta: float, player_position: Vector3) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_obstacle()
		_spawn_timer = spawn_time

	for obstacle in _obstacles.duplicate():
		obstacle.position.z += world_speed * delta
		if obstacle.position.z > floor_front_z:
			_obstacles.erase(obstacle)
			obstacle.queue_free()
		elif _collides_with_player(obstacle, player_position):
			player_hit.emit()


func _build_material() -> void:
	_mat_obstacle = StandardMaterial3D.new()
	_mat_obstacle.albedo_color = Color(0.9, 0.12, 0.08)
	_mat_obstacle.roughness = 0.35


func _spawn_obstacle() -> void:
	var lane := _rng.randi_range(0, _lane_positions.size() - 1)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.15, 1.15, 1.15)

	var obstacle := MeshInstance3D.new()
	obstacle.name = "Obstacle"
	obstacle.mesh = mesh
	obstacle.material_override = _mat_obstacle
	obstacle.position = Vector3(_lane_positions[lane], 0.58, floor_back_z)
	add_child(obstacle)
	_obstacles.append(obstacle)


func _collides_with_player(obstacle: MeshInstance3D, player_position: Vector3) -> bool:
	var x_close := absf(obstacle.position.x - player_position.x) < 0.95
	var z_close := absf(obstacle.position.z - player_position.z) < 0.95
	return x_close and z_close

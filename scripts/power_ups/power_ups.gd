class_name RunnerPowerUps
extends Node3D

signal power_up_collected(type: String)

const TYPE_LUPA := "lupa"
const TYPE_REVIVE := "revive"
const TYPE_HEART := "heart"
const TYPE_LIGHTNING := "lightning"
const TYPE_HOURGLASS := "hourglass"
const TYPE_DOUBLE := "double"

const USE_EFFECT_DURATION := 1.0
const USE_EFFECT_RISE := 3.2
const USE_EFFECT_SPIN_DEGREES := 720.0
const USE_EFFECT_START_Y_OFFSET := 1.0
const USE_EFFECT_POP_SCALE := 1.5

var world_speed := 8.0
var floor_back_z := -18.0
var floor_front_z := 11.6
var spawn_interval := 4.0
var spawn_chance := 0.5

var float_amplitude := 0.15
var float_speed := 3.6
var float_rotation_speed := 48.0

var _spawn_entries: Array = []
var _power_ups: Array = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _lane_positions: Array = []
var _spawn_logic := PowerUpSpawnLogic.new()
var _visual_factory := PowerUpVisualFactory.new()


func setup(lane_positions: Array) -> void:
	name = "PowerUps"
	_lane_positions = lane_positions
	_rng.randomize()
	_visual_factory.setup(_rng, float_rotation_speed)
	_build_spawn_pool()


func reset() -> void:
	for item in _power_ups:
		var power_up := item as Node3D
		if power_up:
			power_up.queue_free()
	_power_ups.clear()
	_time = 0.0


func tick(delta: float, player_pos: Vector3) -> void:
	_time += delta
	if _time >= spawn_interval:
		_time = 0.0
		_try_spawn_row()

	for item in _power_ups.duplicate():
		var power_up := item as Node3D
		if not power_up:
			continue

		power_up.position.z += world_speed * delta

		var phase: float = power_up.get_meta("float_phase", 0.0)
		phase += float_speed * delta
		power_up.set_meta("float_phase", phase)
		var base_y: float = power_up.get_meta("base_y", 0.5)
		power_up.position.y = base_y + sin(phase) * float_amplitude

		var rotation_speed_x: float = power_up.get_meta("rot_speed_x", float_rotation_speed)
		var rotation_speed_y: float = power_up.get_meta("rot_speed_y", float_rotation_speed)
		var rotation_speed_z: float = power_up.get_meta("rot_speed_z", float_rotation_speed)
		var rotation_direction_x: float = power_up.get_meta("rot_dir_x", 1.0)
		var rotation_direction_y: float = power_up.get_meta("rot_dir_y", 1.0)
		var rotation_direction_z: float = power_up.get_meta("rot_dir_z", 1.0)
		power_up.rotation_degrees.x += rotation_speed_x * delta * rotation_direction_x
		power_up.rotation_degrees.y += rotation_speed_y * delta * rotation_direction_y
		power_up.rotation_degrees.z += rotation_speed_z * delta * rotation_direction_z

		if player_pos.distance_to(power_up.position) < 1.2:
			var picked_type: String = power_up.get_meta("type", "")
			_power_ups.erase(item)
			power_up.queue_free()
			if picked_type != "":
				power_up_collected.emit(picked_type)
			continue

		if power_up.position.z > floor_front_z:
			_power_ups.erase(item)
			power_up.queue_free()


func spawn_use_effect(type: String, origin: Vector3) -> void:
	var path := ""
	for asset_path in PowerUpSpawnLogic.ASSET_TYPES:
		if PowerUpSpawnLogic.ASSET_TYPES[asset_path] == type:
			path = asset_path
			break
	if path == "" and type != TYPE_DOUBLE:
		return
	var visual := _visual_factory.make_power_up({"type": type, "path": path})
	if not visual:
		return
	visual.set_meta("type", "")

	var root := Node3D.new()
	root.name = "PowerUpUseEffect"
	root.position = origin + Vector3(0, USE_EFFECT_START_Y_OFFSET, 0)
	add_child(root)
	root.add_child(visual)

	var initial_scale := visual.scale
	var rise_target_y := root.position.y + USE_EFFECT_RISE
	var spin_target_y := visual.rotation_degrees.y + USE_EFFECT_SPIN_DEGREES

	var rise := create_tween()
	rise.bind_node(root)
	rise.set_parallel(true)
	rise.tween_property(root, "position:y", rise_target_y, USE_EFFECT_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.tween_property(visual, "rotation_degrees:y", spin_target_y, USE_EFFECT_DURATION)

	var pop := create_tween()
	pop.bind_node(root)
	pop.tween_property(visual, "scale", initial_scale * USE_EFFECT_POP_SCALE, USE_EFFECT_DURATION * 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(visual, "scale", Vector3.ZERO, USE_EFFECT_DURATION * 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pop.finished.connect(root.queue_free)


func _build_spawn_pool() -> void:
	_spawn_entries = _spawn_logic.build_spawn_entries()


func _try_spawn_row() -> void:
	if _rng.randf() > spawn_chance:
		return

	if not _spawn_logic.can_spawn(_power_ups, floor_back_z, _lane_positions, _spawn_entries):
		return

	var index := _rng.randi_range(0, _spawn_entries.size() - 1)
	var entry: Dictionary = _spawn_entries[index]
	var power_up := _visual_factory.make_power_up(entry)
	if not power_up:
		return
	var lane_index := _rng.randi_range(0, _lane_positions.size() - 1)
	power_up.position = Vector3(_lane_positions[lane_index], 0.5, floor_back_z)
	add_child(power_up)
	_power_ups.append(power_up)

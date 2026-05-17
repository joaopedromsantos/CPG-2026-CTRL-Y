class_name RunnerPlayer
extends CharacterBody3D

const PLAYER_MOVEMENT_LOGIC_SCRIPT = preload("res://scripts/player/movement/player_movement_logic.gd")
const PLAYER_ANIMATION_CONTROLLER_SCRIPT = preload("res://scripts/player/animation/player_animation_controller.gd")

@export var lane_change_speed := 12.0
@export var player_y := 0.0
@export var player_z := 8.5

const DEATH_ANIMATION := "RobotArmature|Robot_Death"
const RUN_ANIMATION := "RobotArmature|Robot_Running"
const JUMP_ANIMATION := "RobotArmature|Robot_WalkJump"
const NO_ANIMATION := "RobotArmature|Robot_No"
const BODY_SHAKE_ANGLE := 0.16
const BODY_SHAKE_SPEED := 42.0

var _animation_player: AnimationPlayer
var _gesture_animation_player: AnimationPlayer
var _model: Node3D
var _jump_sound: AudioStreamPlayer
var _model_base_rotation := Vector3.ZERO

var _lane_positions: Array[float] = []
var _current_lane := 1
var _target_x := 0.0
var _current_animation := ""
var _can_change_lane := true
var _lane_change_cooldown := 0.08
var _vertical_velocity := 0.0
var _is_jumping := false
var _jump_force := 8.0
var _gravity := 18.0
var _is_dead := false
var _blink_duration := 2.0
var _blink_elapsed := 0.0
var _blink_toggle_time := 0.0
var _speed_multiplier := 1.0
var _movement_logic = PLAYER_MOVEMENT_LOGIC_SCRIPT.new()
var _animation_controller = PLAYER_ANIMATION_CONTROLLER_SCRIPT.new()


func get_runner_position() -> Vector3:
	return global_position


func set_speed_multiplier(multiplier: float) -> void:
	_speed_multiplier = multiplier
	if _animation_player and _current_animation == RUN_ANIMATION:
		_animation_player.speed_scale = multiplier


func setup(lane_positions: Array[float], start_lane: int) -> void:
	_model = $Robot
	_model_base_rotation = _model.rotation
	_animation_player = $Robot/AnimationPlayer
	_gesture_animation_player = _animation_controller.setup_gesture_animation_player(_animation_player, _model, NO_ANIMATION)
	_lane_positions = lane_positions
	_current_lane = _movement_logic.clamped_lane(start_lane, _lane_positions)
	_target_x = _movement_logic.lane_target_x(_current_lane, _lane_positions)
	_jump_sound = AudioStreamPlayer.new()
	_jump_sound.stream = load("res://assets/sounds/jump_sound.wav")
	add_child(_jump_sound)
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		game_settings.call("apply_sfx_volume", _jump_sound)
	reset(_current_lane)


func reset(start_lane: int) -> void:
	_current_lane = _movement_logic.clamped_lane(start_lane, _lane_positions)
	_target_x = _movement_logic.lane_target_x(_current_lane, _lane_positions)
	position = Vector3(_target_x, player_y, player_z)
	rotation.y = PI
	_is_dead = false
	_blink_elapsed = 0.0
	_blink_toggle_time = 0.0
	_speed_multiplier = 1.0
	if _animation_player:
		_animation_player.speed_scale = 1.0
	if _model:
		_model.visible = true
		_model.rotation = _model_base_rotation
	if _gesture_animation_player:
		_gesture_animation_player.stop()
	_play_base_animation(RUN_ANIMATION)


func change_lane(direction: int) -> void:
	if not _can_change_lane:
		return
	_current_lane = _movement_logic.next_lane(_current_lane, direction, _lane_positions)
	_target_x = _movement_logic.lane_target_x(_current_lane, _lane_positions)
	_can_change_lane = false


func jump() -> void:
	if not _can_change_lane or _is_jumping:
		return
	_play_base_animation(JUMP_ANIMATION)
	_vertical_velocity = _jump_force
	_is_jumping = true
	_can_change_lane = false
	_jump_sound.play()


func die() -> void:
	_is_dead = true
	if _gesture_animation_player:
		_gesture_animation_player.stop()
	if _model:
		_model.rotation = _model_base_rotation
	_animation_player.play(DEATH_ANIMATION)
	_current_animation = DEATH_ANIMATION


func get_death_animation_duration() -> float:
	if _animation_player and _animation_player.has_animation(DEATH_ANIMATION):
		return _animation_player.get_animation(DEATH_ANIMATION).length
	return 2.0


func take_damage() -> void:
	if _is_dead:
		return
	_blink_elapsed = _blink_duration
	_blink_toggle_time = 0.0
	_animation_controller.play_no_gesture(_gesture_animation_player)


func tick(delta: float) -> void:
	var weight: float = _movement_logic.lane_weight(lane_change_speed, _speed_multiplier, delta)
	position.x = lerpf(position.x, _target_x, weight)

	if _is_jumping:
		_vertical_velocity -= _gravity * delta
		position.y += _vertical_velocity * delta

		if position.y <= player_y:
			position.y = player_y
			_vertical_velocity = 0.0
			_is_jumping = false
			_play_base_animation(RUN_ANIMATION)

	if not _can_change_lane:
		_lane_change_cooldown -= delta
		if _lane_change_cooldown <= 0.0:
			_can_change_lane = true
			_lane_change_cooldown = 0.08

	_update_damage_blink(delta)

	if not _is_dead and _animation_player and not _animation_player.is_playing():
		if _current_animation != RUN_ANIMATION:
			_play_base_animation(RUN_ANIMATION)
		else:
			_animation_player.play(RUN_ANIMATION)


func _play_base_animation(animation_name: String) -> void:
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return

	_animation_player.play(animation_name)
	_current_animation = animation_name


func _update_damage_blink(delta: float) -> void:
	if _blink_elapsed <= 0.0:
		if _model and not _model.visible:
			_model.visible = true
		if _model:
			_model.rotation = _model_base_rotation
		return

	_blink_elapsed = maxf(_blink_elapsed - delta, 0.0)
	_update_body_damage_shake()
	_blink_toggle_time -= delta
	if _blink_toggle_time <= 0.0:
		var progress := 1.0 - (_blink_elapsed / _blink_duration)
		_blink_toggle_time = lerpf(0.05, 0.35, progress)
		if _model:
			_model.visible = not _model.visible

	if _blink_elapsed <= 0.0 and _model:
		_model.visible = true
		_model.rotation = _model_base_rotation


func _update_body_damage_shake() -> void:
	if _model == null:
		return

	_model.rotation = _animation_controller.damage_shake_rotation(
		_model_base_rotation,
		_blink_duration,
		_blink_elapsed,
		BODY_SHAKE_SPEED,
		BODY_SHAKE_ANGLE
	)

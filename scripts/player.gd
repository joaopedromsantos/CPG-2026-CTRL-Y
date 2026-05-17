class_name RunnerPlayer
extends CharacterBody3D

@export var lane_change_speed := 12.0
@export var player_y := 0.0
@export var player_z := 8.5

var _anim: AnimationPlayer
var _snd_jump: AudioStreamPlayer

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


func get_runner_position() -> Vector3:
	return global_position

func setup(lane_positions: Array[float], start_lane: int) -> void:
	_anim = $Robot/AnimationPlayer
	_lane_positions = lane_positions
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	_snd_jump = AudioStreamPlayer.new()
	_snd_jump.stream = load("res://assets/sounds/jump_sound.wav")
	add_child(_snd_jump)
	reset(_current_lane)


func reset(start_lane: int) -> void:
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	position = Vector3(_target_x, player_y, player_z)
	rotation.y = PI
	_is_dead = false
	_anim.play("RobotArmature|Robot_Running")
	_current_animation = "RobotArmature|Robot_Running"


func change_lane(direction: int) -> void:
	if not _can_change_lane:
		return
	_current_lane = clampi(_current_lane + direction, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	_can_change_lane = false


func jump() -> void:
	if not _can_change_lane or _is_jumping:
		return
	_anim.play("RobotArmature|Robot_WalkJump")
	_current_animation = "RobotArmature|Robot_WalkJump"
	_vertical_velocity = _jump_force
	_is_jumping = true
	_can_change_lane = false
	_snd_jump.play()


func die() -> void:
	_is_dead = true
	_anim.play("RobotArmature|Robot_Death")
	_current_animation = "RobotArmature|Robot_Death"


func take_damage() -> void:
	if _is_dead:
		return
	_anim.play("RobotArmature|Robot_No")
	_current_animation = "RobotArmature|Robot_No"


func tick(delta: float) -> void:
	var weight := 1.0 - exp(-lane_change_speed * delta)
	position.x = lerpf(position.x, _target_x, weight)

	if _is_jumping:
		_vertical_velocity -= _gravity * delta
		position.y += _vertical_velocity * delta

		if position.y <= player_y:
			position.y = player_y
			_vertical_velocity = 0.0
			_is_jumping = false
			_anim.play("RobotArmature|Robot_Running")
			_current_animation = "RobotArmature|Robot_Running"

	if not _can_change_lane:
		_lane_change_cooldown -= delta
		if _lane_change_cooldown <= 0.0:
			_can_change_lane = true
			_lane_change_cooldown = 0.08

	if not _is_dead and not _anim.is_playing():
		if _current_animation != "RobotArmature|Robot_Running":
			_anim.play("RobotArmature|Robot_Running")
			_current_animation = "RobotArmature|Robot_Running"
		else:
			_anim.play("RobotArmature|Robot_Running")

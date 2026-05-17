class_name RunnerPlayer
extends CharacterBody3D

@export var lane_change_speed := 12.0
@export var player_y := 0.0
@export var player_z := 8.5

var _anim: AnimationPlayer
var _gesture_anim: AnimationPlayer
var _model: Node3D
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
var _blink_duration := 2.0
var _blink_elapsed := 0.0
var _blink_toggle_time := 0.0

const DEATH_ANIMATION := "RobotArmature|Robot_Death"
const RUN_ANIMATION := "RobotArmature|Robot_Running"
const JUMP_ANIMATION := "RobotArmature|Robot_WalkJump"
const NO_ANIMATION := "RobotArmature|Robot_No"
const NO_UPPER_ANIMATION := "upper_body_no"
const UPPER_BODY_BONES := [
	"Abdomen",
	"Torso",
	"Neck",
	"Head",
	"Shoulder",
	"UpperArm",
	"LowerArm",
	"Palm",
	"Middle",
	"Thumb",
	"Index",
	"Ring",
]


func get_runner_position() -> Vector3:
	return global_position

func setup(lane_positions: Array[float], start_lane: int) -> void:
	_model = $Robot
	_anim = $Robot/AnimationPlayer
	_setup_gesture_animation_player()
	_lane_positions = lane_positions
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	_snd_jump = AudioStreamPlayer.new()
	_snd_jump.stream = load("res://assets/sounds/jump_sound.wav")
	add_child(_snd_jump)
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		game_settings.call("apply_sfx_volume", _snd_jump)
	reset(_current_lane)


func reset(start_lane: int) -> void:
	_current_lane = clampi(start_lane, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	position = Vector3(_target_x, player_y, player_z)
	rotation.y = PI
	_is_dead = false
	_blink_elapsed = 0.0
	_blink_toggle_time = 0.0
	if _model:
		_model.visible = true
	if _gesture_anim:
		_gesture_anim.stop()
	_play_base_animation(RUN_ANIMATION)


func change_lane(direction: int) -> void:
	if not _can_change_lane:
		return
	_current_lane = clampi(_current_lane + direction, 0, _lane_positions.size() - 1)
	_target_x = _lane_positions[_current_lane]
	_can_change_lane = false


func jump() -> void:
	if not _can_change_lane or _is_jumping:
		return
	_play_base_animation(JUMP_ANIMATION)
	_vertical_velocity = _jump_force
	_is_jumping = true
	_can_change_lane = false
	_snd_jump.play()


func die() -> void:
	_is_dead = true
	if _gesture_anim:
		_gesture_anim.stop()
	_anim.play(DEATH_ANIMATION)
	_current_animation = DEATH_ANIMATION


func get_death_animation_duration() -> float:
	if _anim and _anim.has_animation(DEATH_ANIMATION):
		return _anim.get_animation(DEATH_ANIMATION).length
	return 2.0


func take_damage() -> void:
	if _is_dead:
		return
	_blink_elapsed = _blink_duration
	_blink_toggle_time = 0.0
	_play_no_gesture()


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
			_play_base_animation(RUN_ANIMATION)

	if not _can_change_lane:
		_lane_change_cooldown -= delta
		if _lane_change_cooldown <= 0.0:
			_can_change_lane = true
			_lane_change_cooldown = 0.08

	_update_damage_blink(delta)

	if not _is_dead and not _anim.is_playing():
		if _current_animation != RUN_ANIMATION:
			_play_base_animation(RUN_ANIMATION)
		else:
			_anim.play(RUN_ANIMATION)


func _setup_gesture_animation_player() -> void:
	if _anim == null or not _anim.has_animation(NO_ANIMATION):
		return

	_gesture_anim = AnimationPlayer.new()
	_gesture_anim.name = "UpperBodyGestureAnimationPlayer"
	_gesture_anim.root_node = _anim.root_node
	_model.add_child(_gesture_anim)

	var no_animation := _anim.get_animation(NO_ANIMATION).duplicate(true) as Animation
	_keep_upper_body_tracks(no_animation)

	var library := AnimationLibrary.new()
	library.add_animation(NO_UPPER_ANIMATION, no_animation)
	_gesture_anim.add_animation_library("", library)


func _keep_upper_body_tracks(animation: Animation) -> void:
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		if not _is_upper_body_track(animation.track_get_path(track_index)):
			animation.remove_track(track_index)


func _is_upper_body_track(track_path: NodePath) -> bool:
	var path_text := String(track_path)
	for bone_name in UPPER_BODY_BONES:
		if path_text.contains(bone_name):
			return true

	return false


func _play_no_gesture() -> void:
	if _gesture_anim == null or not _gesture_anim.has_animation(NO_UPPER_ANIMATION):
		return

	_gesture_anim.stop()
	_gesture_anim.play(NO_UPPER_ANIMATION)


func _play_base_animation(animation_name: String) -> void:
	if _anim == null or not _anim.has_animation(animation_name):
		return

	_anim.play(animation_name)
	_current_animation = animation_name


func _update_damage_blink(delta: float) -> void:
	if _blink_elapsed <= 0.0:
		if _model and not _model.visible:
			_model.visible = true
		return

	_blink_elapsed = maxf(_blink_elapsed - delta, 0.0)
	_blink_toggle_time -= delta
	if _blink_toggle_time <= 0.0:
		var progress := 1.0 - (_blink_elapsed / _blink_duration)
		_blink_toggle_time = lerpf(0.05, 0.35, progress)
		if _model:
			_model.visible = not _model.visible

	if _blink_elapsed <= 0.0 and _model:
		_model.visible = true

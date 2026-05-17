class_name PlayerAnimationController
extends RefCounted

const NO_UPPER_ANIMATION := "upper_body_no"
const HEAD_SPIN_TURNS := 2.0
const HEAD_SPIN_STEPS := 16
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


func setup_gesture_animation_player(
	animation_player: AnimationPlayer,
	model: Node3D,
	no_animation_name: String
) -> AnimationPlayer:
	if animation_player == null or not animation_player.has_animation(no_animation_name):
		return null

	var gesture_animation_player := AnimationPlayer.new()
	gesture_animation_player.name = "UpperBodyGestureAnimationPlayer"
	gesture_animation_player.root_node = animation_player.root_node
	model.add_child(gesture_animation_player)

	var no_animation := animation_player.get_animation(no_animation_name).duplicate(true) as Animation
	_keep_upper_body_tracks(no_animation)
	_make_head_spin_more_evident(no_animation)

	var library := AnimationLibrary.new()
	library.add_animation(NO_UPPER_ANIMATION, no_animation)
	gesture_animation_player.add_animation_library("", library)
	return gesture_animation_player


func play_no_gesture(gesture_animation_player: AnimationPlayer) -> void:
	if gesture_animation_player and gesture_animation_player.has_animation(NO_UPPER_ANIMATION):
		gesture_animation_player.stop()
		gesture_animation_player.play(NO_UPPER_ANIMATION)


func damage_shake_rotation(
	model_base_rotation: Vector3,
	blink_duration: float,
	blink_elapsed: float,
	body_shake_speed: float,
	body_shake_angle: float
) -> Vector3:
	var elapsed := blink_duration - blink_elapsed
	var fade := clampf(blink_elapsed / blink_duration, 0.0, 1.0)
	return model_base_rotation + Vector3(
		sin(elapsed * body_shake_speed * 0.71) * body_shake_angle * 0.35 * fade,
		sin(elapsed * body_shake_speed) * body_shake_angle * fade,
		cos(elapsed * body_shake_speed * 0.83) * body_shake_angle * 0.45 * fade
	)


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


func _make_head_spin_more_evident(animation: Animation) -> void:
	var head_rotation_paths: Array[NodePath] = []
	var head_base_rotations: Array[Quaternion] = []
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		if animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		if not _is_head_track(animation.track_get_path(track_index)):
			continue

		head_rotation_paths.append(animation.track_get_path(track_index))
		head_base_rotations.append(_get_first_rotation_key(animation, track_index))
		animation.remove_track(track_index)

	for path_index in head_rotation_paths.size():
		var track_index := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, head_rotation_paths[path_index])
		var base_rotation := head_base_rotations[path_index]
		for step in HEAD_SPIN_STEPS + 1:
			var progress := float(step) / float(HEAD_SPIN_STEPS)
			var spin := Quaternion(Vector3.UP, TAU * HEAD_SPIN_TURNS * progress)
			animation.track_insert_key(track_index, animation.length * progress, base_rotation * spin)


func _is_head_track(track_path: NodePath) -> bool:
	var path_text := String(track_path)
	return path_text.contains("Head") and not path_text.contains("Head_end")


func _get_first_rotation_key(animation: Animation, track_index: int) -> Quaternion:
	if animation.track_get_key_count(track_index) > 0:
		return animation.track_get_key_value(track_index, 0) as Quaternion

	return Quaternion.IDENTITY

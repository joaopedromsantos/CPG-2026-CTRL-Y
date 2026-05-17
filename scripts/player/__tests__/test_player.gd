extends GutTest

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const LANES: Array[float] = [-2.8, 0.0, 2.8]

var _player


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child_autoqfree(_player)
	_player.setup(LANES, 1)
	await wait_idle_frames(1)


func test_player_scene_uses_refactored_script() -> void:
	assert_true(_player.get_script().resource_path.ends_with("scripts/player/player.gd"))


func test_setup_places_player_on_start_lane() -> void:
	assert_almost_eq(_player.position.x, 0.0, 0.001)
	assert_almost_eq(_player.position.y, _player.player_y, 0.001)
	assert_almost_eq(_player.position.z, _player.player_z, 0.001)


func test_change_lane_moves_toward_target_lane() -> void:
	_player.change_lane(1)
	_player.tick(0.1)

	assert_gt(_player.position.x, 0.0)


func test_change_lane_is_ignored_while_on_cooldown() -> void:
	_player.change_lane(1)
	_player.change_lane(-1)
	_player.tick(0.1)

	assert_gt(_player.position.x, 0.0)


func test_reset_clamps_start_lane_to_valid_range() -> void:
	_player.reset(99)

	assert_almost_eq(_player.position.x, 2.8, 0.001)


func test_get_death_animation_duration_returns_fallback_without_animation() -> void:
	var player = preload("res://scripts/player/player.gd").new()
	add_child_autoqfree(player)

	assert_eq(player.get_death_animation_duration(), 2.0)

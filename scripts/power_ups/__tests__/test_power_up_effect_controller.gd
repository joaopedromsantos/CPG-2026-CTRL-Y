extends GutTest

const POWER_UP_CONFIG_SCRIPT = preload("res://scripts/power_ups/power_up_config.gd")
const POWER_UP_EFFECT_CONTROLLER_SCRIPT = preload("res://scripts/power_ups/effects/power_up_effect_controller.gd")

var _config
var _controller


func before_each() -> void:
	_config = POWER_UP_CONFIG_SCRIPT.new()
	_controller = POWER_UP_EFFECT_CONTROLLER_SCRIPT.new()
	add_child_autoqfree(_controller)
	_controller.setup(null, null, _config, 3, 1)


func test_activate_success_emits_active_slot_change() -> void:
	watch_signals(_controller)

	var activated: bool = _controller.activate("double", 1, 1)

	assert_true(activated)
	assert_true(_controller.is_slot_active(1))
	assert_signal_emitted_with_parameters(_controller, "power_up_slot_changed", [1, "double", 8.0, 8.0, true])


func test_activate_rejects_unknown_type() -> void:
	var activated: bool = _controller.activate("unknown", 0, 1)

	assert_false(activated)
	assert_false(_controller.is_slot_active(0))


func test_activate_rejects_slot_that_is_already_active() -> void:
	assert_true(_controller.activate("double", 0, 1))

	var activated: bool = _controller.activate("lupa", 0, 1)

	assert_false(activated)


func test_tick_expires_effect_and_emits_inactive_slot_change() -> void:
	_controller.activate("double", 0, 1)
	watch_signals(_controller)

	_controller.tick(8.1)

	assert_false(_controller.is_slot_active(0))
	assert_signal_emitted_with_parameters(_controller, "power_up_slot_changed", [0, "double", 0.0, 8.0, false])


func test_heart_heals_immediately_and_on_interval() -> void:
	watch_signals(_controller)

	assert_true(_controller.activate("heart", 0, 1))
	_controller.tick(_config.heart_heal_interval)

	assert_signal_emitted_with_parameters(_controller, "lives_changed", [2], 0)
	assert_signal_emitted_with_parameters(_controller, "lives_changed", [3], 1)


func test_consume_revive_removes_active_revive() -> void:
	assert_true(_controller.activate("revive", 2, 0))
	watch_signals(_controller)

	var consumed: bool = _controller.consume_revive_if_available(0)

	assert_true(consumed)
	assert_false(_controller.is_slot_active(2))
	assert_signal_emitted_with_parameters(_controller, "power_up_slot_changed", [2, "revive", 10.0, 10.0, false])


func test_activate_lightning_marks_wrong_block_and_clears_slot_immediately() -> void:
	var blocks := RunnerBlocks.new()
	add_child_autoqfree(blocks)
	blocks.world_speed = 10.0
	blocks.steps_per_spawn = 1
	blocks.step_distance = 1.0
	blocks.floor_back_z = -10.0
	blocks.floor_front_z = 12.0
	blocks.setup([-2.8, 0.0, 2.8] as Array[float])
	blocks.set_equation_options([
		{"value": 10, "isCorrect": true},
		{"value": 20, "isCorrect": false},
		{"value": 30, "isCorrect": false},
	], [10])
	blocks.tick(0.1, Vector3(0.0, 1.0, 8.5))
	_controller.setup(null, blocks, _config, 3, 1)
	watch_signals(_controller)

	var activated: bool = _controller.activate("lightning", 1, 1)

	assert_true(activated)
	assert_false(_controller.is_slot_active(1))
	assert_signal_emitted_with_parameters(_controller, "power_up_slot_changed", [1, "lightning", 0.0, 0.0, false])

	var row := blocks.get_child(0)
	var correct_block := row.get_child(0) as Node3D
	var destroyed_count := 0
	for block in row.get_children():
		if bool((block as Node3D).get_meta("is_destroyed", false)):
			destroyed_count += 1
	assert_eq(destroyed_count, 1)
	assert_false(bool(correct_block.get_meta("is_destroyed", false)))


func test_activate_lightning_without_blocks_returns_false() -> void:
	var activated: bool = _controller.activate("lightning", 0, 1)

	assert_false(activated)
	assert_false(_controller.is_slot_active(0))

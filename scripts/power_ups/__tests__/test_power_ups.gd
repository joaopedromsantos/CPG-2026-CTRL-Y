extends GutTest

const POWER_UPS_SCRIPT = preload("res://scripts/power_ups/power_ups.gd")

var _power_ups


func before_each() -> void:
	_power_ups = POWER_UPS_SCRIPT.new()
	_power_ups.spawn_interval = 0.1
	_power_ups.spawn_chance = 1.0
	_power_ups.floor_back_z = -10.0
	_power_ups.floor_front_z = 12.0
	add_child_autoqfree(_power_ups)


func test_setup_builds_power_up_root_name() -> void:
	_power_ups.setup([-2.8, 0.0, 2.8])

	assert_eq(_power_ups.name, "PowerUps")


func test_tick_spawns_power_up_when_spawn_conditions_match() -> void:
	_power_ups.setup([-2.8, 0.0, 2.8])

	_power_ups.tick(0.1, Vector3(99.0, 99.0, 99.0))

	assert_eq(_power_ups.get_child_count(), 1)
	assert_eq(_power_ups.get_child(0).name, "PowerUp")
	assert_ne(String(_power_ups.get_child(0).get_meta("type", "")), "")


func test_tick_does_not_spawn_without_lanes() -> void:
	_power_ups.setup([])

	_power_ups.tick(0.1, Vector3(99.0, 99.0, 99.0))

	assert_eq(_power_ups.get_child_count(), 0)


func test_tick_collects_power_up_and_emits_type() -> void:
	_power_ups.setup([-2.8, 0.0, 2.8])
	_power_ups.tick(0.1, Vector3(99.0, 99.0, 99.0))
	_power_ups.spawn_interval = 999.0
	var spawned := _power_ups.get_child(0) as Node3D
	var spawned_type := String(spawned.get_meta("type", ""))
	watch_signals(_power_ups)

	_power_ups.tick(0.0, spawned.position)
	await wait_idle_frames(1)

	assert_signal_emitted_with_parameters(_power_ups, "power_up_collected", [spawned_type])
	assert_eq(_power_ups.get_child_count(), 0)


func test_spawn_use_effect_ignores_unknown_type() -> void:
	_power_ups.setup([-2.8, 0.0, 2.8])

	_power_ups.spawn_use_effect("unknown", Vector3.ZERO)

	assert_eq(_power_ups.get_child_count(), 0)

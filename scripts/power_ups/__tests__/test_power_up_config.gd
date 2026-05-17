extends GutTest

const POWER_UP_CONFIG_SCRIPT = preload("res://scripts/power_ups/power_up_config.gd")


func test_duration_for_known_type_returns_configured_duration() -> void:
	var config = POWER_UP_CONFIG_SCRIPT.new()
	config.lupa_duration = 9.0

	assert_eq(config.duration_for("lupa"), 9.0)


func test_duration_for_unknown_type_returns_zero() -> void:
	var config = POWER_UP_CONFIG_SCRIPT.new()

	assert_eq(config.duration_for("unknown"), 0.0)

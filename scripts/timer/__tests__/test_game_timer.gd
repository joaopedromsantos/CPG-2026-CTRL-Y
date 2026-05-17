extends GutTest

const GAME_TIMER_SCRIPT = preload("res://scripts/timer/game_timer.gd")


func test_timer_starts_ticks_stops_and_formats_time() -> void:
	var timer = GAME_TIMER_SCRIPT.new()

	timer.start_timer()
	timer.tick(61.4)
	timer.stop_timer()
	timer.tick(1.0)

	assert_eq(timer.formatted_time(), "01:01")


func test_reset_timer_clears_time_and_stops_running() -> void:
	var timer = GAME_TIMER_SCRIPT.new()
	timer.start_timer()
	timer.tick(10.0)

	timer.reset_timer()

	assert_eq(timer.current_time, 0.0)
	assert_false(timer.is_time_running)

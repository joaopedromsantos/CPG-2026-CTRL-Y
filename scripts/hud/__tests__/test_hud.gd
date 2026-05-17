extends GutTest

const HUD_SCENE = preload("res://scenes/hud.tscn")

var _hud


func before_each() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child_autoqfree(_hud)
	await wait_idle_frames(1)


func test_show_equation_sets_current_equation_and_label_text() -> void:
	var equation := {
		"equation": "7 + ? = 12",
		"options": [1, 2, 5],
		"correctAnswers": [5],
	}

	_hud.show_equation(equation)

	assert_eq(_hud.get_current_equation(), equation)
	assert_eq(_hud.equation_label.text, "7 + ? = 12")
	assert_eq(_hud.get_current_options(), [1, 2, 5])
	assert_eq(_hud.get_current_correct_answers(), [5])


func test_show_equation_clears_label_for_empty_equation() -> void:
	_hud.show_equation({})

	assert_eq(_hud.equation_label.text, "")
	assert_eq(_hud.get_current_options(), [])
	assert_eq(_hud.get_current_correct_answers(), [])


func test_score_change_updates_label_and_last_score() -> void:
	_hud.on_score_change(12)

	assert_eq(_hud.score_label.text, "12")
	assert_eq(_hud._last_score, 12)


func test_set_max_lives_adds_and_removes_hearts() -> void:
	_hud.set_max_lives(5)

	assert_eq(_hud.hearts_row.get_child_count(), 5)

	_hud.set_max_lives(2)
	await wait_idle_frames(1)

	assert_eq(_hud.hearts_row.get_child_count(), 2)


func test_lives_change_updates_heart_textures() -> void:
	_hud.set_max_lives(3)
	_hud.on_lives_change(2)

	var first_heart := _hud.hearts_row.get_child(0) as TextureRect
	var third_heart := _hud.hearts_row.get_child(2) as TextureRect

	assert_eq(first_heart.texture, _hud.HEART_FULL_TEXTURE)
	assert_eq(third_heart.texture, _hud.HEART_EMPTY_TEXTURE)


func test_power_up_slots_change_sets_icon_texture_and_last_slots() -> void:
	_hud.on_power_up_slots_change(["lupa", "", "", ""])

	assert_eq(_hud._last_power_up_slots, ["lupa", "", "", ""])
	assert_not_null(_hud._slot_icon_rects[0].texture)
	assert_eq(_hud._slot_icon_rects[1].texture, null)


func test_power_up_slot_active_changed_updates_countdown_and_style() -> void:
	_hud.on_power_up_slot_active_changed(0, "lupa", 5.2, 6.0, true)

	assert_true(_hud._slot_countdown_labels[0].visible)
	assert_eq(_hud._slot_countdown_labels[0].text, "6")
	assert_eq(_hud._slot_icon_rects[0].modulate, _hud.SLOT_ICON_ACTIVE_MODULATE)

	_hud.on_power_up_slot_active_changed(0, "lupa", 0.0, 6.0, false)

	assert_false(_hud._slot_countdown_labels[0].visible)
	assert_eq(_hud._slot_icon_rects[0].modulate, _hud.SLOT_ICON_INACTIVE_MODULATE)


func test_on_restart_game_resets_hud_state() -> void:
	_hud.on_score_change(10)
	_hud.show_equation({"equation": "1 + 1"})
	_hud.on_restart_game()

	assert_eq(_hud._last_score, 0)
	assert_eq(_hud._last_lives, -1)
	assert_eq(_hud._last_power_up_slots, [])
	assert_eq(_hud.equation_label.text, "")
	assert_true(_hud.pause_button.visible)

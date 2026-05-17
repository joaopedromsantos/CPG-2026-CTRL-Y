extends GutTest

const POWER_UP_SLOT_LOGIC_SCRIPT = preload("res://scripts/hud/slots/power_up_slot_logic.gd")
const SLOT_COUNT := 4


func test_power_up_display_returns_null_for_empty_type() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()

	assert_eq(logic.power_up_display("", {}, {}), null)


func test_power_up_display_returns_mapped_texture() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()
	var texture := Texture2D.new()
	var type_to_icon := {"lupa": 0}
	var textures := {0: texture}

	assert_eq(logic.power_up_display("lupa", type_to_icon, textures), texture)


func test_power_up_display_returns_null_for_unknown_type() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()
	var texture := Texture2D.new()
	var type_to_icon := {"lupa": 0}
	var textures := {0: texture}

	assert_eq(logic.power_up_display("unknown", type_to_icon, textures), null)


func test_countdown_text_ceilings_remaining_time() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()

	assert_eq(logic.countdown_text(5.2), "6")
	assert_eq(logic.countdown_text(5.0), "5")
	assert_eq(logic.countdown_text(-1.0), "0")


func test_is_valid_slot_checks_bounds() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()

	assert_false(logic.is_valid_slot(-1, SLOT_COUNT))
	assert_true(logic.is_valid_slot(0, SLOT_COUNT))
	assert_true(logic.is_valid_slot(3, SLOT_COUNT))
	assert_false(logic.is_valid_slot(4, SLOT_COUNT))


func test_is_reserve_slot_matches_configured_index() -> void:
	var logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()

	assert_false(logic.is_reserve_slot(2, 3))
	assert_true(logic.is_reserve_slot(3, 3))

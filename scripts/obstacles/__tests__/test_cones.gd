extends GutTest

const CONES_SCRIPT = preload("res://scripts/obstacles/cones.gd")
const LANES: Array[float] = [-2.8, 0.0, 2.8]


func test_setup_sets_cones_root_name() -> void:
	var cones = CONES_SCRIPT.new()
	add_child_autoqfree(cones)

	cones.setup(LANES)

	assert_eq(cones.name, "Cones")


func test_tick_when_disabled_keeps_no_children() -> void:
	var cones = CONES_SCRIPT.new()
	cones.enabled = false
	add_child_autoqfree(cones)
	cones.setup(LANES)

	cones.tick(1.0, Vector3.ZERO)

	assert_eq(cones.get_child_count(), 0)

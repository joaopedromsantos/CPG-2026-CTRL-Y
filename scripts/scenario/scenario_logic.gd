class_name RunnerScenarioLogic
extends RefCounted


func actual_row_count(configured_rows: int, floor_back_z: float, floor_front_z: float, floor_tile_size: float) -> int:
	var visible_depth := floor_front_z - floor_back_z + floor_tile_size * 2.0
	var needed_rows := int(ceil(visible_depth / floor_tile_size))
	return max(configured_rows, needed_rows + 1)


func wrap_z(floor_front_z: float, floor_tile_size: float) -> float:
	return floor_front_z + floor_tile_size


func wrapped_z(z_position: float, rows_actual: int, floor_tile_size: float, floor_front_z: float) -> float:
	if z_position > wrap_z(floor_front_z, floor_tile_size):
		return z_position - float(rows_actual) * floor_tile_size

	return z_position


func light_pole_rotation(side: int, is_square: bool) -> Vector3:
	if is_square:
		return Vector3(0.0, 0.0 if side < 0 else 180.0, 0.0)

	return Vector3(0.0, -90.0 if side < 0 else 90.0, 0.0)


func pick_light_pole_variant(rng: RandomNumberGenerator, previous_variant_idx: int, variant_count: int) -> int:
	if variant_count <= 1:
		return 0

	var variant_idx := rng.randi_range(0, variant_count - 1)
	if variant_idx == previous_variant_idx:
		variant_idx = (variant_idx + rng.randi_range(1, variant_count - 1)) % variant_count

	return variant_idx


func side_prop_spawn_chance(slot_idx: int, base_chance: float) -> float:
	var wave := 0.12 if slot_idx % 3 == 0 else (-0.10 if slot_idx % 3 == 1 else 0.0)
	return clampf(base_chance + wave, 0.25, 0.85)

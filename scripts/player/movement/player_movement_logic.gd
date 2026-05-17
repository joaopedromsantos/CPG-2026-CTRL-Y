class_name PlayerMovementLogic
extends RefCounted


func clamped_lane(start_lane: int, lane_positions: Array[float]) -> int:
	return clampi(start_lane, 0, lane_positions.size() - 1)


func lane_target_x(lane: int, lane_positions: Array[float]) -> float:
	return lane_positions[lane]


func lane_weight(lane_change_speed: float, speed_multiplier: float, delta: float) -> float:
	return 1.0 - exp(-lane_change_speed * speed_multiplier * delta)


func next_lane(current_lane: int, direction: int, lane_positions: Array[float]) -> int:
	return clampi(current_lane + direction, 0, lane_positions.size() - 1)

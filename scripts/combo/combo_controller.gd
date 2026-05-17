extends RefCounted
class_name ComboController

const TIERS := [
	{"threshold": 5, "multiplier": 2},
	{"threshold": 10, "multiplier": 4},
	{"threshold": 15, "multiplier": 6},
]

var streak: int = 0
var current_tier: int = 0


func register_correct() -> int:
	streak += 1
	for i in range(TIERS.size() - 1, -1, -1):
		if streak == int(TIERS[i]["threshold"]) and current_tier < i + 1:
			current_tier = i + 1
			return current_tier
	return -1


func register_miss() -> void:
	streak = 0
	current_tier = 0


func reset() -> void:
	streak = 0
	current_tier = 0


func get_multiplier() -> int:
	if current_tier <= 0:
		return 1
	return int(TIERS[current_tier - 1]["multiplier"])

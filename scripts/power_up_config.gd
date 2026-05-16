class_name PowerUpConfig
extends Resource

@export_group("Durations")
@export var lupa_duration := 6.0
@export var revive_duration := 10.0
@export var heart_duration := 5.0
@export var lightning_duration := 5.0
@export var hourglass_duration := 6.0
@export var double_duration := 8.0

@export_group("Effects")
@export var heart_heal_interval := 2.0
@export var hourglass_speed_multiplier := 0.55
@export var double_score_multiplier := 2


func duration_for(type: String) -> float:
	match type:
		"lupa": return lupa_duration
		"revive": return revive_duration
		"heart": return heart_duration
		"lightning": return lightning_duration
		"hourglass": return hourglass_duration
		"double": return double_duration
		_: return 0.0

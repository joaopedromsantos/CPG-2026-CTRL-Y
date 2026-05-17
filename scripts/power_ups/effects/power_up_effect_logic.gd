class_name PowerUpEffectLogic
extends RefCounted


func make_effect(type: String, slot: int, duration: float) -> Dictionary:
	return {
		"type": type,
		"slot": slot,
		"remaining": duration,
		"duration": duration,
		"heal_elapsed": 0.0,
	}


func tick_effect(effect: Dictionary, delta: float) -> Dictionary:
	effect["remaining"] = float(effect.get("remaining", 0.0)) - delta
	return effect


func is_slot_active(active_effects: Array[Dictionary], slot: int) -> bool:
	for effect in active_effects:
		if int(effect.get("slot", -1)) == slot:
			return true
	return false


func has_active_type(active_effects: Array[Dictionary], type: String) -> bool:
	for effect in active_effects:
		if String(effect.get("type", "")) == type:
			return true
	return false

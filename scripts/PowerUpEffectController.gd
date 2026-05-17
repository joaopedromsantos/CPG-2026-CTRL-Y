class_name PowerUpEffectController
extends Node

signal lives_changed(lives: int)
signal power_up_slot_changed(slot: int, type: String, remaining: float, duration: float, active: bool)

const TYPE_LUPA := "lupa"
const TYPE_REVIVE := "revive"
const TYPE_HEART := "heart"
const TYPE_LIGHTNING := "lightning"
const TYPE_HOURGLASS := "hourglass"
const TYPE_DOUBLE := "double"

const LIGHTNING_PLAYER_SPEED_MULTIPLIER := 2.0

var config: PowerUpConfig
var player: RunnerPlayer
var blocks: RunnerBlocks
var max_lives := 3

var _active_effects: Array[Dictionary] = []
var _current_lives := 3


func setup(
	p_player: RunnerPlayer,
	p_blocks: RunnerBlocks,
	p_config: PowerUpConfig,
	p_max_lives: int,
	p_current_lives: int
) -> void:
	player = p_player
	blocks = p_blocks
	config = p_config
	max_lives = p_max_lives
	_current_lives = p_current_lives
	_sync_effect_state()


func reset(current_lives: int) -> void:
	for effect in _active_effects:
		_emit_slot_changed(effect, false)
	_active_effects.clear()
	_current_lives = current_lives
	_sync_effect_state()


func set_current_lives(current_lives: int) -> void:
	_current_lives = clampi(current_lives, 0, max_lives)


func tick(delta: float) -> void:
	var changed := false
	for i in range(_active_effects.size() - 1, -1, -1):
		var effect := _active_effects[i]
		effect["remaining"] = float(effect.get("remaining", 0.0)) - delta
		if String(effect.get("type", "")) == TYPE_HEART:
			effect["heal_elapsed"] = float(effect.get("heal_elapsed", 0.0)) + delta
			if float(effect["heal_elapsed"]) >= config.heart_heal_interval:
				effect["heal_elapsed"] = 0.0
				_heal(1)

		if float(effect["remaining"]) <= 0.0:
			effect["remaining"] = 0.0
			_emit_slot_changed(effect, false)
			_active_effects.remove_at(i)
			changed = true
		else:
			_active_effects[i] = effect
			_emit_slot_changed(effect, true)

	if changed:
		_sync_effect_state()


func activate(type: String, slot: int, current_lives: int) -> bool:
	if is_slot_active(slot):
		return false

	var duration := config.duration_for(type)
	if duration <= 0.0:
		return false

	_current_lives = current_lives
	var effect := {
		"type": type,
		"slot": slot,
		"remaining": duration,
		"duration": duration,
		"heal_elapsed": 0.0,
	}
	_active_effects.append(effect)

	if type == TYPE_HEART:
		_heal(1)

	_sync_effect_state()
	_emit_slot_changed(effect, true)
	return true


func get_score_multiplier() -> int:
	if _has_active_type(TYPE_DOUBLE):
		return config.double_score_multiplier
	return 1


func get_world_speed_multiplier() -> float:
	if _has_active_type(TYPE_HOURGLASS):
		return config.hourglass_speed_multiplier
	return 1.0


func get_player_speed_multiplier() -> float:
	if _has_active_type(TYPE_LIGHTNING):
		return LIGHTNING_PLAYER_SPEED_MULTIPLIER
	return 1.0


func consume_revive_if_available(current_lives: int) -> bool:
	_current_lives = current_lives
	for i in range(_active_effects.size() - 1, -1, -1):
		if String(_active_effects[i].get("type", "")) == TYPE_REVIVE:
			_emit_slot_changed(_active_effects[i], false)
			_active_effects.remove_at(i)
			_sync_effect_state()
			return true
	return false


func _heal(amount: int) -> void:
	var next_lives := clampi(_current_lives + amount, 0, max_lives)
	if next_lives == _current_lives:
		return

	_current_lives = next_lives
	lives_changed.emit(_current_lives)


func _sync_effect_state() -> void:
	if blocks:
		blocks.set_correct_answers_highlighted(_has_active_type(TYPE_LUPA))
	if player:
		player.set_speed_multiplier(get_player_speed_multiplier())


func _has_active_type(type: String) -> bool:
	for effect in _active_effects:
		if String(effect.get("type", "")) == type:
			return true
	return false


func is_slot_active(slot: int) -> bool:
	for effect in _active_effects:
		if int(effect.get("slot", -1)) == slot:
			return true
	return false


func _emit_slot_changed(effect: Dictionary, active: bool) -> void:
	power_up_slot_changed.emit(
		int(effect.get("slot", -1)),
		String(effect.get("type", "")),
		float(effect.get("remaining", 0.0)),
		float(effect.get("duration", 0.0)),
		active
	)

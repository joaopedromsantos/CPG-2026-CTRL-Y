extends Node3D
@onready var hud = $HUD

signal game_over(score: int)
signal restart_game
signal score_event
signal lives_event
signal power_up_slots_event(slots: Array)
signal power_up_used(type: String, slot: int)

const LANE_WIDTH := 2.8
const FLOOR_BACK_Z := -18.0
const FLOOR_FRONT_Z := 11.6
const BASE_WORLD_SPEED := 8.0
const WORLD_SPEED_PER_SCORE := 0.2
const EQUATION_QUEUE_SIZE := 3
const DEFAULT_MAX_LIVES := 3
const DIFFICULTY_LIVES := {
	"easy": 6,
	"medium": 5,
	"hard": 4,
	"impossible": 3,
}
const DIFFICULTY_WITHOUT_CONES := "easy"
const POWER_UP_SLOT_COUNT := 4
const ACTIVATABLE_POWER_UP_SLOT_COUNT := 3
const RESERVE_POWER_UP_SLOT := 3
const MIN_GAME_OVER_DELAY := 2.0
const LIFE_LOST_REACTION_DELAY := 0.45
const EQUATION_SEQUENCE_SCRIPT = preload("res://scripts/equation_sequence.gd")
const POWER_UP_CONFIG = preload("res://assets/power-ups/power_up_config.tres")

var _lane_positions: Array[float] = [
	-LANE_WIDTH,
	0.0,
	LANE_WIDTH,
]

var _score := 0.0
var _max_lives := DEFAULT_MAX_LIVES
var _lives := DEFAULT_MAX_LIVES
var _is_game_over := false
var _is_paused := false
var world_speed := BASE_WORLD_SPEED
var _power_up_slots: Array[String] = ["", "", "", ""]

var _player: RunnerPlayer
# var _hud: RunnerHud
var _cenario: RunnerScenario
var _blocos: RunnerBlocos
var _power_ups: RunnerPowerUps
var _cones: RunnerCones
var _power_up_effects: RunnerPowerUpEffectController
var _snd_game: AudioStreamPlayer
var _snd_lose: AudioStreamPlayer
var _snd_punch: AudioStreamPlayer
var _snd_correct: AudioStreamPlayer
var _snd_wrong: AudioStreamPlayer
var _equation_sequence = EQUATION_SEQUENCE_SCRIPT.new()
var _camera: Camera3D
var _camera_base_position := Vector3.ZERO
var _shake_duration := 0.0
var _shake_time_left := 0.0
var _shake_strength := 0.0
var _game_over_sequence_id := 0


func _ready() -> void:
	_equation_sequence.load_from_file()
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		_equation_sequence.set_difficulty(String(game_settings.get("selected_difficulty")))
	_build_cenario()
	_build_player()
	_build_blocos()
	_build_power_ups()
	_build_cones()
	_build_power_up_effect_controller()
	# _build_hud()
	_setup_camera()
	_build_audio()
	
	game_over.connect(hud.on_game_over)
	restart_game.connect(hud.on_restart_game)
	score_event.connect(hud.on_score_change)
	lives_event.connect(hud.on_lives_change)
	hud.pause_event.connect(_on_hud_pause_event)
	hud.restart_event.connect(_restart)
	hud.start_screen_event.connect(_on_hud_start_screen_event)
	hud.quit_event.connect(_on_hud_quit_event)
	_blocos.answer_selected.connect(_on_blocos_answer_selected)
	_power_ups.power_up_collected.connect(_on_power_up_collected)
	_cones.cone_hit.connect(_on_cone_hit)
	power_up_slots_event.connect(hud.on_power_up_slots_change)
	_restart()


func _setup_camera() -> void:
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 4.0, 15.0)
	add_child(_camera)
	_camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	_camera.current = true
	_camera_base_position = _camera.position


func _process(delta: float) -> void:
	if _is_game_over or _is_paused:
		return

	_player.tick(delta)
	_power_up_effects.tick(delta)
	_cenario.tick(delta)
	_blocos.tick(delta, _player.get_runner_position())
	_power_ups.tick(delta, _player.get_runner_position())
	_cones.tick(
		delta,
		_player.get_runner_position(),
		_blocos.get_active_row_z_positions(),
		_blocos.get_distance_to_next_spawn()
	)
	_update_world_speed(delta)
	_update_camera_shake(delta)


func _update_world_speed(_delta: float) -> void:
	var speed_multiplier := 1.0
	if _power_up_effects:
		speed_multiplier = _power_up_effects.get_world_speed_multiplier()
	var target_speed := (BASE_WORLD_SPEED + _score * WORLD_SPEED_PER_SCORE) * speed_multiplier
	if is_equal_approx(world_speed, target_speed):
		return

	world_speed = target_speed
	_cenario.world_speed = world_speed
	_blocos.world_speed = world_speed
	_power_ups.world_speed = world_speed
	_cones.world_speed = world_speed


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_LEFT, KEY_A:
			if not _is_game_over and not _is_paused:
				_player.change_lane(-1)
				get_tree().root.set_input_as_handled()
		KEY_RIGHT, KEY_D:
			if not _is_game_over and not _is_paused:
				_player.change_lane(1)
				get_tree().root.set_input_as_handled()
		KEY_SPACE:
			if not _is_game_over and not _is_paused:
				_player.jump()
				get_tree().root.set_input_as_handled()
		KEY_1:
			if not _is_game_over and not _is_paused:
				_use_power_up_slot(0)
				get_tree().root.set_input_as_handled()
		KEY_2:
			if not _is_game_over and not _is_paused:
				_use_power_up_slot(1)
				get_tree().root.set_input_as_handled()
		KEY_3:
			if not _is_game_over and not _is_paused:
				_use_power_up_slot(2)
				get_tree().root.set_input_as_handled()
		KEY_R:
			if _is_game_over:
				_restart()


func _build_cenario() -> void:
	_cenario = RunnerScenario.new()
	_cenario.world_speed = world_speed
	_cenario.lane_width = LANE_WIDTH
	_cenario.floor_back_z = FLOOR_BACK_Z
	_cenario.floor_front_z = FLOOR_FRONT_Z
	add_child(_cenario)
	_cenario.setup()


func _build_player() -> void:
	_player = preload("res://scenes/player.tscn").instantiate()
	_player.player_z = 8.5
	add_child(_player)
	_player.setup(_lane_positions, 1)


func _build_blocos() -> void:
	_blocos = RunnerBlocos.new()
	_blocos.world_speed = world_speed
	_blocos.floor_back_z = FLOOR_BACK_Z
	_blocos.floor_front_z = FLOOR_FRONT_Z
	add_child(_blocos)
	_blocos.setup(_lane_positions)


func _build_power_ups() -> void:
	_power_ups = RunnerPowerUps.new()
	_power_ups.world_speed = BASE_WORLD_SPEED
	_power_ups.floor_back_z = FLOOR_BACK_Z
	_power_ups.floor_front_z = FLOOR_FRONT_Z
	add_child(_power_ups)
	_power_ups.setup(_lane_positions)


func _build_cones() -> void:
	_cones = RunnerCones.new()
	_cones.world_speed = BASE_WORLD_SPEED
	_cones.floor_back_z = FLOOR_BACK_Z
	_cones.floor_front_z = FLOOR_FRONT_Z
	add_child(_cones)
	_cones.setup(_lane_positions)


func _build_power_up_effect_controller() -> void:
	_power_up_effects = RunnerPowerUpEffectController.new()
	add_child(_power_up_effects)
	_power_up_effects.setup(_player, _blocos, POWER_UP_CONFIG, _max_lives, _lives)
	_power_up_effects.setup(_player, _blocos, POWER_UP_CONFIG, _max_lives, _lives)
	_power_up_effects.lives_changed.connect(_on_power_up_lives_changed)
	_power_up_effects.power_up_slot_changed.connect(_on_power_up_slot_changed)
	_power_up_effects.power_up_slot_changed.connect(hud.on_power_up_slot_active_changed)


# func _build_hud() -> void:
# 	_hud = RunnerHud.new()
# 	add_child(_hud)
# 	_hud.setup(hud_sentences)


func _build_audio() -> void:
	_snd_game = AudioStreamPlayer.new()
	_snd_game.stream = load("res://assets/sounds/game_sound.wav")
	add_child(_snd_game)
	_snd_game.finished.connect(_snd_game.play)

	_snd_lose = AudioStreamPlayer.new()
	_snd_lose.stream = load("res://assets/sounds/losing_sound.wav")
	add_child(_snd_lose)

	_snd_punch = AudioStreamPlayer.new()
	_snd_punch.stream = load("res://assets/sounds/punch_sound.wav")
	add_child(_snd_punch)

	_snd_correct = AudioStreamPlayer.new()
	_snd_correct.stream = load("res://assets/sounds/bonus_sound.wav")
	add_child(_snd_correct)

	_snd_wrong = AudioStreamPlayer.new()
	_snd_wrong.stream = load("res://assets/sounds/punch_sound.wav")
	add_child(_snd_wrong)

	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		game_settings.call("apply_music_volume", _snd_game)
		game_settings.call("apply_sfx_volume", _snd_lose)
		game_settings.call("apply_sfx_volume", _snd_punch)
		game_settings.call("apply_sfx_volume", _snd_correct)
		game_settings.call("apply_sfx_volume", _snd_wrong)


func _restart() -> void:
	_game_over_sequence_id += 1
	_score = 0.0
	_max_lives = DifficultySettings.get_max_lives(_resolve_current_difficulty())
	world_speed = BASE_WORLD_SPEED
	_cenario.world_speed = world_speed
	_blocos.world_speed = world_speed
	_power_ups.world_speed = world_speed
	_cones.world_speed = world_speed
	_shake_time_left = 0.0
	if _camera:
		_camera.position = _camera_base_position
	var current_difficulty := _resolve_current_difficulty()
	_max_lives = int(DIFFICULTY_LIVES.get(current_difficulty, DEFAULT_MAX_LIVES))
	_lives = _max_lives
	_power_up_effects.max_lives = _max_lives
	_cones.enabled = current_difficulty != DIFFICULTY_WITHOUT_CONES
	hud.set_max_lives(_max_lives)
	_is_game_over = false
	if _is_paused:
		_resume()
	_player.reset(1)
	_blocos.reset()
	_power_ups.reset()
	_cones.reset()
	_power_up_effects.max_lives = _max_lives
	_power_up_effects.reset(_lives)
	hud.set_max_lives(_max_lives)
	for i in range(POWER_UP_SLOT_COUNT):
		_power_up_slots[i] = ""
	power_up_slots_event.emit(_power_up_slots.duplicate())
	# _hud.hide_game_over()
	# _hud.update_score(0)
	if _snd_lose:
		_snd_lose.stop()
	if _snd_game:
		_snd_game.play()
	
	restart_game.emit()
	score_event.emit(int(_score))
	lives_event.emit(_lives)
	_set_active_equation(_equation_sequence.start(EQUATION_QUEUE_SIZE))


func _end_game() -> void:
	if _is_paused:
		_resume()
	_is_game_over = true
	_game_over_sequence_id += 1
	var sequence_id := _game_over_sequence_id
	var player_record := get_node_or_null("/root/PlayerRecord")
	if player_record:
		player_record.call("update_high_score", int(_score))
	_snd_game.stop()
	_snd_punch.stop()
	_snd_correct.stop()
	_snd_wrong.stop()
	_snd_lose.play()
	_player.die()
	var death_delay := maxf(MIN_GAME_OVER_DELAY, _player.get_death_animation_duration())
	hud.show_death_fade(death_delay)
	await get_tree().create_timer(death_delay).timeout
	if sequence_id != _game_over_sequence_id:
		return
	game_over.emit(int(_score))
	_submit_online_score()


func _on_hud_pause_event() -> void:
	if _is_game_over:
		return

	if _is_paused:
		_resume()
	else:
		_pause()


func _on_hud_quit_event() -> void:
	get_tree().quit()


func _on_hud_start_screen_event() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")


func _pause() -> void:
	_is_paused = true
	hud.on_pause()
	_snd_game.stop()
	_snd_punch.play()


func _resume() -> void:
	_is_paused = false
	hud.on_resume()
	_snd_lose.stop()
	_snd_game.play()


func _on_blocos_answer_selected(is_correct: bool, _selected_answer: int) -> void:
	if is_correct:
		_score += _power_up_effects.get_score_multiplier()
		score_event.emit(int(_score))
		_snd_correct.play()
	else:
		if _lose_life():
			return

	hud.show_feedback(is_correct)
	_set_active_equation(_equation_sequence.advance())

func _set_active_equation(equation: Dictionary) -> void:
	hud.show_equation(equation)
	_blocos.set_equation(equation)


func _on_power_up_collected(type: String) -> void:
	var empty_idx := _power_up_slots.find("")
	if empty_idx >= 0:
		_power_up_slots[empty_idx] = type
	else:
		_power_up_slots[RESERVE_POWER_UP_SLOT] = type
	power_up_slots_event.emit(_power_up_slots.duplicate())


func _on_cone_hit() -> void:
	if _is_game_over:
		return
	if _lose_life():
		return
	hud.show_feedback(false)


func _lose_life() -> bool:
	_lives = maxi(_lives - 1, 0)
	_power_up_effects.set_current_lives(_lives)
	if _lives <= 0 and _power_up_effects.consume_revive_if_available(_lives):
		_lives = 1
		_power_up_effects.set_current_lives(_lives)
	lives_event.emit(_lives)
	_play_life_lost_reaction()
	if _lives <= 0:
		_is_game_over = true
		_end_game_after_life_lost_reaction()
		return true

	return false


func _play_life_lost_reaction() -> void:
	_player.take_damage()
	_start_camera_shake(0.28, 0.18)
	_snd_wrong.play()


func _end_game_after_life_lost_reaction() -> void:
	var sequence_id := _game_over_sequence_id
	await get_tree().create_timer(LIFE_LOST_REACTION_DELAY).timeout
	if sequence_id != _game_over_sequence_id:
		return
	_end_game()


func _start_camera_shake(duration: float, strength: float) -> void:
	_shake_duration = minf(duration, 2.0)
	_shake_time_left = _shake_duration
	_shake_strength = strength


func _update_camera_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_time_left <= 0.0:
		_camera.position = _camera_base_position
		return

	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var progress := _shake_time_left / _shake_duration
	var strength := _shake_strength * progress
	_camera.position = _camera_base_position + Vector3(
		randf_range(-strength, strength),
		randf_range(-strength, strength),
		0.0
	)


func _on_power_up_lives_changed(lives: int) -> void:
	_lives = clampi(lives, 0, _max_lives)
	_lives = clampi(lives, 0, _max_lives)
	lives_event.emit(_lives)


func _resolve_current_difficulty() -> String:
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		return String(game_settings.get("selected_difficulty"))
	return "easy"


func _use_power_up_slot(slot: int) -> void:
	if slot < 0 or slot >= ACTIVATABLE_POWER_UP_SLOT_COUNT:
		return
	if _power_up_effects.is_slot_active(slot):
		return
	var type := _power_up_slots[slot]
	if type == "":
		return
	if not _power_up_effects.activate(type, slot, _lives):
		return
	_power_ups.spawn_use_effect(type, _player.get_runner_position())
	power_up_used.emit(type, slot)


func _on_power_up_slot_changed(slot: int, _type: String, _remaining: float, _duration: float, active: bool) -> void:
	if active:
		return
	if slot < 0 or slot >= ACTIVATABLE_POWER_UP_SLOT_COUNT:
		return
	_power_up_slots[slot] = _power_up_slots[RESERVE_POWER_UP_SLOT]
	_power_up_slots[RESERVE_POWER_UP_SLOT] = ""
	power_up_slots_event.emit(_power_up_slots.duplicate())

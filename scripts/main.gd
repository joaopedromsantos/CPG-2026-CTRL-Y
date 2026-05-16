extends Node3D

@export var hud_sentences: Array[String] = [
	"Frase 1",
	"Frase 2",
	"Frase 3",
]

const LANE_WIDTH := 2.8
const WORLD_SPEED := 8.0
const FLOOR_BACK_Z := -18.0
const FLOOR_FRONT_Z := 11.6

var _lane_positions: Array[float] = [
	-LANE_WIDTH,
	0.0,
	LANE_WIDTH,
]

var _score := 0.0
var _is_game_over := false

var _player: RunnerPlayer
var _hud: RunnerHud
var _cenario: RunnerScenario
var _blocos: RunnerBlocos


func _ready() -> void:
	_build_cenario()
	_build_player()
	_build_blocos()
	_build_hud()
	_setup_camera()
	_restart()


func _setup_camera() -> void:
	var camera = Camera3D.new()
	camera.position = Vector3(0, 4.0, 15.0)
	camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	add_child(camera)
	camera.current = true


func _process(delta: float) -> void:
	if _is_game_over:
		return

	_player.tick(delta)
	_cenario.tick(delta)
	_blocos.tick(delta, _player.get_runner_position())
	_update_score(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_LEFT, KEY_A:
			if not _is_game_over:
				_player.change_lane(-1)
				get_tree().root.set_input_as_handled()
		KEY_RIGHT, KEY_D:
			if not _is_game_over:
				_player.change_lane(1)
				get_tree().root.set_input_as_handled()
		KEY_SPACE:
			if not _is_game_over:
				_player.jump()
				get_tree().root.set_input_as_handled()
		KEY_R:
			if _is_game_over:
				_restart()


func _build_cenario() -> void:
	_cenario = RunnerScenario.new()
	_cenario.world_speed = WORLD_SPEED
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
	_blocos.world_speed = WORLD_SPEED
	_blocos.floor_back_z = FLOOR_BACK_Z
	_blocos.floor_front_z = FLOOR_FRONT_Z
	_blocos.player_hit.connect(_end_game)
	add_child(_blocos)
	_blocos.setup(_lane_positions)


func _build_hud() -> void:
	_hud = RunnerHud.new()
	add_child(_hud)
	_hud.setup(hud_sentences)


func _restart() -> void:
	_score = 0.0
	_is_game_over = false
	_player.reset(1)
	_blocos.reset()
	_hud.hide_game_over()
	_hud.update_score(0)


func _end_game() -> void:
	_is_game_over = true
	_player.die()
	_hud.show_game_over()


func _update_score(delta: float) -> void:
	_score += delta * 10.0
	_hud.update_score(int(_score))

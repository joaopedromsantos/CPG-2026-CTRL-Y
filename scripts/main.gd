extends Node3D

@export var hud_sentences: Array[String] = [
	"Frase 1",
	"Frase 2",
	"Frase 3",
]

const PLAYER_SCENE := preload("res://assets/player/UAL1_Standard.glb")

const LANE_COUNT := 3
const LANE_WIDTH := 2.8
const PLAYER_Z := 5.8
const PLAYER_SCALE := Vector3(0.85, 0.85, 0.85)
const PLAYER_Y := 0.0
const LANE_CHANGE_SPEED := 12.0
const WORLD_SPEED := 8.0
const OBSTACLE_SPAWN_TIME := 1.05
const FLOOR_TILE_SIZE := 1.4
const FLOOR_ROWS := 18
const FLOOR_COLS := 9
const FLOOR_BACK_Z := -18.0
const FLOOR_FRONT_Z := 11.6

var _lane_positions: Array[float] = []
var _current_lane := 1
var _target_x := 0.0
var _spawn_timer := 0.0
var _score := 0.0
var _is_game_over := false
var _rng := RandomNumberGenerator.new()

var _player: Node3D
var _hud: Label
var _game_over_label: Label
var _obstacles: Array[MeshInstance3D] = []
var _floor_tiles: Array[MeshInstance3D] = []
var _lane_markers: Array[MeshInstance3D] = []

var _mat_obstacle: StandardMaterial3D
var _mat_floor_light: StandardMaterial3D
var _mat_floor_dark: StandardMaterial3D
var _mat_lane: StandardMaterial3D
var _mat_fallback_player: StandardMaterial3D


func _ready() -> void:
	_rng.randomize()
	_build_materials()
	_build_lanes()
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	_restart()


func _process(delta: float) -> void:
	if _is_game_over:
		return

	_move_player(delta)
	_animate_player(delta)
	_move_world(delta)
	_update_obstacles(delta)
	_update_score(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_LEFT, KEY_A:
			_change_lane(-1)
		KEY_RIGHT, KEY_D:
			_change_lane(1)
		KEY_R:
			if _is_game_over:
				_restart()


func _build_materials() -> void:
	_mat_obstacle = _make_material(Color(0.9, 0.12, 0.08), 0.35, 0.0)
	_mat_floor_light = _make_material(Color(0.68, 0.72, 0.68), 0.7, 0.0)
	_mat_floor_dark = _make_material(Color(0.14, 0.17, 0.2), 0.75, 0.0)
	_mat_lane = _make_material(Color(1.0, 1.0, 1.0, 0.8), 0.55, 0.0)
	_mat_fallback_player = _make_material(Color(0.15, 0.55, 1.0), 0.18, 0.35)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _build_lanes() -> void:
	_lane_positions = [
		-LANE_WIDTH,
		0.0,
		LANE_WIDTH,
	]


func _build_world() -> void:
	var world := Node3D.new()
	world.name = "World"
	add_child(world)

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(FLOOR_TILE_SIZE, 0.06, FLOOR_TILE_SIZE)

	var start_x := -float(FLOOR_COLS - 1) * FLOOR_TILE_SIZE * 0.5
	for row in FLOOR_ROWS:
		for col in FLOOR_COLS:
			var tile := MeshInstance3D.new()
			tile.mesh = floor_mesh
			tile.material_override = _mat_floor_dark if (row + col) % 2 == 0 else _mat_floor_light
			tile.position = Vector3(
				start_x + col * FLOOR_TILE_SIZE,
				-0.06,
				FLOOR_BACK_Z + row * FLOOR_TILE_SIZE
			)
			world.add_child(tile)
			_floor_tiles.append(tile)

	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.08, 0.05, 0.95)
	for side in 2:
		var x := -LANE_WIDTH * 0.5 if side == 0 else LANE_WIDTH * 0.5
		for index in 10:
			var marker := MeshInstance3D.new()
			marker.mesh = marker_mesh
			marker.material_override = _mat_lane
			marker.position = Vector3(x, 0.03, FLOOR_BACK_Z + index * 2.6)
			world.add_child(marker)
			_lane_markers.append(marker)


func _build_player() -> void:
	_player = PLAYER_SCENE.instantiate() as Node3D
	if _player == null:
		_player = _make_fallback_player()

	_player.name = "Player"
	_player.scale = PLAYER_SCALE
	_player.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_player.position = Vector3(_lane_positions[_current_lane], PLAYER_Y, PLAYER_Z)
	add_child(_player)
	_play_running_animation(_player)


func _make_fallback_player() -> Node3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1

	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = _mat_fallback_player
	mesh.position.y = 0.55
	return mesh


func _play_running_animation(root: Node) -> void:
	for child in root.get_children():
		if child is AnimationPlayer:
			var animation_player := child as AnimationPlayer
			var animations := animation_player.get_animation_list()
			if animations.is_empty():
				continue

			var selected := animations[0]
			for animation_name in animations:
				var lower_name := String(animation_name).to_lower()
				if lower_name.contains("run") or lower_name.contains("walk"):
					selected = animation_name
					break

			animation_player.play(selected)
			return

		_play_running_animation(child)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 6.4, 11.0)
	camera.rotation_degrees = Vector3(-56.0, 0.0, 0.0)
	camera.fov = 55.0
	camera.current = true
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.light_energy = 2.6
	add_child(light)

	var ambient := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.1, 0.13)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.7)
	environment.ambient_light_energy = 0.65
	ambient.environment = environment
	add_child(ambient)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var top_bar := ColorRect.new()
	top_bar.color = Color(0.02, 0.025, 0.03, 0.72)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 112.0
	canvas.add_child(top_bar)

	_hud = Label.new()
	_hud.position = Vector2(18.0, 14.0)
	_hud.add_theme_font_size_override("font_size", 28)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hud.add_theme_constant_override("shadow_offset_x", 2)
	_hud.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(_hud)

	var sentence_box := VBoxContainer.new()
	sentence_box.anchor_left = 0.38
	sentence_box.anchor_right = 1.0
	sentence_box.offset_top = 12.0
	sentence_box.offset_right = -18.0
	sentence_box.offset_bottom = 104.0
	sentence_box.add_theme_constant_override("separation", 4)
	canvas.add_child(sentence_box)

	for sentence in hud_sentences:
		var label := Label.new()
		label.text = sentence
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		sentence_box.add_child(label)

	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_game_over_label.anchor_right = 1.0
	_game_over_label.anchor_bottom = 1.0
	_game_over_label.offset_top = -40.0
	_game_over_label.add_theme_font_size_override("font_size", 34)
	_game_over_label.add_theme_color_override("font_color", Color.WHITE)
	_game_over_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_game_over_label.add_theme_constant_override("shadow_offset_x", 3)
	_game_over_label.add_theme_constant_override("shadow_offset_y", 3)
	canvas.add_child(_game_over_label)


func _restart() -> void:
	for obstacle in _obstacles:
		obstacle.queue_free()
	_obstacles.clear()

	_current_lane = 1
	_target_x = _lane_positions[_current_lane]
	_player.position = Vector3(_target_x, PLAYER_Y, PLAYER_Z)
	_player.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_spawn_timer = 0.35
	_score = 0.0
	_is_game_over = false
	_game_over_label.text = ""
	_update_hud()


func _change_lane(direction: int) -> void:
	if _is_game_over:
		return

	_current_lane = clampi(_current_lane + direction, 0, LANE_COUNT - 1)
	_target_x = _lane_positions[_current_lane]


func _move_player(delta: float) -> void:
	var weight := 1.0 - exp(-LANE_CHANGE_SPEED * delta)
	_player.position.x = lerpf(_player.position.x, _target_x, weight)


func _animate_player(delta: float) -> void:
	_player.rotation_degrees.y = 180.0 + sin(Time.get_ticks_msec() * 0.008) * 2.0
	_player.position.y = PLAYER_Y + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.035


func _move_world(delta: float) -> void:
	for tile in _floor_tiles:
		tile.position.z += WORLD_SPEED * delta
		if tile.position.z > FLOOR_FRONT_Z:
			tile.position.z -= FLOOR_ROWS * FLOOR_TILE_SIZE

	for marker in _lane_markers:
		marker.position.z += WORLD_SPEED * delta
		if marker.position.z > FLOOR_FRONT_Z:
			marker.position.z -= 26.0


func _update_obstacles(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_obstacle()
		_spawn_timer = OBSTACLE_SPAWN_TIME

	for obstacle in _obstacles.duplicate():
		obstacle.position.z += WORLD_SPEED * delta
		if obstacle.position.z > FLOOR_FRONT_Z:
			_obstacles.erase(obstacle)
			obstacle.queue_free()
		elif _collides_with_player(obstacle):
			_end_game()


func _spawn_obstacle() -> void:
	var lane := _rng.randi_range(0, LANE_COUNT - 1)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.15, 1.15, 1.15)

	var obstacle := MeshInstance3D.new()
	obstacle.name = "Obstacle"
	obstacle.mesh = mesh
	obstacle.material_override = _mat_obstacle
	obstacle.position = Vector3(_lane_positions[lane], 0.58, FLOOR_BACK_Z)
	add_child(obstacle)
	_obstacles.append(obstacle)


func _collides_with_player(obstacle: MeshInstance3D) -> bool:
	var x_close := absf(obstacle.position.x - _player.position.x) < 0.95
	var z_close := absf(obstacle.position.z - _player.position.z) < 0.95
	return x_close and z_close


func _end_game() -> void:
	_is_game_over = true
	_game_over_label.text = "Fim de jogo\nAperte R para reiniciar"


func _update_score(delta: float) -> void:
	_score += delta * 10.0
	_update_hud()


func _update_hud() -> void:
	_hud.text = "Pontos: %04d" % int(_score)

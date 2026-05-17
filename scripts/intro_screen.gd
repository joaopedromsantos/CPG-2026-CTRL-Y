class_name IntroScreen
extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const ROBOT_SCENE := preload("res://assets/player/Robot.fbx")
const DESIGN_SIZE := Vector2(1408.0, 1152.0)
const FONT_REGULAR := "res://assets/fonts/fredoka/Fredoka_Condensed-Medium.ttf"
const FONT_BOLD := "res://assets/fonts/fredoka/Fredoka_Condensed-Bold.ttf"
const ROBOT_ROTATION_SPEED := 1.8
const ROBOT_IDLE_ANIMATION := "RobotArmature|Robot_Idle"
const ROBOT_DEATH_ANIMATION := "RobotArmature|Robot_Death"
const ROBOT_IDLE_SWAY_SPEED := 1.8
const ROBOT_IDLE_SWAY_ANGLE := 0.035
const ROBOT_IDLE_BOB_HEIGHT := 0.035
const ROBOT_PUSHBACK_DURATION := 0.62
const ROBOT_PUSHBACK_DISTANCE := 0.42
const ROBOT_PUSHBACK_LEAN := 0.22
const ROBOT_PUSHBACK_SHAKE := 0.035
const ROBOT_ARM_SWING := 0.85
const ROBOT_ARM_BONES := [
	"Shoulder.L",
	"UpperArm.L",
	"LowerArm.L",
	"Shoulder.R",
	"UpperArm.R",
	"LowerArm.R",
]
const PANEL_STAGGER := 0.62
const PANEL_ENTER_DURATION := 0.36
const PANEL_SLIDE_DISTANCE := 42.0
const TYPEWRITER_SPEED := 38.0
const TYPEWRITER_DELAY := 0.20
const ORANGE_GLITCH_DURATION := 0.85
const MONITOR_GLOW_SPEED := 3.0

const CYAN := Color(0.11, 0.91, 0.98)
const CYAN_SOFT := Color(0.11, 0.91, 0.98, 0.55)
const CYAN_DARK := Color(0.04, 0.38, 0.52, 0.72)
const BLUE_BLACK := Color(0.004, 0.018, 0.052)
const PANEL_FILL := Color(0.006, 0.025, 0.075, 0.82)
const ORANGE := Color(1.0, 0.58, 0.13)
const ORANGE_DARK := Color(0.72, 0.34, 0.04)
const METAL := Color(0.58, 0.67, 0.70)
const DARK_METAL := Color(0.07, 0.12, 0.18)
const YELLOW := Color(0.96, 0.60, 0.10)
const YELLOW_LIGHT := Color(1.0, 0.78, 0.18)
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)

var _font_regular: Font
var _font_bold: Font
var _stars: Array[Vector2] = []
var _sparks: Array[Vector2] = []
var _robot_viewport_container: SubViewportContainer
var _robot_viewport: SubViewport
var _robot: Node3D
var _robot_animation: AnimationPlayer
var _robot_skeleton: Skeleton3D
var _robot_base_position := Vector3.ZERO
var _robot_pushback_time_left := 0.0
var _robot_click_count := 0
var _robot_is_dead := false
var _robot_arm_base_rotations: Dictionary = {}
var _intro_started_at_msec := 0
var _menu_audio: AudioStreamPlayer


func _ready() -> void:
	_intro_started_at_msec = Time.get_ticks_msec()
	_font_regular = load(FONT_REGULAR)
	_font_bold = load(FONT_BOLD)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	_build_star_field()
	_build_robot_viewport()
	_layout_robot_viewport()
	_play_menu_music()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_robot_viewport()
		queue_redraw()


func _exit_tree() -> void:
	_stop_menu_music()


func _stop_menu_music() -> void:
	if _menu_audio:
		_menu_audio.stop()
		if _menu_audio.finished.is_connected(_menu_audio.play):
			_menu_audio.finished.disconnect(_menu_audio.play)
		_menu_audio.stream = null


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		get_tree().root.set_input_as_handled()
		_stop_menu_music()
		get_tree().change_scene_to_file(GAME_SCENE)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _is_robot_clicked(get_global_mouse_position()):
			accept_event()
			_on_robot_clicked()


func _process(delta: float) -> void:
	if _robot == null:
		return
	var rotation_direction := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		rotation_direction -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		rotation_direction += 1.0
	if not is_zero_approx(rotation_direction):
		_robot.rotate_y(rotation_direction * ROBOT_ROTATION_SPEED * delta)
	if _robot_is_dead:
		queue_redraw()
		return
	if _robot_pushback_time_left > 0.0:
		_robot_pushback_time_left = maxf(_robot_pushback_time_left - delta, 0.0)
	_update_robot_idle_sway()
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := Vector2(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	draw_set_transform(Vector2.ZERO, 0.0, scale)
	_draw_scene()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _build_star_field() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 80717
	for i in 95:
		_stars.append(Vector2(rng.randf_range(0.0, DESIGN_SIZE.x), rng.randf_range(0.0, 700.0)))
	for i in 130:
		_sparks.append(Vector2(rng.randf_range(0.0, DESIGN_SIZE.x), rng.randf_range(510.0, 700.0)))


func _play_menu_music() -> void:
	_menu_audio = AudioStreamPlayer.new()
	_menu_audio.stream = load("res://assets/sounds/menu_sound.wav")
	add_child(_menu_audio)
	_menu_audio.finished.connect(_menu_audio.play)
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings:
		game_settings.call("apply_music_volume", _menu_audio)
	_menu_audio.play()


func _build_robot_viewport() -> void:
	_robot_viewport_container = SubViewportContainer.new()
	_robot_viewport_container.name = "GameplayRobotPreview"
	_robot_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_robot_viewport_container.stretch = false
	add_child(_robot_viewport_container)

	_robot_viewport = SubViewport.new()
	_robot_viewport.transparent_bg = true
	_robot_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_robot_viewport_container.add_child(_robot_viewport)

	var world := Node3D.new()
	_robot_viewport.add_child(world)

	_robot = ROBOT_SCENE.instantiate()
	_robot.name = "Robot"
	_robot.scale = Vector3.ONE * 0.4
	_robot.rotation_degrees = Vector3(0.0, -28.0, 0.0)
	_robot_base_position = _robot.position
	world.add_child(_robot)
	_setup_robot_idle_animation()
	_setup_robot_arm_animation()

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 3.2
	key_light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 1.5
	fill_light.omni_range = 8.0
	fill_light.position = Vector3(-2.0, 2.6, 3.0)
	world.add_child(fill_light)

	var camera := Camera3D.new()
	camera.look_at_from_position(Vector3(0.0, 1.35, 5.8), Vector3(0.0, 0.9, 0.0), Vector3.UP)
	camera.fov = 31.0
	camera.current = true
	world.add_child(camera)


func _setup_robot_idle_animation() -> void:
	_robot_animation = _find_animation_player(_robot)
	if _robot_animation == null or not _robot_animation.has_animation(ROBOT_IDLE_ANIMATION):
		return
	_robot_animation.play(ROBOT_IDLE_ANIMATION)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _setup_robot_arm_animation() -> void:
	_robot_skeleton = _find_skeleton(_robot)
	if _robot_skeleton == null:
		return
	_robot_arm_base_rotations.clear()
	for bone_name in ROBOT_ARM_BONES:
		var bone_index := _robot_skeleton.find_bone(bone_name)
		if bone_index >= 0:
			_robot_arm_base_rotations[bone_name] = _robot_skeleton.get_bone_pose_rotation(bone_index)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _update_robot_idle_sway() -> void:
	if _robot_animation and not _robot_animation.is_playing():
		_robot_animation.play(ROBOT_IDLE_ANIMATION)
	var time := Time.get_ticks_msec() * 0.001
	var sway := sin(time * ROBOT_IDLE_SWAY_SPEED)
	var bob := sin(time * ROBOT_IDLE_SWAY_SPEED * 2.0)
	var pushback := _robot_pushback_amount()
	var shake := sin(time * 65.0) * ROBOT_PUSHBACK_SHAKE * pushback
	_robot.rotation.x = sway * ROBOT_IDLE_SWAY_ANGLE * 0.45 - pushback * ROBOT_PUSHBACK_LEAN
	_robot.rotation.z = sway * ROBOT_IDLE_SWAY_ANGLE + shake
	_robot.position = _robot_base_position + Vector3(shake * 0.25, bob * ROBOT_IDLE_BOB_HEIGHT, -pushback * ROBOT_PUSHBACK_DISTANCE)
	_update_robot_arm_pushback(pushback, time)


func _update_robot_arm_pushback(pushback: float, time: float) -> void:
	if _robot_skeleton == null or _robot_arm_base_rotations.is_empty():
		return
	if pushback <= 0.0:
		return

	var flutter := sin(time * 38.0) * 0.18 * pushback
	for bone_name in _robot_arm_base_rotations.keys():
		var bone_index := _robot_skeleton.find_bone(String(bone_name))
		if bone_index < 0:
			continue
		var side := -1.0 if String(bone_name).ends_with(".L") else 1.0
		var base_rotation := _robot_arm_base_rotations[bone_name] as Quaternion
		var lift := Quaternion(Vector3.RIGHT, (-ROBOT_ARM_SWING + flutter) * pushback)
		var spread := Quaternion(Vector3.FORWARD, side * (0.42 + flutter) * pushback)
		var twist := Quaternion(Vector3.UP, side * 0.18 * pushback)
		if String(bone_name).begins_with("LowerArm"):
			lift = Quaternion(Vector3.RIGHT, (-ROBOT_ARM_SWING * 0.45 + flutter) * pushback)
			spread = Quaternion(Vector3.FORWARD, side * 0.20 * pushback)
		_robot_skeleton.set_bone_pose_rotation(bone_index, base_rotation * spread * lift * twist)


func _play_robot_pushback() -> void:
	_robot_pushback_time_left = ROBOT_PUSHBACK_DURATION


func _on_robot_clicked() -> void:
	if _robot_is_dead:
		return
	_robot_click_count += 1
	if _robot_click_count > 5:
		_play_robot_death()
	else:
		_play_robot_pushback()


func _play_robot_death() -> void:
	_robot_is_dead = true
	_robot_pushback_time_left = 0.0
	_reset_robot_arm_pose()
	_robot.position = _robot_base_position
	_robot.rotation.x = 0.0
	_robot.rotation.z = 0.0
	if _robot_animation and _robot_animation.has_animation(ROBOT_DEATH_ANIMATION):
		_robot_animation.stop()
		_robot_animation.play(ROBOT_DEATH_ANIMATION)


func _reset_robot_arm_pose() -> void:
	if _robot_skeleton == null or _robot_arm_base_rotations.is_empty():
		return
	for bone_name in _robot_arm_base_rotations.keys():
		var bone_index := _robot_skeleton.find_bone(String(bone_name))
		if bone_index >= 0:
			_robot_skeleton.set_bone_pose_rotation(bone_index, _robot_arm_base_rotations[bone_name] as Quaternion)


func _is_robot_clicked(screen_position: Vector2) -> bool:
	if _robot_viewport_container == null:
		return false
	var robot_rect := _robot_viewport_container.get_global_rect()
	return robot_rect.has_point(screen_position)


func _robot_pushback_amount() -> float:
	if _robot_pushback_time_left <= 0.0:
		return 0.0
	var progress := 1.0 - (_robot_pushback_time_left / ROBOT_PUSHBACK_DURATION)
	var impact := sin(clampf(progress, 0.0, 1.0) * PI)
	return pow(impact, 0.55)


func _layout_robot_viewport() -> void:
	if _robot_viewport_container == null or _robot_viewport == null:
		return
	var scale := Vector2(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var robot_rect := Rect2(Vector2(710.0, 330.0), Vector2(620.0, 730.0))
	var pixel_rect := Rect2(robot_rect.position * scale, robot_rect.size * scale)
	_robot_viewport_container.position = pixel_rect.position
	_robot_viewport_container.size = pixel_rect.size
	_robot_viewport.size = Vector2i(maxi(1, int(pixel_rect.size.x)), maxi(1, int(pixel_rect.size.y)))


func _draw_scene() -> void:
	_draw_background()
	_draw_left_panels_animated()
	_draw_monitor()
	_draw_continue_box()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BLUE_BLACK)
	for i in 18:
		var t := float(i) / 17.0
		var color := Color(0.0, 0.06 + t * 0.05, 0.13 + t * 0.12, 0.10)
		draw_rect(Rect2(0, i * 64, DESIGN_SIZE.x, 64), color)
	for star in _stars:
		draw_circle(star, 1.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.65))
	_draw_cross(Vector2(640, 546), 6, CYAN)
	_draw_cross(Vector2(936, 259), 5, CYAN)
	_draw_floor_grid()
	_draw_distant_city()


func _draw_floor_grid() -> void:
	var horizon_y := 690.0
	for i in 18:
		var x := 40.0 + i * 82.0
		draw_line(Vector2(x, DESIGN_SIZE.y), Vector2(660 + (x - 704) * 0.24, horizon_y), CYAN_DARK, 1.4)
	for i in 11:
		var y := horizon_y + pow(float(i) / 10.0, 1.6) * 430.0
		draw_line(Vector2(0, y), Vector2(DESIGN_SIZE.x, y + 8), Color(CYAN.r, CYAN.g, CYAN.b, 0.18), 1.2)
	draw_line(Vector2(0, horizon_y), Vector2(DESIGN_SIZE.x, horizon_y + 4), Color(CYAN.r, CYAN.g, CYAN.b, 0.20), 1.2)


func _draw_distant_city() -> void:
	for p in _sparks:
		draw_rect(Rect2(p, Vector2(2, 2)), Color(CYAN.r, CYAN.g, CYAN.b, 0.70))
	for x in [8, 674, 760, 1322]:
		draw_line(Vector2(x, 500), Vector2(x, 700), Color(CYAN.r, CYAN.g, CYAN.b, 0.32), 1.0)
	for y in [517, 567, 647]:
		draw_line(Vector2(0, y), Vector2(118, y), Color(CYAN.r, CYAN.g, CYAN.b, 0.22), 1.0)
		draw_line(Vector2(664, y), Vector2(832, y), Color(CYAN.r, CYAN.g, CYAN.b, 0.22), 1.0)


func _draw_left_panels_animated() -> void:
	_draw_intro_panel(0, Rect2(36, 66, 568, 160), [
		{"text": "SISTEMA INICIANDO...", "pos": Vector2(76, 131), "font_size": 38, "color": CYAN, "font": _font_bold, "glitch": false},
		{"text": "ERRO DETECTADO.", "pos": Vector2(78, 184), "font_size": 31, "color": ORANGE, "font": _font_bold, "glitch": true},
	])

	_draw_intro_panel(1, Rect2(36, 254, 568, 188), _make_panel_lines([
		"Voc\u00ea \u00e9 RX-07, um rob\u00f4 criado para",
		"resolver problemas matem\u00e1ticos.",
		"Mas algo deu errado na sua",
		"programa\u00e7\u00e3o."
	], Vector2(76, 301), 28, CYAN, _font_regular))

	_draw_intro_panel(2, Rect2(36, 462, 568, 188), _make_panel_lines([
		"Seu n\u00facleo de energia est\u00e1 falhando,",
		"e a \u00fanica forma de continuar",
		"funcionando \u00e9 resolver equa\u00e7\u00f5es",
		"antes que o sistema entre em colapso."
	], Vector2(76, 510), 28, CYAN, _font_regular))

	_draw_intro_panel(3, Rect2(36, 668, 568, 152), _make_panel_lines([
		"Cada c\u00e1lculo correto estabiliza",
		"seus circuitos por mais alguns",
		"segundos."
	], Vector2(76, 716), 28, CYAN, _font_regular))

	_draw_intro_panel(4, Rect2(36, 838, 568, 108), _make_panel_lines([
		"Cada erro aproxima o desligamento",
		"definitivo."
	], Vector2(76, 882), 28, CYAN, _font_regular))

	_draw_intro_panel(5, Rect2(36, 965, 568, 118), [
		{"text": "RESOLVA. SOBREVIVA.", "pos": Vector2(78, 1018), "font_size": 32, "color": ORANGE, "font": _font_bold, "glitch": true},
		{"text": "REPROGRAME SEU DESTINO.", "pos": Vector2(78, 1062), "font_size": 32, "color": ORANGE, "font": _font_bold, "glitch": true},
	])


func _make_panel_lines(lines: Array[String], pos: Vector2, font_size: int, color: Color, font: Font) -> Array:
	var panel_lines := []
	for i in lines.size():
		panel_lines.append({
			"text": lines[i],
			"pos": pos + Vector2(0, i * 39),
			"font_size": font_size,
			"color": color,
			"font": font,
			"glitch": false,
		})
	return panel_lines


func _draw_intro_panel(index: int, rect: Rect2, lines: Array) -> void:
	var elapsed := _intro_elapsed()
	var start_time := index * PANEL_STAGGER
	var enter_progress := clampf((elapsed - start_time) / PANEL_ENTER_DURATION, 0.0, 1.0)
	if enter_progress <= 0.0:
		return

	var eased := _ease_out_cubic(enter_progress)
	var offset := Vector2(-PANEL_SLIDE_DISTANCE * (1.0 - eased), 0.0)
	var alpha := eased
	_draw_panel_alpha(Rect2(rect.position + offset, rect.size), alpha)

	var text_time := maxf(elapsed - start_time - PANEL_ENTER_DURATION - TYPEWRITER_DELAY, 0.0)
	var visible_chars := int(text_time * TYPEWRITER_SPEED)
	for line in lines:
		var text := String(line["text"])
		var visible_text := text.substr(0, mini(text.length(), visible_chars))
		visible_chars = maxi(visible_chars - text.length(), 0)
		if visible_text.is_empty():
			continue
		_draw_intro_text(
			visible_text,
			(line["pos"] as Vector2) + offset,
			int(line["font_size"]),
			line["color"] as Color,
			line["font"] as Font,
			alpha,
			bool(line["glitch"]) and text_time <= ORANGE_GLITCH_DURATION,
			index
		)


func _draw_intro_text(text: String, pos: Vector2, font_size: int, color: Color, font: Font, alpha: float, glitch: bool, panel_index: int) -> void:
	var text_color := _with_alpha(color, alpha)
	if glitch:
		var glitch_seed := int(_intro_elapsed() * 22.0) + panel_index * 13
		if glitch_seed % 5 == 0:
			_draw_text_alpha(text, pos + Vector2(-3, 0), font_size, Color(CYAN.r, CYAN.g, CYAN.b, alpha * 0.58), font)
			_draw_text_alpha(text, pos + Vector2(3, 1), font_size, Color(ORANGE.r, ORANGE.g * 0.72, ORANGE.b, alpha * 0.70), font)
		if glitch_seed % 7 == 0:
			text_color.a *= 0.45
	_draw_text_alpha(text, pos, font_size, text_color, font)


func _draw_panel_alpha(rect: Rect2, alpha: float) -> void:
	var cut := 18.0
	var points := PackedVector2Array([
		Vector2(rect.position.x + cut, rect.position.y),
		Vector2(rect.end.x - 22, rect.position.y + 4),
		Vector2(rect.end.x, rect.position.y + cut),
		Vector2(rect.end.x, rect.end.y - cut),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut),
		Vector2(rect.position.x, rect.position.y + cut),
	])
	draw_colored_polygon(points, _with_alpha(PANEL_FILL, PANEL_FILL.a * alpha))
	draw_polyline(_closed(points), _with_alpha(CYAN, alpha), 3.0)
	draw_line(Vector2(rect.position.x + cut, rect.position.y), Vector2(rect.position.x + 32, rect.position.y), _with_alpha(Color(0.58, 1.0, 1.0), alpha), 3.0)
	draw_line(Vector2(rect.end.x - 42, rect.position.y + 3), Vector2(rect.end.x - 18, rect.position.y + 3), _with_alpha(CYAN_SOFT, CYAN_SOFT.a * alpha), 3.0)


func _draw_text_alpha(text: String, pos: Vector2, font_size: int, color: Color, font: Font) -> void:
	draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _with_alpha(SHADOW, SHADOW.a * color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _intro_elapsed() -> float:
	return maxf(float(Time.get_ticks_msec() - _intro_started_at_msec) * 0.001, 0.0)


func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))


func _draw_left_panels() -> void:
	_draw_panel(Rect2(36, 66, 568, 160))
	_draw_text("SISTEMA INICIANDO...", Vector2(76, 131), 38, CYAN, _font_bold)
	_draw_text("ERRO DETECTADO.", Vector2(78, 184), 31, ORANGE, _font_bold)

	_draw_panel(Rect2(36, 254, 568, 188))
	_draw_text_block([
		"Você é RX-07, um robô criado para",
		"resolver problemas matemáticos.",
		"Mas algo deu errado na sua",
		"programação."
	], Vector2(76, 301), 28, CYAN)

	_draw_panel(Rect2(36, 462, 568, 188))
	_draw_text_block([
		"Seu núcleo de energia está falhando,",
		"e a única forma de continuar",
		"funcionando é resolver equações",
		"antes que o sistema entre em colapso."
	], Vector2(76, 510), 28, CYAN)

	_draw_panel(Rect2(36, 668, 568, 152))
	_draw_text_block([
		"Cada cálculo correto estabiliza",
		"seus circuitos por mais alguns",
		"segundos."
	], Vector2(76, 716), 28, CYAN)

	_draw_panel(Rect2(36, 838, 568, 108))
	_draw_text_block([
		"Cada erro aproxima o desligamento",
		"definitivo."
	], Vector2(76, 882), 28, CYAN)

	_draw_panel(Rect2(36, 965, 568, 118))
	_draw_text("RESOLVA. SOBREVIVA.", Vector2(78, 1018), 32, ORANGE, _font_bold)
	_draw_text("REPROGRAME SEU DESTINO.", Vector2(78, 1062), 32, ORANGE, _font_bold)


func _draw_panel(rect: Rect2) -> void:
	var cut := 18.0
	var points := PackedVector2Array([
		Vector2(rect.position.x + cut, rect.position.y),
		Vector2(rect.end.x - 22, rect.position.y + 4),
		Vector2(rect.end.x, rect.position.y + cut),
		Vector2(rect.end.x, rect.end.y - cut),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut),
		Vector2(rect.position.x, rect.position.y + cut),
	])
	draw_colored_polygon(points, PANEL_FILL)
	draw_polyline(_closed(points), CYAN, 3.0)
	draw_line(Vector2(rect.position.x + cut, rect.position.y), Vector2(rect.position.x + 32, rect.position.y), Color(0.58, 1.0, 1.0), 3.0)
	draw_line(Vector2(rect.end.x - 42, rect.position.y + 3), Vector2(rect.end.x - 18, rect.position.y + 3), CYAN_SOFT, 3.0)


func _draw_continue_box() -> void:
	_draw_panel(Rect2(1086, 42, 288, 128))
	_draw_text("PRESSIONE [ENTER]", Vector2(1118, 98), 26, CYAN, _font_bold)
	_draw_text("PARA CONTINUAR", Vector2(1134, 133), 25, CYAN, _font_bold)


func _draw_monitor() -> void:
	var pulse: float = 0.5 + sin(_intro_elapsed() * MONITOR_GLOW_SPEED) * 0.5
	var blue_glow_alpha: float = lerpf(0.18, 0.52, pulse)
	var screen := PackedVector2Array([
		Vector2(1010, 220), Vector2(1266, 181), Vector2(1291, 352), Vector2(995, 374)
	])
	draw_colored_polygon(screen, Color(0.02, 0.09, 0.18))
	for width in [24.0, 16.0, 9.0]:
		var width_float: float = width
		draw_polyline(_closed(screen), Color(CYAN.r, CYAN.g, CYAN.b, blue_glow_alpha * (width_float / 24.0) * 0.32), width_float)
	draw_polyline(_closed(screen), Color(0.03, 0.28, 0.52), 12)
	var inner := PackedVector2Array([
		Vector2(1049, 259), Vector2(1242, 237), Vector2(1255, 332), Vector2(1041, 344)
	])
	draw_colored_polygon(inner, Color(0.02, 0.03, 0.05))
	for width in [10.0, 6.0]:
		var width_float: float = width
		draw_polyline(_closed(inner), Color(CYAN.r, CYAN.g, CYAN.b, blue_glow_alpha * (width_float / 10.0) * 0.22), width_float)
	_draw_glowing_monitor_text("ERRO DE", Vector2(1087, 289), 29)
	_draw_glowing_monitor_text("PROGRAMAÇÃO", Vector2(1055, 333), 29)


func _draw_glowing_monitor_text(text: String, pos: Vector2, font_size: int) -> void:
	var pulse: float = 0.5 + sin(_intro_elapsed() * MONITOR_GLOW_SPEED) * 0.5
	var glow_alpha: float = lerpf(0.24, 0.72, pulse)
	for radius in [8.0, 5.0, 3.0]:
		var radius_float: float = radius
		var alpha: float = glow_alpha * (radius_float / 8.0) * 0.45
		_draw_text_alpha(text, pos + Vector2(-radius, 0), font_size, Color(ORANGE.r, ORANGE.g, ORANGE.b, alpha), _font_bold)
		_draw_text_alpha(text, pos + Vector2(radius, 0), font_size, Color(ORANGE.r, ORANGE.g, ORANGE.b, alpha), _font_bold)
		_draw_text_alpha(text, pos + Vector2(0, -radius), font_size, Color(ORANGE.r, ORANGE.g, ORANGE.b, alpha), _font_bold)
		_draw_text_alpha(text, pos + Vector2(0, radius), font_size, Color(ORANGE.r, ORANGE.g, ORANGE.b, alpha), _font_bold)
	_draw_text_alpha(text, pos, font_size, Color(1.0, 0.74, 0.24, 1.0), _font_bold)


func _draw_platform() -> void:
	_draw_ellipse(Rect2(646, 810, 570, 244), Color(0.0, 0.0, 0.0, 0.40))
	_draw_ellipse(Rect2(610, 790, 650, 248), Color(0.07, 0.14, 0.19))
	_draw_ellipse(Rect2(640, 813, 590, 185), Color(0.02, 0.05, 0.08))
	draw_arc(Vector2(935, 884), 304, 0.06, TAU - 0.08, 96, CYAN, 22)
	draw_arc(Vector2(935, 884), 258, 0.10, TAU - 0.12, 96, Color(CYAN.r, CYAN.g, CYAN.b, 0.28), 4)
	for i in 18:
		var a := i * TAU / 18.0
		var p := Vector2(935, 884) + Vector2(cos(a) * 278, sin(a) * 84)
		_draw_ellipse(Rect2(p - Vector2(8, 4), Vector2(16, 8)), Color(0.07, 0.55, 0.67), 18)
	for x in [695, 797, 1097, 1190]:
		draw_rect(Rect2(x, 970, 42, 74), DARK_METAL)


func _draw_robot() -> void:
	_draw_arm(Vector2(708, 640), Vector2(585, 633), Vector2(547, 604), false)
	_draw_arm(Vector2(1164, 640), Vector2(1266, 620), Vector2(1341, 594), true)
	_draw_leg(Vector2(940, 760), Vector2(934, 902), false)
	_draw_leg(Vector2(1018, 760), Vector2(1062, 902), true)
	_draw_body()
	_draw_head()


func _draw_head() -> void:
	var head := PackedVector2Array([
		Vector2(882, 389), Vector2(976, 374), Vector2(1082, 388), Vector2(1160, 425),
		Vector2(1163, 566), Vector2(1092, 604), Vector2(961, 615), Vector2(867, 581), Vector2(855, 436)
	])
	draw_colored_polygon(head, YELLOW)
	draw_colored_polygon(PackedVector2Array([Vector2(882, 389), Vector2(976, 374), Vector2(1082, 388), Vector2(1142, 422), Vector2(853, 454)]), YELLOW_LIGHT)
	draw_colored_polygon(PackedVector2Array([Vector2(872, 507), Vector2(1162, 504), Vector2(1160, 565), Vector2(1092, 604), Vector2(961, 615), Vector2(867, 581)]), Color(0.84, 0.43, 0.06))
	draw_rect(Rect2(880, 452, 270, 19), Color(0.35, 0.55, 0.58))
	draw_rect(Rect2(874, 563, 286, 20), Color(0.53, 0.64, 0.66))
	for x in [901, 944, 987, 1030, 1075, 1120]:
		draw_circle(Vector2(x, 463), 4, CYAN)
		draw_circle(Vector2(x, 573), 4, CYAN)
	_draw_eye(Vector2(932, 516), 48)
	_draw_eye(Vector2(1066, 516), 48)
	draw_rect(Rect2(884, 431, 98, 21), DARK_METAL)
	draw_rect(Rect2(1025, 431, 99, 21), DARK_METAL)
	draw_rect(Rect2(894, 434, 76, 6), CYAN_DARK)
	draw_rect(Rect2(1035, 434, 76, 6), CYAN_DARK)


func _draw_eye(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color(0.02, 0.03, 0.05))
	draw_circle(center + Vector2(11, -8), radius * 0.62, Color(0.05, 0.08, 0.13))
	draw_arc(center, radius, 0.1, TAU, 24, Color(0.0, 0.0, 0.0, 0.35), 5)


func _draw_body() -> void:
	draw_rect(Rect2(926, 615, 104, 160), Color(0.83, 0.43, 0.07))
	draw_rect(Rect2(912, 612, 132, 22), DARK_METAL)
	draw_rect(Rect2(908, 742, 140, 26), Color(0.60, 0.64, 0.62))
	draw_rect(Rect2(923, 635, 104, 118), Color(0.93, 0.54, 0.11))
	draw_rect(Rect2(892, 718, 174, 30), Color(0.0, 0.0, 0.0, 0.16))


func _draw_arm(shoulder: Vector2, elbow: Vector2, hand: Vector2, flipped: bool) -> void:
	_draw_segment(shoulder, elbow, 34, YELLOW)
	_draw_joint(shoulder, 29)
	_draw_joint(elbow, 24)
	_draw_segment(elbow, hand, 25, ORANGE_DARK)
	_draw_claw(hand, flipped)


func _draw_segment(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var dir := (b - a).normalized()
	var n := Vector2(-dir.y, dir.x) * width * 0.5
	var points := PackedVector2Array([a + n, b + n, b - n, a - n])
	draw_colored_polygon(points, color)
	draw_polyline(_closed(points), Color(0.18, 0.23, 0.25), 5)


func _draw_joint(pos: Vector2, radius: float) -> void:
	draw_circle(pos, radius, DARK_METAL)
	draw_arc(pos, radius - 8, 0.0, TAU, 36, CYAN, 6)


func _draw_claw(pos: Vector2, flipped: bool) -> void:
	var side := -1.0 if flipped else 1.0
	draw_rect(Rect2(pos.x - 18, pos.y - 22, 36, 44), METAL)
	draw_line(pos, pos + Vector2(44 * side, -36), METAL, 15)
	draw_line(pos, pos + Vector2(42 * side, 36), METAL, 15)
	var top_x := pos.x + (31 * side if not flipped else 49 * side)
	var bottom_x := pos.x + (29 * side if not flipped else 47 * side)
	draw_rect(Rect2(top_x, pos.y - 52, 18, 34), Color(0.70, 0.78, 0.80))
	draw_rect(Rect2(bottom_x, pos.y + 18, 18, 34), Color(0.70, 0.78, 0.80))


func _draw_leg(hip: Vector2, foot: Vector2, right: bool) -> void:
	var knee := Vector2(hip.x + (24 if right else -12), 812)
	_draw_segment(hip, knee, 22, ORANGE_DARK)
	_draw_segment(knee, foot - Vector2(0, 32), 21, YELLOW)
	draw_rect(Rect2(knee.x - 24, knee.y - 8, 48, 24), METAL)
	var boot := PackedVector2Array([
		foot + Vector2(-38, -24), foot + Vector2(22, -27), foot + Vector2(45, 14), foot + Vector2(-31, 20)
	])
	draw_colored_polygon(boot, YELLOW)
	draw_colored_polygon(PackedVector2Array([foot + Vector2(-31, 20), foot + Vector2(45, 14), foot + Vector2(61, 36), foot + Vector2(-17, 42)]), METAL)


func _draw_hanging_arms() -> void:
	_draw_cable(Vector2(825, -20), Vector2(783, 99), Vector2(691, 207))
	_draw_cable(Vector2(1130, -20), Vector2(1214, 128), Vector2(1327, 294))
	_draw_industrial_arm(Vector2(802, 34), Vector2(724, 198), Vector2(792, 345), false)
	_draw_industrial_arm(Vector2(1376, 305), Vector2(1282, 397), Vector2(1295, 517), true)


func _draw_cable(a: Vector2, b: Vector2, c: Vector2) -> void:
	var prev := a
	for i in range(1, 21):
		var t := i / 20.0
		var p := a.lerp(b, t).lerp(b.lerp(c, t), t)
		draw_line(prev, p, Color(0.01, 0.08, 0.15), 5)
		prev = p


func _draw_industrial_arm(a: Vector2, b: Vector2, c: Vector2, flipped: bool) -> void:
	_draw_segment(a, b, 44, YELLOW)
	_draw_segment(b, c, 38, METAL)
	_draw_joint(a, 31)
	_draw_joint(b, 31)
	_draw_claw(c, flipped)


func _draw_text_block(lines: Array[String], pos: Vector2, font_size: int, color: Color) -> void:
	for i in lines.size():
		_draw_text(lines[i], pos + Vector2(0, i * 39), font_size, color, _font_regular)


func _draw_text(text: String, pos: Vector2, font_size: int, color: Color, font: Font) -> void:
	draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_cross(pos: Vector2, radius: float, color: Color) -> void:
	draw_line(pos + Vector2(-radius, 0), pos + Vector2(radius, 0), color, 1.5)
	draw_line(pos + Vector2(0, -radius), pos + Vector2(0, radius), color, 1.5)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed


func _draw_ellipse(rect: Rect2, color: Color, segments := 72) -> void:
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

extends Node2D
@onready var root_control: Control = $CanvasLayer/RootControl
@onready var equation_label: Label = $CanvasLayer/RootControl/TopCenterContainer/EquationLabel
@onready var feedback_label: Label = $CanvasLayer/RootControl/TopCenterContainer/FeedbackLabel

@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/Row/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/Row/ScoreLabel
@onready var hearts_row: HBoxContainer = $CanvasLayer/RootControl/TopRightContainer/Wrapper/LivesContainer/HeartsRow
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton
@onready var pause_screen: PauseScreen = $CanvasLayer/RootControl/PauseScreen
@onready var endgame_overlay: Control = $CanvasLayer/RootControl/EndGameOverlay
@onready var endgame_score_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/ScoreStat/ScoreContent/ScoreValue
@onready var endgame_time_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/TimeStat/TimeContent/TimeValue
@onready var endgame_title_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/Title
@onready var endgame_subtitle_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/Subtitle
@onready var endgame_buttons_row: HBoxContainer = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/ButtonsRow
@onready var slot_labels: Array[Label] = [
	$CanvasLayer/RootControl/BottomCenterContainer/SlotsRow/Slot1/ContentLabel,
	$CanvasLayer/RootControl/BottomCenterContainer/SlotsRow/Slot2/ContentLabel,
	$CanvasLayer/RootControl/BottomCenterContainer/SlotsRow/Slot3/ContentLabel,
	$CanvasLayer/RootControl/BottomCenterContainer/SlotsRow/Slot3/Slot4/ContentLabel,
]


signal pause_event
signal restart_event
signal start_screen_event
signal quit_event

const PLAY_BUTTON_IMAGE = preload("res://assets/hud/play-button.png")
const PAUSE_BUTTON_IMAGE = preload("res://assets/hud/pause-button-hud.png")
const HEART_FULL_TEXTURE = preload("res://assets/hud/heart_full.svg")
const HEART_EMPTY_TEXTURE = preload("res://assets/hud/heart_empty.svg")
enum PowerUpSlotIcon {
	LUPA,
	REVIVE,
	HEART,
	LIGHTNING,
	HOURGLASS,
	DOUBLE,
}
const POWER_UP_SLOT_TEXTURES := {
	PowerUpSlotIcon.LUPA: preload("res://assets/power-ups/slots/lupa.png"),
	PowerUpSlotIcon.REVIVE: preload("res://assets/power-ups/slots/revive.png"),
	PowerUpSlotIcon.HEART: preload("res://assets/power-ups/slots/heart.png"),
	PowerUpSlotIcon.LIGHTNING: preload("res://assets/power-ups/slots/lightning.png"),
	PowerUpSlotIcon.HOURGLASS: preload("res://assets/power-ups/slots/hourglass.png"),
	PowerUpSlotIcon.DOUBLE: preload("res://assets/power-ups/slots/double.png"),
}
const POWER_UP_TYPE_TO_SLOT_ICON := {
	"lupa": PowerUpSlotIcon.LUPA,
	"revive": PowerUpSlotIcon.REVIVE,
	"heart": PowerUpSlotIcon.HEART,
	"lightning": PowerUpSlotIcon.LIGHTNING,
	"hourglass": PowerUpSlotIcon.HOURGLASS,
	"double": PowerUpSlotIcon.DOUBLE,
}
const FEEDBACK_COLOR_CORRECT := Color(0.2, 0.85, 0.3, 1.0)
const FEEDBACK_COLOR_WRONG := Color(0.95, 0.2, 0.2, 1.0)
const ENDGAME_DEFAULT_TITLE := "Você morreu!"
const ENDGAME_DEFAULT_SUBTITLE := "Fim da corrida"
const ENDGAME_NEW_RECORD_TITLE := "🎉 Novo Recorde!"
const ENDGAME_SUBMITTING_SUBTITLE := "Salvando ranking..."
const ENDGAME_DEFAULT_TITLE_COLOR := Color(1, 0.92, 0.26, 1)
const ENDGAME_NEW_RECORD_TITLE_COLOR := Color(1.0, 0.62, 0.95, 1.0)
const SLOT_ACTIVE_BORDER_COLOR := Color(0.2, 0.75, 1.0, 1.0)
const SLOT_ACTIVE_SHADOW_COLOR := Color(0.2, 0.75, 1.0, 0.55)
const SLOT_COUNTDOWN_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SLOT_COUNTDOWN_OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.9)
const SLOT_ICON_ACTIVE_MODULATE := Color(0.35, 0.35, 0.35, 1.0)
const SLOT_ICON_INACTIVE_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const RESERVE_SLOT_INDEX := 3
const DEATH_FADE_TARGET_ALPHA := 0.8

var timer := GameTimer.new()
var _current_equation: Dictionary = {}
var _feedback_tween: Tween
var _death_fade_tween: Tween
var _death_fade_rect: ColorRect
var _last_score := 0
var _last_lives := -1
var _last_power_up_slots: Array = []
var _slot_icon_rects: Array[TextureRect] = []
var _slot_panels: Array[Panel] = []
var _slot_default_styles: Array[StyleBox] = []
var _slot_active_styles: Array[StyleBoxFlat] = []
var _slot_countdown_labels: Array[Label] = []


func _ready() -> void:
	_setup_death_fade()
	_setup_power_up_slot_icons()
	pause_screen.resume_requested.connect(_on_pause_screen_resume_requested)
	pause_screen.restart_requested.connect(_on_pause_screen_restart_requested)
	pause_screen.start_screen_requested.connect(_on_pause_screen_start_screen_requested)
	timer.start_timer()


func _process(delta: float) -> void:
	timer.tick(delta)
	
	cronometer_label.text = timer.formatted_time()
	if Input.is_action_just_pressed("pause"):
		pause_event.emit()
	
func on_game_over(score: int) -> void:
	timer.stop_timer()
	pause_screen.hide_pause()
	_hide_feedback()
	_hide_death_fade()
	endgame_score_label.text = "%d" % [score]
	endgame_time_label.text = timer.formatted_time()
	_reset_endgame_celebration()
	_set_endgame_awaiting_ranking()
	endgame_overlay.visible = true
	pause_button.visible = false
	_connect_ranking_signal()


func _reset_endgame_celebration() -> void:
	if endgame_title_label:
		endgame_title_label.text = ENDGAME_DEFAULT_TITLE
		endgame_title_label.add_theme_color_override("font_color", ENDGAME_DEFAULT_TITLE_COLOR)
	if endgame_subtitle_label:
		endgame_subtitle_label.text = ENDGAME_DEFAULT_SUBTITLE


func _set_endgame_awaiting_ranking() -> void:
	if endgame_subtitle_label:
		endgame_subtitle_label.text = ENDGAME_SUBMITTING_SUBTITLE
	if endgame_buttons_row:
		endgame_buttons_row.visible = false


func _connect_ranking_signal() -> void:
	var ranking_api := get_node_or_null("/root/RankingAPI")
	if ranking_api == null:
		on_score_submission_skipped()
		return
	if not ranking_api.is_connected("score_submitted", _on_score_submitted):
		ranking_api.connect("score_submitted", _on_score_submitted, CONNECT_ONE_SHOT)


func on_score_submission_skipped() -> void:
	_on_score_submitted(false)


func _on_score_submitted(is_new_record: bool) -> void:
	if endgame_subtitle_label:
		endgame_subtitle_label.text = ENDGAME_DEFAULT_SUBTITLE
	if is_new_record and endgame_title_label:
		endgame_title_label.text = ENDGAME_NEW_RECORD_TITLE
		endgame_title_label.add_theme_color_override("font_color", ENDGAME_NEW_RECORD_TITLE_COLOR)
		_play_new_record_animation()
	if endgame_buttons_row:
		endgame_buttons_row.visible = true


func _play_new_record_animation() -> void:
	if endgame_title_label == null:
		return
	endgame_title_label.pivot_offset = endgame_title_label.size * 0.5
	endgame_title_label.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(endgame_title_label, "scale", Vector2(1.25, 1.25), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(endgame_title_label, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func on_pause() -> void:
	timer.stop_timer()
	pause_button.texture_normal = PLAY_BUTTON_IMAGE
	pause_screen.show_pause(_last_score, timer.formatted_time(), maxi(_last_lives, 0), _last_power_up_slots)


func on_resume() -> void:
	timer.start_timer()
	pause_button.texture_normal = PAUSE_BUTTON_IMAGE
	pause_screen.hide_pause()


func on_score_change(score: int) -> void:
	_last_score = score
	score_label.text = "%d" % [score]
	if score <= 0:
		return
	score_label.pivot_offset = score_label.size * 0.5
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func on_lives_change(lives: int) -> void:
	var hearts := hearts_row.get_children()
	var lost := _last_lives != -1 and lives < _last_lives
	for i in range(hearts.size()):
		var heart := hearts[i] as TextureRect
		var should_be_full := i < lives
		var was_full := heart.texture == HEART_FULL_TEXTURE
		heart.texture = HEART_FULL_TEXTURE if should_be_full else HEART_EMPTY_TEXTURE
		if lost and was_full and not should_be_full:
			_play_heart_lost_animation(heart)
	_last_lives = lives


func set_max_lives(max_lives: int) -> void:
	var target := maxi(max_lives, 0)
	var hearts := hearts_row.get_children()
	while hearts.size() > target:
		var extra: Node = hearts.pop_back()
		extra.queue_free()
	while hearts.size() < target:
		var template: TextureRect = null
		if hearts_row.get_child_count() > 0:
			template = hearts_row.get_child(0) as TextureRect
		var new_heart := TextureRect.new()
		new_heart.custom_minimum_size = Vector2(36, 36)
		new_heart.texture = HEART_FULL_TEXTURE
		new_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		new_heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if template:
			new_heart.custom_minimum_size = template.custom_minimum_size
		hearts_row.add_child(new_heart)
		hearts.append(new_heart)


func _play_heart_lost_animation(heart: TextureRect) -> void:
	heart.pivot_offset = heart.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(heart, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _setup_power_up_slot_icons() -> void:
	_slot_icon_rects.clear()
	_slot_panels.clear()
	_slot_default_styles.clear()
	_slot_active_styles.clear()
	_slot_countdown_labels.clear()
	for label in slot_labels:
		label.visible = false
		var panel := label.get_parent() as Panel
		var is_reserve_slot := _slot_panels.size() == RESERVE_SLOT_INDEX
		if is_reserve_slot:
			panel.z_index = 20
		var key_label := panel.get_node_or_null("KeyLabel") as Label
		if key_label:
			key_label.z_index = 10
		_slot_panels.append(panel)
		_slot_default_styles.append(panel.get_theme_stylebox("panel"))
		_slot_active_styles.append(_make_active_slot_style(panel.get_theme_stylebox("panel")))

		var icon := TextureRect.new()
		icon.name = "PowerUpIcon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		if is_reserve_slot:
			icon.offset_left = 4.0
			icon.offset_top = 4.0
			icon.offset_right = -4.0
			icon.offset_bottom = -4.0
		else:
			icon.offset_left = 11.0
			icon.offset_top = 8.0
			icon.offset_right = -11.0
			icon.offset_bottom = -8.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.get_parent().add_child(icon)
		_slot_icon_rects.append(icon)

		var countdown := Label.new()
		countdown.name = "PowerUpCountdown"
		countdown.visible = false
		countdown.set_anchors_preset(Control.PRESET_FULL_RECT)
		countdown.offset_left = 0.0
		countdown.offset_top = 0.0
		countdown.offset_right = 0.0
		countdown.offset_bottom = 0.0
		countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown.add_theme_font_size_override("font_size", 27)
		countdown.add_theme_color_override("font_color", SLOT_COUNTDOWN_FONT_COLOR)
		countdown.add_theme_color_override("font_outline_color", SLOT_COUNTDOWN_OUTLINE_COLOR)
		countdown.add_theme_constant_override("outline_size", 8)
		if label.has_theme_font("font"):
			countdown.add_theme_font_override("font", label.get_theme_font("font"))
		label.get_parent().add_child(countdown)
		_slot_countdown_labels.append(countdown)


func _setup_death_fade() -> void:
	_death_fade_rect = ColorRect.new()
	_death_fade_rect.name = "DeathFade"
	_death_fade_rect.visible = false
	_death_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_death_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_fade_rect.z_index = 90
	root_control.add_child(_death_fade_rect)
	endgame_overlay.z_index = 100


func show_death_fade(duration: float) -> void:
	if _death_fade_tween and _death_fade_tween.is_valid():
		_death_fade_tween.kill()
	_death_fade_rect.visible = true
	_death_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_death_fade_tween = create_tween()
	_death_fade_tween.tween_property(
		_death_fade_rect,
		"color:a",
		DEATH_FADE_TARGET_ALPHA,
		maxf(duration, 0.01)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_death_fade() -> void:
	if _death_fade_tween and _death_fade_tween.is_valid():
		_death_fade_tween.kill()
	if _death_fade_rect:
		_death_fade_rect.visible = false
		_death_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)


func on_power_up_slots_change(slots: Array) -> void:
	_last_power_up_slots = slots.duplicate()
	for i in range(_slot_icon_rects.size()):
		var type := ""
		if i < slots.size():
			type = String(slots[i])
		_slot_icon_rects[i].texture = _power_up_display(type)
		if type == "":
			on_power_up_slot_active_changed(i, "", 0.0, 0.0, false)


func on_power_up_slot_active_changed(slot: int, _type: String, remaining: float, _duration: float, active: bool) -> void:
	if slot < 0 or slot >= _slot_countdown_labels.size():
		return

	_slot_panels[slot].add_theme_stylebox_override(
		"panel",
		_slot_active_styles[slot] if active else _slot_default_styles[slot]
	)
	_slot_countdown_labels[slot].visible = active
	_slot_icon_rects[slot].modulate = SLOT_ICON_ACTIVE_MODULATE if active else SLOT_ICON_INACTIVE_MODULATE
	if active:
		_slot_countdown_labels[slot].text = "%d" % [maxi(0, ceili(remaining))]


func _power_up_display(type: String) -> Texture2D:
	var slot_icon := int(POWER_UP_TYPE_TO_SLOT_ICON.get(type, -1))
	return POWER_UP_SLOT_TEXTURES.get(slot_icon, null) as Texture2D


func _make_active_slot_style(base_style: StyleBox) -> StyleBoxFlat:
	var style := base_style.duplicate(true) as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	style.border_width_left = maxi(style.border_width_left, 4)
	style.border_width_top = maxi(style.border_width_top, 4)
	style.border_width_right = maxi(style.border_width_right, 4)
	style.border_width_bottom = maxi(style.border_width_bottom, 4)
	style.border_color = SLOT_ACTIVE_BORDER_COLOR
	style.shadow_color = SLOT_ACTIVE_SHADOW_COLOR
	style.shadow_size = maxi(style.shadow_size, 8)
	style.shadow_offset = Vector2.ZERO
	return style

func on_restart_game() -> void:
	endgame_overlay.visible = false
	pause_button.visible = true
	pause_button.texture_normal = PAUSE_BUTTON_IMAGE
	_reset_endgame_celebration()
	if endgame_buttons_row:
		endgame_buttons_row.visible = true
	var ranking_api := get_node_or_null("/root/RankingAPI")
	if ranking_api and ranking_api.is_connected("score_submitted", _on_score_submitted):
		ranking_api.disconnect("score_submitted", _on_score_submitted)
	timer.reset_timer()
	timer.start_timer()
	_last_score = 0
	_last_lives = -1
	_last_power_up_slots = []
	show_equation({})
	_hide_feedback()


func show_feedback(is_correct: bool) -> void:
	if is_correct:
		feedback_label.text = "Acertou!"
		feedback_label.add_theme_color_override("font_color", FEEDBACK_COLOR_CORRECT)
	else:
		feedback_label.text = "Errou! ✕"
		feedback_label.add_theme_color_override("font_color", FEEDBACK_COLOR_WRONG)

	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()

	feedback_label.modulate = Color(1, 1, 1, 0)
	feedback_label.scale = Vector2(0.6, 0.6)

	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 1.0, 0.18)
	_feedback_tween.tween_property(feedback_label, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.chain().tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.1)
	_feedback_tween.chain().tween_interval(0.55)
	_feedback_tween.chain().tween_property(feedback_label, "modulate:a", 0.0, 0.35)


func _hide_feedback() -> void:
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()
	feedback_label.text = ""
	feedback_label.modulate = Color(1, 1, 1, 0)


func _on_pause_button_pressed() -> void:
	pause_event.emit()
	pause_button.release_focus()


func _on_pause_screen_resume_requested() -> void:
	pause_event.emit()


func _on_pause_screen_restart_requested() -> void:
	restart_event.emit()


func _on_pause_screen_start_screen_requested() -> void:
	start_screen_event.emit()


func _on_restart_button_pressed() -> void:
	restart_event.emit()


func _on_start_screen_button_pressed() -> void:
	start_screen_event.emit()


func _on_quit_button_pressed() -> void:
	quit_event.emit()


func show_equation(equation: Dictionary) -> void:
	_current_equation = equation
	if _current_equation.is_empty():
		equation_label.text = ""
		return

	equation_label.text = String(_current_equation.get("equation", ""))


func get_current_equation() -> Dictionary:
	return _current_equation


func get_current_options() -> Array:
	return _current_equation.get("queued_options", _current_equation.get("options", []))


func get_current_correct_answers() -> Array:
	return _current_equation.get("correctAnswers", [])

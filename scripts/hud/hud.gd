extends Node2D

const POWER_UP_SLOTS_VIEW_SCRIPT = preload("res://scripts/hud/slots/power_up_slots_view.gd")
const LIVES_VIEW_SCRIPT = preload("res://scripts/hud/lives/lives_view.gd")
const FEEDBACK_VIEW_SCRIPT = preload("res://scripts/hud/feedback/feedback_view.gd")
const DEATH_FADE_VIEW_SCRIPT = preload("res://scripts/hud/death/death_fade_view.gd")
const ENDGAME_VIEW_SCRIPT = preload("res://scripts/hud/endgame/endgame_view.gd")
const OVERCLOCK_VIEW_SCRIPT = preload("res://scripts/hud/overclock/overclock_view.gd")

@onready var root_control: Control = $CanvasLayer/RootControl
@onready var equation_label: Label = $CanvasLayer/RootControl/TopCenterContainer/EquationLabel
@onready var feedback_label: Label = $CanvasLayer/RootControl/TopCenterContainer/FeedbackLabel

@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/Row/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/Row/ScoreLabel
@onready var hearts_row: HBoxContainer = $CanvasLayer/RootControl/TopRightContainer/Wrapper/LivesContainer/HeartsRow
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton
@onready var pause_screen: PauseScreen = $CanvasLayer/RootControl/PauseScreen
@onready var endgame_overlay: Control = $CanvasLayer/RootControl/EndGameOverlay
@onready var overclock_label: Label = $CanvasLayer/RootControl/OverclockLayer/OverclockLabel
@onready var overclock_edges: ColorRect = $CanvasLayer/RootControl/OverclockLayer/EdgesRect
@onready var combo_badge_container: PanelContainer = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ComboBadgeContainer
@onready var combo_badge_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ComboBadgeContainer/ComboBadgeLabel
@onready var endgame_score_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/ScoreStat/ScoreContent/ScoreValue
@onready var endgame_time_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/TimeStat/TimeContent/TimeValue
@onready var endgame_title_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/Title
@onready var endgame_subtitle_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/Subtitle
@onready var endgame_buttons_row: HBoxContainer = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/ButtonsRow
@onready var record_container: Control = $CanvasLayer/RootControl/BottomRightContainer
@onready var record_label: Label = $CanvasLayer/RootControl/BottomRightContainer/RecordPanel/Row/RecordLabel
@onready var countdown_layer: Control = $CanvasLayer/RootControl/CountdownLayer
@onready var countdown_label: Label = $CanvasLayer/RootControl/CountdownLayer/CountdownLabel
@onready var countdown_dim: ColorRect = $CanvasLayer/RootControl/CountdownLayer/DimRect
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
signal countdown_finished

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
var _slots_view := POWER_UP_SLOTS_VIEW_SCRIPT.new()
var _lives_view := LIVES_VIEW_SCRIPT.new()
var _feedback_view := FEEDBACK_VIEW_SCRIPT.new()
var _death_fade_view := DEATH_FADE_VIEW_SCRIPT.new()
var _endgame_view := ENDGAME_VIEW_SCRIPT.new()
var _overclock_view := OVERCLOCK_VIEW_SCRIPT.new()


func _ready() -> void:
	_setup_death_fade()
	_setup_power_up_slot_icons()
	_overclock_view.setup(overclock_label, overclock_edges)
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
	_endgame_view.reset_celebration(
		endgame_title_label,
		endgame_subtitle_label,
		ENDGAME_DEFAULT_TITLE,
		ENDGAME_DEFAULT_SUBTITLE,
		ENDGAME_DEFAULT_TITLE_COLOR
	)


func _set_endgame_awaiting_ranking() -> void:
	_endgame_view.set_awaiting_ranking(endgame_subtitle_label, endgame_buttons_row, ENDGAME_SUBMITTING_SUBTITLE)


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
	_endgame_view.apply_score_submitted(
		is_new_record,
		endgame_title_label,
		endgame_subtitle_label,
		endgame_buttons_row,
		ENDGAME_DEFAULT_SUBTITLE,
		ENDGAME_NEW_RECORD_TITLE,
		ENDGAME_NEW_RECORD_TITLE_COLOR
	)
	if is_new_record and endgame_title_label:
		_play_new_record_animation()


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
	var lost := _last_lives != -1 and lives < _last_lives
	var changed_to_empty := _lives_view.update_lives(hearts_row, lives, HEART_FULL_TEXTURE, HEART_EMPTY_TEXTURE)
	if lost:
		for heart in changed_to_empty:
			_play_heart_lost_animation(heart)
	_last_lives = lives


func set_max_lives(max_lives: int) -> void:
	_lives_view.set_max_lives(hearts_row, max_lives, HEART_FULL_TEXTURE)


func _play_heart_lost_animation(heart: TextureRect) -> void:
	heart.pivot_offset = heart.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(heart, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _setup_power_up_slot_icons() -> void:
	_slots_view.setup(
		slot_labels,
		RESERVE_SLOT_INDEX,
		SLOT_COUNTDOWN_FONT_COLOR,
		SLOT_COUNTDOWN_OUTLINE_COLOR,
		SLOT_ICON_ACTIVE_MODULATE,
		SLOT_ICON_INACTIVE_MODULATE,
		SLOT_ACTIVE_BORDER_COLOR,
		SLOT_ACTIVE_SHADOW_COLOR
	)
	_slot_icon_rects = _slots_view.icon_rects
	_slot_panels = _slots_view.panels
	_slot_default_styles = _slots_view.default_styles
	_slot_active_styles = _slots_view.active_styles
	_slot_countdown_labels = _slots_view.countdown_labels


func _setup_death_fade() -> void:
	_death_fade_rect = _death_fade_view.create_death_fade(root_control, endgame_overlay)


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
	_death_fade_view.hide_death_fade(_death_fade_rect)


func on_power_up_slots_change(slots: Array) -> void:
	_last_power_up_slots = slots.duplicate()
	var inactive_slots := _slots_view.update_slots(slots, POWER_UP_TYPE_TO_SLOT_ICON, POWER_UP_SLOT_TEXTURES)
	for slot in inactive_slots:
		on_power_up_slot_active_changed(slot, "", 0.0, 0.0, false)


func on_power_up_slot_active_changed(slot: int, _type: String, remaining: float, _duration: float, active: bool) -> void:
	_slots_view.update_slot_active(slot, remaining, active)

func on_restart_game() -> void:
	endgame_overlay.visible = false
	pause_screen.hide_pause()
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
	record_container.visible = false
	show_equation({})
	_hide_feedback()
	on_overclock_reset()


const COMBO_BADGE_TIER_TEXT := {1: "X2", 2: "X4", 3: "X6"}
const COMBO_BADGE_TIER_FONT_COLOR := {
	1: Color(1, 0.95, 0.18, 1),
	2: Color(0.2, 0.85, 1.0, 1),
	3: Color(0.85, 0.3, 1.0, 1),
}
const COMBO_BADGE_TIER_OUTLINE := {
	1: Color(0.3, 0.22, 0, 1),
	2: Color(0, 0.15, 0.35, 1),
	3: Color(0.22, 0, 0.32, 1),
}
const COMBO_BADGE_TIER_BORDER := {
	1: Color(1, 0.95, 0.18, 1),
	2: Color(0.2, 0.85, 1.0, 1),
	3: Color(0.85, 0.3, 1.0, 1),
}


func on_overclock_triggered(tier: int) -> void:
	_overclock_view.play(tier)
	_apply_combo_badge(tier)


func on_overclock_reset() -> void:
	_overclock_view.stop()
	_hide_combo_badge()


func _apply_combo_badge(tier: int) -> void:
	if not COMBO_BADGE_TIER_TEXT.has(tier):
		return
	combo_badge_label.text = String(COMBO_BADGE_TIER_TEXT[tier])
	combo_badge_label.add_theme_color_override("font_color", COMBO_BADGE_TIER_FONT_COLOR[tier])
	combo_badge_label.add_theme_color_override("font_outline_color", COMBO_BADGE_TIER_OUTLINE[tier])
	var panel_style := combo_badge_container.get_theme_stylebox("panel")
	if panel_style is StyleBoxFlat:
		var sb := (panel_style as StyleBoxFlat).duplicate() as StyleBoxFlat
		var border_color: Color = COMBO_BADGE_TIER_BORDER[tier]
		sb.border_color = border_color
		sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.5)
		combo_badge_container.add_theme_stylebox_override("panel", sb)
	combo_badge_container.visible = true
	combo_badge_container.pivot_offset = combo_badge_container.size * 0.5
	combo_badge_container.scale = Vector2(0.6, 0.6)
	var tween := combo_badge_container.create_tween()
	tween.tween_property(combo_badge_container, "scale", Vector2(1.15, 1.15), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_badge_container, "scale", Vector2(1.0, 1.0), 0.14) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _hide_combo_badge() -> void:
	combo_badge_container.visible = false
	combo_badge_container.scale = Vector2.ONE


func show_feedback(is_correct: bool) -> void:
	_feedback_view.set_feedback(feedback_label, is_correct, FEEDBACK_COLOR_CORRECT, FEEDBACK_COLOR_WRONG)

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
	_feedback_view.clear_feedback(feedback_label)


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


func set_record_holder(record_name: String, record_score: int) -> void:
	if record_name == "":
		record_container.visible = false
		return
	record_label.text = "%s - %d" % [record_name, record_score]
	record_container.visible = true


func start_countdown() -> void:
	countdown_layer.visible = true
	pause_button.visible = false
	var steps := ["3", "2", "1", "GO!"]
	for i in range(steps.size()):
		var step_text: String = steps[i]
		countdown_label.text = step_text
		countdown_label.modulate = Color(1, 1, 1, 1)
		countdown_label.scale = Vector2(2.0, 2.0)
		countdown_label.pivot_offset = countdown_label.size * 0.5
		var is_go := step_text == "GO!"
		if is_go:
			countdown_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3, 1))
		else:
			countdown_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if is_go:
			tween.tween_property(countdown_label, "modulate:a", 0.0, 0.5) \
				.set_delay(0.25)
			tween.tween_property(countdown_dim, "color:a", 0.0, 0.4) \
				.set_delay(0.1)
		else:
			tween.tween_property(countdown_label, "modulate:a", 0.0, 0.25) \
				.set_delay(0.55)
		var wait_time := 0.5 if is_go else 0.85
		await get_tree().create_timer(wait_time).timeout
	countdown_layer.visible = false
	countdown_dim.color = Color(0, 0, 0, 0.45)
	pause_button.visible = true
	countdown_finished.emit()

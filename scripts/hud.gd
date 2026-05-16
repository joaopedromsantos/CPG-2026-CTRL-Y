extends Node2D
@onready var equation_label: Label = $CanvasLayer/RootControl/TopCenterContainer/EquationLabel
@onready var feedback_label: Label = $CanvasLayer/RootControl/TopCenterContainer/FeedbackLabel

@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/Row/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/Row/ScoreLabel
@onready var hearts_row: HBoxContainer = $CanvasLayer/RootControl/TopRightContainer/Wrapper/LivesContainer/HeartsRow
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton
@onready var endgame_overlay: Control = $CanvasLayer/RootControl/EndGameOverlay
@onready var endgame_score_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/ScoreStat/ScoreContent/ScoreValue
@onready var endgame_time_label: Label = $CanvasLayer/RootControl/EndGameOverlay/Panel/Content/StatsRow/TimeStat/TimeContent/TimeValue


signal pause_event
signal restart_event
signal quit_event

const PLAY_BUTTON_IMAGE = preload("res://assets/hud/play-button.png")
const PAUSE_BUTTON_IMAGE = preload("res://assets/hud/pause-button-hud.png")
const HEART_FULL_TEXTURE = preload("res://assets/hud/heart_full.svg")
const HEART_EMPTY_TEXTURE = preload("res://assets/hud/heart_empty.svg")
const FEEDBACK_COLOR_CORRECT := Color(0.2, 0.85, 0.3, 1.0)
const FEEDBACK_COLOR_WRONG := Color(0.95, 0.2, 0.2, 1.0)

var timer := GameTimer.new()
var _current_equation: Dictionary = {}
var _feedback_tween: Tween
var _last_lives := -1


func _ready() -> void:
	timer.start_timer()


func _process(delta: float) -> void:
	timer.tick(delta)
	
	cronometer_label.text = timer.formatted_time()
	
func on_game_over(score: int) -> void:
	timer.stop_timer()
	_hide_feedback()
	endgame_score_label.text = "%d" % [score]
	endgame_time_label.text = timer.formatted_time()
	endgame_overlay.visible = true
	pause_button.visible = false


func on_pause() -> void:
	timer.stop_timer()
	
	pause_button.texture_normal = PLAY_BUTTON_IMAGE


func on_resume() -> void:
	timer.start_timer()
	
	pause_button.texture_normal = PAUSE_BUTTON_IMAGE


func on_score_change(score: int) -> void:
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


func _play_heart_lost_animation(heart: TextureRect) -> void:
	heart.pivot_offset = heart.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(heart, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)



func on_restart_game() -> void:
	endgame_overlay.visible = false
	pause_button.visible = true
	pause_button.texture_normal = PAUSE_BUTTON_IMAGE
	timer.reset_timer()
	timer.start_timer()
	_last_lives = -1
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


func _on_restart_button_pressed() -> void:
	restart_event.emit()


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


func get_current_answer() -> int:
	return int(_current_equation.get("answer", 0))

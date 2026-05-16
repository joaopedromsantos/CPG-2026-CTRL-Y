extends Node2D
@onready var equation_label: Label = $CanvasLayer/RootControl/TopCenterContainer/EquationLabel
@onready var feedback_label: Label = $CanvasLayer/RootControl/TopCenterContainer/FeedbackLabel

@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/ScoreLabel
@onready var lives_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/LivesContainer/LivesLabel
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton


signal pause_event

const PLAY_BUTTON_IMAGE = preload("res://assets/hud/play-button.png")
const PAUSE_BUTTON_IMAGE = preload("res://assets/hud/pause-button-hud.png")
const FEEDBACK_COLOR_CORRECT := Color(0.2, 0.85, 0.3, 1.0)
const FEEDBACK_COLOR_WRONG := Color(0.95, 0.2, 0.2, 1.0)

var timer := GameTimer.new()
var _current_equation: Dictionary = {}
var _feedback_tween: Tween


func _ready() -> void:
	timer.start_timer()


func _process(delta: float) -> void:
	timer.tick(delta)
	
	cronometer_label.text = timer.formatted_time()
	
func on_game_over() -> void:
	timer.stop_timer()


func on_pause() -> void:
	timer.stop_timer()
	
	pause_button.texture_normal = PLAY_BUTTON_IMAGE


func on_resume() -> void:
	timer.start_timer()
	
	pause_button.texture_normal = PAUSE_BUTTON_IMAGE


func on_score_change(score: int) -> void:
	score_label.text = "%d" % [score]


func on_lives_change(lives: int) -> void:
	lives_label.text = "%d" % [lives]
	
	
func on_restart_game() -> void:
	timer.reset_timer()
	timer.start_timer()
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

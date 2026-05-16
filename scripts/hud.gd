extends Node2D
@onready var equation_label: Label = $CanvasLayer/RootControl/TopCenterContainer/EquationLabel

@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/ScoreLabel
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton


signal pause_event

const PLAY_BUTTON_IMAGE = preload("res://assets/hud/play-button.png")
const PAUSE_BUTTON_IMAGE = preload("res://assets/hud/pause-button-hud.png")

var timer := GameTimer.new()
var _current_equation: Dictionary = {}


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
	
	
func on_restart_game() -> void:
	timer.reset_timer()
	timer.start_timer()
	show_equation({})


func _on_pause_button_pressed() -> void:
	pause_event.emit()


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

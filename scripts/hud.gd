extends Node2D
@onready var cronometer_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/CronometerContainer/CronometerLabel
@onready var score_label: Label = $CanvasLayer/RootControl/TopRightContainer/Wrapper/ScoreContainer/ScoreLabel
@onready var pause_button: TextureButton = $CanvasLayer/RootControl/TopLeftContainer/PauseButton


signal pause_event

const PLAY_BUTTON_IMAGE = preload("res://assets/hud/play-button.png")
const PAUSE_BUTTON_IMAGE = preload("res://assets/hud/pause-button-hud.png")

var timer := GameTimer.new()


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


func _on_pause_button_pressed() -> void:
	pause_event.emit()

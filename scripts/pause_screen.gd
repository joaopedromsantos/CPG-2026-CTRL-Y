class_name PauseScreen
extends Control

signal resume_requested
signal start_screen_requested

@onready var score_value: Label = $Panel/Content/StatsRow/ScoreStat/ScoreContent/ScoreValue
@onready var time_value: Label = $Panel/Content/StatsRow/TimeStat/TimeContent/TimeValue
@onready var lives_value: Label = $Panel/Content/StatsRow/LivesStat/LivesContent/LivesValue
@onready var power_ups_value: Label = $Panel/Content/PowerUpsPanel/PowerUpsContent/PowerUpsValue
@onready var resume_button: Button = $Panel/Content/ButtonsRow/ResumeButton
@onready var start_screen_button: Button = $Panel/Content/ButtonsRow/StartScreenButton

const POWER_UP_LABELS := {
	"lupa": "Lupa",
	"revive": "Revive",
	"heart": "Coração",
	"lightning": "Raio",
	"hourglass": "Ampulheta",
	"double": "2x",
}


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_button_pressed)
	start_screen_button.pressed.connect(_on_start_screen_button_pressed)


func show_pause(score: int, time_text: String, lives: int, power_up_slots: Array) -> void:
	score_value.text = "%d" % score
	time_value.text = time_text
	lives_value.text = "%d" % lives
	power_ups_value.text = _format_power_up_slots(power_up_slots)
	visible = true


func hide_pause() -> void:
	visible = false


func _format_power_up_slots(power_up_slots: Array) -> String:
	var labels: Array[String] = []
	for slot in power_up_slots:
		var type := String(slot)
		if type == "":
			continue
		labels.append(String(POWER_UP_LABELS.get(type, type)))

	if labels.is_empty():
		return "Nenhum"

	return ", ".join(labels)


func _on_resume_button_pressed() -> void:
	resume_button.release_focus()
	resume_requested.emit()


func _on_start_screen_button_pressed() -> void:
	start_screen_button.release_focus()
	start_screen_requested.emit()

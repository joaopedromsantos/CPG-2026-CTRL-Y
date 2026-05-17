class_name SettingsScreen
extends Control

const START_SCENE := "res://scenes/start_screen.tscn"

signal close_requested
signal music_volume_changed

@onready var music_slider: HSlider = $Panel/Content/MusicRow/MusicSlider
@onready var music_value: Label = $Panel/Content/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Panel/Content/SfxRow/SfxSlider
@onready var sfx_value: Label = $Panel/Content/SfxRow/SfxValue
@onready var close_button: Button = $CloseButton
@onready var reset_button: Button = $Panel/Content/ButtonRow/ResetButton
@onready var save_button: Button = $Panel/Content/ButtonRow/SaveButton

var _game_settings: Node


func _ready() -> void:
	_game_settings = get_node_or_null("/root/GameSettings")
	_load_current_settings()
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	save_button.pressed.connect(_on_save_pressed)


func show_settings() -> void:
	_load_current_settings()
	visible = true
	save_button.grab_focus()


func _load_current_settings() -> void:
	var current_music := SoundSettings.MAX_VOLUME
	var current_sfx := SoundSettings.MAX_VOLUME
	if _game_settings:
		current_music = int(_game_settings.get("music_volume"))
		current_sfx = int(_game_settings.get("sfx_volume"))

	music_slider.value = current_music
	sfx_slider.value = current_sfx
	_update_volume_labels()


func _update_volume_labels() -> void:
	music_value.text = "%d / 10" % int(music_slider.value)
	sfx_value.text = "%d / 10" % int(sfx_slider.value)


func _on_music_volume_changed(value: float) -> void:
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	_update_volume_labels()


func _on_save_pressed() -> void:
	save_button.release_focus()
	if _game_settings:
		_game_settings.call("set_audio_settings", int(music_slider.value), int(sfx_slider.value))
	music_volume_changed.emit()
	_close()


func _on_reset_pressed() -> void:
	reset_button.release_focus()
	music_slider.value = SoundSettings.MAX_VOLUME
	sfx_slider.value = SoundSettings.MAX_VOLUME
	_update_volume_labels()
	if _game_settings:
		_game_settings.call("reset_audio_settings")
	music_volume_changed.emit()


func _on_close_pressed() -> void:
	close_button.release_focus()
	_close()


func _close() -> void:
	visible = false
	close_requested.emit()
	if get_signal_connection_list("close_requested").is_empty():
		get_tree().change_scene_to_file(START_SCENE)

extends Control

const MAIN_MENU_SCENE := "res://scenes/start_screen.tscn"

@onready var line_edit: LineEdit = $Panel/Content/LineEdit
@onready var confirm_button: Button = $Panel/Content/ConfirmButton
@onready var hint_label: Label = $Panel/Content/HintLabel


func _ready() -> void:
	line_edit.max_length = PlayerData.MAX_NAME_LENGTH
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	confirm_button.pressed.connect(_on_confirm_pressed)

	if PlayerData.has_name():
		line_edit.text = PlayerData.get_display_name()

	_refresh_state(line_edit.text)
	line_edit.grab_focus()
	line_edit.caret_column = line_edit.text.length()


func _on_text_changed(new_text: String) -> void:
	_refresh_state(new_text)


func _on_text_submitted(_text: String) -> void:
	if not confirm_button.disabled:
		_confirm()


func _on_confirm_pressed() -> void:
	_confirm()


func _refresh_state(current_text: String) -> void:
	var trimmed := current_text.strip_edges()
	var length := trimmed.length()
	confirm_button.disabled = length < PlayerData.MIN_NAME_LENGTH
	hint_label.text = "%d / %d caracteres (mínimo %d)" % [
		length, PlayerData.MAX_NAME_LENGTH, PlayerData.MIN_NAME_LENGTH
	]


func _confirm() -> void:
	var new_name := line_edit.text.strip_edges()
	if new_name.length() < PlayerData.MIN_NAME_LENGTH:
		return
	PlayerData.save_name(new_name)
	PlayerData._session_name_confirmed = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

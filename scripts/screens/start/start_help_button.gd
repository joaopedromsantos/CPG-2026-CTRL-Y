class_name StartHelpButton
extends Button

@export_file("*.tscn") var help_scene_path := "res://scenes/help_screen.tscn"

var _help_modal: Control


func _ready() -> void:
	pressed.connect(_open_help)
	call_deferred("_build_help_modal")


func _unhandled_input(event: InputEvent) -> void:
	if not is_help_visible():
		return
	if event.is_action_pressed("ui_cancel"):
		_close_help()
	get_viewport().set_input_as_handled()


func is_help_visible() -> bool:
	return _help_modal != null and _help_modal.visible


func _build_help_modal() -> void:
	if _help_modal:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	_help_modal = load(help_scene_path).instantiate() as Control
	_help_modal.visible = false
	if _help_modal.has_signal("close_requested"):
		_help_modal.close_requested.connect(_close_help)
	parent_node.add_child(_help_modal)


func _open_help() -> void:
	release_focus()
	if _help_modal == null:
		_build_help_modal()
	if _help_modal == null:
		return

	if _help_modal.has_method("show_help"):
		_help_modal.call("show_help")
	else:
		_help_modal.visible = true


func _close_help() -> void:
	if _help_modal:
		_help_modal.visible = false
	grab_focus()

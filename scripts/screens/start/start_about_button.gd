class_name StartAboutButton
extends Button

@export_file("*.tscn") var about_scene_path := "res://scenes/about_screen.tscn"

var _about_modal: Control


func _ready() -> void:
	pressed.connect(_open_about)
	call_deferred("_build_about_modal")


func _unhandled_input(event: InputEvent) -> void:
	if not is_about_visible():
		return
	if event.is_action_pressed("ui_cancel"):
		_close_about()
	get_viewport().set_input_as_handled()


func is_about_visible() -> bool:
	return _about_modal != null and _about_modal.visible


func _build_about_modal() -> void:
	if _about_modal:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	_about_modal = load(about_scene_path).instantiate() as Control
	_about_modal.visible = false
	if _about_modal.has_signal("close_requested"):
		_about_modal.close_requested.connect(_close_about)
	parent_node.add_child(_about_modal)


func _open_about() -> void:
	release_focus()
	if _about_modal == null:
		_build_about_modal()
	if _about_modal == null:
		return

	if _about_modal.has_method("show_about"):
		_about_modal.call("show_about")
	else:
		_about_modal.visible = true


func _close_about() -> void:
	if _about_modal:
		_about_modal.visible = false
	grab_focus()

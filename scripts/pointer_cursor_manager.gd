extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_to_tree(get_tree().root)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	_apply_to_node(node)


func _apply_to_tree(node: Node) -> void:
	_apply_to_node(node)
	for child in node.get_children():
		_apply_to_tree(child)


func _apply_to_node(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

class_name HudLivesView
extends RefCounted


func set_max_lives(hearts_row: HBoxContainer, max_lives: int, heart_full_texture: Texture2D) -> void:
	var target := maxi(max_lives, 0)
	var hearts := hearts_row.get_children()
	while hearts.size() > target:
		var extra: Node = hearts.pop_back()
		extra.queue_free()
	while hearts.size() < target:
		var template: TextureRect = null
		if hearts_row.get_child_count() > 0:
			template = hearts_row.get_child(0) as TextureRect
		var new_heart := TextureRect.new()
		new_heart.custom_minimum_size = Vector2(36, 36)
		new_heart.texture = heart_full_texture
		new_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		new_heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if template:
			new_heart.custom_minimum_size = template.custom_minimum_size
		hearts_row.add_child(new_heart)
		hearts.append(new_heart)


func update_lives(hearts_row: HBoxContainer, lives: int, heart_full_texture: Texture2D, heart_empty_texture: Texture2D) -> Array[TextureRect]:
	var changed_to_empty: Array[TextureRect] = []
	var hearts := hearts_row.get_children()
	for i in range(hearts.size()):
		var heart := hearts[i] as TextureRect
		var should_be_full := i < lives
		var was_full := heart.texture == heart_full_texture
		heart.texture = heart_full_texture if should_be_full else heart_empty_texture
		if was_full and not should_be_full:
			changed_to_empty.append(heart)
	return changed_to_empty

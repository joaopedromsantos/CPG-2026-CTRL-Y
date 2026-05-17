class_name HudPowerUpSlotLogic
extends RefCounted


func power_up_display(type: String, type_to_icon: Dictionary, textures: Dictionary) -> Texture2D:
	var slot_icon := int(type_to_icon.get(type, -1))
	return textures.get(slot_icon, null) as Texture2D


func countdown_text(remaining: float) -> String:
	return "%d" % [maxi(0, ceili(remaining))]


func is_valid_slot(slot: int, slot_count: int) -> bool:
	return slot >= 0 and slot < slot_count


func is_reserve_slot(slot: int, reserve_slot_index: int) -> bool:
	return slot == reserve_slot_index


func active_slot_style(base_style: StyleBox, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style := base_style.duplicate(true) as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	style.border_width_left = maxi(style.border_width_left, 4)
	style.border_width_top = maxi(style.border_width_top, 4)
	style.border_width_right = maxi(style.border_width_right, 4)
	style.border_width_bottom = maxi(style.border_width_bottom, 4)
	style.border_color = border_color
	style.shadow_color = shadow_color
	style.shadow_size = maxi(style.shadow_size, 8)
	style.shadow_offset = Vector2.ZERO
	return style

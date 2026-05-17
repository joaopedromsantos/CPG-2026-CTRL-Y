class_name HudDeathFadeView
extends RefCounted


func create_death_fade(root_control: Control, endgame_overlay: Control) -> ColorRect:
	var death_fade_rect := ColorRect.new()
	death_fade_rect.name = "DeathFade"
	death_fade_rect.visible = false
	death_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	death_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_fade_rect.z_index = 90
	root_control.add_child(death_fade_rect)
	endgame_overlay.z_index = 100
	return death_fade_rect


func hide_death_fade(death_fade_rect: ColorRect) -> void:
	if death_fade_rect:
		death_fade_rect.visible = false
		death_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)

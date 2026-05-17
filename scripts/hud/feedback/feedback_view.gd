class_name HudFeedbackView
extends RefCounted


func set_feedback(label: Label, is_correct: bool, correct_color: Color, wrong_color: Color) -> void:
	if is_correct:
		label.text = "Acertou!"
		label.add_theme_color_override("font_color", correct_color)
	else:
		label.text = "Errou! ✕"
		label.add_theme_color_override("font_color", wrong_color)


func clear_feedback(label: Label) -> void:
	label.text = ""
	label.modulate = Color(1, 1, 1, 0)

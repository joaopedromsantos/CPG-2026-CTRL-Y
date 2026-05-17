class_name HudEndgameView
extends RefCounted


func reset_celebration(title_label: Label, subtitle_label: Label, default_title: String, default_subtitle: String, default_title_color: Color) -> void:
	if title_label:
		title_label.text = default_title
		title_label.add_theme_color_override("font_color", default_title_color)
	if subtitle_label:
		subtitle_label.text = default_subtitle


func set_awaiting_ranking(subtitle_label: Label, buttons_row: HBoxContainer, submitting_subtitle: String) -> void:
	if subtitle_label:
		subtitle_label.text = submitting_subtitle
	if buttons_row:
		buttons_row.visible = false


func apply_score_submitted(
	is_new_record: bool,
	title_label: Label,
	subtitle_label: Label,
	buttons_row: HBoxContainer,
	default_subtitle: String,
	new_record_title: String,
	new_record_title_color: Color
) -> void:
	if subtitle_label:
		subtitle_label.text = default_subtitle
	if is_new_record and title_label:
		title_label.text = new_record_title
		title_label.add_theme_color_override("font_color", new_record_title_color)
	if buttons_row:
		buttons_row.visible = true

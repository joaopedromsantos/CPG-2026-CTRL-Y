class_name RunnerHud
extends CanvasLayer

var _score_label: Label
var _game_over_label: Label


func setup(sentences: Array[String]) -> void:
	name = "HUD"
	_build_top_bar()
	_build_score_label()
	_build_sentence_box(sentences)
	_build_game_over_label()


func update_score(score: int) -> void:
	_score_label.text = "Pontos: %04d" % score


func show_game_over() -> void:
	_game_over_label.text = "Fim de jogo\nAperte R para reiniciar"


func hide_game_over() -> void:
	_game_over_label.text = ""


func _build_top_bar() -> void:
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.02, 0.025, 0.03, 0.72)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 112.0
	add_child(top_bar)


func _build_score_label() -> void:
	_score_label = Label.new()
	_score_label.position = Vector2(18.0, 14.0)
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_score_label.add_theme_constant_override("shadow_offset_x", 2)
	_score_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_score_label)


func _build_sentence_box(sentences: Array[String]) -> void:
	var sentence_box := VBoxContainer.new()
	sentence_box.anchor_left = 0.38
	sentence_box.anchor_right = 1.0
	sentence_box.offset_top = 12.0
	sentence_box.offset_right = -18.0
	sentence_box.offset_bottom = 104.0
	sentence_box.add_theme_constant_override("separation", 4)
	add_child(sentence_box)

	for sentence in sentences:
		var label := Label.new()
		label.text = sentence
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		sentence_box.add_child(label)


func _build_game_over_label() -> void:
	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_game_over_label.anchor_right = 1.0
	_game_over_label.anchor_bottom = 1.0
	_game_over_label.offset_top = -40.0
	_game_over_label.add_theme_font_size_override("font_size", 34)
	_game_over_label.add_theme_color_override("font_color", Color.WHITE)
	_game_over_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_game_over_label.add_theme_constant_override("shadow_offset_x", 3)
	_game_over_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(_game_over_label)

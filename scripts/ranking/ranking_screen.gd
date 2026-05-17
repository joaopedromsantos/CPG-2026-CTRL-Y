extends Control

const MAIN_MENU_SCENE := "res://scenes/start_screen.tscn"

const DIFFICULTY_TAB_INDEX := {
	DifficultySettings.DIFFICULTY_EASY: 0,
	DifficultySettings.DIFFICULTY_MEDIUM: 1,
	DifficultySettings.DIFFICULTY_HARD: 2,
	DifficultySettings.DIFFICULTY_IMPOSSIBLE: 3,
}

const TAB_KEY_ORDER := [
	DifficultySettings.DIFFICULTY_EASY,
	DifficultySettings.DIFFICULTY_MEDIUM,
	DifficultySettings.DIFFICULTY_HARD,
	DifficultySettings.DIFFICULTY_IMPOSSIBLE,
]

@onready var tab_container: TabContainer = $Panel/Content/TabContainer
@onready var back_button: Button = $Panel/Content/BackButton
@onready var containers: Dictionary = {
	DifficultySettings.DIFFICULTY_EASY: $Panel/Content/TabContainer/Easy/Scroll/List,
	DifficultySettings.DIFFICULTY_MEDIUM: $Panel/Content/TabContainer/Medium/Scroll/List,
	DifficultySettings.DIFFICULTY_HARD: $Panel/Content/TabContainer/Hard/Scroll/List,
	DifficultySettings.DIFFICULTY_IMPOSSIBLE: $Panel/Content/TabContainer/Impossible/Scroll/List,
}


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	for index in TAB_KEY_ORDER.size():
		var key: String = TAB_KEY_ORDER[index]
		tab_container.set_tab_title(index, DifficultySettings.get_label(key))

	var initial_difficulty := PlayerData.difficulty
	if initial_difficulty in DIFFICULTY_TAB_INDEX:
		tab_container.current_tab = int(DIFFICULTY_TAB_INDEX[initial_difficulty])

	_populate(RankingAPI.last_leaderboard)


func _populate(data: Dictionary) -> void:
	for key in containers.keys():
		var list: VBoxContainer = containers[key]
		_clear_children(list)
		var entries: Array = data.get(key, []) if data is Dictionary else []
		if entries.is_empty():
			list.add_child(_make_empty_label())
			continue
		var local_name := PlayerData.get_display_name()
		for entry in entries:
			if not (entry is Dictionary):
				continue
			list.add_child(_make_entry_row(entry, local_name))


func _make_entry_row(entry: Dictionary, local_name: String) -> Control:
	var rank := int(entry.get("rank", 0))
	var name_text := String(entry.get("display_name", ""))
	var score := int(entry.get("highscore", 0))
	var is_self := local_name != "" and name_text == local_name

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var rank_label := Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(72, 0)
	rank_label.add_theme_font_size_override("font_size", 22)
	rank_label.add_theme_color_override("font_color", _color_for_rank(rank))
	row.add_child(rank_label)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.36, 0.97, 1.0) if is_self else Color(1, 1, 1)
	)
	row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = "%d pts" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.custom_minimum_size = Vector2(120, 0)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1, 0.86, 0.32))
	row.add_child(score_label)

	return row


func _make_empty_label() -> Label:
	var label := Label.new()
	label.text = "Nenhum jogador no ranking ainda."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	return label


func _color_for_rank(rank: int) -> Color:
	match rank:
		1:
			return Color(1.0, 0.84, 0.20)
		2:
			return Color(0.82, 0.85, 0.92)
		3:
			return Color(0.85, 0.55, 0.25)
		_:
			return Color(1, 1, 1, 0.85)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

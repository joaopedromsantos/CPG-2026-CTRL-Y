class_name HelpScreen
extends Control

signal close_requested

const NEON_CYAN := Color(0.36, 0.97, 1.0)
const PANEL_BG := Color(0.04, 0.08, 0.18, 0.86)
const ROW_BG := Color(0.02, 0.04, 0.10, 0.72)
const HEADER_BG := Color(0.10, 0.30, 0.46, 0.92)
const ORANGE := Color(1.0, 0.62, 0.13)
const WHITE := Color(1.0, 1.0, 1.0)
const FIRST_COLUMN_ICON_LEFT_MARGIN := 16.0

@onready var close_button: Button = $CloseButton
@onready var power_up_rows: VBoxContainer = $Panel/Content/Scroll/HelpRows/PowerUpsTable/PowerUpsContent/Rows
@onready var obstacle_rows: VBoxContainer = $Panel/Content/Scroll/HelpRows/ObstaclesTable/ObstaclesContent/Rows
@onready var difficulty_rows: VBoxContainer = $Panel/Content/Scroll/HelpRows/DifficultyTable/DifficultyContent/Rows

var _tables_built := false


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	_build_tables()


func show_help() -> void:
	visible = true
	close_button.grab_focus()


func _on_close_pressed() -> void:
	close_button.release_focus()
	visible = false
	close_requested.emit()


func _build_tables() -> void:
	if _tables_built:
		return

	var power_ups := [
		{
			"icon": "res://assets/power-ups/slots/heart.png",
			"name": "Coração",
			"effect": "Recupera vida ao longo de 5s."
		},
		{
			"icon": "res://assets/power-ups/slots/hourglass.png",
			"name": "Ampulheta",
			"effect": "Reduz a velocidade do mundo por 6s."
		},
		{
			"icon": "res://assets/power-ups/slots/lightning.png",
			"name": "Raio",
			"effect": "Cai um raio em um número, mostrando que não é o correto."
		},
		{
			"icon": "res://assets/power-ups/slots/lupa.png",
			"name": "Lupa",
			"effect": "Destaca as respostas corretas por 6s."
		},
		{
			"icon": "res://assets/power-ups/slots/double.png",
			"name": "Double",
			"effect": "Dobra os pontos dos acertos por 8s."
		},
		{
			"icon": "res://assets/power-ups/slots/revive.png",
			"name": "Revive",
			"effect": "Revive uma vez se você perder em até 10s."
		},
	]

	for item in power_ups:
		power_up_rows.add_child(_make_power_up_row(item))

	var obstacles := [
		{
			"icon": "res://assets/city-kit-roads/previews/construction-cone.png",
			"name": "Cone",
			"effect": "Remove 1 vida ao contato."
		},
		{
			"icon": "res://assets/car-kit/previews/box.png",
			"name": "Box",
			"effect": "Remove 1 vida ao contato."
		},
	]

	for item in obstacles:
		obstacle_rows.add_child(_make_power_up_row(item))

	var difficulties := [
		{"badge": "I", "name": "Fácil", "effect": "Equações mais simples para começar a partida."},
		{"badge": "II", "name": "Médio", "effect": "Equações intermediárias para uma partida normal."},
		{"badge": "III", "name": "Difícil", "effect": "Equações mais exigentes e menos previsíveis."},
		{"badge": "IV", "name": "Impossível", "effect": "Grupo mais severo de equações do jogo."},
	]

	for item in difficulties:
		difficulty_rows.add_child(_make_difficulty_row(item))

	_tables_built = true


func _make_power_up_row(item: Dictionary) -> Control:
	var row := _make_row_panel()
	var content := _make_row_content()
	row.add_child(content)

	var icon_cell := HBoxContainer.new()
	icon_cell.custom_minimum_size = Vector2(170.0, 46.0)
	icon_cell.add_theme_constant_override("separation", 8)
	content.add_child(icon_cell)

	var icon_margin := MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left", int(FIRST_COLUMN_ICON_LEFT_MARGIN))
	icon_cell.add_child(icon_margin)

	if item.has("icon"):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(34.0, 34.0)
		icon.texture = load(String(item["icon"]))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_margin.add_child(icon)
	else:
		var badge := _make_badge(String(item["badge"]))
		icon_margin.add_child(badge)

	var name_label := _make_label(String(item["name"]), 19, WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_cell.add_child(name_label)

	var effect_label := _make_label(String(item["effect"]), 18, WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(effect_label)
	return row


func _make_difficulty_row(item: Dictionary) -> Control:
	var row := _make_row_panel()
	var content := _make_row_content()
	row.add_child(content)

	var difficulty_cell := HBoxContainer.new()
	difficulty_cell.custom_minimum_size = Vector2(170.0, 46.0)
	difficulty_cell.add_theme_constant_override("separation", 8)
	content.add_child(difficulty_cell)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", int(FIRST_COLUMN_ICON_LEFT_MARGIN))
	difficulty_cell.add_child(badge_margin)

	var badge := _make_badge(String(item["badge"]))
	badge_margin.add_child(badge)

	var name_label := _make_label(String(item["name"]), 19, WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_cell.add_child(name_label)

	var effect_label := _make_label(String(item["effect"]), 18, WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(effect_label)
	return row


func _make_row_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_box(ROW_BG, ORANGE, 1, 0, Vector2.ZERO))
	return panel


func _make_row_content() -> HBoxContainer:
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return content


func _make_badge(text: String) -> Label:
	var label := _make_label(text, 17, Color(0.04, 0.08, 0.18), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(48.0 if text.length() > 2 else 36.0, 32.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _make_box(ORANGE, Color(1.0, 0.82, 0.30), 2, 6, Vector2.ZERO))
	return label


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.58))
	return label


func _make_box(fill: Color, border: Color, border_width: int, radius: int, shadow_offset: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	if shadow_offset != Vector2.ZERO:
		box.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
		box.shadow_size = 10
		box.shadow_offset = shadow_offset
	return box

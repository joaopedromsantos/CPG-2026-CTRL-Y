class_name AboutScreen
extends Control

signal close_requested

const NEON_CYAN := Color(0.36, 0.97, 1.0)
const PANEL_BG := Color(0.04, 0.08, 0.18, 0.86)
const SECTION_BG := Color(0.04, 0.08, 0.18, 0.68)
const SECTION_BORDER := Color(0.36, 0.97, 1.0, 0.45)
const ORANGE := Color(1.0, 0.62, 0.13)
const WHITE := Color(1.0, 1.0, 1.0)

@onready var close_button: Button = $CloseButton
@onready var about_rows: VBoxContainer = $Panel/Content/Scroll/AboutRows

var _content_built := false


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	_build_content()


func show_about() -> void:
	visible = true
	close_button.grab_focus()


func _on_close_pressed() -> void:
	close_button.release_focus()
	visible = false
	close_requested.emit()


func _build_content() -> void:
	if _content_built:
		return

	_add_section("O Jogo", [
		"Math Runner é um runner educativo onde uma equação aparece no topo da tela e você precisa escolher a resposta correta entre 3 alternativas, cada uma em um caminho diferente.",
		"Durante a corrida, colete power-ups para ganhar vantagem e desvie dos obstáculos para não perder vidas!",
	])

	_add_section("A História", [
		"Você é RX-07, um robô criado para resolver problemas matemáticos. Mas algo deu errado na sua programação.",
		"Seu núcleo de energia está falhando, e a única forma de continuar funcionando é resolver equações antes que o sistema entre em colapso.",
		"Cada cálculo correto estabiliza seus circuitos por mais alguns segundos. Cada erro aproxima o desligamento definitivo.",
		"RESOLVA. SOBREVIVA. REPROGRAME SEU DESTINO.",
	])

	_add_credits_section()

	_add_section("Evento", [
		"Criado no Coding Pizza and Glory (CPG), evento realizado no Inatel em 2026.",
		"Desenvolvido com Godot Engine.",
	])

	var tagline := _make_label("Feito a base de muita parceria e Energéticos ⚡", 16, ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about_rows.add_child(tagline)

	_content_built = true


func _add_section(title: String, texts: Array) -> void:
	var section := PanelContainer.new()
	section.add_theme_stylebox_override("panel", _make_section_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	section.add_child(vbox)

	var title_label := _make_label(title, 24, NEON_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	vbox.add_child(title_label)

	for text in texts:
		var label := _make_label(String(text), 17, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label)

	about_rows.add_child(section)


func _add_credits_section() -> void:
	var section := PanelContainer.new()
	section.add_theme_stylebox_override("panel", _make_section_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	section.add_child(vbox)

	var title_label := _make_label("Créditos", 24, NEON_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	vbox.add_child(title_label)

	var credits := [
		{
			"name": "Gabriel Pivoto",
			"linkedin": "https://www.linkedin.com/in/pivoto-gabriel/",
			"github": "https://github.com/gabriel-pivoto",
		},
		{
			"name": "Luiz Gustavo Guimarães",
			"linkedin": "https://www.linkedin.com/in/luiz-gustavo-guimaraes-santos/",
			"github": "https://github.com/LuizGuimaraesz",
		},
		{
			"name": "Pedro Augusto Barbosa",
			"linkedin": "https://www.linkedin.com/in/pedroaba/",
			"github": "https://github.com/pedroaba",
		},
		{
			"name": "João Pedro Santos",
			"linkedin": "https://www.linkedin.com/in/joaopedrosantosdev/",
			"github": "https://github.com/joaopedromsantos",
		},
	]

	for person in credits:
		vbox.add_child(_make_credit_row(person))

	about_rows.add_child(section)


func _make_credit_row(person: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override("panel", _make_row_style())

	var row_vbox := VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 4)
	row_panel.add_child(row_vbox)

	var name_label := _make_label(String(person["name"]), 19, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	row_vbox.add_child(name_label)

	var links := RichTextLabel.new()
	links.bbcode_enabled = true
	links.fit_content = true
	links.scroll_active = false
	links.custom_minimum_size = Vector2(0, 24)
	links.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	links.add_theme_font_size_override("normal_font_size", 15)
	links.add_theme_color_override("default_color", NEON_CYAN)

	var bbcode := "[center][url=%s]LinkedIn[/url]  •  [url=%s]GitHub[/url][/center]" % [
		String(person["linkedin"]),
		String(person["github"]),
	]
	links.text = bbcode
	links.meta_clicked.connect(_on_link_clicked)
	row_vbox.add_child(links)

	return row_panel


func _on_link_clicked(meta: Variant) -> void:
	OS.shell_open(String(meta))


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


func _make_section_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.content_margin_left = 18.0
	box.content_margin_top = 14.0
	box.content_margin_right = 18.0
	box.content_margin_bottom = 14.0
	box.bg_color = SECTION_BG
	box.border_color = SECTION_BORDER
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	return box


func _make_row_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.04, 0.10, 0.72)
	box.border_color = ORANGE
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 0
	box.corner_radius_top_right = 0
	box.corner_radius_bottom_left = 0
	box.corner_radius_bottom_right = 0
	box.content_margin_left = 12.0
	box.content_margin_top = 8.0
	box.content_margin_right = 12.0
	box.content_margin_bottom = 8.0
	return box

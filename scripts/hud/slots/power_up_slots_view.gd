class_name HudPowerUpSlotsView
extends RefCounted

const POWER_UP_SLOT_LOGIC_SCRIPT = preload("res://scripts/hud/slots/power_up_slot_logic.gd")

var icon_rects: Array[TextureRect] = []
var panels: Array[Panel] = []
var default_styles: Array[StyleBox] = []
var active_styles: Array[StyleBoxFlat] = []
var countdown_labels: Array[Label] = []

var _logic := POWER_UP_SLOT_LOGIC_SCRIPT.new()
var _reserve_slot_index := 3
var _slot_countdown_font_color := Color.WHITE
var _slot_countdown_outline_color := Color.BLACK
var _slot_icon_active_modulate := Color(0.35, 0.35, 0.35, 1.0)
var _slot_icon_inactive_modulate := Color.WHITE
var _slot_active_border_color := Color(0.2, 0.75, 1.0, 1.0)
var _slot_active_shadow_color := Color(0.2, 0.75, 1.0, 0.55)


func setup(
	slot_labels: Array,
	reserve_slot_index: int,
	slot_countdown_font_color: Color,
	slot_countdown_outline_color: Color,
	slot_icon_active_modulate: Color,
	slot_icon_inactive_modulate: Color,
	slot_active_border_color: Color,
	slot_active_shadow_color: Color
) -> void:
	_reserve_slot_index = reserve_slot_index
	_slot_countdown_font_color = slot_countdown_font_color
	_slot_countdown_outline_color = slot_countdown_outline_color
	_slot_icon_active_modulate = slot_icon_active_modulate
	_slot_icon_inactive_modulate = slot_icon_inactive_modulate
	_slot_active_border_color = slot_active_border_color
	_slot_active_shadow_color = slot_active_shadow_color

	icon_rects.clear()
	panels.clear()
	default_styles.clear()
	active_styles.clear()
	countdown_labels.clear()

	for label in slot_labels:
		label.visible = false
		var panel := label.get_parent() as Panel
		var is_reserve_slot := _logic.is_reserve_slot(panels.size(), _reserve_slot_index)
		if is_reserve_slot:
			panel.z_index = 20
		var key_label := panel.get_node_or_null("KeyLabel") as Label
		if key_label:
			key_label.z_index = 10
		panels.append(panel)
		default_styles.append(panel.get_theme_stylebox("panel"))
		active_styles.append(_logic.active_slot_style(panel.get_theme_stylebox("panel"), _slot_active_border_color, _slot_active_shadow_color))

		var icon := TextureRect.new()
		icon.name = "PowerUpIcon"
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		if is_reserve_slot:
			icon.offset_left = 4.0
			icon.offset_top = 4.0
			icon.offset_right = -4.0
			icon.offset_bottom = -4.0
		else:
			icon.offset_left = 11.0
			icon.offset_top = 8.0
			icon.offset_right = -11.0
			icon.offset_bottom = -8.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.get_parent().add_child(icon)
		icon_rects.append(icon)

		var countdown := Label.new()
		countdown.name = "PowerUpCountdown"
		countdown.visible = false
		countdown.set_anchors_preset(Control.PRESET_FULL_RECT)
		countdown.offset_left = 0.0
		countdown.offset_top = 0.0
		countdown.offset_right = 0.0
		countdown.offset_bottom = 0.0
		countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown.add_theme_font_size_override("font_size", 27)
		countdown.add_theme_color_override("font_color", _slot_countdown_font_color)
		countdown.add_theme_color_override("font_outline_color", _slot_countdown_outline_color)
		countdown.add_theme_constant_override("outline_size", 8)
		if label.has_theme_font("font"):
			countdown.add_theme_font_override("font", label.get_theme_font("font"))
		label.get_parent().add_child(countdown)
		countdown_labels.append(countdown)


func update_slots(slots: Array, type_to_icon: Dictionary, textures: Dictionary) -> Array[int]:
	var inactive_slots: Array[int] = []
	for i in range(icon_rects.size()):
		var type := ""
		if i < slots.size():
			type = String(slots[i])
		icon_rects[i].texture = _logic.power_up_display(type, type_to_icon, textures)
		if type == "":
			inactive_slots.append(i)
	return inactive_slots


func update_slot_active(slot: int, remaining: float, active: bool) -> void:
	if not _logic.is_valid_slot(slot, countdown_labels.size()):
		return

	panels[slot].add_theme_stylebox_override(
		"panel",
		active_styles[slot] if active else default_styles[slot]
	)
	countdown_labels[slot].visible = active
	icon_rects[slot].modulate = _slot_icon_active_modulate if active else _slot_icon_inactive_modulate
	if active:
		countdown_labels[slot].text = _logic.countdown_text(remaining)

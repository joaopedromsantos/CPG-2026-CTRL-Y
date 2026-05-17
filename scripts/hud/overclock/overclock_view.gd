class_name HudOverclockView
extends RefCounted

const TIER_TEXT_COLOR := {
	1: Color(1.0, 0.95, 0.18, 1.0),
	2: Color(0.2, 0.85, 1.0, 1.0),
	3: Color(0.85, 0.3, 1.0, 1.0),
}
const TIER_OUTLINE_COLOR := {
	1: Color(0.35, 0.22, 0.0, 1.0),
	2: Color(0.0, 0.15, 0.35, 1.0),
	3: Color(0.22, 0.0, 0.32, 1.0),
}
const TIER_NEON := {
	1: Vector3(1.0, 0.9, 0.1),
	2: Vector3(0.1, 0.7, 1.0),
	3: Vector3(0.8, 0.2, 1.0),
}
const TIER_LABEL := {
	1: "OVERCLOCK X2",
	2: "OVERCLOCK X4",
	3: "OVERCLOCK X6",
}
const TIER_GLITCH := {
	1: 0.0,
	2: 0.35,
	3: 0.85,
}
const TIER_TIME_SCALE := {
	1: 14.0,
	2: 22.0,
	3: 36.0,
}
const TIER_EDGE_SIZE := {
	1: 0.16,
	2: 0.20,
	3: 0.26,
}
const TIER_PULSE_SPEED := {
	1: 8.0,
	2: 13.0,
	3: 18.0,
}

const POP_IN_TIME := 0.18
const POP_SETTLE_TIME := 0.16
const HOLD_TIME := 1.1
const FADE_OUT_TIME := 0.55
const SHAKE_PULSES := 4
const SHAKE_AMPLITUDE := 14.0
const RISE_AMOUNT := 42.0
const EDGES_FADE_IN := 0.14
const EDGES_FADE_OUT := 0.55

var _label: Label
var _edges: ColorRect
var _label_base_pos: Vector2
var _base_captured: bool = false
var _active_tween: Tween


func setup(label: Label, edges_rect: ColorRect) -> void:
	_label = label
	_edges = edges_rect
	if _label:
		_label.pivot_offset = _label.size * 0.5
		_label_base_pos = _label.position
		_base_captured = true
		_label.modulate.a = 0.0
	if _edges:
		_edges.modulate.a = 1.0
		_apply_shader_param("intensity", 0.0)


func play(tier: int) -> void:
	if _label == null or _edges == null:
		return
	if not TIER_LABEL.has(tier):
		return

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	var text_color: Color = TIER_TEXT_COLOR[tier]
	var outline_color: Color = TIER_OUTLINE_COLOR[tier]
	var neon: Vector3 = TIER_NEON[tier]
	var glitch_value: float = TIER_GLITCH[tier]

	_label.text = String(TIER_LABEL[tier])
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_color_override("font_outline_color", outline_color)
	_label.pivot_offset = _label.size * 0.5
	_label.scale = Vector2(0.35, 0.35)
	_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_label.position = _label_base_pos

	_apply_shader_param("neon_color", neon)
	_apply_shader_param("glitch", glitch_value)
	_apply_shader_param("time_scale", float(TIER_TIME_SCALE[tier]))
	_apply_shader_param("edge_size", float(TIER_EDGE_SIZE[tier]))
	_apply_shader_param("pulse_speed", float(TIER_PULSE_SPEED[tier]))
	_apply_shader_param("intensity", 0.0)

	_active_tween = _label.create_tween()
	_active_tween.set_parallel(true)

	_active_tween.tween_property(_label, "modulate:a", 1.0, POP_IN_TIME)
	_active_tween.tween_property(_label, "scale", Vector2(1.35, 1.35), POP_IN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_active_tween.chain().tween_property(_label, "scale", Vector2(1.0, 1.0), POP_SETTLE_TIME) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	for i in range(SHAKE_PULSES):
		var dx := randf_range(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE)
		var dy := -RISE_AMOUNT * (float(i + 1) / float(SHAKE_PULSES))
		_active_tween.chain().tween_property(
			_label,
			"position",
			_label_base_pos + Vector2(dx, dy),
			0.05
		)

	_active_tween.chain().tween_property(_label, "position", _label_base_pos + Vector2(0.0, -RISE_AMOUNT), 0.12)

	var edges_tween := _edges.create_tween()
	edges_tween.tween_method(_set_intensity, 0.0, 1.0, EDGES_FADE_IN)
	edges_tween.tween_interval(HOLD_TIME)
	edges_tween.tween_method(_set_intensity, 1.0, 0.0, EDGES_FADE_OUT)

	_active_tween.chain().tween_interval(HOLD_TIME)
	_active_tween.chain().tween_property(_label, "modulate:a", 0.0, FADE_OUT_TIME)


func stop() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	if _label:
		_label.modulate.a = 0.0
		_label.scale = Vector2.ONE
		if _base_captured:
			_label.position = _label_base_pos
	_apply_shader_param("intensity", 0.0)


func _set_intensity(value: float) -> void:
	_apply_shader_param("intensity", value)


func _apply_shader_param(name: String, value) -> void:
	if _edges == null:
		return
	var mat := _edges.material
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter(name, value)

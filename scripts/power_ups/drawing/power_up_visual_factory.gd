class_name PowerUpVisualFactory
extends RefCounted

const TYPE_DOUBLE := "double"

const ASSET_SCALES := {
	"res://assets/power-ups/magnifying_glass.glb": 0.3,
	"res://assets/power-ups/cutscene_model.glb": 0.8,
	"res://assets/power-ups/heart_emoji.glb": 0.005,
	"res://assets/power-ups/Lightning Bolt.glb": 1.6,
	"res://assets/power-ups/transparent_glass_hourglass.glb": 0.03,
}

const ASSET_BASE_Y := {
	"res://assets/power-ups/transparent_glass_hourglass.glb": 1.05,
}

const DEFAULT_SCALE := 0.1
const DEFAULT_BASE_Y := 0.5
const DOUBLE_COLOR := Color(1.0, 0.65, 0.05)
const DOUBLE_OUTLINE_COLOR := Color(0.3, 0.12, 0.0)

var float_rotation_speed := 48.0
var rng: RandomNumberGenerator


func setup(random_number_generator: RandomNumberGenerator, rotation_speed: float) -> void:
	rng = random_number_generator
	float_rotation_speed = rotation_speed


func make_power_up(entry: Dictionary) -> Node3D:
	var type: String = entry.get("type", "")
	var path: String = entry.get("path", "")
	var node: Node3D = null

	if type == TYPE_DOUBLE:
		node = _make_double_label()
	elif path != "" and ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource and resource is PackedScene:
			var instance := (resource as PackedScene).instantiate()
			if instance and instance is Node3D:
				node = instance as Node3D
				var scale: float = ASSET_SCALES.get(path, DEFAULT_SCALE)
				node.scale = Vector3.ONE * scale

	if node == null:
		node = _make_fallback_sphere()

	node.name = "PowerUp"
	node.set_meta("type", type)
	_init_power_up_meta(node, path)
	return node


func _make_double_label() -> Node3D:
	var root := Node3D.new()
	var label := Label3D.new()
	label.text = "2x"
	label.font_size = 128
	label.outline_size = 24
	label.modulate = DOUBLE_COLOR
	label.outline_modulate = DOUBLE_OUTLINE_COLOR
	label.double_sided = true
	label.pixel_size = 0.006
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(label)
	return root


func _make_fallback_sphere() -> Node3D:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.radial_segments = 12
	sphere.rings = 6
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.7, 0.3)
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	return root


func _init_power_up_meta(node: Node3D, path: String) -> void:
	node.set_meta("float_phase", rng.randf() * TAU)
	node.set_meta("base_y", ASSET_BASE_Y.get(path, DEFAULT_BASE_Y))
	var direction_x := 1.0 if rng.randi_range(0, 1) == 1 else -1.0
	var direction_y := 1.0 if rng.randi_range(0, 1) == 1 else -1.0
	var direction_z := 1.0 if rng.randi_range(0, 1) == 1 else -1.0
	node.set_meta("rot_dir_x", direction_x)
	node.set_meta("rot_dir_y", direction_y)
	node.set_meta("rot_dir_z", direction_z)
	node.set_meta("rot_speed_x", float_rotation_speed * rng.randf_range(0.8, 1.3))
	node.set_meta("rot_speed_y", float_rotation_speed * rng.randf_range(0.8, 1.3))
	node.set_meta("rot_speed_z", float_rotation_speed * rng.randf_range(0.8, 1.3))

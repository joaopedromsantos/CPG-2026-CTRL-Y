extends Node3D

func _ready() -> void:
	# Build a magnifying-glass asset composed of a torus rim, a thin transparent lens, and a handle.
	# Rim (thick flat ring approximated with a short cylinder underneath the lens)
	var rim := MeshInstance3D.new()
	var rim_cyl := CylinderMesh.new()
	rim_cyl.top_radius = 0.38
	rim_cyl.bottom_radius = 0.38
	rim_cyl.height = 0.06
	rim_cyl.radial_segments = 48
	rim.mesh = rim_cyl
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.15, 0.15, 0.18)
	rim_mat.metallic = 0.9
	rim_mat.roughness = 0.2
	rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	rim.material_override = rim_mat
	rim.position = Vector3(0, 0, 0)
	add_child(rim)

	# Lens (thin cylinder) inside the rim
	var lens := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.32
	cyl.height = 0.06
	cyl.radial_segments = 48
	lens.mesh = cyl
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = Color(0.85, 0.9, 1.0, 0.35)
	lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens_mat.unshaded = false
	lens_mat.roughness = 0.05
	lens_mat.metallic = 0.0
	lens_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	lens.material_override = lens_mat
	lens.position = Vector3(0, 0.02, 0)
	add_child(lens)

	# Handle
	var handle := MeshInstance3D.new()
	var handle_cyl := CylinderMesh.new()
	handle_cyl.top_radius = 0.045
	handle_cyl.bottom_radius = 0.045
	handle_cyl.height = 0.7
	handle_cyl.radial_segments = 12
	handle.mesh = handle_cyl
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.12, 0.12, 0.12)
	handle_mat.roughness = 0.45
	handle.material_override = handle_mat
	handle.position = Vector3(0.42, -0.15, 0)
	handle.rotation_degrees = Vector3(0, 0, 70)
	add_child(handle)

	set_name("LupaAsset")

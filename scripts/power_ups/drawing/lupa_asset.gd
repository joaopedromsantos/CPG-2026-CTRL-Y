class_name LupaAsset
extends Node3D


func _ready() -> void:
	var rim := MeshInstance3D.new()
	var rim_cylinder := CylinderMesh.new()
	rim_cylinder.top_radius = 0.38
	rim_cylinder.bottom_radius = 0.38
	rim_cylinder.height = 0.06
	rim_cylinder.radial_segments = 48
	rim.mesh = rim_cylinder
	var rim_material := StandardMaterial3D.new()
	rim_material.albedo_color = Color(0.15, 0.15, 0.18)
	rim_material.metallic = 0.9
	rim_material.roughness = 0.2
	rim_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rim.material_override = rim_material
	rim.position = Vector3(0, 0, 0)
	add_child(rim)

	var lens := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.32
	cylinder.bottom_radius = 0.32
	cylinder.height = 0.06
	cylinder.radial_segments = 48
	lens.mesh = cylinder
	var lens_material := StandardMaterial3D.new()
	lens_material.albedo_color = Color(0.85, 0.9, 1.0, 0.35)
	lens_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens_material.unshaded = false
	lens_material.roughness = 0.05
	lens_material.metallic = 0.0
	lens_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	lens.material_override = lens_material
	lens.position = Vector3(0, 0.02, 0)
	add_child(lens)

	var handle := MeshInstance3D.new()
	var handle_cylinder := CylinderMesh.new()
	handle_cylinder.top_radius = 0.045
	handle_cylinder.bottom_radius = 0.045
	handle_cylinder.height = 0.7
	handle_cylinder.radial_segments = 12
	handle.mesh = handle_cylinder
	var handle_material := StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.12, 0.12, 0.12)
	handle_material.roughness = 0.45
	handle.material_override = handle_material
	handle.position = Vector3(0.42, -0.15, 0)
	handle.rotation_degrees = Vector3(0, 0, 70)
	add_child(handle)

	set_name("LupaAsset")

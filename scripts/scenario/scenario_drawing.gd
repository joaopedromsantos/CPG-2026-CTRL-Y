class_name RunnerScenarioDrawing
extends RefCounted

var mat_floor_light: StandardMaterial3D
var mat_floor_dark: StandardMaterial3D
var mat_side_ground: StandardMaterial3D
var mat_lane: StandardMaterial3D
var mat_tree_trunk: StandardMaterial3D
var mat_tree_leaf: StandardMaterial3D
var mat_bench_wood: StandardMaterial3D
var mat_bench_metal: StandardMaterial3D


func setup_materials() -> void:
	var asphalt_color := Color(0.05, 0.06, 0.08)
	var sidewalk_color := Color(0.11, 0.12, 0.14)
	mat_floor_light = make_material(sidewalk_color, 1.0, 0.0)
	mat_floor_dark = make_material(asphalt_color, 0.95, 0.0)
	mat_side_ground = make_material(Color(0.07, 0.12, 0.08), 1.0, 0.0)
	mat_lane = make_material(Color(0.96, 0.93, 0.78), 0.35, 0.0)
	mat_lane.emission_enabled = true
	mat_lane.emission = Color(0.96, 0.93, 0.78)
	mat_lane.emission_energy_multiplier = 0.5
	mat_tree_trunk = make_material(Color(0.34, 0.18, 0.08), 0.9, 0.0)
	mat_tree_leaf = make_material(Color(0.08, 0.34, 0.16), 0.95, 0.0)
	mat_bench_wood = make_material(Color(0.48, 0.25, 0.11), 0.85, 0.0)
	mat_bench_metal = make_material(Color(0.16, 0.17, 0.18), 0.65, 0.1)


func make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func make_floor_mesh(floor_tile_size: float) -> BoxMesh:
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(floor_tile_size, 0.06, floor_tile_size)
	return floor_mesh


func make_dash_mesh(floor_tile_size: float) -> BoxMesh:
	var dash_mesh := BoxMesh.new()
	dash_mesh.size = Vector3(0.18, 0.02, floor_tile_size * 0.55)
	return dash_mesh


func make_edge_mesh(floor_tile_size: float) -> BoxMesh:
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.22, 0.02, floor_tile_size + 0.02)
	return edge_mesh


func make_star_material() -> StandardMaterial3D:
	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color(0.95, 0.97, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.95, 0.97, 1.0)
	star_mat.emission_energy_multiplier = 2.5
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return star_mat


func make_star_mesh() -> SphereMesh:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.08
	star_mesh.height = 0.16
	star_mesh.radial_segments = 6
	star_mesh.rings = 4
	return star_mesh


func create_pixel_building(
	width: float,
	height: float,
	building_mat: StandardMaterial3D,
	side_mat: StandardMaterial3D,
	window_mat: StandardMaterial3D
) -> Node3D:
	var root := Node3D.new()
	root.name = "PixelSkylineBuilding"

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(width, height, 1.0)
	body.mesh = body_mesh
	body.material_override = building_mat
	body.position.y = height * 0.5
	root.add_child(body)

	var side := MeshInstance3D.new()
	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(0.28, height, 1.04)
	side.mesh = side_mesh
	side.material_override = side_mat
	side.position = Vector3(width * 0.5 + 0.14, height * 0.5, 0.0)
	root.add_child(side)

	var cols := maxi(1, int(width / 0.55))
	var rows := maxi(2, int(height / 0.9))
	for row in range(rows):
		for col in range(cols):
			if (row + col) % 3 == 0:
				continue
			var window := MeshInstance3D.new()
			var window_mesh := BoxMesh.new()
			window_mesh.size = Vector3(0.18, 0.28, 0.04)
			window.mesh = window_mesh
			window.material_override = window_mat
			window.position = Vector3(
				(float(col) - float(cols - 1) * 0.5) * 0.46,
				0.8 + float(row) * 0.68,
				-0.53
			)
			root.add_child(window)

	return root


func create_tree_prop(rng: RandomNumberGenerator) -> Node3D:
	var tree := Node3D.new()
	tree.name = "SideTree"

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.13
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = rng.randf_range(1.0, 1.45)
	trunk_mesh.radial_segments = 8
	trunk.mesh = trunk_mesh
	trunk.material_override = mat_tree_trunk
	trunk.position.y = trunk_mesh.height * 0.5
	tree.add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = rng.randf_range(0.65, 0.9)
	leaf_mesh.height = leaf_mesh.radius * rng.randf_range(1.55, 1.9)
	leaf_mesh.radial_segments = 10
	leaf_mesh.rings = 5
	leaves.mesh = leaf_mesh
	leaves.material_override = mat_tree_leaf
	leaves.position = Vector3(0.0, trunk_mesh.height + leaf_mesh.height * 0.32, 0.0)
	tree.add_child(leaves)

	tree.scale = Vector3.ONE * rng.randf_range(1.6, 2.2)
	return tree


func create_bench_prop(side: int, rng: RandomNumberGenerator) -> Node3D:
	var bench := Node3D.new()
	bench.name = "SideBench"
	bench.rotation_degrees.y = 90.0 if side < 0 else -90.0

	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(1.25, 0.16, 0.42)
	seat.mesh = seat_mesh
	seat.material_override = mat_bench_wood
	seat.position.y = 0.45
	bench.add_child(seat)

	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(1.25, 0.48, 0.12)
	back.mesh = back_mesh
	back.material_override = mat_bench_wood
	back.position = Vector3(0.0, 0.72, -0.24)
	bench.add_child(back)

	for leg_x in [-0.48, 0.48]:
		for leg_z in [-0.13, 0.13]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.08, 0.45, 0.08)
			leg.mesh = leg_mesh
			leg.material_override = mat_bench_metal
			leg.position = Vector3(leg_x, 0.22, leg_z)
			bench.add_child(leg)

	bench.scale = Vector3.ONE * rng.randf_range(1.35, 1.7)
	return bench


func create_camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 6.4, 11.0)
	camera.rotation_degrees = Vector3(-56.0, 0.0, 0.0)
	camera.fov = 55.0
	camera.current = true
	return camera


func create_sun() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.light_energy = 2.6
	return light


func create_world_environment() -> WorldEnvironment:
	var ambient := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.1, 0.13)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.7)
	environment.ambient_light_energy = 0.65
	ambient.environment = environment
	return ambient

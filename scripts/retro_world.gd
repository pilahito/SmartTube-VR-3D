class_name RetroWorld
extends Node3D

var fireflies: MultiMeshInstance3D
var elapsed := 0.0

func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.012, 0.018, 0.025)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.65, 0.75)
	environment.ambient_light_energy = 0.6
	environment.fog_enabled = true
	environment.fog_density = 0.018
	environment.fog_light_color = Color(0.16, 0.2, 0.25)
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40, -25, 0)
	moon.light_color = Color(0.7, 0.8, 1.0)
	moon.light_energy = 0.7
	add_child(moon)
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 45
	floor_mesh.bottom_radius = 45
	floor_mesh.height = 0.2
	var ground := _mesh(floor_mesh, Vector3(0, -0.1, 0), Color(0.06, 0.08, 0.09))
	ground.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for index in range(36):
		var angle := rng.randf_range(0, TAU)
		var distance := rng.randf_range(12, 32)
		var position_3d := Vector3(sin(angle) * distance, 0, cos(angle) * distance)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.14
		trunk.bottom_radius = 0.6
		trunk.height = rng.randf_range(7, 13)
		var tree := _mesh(trunk, position_3d + Vector3.UP * trunk.height * 0.5, Color(0.13, 0.15, 0.17))
		tree.rotation.z = rng.randf_range(-0.15, 0.15)
		for branch in range(3):
			var branch_mesh := CylinderMesh.new()
			branch_mesh.top_radius = 0.02
			branch_mesh.bottom_radius = 0.15
			branch_mesh.height = 3.0
			var twig := _mesh(branch_mesh, position_3d + Vector3.UP * (4.0 + branch * 1.5), Color(0.16, 0.18, 0.2))
			twig.rotation = Vector3(0.4, angle + branch, 0.8)
	var particles := MultiMesh.new()
	particles.transform_format = MultiMesh.TRANSFORM_3D
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.025
	glow_mesh.height = 0.05
	glow_mesh.radial_segments = 6
	glow_mesh.rings = 3
	particles.mesh = glow_mesh
	particles.instance_count = 128
	fireflies = MultiMeshInstance3D.new()
	fireflies.multimesh = particles
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(0.8, 0.9, 1)
	fireflies.material_override = glow
	add_child(fireflies)
	var caps := MultiMesh.new()
	caps.transform_format = MultiMesh.TRANSFORM_3D
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.24
	cap_mesh.height = 0.2
	cap_mesh.radial_segments = 12
	cap_mesh.rings = 6
	caps.mesh = cap_mesh
	caps.instance_count = 40
	var cap_instances := MultiMeshInstance3D.new()
	cap_instances.multimesh = caps
	var cap_material := ShaderMaterial.new()
	cap_material.shader = load("res://scripts/mushroom.gdshader")
	cap_instances.material_override = cap_material
	add_child(cap_instances)
	for index in range(40):
		var angle := rng.randf_range(0, TAU)
		var distance := rng.randf_range(5, 15)
		var location := Vector3(sin(angle) * distance, 0.28, cos(angle) * distance)
		var scale_factor := rng.randf_range(0.5, 1.5)
		caps.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_factor), location))
	_update_fireflies()

func _mesh(mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1
	instance.material_override = material
	add_child(instance)
	return instance

func _process(delta: float) -> void:
	elapsed += delta
	_update_fireflies()

func _update_fireflies() -> void:
	for index in range(128):
		var phase := float(index) * 2.39996
		var radius := 5.0 + float(index % 13)
		var point := Vector3(sin(phase + elapsed * 0.035) * radius, 1.2 + float(index % 7) * 0.45 + sin(elapsed + phase) * 0.3, cos(phase + elapsed * 0.035) * radius)
		fireflies.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, point))

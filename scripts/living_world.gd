class_name LivingWorld
extends Node3D

# Geometric prototypes; the viewer and video stay stationary.
var world_id := 2
var moving: Array[Node3D] = []
var elapsed := 0.0
var materials: Dictionary = {}

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.018, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.68, 0.72)
	env.ambient_light_energy = 0.65
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = env
	add_child(atmosphere)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 0.8
	add_child(light)
	var ground := _box(Vector3(34, 0.2, 34), Vector3(0, -0.1, 0), 0.12)
	ground.create_trimesh_collision()
	match world_id:
		2: _observatory()
		3: _greenhouse()
		4: _express()
		5: _library()

func _mesh(shape: Mesh, at: Vector3, shade: float, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = at
	if not materials.has(shade):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(shade, shade, shade)
		mat.roughness = 0.8
		materials[shade] = mat
	node.material_override = materials[shade]
	if parent == null:
		add_child(node)
	else:
		parent.add_child(node)
	return node

func _box(size: Vector3, at: Vector3, shade: float, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, at, shade, parent)

func _ring(radius: float, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.06
	mesh.outer_radius = radius + 0.06
	mesh.rings = 48
	mesh.ring_segments = 8
	return _mesh(mesh, at, 0.65, parent)

func _observatory() -> void:
	for index in range(3):
		var pivot := Node3D.new()
		pivot.position = Vector3(-9, 6, -12)
		pivot.rotation.z = float(index) * 0.8
		add_child(pivot)
		_ring(3.0 + index * 0.6, Vector3.ZERO, pivot)
		moving.append(pivot)
	for index in range(80):
		var phase := index * 2.39996
		var star := SphereMesh.new()
		star.radius = 0.035
		star.height = 0.07
		star.radial_segments = 6
		star.rings = 3
		_mesh(star, Vector3(sin(phase) * 30, 7 + float(index % 17), cos(phase) * 30), 0.95)

func _greenhouse() -> void:
	for index in range(8):
		var arch := _ring(14, Vector3.ZERO)
		arch.rotation = Vector3(PI / 2, float(index) * PI / 8, 0)
	for index in range(7):
		var jelly := Node3D.new()
		jelly.position = Vector3(sin(index * 2.4) * 10, 4 + index * 0.35, cos(index * 2.4) * 10)
		add_child(jelly)
		var cap := SphereMesh.new()
		cap.radius = 0.65
		cap.height = 0.6
		_mesh(cap, Vector3.ZERO, 0.7, jelly)
		for strand in range(5):
			_box(Vector3(0.025, 1.8, 0.025), Vector3(sin(strand * TAU / 5) * 0.35, -1, cos(strand * TAU / 5) * 0.35), 0.5, jelly)
		moving.append(jelly)

func _express() -> void:
	_box(Vector3(7, 0.3, 30), Vector3(0, 0.05, 0), 0.25)
	for side in [-1.0, 1.0]:
		_box(Vector3(0.08, 0.15, 70), Vector3(side * 2.1, 0.2, 0), 0.6)
		_box(Vector3(0.08, 0.08, 30), Vector3(side * 3.4, 1.2, 0), 0.5)
		for index in range(8):
			_box(Vector3(0.08, 1.2, 0.08), Vector3(side * 3.4, 0.6, index * 4 - 14), 0.4)
		for index in range(3):
			_box(Vector3(1.4, 0.5, 1), Vector3(side * 2.3, 0.65, index * 4 + 2), 0.35)
	for index in range(14):
		_box(Vector3(4, 0.15, 0.25), Vector3(0, 0.02, index * 5 - 35), 0.3)

func _library() -> void:
	for index in range(10):
		var shelf := Node3D.new()
		var angle := index * TAU / 10
		shelf.position = Vector3(sin(angle) * 12, 2 + (index % 3), cos(angle) * 12)
		shelf.rotation.y = angle
		add_child(shelf)
		for level in range(3):
			_box(Vector3(3, 0.12, 0.7), Vector3(0, level * 1.1, 0), 0.3, shelf)
			for book in range(9):
				_box(Vector3(0.22, 0.65 + (book % 3) * 0.08, 0.45), Vector3(-1.2 + book * 0.3, level * 1.1 + 0.45, 0), 0.4 + float(book % 4) * 0.1, shelf)
		moving.append(shelf)

func _process(delta: float) -> void:
	elapsed += delta
	for index in range(moving.size()):
		if world_id == 2:
			moving[index].rotate_y(delta * 0.05 * (index + 1))
		else:
			moving[index].position.y += sin(elapsed * 0.5 + index) * delta * 0.08

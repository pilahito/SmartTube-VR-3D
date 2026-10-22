## Muebles con aristas redondeadas, hechos por código (sin assets). Cada pieza busca antes un modelo
## `res://models/<nombre>.glb`: si existe lo usa en lugar de la versión procedural.
class_name Furniture
extends RefCounted


## Caja con aristas redondeadas: malla suave (normales por vértice) de `n`×`n` cuadrados por cara.
static func rounded_box(size: Vector3, radius: float, n := 5) -> ArrayMesh:
	var h := size * 0.5
	var r := minf(radius, minf(h.x, minf(h.y, h.z)) - 0.001)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP],
		[Vector3.LEFT, Vector3.UP, Vector3.BACK],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK],
		[Vector3.DOWN, Vector3.BACK, Vector3.RIGHT],
		[Vector3.BACK, Vector3.UP, Vector3.RIGHT],
		[Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	for f in faces:
		var nrm: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		for j in n:
			for i in n:
				var corners: Array[Vector3] = []
				for c in [[i, j], [i + 1, j], [i, j + 1], [i + 1, j + 1]]:
					var a: float = lerpf(-1.0, 1.0, c[0] / float(n))
					var b: float = lerpf(-1.0, 1.0, c[1] / float(n))
					# Reparto no uniforme: más puntos cerca de las aristas, donde está la curvatura.
					a = signf(a) * pow(absf(a), 1.6)
					b = signf(b) * pow(absf(b), 1.6)
					var p := (nrm + u * a + v * b) * h
					var inner := Vector3(clampf(p.x, -(h.x - r), h.x - r), clampf(p.y, -(h.y - r), h.y - r), clampf(p.z, -(h.z - r), h.z - r))
					var dir := (p - inner).normalized()
					corners.append(inner + dir * r)
				var nn: Array[Vector3] = []
				for q in corners:
					var inner2 := Vector3(clampf(q.x, -(h.x - r), h.x - r), clampf(q.y, -(h.y - r), h.y - r), clampf(q.z, -(h.z - r), h.z - r))
					nn.append((q - inner2).normalized())
				for idx in [0, 2, 1, 1, 2, 3]:
					st.set_normal(nn[idx])
					st.add_vertex(corners[idx])
	return st.commit()


static func _node(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func mat(c: Color, rough := 0.85, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


## Modelo externo opcional: res://models/<name>.glb (o .gltf). Devuelve null si no existe.
static func model(model_name: String) -> Node3D:
	for ext in ["glb", "gltf"]:
		var path := "res://models/%s.%s" % [model_name, ext]
		if ResourceLoader.exists(path):
			var scene := load(path) as PackedScene
			if scene:
				return scene.instantiate() as Node3D
	return null


static func _place(parent: Node3D, node: Node3D, pos: Vector3, yaw: float) -> Node3D:
	node.position = pos
	node.rotation.y = yaw
	parent.add_child(node)
	return node


static func _cyl(parent: Node3D, top: float, bottom: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 14
	c.rings = 1
	return _node(parent, c, pos, m)


## Sofá de 3 plazas: base, respaldo, brazos, cojines de asiento y patas. Mira hacia -z.
static func sofa(parent: Node3D, pos: Vector3, yaw: float, fabric: Color, width := 4.2) -> Node3D:
	var ext := model("sofa")
	if ext:
		return _place(parent, ext, pos, yaw)
	var root := Node3D.new()
	var body := mat(fabric, 0.95)
	var cush := mat(fabric.lightened(0.08), 0.95)
	var depth := 1.5
	_node(root, rounded_box(Vector3(width, 0.45, depth), 0.12), Vector3(0, 0.45, 0), body)
	_node(root, rounded_box(Vector3(width, 0.95, 0.5), 0.2), Vector3(0, 0.95, depth * 0.5 - 0.25), body)
	for side in [-1.0, 1.0]:
		_node(root, rounded_box(Vector3(0.45, 0.8, depth), 0.18), Vector3(side * (width * 0.5 - 0.225), 0.8, 0), body)
	var seats := 3
	var sw := (width - 0.9) / seats
	for i in seats:
		var x := -width * 0.5 + 0.45 + sw * (i + 0.5)
		_node(root, rounded_box(Vector3(sw - 0.05, 0.28, depth - 0.55), 0.12), Vector3(x, 0.8, -0.2), cush)
		_node(root, rounded_box(Vector3(sw - 0.1, 0.7, 0.28), 0.12), Vector3(x, 1.15, depth * 0.5 - 0.62), cush).rotation_degrees.x = -12.0
	var wood := mat(Color(0.18, 0.12, 0.08), 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(root, 0.05, 0.035, 0.22, Vector3(sx * (width * 0.5 - 0.2), 0.11, sz * (depth * 0.5 - 0.2)), wood)
	return _place(parent, root, pos, yaw)


static func armchair(parent: Node3D, pos: Vector3, yaw: float, fabric: Color) -> Node3D:
	var ext := model("armchair")
	if ext:
		return _place(parent, ext, pos, yaw)
	var root := Node3D.new()
	var body := mat(fabric, 0.95)
	_node(root, rounded_box(Vector3(1.3, 0.4, 1.2), 0.12), Vector3(0, 0.4, 0), body)
	_node(root, rounded_box(Vector3(1.3, 0.9, 0.4), 0.16), Vector3(0, 0.85, 0.4), body)
	for side in [-1.0, 1.0]:
		_node(root, rounded_box(Vector3(0.28, 0.65, 1.2), 0.12), Vector3(side * 0.51, 0.65, 0), body)
	_node(root, rounded_box(Vector3(0.75, 0.22, 0.75), 0.1), Vector3(0, 0.67, -0.08), mat(fabric.lightened(0.1), 0.95))
	var wood := mat(Color(0.18, 0.12, 0.08), 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(root, 0.04, 0.03, 0.2, Vector3(sx * 0.5, 0.1, sz * 0.45), wood)
	return _place(parent, root, pos, yaw)


static func coffee_table(parent: Node3D, pos: Vector3, yaw: float, wood: Color) -> Node3D:
	var ext := model("coffee_table")
	if ext:
		return _place(parent, ext, pos, yaw)
	var root := Node3D.new()
	var m := mat(wood, 0.5)
	_node(root, rounded_box(Vector3(2.0, 0.07, 1.0), 0.03), Vector3(0, 0.46, 0), m)
	_node(root, rounded_box(Vector3(1.7, 0.05, 0.75), 0.02), Vector3(0, 0.2, 0), m)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(root, 0.03, 0.022, 0.44, Vector3(sx * 0.85, 0.22, sz * 0.38), m)
	_node(root, rounded_box(Vector3(0.35, 0.05, 0.26), 0.01), Vector3(-0.4, 0.51, 0.05), mat(Color(0.75, 0.2, 0.18), 0.7))
	_node(root, rounded_box(Vector3(0.33, 0.04, 0.24), 0.01), Vector3(-0.4, 0.56, 0.05), mat(Color(0.9, 0.88, 0.8), 0.7))
	var cup := _cyl(root, 0.06, 0.045, 0.09, Vector3(0.45, 0.54, -0.1), mat(Color(0.95, 0.95, 0.95), 0.3))
	cup.rotation.y = 0.5
	return _place(parent, root, pos, yaw)


## Lámpara de pie con pantalla cónica luminosa.
static func floor_lamp(parent: Node3D, pos: Vector3, glow: Color) -> Node3D:
	var ext := model("floor_lamp")
	if ext:
		return _place(parent, ext, pos, 0.0)
	var root := Node3D.new()
	var metal := mat(Color(0.12, 0.12, 0.14), 0.35)
	_cyl(root, 0.22, 0.25, 0.05, Vector3(0, 0.025, 0), metal)
	_cyl(root, 0.02, 0.02, 1.6, Vector3(0, 0.85, 0), metal)
	var shade := _cyl(root, 0.18, 0.3, 0.4, Vector3(0, 1.8, 0), mat(glow, 0.9, 2.2))
	shade.mesh.set("cap_top", false)
	return _place(parent, root, pos, 0.0)


static func plant(parent: Node3D, pos: Vector3, scale_factor := 1.0) -> Node3D:
	var ext := model("plant")
	if ext:
		return _place(parent, ext, pos, 0.0)
	var root := Node3D.new()
	_cyl(root, 0.32, 0.22, 0.55, Vector3(0, 0.275, 0), mat(Color(0.6, 0.35, 0.25), 0.8))
	_cyl(root, 0.3, 0.3, 0.04, Vector3(0, 0.55, 0), mat(Color(0.2, 0.12, 0.08), 1.0))
	var leaf := SphereMesh.new()
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 8
	leaf.rings = 4
	var green := mat(Color(0.14, 0.45, 0.2), 0.7)
	for i in 9:
		var a := TAU * i / 9.0
		var l := _node(root, leaf, Vector3(cos(a) * 0.22, 0.95 + (i % 3) * 0.18, sin(a) * 0.22), green)
		l.scale = Vector3(0.16, 0.55, 0.38)
		l.rotation = Vector3(0.0, -a, deg_to_rad(28.0 + (i % 3) * 12.0))
	root.scale = Vector3.ONE * scale_factor
	return _place(parent, root, pos, 0.0)


static func rug(parent: Node3D, pos: Vector3, size: Vector2, c: Color) -> Node3D:
	var root := Node3D.new()
	_node(root, rounded_box(Vector3(size.x, 0.04, size.y), 0.018, 3), Vector3.ZERO, mat(c, 1.0))
	_node(root, rounded_box(Vector3(size.x - 0.5, 0.045, size.y - 0.5), 0.018, 3), Vector3(0, 0.003, 0), mat(c.lightened(0.12), 1.0))
	return _place(parent, root, pos, 0.0)


## Mueble bajo (aparador / consola de TV) con puertas.
static func sideboard(parent: Node3D, pos: Vector3, yaw: float, wood: Color, width := 3.2) -> Node3D:
	var ext := model("sideboard")
	if ext:
		return _place(parent, ext, pos, yaw)
	var root := Node3D.new()
	var m := mat(wood, 0.55)
	_node(root, rounded_box(Vector3(width, 0.6, 0.5), 0.04), Vector3(0, 0.4, 0), m)
	var dark := mat(wood.darkened(0.35), 0.6)
	for i in 3:
		_node(root, rounded_box(Vector3(width / 3.0 - 0.1, 0.46, 0.03), 0.01, 3), Vector3(-width / 3.0 + i * width / 3.0, 0.4, 0.26), dark)
	for sx in [-1.0, 1.0]:
		_cyl(root, 0.03, 0.02, 0.1, Vector3(sx * (width * 0.5 - 0.15), 0.05, 0), m)
	return _place(parent, root, pos, yaw)

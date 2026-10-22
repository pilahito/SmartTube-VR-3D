## Los 16 escenarios del menú (docs/interfaz/escenarios.jpg), generados por código.
## La playa reutiliza el mundo existente; el resto son entornos sencillos (cielo, luz, niebla, suelo y
## geometría) pensados para que se parezcan en ambiente a los mockups, no réplicas de ellos.
class_name Scenarios
extends Node3D

signal applied(def: Dictionary)

const ROOM := Vector3(26.0, 6.5, 26.0)
const SAND_DRY := Color(0.93, 0.83, 0.62)
const SAND_WET := Color(0.62, 0.52, 0.38)
const SEA_DEEP := Color(0.02, 0.18, 0.32)
const SEA_SHALLOW := Color(0.10, 0.62, 0.66)
const SEA_FOAM := Color(0.95, 0.97, 1.0)

## Orden del menú: 4 columnas × 4 filas, como en la maqueta.
const LIST := [
	{"id": "bosque", "name": "Bosque natural", "kind": "forest",
		"sky_top": Color(0.35, 0.6, 0.8), "sky_horizon": Color(0.75, 0.88, 0.8), "ground": Color(0.1, 0.22, 0.07),
		"sun": Color(1.0, 0.95, 0.75), "sun_energy": 0.75, "sun_pitch": -40.0, "sun_yaw": 160.0,
		"ambient": Color(0.5, 0.65, 0.5), "ambient_energy": 0.55, "fog": Color(0.45, 0.62, 0.5), "fog_density": 0.02,
		"leaf": Color(0.13, 0.42, 0.16), "trunk": Color(0.28, 0.18, 0.1), "accent": Color(0.3, 0.6, 0.25), "wind": -14.0},
	{"id": "arcade", "name": "Retro Arcade", "kind": "room",
		"sky_top": Color(0.05, 0.02, 0.1), "sky_horizon": Color(0.1, 0.05, 0.2), "ground": Color(0.08, 0.06, 0.12),
		"wall": Color(0.16, 0.09, 0.28), "accent": Color(1.0, 0.2, 0.7), "accent2": Color(0.1, 0.9, 1.0),
		"light": Color(0.8, 0.4, 1.0), "light_energy": 1.4, "ambient": Color(0.5, 0.35, 0.75), "ambient_energy": 1.2},
	{"id": "gamer", "name": "Gamer RGB", "kind": "room",
		"sky_top": Color(0.03, 0.02, 0.08), "sky_horizon": Color(0.08, 0.04, 0.16), "ground": Color(0.04, 0.04, 0.06),
		"wall": Color(0.1, 0.1, 0.16), "accent": Color(0.7, 0.2, 1.0), "accent2": Color(0.1, 0.8, 1.0),
		"light": Color(0.6, 0.3, 1.0), "light_energy": 1.2, "ambient": Color(0.4, 0.3, 0.65), "ambient_energy": 1.1},
	{"id": "cyberpunk", "name": "Cyberpunk", "kind": "city",
		"sky_top": Color(0.06, 0.03, 0.18), "sky_horizon": Color(0.7, 0.18, 0.55), "ground": Color(0.05, 0.04, 0.09),
		"sun": Color(0.9, 0.4, 1.0), "sun_energy": 0.5, "sun_pitch": -20.0, "sun_yaw": 160.0,
		"ambient": Color(0.45, 0.25, 0.6), "ambient_energy": 0.8, "fog": Color(0.45, 0.15, 0.45), "fog_density": 0.012,
		"accent": Color(1.0, 0.2, 0.75), "accent2": Color(0.1, 0.85, 1.0), "wind": -80.0},
	{"id": "cine", "name": "Cine clásico", "kind": "room",
		"sky_top": Color(0.05, 0.03, 0.03), "sky_horizon": Color(0.1, 0.06, 0.05), "ground": Color(0.12, 0.09, 0.08),
		"wall": Color(0.2, 0.15, 0.13), "accent": Color(0.65, 0.08, 0.1), "accent2": Color(1.0, 0.75, 0.4),
		"light": Color(1.0, 0.8, 0.55), "light_energy": 0.9, "ambient": Color(0.55, 0.42, 0.36), "ambient_energy": 1.1},
	{"id": "espacio", "name": "Espacio", "kind": "space",
		"sky_top": Color(0.0, 0.0, 0.02), "sky_horizon": Color(0.05, 0.03, 0.12), "ground": Color(0.06, 0.07, 0.1),
		"sun": Color(1.0, 0.97, 0.9), "sun_energy": 1.3, "sun_pitch": -25.0, "sun_yaw": 120.0,
		"ambient": Color(0.2, 0.22, 0.4), "ambient_energy": 0.6, "fog": Color(0, 0, 0), "fog_density": 0.0,
		"accent": Color(0.3, 0.6, 1.0), "wind": -80.0},
	{"id": "montanas", "name": "Montañas", "kind": "mountains",
		"sky_top": Color(0.28, 0.5, 0.88), "sky_horizon": Color(0.8, 0.88, 0.96), "ground": Color(0.2, 0.3, 0.14),
		"sun": Color(1.0, 0.96, 0.88), "sun_energy": 0.9, "sun_pitch": -42.0, "sun_yaw": 160.0,
		"ambient": Color(0.55, 0.65, 0.8), "ambient_energy": 0.6, "fog": Color(0.78, 0.86, 0.95), "fog_density": 0.006,
		"accent": Color(0.55, 0.58, 0.62), "wind": -12.0},
	{"id": "playa", "name": "Playa", "kind": "beach",
		"sky_top": Color(0.22, 0.47, 0.85), "sky_horizon": Color(0.72, 0.84, 0.95), "ground": Color(0.2, 0.35, 0.5),
		"sun": Color(1.0, 0.95, 0.85), "sun_energy": 1.1, "sun_pitch": -35.0, "sun_yaw": 160.0,
		"ambient_energy": 0.9, "fog": Color(0.75, 0.85, 0.95), "fog_density": 0.004,
		"tint": Color(1, 1, 1), "accent": Color(0.1, 0.62, 0.66), "wind": -16.0},
	{"id": "bosque_magico", "name": "Bosque mágico", "kind": "forest",
		"sky_top": Color(0.05, 0.03, 0.2), "sky_horizon": Color(0.2, 0.1, 0.4), "ground": Color(0.06, 0.1, 0.16),
		"sun": Color(0.5, 0.55, 1.0), "sun_energy": 0.4, "sun_pitch": -45.0, "sun_yaw": 160.0,
		"ambient": Color(0.35, 0.3, 0.7), "ambient_energy": 0.8, "fog": Color(0.18, 0.1, 0.4), "fog_density": 0.02,
		"leaf": Color(0.35, 0.2, 0.7), "trunk": Color(0.12, 0.1, 0.22), "accent": Color(0.3, 0.9, 0.9), "glow": true, "wind": -22.0},
	{"id": "salon", "name": "Salón", "kind": "room",
		"sky_top": Color(0.5, 0.4, 0.3), "sky_horizon": Color(0.6, 0.5, 0.4), "ground": Color(0.35, 0.22, 0.12),
		"wall": Color(0.78, 0.68, 0.55), "accent": Color(0.4, 0.22, 0.12), "accent2": Color(1.0, 0.9, 0.7),
		"light": Color(1.0, 0.85, 0.6), "light_energy": 1.3, "ambient": Color(0.75, 0.65, 0.5), "ambient_energy": 0.9},
	{"id": "salon_nocturno", "name": "Salón nocturno", "kind": "room",
		"sky_top": Color(0.04, 0.05, 0.1), "sky_horizon": Color(0.08, 0.1, 0.18), "ground": Color(0.2, 0.12, 0.07),
		"wall": Color(0.22, 0.17, 0.14), "accent": Color(1.0, 0.45, 0.1), "accent2": Color(0.15, 0.3, 0.7),
		"light": Color(1.0, 0.6, 0.3), "light_energy": 0.9, "ambient": Color(0.5, 0.4, 0.4), "ambient_energy": 1.0},
	{"id": "salon_moderno", "name": "Salón moderno", "kind": "room",
		"sky_top": Color(0.7, 0.8, 0.9), "sky_horizon": Color(0.8, 0.85, 0.9), "ground": Color(0.6, 0.58, 0.55),
		"wall": Color(0.88, 0.88, 0.86), "accent": Color(0.35, 0.37, 0.4), "accent2": Color(0.8, 0.9, 1.0),
		"light": Color(1.0, 1.0, 0.95), "light_energy": 1.4, "ambient": Color(0.9, 0.92, 0.95), "ambient_energy": 1.0},
	{"id": "salon_futurista", "name": "Salón futurista", "kind": "room",
		"sky_top": Color(0.02, 0.05, 0.1), "sky_horizon": Color(0.05, 0.12, 0.2), "ground": Color(0.07, 0.1, 0.14),
		"wall": Color(0.18, 0.25, 0.34), "accent": Color(0.1, 0.8, 1.0), "accent2": Color(0.3, 0.5, 1.0),
		"light": Color(0.5, 0.85, 1.0), "light_energy": 1.1, "ambient": Color(0.45, 0.65, 0.85), "ambient_energy": 1.2},
	{"id": "playa_tropical", "name": "Playa tropical", "kind": "beach",
		"sky_top": Color(0.1, 0.5, 0.95), "sky_horizon": Color(0.6, 0.88, 0.98), "ground": Color(0.1, 0.4, 0.55),
		"sun": Color(1.0, 0.97, 0.88), "sun_energy": 1.25, "sun_pitch": -55.0, "sun_yaw": 160.0,
		"ambient_energy": 1.0, "fog": Color(0.7, 0.92, 0.98), "fog_density": 0.003,
		"tint": Color(0.9, 1.15, 1.1), "accent": Color(0.1, 0.8, 0.8), "wind": -16.0},
	{"id": "playa_atardecer", "name": "Playa atardecer", "kind": "beach",
		"sky_top": Color(0.18, 0.2, 0.5), "sky_horizon": Color(1.0, 0.55, 0.3), "ground": Color(0.3, 0.2, 0.3),
		"sun": Color(1.0, 0.6, 0.3), "sun_energy": 1.0, "sun_pitch": -7.0, "sun_yaw": 160.0,
		"ambient_energy": 0.7, "fog": Color(1.0, 0.65, 0.45), "fog_density": 0.006,
		"tint": Color(1.0, 0.7, 0.6), "accent": Color(1.0, 0.5, 0.3), "wind": -16.0},
	{"id": "playa_noche", "name": "Playa de noche", "kind": "beach",
		"sky_top": Color(0.01, 0.02, 0.08), "sky_horizon": Color(0.06, 0.1, 0.22), "ground": Color(0.02, 0.04, 0.1),
		"sun": Color(0.6, 0.7, 1.0), "sun_energy": 0.35, "sun_pitch": -35.0, "sun_yaw": 160.0,
		"ambient_energy": 0.35, "fog": Color(0.05, 0.08, 0.18), "fog_density": 0.006,
		"tint": Color(0.16, 0.2, 0.38), "accent": Color(0.2, 0.3, 0.6), "wind": -18.0},
]

var env: Environment
var sun: DirectionalLight3D
var sky_proc: ProceduralSkyMaterial
var sky_stars: PanoramaSkyMaterial
var beach_root: Node3D
var sand: StaticBody3D
var ocean: MeshInstance3D
var current := ""
var _root: Node3D


func _ready() -> void:
	_root = Node3D.new()
	_root.name = "Escenario"
	add_child(_root)


static func get_def(id: String) -> Dictionary:
	for d in LIST:
		if d["id"] == id:
			return d
	return LIST[7]


## Enlaza el mundo de la playa y el entorno que ya existen en la escena principal.
func setup(we: WorldEnvironment, light: DirectionalLight3D, beach: Node3D, sand_body: StaticBody3D, ocean_mesh: MeshInstance3D) -> void:
	env = we.environment
	sky_proc = env.sky.sky_material
	sun = light
	beach_root = beach
	sand = sand_body
	ocean = ocean_mesh


func apply(id: String) -> void:
	var d := get_def(id)
	current = d["id"]
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()
	var kind: String = d["kind"]
	var is_beach := kind == "beach"
	beach_root.visible = is_beach
	sand.collision_layer = 1 if is_beach else 0
	_apply_light_and_sky(d)
	if is_beach:
		_tint_beach(d["tint"])
	else:
		_build_ground(d)
	match kind:
		"forest": _forest(d)
		"mountains": _mountains(d)
		"city": _city(d)
		"space": _space(d)
		"room": _room(d)
	applied.emit(d)


# ---------------------------------------------------------------- cielo, luz y niebla

func _apply_light_and_sky(d: Dictionary) -> void:
	var kind: String = d["kind"]
	sky_proc.sky_top_color = d["sky_top"]
	sky_proc.sky_horizon_color = d["sky_horizon"]
	sky_proc.ground_horizon_color = d["sky_horizon"]
	sky_proc.ground_bottom_color = d["ground"]
	env.sky.sky_material = sky_proc
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if kind == "beach" else Environment.AMBIENT_SOURCE_COLOR
	if d.has("ambient"):
		env.ambient_light_color = d["ambient"]
	env.ambient_light_energy = d["ambient_energy"]
	env.fog_enabled = d.has("fog") and d["fog_density"] > 0.0
	if env.fog_enabled:
		env.fog_light_color = d["fog"]
		env.fog_density = d["fog_density"]
	var lit := d.has("sun")
	sun.visible = lit
	if lit:
		sun.light_color = d["sun"]
		sun.light_energy = d["sun_energy"]
		sun.rotation_degrees = Vector3(d["sun_pitch"], d["sun_yaw"], 0)


func _tint_beach(t: Color) -> void:
	var sm: ShaderMaterial = sand.get_child(0).mesh.surface_get_material(0)
	sm.set_shader_parameter("dry", SAND_DRY * t)
	sm.set_shader_parameter("wet", SAND_WET * t)
	var om: ShaderMaterial = ocean.mesh.material
	om.set_shader_parameter("deep_color", SEA_DEEP * t)
	om.set_shader_parameter("shallow_color", SEA_SHALLOW * t)
	om.set_shader_parameter("foam_color", SEA_FOAM * Color(minf(t.r + 0.1, 1.0), minf(t.g + 0.1, 1.0), minf(t.b + 0.1, 1.0)))


# ---------------------------------------------------------------- piezas comunes

func _mat(c: Color, emit := false, energy := 2.0, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
	return m


func _mesh_node(mesh: Mesh, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else _root).add_child(mi)
	return mi


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh_node(m, pos, mat, parent)


func _glow(size: Vector3, pos: Vector3, c: Color, energy := 3.0) -> MeshInstance3D:
	return _box(size, pos, _mat(c, true, energy))


func _omni(pos: Vector3, c: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng
	_root.add_child(l)
	return l


func _static_floor(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	_root.add_child(body)


func _scatter(mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color] = []) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(mmi)


func _build_ground(d: Dictionary) -> void:
	var kind: String = d["kind"]
	if kind == "room" or kind == "space":
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(500, 500)
	_mesh_node(plane, Vector3.ZERO, _mat(d["ground"]))
	_static_floor(Vector3(500, 0.2, 500), Vector3(0, -0.1, 0))


## Dispersión al azar fuera de la zona frente al usuario (por donde se ve la pantalla).
func _spots(n: int, r_min: float, r_max: float, seed_value: int) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array[Vector2] = []
	var guard := 0
	while out.size() < n and guard < n * 20:
		guard += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(r_min, r_max)
		var p := Vector2(cos(a), sin(a)) * r
		if absf(p.x) < 9.5 and p.y < 2.0 and p.y > -14.0:
			continue
		out.append(p)
	return out


# ---------------------------------------------------------------- bosques

func _tree_mesh(trunk: Color, leaf: Color, glow: bool) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var t := CylinderMesh.new()
	t.top_radius = 0.18
	t.bottom_radius = 0.26
	t.height = 2.4
	t.radial_segments = 6
	t.rings = 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(_mat(trunk))
	st.append_from(t, 0, Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 0)))
	st.commit(mesh)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.set_material(_mat(leaf, glow, 0.35))
	for i in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 2.0 - i * 0.5
		cone.height = 2.3
		cone.radial_segments = 7
		cone.rings = 1
		st2.append_from(cone, 0, Transform3D(Basis.IDENTITY, Vector3(0, 3.0 + i * 1.2, 0)))
	st2.commit(mesh)
	return mesh


func _forest(d: Dictionary) -> void:
	var glow: bool = d.has("glow")
	var xforms: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for p in _spots(260, 6.0, 90.0, 7):
		var s := rng.randf_range(0.8, 1.9)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
		xforms.append(Transform3D(b, Vector3(p.x, 0, p.y)))
	_scatter(_tree_mesh(d["trunk"], d["leaf"], glow), xforms)
	if glow:
		var orbs: Array[Transform3D] = []
		for p in _spots(90, 3.0, 40.0, 5):
			orbs.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.5, 1.4)), Vector3(p.x, rng.randf_range(0.4, 3.2), p.y)))
		var orb := SphereMesh.new()
		orb.radius = 0.08
		orb.height = 0.16
		orb.radial_segments = 8
		orb.rings = 4
		orb.material = _mat(d["accent"], true, 4.0)
		_scatter(orb, orbs)


# ---------------------------------------------------------------- montañas

func _mountains(d: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 7
	cone.rings = 1
	var rock := cone.duplicate() as CylinderMesh
	rock.material = _mat(d["accent"])
	var snow := cone.duplicate() as CylinderMesh
	snow.material = _mat(Color(0.95, 0.97, 1.0))
	var rocks: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	for i in 46:
		var a := rng.randf() * TAU
		var r := rng.randf_range(70.0, 190.0)
		var h := rng.randf_range(35.0, 95.0)
		var w := h * rng.randf_range(0.9, 1.4)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		var yaw := Basis(Vector3.UP, rng.randf() * TAU)
		rocks.append(Transform3D(yaw.scaled(Vector3(w, h, w)), pos + Vector3(0, h * 0.5, 0)))
		caps.append(Transform3D(yaw.scaled(Vector3(w * 0.4, h * 0.4, w * 0.4)), pos + Vector3(0, h * 0.8, 0)))
	_scatter(rock, rocks)
	_scatter(snow, caps)
	var pines := _spots(90, 8.0, 45.0, 3)
	var tx: Array[Transform3D] = []
	for p in pines:
		var s := rng.randf_range(0.7, 1.4)
		tx.append(Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), Vector3(p.x, 0, p.y)))
	_scatter(_tree_mesh(Color(0.25, 0.17, 0.1), Color(0.12, 0.3, 0.16), false), tx)


# ---------------------------------------------------------------- ciudad cyberpunk

func _city(d: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var palette := [d["accent"], d["accent2"], Color(0.7, 0.3, 1.0), Color(1.0, 0.8, 0.3)]
	for p in _spots(110, 22.0, 120.0, 13):
		var w := rng.randf_range(6.0, 14.0)
		var h := rng.randf_range(18.0, 85.0)
		var b := Basis.IDENTITY.scaled(Vector3(w, h, w))
		xforms.append(Transform3D(b, Vector3(p.x, h * 0.5, p.y)))
		colors.append(palette[rng.randi() % palette.size()])
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, fog_disabled;
varying vec4 vc;
varying vec3 wpos;
varying vec3 wnrm;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void vertex() {
	vc = COLOR;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 cell = vec2((wpos.x + wpos.z) * 0.8, wpos.y * 0.55);
	vec2 id = floor(cell);
	vec2 f = fract(cell);
	float lit = step(0.55, hash(id)) * step(0.15, f.x) * step(f.x, 0.8) * step(0.2, f.y) * step(f.y, 0.7);
	lit *= 1.0 - step(0.5, abs(wnrm.y));
	vec3 base = vec3(0.03, 0.02, 0.07);
	ALBEDO = base + vc.rgb * lit * (0.7 + 0.5 * hash(id + 7.0));
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	box.material = m
	_scatter(box, xforms, colors)
	# carteles de neón a los lados de la pantalla
	var i := 0
	for x in [-14.0, -11.0, 11.0, 14.0]:
		_glow(Vector3(0.4, 7.0, 0.4), Vector3(x, 3.5, -16.0 - i), palette[i % 2], 4.0)
		i += 2
	_omni(Vector3(0, 6, -6), d["accent"], 1.2, 40.0)


# ---------------------------------------------------------------- espacio

func _space(d: Dictionary) -> void:
	if sky_stars == null:
		var img := Image.create(2048, 1024, false, Image.FORMAT_RGB8)
		img.fill(Color(0.0, 0.0, 0.02))
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 4500:
			var v := rng.randf_range(0.35, 1.0)
			var x := rng.randi() % 2047
			var y := rng.randi() % 1023
			var c := Color(v, v, minf(v + 0.1, 1.0))
			img.set_pixel(x, y, c)
			if rng.randf() < 0.2:
				img.set_pixel(x + 1, y, c)
				img.set_pixel(x, y + 1, c)
		sky_stars = PanoramaSkyMaterial.new()
		sky_stars.panorama = ImageTexture.create_from_image(img)
	env.sky.sky_material = sky_stars
	var planet := SphereMesh.new()
	planet.radius = 38.0
	planet.height = 76.0
	_mesh_node(planet, Vector3(-70, 30, -130), _mat(Color(0.2, 0.4, 0.9), false, 1.0, 0.6))
	var moon := SphereMesh.new()
	moon.radius = 9.0
	moon.height = 18.0
	_mesh_node(moon, Vector3(60, 45, -110), _mat(Color(0.6, 0.58, 0.55)))
	var disc := CylinderMesh.new()
	disc.top_radius = 7.5
	disc.bottom_radius = 7.5
	disc.height = 0.2
	_mesh_node(disc, Vector3(0, -0.1, 0), _mat(d["ground"], false, 1.0, 0.85))
	var ring := TorusMesh.new()
	ring.inner_radius = 7.3
	ring.outer_radius = 7.6
	_mesh_node(ring, Vector3(0, 0.02, 0), _mat(d["accent"], true, 1.6))
	_static_floor(Vector3(15, 0.2, 15), Vector3(0, -0.1, 0))


# ---------------------------------------------------------------- salas

func _checker(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, a)
	img.set_pixel(1, 1, a)
	img.set_pixel(1, 0, b)
	img.set_pixel(0, 1, b)
	return ImageTexture.create_from_image(img)


func _room(d: Dictionary) -> void:
	var w := ROOM.x
	var h := ROOM.y
	var dep := ROOM.z
	var wall := _mat(d["wall"])
	# suelo (con ajedrez en el arcade)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(w, dep)
	var floor_mat := _mat(d["ground"], false, 1.0, 0.45)
	if d["id"] == "arcade":
		floor_mat.albedo_texture = _checker(Color(0.12, 0.08, 0.2), Color(0.03, 0.02, 0.06))
		floor_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		floor_mat.uv1_scale = Vector3(w * 0.5, dep * 0.5, 1)
	_mesh_node(floor_mesh, Vector3.ZERO, floor_mat)
	_static_floor(Vector3(w, 0.2, dep), Vector3(0, -0.1, 0))
	# techo y paredes
	_box(Vector3(w, 0.2, dep), Vector3(0, h + 0.1, 0), wall)
	_box(Vector3(w, h, 0.2), Vector3(0, h * 0.5, -dep * 0.5), wall)
	_box(Vector3(w, h, 0.2), Vector3(0, h * 0.5, dep * 0.5), wall)
	_box(Vector3(0.2, h, dep), Vector3(-w * 0.5, h * 0.5, 0), wall)
	_box(Vector3(0.2, h, dep), Vector3(w * 0.5, h * 0.5, 0), wall)
	_omni(Vector3(0, h - 0.8, -5), d["light"], d["light_energy"] * 2.2, 34.0)
	_omni(Vector3(0, h - 0.8, 6), d["light"], d["light_energy"] * 1.6, 30.0)
	match d["id"]:
		"arcade": _room_arcade(d)
		"gamer": _room_gamer(d)
		"cine": _room_cinema(d)
		"salon": _room_lounge(d, Color(1.0, 0.92, 0.75), false)
		"salon_nocturno": _room_lounge(d, d["accent2"], true)
		"salon_moderno": _room_lounge(d, d["accent2"], false)
		"salon_futurista": _room_future(d)


func _room_arcade(d: Dictionary) -> void:
	var body := _mat(Color(0.1, 0.08, 0.18))
	var i := 0
	for z in [-9.0, -5.5, -2.0, 1.5, 5.0, 8.5]:
		for side in [-1.0, 1.0]:
			var x: float = side * (ROOM.x * 0.5 - 0.8)
			_box(Vector3(1.0, 2.0, 0.9), Vector3(x, 1.0, z), body)
			var c: Color = d["accent"] if i % 2 == 0 else d["accent2"]
			_glow(Vector3(0.05, 0.7, 0.6), Vector3(x - side * 0.5, 1.45, z), c, 3.5)
			i += 1
	_glow(Vector3(ROOM.x, 0.08, 0.08), Vector3(0, ROOM.y - 0.3, -ROOM.z * 0.5 + 0.2), d["accent"], 4.0)
	_glow(Vector3(0.08, 0.08, ROOM.z), Vector3(-6, ROOM.y - 0.3, 0), d["accent2"], 4.0)
	_glow(Vector3(0.08, 0.08, ROOM.z), Vector3(6, ROOM.y - 0.3, 0), d["accent"], 4.0)


func _room_gamer(d: Dictionary) -> void:
	for y in [0.15, ROOM.y - 0.2]:
		_glow(Vector3(ROOM.x, 0.1, 0.1), Vector3(0, y, -ROOM.z * 0.5 + 0.2), d["accent"], 4.0)
		_glow(Vector3(0.1, 0.1, ROOM.z), Vector3(-ROOM.x * 0.5 + 0.2, y, 0), d["accent2"], 4.0)
		_glow(Vector3(0.1, 0.1, ROOM.z), Vector3(ROOM.x * 0.5 - 0.2, y, 0), d["accent"], 4.0)
	var desk := _mat(Color(0.08, 0.08, 0.1))
	_box(Vector3(5.0, 0.1, 1.4), Vector3(0, 0.8, 5.0), desk)
	for x in [-2.2, 2.2]:
		_box(Vector3(0.1, 0.8, 1.2), Vector3(x, 0.4, 5.0), desk)
	_glow(Vector3(4.8, 0.05, 0.05), Vector3(0, 0.76, 5.65), d["accent2"], 4.0)
	_glow(Vector3(0.4, 0.4, 0.4), Vector3(-ROOM.x * 0.5 + 1.0, 0.2, -6.0), d["accent"], 3.0)


func _room_cinema(d: Dictionary) -> void:
	var curtain := _mat(d["accent"], false, 1.0, 0.95)
	for side in [-1.0, 1.0]:
		_box(Vector3(5.0, ROOM.y, 0.6), Vector3(side * 8.0, ROOM.y * 0.5, -ROOM.z * 0.5 + 0.5), curtain)
		_box(Vector3(5.0, 0.8, 0.6), Vector3(side * 3.6, ROOM.y - 0.4, -ROOM.z * 0.5 + 0.5), curtain)
	_box(Vector3(2.4, 0.02, ROOM.z - 2.0), Vector3(0, 0.02, 0), curtain)
	var i := 0
	for z in [-9.0, -3.0, 3.0, 9.0]:
		for side in [-1.0, 1.0]:
			_glow(Vector3(0.12, 0.35, 0.3), Vector3(side * (ROOM.x * 0.5 - 0.2), 2.4, z), d["accent2"], 3.0)
			i += 1


## Salón: sofá, ventana y, según la variante, chimenea o luz de ciudad.
func _room_lounge(d: Dictionary, window: Color, fireplace: bool) -> void:
	var sofa := _mat(d["accent"], false, 1.0, 0.95)
	_box(Vector3(4.2, 0.8, 1.3), Vector3(0, 0.4, 8.5), sofa)
	_box(Vector3(4.2, 1.1, 0.4), Vector3(0, 1.0, 9.1), sofa)
	_box(Vector3(1.6, 0.5, 1.2), Vector3(-4.0, 0.25, 6.5), sofa)
	_box(Vector3(2.4, 0.45, 1.1), Vector3(0, 0.22, 5.2), _mat(d["accent"].darkened(0.3)))
	var strong := 2.5 if d["id"] == "salon_moderno" else 1.6
	for z in [-6.0, 0.0, 6.0]:
		_glow(Vector3(0.1, 3.0, 4.0), Vector3(ROOM.x * 0.5 - 0.15, 2.6, z), window, strong)
	if fireplace:
		_box(Vector3(3.2, 2.4, 0.6), Vector3(-9.0, 1.2, -ROOM.z * 0.5 + 0.5), _mat(Color(0.12, 0.1, 0.1)))
		_glow(Vector3(1.8, 0.9, 0.1), Vector3(-9.0, 0.7, -ROOM.z * 0.5 + 0.85), d["accent"], 5.0)
		_omni(Vector3(-9.0, 1.0, -ROOM.z * 0.5 + 2.0), d["accent"], 2.2, 14.0)


func _room_future(d: Dictionary) -> void:
	for x in [-6.0, -2.0, 2.0, 6.0]:
		_glow(Vector3(0.06, 0.04, ROOM.z - 2.0), Vector3(x, 0.03, 0), d["accent"], 3.5)
		_glow(Vector3(0.06, 0.04, ROOM.z - 2.0), Vector3(x, ROOM.y - 0.05, 0), d["accent2"], 3.5)
	var ring := TorusMesh.new()
	ring.inner_radius = 4.4
	ring.outer_radius = 4.6
	var r := _mesh_node(ring, Vector3(0, ROOM.y - 0.12, 2.0), _mat(d["accent"], true, 4.0))
	r.scale = Vector3(1, 0.2, 1)
	_glow(Vector3(ROOM.x, 0.1, 0.1), Vector3(0, 1.6, -ROOM.z * 0.5 + 0.2), d["accent2"], 3.5)

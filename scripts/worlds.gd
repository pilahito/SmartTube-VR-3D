## Catálogo de mundos. Cada mundo se construye por código dentro de un nodo contenedor,
## con su cielo, luces, suelo (capa 1, para el teletransporte), decorado y sonido.
## Al cambiar de mundo, main.gd borra el contenedor entero y construye el siguiente.
class_name Worlds
extends RefCounted

const PANORAMA_DIR := "res://worlds/panoramas/"
## Carpetas donde el usuario puede dejar sus propias fotos 360° (equirectangulares 2:1).
const USER_PANORAMA_DIRS := [
	"user://panoramas",
	"/storage/emulated/0/Android/data/app.smarttube.vr3d/files/panoramas",
]
const IMAGE_EXTENSIONS := ["jpg", "jpeg", "png", "webp"]
const MAX_PANORAMA_WIDTH := 4096

const BUILTIN := [
	{"id": "playa_dia", "name": "Playa (día)"},
	{"id": "playa_atardecer", "name": "Playa (atardecer)"},
	{"id": "playa_noche", "name": "Playa (noche)"},
	{"id": "cine", "name": "Sala de cine"},
	{"id": "salon", "name": "Salón"},
	{"id": "espacio", "name": "Espacio"},
	{"id": "pano:res://worlds/panoramas/aurora_boreal.jpg", "name": "360° Aurora boreal"},
	{"id": "pano:res://worlds/panoramas/nebulosa.jpg", "name": "360° Nebulosa"},
]


## Lista de mundos: los incluidos + una entrada por cada foto 360° del usuario.
static func catalog() -> Array:
	var list := BUILTIN.duplicate(true)
	for dir_path: String in USER_PANORAMA_DIRS:
		if dir_path.begins_with("/storage/") and OS.get_name() != "Android":
			continue
		DirAccess.make_dir_recursive_absolute(dir_path)
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		var files := Array(dir.get_files())
		files.sort()
		for f: String in files:
			if f.get_extension().to_lower() in IMAGE_EXTENSIONS:
				list.append({"id": "pano:" + dir_path.path_join(f), "name": "360° " + f.get_basename()})
	return list


## Construye el mundo `id` dentro de `parent`. Devuelve los ajustes de la pantalla y
## el punto de aparición: {"spawn": Vector3, "screen_distance": float, "screen_width": float}.
static func build(id: String, parent: Node3D) -> Dictionary:
	if id.begins_with("pano:"):
		return _build_panorama(parent, id.substr(5))
	match id:
		"playa_atardecer": return _build_beach(parent, "atardecer")
		"playa_noche": return _build_beach(parent, "noche")
		"cine": return _build_cinema(parent)
		"salon": return _build_living_room(parent)
		"espacio": return _build_space(parent)
	return _build_beach(parent, "dia")


# ---------------------------------------------------------------- playa

static func _build_beach(parent: Node3D, preset: String) -> Dictionary:
	WorldBuilder.build_environment(parent, preset)
	var sand := WorldBuilder.build_sand(parent)
	WorldBuilder.build_ocean(parent, preset)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var noise: FastNoiseLite = sand.get_meta("noise")
	var palm_spots := [Vector3(-7, 0, 3), Vector3(-9.5, 0, 7), Vector3(8, 0, 2), Vector3(11, 0, 6),
		Vector3(-15, 0, 12), Vector3(16, 0, 11), Vector3(-4, 0, 14), Vector3(5, 0, 16), Vector3(-22, 0, 5), Vector3(24, 0, 4)]
	for p in palm_spots:
		p.y = WorldBuilder.sand_height(p.x, p.z, noise) - 0.1
		WorldBuilder.build_palm(parent, p, rng)
	WorldBuilder.build_rocks(parent, rng, noise)
	if preset == "noche":
		_add_campfire(parent, Vector3(-3.5, WorldBuilder.sand_height(-3.5, 4.0, noise), 4.0))

	var quiet := -6.0 if preset == "noche" else 0.0
	for x in [-25.0, 0.0, 25.0]:
		var ocean := _sound_3d(parent, "res://audio/ocean_waves.wav", Vector3(x, 0.5, WorldBuilder.SHORE_Z - 2))
		ocean.unit_size = 25.0
		ocean.volume_db = -2.0 + quiet
	_sound(parent, "res://audio/wind.wav", -16.0 + quiet)
	return {"spawn": Vector3(0, WorldBuilder.sand_height(0, 0, noise) + 0.05, 0), "screen_distance": 10.0, "screen_width": 8.0}


## Hoguera: troncos, llamas emisivas y una luz cálida que parpadea.
static func _add_campfire(parent: Node3D, pos: Vector3) -> void:
	var fire := Node3D.new()
	fire.name = "Hoguera"
	fire.position = pos
	parent.add_child(fire)
	var log_mat := _mat(Color(0.25, 0.15, 0.08), 1.0)
	for i in 4:
		var l := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.07; cyl.bottom_radius = 0.07; cyl.height = 0.9; cyl.radial_segments = 8
		l.mesh = cyl
		l.material_override = log_mat
		l.rotation = Vector3(deg_to_rad(70), TAU * i / 4.0, 0)
		l.position = Vector3(0, 0.15, 0)
		fire.add_child(l)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.55, 0.15)
	for i in 3:
		var f := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0; cone.bottom_radius = 0.18 - i * 0.04; cone.height = 0.5 + i * 0.15; cone.radial_segments = 8
		f.mesh = cone
		f.material_override = flame_mat
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.position = Vector3((i - 1) * 0.06, 0.3 + i * 0.05, 0)
		fire.add_child(f)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.3)
	light.light_energy = 2.5
	light.omni_range = 8.0
	light.position = Vector3(0, 0.8, 0)
	fire.add_child(light)
	var tw := light.create_tween().set_loops()
	tw.tween_property(light, "light_energy", 1.8, 0.17)
	tw.tween_property(light, "light_energy", 2.8, 0.23)
	tw.tween_property(light, "light_energy", 2.2, 0.11)


# ---------------------------------------------------------------- sala de cine

static func _build_cinema(parent: Node3D) -> Dictionary:
	var env := _dark_environment(Color(0.0, 0.0, 0.0), Color(0.5, 0.4, 0.4), 0.12)
	_add_environment(parent, env)

	const W := 32.0   # ancho
	const L := 42.0   # largo (de z = -28 a z = 14)
	const H := 13.0   # alto
	var z0 := -28.0
	var wall := _mat(Color(0.16, 0.06, 0.07), 0.9)
	var carpet := _mat(Color(0.12, 0.03, 0.05), 1.0)
	var dark := _mat(Color(0.03, 0.03, 0.035), 1.0)
	_floor(parent, Vector3(W, 0.2, L), Vector3(0, -0.1, z0 + L * 0.5), carpet)
	_box(parent, Vector3(W, 0.2, L), Vector3(0, H, z0 + L * 0.5), dark)               # techo
	_box(parent, Vector3(W, H, 0.2), Vector3(0, H * 0.5, z0), dark)                    # pared de la pantalla
	_box(parent, Vector3(W, H, 0.2), Vector3(0, H * 0.5, z0 + L), wall)                # pared del fondo
	_box(parent, Vector3(0.2, H, L), Vector3(-W * 0.5, H * 0.5, z0 + L * 0.5), wall)   # izquierda
	_box(parent, Vector3(0.2, H, L), Vector3(W * 0.5, H * 0.5, z0 + L * 0.5), wall)    # derecha

	# Paneles acústicos en las paredes laterales
	var panel_mat := _mat(Color(0.22, 0.08, 0.09), 1.0)
	for side in [-1.0, 1.0]:
		for i in 7:
			_box(parent, Vector3(0.15, 4.5, 4.0), Vector3(side * (W * 0.5 - 0.15), 4.5, z0 + 5.0 + i * 5.2), panel_mat)

	# Telones rojos a los lados de la pantalla (pliegues con cajas alternas)
	var curtain := _mat(Color(0.45, 0.04, 0.06), 0.8)
	for side in [-1.0, 1.0]:
		for i in 10:
			var depth := 0.25 if i % 2 == 0 else 0.1
			_box(parent, Vector3(0.45, H - 0.4, depth), Vector3(side * (W * 0.5 - 0.3 - i * 0.42), (H - 0.4) * 0.5, z0 + 0.4 + depth * 0.5), curtain)

	# Butacas (una sola MultiMesh por pieza para que sea ligero)
	var seats := []
	for row in 9:
		var z := -4.5 + row * 1.6
		if absf(z) < 1.2:
			continue # pasillo donde está el usuario
		for col in 18:
			var x := -12.75 + col * 1.5
			if absf(x) < 1.0:
				continue
			seats.append(Vector3(x, 0, z))
	_multi_box(parent, Vector3(0.9, 0.45, 0.8), Vector3(0, 0.25, 0), seats, _mat(Color(0.55, 0.05, 0.08), 0.7))      # asiento
	_multi_box(parent, Vector3(0.9, 0.9, 0.18), Vector3(0, 0.75, 0.38), seats, _mat(Color(0.5, 0.04, 0.07), 0.7))    # respaldo
	_multi_box(parent, Vector3(0.12, 0.7, 0.8), Vector3(0.5, 0.35, 0.0), seats, _mat(Color(0.08, 0.06, 0.06), 0.6))  # reposabrazos

	# Apliques de luz tenue en las paredes y luces del pasillo
	var glow := _emissive(Color(1.0, 0.7, 0.45), 2.0)
	for side in [-1.0, 1.0]:
		for i in 6:
			var z := z0 + 7.0 + i * 6.0
			_box(parent, Vector3(0.1, 0.5, 0.25), Vector3(side * (W * 0.5 - 0.12), 7.5, z), glow)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.7, 0.45)
			l.light_energy = 0.6
			l.omni_range = 5.0
			l.position = Vector3(side * (W * 0.5 - 0.8), 7.5, z)
			parent.add_child(l)
	var step := _emissive(Color(0.3, 0.5, 1.0), 1.5)
	for i in 12:
		for side in [-1.0, 1.0]:
			_box(parent, Vector3(0.06, 0.03, 0.3), Vector3(side * 1.05, 0.02, -8.0 + i * 1.8), step)

	# Luz que "sale" de la pantalla e ilumina la sala
	var spill := SpotLight3D.new()
	spill.light_color = Color(0.7, 0.75, 0.9)
	spill.light_energy = 3.0
	spill.spot_range = 30.0
	spill.spot_angle = 60.0
	spill.position = Vector3(0, 3.0, -12.0)
	spill.rotation_degrees = Vector3(-8, 180, 0)
	parent.add_child(spill)
	return {"spawn": Vector3(0, 0.02, 0), "screen_distance": 14.0, "screen_width": 14.0}


# ---------------------------------------------------------------- salón

static func _build_living_room(parent: Node3D) -> Dictionary:
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.15, 0.2, 0.42)
	sky.sky_horizon_color = Color(0.95, 0.6, 0.4)
	sky.ground_horizon_color = Color(0.3, 0.25, 0.3)
	sky.ground_bottom_color = Color(0.08, 0.08, 0.1)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = sky
	env.sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.75, 0.65)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_add_environment(parent, env)

	const W := 16.0   # x de -8 a 8
	const Z0 := -10.0 # pared de delante
	const Z1 := 6.0   # pared de atrás
	const H := 4.2
	var cx := 0.0
	var cz := (Z0 + Z1) * 0.5
	var wood := ShaderMaterial.new()
	wood.shader = load("res://scripts/wood_floor.gdshader")
	_floor(parent, Vector3(W, 0.2, Z1 - Z0), Vector3(cx, -0.1, cz), wood)
	var wall := _mat(Color(0.82, 0.76, 0.68), 0.95)
	var accent := _mat(Color(0.22, 0.28, 0.3), 0.9)
	_box(parent, Vector3(W, 0.2, Z1 - Z0), Vector3(cx, H, cz), _mat(Color(0.92, 0.9, 0.86), 1.0))  # techo
	_box(parent, Vector3(W, H, 0.2), Vector3(cx, H * 0.5, Z0), accent)                              # pared de la pantalla
	_box(parent, Vector3(W, H, 0.2), Vector3(cx, H * 0.5, Z1), wall)
	_box(parent, Vector3(0.2, H, Z1 - Z0), Vector3(8.0, H * 0.5, cz), wall)
	# Pared izquierda con ventanal: marco alrededor de un hueco por el que se ve el cielo
	_box(parent, Vector3(0.2, 0.8, Z1 - Z0), Vector3(-8.0, 0.4, cz), wall)
	_box(parent, Vector3(0.2, 0.6, Z1 - Z0), Vector3(-8.0, H - 0.3, cz), wall)
	_box(parent, Vector3(0.2, H, 2.0), Vector3(-8.0, H * 0.5, Z0 + 1.0), wall)
	_box(parent, Vector3(0.2, H, 2.0), Vector3(-8.0, H * 0.5, Z1 - 1.0), wall)
	var frame := _mat(Color(0.12, 0.12, 0.13), 0.5)
	for i in 6:
		_box(parent, Vector3(0.25, H - 1.4, 0.08), Vector3(-8.0, 0.8 + (H - 1.4) * 0.5, Z0 + 2.0 + i * 2.4), frame)

	# Alfombra, sofá, mesa baja, estantería, plantas y lámpara
	_box(parent, Vector3(4.5, 0.02, 3.2), Vector3(0, 0.01, -0.6), _mat(Color(0.55, 0.62, 0.66), 1.0))
	var fabric := _mat(Color(0.25, 0.32, 0.38), 1.0)
	_box(parent, Vector3(3.2, 0.42, 0.95), Vector3(0, 0.21, 1.4), fabric)
	_box(parent, Vector3(3.2, 0.75, 0.25), Vector3(0, 0.55, 1.85), fabric)
	_box(parent, Vector3(0.25, 0.6, 0.95), Vector3(-1.6, 0.4, 1.4), fabric)
	_box(parent, Vector3(0.25, 0.6, 0.95), Vector3(1.6, 0.4, 1.4), fabric)
	var oak := _mat(Color(0.5, 0.34, 0.2), 0.6)
	_box(parent, Vector3(1.4, 0.06, 0.7), Vector3(0, 0.4, -0.8), oak)
	for p in [Vector3(-0.62, 0.19, -1.08), Vector3(0.62, 0.19, -1.08), Vector3(-0.62, 0.19, -0.52), Vector3(0.62, 0.19, -0.52)]:
		_box(parent, Vector3(0.05, 0.38, 0.05), p, oak)
	for i in 4:
		_box(parent, Vector3(0.4, 0.04, 2.4), Vector3(7.7, 0.4 + i * 0.6, -3.0), oak)
	var book_colors := [Color(0.6, 0.15, 0.12), Color(0.15, 0.3, 0.55), Color(0.8, 0.65, 0.2), Color(0.2, 0.45, 0.25)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for shelf in 4:
		var z := -4.1
		while z < -1.9:
			var t := rng.randf_range(0.04, 0.09)
			var h := rng.randf_range(0.25, 0.38)
			_box(parent, Vector3(0.28, h, t), Vector3(7.7, 0.42 + shelf * 0.6 + h * 0.5, z), _mat(book_colors[rng.randi() % 4], 0.8))
			z += t + 0.01
	for p in [Vector3(-6.8, 0, 4.5), Vector3(6.8, 0, 4.5), Vector3(-6.8, 0, -8.8)]:
		_add_plant(parent, p)
	_add_floor_lamp(parent, Vector3(2.4, 0, 1.6))
	var ceiling := OmniLight3D.new()
	ceiling.light_color = Color(1.0, 0.85, 0.7)
	ceiling.light_energy = 0.7
	ceiling.omni_range = 12.0
	ceiling.position = Vector3(0, H - 0.4, -1.0)
	parent.add_child(ceiling)
	# Luz del atardecer entrando por la ventana
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.7, 0.45)
	sun.light_energy = 0.8
	sun.rotation_degrees = Vector3(-20, -90, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 20.0
	parent.add_child(sun)
	return {"spawn": Vector3(0, 0.02, 0), "screen_distance": 7.0, "screen_width": 7.0}


static func _add_plant(parent: Node3D, pos: Vector3) -> void:
	var pot := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28; cyl.bottom_radius = 0.2; cyl.height = 0.5; cyl.radial_segments = 12
	pot.mesh = cyl
	pot.material_override = _mat(Color(0.85, 0.85, 0.82), 0.6)
	pot.position = pos + Vector3(0, 0.25, 0)
	parent.add_child(pot)
	var leaves := _mat(Color(0.18, 0.42, 0.2), 0.8)
	for i in 5:
		var s := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.32; sp.height = 0.5; sp.radial_segments = 8; sp.rings = 5
		s.mesh = sp
		s.material_override = leaves
		s.position = pos + Vector3(cos(i * 1.3) * 0.18, 0.75 + i * 0.18, sin(i * 1.3) * 0.18)
		parent.add_child(s)


static func _add_floor_lamp(parent: Node3D, pos: Vector3) -> void:
	var metal := _mat(Color(0.1, 0.1, 0.1), 0.4)
	_box(parent, Vector3(0.35, 0.03, 0.35), pos + Vector3(0, 0.015, 0), metal)
	_box(parent, Vector3(0.03, 1.6, 0.03), pos + Vector3(0, 0.8, 0), metal)
	var shade := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18; cyl.bottom_radius = 0.26; cyl.height = 0.3; cyl.radial_segments = 16
	shade.mesh = cyl
	shade.material_override = _emissive(Color(1.0, 0.85, 0.6), 0.8)
	shade.position = pos + Vector3(0, 1.65, 0)
	parent.add_child(shade)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.55)
	l.light_energy = 1.2
	l.omni_range = 6.0
	l.position = pos + Vector3(0, 1.55, 0)
	parent.add_child(l)


# ---------------------------------------------------------------- espacio

static func _build_space(parent: Node3D) -> Dictionary:
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load(PANORAMA_DIR + "nebulosa.jpg")
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = pano
	env.sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.6)
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_add_environment(parent, env)

	var star := DirectionalLight3D.new()
	star.name = "Estrella"
	star.light_color = Color(1.0, 0.95, 0.88)
	star.light_energy = 1.3
	star.rotation_degrees = Vector3(-25, 120, 0)
	star.shadow_enabled = true
	star.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	star.directional_shadow_max_distance = 20.0
	parent.add_child(star)

	# Plataforma flotante con borde luminoso
	var deck := _mat(Color(0.32, 0.34, 0.38), 0.35)
	deck.metallic = 0.6
	var body := StaticBody3D.new()
	body.name = "Plataforma"
	body.collision_layer = 1
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 7.0; cyl.bottom_radius = 5.5; cyl.height = 0.6; cyl.radial_segments = 48
	disc.mesh = cyl
	disc.material_override = deck
	disc.position.y = -0.3
	body.add_child(disc)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 7.0; shape.height = 0.6
	col.shape = shape
	col.position.y = -0.3
	body.add_child(col)
	parent.add_child(body)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 6.95; torus.outer_radius = 7.1; torus.rings = 64; torus.ring_segments = 6
	rim.mesh = torus
	rim.material_override = _emissive(Color(0.3, 0.7, 1.0), 2.5)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(rim)
	var lines := _emissive(Color(0.3, 0.7, 1.0), 1.2)
	for i in 8:
		var a := TAU * i / 8.0
		var seg := _box(parent, Vector3(0.05, 0.01, 4.0), Vector3(sin(a) * 4.5, 0.005, cos(a) * 4.5), lines)
		seg.rotation.y = a

	# Planeta gigante con anillos y una luna
	var planet := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 90.0; sp.height = 180.0; sp.radial_segments = 64; sp.rings = 32
	planet.mesh = sp
	var pm := ShaderMaterial.new()
	pm.shader = load("res://scripts/planet.gdshader")
	planet.material_override = pm
	planet.position = Vector3(-140, 30, -230)
	planet.rotation_degrees = Vector3(12, 0, -18)
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(planet)
	var ring := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(380, 380)
	ring.mesh = plane
	var rm := ShaderMaterial.new()
	rm.shader = load("res://scripts/planet_ring.gdshader")
	ring.material_override = rm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.add_child(ring)
	var moon := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 9.0; ms.height = 18.0; ms.radial_segments = 24; ms.rings = 12
	moon.mesh = ms
	moon.material_override = _mat(Color(0.6, 0.58, 0.55), 1.0)
	moon.position = Vector3(70, 45, -160)
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(moon)
	# el planeta gira muy despacio
	var tw := planet.create_tween().set_loops()
	tw.tween_property(planet, "rotation:y", TAU, 600.0).as_relative()

	_sound(parent, "res://audio/space_drone.wav", -14.0)
	return {"spawn": Vector3(0, 0.02, 0), "screen_distance": 10.0, "screen_width": 10.0}


# ---------------------------------------------------------------- foto 360°

static func _build_panorama(parent: Node3D, path: String) -> Dictionary:
	var tex := _load_panorama(path)
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = tex
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = pano
	env.sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	_add_environment(parent, env)
	# Suelo invisible: la foto es el mundo; solo sirve para que el cuerpo no caiga.
	var body := StaticBody3D.new()
	body.name = "SueloInvisible"
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6, 0.2, 6)
	col.shape = shape
	col.position.y = -0.1
	body.add_child(col)
	parent.add_child(body)
	return {"spawn": Vector3(0, 0.02, 0), "screen_distance": 8.0, "screen_width": 8.0}


static func _load_panorama(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_warning("No se pudo cargar la foto 360°: " + path)
		var fallback := Image.create(2, 1, false, Image.FORMAT_RGB8)
		fallback.fill(Color(0.1, 0.1, 0.12))
		return ImageTexture.create_from_image(fallback)
	if img.get_width() > MAX_PANORAMA_WIDTH:
		img.resize(MAX_PANORAMA_WIDTH, MAX_PANORAMA_WIDTH / 2, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- utilidades

static func _dark_environment(bg: Color, ambient: Color, ambient_energy: float) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return env


static func _add_environment(parent: Node3D, env: Environment) -> void:
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)


static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Suelo visible con colisión en la capa 1 (la que acepta el teletransporte).
static func _floor(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Suelo"
	body.collision_layer = 1
	body.position = pos
	parent.add_child(body)
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


## Muchas cajas iguales en una sola llamada de dibujo.
static func _multi_box(parent: Node3D, size: Vector3, offset: Vector3, positions: Array, mat: Material) -> void:
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = b
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis(), positions[i] + offset))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	parent.add_child(mmi)


static func _sound(parent: Node3D, path: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _loop_wav(path)
	p.volume_db = volume_db
	p.autoplay = true
	parent.add_child(p)
	return p


static func _sound_3d(parent: Node3D, path: String, pos: Vector3) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = _loop_wav(path)
	p.position = pos
	p.autoplay = true
	parent.add_child(p)
	return p


static func _loop_wav(path: String) -> AudioStream:
	var s: AudioStream = load(path)
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	return s

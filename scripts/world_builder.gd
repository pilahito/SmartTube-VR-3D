## Construye la playa de forma procedural (sin assets con copyright).
class_name WorldBuilder
extends RefCounted

const SHORE_Z := -6.0

## Altura de la arena en (x, z). Llano en la zona del usuario, baja hacia el mar,
## dunas suaves detrás.
static func sand_height(x: float, z: float, noise: FastNoiseLite) -> float:
	var h := 0.0
	# pendiente hacia el mar (z negativo)
	h += clampf((z - SHORE_Z) * 0.06, -1.6, 0.6)
	# dunas detrás del usuario
	if z > 8.0:
		h += (z - 8.0) * 0.08 + noise.get_noise_2d(x * 0.6, z * 0.6) * 1.2 * clampf((z - 8.0) / 10.0, 0.0, 1.0)
	h += noise.get_noise_2d(x * 3.0, z * 3.0) * 0.05
	return h


static func build_sand(parent: Node3D) -> StaticBody3D:
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.05
	var size := 120.0
	var res := 96
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in res + 1:
		for ix in res + 1:
			var x := -size * 0.5 + size * ix / res
			var z := -30.0 + 90.0 * iz / res
			st.set_uv(Vector2(x, z) * 0.1)
			st.add_vertex(Vector3(x, sand_height(x, z, noise), z))
	for iz in res:
		for ix in res:
			var i := iz * (res + 1) + ix
			st.add_index(i); st.add_index(i + 1); st.add_index(i + res + 1)
			st.add_index(i + 1); st.add_index(i + res + 2); st.add_index(i + res + 1)
	st.generate_normals()
	var mesh := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/sand.gdshader")
	mat.set_shader_parameter("shore_z", SHORE_Z)
	mesh.surface_set_material(0, mat)

	var body := StaticBody3D.new()
	body.name = "Arena"
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	body.add_child(col)
	parent.add_child(body)
	body.set_meta("noise", noise)
	return body


static func build_ocean(parent: Node3D) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 200)
	plane.subdivide_width = 160
	plane.subdivide_depth = 120
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/ocean.gdshader")
	mat.set_shader_parameter("shore_z", SHORE_Z)
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Oceano"
	mi.mesh = plane
	mi.position = Vector3(0, -0.15, SHORE_Z - 96.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func build_environment(parent: Node3D) -> DirectionalLight3D:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.47, 0.85)
	sky_mat.sky_horizon_color = Color(0.72, 0.84, 0.95)
	sky_mat.ground_horizon_color = Color(0.72, 0.84, 0.95)
	sky_mat.ground_bottom_color = Color(0.2, 0.35, 0.5)
	sky_mat.sun_angle_max = 20.0
	sky_mat.sun_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.85, 0.95)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sol"
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.1
	sun.rotation_degrees = Vector3(-35, 160, 0) # sol delante, sobre el mar
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	parent.add_child(sun)
	return sun


## Palmera procedural: tronco curvo por segmentos + hojas arqueadas.
static func build_palm(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var palm := Node3D.new()
	palm.position = pos
	palm.rotation.y = rng.randf() * TAU
	parent.add_child(palm)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.45, 0.33, 0.22)
	trunk_mat.roughness = 1.0
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.2, 0.5, 0.18)
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_mat.roughness = 0.8

	var height := rng.randf_range(5.0, 8.0)
	var lean := rng.randf_range(0.6, 2.0)
	var segs := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 7
	var prev := PackedVector3Array()
	var top := Vector3.ZERO
	for s in segs + 1:
		var t := float(s) / segs
		var center := Vector3(lean * t * t, height * t, 0)
		var r := lerpf(0.22, 0.13, t) * (1.0 + 0.08 * sin(t * 40.0))
		var ring := PackedVector3Array()
		for k in sides:
			var a := TAU * k / sides
			ring.append(center + Vector3(cos(a) * r, 0, sin(a) * r))
		if s > 0:
			for k in sides:
				var k2 := (k + 1) % sides
				st.add_vertex(prev[k]); st.add_vertex(ring[k]); st.add_vertex(prev[k2])
				st.add_vertex(prev[k2]); st.add_vertex(ring[k]); st.add_vertex(ring[k2])
		prev = ring
		top = center
	st.generate_normals()
	var trunk := MeshInstance3D.new()
	trunk.mesh = st.commit()
	trunk.material_override = trunk_mat
	palm.add_child(trunk)

	# Hojas: tiras arqueadas con forma de pluma
	var lst := SurfaceTool.new()
	lst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := rng.randi_range(7, 10)
	for l in leaves:
		var yaw := TAU * l / leaves + rng.randf_range(-0.2, 0.2)
		var length := rng.randf_range(2.6, 3.6)
		var dir := Vector3(cos(yaw), 0, sin(yaw))
		var side := dir.cross(Vector3.UP).normalized()
		var n := 8
		var pts_l := PackedVector3Array(); var pts_r := PackedVector3Array(); var pts_c := PackedVector3Array()
		for i in n + 1:
			var t := float(i) / n
			var c := top + dir * length * t + Vector3.UP * (0.6 * t - 1.6 * t * t)
			var w := sin(t * PI) * 0.45
			pts_c.append(c)
			pts_l.append(c + side * w - Vector3.UP * w * 0.3)
			pts_r.append(c - side * w - Vector3.UP * w * 0.3)
		for i in n:
			lst.add_vertex(pts_c[i]); lst.add_vertex(pts_l[i]); lst.add_vertex(pts_c[i + 1])
			lst.add_vertex(pts_l[i]); lst.add_vertex(pts_l[i + 1]); lst.add_vertex(pts_c[i + 1])
			lst.add_vertex(pts_c[i]); lst.add_vertex(pts_c[i + 1]); lst.add_vertex(pts_r[i])
			lst.add_vertex(pts_r[i]); lst.add_vertex(pts_c[i + 1]); lst.add_vertex(pts_r[i + 1])
	lst.generate_normals()
	var leaves_mi := MeshInstance3D.new()
	leaves_mi.mesh = lst.commit()
	leaves_mi.material_override = leaf_mat
	palm.add_child(leaves_mi)
	# cocos
	var coco_mat := StandardMaterial3D.new()
	coco_mat.albedo_color = Color(0.35, 0.25, 0.12)
	for c in 3:
		var sp := SphereMesh.new()
		sp.radius = 0.12; sp.height = 0.24; sp.radial_segments = 8; sp.rings = 4
		var cm := MeshInstance3D.new()
		cm.mesh = sp
		cm.material_override = coco_mat
		cm.position = top + Vector3(cos(c * 2.1) * 0.18, -0.25, sin(c * 2.1) * 0.18)
		palm.add_child(cm)


static func build_rocks(parent: Node3D, rng: RandomNumberGenerator, noise: FastNoiseLite) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.43, 0.4)
	mat.roughness = 0.9
	for i in 10:
		var m := SphereMesh.new()
		var r := rng.randf_range(0.3, 1.2)
		m.radius = r; m.height = r * rng.randf_range(0.8, 1.4); m.radial_segments = 8; m.rings = 5
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = mat
		var x: float = rng.randf_range(-40, 40) * (1.0 if rng.randf() > 0.3 else 0.4)
		var z := rng.randf_range(-9, 25)
		if absf(x) < 6 and z < 12:
			x += 12.0 * signf(x + 0.01)
		mi.position = Vector3(x, sand_height(x, z, noise) - r * 0.3, z)
		mi.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
		parent.add_child(mi)

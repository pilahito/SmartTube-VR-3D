## Exporta cada mundo a un modelo GLB (glTF binario) para la página de descargas.
## Uso: godot --headless -s tools/export_worlds.gd -- <carpeta_salida>
## Construye los mundos con el mismo código que la app (Worlds.build) y guarda además
## un worlds.json con los datos que muestra la página.
extends SceneTree

## Los shaders propios no existen en glTF: se cambian por materiales estándar parecidos.
const SHADER_COLORS := {
	"res://scripts/sand.gdshader": Color(0.93, 0.83, 0.62),
	"res://scripts/ocean.gdshader": Color(0.05, 0.4, 0.5),
	"res://scripts/wood_floor.gdshader": Color(0.55, 0.37, 0.22),
	"res://scripts/planet.gdshader": Color(0.8, 0.55, 0.38),
}
const DESCRIPTIONS := {
	"playa_dia": "La playa original: arena con dunas, mar, palmeras y rocas.",
	"playa_atardecer": "La playa con el sol bajo y el mar de tonos cálidos.",
	"playa_noche": "La playa de noche, con luna y una hoguera.",
	"cine": "Sala grande con butacas rojas, telones y apliques de luz.",
	"salon": "Salón con tarima, sofá, estantería con libros, plantas y ventanal.",
	"espacio": "Plataforma flotante, planeta gigante con anillos y una luna.",
}
## Fondo 360° que la página pone detrás del modelo al previsualizarlo.
const SKYBOX := {
	"espacio": "nebulosa.jpg",
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "build/site"
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("models"))
	var index := []
	for entry: Dictionary in Worlds.BUILTIN:
		var id: String = entry.id
		if id.begins_with("pano:"):
			continue
		var root := Node3D.new()
		root.name = id
		get_root().add_child(root)
		Worlds.build(id, root)
		var stats := _prepare_for_gltf(root)
		var file := "models/%s.glb" % id
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_scene(root, state)
		if err == OK:
			err = doc.write_to_filesystem(state, out_dir.path_join(file))
		if err != OK:
			push_error("No se pudo exportar %s (error %d)" % [id, err])
			quit(1)
			return
		var size := FileAccess.get_file_as_bytes(out_dir.path_join(file)).size()
		print("OK %s: %d triángulos, %d KB" % [file, stats.triangles, size / 1024])
		index.append({
			"id": id,
			"name": entry.name,
			"description": DESCRIPTIONS.get(id, ""),
			"file": file,
			"bytes": size,
			"triangles": stats.triangles,
			"skybox": "panoramas/" + SKYBOX[id] if SKYBOX.has(id) else "",
		})
		root.free()

	DirAccess.make_dir_recursive_absolute(out_dir.path_join("panoramas"))
	for entry: Dictionary in Worlds.BUILTIN:
		var id: String = entry.id
		if not id.begins_with("pano:"):
			continue
		var src := id.substr(5)
		var file := "panoramas/" + src.get_file()
		var bytes := FileAccess.get_file_as_bytes(src)
		var f := FileAccess.open(out_dir.path_join(file), FileAccess.WRITE)
		f.store_buffer(bytes)
		f.close()
		print("OK %s: %d KB" % [file, bytes.size() / 1024])
		index.append({"id": src.get_file().get_basename(), "name": entry.name, "file": file,
			"bytes": bytes.size(), "panorama": true,
			"description": "Foto 360° equirectangular (4096×2048). Cópiala a la carpeta de panoramas de las Quest o úsala de fondo en Blender."})

	var json := FileAccess.open(out_dir.path_join("worlds.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(index, "  "))
	json.close()
	quit()


## Quita lo que glTF no entiende (sonido, colisiones, entorno) y cambia los shaders.
func _prepare_for_gltf(node: Node) -> Dictionary:
	var stats := {"triangles": 0}
	_walk(node, stats)
	return stats


func _walk(node: Node, stats: Dictionary) -> void:
	for child in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D or child is WorldEnvironment \
				or child is CollisionShape3D:
			child.free()
			continue
		if child is MeshInstance3D:
			_fix_materials(child)
			stats.triangles += _count_triangles(child.mesh)
		elif child is MultiMeshInstance3D:
			# Se cambia por mallas sueltas: el exportador pierde las posiciones de las instancias
			var mesh: Mesh = child.multimesh.mesh
			for pos: Vector3 in child.get_meta("positions", PackedVector3Array()):
				var mi := MeshInstance3D.new()
				mi.mesh = mesh
				mi.position = pos
				node.add_child(mi)
				stats.triangles += _count_triangles(mesh)
			child.free()
			continue
		_walk(child, stats)


func _fix_materials(mi: MeshInstance3D) -> void:
	var mat := mi.material_override
	if mat == null and mi.mesh and mi.mesh.get_surface_count() > 0:
		mat = mi.mesh.surface_get_material(0)
	if not mat is ShaderMaterial:
		return
	var path: String = (mat as ShaderMaterial).shader.resource_path
	if path == "res://scripts/planet_ring.gdshader":
		# El anillo es un plano con transparencia en el shader: se cambia por un anillo de verdad.
		var plane := mi.mesh as PlaneMesh
		mi.mesh = _ring_mesh(plane.size.x * 0.5 * 0.55, plane.size.x * 0.5)
		var ring := StandardMaterial3D.new()
		ring.albedo_color = Color(0.85, 0.78, 0.66, 0.6)
		ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.cull_mode = BaseMaterial3D.CULL_DISABLED
		ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = ring
		return
	var std := StandardMaterial3D.new()
	std.albedo_color = SHADER_COLORS.get(path, Color(0.7, 0.7, 0.7))
	if path == "res://scripts/ocean.gdshader":
		var deep = (mat as ShaderMaterial).get_shader_parameter("deep_color")
		var shallow = (mat as ShaderMaterial).get_shader_parameter("shallow_color")
		if deep is Color and shallow is Color:
			std.albedo_color = deep.lerp(shallow, 0.5)
		std.roughness = 0.9 # si es liso, el plano refleja las luces del visor como un espejo
		std.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		std.roughness = 0.9
	mi.material_override = std


func _ring_mesh(inner: float, outer: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var segs := 96
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var i0 := Vector3(cos(a0), 0, sin(a0)) * inner
		var o0 := Vector3(cos(a0), 0, sin(a0)) * outer
		var i1 := Vector3(cos(a1), 0, sin(a1)) * inner
		var o1 := Vector3(cos(a1), 0, sin(a1)) * outer
		st.add_vertex(i0); st.add_vertex(o0); st.add_vertex(o1)
		st.add_vertex(i0); st.add_vertex(o1); st.add_vertex(i1)
	return st.commit()


func _count_triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var idx = arrays[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and idx.size() > 0:
			total += idx.size() / 3
		else:
			total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total

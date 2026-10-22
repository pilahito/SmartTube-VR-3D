## Pantalla de cine que muestra un VideoStreamPlayer a través de un SubViewport.
## Ajustes de "Pantalla virtual" (docs/interfaz/pantalla-ajustes.jpg): curva/plana, curvatura, formato,
## tamaño en pulgadas, distancia, altura, inclinación, 3D lado a lado y proyección 180°/360°.
## Fase 1: vídeo OGV (Theora) incluido. Fase 2: superficie Android nativa (ExoPlayer).
class_name CinemaScreen
extends Node3D

const VIDEO_PATH := "res://video/big_buck_bunny_clip.ogv"
const INCH := 0.0254
const DOME_RADIUS := 50.0
const FORMATS := {"21:9": 21.0 / 9.0, "16:9": 16.0 / 9.0, "32:9": 32.0 / 9.0, "4:3": 4.0 / 3.0}
const FORMAT_FIT := "Ajustar"
const PRESETS := {
	"Cine": {"curved": true, "curvature": 1.0, "format": "16:9", "diagonal_inches": 360.0,
		"distance": 10.0, "height": 0.6, "tilt_deg": 0.0, "projection": 0},
	"Tumbado": {"curved": true, "curvature": 0.6, "format": "16:9", "diagonal_inches": 220.0,
		"distance": 5.0, "height": 0.0, "tilt_deg": 70.0, "projection": 0},
	"Escritorio": {"curved": true, "curvature": 0.5, "format": "16:9", "diagonal_inches": 100.0,
		"distance": 2.0, "height": -0.2, "tilt_deg": -5.0, "projection": 0},
	"Completa": {"curved": true, "curvature": 1.0, "format": "16:9", "diagonal_inches": 600.0,
		"distance": 8.0, "height": 0.6, "tilt_deg": 0.0, "projection": 0},
}
const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex : source_color, filter_linear;
uniform bool sbs = false;
void fragment() {
	vec2 uv = UV;
	if (sbs) {
		uv.x = uv.x * 0.5 + 0.5 * float(VIEW_INDEX);
	}
	ALBEDO = texture(tex, uv).rgb;
}
"""

var curved := true
var curvature := 1.0                 # 1.0 = cilindro centrado en el espectador
var format := "16:9"                 # clave de FORMATS o FORMAT_FIT
var diagonal_inches := 360.0
var distance := 10.0
var height := 0.6                    # metros sobre los ojos
var tilt_deg := 0.0
var stereo_sbs := false
var projection := 0                  # 0 = pantalla, 180 o 360 grados
var player: VideoStreamPlayer
var last_position := 0.0             # posición antes del último salto (para "Deshacer salto")
var _video_size := Vector2i(854, 480)
var _size_known := false
var _viewport: SubViewport
var _mesh: MeshInstance3D
var _mat: ShaderMaterial
var _dome_mat: ShaderMaterial
var _fullscreen_saved := {}


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = _video_size
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	player = VideoStreamPlayer.new()
	player.stream = load(VIDEO_PATH)
	player.expand = true
	player.size = Vector2(_video_size)
	player.loop = true
	player.volume_db = linear_to_db(0.8)
	_viewport.add_child(player)

	_mat = _make_material(SHADER)
	# La esfera de 180°/360° rodea al espectador: sin niebla para que no se vea desvaída.
	_dome_mat = _make_material(SHADER.replace("unshaded,", "unshaded, fog_disabled,"))
	_mesh = MeshInstance3D.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	rebuild()
	player.play()


func _process(_d: float) -> void:
	# El tamaño real del vídeo solo se conoce cuando ya hay un fotograma.
	if not _size_known:
		var tex := player.get_video_texture()
		if tex and tex.get_width() > 0:
			_video_size = Vector2i(tex.get_width(), tex.get_height())
			_size_known = true
			_viewport.size = _video_size
			player.size = Vector2(_video_size)
			rebuild()


func _make_material(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", _viewport.get_texture())
	return m


func video_texture() -> Texture2D:
	return _viewport.get_texture()


func video_info() -> String:
	return "%dp" % _video_size.y


## Proporción de la pantalla según el formato elegido ("Ajustar" usa la del vídeo).
func get_aspect() -> float:
	if FORMATS.has(format):
		return FORMATS[format]
	return _eye_aspect()


func get_width() -> float:
	var a := get_aspect()
	return diagonal_inches * INCH * a / sqrt(a * a + 1.0)


## Proporción de la imagen de un ojo: en lado a lado cada ojo ve la mitad del ancho.
func _eye_aspect() -> float:
	var a := float(_video_size.x) / float(_video_size.y)
	return a * 0.5 if stereo_sbs else a


## Zona de la imagen (por ojo, 0..1) que cubre la pantalla sin deformar el vídeo.
func _uv_rect(screen_aspect: float) -> Rect2:
	var ea := _eye_aspect()
	if screen_aspect > ea:
		var v := ea / screen_aspect
		return Rect2(0.0, (1.0 - v) * 0.5, 1.0, v)
	var u := screen_aspect / ea
	return Rect2((1.0 - u) * 0.5, 0.0, u, 1.0)


func rebuild() -> void:
	if _mesh == null:
		return
	var mat := _mat if projection == 0 else _dome_mat
	_mesh.mesh = _screen_mesh() if projection == 0 else _dome_mesh()
	mat.set_shader_parameter("sbs", stereo_sbs)
	_mesh.material_override = mat


## Pantalla curva (cilindro) o plana, centrada en el origen del nodo.
func _screen_mesh() -> ArrayMesh:
	var a := get_aspect()
	var w := get_width()
	var h := w / a
	var uv := _uv_rect(a)
	var radius := distance / maxf(curvature, 0.05)
	var segs := 32 if curved else 1
	var up := Vector3(0, h * 0.5, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var p0 := _screen_point(t0, w, radius)
		var p1 := _screen_point(t1, w, radius)
		var u0 := uv.position.x + uv.size.x * t0
		var u1 := uv.position.x + uv.size.x * t1
		var vt := uv.position.y
		var vb := uv.end.y
		st.set_uv(Vector2(u0, vt)); st.add_vertex(p0 + up)
		st.set_uv(Vector2(u1, vt)); st.add_vertex(p1 + up)
		st.set_uv(Vector2(u0, vb)); st.add_vertex(p0 - up)
		st.set_uv(Vector2(u1, vt)); st.add_vertex(p1 + up)
		st.set_uv(Vector2(u1, vb)); st.add_vertex(p1 - up)
		st.set_uv(Vector2(u0, vb)); st.add_vertex(p0 - up)
	return st.commit()


func _screen_point(t: float, w: float, radius: float) -> Vector3:
	if not curved:
		return Vector3((t - 0.5) * w, 0, 0)
	var ang := (t - 0.5) * w / radius
	return Vector3(sin(ang) * radius, 0, radius - cos(ang) * radius)


## Esfera (360°) o media esfera (180°) alrededor del espectador, proyección equirrectangular.
func _dome_mesh() -> ArrayMesh:
	var span := deg_to_rad(float(projection))
	var nx := 48 if projection == 180 else 96
	var ny := 32
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in ny:
		for i in nx:
			var u0 := float(i) / nx
			var u1 := float(i + 1) / nx
			var v0 := float(j) / ny
			var v1 := float(j + 1) / ny
			var a := _dome_point(u0, v0, span)
			var b := _dome_point(u1, v0, span)
			var c := _dome_point(u0, v1, span)
			var d := _dome_point(u1, v1, span)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(a)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(b)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(c)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(b)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(d)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(c)
	return st.commit()


func _dome_point(u: float, v: float, span: float) -> Vector3:
	var lon := (u - 0.5) * span
	var lat := (0.5 - v) * PI
	return Vector3(sin(lon) * cos(lat), sin(lat), -cos(lon) * cos(lat)) * DOME_RADIUS


## Coloca la pantalla delante de la cabeza (o la esfera, centrada en ella).
func place(head: Vector3, yaw: float) -> void:
	var yaw_basis := Basis(Vector3.UP, yaw)
	if projection != 0:
		global_transform = Transform3D(yaw_basis, head)
		return
	var pivot := Transform3D(yaw_basis * Basis(Vector3.RIGHT, deg_to_rad(tilt_deg)), head)
	global_transform = pivot * Transform3D(Basis.IDENTITY, Vector3(0, height, -distance))


func apply_preset(preset: String) -> void:
	if not PRESETS.has(preset):
		return
	for k in PRESETS[preset]:
		set(k, PRESETS[preset][k])


## Alterna entre la configuración actual y la pantalla grande ("pantalla completa").
func toggle_fullscreen() -> void:
	if _fullscreen_saved.is_empty():
		for k in PRESETS["Completa"]:
			_fullscreen_saved[k] = get(k)
		apply_preset("Completa")
	else:
		for k in _fullscreen_saved:
			set(k, _fullscreen_saved[k])
		_fullscreen_saved = {}


func toggle_play() -> void:
	player.paused = not player.paused


func seek(delta: float) -> void:
	var len := player.get_stream_length()
	last_position = player.stream_position
	player.stream_position = clampf(player.stream_position + delta, 0.0, maxf(len - 0.5, 0.0))


func seek_ratio(r: float) -> void:
	var len := player.get_stream_length()
	last_position = player.stream_position
	player.stream_position = clampf(r, 0.0, 1.0) * maxf(len - 0.5, 0.0)


func undo_seek() -> void:
	player.stream_position = last_position


func set_volume(v: float) -> void:
	player.volume_db = linear_to_db(maxf(v, 0.001))


func is_playing_now() -> bool:
	return player.is_playing() and not player.paused

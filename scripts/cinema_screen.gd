## Pantalla de cine curva que muestra un VideoStreamPlayer a trav�s de un SubViewport.
## Fase 1: v�deo OGV (Theora) incluido. Fase 2: superficie Android nativa (ExoPlayer).
class_name CinemaScreen
extends Node3D

const VIDEO_PATH := "res://video/big_buck_bunny_clip.ogv"
const ASPECT := 16.0 / 9.0

var width := 8.0: set = set_width
var radius := 10.0
var player: VideoStreamPlayer
var _viewport: SubViewport
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D

func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(854, 480)
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	player = VideoStreamPlayer.new()
	player.stream = load(VIDEO_PATH)
	player.expand = true
	player.size = Vector2(854, 480)
	player.loop = true
	player.volume_db = linear_to_db(0.25)
	_viewport.add_child(player)

	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_texture = _viewport.get_texture()
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh = MeshInstance3D.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	# marco oscuro detr�s
	_rebuild()
	player.play()


func set_width(w: float) -> void:
	width = clampf(w, 3.0, 20.0)
	if _mesh:
		_rebuild()


## Superficie cil�ndrica centrada en el espectador (radio = distancia actual).
func _rebuild() -> void:
	var h := width / ASPECT
	var arc := width / radius
	var segs := 32
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var a0 := -arc * 0.5 + arc * i / segs
		var a1 := -arc * 0.5 + arc * (i + 1) / segs
		var u0 := float(i) / segs
		var u1 := float(i + 1) / segs
		var p0 := Vector3(sin(a0) * radius, 0, radius - cos(a0) * radius)
		var p1 := Vector3(sin(a1) * radius, 0, radius - cos(a1) * radius)
		var up := Vector3(0, h * 0.5, 0)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(p0 + up)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(p1 + up)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(p0 - up)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(p1 + up)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(p1 - up)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(p0 - up)
	_mesh.mesh = st.commit()
	_mesh.material_override = _mat


func toggle_play() -> void:
	player.paused = not player.paused


func seek(delta: float) -> void:
	var len := player.get_stream_length()
	var p := clampf(player.stream_position + delta, 0.0, maxf(len - 0.5, 0.0))
	player.stream_position = p


func set_volume(v: float) -> void:
	player.volume_db = linear_to_db(maxf(v, 0.001))


func is_playing_now() -> bool:
	return player.is_playing() and not player.paused

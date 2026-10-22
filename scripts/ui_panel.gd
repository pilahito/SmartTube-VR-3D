## Barra de reproducción flotante (se muestra en 3D con XRToolsViewport2DIn3D).
## Diseño basado en docs/interfaz/reproductor.jpg.
extends Control

signal action(name: String)
signal volume_changed(value: float)
signal seek_to(ratio: float)

const UNDO_SECONDS := 5.0

var _time: Label
var _res: Label
var _codec: Label
var _now: Label
var _play: IconBtn
var _seek: HSlider
var _undo: IconBtn
var _undo_left := 0.0
var _seeking := false


func _ready() -> void:
	size = Vector2(1240, 200)
	var glass := PanelContainer.new()
	glass.set_anchors_preset(Control.PRESET_FULL_RECT)
	glass.add_theme_stylebox_override("panel", UIKit.glass(30, 30, 14))
	add_child(glass)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	glass.add_child(col)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	col.add_child(row1)
	_play = _flat_icon("pause", "play_pause", Vector2(76, 72))
	row1.add_child(_play)
	row1.add_child(_flat_icon("back", "seek_back", Vector2(70, 72), "10"))
	row1.add_child(_flat_icon("fwd", "seek_fwd", Vector2(70, 72), "10"))
	_time = UIKit.label("0:00 / 0:00", 30, Color(1, 1, 1, 0.92))
	_time.custom_minimum_size = Vector2(190, 0)
	_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row1.add_child(_time)
	_undo = IconBtn.new()
	_undo.lead = "undo"
	_undo.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_undo.add_theme_font_size_override("font_size", 22)
	_undo.custom_minimum_size = Vector2(230, 72)
	UIKit.style_button(_undo, 18, 68, 14)
	_undo.visible = false
	_undo.pressed.connect(func():
		_undo_left = 0.0
		_undo.visible = false
		action.emit("undo_seek"))
	row1.add_child(_undo)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(spacer)
	_res = _chip(row1)
	_codec = _chip(row1)
	var vol_icon := IconBtn.new()
	vol_icon.kind = "speaker"
	vol_icon.custom_minimum_size = Vector2(60, 72)
	vol_icon.flat = true
	vol_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row1.add_child(vol_icon)
	var vol := UIKit.slider(0.0, 1.0, 0.05, 0.8, Color.WHITE, 72, 6, 22)
	vol.custom_minimum_size = Vector2(170, 72)
	vol.size_flags_horizontal = Control.SIZE_SHRINK_END
	vol.value_changed.connect(func(v): volume_changed.emit(v))
	row1.add_child(vol)

	# Barra de progreso: roja hasta donde vas, sin pomo; pulsa en cualquier punto para saltar.
	_seek = UIKit.slider(0.0, 1.0, 0.001, 0.0, UIKit.PROGRESS, 18, 10, 0)
	_seek.drag_started.connect(func(): _seeking = true)
	_seek.drag_ended.connect(func(_changed: bool):
		_seeking = false
		seek_to.emit(_seek.value))
	col.add_child(_seek)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 12)
	col.add_child(row3)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(22, 22)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", UIKit.box(Color(0.5, 0.8, 0.25), 11))
	row3.add_child(dot)
	_now = UIKit.label("Playa · Big Buck Bunny", 24, Color(1, 1, 1, 0.9))
	_now.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row3.add_child(_now)
	var spacer3 := Control.new()
	spacer3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row3.add_child(spacer3)
	row3.add_child(_flat_icon("gear", "toggle_settings", Vector2(64, 52)))
	row3.add_child(_flat_icon("expand", "fullscreen", Vector2(64, 52)))


func _process(delta: float) -> void:
	if _undo_left > 0.0:
		_undo_left -= delta
		_undo.text = "Deshacer salto\n%d s" % ceili(maxf(_undo_left, 0.0))
		if _undo_left <= 0.0:
			_undo.visible = false


func _chip(parent: Control) -> Label:
	var pc := PanelContainer.new()
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pc.add_theme_stylebox_override("panel", UIKit.chip_box())
	var l := UIKit.label("", 24)
	pc.add_child(l)
	parent.add_child(pc)
	return l


func _flat_icon(kind: String, act: String, min_size: Vector2, caption := "") -> IconBtn:
	var b := IconBtn.new()
	b.kind = kind
	b.caption = caption
	b.custom_minimum_size = min_size
	UIKit.style_flat(b)
	b.pressed.connect(func(): action.emit(act))
	return b


## Muestra durante unos segundos el botón para volver al punto anterior al salto.
func show_undo() -> void:
	_undo_left = UNDO_SECONDS
	_undo.text = "Deshacer salto\n%d s" % int(UNDO_SECONDS)
	_undo.visible = true


func set_scene_name(scene_name: String) -> void:
	_now.text = "%s · Big Buck Bunny" % scene_name


func set_info(resolution: String, codec: String) -> void:
	_res.text = resolution
	_codec.text = codec


func set_status(playing: bool, pos: float, length: float) -> void:
	if _play == null:
		return
	_play.set_kind("pause" if playing else "play")
	_time.text = "%s / %s" % [_fmt(pos), _fmt(length)]
	if not _seeking and length > 0.0:
		_seek.set_value_no_signal(clampf(pos / length, 0.0, 1.0))


func _fmt(s: float) -> String:
	var t := int(maxf(s, 0.0))
	return "%d:%02d" % [t / 60, t % 60]

## Panel de control flotante (se muestra en 3D con XRToolsViewport2DIn3D).
## Diseño basado en docs/interfaz/reproductor.jpg y pantalla-ajustes.jpg de SmartTube-VR.
extends Control

signal action(name: String)
signal volume_changed(value: float)
signal seek_to(ratio: float)
signal screen_size_changed(value: float)
signal screen_distance_changed(value: float)

const ACCENT := Color(0.24, 0.72, 1.0)
const PROGRESS := Color(1.0, 0.23, 0.19)
const GLASS := Color(0.04, 0.06, 0.1, 0.9)

var _title: Label
var _time: Label
var _play_icon: IconBtn
var _seek: HSlider
var _seeking := false


## Botón con icono dibujado por código (sin depender de fuentes ni de assets importados).
class IconBtn extends Button:
	var kind := "play"
	var label := ""

	func set_kind(k: String) -> void:
		kind = k
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var col := Color.WHITE
		var s := minf(size.x, size.y) * 0.26
		match kind:
			"play":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s), c + Vector2(s, 0)]), col)
			"pause":
				draw_rect(Rect2(c + Vector2(-s * 0.8, -s), Vector2(s * 0.55, s * 2)), col)
				draw_rect(Rect2(c + Vector2(s * 0.25, -s), Vector2(s * 0.55, s * 2)), col)
			"back", "fwd":
				var d := -1.0 if kind == "back" else 1.0
				var h := s * 0.7
				var x0 := c.x - d * s * 1.15
				for i in 2:
					var x := x0 + d * i * h
					draw_colored_polygon(PackedVector2Array([Vector2(x + d * h, c.y - h), Vector2(x + d * h, c.y + h), Vector2(x, c.y)]), col)
				var f := ThemeDB.fallback_font
				draw_string(f, Vector2(c.x + d * s * 1.15 - 14.0, c.y + s * 1.9), label, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 20, Color(1, 1, 1, 0.85))


func _ready() -> void:
	size = Vector2(900, 360)
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := _box(GLASS, 28)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.4, 0.65, 1.0, 0.35)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30; root.offset_right = -30; root.offset_top = 20; root.offset_bottom = -20
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# Cabecera: título y tiempo
	var top := HBoxContainer.new()
	root.add_child(top)
	_title = _label("SmartTube VR 3D · Playa", 32)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_time = _label("0:00 / 0:00", 30)
	top.add_child(_time)

	# Barra de progreso (clic para saltar)
	_seek = HSlider.new()
	_seek.min_value = 0.0; _seek.max_value = 1.0; _seek.step = 0.001
	_seek.custom_minimum_size = Vector2(0, 36)
	_seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seek.add_theme_stylebox_override("slider", _bar(Color(1, 1, 1, 0.22)))
	_seek.add_theme_stylebox_override("grabber_area", _bar(PROGRESS))
	_seek.add_theme_stylebox_override("grabber_area_highlight", _bar(PROGRESS))
	_seek.drag_started.connect(func(): _seeking = true)
	_seek.drag_ended.connect(func(_changed: bool):
		_seeking = false
		seek_to.emit(_seek.value))
	root.add_child(_seek)

	# Controles de reproducción
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	root.add_child(row1)
	row1.add_child(_icon_btn("back", "seek_back", "10"))
	_play_icon = _icon_btn("pause", "play_pause")
	_play_icon.custom_minimum_size = Vector2(120, 76)
	row1.add_child(_play_icon)
	row1.add_child(_icon_btn("fwd", "seek_fwd", "10"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(spacer)
	row1.add_child(_btn("Centrar", "recenter"))
	row1.add_child(_btn("Salir", "exit"))

	# Ajustes de pantalla virtual y volumen
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 24)
	root.add_child(row2)
	row2.add_child(_slider_col("Volumen", 0.0, 1.0, 0.05, 0.8, func(v): volume_changed.emit(v)))
	row2.add_child(_slider_col("Tamaño", 3.0, 20.0, 0.5, 8.0, func(v): screen_size_changed.emit(v)))
	row2.add_child(_slider_col("Distancia", 4.0, 25.0, 0.5, 10.0, func(v): screen_distance_changed.emit(v)))


func _box(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	return s


func _bar(c: Color) -> StyleBoxFlat:
	var s := _box(c, 6)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.09), 20))
	b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.2), 20))
	b.add_theme_stylebox_override("pressed", _box(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.7), 20))
	b.add_theme_stylebox_override("focus", _box(Color(1, 1, 1, 0.14), 20))


func _label(t: String, s: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", s)
	return l


func _btn(t: String, act: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(150, 76)
	b.add_theme_font_size_override("font_size", 28)
	_style_button(b)
	b.pressed.connect(func(): action.emit(act))
	return b


func _icon_btn(kind: String, act: String, lbl := "") -> IconBtn:
	var b := IconBtn.new()
	b.kind = kind
	b.label = lbl
	b.custom_minimum_size = Vector2(100, 76)
	_style_button(b)
	b.pressed.connect(func(): action.emit(act))
	return b


func _slider_col(t: String, lo: float, hi: float, step: float, val: float, cb: Callable) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	col.add_child(_label(t, 26))
	var sl := HSlider.new()
	sl.min_value = lo; sl.max_value = hi; sl.step = step; sl.value = val
	sl.custom_minimum_size = Vector2(0, 44)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.add_theme_stylebox_override("slider", _bar(Color(1, 1, 1, 0.22)))
	sl.add_theme_stylebox_override("grabber_area", _bar(ACCENT))
	sl.add_theme_stylebox_override("grabber_area_highlight", _bar(ACCENT))
	sl.value_changed.connect(cb)
	col.add_child(sl)
	return col


func set_status(playing: bool, pos: float, length: float) -> void:
	if _play_icon == null:
		return
	_play_icon.set_kind("pause" if playing else "play")
	_time.text = "%s / %s" % [_fmt(pos), _fmt(length)]
	if not _seeking and length > 0.0:
		_seek.set_value_no_signal(clampf(pos / length, 0.0, 1.0))


func _fmt(s: float) -> String:
	var t := int(maxf(s, 0.0))
	return "%d:%02d" % [t / 60, t % 60]

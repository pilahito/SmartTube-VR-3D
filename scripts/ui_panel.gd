## Panel de control flotante (se muestra en 3D con XRToolsViewport2DIn3D).
extends Control

signal action(name: String)
signal volume_changed(value: float)

var _title: Label
var _time: Label
var _play_btn: Button
var _vol: HSlider
var _world: Label

func _ready() -> void:
	size = Vector2(900, 450)
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.12, 0.88)
	sb.set_corner_radius_all(28)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30; root.offset_right = -30; root.offset_top = 20; root.offset_bottom = -20
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	_title = _label("SmartTube VR 3D", 34)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_time = _label("0:00 / 0:00", 30)
	top.add_child(_time)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	root.add_child(row1)
	row1.add_child(_btn("« -10 s", "seek_back"))
	_play_btn = _btn("Pausa", "play_pause")
	row1.add_child(_play_btn)
	row1.add_child(_btn("+10 s »", "seek_fwd"))
	row1.add_child(_btn("Centrar", "recenter"))
	row1.add_child(_btn("Salir", "exit"))

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	root.add_child(row2)
	row2.add_child(_btn("Más cerca", "closer"))
	row2.add_child(_btn("Más lejos", "farther"))
	row2.add_child(_btn("Más pequeña", "smaller"))
	row2.add_child(_btn("Más grande", "bigger"))

	var row_world := HBoxContainer.new()
	row_world.add_theme_constant_override("separation", 12)
	root.add_child(row_world)
	var prev := _btn("◀ Mundo", "world_prev")
	prev.size_flags_horizontal = Control.SIZE_FILL
	row_world.add_child(prev)
	_world = _label("", 30)
	_world.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world.clip_text = true
	row_world.add_child(_world)
	var next := _btn("Mundo ▶", "world_next")
	next.size_flags_horizontal = Control.SIZE_FILL
	row_world.add_child(next)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 16)
	root.add_child(row3)
	row3.add_child(_label("Volumen", 30))
	_vol = HSlider.new()
	_vol.min_value = 0; _vol.max_value = 1; _vol.step = 0.05; _vol.value = 0.8
	_vol.custom_minimum_size = Vector2(0, 50)
	_vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vol.value_changed.connect(func(v): volume_changed.emit(v))
	row3.add_child(_vol)


func _label(t: String, s: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", s)
	return l


func _btn(t: String, act: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(150, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func(): action.emit(act))
	return b


func set_world_name(world_name: String) -> void:
	if _world:
		_world.text = world_name


func set_status(playing: bool, pos: float, length: float) -> void:
	if _play_btn == null:
		return
	_play_btn.text = "Pausa" if playing else "Reproducir"
	_time.text = "%s / %s" % [_fmt(pos), _fmt(length)]


func _fmt(s: float) -> String:
	var t := int(maxf(s, 0.0))
	return "%d:%02d" % [t / 60, t % 60]

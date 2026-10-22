## Panel "Pantalla virtual" (docs/interfaz/pantalla-ajustes.jpg).
## Emite `setting(clave, valor)`; el estado real vive en CinemaScreen y se refleja con sync_from().
extends Control

signal setting(key: String, value: Variant)

const FORMAT_NAMES := ["21:9", "16:9", "32:9", "4:3", CinemaScreen.FORMAT_FIT]
const PRESET_BUTTONS := [["Cine", "Cine"], ["Tumbado (techo)", "Tumbado"], ["Escritorio", "Escritorio"]]

var _curved_btn: Button
var _flat_btn: Button
var _format_btns := {}
var _sliders := {}       # clave -> HSlider
var _values := {}        # clave -> Label
var _sbs_btn: Button
var _proj_btn: Button


func _ready() -> void:
	size = Vector2(480, 800)
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIKit.glass(28, 26, 22))
	add_child(bg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	bg.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := UIKit.label("Pantalla virtual", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := IconBtn.new()
	close.kind = "close"
	close.custom_minimum_size = Vector2(56, 56)
	UIKit.style_button(close)
	close.pressed.connect(func(): setting.emit("close", true))
	head.add_child(close)

	var shape := HBoxContainer.new()
	shape.add_theme_constant_override("separation", 10)
	col.add_child(shape)
	var shape_group := ButtonGroup.new()
	_curved_btn = _toggle("Curva", Vector2(0, 56), 26, shape_group)
	_curved_btn.pressed.connect(func(): setting.emit("curved", true))
	_flat_btn = _toggle("Plana", Vector2(0, 56), 26, shape_group)
	_flat_btn.pressed.connect(func(): setting.emit("curved", false))
	shape.add_child(_curved_btn)
	shape.add_child(_flat_btn)

	_add_slider(col, "curvature", "Curvatura", 0.2, 1.5, 0.05, 1.0)

	col.add_child(UIKit.label("Formato", 26))
	var formats := HBoxContainer.new()
	formats.add_theme_constant_override("separation", 8)
	col.add_child(formats)
	var fmt_group := ButtonGroup.new()
	for f in FORMAT_NAMES:
		var b := _toggle(f, Vector2(0, 48), 20, fmt_group, 4)
		b.pressed.connect(func(): setting.emit("format", f))
		formats.add_child(b)
		_format_btns[f] = b

	_add_slider(col, "diagonal_inches", "Tamaño", 40.0, 600.0, 5.0, 360.0)
	_add_slider(col, "distance", "Distancia", 1.5, 25.0, 0.5, 10.0)
	_add_slider(col, "height", "Altura", -2.0, 6.0, 0.1, 0.6)
	_add_slider(col, "tilt_deg", "Inclinación", -30.0, 90.0, 1.0, 0.0)

	var presets := HFlowContainer.new()
	presets.add_theme_constant_override("h_separation", 8)
	presets.add_theme_constant_override("v_separation", 8)
	col.add_child(presets)
	for p in PRESET_BUTTONS:
		var b := UIKit.text_button(p[0], 22, Vector2(0, 48), 16)
		b.pressed.connect(func(): setting.emit("preset", p[1]))
		presets.add_child(b)
	_sbs_btn = UIKit.text_button("3D lado a lado", 22, Vector2(0, 48), 16)
	_sbs_btn.toggle_mode = true
	_sbs_btn.toggled.connect(func(on: bool): setting.emit("stereo_sbs", on))
	presets.add_child(_sbs_btn)
	_proj_btn = UIKit.text_button("360°/180°", 22, Vector2(0, 48), 16)
	_proj_btn.toggle_mode = true
	_proj_btn.pressed.connect(func(): setting.emit("projection_next", true))
	presets.add_child(_proj_btn)


func _toggle(t: String, min_size: Vector2, font_size: int, group: ButtonGroup, pad := 14) -> Button:
	var b := UIKit.text_button(t, font_size, min_size, 16, pad)
	b.toggle_mode = true
	b.button_group = group
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _add_slider(parent: Control, key: String, label_text: String, lo: float, hi: float, step: float, val: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := UIKit.label(label_text, 26)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := UIKit.label("", 24, Color(1, 1, 1, 0.8))
	row.add_child(v)
	var s := UIKit.slider(lo, hi, step, val, UIKit.ACCENT, 30)
	s.value_changed.connect(func(x: float):
		_values[key].text = _fmt(key, x)
		setting.emit(key, x))
	parent.add_child(s)
	_sliders[key] = s
	_values[key] = v
	v.text = _fmt(key, val)


func _fmt(key: String, v: float) -> String:
	match key:
		"curvature": return "%d%%" % roundi(v * 100.0)
		"diagonal_inches": return "%d pulgadas" % roundi(v)
		"tilt_deg": return "%d°" % roundi(v)
		_: return "%.1f m" % v


## Refleja en los controles el estado actual de la pantalla (tras un preajuste, por ejemplo).
func sync_from(s: CinemaScreen) -> void:
	_curved_btn.set_pressed_no_signal(s.curved)
	_flat_btn.set_pressed_no_signal(not s.curved)
	for f in _format_btns:
		_format_btns[f].set_pressed_no_signal(f == s.format)
	for key in _sliders:
		var v: float = s.get(key)
		_sliders[key].set_value_no_signal(v)
		_values[key].text = _fmt(key, v)
	_sbs_btn.set_pressed_no_signal(s.stereo_sbs)
	_proj_btn.set_pressed_no_signal(s.projection != 0)
	_proj_btn.text = "360°/180°" if s.projection == 0 else "%d°" % s.projection

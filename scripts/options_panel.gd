## Panel "Reproductor VR" con las opciones (arriba a la derecha), como en docs/interfaz/reproductor.jpg.
extends Control

signal action(name: String)

var _sub: Label


func _ready() -> void:
	size = Vector2(470, 515)
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIKit.glass(28, 26, 22))
	add_child(bg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	bg.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var icon := IconBtn.new()
	icon.kind = "monitor"
	icon.custom_minimum_size = Vector2(72, 72)
	icon.flat = true
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	head.add_child(titles)
	titles.add_child(UIKit.label("Reproductor VR", 34))
	_sub = UIKit.label("", 24, UIKit.MUTED)
	titles.add_child(_sub)
	var close := IconBtn.new()
	close.kind = "close"
	close.custom_minimum_size = Vector2(56, 56)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	UIKit.style_flat(close)
	close.pressed.connect(func(): action.emit("close"))
	head.add_child(close)

	col.add_child(_gap(6))
	col.add_child(UIKit.divider())
	col.add_child(_gap(10))
	col.add_child(UIKit.label("Opciones", 26))
	col.add_child(_row("scenes", "Escenarios", "scenarios"))
	col.add_child(UIKit.divider())
	col.add_child(_row("screen_curved", "Ajustes de video", "video_settings"))
	col.add_child(UIKit.divider())
	col.add_child(_row("recenter", "Centrar vista", "recenter"))
	col.add_child(UIKit.divider())
	col.add_child(_row("exit", "Salir de la app", "exit"))


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _row(lead: String, text: String, act: String) -> IconBtn:
	var b := IconBtn.new()
	b.lead = lead
	b.trail = "chevron"
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 28)
	b.custom_minimum_size = Vector2(0, 70)
	UIKit.style_flat(b, 14)
	b.add_theme_stylebox_override("normal", _pad(StyleBoxEmpty.new()))
	for state in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, _pad(b.get_theme_stylebox(state)))
	b.pressed.connect(func(): action.emit(act))
	return b


func _pad(s: StyleBox) -> StyleBox:
	s.content_margin_left = 84
	s.content_margin_right = 44
	return s


func set_info(text: String) -> void:
	_sub.text = text

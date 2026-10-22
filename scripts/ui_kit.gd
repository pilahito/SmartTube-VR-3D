## Estilo compartido de los paneles (cristal oscuro, acento azul), tomado de docs/interfaz/.
class_name UIKit
extends RefCounted

const ACCENT := Color(0.24, 0.72, 1.0)
const PROGRESS := Color(1.0, 0.23, 0.19)
const GLASS := Color(0.04, 0.06, 0.1, 0.9)
const TRACK := Color(1, 1, 1, 0.22)


static func box(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	return s


static func glass(r: int, margin_h: int, margin_v: int) -> StyleBoxFlat:
	var s := box(GLASS, r)
	s.set_border_width_all(2)
	s.border_color = Color(0.4, 0.65, 1.0, 0.35)
	s.content_margin_left = margin_h
	s.content_margin_right = margin_h
	s.content_margin_top = margin_v
	s.content_margin_bottom = margin_v
	return s


static func bar(c: Color) -> StyleBoxFlat:
	var s := box(c, 6)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func label(t: String, size: int, c := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	return l


static func _padded(c: Color, radius: int, pad: int) -> StyleBoxFlat:
	var s := box(c, radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	return s


static func style_button(b: Button, radius := 20, pad := 14) -> void:
	b.add_theme_stylebox_override("normal", _padded(Color(1, 1, 1, 0.09), radius, pad))
	b.add_theme_stylebox_override("hover", _padded(Color(1, 1, 1, 0.2), radius, pad))
	var on := _padded(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.75), radius, pad)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("focus", _padded(Color(1, 1, 1, 0.14), radius, pad))


static func text_button(t: String, font_size: int, min_size: Vector2, radius := 20, pad := 14) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	style_button(b, radius, pad)
	return b


static func slider(lo: float, hi: float, step: float, val: float, fill: Color, height := 36) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = val
	s.custom_minimum_size = Vector2(0, height)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_theme_stylebox_override("slider", bar(TRACK))
	s.add_theme_stylebox_override("grabber_area", bar(fill))
	s.add_theme_stylebox_override("grabber_area_highlight", bar(fill))
	return s

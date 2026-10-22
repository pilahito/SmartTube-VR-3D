## Estilo compartido de los paneles (cristal gris oscuro, acento azul), tomado de docs/interfaz/.
class_name UIKit
extends RefCounted

const ACCENT := Color(0.08, 0.5, 1.0)
const PROGRESS := Color(0.88, 0.2, 0.2)
const GLASS := Color(0.07, 0.07, 0.08, 0.9)
const BORDER := Color(1, 1, 1, 0.16)
const TRACK := Color(1, 1, 1, 0.2)
const MUTED := Color(1, 1, 1, 0.6)


static func box(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	return s


## Fondo de panel: cristal oscuro con borde fino.
static func glass(r: int, margin_h: int, margin_v: int) -> StyleBoxFlat:
	var s := box(GLASS, r)
	s.set_border_width_all(2)
	s.border_color = BORDER
	s.content_margin_left = margin_h
	s.content_margin_right = margin_h
	s.content_margin_top = margin_v
	s.content_margin_bottom = margin_v
	return s


## Etiqueta tipo "chip" (resolución, códec): píldora con borde.
static func chip_box(r := 22) -> StyleBoxFlat:
	var s := outlined(Color(1, 1, 1, 0.08), r)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func outlined(c: Color, r: int) -> StyleBoxFlat:
	var s := box(c, r)
	s.set_border_width_all(1)
	s.border_color = Color(1, 1, 1, 0.12)
	return s


static func label(t: String, size: int, c := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	return l


static func _btn_style(c: Color, radius: int, pad_l: int, pad_r: int, border: bool) -> StyleBoxFlat:
	var s := outlined(c, radius) if border else box(c, radius)
	s.content_margin_left = pad_l
	s.content_margin_right = pad_r
	return s


## Botón con borde fino; al activarse (toggle o pulsado) se rellena de azul.
static func style_button(b: Button, radius := 16, pad_l := 14, pad_r := -1) -> void:
	var pr := pad_l if pad_r < 0 else pad_r
	b.add_theme_stylebox_override("normal", _btn_style(Color(1, 1, 1, 0.07), radius, pad_l, pr, true))
	b.add_theme_stylebox_override("hover", _btn_style(Color(1, 1, 1, 0.16), radius, pad_l, pr, true))
	var on := _btn_style(ACCENT, radius, pad_l, pr, false)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("focus", _btn_style(Color(1, 1, 1, 0.12), radius, pad_l, pr, true))


## Botón sin caja (solo un icono): se ilumina al apuntarlo.
static func style_flat(b: Button, radius := 18) -> void:
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.12), radius))
	b.add_theme_stylebox_override("pressed", box(Color(1, 1, 1, 0.22), radius))
	b.add_theme_stylebox_override("hover_pressed", box(Color(1, 1, 1, 0.22), radius))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func text_button(t: String, font_size: int, min_size: Vector2, radius := 16, pad := 14) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	style_button(b, radius, pad)
	return b


## Círculo suave para el pomo de los sliders (o transparente si c.a == 0).
static func dot(c: Color, d: int) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d * 0.5
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(r, r))
			var a := clampf(r - dist + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * a))
	return ImageTexture.create_from_image(img)


## Slider de pista fina con pomo redondo (thumb = 0 lo oculta, como en la barra de progreso).
static func slider(lo: float, hi: float, step: float, val: float, fill: Color, height := 36, track := 6, thumb := 26) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = val
	s.custom_minimum_size = Vector2(0, height)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_theme_stylebox_override("slider", bar(TRACK, track))
	s.add_theme_stylebox_override("grabber_area", bar(fill, track))
	s.add_theme_stylebox_override("grabber_area_highlight", bar(fill, track))
	var knob := dot(Color(fill.r, fill.g, fill.b, 1.0 if thumb > 0 else 0.0), maxi(thumb, 2))
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_icon_override("grabber_disabled", knob)
	return s


static func bar(c: Color, h: int) -> StyleBoxFlat:
	var s := box(c, h)
	s.content_margin_top = h * 0.5
	s.content_margin_bottom = h * 0.5
	return s


static func divider() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.1)
	r.custom_minimum_size = Vector2(0, 1)
	return r

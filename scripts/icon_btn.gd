## Botón con iconos dibujados por código (sin depender de fuentes ni de assets importados).
## `kind` va centrado; `lead` a la izquierda del texto y `trail` a la derecha.
class_name IconBtn
extends Button

var kind := ""
var lead := ""
var trail := ""
var caption := ""


func set_kind(k: String) -> void:
	if k != kind:
		kind = k
		queue_redraw()


func _draw() -> void:
	if kind != "":
		_icon(kind, size * 0.5, minf(size.x, size.y) * 0.26)
	if lead != "":
		_icon(lead, Vector2(size.y * 0.55, size.y * 0.5), size.y * 0.26)
	if trail != "":
		_icon(trail, Vector2(size.x - size.y * 0.45, size.y * 0.5), size.y * 0.2)


func _icon(k: String, c: Vector2, s: float) -> void:
	var col := Color.WHITE
	match k:
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s), c + Vector2(s, 0)]), col)
		"pause":
			draw_rect(Rect2(c + Vector2(-s * 0.8, -s), Vector2(s * 0.55, s * 2)), col)
			draw_rect(Rect2(c + Vector2(s * 0.25, -s), Vector2(s * 0.55, s * 2)), col)
		"back", "fwd":
			# Dos triángulos con la punta hacia el sentido del salto; debajo, los segundos.
			var d := -1.0 if k == "back" else 1.0
			var h := s * 0.7
			var x0 := c.x - d * h
			for i in 2:
				var base := x0 + d * i * h
				draw_colored_polygon(PackedVector2Array([Vector2(base, c.y - h), Vector2(base, c.y + h), Vector2(base + d * h, c.y)]), col)
			draw_string(ThemeDB.fallback_font, Vector2(c.x - 14.0, c.y + s * 1.9), caption, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 20, Color(1, 1, 1, 0.85))
		"close":
			draw_line(c + Vector2(-s, -s) * 0.8, c + Vector2(s, s) * 0.8, col, 4.0, true)
			draw_line(c + Vector2(-s, s) * 0.8, c + Vector2(s, -s) * 0.8, col, 4.0, true)
		"gear":
			draw_arc(c, s * 0.7, 0.0, TAU, 32, col, 4.0, true)
			for i in 8:
				var v := Vector2.from_angle(TAU * i / 8.0)
				draw_line(c + v * s * 0.85, c + v * s * 1.2, col, 5.0, true)
		"expand":
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var p: Vector2 = c + Vector2(sx, sy) * s
					draw_line(p, p + Vector2(-sx * s * 0.6, 0), col, 4.0, true)
					draw_line(p, p + Vector2(0, -sy * s * 0.6), col, 4.0, true)
		"speaker":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, -s * 0.4), c + Vector2(-s * 0.4, -s * 0.4), c + Vector2(s * 0.2, -s * 0.9),
				c + Vector2(s * 0.2, s * 0.9), c + Vector2(-s * 0.4, s * 0.4), c + Vector2(-s, s * 0.4)]), col)
			draw_arc(c + Vector2(s * 0.2, 0), s * 0.7, -0.9, 0.9, 12, col, 3.0, true)
		"menu":
			for i in 3:
				draw_line(c + Vector2(-s, (i - 1) * s * 0.7), c + Vector2(s, (i - 1) * s * 0.7), col, 4.0, true)
		"chevron":
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.5, -s), c + Vector2(s * 0.5, 0), c + Vector2(-s * 0.5, s)]), Color(1, 1, 1, 0.7), 3.5, true)
		"undo":
			# Flecha que vuelve atrás: arco abierto con la punta arriba a la izquierda.
			var r := s * 0.95
			var cc := c + Vector2(0, s * 0.15)
			draw_arc(cc, r, -PI * 0.5, PI * 0.65, 24, col, 3.5, true)
			var tip := cc + Vector2(0, -r)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.55, 0), tip + Vector2(s * 0.1, -s * 0.45), tip + Vector2(s * 0.1, s * 0.45)]), col)
		"monitor":
			draw_rect(Rect2(c + Vector2(-s * 1.1, -s * 0.9), Vector2(s * 2.2, s * 1.5)), col, false, 3.5)
			draw_line(c + Vector2(0, s * 0.6), c + Vector2(0, s * 1.0), col, 3.5, true)
			draw_line(c + Vector2(-s * 0.6, s * 1.0), c + Vector2(s * 0.6, s * 1.0), col, 3.5, true)
		"screen_curved":
			# Pantalla curva de frente: bordes superior e inferior combados hacia el centro.
			var w := s * 1.15
			var top := PackedVector2Array()
			var bottom := PackedVector2Array()
			for i in 13:
				var x := lerpf(-w, w, i / 12.0)
				var sag := s * 0.45 * (1.0 - pow(x / w, 2.0))
				top.append(c + Vector2(x, -s * 0.8 + sag))
				bottom.append(c + Vector2(x, s * 0.35 + sag))
			draw_polyline(top, col, 3.5, true)
			draw_polyline(bottom, col, 3.5, true)
			draw_line(top[0], bottom[0], col, 3.5, true)
			draw_line(top[12], bottom[12], col, 3.5, true)
		"screen_flat":
			draw_rect(Rect2(c + Vector2(-s * 1.1, -s * 0.8), Vector2(s * 2.2, s * 1.6)), col, false, 3.5)
		"recenter":
			draw_arc(c, s * 0.8, 0.0, TAU, 24, col, 3.5, true)
			draw_line(c + Vector2(0, -s * 1.2), c + Vector2(0, -s * 0.5), col, 3.5, true)
			draw_line(c + Vector2(0, s * 1.2), c + Vector2(0, s * 0.5), col, 3.5, true)
			draw_line(c + Vector2(-s * 1.2, 0), c + Vector2(-s * 0.5, 0), col, 3.5, true)
			draw_line(c + Vector2(s * 1.2, 0), c + Vector2(s * 0.5, 0), col, 3.5, true)
		"exit":
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.1, -s), c + Vector2(-s, -s), c + Vector2(-s, s), c + Vector2(-s * 0.1, s)]), col, 3.5, true)
			draw_line(c + Vector2(-s * 0.3, 0), c + Vector2(s, 0), col, 3.5, true)
			draw_polyline(PackedVector2Array([c + Vector2(s * 0.45, -s * 0.5), c + Vector2(s, 0), c + Vector2(s * 0.45, s * 0.5)]), col, 3.5, true)

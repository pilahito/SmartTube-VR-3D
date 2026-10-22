## Botón con icono dibujado por código (sin depender de fuentes ni de assets importados).
class_name IconBtn
extends Button

var kind := "play"
var caption := ""


func set_kind(k: String) -> void:
	if k != kind:
		kind = k
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var s := minf(size.x, size.y) * 0.26
	var col := Color.WHITE
	match kind:
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s), c + Vector2(s, 0)]), col)
		"pause":
			draw_rect(Rect2(c + Vector2(-s * 0.8, -s), Vector2(s * 0.55, s * 2)), col)
			draw_rect(Rect2(c + Vector2(s * 0.25, -s), Vector2(s * 0.55, s * 2)), col)
		"back", "fwd":
			# Dos triángulos con la punta hacia el sentido del salto; debajo, los segundos.
			var d := -1.0 if kind == "back" else 1.0
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
					var p := c + Vector2(sx, sy) * s
					draw_line(p, p + Vector2(-sx * s * 0.6, 0), col, 4.0, true)
					draw_line(p, p + Vector2(0, -sy * s * 0.6), col, 4.0, true)
		"speaker":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, -s * 0.4), c + Vector2(-s * 0.4, -s * 0.4), c + Vector2(s * 0.2, -s * 0.9),
				c + Vector2(s * 0.2, s * 0.9), c + Vector2(-s * 0.4, s * 0.4), c + Vector2(-s, s * 0.4)]), col)
			draw_arc(c + Vector2(s * 0.2, 0), s * 0.7, -0.9, 0.9, 12, col, 3.0, true)

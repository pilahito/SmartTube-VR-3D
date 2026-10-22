## Casilla del menú Escenarios: miniatura dibujada por código con el cielo, el suelo y algo de la escena.
class_name ScenarioTile
extends Button

var def := {}
var chosen := false: set = _set_chosen


func _set_chosen(v: bool) -> void:
	chosen = v
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var inner := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	_thumb(inner)
	draw_rect(Rect2(inner.position.x, inner.end.y - 38, inner.size.x, 38), Color(0, 0, 0, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(inner.position.x, inner.end.y - 11), def.get("name", ""),
		HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 22, Color.WHITE)
	var lit := chosen or is_hovered()
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(4 if lit else 1)
	sb.border_color = UIKit.ACCENT if lit else Color(1, 1, 1, 0.18)
	draw_style_box(sb, r)


func _thumb(r: Rect2) -> void:
	var kind: String = def.get("kind", "beach")
	var top: Color = def["sky_top"]
	var hor: Color = def["sky_horizon"]
	var ground: Color = def["ground"]
	var horizon_y := r.position.y + r.size.y * (0.62 if kind != "room" else 0.7)
	var w := r.size.x
	var x0 := r.position.x
	var y0 := r.position.y
	var h := r.size.y
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, y0), Vector2(r.end.x, horizon_y), Vector2(x0, horizon_y)]),
		PackedColorArray([top, top, hor, hor]))
	match kind:
		"beach":
			var t: Color = def.get("tint", Color.WHITE)
			var sun: Color = def.get("sun", Color.WHITE)
			draw_circle(Vector2(x0 + w * 0.72, y0 + h * (0.5 if def["id"] == "playa_atardecer" else 0.26)), h * 0.09, sun.lightened(0.3))
			draw_rect(Rect2(x0, horizon_y - h * 0.12, w, h * 0.12), Scenarios.SEA_SHALLOW * t)
			draw_rect(Rect2(x0, horizon_y, w, r.end.y - horizon_y), Scenarios.SAND_DRY * t)
			var trunk := Color(0.3, 0.2, 0.12) * t
			draw_line(Vector2(x0 + w * 0.2, r.end.y - 6), Vector2(x0 + w * 0.26, y0 + h * 0.3), trunk, 3.0)
			for a in [-2.6, -1.9, -1.2, -0.5]:
				draw_line(Vector2(x0 + w * 0.26, y0 + h * 0.3), Vector2(x0 + w * 0.26, y0 + h * 0.3) + Vector2.from_angle(a) * h * 0.22 + Vector2(0, h * 0.08), Color(0.1, 0.45, 0.2) * t, 3.0)
		"forest":
			draw_rect(Rect2(x0, horizon_y, w, r.end.y - horizon_y), ground)
			var leaf: Color = def["leaf"]
			for i in 9:
				var tx := x0 + w * (0.06 + i * 0.11)
				var th := h * (0.38 + 0.12 * ((i * 5) % 3))
				var base_y := horizon_y + h * 0.1 * (i % 2)
				draw_colored_polygon(PackedVector2Array([Vector2(tx, base_y - th), Vector2(tx - th * 0.3, base_y), Vector2(tx + th * 0.3, base_y)]), leaf)
			if def.has("glow"):
				for i in 12:
					draw_circle(Vector2(x0 + w * ((i * 37 % 100) / 100.0), y0 + h * (0.35 + (i * 23 % 50) / 100.0)), 2.5, def["accent"])
		"mountains":
			draw_rect(Rect2(x0, horizon_y, w, r.end.y - horizon_y), ground)
			var rock: Color = def["accent"]
			for m in [[0.28, 0.5, 0.3], [0.62, 0.62, 0.34], [0.86, 0.4, 0.24]]:
				var cx: float = x0 + w * m[0]
				var ph: float = h * m[1]
				var pw: float = w * m[2]
				draw_colored_polygon(PackedVector2Array([Vector2(cx, horizon_y - ph), Vector2(cx - pw, horizon_y), Vector2(cx + pw, horizon_y)]), rock)
				draw_colored_polygon(PackedVector2Array([Vector2(cx, horizon_y - ph), Vector2(cx - pw * 0.3, horizon_y - ph * 0.65), Vector2(cx + pw * 0.3, horizon_y - ph * 0.65)]), Color.WHITE)
		"space":
			draw_rect(r, Color(0, 0, 0.03))
			for i in 40:
				draw_circle(Vector2(x0 + w * ((i * 53 % 100) / 100.0), y0 + h * ((i * 31 % 100) / 100.0)), 1.2, Color(1, 1, 1, 0.8))
			draw_circle(Vector2(x0 + w * 0.3, y0 + h * 0.48), h * 0.3, Color(0.25, 0.4, 0.85))
			draw_circle(Vector2(x0 + w * 0.7, y0 + h * 0.3), h * 0.1, Color(0.6, 0.55, 0.5))
			draw_arc(Vector2(x0 + w * 0.5, r.end.y - h * 0.18), w * 0.2, 0.0, TAU, 32, def["accent"], 3.0)
		"city":
			draw_rect(Rect2(x0, horizon_y, w, r.end.y - horizon_y), ground)
			for i in 11:
				var bx := x0 + w * i * 0.093
				var bh := h * (0.3 + 0.35 * ((i * 7) % 5) / 5.0)
				draw_rect(Rect2(bx, horizon_y - bh, w * 0.085, bh), Color(0.06, 0.04, 0.12))
				for j in 4:
					draw_rect(Rect2(bx + 3 + (j % 2) * 8, horizon_y - bh + 6 + j * 10, 4, 4), def["accent"] if (i + j) % 2 == 0 else def["accent2"])
			draw_rect(Rect2(x0, horizon_y, w, 2), def["accent"])
		"room":
			var wall: Color = def["wall"]
			draw_rect(Rect2(x0, y0, w, horizon_y - y0), wall)
			draw_rect(Rect2(x0, horizon_y, w, r.end.y - horizon_y), ground)
			draw_rect(Rect2(x0, horizon_y - 2, w, 3), def["accent"])
			draw_rect(Rect2(x0 + w * 0.3, y0 + h * 0.12, w * 0.4, h * 0.38), Color(0.02, 0.02, 0.03))
			draw_rect(Rect2(x0 + w * 0.06, y0 + h * 0.1, w * 0.1, h * 0.5), def["accent2"].darkened(0.1))
			draw_rect(Rect2(x0 + w * 0.84, y0 + h * 0.1, w * 0.1, h * 0.5), def["accent"])
			draw_rect(Rect2(x0 + w * 0.34, horizon_y + h * 0.05, w * 0.32, h * 0.1), def["accent"].darkened(0.2))

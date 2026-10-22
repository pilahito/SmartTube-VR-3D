## Casilla del catálogo de NebularVR: miniatura (el panorama descargado), nombre y categoría.
class_name CatalogTile
extends Button

var entry := {}
var texture: Texture2D
var chosen := false: set = _set_chosen


func _set_chosen(v: bool) -> void:
	chosen = v
	queue_redraw()


func set_texture(t: Texture2D) -> void:
	texture = t
	queue_redraw()


func _draw() -> void:
	var inner := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	if texture:
		draw_texture_rect(texture, inner, false)
	else:
		draw_rect(inner, Color(1, 1, 1, 0.06))
		draw_string(ThemeDB.fallback_font, Vector2(inner.position.x, inner.get_center().y), "Descargando…", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 20, UIKit.MUTED)
	draw_rect(Rect2(inner.position.x, inner.end.y - 38, inner.size.x, 38), Color(0, 0, 0, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(inner.position.x, inner.end.y - 11), entry.get("name", ""), HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 20, Color.WHITE)
	var lit := chosen or is_hovered()
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(4 if lit else 1)
	sb.border_color = UIKit.ACCENT if lit else Color(1, 1, 1, 0.18)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))

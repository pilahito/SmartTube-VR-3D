## Botón redondo de la barra rápida de escenarios (inicio.jpg, parte inferior).
class_name ScenarioDot
extends Button

var def := {}
var chosen := false: set = _set_chosen


func _set_chosen(v: bool) -> void:
	chosen = v
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, 76.0) * 0.5
	var c := Vector2(size.x * 0.5, r + 4.0)
	var lit := chosen or is_hovered()
	if lit:
		draw_circle(c, r + 5.0, Color(UIKit.ACCENT.r, UIKit.ACCENT.g, UIKit.ACCENT.b, 0.35))
	draw_circle(c, r, def["sky_top"].lerp(def["sky_horizon"], 0.5))
	# mitad inferior: suelo (arco relleno)
	var pts := PackedVector2Array()
	for i in 21:
		var a := lerpf(0.0, PI, i / 20.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var ground: Color = def["ground"] if def["kind"] != "beach" else Scenarios.SAND_DRY * def.get("tint", Color.WHITE)
	draw_colored_polygon(pts, ground)
	draw_arc(c, r, 0.0, TAU, 32, Color(UIKit.ACCENT if lit else Color(1, 1, 1, 0.35)), 3.0 if lit else 1.5, true)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(0, c.y + r + 30.0), def["short"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color.WHITE if lit else Color(1, 1, 1, 0.85))

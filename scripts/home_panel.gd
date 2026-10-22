## Pantalla de inicio (docs/interfaz/inicio.jpg): barra lateral, recomendados y barra rápida de escenarios.
## Sin datos de YouTube: la tarjeta de vídeo es el clip local y el resto son escenarios que se pueden aplicar.
extends Control

signal action(name: String)
signal scenario_chosen(id: String)

const QUICK := ["playa", "bosque", "cyberpunk", "espacio", "salon"]
const QUICK_NAMES := {"playa": "playa", "bosque": "bosque", "cyberpunk": "cyberpunk", "espacio": "espacio", "salon": "salón"}

var _duration: Label
var _current_dot: Panel
var _current_name: Label
var _tiles := {}
var _dots := {}
var _video: TextureRect


func _ready() -> void:
	size = Vector2(1220, 650)
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIKit.glass(30, 22, 20))
	add_child(bg)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	bg.add_child(root)
	root.add_child(_sidebar())
	root.add_child(_main())


func _sidebar() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(235, 0)
	col.add_theme_constant_override("separation", 6)
	var brand := HBoxContainer.new()
	brand.add_theme_constant_override("separation", 10)
	var logo := Panel.new()
	logo.custom_minimum_size = Vector2(46, 34)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo.add_theme_stylebox_override("panel", UIKit.box(Color(0.9, 0.1, 0.1), 9))
	brand.add_child(logo)
	brand.add_child(UIKit.label("SmartTube VR", 28))
	col.add_child(brand)
	col.add_child(_gap(14))
	for item in [["home", "Inicio", ""], ["scenes", "Escenarios", "scenarios"], ["screen_curved", "Pantalla", "video_settings"],
			["recenter", "Centrar vista", "recenter"], ["exit", "Salir", "exit"]]:
		var b := _nav(item[0], item[1], item[2] == "")
		var act: String = item[2]
		b.pressed.connect(func(): action.emit(act if act != "" else "close"))
		col.add_child(b)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	col.add_child(UIKit.divider())
	col.add_child(UIKit.label("Escenario actual", 20, UIKit.MUTED))
	var cur := HBoxContainer.new()
	cur.add_theme_constant_override("separation", 10)
	_current_dot = Panel.new()
	_current_dot.custom_minimum_size = Vector2(20, 20)
	_current_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cur.add_child(_current_dot)
	_current_name = UIKit.label("", 26, Color(0.4, 0.9, 0.7))
	cur.add_child(_current_name)
	col.add_child(cur)
	return col


func _nav(icon: String, text: String, active: bool) -> IconBtn:
	var b := IconBtn.new()
	b.lead = icon
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(0, 62)
	UIKit.style_flat(b, 14)
	var normal: StyleBox = UIKit.box(Color(UIKit.ACCENT.r, UIKit.ACCENT.g, UIKit.ACCENT.b, 0.28), 14) if active else StyleBoxEmpty.new()
	normal.content_margin_left = 72
	normal.content_margin_right = 12
	b.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "hover_pressed"]:
		b.get_theme_stylebox(state).content_margin_left = 72
	return b


func _main() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := UIKit.label("Recomendados para ti", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := IconBtn.new()
	close.kind = "close"
	close.custom_minimum_size = Vector2(64, 50)
	UIKit.style_flat(close)
	close.pressed.connect(func(): action.emit("close"))
	head.add_child(close)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	grid.add_child(_video_card())
	var scenes := ["bosque_magico", "playa_atardecer", "cyberpunk", "espacio", "salon_nocturno", "montanas", "cine"]
	for id in scenes:
		grid.add_child(_scenario_card(Scenarios.get_def(id)))

	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	col.add_child(_quick_bar())
	return col


func _card(thumb: Control, title: String, subtitle: String) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.custom_minimum_size = Vector2(205, 0)
	c.add_theme_constant_override("separation", 3)
	thumb.custom_minimum_size = Vector2(205, 116)
	c.add_child(thumb)
	var t := UIKit.label(title, 20)
	t.custom_minimum_size = Vector2(205, 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.max_lines_visible = 2
	c.add_child(t)
	c.add_child(UIKit.label(subtitle, 17, UIKit.MUTED))
	return c


func _video_card() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(205, 116)
	holder.clip_contents = true
	_video = TextureRect.new()
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_video.stretch_mode = TextureRect.STRETCH_SCALE
	holder.add_child(_video)
	_duration = UIKit.label("0:00", 18)
	_duration.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_duration.offset_left = -64
	_duration.offset_top = -30
	_duration.offset_right = -6
	_duration.offset_bottom = -4
	_duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	holder.add_child(_duration)
	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.pressed.connect(func(): action.emit("close"))
	holder.add_child(btn)
	var card := _card(holder, "Big Buck Bunny (clip de prueba)", "Vídeo local · en reproducción")
	return card


func _scenario_card(d: Dictionary) -> Control:
	var t := ScenarioTile.new()
	t.def = d
	t.show_name = false
	t.clip_contents = true
	for st in ["normal", "hover", "pressed", "focus"]:
		t.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var id: String = d["id"]
	t.pressed.connect(func(): scenario_chosen.emit(id))
	_tiles[id] = t
	return _card(t, d["name"], "Escenario")


func _quick_bar() -> Control:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", UIKit.outlined(Color(1, 1, 1, 0.05), 36))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	wrap.add_child(row)
	for id in QUICK:
		var d: Dictionary = Scenarios.get_def(id).duplicate()
		d["short"] = QUICK_NAMES[id]
		var b := ScenarioDot.new()
		b.def = d
		b.custom_minimum_size = Vector2(120, 118)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.pressed.connect(func(): scenario_chosen.emit(id))
		row.add_child(b)
		_dots[id] = b
	return wrap


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func set_video(tex: Texture2D) -> void:
	_video.texture = tex


func set_duration(seconds: float) -> void:
	var t := int(maxf(seconds, 0.0))
	_duration.text = "%d:%02d" % [t / 60, t % 60]


func set_current(def: Dictionary) -> void:
	_current_name.text = def["name"]
	_current_dot.add_theme_stylebox_override("panel", UIKit.box(def["sky_horizon"].lerp(def["accent"] if def.has("accent") else def["ground"], 0.4), 10))
	for k in _dots:
		_dots[k].chosen = (k == def["id"])

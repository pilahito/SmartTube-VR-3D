## Menú "Escenarios" (docs/interfaz/escenarios.jpg): cuadrícula de 4×4 con los 16 escenarios.
extends Control

signal chosen(id: String)
signal closed

var _tiles := {}


func _ready() -> void:
	size = Vector2(980, 710)
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIKit.glass(26, 24, 20))
	add_child(bg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	bg.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var brand := UIKit.label("SmartTube VR", 32)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(brand)
	var close := IconBtn.new()
	close.kind = "close"
	close.custom_minimum_size = Vector2(70, 54)
	UIKit.style_button(close, 12, 8)
	close.pressed.connect(func(): closed.emit())
	head.add_child(close)
	col.add_child(UIKit.label("Escenarios", 44))
	col.add_child(UIKit.divider())

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	for d in Scenarios.LIST:
		var t := ScenarioTile.new()
		t.def = d
		t.custom_minimum_size = Vector2(220, 122)
		t.clip_contents = true
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		t.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		t.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var id: String = d["id"]
		t.pressed.connect(func(): chosen.emit(id))
		grid.add_child(t)
		_tiles[id] = t


func set_current(id: String) -> void:
	for k in _tiles:
		_tiles[k].chosen = (k == id)

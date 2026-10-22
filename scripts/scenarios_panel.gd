## Menú "Escenarios" (docs/interfaz/escenarios.jpg): cuadrícula de 4×4 con los 16 escenarios.
extends Control

signal chosen(id: String)
signal closed
signal catalog_opened
signal catalog_chosen(entry: Dictionary)

var _tiles := {}
var _catalog_tiles := {}
var _page_builtin: Control
var _page_catalog: Control
var _catalog_grid: GridContainer
var _catalog_status: Label
var _tab_builtin: Button
var _tab_catalog: Button


func _ready() -> void:
	size = Vector2(980, 750)
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
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	col.add_child(tabs)
	var tab_group := ButtonGroup.new()
	_tab_builtin = _tab("Escenarios", tab_group)
	_tab_builtin.button_pressed = true
	_tab_builtin.pressed.connect(func(): _show_page(false))
	_tab_catalog = _tab("NebularVR", tab_group)
	_tab_catalog.pressed.connect(func():
		_show_page(true)
		catalog_opened.emit())
	tabs.add_child(_tab_builtin)
	tabs.add_child(_tab_catalog)
	col.add_child(UIKit.divider())

	_page_builtin = VBoxContainer.new()
	col.add_child(_page_builtin)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_page_builtin.add_child(grid)
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

	_page_catalog = VBoxContainer.new()
	_page_catalog.visible = false
	_page_catalog.add_theme_constant_override("separation", 8)
	col.add_child(_page_catalog)
	_catalog_status = UIKit.label("", 22, UIKit.MUTED)
	_page_catalog.add_child(_catalog_status)
	_catalog_grid = GridContainer.new()
	_catalog_grid.columns = 4
	_catalog_grid.add_theme_constant_override("h_separation", 10)
	_catalog_grid.add_theme_constant_override("v_separation", 10)
	_page_catalog.add_child(_catalog_grid)


func set_current(id: String) -> void:
	for k in _tiles:
		_tiles[k].chosen = (k == id)
	for k in _catalog_tiles:
		_catalog_tiles[k].chosen = ("nebular:" + k == id)


func _tab(t: String, group: ButtonGroup) -> Button:
	var b := UIKit.text_button(t, 30, Vector2(220, 60), 14, 20)
	b.toggle_mode = true
	b.button_group = group
	return b


func _show_page(catalog: bool) -> void:
	_page_builtin.visible = not catalog
	_page_catalog.visible = catalog


func set_catalog_status(text: String) -> void:
	_catalog_status.text = text
	_catalog_status.visible = text != ""


## Crea las casillas del catálogo (se rellenan con set_catalog_texture al llegar cada imagen).
func set_catalog_entries(entries: Array) -> void:
	for c in _catalog_grid.get_children():
		c.queue_free()
	_catalog_tiles.clear()
	for e in entries:
		var t := CatalogTile.new()
		t.entry = e
		t.custom_minimum_size = Vector2(220, 122)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for st in ["normal", "hover", "pressed", "focus"]:
			t.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		t.clip_contents = true
		t.pressed.connect(func(): catalog_chosen.emit(e))
		_catalog_grid.add_child(t)
		_catalog_tiles[e["id"]] = t
	set_catalog_status("" if not entries.is_empty() else "El catálogo no tiene entornos válidos")


func set_catalog_texture(id: String, tex: Texture2D) -> void:
	if _catalog_tiles.has(id):
		_catalog_tiles[id].set_texture(tex)


func show_catalog_tab() -> void:
	_tab_catalog.button_pressed = true
	_show_page(true)

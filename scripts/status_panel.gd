## Píldora de estado (arriba a la izquierda), como en docs/interfaz/reproductor.jpg.
## Sin Wi-Fi ni batería: Godot 4.7 no puede leerlos; se muestran el dispositivo y los Hz.
extends Control

signal menu_pressed

var _device: Label
var _rate: Label
var _rate_sep: ColorRect


func _ready() -> void:
	size = Vector2(500, 72)
	var pill := PanelContainer.new()
	pill.set_anchors_preset(Control.PRESET_FULL_RECT)
	pill.add_theme_stylebox_override("panel", UIKit.glass(36, 28, 10))
	add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(row)
	_device = _text("Escritorio")
	row.add_child(_device)
	row.add_child(_separator())
	_rate = _text("")
	row.add_child(_rate)
	_rate_sep = _separator()
	row.add_child(_rate_sep)
	var menu := IconBtn.new()
	menu.kind = "menu"
	menu.custom_minimum_size = Vector2(56, 52)
	UIKit.style_flat(menu)
	menu.pressed.connect(func(): menu_pressed.emit())
	row.add_child(menu)


func _text(t: String) -> Label:
	var l := UIKit.label(t, 28)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _separator() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.3)
	r.custom_minimum_size = Vector2(2, 34)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func set_device(model: String, rate: String) -> void:
	_device.text = model
	_rate.text = rate
	_rate.visible = rate != ""
	_rate_sep.visible = rate != ""

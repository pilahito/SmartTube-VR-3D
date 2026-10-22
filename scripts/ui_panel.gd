## Barra de reproducción flotante (se muestra en 3D con XRToolsViewport2DIn3D).
## Diseño basado en docs/interfaz/reproductor.jpg: píldora de estado arriba y barra de cristal abajo.
extends Control

signal action(name: String)
signal volume_changed(value: float)
signal seek_to(ratio: float)

const UNDO_SECONDS := 5.0

var _device: Label
var _time: Label
var _info: Label
var _play: IconBtn
var _seek: HSlider
var _undo: Button
var _undo_left := 0.0
var _seeking := false


func _ready() -> void:
	size = Vector2(1280, 290)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Píldora de estado (arriba a la izquierda)
	var top := HBoxContainer.new()
	root.add_child(top)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.glass(26, 22, 8))
	_device = UIKit.label("SmartTube VR 3D", 26)
	pill.add_child(_device)
	top.add_child(pill)

	# Barra de cristal
	var glass := PanelContainer.new()
	glass.add_theme_stylebox_override("panel", UIKit.glass(28, 28, 16))
	root.add_child(glass)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	glass.add_child(col)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	col.add_child(row1)
	_play = _icon_btn("pause", "play_pause", Vector2(96, 72))
	row1.add_child(_play)
	row1.add_child(_icon_btn("back", "seek_back", Vector2(84, 72), "10"))
	row1.add_child(_icon_btn("fwd", "seek_fwd", Vector2(84, 72), "10"))
	_time = UIKit.label("0:00 / 0:00", 30)
	_time.custom_minimum_size = Vector2(170, 0)
	_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row1.add_child(_time)
	_undo = UIKit.text_button("Deshacer salto 5 s", 24, Vector2(210, 72))
	_undo.visible = false
	_undo.pressed.connect(func():
		_undo_left = 0.0
		_undo.visible = false
		action.emit("undo_seek"))
	row1.add_child(_undo)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(spacer)
	var vol_icon := IconBtn.new()
	vol_icon.kind = "speaker"
	vol_icon.custom_minimum_size = Vector2(56, 72)
	vol_icon.flat = true
	vol_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row1.add_child(vol_icon)
	var vol := UIKit.slider(0.0, 1.0, 0.05, 0.8, UIKit.ACCENT, 72)
	vol.custom_minimum_size = Vector2(170, 72)
	vol.size_flags_horizontal = Control.SIZE_SHRINK_END
	vol.value_changed.connect(func(v): volume_changed.emit(v))
	row1.add_child(vol)
	row1.add_child(_btn("Centrar", "recenter", Vector2(124, 72)))
	row1.add_child(_btn("Salir", "exit", Vector2(96, 72)))

	_seek = UIKit.slider(0.0, 1.0, 0.001, 0.0, UIKit.PROGRESS, 34)
	_seek.drag_started.connect(func(): _seeking = true)
	_seek.drag_ended.connect(func(_changed: bool):
		_seeking = false
		seek_to.emit(_seek.value))
	col.add_child(_seek)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 14)
	col.add_child(row3)
	var title := UIKit.label("SmartTube VR 3D · Playa", 26, Color(1, 1, 1, 0.8))
	row3.add_child(title)
	var chip := PanelContainer.new()
	var chip_box := UIKit.box(Color(1, 1, 1, 0.12), 16)
	chip_box.content_margin_left = 12
	chip_box.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", chip_box)
	_info = UIKit.label("", 22)
	chip.add_child(_info)
	row3.add_child(chip)
	var spacer3 := Control.new()
	spacer3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row3.add_child(spacer3)
	row3.add_child(_icon_btn("gear", "toggle_settings", Vector2(64, 48)))
	row3.add_child(_icon_btn("expand", "fullscreen", Vector2(64, 48)))


func _process(delta: float) -> void:
	if _undo_left > 0.0:
		_undo_left -= delta
		_undo.text = "Deshacer salto %d s" % ceili(maxf(_undo_left, 0.0))
		if _undo_left <= 0.0:
			_undo.visible = false


func _btn(t: String, act: String, min_size: Vector2) -> Button:
	var b := UIKit.text_button(t, 26, min_size)
	b.pressed.connect(func(): action.emit(act))
	return b


func _icon_btn(kind: String, act: String, min_size: Vector2, caption := "") -> IconBtn:
	var b := IconBtn.new()
	b.kind = kind
	b.caption = caption
	b.custom_minimum_size = min_size
	UIKit.style_button(b)
	b.pressed.connect(func(): action.emit(act))
	return b


## Muestra durante unos segundos el botón para volver al punto anterior al salto.
func show_undo() -> void:
	_undo_left = UNDO_SECONDS
	_undo.text = "Deshacer salto %d s" % int(UNDO_SECONDS)
	_undo.visible = true


func set_device(text: String) -> void:
	_device.text = text


func set_info(text: String) -> void:
	_info.text = text


func set_status(playing: bool, pos: float, length: float) -> void:
	if _play == null:
		return
	_play.set_kind("pause" if playing else "play")
	_time.text = "%s / %s" % [_fmt(pos), _fmt(length)]
	if not _seeking and length > 0.0:
		_seek.set_value_no_signal(clampf(pos / length, 0.0, 1.0))


func _fmt(s: float) -> String:
	var t := int(maxf(s, 0.0))
	return "%d:%02d" % [t / 60, t % 60]

extends Control

signal action(name: String)
signal volume_changed(value: float)
signal launch_app(package_name: String)
signal pin_app(package_name: String, label: String)
signal unpin_app(package_name: String)
var _time: Label
var _message: Label
var _play: Button
var _home: VBoxContainer
var _cinema: VBoxContainer
var _apps: VBoxContainer
var _favorites: GridContainer
var _favorite_page := 0
var _favorite_items: Array[Dictionary] = []
var _app_items: Array[Dictionary] = []
var _app_page := 0
var _app_rows: VBoxContainer
var _app_status: Label
var _organize := false
var _environment_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.08, 0.96)
	style.set_corner_radius_all(24)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	root.add_child(_label("NebulaVR", 44))
	_environment_label = _label("Tu espacio inmersivo � Playa", 24)
	root.add_child(_environment_label)
	_home = VBoxContainer.new()
	root.add_child(_home)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_home.add_child(grid)
	grid.add_child(_btn("Cine � video de prueba", "cinema"))
	grid.add_child(_btn("Navegador externo", "browser"))
	grid.add_child(_btn("Anadir app", "apps"))
	grid.add_child(_btn("Centrar panel", "recenter"))
	grid.add_child(_btn("Playa / bosque", "world"))
	grid.add_child(_btn("Cambiar asiento", "seat"))
	grid.add_child(_btn("SmartTube VR", "smarttube"))
	grid.add_child(_btn("Modo ECO", "quality"))
	grid.add_child(_btn("Salir", "exit"))
	_home.add_child(_label("Mis aplicaciones", 26))
	_favorites = GridContainer.new()
	_favorites.columns = 3
	_home.add_child(_favorites)
	var favorite_controls := HBoxContainer.new()
	_home.add_child(favorite_controls)
	favorite_controls.add_child(_btn("Anterior", "favorites_prev"))
	favorite_controls.add_child(_btn("Siguiente", "favorites_next"))
	favorite_controls.add_child(_btn("Quitar accesos", "organize"))
	_apps = VBoxContainer.new()
	_apps.visible = false
	root.add_child(_apps)
	_app_status = _label("Apps instaladas", 26)
	_app_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apps.add_child(_app_status)
	_app_rows = VBoxContainer.new()
	_apps.add_child(_app_rows)
	var app_controls := HBoxContainer.new()
	_apps.add_child(app_controls)
	app_controls.add_child(_btn("Anterior", "apps_prev"))
	app_controls.add_child(_btn("Siguiente", "apps_next"))
	app_controls.add_child(_btn("Inicio", "close_apps"))
	_cinema = VBoxContainer.new()
	_cinema.visible = false
	root.add_child(_cinema)
	_time = _label("0:00 / 0:00", 26)
	_cinema.add_child(_time)
	var transport := HBoxContainer.new()
	_cinema.add_child(transport)
	transport.add_child(_btn("-10 s", "seek_back"))
	_play = _btn("Pausa", "play_pause")
	transport.add_child(_play)
	transport.add_child(_btn("+10 s", "seek_fwd"))
	transport.add_child(_btn("Inicio", "home"))
	transport.add_child(_btn("Mundo", "world"))
	var settings := HBoxContainer.new()
	_cinema.add_child(settings)
	for item in [["Acercar", "closer"], ["Alejar", "farther"], ["Reducir", "smaller"], ["Ampliar", "bigger"]]:
		settings.add_child(_btn(item[0], item[1]))
	settings.add_child(_btn("Curva / plana", "curvature"))
	var volume := HSlider.new()
	volume.max_value = 1
	volume.step = 0.05
	volume.value = 0.25
	volume.custom_minimum_size.y = 48
	volume.value_changed.connect(func(v: float): volume_changed.emit(v))
	_cinema.add_child(_label("Volumen del video", 24))
	_cinema.add_child(volume)
	_message = _label("Gatillo: seleccionar � B: mostrar u ocultar panel", 23)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_message)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _btn(text: String, command: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 84)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 26)
	var accent := Color(0.36, 0.7, 1.0)
	if command == "cinema":
		accent = Color(0.52, 0.44, 1.0)
	elif command == "smarttube":
		accent = Color(1.0, 0.35, 0.4)
	elif command == "apps":
		accent = Color(0.25, 0.85, 0.7)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.09, 0.16, 0.98)
	normal.border_color = accent.darkened(0.5)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	button.add_theme_stylebox_override("normal", normal)
	var active := normal.duplicate() as StyleBoxFlat
	active.bg_color = accent.darkened(0.7)
	active.border_color = accent
	active.set_border_width_all(3)
	for state in ["hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, active)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	button.pressed.connect(func():
		match command:
			"favorites_prev":
				_favorite_page = maxi(0, _favorite_page - 1)
				_refresh_favorites()
			"favorites_next":
				_favorite_page = mini(maxi(0, (_favorite_items.size() - 1) / 3), _favorite_page + 1)
				_refresh_favorites()
			"organize":
				_organize = not _organize
				_refresh_favorites()
				show_message("Pulsa un acceso para quitarlo; vuelve a pulsar Quitar accesos para terminar." if _organize else "Pulsa una app para abrirla.")
			"apps_prev":
				_app_page = maxi(0, _app_page - 1)
				_refresh_apps()
			"apps_next":
				_app_page = mini(maxi(0, (_app_items.size() - 1) / 4), _app_page + 1)
				_refresh_apps()
			"close_apps":
				_apps.visible = false
				_home.visible = true
		if command == "cinema" or command == "home":
			_home.visible = command == "home"
			_cinema.visible = command == "cinema"
		action.emit(command))
	return button

func set_favorites(items: Array[Dictionary]) -> void:
	_favorite_items = items.duplicate(true)
	_favorite_page = mini(_favorite_page, maxi(0, (items.size() - 1) / 3))
	_refresh_favorites()

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh_favorites() -> void:
	_clear(_favorites)
	if _favorite_items.is_empty():
		_favorites.add_child(_label("Usa Anadir app para fijar tus apps.", 23))
	for index in range(_favorite_page * 3, mini(_favorite_items.size(), (_favorite_page + 1) * 3)):
		var item := _favorite_items[index]
		var button := _btn(("Quitar: " if _organize else "") + str(item.label), "favorite")
		button.pressed.connect(func():
			if _organize:
				unpin_app.emit(item.package)
			else:
				launch_app.emit(item.package))
		_favorites.add_child(button)

func show_apps(items: Array[Dictionary], message: String) -> void:
	_home.visible = false
	_cinema.visible = false
	_apps.visible = true
	_app_items = items
	_app_page = 0
	_app_status.text = message if not message.is_empty() else "Elige una app para fijarla en el inicio"
	_refresh_apps()

func _refresh_apps() -> void:
	_clear(_app_rows)
	for index in range(_app_page * 4, mini(_app_items.size(), (_app_page + 1) * 4)):
		var item := _app_items[index]
		var button := _btn("+ " + str(item.label), "pin")
		button.pressed.connect(func(): pin_app.emit(item.package, item.label))
		_app_rows.add_child(button)

func show_message(text: String) -> void:
	_message.text = text

func set_environment(title: String) -> void:
	_environment_label.text = "Tu espacio inmersivo � " + title

func show_cinema(enabled: bool) -> void:
	_home.visible = not enabled
	_cinema.visible = enabled
	_apps.visible = false

func set_status(playing: bool, pos: float, length: float) -> void:
	if not is_instance_valid(_play):
		return
	_play.text = "Pausa" if playing else "Reproducir"
	_time.text = "%s / %s" % [_fmt(pos), _fmt(length)]

func _fmt(seconds: float) -> String:
	var value := int(maxf(seconds, 0.0))
	return "%d:%02d" % [value / 60, value % 60]

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
var _panoramas: VBoxContainer
var _panorama_rows: VBoxContainer
var _panorama_items := PackedStringArray()
var _panorama_page := 0
var _panorama_status: Label
var _worlds: VBoxContainer
var _world_buttons: Array[Button] = []
var _world_page := 0
var _world_page_label: Label
const WORLDS_PER_PAGE := 6
const WORLD_TITLES := ["Playa", "Bosque de Hadas", "Observatorio Astral", "Invernadero Abisal", "Expreso Fantasma", "Biblioteca de Mercurio",
	"Playa al atardecer", "Playa de noche", "Sala de cine", "Salón", "Espacio", "Aurora boreal 360°", "Nebulosa 360°"]
const WORLD_SUBTITLES := ["Brisa y horizonte", "Luciérnagas y calma", "Un palco entre estrellas", "Jardín bajo las aguas", "El viaje sin destino", "Historias en suspensión",
	"Sol bajo y mar dorado", "Luna, estrellas y hoguera", "Butacas, telones y penumbra", "Sofá, libros y ventanal", "Planeta con anillos", "Lago helado bajo la aurora", "El espacio profundo"]
var _return_to_cinema := false
var _favorite_controls: HBoxContainer
var _world_title: Label
var _environment_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/nebula.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var logo := TextureRect.new()
	logo.texture = load("res://icon.svg")
	logo.custom_minimum_size = Vector2(58, 58)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(logo)
	header.add_child(_label("NebulaVR", 42))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_btn("Cerrar", "exit"))
	_environment_label = _label("TU RINCÓN DEL UNIVERSO  /  Playa", 24)
	root.add_child(_environment_label)
	_home = VBoxContainer.new()
	root.add_child(_home)
	_home.add_child(_label("Desconecta. Estás en tu universo.", 34))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	_home.add_child(cards)
	var hero := _feature_card("cinema", "La mejor butaca es la tuya", "ENTRAR AL CINE   /   Vídeo de demostración", "cinema")
	hero.size_flags_stretch_ratio = 1.65
	cards.add_child(hero)
	var worlds_card := _feature_card("worlds", "Un lugar para perderte", "%d lugares para desconectar" % WORLD_TITLES.size(), "worlds")
	cards.add_child(worlds_card)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	_home.add_child(grid)
	for item in [["SmartTube VR ↗", "smarttube"], ["Navegador ↗", "browser"], ["Añadir aplicaciones", "apps"], ["Cambiar asiento", "seat"], ["Centrar panel", "recenter"], ["Modo ECO", "quality"]]:
		grid.add_child(_btn(item[0], item[1]))
	_home.add_child(_label("Mis aplicaciones", 26))
	_favorites = GridContainer.new()
	_favorites.columns = 3
	_home.add_child(_favorites)
	var favorite_controls := HBoxContainer.new()
	_favorite_controls = favorite_controls
	favorite_controls.hide()
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
	var transport := GridContainer.new()
	transport.columns = 3
	_cinema.add_child(transport)
	transport.add_child(_btn("-10 s", "seek_back"))
	_play = _btn("Pausa", "play_pause")
	transport.add_child(_play)
	transport.add_child(_btn("+10 s", "seek_fwd"))
	transport.add_child(_btn("Inicio", "home"))
	transport.add_child(_btn("Entornos", "worlds"))
	var settings := GridContainer.new()
	settings.columns = 3
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
	_worlds = VBoxContainer.new()
	_worlds.visible = false
	root.add_child(_worlds)
	_worlds.add_child(_label("Elige tu entorno", 30))
	var worlds_grid := GridContainer.new()
	worlds_grid.columns = 3
	worlds_grid.add_theme_constant_override("h_separation", 16)
	worlds_grid.add_theme_constant_override("v_separation", 12)
	_worlds.add_child(worlds_grid)
	for index in WORLD_TITLES.size():
		var button := _feature_card("world_" + str(index), WORLD_TITLES[index], WORLD_SUBTITLES[index], "world_select:" + str(index))
		button.custom_minimum_size.y = 220
		_world_buttons.append(button)
		worlds_grid.add_child(button)
	var world_pages := HBoxContainer.new()
	_worlds.add_child(world_pages)
	world_pages.add_child(_btn("Anterior", "worlds_prev"))
	_world_page_label = _label("", 24)
	_world_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_pages.add_child(_world_page_label)
	world_pages.add_child(_btn("Siguiente", "worlds_next"))
	_refresh_world_page()
	var world_controls := HBoxContainer.new()
	_worlds.add_child(world_controls)
	world_controls.add_child(_btn("Volver", "close_worlds"))
	world_controls.add_child(_btn("Moon ↗", "moon_catalog"))
	world_controls.add_child(_btn("Mis panoramas", "panoramas"))
	_panoramas = VBoxContainer.new()
	_panoramas.hide()
	root.add_child(_panoramas)
	_panoramas.add_child(_label("Tus panoramas 360°", 30))
	var help := _label("PNG / JPEG 2:1 · hasta 4096 × 2048 y 16 MiB.\nImporta imágenes propias o con permiso desde tus archivos.", 23)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panoramas.add_child(help)
	_panorama_status = _label("", 23)
	_panoramas.add_child(_panorama_status)
	_panorama_rows = VBoxContainer.new()
	_panoramas.add_child(_panorama_rows)
	var pages := HBoxContainer.new()
	_panoramas.add_child(pages)
	pages.add_child(_btn("Anterior", "panoramas_prev"))
	pages.add_child(_btn("Siguiente", "panoramas_next"))
	pages.add_child(_btn("Actualizar", "panoramas_scan"))
	var import_controls := HBoxContainer.new()
	_panoramas.add_child(import_controls)
	import_controls.add_child(_btn("Volver a entornos", "close_panoramas"))
	import_controls.add_child(_btn("Importar imagen", "panorama_import"))
	_message = _label("Gatillo / A: elegir   ·   B: panel   ·   Joystick: navegar", 23)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_message)

func _feature_card(art: String, title: String, subtitle: String, command: String) -> Button:
	var button := _btn("", command)
	button.custom_minimum_size = Vector2(0, 238)
	button.tooltip_text = subtitle
	button.accessibility_name = title
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_top = 12
	content.offset_right = -12
	content.offset_bottom = -12
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var picture := TextureRect.new()
	picture.texture = load("res://assets/ui/" + art + ".svg")
	picture.custom_minimum_size.y = 128
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	var heading := _label(title, 25)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(heading)
	var caption := _label(subtitle, 19)
	caption.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(caption)
	return button

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _btn(text: String, command: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	var accent := Color(0.36, 0.7, 1.0)
	if command == "cinema":
		accent = Color(0.52, 0.44, 1.0)
	elif command == "smarttube":
		accent = Color(1.0, 0.35, 0.4)
	elif command == "apps":
		accent = Color(0.25, 0.85, 0.7)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.11, 0.13, 0.23, 0.94)
	normal.border_color = accent.darkened(0.5)
	normal.set_border_width_all(0)
	normal.shadow_color = Color(0, 0, 0, 0.22)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 4)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	button.add_theme_stylebox_override("normal", normal)
	var active := normal.duplicate() as StyleBoxFlat
	active.bg_color = accent.darkened(0.6)
	active.border_color = accent
	active.set_border_width_all(3)
	for state in ["hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, active)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	button.pressed.connect(func():
		match command:
			"close_panoramas":
				_panoramas.hide()
				_worlds.show()
			"panoramas_prev":
				_panorama_page = maxi(0, _panorama_page - 1)
				_refresh_panoramas()
			"panoramas_next":
				_panorama_page = mini(maxi(0, (_panorama_items.size() - 1) / 4), _panorama_page + 1)
				_refresh_panoramas()
			"worlds":
				_return_to_cinema = _cinema.visible
				_home.hide()
				_cinema.hide()
				_apps.hide()
				_worlds.show()
				_world_buttons[_world_page * WORLDS_PER_PAGE].grab_focus()
			"worlds_prev", "worlds_next":
				var last_page := (WORLD_TITLES.size() - 1) / WORLDS_PER_PAGE
				_world_page = clampi(_world_page + (1 if command == "worlds_next" else -1), 0, last_page)
				_refresh_world_page()
				_world_buttons[_world_page * WORLDS_PER_PAGE].grab_focus()
			"close_worlds":
				_worlds.hide()
				_cinema.visible = _return_to_cinema
				_home.visible = not _return_to_cinema
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
			_worlds.hide()
			_home.visible = command == "home"
			_cinema.visible = command == "cinema"
		action.emit(command))
	return button

func _refresh_world_page() -> void:
	for index in _world_buttons.size():
		_world_buttons[index].visible = index / WORLDS_PER_PAGE == _world_page
	_world_page_label.text = "Página %d de %d" % [_world_page + 1, (WORLD_TITLES.size() - 1) / WORLDS_PER_PAGE + 1]

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
	_favorite_controls.visible = not _favorite_items.is_empty()
	if _favorite_items.is_empty():
		var add := _btn("+  Tu espacio, tus aplicaciones. Añade la primera", "apps")
		_favorites.add_child(add)
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
	_environment_label.text = "TU RINCÓN DEL UNIVERSO  /  " + title

func show_cinema(enabled: bool) -> void:
	_panoramas.hide()
	_worlds.hide()
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

func show_panoramas(items: PackedStringArray) -> void:
	_home.hide()
	_cinema.hide()
	_apps.hide()
	_worlds.hide()
	_panoramas.show()
	_panorama_items = items
	_panorama_page = 0
	_refresh_panoramas()

func _refresh_panoramas() -> void:
	_clear(_panorama_rows)
	_panorama_status.text = "%d panoramas · Página %d" % [_panorama_items.size(), _panorama_page + 1] if not _panorama_items.is_empty() else "Aún no hay panoramas. Pulsa Importar imagen."
	for index in range(_panorama_page * 4, mini(_panorama_items.size(), (_panorama_page + 1) * 4)):
		var button := _btn(_panorama_items[index].get_basename().left(45), "panorama_select:" + str(index))
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_panorama_rows.add_child(button)

## Escena principal: playa inmersiva + pantalla de cine + control con mandos.
extends Node3D

const XRT := "res://addons/godot-xr-tools/"

var xr_interface: XRInterface
var origin: XROrigin3D
var camera: XRCamera3D
var screen: CinemaScreen
var panel: Node3D
var ui: Control
var screen_distance := 10.0
var beach_world: Node3D
var forest_world: Node3D
var forest_active := false
var active_world_id := 0
const WORLD_NAMES := ["Playa", "Bosque de Hadas", "Observatorio Astral", "Invernadero Abisal", "Expreso Fantasma", "Biblioteca de Mercurio"]
var spawn_index := 1
var installed_apps := InstalledApps.new()
var panorama_picker: FileDialog
var panorama_library := PanoramaLibrary.new()
var eco_mode := false
var curved_screen := true
var right_controller: XRController3D
var turn_provider: Node
var navigation_delay := 0.0

func _ready() -> void:
	_init_xr()
	var sun := WorldBuilder.build_environment(self)
	var sand := WorldBuilder.build_sand(self)
	WorldBuilder.build_ocean(self)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var noise: FastNoiseLite = sand.get_meta("noise")
	var palm_spots := [Vector3(-7, 0, 3), Vector3(-9.5, 0, 7), Vector3(8, 0, 2), Vector3(11, 0, 6),
		Vector3(-15, 0, 12), Vector3(16, 0, 11), Vector3(-4, 0, 14), Vector3(5, 0, 16), Vector3(-22, 0, 5), Vector3(24, 0, 4)]
	for p in palm_spots:
		p.y = WorldBuilder.sand_height(p.x, p.z, noise) - 0.1
		WorldBuilder.build_palm(self, p, rng)
	WorldBuilder.build_rocks(self, rng, noise)
	_build_audio()
	beach_world = Node3D.new()
	beach_world.name = "Playa"
	var world_children := get_children()
	add_child(beach_world)
	for child in world_children:
		child.reparent(beach_world)
	_build_rig()
	_build_screen()
	_build_panel()
	add_child(panorama_library)
	panorama_library.loaded.connect(_apply_panorama)
	panorama_library.failed.connect(func(message: String): ui.show_message(message))
	installed_apps.load_favorites()
	ui.set_favorites(installed_apps.favorites)
	screen.visible = false
	screen.player.paused = true
	if "--preview-forest" in OS.get_cmdline_user_args():
		_switch_world()
	sun.shadow_enabled = true


func _init_xr() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Quest: refresco alto si el visor lo permite (90 Hz), si no 72 Hz
		if xr_interface.has_method("get_available_display_refresh_rates"):
			var rates: Array = xr_interface.get_available_display_refresh_rates()
			for preferred in [120.0, 90.0, 80.0, 72.0]:
				if rates.has(preferred):
					xr_interface.display_refresh_rate = preferred
					break
		Engine.physics_ticks_per_second = int(maxf(xr_interface.display_refresh_rate, 72.0))
		# Foveaci�n fija (tambi�n configurada en project.godot)
		if "foveation_level" in xr_interface:
			xr_interface.foveation_level = 3
			xr_interface.foveation_dynamic = true
	else:
		print("OpenXR no disponible: modo escritorio para pruebas")


func _build_rig() -> void:
	origin = XROrigin3D.new()
	origin.name = "XROrigin3D"
	add_child(origin)
	camera = XRCamera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 1.7, 0)
	camera.far = 400.0
	origin.add_child(camera)
	var body: Node = load(XRT + "player/player_body.tscn").instantiate()
	origin.add_child(body)

	for hand in ["left_hand", "right_hand"]:
		var c := XRController3D.new()
		c.name = "Mando_" + hand
		c.tracker = hand
		origin.add_child(c)
		c.pose = "aim"
		var side := "left" if hand == "left_hand" else "right"
		var hand_model: Node3D = load(XRT + "hands/scenes/lowpoly/" + side + "_hand_low.tscn").instantiate()
		c.add_child(hand_model)
		# rayo l�ser
		var pointer: Node3D = load(XRT + "functions/function_pointer.tscn").instantiate()
		pointer.set("show_target", true)
		c.add_child(pointer)
		if hand == "right_hand":
			right_controller = c
			var turn: Node = load(XRT + "functions/movement_turn.tscn").instantiate()
			turn.set("turn_mode", 1) # SNAP
			turn.set("step_turn_angle", 30.0)
			c.add_child(turn)
			turn_provider = turn
			c.button_pressed.connect(_on_right_button)
		else:
			var tp: Node = load(XRT + "functions/function_teleport.tscn").instantiate()
			tp.set("teleport_button_action", "grip_click")
			tp.set("valid_teleport_mask", 1)
			c.add_child(tp)
			c.button_pressed.connect(_on_left_button)


func _build_audio() -> void:
	var ocean := AudioStreamPlayer3D.new()
	ocean.stream = _loop_wav("res://audio/ocean_waves.wav")
	ocean.position = Vector3(0, 0.5, WorldBuilder.SHORE_Z - 2)
	ocean.unit_size = 25.0
	ocean.volume_db = -24.0
	ocean.autoplay = true
	add_child(ocean)
	var ocean2 := ocean.duplicate()
	ocean2.position = Vector3(-25, 0.5, WorldBuilder.SHORE_Z - 2)
	add_child(ocean2)
	var ocean3 := ocean.duplicate()
	ocean3.position = Vector3(25, 0.5, WorldBuilder.SHORE_Z - 2)
	add_child(ocean3)
	var wind := AudioStreamPlayer.new()
	wind.stream = _loop_wav("res://audio/wind.wav")
	wind.volume_db = -16.0
	wind.autoplay = true
	add_child(wind)


func _loop_wav(path: String) -> AudioStream:
	var s: AudioStream = load(path)
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	return s


func _build_screen() -> void:
	screen = CinemaScreen.new()
	screen.name = "PantallaCine"
	add_child(screen)
	_place_screen()


func _place_screen() -> void:
	var yaw := 0.0
	var head := Vector3(0, 1.7, 0)
	if camera:
		head = camera.global_position
		yaw = camera.global_rotation.y
	var basis := Basis(Vector3.UP, yaw)
	screen.global_transform = Transform3D(basis, head + basis * Vector3(0, 0.6, -screen_distance))
	screen.radius = screen_distance if curved_screen else 1000.0
	screen._rebuild()
	if panel:
		panel.global_transform = Transform3D(basis * Basis(Vector3.RIGHT, deg_to_rad(-10)), head + basis * Vector3(0, -0.12, -1.8))


func _build_panel() -> void:
	panel = load(XRT + "objects/viewport_2d_in_3d.tscn").instantiate()
	panel.name = "PanelControl"
	add_child(panel)
	panel.set("screen_size", Vector2(1.65, 1.24))
	panel.set("viewport_size", Vector2(1200, 900))
	panel.set("scene", load("res://scenes/ui_panel.tscn"))
	panel.set("unshaded", true)
	ui = panel.get_scene_instance()
	if ui:
		ui.action.connect(_on_action)
		ui.volume_changed.connect(func(v): screen.set_volume(v))
		ui.launch_app.connect(_launch_app)
		ui.pin_app.connect(_pin_app)
		ui.unpin_app.connect(_unpin_app)
	_place_screen()


func _on_action(act: String) -> void:
	if act.begins_with("world_select:"):
		_select_world(act.get_slice(":", 1).to_int())
		return
	if act.begins_with("panorama_select:"):
		if panorama_library.request(act.get_slice(":", 1).to_int()):
			ui.show_message("Cargando panorama…")
		else:
			ui.show_message("Espera a que termine la carga y vuelve a intentarlo.")
		return
	match act:
		"panorama_import":
			_open_panorama_picker()
		"moon_catalog":
			var error := OS.shell_open("https://moonvrhome.com/es/environments")
			ui.show_message("Moon se abre en el navegador externo." if error == OK else "No se pudo abrir Moon.")
		"panoramas", "panoramas_scan":
			ui.show_panoramas(panorama_library.scan())
		"cinema":
			ui.show_cinema(true)
			screen.visible = true
			screen.player.paused = false
		"home":
			ui.show_cinema(false)
			screen.visible = false
			screen.player.paused = true
		"browser":
			var err := OS.shell_open("https://www.youtube.com/")
			ui.show_message("Navegador externo solicitado" if err == OK else "No se pudo abrir el navegador")
		"apps":
			var items := installed_apps.list_apps()
			ui.show_apps(items, installed_apps.error_message)
		"smarttube": _launch_app(InstalledApps.SMARTTUBE)
		"quality":
			eco_mode = not eco_mode
			get_viewport().scaling_3d_scale = 0.75 if eco_mode else 1.0
			ui.show_message("Modo ECO: resolucion 3D al 75 %" if eco_mode else "Calidad normal")
		"curvature":
			curved_screen = not curved_screen
			_place_screen()
			ui.show_message("Pantalla curva" if curved_screen else "Pantalla plana")
		"world": _switch_world()
		"seat":
			spawn_index = (spawn_index + 1) % 3
			screen_distance = [6.0, 10.0, 16.0][spawn_index]
			_place_screen()
			ui.show_message(["Asiento cercano", "Asiento central", "Asiento panoramico"][spawn_index])
		"play_pause": screen.toggle_play()
		"seek_back": screen.seek(-10.0)
		"seek_fwd": screen.seek(10.0)
		"closer":
			screen_distance = clampf(screen_distance - 1.5, 4.0, 25.0); _place_screen()
		"farther":
			screen_distance = clampf(screen_distance + 1.5, 4.0, 25.0); _place_screen()
		"smaller": screen.width -= 1.0
		"bigger": screen.width += 1.0
		"recenter": _recenter()
		"exit": get_tree().quit()

func _launch_app(package_name: String) -> void:
	if installed_apps.launch(package_name):
		screen.player.paused = true
		ui.show_message("App externa solicitada. Vuelve a NebulaVR desde la biblioteca del visor.")
	else:
		ui.show_message(installed_apps.error_message)

func _pin_app(package_name: String, label: String) -> void:
	var added := installed_apps.pin_app(package_name, label)
	ui.set_favorites(installed_apps.favorites)
	ui.show_message("Acceso guardado: " + label if added else "No se pudo guardar: puede existir ya o haberse alcanzado el limite.")

func _unpin_app(package_name: String) -> void:
	installed_apps.unpin_app(package_name)
	ui.set_favorites(installed_apps.favorites)


func _recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	_place_screen.call_deferred()

func _switch_world() -> void:
	_select_world((active_world_id + 1) % WORLD_NAMES.size())

func _select_world(id: int) -> void:
	panorama_library.cancel()
	if id < 0 or id >= WORLD_NAMES.size() or id == active_world_id:
		return
	if active_world_id == 0:
		_stop_world_audio(beach_world)
		remove_child(beach_world)
	elif is_instance_valid(forest_world):
		remove_child(forest_world)
		forest_world.free()
		forest_world = null
	if id == 0:
		add_child(beach_world)
	elif id == 1:
		forest_world = RetroWorld.new()
		add_child(forest_world)
	else:
		var world := LivingWorld.new()
		world.world_id = id
		forest_world = world
		add_child(world)
	active_world_id = id
	forest_active = id != 0
	ui.set_environment(WORLD_NAMES[id])
	ui.show_message(WORLD_NAMES[id])

func _open_panorama_picker() -> void:
	if OS.has_feature("android") and not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		ui.show_message("El sistema no ofrece selector de archivos. Usa la carpeta panoramas.")
		return
	if not is_instance_valid(panorama_picker):
		panorama_picker = FileDialog.new()
		panorama_picker.access = FileDialog.ACCESS_FILESYSTEM
		panorama_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		panorama_picker.use_native_dialog = true
		panorama_picker.title = "Importar panorama 360°"
		panorama_picker.add_filter("*.png,*.jpg,*.jpeg", "Panorama 2:1", "image/png,image/jpeg")
		ui.add_child(panorama_picker)
		panorama_picker.file_selected.connect(func(path: String):
			if panorama_library.request_import(path):
				ui.show_message("Importando panorama…")
			else:
				ui.show_message("Espera a que termine la carga o libera espacio en la biblioteca (máximo 128)."))
	panorama_picker.popup_centered(Vector2i(1000, 650))

func _apply_panorama(image: Image, title: String) -> void:
	# Validate/decode first; keep the current world on failure and keep the player.
	var world := PanoramaLibrary.build_world(image)
	if active_world_id == 0:
		_stop_world_audio(beach_world)
		remove_child(beach_world)
	elif is_instance_valid(forest_world):
		remove_child(forest_world)
		forest_world.free()
	forest_world = world
	add_child(world)
	active_world_id = -1
	forest_active = true
	if ui._panoramas.visible:
		ui.show_panoramas(panorama_library.scan())
	ui.set_environment(title + " · Panorama 360°")
	ui.show_message("Panorama aplicado. El vídeo conserva su reproducción.")

func _exit_tree() -> void:
	if is_instance_valid(beach_world):
		_stop_world_audio(beach_world, true)
	if is_instance_valid(beach_world) and not beach_world.is_inside_tree():
		beach_world.free()

func _stop_world_audio(world: Node, release_streams := false) -> void:
	for child in world.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			child.stop()
			if release_streams:
				child.stream = null


func _set_panel_visible(value: bool) -> void:
	panel.visible = value
	panel.set("enabled", value)
	if turn_provider:
		turn_provider.set("enabled", not value)
	if value:
		_place_screen()
		_focus_first_button(ui)

func _focus_first_button(node: Node) -> bool:
	if node is Button and node.is_visible_in_tree() and not node.disabled:
		node.grab_focus()
		return true
	for child in node.get_children():
		if _focus_first_button(child):
			return true
	return false

func _on_left_button(button: String) -> void:
	if button == "menu_button":
		_on_action("home")
		_set_panel_visible(true)

func _on_right_button(button: String) -> void:
	match button:
		"by_button": _set_panel_visible(not panel.visible)
		"ax_button":
			if panel.visible:
				_send_ui_action("ui_accept")
			else:
				_on_action("play_pause")
		"primary_click": _recenter()

func _send_ui_action(action_name: String) -> void:
	var viewport := panel.get_node("Viewport") as SubViewport
	var focus := viewport.gui_get_focus_owner()
	if not is_instance_valid(focus) or not focus.is_visible_in_tree():
		_focus_first_button(ui)
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action_name
		event.pressed = pressed
		viewport.push_input(event)

func _process(delta: float) -> void:
	if turn_provider:
		turn_provider.set("enabled", not panel.visible)
	navigation_delay = maxf(0.0, navigation_delay - delta)
	if panel and panel.visible and right_controller and right_controller.get_is_active():
		var stick := right_controller.get_vector2("primary")
		if stick.length() < 0.35:
			navigation_delay = 0.0
		elif navigation_delay == 0.0 and stick.length() > 0.65:
			if absf(stick.x) > absf(stick.y):
				_send_ui_action("ui_right" if stick.x > 0 else "ui_left")
			else:
				_send_ui_action("ui_up" if stick.y > 0 else "ui_down")
			navigation_delay = 0.28
	if ui and screen and Engine.get_process_frames() % 10 == 0:
		ui.set_status(screen.is_playing_now(), screen.player.stream_position, screen.player.get_stream_length())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(screen) and is_instance_valid(screen.player):
		screen.player.paused = true

func _unhandled_key_input(event: InputEvent) -> void:
	if get_viewport().use_xr or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _on_action("cinema")
		KEY_2: _on_action("world")
		KEY_3: _on_action("home")
		KEY_SPACE: _on_action("play_pause")
		KEY_LEFT: _on_action("seek_back")
		KEY_RIGHT: _on_action("seek_fwd")
		KEY_F: _on_action("curvature")
		KEY_R: _place_screen()

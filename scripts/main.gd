## Escena principal: mundo inmersivo (cambiable) + pantalla de cine + control con mandos.
extends Node3D

const XRT := "res://addons/godot-xr-tools/"
const SETTINGS_PATH := "user://ajustes.cfg"

var xr_interface: XRInterface
var origin: XROrigin3D
var camera: XRCamera3D
var player_body: Node
var screen: CinemaScreen
var panel: Node3D
var ui: Control
var screen_distance := 10.0
var worlds: Array = []
var world_index := 0
var _world: Node3D

func _ready() -> void:
	_init_xr()
	_build_rig()
	_build_screen()
	_build_panel()
	worlds = Worlds.catalog()
	_load_world(_saved_world_index())


## Borra el mundo actual y construye el de la posición `index` del catálogo.
func _load_world(index: int) -> void:
	world_index = wrapi(index, 0, worlds.size())
	var entry: Dictionary = worlds[world_index]
	if _world:
		_world.queue_free()
	_world = Node3D.new()
	_world.name = "Mundo"
	add_child(_world)
	var info := Worlds.build(entry.id, _world)
	# Volver al punto de partida del nuevo mundo (el anterior puede tener otra forma)
	if player_body and player_body.has_method("teleport"):
		player_body.teleport(Transform3D(Basis(), info.spawn))
		player_body.set("velocity", Vector3.ZERO)
	elif origin:
		origin.global_position = info.spawn
	screen_distance = info.screen_distance
	screen.width = info.screen_width
	_place_screen.call_deferred()
	if ui:
		ui.set_world_name(entry.name)
	_save_world(entry.id)


func _saved_world_index() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var id: String = cfg.get_value("mundo", "id", "")
		for i in worlds.size():
			if worlds[i].id == id:
				return i
	return 0


func _save_world(id: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("mundo", "id", id)
	cfg.save(SETTINGS_PATH)


func _init_xr() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Quest: refresco alto si el visor lo permite (90 Hz), si no 72 Hz
		if xr_interface.has_method("get_available_display_refresh_rates"):
			var rates: Array = xr_interface.get_available_display_refresh_rates()
			if rates.has(90.0):
				xr_interface.display_refresh_rate = 90.0
		Engine.physics_ticks_per_second = int(maxf(xr_interface.display_refresh_rate, 72.0))
		# Foveación fija (también configurada en project.godot)
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
	camera.far = 1000.0
	origin.add_child(camera)
	player_body = load(XRT + "player/player_body.tscn").instantiate()
	origin.add_child(player_body)

	for hand in ["left_hand", "right_hand"]:
		var c := XRController3D.new()
		c.name = "Mando_" + hand
		c.tracker = hand
		origin.add_child(c)
		# modelo sencillo del mando
		var m := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.025; cap.height = 0.14
		m.mesh = cap
		m.rotation_degrees.x = 90
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.15, 0.15, 0.18)
		m.material_override = mm
		c.add_child(m)
		# rayo láser
		var pointer: Node3D = load(XRT + "functions/function_pointer.tscn").instantiate()
		pointer.set("show_target", true)
		c.add_child(pointer)
		if hand == "right_hand":
			var turn: Node = load(XRT + "functions/movement_turn.tscn").instantiate()
			turn.set("turn_mode", 1) # SNAP
			turn.set("step_turn_angle", 30.0)
			c.add_child(turn)
			c.button_pressed.connect(_on_right_button)
		else:
			var tp: Node = load(XRT + "functions/function_teleport.tscn").instantiate()
			tp.set("teleport_button_action", "grip_click")
			tp.set("valid_teleport_mask", 1)
			c.add_child(tp)


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
	screen.radius = screen_distance
	screen._rebuild()
	if panel:
		panel.global_transform = Transform3D(basis * Basis(Vector3.RIGHT, deg_to_rad(-25)), head + basis * Vector3(0, -0.55, -1.3))


func _build_panel() -> void:
	panel = load(XRT + "objects/viewport_2d_in_3d.tscn").instantiate()
	panel.name = "PanelControl"
	add_child(panel)
	panel.set("screen_size", Vector2(1.0, 0.5))
	panel.set("viewport_size", Vector2(900, 450))
	panel.set("scene", load("res://scenes/ui_panel.tscn"))
	panel.set("unshaded", true)
	ui = panel.get_scene_instance()
	if ui:
		ui.action.connect(_on_action)
		ui.volume_changed.connect(func(v): screen.set_volume(v))
	_place_screen()


func _on_action(act: String) -> void:
	match act:
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
		"world_prev": _load_world(world_index - 1)
		"world_next": _load_world(world_index + 1)
		"exit": get_tree().quit()


func _recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	_place_screen.call_deferred()


func _on_right_button(name: String) -> void:
	# B: mostrar/ocultar el panel delante de ti
	if name == "by_button" and panel:
		panel.visible = not panel.visible
		panel.set("enabled", panel.visible)
		if panel.visible:
			_place_screen()


func _process(_d: float) -> void:
	if ui and screen and Engine.get_process_frames() % 10 == 0:
		ui.set_status(screen.is_playing_now(), screen.player.stream_position, screen.player.get_stream_length())

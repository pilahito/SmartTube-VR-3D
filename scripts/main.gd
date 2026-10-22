## Escena principal: playa inmersiva + pantalla de cine + control con mandos.
extends Node3D

const XRT := "res://addons/godot-xr-tools/"

var xr_interface: XRInterface
var origin: XROrigin3D
var camera: XRCamera3D
var screen: CinemaScreen
var panel: Node3D
var ui: Control
var settings_panel: Node3D
var settings_ui: Control

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
	_build_rig()
	_build_screen()
	_build_panel()
	sun.shadow_enabled = true


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
	camera.far = 400.0
	origin.add_child(camera)
	var body: Node = load(XRT + "player/player_body.tscn").instantiate()
	origin.add_child(body)

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


func _build_audio() -> void:
	var ocean := AudioStreamPlayer3D.new()
	ocean.stream = _loop_wav("res://audio/ocean_waves.wav")
	ocean.position = Vector3(0, 0.5, WorldBuilder.SHORE_Z - 2)
	ocean.unit_size = 25.0
	ocean.volume_db = -2.0
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
	screen.place(head, yaw)
	if panel:
		panel.global_transform = Transform3D(basis * Basis(Vector3.RIGHT, deg_to_rad(-25)), head + basis * Vector3(0, -0.55, -1.3))
	if settings_panel:
		var p := head + basis * Vector3(0.85, -0.1, -1.1)
		settings_panel.global_transform = Transform3D(Basis.looking_at(p - head, Vector3.UP), p)


func _make_panel(node_name: String, scene_path: String, viewport_px: Vector2, metres_per_px: float) -> Node3D:
	var p: Node3D = load(XRT + "objects/viewport_2d_in_3d.tscn").instantiate()
	p.name = node_name
	add_child(p)
	p.set("screen_size", viewport_px * metres_per_px)
	p.set("viewport_size", viewport_px)
	p.set("scene", load(scene_path))
	p.set("unshaded", true)
	return p


func _build_panel() -> void:
	panel = _make_panel("PanelControl", "res://scenes/ui_panel.tscn", Vector2(1280, 290), 0.0009)
	ui = panel.get_scene_instance()
	if ui:
		ui.action.connect(_on_action)
		ui.volume_changed.connect(func(v): screen.set_volume(v))
		ui.seek_to.connect(func(r):
			screen.seek_ratio(r)
			ui.show_undo())
		ui.set_device(_device_text())
		ui.set_info(screen.video_info())

	settings_panel = _make_panel("PanelPantalla", "res://scenes/settings_panel.tscn", Vector2(480, 800), 0.0009)
	settings_ui = settings_panel.get_scene_instance()
	if settings_ui:
		settings_ui.setting.connect(_on_setting)
		settings_ui.sync_from(screen)
	_set_settings_visible(false)
	_place_screen()


func _device_text() -> String:
	var model := OS.get_model_name()
	if model == "" or model == "GenericDevice":
		model = "Escritorio"
	var hz := ""
	if xr_interface and xr_interface.is_initialized():
		hz = " · %d Hz" % int(xr_interface.display_refresh_rate)
	return model + hz


func _set_settings_visible(on: bool) -> void:
	settings_panel.visible = on
	settings_panel.set("enabled", on)


func _on_setting(key: String, value: Variant) -> void:
	match key:
		"close":
			_set_settings_visible(false)
			return
		"preset": screen.apply_preset(value)
		"projection_next": screen.projection = {0: 180, 180: 360, 360: 0}[screen.projection]
		_: screen.set(key, value)
	screen.rebuild()
	_place_screen()
	if key in ["preset", "projection_next"]:
		settings_ui.sync_from(screen)


func _on_action(act: String) -> void:
	match act:
		"play_pause": screen.toggle_play()
		"seek_back":
			screen.seek(-10.0); ui.show_undo()
		"seek_fwd":
			screen.seek(10.0); ui.show_undo()
		"undo_seek": screen.undo_seek()
		"toggle_settings": _set_settings_visible(not settings_panel.visible)
		"fullscreen":
			screen.toggle_fullscreen()
			screen.rebuild()
			_place_screen()
			settings_ui.sync_from(screen)
		"recenter": _recenter()
		"exit": get_tree().quit()


func _recenter() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	_place_screen.call_deferred()


func _on_right_button(name: String) -> void:
	# B: mostrar/ocultar el panel delante de ti
	if name == "by_button" and panel:
		panel.visible = not panel.visible
		panel.set("enabled", panel.visible)
		if not panel.visible:
			_set_settings_visible(false)
		else:
			_place_screen()


func _process(_d: float) -> void:
	if ui and screen and Engine.get_process_frames() % 10 == 0:
		ui.set_status(screen.is_playing_now(), screen.player.stream_position, screen.player.get_stream_length())
		ui.set_info(screen.video_info())

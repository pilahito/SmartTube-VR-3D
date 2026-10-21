extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.ui != null, "Launcher no creado")
	assert(not scene.screen.visible, "El inicio debe ser el launcher")
	var original_player = scene.screen.player
	scene._set_panel_visible(true)
	assert(not scene.turn_provider.enabled, "El joystick no debe girar el mundo al navegar")
	var viewport = scene.panel.get_node("Viewport")
	assert(viewport.gui_get_focus_owner() is Button, "Falta foco para el mando")
	scene._on_right_button("by_button")
	assert(not scene.panel.visible and scene.turn_provider.enabled)
	scene._on_right_button("ax_button")
	assert(not original_player.paused)
	scene._on_right_button("ax_button")
	assert(original_player.paused)
	scene._on_left_button("menu_button")
	assert(scene.panel.visible and not scene.turn_provider.enabled)
	scene.screen.set_volume(0.0)
	assert(is_zero_approx(original_player.volume), "Silencio debe ser volumen cero")
	scene.screen.set_volume(0.25)
	scene._on_action("cinema")
	assert(scene.screen.visible)
	scene._on_action("world")
	await process_frame
	assert(scene.forest_active)
	assert(scene.screen.player == original_player, "Cambiar mundo recreo el reproductor")
	scene._select_world(0)
	await process_frame
	assert(not scene.forest_active)
	assert(scene.screen.player == original_player)
	for id in range(6):
		scene._select_world(id)
		await process_frame
		assert(scene.active_world_id == id)
		assert(scene.screen.player == original_player)
	for index in range(3):
		scene._on_action("seat")
		assert(scene.screen_distance >= 6 and scene.screen_distance <= 16)
	scene._on_action("home")
	assert(scene.screen.player.paused)
	scene.queue_free()
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	print("NEBULAVR_SMOKE_OK: inicio, cine, mundos, reproductor persistente, asientos")
	quit(0)

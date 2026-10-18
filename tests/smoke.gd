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
	scene._on_action("cinema")
	assert(scene.screen.visible)
	scene._on_action("world")
	await process_frame
	assert(scene.forest_active)
	assert(scene.screen.player == original_player, "Cambiar mundo recreo el reproductor")
	scene._on_action("world")
	await process_frame
	assert(not scene.forest_active)
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

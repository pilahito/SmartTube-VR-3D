extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var library := PanoramaLibrary.new()
	root.add_child(library)
	DirAccess.make_dir_recursive_absolute(PanoramaLibrary.DIRECTORY)
	var path := PanoramaLibrary.DIRECTORY.path_join("__nebula_test.png")
	var image := Image.create(128, 64, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 0.5, 0.8))
	assert(image.save_png(path) == OK)
	var decoded := PanoramaLibrary._decode(path)
	assert(decoded.has("image"))
	# A tiny PNG header declaring enormous dimensions must fail before decompression.
	var bomb := image.save_png_to_buffer()
	bomb[16] = 127
	var bad_path := PanoramaLibrary.DIRECTORY.path_join("__nebula_bad.png")
	var file := FileAccess.open(bad_path, FileAccess.WRITE)
	file.store_buffer(bomb)
	file.close()
	assert(PanoramaLibrary._decode(bad_path).has("error"))
	assert(PanoramaLibrary._dimensions(PackedByteArray([255, 216, 255, 192, 0, 1])) == Vector2i.ZERO)
	var jpeg := image.save_jpg_to_buffer()
	assert(PanoramaLibrary._dimensions(jpeg) == Vector2i(128, 64))
	var wrong := Image.create(64, 64, false, Image.FORMAT_RGB8)
	wrong.save_png(bad_path)
	assert(PanoramaLibrary._decode(bad_path).has("error"))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.screen.player
	scene._on_action("cinema")
	var paused: bool = player.paused
	scene._apply_panorama(decoded.image, "Prueba")
	assert(scene.active_world_id == -1)
	assert(scene.screen.player == player and player.paused == paused)
	assert(scene.forest_world.get_node("WorldEnvironment").environment.sky.sky_material is PanoramaSkyMaterial)
	scene._select_world(1)
	scene._apply_panorama(decoded.image, "Otra")
	scene._select_world(0)
	assert(scene.active_world_id == 0 and scene.screen.player == player)
	var entries := library.scan()
	var index := entries.find("__nebula_test.png")
	assert(index >= 0)
	assert(library.request(index))
	assert(not library.request(index), "Only one decoding task may run")
	var result: Array = await library.loaded
	assert(result[0].get_size() == Vector2i(128, 64))
	var external := "user://__nebula_import.jpg"
	var source := FileAccess.open(external, FileAccess.WRITE)
	source.store_buffer(jpeg)
	source.close()
	var before := library.scan()
	assert(library.request_import(external))
	var imported: Array = await library.loaded
	assert(imported[0].get_size() == Vector2i(128, 64))
	var after := library.scan()
	assert(after.size() == before.size() + 1)
	assert(library.request_import(external))
	await library.loaded
	assert(library.scan().size() == after.size(), "Duplicate content must not duplicate files")
	for entry in after:
		if not before.has(entry):
			DirAccess.remove_absolute(PanoramaLibrary.DIRECTORY.path_join(entry))
	DirAccess.remove_absolute(external)
	assert(library.request(index))
	library.cancel()
	await create_timer(0.15).timeout
	assert(library._thread == null, "Cancelled work must be drained")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(bad_path)
	scene.queue_free()
	library.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("NEBULAVR_PANORAMAS_OK: PNG/JPEG, limits, asynchronous loading, player continuity, world lifecycle")
	quit()

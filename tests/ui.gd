extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _find_button(node: Node, title: String) -> Button:
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var found := _find_button(child, title)
		if found:
			return found
	return null

func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var ui = scene.ui
	_find_button(ui, "Elegir entorno").pressed.emit()
	await process_frame
	assert(ui._worlds.visible and not ui._home.visible)
	for index in range(6):
		ui._world_buttons[index].pressed.emit()
		assert(scene.active_world_id == index)
		assert(ui._world_buttons[index].get_global_rect().end.x <= 1200)
		assert(ui._world_buttons[index].get_global_rect().end.y <= 800)
	_find_button(ui._worlds, "Volver").pressed.emit()
	assert(ui._home.visible and not ui._worlds.visible)
	scene._on_action("cinema")
	_find_button(ui._cinema, "Entornos").pressed.emit()
	_find_button(ui._worlds, "Volver").pressed.emit()
	assert(ui._cinema.visible and not ui._home.visible)
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("NEBULAVR_UI_OK: selector, seis botones, limites, retorno al cine")
	quit()

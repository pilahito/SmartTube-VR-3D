extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _find_button(node: Node, title: String) -> Button:
	if node is Button and (node.text == title or node.tooltip_text == title):
		return node
	for child in node.get_children():
		var found := _find_button(child, title)
		if found:
			return found
	return null

func _check_bounds(node: Node) -> void:
	if (node is Button or node is Label) and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		assert(rect.position.x >= 0 and rect.position.y >= 0)
		assert(rect.end.x <= 1200 and rect.end.y <= 900, "Botón fuera del panel: " + node.text)
	for child in node.get_children():
		_check_bounds(child)

func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var ui = scene.ui
	_check_bounds(ui)
	_find_button(ui, "%d lugares para desconectar" % ui.WORLD_TITLES.size()).pressed.emit()
	await process_frame
	assert(ui._worlds.visible and not ui._home.visible)
	await process_frame
	_check_bounds(ui)
	for index in ui._world_buttons.size():
		if index > 0 and index % ui.WORLDS_PER_PAGE == 0:
			_find_button(ui._worlds, "Siguiente").pressed.emit()
			await process_frame
			_check_bounds(ui)
		assert(ui._world_buttons[index].is_visible_in_tree(), "La tarjeta del mundo %d debe verse en su página" % index)
		ui._world_buttons[index].pressed.emit()
		await process_frame
		assert(scene.active_world_id == index)
		assert(ui._world_buttons[index].get_global_rect().end.x <= 1200)
		assert(ui._world_buttons[index].get_global_rect().end.y <= 900)
	for page in ui._world_buttons.size() / ui.WORLDS_PER_PAGE:
		_find_button(ui._worlds, "Anterior").pressed.emit()
	await process_frame
	assert(ui._world_buttons[0].is_visible_in_tree())
	_find_button(ui._worlds, "Mis panoramas").pressed.emit()
	await process_frame
	assert(ui._panoramas.visible and not ui._worlds.visible)
	_check_bounds(ui)
	_find_button(ui._panoramas, "Volver a entornos").pressed.emit()
	_find_button(ui._worlds, "Volver").pressed.emit()
	assert(ui._home.visible and not ui._worlds.visible)
	scene._on_action("cinema")
	_find_button(ui._cinema, "Entornos").pressed.emit()
	_find_button(ui._worlds, "Volver").pressed.emit()
	assert(ui._cinema.visible and not ui._home.visible)
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("NEBULAVR_UI_OK: selector, mundos en páginas, limites, retorno al cine")
	quit()

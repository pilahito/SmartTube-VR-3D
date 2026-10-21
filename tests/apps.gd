extends SceneTree

func _initialize() -> void:
	var apps := InstalledApps.new()
	apps.storage_path = "user://apps-test.json"
	assert(not apps.available())
	assert(apps.list_apps().is_empty())
	assert(not apps.error_message.is_empty())
	assert(not apps.launch("com.brave.browser"))
	assert(not apps.pin_app("mal paquete", "Mal"))
	assert(apps.pin_app("com.brave.browser", "Brave"))
	assert(not apps.pin_app("com.brave.browser", "Duplicado"))
	assert(apps.pin_app(InstalledApps.SMARTTUBE, "SmartTube VR"))
	var path := "user://apps-test.json"
	assert(apps.save_favorites(path))
	var restored := InstalledApps.new()
	restored.load_favorites(path)
	assert(restored.favorites == apps.favorites)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('[{"package":"invalid package"},{"package":"com.brave.browser","label":"Brave"},{"package":"com.brave.browser","label":"duplicado"}]')
	file.close()
	restored.load_favorites(path)
	assert(restored.favorites.size() == 1)
	DirAccess.remove_absolute(path)
	print("NEBULAVR_APPS_OK: escritorio, errores, duplicados, persistencia y datos invalidos")
	quit(0)

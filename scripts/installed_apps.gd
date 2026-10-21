class_name InstalledApps
extends RefCounted

const SAVE_PATH := "user://launcher_apps.json"
const SMARTTUBE := "app.smarttube.fdroid.vr"
## Paquetes con los que se instala SmartTube (estable, beta y la versión VR), en orden de preferencia.
const SMARTTUBE_PACKAGES := ["org.smarttube.stable", "org.smarttube.beta", SMARTTUBE]
var error_message := ""
var favorites: Array[Dictionary] = []
var storage_path := SAVE_PATH

func available() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime")

func _java_error() -> bool:
	var wrapper = Engine.get_singleton("JavaClassWrapper")
	var exception = wrapper.get_exception()
	if exception != null:
		error_message = "Android no pudo completar la accion."
		return true
	return false

func _field(object, field: String):
	var reflected = object.getClass().getField(field)
	if _java_error() or reflected == null:
		return null
	var result = reflected.get(object)
	if _java_error():
		return null
	return result

func list_apps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	error_message = ""
	if not available():
		error_message = "Las apps instaladas se consultan en las Quest. El simulador de PC no contiene apps Android."
		return result
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.getActivity()
	if _java_error() or activity == null:
		return result
	var manager = activity.getPackageManager()
	if _java_error() or manager == null:
		return result
	var intent_class = Engine.get_singleton("JavaClassWrapper").wrap("android.content.Intent")
	var seen := {}
	for category in ["android.intent.category.LAUNCHER", "android.intent.category.LEANBACK_LAUNCHER", "com.oculus.intent.category.VR"]:
		var intent = intent_class.Intent("android.intent.action.MAIN")
		intent.addCategory(category)
		if _java_error():
			return result
		var matches = manager.queryIntentActivities(intent, 0)
		if _java_error() or matches == null:
			continue
		var count: int = matches.size()
		if _java_error():
			continue
		for index in range(mini(count, 512)):
			var info = matches.get(index)
			if _java_error() or info == null:
				continue
			var activity_info = _field(info, "activityInfo")
			if activity_info == null:
				continue
			var package_value = _field(activity_info, "packageName")
			if package_value == null:
				continue
			var package_name := str(package_value)
			if seen.has(package_name) or package_name == "app.smarttube.vr3d":
				continue
			var label_object = info.loadLabel(manager)
			if _java_error():
				continue
			var label := package_name
			if label_object is String:
				label = label_object
			elif label_object != null:
				label = str(label_object.toString())
			if _java_error():
				label = package_name
			seen[package_name] = true
			result.append({"package": package_name, "label": label.left(40)})
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.label).naturalnocasecmp_to(str(b.label)) < 0)
	return result

func launch(package_name: String) -> bool:
	error_message = ""
	if not available():
		error_message = "Abrir apps Android requiere ejecutar NebulaVR en las Quest."
		return false
	if not valid_package(package_name):
		error_message = "Identificador de app no valido."
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.getActivity()
	if _java_error() or activity == null:
		return false
	var manager = activity.getPackageManager()
	if _java_error() or manager == null:
		return false
	var intent = manager.getLaunchIntentForPackage(package_name)
	if _java_error():
		return false
	if intent == null:
		intent = manager.getLeanbackLaunchIntentForPackage(package_name)
		if _java_error():
			return false
	if intent == null:
		error_message = "La app no esta instalada o no tiene una actividad de inicio visible."
		return false
	activity.startActivity(intent)
	if _java_error():
		return false
	return true

## Abre la primera versión de SmartTube que esté instalada.
func launch_smarttube() -> bool:
	for package_name: String in SMARTTUBE_PACKAGES:
		if launch(package_name):
			return true
		if not available():
			return false
	error_message = "SmartTube no está instalada en este visor."
	return false

func valid_package(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+$")
	return pattern.search(value) != null

func pin_app(package_name: String, label: String) -> bool:
	if not valid_package(package_name) or favorites.size() >= 24:
		return false
	for item in favorites:
		if item.package == package_name:
			return false
	favorites.append({"package": package_name, "label": label.strip_edges().left(40)})
	return save_favorites(storage_path)

func unpin_app(package_name: String) -> bool:
	for index in range(favorites.size()):
		if favorites[index].package == package_name:
			favorites.remove_at(index)
			return save_favorites(storage_path)
	return false

func save_favorites(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		error_message = "No se pudieron guardar los accesos."
		return false
	file.store_string(JSON.stringify(favorites))
	return true

func load_favorites(path: String = SAVE_PATH) -> void:
	favorites.clear()
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Array:
		return
	var seen := {}
	for item in data:
		if not item is Dictionary or not item.get("package") is String:
			continue
		var package_name: String = item.package
		if not valid_package(package_name) or seen.has(package_name):
			continue
		seen[package_name] = true
		favorites.append({"package": package_name, "label": str(item.get("label", package_name)).left(40)})
		if favorites.size() == 24:
			break

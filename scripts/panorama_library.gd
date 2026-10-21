class_name PanoramaLibrary
extends Node
## Local equirectangular skyboxes. No remote code, APK or packed scenes are loaded.
signal loaded(image: Image, title: String)
signal failed(message: String)
const DIRECTORY := "user://panoramas"
const MAX_BYTES := 16 * 1024 * 1024
const MAX_WIDTH := 4096
const MAX_HEIGHT := 2048
var entries: PackedStringArray = []
var _thread: Thread
var _discard := false

func scan() -> PackedStringArray:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	entries.clear()
	for file in DirAccess.get_files_at(DIRECTORY):
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg"]:
			entries.append(file)
	entries.sort()
	entries.resize(mini(entries.size(), 128))
	return entries.duplicate()

func request(index: int) -> bool:
	if _thread != null or index < 0 or index >= entries.size():
		return false
	var path := DIRECTORY.path_join(entries[index])
	_discard = false
	_thread = Thread.new()
	var error := _thread.start(_decode.bind(path))
	if error != OK:
		_thread = null
		return false
	return true

func request_import(path: String) -> bool:
	if _thread != null or scan().size() >= 128:
		return false
	_discard = false
	_thread = Thread.new()
	if _thread.start(_import_file.bind(path)) != OK:
		_thread = null
		return false
	return true

static func _import_file(path: String) -> Dictionary:
	var result := _decode(path, true)
	if result.has("error"):
		return result
	var data: PackedByteArray = result["bytes"]
	var extension := ".png" if data[0] == 137 else ".jpg"
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(data)
	var filename := hash.finish().hex_encode().left(24) + extension
	var target := DIRECTORY.path_join(filename)
	if not FileAccess.file_exists(target):
		var file := FileAccess.open(target + ".tmp", FileAccess.WRITE)
		if file == null:
			return {"error": "No se pudo guardar el panorama."}
		file.store_buffer(data)
		var error := file.get_error()
		file.close()
		if error != OK or DirAccess.rename_absolute(target + ".tmp", target) != OK:
			DirAccess.remove_absolute(target + ".tmp")
			return {"error": "No se pudo guardar el panorama."}
	result.erase("bytes")
	return result

static func _dimensions(data: PackedByteArray) -> Vector2i:
	# Read dimensions BEFORE decompressing: compressed size alone cannot bound RAM.
	if data.size() >= 24 and data.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		return Vector2i(_be32(data, 16), _be32(data, 20))
	if data.size() < 4 or data[0] != 255 or data[1] != 216:
		return Vector2i.ZERO
	var pos := 2
	while pos + 3 < data.size():
		if data[pos] != 255:
			return Vector2i.ZERO
		while pos < data.size() and data[pos] == 255:
			pos += 1
		if pos >= data.size():
			break
		var marker := data[pos]
		pos += 1
		if marker == 217 or marker == 218:
			break
		if marker == 1 or (marker >= 208 and marker <= 215):
			continue
		if pos + 1 >= data.size():
			break
		var length := data[pos] * 256 + data[pos + 1]
		if length < 2 or pos + length > data.size():
			break
		if marker in [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207] and length >= 8:
			return Vector2i(data[pos + 5] * 256 + data[pos + 6], data[pos + 3] * 256 + data[pos + 4])
		pos += length
	return Vector2i.ZERO

static func _be32(data: PackedByteArray, pos: int) -> int:
	return (int(data[pos]) << 24) | (int(data[pos + 1]) << 16) | (int(data[pos + 2]) << 8) | int(data[pos + 3])

static func _decode(path: String, keep_bytes := false) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES or file.get_length() < 24:
		return {"error": "No se pudo leer la imagen o supera 16 MiB."}
	var data := file.get_buffer(file.get_length())
	var dimensions := _dimensions(data)
	if dimensions.x < 64 or dimensions.y < 32 or dimensions.x > MAX_WIDTH or dimensions.y > MAX_HEIGHT or dimensions.x != dimensions.y * 2:
		return {"error": "Usa un panorama 360° de proporción 2:1, hasta 4096 × 2048."}
	var image := Image.new()
	var error := image.load_png_from_buffer(data) if data[0] == 137 else image.load_jpg_from_buffer(data)
	if error != OK or image.get_size() != dimensions:
		return {"error": "La imagen está dañada o no es PNG/JPEG."}
	var result := {"image": image, "title": path.get_file().get_basename().left(64)}
	if keep_bytes:
		result["bytes"] = data
	return result

func cancel() -> void:
	_discard = true

func _process(_delta: float) -> void:
	if _thread == null or _thread.is_alive():
		return
	var result: Dictionary = _thread.wait_to_finish()
	_thread = null
	if _discard:
		return
	if result.has("error"):
		failed.emit(result.error)
	else:
		loaded.emit(result.image, result.title)

func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

static func build_world(image: Image) -> Node3D:
	var world := Node3D.new()
	world.name = "Panorama360"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var material := PanoramaSkyMaterial.new()
	material.panorama = ImageTexture.create_from_image(image)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.7, 0.8)
	environment.ambient_light_energy = 0.6
	var background := WorldEnvironment.new()
	background.name = "WorldEnvironment"
	background.environment = environment
	world.add_child(background)
	# Invisible stationary floor keeps the XR player grounded. No panorama parallax.
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.5
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200, 1, 200)
	collision.shape = shape
	floor_body.add_child(collision)
	world.add_child(floor_body)
	return world

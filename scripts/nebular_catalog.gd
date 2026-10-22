## Cliente del catálogo de entornos de NebularVR (github.com/pilahito/NebularVR-Quest, carpeta catalogo/).
## Contrato (catalogo/LEEME.md): se lee catalogo.json y solo se descargan los archivos que lista; la descarga
## se rechaza si el SHA-256 o el tamaño no coinciden. Panoramas 360° 2:1, JPG o PNG, máx. 8192×4096 y 40 MB.
class_name NebularCatalog
extends Node

signal list_ready(entries: Array)
signal image_ready(id: String, texture: ImageTexture)
signal failed(what: String)

const BASE_URL := "https://raw.githubusercontent.com/pilahito/NebularVR-Quest/main/catalogo/"
const MAX_BYTES := 40 * 1024 * 1024
const MAX_W := 8192
const MAX_H := 4096
const CACHE_DIR := "user://nebular/"
const CATEGORIES := ["nature", "sky", "scifi", "urban", "interior", "anime", "cartoon", "other"]

var base_url := BASE_URL
var entries: Array = []
var _http: HTTPRequest
var _queue: Array = []
var _busy := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.body_size_limit = MAX_BYTES + 1024
	_http.timeout = 30.0
	add_child(_http)
	_http.request_completed.connect(_on_completed)
	_next()


## Pide catalogo.json (si hay conexión). Emite list_ready con las entradas válidas.
func fetch_list() -> void:
	_enqueue({"kind": "list", "url": base_url + "catalogo.json"})


## Pide (o recupera de la caché) la imagen de una entrada. Emite image_ready.
func fetch_image(entry: Dictionary) -> void:
	var cached := load_cached(entry)
	if cached:
		image_ready.emit(entry["id"], cached)
		return
	_enqueue({"kind": "image", "url": base_url + entry["file"], "entry": entry})


## Textura de la caché si el archivo existe y su hash coincide; si no, null.
func load_cached(entry: Dictionary) -> ImageTexture:
	var path: String = CACHE_DIR + entry["file"]
	if not FileAccess.file_exists(path):
		return null
	var buf := FileAccess.get_file_as_bytes(path)
	if not _verify(buf, entry):
		DirAccess.remove_absolute(path)
		return null
	return _texture(buf, entry["file"])


func _enqueue(job: Dictionary) -> void:
	_queue.append(job)
	_next()


func _next() -> void:
	if _http == null or _busy or _queue.is_empty():
		return
	_busy = true
	var job: Dictionary = _queue[0]
	var err := _http.request(job["url"])
	if err != OK:
		_queue.pop_front()
		_busy = false
		failed.emit("No se pudo iniciar la descarga (%d)" % err)
		_next()


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var job: Dictionary = _queue.pop_front()
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Sin conexión con el catálogo" if job["kind"] == "list" else "No se pudo descargar %s" % job["entry"]["name"])
	elif job["kind"] == "list":
		_on_list(body)
	else:
		_on_image(job["entry"], body)
	_next()


func _on_list(body: PackedByteArray) -> void:
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != 1 or typeof(data.get("environments")) != TYPE_ARRAY:
		failed.emit("El catálogo tiene un formato desconocido")
		return
	entries.clear()
	for raw in data["environments"]:
		var e := validate_entry(raw)
		if not e.is_empty():
			entries.append(e)
	list_ready.emit(entries)


func _on_image(entry: Dictionary, body: PackedByteArray) -> void:
	if not _verify(body, entry):
		failed.emit("%s: el hash no coincide, descarga rechazada" % entry["name"])
		return
	var tex := _texture(body, entry["file"])
	if tex == null:
		failed.emit("%s: imagen no válida (debe ser 2:1 y de hasta 8192×4096)" % entry["name"])
		return
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var f := FileAccess.open(CACHE_DIR + entry["file"], FileAccess.WRITE)
	if f:
		f.store_buffer(body)
		f.close()
	image_ready.emit(entry["id"], tex)


## Valida una entrada del JSON; devuelve {} si algo no cumple (se ignora, no se descarga).
static func validate_entry(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var id := str(raw.get("id", ""))
	var file := str(raw.get("file", ""))
	var sha := str(raw.get("sha256", "")).to_lower()
	var id_re := RegEx.create_from_string("^[a-z0-9_-]{1,48}$")
	var file_re := RegEx.create_from_string("^[A-Za-z0-9_-]{1,64}\\.(jpg|jpeg|png)$")
	var sha_re := RegEx.create_from_string("^[0-9a-f]{64}$")
	if not id_re.search(id) or not file_re.search(file) or not sha_re.search(sha):
		return {}
	var size := int(raw.get("size", 0))
	if size <= 0 or size > MAX_BYTES:
		return {}
	var sun := Color.WHITE
	if str(raw.get("sun", "")).is_valid_html_color():
		sun = Color.html(str(raw["sun"]))
	var category := str(raw.get("category", "other"))
	return {
		"id": id, "name": str(raw.get("name", id)).substr(0, 60), "file": file, "sha256": sha, "size": size,
		"category": category if category in CATEGORIES else "other",
		"author": str(raw.get("author", "")).substr(0, 60), "license": str(raw.get("license", "")).substr(0, 60),
		"sun": sun.to_html(false), "energy": clampf(float(raw.get("energy", 0.8)), 0.0, 2.0),
	}


static func _verify(buf: PackedByteArray, entry: Dictionary) -> bool:
	if buf.size() != int(entry["size"]) or buf.size() > MAX_BYTES:
		return false
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(buf)
	return ctx.finish().hex_encode() == entry["sha256"]


static func _texture(buf: PackedByteArray, file: String) -> ImageTexture:
	var img := Image.new()
	var err := img.load_png_from_buffer(buf) if file.to_lower().ends_with(".png") else img.load_jpg_from_buffer(buf)
	if err != OK:
		return null
	var w := img.get_width()
	var h := img.get_height()
	if w > MAX_W or h > MAX_H or w < 256 or absf(float(w) / float(h) - 2.0) > 0.05:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

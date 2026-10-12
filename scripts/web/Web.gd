extends Node

var callback
var receiver: Object
var receiver_method: String
var proxy_base: String = ""
var serial: int = 0

func _ready():
	if !OS.has_feature("HTML5"): return
	callback = JavaScript.create_callback(self, "_files_received")
	JavaScript.get_interface("window").sspFileCallback = callback
	var configured = JavaScript.eval("window.SSP_PROXY || ''", true)
	if configured is String: proxy_base = configured.trim_suffix("/")
	pause_mode = PAUSE_MODE_PROCESS

func proxy_url(url: String) -> String:
	if proxy_base != "" and url.begins_with("https://cdn.rhythia.net/"):
		return proxy_base + url.trim_prefix("https://cdn.rhythia.net")
	return url

func open_files(target: Object, method: String, filters: PoolStringArray, multiple: bool):
	receiver = target
	receiver_method = method
	var extensions = []
	for filter in filters:
		for part in filter.split(";")[0].split(","):
			var ext = part.strip_edges().trim_prefix("*")
			if ext.begins_with("."): extensions.append(ext)
	JavaScript.eval("window.sspChoose(%s, %s)" % [JSON.print(extensions), "true" if multiple else "false"], true)

func _files_received(_args):
	var paths = PoolStringArray()
	var count = int(JavaScript.eval("window.sspFiles.length", true))
	serial += 1
	var directory = "user://imports/%s" % serial
	Directory.new().make_dir_recursive(directory)
	for i in range(count):
		var name = str(JavaScript.eval("window.sspFiles[%s].name" % i, true)).get_file()
		if !name.is_valid_filename(): continue
		var bytes = JavaScript.eval("window.sspFiles[%s].bytes" % i, true)
		if !(bytes is PoolByteArray): continue
		var file = File.new()
		var path = directory.plus_file(name)
		if file.open(path, File.WRITE) == OK:
			file.store_buffer(bytes)
			file.close()
			paths.append(path)
	JavaScript.eval("window.sspFiles = []", true)
	if is_instance_valid(receiver): receiver.call(receiver_method, paths)

func save_file(target: Object, method: String, _filters: PoolStringArray):
	var name = "export.json"
	var path = "user://" + name
	target.call(method, path)
	call_deferred("_download_saved_file", path, name)

func _download_saved_file(path: String, name: String):
	var file = File.new()
	if file.open(path, File.READ) != OK: return
	JavaScript.download_buffer(file.get_buffer(file.get_len()), name, "application/octet-stream")
	file.close()

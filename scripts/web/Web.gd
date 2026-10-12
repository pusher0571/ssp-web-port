extends Node

var callback
var receiver: Object
var receiver_method: String
var serial: int = 0
var pointer_callback
var exit_callback
var pointer_locked: bool = false
var game: Node

func _ready():
	if !OS.has_feature("HTML5"): return
	callback = JavaScript.create_callback(self, "_files_received")
	JavaScript.get_interface("window").sspFileCallback = callback
	pointer_callback = JavaScript.create_callback(self, "_pointer_changed")
	JavaScript.get_interface("window").sspPointerCallback = pointer_callback
	exit_callback = JavaScript.create_callback(self, "_exit_game")
	JavaScript.get_interface("window").sspExitCallback = exit_callback
	pause_mode = PAUSE_MODE_PROCESS

func begin_game(target: Node):
	game = target
	pointer_locked = false
	JavaScript.eval("window.sspSetGameActive(true)", true)

func end_game(target: Node):
	if game != target: return
	game = null
	pointer_locked = false
	JavaScript.eval("window.sspSetGameActive(false)", true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _pointer_changed(args):
	if !is_instance_valid(game): return
	pointer_locked = bool(args[0])
	game.web_pointer_changed(pointer_locked)

func _exit_game(_args):
	if is_instance_valid(game): game.end(Globals.END_GIVEUP)

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

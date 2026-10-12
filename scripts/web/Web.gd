extends Node

var callback
var receiver: Object
var receiver_method: String
var serial: int = 0
var pointer_callback
var exit_callback
var pointer_locked: bool = false
var game: Node
var settings_callback
var settings_close_callback
var settings_codes_visible: bool = false
var reopen_settings: bool = false
var previous_settings: Dictionary = {}
const SettingsCode = preload("res://scripts/web/SettingsCode.gd")

func _ready():
	if !OS.has_feature("HTML5"): return
	callback = JavaScript.create_callback(self, "_files_received")
	JavaScript.get_interface("window").sspFileCallback = callback
	pointer_callback = JavaScript.create_callback(self, "_pointer_changed")
	JavaScript.get_interface("window").sspPointerCallback = pointer_callback
	exit_callback = JavaScript.create_callback(self, "_exit_game")
	JavaScript.get_interface("window").sspExitCallback = exit_callback
	settings_callback = JavaScript.create_callback(self, "_settings_code_action")
	JavaScript.get_interface("window").sspSettingsCallback = settings_callback
	settings_close_callback = JavaScript.create_callback(self, "_settings_codes_closed")
	JavaScript.get_interface("window").sspSettingsCloseCallback = settings_close_callback
	pause_mode = PAUSE_MODE_PROCESS

func open_settings_codes():
	if !OS.has_feature("HTML5") or is_instance_valid(game): return
	settings_codes_visible = true
	get_tree().paused = true
	JavaScript.eval("window.sspSettingsCodes.open(%s, %s)" % [JSON.print(SettingsCode.encode(Rhythia.get_settings_data())), "true" if !previous_settings.empty() else "false"], true)

func _settings_codes_closed(_args):
	settings_codes_visible = false
	get_tree().paused = false

func _settings_result(message: String, error: bool = false):
	JavaScript.eval("window.sspSettingsCodes.result(%s, %s, %s, %s)" % [JSON.print(message), "true" if error else "false", JSON.print(SettingsCode.encode(Rhythia.get_settings_data())), "true" if !previous_settings.empty() else "false"], true)

func _settings_code_action(args):
	if !settings_codes_visible or args.size() < 1: return
	var current = Rhythia.get_settings_data()
	var data: Dictionary
	var missing = []
	if str(args[0]) == "import":
		if args.size() != 2: return
		var decoded = SettingsCode.decode(str(args[1]), current, Globals.locale.size())
		if decoded.has("error"):
			_settings_result(decoded.error, true)
			return
		data = current.duplicate(true)
		for key in decoded.settings:
			data[key] = decoded.settings[key]
		var registries = {
			"selected_colorset": Rhythia.registry_colorset,
			"selected_space": Rhythia.registry_world,
			"selected_mesh": Rhythia.registry_mesh,
			"selected_hit_effect": Rhythia.registry_effect,
			"selected_miss_effect": Rhythia.registry_effect
		}
		for key in registries:
			if decoded.settings.has(key) and !registries[key].get_item(data[key]):
				missing.append(key)
				data[key] = current[key]
	elif str(args[0]) == "undo" and !previous_settings.empty():
		data = previous_settings.duplicate(true)
	else:
		return
	var error = apply_settings_data(data)
	if !error.empty():
		_settings_result(error, true)
		return
	if str(args[0]) == "import":
		previous_settings = current
	else:
		previous_settings.clear()
	var message = "Settings imported and saved." if str(args[0]) == "import" else "Previous settings restored and saved."
	if !missing.empty():
		message += " Some custom assets are not installed here; those selections were kept."
	_settings_result(message)
	# Existing settings controls write their values every frame. Recreate the menu
	# so every control reads the imported values before it can write anything back.
	reopen_settings = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func apply_settings_data(data: Dictionary) -> String:
	var path = "user://settings-code-import.tmp"
	var file = File.new()
	if file.open(path, File.WRITE) != OK:
		return "Settings could not be imported: browser storage is unavailable."
	file.store_string(JSON.print(data))
	file.close()
	var result = Rhythia.load_saved_settings(path)
	Directory.new().remove(path)
	if result != 0:
		return "Settings could not be read."
	if Rhythia.save_settings() != "OK":
		return "Settings could not be saved."
	return ""

func settings_menu_ready(menu: Node):
	if !reopen_settings: return
	reopen_settings = false
	menu.get_node("Sidebar").press(1, true)
	get_tree().paused = settings_codes_visible

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

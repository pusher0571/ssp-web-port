extends Button

func _pressed():
	if OS.has_feature("HTML5"):
		Globals.notify(Globals.NOTIFY_INFO, "Maps, settings and scores are saved locally in this browser. Use Add Map to import a file.", "Browser storage")
		return
	if !OS.has_feature("Android"):
		OS.shell_open(ProjectSettings.globalize_path(Globals.p("user://")))

func _ready():
	if OS.has_feature("HTML5"):
		text = "Browser storage"
		return
	if OS.has_feature("Android"):
		disabled = true
		text = "User folder location: " + Globals.p("user://")

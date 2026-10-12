extends Button

func _ready():
	visible = OS.has_feature("HTML5")

func _pressed():
	Web.open_settings_codes()

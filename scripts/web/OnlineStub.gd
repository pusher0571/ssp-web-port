extends Node

# Local imports only. These signals keep the existing map UI compatible.
signal db_maps_done
signal map_downloaded
signal latest_version
var map_registry:Registry
var mapdl_hr:HTTPRequest = HTTPRequest.new()
var mapdl_bs:float = 1

func load_db_maps():
	call_deferred("emit_signal", "db_maps_done")

func download_map(_song):
	return ""

func cancel():
	pass

func check_latest_version():
	call_deferred("emit_signal", "latest_version", ProjectSettings.get_setting("application/config/version"))

func attempt_update():
	pass

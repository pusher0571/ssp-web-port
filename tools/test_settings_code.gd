extends SceneTree

const Code = preload("res://scripts/web/SettingsCode.gd")
var failures = 0

func check(condition: bool, description: String):
	if !condition:
		failures += 1
		printerr("FAIL: " + description)

func _init():
	call_deferred("run_tests")

func run_tests():
	var settings = {
		"sensitivity": -0.375, "music_offset": -35.0,
		"cursor_color": "a8d9f5", "panel_bg": "090a12b0",
		"play_hit_snd": false, "language": 0, "trail_detail": 10,
		"master_volume": -80.0, "target_fps": 144,
		"selected_mesh": "ssp_cube", "fov": 70.0,
		"record_replays": false, "enable_oldmenu": false,
		"window_fullscreen": true, "hlm_converted": true
	}
	var code = Code.encode(settings)
	var result = Code.decode(code, settings, 4)
	check(!result.has("error"), "exported codes import successfully")
	if result.has("settings"):
		check(result.settings.size() == 11, "all eleven portable settings are exported")
		check(result.settings.sensitivity == -0.375 and result.settings.music_offset == -35.0, "signed numeric settings round-trip")
		check(result.settings.cursor_color == "a8d9f5" and result.settings.panel_bg == "090a12b0", "colors and alpha round-trip")
		check(result.settings.play_hit_snd == false and result.settings.master_volume == -80.0, "disabled sound and muted volume round-trip")
		check(result.settings.selected_mesh == "ssp_cube" and result.settings.target_fps == 144, "asset selections and integer settings round-trip")
		check(!result.settings.has("record_replays") and !result.settings.has("window_fullscreen"), "platform and removed features are excluded")
	check(!Code.decode("  " + code.replace(":", ":\n") + "\r\n", settings, 4).has("error"), "shared codes tolerate whitespace")
	check(Code.decode(code.substr(0, code.length() - 1), settings, 4).has("error"), "truncated codes are rejected")
	check(Code.decode(code.replace("SSP1:", "SSP9:"), settings, 4).has("error"), "future formats are rejected")
	var parts = code.split(":")
	parts[2] = "0000000000000000"
	check(Code.decode(parts.join(":"), settings, 4).has("error"), "checksum damage is rejected")
	parts = code.split(":")
	parts[1] = "99999999"
	check(Code.decode(parts.join(":"), settings, 4).has("error"), "decompression allocation is bounded")
	check(Code.decode(Code.encode({"language": 10}), settings, 4).has("error"), "invalid language index is rejected")
	check(Code.decode(Code.encode({"sensitivity": "bad"}), settings, 4).has("error"), "wrong number types are rejected")
	check(Code.decode(Code.encode({"trail_detail": 1.5}), settings, 4).has("error"), "fractional integer settings are rejected")
	check(Code.decode(Code.encode({"play_hit_snd": 1}), settings, 4).has("error"), "wrong boolean types are rejected")
	check(Code.decode(Code.encode({"cursor_color": "not-a-color"}), settings, 4).has("error"), "invalid colors are rejected")
	check(Code.decode(Code.encode({"fov": 0}), settings, 4).has("error"), "unusable field of view is rejected")
	check(Code.decode(Code.encode({"unknown": 1}), settings, 4).has("error"), "unknown settings are rejected")
	check(Code.decode(Code.encode({}), settings, 4).has("error"), "empty settings are rejected")
	print("Settings-code tests: " + ("PASS" if failures == 0 else "%s failures" % failures))
	quit(0 if failures == 0 else 1)

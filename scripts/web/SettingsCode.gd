extends Reference

# A versioned, compressed JSON format. Only settings from the existing save schema
# are accepted; maps, scores and files are never part of a code.
const PREFIX = "SSP1"
const MAX_CODE_LENGTH = 32768
const MAX_JSON_BYTES = 65536
const EXCLUDED = [
	"hlm_converted", "enable_oldmenu", "disable_update", "last_search_incl_online",
	"record_replays", "record_mode", "record_limit", "alt_cam", "absolute_mode",
	"window_fullscreen", "window_borderless", "auto_maximize",
	"ignore_controller_detection", "mirror_buttons", "cursor_face_velocity"
]
const RANGES = {
	"fov": [1, 179], "custom_speed": [0.05, 1000],
	"render_scale": [0.1, 8], "cursor_color_type": [0, 2],
	"friend_position": [0, 7], "target_fps": [0, 10000],
	"trail_detail": [1, 10000], "trail_time": [0, 60],
	"sensitivity": [-1000, 1000]
}

static func portable(settings: Dictionary) -> Dictionary:
	var data = settings.duplicate(true)
	for key in EXCLUDED:
		data.erase(key)
	return data

static func encode(settings: Dictionary) -> String:
	var text = JSON.print({"version": 1, "settings": portable(settings)})
	var bytes = text.to_utf8()
	return "%s:%s:%s:%s" % [PREFIX, bytes.size(), text.sha256_text().substr(0, 16), Marshalls.raw_to_base64(bytes.compress(File.COMPRESSION_DEFLATE))]

static func fail(message: String) -> Dictionary:
	return {"error": message}

static func decode(code: String, schema: Dictionary, language_count: int) -> Dictionary:
	if code.length() > MAX_CODE_LENGTH:
		return fail("This code is too long.")
	# Permit line wrapping when codes are shared in a chat or text file.
	code = code.replace("\r", "").replace("\n", "").replace("\t", "").replace(" ", "")
	var parts = code.split(":", true)
	if parts.size() != 4 or parts[0] != PREFIX:
		return fail("Use a settings code exported by SSP Web Port (SSP1).")
	if !parts[1].is_valid_integer():
		return fail("This settings code is incomplete or damaged.")
	var size = int(parts[1])
	if size < 2 or size > MAX_JSON_BYTES:
		return fail("This settings code has an invalid size.")
	var hex = RegEx.new()
	hex.compile("^[0-9a-f]{16}$")
	var base64 = RegEx.new()
	base64.compile("^[A-Za-z0-9+/]+={0,2}$")
	if !hex.search(parts[2]) or parts[3].length() % 4 != 0 or !base64.search(parts[3]):
		return fail("This settings code is incomplete or damaged.")
	var packed = Marshalls.base64_to_raw(parts[3])
	var bytes = packed.decompress_dynamic(MAX_JSON_BYTES, File.COMPRESSION_DEFLATE)
	if bytes.size() != size:
		return fail("This settings code is incomplete or damaged.")
	var text = bytes.get_string_from_utf8()
	if text.sha256_text().substr(0, 16) != parts[2]:
		return fail("This settings code is incomplete or damaged.")
	var parsed = JSON.parse(text)
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return fail("This settings code contains invalid data.")
	var envelope = parsed.result
	if !envelope.has("version") or envelope.version != 1 or !envelope.has("settings") or typeof(envelope.settings) != TYPE_DICTIONARY:
		return fail("This settings code uses an unsupported format.")
	return validate(envelope.settings, portable(schema), language_count)

static func validate(data: Dictionary, schema: Dictionary, language_count: int) -> Dictionary:
	if data.empty():
		return fail("This code contains no settings.")
	var colors = RegEx.new()
	colors.compile("^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")
	for key in data:
		if !schema.has(key):
			return fail("This code contains an unsupported setting: %s." % key)
		var value = data[key]
		var kind = typeof(schema[key])
		if kind == TYPE_BOOL:
			if typeof(value) != TYPE_BOOL:
				return fail("Invalid value for %s." % key)
		elif kind == TYPE_INT or kind == TYPE_REAL or key == "edge_drift":
			if key == "edge_drift" and typeof(value) == TYPE_STRING and value == "+inf":
				continue
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_REAL:
				return fail("Invalid number for %s." % key)
			if is_nan(value) or is_inf(value) or abs(value) > 1000000:
				return fail("Invalid number for %s." % key)
			if kind == TYPE_INT and value != floor(value):
				return fail("Invalid whole number for %s." % key)
			if RANGES.has(key) and (value < RANGES[key][0] or value > RANGES[key][1]):
				return fail("Value outside the supported range for %s." % key)
			if key == "language" and (value < 0 or value >= language_count):
				return fail("This language is not available.")
		elif kind == TYPE_STRING:
			if typeof(value) != TYPE_STRING:
				return fail("Invalid value for %s." % key)
			if str(key).begins_with("selected_"):
				if value.empty() or value.length() > 256:
					return fail("Invalid content ID for %s." % key)
			elif !colors.search(value):
				return fail("Invalid color for %s." % key)
		else:
			return fail("Unsupported value for %s." % key)
	return {"settings": data}

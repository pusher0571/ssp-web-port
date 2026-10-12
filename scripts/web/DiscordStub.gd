extends Node

# Keep the existing client call sites parseable without shipping the native SDK.
enum ActivityType { Playing }
class Activity:
	func set_type(_value): pass
	func set_state(_value): pass
	func set_details(_value): pass
	func get_assets(): return self
	func set_large_image(_value): pass
class Manager:
	func update_activity(_value): pass
var activity_manager = Manager.new()

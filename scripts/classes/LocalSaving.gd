extends Object
class_name LocalSaveSystem

const DEFAULT_PATH:String = "user://SaveFile.ini"

const Sections:Dictionary = {SETTINGS = "SETTINGS"}

static var savedData := ConfigFile.new()

static func initialize() -> void:
	if not FileAccess.file_exists(DEFAULT_PATH): save_file()
	load_file()
		
static func save_file(path:String=DEFAULT_PATH):
	if not savedData is ConfigFile: savedData = ConfigFile.new()
	savedData.save(path)

static func load_file(path:String=DEFAULT_PATH):
	var config:=ConfigFile.new()
	config.load(path)
	savedData = config

static func set_data(section:String, key:String, value):
	savedData.set_value(section, key, value)

static func get_data(section:String, key:String, default = null):
	return savedData.get_value(section, key, default)


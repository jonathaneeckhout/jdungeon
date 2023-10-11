extends Resource
class_name SaveSystem

const DEFAULT_PATH:String = "user://SaveFile.ini"

const Sections:Dictionary = {SETTINGS = "SETTINGS", GAME_DATA = "GAME_DATA"}
@export var savePath:String:
	get: 
		if savePath == "": return DEFAULT_PATH
		else: return savePath


var savedData:=ConfigFile.new()

func _init() -> void:
	if not FileAccess.file_exists(savePath): save_file()
	load_file()
		
func save_file(path:String=savePath):
	if not savedData is ConfigFile: savedData = ConfigFile.new()
	savedData.save(path)

func load_file(path:String=savePath):
	var config:=ConfigFile.new()
	config.load(path)
	savedData = config

func set_data(section:String, key:String, value):
	savedData.set_value(section, key, value)

func get_data(section:String, key:String, default = null):
	return savedData.get_value(section, key, default)
	pass

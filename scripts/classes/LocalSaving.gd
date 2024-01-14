extends RefCounted
class_name LocalSaveSystem

const DEFAULT_PATH: String = "user://SaveFile.ini"

const Sections: Dictionary = {SETTINGS = "SETTINGS"}

static var savedData := ConfigFile.new()


static func file_exists() -> bool:
	return FileAccess.file_exists(DEFAULT_PATH)


static func save_file(path: String = DEFAULT_PATH):
	if not savedData is ConfigFile:
		savedData = ConfigFile.new()
	var errCode: int = savedData.save(path)
	if errCode != OK:
		GodotLogger.error(
			"Could not perform a local save. Error code {0} ({1})".format(
				[errCode, error_string(errCode)]
			)
		)

	return errCode


static func load_file(path: String = DEFAULT_PATH):
	var config := ConfigFile.new()
	var errCode: int = config.load(path)
	savedData = config
	if errCode != OK:
		GodotLogger.error(
			"Could not perform a local load. Error code {0} ({1})".format(
				[errCode, error_string(errCode)]
			)
		)

	return errCode


static func set_data(section: String, key: String, value):
	savedData.set_value(section, key, value)


static func get_data(section: String, key: String, default = null):
	return savedData.get_value(section, key, default)

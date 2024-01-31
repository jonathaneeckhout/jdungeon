extends Node

class_name JSONDatabaseBackend

@export var config: ConfigResource = null


# Upercase function name to match csharp style
func Init():
	return create_file_if_not_exists(config.json_backend_file, {})


func create_file_if_not_exists(path: String, json_data: Dictionary) -> bool:
	if FileAccess.file_exists(path):
		GodotLogger.info("File=[%s] already exists" % path)
		return true

	return write_json_to_file(path, json_data)


func write_json_to_file(path: String, json_data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		GodotLogger.error("Could not open file=[%s] to write" % path)
		return false

	var string_data = JSON.stringify(json_data, "    ")

	file.store_string(string_data)

	file.close()

	return true


func read_json_from_file(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		GodotLogger.warn("Could not open file=[%s] to read" % path)
		return null

	var string_data = file.get_as_text()

	return JSON.parse_string(string_data)


func CreateAccount(username: String, password: String) -> Dictionary:
	var users_json: Variant = read_json_from_file(config.json_backend_file)
	var error: String = ""

	if users_json == null:
		GodotLogger.warn("Could not json parse content of %s" % config.json_backend_file)
		return {"result": false, "error": "Oops something went wrong"}

	if username in users_json:
		error = "User=[%s] already exists" % username
		GodotLogger.info(error)
		return {"result": false, "error": error}

	users_json[username] = {"password": password}

	if not write_json_to_file(config.json_backend_file, users_json):
		GodotLogger.warn("Could not store new user")
		return {"result": false, "error": "Oops something went wrong"}

	GodotLogger.info("Successfully created user=[%s]" % username)

	return {"result": true, "error": ""}


func AuthenticateUser(username: String, password: String) -> bool:
	var users_json = read_json_from_file(config.json_backend_file)
	if users_json == null:
		GodotLogger.warn("Could not json parse content of %s" % config.json_backend_file)
		return false

	return (
		username in users_json
		and "password" in users_json[username]
		and users_json[username]["password"] == password
	)


func StorePlayerData(username: String, data: Dictionary) -> bool:
	var users_json = read_json_from_file(config.json_backend_file)
	if users_json == null:
		GodotLogger.warn("Could not json parse content of %s" % config.json_backend_file)
		return false

	if not username in users_json:
		GodotLogger.warn("User=[%s] does not exists" % username)
		return false

	users_json[username]["data"] = data

	if not write_json_to_file(config.json_backend_file, users_json):
		GodotLogger.warn("Could not store player=[]'s data" % username)
		return false

	return true


func LoadPlayerData(username: String) -> Dictionary:
	var users_json = read_json_from_file(config.json_backend_file)
	if users_json == null:
		GodotLogger.warn("Could not json parse content of %s" % config.json_backend_file)
		return {}

	if not username in users_json:
		GodotLogger.warn("User=[%s] does not exists" % username)
		return {}

	if not "data" in users_json[username]:
		GodotLogger.info("Player=[%s] does not have persistent data" % username)
		return {}

	return users_json[username]["data"]

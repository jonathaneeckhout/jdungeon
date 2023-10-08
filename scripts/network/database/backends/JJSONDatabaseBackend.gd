extends Node

class_name JJSONDatabaseBackend


# Upercase function name to match csharp style
func Init() -> bool:
	return create_file_if_not_exists(J.USERS_FILEPATH, {})


func create_file_if_not_exists(path: String, json_data: Dictionary) -> bool:
	if FileAccess.file_exists(path):
		J.logger.info("File=[%s] already exists" % path)
		return true

	return write_json_to_file(path, json_data)


func write_json_to_file(path: String, json_data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		J.logger.err("Could not open file=[%s] to write" % path)
		return false

	var string_data = JSON.stringify(json_data, "    ")

	file.store_string(string_data)

	file.close()

	return true


func read_json_from_file(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		J.logger.warn("Could not open file=[%s] to read" % path)
		return null

	var string_data = file.get_as_text()

	return JSON.parse_string(string_data)


func CreateAccount(username: String, password: String) -> bool:
	var users_json = read_json_from_file(J.USERS_FILEPATH)
	if users_json == null:
		J.logger.warn("Could not json parse content of %s" % J.USERS_FILEPATH)
		return false

	if username in users_json:
		J.logger.info("User=[%s] already exists" % username)
		return false

	users_json[username] = {"password": password}

	if not write_json_to_file(J.USERS_FILEPATH, users_json):
		J.logger.warn("Could not store new user")
		return false

	J.logger.info("Successfully created user=[%s]" % username)

	return true


func AuthenticateUser(username: String, password: String) -> bool:
	var users_json = read_json_from_file(J.USERS_FILEPATH)
	if users_json == null:
		J.logger.warn("Could not json parse content of %s" % J.USERS_FILEPATH)
		return false

	return (
		username in users_json
		and "password" in users_json[username]
		and users_json[username]["password"] == password
	)


func store_player_data(username: String, data: Dictionary) -> bool:
	var users_json = read_json_from_file(J.USERS_FILEPATH)
	if users_json == null:
		J.logger.warn("Could not json parse content of %s" % J.USERS_FILEPATH)
		return false

	if not username in users_json:
		J.logger.warn("User=[%s] does not exists" % username)
		return false

	users_json[username]["data"] = data

	if not write_json_to_file(J.USERS_FILEPATH, users_json):
		J.logger.warn("Could not store player=[]'s data" % username)
		return false

	return true


func load_player_data(username: String) -> Dictionary:
	var users_json = read_json_from_file(J.USERS_FILEPATH)
	if users_json == null:
		J.logger.warn("Could not json parse content of %s" % J.USERS_FILEPATH)
		return {}

	if not username in users_json:
		J.logger.warn("User=[%s] does not exists" % username)
		return {}

	if not "data" in users_json[username]:
		J.logger.info("Player=[%s] does have persistent exists" % username)
		return {}

	return users_json[username]["data"]

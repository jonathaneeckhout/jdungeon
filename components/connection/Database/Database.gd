extends Node

class_name Database

enum BACKENDS { JSON, POSTGRES }

@export var config: ConfigResource = null

var _backend: Node


func init() -> bool:
	match config.database_backend:
		BACKENDS.JSON:
			GodotLogger.info("Loading json database backend")
			_backend = JSONDatabaseBackend.new()
			_backend.name = "JsonBackend"
			_backend.config = config
			add_child(_backend)
		BACKENDS.POSTGRES:
			GodotLogger.info("Loading postgres database backend")
			_backend = (
				load("res://scripts/network/database/backends/PostgresDatabaseBackend.cs").new()
			)
			_backend.name = "PostgresBackend"
			add_child(_backend)

	if not _backend or not _backend.Init():
		GodotLogger.error("Failed to init database")
		return false

	GodotLogger.info("Database backend=[%s] successfully loaded" % _backend.name)

	return true


func create_account(username: String, password: String) -> Dictionary:
	var validation_result: Dictionary = is_account_valid(username, password)
	if not validation_result["result"]:
		GodotLogger.info("Invalid account for username=[%s]" % username)
		return validation_result

	return _backend.CreateAccount(username, password)


func is_account_valid(username: String, password: String) -> Dictionary:
	var username_regex = RegEx.new()
	# Regular expression to check for only letters and digits in the username and password
	username_regex.compile("^[a-zA-Z0-9]+$")

	var password_regex = RegEx.new()
	# This pattern disallows white spaces
	password_regex.compile("^[^\\s]+$")

	var error: String = ""

	if username.length() < 4 or username.length() > 16:
		error = "Username must be at least 4 characters long or maximum 16 characters long."
		GodotLogger.warn(error)
		return {"result": false, "error": error}

	if password.length() < 4 or password.length() > 32:
		error = "Password must be at least 4 characters long or maximum 32 characters long."
		GodotLogger.warn(error)
		return {"result": false, "error": error}

	if not username_regex.search(username):
		error = "Username can only contain letters and digits."
		GodotLogger.warn(error)
		return {"result": false, "error": error}

	if not password_regex.search(password):
		error = "Password cannot contain white spaces."
		GodotLogger.warn(error)
		return {"result": false, "error": error}

	return {"result": true, "error": ""}


func authenticate_user(username: String, password: String) -> bool:
	if username == "" or password == "":
		GodotLogger.info("Invalid username or password")
		return false

	return _backend.AuthenticateUser(username, password)


func store_player_data(username: String, data: Dictionary) -> bool:
	return _backend.StorePlayerData(username, data)


func load_player_data(username: String) -> Dictionary:
	return _backend.LoadPlayerData(username)

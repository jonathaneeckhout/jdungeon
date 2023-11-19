extends Node

class_name Database

var backend: Node


func init() -> bool:
	match Global.env_database_backend:
		"json":
			GodotLogger.info("Loading json database backend")
			backend = JSONDatabaseBackend.new()
			backend.name = "Backend"
			add_child(backend)
		"postgres":
			GodotLogger.info("Loading postgres database backend")
			backend = (
				load("res://scripts/network/database/backends/PostgresDatabaseBackend.cs").new()
			)
			backend.name = "Backend"
			add_child(backend)

	if not backend or not backend.Init():
		GodotLogger.error("Failed to init database")
		return false

	GodotLogger.info("Database backend=[%s] successfully loaded" % Global.env_database_backend)

	return true


func create_account(username: String, password: String) -> Dictionary:
	var validation_result: Dictionary = is_account_valid(username, password)
	if not validation_result["result"]:
		GodotLogger.info("Invalid account for username=[%s]" % username)
		return validation_result

	return backend.CreateAccount(username, password)


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

	return backend.AuthenticateUser(username, password)


func store_player_data(username: String, data: Dictionary) -> bool:
	return backend.StorePlayerData(username, data)


func load_player_data(username: String) -> Dictionary:
	return backend.LoadPlayerData(username)

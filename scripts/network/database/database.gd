extends Node

var backend: Node


func init() -> bool:
	match J.global.env_server_database_backend:
		"json":
			J.logger.info("Loading json database backend")
			backend = JJSONDatabaseBackend.new()
			backend.name = "Backend"
			add_child(backend)
		"postgres":
			J.logger.info("Loading postgres database backend")
			backend = (
				load("res://scripts/network/database/backends/JPostgresDatabaseBackend.cs").new()
			)
			backend.name = "Backend"
			add_child(backend)

	if not backend or not backend.Init():
		J.logger.err("Failed to init database")
		return false

	return true


func create_account(username: String, password: String) -> bool:
	if username == "" or password == "" or not is_account_valid(username, password):
		J.logger.info("Invalid username or password")
		return false

	return backend.CreateAccount(username, password)


func is_account_valid(username: String, password: String) -> bool:
	var username_regex = RegEx.new()
	# Regular expression to check for only letters and digits in the username and password
	username_regex.compile("^[a-zA-Z0-9]+$")

	var password_regex = RegEx.new()
	# This pattern disallows white spaces
	password_regex.compile("^[^\\s]+$")

	if username.length() < 4 or username.length() > 16:
		J.logger.warn("Username must be at least 4 characters long or maximum 16 characters long.")
		return false

	if password.length() < 4 or password.length() > 32:
		J.logger.warn("Password must be at least 4 characters long or maximum 32 characters long.")
		return false

	if not username_regex.search(username):
		J.logger.warn("Username can only contain letters and digits.")
		return false

	if not password_regex.search(password):
		J.logger.warn("Password cannot contain white spaces.")
		return false

	return true


func authenticate_user(username: String, password: String) -> bool:
	if username == "" or password == "":
		J.logger.info("Invalid username or password")
		return false

	return backend.AuthenticateUser(username, password)


func store_player_data(username: String, data: Dictionary) -> bool:
	return backend.StorePlayerData(username, data)


func load_player_data(username: String) -> Dictionary:
	return backend.LoadPlayerData(username)

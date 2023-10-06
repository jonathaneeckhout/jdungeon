extends Node

var backend: Node


func init() -> bool:
	match J.global.env_server_database_backend:
		"json":
			J.logger.info("Loading json database backend")
			backend = JSONDatabaseBackend.new()
			backend.name = "Backend"
			add_child(backend)

	if not backend or not backend.init():
		J.logger.err("Failed to init database")
		return false

	return true


func create_account(username: String, password: String) -> bool:
	if username == "" or password == "":
		J.logger.info("Invalid username or password")
		return false

	return backend.create_account(username, password)


func authenticate_user(username: String, password: String) -> bool:
	if username == "" or password == "":
		J.logger.info("Invalid username or password")
		return false

	return backend.authenticate_user(username, password)


func store_player_data(username: String, data: Dictionary) -> bool:
	return backend.store_player_data(username, data)


func load_player_data(username: String) -> Dictionary:
	return backend.load_player_data(username)

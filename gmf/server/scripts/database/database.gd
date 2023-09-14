extends Node

var backend: Node


func init() -> bool:
	match Gmf.global.env_server_database_backend:
		"json":
			Gmf.logger.info("Loading json database backend")
			backend = load("res://gmf/server/scripts/database/backends/json_backend.gd").new()
			backend.name = "Backend"
			add_child(backend)

	if not backend or not backend.init():
		Gmf.logger.err("Failed to init database")
		return false

	return true


func create_account(username: String, password: String) -> bool:
	if username == "" or password == "":
		Gmf.logger.info("Invalid username or password")
		return false

	return backend.create_account(username, password)


func authenticate_user(username: String, password: String) -> bool:
	if username == "" or password == "":
		Gmf.logger.info("Invalid username or password")
		return false

	return backend.authenticate_user(username, password)

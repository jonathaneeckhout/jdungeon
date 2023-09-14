extends Node

var env_server_address = ""
var env_server_port = 0
var env_server_max_peers = 0
var env_server_crt = ""
var env_server_key = ""
var env_server_database_backend = ""
var env_debug = false

var server: Node
var client: Node


func load_server_env_variables():
	env_debug = Gmf.env.get_value("DEBUG") == "true"

	var env_port_str = Gmf.env.get_value("SERVER_PORT")
	if env_port_str == "":
		return false

	env_server_port = int(env_port_str)

	var env_max_peers_str = Gmf.env.get_value("SERVER_MAX_PEERS")
	if env_max_peers_str == "":
		return false

	env_server_max_peers = int(env_max_peers_str)

	env_server_crt = Gmf.env.get_value("SERVER_CRT")
	if env_server_crt == "":
		return false

	env_server_key = Gmf.env.get_value("SERVER_KEY")
	if env_server_key == "":
		return false

	env_server_database_backend = Gmf.env.get_value("SERVER_DATABASE_BACKEND")
	if env_server_database_backend == "":
		return false

	return true


func load_client_env_variables():
	env_debug = Gmf.env.get_value("DEBUG") == "true"

	env_server_address = Gmf.env.get_value("SERVER_ADDRESS")

	var env_port_str = Gmf.env.get_value("SERVER_PORT")
	if env_port_str != "":
		env_server_port = int(env_port_str)

	return true

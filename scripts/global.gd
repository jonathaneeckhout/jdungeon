extends Node

var env_server_address: String = ""
var env_server_port: int = 0
var env_server_max_peers: int = 0
var env_server_crt: String = ""
var env_server_key: String = ""
var env_server_database_backend: String = ""
var env_server_json_backend_file: String = ""
var env_debug: bool = false
var env_audio_mute: bool = false

var env_postgres_address: String = ""
var env_postgres_port: int = 0
var env_postgres_user: String = ""
var env_postgress_password: String = ""
var env_postgress_db: String = ""

var server: Node
var client: Node


func load_server_env_variables() -> bool:
	env_debug = J.env.get_value("DEBUG") == "true"

	var env_port_str = J.env.get_value("SERVER_PORT")
	if env_port_str == "":
		return false

	env_server_port = int(env_port_str)

	var env_max_peers_str = J.env.get_value("SERVER_MAX_PEERS")
	if env_max_peers_str == "":
		return false

	env_server_max_peers = int(env_max_peers_str)

	env_server_crt = J.env.get_value("SERVER_CRT")
	if env_server_crt == "":
		return false

	env_server_key = J.env.get_value("SERVER_KEY")
	if env_server_key == "":
		return false

	env_server_database_backend = J.env.get_value("SERVER_DATABASE_BACKEND")
	if env_server_database_backend == "":
		return false

	match env_server_database_backend:
		"json":
			env_server_json_backend_file = J.env.get_value("SERVER_JSON_BACKEND_FILE")
			if env_server_json_backend_file == "":
				return false
		"postgres":
			env_postgres_address = J.env.get_value("POSTGRES_ADDRESS")
			if env_postgres_address == "":
				return false

			var env_postgres_port_str = J.env.get_value("POSTGRES_PORT")
			if env_postgres_port_str == "":
				return false

			env_postgres_port = int(env_postgres_port_str)

			env_postgres_user = J.env.get_value("POSTGRES_USER")
			if env_postgres_user == "":
				return false

			env_postgress_password = J.env.get_value("POSTGRES_PASSWORD")
			if env_postgress_password == "":
				return false

			env_postgress_db = J.env.get_value("POSTGRES_DB")
			if env_postgress_db == "":
				return false

	return true


func load_client_env_variables() -> bool:
	env_debug = J.env.get_value("DEBUG") == "true"

	env_server_address = J.env.get_value("SERVER_ADDRESS")

	var env_port_str = J.env.get_value("SERVER_PORT")
	if env_port_str == "":
		return false

	env_server_port = int(env_port_str)

	env_audio_mute = J.env.get_value("AUDIO_MUTE") == "true"

	return true

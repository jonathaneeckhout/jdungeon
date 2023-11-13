extends Node

enum MODE { SERVER, CLIENT }

signal client_connected(connected: bool)

var mode: MODE = MODE.CLIENT

var users: Dictionary = {}

var database: Database
var message_handler: MessageHandler

var account_rpc: AccountRPC


func init_common() -> bool:
	account_rpc = AccountRPC.new()
	# This short name is done to optimization the network traffic
	account_rpc.name = "A"
	add_child(account_rpc)

	return true


func server_init(port: int, max_clients: int, cert_path: String, key_path: String) -> bool:
	mode = MODE.SERVER

	if not init_common():
		GodotLogger.error("Failed to init gateway's common part")
		return false

	database = Database.new()
	database.name = "Database"
	add_child(database)

	if not database.init():
		GodotLogger.error("Failed to init server's database")
		return false

	var server: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

	var error = server.create_server(port, max_clients)
	if error != OK:
		GodotLogger.error("Failed to create server")
		return false

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.error("Failed to start server")
		return false

	if not Global.env_no_tls:
		var server_tls_options = server_get_tls_options(cert_path, key_path)
		if server_tls_options == null:
			GodotLogger.error("Failed to load tls options")
			return false

		error = server.host.dtls_server_setup(server_tls_options)
		if error != OK:
			GodotLogger.error("Failed to setup DTLS")
			return false

	multiplayer.multiplayer_peer = server

	multiplayer.peer_connected.connect(_on_server_peer_connected)
	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)

	GodotLogger.info("Started gateway server")

	return true


func client_init() -> bool:
	mode = MODE.CLIENT

	if not init_common():
		GodotLogger.error("Failed to init gateway server's common part")
		return false

	multiplayer.connected_to_server.connect(_on_client_connection_succeeded)
	multiplayer.connection_failed.connect(_on_client_connection_failed)
	multiplayer.server_disconnected.connect(_on_client_disconnected)

	return true


func client_connect(address: String, port: int) -> bool:
	var client: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

	var error: int = client.create_client(address, port)
	if error != OK:
		GodotLogger.warn(
			"Failed to create client. Error code {0} ({1})".format([error, error_string(error)])
		)
		return false

	if client.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		GodotLogger.warn("Failed to connect to server")
		return false

	if not Global.env_no_tls:
		var client_tls_options: TLSOptions

		if Global.env_debug:
			client_tls_options = TLSOptions.client_unsafe()
		else:
			client_tls_options = TLSOptions.client()

		error = client.host.dtls_client_setup(address, client_tls_options)
		if error != OK:
			GodotLogger.warn(
				"Failed to connect via DTLS. Error code {0} ({1})".format(
					[error, error_string(error)]
				)
			)
			return false

	multiplayer.multiplayer_peer = client

	GodotLogger.info("Started client")

	return true


func server_get_tls_options(cert_path: String, key_path: String) -> TLSOptions:
	if not FileAccess.file_exists(cert_path):
		GodotLogger.error("Certificate=[%s] does not exist" % cert_path)
		return null

	if not FileAccess.file_exists(key_path):
		GodotLogger.error("Key=[%s] does not exist" % key_path)
		return null

	var cert_file = FileAccess.open(cert_path, FileAccess.READ)
	if cert_file == null:
		GodotLogger.error("Failed to open server certificate %s" % cert_path)
		return null

	var key_file = FileAccess.open(key_path, FileAccess.READ)
	if key_file == null:
		GodotLogger.error("Failed to open server key %s" % key_path)
		return null

	var cert_string = cert_file.get_as_text()
	var key_string = key_file.get_as_text()

	var cert = X509Certificate.new()

	var error = cert.load_from_string(cert_string)
	if error != OK:
		GodotLogger.error("Failed to load certificate")
		return null

	var key = CryptoKey.new()

	error = key.load_from_string(key_string)
	if error != OK:
		GodotLogger.error("Failed to load key")
		return null

	return TLSOptions.server(key, cert)


func is_server() -> bool:
	return mode == MODE.SERVER


func is_user_logged_in(id: int) -> bool:
	return users[id].logged_in


func get_user_by_id(id: int) -> User:
	return users.get(id)


func _on_server_peer_connected(id: int):
	GodotLogger.info("Peer connected %d" % id)
	users[id] = User.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Peer disconnected %d" % id)
	users.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Connection succeeded")
	client_connected.emit(true)


func _on_client_connection_failed():
	GodotLogger.warn("Connection failed")
	client_connected.emit(false)


func _on_client_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)


class User:
	extends Object
	var username: String = ""
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()

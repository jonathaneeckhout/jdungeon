extends Node

enum MODE { SERVER, CLIENT }

signal client_connected(connected: bool)

var mode: MODE = MODE.CLIENT

var users: Dictionary = {}

var dtls_networking: DTLSNetworking
var database: Database
var message_handler: MessageHandler

var account_rpc: AccountRPC


func _ready():
	dtls_networking = DTLSNetworking.new()


func init_common() -> bool:
	account_rpc = AccountRPC.new()
	# This short name is done to optimization the network traffic
	account_rpc.name = "A"
	add_child(account_rpc)

	return true


func server_init(port: int, max_clients: int, cert_path: String, key_path: String) -> bool:
	mode = MODE.SERVER

	if not init_common():
		GodotLogger.error("Failed to init client gateway's common part")
		return false

	database = dtls_networking.add_database(self)
	if database == null:
		GodotLogger.error("Failed add database")
		return false

	var server: ENetMultiplayerPeer = dtls_networking.server_init(
		port, max_clients, cert_path, key_path
	)
	if server == null:
		GodotLogger.error("Failed create server")
		return false

	multiplayer.multiplayer_peer = server

	multiplayer.peer_connected.connect(_on_server_peer_connected)
	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)

	GodotLogger.info("Started client gateway server")

	return true


func client_init() -> bool:
	mode = MODE.CLIENT

	if not init_common():
		GodotLogger.error("Failed to init client gateway server's common part")
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

	GodotLogger.info("Started gateway client")

	return true


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

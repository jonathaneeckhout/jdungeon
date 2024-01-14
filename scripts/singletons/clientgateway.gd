extends Node

enum MODE { SERVER, CLIENT }

signal client_connected(connected: bool)

var mode: MODE = MODE.CLIENT

var users: Dictionary = {}

var dtls_networking: DTLSNetworking
var database: Database
var message_handler: MessageHandler

var client_rpc: ClientRPC

var client: ENetMultiplayerPeer


func _ready():
	dtls_networking = DTLSNetworking.new()


func init_common() -> bool:
	client_rpc = ClientRPC.new()
	# This short name is done to optimization the network traffic
	client_rpc.name = "C"
	add_child(client_rpc)

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

	return true


func client_connect(address: String, port: int) -> bool:
	if not multiplayer.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer.connected_to_server.connect(_on_client_connection_succeeded)

	if not multiplayer.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer.connection_failed.connect(_on_client_connection_failed)

	if not multiplayer.server_disconnected.is_connected(_on_client_disconnected):
		multiplayer.server_disconnected.connect(_on_client_disconnected)

	client = dtls_networking.client_connect(address, port)
	if client == null:
		GodotLogger.warn("Failed to connect to server")
		return false

	multiplayer.multiplayer_peer = client

	GodotLogger.info("Started gateway client")

	return true


func client_disconnect():
	client_cleanup()
	client.close()


func client_cleanup():
	multiplayer.multiplayer_peer = null

	if multiplayer.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer.connected_to_server.disconnect(_on_client_connection_succeeded)

	if multiplayer.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer.connection_failed.disconnect(_on_client_connection_failed)

	if multiplayer.server_disconnected.is_connected(_on_client_disconnected):
		multiplayer.server_disconnected.disconnect(_on_client_disconnected)


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

	client_cleanup()


func _on_client_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)

	client_cleanup()


class User:
	extends RefCounted
	var username: String = ""
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()

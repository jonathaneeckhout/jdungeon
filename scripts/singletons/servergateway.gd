extends Node

enum MODE { SERVER, CLIENT }

signal client_connected(connected: bool)

var multiplayer_api: MultiplayerAPI

var mode: MODE = MODE.CLIENT

var servers: Dictionary = {}

var dtls_networking: DTLSNetworking
var database: Database
var message_handler: MessageHandler

var server_rpc: ServerRPC


func _ready():
	dtls_networking = DTLSNetworking.new()

	multiplayer_api = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(multiplayer_api, "/root/S")


func _process(_delta):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()


func init_common() -> bool:
	server_rpc = ServerRPC.new()
	# This short name is done to optimization the network traffic
	server_rpc.name = "S"
	add_child(server_rpc)
	return true


func server_init(port: int, max_clients: int, cert_path: String, key_path: String) -> bool:
	mode = MODE.SERVER

	if not init_common():
		GodotLogger.error("Failed to init server gateway's common part")
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

	multiplayer_api.multiplayer_peer = server

	multiplayer_api.peer_connected.connect(_on_server_peer_connected)
	multiplayer_api.peer_disconnected.connect(_on_server_peer_disconnected)

	GodotLogger.info("Started server gateway server")

	return true


func client_init(address: String, port: int) -> bool:
	mode = MODE.CLIENT

	if not init_common():
		GodotLogger.error("Failed to init gateway server's common part")
		return false

	multiplayer_api.connected_to_server.connect(_on_client_connection_succeeded)
	multiplayer_api.connection_failed.connect(_on_client_connection_failed)
	multiplayer_api.server_disconnected.connect(_on_client_disconnected)

	var client: ENetMultiplayerPeer = dtls_networking.client_connect(address, port)
	if client == null:
		GodotLogger.warn("Failed to connect to server")
		return false

	multiplayer_api.multiplayer_peer = client

	GodotLogger.info("Started gateway client")

	return true


func is_server() -> bool:
	return mode == MODE.SERVER


func get_server_by_id(id: int) -> Server:
	return servers.get(id)


func _on_server_peer_connected(id: int):
	GodotLogger.info("Server peer connected %d" % id)
	servers[id] = Server.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Server peer disconnected %d" % id)
	servers.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Gateway server's connection succeeded")
	client_connected.emit(true)

	server_rpc.register_server.rpc_id(1, "World", Global.env_server_address, Global.env_server_port)


func _on_client_connection_failed():
	GodotLogger.warn("Gateway server's connection failed")
	client_connected.emit(false)


func _on_client_disconnected():
	GodotLogger.info("Gateway server's server disconnected")
	client_connected.emit(false)


class Server:
	extends Object
	var name: String = ""
	var address: String = ""
	var port: int = 0
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()

extends Node

enum MODE { SERVER, CLIENT }

const COOKIE_TIMER_INTERVAL: float = 10.0
const COOKIE_VALID_TIME: float = 60.0

signal server_connected(connected: bool)

var multiplayer_api: MultiplayerAPI

var mode: MODE = MODE.CLIENT

var servers: Dictionary = {}
var users: Dictionary = {}

var dtls_networking: DTLSNetworking
var database: Database
var message_handler: MessageHandler

var server_rpc: ServerRPC

var client: ENetMultiplayerPeer = null


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


func client_init() -> bool:
	mode = MODE.CLIENT

	if not init_common():
		GodotLogger.error("Failed to init gateway server's common part")
		return false

	var check_cookie_timer: Timer = Timer.new()
	check_cookie_timer.name = "CheckCookieTimer"
	check_cookie_timer.autostart = true
	check_cookie_timer.one_shot = false
	check_cookie_timer.wait_time = COOKIE_TIMER_INTERVAL
	check_cookie_timer.timeout.connect(_on_check_cookie_timer_timeout)
	add_child(check_cookie_timer)

	return true


func client_connect(address: String, port: int) -> bool:
	if not multiplayer_api.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer_api.connected_to_server.connect(_on_client_connection_succeeded)

	if not multiplayer_api.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer_api.connection_failed.connect(_on_client_connection_failed)

	if not multiplayer_api.server_disconnected.is_connected(_on_client_disconnected):
		multiplayer_api.server_disconnected.connect(_on_client_disconnected)

	client = dtls_networking.client_connect(address, port)
	if client == null:
		GodotLogger.warn("Failed to connect to gateway server")
		return false

	multiplayer_api.multiplayer_peer = client

	GodotLogger.info("Started gateway client")

	return true


func client_disconnect():
	client_cleanup()

	if client != null:
		client.close()
		client = null


func client_cleanup():
	multiplayer_api.multiplayer_peer = null

	if multiplayer_api.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer_api.connected_to_server.disconnect(_on_client_connection_succeeded)

	if multiplayer_api.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer_api.connection_failed.disconnect(_on_client_connection_failed)

	if multiplayer_api.server_disconnected.is_connected(_on_client_disconnected):
		multiplayer_api.server_disconnected.disconnect(_on_client_disconnected)


func is_server() -> bool:
	return mode == MODE.SERVER


func get_server_by_id(id: int) -> Server:
	return servers.get(id)


func get_server_by_name(server_name: String) -> Server:
	for id in servers:
		var server = servers[id]
		if server.name == server_name:
			return server

	return null


func register_user(username: String, cookie: String):
	GodotLogger.info("Registering user=[%s]" % username)
	var user = S.User.new()
	user.username = username
	user.cookie = cookie
	S.users[username] = user


func authenticate_user(username: String, cookie: String) -> bool:
	GodotLogger.info("Authenticating user=[%s]" % username)

	var user: User = get_user_by_username(username)
	if user == null:
		GodotLogger.info("User=[%s] not found" % username)
		return false

	return user.cookie == cookie


func get_user_by_username(username: String) -> User:
	return users.get(username)


func _on_server_peer_connected(id: int):
	GodotLogger.info("Server peer connected %d" % id)
	servers[id] = Server.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Server peer disconnected %d" % id)
	servers.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Gateway server's connection succeeded")
	server_connected.emit(true)


func _on_client_connection_failed():
	GodotLogger.warn("Gateway server's connection failed")
	server_connected.emit(false)


func _on_client_disconnected():
	GodotLogger.info("Gateway server's server disconnected")
	server_connected.emit(false)


func _on_check_cookie_timer_timeout():
	var to_be_deleted: Array[String] = []
	var current_time: float = Time.get_unix_time_from_system()

	for username in users:
		var user: User = users[username]
		if (current_time - user.registered_time) > COOKIE_VALID_TIME:
			to_be_deleted.append(username)

	for username in to_be_deleted:
		GodotLogger.info("User=[%s] cookie expired, removing from list" % username)
		users.erase(username)


class Server:
	extends RefCounted
	var name: String = ""
	var address: String = ""
	var peer_id: int = 0
	var port: int = 0
	var portals_info: Dictionary = {}
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()


class User:
	extends RefCounted
	var username: String = ""
	var cookie: String = ""
	# Used to check how long the cookie is valid
	var registered_time: float = Time.get_unix_time_from_system()

extends Node

enum MODE { SERVER, CLIENT }

signal client_connected(connected: bool)
# TODO: place this signal in another file
signal shop_opened(vendor_name: String)

const CLOCK_SYNC_TIME: float = 0.5

var mode: MODE = MODE.CLIENT

var users: Dictionary = {}

var dtls_networking: DTLSNetworking
var database: Database
var message_handler: MessageHandler

var clock_rpc: ClockRPC
var player_rpc: PlayerRPC
var sync_rpc: SyncRPC

var server: ENetMultiplayerPeer = null
var client: ENetMultiplayerPeer = null

var clock: float = 0.0
var clock_sync_timer: Timer

# The current world
var world: World = null

var client_player: Player = null


func _ready():
	dtls_networking = DTLSNetworking.new()


func init_common() -> bool:
	clock_rpc = ClockRPC.new()
	# This short name is done to optimization the network traffic
	clock_rpc.name = "C"
	add_child(clock_rpc)

	player_rpc = PlayerRPC.new()
	# This short name is done to optimization the network traffic
	player_rpc.name = "P"
	add_child(player_rpc)

	sync_rpc = SyncRPC.new()
	# This short name is done to optimization the network traffic
	sync_rpc.name = "S"
	add_child(sync_rpc)

	return true


func server_init() -> bool:
	mode = MODE.SERVER

	if not init_common():
		GodotLogger.error("Failed to init gameserver's common part")
		return false

	database = dtls_networking.add_database(self)
	if database == null:
		GodotLogger.error("Failed add database")
		return false

	message_handler = MessageHandler.new()
	message_handler.name = "MessageHandler"
	add_child(message_handler)

	return true


func server_start(port: int, max_clients: int, cert_path: String, key_path: String) -> bool:
	server = dtls_networking.server_init(port, max_clients, cert_path, key_path)
	if server == null:
		GodotLogger.error("Failed create server")
		return false

	multiplayer.multiplayer_peer = server

	multiplayer.peer_connected.connect(_on_server_peer_connected)
	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)

	GodotLogger.info("Started server")

	return true


func client_init() -> bool:
	mode = MODE.CLIENT

	if not init_common():
		GodotLogger.error("Failed to init gameserver's common part")
		return false

	clock_sync_timer = Timer.new()
	clock_sync_timer.name = "ClockSyncTimer"
	clock_sync_timer.wait_time = CLOCK_SYNC_TIME
	clock_sync_timer.timeout.connect(_on_clock_sync_timer_timeout)
	add_child(clock_sync_timer)

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

	GodotLogger.info("Started client")

	return true


func client_disconnect():
	client_cleanup()

	if client != null:
		client.close()
		client = null


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


func is_own_player(player: Player) -> bool:
	# You can never be your own player on the server instance
	if is_server():
		return false

	if player == null:
		return false

	# If the player's id matches the id of the connection you know that you're facing your own player node
	return player.peer_id == multiplayer.get_unique_id()


func is_user_logged_in(id: int) -> bool:
	return users[id].logged_in


func get_user_by_id(id: int) -> User:
	return users.get(id)


func start_sync_clock():
	clock_rpc.fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	clock_sync_timer.start()


func stop_sync_clock():
	clock_sync_timer.stop()


func _on_server_peer_connected(id: int):
	GodotLogger.info("Peer connected %d" % id)
	users[id] = User.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Peer disconnected %d" % id)
	users.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Connection succeeded")
	client_connected.emit(true)

	start_sync_clock()


func _on_client_connection_failed():
	GodotLogger.warn("Connection failed")
	client_connected.emit(false)

	client_cleanup()


func _on_client_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)

	stop_sync_clock()

	client_cleanup()


func _on_clock_sync_timer_timeout():
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		clock_rpc.get_latency.rpc_id(1, Time.get_unix_time_from_system())


class User:
	extends RefCounted
	var username: String = ""
	var logged_in: bool = false
	var connected_time: float = Time.get_unix_time_from_system()
	var player: Player = null

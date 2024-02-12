extends Node

class_name MultiplayerConnection

## Signal indicating if a client connected or not
signal client_connected(connected: bool)

signal client_disconnected(username: String)

## Signal to indicate that the initialization is done. Used for the child components
signal init_done

@export var database: Database = null

## The modes a connection can be in
enum MODE { SERVER, CLIENT }

var multiplayer_api: MultiplayerAPI = null

## A list of the components attached to this component
var component_list: ComponentList = ComponentList.new()

var network_stats: NetworkStats = NetworkStats.new()

## The client's player character
var client_player: Player = null

var map: Map = null

# The current mode of this instance
var _mode: MODE = MODE.CLIENT

# Boolean indicating if the client already called the init
var _client_init_done: bool = false

# Dict containing all user connected to the server
var _server_users: Dictionary = {}


func _init():
	set_process(false)


func _process(_delta):
	if multiplayer_api and multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()


func _init_common() -> bool:
	multiplayer_api = MultiplayerAPI.create_default_interface()

	get_tree().set_multiplayer(multiplayer_api, get_path())

	# Set the current multiplayer's api path to this path to optimize multiplayer packets
	multiplayer_api.object_configuration_add(null, get_path())

	return true


func _client_init() -> bool:
	if _client_init_done:
		GodotLogger.info("Client init already done, no need to do it again")
		return true

	_mode = MODE.CLIENT

	GodotLogger.info("Running game as client instance")

	if not _init_common():
		GodotLogger.error("Failed to init common connection part")
		return false

	_client_init_done = true

	# Let the others know you're done initializing
	init_done.emit()

	return true


## Client start function to be called after the inherited class client start
func _client_start():
	if not multiplayer_api.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer_api.connected_to_server.connect(_on_client_connection_succeeded)

	if not multiplayer_api.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer_api.connection_failed.connect(_on_client_connection_failed)

	if not multiplayer_api.server_disconnected.is_connected(_on_client_server_disconnected):
		multiplayer_api.server_disconnected.connect(_on_client_server_disconnected)

	set_process(true)


func _client_cleanup():
	multiplayer_api.multiplayer_peer = null

	if multiplayer_api.connected_to_server.is_connected(_on_client_connection_succeeded):
		multiplayer_api.connected_to_server.disconnect(_on_client_connection_succeeded)

	if multiplayer_api.connection_failed.is_connected(_on_client_connection_failed):
		multiplayer_api.connection_failed.disconnect(_on_client_connection_failed)

	if multiplayer_api.server_disconnected.is_connected(_on_client_server_disconnected):
		multiplayer_api.server_disconnected.disconnect(_on_client_server_disconnected)


func _server_init() -> bool:
	_mode = MODE.SERVER

	GodotLogger.info("Running game as server instance")

	if not _init_common():
		GodotLogger.error("Failed to init common connection part")
		return false

	# Let the others know you're done initializing
	init_done.emit()

	return true


func _server_start():
	if not multiplayer_api.peer_connected.is_connected(_on_server_peer_connected):
		multiplayer_api.peer_connected.connect(_on_server_peer_connected)

	if not multiplayer_api.peer_disconnected.is_connected(_on_server_peer_disconnected):
		multiplayer_api.peer_disconnected.connect(_on_server_peer_disconnected)

	set_process(true)


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


## Check if the current instance is running as server or client
func is_server() -> bool:
	return _mode == MODE.SERVER


## Check if the given player is your own player
func is_own_player(player: Player) -> bool:
	return client_player == player


## Get the user by its id
## To be called on server-side
func get_user_by_id(id: int) -> User:
	assert(is_server(), "This function should only be called on the server side")

	return _server_users.get(id)


func get_server_by_name(server_name: String) -> User:
	for id in _server_users:
		if _server_users[id].name == server_name:
			return _server_users[id]

	return null


## Checks if a user is logged in by it's id
func is_user_logged_in(id: int) -> bool:
	assert(is_server(), "This function should only be called on the server side")

	return _server_users[id].logged_in


func _on_server_peer_connected(id: int):
	GodotLogger.info("Peer connected %d" % id)

	_server_users[id] = User.new()


func _on_server_peer_disconnected(id: int):
	GodotLogger.info("Peer disconnected %d" % id)

	var user: User = get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	client_disconnected.emit(user.username)

	_server_users.erase(id)


func _on_client_connection_succeeded():
	GodotLogger.info("Connection succeeded")
	client_connected.emit(true)


func _on_client_connection_failed():
	GodotLogger.warn("Connection failed")
	client_connected.emit(false)

	_client_cleanup()


func _on_client_server_disconnected():
	GodotLogger.info("Server disconnected")
	client_connected.emit(false)

	_client_cleanup()


class User:
	extends RefCounted
	var username: String = ""
	var logged_in: bool = false
	var cookie: String = ""
	var connected_time: float = Time.get_unix_time_from_system()
	var player: Player = null
	var portals_info: Dictionary = {}
	var name: String = ""
	var address: String = ""
	var peer_id: int = 0

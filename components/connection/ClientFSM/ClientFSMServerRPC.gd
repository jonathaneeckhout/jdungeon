extends Node

class_name ClientFSMServerRPC

const COMPONENT_NAME = "ClientFSMServerRPC"

const COOKIE_TIMER_INTERVAL: float = 10.0
const COOKIE_VALID_TIME: float = 60.0

signal authenticated(response: bool)
signal player_loaded(player_info: Dictionary)

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null

var users: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done

	if _multiplayer_connection.is_server():
		var check_cookie_timer: Timer = Timer.new()
		check_cookie_timer.name = "CheckCookieTimer"
		check_cookie_timer.autostart = true
		check_cookie_timer.one_shot = false
		check_cookie_timer.wait_time = COOKIE_TIMER_INTERVAL
		check_cookie_timer.timeout.connect(_on_check_cookie_timer_timeout)
		add_child(check_cookie_timer)

		_multiplayer_connection.client_disconnected.connect(_on_client_disconnected)


func register_user(username: String, cookie: String):
	GodotLogger.info("Registering user=[%s]" % username)

	var user = MultiplayerConnection.User.new()
	user.username = username
	user.cookie = cookie
	users[username] = user


func authenticate(username: String, cookie: String):
	_authenticate.rpc_id(1, username, cookie)


func load_player():
	_load_player.rpc_id(1)


func _authenticate_user(username: String, cookie: String) -> bool:
	GodotLogger.info("Authenticating user=[%s]" % username)

	var user: MultiplayerConnection.User = _get_user_by_username(username)
	if user == null:
		GodotLogger.info("User=[%s] not found" % username)
		return false

	return user.cookie == cookie


func _get_user_by_username(username: String) -> MultiplayerConnection.User:
	return users.get(username)


func _on_check_cookie_timer_timeout():
	var to_be_deleted: Array[String] = []
	var current_time: float = Time.get_unix_time_from_system()

	for username in users:
		var user: MultiplayerConnection.User = users[username]
		if (current_time - user.connected_time) > COOKIE_VALID_TIME:
			to_be_deleted.append(username)

	for username in to_be_deleted:
		GodotLogger.info("User=[%s] cookie expired, removing from list" % username)
		users.erase(username)


@rpc("call_remote", "any_peer", "reliable")
func _authenticate(username: String, cookie: String):
	if not _multiplayer_connection.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var res = _authenticate_user(username, cookie)
	if not res:
		_authentication_response.rpc_id(id, false)
		return

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		_authentication_response.rpc_id(id, false)
		return

	GodotLogger.info("Player=[%s] successfully logged in" % username)
	user.username = username
	user.logged_in = true

	_authentication_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable")
func _authentication_response(response: bool):
	authenticated.emit(response)


@rpc("call_remote", "any_peer", "reliable")
func _load_player():
	if not _multiplayer_connection.multiplayer_api.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	if user.player == null:
		# TODO: fix this spawn location
		user.player = _multiplayer_connection.map.server_add_player(
			id, user.username, Vector2(0, 128)
		)

	_load_player_response.rpc_id(id, id, user.username, user.player.position)


@rpc("call_remote", "authority", "reliable")
func _load_player_response(peer_id: int, username: String, pos: Vector2):
	player_loaded.emit({"peer_id": peer_id, "username": username, "pos": pos})


func _on_client_disconnected(username: String):
	_multiplayer_connection.map.server_remove_player(username)

extends Node

class_name ClientFSMGatewayRPC

const COMPONENT_NAME = "ClientFSMGatewayRPC"

signal authenticated(response: bool)
signal server_info_received(response: Dictionary)
signal account_created(response: Dictionary)

@export var gateway_server_multiplayer_connection: WebsocketMultiplayerConnection = null

@export var server_fsm_rpc: ServerFSMRPC = null

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


func authenticate(username: String, password: String):
	_authenticate.rpc_id(1, username, password)


func get_server():
	_get_server.rpc_id(1)


func create_account(username: String, password: String):
	_create_account.rpc_id(1, username, password)


@rpc("call_remote", "any_peer", "reliable")
func _authenticate(username: String, password: String):
	if not _multiplayer_connection.is_server():
		return

	GodotLogger.info("Authenticating user=[%s]" % username)
	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var res = _multiplayer_connection.database.authenticate_user(username, password)
	if not res:
		_authentication_response.rpc_id(id, false)
		return

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	GodotLogger.info("Player=[%s] successfully logged in" % username)
	user.username = username
	user.logged_in = res

	_authentication_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable")
func _authentication_response(response: bool):
	authenticated.emit(response)


@rpc("call_remote", "any_peer", "reliable")
func _get_server():
	if not _multiplayer_connection.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		return

	# Take the default starter server
	var server_name: String = "BaseCamp"

	var data: Dictionary = {}
	# var data: Dictionary = C.database.load_player_data(user.username)
	if not data.is_empty() and data.has("server") and data["server"] != "":
		server_name = data["server"]

	GodotLogger.info("Adding player to server=[%s]" % server_name)

	var server: MultiplayerConnection.User = (
		gateway_server_multiplayer_connection.get_server_by_name(server_name)
	)
	if server == null:
		GodotLogger.warn("Could not find server=[%s]" % server_name)
		_get_server_response.rpc_id(id, true, "World", "", "")
		return

	# Create an unique cookie
	var cookie: String = J.uuid_util.v4()

	# Register the user on the server side
	GodotLogger.info("Registering user=[%s] on server=[%s]" % [user.username, server.name])
	server_fsm_rpc.register_user(server.peer_id, user.username, cookie)

	GodotLogger.info("Sending server=[%s] data to user=[%s]" % [server.name, user.username])
	_get_server_response.rpc_id(id, false, server.name, server.address, cookie)


@rpc("call_remote", "authority", "reliable")
func _get_server_response(error: bool, server_name: String, address: String, cookie: String):
	server_info_received.emit(
		{"error": error, "name": server_name, "address": address, "cookie": cookie}
	)


@rpc("call_remote", "any_peer", "reliable")
func _create_account(username: String, password: String):
	if not _multiplayer_connection.is_server():
		return

	GodotLogger.info("Creating account for user=[%s]" % username)
	var id: int = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var create_account_result: Dictionary = _multiplayer_connection.database.create_account(
		username, password
	)
	if create_account_result["result"]:
		_create_account_response.rpc_id(id, false, "Account created")
	else:
		_create_account_response.rpc_id(id, true, create_account_result["error"])


@rpc("call_remote", "authority", "reliable")
func _create_account_response(error: bool, reason: String = ""):
	account_created.emit({"error": error, "reason": reason})

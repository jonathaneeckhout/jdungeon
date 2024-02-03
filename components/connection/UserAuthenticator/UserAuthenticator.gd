extends Node

class_name UserAuthenticator

const COMPONENT_NAME = "UserAuthenticator"

signal server_player_logged_in(peer_id: int, username: String)

## Signal returning whether or not a player successfully authenticated to the server
signal client_authenticated(response: bool)

var _multiplayer_connection: MultiplayerConnection = null


func _ready():
	_multiplayer_connection = get_parent()

	# Register yourself with your parent
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized
	await _multiplayer_connection.init_done


func authenticate(username: String, password: String):
	_authenticate.rpc_id(1, username, password)


@rpc("call_remote", "any_peer", "reliable")
func _authenticate(username: String, _password: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id: int = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	# TODO: for now no authentication is implemented

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		GodotLogger.warn("Could not find user with id=%d" % id)
		_authentication_response.rpc_id(id, false)
		return

	GodotLogger.info("Player=[%s] successfully logged in" % username)
	user.username = username
	user.logged_in = true

	server_player_logged_in.emit(id, username)

	_authentication_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable")
func _authentication_response(response: bool):
	client_authenticated.emit(response)

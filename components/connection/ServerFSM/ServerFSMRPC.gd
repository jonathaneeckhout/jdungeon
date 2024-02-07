extends Node

class_name ServerFSMRPC

const COMPONENT_NAME = "ServerFSMRPC"

signal server_registered(response: bool)

@export var client_fsm_server_rpc: ClientFSMServerRPC = null

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


func register_server(server_name: String, address: String, portals_info: Dictionary):
	_register_server.rpc_id(1, server_name, address, portals_info)


func register_user(peer_id: int, username: String, cookie: String):
	_register_user.rpc_id(peer_id, username, cookie)


@rpc("call_remote", "any_peer", "reliable")
func _register_server(server_name: String, address: String, portals_info: Dictionary):
	# Ensure this call is only run on the server.
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id: int = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var server: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if server == null:
		GodotLogger.warn("Failed to get server with peer id=[%d]" % id)
		_register_response.rpc_id(id, false)
		return

	server.name = server_name
	server.peer_id = id
	server.address = address
	server.portals_info = portals_info

	GodotLogger.info("Server=[%s] with address=[%s] registered" % [server_name, address])

	_register_response.rpc_id(id, true)


@rpc("call_remote", "authority", "reliable")
func _register_response(response: bool):
	server_registered.emit(response)


@rpc("call_remote", "authority", "reliable")
func _register_user(username: String, cookie: String):
	client_fsm_server_rpc.register_user(username, cookie)

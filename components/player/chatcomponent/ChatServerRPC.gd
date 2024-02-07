extends Node

# Define the class name for the script.
class_name ChatServerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "ChatServerRPC"

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null


func send_map_message(message: String):
	_send_map_message.rpc_id(1, message)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


@rpc("call_remote", "any_peer", "reliable")
func _send_map_message(m: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	_receive_map_message.rpc(user.player.name, m)


@rpc("call_remote", "authority", "reliable")
func _receive_map_message(f: String, m: String):
	if _multiplayer_connection.is_server():
		return

	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(ChatComponent.COMPONENT_NAME):
		(
			_multiplayer_connection
			. client_player
			. component_list[ChatComponent.COMPONENT_NAME]
			. client_receive_map_message(f, m)
		)

extends Node

# Define the class name for the script.
class_name PlayerUnstuckRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "PlayerUnstuckRPC"

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


func unstuck():
	_unstuck.rpc_id(1)


@rpc("call_remote", "any_peer", "reliable")
func _unstuck():
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("stats_synchronizer"):
		user.player.component_list["stats_synchronizer"].kill()

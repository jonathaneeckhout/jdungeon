extends Node

# Define the class name for the script.
class_name PlayerSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "PlayerSynchronizerRPC"

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


func sync_pos(peer_id: int, current_frame: int, pos: Vector2):
	_sync_pos.rpc_id(peer_id, current_frame, pos)


func sync_input(current_frame: int, direction: Vector2, timestamp: float):
	_sync_input.rpc_id(1, current_frame, direction, timestamp)


func sync_interact(target: String):
	_sync_interact.rpc_id(1, target)


func request_attack(timestamp: float, enemies: Array):
	_request_attack.rpc_id(1, timestamp, enemies)


@rpc("call_remote", "authority", "unreliable")
func _sync_pos(c: int, p: Vector2):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has("player_synchronizer"):
		_multiplayer_connection.client_player.component_list["player_synchronizer"].client_sync_pos(
			c, p
		)


@rpc("call_remote", "any_peer", "reliable")
func _sync_input(c: int, d: Vector2, t: float):
	if not _multiplayer_connection.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_input(c, d, t)


@rpc("call_remote", "any_peer", "reliable")
func _sync_interact(t: String):
	if not _multiplayer_connection.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_interact(t)


@rpc("call_remote", "any_peer", "reliable")
func _request_attack(t: float, e: Array):
	if not _multiplayer_connection.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_handle_attack_request(t, e)

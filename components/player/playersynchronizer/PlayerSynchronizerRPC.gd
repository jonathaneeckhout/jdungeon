extends Node

# Define the class name for the script.
class_name PlayerSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "PlayerSynchronizerRPC"

enum TYPE { POS, INPUT, INTERACT, ATTACK }

@export var message_identifier: int = 0

var _network_message_handler: NetworkMessageHandler = null

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_network_message_handler = get_parent()

	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent().get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


func sync_pos(peer_id: int, current_frame: int, pos: Vector2):
	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.POS, current_frame, pos]
	)


func sync_input(current_frame: int, direction: Vector2, timestamp: float):
	_network_message_handler.send_message(
		1, message_identifier, [TYPE.INPUT, current_frame, direction, timestamp]
	)


func sync_interact(target: String):
	_network_message_handler.send_message(1, message_identifier, [TYPE.INTERACT, target])


func request_attack(timestamp: float, direction: Vector2, enemies: Array):
	_network_message_handler.send_message(
		1, message_identifier, [TYPE.ATTACK, timestamp, direction, enemies]
	)


func handle_message(peer_id: int, message: Array):
	match message[0]:
		TYPE.POS:
			_sync_pos(peer_id, message[1], message[2])
		TYPE.INPUT:
			_sync_input(peer_id, message[1], message[2], message[3])
		TYPE.INTERACT:
			_sync_interact(peer_id, message[1])
		TYPE.ATTACK:
			_request_attack(peer_id, message[1], message[2], message[3])


func _sync_pos(id: int, c: int, p: Vector2):
	if id != 1:
		return

	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has("player_synchronizer"):
		_multiplayer_connection.client_player.component_list["player_synchronizer"].client_sync_pos(
			c, p
		)


func _sync_input(id: int, c: int, d: Vector2, t: float):
	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_input(c, d, t)


func _sync_interact(id: int, t: String):
	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_sync_interact(t)


func _request_attack(id: int, t: float, d: Vector2, e: Array):
	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("player_synchronizer"):
		user.player.component_list["player_synchronizer"].server_handle_attack_request(t, d, e)

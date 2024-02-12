extends Node

class_name PositionSynchronizerRPC

const COMPONENT_NAME = "PositionSynchronizerRPC"

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


func sync_position(peer_id: int, player_name: String, timestamp: float, pos: Vector2):
	_network_message_handler.send_message(
		peer_id, message_identifier, [player_name, timestamp, pos]
	)


func handle_message(peer_id: int, message: Array):
	if peer_id != 1:
		return

	var n = message[0]
	var t = message[1]
	var p = message[2]

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("position_synchronizer"):
		entity.component_list["position_synchronizer"].client_sync_position(t, p)

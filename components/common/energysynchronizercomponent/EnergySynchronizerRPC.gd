extends Node

class_name EnergySynchronizerRPC

const COMPONENT_NAME = "EnergySynchronizerRPC"

enum TYPE { SYNC, SYNC_RESPONSE, SYNC_CONSUME, SYNC_RECOVER }

@export var message_identifier: int = 0

# Reference to the MultiplayerConnection parent node.
var _multiplayer_connection: MultiplayerConnection = null

var _network_message_handler: NetworkMessageHandler = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_network_message_handler = get_parent()

	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent().get_parent()

	# Register the component with the parent MultiplayerConnection.
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await _multiplayer_connection.init_done


func handle_message(peer_id: int, message: Array):
	match message[0]:
		TYPE.SYNC:
			_request_sync(peer_id, message[1])
		TYPE.SYNC_RESPONSE:
			_sync_response(peer_id, message[1], message[2])
		TYPE.SYNC_CONSUME:
			_sync_consume(peer_id, message[1], message[2], message[3], message[4], message[5])
		TYPE.SYNC_RECOVER:
			_sync_recover(peer_id, message[1], message[2], message[3], message[4], message[5])


func request_sync(entity_name: String):
	_network_message_handler.send_message(1, message_identifier, [TYPE.SYNC, entity_name])


func sync_response(peer_id: int, entity_name: String, data: Dictionary):
	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.SYNC_RESPONSE, entity_name, data]
	)


func sync_energy_consume(
	peer_id: int, entity_name: String, timestamp: float, from: String, energy: int, amount: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_CONSUME, entity_name, timestamp, from, energy, amount]
	)


func sync_energy_recover(
	peer_id: int, entity_name: String, timestamp: float, from: String, energy: int, amount: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_RECOVER, entity_name, timestamp, from, energy, amount]
	)


#Called by client, runs on server
func _request_sync(id: int, n: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EnergySynchronizerComponent.COMPONENT_NAME):
		_sync_response(
			id, n, entity.component_list[EnergySynchronizerComponent.COMPONENT_NAME].to_json()
		)


func _sync_response(id: int, n: String, d: Dictionary):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EnergySynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EnergySynchronizerComponent.COMPONENT_NAME].from_json(d)


func _sync_consume(id: int, n: String, t: float, f: String, e: int, a: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EnergySynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EnergySynchronizerComponent.COMPONENT_NAME].sync_consume(t, f, e, a)


func _sync_recover(id: int, n: String, t: float, f: String, e: int, a: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EnergySynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EnergySynchronizerComponent.COMPONENT_NAME].sync_recover(t, f, e, a)

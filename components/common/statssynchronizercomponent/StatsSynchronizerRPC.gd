extends Node

class_name StatsSynchronizerRPC

const COMPONENT_NAME = "StatsSynchronizerRPC"

enum TYPE {
	SYNC_STATS,
	SYNC_RESPONSE,
	SYNC_HURT,
	SYNC_HEAL,
	SYNC_ENERGY_RECOVERY,
	SYNC_INT_CHANGE,
	SYNC_FLOAT_CHANGE
}

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
		TYPE.SYNC_STATS:
			_sync_stats(peer_id, message[1])
		TYPE.SYNC_RESPONSE:
			_sync_response(peer_id, message[1], message[2])
		TYPE.SYNC_HURT:
			_sync_hurt(peer_id, message[1], message[2], message[3], message[4], message[5])
		TYPE.SYNC_HEAL:
			_sync_heal(peer_id, message[1], message[2], message[3], message[4], message[5])
		TYPE.SYNC_ENERGY_RECOVERY:
			_sync_energy_recovery(
				peer_id, message[1], message[2], message[3], message[4], message[5]
			)
		TYPE.SYNC_INT_CHANGE:
			_sync_int_change(peer_id, message[1], message[2], message[3], message[4])
		TYPE.SYNC_FLOAT_CHANGE:
			_sync_float_change(peer_id, message[1], message[2], message[3], message[4])


func sync_stats(entity_name: String):
	_network_message_handler.send_message(1, message_identifier, [TYPE.SYNC_STATS, entity_name])


func sync_response(peer_id: int, entity_name: String, data: Dictionary):
	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.SYNC_RESPONSE, entity_name, data]
	)


func sync_hurt(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	attacker_name: String,
	health: int,
	damage: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_HURT, entity_name, timestamp, attacker_name, health, damage]
	)


func sync_heal(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	healer_name: String,
	health: int,
	healing: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_HEAL, entity_name, timestamp, healer_name, health, healing]
	)


func sync_energy_recovery(
	peer_id: int, entity_name: String, timestamp: float, from: String, energy: int, recovered: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_ENERGY_RECOVERY, entity_name, timestamp, from, energy, recovered]
	)


func sync_int_change(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	stat_type: StatsSynchronizerComponent.TYPE,
	value: int
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_INT_CHANGE, entity_name, timestamp, stat_type, value]
	)


func sync_float_change(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	stat_type: StatsSynchronizerComponent.TYPE,
	value: float
):
	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.SYNC_FLOAT_CHANGE, entity_name, timestamp, stat_type, value]
	)


#Called by client, runs on server
func _sync_stats(id: int, n: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_stats(id)


func _sync_response(id: int, n: String, d: Dictionary):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_response(d)


func _sync_hurt(id: int, n: String, t: float, f: String, c: int, d: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_hurt(t, f, c, d)


func _sync_heal(id: int, n: String, t: float, f: String, c: int, h: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_heal(t, f, c, h)


func _sync_energy_recovery(id: int, n: String, t: float, f: String, e: int, r: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_energy_recovery(t, f, e, r)


func _sync_int_change(id: int, n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: int):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_int_change(t, s, v)


func _sync_float_change(id: int, n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: float):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_float_change(t, s, v)

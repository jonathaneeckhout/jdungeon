extends Node

class_name StatsSynchronizerRPC

const COMPONENT_NAME = "StatsSynchronizerRPC"

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


func sync_stats(entity_name: String):
	_sync_stats.rpc_id(1, entity_name)


func sync_response(peer_id: int, entity_name: String, data: Dictionary):
	_sync_response.rpc_id(peer_id, entity_name, data)


func sync_hurt(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	attacker_name: String,
	health: int,
	damage: int
):
	_sync_hurt.rpc_id(peer_id, entity_name, timestamp, attacker_name, health, damage)


func sync_heal(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	healer_name: String,
	health: int,
	healing: int
):
	_sync_heal.rpc_id(peer_id, entity_name, timestamp, healer_name, health, healing)


func sync_energy_recovery(
	peer_id: int, entity_name: String, timestamp: float, from: String, energy: int, recovered: int
):
	_sync_energy_recovery.rpc_id(peer_id, entity_name, timestamp, from, energy, recovered)


func sync_int_change(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	stat_type: StatsSynchronizerComponent.TYPE,
	value: int
):
	_sync_int_change.rpc_id(peer_id, entity_name, timestamp, stat_type, value)


func sync_float_change(
	peer_id: int,
	entity_name: String,
	timestamp: float,
	stat_type: StatsSynchronizerComponent.TYPE,
	value: float
):
	_sync_float_change.rpc_id(peer_id, entity_name, timestamp, stat_type, value)


#Called by client, runs on server
@rpc("call_remote", "any_peer", "reliable")
func _sync_stats(n: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = multiplayer.get_remote_sender_id()

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


@rpc("call_remote", "authority", "reliable")
func _sync_response(n: String, d: Dictionary):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_response(d)


@rpc("call_remote", "authority", "reliable")
func _sync_hurt(n: String, t: float, f: String, c: int, d: int):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_hurt(t, f, c, d)


@rpc("call_remote", "authority", "reliable")
func _sync_heal(n: String, t: float, f: String, c: int, h: int):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_heal(t, f, c, h)


@rpc("call_remote", "authority", "reliable")
func _sync_energy_recovery(n: String, t: float, f: String, e: int, r: int):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_energy_recovery(t, f, e, r)


@rpc("call_remote", "authority", "reliable")
func _sync_int_change(n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: int):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_int_change(t, s, v)


@rpc("call_remote", "authority", "reliable")
func _sync_float_change(n: String, t: float, s: StatsSynchronizerComponent.TYPE, v: float):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("stats_synchronizer"):
		entity.component_list["stats_synchronizer"].sync_float_change(t, s, v)

extends Node

class_name ActionSynchronizerRPC

const COMPONENT_NAME = "ActionSynchronizerRPC"

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


func sync_attack(peer_id: int, entity_name: String, timestamp: float, direction: Vector2):
	_sync_attack.rpc_id(peer_id, entity_name, timestamp, direction)


func sync_skill_use(
	peer_id: int, entity_name: String, timestamp: float, pos: Vector2, skill: String
):
	_sync_skill_use.rpc_id(peer_id, entity_name, timestamp, pos, skill)


@rpc("call_remote", "authority", "reliable")
func _sync_attack(n: String, t: float, d: Vector2):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_attack(t, d)


@rpc("call_remote", "authority", "reliable")
func _sync_skill_use(n: String, t: float, p: Vector2, s: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("action_synchronizer"):
		entity.component_list["action_synchronizer"].sync_skill_use(t, p, s)

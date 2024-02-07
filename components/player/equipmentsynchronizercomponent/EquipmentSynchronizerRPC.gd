extends Node

# Define the class name for the script.
class_name EquipmentSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "EquipmentSynchronizerRPC"

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


func sync_equipment(entity_name: String):
	_sync_equipment.rpc_id(1, entity_name)


func sync_response(peer_id: int, entity_name: String, equipment: Dictionary):
	_sync_response.rpc_id(peer_id, entity_name, equipment)


func equip_item(peer_id: int, entity_name: String, item_uuid: String, item_class: String):
	_equip_item.rpc_id(peer_id, entity_name, item_uuid, item_class)


func unequip_item(peer_id: int, entity_name: String, item_uuid: String):
	_unequip_item.rpc_id(peer_id, entity_name, item_uuid)


func remove_equipment_item(item_uuid: String):
	_remove_equipment_item.rpc_id(1, item_uuid)


@rpc("call_remote", "any_peer", "reliable")
func _sync_equipment(n: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	# Only allow logged in players
	if not _multiplayer_connection.is_user_logged_in(id):
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EquipmentSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EquipmentSynchronizerComponent.COMPONENT_NAME].server_sync_equipment(
			id
		)


@rpc("call_remote", "authority", "reliable")
func _sync_response(n: String, e: Dictionary):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EquipmentSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EquipmentSynchronizerComponent.COMPONENT_NAME].from_json(e)


@rpc("call_remote", "authority", "reliable")
func _equip_item(n: String, u: String, c: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EquipmentSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EquipmentSynchronizerComponent.COMPONENT_NAME].client_equip_item(u, c)


@rpc("call_remote", "authority", "reliable")
func _unequip_item(n: String, u: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(EquipmentSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[EquipmentSynchronizerComponent.COMPONENT_NAME].client_unequip_item(u)


@rpc("call_remote", "any_peer", "reliable")
func _remove_equipment_item(u: String):
	if not _multiplayer_connection.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has(EquipmentSynchronizerComponent.COMPONENT_NAME):
		(
			user
			. player
			. component_list[EquipmentSynchronizerComponent.COMPONENT_NAME]
			. server_unequip_item(u)
		)

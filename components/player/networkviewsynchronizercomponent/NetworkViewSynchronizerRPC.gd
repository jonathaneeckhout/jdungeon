extends Node

# Define the class name for the script.
class_name NetworkViewSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "NetworkViewSynchronizerRPC"

enum TYPE {
	ADD_PLAYER,
	REMOVE_PLAYER,
	ADD_ENEMY,
	REMOVE_ENEMY,
	ADD_NPC,
	REMOVE_NPC,
	ADD_ITEM,
	REMOVE_ITEM,
	SYNC_BODIES_IN_VIEW
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
		TYPE.ADD_PLAYER:
			_add_player(peer_id, message[1], message[2], message[3], message[4])
		TYPE.REMOVE_PLAYER:
			_remove_player(peer_id, message[1], message[2])
		TYPE.ADD_ENEMY:
			_add_enemy(peer_id, message[1], message[2], message[3], message[4])
		TYPE.REMOVE_ENEMY:
			_remove_enemy(peer_id, message[1], message[2])
		TYPE.ADD_NPC:
			_add_npc(peer_id, message[1], message[2], message[3], message[4])
		TYPE.REMOVE_NPC:
			_remove_npc(peer_id, message[1], message[2])
		TYPE.ADD_ITEM:
			_add_item(peer_id, message[1], message[2], message[3], message[4])
		TYPE.REMOVE_ITEM:
			_remove_item(peer_id, message[1], message[2])
		TYPE.SYNC_BODIES_IN_VIEW:
			_sync_bodies_in_view(peer_id)


func add_player(
	peer_id: int,
	entity_name: String,
	target_entity_peer_id: int,
	target_entity_name: String,
	pos: Vector2
):
	# _add_player.rpc_id(peer_id, entity_name, target_entity_peer_id, target_entity_name, pos)

	_network_message_handler.send_message(
		peer_id,
		message_identifier,
		[TYPE.ADD_PLAYER, entity_name, target_entity_peer_id, target_entity_name, pos]
	)


func remove_player(peer_id: int, entity_name: String, target_entity_name: String):
	# _remove_player.rpc_id(peer_id, entity_name, target_entity_name)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.REMOVE_PLAYER, entity_name, target_entity_name]
	)


func add_enemy(
	peer_id: int, entity_name: String, enemy_name: String, enemy_class: String, pos: Vector2
):
	# _add_enemy.rpc_id(peer_id, entity_name, enemy_name, enemy_class, pos)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.ADD_ENEMY, entity_name, enemy_name, enemy_class, pos]
	)


func remove_enemy(peer_id: int, entity_name: String, enemy_name: String):
	# _remove_enemy.rpc_id(peer_id, entity_name, enemy_name)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.REMOVE_ENEMY, entity_name, enemy_name]
	)


func add_npc(peer_id: int, entity_name: String, npc_name: String, npc_class: String, pos: Vector2):
	# _add_npc.rpc_id(peer_id, entity_name, npc_name, npc_class, pos)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.ADD_NPC, entity_name, npc_name, npc_class, pos]
	)


func remove_npc(peer_id: int, entity_name: String, npc_name: String):
	# _remove_npc.rpc_id(peer_id, entity_name, npc_name)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.REMOVE_ENEMY, entity_name, npc_name]
	)


func add_item(
	peer_id: int, entity_name: String, item_name: String, item_class: String, pos: Vector2
):
	# _add_item.rpc_id(peer_id, entity_name, item_name, item_class, pos)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.ADD_ITEM, entity_name, item_name, item_class, pos]
	)


func remove_item(peer_id: int, entity_name: String, item_name: String):
	# _remove_item.rpc_id(peer_id, entity_name, item_name)

	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.REMOVE_ENEMY, entity_name, item_name]
	)


func sync_bodies_in_view():
	# _sync_bodies_in_view.rpc_id(1)

	_network_message_handler.send_message(1, message_identifier, [TYPE.SYNC_BODIES_IN_VIEW])


func _add_player(id: int, n: String, i: int, u: String, p: Vector2):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_player(i, u, p)


func _remove_player(id: int, n: String, u: String):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_player(u)


func _add_enemy(id: int, n: String, en: String, ec: String, p: Vector2):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_enemy(en, ec, p)


func _remove_enemy(id: int, n: String, en: String):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_enemy(en)


func _add_npc(id: int, n: String, nn: String, nc: String, p: Vector2):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_npc(nn, nc, p)


func _remove_npc(id: int, n: String, nn: String):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_npc(nn)


func _add_item(id: int, n: String, iu: String, ic: String, p: Vector2):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_item(iu, ic, p)


func _remove_item(id: int, n: String, iu: String):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_item(iu)


func _sync_bodies_in_view(id: int):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("networkview_synchronizer"):
		user.player.component_list["networkview_synchronizer"].sync_bodies_in_view()

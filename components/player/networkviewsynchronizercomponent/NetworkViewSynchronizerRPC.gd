extends Node

# Define the class name for the script.
class_name NetworkViewSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "NetworkViewSynchronizerRPC"

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


func add_player(
	peer_id: int,
	entity_name: String,
	target_entity_peer_id: int,
	target_entity_name: String,
	pos: Vector2
):
	_add_player.rpc_id(peer_id, entity_name, target_entity_peer_id, target_entity_name, pos)


func remove_player(peer_id: int, entity_name: String, target_entity_name: String):
	_remove_player.rpc_id(peer_id, entity_name, target_entity_name)


func add_enemy(
	peer_id: int, entity_name: String, enemy_name: String, enemy_class: String, pos: Vector2
):
	_add_enemy.rpc_id(peer_id, entity_name, enemy_name, enemy_class, pos)


func remove_enemy(peer_id: int, entity_name: String, enemy_name: String):
	_remove_enemy.rpc_id(peer_id, entity_name, enemy_name)


func add_npc(peer_id: int, entity_name: String, npc_name: String, npc_class: String, pos: Vector2):
	_add_npc.rpc_id(peer_id, entity_name, npc_name, npc_class, pos)


func remove_npc(peer_id: int, entity_name: String, npc_name: String):
	_remove_npc.rpc_id(peer_id, entity_name, npc_name)


func add_item(
	peer_id: int, entity_name: String, item_name: String, item_class: String, pos: Vector2
):
	_add_item.rpc_id(peer_id, entity_name, item_name, item_class, pos)


func remove_item(peer_id: int, entity_name: String, item_name: String):
	_remove_item.rpc_id(peer_id, entity_name, item_name)


func sync_bodies_in_view():
	_sync_bodies_in_view.rpc_id(1)


@rpc("call_remote", "authority", "reliable")
func _add_player(n: String, i: int, u: String, p: Vector2):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_player(i, u, p)


@rpc(
	"call_remote",
	"authority",
	"reliable",
)
func _remove_player(n: String, u: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_player(u)


@rpc("call_remote", "authority", "reliable")
func _add_enemy(n: String, en: String, ec: String, p: Vector2):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_enemy(en, ec, p)


@rpc("call_remote", "authority", "reliable")
func _remove_enemy(n: String, en: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_enemy(en)


@rpc("call_remote", "authority", "reliable")
func _add_npc(n: String, nn: String, nc: String, p: Vector2):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_npc(nn, nc, p)


@rpc("call_remote", "authority", "reliable")
func _remove_npc(n: String, nn: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_npc(nn)


@rpc("call_remote", "authority", "reliable")
func _add_item(n: String, iu: String, ic: String, p: Vector2):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].add_item(iu, ic, p)


@rpc("call_remote", "authority", "reliable")
func _remove_item(n: String, iu: String):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has("networkview_synchronizer"):
		entity.component_list["networkview_synchronizer"].remove_item(iu)


@rpc("call_remote", "any_peer", "reliable")
func _sync_bodies_in_view():
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	if user.player.component_list.has("networkview_synchronizer"):
		user.player.component_list["networkview_synchronizer"].sync_bodies_in_view()

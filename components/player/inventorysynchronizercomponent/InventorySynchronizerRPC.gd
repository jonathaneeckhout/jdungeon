extends Node

# Define the class name for the script.
class_name InventorySynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "InventorySynchronizerRPC"

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


func sync_inventory():
	_sync_inventory.rpc_id(1)


func sync_response(peer_id: int, inventory: Dictionary):
	_sync_response.rpc_id(peer_id, inventory)


func add_item(peer_id: int, item_uuid: String, item_class: String, amount: int):
	_add_item.rpc_id(peer_id, item_uuid, item_class, amount)


func remove_item(peer_id: int, item_uuid: String):
	_remove_item.rpc_id(peer_id, item_uuid)


func add_gold(peer_id: int, total: int, amount: int):
	_add_gold.rpc_id(peer_id, total, amount)


func remove_gold(peer_id: int, total: int, amount: int):
	_remove_gold.rpc_id(peer_id, total, amount)


func use_item(item_uuid: String):
	_use_item.rpc_id(1, item_uuid)


func drop_item(item_uuid: String):
	_drop_item.rpc_id(1, item_uuid)


@rpc("call_remote", "any_peer", "reliable")
func _sync_inventory():
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

	if user.player.component_list.has(InventorySynchronizerComponent.COMPONENT_NAME):
		(
			user
			. player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. server_sync_inventory(id)
		)


@rpc("call_remote", "authority", "reliable")
func _sync_response(i: Dictionary):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(
		InventorySynchronizerComponent.COMPONENT_NAME
	):
		(
			_multiplayer_connection
			. client_player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. from_json(i)
		)


@rpc("call_remote", "authority", "reliable")
func _add_item(u: String, c: String, a: int):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(
		InventorySynchronizerComponent.COMPONENT_NAME
	):
		(
			_multiplayer_connection
			. client_player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. client_add_item(u, c, a)
		)


@rpc("call_remote", "authority", "reliable")
func _remove_item(u: String):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(
		InventorySynchronizerComponent.COMPONENT_NAME
	):
		(
			_multiplayer_connection
			. client_player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. client_remove_item(u)
		)


@rpc("call_remote", "authority", "reliable")
func _add_gold(t: int, a: int):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(
		InventorySynchronizerComponent.COMPONENT_NAME
	):
		(
			_multiplayer_connection
			. client_player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. client_add_gold(t, a)
		)


@rpc("call_remote", "authority", "reliable")
func _remove_gold(t: int, a: int):
	if _multiplayer_connection.client_player == null:
		return

	if _multiplayer_connection.client_player.component_list.has(
		InventorySynchronizerComponent.COMPONENT_NAME
	):
		(
			_multiplayer_connection
			. client_player
			. component_list[InventorySynchronizerComponent.COMPONENT_NAME]
			. client_remove_gold(t, a)
		)


@rpc("call_remote", "any_peer", "reliable")
func _use_item(u: String):
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

	if user.player.component_list.has(InventorySynchronizerComponent.COMPONENT_NAME):
		user.player.component_list[InventorySynchronizerComponent.COMPONENT_NAME].server_use_item(u)


@rpc("call_remote", "any_peer", "reliable")
func _drop_item(u: String):
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

	if user.player.component_list.has(InventorySynchronizerComponent.COMPONENT_NAME):
		user.player.component_list[InventorySynchronizerComponent.COMPONENT_NAME].server_drop_item(
			u
		)

extends Node

# Define the class name for the script.
class_name ShopSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "ShopSynchronizerRPC"

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


func sync_shop(peer_id: int, entity_name: String, shop: Dictionary):
	_sync_shop.rpc_id(peer_id, entity_name, shop)


func buy_item(entity_name: String, item_uuid: String):
	_buy_item.rpc_id(1, entity_name, item_uuid)


@rpc("call_remote", "authority", "reliable")
func _sync_shop(n: String, s: Dictionary):
	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(ShopSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[ShopSynchronizerComponent.COMPONENT_NAME].from_json(s)


@rpc("call_remote", "any_peer", "reliable")
func _buy_item(n: String, u: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()

	var user: MultiplayerConnection.User = _multiplayer_connection.get_user_by_id(id)
	if user == null:
		return

	if not user.logged_in:
		return

	if user.player == null:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(ShopSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[ShopSynchronizerComponent.COMPONENT_NAME].server_buy_item(
			user.player, u
		)

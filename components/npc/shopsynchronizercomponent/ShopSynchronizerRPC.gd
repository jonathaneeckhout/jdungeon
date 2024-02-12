extends Node

# Define the class name for the script.
class_name ShopSynchronizerRPC

# The component name for registration in the multiplayer connection's component list.
const COMPONENT_NAME = "ShopSynchronizerRPC"

enum TYPE { SYNC_SHOP, BUY_ITEM }

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


func sync_shop(peer_id: int, entity_name: String, shop: Dictionary):
	_network_message_handler.send_message(
		peer_id, message_identifier, [TYPE.SYNC_SHOP, entity_name, shop]
	)


func buy_item(entity_name: String, item_uuid: String):
	_network_message_handler.send_message(
		1, message_identifier, [TYPE.BUY_ITEM, entity_name, item_uuid]
	)


func handle_message(peer_id: int, message: Array):
	match message[0]:
		TYPE.SYNC_SHOP:
			_sync_shop(peer_id, message[1], message[2])
		TYPE.BUY_ITEM:
			_buy_item(peer_id, message[1], message[2])


func _sync_shop(id: int, n: String, s: Dictionary):
	if id != 1:
		return

	var entity: Node = _multiplayer_connection.map.get_entity_by_name(n)

	if entity == null:
		return

	if entity.get("component_list") == null:
		return

	if entity.component_list.has(ShopSynchronizerComponent.COMPONENT_NAME):
		entity.component_list[ShopSynchronizerComponent.COMPONENT_NAME].from_json(s)


func _buy_item(id: int, n: String, u: String):
	assert(_multiplayer_connection.is_server(), "This call can only run on the server")

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

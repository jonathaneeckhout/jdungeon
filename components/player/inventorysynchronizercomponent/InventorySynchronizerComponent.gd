extends Node

class_name InventorySynchronizerComponent

signal loaded
signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

signal gold_added(total: int, amount: int)
signal gold_removed(total: int, amount: int)

const COMPONENT_NAME: String = "inventory_synchronizer"

@export var size: int = 36

var items: Array[Item] = []
var gold: int = 1000

var _target_node: Node

var _inventory_synchronizer_rpc: InventorySynchronizerRPC = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the InventorySynchronizerRPC component.
	_inventory_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		InventorySynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the InventorySynchronizerRPC component is present
	assert(_inventory_synchronizer_rpc != null, "Failed to get InventorySynchronizerRPC component")

	if _target_node.get("position") == null:
		GodotLogger.error("_target_node does not have the position variable")
		return

	if _target_node.get("peer_id") == null:
		GodotLogger.error("_target_node does not have the peer_id variable")
		return

	# Physics only needed on client side
	if _target_node.multiplayer_connection.is_own_player(_target_node):
		#Wait until the connection is ready to synchronize stats
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_inventory_synchronizer_rpc.sync_inventory()


func server_sync_inventory(peer_id: int):
	_inventory_synchronizer_rpc.sync_response(peer_id, to_json())


func server_add_item(item: Item) -> bool:
	if not _target_node.multiplayer_connection.is_server():
		return false

	if item.item_type == Item.ITEM_TYPE.CURRENCY:
		server_add_gold(item.amount)
		return true

	item.collision_layer = 0

	if items.size() >= size:
		return false

	items.append(item)

	_inventory_synchronizer_rpc.add_item(
		_target_node.peer_id, item.name, item.item_class, item.amount
	)

	return true


func client_add_item(item_uuid: String, item_class: String, amount: int):
	var item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.amount = amount
	item.collision_layer = 0

	items.append(item)

	item_added.emit(item_uuid, item_class)


func server_remove_item(item_uuid: String):
	if not _target_node.multiplayer_connection.is_server():
		return false

	var item: Item = get_item(item_uuid)
	if item != null:
		items.erase(item)
		_inventory_synchronizer_rpc.remove_item(_target_node.peer_id, item_uuid)
		return item


func client_remove_item(item_uuid: String):
	var item: Item = get_item(item_uuid)
	if item != null:
		items.erase(item)

		item_removed.emit(item_uuid)


func get_item(item_uuid: String) -> Item:
	for item in items:
		if item.uuid == item_uuid:
			return item

	return null


func server_use_item(item_uuid: String):
	if not _target_node.multiplayer_connection.is_server():
		return false

	var item: Item = get_item(item_uuid)
	if item and item.server_use(_target_node):
		server_remove_item(item_uuid)
		return true

	return false


func server_drop_item(item_uuid: String):
	if not _target_node.multiplayer_connection.is_server():
		return false

	var item = get_item(item_uuid)
	if not item:
		return

	server_remove_item(item_uuid)

	var random_x = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	var random_y = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	item.position = _target_node.position + Vector2(random_x, random_y)
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	_target_node.multiplayer_connection.map.items.add_child(item)
	item.start_expire_timer()


func server_add_gold(amount: int):
	if not _target_node.multiplayer_connection.is_server():
		return

	gold += amount
	_inventory_synchronizer_rpc.add_gold(_target_node.peer_id, gold, amount)


func client_add_gold(total: int, amount: int):
	gold = total
	gold_added.emit(total, amount)


func server_remove_gold(amount: int) -> bool:
	if not _target_node.multiplayer_connection.is_server():
		return false

	if amount <= gold:
		gold -= amount
		_inventory_synchronizer_rpc.remove_gold(_target_node.peer_id, gold, amount)
		return true

	return false


func client_remove_gold(total: int, amount: int):
	gold = total
	gold_removed.emit(total, amount)


func to_json() -> Dictionary:
	var output: Dictionary = {"gold": gold, "items": []}

	for item in items:
		output["items"].append(item.to_json())

	return output


func from_json(data: Dictionary) -> bool:
	if "gold" in data:
		gold = data["gold"]

		gold_added.emit(data["gold"], 0)
	else:
		GodotLogger.warn('Failed to load inventory from data, missing "gold" key')
		return false

	if "items" in data:
		items = []
	else:
		GodotLogger.warn('Failed to load inventory from data, missing "gold" key')
		return false

	for item_data in data["items"]:
		if not "uuid" in item_data:
			GodotLogger.warn('Failed to load inventory from data, missing "uuid" key')
			return false

		if not "item_class" in item_data:
			GodotLogger.warn('Failed to load inventory from data, missing "item_class" key')
			return false

		if not "amount" in item_data:
			GodotLogger.warn('Failed to load inventory from data, missing "amount" key')
			return false

		var item: Item = J.item_scenes[item_data["item_class"]].instantiate()
		item.from_json(item_data)
		item.collision_layer = 0

		items.append(item)

	loaded.emit()

	return true

extends Node

class_name InventorySynchronizerComponent

signal loaded
signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

signal gold_added(total: int, amount: int)
signal gold_removed(total: int, amount: int)

@export var size: int = 36

var target_node: Node

var items: Array[Item] = []
var gold: int = 1000


func _ready():
	target_node = get_parent()

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return


func add_item(item: Item) -> bool:
	if not G.is_server():
		return false

	if item.item_type == Item.ITEM_TYPE.CURRENCY:
		add_gold(item.amount)
		return true

	item.collision_layer = 0

	if items.size() >= size:
		return false

	items.append(item)

	sync_add_item.rpc_id(target_node.peer_id, item.name, item.item_class, item.amount)

	return true


func remove_item(item_uuid: String):
	if not G.is_server():
		return false

	var item: Item = get_item(item_uuid)
	if item != null:
		items.erase(item)
		sync_remove_item.rpc_id(target_node.peer_id, item_uuid)
		return item


func get_item(item_uuid: String) -> Item:
	for item in items:
		if item.uuid == item_uuid:
			return item

	return null


func use_item(item_uuid: String):
	if not G.is_server():
		return false

	var item: Item = get_item(item_uuid)
	if item and item.use(target_node):
		remove_item(item_uuid)
		return true

	return false


func add_gold(amount: int):
	if not G.is_server():
		return

	gold += amount
	sync_add_gold.rpc_id(target_node.peer_id, gold, amount)


func remove_gold(amount: int) -> bool:
	if not G.is_server():
		return false

	if amount <= gold:
		gold -= amount
		sync_remove_gold.rpc_id(target_node.peer_id, gold, amount)
		return true

	return false


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


@rpc("call_remote", "any_peer", "reliable")
func sync_inventory():
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		sync_response.rpc_id(id, to_json())


@rpc("call_remote", "authority", "reliable")
func sync_response(inventory: Dictionary):
	from_json(inventory)


@rpc("call_remote", "authority", "reliable")
func sync_add_item(item_uuid: String, item_class: String, amount: int):
	var item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.amount = amount
	item.collision_layer = 0

	items.append(item)

	item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable")
func sync_remove_item(item_uuid: String):
	var item: Item = get_item(item_uuid)
	if item != null:
		items.erase(item)

		item_removed.emit(item_uuid)


@rpc("call_remote", "authority", "reliable")
func sync_add_gold(total: int, amount: int):
	gold = total
	gold_added.emit(total, amount)


@rpc("call_remote", "authority", "reliable")
func sync_remove_gold(total: int, amount: int):
	gold = total
	gold_removed.emit(total, amount)


@rpc("call_remote", "any_peer", "reliable")
func use_inventory_item(item_uuid: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if target_node.peer_id != id:
		return

	use_item(item_uuid)


@rpc("call_remote", "any_peer", "reliable")
func drop_inventory_item(item_uuid: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if target_node.peer_id != id:
		return

	var item = get_item(item_uuid)
	if not item:
		return

	remove_item(item_uuid)

	var random_x = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	var random_y = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	item.position = target_node.position + Vector2(random_x, random_y)
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	G.world.items.add_child(item)
	item.start_expire_timer()

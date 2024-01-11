extends Node

class_name InventorySynchronizerComponent

signal loaded

signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)
signal item_amount_changed(item_uuid: String, item_class:String, new_amount: int)

signal gold_changed(total: int, changed_amount: int)

signal status_message(message: String)

const COMPONENT_NAME: String = "InventorySynchronizerComponent"

const INVENTORY_JSON_KEYS: Array[String] = ["items", "gold"]
const ITEM_JSON_KEYS: Array[String] = ["uuid", "item_class", "amount"]
const InventoryStatusMessages: Dictionary = {
	CANNOT_ADD_ITEM_INVENTORY_FULL = "The inventory has no space for that item.",
	CANNOT_ADD_ITEM_GENERIC = "You cannot take that item.",
	CANNOT_USE_ITEM = "You cannot use that item.",
}


@export var size: int = 36

var target_node: Node

var items: Array[Item] = []
var gold: int = 1000


func _ready():
	target_node = get_parent()
	
	if target_node.get("component_list") != null:
		target_node.component_list[COMPONENT_NAME] = self
	
	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return
		
	if G.is_server():
		return
		
	#Wait until the connection is ready to synchronize stats
	if not multiplayer.has_multiplayer_peer():
		await multiplayer.connected_to_server

	#Wait an additional frame so others can get set.
	await get_tree().process_frame

	#Some entities take a bit to get added to the tree, do not update them until then.
	if not is_inside_tree():
		await tree_entered
		
	G.sync_rpc.inventorysynchronizercomponent_sync_inventory.rpc_id(1, target_node.get_name())
	

## Tries to merge an item into the inventory. Items from the same class get stacked togheter.
## Returns a bool depending on wether it is successful or not.
func add_item(item: Item) -> bool:
	assert(G.is_server())
	
	#If it is currency, add its amount as gold.
	if item.item_type == Item.ITEM_TYPE.CURRENCY:
		change_gold(item.amount)
		return true

	item.collision_layer = 0

	if items.size() >= size:
		status_message.emit(InventoryStatusMessages.CANNOT_ADD_ITEM_INVENTORY_FULL)
		return false
	
	# If the item exists, add to it the amount from the item being added. The item being added will be discarded.
	var existing_item: Item = get_item_by_class(item.item_class)
	if existing_item is Item and existing_item.amount < existing_item.amount_max:
	
		# Get the total amount that the amount will end up with.
		var amount_to_add: int = item.amount + existing_item.amount
		
		# Get the overflow of the amount
		var amount_overflow: int = max(amount_to_add - existing_item.max_amount, 0)
		assert(amount_overflow >= 0)
		
		# Correct the amount to add
		amount_to_add = min(amount_to_add, existing_item.amount_max)

		# Set the amount it should have
		set_item_amount(existing_item.uuid, amount_to_add)
		assert(item.get_parent() == null, "The item should be an orphan by now.")
		
		sync_item(target_node.peer_id, existing_item.uuid)
		
		# If anything's left, add it as another item.
		if amount_overflow > 0:
			# The item's amount is reduced to the overflow amount
			item.amount = amount_overflow
			assert(item.amount > 0)
			add_item(item)
		
	else:
		items.append(item)
		assert(item.amount > 0)
		sync_item(target_node.peer_id, item.uuid)

	return true


func set_item_amount(item_uuid: String, amount: int):
	var item: Item = get_item(item_uuid)
	assert(amount >= 0, "Cannot have a negative amount of '{0}', set to 0 to remove it.".format([amount]))
	item.amount = min(amount)
	
	if item.amount <= 0:
		remove_item(item_uuid)
	
	item_amount_changed.emit(item.item_uuid, item.item_class, amount)
	sync_item(target_node.peer_id, item_uuid)
	


func remove_item(item_uuid: String):
	if not G.is_server():
		return false
	
	var item: Item = get_item(item_uuid)
	
	if item != null:
		items.erase(item)
		sync_item.rpc_id(target_node.peer_id, item_uuid, 0)
		return item


func get_item(item_uuid: String) -> Item:
	for item: Item in items:
		if item.uuid == item_uuid:
			return item
	
	GodotLogger.error(
		"Could not find an item with uuid '{0}'"
		.format([item_uuid])
		)
	return null


func get_item_by_class(item_class: String) -> Item:
	for item: Item in items:
		if item.item_class == item_class:
			return item

	return null


func use_item(item_uuid: String, amount: int = 1) -> bool:
	assert(G.is_server())
	
	var item: Item = get_item(item_uuid)
	if not item is Item:
		return false
	
	var items_used: int
	
	if item.amount < amount:
		GodotLogger.warn("Tried to use more of an item than there is available")
		return false
		
	# Attempt to use the proposed number of items
	for use_count: int in amount:
		if item and item.use(target_node):
			set_item_amount(item_uuid, item.amount - 1)
			items_used += 1
		else:
			status_message.emit(InventoryStatusMessages.CANNOT_USE_ITEM)
			break
			
	if items_used > 0:
		sync_item(target_node.peer_id, item_uuid)

	return true


func drop_item(item_uuid: String, amount: int):
	assert(G.is_server())
	var item: Item = get_item(item_uuid)
	if not item:
		return

	set_item_amount(item_uuid, item.amount - amount)

	var random_x = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	var random_y = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	item.position = target_node.position + Vector2(random_x, random_y)
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	G.world.items.add_child(item)
	item.start_expire_timer()


func set_gold(amount: int) -> bool:
	if not G.is_server():
		return false

	var previous_gold_amount: int = gold
	gold = amount
	sync_gold.rpc_id(target_node.peer_id, gold, gold - previous_gold_amount)
	return true


func change_gold(amount: int):
	if not G.is_server():
		return

	gold += amount
	sync_gold.rpc_id(target_node.peer_id, gold, amount)


func to_json() -> Dictionary:
	var output: Dictionary = {"gold": gold, "items": []}

	for item in items:
		output["items"].append(item.to_json())

	return output


func from_json(data: Dictionary) -> bool:
	for inv_key: String in INVENTORY_JSON_KEYS:
		if not inv_key in data.keys():
			GodotLogger.warn(
				"Failed to load inventory from data, missing '{0} key."
				.format([inv_key])
				)
			return false
	
	for item_key: String in ITEM_JSON_KEYS:
		if not item_key in data.get("items",[]):
			GodotLogger.warn(
				"Failed to load inventory from data, missing '{0} key for item."
				.format([item_key])
				)
			return false
			
	var gold_change: int = gold - data["gold"]
	gold = data["gold"]
	gold_changed.emit(gold, gold_change)
	
	items = []
	for item_data: Dictionary in data.get("items"):
		item_from_json(item_data)

	loaded.emit()
	return true


func sync_inventory(id: int):
	assert(G.is_server())
	G.sync_rpc.inventorysynchronizercomponent_sync_inventory_response.rpc_id(id, target_node.get_name(), to_json())


func sync_inventory_response(inventory: Dictionary):
	from_json(inventory)


func sync_item(id: int, item_uuid: String):
	assert(G.is_server())
	var item: Item = get_item(item_uuid)
	if not item is Item:
		GodotLogger.warn("There's no item with uuid '{0}' in this inventory, cannot sync.".format([item_uuid]))
		return

	G.sync_rpc.inventorysynchronizercomponent_sync_item_response.rpc_id(id, target_node.get_name(), item_to_json(item))


func sync_item_response(item_dict: Dictionary):
	item_from_json(item_dict)

func item_to_json(item: Item) -> Dictionary:
	var output: Dictionary
	
	for item_key: String in ITEM_JSON_KEYS:
		output[item_key] = item.get(item_key)
		
	return output
	
func item_from_json(data: Dictionary) -> bool:
	for item_key: String in ITEM_JSON_KEYS:
		if not item_key in data:
			GodotLogger.warn(
			"Failed to load item from data, missing '{0} key."
			.format([item_key])
			)
			return false
	
	assert(not G.is_server())
	var item_uuid: String = data["uuid"]
	var item_class: String = data["item_class"]
	var amount: int = data["amount"]
	
	var item: Item = get_item(item_uuid)
	
	# If adding an item.
	if amount > 0:
		#If the player does not have this item on their end, create it.
		if item == null:
			item = J.item_scenes[item_class].duplicate().instantiate()
			assert(item.item_class == item_class)
			
			item.uuid = item_uuid
			item.collision_layer = 0
			items.append(item)
		
		# Change the amount
		item.amount = amount
		item_added.emit(item_uuid, item_class)
	
	#If the amount is less than 1, then it is being removed
	else:
		items.erase(item)
		item_removed.emit(item_uuid)
	
	item_amount_changed.emit(item_uuid, item_class, amount)
	return true
	

func sync_gold(id: int):
	assert(G.is_server())
	G.sync_rpc.inventorysynchronizercomponent_sync_gold_response.rpc_id(id, target_node.get_name(), gold)


func sync_gold_response(amount: int):
	var change_amount: int = gold - amount
	gold = amount
	gold_changed.emit(gold, change_amount)


func client_invoke_use_item(item_uuid: String, amount: int = 1):
	assert(not G.is_server())
	G.sync_rpc.inventorysynchronizercomponent_sync_use_item.rpc_id(1, item_uuid, amount)

func client_invoke_drop_item(item_uuid: String, amount: int = 1):
	assert(not G.is_server())
	G.sync_rpc.inventorysynchronizercomponent_sync_drop_item.rpc_id(1, item_uuid, amount)

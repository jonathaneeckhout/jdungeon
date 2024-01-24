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
		
	client_invoke_sync_inventory()
	

## Tries to merge an item into the inventory. Items from the same class get stacked togheter.
## Returns a bool depending on wether it is successful or not.
func add_item(item: Item) -> bool:
	assert(G.is_server())
	if Global.debug_mode:
		GodotLogger.info("Adding item '{1}' to player '{0}'.".format([target_node.get_name(), str(item.name)]))
	
	#If it is currency, add its amount as gold.
	if item.item_type == Item.ITEM_TYPE.CURRENCY:
		change_gold(item.amount)
		if Global.debug_mode:
			GodotLogger.info("Adding {1} gold to player '{0}'.".format([target_node.get_name(), str(item.amount)]))		
		return true

	item.collision_layer = 0
	
	#Inventory full
	if items.size() >= size:
		status_message.emit(InventoryStatusMessages.CANNOT_ADD_ITEM_INVENTORY_FULL)
		if Global.debug_mode:
			GodotLogger.info("Cannot add item, inventory full.")
		return false
	
	# If the item exists, add to it the amount from the item being added. The item being added will be discarded.
	var existing_item: Item = get_item_by_class(item.item_class)
	if existing_item is Item and existing_item.amount < existing_item.amount_max:
	
		# Get the total amount that the amount will end up with.
		var amount_to_add: int = item.amount + existing_item.amount
		
		# Get the overflow of the amount
		var amount_overflow: int = max(amount_to_add - existing_item.amount_max, 0)
		assert(amount_overflow >= 0)
		
		# Correct the amount to add
		amount_to_add = amount_to_add - amount_overflow

		# Set the amount it should have
		if Global.debug_mode:
			GodotLogger.info("Stacking item '{0}' of {1} amount to player '{0}'.".format([str(item.name), str(amount_to_add)]))
			
		existing_item.amount += amount_to_add
		
		assert(item.get_parent() == null, "The item should be an orphan by now.")
		item_added.emit(item.uuid, item.item_class)
		
		if G.is_server():
			sync_item_response.rpc_id( target_node.peer_id, existing_item.to_json() )
		
		# If anything's left, add it as another item.
		if amount_overflow > 0:
			if Global.debug_mode:
				GodotLogger.info("Stack was full, allocating {0} overflown item(s).".format([str(amount_overflow)]))
			# The item's amount is reduced to the overflow amount
			item.amount = amount_overflow
			assert(item.amount > 0)
			add_item(item)
			
	#There's nothing to stack, add another item.
	else:
		items.append(item)
		item_added.emit(item.uuid, item.item_class)
		assert(item.amount > 0)
		
		if G.is_server():
			sync_item_response.rpc_id(target_node.peer_id, item.to_json())
	
	item.amount_changed.connect(on_item_amount_changed)
	
	#Failsafe
	if not get_item_by_class(item.item_class):
		GodotLogger.warn("Item was not added.")
		
	return true


func remove_item(item_uuid: String) -> Item:
	
	var item: Item = get_item(item_uuid)
	
	if item != null:
		items.erase(item)
		
		if item.amount_changed.is_connected(on_item_amount_changed):
			item.amount_changed.disconnect(on_item_amount_changed)
		
		if G.is_server():
			sync_item.rpc_id(target_node.peer_id, item_uuid, 0)
	else:
		GodotLogger.warn("The item could not be found in '{0}' this inventory.".format([target_node.get_name()]))
			
	return item
	


func get_item(item_uuid: String) -> Item:
	for item: Item in items:
		if item.uuid == item_uuid:
			return item
	
	GodotLogger.error(
		"Could not find an item with uuid '{0}' in '{1}' inventory."
		.format([item_uuid, target_node.get_name()])
		)
	return null


func has_item(item_uuid: String) -> bool:
	for item: Item in items:
		if item.uuid == item_uuid:
			return true
	return false


## Returns the first instance of an item of this class
func get_item_by_class(item_class: String) -> Item:
	for item: Item in items:
		if item.item_class == item_class:
			return item
	

	GodotLogger.warn("Could not find item of class '{0}'.".format([item_class]))
	return null


func use_item(item_uuid: String, amount: int = 1) -> bool:
	assert(G.is_server())
	
	var item: Item = get_item(item_uuid)
	if not item is Item:
		return false
	
	var items_used: int = 0
	
	if item.amount < amount:
		GodotLogger.warn("Tried to use more of an item than there is available. {0} in the stack, attempted to use {1}"
		.format([item.amount, amount]))
		return false
		
	# Attempt to use the proposed number of items
	for use_count: int in amount:
		if item and item.use(target_node):
			items_used += 1
		else:
			status_message.emit(InventoryStatusMessages.CANNOT_USE_ITEM)
			break
			
	if items_used > 0:
		sync_item_response.rpc_id( target_node.peer_id, item.to_json() )

	return true


@rpc("call_remote","any_peer","reliable")
func drop_item(item_uuid: String, amount: int):
	assert(G.is_server())
	var item: Item = get_item(item_uuid)
	if not item:
		GodotLogger.warn("Could not drop item with uuid '{0}'.".format([item_uuid]))
		return

	item.amount -= amount

	var random_x = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	var random_y = randi_range(-J.DROP_RANGE, J.DROP_RANGE)
	item.position = target_node.position + Vector2(random_x, random_y)
	item.collision_layer = J.PHYSICS_LAYER_ITEMS

	G.world.items.add_child(item)
	item.start_expire_timer()


func set_gold(amount: int) -> bool:
	assert(G.is_server())

	var previous_gold_amount: int = gold
	gold = amount
	gold_changed.emit(gold, gold - previous_gold_amount)
	sync_gold_response.rpc_id(target_node.peer_id, gold)
	return true


func change_gold(amount: int):
	assert(G.is_server())

	set_gold(gold + amount)


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
			
	# If there's items
	if not data.get("items", []).is_empty():
		for item_key: String in ITEM_JSON_KEYS:
			if not item_key in data.get("items",[]):
				GodotLogger.warn(
					"Failed to load inventory from data, missing '{0} key for item."
					.format([item_key])
					)
				return false
				
	elif Global.debug_mode:
		GodotLogger.warn("The inventory was devoid of items, is this ok? \n" + str(data))
			
	var gold_change: int = gold - data["gold"]
	gold = data["gold"]
	gold_changed.emit(gold, gold_change)
	
	for item_data: Dictionary in data.get("items"):
		Item.instance_from_json(item_data)

	loaded.emit()
	return true


@rpc("call_remote", "any_peer", "reliable")
func sync_inventory():
	assert(G.is_server())
	
	var id: int = multiplayer.get_remote_sender_id()
	
	# Only allow logged in players
	if not G.is_user_logged_in(id):
		GodotLogger.warn("Client was not logged in, cannot sync.")
		return
	
	if id == target_node.peer_id:
		sync_inventory_response.rpc_id(id, to_json())
	else:
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))


@rpc("call_remote", "authority", "reliable")
func sync_inventory_response(inventory: Dictionary):
	from_json(inventory)


@rpc("call_remote", "any_peer", "reliable")
func sync_item(item_uuid: String):
	assert(G.is_server())
	
	var id: int = multiplayer.get_remote_sender_id()
	
	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return
	
	var item: Item = get_item(item_uuid)
	
	if not item is Item:
		GodotLogger.warn("There's no item with uuid '{0}' in this inventory, cannot sync.".format([item_uuid]))
		return
		
	if id == target_node.peer_id:
		sync_item_response.rpc_id(id, item.to_json())
	else:
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))


@rpc("call_remote","authority","reliable")
func sync_item_response(item_dict: Dictionary):
	item_from_json(item_dict)


@rpc("call_remote","any_peer","reliable")
func sync_use_item(item_uuid: String, amount: int):
	assert(G.is_server())
	
	var id: int = multiplayer.get_remote_sender_id()
	
	# Only allow logged in players or the server
	if not G.is_user_logged_in(id) or id == 0:
		GodotLogger.warn("Client was not logged in, cannot sync.")
		return
		
	# Only allow clients to sync their own entity
	if id != target_node.peer_id:	
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))	
		return
	
	use_item(item_uuid, amount)


@rpc("call_remote","any_peer","reliable")
func sync_drop_item(item_uuid: String, amount: int):
	assert(G.is_server())
	
	var id: int = multiplayer.get_remote_sender_id()
	
	# Only allow logged in players or the server
	if not G.is_user_logged_in(id) or id == 0:
		GodotLogger.warn("Client was not logged in, cannot sync.")
		return
		
	# Only allow clients to sync their own entity
	if id != target_node.peer_id:	
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))	
		return
	
	drop_item(item_uuid, amount)
	

@rpc("call_remote","any_peer","reliable")
func sync_gold():
	assert(G.is_server())
	
	var id: int = multiplayer.get_remote_sender_id()
	
	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return
		
	if id == target_node.peer_id:
		sync_gold_response.rpc_id(id, gold)
	else:
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))


@rpc("call_remote","authority","reliable")
func sync_gold_response(amount: int):
	var change_amount: int = gold - amount
	gold = amount
	gold_changed.emit(gold, change_amount)


func client_invoke_sync_inventory():
	assert(not G.is_server())
	sync_inventory.rpc_id(1)


func client_invoke_use_item(item_uuid: String, amount: int = 1):
	assert(not G.is_server())
	sync_use_item.rpc_id(1, item_uuid, amount)


func client_invoke_drop_item(item_uuid: String, amount: int = 1):
	assert(not G.is_server())
	sync_drop_item.rpc_id(1, item_uuid, amount)


func on_item_amount_changed(item: Item, new_amount: int):
	assert(new_amount >= 0, "Cannot have a negative amount of '{0}', set to 0 to remove it.".format([new_amount]))
	item.amount = new_amount
	
	if item.amount <= 0:
		remove_item(item.uuid)
	
	if G.is_server():
		sync_item_response.rpc_id( target_node.peer_id, item.to_json() )
	
	item_amount_changed.emit(item.uuid, item.item_class, item.amount)
	
		

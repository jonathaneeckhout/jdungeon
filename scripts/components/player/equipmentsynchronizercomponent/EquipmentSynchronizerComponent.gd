extends Node

class_name EquipmentSynchronizerComponent

signal loaded
signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var inventory_synchronizer: InventorySynchronizerComponent

var target_node: Node

var items: Dictionary = {
	"Head": null,
	"Body": null,
	"Legs": null,
	"Arms": null,
	"RightHand": null,
	"LeftHand": null,
	"Ring1": null,
	"Ring2": null,
}

var delay_timer: Timer


func _ready():
	target_node = get_parent()

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
		
	client_invoke_sync_equipment()


@rpc("call_remote","any_peer","reliable")
func equip_item(item_uuid: String) -> bool:
	# Try to find the item
	var item: Item = inventory_synchronizer.get_item(item_uuid)
	if not item is Item:
		item = get_item(item_uuid)
		if not item is Item:
			GodotLogger.warn("Could not find item in this player's equipment nor inventory.")
	
	if items[item.equipment_slot] != null:
		unequip_item(items[item.equipment_slot].uuid)

	if _equip_item(item):
		sync_equip_item_response.rpc_id(target_node.peer_id, item.uuid, item.item_class)

		for watcher in watcher_synchronizer.watchers:
			sync_equip_item_response.rpc_id(watcher.peer_id, item.uuid, item.item_class)

		item_added.emit(item.uuid, item.item_class)

		return true

	return false


## Client and server compatible
func _equip_item(item: Item) -> bool:
	if not items.has(item.equipment_slot):
		GodotLogger.warn("Item has invalid equipment_slot=[%s]" % item.equipment_slot)
		return false

	if items[item.equipment_slot] != null:
		_unequip_item(items[item.equipment_slot].uuid)

	items[item.equipment_slot] = item

	return true

@rpc("call_remote","any_peer","reliable")
func unequip_item(item_uuid: String) -> Item:
	var item: Item = _unequip_item(item_uuid)
	if item:
		sync_unequip_item.rpc_id(target_node.peer_id, item.uuid)

		for watcher in watcher_synchronizer.watchers:
			sync_unequip_item.rpc_id(watcher.peer_id, item.uuid)

		item_removed.emit(item_uuid)

	return item


## Client and server compatible
func _unequip_item(item_uuid: String) -> Item:
	var item: Item = get_item(item_uuid)
	if item:
		items[item.equipment_slot] = null

		if target_node.get("inventory") != null:
			inventory_synchronizer.add_item(item)
		else:
			GodotLogger.warn("Player does not have a inventory, item will be lost")

	return item


func get_item(item_uuid: String) -> Item:
	for equipment_slot in items:
		var item: Item = items[equipment_slot]
		if item != null and item.uuid == item_uuid:
			return item

	return null


func get_boost() -> Boost:
	var boost: Boost = Boost.new()
	for equipment_slot in items:
		var item: Item = items[equipment_slot]
		if item != null:
			boost.add_boost(item.boost)
	return boost


func to_json() -> Dictionary:
	var output: Dictionary = {}

	for slot in items:
		if items[slot] != null:
			var item: Item = items[slot]
			output[slot] = item.to_json()

	return output


func from_json(data: Dictionary) -> bool:
	for slot in data:
		if not slot in items:
			GodotLogger.warn("Slot=[%s] does not exist in equipment items" % slot)
			return false

		var item_data: Dictionary = data[slot]
		if not "uuid" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "uuid" key')
			return false

		if not "item_class" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "item_class" key')
			return false

		if not "amount" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "amount" key')
			return false

		var item: Item = J.item_scenes[item_data["item_class"]].instantiate()
		item.from_json(item_data)
		item.collision_layer = 0

		items[slot] = item

	loaded.emit()

	return true


@rpc("call_remote", "any_peer", "reliable")
func sync_equipment():
	assert(G.is_server())

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		sync_equipment_response.rpc_id(id, to_json())
	else:
		GodotLogger.warn("A sync attempt came from a different peer than the one that owns this entity. Owned by: {0} | Called by: {1}".format([str(target_node.peer_id), id]))
	


@rpc("call_remote", "authority", "reliable")
func sync_equipment_response(equipment: Dictionary):
	from_json(equipment)


@rpc("call_remote", "authority", "reliable")
func sync_equip_item_response(item_uuid: String, item_class: String):
	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.collision_layer = 0

	if _equip_item(item):
		item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable")
func sync_unequip_item(item_uuid: String):
	if _unequip_item(item_uuid) != null:
		item_removed.emit(item_uuid)


@rpc("call_remote", "any_peer", "reliable")
func remove_equipment_item(item_uuid: String):
	assert(G.is_server())

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if target_node.peer_id != id:
		return

	unequip_item(item_uuid)
	
func client_invoke_sync_equipment():
	sync_equipment.rpc_id(1)
	
func client_invoke_equip_item(item_uuid: String):
	equip_item.rpc_id(1, item_uuid)

func client_invoke_unequip_item(item_uuid: String):
	unequip_item.rpc_id(1, item_uuid)

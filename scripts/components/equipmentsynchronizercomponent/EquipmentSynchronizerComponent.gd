extends Node

class_name EquipmentSynchronizerComponent

signal loaded
signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

@export var watcher_synchronizer: WatcherSynchronizerComponent

var target_node: Node

var items = {
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
		J.logger.error("target_node does not have the peer_id variable")
		return

	if not J.is_server():
		# This timer is needed to give the client some time to setup its multiplayer connection
		delay_timer = Timer.new()
		delay_timer.name = "DelayTimer"
		delay_timer.wait_time = 0.1
		delay_timer.autostart = true
		delay_timer.one_shot = true
		delay_timer.timeout.connect(_on_delay_timer_timeout)
		add_child(delay_timer)


func equip_item(item: Item) -> bool:
	if items[item.equipment_slot] != null:
		unequip_item(items[item.equipment_slot].uuid)

	if _equip_item(item):
		sync_equip_item.rpc_id(target_node.peer_id, item.uuid, item.item_class)

		for watcher in watcher_synchronizer.watchers:
			sync_equip_item.rpc_id(watcher.peer_id, item.uuid, item.item_class)

		item_added.emit(item.uuid, item.item_class)

		return true

	return false


func _equip_item(item: Item) -> bool:
	if not items.has(item.equipment_slot):
		J.logger.warn("Item has invalid equipment_slot=[%s]" % item.equipment_slot)
		return false

	if items[item.equipment_slot] != null:
		_unequip_item(items[item.equipment_slot].uuid)

	items[item.equipment_slot] = item

	return true


func unequip_item(item_uuid: String) -> Item:
	var item: Item = _unequip_item(item_uuid)
	if item:
		sync_unequip_item.rpc_id(target_node.peer_id, item.uuid)

		for watcher in watcher_synchronizer.watchers:
			sync_unequip_item.rpc_id(watcher.peer_id, item.uuid)

		item_removed.emit(item_uuid)

	return item


func _unequip_item(item_uuid: String) -> Item:
	var item: Item = get_item(item_uuid)
	if item:
		items[item.equipment_slot] = null

		if target_node.get("inventory") != null:
			target_node.inventory.add_item(item)
		else:
			J.logger.warn("Player does not have a inventory, item will be lost")

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
			J.logger.warn("Slot=[%s] does not exist in equipment items" % slot)
			return false

		var item_data: Dictionary = data[slot]
		if not "uuid" in item_data:
			J.logger.warn('Failed to load equipment from data, missing "uuid" key')
			return false

		if not "item_class" in item_data:
			J.logger.warn('Failed to load equipment from data, missing "item_class" key')
			return false

		if not "amount" in item_data:
			J.logger.warn('Failed to load equipment from data, missing "amount" key')
			return false

		var item: Item = J.item_scenes[item_data["item_class"]].instantiate()
		item.from_json(item_data)
		item.collision_layer = 0

		items[slot] = item

	loaded.emit()

	return true


func _on_delay_timer_timeout():
	sync_equipment.rpc_id(1)


@rpc("call_remote", "any_peer", "reliable") func sync_equipment():
	if not J.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	sync_response.rpc_id(id, to_json())


@rpc("call_remote", "authority", "reliable") func sync_response(equipment: Dictionary):
	from_json(equipment)


@rpc("call_remote", "authority", "reliable")
func sync_equip_item(item_uuid: String, item_class: String):
	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.collision_layer = 0

	if _equip_item(item):
		item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable") func sync_unequip_item(item_uuid: String):
	if _unequip_item(item_uuid) != null:
		item_removed.emit(item_uuid)


@rpc("call_remote", "any_peer", "reliable") func remove_equipment_item(item_uuid: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	if target_node.peer_id != id:
		return

	unequip_item(item_uuid)

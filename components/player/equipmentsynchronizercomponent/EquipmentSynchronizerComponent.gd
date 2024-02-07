extends Node

class_name EquipmentSynchronizerComponent

signal loaded
signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

const COMPONENT_NAME: String = "equipment_synchronizer"

@export var watcher_synchronizer: WatcherSynchronizerComponent

var _target_node: Node

var _equipment_synchronizer_rpc: EquipmentSynchronizerRPC = null

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
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the EquipmentSynchronizerRPC component.
	_equipment_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		EquipmentSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the EquipmentSynchronizerRPC component is present
	assert(_equipment_synchronizer_rpc != null, "Failed to get EquipmentSynchronizerRPC component")

	if _target_node.get("peer_id") == null:
		GodotLogger.error("_target_node does not have the peer_id variable")
		return

	# Physics only needed on client side
	if not _target_node.multiplayer_connection.is_server():
		#Wait until the connection is ready to synchronize stats
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_equipment_synchronizer_rpc.sync_equipment(_target_node.name)


func server_sync_equipment(peer_id: int):
	return _equipment_synchronizer_rpc.sync_response(peer_id, _target_node.name, to_json())


func server_equip_item(item: Item) -> bool:
	if items[item.equipment_slot] != null:
		server_unequip_item(items[item.equipment_slot].uuid)

	if _equip_item(item):
		_equipment_synchronizer_rpc.equip_item(
			_target_node.peer_id, _target_node.name, item.uuid, item.item_class
		)

		for watcher in watcher_synchronizer.watchers:
			_equipment_synchronizer_rpc.equip_item(
				watcher.peer_id, _target_node.name, item.uuid, item.item_class
			)

		item_added.emit(item.uuid, item.item_class)

		return true

	return false


func client_equip_item(item_uuid: String, item_class: String):
	var item: Item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.collision_layer = 0

	if _equip_item(item):
		item_added.emit(item_uuid, item_class)


func _equip_item(item: Item) -> bool:
	if not items.has(item.equipment_slot):
		GodotLogger.warn("Item has invalid equipment_slot=[%s]" % item.equipment_slot)
		return false

	if items[item.equipment_slot] != null:
		_unequip_item(items[item.equipment_slot].uuid)

	items[item.equipment_slot] = item

	return true


func server_unequip_item(item_uuid: String) -> Item:
	var item: Item = _unequip_item(item_uuid)
	if item:
		_equipment_synchronizer_rpc.unequip_item(_target_node.peer_id, _target_node.name, item.uuid)

		for watcher in watcher_synchronizer.watchers:
			_equipment_synchronizer_rpc.unequip_item(watcher.peer_id, _target_node.name, item.uuid)

		item_removed.emit(item_uuid)

	return item


func client_unequip_item(item_uuid: String):
	if _unequip_item(item_uuid) != null:
		item_removed.emit(item_uuid)


func _unequip_item(item_uuid: String) -> Item:
	var item: Item = get_item(item_uuid)
	if item:
		items[item.equipment_slot] = null

		if _target_node.get("inventory") != null:
			_target_node.inventory.server_add_item(item)
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
	boost.identifier = "equipment"

	for equipment_slot in items:
		var item: Item = items[equipment_slot]
		if item != null:
			boost.combine_boost(item.boost)

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

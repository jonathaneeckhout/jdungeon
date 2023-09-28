extends Node

class_name JEquipment

const SIZE = 8

signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

@export var player: JPlayerBody2D

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


func _ready():
	if J.is_server():
		J.rpcs.item.equipment_item_removed.connect(_on_equipment_item_removed)


func equip_item(item: JItem) -> bool:
	if items[item.equipment_slot] != null:
		unequip_item(items[item.equipment_slot])

	if _equip_item(item):
		sync_equip_item.rpc_id(player.peer_id, item.uuid, item.item_class)
		return true

	return false


func _equip_item(item: JItem) -> bool:
	if not items.has(item.equipment_slot):
		J.logger.warn("Item has invalid equipment_slot=[%s]" % item.equipment_slot)
		return false

	if items[item.equipment_slot] != null:
		_unequip_item(items[item.equipment_slot].uuid)

	items[item.equipment_slot] = item

	return true


func unequip_item(item_uuid: String) -> JItem:
	var item: JItem = _unequip_item(item_uuid)
	if item:
		sync_unequip_item.rpc_id(player.peer_id, item.uuid)

	return item


func _unequip_item(item_uuid: String) -> JItem:
	var item: JItem = get_item(item_uuid)
	if item:
		items[item.equipment_slot] = null

		if player.inventory:
			player.inventory.add_item(item)
		else:
			J.logger.warn("Player does not have a inventory, item will be lost")

	return item


func get_item(item_uuid: String) -> JItem:
	for equipment_slot in items:
		var item = items[equipment_slot]
		if item != null and item.uuid == item_uuid:
			return item

	return null


func _on_equipment_item_removed(id: int, item_uuid: String):
	if player.peer_id != id:
		return

	unequip_item(item_uuid)


@rpc("call_remote", "authority", "reliable")
func sync_equip_item(item_uuid: String, item_class: String):
	var item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.collision_layer = 0

	if _equip_item(item):
		item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable") func sync_unequip_item(item_uuid: String):
	if _unequip_item(item_uuid) != null:
		item_removed.emit(item_uuid)

extends Node

class_name JInventory

signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

@export var size: int = 36
@export var player: JPlayerBody2D

var items: Array[JItem] = []
var gold: int = 0


func add_item(item: JItem) -> bool:
	if items.size() >= size:
		return false

	items.append(item)

	sync_add_item.rpc_id(player.peer_id, item.name, item.item_class)

	return true


func remove_item(item_uuid: String):
	var item: JItem = get_item(item_uuid)
	if item != null:
		items.erase(item)
		sync_remove_item.rpc_id(player.peer_id, item_uuid)
		return item


func get_item(item_uuid: String) -> JItem:
	for item in items:
		if item.name == item_uuid:
			return item

	return null


@rpc("call_remote", "authority", "reliable")
func sync_add_item(item_uuid: String, item_class: String):
	item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable") func sync_remove_item(item_uuid: String):
	item_removed.emit(item_uuid)

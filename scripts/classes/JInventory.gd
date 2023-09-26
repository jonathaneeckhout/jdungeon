extends Node

class_name JInventory

signal item_added(item_uuid: String, item_class: String)
signal item_removed(item_uuid: String)

signal gold_added(total: int, amount: int)
signal gold_removed(total: int, amount: int)

@export var size: int = 36
@export var player: JPlayerBody2D

var items: Array[JItem] = []
var gold: int = 0


func add_item(item: JItem) -> bool:
	if not J.is_server():
		return false

	if item.is_gold:
		add_gold(item.amount)
		return true

	if items.size() >= size:
		return false

	items.append(item)

	sync_add_item.rpc_id(player.peer_id, item.name, item.item_class, item.amount)

	return true


func remove_item(item_uuid: String):
	if not J.is_server():
		return false

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


func add_gold(amount: int):
	if not J.is_server():
		return

	gold += amount
	sync_add_gold.rpc_id(player.peer_id, gold, amount)


func remove_gold(amount: int) -> bool:
	if not J.is_server():
		return false

	if amount <= gold:
		gold -= amount
		sync_remove_gold.rpc_id(player.peer_id, gold, amount)
		return true

	return false


@rpc("call_remote", "authority", "reliable")
func sync_add_item(item_uuid: String, item_class: String, amount: int):
	var item = J.item_scenes[item_class].instantiate()
	item.uuid = item_uuid
	item.item_class = item_class
	item.amount = amount

	items.append(item)

	item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable") func sync_remove_item(item_uuid: String):
	var item: JItem = get_item(item_uuid)
	if item != null:
		items.erase(item)

		item_removed.emit(item_uuid)


@rpc("call_remote", "authority", "reliable") func sync_add_gold(total: int, amount: int):
	gold = total
	gold_added.emit(total, amount)


@rpc("call_remote", "authority", "reliable") func sync_remove_gold(total: int, amount: int):
	gold = total
	gold_removed.emit(total, amount)

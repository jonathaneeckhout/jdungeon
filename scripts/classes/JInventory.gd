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


func _ready():
	if not J.is_server():
		gold_added.connect(_on_client_gold_added)
		gold_removed.connect(_on_client_gold_removed)


func add_item(item: JItem) -> bool:
	if item.is_gold:
		add_gold(item.amount)
		return true

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


func add_gold(amount: int):
	gold += amount
	sync_add_gold.rpc_id(player.peer_id, gold, amount)


func remove_gold(amount: int) -> bool:
	if amount <= gold:
		gold -= amount
		sync_remove_gold.rpc_id(player.peer_id, gold, amount)
		return true

	return false


func _on_client_gold_added(total: int, _amount: int):
	gold = total


func _on_client_gold_removed(total: int, _amount: int):
	gold = total


@rpc("call_remote", "authority", "reliable")
func sync_add_item(item_uuid: String, item_class: String):
	item_added.emit(item_uuid, item_class)


@rpc("call_remote", "authority", "reliable") func sync_remove_item(item_uuid: String):
	item_removed.emit(item_uuid)


@rpc("call_remote", "authority", "reliable") func sync_add_gold(total: int, amount: int):
	gold_added.emit(total, amount)


@rpc("call_remote", "authority", "reliable") func sync_remove_gold(total: int, amount: int):
	gold_removed.emit(total, amount)

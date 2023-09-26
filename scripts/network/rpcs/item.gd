extends Node

signal item_added(item_name: String, item_class: String, pos: Vector2)
signal item_removed(item_name: String)

@rpc("call_remote", "authority", "reliable")
func add_item(item_name: String, item_class: String, pos: Vector2):
	item_added.emit(item_name, item_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_item(item_name: String):
	item_removed.emit(item_name)

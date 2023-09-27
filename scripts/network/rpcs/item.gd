extends Node

signal item_added(item_uuid: String, item_class: String, pos: Vector2)
signal item_removed(item_uuid: String)

signal inventory_item_used(id: int, item_uuid: String)
signal inventory_item_dropped(id: int, item_uuid: String)

@rpc("call_remote", "authority", "reliable")
func add_item(item_uuid: String, item_class: String, pos: Vector2):
	item_added.emit(item_uuid, item_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_item(item_uuid: String):
	item_removed.emit(item_uuid)


@rpc("call_remote", "any_peer", "reliable") func use_inventory_item(item_uuid: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	inventory_item_used.emit(id, item_uuid)


@rpc("call_remote", "any_peer", "reliable") func drop_inventory_item(item_uuid: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	inventory_item_dropped.emit(id, item_uuid)

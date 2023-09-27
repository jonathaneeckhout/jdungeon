extends Node

signal npc_added(npc_name: String, npc_class: String, pos: Vector2)
signal npc_removed(npc_name: String)

signal shop_updated(vendor: String, shop: Dictionary)
signal shop_item_bought(id: int, vendor: String, item_uuid: String)

@rpc("call_remote", "authority", "reliable")
func add_npc(npc_name: String, npc_class: String, pos: Vector2):
	npc_added.emit(npc_name, npc_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_npc(npc_name: String):
	npc_removed.emit(npc_name)


@rpc("call_remote", "authority", "reliable") func sync_shop(vendor: String, shop: Dictionary):
	shop_updated.emit(vendor, shop)


@rpc("call_remote", "any_peer", "reliable") func buy_shop_item(vendor: String, item_uuid: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	shop_item_bought.emit(id, vendor, item_uuid)

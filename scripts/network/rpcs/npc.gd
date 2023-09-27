extends Node

signal npc_added(npc_name: String, npc_class: String, pos: Vector2)
signal npc_removed(npc_name: String)

signal shop_updated(vendor: String, shop: Array[Dictionary])

@rpc("call_remote", "authority", "reliable")
func add_npc(npc_name: String, npc_class: String, pos: Vector2):
	npc_added.emit(npc_name, npc_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_npc(npc_name: String):
	npc_removed.emit(npc_name)


@rpc("call_remote", "authority", "reliable") func sync_shop(vendor: String, shop: Array[Dictionary]):
	shop_updated.emit(vendor, shop)

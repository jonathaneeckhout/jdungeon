extends Node

class_name ShopSynchronizerComponent

signal shop_item_bought(player_id: int, item_uuid: String)

@export var size: int = 36

var inventory: Array[Dictionary] = []

var target_node: Node


func _ready():
	target_node = get_parent()

	if target_node.get("npc_class") == null:
		GodotLogger.error("target_node does not have the npc_class variable")
		return

	if G.is_server():
		shop_item_bought.connect(_on_shop_item_bought)


func add_item(item_class: String, price: int) -> bool:
	if inventory.size() >= size:
		GodotLogger.warn(
			"Can not add more items to %s's shop, shop is full" % target_node.npc_class
		)
		return false

	var item = {
		"uuid": J.uuid_util.v4(),
		"item_class": item_class,
		"price": price,
	}

	inventory.append(item)

	return true


func get_item(item_uuid: String):
	for item in inventory:
		if item["uuid"] == item_uuid:
			return item


func to_json() -> Dictionary:
	return {"inventory": inventory}


func from_json(data: Dictionary) -> bool:
	if not "inventory" in data:
		GodotLogger.warn('Failed to load equipment from data, missing "inventory" key')
		return false

	# Clear the current inventory
	inventory = []

	for item_data in data["inventory"]:
		if not "uuid" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "uuid" key')
			return false

		if not "item_class" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "item_class" key')
			return false

		if not "price" in item_data:
			GodotLogger.warn('Failed to load equipment from data, missing "price" key')
			return false

		inventory.append(item_data)

	return true


func open_shop(peer_id: int):
	sync_shop.rpc_id(peer_id, to_json())


func _on_shop_item_bought(player_id: int, item_uuid: String):
	var player = G.world.get_player_by_peer_id(player_id)
	if player == null:
		return

	var shop_item = get_item(item_uuid)
	if !shop_item:
		return

	if player.get("inventory") == null:
		GodotLogger.error("player does not have the inventory variable")
		return

	if player.inventory.remove_gold(shop_item["price"]):
		var new_item: Item = J.item_scenes[shop_item["item_class"]].instantiate()
		new_item.uuid = J.uuid_util.v4()
		new_item.item_class = shop_item["item_class"]

		if not player.inventory.add_item(new_item):
			player.inventory.add_gold(shop_item["price"])


@rpc("call_remote", "authority", "reliable") func sync_shop(shop: Dictionary):
	from_json(shop)

	G.shop_opened.emit(target_node.name)


@rpc("call_remote", "any_peer", "reliable") func buy_shop_item(item_uuid: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	shop_item_bought.emit(id, item_uuid)

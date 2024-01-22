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


func get_item(item_uuid: String) -> Dictionary:
	for item: Dictionary in inventory:
		if item["uuid"] == item_uuid:
			return item
			
	GodotLogger.error("Could not get item in shop.")
	return {}


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
	if Global.debug_mode:
		GodotLogger.info("Player '{0}' attempted to buy item.".format([str(player_id)]))
	
	var player: Node = G.world.get_player_by_peer_id(player_id)
	if player == null:
		GodotLogger.warn("Could not find player with id {0}.".format([str(player_id)]))
		return

	var shop_item: Dictionary = get_item(item_uuid)
	if shop_item.is_empty():
		GodotLogger.warn("Could not find item in the shop.")
		return

	if player.get("inventory") == null:
		GodotLogger.error("Player does not have the inventory property")
		return
	
	if player.inventory.gold < shop_item["price"]:
		GodotLogger.info("Refused to sell item, not enough gold on player.")
		return
	
	# Subtract the gold from the player
	player.inventory.change_gold(-shop_item["price"])
	var new_item: Item = J.item_scenes[shop_item["item_class"]].instantiate()
	new_item.uuid = J.uuid_util.v4()
	new_item.item_class = shop_item["item_class"]

	
	if not player.inventory.add_item(new_item):
		# Couldn't add the item to the player's inventory, return the gold to the player.
		GodotLogger.info("Failed to add item to the player's '{0}' inventory.".format([str(player.get_name())]))
		player.inventory.change_gold(shop_item["price"])
	
	if Global.debug_mode:
		GodotLogger.info(
			"Player '{0}' bought '{1}' for '{2}' gold"
			.format([target_node.get_name(), shop_item["item_class"], shop_item["price"]])
			)

@rpc("call_remote", "authority", "reliable")
func sync_shop(shop: Dictionary):
	from_json(shop)

	G.shop_opened.emit(target_node.name)


@rpc("call_remote", "any_peer", "reliable")
func buy_shop_item(item_uuid: String):
	if not G.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		GodotLogger.warn("Client was not logged in, cannot sync.")
		return

	shop_item_bought.emit(id, item_uuid)

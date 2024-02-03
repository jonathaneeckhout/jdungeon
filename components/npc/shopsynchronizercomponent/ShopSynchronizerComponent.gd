extends Node

class_name ShopSynchronizerComponent

const COMPONENT_NAME: String = "shop_synchronizer"

signal loaded

@export var size: int = 36

var inventory: Array[Dictionary] = []

var _target_node: Node

var _shop_synchronizer_rpc: ShopSynchronizerRPC = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the ShopSynchronizerRPC component.
	_shop_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		ShopSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the ShopSynchronizerRPC component is present
	assert(_shop_synchronizer_rpc != null, "Failed to get ShopSynchronizerRPC component")

	if _target_node.get("npc_class") == null:
		GodotLogger.error("_target_node does not have the npc_class variable")
		return


func server_add_item(item_class: String, price: int) -> bool:
	if inventory.size() >= size:
		GodotLogger.warn(
			"Can not add more items to %s's shop, shop is full" % _target_node.npc_class
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

	loaded.emit()

	return true


func server_sync_shop(peer_id: int):
	_shop_synchronizer_rpc.sync_shop(peer_id, _target_node.name, to_json())


func client_sync_shop(shop: Dictionary):
	from_json(shop)


func server_buy_item(player: Player, item_uuid: String):
	var shop_item = get_item(item_uuid)
	if !shop_item:
		return

	if player.get("inventory") == null:
		GodotLogger.error("player does not have the inventory variable")
		return

	if player.inventory.server_remove_gold(shop_item["price"]):
		var new_item: Item = J.item_scenes[shop_item["item_class"]].instantiate()
		new_item.uuid = J.uuid_util.v4()
		new_item.item_class = shop_item["item_class"]

		if not player.inventory.server_add_item(new_item):
			player.inventory.server_add_gold(shop_item["price"])

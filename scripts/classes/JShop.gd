extends Node

class_name JShop

@export var size: int = 1

var inventory: Array[Dictionary] = []

@onready var parent = $".."


func _ready():
	if J.is_server():
		J.rpcs.npc.shop_item_bought.connect(_on_shop_item_bought)


func add_item(item_class: String, price: int) -> bool:
	if inventory.size() >= size:
		J.logger.warn("Can not add more items to %s's shop, shop is full" % parent.npc_class)
		return false

	var item = {
		"uuid": J.uuid_util.v4(),
		"class": item_class,
		"price": price,
	}

	inventory.append(item)

	return true


func get_item(item_uuid: String):
	for item in inventory:
		if item["uuid"] == item_uuid:
			return item


func to_json():
	return {"inventory": inventory}


func _on_shop_item_bought(id: int, vendor: String, item_uuid: String):
	if vendor != parent.npc_class:
		return

	var player = J.world.get_player_by_peer_id(id)
	if player == null:
		return

	var shop_item = get_item(item_uuid)
	if !shop_item:
		return

	if player.inventory.remove_gold(shop_item["price"]):
		var new_item: JItem = J.item_scenes[shop_item["class"]].instantiate()
		new_item.uuid = J.uuid_util.v4()
		new_item.item_class = shop_item["class"]

		if not player.inventory.add_item(new_item):
			player.inventory.add_gold(shop_item["price"])

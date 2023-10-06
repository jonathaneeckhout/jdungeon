extends Node

class_name JPlayerPersistency


static func store_data(player: JPlayerBody2D) -> bool:
	var inventory: Dictionary = {"gold": player.inventory.gold, "items": []}
	for item in player.inventory.items:
		inventory["items"].append(
			{"uuid": item.uuid, "item_class": item.item_class, "amount": item.amount}
		)

	var data: Dictionary = {
		"position": {"x": player.position.x, "y": player.position.y},
		"hp": player.stats.hp,
		"inventory": inventory
	}

	return J.server.database.store_player_data(player.username, data)


static func load_data(player: JPlayerBody2D) -> bool:
	var data: Dictionary = J.server.database.load_player_data(player.username)

	# This function's minimal requirement is that the postion key is available in the data
	if not "position" in data:
		J.logger.debug('Invalid format of data, missing "position" key')
		return false

	if not "x" in data["position"]:
		J.logger.debug('Invalid format of data, missing "x" key')
		return false

	if not "y" in data["position"]:
		J.logger.debug('Invalid format of data, missing "y" key')
		return false

	player.position = Vector2(data["position"]["x"], data["position"]["y"])

	if "hp" in data and data["hp"] > 0:
		player.stats.hp = data["hp"]

	if "inventory" in data:
		if "gold" in data["inventory"]:
			player.inventory.gold = data["inventory"]["gold"]

		for item_data in data["inventory"]["items"]:
			if not "uuid" in item_data:
				continue

			if not "item_class" in item_data:
				continue

			if not "amount" in item_data:
				continue

			var item: JItem = J.item_scenes[item_data["item_class"]].instantiate()
			item.uuid = item_data["uuid"]
			item.item_class = item_data["item_class"]
			item.amount = item_data["amount"]
			item.collision_layer = 0

			player.inventory.items.append(item)

	return true

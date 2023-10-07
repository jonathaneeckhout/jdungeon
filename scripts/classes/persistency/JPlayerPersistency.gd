extends Node

class_name JPlayerPersistency


static func store_data(player: JPlayerBody2D) -> bool:
	var data: Dictionary = {
		"position": {"x": player.position.x, "y": player.position.y},
		"hp": player.stats.hp,
		"inventory": player.inventory.to_json(),
		"equipment": player.equipment.to_json()
	}

	return J.server.database.store_player_data(player.username, data)


static func load_data(player: JPlayerBody2D) -> bool:
	var data: Dictionary = J.server.database.load_player_data(player.username)

	# This function's minimal requirement is that the postion key is available in the data
	if not "position" in data:
		J.logger.warn('Invalid format of data, missing "position" key')
		return false

	if not "x" in data["position"]:
		J.logger.warn('Invalid format of data, missing "x" key')
		return false

	if not "y" in data["position"]:
		J.logger.warn('Invalid format of data, missing "y" key')
		return false

	player.position = Vector2(data["position"]["x"], data["position"]["y"])

	if "hp" in data and data["hp"] > 0:
		player.stats.hp = data["hp"]

	if "inventory" in data:
		if not player.inventory.from_json(data["inventory"]):
			J.log.warn("Failed to load inventory from data")
			return false

	if "equipment" in data:
		if not player.equipment.from_json(data["equipment"]):
			J.log.warn("Failed to load equipment from data")
			return false

	return true

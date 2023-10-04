extends Node

class_name JPlayerPersistency

var position: Vector2 = Vector2.ZERO


func to_json() -> Dictionary:
	var data: Dictionary = {"position": {"x": position.x, "y": position.y}}

	return data


static func from_json(json_data: Dictionary) -> JPlayerPersistency:
	if not "position" in json_data:
		J.logger.debug("Invalid format of json_data, missing position key")
		return null

	if not "x" in json_data["position"]:
		J.logger.debug("Invalid format of json_data, missing x key")
		return null

	if not "y" in json_data["position"]:
		J.logger.debug("Invalid format of json_data, missing y key")
		return null

	var data: JPlayerPersistency = JPlayerPersistency.new()
	data.position = Vector2(json_data["position"]["x"], json_data["position"]["y"])

	return data

extends Node

class_name HealhSynchronizerComponent

const COMPONENT_NAME: String = "health_synchronizer"

var _target_node: Node

@export var hp_max: int = 100

var hp: int = hp_max

var is_dead: bool = false


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self


func to_json() -> Dictionary:
	var output: Dictionary = {"hp_max": hp_max, "hp": hp}

	return output


func from_json(data: Dictionary) -> bool:
	if not "hp_max" in data:
		GodotLogger.warn('Failed to load health info from data, missing "hp_max" key')
		return false

	if not "hp" in data:
		GodotLogger.warn('Failed to load health info from data, missing "hp" key')
		return false

	hp_max = data["hp_max"]
	hp = data["hp"]

	return true

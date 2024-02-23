extends Node

class_name ClassComponent

var current_class: String = "":
	set(val):
		current_class = val
		_class_resource = _class_resources[val]

var _class_resource: ClassResource = null

var _class_resources: Dictionary = {
	"Warrior": preload("res://components/player/classcomponent/classes/WarriorClassResource.tres"),
	"Ranger": preload("res://components/player/classcomponent/classes/RangerClassResource.tres"),
	"Wizard": preload("res://components/player/classcomponent/classes/WizardClassResource.tres")
}

var _target_node: Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")


func to_json() -> Dictionary:
	var output: Dictionary = {"current_class": current_class}

	return output


func from_json(data: Dictionary) -> bool:
	if not "current_class" in data:
		GodotLogger.warn('Failed to load class info from data, missing "current_class" key')
		return false

	current_class = data["current_class"]
	return true


func get_boost() -> Boost:
	var boost: Boost = Boost.new()

	if _class_resource != null:
		boost.hp_max = _class_resource.base_hp_max
		boost.energy_max = _class_resource.base_energy_max
		boost.energy_regen = _class_resource.base_energy_regen
		boost.attack_power_min = _class_resource.base_attack_power_min
		boost.attack_power_max = _class_resource.base_attack_power_max
		boost.defense = _class_resource.base_defense
		boost.movement_speed = _class_resource.base_movement_speed

	return boost

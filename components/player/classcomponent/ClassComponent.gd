extends Node

class_name ClassComponent

enum CLASS { NONE, WARRIOR, RANGER, WIZARD }

@export var current_class: CLASS = CLASS.NONE:
	set(val):
		current_class = val
		_class_resource = _class_resources[val]

var _class_resource: ClassResource = null

var _class_resources: Dictionary = {
	CLASS.WARRIOR:
	preload("res://components/player/classcomponent/classes/WarriorClassResource.tres"),
	CLASS.RANGER:
	preload("res://components/player/classcomponent/classes/RangerClassResource.tres"),
	CLASS.WIZARD: preload("res://components/player/classcomponent/classes/WizardClassResource.tres")
}

var _target_node: Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")


static func string_to_class(class_string: String) -> CLASS:
	match class_string:
		"Warrior":
			return CLASS.WARRIOR
		"Ranger":
			return CLASS.RANGER
		"Wizard":
			return CLASS.WIZARD

	return CLASS.NONE

extends Node
class_name StatusEffectComponent

@export_group("Node References")
@export var stats_component: StatsSynchronizerComponent


var status_effects_applied: Array[StatusEffectResource]

## The format is String:Dictionary
var status_effects_active: Dictionary

func get_all_applied_classes() -> Array[String]:
	var output: Array[String] = []
	for status: StatusEffectResource in status_effects_applied:
		output.append(status.class_identifier)
	return output

func get_status_effect_applied_by_class(class_identifier: String) -> StatusEffectResource:
	for status: StatusEffectResource in status_effects_applied:
		if status.class_identifier == class_identifier:
			return status
	return null

func add_status_effect(status_identifier: String, stack_override: int = 1, duration_override: float = 1.0):
	var newStatus: StatusEffectResource = J.status_effect_resources[status_identifier].duplicate()
	newStatus.set_duration_left(duration_override).set_stacks(stack_override)
	
	# If another of this class exists, combine it.
	var currentInstance: StatusEffectResource = get_status_effect_applied_by_class(status_effect.status_class)
	if currentInstance is StatusEffectResource:
		currentInstance.combine_status(status_effect)
	
	return newStatus
	
func add_status_effect(status_effect: StatusEffectResource):


## Uses a while loop to find and remove an instance of a status effect
func remove_status_by_class(status_class: String):
	var x:int = 0
	while(x < status_effects_applied.size()):
		if status_effects_applied[x].status_class == status_class:
			status_effects_applied.remove_at(x)
			return
		x += 1

func to_json() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for status in status_effects_applied:
		var entry: Dictionary = status.to_json()
		output.append(entry)
	return output

func from_json(data: Array[Dictionary]):
	
	for dict: Dictionary in data:
		var newStatus: StatusEffectResource
		newStatus.from_json(dict)
	pass

extends Node
class_name CharacterClassComponent

@export var stats_component: StatsSynchronizerComponent

@export var classes: Array[CharacterClassResource]

##Only those here will be presented to the user, leave empty to disable
@export var class_whitelist: Array[String]

##Removes any option presented to the user that's defined here, taking precedence over [member class_whitelist]
@export var class_blacklist: Array[String]

@export var max_classes: int

func remove_class(charclass: String):
	if classes.is_empty():
		GodotLogger.warn("Tried to remove a class but there are none in this component.")
		return
	
	var index: int = 0
	while index < classes.size():
		if classes[index].class_registered == charclass:
			classes.remove_at(index)
			return


func add_class(charclass: String, bypassLimit: bool = false):
	if bypassLimit or classes.size() >= max_classes:
		GodotLogger.warn("Tried to add a class but the limit has already been reached for this component.")
		return
		
	var charClass: CharacterClassResource = J.charclass_resources[charclass].duplicate()
	classes.append(charClass)


## Applies bonuses and multipliers to the character's stats
func apply_stats():
	for charclass in classes:
		for stat in StatsSynchronizerComponent.StatListWithDefaults:
			var value: float = stats_component.get(stat) * charclass.get_multiplier(stat) + charclass.get_bonus(stat)
			stats_component.set(stat, value)

func is_full() -> bool:
	return classes.size() >= max_classes
		

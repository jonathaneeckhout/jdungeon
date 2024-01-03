extends Object
class_name Boost
## This is used to store the boosts a player may obtain. Most common sources being items and status effects.
## These are meant to be temporary and may be deleted at any time.

const NO_IDENTIFIER: String = ""

## If another boost with this identifier is present, prevent it's addition
var identifier: String = NO_IDENTIFIER

## Private. Stores an arbitrary amount of values
var stat_boost_dict: Dictionary
## Private. Stores modifiers to be applied to stats. After all flat values have been applied.
var stat_boost_modifier_dict: Dictionary

var hp_max: int = 0:
	set(val):
		stat_boost_dict["hp_max"] = val
	get:
		return stat_boost_dict.get("hp_max", 0 as int)

var hp: int = 0:
	set(val):
		stat_boost_dict["hp"] = val
	get:
		return stat_boost_dict.get("hp", 0 as int)

var attack_power_min: int = 0:
	set(val):
		stat_boost_dict["attack_power_min"] = val
	get:
		return stat_boost_dict.get("attack_power_min", 0 as int)

var attack_power_max: int = 0:
	set(val):
		stat_boost_dict["attack_power_max"] = val
	get:
		return stat_boost_dict.get("attack_power_max", 0 as int)

var defense: int = 0:
	set(val):
		stat_boost_dict["defense"] = val
	get:
		return stat_boost_dict.get("defense", 0 as int)


func combine_boost(boost: Boost):
	if Global.debug_mode:
		if boost.identifier != NO_IDENTIFIER and identifier != NO_IDENTIFIER:
			GodotLogger.info(
				(
					"Mixed 2 boosts with differing identifiers (Original '{0}' and incoming '{1}')"
					. format([identifier, boost.identifier])
				)
			)
			
	for stat: String in stat_boost_dict:
		add_stat_boost(stat, boost.get_stat_boost(stat))
		
	for stat: String in stat_boost_modifier_dict:
		add_stat_boost_modifier(stat, boost.get_stat_boost_modifier(stat))


func set_stat_boost(stat_name: String, value: int):
	stat_boost_dict[stat_name] = value


func add_stat_boost(stat_name: String, value: int):
	set_stat_boost(stat_name, get_stat_boost(stat_name) + value)


func get_stat_boost(stat_name: String, default: int = 0) -> int:
	return stat_boost_dict.get(stat_name, default)


func set_stat_boost_modifier(stat_name: String, value: float):
	stat_boost_modifier_dict[stat_name] = value


func get_stat_boost_modifier(stat_name: String, default: float = 1) -> float:
	return stat_boost_modifier_dict.get(stat_name, default)


func add_stat_boost_modifier(stat_name: String, value: float, additive: bool = false):
	if additive:
		set_stat_boost_modifier(stat_name, get_stat_boost_modifier(stat_name) + value)
	else:
		set_stat_boost_modifier(stat_name, get_stat_boost_modifier(stat_name) * value)

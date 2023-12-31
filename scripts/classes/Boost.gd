extends Object
class_name Boost
## This is used to store the boosts a player may obtain. Most common sources being items and status effects.
## These are meant to be temporary and may be deleted at any time.

const NO_IDENTIFIER: String = ""

## If another boost with this identifier is present, prevent it's addition
var identifier: String = NO_IDENTIFIER

#Stores an arbitrary amount of values
var statBoostDict: Dictionary
var statBoostModifierDict: Dictionary

var hp_max: int = 0:
	set(val):
		statBoostDict["hp_max"] = val
	get:
		return statBoostDict.get("hp_max", 0 as int)

var hp: int = 0:
	set(val):
		statBoostDict["hp"] = val
	get:
		return statBoostDict.get("hp", 0 as int)

var attack_power_min: int = 0:
	set(val):
		statBoostDict["attack_power_min"] = val
	get:
		return statBoostDict.get("attack_power_min", 0 as int)

var attack_power_max: int = 0:
	set(val):
		statBoostDict["attack_power_max"] = val
	get:
		return statBoostDict.get("attack_power_max", 0 as int)

var defense: int = 0:
	set(val):
		statBoostDict["defense"] = val
	get:
		return statBoostDict.get("defense", 0 as int)


func combine_boost(boost: Boost):
	if Global.debug_mode:
		if boost.identifier != NO_IDENTIFIER and identifier != NO_IDENTIFIER:
			GodotLogger.info(
				(
					"Mixed 2 boosts with differing identifiers (Original '{0}' and incoming '{1}')"
					. format([identifier, boost.identifier])
				)
			)
	for stat: String in statBoostDict:
		set_stat_boost(stat, boost.get_stat_boost(stat))


func set_stat_boost(statName: String, value: int):
	statBoostDict[statName] = value


func add_stat_boost(stat_name: String, value: int):
	set_stat_boost(stat_name, get_stat_boost(stat_name) + value)


func get_stat_boost(statName: String, default: int = 0) -> int:
	return statBoostDict.get(statName, default)


func set_stat_boost_modifier(stat_name: String, value: float):
	statBoostModifierDict[stat_name] = value


func get_stat_boost_modifier(stat_name: String, default: float = 1) -> float:
	return statBoostModifierDict.get(stat_name, default)


func add_stat_boost_modifier(stat_name: String, value: float, additive: bool = false):
	if additive:
		set_stat_boost_modifier(stat_name, get_stat_boost_modifier(stat_name) + value)
	else:
		set_stat_boost_modifier(stat_name, get_stat_boost_modifier(stat_name) * value)

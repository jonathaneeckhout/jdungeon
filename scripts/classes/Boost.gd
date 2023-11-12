extends Node

class_name Boost
## This node is used to store the boosts a certain item can give the player

#Stores an arbitrary amount of values
var statBoostDict: Dictionary

var hp_max: int = 0:
	set(val):
		statBoostDict["hp_max"] = val
	get:
		return statBoostDict.get("hp_max", 0)
		
var hp: int = 0:
	set(val):
		statBoostDict["hp"] = val
	get:
		return statBoostDict.get("hp", 0)
		
var attack_power_min: int = 0:
	set(val):
		statBoostDict["attack_power_min"] = val
	get:
		return statBoostDict.get("attack_power_min", 0)
		
var attack_power_max: int = 0:
	set(val):
		statBoostDict["attack_power_max"] = val
	get:
		return statBoostDict.get("attack_power_max", 0)

var defense: int = 0:
	set(val):
		statBoostDict["defense"] = val
	get:
		return statBoostDict.get("defense", 0)


func add_boost(boost: Boost):
	hp_max += boost.hp_max
	attack_power_min += boost.attack_power_min
	attack_power_max += boost.attack_power_max

	defense += boost.defense
	
func set_stat_boost(statName: String, value):
	statBoostDict[statName] = value

func get_stat_boost(statName: String, default = null):
	return statBoostDict.get(statName, default)

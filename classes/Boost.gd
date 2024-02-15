extends RefCounted

class_name Boost

var hp_max: int = 0
var hp: int = 0
var attack_power_min: int = 0
var attack_power_max: int = 0
var defense: int = 0


func add_boost(boost: Boost):
	hp_max = boost.hp_max
	hp = boost.hp
	attack_power_min = boost.attack_power_min
	attack_power_max = boost.attack_power_max
	defense = boost.defense

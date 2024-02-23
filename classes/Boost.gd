extends RefCounted

class_name Boost

var hp_max: int = 0
var hp: int = 0
var energy_max: int = 0
var energy_regen: int = 0
var attack_power_min: int = 0
var attack_power_max: int = 0
var attack_speed: float = 0.0
var attack_range: float = 0.0
var defense: int = 0
var movement_speed: float = 0.0


func add_boost(boost: Boost):
	hp_max += boost.hp_max
	hp += boost.hp
	energy_max += boost.energy_max
	energy_regen += boost.energy_regen
	attack_power_min += boost.attack_power_min
	attack_power_max += boost.attack_power_max
	attack_speed += boost.attack_speed
	attack_range += boost.attack_range
	defense += boost.defense
	movement_speed += boost.movement_speed

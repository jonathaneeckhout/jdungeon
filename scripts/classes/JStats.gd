extends Node

class_name JStats

@export var parent: JBody2D

var max_hp: int = 10
var hp: int = max_hp
var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var defense: int = 0

var movement_speed: float = 300.0

var level: int = 1
var experience: int = 0


func hurt(damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0
		parent.die()

	return reduced_damage


func reset_hp():
	hp = max_hp

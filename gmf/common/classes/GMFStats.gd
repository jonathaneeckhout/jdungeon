extends Node

class_name GMFStats

var max_hp: int = 10
var hp: int = max_hp
var attack_power_min: int = 0
var attack_power_max: int = 1
var attack_speed: float = 0.8
var defense: int = 0

var movement_speed: float = 300.0

var level: int = 1
var experience: int = 0


func hurt(damage: int):
	pass

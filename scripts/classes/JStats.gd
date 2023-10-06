extends Node

class_name JStats

signal synced

@export var parent: JBody2D

var max_hp: int = 10:
	set(new_max_hp):
		max_hp = new_max_hp
		hp = max_hp
var hp: int = max_hp
var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var attack_range: float = 64.0
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


func heal(healing: int) -> int:
	hp = min(max_hp, hp + healing)

	return healing


func reset_hp():
	hp = max_hp


func get_output() -> Dictionary:
	return {"max_hp": max_hp, "hp": hp}


@rpc("call_remote", "any_peer", "reliable") func get_sync(id: int):
	if not J.is_server():
		return

	if id in multiplayer.get_peers():
		sync.rpc_id(id, get_output())


@rpc("call_remote", "authority", "unreliable") func sync(data: Dictionary):
	max_hp = data["max_hp"]
	hp = data["hp"]

	synced.emit()

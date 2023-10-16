extends Node

class_name JStats

signal loaded
signal synced

const EXPERIENCE_PER_LEVEL_BASE:float = 100


@export var parent: JBody2D

var hp_max: int = 10:
	set(new_hp_max):
		hp_max = clamp(new_hp_max, 0, INF)
		
		hp = hp
		
var hp: int = hp_max:
	set(new_hp):
		hp = clamp(new_hp, -INF, hp_max)
		
var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var attack_range: float = 64.0
var defense: int = 0

var movement_speed: float = 300.0

var level: int = 1:
	set(newLevel):
		level = newLevel
		
var experience: int = 0

var experience_worth:int


func hp_hurt(damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if hp pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0

	return reduced_damage


func hp_heal(healing: int) -> int:
	hp = min(hp_max, hp + healing)

	return healing


func hp_reset():
	hp = hp_max


func to_json() -> Dictionary:
	return {"hp_max": hp_max, "hp": hp, "level": level, "experience": experience}


func from_json(data: Dictionary) -> bool:
	if "hp_max" not in data:
		J.logger.warn('Failed to load stats from data, missing "hp_max" key')
		return false

	if "hp" not in data:
		J.logger.warn('Failed to load stats from data, missing "hp" key')
		return false
	if "level" not in data:
		J.logger.warn('Failed to load stats from data, missing "level" key')
		return false

	if "experience" not in data:
		J.logger.warn('Failed to load stats from data, missing "experience" key')
		return false

	hp_max = data["hp_max"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	# levelUpExperienceRequired = calculate_experience_needed(level)

	loaded.emit()

	return true


#Level is based on the amount of experience the character has
func level_get_from_experience()->float:
	return experience / 100

func level_get_experience_to_next()->float:
	return fmod(experience, 100)

func level_update():
	var originalLevel:int = level
	level = level_get_from_experience()
	
	if originalLevel != level:
		parent.synchronizer.sync_level( level, level - originalLevel, level_get_experience_to_next() )

func experience_add(from: String, amount: int):
	experience += amount

	level_update()
	parent.synchronizer.sync_experience(from, experience, amount)


@rpc("call_remote", "any_peer", "reliable") func get_sync(id: int):
	if not J.is_server():
		return

	if id in multiplayer.get_peers():
		sync.rpc_id(id, to_json())


@rpc("call_remote", "authority", "unreliable") func sync(data: Dictionary):
	hp_max = data["hp_max"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	synced.emit()

extends Node

class_name JStats

signal loaded
signal synced

const BASE_EXPERIENCE = 100

@export var parent: JBody2D

var max_hp: int = 10
var hp: int = max_hp

var attack_power_min: int = 0
var attack_power_max: int = 10
var attack_speed: float = 0.8
var attack_range: float = 64.0
var defense: int = 0

var movement_speed: float = 300.0

var level: int = 1:
	set(new_level):
		level = new_level
		experience_needed = calculate_experience_needed(level)

var experience: int = 0
var experience_needed: int = BASE_EXPERIENCE
var experience_given: int = 0


func hurt(damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0

	return reduced_damage


func heal(healing: int) -> int:
	hp = min(max_hp, hp + healing)

	return healing


func reset_hp():
	hp = max_hp


func to_json() -> Dictionary:
	return {"max_hp": max_hp, "hp": hp, "level": level, "experience": experience}


func from_json(data: Dictionary) -> bool:
	if "max_hp" not in data:
		J.logger.warn('Failed to load stats from data, missing "max_hp" key')
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

	max_hp = data["max_hp"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	# experience_needed = calculate_experience_needed(level)

	loaded.emit()

	return true


func calculate_experience_needed(current_level: int):
	# TODO: Replace placeholder function to calculate experience needed to level up
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))


func add_level(amount: int):
	level += amount
	# experience_needed = calculate_experience_needed(level)
	parent.synchronizer.sync_level(level, amount, experience_needed)


func add_experience(from: String, amount: int):
	experience += amount

	while experience >= experience_needed:
		experience -= experience_needed
		add_level(1)

	parent.synchronizer.sync_experience(from, experience, amount)


@rpc("call_remote", "any_peer", "reliable") func sync_stats(id: int):
	if not J.is_server():
		return

	var caller_id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(caller_id):
		return

	if id in multiplayer.get_peers():
		sync_response.rpc_id(id, to_json())


@rpc("call_remote", "authority", "unreliable") func sync_response(data: Dictionary):
	max_hp = data["max_hp"]
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	synced.emit()

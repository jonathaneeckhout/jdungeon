extends Node

class_name JStats

enum TYPE {
	HP_MAX,
	HP,
	ATTACK_POWER_MIN,
	ATTACK_POWER_MAX,
	ATTACK_SPEED,
	ATTACK_RANGE,
	DEFENSE,
	MOVEMENT_SPEED,
	LEVEL,
	EXPERIENCE,
	EXPERIENCE_NEEDED
}

signal loaded
signal stats_changed(stat_type: TYPE)
signal gained_level

const BASE_EXPERIENCE: int = 100

@export var parent: JBody2D

var hp_max: int = 100:
	set(val):
		hp_max = val
		stats_changed.emit(TYPE.HP_MAX)

var hp: int = hp_max:
	set(val):
		hp = val
		stats_changed.emit(TYPE.HP)

var attack_power_min: int = 0:
	set(val):
		attack_power_min = val
		stats_changed.emit(TYPE.ATTACK_POWER_MIN)

var attack_power_max: int = 5:
	set(val):
		attack_power_max = val
		stats_changed.emit(TYPE.ATTACK_POWER_MAX)

var attack_speed: float = 0.8:
	set(val):
		attack_speed = val
		stats_changed.emit(TYPE.ATTACK_SPEED)

var attack_range: float = 64.0:
	set(val):
		attack_range = val
		stats_changed.emit(TYPE.ATTACK_RANGE)

var defense: int = 0:
	set(val):
		defense = val
		stats_changed.emit(TYPE.DEFENSE)

var movement_speed: float = 300.0:
	set(val):
		movement_speed = val
		stats_changed.emit(TYPE.MOVEMENT_SPEED)

var level: int = 1:
	set(val):
		level = clamp(val, 0, 100)
		experience_needed = calculate_experience_needed(level)
		gained_level.emit()
		stats_changed.emit(TYPE.LEVEL)

var experience: int = 0:
	set(val):
		experience = val
		stats_changed.emit(TYPE.EXPERIENCE)

var experience_needed: int = BASE_EXPERIENCE:
	set(val):
		experience_needed = val
		stats_changed.emit(TYPE.EXPERIENCE_NEEDED)

var experience_worth: int = 0


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
	hp = min(hp_max, hp + healing)

	return healing


func reset_hp():
	hp = hp_max


func to_json() -> Dictionary:
	return {"hp": hp, "level": level, "experience": experience}


func from_json(data: Dictionary) -> bool:
	if not "hp" in data:
		J.logger.warn('Failed to load stats from data, missing "hp" key')
		return false

	if not "level" in data:
		J.logger.warn('Failed to load stats from data, missing "level" key')
		return false

	if not "experience" in data:
		J.logger.warn('Failed to load stats from data, missing "experience" key')
		return false

	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	experience_needed = calculate_experience_needed(level)

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


func apply_boost(boost: JBoost):
	hp_max += boost.hp_max
	hp += boost.hp
	attack_power_min += boost.attack_power_min
	attack_power_max += boost.attack_power_max

	defense += boost.defense


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
	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

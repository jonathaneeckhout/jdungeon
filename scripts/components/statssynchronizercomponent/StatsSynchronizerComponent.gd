extends Node

class_name StatsSynchronizerComponent

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
	EXPERIENCE_NEEDED,
	HURT,
	HEAL
}

const BASE_EXPERIENCE: int = 100

signal loaded
signal stats_changed(stat_type: TYPE)
signal got_hurt(from: String, damage: int)
signal healed(from: String, healing: int)
signal died
signal respawned

@export var watcher_synchronizer: WatcherSynchronizerComponent

@export var hp_max: int = 100:
	set(val):
		hp_max = val
		stats_changed.emit(TYPE.HP_MAX)

@export var hp: int = hp_max:
	set(val):
		hp = val
		if hp <= 0:
			is_dead = true
			died.emit()
		else:
			if is_dead:
				respawned.emit()
			is_dead = false
		stats_changed.emit(TYPE.HP)

@export var attack_power_min: int = 0:
	set(val):
		attack_power_min = val
		stats_changed.emit(TYPE.ATTACK_POWER_MIN)

@export var attack_power_max: int = 5:
	set(val):
		attack_power_max = val
		stats_changed.emit(TYPE.ATTACK_POWER_MAX)

@export var attack_speed: float = 0.8:
	set(val):
		attack_speed = val
		stats_changed.emit(TYPE.ATTACK_SPEED)

@export var attack_range: float = 64.0:
	set(val):
		attack_range = val
		stats_changed.emit(TYPE.ATTACK_RANGE)

@export var defense: int = 0:
	set(val):
		defense = val
		stats_changed.emit(TYPE.DEFENSE)

@export var movement_speed: float = 300.0:
	set(val):
		movement_speed = val
		stats_changed.emit(TYPE.MOVEMENT_SPEED)

@export var level: int = 1:
	set(val):
		level = clamp(val, 0, 100)
		experience_needed = calculate_experience_needed(level)
		stats_changed.emit(TYPE.LEVEL)

@export var experience: int = 0:
	set(val):
		experience = val
		stats_changed.emit(TYPE.EXPERIENCE)

@export var experience_needed: int = BASE_EXPERIENCE:
	set(val):
		experience_needed = val
		stats_changed.emit(TYPE.EXPERIENCE_NEEDED)

@export var experience_worth: int = 0

var target_node: Node
var peer_id: int = 0
var is_dead: bool = false

var server_buffer: Array[Dictionary] = []
var ready_done: bool = false

var _default_hp_max: int = hp_max
var _default_attack_power_min: int = attack_power_min
var _default_attack_power_max: int = attack_power_max
var _default_defense: int = defense
var _default_movement_speed: float = movement_speed

var delay_timer: Timer


func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["stats_synchronizer"] = self

	if target_node.get("peer_id") != null:
		peer_id = target_node.peer_id

	# Physics only needed on client side
	if G.is_server():
		set_physics_process(false)
	else:
		# This timer is needed to give the client some time to setup its multiplayer connection
		delay_timer = Timer.new()
		delay_timer.name = "DelayTimer"
		delay_timer.wait_time = 0.1
		delay_timer.autostart = true
		delay_timer.one_shot = true
		delay_timer.timeout.connect(_on_delay_timer_timeout)
		add_child(delay_timer)

	ready_done = true


func _physics_process(_delta):
	check_server_buffer()


func check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry = server_buffer[i]
		if entry["timestamp"] <= G.clock:
			match entry["type"]:
				TYPE.HP_MAX:
					hp_max = entry["value"]
				TYPE.HP:
					hp = entry["value"]
				TYPE.ATTACK_POWER_MIN:
					attack_power_min = entry["value"]
				TYPE.ATTACK_POWER_MAX:
					attack_power_max = entry["value"]
				TYPE.ATTACK_SPEED:
					attack_speed = entry["value"]
				TYPE.ATTACK_RANGE:
					attack_range = entry["value"]
				TYPE.DEFENSE:
					defense = entry["value"]
				TYPE.MOVEMENT_SPEED:
					movement_speed = entry["value"]
				TYPE.LEVEL:
					level = entry["value"]
				TYPE.EXPERIENCE:
					experience = entry["value"]
				TYPE.EXPERIENCE_NEEDED:
					experience_needed = entry["value"]
				TYPE.HURT:
					hp = entry["hp"]
					got_hurt.emit(entry["from"], entry["damage"])
				TYPE.HEAL:
					hp = entry["hp"]
					healed.emit(entry["from"], entry["healing"])
			server_buffer.remove_at(i)


func hurt(from: Node, damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0
		if experience_worth > 0 and from.get("stats"):
			from.stats.add_experience(experience_worth)

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		G.sync_rpc.statssynchronizer_sync_hurt.rpc_id(
			peer_id, target_node.name, timestamp, from.name, hp, reduced_damage
		)

	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.statssynchronizer_sync_hurt.rpc_id(
			watcher.peer_id, target_node.name, timestamp, from.name, hp, reduced_damage
		)

	got_hurt.emit(from.name, reduced_damage)

	return reduced_damage


func heal(from: String, healing: int) -> int:
	hp = min(hp_max, hp + healing)

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		G.sync_rpc.statssynchronizer_sync_heal.rpc_id(
			peer_id, target_node.name, timestamp, from, hp, healing
		)

	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.statssynchronizer_sync_heal.rpc_id(
			watcher.peer_id, target_node.name, timestamp, from, hp, healing
		)

	healed.emit(from, healing)

	return healing


func reset_hp():
	hp = hp_max
	_sync_int_change(TYPE.HP, hp)


func kill():
	hp = 0
	_sync_int_change(TYPE.HP, hp)


func load_defaults():
	hp_max = _default_hp_max
	attack_power_min = _default_attack_power_min
	attack_power_max = _default_attack_power_max
	defense = _default_defense
	movement_speed = _default_movement_speed


func calculate_experience_needed(current_level: int):
	# TODO: Replace placeholder function to calculate experience needed to level up
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))


func add_level(amount: int):
	level += amount


func add_experience(amount: int):
	experience += amount

	while experience >= experience_needed:
		experience -= experience_needed
		add_level(1)


func apply_boost(boost: Boost):
	hp_max += boost.hp_max
	hp += boost.hp
	attack_power_min += boost.attack_power_min
	attack_power_max += boost.attack_power_max

	defense += boost.defense

	var data: Dictionary = to_json(true)

	if peer_id > 0:
		G.sync_rpc.statssynchronizer_sync_response.rpc_id(peer_id, target_node.name, data)

	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.statssynchronizer_sync_response.rpc_id(watcher.peer_id, target_node.name, data)


func to_json(full: bool = false) -> Dictionary:
	var data: Dictionary = {"hp": hp, "level": level, "experience": experience}
	if full:
		data.merge(
			{
				"hp_max": hp_max,
				"attack_power_min": attack_power_min,
				"attack_power_max": attack_power_max,
				"attack_speed": attack_speed,
				"attack_range": attack_range,
				"defense": defense,
				"movement_speed": movement_speed
			}
		)
	return data


func from_json(data: Dictionary, full: bool = false) -> bool:
	if not "hp" in data:
		GodotLogger.warn('Failed to load stats from data, missing "hp" key')
		return false

	if not "level" in data:
		GodotLogger.warn('Failed to load stats from data, missing "level" key')
		return false

	if not "experience" in data:
		GodotLogger.warn('Failed to load stats from data, missing "experience" key')
		return false

	if full:
		if not "hp_max" in data:
			GodotLogger.warn('Failed to load stats from data, missing "hp_max" key')
			return false

		if not "attack_power_min" in data:
			GodotLogger.warn('Failed to load stats from data, missing "attack_power_min" key')
			return false

		if not "attack_power_max" in data:
			GodotLogger.warn('Failed to load stats from data, missing "attack_power_max" key')
			return false

		if not "attack_speed" in data:
			GodotLogger.warn('Failed to load stats from data, missing "attack_speed" key')
			return false

		if not "attack_range" in data:
			GodotLogger.warn('Failed to load stats from data, missing "attack_range" key')
			return false

		if not "defense" in data:
			GodotLogger.warn('Failed to load stats from data, missing "defense" key')
			return false

		if not "movement_speed" in data:
			GodotLogger.warn('Failed to load stats from data, missing "movement_speed" key')
			return false

	hp = data["hp"]
	level = data["level"]
	experience = data["experience"]

	experience_needed = calculate_experience_needed(level)

	if full:
		hp_max = data["hp_max"]
		attack_power_min = data["attack_power_min"]
		attack_power_max = data["attack_power_max"]
		attack_speed = data["attack_speed"]
		attack_range = data["attack_range"]
		defense = data["defense"]
		movement_speed = data["movement_speed"]

	loaded.emit()

	return true


func _sync_int_change(stat_type: TYPE, value: int):
	if not ready_done:
		return

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		G.sync_rpc.statssynchronizer_sync_int_change.rpc_id(
			peer_id, target_node.name, timestamp, stat_type, value
		)

	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.statssynchronizer_sync_int_change.rpc_id(
			watcher.peer_id, target_node.name, timestamp, stat_type, value
		)


func _sync_float_change(stat_type: TYPE, value: float):
	if not ready_done:
		return

	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		G.sync_rpc.statssynchronizer_sync_float_change.rpc_id(
			peer_id, target_node.name, timestamp, stat_type, value
		)
	for watcher in watcher_synchronizer.watchers:
		G.sync_rpc.statssynchronizer_sync_float_change.rpc_id(
			watcher.peer_id, target_node.name, timestamp, stat_type, value
		)


func _on_delay_timer_timeout():
	G.sync_rpc.statssynchronizer_sync_stats.rpc_id(1, target_node.name)
	delay_timer.queue_free()


func sync_stats():
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	G.sync_rpc.statssynchronizer_sync_response.rpc_id(id, target_node.name, to_json(true))


func sync_response(data: Dictionary):
	from_json(data, true)


func sync_int_change(timestamp: float, stat_type: TYPE, value: int):
	server_buffer.append({"timestamp": timestamp, "type": stat_type, "value": value})


func sync_float_change(timestamp: float, stat_type: TYPE, value: float):
	server_buffer.append({"timestamp": timestamp, "type": stat_type, "value": value})


func sync_hurt(timestamp: float, from: String, current_hp: int, damage: int):
	server_buffer.append(
		{
			"type": TYPE.HURT,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"damage": damage
		}
	)


func sync_heal(timestamp: float, from: String, current_hp: int, healing: int):
	server_buffer.append(
		{
			"type": TYPE.HEAL,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"healing": healing
		}
	)

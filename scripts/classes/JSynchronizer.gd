extends Node2D

class_name JSynchronizer

signal attacked(target: String, damage: int)
signal got_hurt(from: String, hp: int, hp_max: int, damage: int)
signal healed(from: String, hp: int, hp_max: int, healing: int)
signal loop_animation_changed(animation: String, direction: Vector2)
signal died
signal respawned
signal experience_gained(from: String, current_exp: int, amount: int)
signal level_gained(current_level: int, amount: int, experience_needed: int)

enum SYNC_TYPES { ATTACK, HURT, HEAL, LOOP_ANIMATION, DIE, RESPAWN, EXPERIENCE }

const INTERPOLATION_OFFSET:float = 0.1
const INTERPOLATION_INDEX:int = 2

#Object that will be synchronized
@export var to_be_synced: CharacterBody2D

#Other players listening to this synchronizer
var watchers: Array[JPlayerBody2D] = []

var last_sync_timestamp: float = 0.0

var server_movement_syncs_buffer: Array[Dictionary] = []
var server_interaction_syncs_buffer: Array[Dictionary] = []


func _physics_process(_delta):
	var timestamp: float = Time.get_unix_time_from_system()

	if J.is_server():
		for watcher in watchers:
			buffer_movement_sync.rpc_id(watcher.peer_id, timestamp, to_be_synced.position, to_be_synced.velocity)
	else:
		parse_server_movement_syncs_buffer()
		parse_server_interaction_syncs_buffer()


func parse_server_movement_syncs_buffer():
	var render_time = J.client.clock - INTERPOLATION_OFFSET

	while (
		server_movement_syncs_buffer.size() > 2
		and render_time > server_movement_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		server_movement_syncs_buffer.remove_at(0)

	if server_movement_syncs_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = calculate_interpolation_factor(render_time)
		to_be_synced.position = interpolate(interpolation_factor, "position")
		to_be_synced.velocity = interpolate(interpolation_factor, "velocity")
	elif (
		server_movement_syncs_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > server_movement_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = calculate_extrapolation_factor(render_time)
		to_be_synced.position = extrapolate(extrapolation_factor, "position")
		to_be_synced.velocity = extrapolate(extrapolation_factor, "velocity")


func calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - server_movement_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				server_movement_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
				- server_movement_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return server_movement_syncs_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		server_movement_syncs_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - server_movement_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				server_movement_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- server_movement_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return server_movement_syncs_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		server_movement_syncs_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


func parse_server_interaction_syncs_buffer():
	for i in range(server_interaction_syncs_buffer.size() - 1, -1, -1):
		var entry = server_interaction_syncs_buffer[i]
		
		if entry["timestamp"] <= J.client.clock:
			match server_interaction_syncs_buffer[i]["type"]:
				SYNC_TYPES.ATTACK:
					attacked.emit(entry["target"], entry["damage"])
					
				SYNC_TYPES.HURT:
					to_be_synced.stats.stat_set(JStats.Keys.HP, entry["hp"]) 
					to_be_synced.stats.stat_set(JStats.Keys.HP, entry["hp_max"]) 
					got_hurt.emit(entry["from"], entry["hp"], entry["hp_max"], entry["damage"])
					
				SYNC_TYPES.HEAL:
					to_be_synced.stats.stat_set(JStats.Keys.HP, entry["hp"])
					to_be_synced.stats.stat_set(JStats.Keys.HP, entry["hp_max"])
					healed.emit(entry["from"], entry["hp"], entry["hp_max"], entry["healing"])
					
				SYNC_TYPES.LOOP_ANIMATION:
					loop_animation_changed.emit(entry["animation"], entry["direction"])
					
				SYNC_TYPES.DIE:
					died.emit()
					
				SYNC_TYPES.RESPAWN:
					respawned.emit()

				SYNC_TYPES.EXPERIENCE:
					to_be_synced.stats.stat_set(JStats.Keys.EXPERIENCE, entry["current_exp"])
					experience_gained.emit(entry["from"], entry["current_exp"], entry["amount"])
					
					
			server_interaction_syncs_buffer.remove_at(i)

func sync_attack(target: String, damage: int):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watchers:
		buffer_attack.rpc_id(watcher.peer_id, timestamp, target, damage)

	attacked.emit(target, damage)


func sync_hurt(from: String, hp: int, hp_max: int, damage: int):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watchers:
		buffer_hurt.rpc_id(watcher.peer_id, timestamp, from, hp, hp_max, damage)

	got_hurt.emit(from, hp, hp_max, damage)


func sync_heal(from: String, hp: int, hp_max: int, healing: int):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watchers:
		buffer_heal.rpc_id(watcher.peer_id, timestamp, from, hp, hp_max, healing)

	healed.emit(from, hp, hp_max, healing)


func sync_loop_animation(animation: String, direction: Vector2):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watchers:
		buffer_loop_animation.rpc_id(watcher.peer_id, timestamp, animation, direction)

	loop_animation_changed.emit(animation, direction)


func sync_die():
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watchers:
		buffer_die.rpc_id(watcher.peer_id, timestamp)

	died.emit()

func sync_experience(from: String, experience_original: int, experience_delta: int):
	var timestamp: float = Time.get_unix_time_from_system()
	
	for watcher in watchers:
		buffer_experience.rpc_id(watcher.peer_id, timestamp, from, experience_original, experience_delta)

	experience_gained.emit(from, experience_original, experience_delta)

func sync_respawn():
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		respawn.rpc_id(watcher.peer_id, timestamp)

	respawned.emit()


@rpc("call_remote", "authority", "unreliable")
func buffer_movement_sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < last_sync_timestamp:
		return

	last_sync_timestamp = timestamp
	server_movement_syncs_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})


@rpc("call_remote", "authority", "reliable")
func buffer_attack(timestamp: float, target: String, damage: int):
	server_interaction_syncs_buffer.append(
		{"type": SYNC_TYPES.ATTACK, "timestamp": timestamp, "target": target, "damage": damage}
	)


@rpc("call_remote", "authority", "reliable")
func buffer_hurt(timestamp: float, from: String, hp: int, hp_max: int, damage: int):
	server_interaction_syncs_buffer.append(
		{
			"type": SYNC_TYPES.HURT,
			"timestamp": timestamp,
			"from": from,
			"hp": hp,
			"hp_max": hp_max,
			"damage": damage
		}
	)


@rpc("call_remote", "authority", "reliable")
func buffer_heal(timestamp: float, from: String, hp: int, hp_max: int, healing: int):
	server_interaction_syncs_buffer.append(
		{
			"type": SYNC_TYPES.HEAL,
			"timestamp": timestamp,
			"from": from,
			"hp": hp,
			"hp_max": hp_max,
			"healing": healing
		}
	)


@rpc("call_remote", "authority", "reliable")
func buffer_loop_animation(timestamp: float, animation: String, direction: Vector2):
	server_interaction_syncs_buffer.append(
		{
			"type": SYNC_TYPES.LOOP_ANIMATION,
			"timestamp": timestamp,
			"animation": animation,
			"direction": direction
		}
	)


@rpc("call_remote", "authority", "reliable") func buffer_die(timestamp: float):
	server_interaction_syncs_buffer.append({"type": SYNC_TYPES.DIE, "timestamp": timestamp})


@rpc("call_remote", "authority", "reliable") func respawn(timestamp: float):
	# Clear the buffers to reset the inter and extrapolation
	server_interaction_syncs_buffer = []
	server_movement_syncs_buffer = []

	server_movement_syncs_buffer.append({"type": SYNC_TYPES.RESPAWN, "timestamp": timestamp})


@rpc("call_remote", "authority", "reliable")
func buffer_experience(timestamp: float, from: String, current_exp: int, amount: int):
	server_interaction_syncs_buffer.append(
		{
			"type": SYNC_TYPES.EXPERIENCE,
			"timestamp": timestamp,
			"from": from,
			"current_exp": current_exp,
			"amount": amount
		}
	)


extends Node2D

class_name JSynchronizer

signal attacked(target: String, damage: int)
signal got_hurt(from: String, hp: int, max_hp: int, damage: int)
signal loop_animation_changed(animation: String, direction: Vector2)
signal died

const INTERPOLATION_OFFSET = 0.1
const INTERPOLATION_INDEX = 2

@export var to_be_synced: CharacterBody2D

var watchers: Array[JPlayerBody2D] = []

var last_sync_timestamp: float = 0.0
var server_syncs_buffer: Array[Dictionary] = []
var attack_buffer: Array[Dictionary] = []
var hurt_buffer: Array[Dictionary] = []
var loop_animation_buffer: Array[Dictionary] = []
var die_buffer: Array[Dictionary] = []


func _physics_process(_delta):
	var timestamp = Time.get_unix_time_from_system()

	if J.is_server():
		for watcher in watchers:
			sync.rpc_id(watcher.peer_id, timestamp, to_be_synced.position, to_be_synced.velocity)
	else:
		calculate_position()
		check_if_attack()
		check_if_hurt()
		check_if_loop_animation_changed()
		check_if_die()


func calculate_position():
	var render_time = J.client.clock - INTERPOLATION_OFFSET

	while (
		server_syncs_buffer.size() > 2
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		server_syncs_buffer.remove_at(0)

	if server_syncs_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = calculate_interpolation_factor(render_time)
		to_be_synced.position = interpolate(interpolation_factor, "position")
		to_be_synced.velocity = interpolate(interpolation_factor, "velocity")
	elif (
		server_syncs_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = calculate_extrapolation_factor(render_time)
		to_be_synced.position = extrapolate(extrapolation_factor, "position")
		to_be_synced.velocity = extrapolate(extrapolation_factor, "velocity")


func calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


func sync_attack(target: String, damage: int):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		attack.rpc_id(watcher.peer_id, timestamp, target, damage)

	attacked.emit(target, damage)


func check_if_attack():
	for i in range(attack_buffer.size() - 1, -1, -1):
		if attack_buffer[i]["timestamp"] <= J.client.clock:
			attacked.emit(attack_buffer[i]["target"], attack_buffer[i]["damage"])
			attack_buffer.remove_at(i)
			return true


func sync_hurt(from: String, hp: int, max_hp: int, damage: int):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		hurt.rpc_id(watcher.peer_id, timestamp, from, hp, max_hp, damage)

	got_hurt.emit(from, hp, max_hp, damage)


func check_if_hurt():
	for i in range(hurt_buffer.size() - 1, -1, -1):
		if hurt_buffer[i]["timestamp"] <= J.client.clock:
			got_hurt.emit(
				hurt_buffer[i]["from"],
				hurt_buffer[i]["hp"],
				hurt_buffer[i]["max_hp"],
				hurt_buffer[i]["damage"]
			)
			hurt_buffer.remove_at(i)
			return true


func sync_loop_animation(animation: String, direction: Vector2):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		loop_animation.rpc_id(watcher.peer_id, timestamp, animation, direction)

	loop_animation_changed.emit(animation, direction)


func check_if_loop_animation_changed():
	for i in range(loop_animation_buffer.size() - 1, -1, -1):
		if loop_animation_buffer[i]["timestamp"] <= J.client.clock:
			loop_animation_changed.emit(
				loop_animation_buffer[i]["animation"], loop_animation_buffer[i]["direction"]
			)
			loop_animation_buffer.remove_at(i)
			return true


func sync_die():
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		die.rpc_id(watcher.peer_id, timestamp)

	died.emit()


func check_if_die():
	for i in range(die_buffer.size() - 1, -1, -1):
		if die_buffer[i]["timestamp"] <= J.client.clock:
			died.emit()
			die_buffer.remove_at(i)
			return true


@rpc("call_remote", "authority", "unreliable")
func sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < last_sync_timestamp:
		return

	last_sync_timestamp = timestamp
	server_syncs_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})


@rpc("call_remote", "authority", "reliable")
func hurt(timestamp: float, from: String, hp: int, max_hp: int, damage: int):
	hurt_buffer.append(
		{"timestamp": timestamp, "from": from, "hp": hp, "max_hp": max_hp, "damage": damage}
	)


@rpc("call_remote", "authority", "reliable")
func attack(timestamp: float, target: String, damage: int):
	attack_buffer.append({"timestamp": timestamp, "target": target, "damage": damage})


@rpc("call_remote", "authority", "reliable")
func loop_animation(timestamp: float, animation: String, direction: Vector2):
	loop_animation_buffer.append(
		{"timestamp": timestamp, "animation": animation, "direction": direction}
	)


@rpc("call_remote", "authority", "reliable") func die(timestamp: float):
	die_buffer.append({"timestamp": timestamp})

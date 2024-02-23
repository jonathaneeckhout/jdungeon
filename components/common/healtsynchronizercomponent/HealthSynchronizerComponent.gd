extends Node

class_name HealthSynchronizerComponent

signal loaded
signal got_hurt(from: String, damage: int)
signal healed(from: String, healing: int)
signal died(from: String)

const COMPONENT_NAME: String = "health_synchronizer"

enum TYPE { HURT, HEAL }

@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var combat_attribute: CombatAttributeSynchronizerComponent = null

@export var hp_max: int = 100

var hp: int = hp_max

var is_dead: bool = false

var _target_node: Node

# This value is used to check if the target node is another player
var _peer_id: int = 0

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _health_synchronizer_rpc: HealthSynchronizerRPC = null

var _server_buffer: Array[Dictionary] = []


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("peer_id") != null:
		_peer_id = _target_node.peer_id

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the HealthSynchronizerRPC component.
	_health_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		HealthSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the HealthSynchronizerRPC component is present
	assert(_health_synchronizer_rpc != null, "Failed to get HealthSynchronizerRPC component")

	got_hurt.connect(_on_got_hurt)

	if not _target_node.multiplayer_connection.is_server():
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_health_synchronizer_rpc.request_sync(_target_node.name)


func _physics_process(_delta: float):
	check_server_buffer()


func check_server_buffer():
	for i in range(_server_buffer.size() - 1, -1, -1):
		var entry: Dictionary = _server_buffer[i]

		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			assert(entry["type"] in TYPE.values(), "This is not a valid type")

			match entry["type"]:
				TYPE.HURT:
					hp = entry["hp"]
					got_hurt.emit(entry["from"], entry["damage"])
				TYPE.HEAL:
					hp = entry["hp"]
					healed.emit(entry["from"], entry["healing"])

			_server_buffer.remove_at(i)


func to_json() -> Dictionary:
	var output: Dictionary = {"hp_max": hp_max, "hp": hp}

	return output


func from_json(data: Dictionary) -> bool:
	if not "hp_max" in data:
		GodotLogger.warn('Failed to load health info from data, missing "hp_max" key')
		return false

	if not "hp" in data:
		GodotLogger.warn('Failed to load health info from data, missing "hp" key')
		return false

	hp_max = data["hp_max"]
	hp = data["hp"]

	loaded.emit()

	return true


func server_hurt(from: Node, damage: int) -> int:
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - combat_attribute.defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < hp:
		hp -= reduced_damage
	# # Die if damage is bigger than remaining hp
	else:
		hp = 0

		# TODO: fix giving exp
		# if experience_worth > 0 and from.get("stats"):
		# 	from.stats.add_experience(experience_worth)

	var timestamp: float = Time.get_unix_time_from_system()

	if _peer_id > 0:
		_health_synchronizer_rpc.sync_hurt(
			_peer_id, _target_node.name, timestamp, from.name, hp, reduced_damage
		)

	for watcher in watcher_synchronizer.watchers:
		_health_synchronizer_rpc.sync_hurt(
			watcher.peer_id, _target_node.name, timestamp, from.name, hp, reduced_damage
		)

	got_hurt.emit(from.name, reduced_damage)

	return reduced_damage


func server_heal(from: String, healing: int) -> int:
	hp = min(hp_max, hp + healing)

	var timestamp: float = Time.get_unix_time_from_system()

	if _peer_id > 0:
		_health_synchronizer_rpc.sync_heal(
			_peer_id, _target_node.name, timestamp, from, hp, healing
		)

	for watcher in watcher_synchronizer.watchers:
		_health_synchronizer_rpc.sync_heal(
			watcher.peer_id, _target_node.name, timestamp, from, hp, healing
		)

	healed.emit(from, healing)

	return healing


func server_reset_hp():
	is_dead = false
	server_heal("", hp_max)


func sync_hurt(timestamp: float, from: String, current_hp: int, damage: int):
	_server_buffer.append(
		{
			"type": TYPE.HURT,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"damage": damage
		}
	)


func sync_heal(timestamp: float, from: String, current_hp: int, healing: int):
	_server_buffer.append(
		{
			"type": TYPE.HEAL,
			"timestamp": timestamp,
			"from": from,
			"hp": current_hp,
			"healing": healing
		}
	)


func _on_got_hurt(from: String, _damage: int):
	if hp <= 0:
		is_dead = true
		died.emit(from)

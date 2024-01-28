extends Node

class_name ActionSynchronizerComponent

signal attacked(direction: Vector2)
signal skill_used(where: Vector2, skill_class: String)

@export var watcher_synchronizer: WatcherSynchronizerComponent

enum TYPE { ATTACK, SKILL_USE }

var target_node: Node

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _action_synchronizer_rpc: ActionSynchronizerRPC = null

var peer_id: int = 0

var server_buffer: Array[Dictionary] = []


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("component_list") != null:
		target_node.component_list["action_synchronizer"] = self

	# Get the ClockSynchronizer component.
	_clock_synchronizer = target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the ActionSynchronizerRPC component.
	_action_synchronizer_rpc = target_node.multiplayer_connection.component_list.get_component(
		ActionSynchronizerRPC.COMPONENT_NAME
	)

	assert(_action_synchronizer_rpc != null, "Failed to get ActionSynchronizerRPC component")

	if target_node.get("peer_id") != null:
		peer_id = target_node.peer_id


func _physics_process(_delta):
	_check_server_buffer()


func _check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry = server_buffer[i]
		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			match entry["type"]:
				TYPE.ATTACK:
					attacked.emit(entry["direction"])
				TYPE.SKILL_USE:
					skill_used.emit(entry["target_position"], entry["skill_class"])
			server_buffer.remove_at(i)


func attack(direction: Vector2):
	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_action_synchronizer_rpc.sync_attack(peer_id, target_node.name, timestamp, direction)

	for watcher in watcher_synchronizer.watchers:
		_action_synchronizer_rpc.sync_attack(
			watcher.peer_id, target_node.name, timestamp, direction
		)

	attacked.emit(direction)


func skill_use(target_global_pos: Vector2, skill_class: String):
	var timestamp: float = Time.get_unix_time_from_system()

	if peer_id > 0:
		_action_synchronizer_rpc.sync_skill_use(
			peer_id, target_node.name, timestamp, target_global_pos, skill_class
		)

	for watcher in watcher_synchronizer.watchers:
		_action_synchronizer_rpc.sync_skill_use(
			watcher.peer_id, target_node.name, timestamp, target_global_pos, skill_class
		)

	skill_used.emit(target_global_pos, skill_class)


func sync_attack(t: float, d: Vector2):
	server_buffer.append({"type": TYPE.ATTACK, "timestamp": t, "direction": d})


func sync_skill_use(timestamp: float, target_global_pos: Vector2, skill_class: String):
	server_buffer.append(
		{
			"type": TYPE.SKILL_USE,
			"timestamp": timestamp,
			"target_global_position": target_global_pos,
			"skill_class": skill_class
		}
	)

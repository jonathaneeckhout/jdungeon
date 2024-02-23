extends Node

class_name ExperienceSynchronizerComponent

signal changed
signal experience_gained(from: String, amount: int)
signal level_gained(amount: int)

const COMPONENT_NAME: String = "experience_synchronizer"

const BASE_EXPERIENCE: int = 100

enum TYPE { ADD_EXPERIENCE, ADD_LEVEL }

@export var watcher_synchronizer: WatcherSynchronizerComponent = null

var level: int = 0
var experience: int = 0
var experience_needed: int = BASE_EXPERIENCE

var _target_node: Node

var _peer_id: int = 0

var _clock_synchronizer: ClockSynchronizer = null

var _experience_synchronizer_rpc: ExperienceSynchronizerRPC = null

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

	# Get the ExperienceSynchronizerRPC component.
	_experience_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		ExperienceSynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the ExperienceSynchronizerRPC component is present
	assert(
		_experience_synchronizer_rpc != null, "Failed to get ExperienceSynchronizerRPC component"
	)

	if _target_node.multiplayer_connection.is_server():
		set_physics_process(false)

	else:
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_experience_synchronizer_rpc.request_sync(_target_node.name)


func _physics_process(_delta: float):
	check_server_buffer()


func check_server_buffer():
	for i in range(_server_buffer.size() - 1, -1, -1):
		var entry: Dictionary = _server_buffer[i]

		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			assert(entry["type"] in TYPE.values(), "This is not a valid type")

			match entry["type"]:
				TYPE.ADD_EXPERIENCE:
					experience = entry["experience"]
					experience_gained.emit(entry["from"], entry["amount"])
					changed.emit()
				TYPE.ADD_LEVEL:
					level = entry["level"]
					level_gained.emit(entry["amount"])
					changed.emit()

			_server_buffer.remove_at(i)


func to_json() -> Dictionary:
	var output: Dictionary = {"level": level, "experience": experience}

	return output


func from_json(data: Dictionary) -> bool:
	if not "level" in data:
		GodotLogger.warn('Failed to load experience info from data, missing "level" key')
		return false

	if not "experience" in data:
		GodotLogger.warn('Failed to load experience info from data, missing "experience" key')
		return false

	level = data["level"]
	experience = data["experience"]

	changed.emit()

	return true


func server_add_experience(from: String, amount: int):
	experience += amount

	var timestamp: float = Time.get_unix_time_from_system()

	if _peer_id > 0:
		_experience_synchronizer_rpc.sync_add_experience(
			_peer_id, _target_node.name, timestamp, name, experience, amount
		)

	for watcher in watcher_synchronizer.watchers:
		_experience_synchronizer_rpc.sync_add_experience(
			watcher.peer_id, _target_node.name, timestamp, name, experience, amount
		)

	experience_gained.emit(from, amount)
	changed.emit()

	while experience >= experience_needed:
		experience -= experience_needed
		server_add_level(1)


func server_add_level(amount: int):
	level += amount

	var timestamp: float = Time.get_unix_time_from_system()

	if _peer_id > 0:
		_experience_synchronizer_rpc.sync_add_level(
			_peer_id, _target_node.name, timestamp, level, amount
		)

	for watcher in watcher_synchronizer.watchers:
		_experience_synchronizer_rpc.sync_add_level(
			watcher.peer_id, _target_node.name, timestamp, level, amount
		)

	level_gained.emit(amount)
	changed.emit()


func sync_add_experience(timestamp: float, from: String, current_experience: int, amount: int):
	_server_buffer.append(
		{
			"type": TYPE.ADD_EXPERIENCE,
			"timestamp": timestamp,
			"from": from,
			"experience": current_experience,
			"amount": amount
		}
	)


func sync_add_level(timestamp: float, current_level: int, amount: int):
	_server_buffer.append(
		{"type": TYPE.ADD_LEVEL, "timestamp": timestamp, "level": current_level, "amount": amount}
	)

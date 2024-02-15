extends Node

class_name EnergySynchronizerComponent

const COMPONENT_NAME: String = "energy_synchronizer"
const ENERGY_INTERVAL_TIME: float = 1

enum TYPE { ENERGY_CONSUME, ENERGY_RECOVER }

signal energy_consumed(from: String, amount: int)
signal energy_recovered(from: String, amount: int)

@export var watcher_synchronizer: WatcherSynchronizerComponent

@export var energy_max: int = 100
@export var energy_regen: int = 10

var energy: int = energy_max

var _target_node: Node

# This value is used to check if the target node is another player
var _peer_id: int = 0

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _energy_synchronizer_rpc: EnergySynchronizerRPC = null

var _energy_regen_timer: Timer = null

var _server_buffer: Array[Dictionary] = []


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	if _target_node.get("peer_id") != null:
		_peer_id = _target_node.peer_id

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the EnergySynchronizerRPC component.
	_energy_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		EnergySynchronizerRPC.COMPONENT_NAME
	)

	# Ensure the EnergySynchronizerRPC component is present
	assert(_energy_synchronizer_rpc != null, "Failed to get EnergySynchronizerRPC component")

	if _target_node.multiplayer_connection.is_server():
		set_physics_process(false)

		_energy_regen_timer = Timer.new()
		_energy_regen_timer.name = "EnergyRegenTimer"
		_energy_regen_timer.wait_time = ENERGY_INTERVAL_TIME
		_energy_regen_timer.autostart = false
		_energy_regen_timer.timeout.connect(_on_energy_regen_timer_timeout)
		add_child(_energy_regen_timer)

	else:
		#Wait until the connection is ready to synchronize stats
		if not _target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await _target_node.multiplayer_connection.multiplayer_api.connected_to_server

		#Wait an additional frame so others can get set.
		await get_tree().process_frame

		#Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		_energy_synchronizer_rpc.request_sync(_target_node.name)


func _physics_process(_delta: float):
	check_server_buffer()


func check_server_buffer():
	for i in range(_server_buffer.size() - 1, -1, -1):
		var entry: Dictionary = _server_buffer[i]

		if entry["timestamp"] <= _clock_synchronizer.client_clock:
			assert(entry["type"] in TYPE.values(), "This is not a valid type")

			match entry["type"]:
				TYPE.ENERGY_CONSUME:
					energy = entry["energy"]
					energy_consumed.emit(entry["from"], entry["amount"])

				TYPE.ENERGY_RECOVER:
					energy = entry["energy"]
					energy_recovered.emit(entry["from"], entry["amount"])

			_server_buffer.remove_at(i)


func to_json() -> Dictionary:
	var output: Dictionary = {
		"energy_max": energy_max, "energy_regen": energy_regen, "energy": energy
	}

	return output


func from_json(data: Dictionary) -> bool:
	if not "energy_max" in data:
		GodotLogger.warn('Failed to load energy info from data, missing "energy_max" key')
		return false

	if not "energy_regen" in data:
		GodotLogger.warn('Failed to load energy info from data, missing "energy_regen" key')
		return false

	if not "energy" in data:
		GodotLogger.warn('Failed to load energy info from data, missing "energy" key')
		return false

	energy_max = data["energy_max"]
	energy_regen = data["energy_regen"]
	energy = data["energy"]

	return true


func recover(from: String, amount: int) -> int:
	energy = min(energy_max, energy + amount)

	var timestamp: float = Time.get_unix_time_from_system()

	if _peer_id > 0:
		_energy_synchronizer_rpc.sync_energy_recovery(
			_peer_id, _target_node.name, timestamp, from, energy, amount
		)

	for watcher in watcher_synchronizer.watchers:
		_energy_synchronizer_rpc.sync_energy_recovery(
			watcher.peer_id, _target_node.name, timestamp, from, energy, amount
		)

	energy_recovered.emit(from, amount)

	return amount


func sync_energy_consume(timestamp: float, from: String, current_energy: int, amount: int):
	_server_buffer.append(
		{
			"type": TYPE.ENERGY_CONSUME,
			"timestamp": timestamp,
			"from": from,
			"energy": current_energy,
			"amount": amount
		}
	)


func sync_energy_recover(timestamp: float, from: String, current_energy: int, amount: int):
	_server_buffer.append(
		{
			"type": TYPE.ENERGY_RECOVER,
			"timestamp": timestamp,
			"from": from,
			"energy": current_energy,
			"amount": amount
		}
	)


func _on_energy_regen_timer_timeout():
	if energy != energy_max:
		recover(_target_node.get_name(), energy_regen)

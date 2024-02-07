extends Node2D
class_name PositionSynchronizerComponent

const INTERPOLATION_OFFSET: float = 0.1
const INTERPOLATION_INDEX: float = 2

@export var watcher_synchronizer: WatcherSynchronizerComponent

var _target_node: Node

# Reference to the ClockSynchronizer component for timestamp synchronization.
var _clock_synchronizer: ClockSynchronizer = null

var _position_synchronizer_rpc: PositionSynchronizerRPC = null

# Buffer which keeps track of all the sync information received from the server
var _server_buffer: Array[Dictionary] = []

# The timestamp of the last received sync message from the server
var _last_sync_timestamp: float = 0.0


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list["position_synchronizer"] = self

	# Get the ClockSynchronizer component.
	_clock_synchronizer = _target_node.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	# Get the PositionSynchronizerRPC component.
	_position_synchronizer_rpc = _target_node.multiplayer_connection.component_list.get_component(
		PositionSynchronizerRPC.COMPONENT_NAME
	)

	assert(_position_synchronizer_rpc != null, "Failed to get PositionSynchronizerRPC component")

	if _target_node.get("position") == null:
		GodotLogger.error("_target_node does not have the position variable")
		return


func _physics_process(_delta):
	# Handle server-side code
	if _target_node.multiplayer_connection.is_server():
		var timestamp: float = Time.get_unix_time_from_system()

		# Sync your position to every entity that is watching you
		for watcher in watcher_synchronizer.watchers:
			_position_synchronizer_rpc.sync_position(
				watcher.peer_id, _target_node.name, timestamp, _target_node.position
			)
	# Handle client-side code
	else:
		# Calculate the postion for the client
		_calculate_position()


func _calculate_position():
	# Calculate the time of the player will actually see the entity
	var render_time = _clock_synchronizer.client_clock - INTERPOLATION_OFFSET

	# Remove older messages out of the interpolation range
	while (
		_server_buffer.size() > 2 and render_time > _server_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		_server_buffer.remove_at(0)

	# If you have enough recent sync messages, interpolate to get smooth movement visualization
	if _server_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = _calculate_interpolation_factor(render_time)
		_target_node.position = _interpolate(interpolation_factor, "position")
	# If you don't have enough recent sync messages, extrapolate to get smooth movement visualization
	elif (
		_server_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = _calculate_extrapolation_factor(render_time)
		_target_node.position = _extrapolate(extrapolation_factor, "position")


func _calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				_server_buffer[INTERPOLATION_INDEX]["timestamp"]
				- _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func _interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return _server_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		_server_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func _calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - _server_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				_server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- _server_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func _extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return _server_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		_server_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


## This function stores the latest received sync information for this entity. This information is later used to smoothly inter or extrapolate the position of the entity.
func client_sync_position(timestamp: float, pos: Vector2):
	# Ignore older syncs
	if timestamp < _last_sync_timestamp:
		return

	_last_sync_timestamp = timestamp
	_server_buffer.append({"timestamp": timestamp, "position": pos})

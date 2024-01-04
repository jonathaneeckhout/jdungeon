extends Node2D
class_name PositionSynchronizerComponent

const INTERPOLATION_OFFSET: float = 0.1
const INTERPOLATION_INDEX: float = 2

## Constant indication how long the position should be stored in the position buffer
const POSITION_BUFFER_TIME_WINDOW: float = 1.0

@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var network_visible_area_size: float = 32.0

var _target_node: Node

# Buffer which keeps track of all the sync information received from the server
var _server_buffer: Array[Dictionary] = []

# The timestamp of the last received sync message from the server
var _last_sync_timestamp: float = 0.0

## Buffer that stores the previous positions of the entity. Used to later do lag compensation.
var _position_buffer: Array[Dictionary] = []


func _ready():
	_target_node = get_parent()

	if _target_node.get("component_list") != null:
		_target_node.component_list["position_synchronizer"] = self

	if _target_node.get("position") == null:
		GodotLogger.error("_target_node does not have the position variable")
		return

	if _target_node.get("velocity") == null:
		GodotLogger.error("_target_node does not have the velocity variable")
		return


func _physics_process(_delta):
	# Handle server-side code
	if G.is_server():
		var timestamp: float = Time.get_unix_time_from_system()

		# Store the position of the target_node for later lag compensation
		_handle_position_buffering(timestamp)

		# Sync your position to every entity that is watching you
		for watcher in watcher_synchronizer.watchers:
			G.sync_rpc.positionsynchronizer_sync.rpc_id(
				watcher.peer_id,
				_target_node.name,
				timestamp,
				_target_node.position,
				_target_node.velocity
			)
	# Handle client-side code
	else:
		# Calculate the postion for the client
		_calculate_position()


func _handle_position_buffering(timestamp: float):
	# Calculate the time threshold. Positions older than this should be removed
	var threshold_timestamp: float = timestamp - POSITION_BUFFER_TIME_WINDOW

	# Remove the older positions
	while _position_buffer.size() > 1 and _position_buffer[0]["t"] < threshold_timestamp:
		_position_buffer.remove_at(0)

	# Add the latest position with its timestamp to the buffer
	_position_buffer.append({"t": timestamp, "p": _target_node.position})


func _calculate_position():
	# Calculate the time of the player will actually see the entity
	var render_time = G.clock - INTERPOLATION_OFFSET

	# Remove older messages out of the interpolation range
	while (
		_server_buffer.size() > 2 and render_time > _server_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		_server_buffer.remove_at(0)

	# If you have enough recent sync messages, interpolate to get smooth movement visualization
	if _server_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = _calculate_interpolation_factor(render_time)
		_target_node.position = _interpolate(interpolation_factor, "position")
		_target_node.velocity = _interpolate(interpolation_factor, "velocity")

	# If you don't have enough recent sync messages, extrapolate to get smooth movement visualization
	elif (
		_server_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > _server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = _calculate_extrapolation_factor(render_time)
		_target_node.position = _extrapolate(extrapolation_factor, "position")
		_target_node.velocity = _extrapolate(extrapolation_factor, "velocity")


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


func is_colliding_with_circle(timestamp: float, pos: Vector2, radius: float) -> bool:
	var target_timestamp: float = timestamp - INTERPOLATION_OFFSET
	var target_pos: Vector2 = get_position_closest_to_timestamp(target_timestamp)

	return target_pos.distance_to(pos) < radius


func get_position_closest_to_timestamp(timestamp: float) -> Vector2:
	var closest_pos: Vector2 = _target_node.position
	var diff: float = Time.get_unix_time_from_system() - timestamp

	for pos in _position_buffer:
		var new_diff: float = absf(pos["t"] - timestamp)
		if new_diff < diff:
			closest_pos = pos["p"]
			diff = new_diff
		else:
			break

	return closest_pos


## This function stores the latest received sync information for this entity. This information is later used to smoothly inter or extrapolate the position of the entity.
func sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < _last_sync_timestamp:
		return

	_last_sync_timestamp = timestamp
	_server_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})

extends Node2D
class_name PositionSynchronizerComponent

const INTERPOLATION_OFFSET: float = 0.1
const INTERPOLATION_INDEX: float = 2

@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var network_visible_area_size: float = 32.0

var target_node: Node

var server_buffer: Array[Dictionary] = []
var last_sync_timestamp: float = 0.0


func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["position_synchronizer"] = self

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the velocity variable")
		return


func _physics_process(_delta):
	var timestamp: float = Time.get_unix_time_from_system()

	if G.is_server():
		for watcher in watcher_synchronizer.watchers:
			G.sync_rpc.positionsynchronizer_sync.rpc_id(
				watcher.peer_id,
				target_node.name,
				timestamp,
				target_node.position,
				target_node.velocity
			)
	else:
		calculate_position()


func calculate_position():
	var render_time = G.clock - INTERPOLATION_OFFSET

	while (
		server_buffer.size() > 2 and render_time > server_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		server_buffer.remove_at(0)

	if server_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = calculate_interpolation_factor(render_time)
		target_node.position = interpolate(interpolation_factor, "position")
		target_node.velocity = interpolate(interpolation_factor, "velocity")
	elif (
		server_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = calculate_extrapolation_factor(render_time)
		target_node.position = extrapolate(extrapolation_factor, "position")
		target_node.velocity = extrapolate(extrapolation_factor, "velocity")


func calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - server_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				server_buffer[INTERPOLATION_INDEX]["timestamp"]
				- server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return server_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		server_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - server_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				server_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- server_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return server_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		server_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


func sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < last_sync_timestamp:
		return

	last_sync_timestamp = timestamp
	server_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})

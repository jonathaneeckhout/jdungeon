extends Node

class_name ClockRPC

const LATENCY_BUFFER_SIZE = 9
const LATENCY_BUFFER_MID_POINT = int(LATENCY_BUFFER_SIZE / float(2))
const LATENCY_MINIMUM_THRESHOLD = 20

var latency: float = 0.0
var latency_buffer = []
var delta_latency: float = 0.0

## Network metrics
var metrics: Dictionary = {}


func _ready():
	# Disable physics process for the server
	set_physics_process(not G.is_server())

	if Global.env_network_profiling:
		metrics["fetch_server_time"] = 0
		metrics["return_server_time"] = 0
		metrics["get_latency"] = 0
		metrics["return_latency"] = 0


func _physics_process(delta):
	G.clock += delta + delta_latency
	delta_latency = 0


@rpc("call_remote", "any_peer", "reliable")
func fetch_server_time(client_time: float):
	if Global.env_network_profiling:
		metrics["fetch_server_time"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()
	return_server_time.rpc_id(id, Time.get_unix_time_from_system(), client_time)


@rpc("call_remote", "authority", "reliable")
func return_server_time(server_time: float, client_time: float):
	if Global.env_network_profiling:
		metrics["return_server_time"] += 1

	latency = (Time.get_unix_time_from_system() - client_time) / 2
	G.clock = server_time + latency


@rpc("call_remote", "any_peer", "reliable")
func get_latency(client_time: float):
	if Global.env_network_profiling:
		metrics["get_latency"] += 1

	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()
	return_latency.rpc_id(id, client_time)


@rpc("call_remote", "authority", "reliable")
func return_latency(client_time: float):
	if Global.env_network_profiling:
		metrics["return_latency"] += 1

	latency_buffer.append((Time.get_unix_time_from_system() - client_time) / 2)
	if latency_buffer.size() == LATENCY_BUFFER_SIZE:
		var total_latency = 0
		var total_counted = 0

		latency_buffer.sort()

		var mid_point_threshold = latency_buffer[LATENCY_BUFFER_MID_POINT] * 2

		for i in range(LATENCY_BUFFER_SIZE - 1):
			if (
				latency_buffer[i] < mid_point_threshold
				or latency_buffer[i] < LATENCY_MINIMUM_THRESHOLD
			):
				total_latency += latency_buffer[i]
				total_counted += 1

		var average_latency = total_latency / total_counted
		delta_latency = average_latency - latency
		latency = average_latency

		latency_buffer.clear()

extends Node

class_name ClockSynchronizer

const COMPONENT_NAME = "ClockSynchronizer"

const LATENCY_BUFFER_SIZE = 9
const LATENCY_BUFFER_MID_POINT = int(LATENCY_BUFFER_SIZE / float(2))
const LATENCY_MINIMUM_THRESHOLD = 20

## Time of the delay between clock sync calls on the client side
@export var client_clock_sync_time: float = 0.5

## The current synced clock, this value should be used on the client side
var client_clock: float = 0.0

var latency: float = 0.0

var _multiplayer_connection: MultiplayerConnection = null

var _latency_buffer = []

var _delta_latency: float = 0.0

# Timer used to call the clock syncs
var _client_clock_sync_timer: Timer = null


func _ready():
	_multiplayer_connection = get_parent()

	# Register yourself with your parent
	_multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized
	await _multiplayer_connection.init_done

	# Server-side code
	if _multiplayer_connection.is_server():
		# Disable physics process for the server
		set_physics_process(false)
	# Client-side code
	else:
		_client_clock_sync_timer = Timer.new()
		_client_clock_sync_timer.name = "ClientClockSyncTimer"
		_client_clock_sync_timer.wait_time = client_clock_sync_time
		_client_clock_sync_timer.autostart = false
		_client_clock_sync_timer.timeout.connect(_on_client_clock_sync_timer_timeout)
		add_child(_client_clock_sync_timer)

		_multiplayer_connection.client_connected.connect(_on_client_connected)


func _physics_process(delta):
	client_clock += delta + _delta_latency
	_delta_latency = 0


func _start_sync_clock():
	GodotLogger.info("Starting sync clock")

	fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())

	_client_clock_sync_timer.start()


func _stop_sync_clock():
	GodotLogger.info("Stopping sync clock")

	_client_clock_sync_timer.stop()


func _on_client_clock_sync_timer_timeout():
	# If the connection is still up, call the get latency rpc
	if _multiplayer_connection.multiplayer_api.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		get_latency.rpc_id(1, Time.get_unix_time_from_system())


func _on_client_connected(connected: bool):
	if connected:
		_start_sync_clock()
	else:
		_stop_sync_clock()


@rpc("call_remote", "any_peer", "reliable")
func fetch_server_time(client_time: float):
	if not _multiplayer_connection.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()
	return_server_time.rpc_id(id, Time.get_unix_time_from_system(), client_time)


@rpc("call_remote", "authority", "reliable")
func return_server_time(server_time: float, client_time: float):
	latency = (Time.get_unix_time_from_system() - client_time) / 2
	client_clock = server_time + latency


@rpc("call_remote", "any_peer", "reliable")
func get_latency(client_time: float):
	if not _multiplayer_connection.is_server():
		return

	var id = _multiplayer_connection.multiplayer_api.get_remote_sender_id()
	return_latency.rpc_id(id, client_time)


@rpc("call_remote", "authority", "reliable")
func return_latency(client_time: float):
	_latency_buffer.append((Time.get_unix_time_from_system() - client_time) / 2)
	if _latency_buffer.size() == LATENCY_BUFFER_SIZE:
		var total_latency = 0
		var total_counted = 0

		_latency_buffer.sort()

		var mid_point_threshold = _latency_buffer[LATENCY_BUFFER_MID_POINT] * 2

		for i in range(LATENCY_BUFFER_SIZE - 1):
			if (
				_latency_buffer[i] < mid_point_threshold
				or _latency_buffer[i] < LATENCY_MINIMUM_THRESHOLD
			):
				total_latency += _latency_buffer[i]
				total_counted += 1

		var average_latency = total_latency / total_counted
		_delta_latency = average_latency - latency
		latency = average_latency

		_latency_buffer.clear()

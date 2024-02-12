extends Node

class_name ClockSynchronizer

const COMPONENT_NAME = "ClockSynchronizer"

const LATENCY_BUFFER_SIZE = 9
const LATENCY_BUFFER_MID_POINT = int(LATENCY_BUFFER_SIZE / float(2))
const LATENCY_MINIMUM_THRESHOLD = 20

enum TYPE { FETCH_SERVER_TIME, RETURN_SERVER_TIME, GET_LATENCY, RETURN_LATENCY }

@export var message_identifier: int = 0

## Time of the delay between clock sync calls on the client side
@export var client_clock_sync_time: float = 0.5

## The current synced clock, this value should be used on the client side
var client_clock: float = 0.0

var latency: float = 0.0

var _network_message_handler: NetworkMessageHandler = null

var _multiplayer_connection: MultiplayerConnection = null

var _latency_buffer = []

var _delta_latency: float = 0.0

# Timer used to call the clock syncs
var _client_clock_sync_timer: Timer = null


func _ready():
	_network_message_handler = get_parent()

	# Get the MultiplayerConnection parent node.
	_multiplayer_connection = get_parent().get_parent()

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


func handle_message(peer_id: int, message: Array):
	match message[0]:
		TYPE.FETCH_SERVER_TIME:
			_fetch_server_time(peer_id, message[1])
		TYPE.RETURN_SERVER_TIME:
			_return_server_time(peer_id, message[1], message[2])
		TYPE.GET_LATENCY:
			_get_latency(peer_id, message[1])
		TYPE.RETURN_LATENCY:
			_return_latency(peer_id, message[1])


func _start_sync_clock():
	GodotLogger.info("Starting sync clock")

	_network_message_handler.send_message(
		1, message_identifier, [TYPE.FETCH_SERVER_TIME, Time.get_unix_time_from_system()]
	)

	_client_clock_sync_timer.start()


func _stop_sync_clock():
	GodotLogger.info("Stopping sync clock")

	_client_clock_sync_timer.stop()


func _on_client_clock_sync_timer_timeout():
	# If the connection is still up, call the get latency rpc
	if (
		_multiplayer_connection.multiplayer_api.multiplayer_peer.get_connection_status()
		== MultiplayerPeer.CONNECTION_CONNECTED
	):
		_network_message_handler.send_message(
			1, message_identifier, [TYPE.GET_LATENCY, Time.get_unix_time_from_system()]
		)


func _on_client_connected(connected: bool):
	if connected:
		_start_sync_clock()
	else:
		_stop_sync_clock()


func _fetch_server_time(id: int, client_time: float):
	if not _multiplayer_connection.is_server():
		return

	_network_message_handler.send_message(
		id,
		message_identifier,
		[TYPE.RETURN_SERVER_TIME, Time.get_unix_time_from_system(), client_time]
	)


func _return_server_time(id: int, server_time: float, client_time: float):
	if id != 1:
		return

	latency = (Time.get_unix_time_from_system() - client_time) / 2
	client_clock = server_time + latency


func _get_latency(id: int, client_time: float):
	if not _multiplayer_connection.is_server():
		return

	_network_message_handler.send_message(
		id, message_identifier, [TYPE.RETURN_LATENCY, client_time]
	)


func _return_latency(id: int, client_time: float):
	if id != 1:
		return

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

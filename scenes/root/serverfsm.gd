extends Node

class_name ServerFSM

## The states of the fsm
## INIT: starting state
## CONNECT: Try to connect and authenticate to the gateway server
## STARTL: Start the gameserver
## RUNNING: The gameserver is operational and running
## ERROR: The gameserver is in error state
enum STATES { INIT, CONNECT, RUNNING, START, ERROR }

## The time before the server tries to reconnect to the gateway server
const RETRY_TIME: int = 10.0

## The current state in which the fsm is in
@export var state: STATES = STATES.INIT

## The name of the map that will be used on the server
var map_name: String = ""

# The world for the server
var _world: World = null

# Timer used to retry the connection towards the gateway server
var _retry_timer: Timer

# Bool indicating if the init was done
var _init_done: bool = false

# Bool indicating if the server is connected to the gateway or not
var _connected_to_gateway: bool = false


func _ready():
	# Create and add the retry timer
	_retry_timer = Timer.new()
	_retry_timer.name = "RetryTimer"
	_retry_timer.autostart = false
	_retry_timer.one_shot = true
	_retry_timer.wait_time = RETRY_TIME
	_retry_timer.timeout.connect(_on__retry_timer_timeout)
	add_child(_retry_timer)

	# Connect to the server connected signal to know if the connection succeeded
	S.server_connected.connect(_on_server_connected)

	# Trigger the fsm, starting with the INIT state
	_fsm.call_deferred(STATES.INIT)


# Loop over the fsm, checking and handling each state
func _fsm(new_state: STATES):
	# Check if we entered a new state
	if new_state != state:
		GodotLogger.info("New state=[%s]" % state_to_string(new_state))

		state = new_state

	match state:
		STATES.INIT:
			_handle_init()

		STATES.CONNECT:
			_handle_connect()

		STATES.START:
			_handle_start()

		STATES.RUNNING:
			_handle_state_running()

		STATES.ERROR:
			_handle_state_error()


# Handle the INIT state
func _handle_init():
	# Init the client side for the gateway server
	if not S.client_init():
		GodotLogger.error("Failed to init the client for the gateway server")

		_fsm.call_deferred(STATES.ERROR)
		return

	# Init the gameserver server-side
	if not G.server_init():
		GodotLogger.error("Failed to init gameserver")

		_fsm.call_deferred(STATES.ERROR)
		return

	# Instantiate the world scene
	_world = J.map_scenes[map_name].instantiate()
	# Set the name
	_world.name = map_name
	# Add it to the Root scene (which is the parent of this script)
	get_parent().add_child(_world)

	# Set the flag used to check if the init is done
	_init_done = true

	# Trigger the fsm and change to the CONNECT STATE
	_fsm.call_deferred(STATES.CONNECT)


# Handle the CONNECT state
func _handle_connect():
	# Try to connect to the gateway server
	if !await _connect_to_gateway():
		GodotLogger.info(
			"Server=[%s] could not connect to gateway server, starting retry timer" % map_name
		)

		_fsm.call_deferred(STATES.ERROR)
		return

	GodotLogger.info("Successfully connected and registered with the gateway server")

	# If succeeded transition to the START state
	_fsm.call_deferred(STATES.START)


func _handle_start():
	# Start the gameserver server
	if not G.server_start(
		Global.env_server_port,
		Global.env_server_max_peers,
		Global.env_server_crt,
		Global.env_server_key
	):
		GodotLogger.error("Failed to start DTLS gameserver")

		_fsm.call_deferred(STATES.ERROR)

		return

	_fsm.call_deferred(STATES.RUNNING)


# Handle the RUNNING state
func _handle_state_running():
	GodotLogger.info("Server successfully started on port %d" % Global.env_server_port)


# Handle the ERROR state
func _handle_state_error():
	if not _init_done:
		GodotLogger.warn("The init was not done yet, not starting the retry timer")

		# Shut down the process if the init failed and in error state
		get_tree().quit()

	# Start the retry timer if it wasn't running yet
	elif _retry_timer.is_stopped():
		_retry_timer.start()


# Connect to the gateway server
func _connect_to_gateway() -> bool:
	# Try to connect to the gateway server
	if !S.client_connect(Global.env_gateway_address, Global.env_gateway_server_port):
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_server_port]
			)
		)
		return false

	# Wait until you receive the server_connected signal
	if !await S.server_connected:
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_server_port]
			)
		)
		return false

	GodotLogger.info(
		(
			"Connected to gateway=[%s] on port=[%d]"
			% [Global.env_gateway_address, Global.env_gateway_server_port]
		)
	)

	# Get the portal information from the world
	var portals_info: Dictionary = _world.get_portal_information()

	# Register the server at the gateway server
	S.server_rpc.register_server.rpc_id(
		1, _world.name, Global.env_server_address, Global.env_server_port, portals_info
	)

	# If it failed, disconnect.
	if not await S.server_rpc.server_registered:
		GodotLogger.warn("Failed to register to the gateway server")

		# Disconnect from the gateway server
		S.client_disconnect()

		return false

	return true


## Converts the state enum value to a string value
func state_to_string(to_string_state: STATES) -> String:
	match to_string_state:
		STATES.INIT:
			return "Init"
		STATES.CONNECT:
			return "Connect"
		STATES.START:
			return "Starting"
		STATES.RUNNING:
			return "Running"
		STATES.ERROR:
			return "Error"

	return "Unknown"


func _on__retry_timer_timeout():
	# If not connected, try to the reconnect
	if not _connected_to_gateway:
		_fsm.call_deferred(STATES.CONNECT)

	# Else try to restart the server
	else:
		_fsm.call_deferred(STATES.START)


func _on_server_connected(connected: bool):
	_connected_to_gateway = connected

	if state == STATES.RUNNING and not connected:
		GodotLogger.info("Disconnected from gateway server, starting retry timer")

		_retry_timer.start()
		return

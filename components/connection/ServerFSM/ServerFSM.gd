extends Node

class_name ServerFSM

## The states of the fsm
## INIT: starting state
## CONNECT: Try to connect and authenticate to the gateway server
## STARTL: Start the gameserver
## RUNNING: The gameserver is operational and running
enum STATES { IDLE, INIT, CONNECT, RUNNING, START }

## The time before the server tries to reconnect to the gateway server
const RETRY_TIME: int = 10.0

@export var _server_gateway_client: WebsocketMultiplayerConnection = null

@export var _server_client_server: WebsocketMultiplayerConnection = null

@export var config: Resource = null

## The current state in which the fsm is in
var state: STATES = STATES.IDLE

## The name of the map that will be used on the server
var map_name: String = ""

var _server_fsm_rpc: ServerFSMRPC = null

# The map for the server
var _map: Map = null

# Timer used to retry the connection towards the gateway server
var _retry_timer: Timer

# Bool indicating if the init was done
var _init_done: bool = false


func _ready():
	# Get the ServerFSMRPC component.
	_server_fsm_rpc = _server_gateway_client.component_list.get_component(
		ServerFSMRPC.COMPONENT_NAME
	)

	# Ensure the ServerFSMRPC component is present
	assert(_server_fsm_rpc != null, "Failed to get ServerFSMRPC component")

	# Create and add the retry timer
	_retry_timer = Timer.new()
	_retry_timer.name = "RetryTimer"
	_retry_timer.autostart = false
	_retry_timer.one_shot = true
	_retry_timer.wait_time = RETRY_TIME
	_retry_timer.timeout.connect(_on__retry_timer_timeout)
	add_child(_retry_timer)

	# Connect to the server connected signal to know if the connection succeeded
	_server_gateway_client.client_connected.connect(_on_gateway_client_connected)

	# Trigger the fsm, starting with the INIT state
	_fsm.call_deferred(STATES.IDLE)


func start():
	_fsm.call_deferred(STATES.INIT)


# Loop over the fsm, checking and handling each state
func _fsm(new_state: STATES):
	# Check if we entered a new state
	if new_state != state:
		GodotLogger.info("New state=[%s]" % state_to_string(new_state))

		state = new_state

	match state:
		STATES.IDLE:
			pass
		STATES.INIT:
			_handle_init()

		STATES.CONNECT:
			_handle_connect()

		STATES.START:
			_handle_start()

		STATES.RUNNING:
			_handle_state_running()


# Handle the INIT state
func _handle_init():
	# Init the client side for the gateway server
	if not _server_gateway_client.websocket_client_init():
		GodotLogger.error("Failed to init the client for the gateway server, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	# Init the gameserver server-side
	if not _server_client_server.websocket_server_init():
		GodotLogger.error("Failed to init gameserver, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	J.server_client_multiplayer_connection = _server_client_server

	# Instantiate the world scene
	_map = J.map_scenes[map_name].instantiate()
	# Set the name
	_map.name = map_name
	_map.multiplayer_connection = _server_client_server

	# Add it to the Root scene (which is the parent of this script)
	get_parent().add_child(_map)

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

		# Start the retry timer
		_retry_timer.start()
		return

	GodotLogger.info("Successfully connected and registered with the gateway server")

	# If succeeded transition to the START state
	_fsm.call_deferred(STATES.START)


func _handle_start():
	# Start the gameserver server
	if not _server_client_server.websocket_server_start(
		config.server_client_server_port,
		config.server_client_server_bind_address,
		config.use_tls,
		config.server_client_certh_path,
		config.server_client_key_path
	):
		GodotLogger.error("Failed to start DTLS gameserver, quitting")

		# Stop the game if init fails
		get_tree().quit()

		return

	_fsm.call_deferred(STATES.RUNNING)


# Handle the RUNNING state
func _handle_state_running():
	GodotLogger.info("Server successfully started on port %d" % config.server_client_server_port)


# Connect to the gateway server
func _connect_to_gateway() -> bool:
	# Try to connect to the gateway server
	if !_server_gateway_client.websocket_client_start(config.server_gateway_client_address):
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.server_gateway_client_address)

		return false

	# Wait until you receive the server_connected signal
	if !await _server_gateway_client.client_connected:
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.server_gateway_client_address)
		return false

	GodotLogger.info("Connected to gateway=[%s]" % config.server_gateway_client_address)

	# TODO: rework this
	# Get the portal information from the world
	# var portals_info: Dictionary = _world.get_portal_information()
	var portals_info: Dictionary = {}

	# Register the server at the gateway server
	_server_fsm_rpc.register_server(map_name, config.client_server_client_address, portals_info)

	# If it failed, disconnect.
	if not await _server_fsm_rpc.server_registered:
		GodotLogger.warn("Failed to register to the gateway server")

		# Disconnect from the gateway server
		_server_gateway_client.websocket_client_disconnect()

		return false

	return true


## Converts the state enum value to a string value
func state_to_string(to_string_state: STATES) -> String:
	match to_string_state:
		STATES.IDLE:
			return "Idle"
		STATES.INIT:
			return "Init"
		STATES.CONNECT:
			return "Connect"
		STATES.START:
			return "Starting"
		STATES.RUNNING:
			return "Running"

	return "Unknown"


func _on__retry_timer_timeout():
	# Try to the reconnect
	_fsm.call_deferred(STATES.CONNECT)


func _on_gateway_client_connected(connected: bool):
	if state == STATES.RUNNING and not connected:
		GodotLogger.info("Disconnected from gateway server, starting retry timer")

		_retry_timer.start()
		return

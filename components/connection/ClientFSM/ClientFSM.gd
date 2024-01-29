extends Node

class_name ClientFSM

enum STATES { IDLE, INIT, LOGIN, RUNNING }

@export var _client_gateway_client: WebsocketMultiplayerConnection = null

@export var _client_server_client: WebsocketMultiplayerConnection = null

@export var config: Resource = null

var state: STATES = STATES.IDLE

var _client_fsm_gateway_rpc: ClientFSMGatewayRPC = null

# The map for the server
var _map: Map = null


func _ready():
	# Get the ClientFSMRPC component.
	_client_fsm_gateway_rpc = _client_gateway_client.component_list.get_component(
		ClientFSMGatewayRPC.COMPONENT_NAME
	)

	# Ensure the ClientFSMGatewayRPC component is present
	assert(_client_fsm_gateway_rpc != null, "Failed to get ClientFSMGatewayRPC component")

	# Trigger the fsm, starting with the INIT state
	_fsm.call_deferred(STATES.IDLE)


func start():
	_fsm.call_deferred(STATES.INIT)


# Loop over the fsm, checking and handling each state
func _fsm(new_state: STATES):
	# Check if we entered a new state
	if new_state != state:
		GodotLogger.info("New state=[%s]" % _state_to_string(new_state))

		state = new_state

	match state:
		STATES.IDLE:
			pass
		STATES.INIT:
			_handle_init()
		STATES.LOGIN:
			_handle_login()
		STATES.RUNNING:
			_handle_state_running()


## Converts the state enum value to a string value
func _state_to_string(to_string_state: STATES) -> String:
	match to_string_state:
		STATES.IDLE:
			return "Idle"
		STATES.INIT:
			return "Init"
		STATES.LOGIN:
			return "Login"
		STATES.RUNNING:
			return "Running"

	return "Unknown"


# Connect to the gateway server
func _connect_to_gateway() -> bool:
	# Try to connect to the gateway server
	if !_client_gateway_client.websocket_client_start(config.client_gateway_client_address):
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.client_gateway_client_address)

		return false

	# Wait until you receive the server_connected signal
	if !await _client_gateway_client.client_connected:
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.client_gateway_client_address)
		return false

	GodotLogger.info("Connected to gateway=[%s]" % config.client_gateway_client_address)

	return true


func _handle_init():
	# Init the client side for the gateway server
	if not _client_gateway_client.websocket_client_init():
		GodotLogger.error("Failed to init the client for the gateway server, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	# Init the gameserver server-side
	if not _client_server_client.websocket_server_init():
		GodotLogger.error("Failed to init the client for the server, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	J.server_client_multiplayer_connection = _client_server_client

	_fsm.call_deferred(STATES.LOGIN)


func _handle_login():
	# Try to connect to the gateway server
	if !await _connect_to_gateway():
		GodotLogger.error("Client could not connect to gateway server")

		return

	# Authenticate the user
	GodotLogger.info("Authenticating to gateway server")
	_client_fsm_gateway_rpc.authenticate("test", "test")

	# Wait for the response
	var response = await _client_fsm_gateway_rpc.authenticated
	if not response:
		GodotLogger.warn("Login to gateway server failed")
		return

	GodotLogger.info("Login to gateway server successful")

	# Fetch the server information
	GodotLogger.info("Fetch server information")
	_client_fsm_gateway_rpc.get_server()

	var server_info: Dictionary = await _client_fsm_gateway_rpc.server_info_received
	if server_info["error"]:
		GodotLogger.warn("Failed to fetch server information")
		return

	# # Disconnect the client from the gateway server
	# GodotLogger.info("Disconnect from gateway server")
	# C.client_disconnect()
	# connected_to_gateway = false

	# GodotLogger.info(
	# 	(
	# 		"Connecting client to world=[%s] with address=[%s] on port=[%d]"
	# 		% [server_info["name"], server_info["address"], server_info["port"]]
	# 	)
	# )

	# # Disconnect from previous game server
	# G.client_disconnect()

	# # Connect to the gameserver
	# if !await _connect_to_server(server_info["address"], server_info["port"]):
	# 	return

	# GodotLogger.info("Authenticating to gateway server=[%s]" % server_info["name"])
	# G.player_rpc.authenticate.rpc_id(1, user, server_info["cookie"])

	# response = await G.player_rpc.authenticated
	# if not response:
	# 	JUI.alertbox("Authentication with server failed", login_panel)
	# 	return

	# GodotLogger.info("Login to game server=[%s] successful" % server_info["name"])

	# server_loaded.emit(server_info["name"])

	# if response:
	# 	state = STATES.RUNNING
	# 	fsm()

	# fsm.call_deferred()


func _handle_state_running():
	GodotLogger.info("Client successfully started")

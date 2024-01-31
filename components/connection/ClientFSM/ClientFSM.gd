extends Node

class_name ClientFSM

enum STATES { IDLE, INIT, LOGIN, WAIT_CREATE_ACCOUNT, CREATE_ACCOUNT, LOAD, RUNNING }

const RETRY_TIME: float = 5.0

@export var _client_gateway_client: WebsocketMultiplayerConnection = null

@export var _client_server_client: WebsocketMultiplayerConnection = null

@export var config: Resource = null

@export var login_panel: LoginPanel

var state: STATES = STATES.IDLE

var _client_fsm_gateway_rpc: ClientFSMGatewayRPC = null

var _client_fsm_server_rpc: ClientFSMServerRPC = null

# The map for the server
var _map: Map = null

var _connected_to_gateway: bool = false

var _login_pressed: bool = false
var _username: String = ""
var _password: String = ""


func _ready():
	# Get the ClientFSMRPC component.
	_client_fsm_gateway_rpc = _client_gateway_client.component_list.get_component(
		ClientFSMGatewayRPC.COMPONENT_NAME
	)

	# Ensure the ClientFSMGatewayRPC component is present
	assert(_client_fsm_gateway_rpc != null, "Failed to get ClientFSMGatewayRPC component")

	# Get the ClientFSMServerRPC component.
	_client_fsm_server_rpc = _client_server_client.component_list.get_component(
		ClientFSMServerRPC.COMPONENT_NAME
	)

	# Ensure the ClientFSMServerRPC component is present
	assert(_client_fsm_server_rpc != null, "Failed to get ClientFSMServerRPC component")

	login_panel.login_pressed.connect(_on_login_pressed)
	login_panel.show_create_account_pressed.connect(_on_show_create_account_pressed)
	login_panel.create_account_pressed.connect(_on_create_account_pressed)
	login_panel.back_create_account_pressed.connect(_on_back_create_account_pressed)

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
		STATES.WAIT_CREATE_ACCOUNT:
			_handle_wait_create_account()
		STATES.CREATE_ACCOUNT:
			_handle_create_account()
		STATES.LOAD:
			_handle_load()
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
		STATES.WAIT_CREATE_ACCOUNT:
			return "Wait Create Account"
		STATES.CREATE_ACCOUNT:
			return "Create Account"
		STATES.LOAD:
			return "Load"
		STATES.RUNNING:
			return "Running"

	return "Unknown"


# Connect to the gateway server
func _connect_to_gateway() -> bool:
	if _connected_to_gateway:
		GodotLogger.info("Already connected to gateway, no need to connect again")
		return true

	# Try to connect to the gateway server
	if !_client_gateway_client.websocket_client_start(config.client_gateway_client_address):
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.client_gateway_client_address)

		return false

	# Wait until you receive the server_connected signal
	if !await _client_gateway_client.client_connected:
		GodotLogger.warn("Could not connect to gateway=[%s]" % config.client_gateway_client_address)
		return false

	GodotLogger.info("Connected to gateway=[%s]" % config.client_gateway_client_address)

	_connected_to_gateway = true

	return true


# Connect to the gateway server
func _connect_to_server() -> bool:
	# Try to connect to the gateway server
	if !_client_server_client.websocket_client_start(config.client_server_client_address):
		GodotLogger.warn("Could not connect to server=[%s]" % config.client_server_client_address)

		return false

	# Wait until you receive the server_connected signal
	if !await _client_server_client.client_connected:
		GodotLogger.warn("Could not connect to server=[%s]" % config.client_server_client_address)
		return false

	GodotLogger.info("Connected to server=[%s]" % config.client_server_client_address)

	return true


func _handle_init():
	# Init the client side for the gateway server
	if not _client_gateway_client.websocket_client_init():
		GodotLogger.error("Failed to init the client for the gateway server, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	# Init the gameserver server-side
	if not _client_server_client.websocket_client_init():
		GodotLogger.error("Failed to init the client for the server, quitting")

		# Stop the game if init fails
		get_tree().quit()
		return

	J.server_client_multiplayer_connection = _client_server_client

	_fsm.call_deferred(STATES.LOGIN)


func _handle_login():
	login_panel.show()
	login_panel.show_login_container()

	# Try to connect to the gateway server
	if !await _connect_to_gateway():
		GodotLogger.error("Client could not connect to gateway server")

		await get_tree().create_timer(RETRY_TIME).timeout

		_fsm.call_deferred(STATES.LOGIN)

		return

	if not _login_pressed:
		return

	_login_pressed = false

	# Authenticate the user
	GodotLogger.info("Authenticating to gateway server")
	_client_fsm_gateway_rpc.authenticate(_username, _password)

	_password = ""

	# Wait for the response
	var response = await _client_fsm_gateway_rpc.authenticated
	if not response:
		GodotLogger.warn("Login to gateway server failed")

		_fsm.call_deferred(STATES.LOGIN)

		return

	GodotLogger.info("Login to gateway server successful")

	# Fetch the server information
	GodotLogger.info("Fetch server information")
	_client_fsm_gateway_rpc.get_server()

	var server_info: Dictionary = await _client_fsm_gateway_rpc.server_info_received
	if server_info["error"]:
		GodotLogger.warn("Failed to fetch server information")

		_fsm.call_deferred(STATES.LOGIN)

		return

	# Disconnect the client from the gateway server
	GodotLogger.info("Disconnect from gateway server")
	_client_gateway_client.websocket_client_disconnect()

	GodotLogger.info(
		(
			"Connecting client to world=[%s] with address=[%s]"
			% [server_info["name"], server_info["address"]]
		)
	)

	# Disconnect from previous game server
	_client_server_client.websocket_client_disconnect()

	# Connect to the gameserver
	if !await _connect_to_server():
		GodotLogger.error("Client could not connect to server")

		_fsm.call_deferred(STATES.LOGIN)

		return

	GodotLogger.info("Authenticating to gateway server=[%s]" % server_info["name"])
	_client_fsm_server_rpc.authenticate(_username, server_info["cookie"])

	_username = ""

	response = await _client_fsm_server_rpc.authenticated
	if not response:
		GodotLogger.warn("Authentication with server failed")
		return

	J.server_client_multiplayer_connection = _client_server_client

	# Instantiate the world scene
	_map = J.map_scenes[server_info["name"]].instantiate()
	# Set the name
	_map.name = server_info["name"]
	_map.multiplayer_connection = _client_server_client

	# Add it to the Root scene (which is the parent of this script)
	get_parent().add_child(_map)

	GodotLogger.info("Login to game server=[%s] successful" % server_info["name"])

	_fsm.call_deferred(STATES.LOAD)


func _handle_wait_create_account():
	pass


func _handle_create_account():
	pass


func _handle_load():
	_client_fsm_server_rpc.load_player()

	var player_info: Dictionary = await _client_fsm_server_rpc.player_loaded

	_map.client_add_player(
		player_info["peer_id"], player_info["username"], player_info["pos"], true
	)

	_fsm.call_deferred(STATES.RUNNING)


func _handle_state_running():
	GodotLogger.info("Client successfully started")

	login_panel.hide()


func _on_login_pressed(username: String, password: String):
	if state == STATES.LOGIN:
		_login_pressed = true
		_username = username
		_password = password

		_fsm.call_deferred(STATES.LOGIN)


func _on_show_create_account_pressed():
	login_panel.show_create_account_container()


func _on_back_create_account_pressed():
	login_panel.show_login_container()


func _on_create_account_pressed(_user: String, _pwd: String):
	pass

extends Node

class_name ClientFSM

enum STATES { INIT, LOGIN, CREATE_ACCOUNT, RUNNING }

signal logged_in
signal server_loaded(server_name: String)

@export var login_panel: LoginPanel

var state: STATES = STATES.INIT

var login_pressed: bool = false
var user: String
var passwd: String

var show_create_account_pressed: bool = false

var create_account_pressed: bool = false
var new_username: String
var new_password: String

var back_create_account_pressed: bool = false

var connected_to_gateway: bool = false
var portalled: bool = false

var world: World = null


func _ready():
	login_panel.login_pressed.connect(_on_login_pressed)
	login_panel.show_create_account_pressed.connect(_on_show_create_account_pressed)
	login_panel.create_account_pressed.connect(_on_create_account_pressed)
	login_panel.back_create_account_pressed.connect(_on_back_create_account_pressed)

	C.client_connected.connect(_on_gateway_connected)
	G.client_connected.connect(_on_gameserver_connected)
	G.player_rpc.player_portalled.connect(_on_player_portalled)

	server_loaded.connect(_on_client_server_loaded)


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.LOGIN:
			_handle_login()
		STATES.CREATE_ACCOUNT:
			_handle_create_account()
		STATES.RUNNING:
			_handle_state_running()


func _handle_init():
	login_panel.play_login_background_audio()
	login_panel.show()
	state = STATES.LOGIN
	fsm.call_deferred()


func _connect_to_gateway() -> bool:
	if connected_to_gateway:
		GodotLogger.info("Already connected to gateway, no need to connect again")
		return true

	if !C.client_connect(Global.env_gateway_address, Global.env_gateway_client_port):
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_client_port]
			)
		)
		JUI.alertbox("Error connecting to gateway", login_panel)
		return false

	if !await C.client_connected:
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_client_port]
			)
		)
		JUI.alertbox("Error connecting to gateway", login_panel)
		return false

	GodotLogger.info(
		(
			"Connected to gateway=[%s] on port=[%d]"
			% [Global.env_gateway_address, Global.env_gateway_client_port]
		)
	)

	connected_to_gateway = true

	return true


func _connect_to_server(address: String, port: int) -> bool:
	if !G.client_connect(address, port):
		GodotLogger.warn("Could not connect to server=[%s] on port=[%d]" % [address, port])
		JUI.alertbox("Error connecting to server", login_panel)
		return false

	if !await G.client_connected:
		GodotLogger.warn("Could not connect to server=[%s] on port=[%d]" % [address, port])
		JUI.alertbox("Error connecting to server", login_panel)
		return false

	GodotLogger.info("Connected to server=[%s] on port=[%d]" % [address, port])

	return true


func _handle_login():
	#TODO: handle connect for account creation
	login_panel.show_login_container()

	if show_create_account_pressed:
		show_create_account_pressed = false
		state = STATES.CREATE_ACCOUNT
		fsm.call_deferred()
		return

	if !login_pressed:
		return

	login_pressed = false

	# Connect to the gateway server
	if !await _connect_to_gateway():
		state = STATES.INIT
		fsm.call_deferred()
		return

	# Authenticate the user
	GodotLogger.info("Authenticating to gateway server")
	C.client_rpc.authenticate.rpc_id(1, user, passwd)

	# Wait for the response
	var response = await C.client_rpc.authenticated
	if not response:
		JUI.alertbox("Login to gateway server failed", login_panel)
		return

	GodotLogger.info("Login to gateway server successful")

	# Fetch the server information
	GodotLogger.info("Fetch server information")
	C.client_rpc.get_server.rpc_id(1)

	var server_info: Dictionary = await C.client_rpc.server_info_received
	if server_info["error"]:
		GodotLogger.info("Failed to fetch server information")
		JUI.alertbox("Server error, please try again", login_panel)
		return

	# Disconnect the client from the gateway server
	GodotLogger.info("Disconnect from gateway server")
	C.client_disconnect()
	connected_to_gateway = false

	GodotLogger.info(
		(
			"Connecting client to world=[%s] with address=[%s] on port=[%d]"
			% [server_info["name"], server_info["address"], server_info["port"]]
		)
	)

	# Disconnect from previous game server
	G.client_disconnect()

	# Connect to the gameserver
	if !await _connect_to_server(server_info["address"], server_info["port"]):
		return

	GodotLogger.info("Authenticating to gateway server=[%s]" % server_info["name"])
	G.player_rpc.authenticate.rpc_id(1, user, server_info["cookie"])

	response = await G.player_rpc.authenticated
	if not response:
		JUI.alertbox("Authentication with server failed", login_panel)
		return

	GodotLogger.info("Login to game server=[%s] successful" % server_info["name"])

	server_loaded.emit(server_info["name"])

	if response:
		state = STATES.RUNNING
		fsm()

	fsm.call_deferred()


func _handle_authenticate():
	pass


func _handle_create_account():
	login_panel.show_create_account_container()

	if back_create_account_pressed:
		back_create_account_pressed = false
		state = STATES.LOGIN
		fsm.call_deferred()
		return

	if !create_account_pressed:
		return

	create_account_pressed = false

	if !await _connect_to_gateway():
		state = STATES.INIT
		fsm.call_deferred()
		return

	C.client_rpc.create_account.rpc_id(1, new_username, new_password)

	var response = await C.client_rpc.account_created
	if response["error"]:
		JUI.alertbox(response["reason"], login_panel)
	else:
		JUI.alertbox("Account created", login_panel)

	fsm.call_deferred()


func _handle_state_running():
	logged_in.emit()
	login_panel.stop_login_background_audio()
	login_panel.hide()


func _on_login_pressed(username: String, password: String):
	login_pressed = true
	user = username
	passwd = password
	fsm()


func _on_show_create_account_pressed():
	show_create_account_pressed = true
	fsm()


func _on_create_account_pressed(username: String, password: String):
	create_account_pressed = true
	new_username = username
	new_password = password
	fsm()


func _on_back_create_account_pressed():
	back_create_account_pressed = true
	fsm()


func _on_gateway_connected(connected: bool):
	connected_to_gateway = connected


func _on_client_server_loaded(server_name: String):
	if world != null:
		world.queue_free()

	world = J.map_scenes[server_name].instantiate()
	world.name = server_name
	get_parent().add_child(world)


func _on_gameserver_connected(connected: bool):
	# Not interested in connected state
	if connected:
		return

	if not portalled:
		world.set_physics_process(false)
		world.queue_free()
		world = null

		state = STATES.INIT
		fsm.call_deferred()
		return
	else:
		portalled = false


func _on_player_portalled(server_name: String, address: String, port: int, cookie: String):
	portalled = true

	# Server should have done this, but just to be sure
	G.client_disconnect()

	# Remove the world
	world.set_physics_process(false)
	world.queue_free()
	world = null

	# Connect to the gameserver
	if !await _connect_to_server(address, port):
		return

	GodotLogger.info("Authenticating to gateway server=[%s]" % server_name)
	G.player_rpc.authenticate.rpc_id(1, user, cookie)

	var response = await G.player_rpc.authenticated
	if not response:
		JUI.alertbox("Authentication with server failed", login_panel)
		state = STATES.INIT
		fsm.call_deferred()
		return

	GodotLogger.info("Login to game server=[%s] successful" % server_name)

	server_loaded.emit(server_name)

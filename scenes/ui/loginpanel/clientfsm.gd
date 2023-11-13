extends Node

class_name ClientFSM

enum STATES { INIT, CONNECT, DISCONNECTED, LOGIN, CREATE_ACCOUNT, RUNNING }

var state: STATES = STATES.INIT
var fsm_timer: Timer

var login_pressed: bool = false
var user: String
var passwd: String

var show_create_account_pressed: bool = false

var create_account_pressed: bool = false
var new_username: String
var new_password: String

var back_create_account_pressed: bool = false

var connected_to_gateway: bool = false

@onready var login_panel: LoginPanel = $".."


func _ready():
	# Add a short timer to deffer the fsm() calls
	fsm_timer = Timer.new()
	fsm_timer.name = "FSMTimer"
	fsm_timer.wait_time = 0.01
	fsm_timer.autostart = false
	fsm_timer.one_shot = true
	fsm_timer.timeout.connect(_on_fsm_timer_timeout)
	add_child(fsm_timer)

	login_panel.login_pressed.connect(_on_login_pressed)
	login_panel.show_create_account_pressed.connect(_on_show_create_account_pressed)
	login_panel.create_account_pressed.connect(_on_create_account_pressed)
	login_panel.back_create_account_pressed.connect(_on_back_create_account_pressed)

	Gateway.client_connected.connect(_on_client_connected)


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.DISCONNECTED:
			pass
		STATES.LOGIN:
			_handle_login()
		STATES.CREATE_ACCOUNT:
			_handle_create_account()
		STATES.RUNNING:
			_handle_state_running()


func _handle_init():
	state = STATES.LOGIN
	fsm_timer.start()


func _connect_to_gateway() -> bool:
	if connected_to_gateway:
		GodotLogger.info("Already connected to gateway, no need to connect again")
		return true

	if !Gateway.client_connect(Global.env_gateway_address, Global.env_gateway_port):
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_port]
			)
		)
		JUI.alertbox("Error connecting to gateway", login_panel)
		return false

	if !await Gateway.client_connected:
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_port]
			)
		)
		JUI.alertbox("Error connecting to gateway", login_panel)
		return false

	GodotLogger.info(
		(
			"Connected to gateway=[%s] on port=[%d]"
			% [Global.env_gateway_address, Global.env_gateway_port]
		)
	)

	connected_to_gateway = true

	return true


func _handle_login():
	#TODO: handle connect for account creation
	login_panel.show_login_container()

	if show_create_account_pressed:
		show_create_account_pressed = false
		state = STATES.CREATE_ACCOUNT
		fsm_timer.start()
		return

	if !login_pressed:
		return

	login_pressed = false

	if !await _connect_to_gateway():
		state = STATES.INIT
		fsm_timer.start()
		return

	Gateway.account_rpc.authenticate.rpc_id(1, user, passwd)

	var response = await Gateway.account_rpc.authenticated
	if response:
		GodotLogger.info("Login Successful")
		state = STATES.RUNNING
		fsm()
	else:
		JUI.alertbox("Login failed", login_panel)

	fsm_timer.start()


func _handle_authenticate():
	pass


func _handle_create_account():
	login_panel.show_create_account_container()

	if back_create_account_pressed:
		back_create_account_pressed = false
		state = STATES.LOGIN
		fsm_timer.start()
		return

	if !create_account_pressed:
		return

	create_account_pressed = false

	if !await _connect_to_gateway():
		state = STATES.INIT
		fsm_timer.start()
		return

	Gateway.account_rpc.create_account.rpc_id(1, new_username, new_password)

	var response = await Gateway.account_rpc.account_created
	if response["error"]:
		JUI.alertbox(response["reason"], login_panel)
	else:
		JUI.alertbox("Account created", login_panel)

	fsm_timer.start()


func _handle_state_running():
	login_panel.logged_in.emit()


func _on_fsm_timer_timeout():
	fsm()


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


func _on_client_connected(connected: bool):
	connected_to_gateway = connected

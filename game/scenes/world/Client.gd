extends Node

enum STATES { INIT, CONNECT, DISCONNECTED, LOGIN, CREATE_ACCOUNT, RUNNING }

var state: STATES = STATES.INIT
var fsm_timer: Timer

var connect_pressed: bool = false
var server_address: String
var server_port: int

var login_pressed: bool = false
var user: String
var passwd: String

var show_create_account_pressed: bool = false

var create_account_pressed: bool = false
var new_username: String
var new_password: String

var back_create_account_pressed: bool = false

@onready var login_panel = $"../LoginPanel"


func _ready():
	# Add a short timer to deffer the fsm() calls
	fsm_timer = Timer.new()
	fsm_timer.name = "FSMTimer"
	fsm_timer.wait_time = 0.01
	fsm_timer.autostart = false
	fsm_timer.one_shot = true
	fsm_timer.timeout.connect(_on_fsm_timer_timeout)
	add_child(fsm_timer)

	login_panel.connect_pressed.connect(_on_connect_pressed)
	login_panel.login_pressed.connect(_on_login_pressed)
	login_panel.show_create_account_pressed.connect(_on_show_create_account_pressed)
	login_panel.create_account_pressed.connect(_on_create_account_pressed)
	login_panel.back_create_account_pressed.connect(_on_back_create_account_pressed)


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.CONNECT:
			_handle_connect()
		STATES.DISCONNECTED:
			pass
		STATES.LOGIN:
			_handle_login()
		STATES.CREATE_ACCOUNT:
			_handle_create_account()
		STATES.RUNNING:
			pass


func _handle_init():
	state = STATES.CONNECT
	fsm_timer.start()


func _handle_connect():
	login_panel.show_connect_container()

	if !connect_pressed:
		return

	connect_pressed = false

	if !Gmf.client.connect_to_server(server_address, server_port):
		Gmf.logger.warn(
			"Could not connect to server=[%s] on port=[%d]" % [server_address, server_port]
		)
		login_panel.show_connect_error("Error conneting server")
		state = STATES.INIT
		fsm_timer.start()
		return

	if !await Gmf.signals.client.connected:
		Gmf.logger.warn(
			"Could not connect to server=[%s] on port=[%d]" % [server_address, server_port]
		)
		login_panel.show_connect_error("Error conneting server")
		state = STATES.INIT
		fsm_timer.start()
		return

	Gmf.logger.info("Connected to server=[%s] on port=[%d]" % [server_address, server_port])

	state = STATES.LOGIN
	fsm_timer.start()


func _handle_login():
	login_panel.show_login_container()

	if show_create_account_pressed:
		show_create_account_pressed = false
		state = STATES.CREATE_ACCOUNT
		fsm_timer.start()
		return

	if !login_pressed:
		return

	login_pressed = false

	Gmf.rpcs.account.authenticate.rpc_id(1, user, passwd)

	var response = await Gmf.signals.client.authenticated
	if response:
		login_panel.show_login_error("Login succeeded")
		login_panel.hide()
		state = STATES.RUNNING
		fsm()
	else:
		login_panel.show_login_error("Login failed")

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

	Gmf.rpcs.account.create_account.rpc_id(1, new_username, new_password)

	var response = await Gmf.signals.client.account_created
	if response["error"]:
		login_panel.show_create_account_error(response["reason"])
	else:
		login_panel.show_create_account_error("Account created")

	fsm_timer.start()


func _on_fsm_timer_timeout():
	fsm()


func _on_connect_pressed(address: String, port: int):
	connect_pressed = true
	server_address = address
	server_port = port

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

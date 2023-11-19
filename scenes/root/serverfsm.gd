extends Node

class_name ServerFSM

enum STATES { INIT, CONNECT, RUNNING }

const RETRY_TIME: int = 10.0

var state: STATES = STATES.INIT

var map_name: String = ""
var world: World = null

var portals_info: Dictionary = {}
var retry_timer: Timer


func _ready():
	retry_timer = Timer.new()
	retry_timer.name = "RetryTimer"
	retry_timer.autostart = false
	retry_timer.one_shot = true
	retry_timer.wait_time = RETRY_TIME
	retry_timer.timeout.connect(_on_retry_timer_timeout)
	add_child(retry_timer)

	world = J.map_scenes[map_name].instantiate()
	world.name = map_name
	get_parent().add_child(world)

	portals_info = world.get_portal_information()

	S.server_connected.connect(_on_server_connected)

	fsm.call_deferred()


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.CONNECT:
			_handle_connect()
		STATES.RUNNING:
			_handle_state_running()


func _connect_to_gateway() -> bool:
	if !S.client_connect(Global.env_gateway_address, Global.env_gateway_server_port):
		GodotLogger.warn(
			(
				"Could not connect to gateway=[%s] on port=[%d]"
				% [Global.env_gateway_address, Global.env_gateway_server_port]
			)
		)
		return false

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

	S.server_rpc.register_server.rpc_id(
		1, world.name, Global.env_server_address, Global.env_server_port, portals_info
	)

	return true


func _handle_init():
	state = STATES.CONNECT
	fsm.call_deferred()


func _handle_connect():
	if !await _connect_to_gateway():
		GodotLogger.info(
			"Server=[%s] could not connect to gateway server, starting retry timer" % map_name
		)
		retry_timer.start()
		return

	state = STATES.RUNNING
	fsm.call_deferred()


func _handle_state_running():
	pass


func _on_retry_timer_timeout():
	state = STATES.INIT
	fsm.call_deferred()


func _on_server_connected(connected: bool):
	if state == STATES.RUNNING and not connected:
		GodotLogger.info("Disconnected from gateway server, starting retry timer")

		retry_timer.start()
		return

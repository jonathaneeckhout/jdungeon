extends Node

class_name ServerFSM

enum STATES { INIT, CONNECT, RUNNING }

var state: STATES = STATES.INIT

var map_name: String = ""
var world: World = null


func _ready():
	world = J.map_scenes[map_name].instantiate()
	world.name = map_name
	get_parent().add_child(world)

	S.server_connected.connect(_on_server_connected)


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.CONNECT:
			pass
		STATES.RUNNING:
			_handle_state_running()


func _handle_init():
	state = STATES.CONNECT
	fsm.call_deferred()


func _handle_state_running():
	pass


func _on_server_connected(connected: bool):
	if connected:
		S.server_rpc.register_server.rpc_id(
			1, world.name, Global.env_server_address, Global.env_server_port
		)

extends Node

enum MODE { SERVER, CLIENT }
enum ENTITY_TYPE { PLAYER, ENEMY, ITEM, NPC }

var mode: MODE = MODE.CLIENT

var logger: Log
var env: Node
var global: Node
var signals: Node
var rpcs: Node

var server: Node
var client: Node

var world: Node

var player_scene: Resource
var enemies_scene: Dictionary = {}


func _ready():
	logger = load("res://addons/logger/logger.gd").new()
	logger.name = "Logger"
	add_child(logger)

	env = load("res://gmf/common/scripts/godotenv/scripts/env.gd").new()
	env.name = "Env"
	add_child(env)

	global = load("res://gmf/common/scripts/global.gd").new()
	global.name = "Global"
	add_child(global)

	signals = load("res://gmf/common/scripts/signals.gd").new()
	signals.name = "Signals"
	add_child(signals)

	rpcs = load("res://gmf/common/scripts/rpcs.gd").new()
	rpcs.name = "RPCs"
	add_child(rpcs)


func init_server() -> bool:
	mode = MODE.SERVER

	Engine.set_physics_ticks_per_second(20)

	if not Gmf.global.load_server_env_variables():
		Gmf.logger.error("Could not load server's env variables")
		return false

	signals.init_server()

	server = load("res://gmf/server/scripts/server.gd").new()
	server.name = "Server"
	add_child(server)

	if not server.init():
		Gmf.logger.error("Could not load init server")
		return false

	return true


func init_client() -> bool:
	mode = MODE.CLIENT

	Engine.set_physics_ticks_per_second(60)

	if not Gmf.global.load_client_env_variables():
		Gmf.logger.error("Could not load client's env variables")
		return false

	signals.init_client()

	client = load("res://gmf/client/scripts/client.gd").new()
	client.name = "Client"
	add_child(client)

	return true


func is_server() -> bool:
	return Gmf.mode == Gmf.MODE.SERVER


func register_player_scene(player_scene_path: String):
	player_scene = load(player_scene_path)


func register_enemy_scene(enemy_class: String, enemy_scene_path: String):
	enemies_scene[enemy_class] = load(enemy_scene_path)

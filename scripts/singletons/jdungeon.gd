extends Node

enum MODE { SERVER, CLIENT }
enum ENTITY_TYPE { PLAYER, ENEMY, ITEM, NPC }

const PHYSICS_LAYER_WORLD = 1
const PHYSICS_LAYER_PLAYERS = 2
const PHYSICS_LAYER_ENEMIES = 4
const PHYSICS_LAYER_NPCS = 8
const PHYSICS_LAYER_ITEMS = 16

const ARRIVAL_DISTANCE = 8

var mode: MODE = MODE.CLIENT

var logger: Log
var env: Node
var global: Node
var signals: Node
var rpcs: Node

var server: JServer
var client: JClient

var world: Node

var player_scene: Resource
var enemies_scene: Dictionary = {}


func _ready():
	logger = load("res://addons/logger/logger.gd").new()
	logger.name = "Logger"
	add_child(logger)

	env = load("res://scripts/godotenv/scripts/env.gd").new()
	env.name = "Env"
	add_child(env)

	global = load("res://scripts/global.gd").new()
	global.name = "Global"
	add_child(global)

	rpcs = load("res://scripts/network/rpcs.gd").new()
	rpcs.name = "RPCs"
	add_child(rpcs)


func init_server() -> bool:
	mode = MODE.SERVER

	Engine.set_physics_ticks_per_second(20)

	if not J.global.load_server_env_variables():
		J.logger.error("Could not load server's env variables")
		return false

	server = load("res://scripts/network/server.gd").new()
	server.name = "Server"
	add_child(server)

	if not server.init():
		J.logger.error("Could not load init server")
		return false

	return true


func init_client() -> bool:
	mode = MODE.CLIENT

	Engine.set_physics_ticks_per_second(60)

	if not J.global.load_client_env_variables():
		J.logger.error("Could not load client's env variables")
		return false

	client = load("res://scripts/network/client.gd").new()
	client.name = "Client"
	add_child(client)

	return true


func is_server() -> bool:
	return J.mode == J.MODE.SERVER


func register_player_scene(player_scene_path: String):
	player_scene = load(player_scene_path)


func register_enemy_scene(enemy_class: String, enemy_scene_path: String):
	enemies_scene[enemy_class] = load(enemy_scene_path)

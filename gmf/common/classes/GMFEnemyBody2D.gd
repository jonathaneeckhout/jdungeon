extends CharacterBody2D

class_name GMFEnemyBody2D

const ARRIVAL_DISTANCE = 8
const SPEED = 300.0

signal state_changed(new_state: String)

@export var peer_id := 1:
	set(id):
		peer_id = id

@export var enemy_class: String = "":
	set(new_class):
		enemy_class = new_class
		Gmf.register_enemy_scene(enemy_class, scene_file_path)

var entity_type: Gmf.ENTITY_TYPE = Gmf.ENTITY_TYPE.ENEMY

var state: String = "Idle"

var moving := false
var move_target := Vector2()

var server_synchronizer: Node2D


func _ready():
	server_synchronizer = load("res://gmf/common/scripts/serverSynchronizer.gd").new()
	server_synchronizer.name = "ServerSynchronizer"
	add_child(server_synchronizer)


func _physics_process(_delta):
	pass

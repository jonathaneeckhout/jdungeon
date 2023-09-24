extends GMFBody2D

class_name GMFEnemyBody2D

signal respawned

const DESPAWN_TIME = 10.0

@export var respawn: bool = false
@export var respawn_time: float = 10.0

@onready var spawn_position: Vector2 = position

var despawn_timer: Timer


func _init():
	entity_type = Gmf.ENTITY_TYPE.ENEMY


var enemy_class: String = "":
	set(new_class):
		enemy_class = new_class
		Gmf.register_enemy_scene(enemy_class, scene_file_path)


func _ready():
	super()

	collision_layer += Gmf.PHYSICS_LAYER_ENEMIES

	if Gmf.is_server():
		despawn_timer = Timer.new()
		despawn_timer.name = "DespawnTimer"
		despawn_timer.one_shot = true
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		add_child(despawn_timer)


func _on_stats_died():
	super()

	despawn_timer.start(DESPAWN_TIME)


func _on_despawn_timer_timeout():
	if respawn:
		Gmf.world.queue_enemy_respawn(enemy_class, spawn_position, respawn_time)

	queue_free()

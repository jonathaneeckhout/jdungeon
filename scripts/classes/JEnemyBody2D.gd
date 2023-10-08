extends JBody2D

class_name JEnemyBody2D

const DESPAWN_TIME = 10.0

var enemy_class: String = ""

@export var respawn: bool = false
@export var respawn_time: float = 10.0

@onready var spawn_position: Vector2 = position

var despawn_timer: Timer


func _init():
	super()

	entity_type = J.ENTITY_TYPE.ENEMY

	collision_layer += J.PHYSICS_LAYER_ENEMIES

	if J.is_server():
		despawn_timer = Timer.new()
		despawn_timer.name = "DespawnTimer"
		despawn_timer.one_shot = true
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		add_child(despawn_timer)


func _ready():
	if not J.is_server() and J.client.player:
		stats.get_sync.rpc_id(1, J.client.player.peer_id)


func die():
	super()

	despawn_timer.start(DESPAWN_TIME)


func _on_despawn_timer_timeout():
	if respawn:
		J.world.queue_enemy_respawn(enemy_class, spawn_position, respawn_time)

	queue_free()

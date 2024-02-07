extends Node

@export var stats: StatsSynchronizerComponent
@export var despawn_time: float = 10.0
@export var respawn_time: float = 10.0
@export var should_respawn: bool = true

var target_node: Node

var despawn_timer: Timer

var spawn_position: Vector2


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("enemy_class") == null:
		GodotLogger.error("target_node does not have the enemy_class variable")
		return

	if not target_node.multiplayer_connection.is_server():
		return

	spawn_position = target_node.position

	stats.died.connect(_on_died)
	despawn_timer = Timer.new()
	despawn_timer.name = "DespawnTimer"
	despawn_timer.one_shot = true
	despawn_timer.wait_time = despawn_time
	despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	add_child(despawn_timer)


func _on_died():
	despawn_timer.start()

	if target_node is CollisionObject2D:
		target_node.collision_layer = J.PHYSICS_LAYER_PASSABLE_ENTITIES
		target_node.collision_mask = 0


func _on_despawn_timer_timeout():
	if should_respawn:
		target_node.multiplayer_connection.map.queue_enemy_respawn(
			target_node.enemy_class, spawn_position, respawn_time
		)

	target_node.queue_free()

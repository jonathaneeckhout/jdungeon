extends Node

class_name JEnemyRespawn

var enemy_class: String
var respawn_position: Vector2
var respawn_time: float


func _ready():
	var respawn_timer: Timer = Timer.new()
	respawn_timer.name = "RespawnTimer"
	respawn_timer.autostart = true
	respawn_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func _on_respawn_timer_timeout():
	var enemy: JEnemyBody2D = J.enemy_scenes[enemy_class].instantiate()
	enemy.name = str(enemy.get_instance_id())
	enemy.position = respawn_position
	enemy.should_respawn = true
	enemy.respawn_time = respawn_time

	J.world.enemies.add_child(enemy)

	queue_free()

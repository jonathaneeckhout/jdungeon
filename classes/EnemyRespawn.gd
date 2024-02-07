extends Node

class_name EnemyRespawn

var enemy_class: String
var respawn_position: Vector2
var respawn_time: float
var map: Map = null


func _ready():
	var respawn_timer: Timer = Timer.new()
	respawn_timer.name = "RespawnTimer"
	respawn_timer.autostart = true
	respawn_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func _on_respawn_timer_timeout():
	var enemy: Enemy = J.enemy_scenes[enemy_class].instantiate()
	enemy.name = str(enemy.get_instance_id())
	enemy.position = respawn_position

	map.enemies.add_child(enemy)

	queue_free()

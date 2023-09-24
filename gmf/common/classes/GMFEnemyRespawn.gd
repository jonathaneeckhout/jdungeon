extends Node

class_name GMFEnemyRespawn

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
	var enemy: GMFEnemyBody2D = Gmf.enemies_scene[enemy_class].instantiate()
	enemy.name = str(enemy.get_instance_id())
	enemy.position = respawn_position
	enemy.respawn = true
	enemy.respawn_time = respawn_time

	Gmf.world.enemies.add_child(enemy)

	queue_free()

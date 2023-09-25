extends Node2D

class_name GMFPlayerBehavior

enum INTERACT_TYPE { ENEMY, NPC, ITEM }

const SPEED = 300.0

@export var player: GMFPlayerBody2D
@export var player_synchronizer: GMFPlayerSynchronizer
@export var player_stats: GMFStats

var attack_timer: Timer

var enemies_in_attack_range: Array[GMFEnemyBody2D] = []

var moving: bool = false
var move_target: Vector2 = Vector2()

var interacting: bool = false
var interact_target: GMFBody2D = null
var interact_type: INTERACT_TYPE = INTERACT_TYPE.ENEMY


func _ready():
	var attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = Gmf.PHYSICS_LAYER_ENEMIES

	var cs_attack_area = CollisionShape2D.new()
	cs_attack_area.name = "AttackAreaCollisionShape2D"
	attack_area.add_child(cs_attack_area)

	var cs_attack_area_circle = CircleShape2D.new()

	cs_attack_area_circle.radius = 64.0
	cs_attack_area.shape = cs_attack_area_circle

	add_child(attack_area)

	attack_area.body_entered.connect(_on_attack_area_enemy_entered)
	attack_area.body_exited.connect(_on_attack_area_enemy_exited)

	player_synchronizer.moved.connect(_on_moved)
	player_synchronizer.interacted.connect(_on_interacted)

	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)


func _physics_process(delta: float):
	if Gmf.is_server():
		behavior(delta)

		player.move_and_slide()


func behavior(_delta: float):
	if moving:
		if player.position.distance_to(move_target) > Gmf.ARRIVAL_DISTANCE:
			player.velocity = (
				player.position.direction_to(move_target) * player_stats.movement_speed
			)
			player.send_new_loop_animation("Move")
		else:
			moving = false
			player.velocity = Vector2.ZERO
	elif interacting:
		if not is_instance_valid(interact_target) or interact_target.is_dead:
			interacting = false
			interact_target = null
			return

		match interact_type:
			INTERACT_TYPE.ENEMY:
				if not enemies_in_attack_range.has(interact_target):
					player.velocity = (
						player.position.direction_to(interact_target.position)
						* player_stats.movement_speed
					)
					player.send_new_loop_animation("Move")
				else:
					player.velocity = Vector2.ZERO

					if attack_timer.is_stopped():
						player.attack(interact_target)
						attack_timer.start(player_stats.attack_speed)

			INTERACT_TYPE.NPC:
				pass
			INTERACT_TYPE.ITEM:
				pass
	else:
		player.send_new_loop_animation("Idle")


func _on_attack_area_enemy_entered(body: GMFEnemyBody2D):
	if not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)


func _on_attack_area_enemy_exited(body: GMFEnemyBody2D):
	if enemies_in_attack_range.has(body):
		enemies_in_attack_range.erase(body)


func _on_moved(target_position: Vector2):
	interacting = false

	moving = true
	move_target = target_position


func _on_interacted(target_name: String):
	moving = false

	if Gmf.world.enemies.has_node(target_name):
		interacting = true
		interact_target = Gmf.world.enemies.get_node(target_name)
		interact_type = INTERACT_TYPE.ENEMY
		return

	if Gmf.world.npcs.has_node(target_name):
		interacting = true
		interact_target = Gmf.world.npcs.get_node(target_name)
		interact_type = INTERACT_TYPE.NPC
		return

	if Gmf.world.items.has_node(target_name):
		interacting = true
		interact_target = Gmf.world.items.get_node(target_name)
		interact_type = INTERACT_TYPE.ITEM
		return


func _on_attack_timer_timeout():
	attack_timer.stop()

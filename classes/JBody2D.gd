extends CharacterBody2D

class_name JBody2D

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ENEMY

var synchronizer: JSynchronizer
var stats: JStats

var loop_animation: String = "Idle"


func _ready():
	collision_layer = J.PHYSICS_LAYER_WORLD

	if J.is_server():
		collision_mask = J.PHYSICS_LAYER_WORLD
	else:
		# Don't handle collision on client side
		collision_mask = 0

	synchronizer = load("res://classes/JSynchronizer.gd").new()
	synchronizer.name = "Synchronizer"
	synchronizer.to_be_synced = self
	add_child(synchronizer)

	stats = load("res://classes/JStats.gd").new()
	stats.name = "Stats"
	add_child(stats)

	stats.died.connect(_on_stats_died)


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	target.hurt(self, damage)
	synchronizer.sync_attack(target.name, damage)


func hurt(from: CharacterBody2D, damage: int):
	var damage_done: int = stats.hurt(damage)

	synchronizer.sync_hurt(from.name, stats.hp, stats.max_hp, damage_done)


func send_new_loop_animation(animation: String):
	if loop_animation != animation:
		loop_animation = animation
		synchronizer.sync_loop_animation(loop_animation, velocity)


func _on_stats_died():
	synchronizer.sync_die()

extends CharacterBody2D

class_name GMFBody2D

var entity_type: Gmf.ENTITY_TYPE = Gmf.ENTITY_TYPE.ENEMY

var synchronizer: GMFSynchronizer
var stats: GMFStats

var loop_animation: String = "Idle"


func _ready():
	collision_layer = Gmf.PHYSICS_LAYER_WORLD

	if Gmf.is_server():
		collision_mask = Gmf.PHYSICS_LAYER_WORLD
	else:
		# Don't handle collision on client side
		collision_mask = 0

	synchronizer = load("res://gmf/common/classes/GMFSynchronizer.gd").new()
	synchronizer.name = "Synchronizer"
	synchronizer.to_be_synced = self
	add_child(synchronizer)

	stats = load("res://gmf/common/classes/GMFStats.gd").new()
	stats.name = "Stats"
	add_child(stats)


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	target.hurt(self, damage)
	synchronizer.sync_attack(target.name, damage)


func hurt(from: CharacterBody2D, damage: int):
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - stats.defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < stats.hp:
		stats.hp -= reduced_damage
		synchronizer.sync_hurt(from.name, stats.hp, reduced_damage)
	# # Die if damage is bigger than remaining hp
	else:
		print("I'm dead")
		# die()


func send_new_loop_animation(animation: String):
	if loop_animation != animation:
		loop_animation = animation
		synchronizer.sync_loop_animation(loop_animation, velocity)

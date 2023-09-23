extends CharacterBody2D

class_name GMFBody2D

enum STATE { IDLE, MOVE, INTERACT, ATTACK, LOOT, NPC }

signal state_changed(new_state: STATE, direction: Vector2, duration: float)
signal attacked(target: String, damage: int)
signal got_hurt(from: String, hp: int, damage: int)

@export var peer_id := 1:
	set(id):
		peer_id = id

var entity_type: Gmf.ENTITY_TYPE = Gmf.ENTITY_TYPE.ENEMY
var state: STATE = STATE.IDLE

var server_synchronizer: Node2D
var stats: Node
var interface: Control


func _ready():
	collision_layer = Gmf.PHYSICS_LAYER_WORLD

	if Gmf.is_server():
		collision_mask = Gmf.PHYSICS_LAYER_WORLD

		# Don't handle input on server side
		set_process_input(false)
	else:
		# Don't handle physics on client side
		collision_mask = 0

		got_hurt.connect(_on_got_hurt)

	server_synchronizer = load("res://gmf/common/classes/GMFBody2D/serverSynchronizer.gd").new()
	server_synchronizer.name = "ServerSynchronizer"
	add_child(server_synchronizer)

	stats = load("res://gmf/common/classes/GMFBody2D/stats.gd").new()
	stats.name = "Stats"
	add_child(stats)

	if has_node("Interface"):
		interface = $Interface


func _physics_process(delta: float):
	if Gmf.is_server():
		behavior(delta)

		move_and_slide()


func behavior(_delta: float):
	pass


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	target.hurt(self, damage)
	server_synchronizer.sync_attack(target.name, damage)


func hurt(from: CharacterBody2D, damage: int):
	# # Reduce the damage according to the defense stat
	var reduced_damage = max(0, damage - stats.defense)

	# # Deal damage if health pool is big enough
	if reduced_damage < stats.hp:
		stats.hp -= reduced_damage
		server_synchronizer.sync_hurt(from.name, stats.hp, reduced_damage)
	# # Die if damage is bigger than remaining hp
	else:
		print("I'm dead")
		# die()

	if interface:
		interface.update_hp_bar(stats.hp, stats.max_hp)


func _on_got_hurt(_from: String, hp: int, _damage: int):
	stats.hp = hp

	if interface:
		interface.update_hp_bar(stats.hp, stats.max_hp)

extends CharacterBody2D

class_name EnemyBody

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ENEMY
var enemy_class: String = ""
var component_list: Dictionary = {}

@onready var spawn_position: Vector2 = position

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent


func _init():
	collision_layer = J.PHYSICS_LAYER_ENEMIES

	if G.is_server():
		# Enemies can be blocked by NPCs and players.
		collision_mask = J.PHYSICS_LAYER_WORLD + J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_NPCS
	else:
		# Don't handle collision on client side
		collision_mask = 0

extends CharacterBody2D

class_name NPCBody

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.NPC
var npc_class: String = ""
var component_list: Dictionary = {}


func _init():
	collision_layer = J.PHYSICS_LAYER_NPCS

	if G.is_server():
		# NPCs cannot be stopped by any entity.
		collision_mask = J.PHYSICS_LAYER_WORLD
	else:
		# Don't handle collision on client side
		collision_mask = 0


func interact(_player: Player):
	pass

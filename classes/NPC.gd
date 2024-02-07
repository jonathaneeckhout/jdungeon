extends CharacterBody2D

class_name NPC

var multiplayer_connection: MultiplayerConnection = null

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.NPC
var npc_class: String = ""
var component_list: Dictionary = {}

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent
@onready var hurtbox: Area2D = $HurtArea


func _init():
	collision_layer = J.PHYSICS_LAYER_NPCS

	multiplayer_connection = J.server_client_multiplayer_connection

	if multiplayer_connection.is_server():
		# NPCs cannot be stopped by any entity.
		collision_mask = J.PHYSICS_LAYER_WORLD
	else:
		# Don't handle collision on client side
		collision_mask = 0


func _ready():
	# Make sure to set the layer to NPCs
	hurtbox.collision_layer = J.PHYSICS_LAYER_NPCS
	# We're not interested in others
	hurtbox.collision_mask = 0


func interact(_player: Player):
	pass

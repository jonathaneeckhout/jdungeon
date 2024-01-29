extends CharacterBody2D

class_name Enemy

var multiplayer_connection: MultiplayerConnection = null

var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.ENEMY
var enemy_class: String = ""
var component_list: Dictionary = {}

@onready var spawn_position: Vector2 = position

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent
@onready var hurtbox: Area2D = $HurtArea
@onready var position_synchronizer: PositionSynchronizerComponent = $PositionSynchronizerComponent
@onready var lag_compensation: Node2D = $LagCompensationComponent


func _init():
	collision_layer = J.PHYSICS_LAYER_ENEMIES

	multiplayer_connection = J.server_client_multiplayer_connection

	if multiplayer_connection.is_server():
		# Enemies can be blocked by NPCs and players.
		collision_mask = J.PHYSICS_LAYER_WORLD + J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_NPCS
	else:
		# Don't handle collision on client side
		collision_mask = 0


func _ready():
	# Make sure to set the layer to enemies
	hurtbox.collision_layer = J.PHYSICS_LAYER_ENEMIES
	# We're not interested in others
	hurtbox.collision_mask = 0

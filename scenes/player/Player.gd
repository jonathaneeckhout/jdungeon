extends CharacterBody2D

class_name Player

var multiplayer_connection: MultiplayerConnection = null

var username: String = ""
var server: String = ""
var peer_id: int = 0
var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.PLAYER

var component_list: Dictionary = {}

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent
@onready var inventory: InventorySynchronizerComponent = $InventorySynchronizerComponent
@onready var equipment: EquipmentSynchronizerComponent = $EquipmentSynchronizerComponent

@onready var shop: Shop = $Camera2D/UILayer/Shop


func _init():
	collision_layer = J.PHYSICS_LAYER_PLAYERS

	# The player cannot walk past NPCs and enemies. But other players cannot block their path.
	collision_mask = J.PHYSICS_LAYER_WORLD + J.PHYSICS_LAYER_ENEMIES + J.PHYSICS_LAYER_NPCS

	multiplayer_connection = J.server_client_multiplayer_connection


func _ready():
	if multiplayer_connection.is_server():
		pass
	else:
		$InterfaceComponent.display_name = username

		if multiplayer_connection.is_own_player(self):
			stats.died.connect(_on_died)
			stats.respawned.connect(_on_respawned)

			focus_camera()
		else:
			$Camera2D.queue_free()


func focus_camera():
	$Camera2D.make_current()


func _on_died():
	%DeathPopup.show_popup()


func _on_respawned():
	%DeathPopup.hide()

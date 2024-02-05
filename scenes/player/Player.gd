extends CharacterBody2D

class_name Player

var multiplayer_connection: MultiplayerConnection = null

var username: String = ""
var server: String = ""
var peer_id: int = 0
var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.PLAYER

var component_list: Dictionary = {}

# @onready var position_synchronizer: PositionSynchronizerComponent = $PositionSynchronizerComponent
# @onready
# var network_view_synchronizer: NetworkViewSynchronizerComponent = $NetworkViewSynchronizerComponent
# @onready var player_synchronizer: PlayerSynchronizer = $PlayerSynchronizer

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent
@onready var inventory: InventorySynchronizerComponent = $InventorySynchronizerComponent
@onready var equipment: EquipmentSynchronizerComponent = $EquipmentSynchronizerComponent

@onready var shop: Shop = $Camera2D/UILayer/Shop
# @onready var player_unstuck: PlayerUnstuckComponent = $PlayerUnstuckComponent
# @onready var update_face: UpdateFaceComponent = $UpdateFaceComponent
# @onready var skeleton: Node2D = $Skeleton
# @onready var dialogue: DialogueSynhcronizerComponent = $DialogueSynchronizerComponent
# @onready var original_scale: Vector2 = skeleton.scale
# @onready var ui_control: Control = $Camera2D/UILayer/GUI


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
			focus_camera()
		else:
			$Camera2D.queue_free()


# func _ready():
# 	# Server and Client's common code
# 	# Add listeners on equipment changes

# 	stats.died.connect(_on_died)
# 	stats.respawned.connect(_on_respawned)
# 	equipment.loaded.connect(_on_equipment_loaded)
# 	equipment.item_added.connect(_on_item_equiped)
# 	equipment.item_removed.connect(_on_item_unequiped)
# 	# Server side code
# 	if G.is_server():
# 		# No input is handeld on server's side
# 		set_process_input(false)
# 		# Remove the camera with ui on the server's side
# 		$Camera2D.queue_free()

# 		stats.stats_changed.connect(_on_stats_changed)

# 	# Client side code
# 	else:
# 		$InterfaceComponent.display_name = username
# 		$InterfaceComponent.show_energy = true

# 		update_face.direction_changed.connect(_on_direction_changed)

# 		# Your own player code
# 		if G.is_own_player(self):
# 			focus_camera()
# 		# Another player code
# 		else:
# 			# No input is handeld on other player's side
# 			set_process_input(false)
# 			# Remove the camera with ui on the other player's side
# 			$Camera2D.queue_free()


func focus_camera():
	$Camera2D.make_current()


# func _on_died():
# 	if not G.is_server() and G.is_own_player(self):
# 		$Camera2D/UILayer/GUI/DeathPopup.show_popup()

# func _on_respawned():
# 	if not G.is_server() and G.is_own_player(self):
# 		$Camera2D/UILayer/GUI/DeathPopup.hide()

# func _on_direction_changed(_original: bool):
# 	move_equipment_weapons()

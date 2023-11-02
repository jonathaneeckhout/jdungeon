extends CharacterBody2D

class_name Player

const PLAYER_HP_GAIN_PER_LEVEL: int = 8
const PLAYER_ATTACK_POWER_GAIN_PER_LEVEL: float = 0.2

var username: String = ""
var peer_id: int = 0
var entity_type: J.ENTITY_TYPE = J.ENTITY_TYPE.PLAYER

@onready var input_synchronizer: InputSynchronizerComponent = $InputSynchronizerComponent
@onready var player_behavior: PlayerBehaviorComponent = $PlayerBehaviorComponent
@onready var position_synchronizer: PositionSynchronizerComponent = $PositionSynchronizerComponent
@onready
var network_view_synchronizer: NetworkViewSynchronizerComponent = $NetworkViewSynchronizerComponent

@onready var stats: StatsSynchronizerComponent = $StatsSynchronizerComponent
@onready var inventory: InventorySynchronizerComponent = $InventorySynchronizerComponent
@onready var equipment: EquipmentSynchronizerComponent = $EquipmentSynchronizerComponent

@onready var original_scale = $Skeleton.scale

@onready var equipment_sprites = {
	"Head": $Sprites/Head,
	"Body": $Sprites/Body,
	"Legs": [$Sprites/RightLeg, $Sprites/LeftLeg],
	"Arms": [$Sprites/RightArm, $Sprites/LeftArm],
	"RightHand": $Sprites/RightHand,
	"LeftHand": $Sprites/LeftHand
}

@onready var original_sprite_textures = {
	"Head": $Sprites/Head.texture,
	"Body": $Sprites/Body.texture,
	"Legs": [$Sprites/RightLeg.texture, $Sprites/LeftLeg.texture],
	"Arms": [$Sprites/RightArm.texture, $Sprites/LeftArm.texture],
	"RightHand": $Sprites/RightHand.texture,
	"LeftHand": $Sprites/LeftHand.texture
}


func _init():
	collision_layer = J.PHYSICS_LAYER_PLAYERS

	if J.is_server():
		# The player cannot walk past NPCs and enemies. But other players cannot block their path.
		collision_mask = J.PHYSICS_LAYER_WORLD + J.PHYSICS_LAYER_ENEMIES + J.PHYSICS_LAYER_NPCS
	else:
		# Don't handle collision on client side
		collision_mask = 0


func _ready():
	# Server and Client's common code
	# Add listeners on equipment changes

	stats.died.connect(_on_died)
	stats.respawned.connect(_on_respawned)
	equipment.loaded.connect(_on_equipment_loaded)
	equipment.item_added.connect(_on_item_equiped)
	equipment.item_removed.connect(_on_item_unequiped)
	# Server side code
	if J.is_server():
		# No input is handeld on server's side
		set_process_input(false)
		# Remove the camera with ui on the server's side
		$Camera2D.queue_free()

		stats.stats_changed.connect(_on_stats_changed)

	# Client side code
	else:
		# Behavior is not handeld on client's side
		player_behavior.queue_free()

		$InterfaceComponent.display_name = username

		# Your own player code
		if peer_id == multiplayer.get_unique_id():
			focus_camera()
		# Another player code
		else:
			# No input is handeld on other player's side
			set_process_input(false)
			# If no input is handled this node makes no sense to keep
			input_synchronizer.queue_free()
			# Remove the camera with ui on the other player's side
			$Camera2D.queue_free()


func focus_camera():
	$Camera2D.make_current()


func load_equipment_single_sprite(equipment_slot: String):
	for child in equipment_sprites[equipment_slot].get_children():
		child.queue_free()

	if equipment.items[equipment_slot]:
		equipment_sprites[equipment_slot].texture = null

		var item: Item = equipment.items[equipment_slot].duplicate()
		item.scale = item.scale / original_scale
		item.get_node("Sprite").hide()
		item.get_node("EquipmentSprite").show()
		equipment_sprites[equipment_slot].add_child(item)
	else:
		equipment_sprites[equipment_slot].texture = original_sprite_textures[equipment_slot]


func load_equipment_double_sprites(equipment_slot: String):
	for equipment_sprite in equipment_sprites[equipment_slot]:
		for child in equipment_sprite.get_children():
			child.queue_free()

	if equipment.items[equipment_slot]:
		equipment_sprites[equipment_slot][0].texture = null
		equipment_sprites[equipment_slot][1].texture = null

		var item_right: Item = equipment.items[equipment_slot].duplicate()
		item_right.scale = item_right.scale / original_scale
		item_right.get_node("Sprite").hide()
		item_right.get_node("EquipmentSpriteRight").show()
		equipment_sprites[equipment_slot][0].add_child(item_right)

		var item_left: Item = equipment.items[equipment_slot].duplicate()
		item_left.scale = item_left.scale / original_scale
		item_left.get_node("Sprite").hide()
		item_left.get_node("EquipmentSpriteLeft").show()
		equipment_sprites[equipment_slot][1].add_child(item_left)

	else:
		equipment_sprites[equipment_slot][0].texture = original_sprite_textures[equipment_slot][0]
		equipment_sprites[equipment_slot][1].texture = original_sprite_textures[equipment_slot][1]


func equipment_changed():
	load_equipment_single_sprite("Head")
	load_equipment_single_sprite("Body")
	load_equipment_double_sprites("Arms")
	load_equipment_double_sprites("Legs")
	load_equipment_single_sprite("RightHand")
	load_equipment_single_sprite("LeftHand")


func calculate_level_boost() -> Boost:
	var boost: Boost = Boost.new()
	boost.hp_max = int((stats.level - 1) * PLAYER_HP_GAIN_PER_LEVEL)
	boost.attack_power_min = int(stats.level * PLAYER_ATTACK_POWER_GAIN_PER_LEVEL)
	boost.attack_power_max = boost.attack_power_min
	return boost


func calculate_and_apply_boosts():
	var boost: Boost = calculate_level_boost()

	var equipment_boost: Boost = equipment.get_boost()
	boost.add_boost(equipment_boost)

	stats.apply_boost(boost)


func update_boosts():
	stats.load_defaults()

	calculate_and_apply_boosts()


func _on_stats_changed(stat_type: StatsSynchronizerComponent.TYPE):
	if J.is_server() and stat_type == StatsSynchronizerComponent.TYPE.LEVEL:
		update_boosts()


func _on_equipment_loaded():
	if J.is_server():
		update_boosts()
	else:
		equipment_changed()


func _on_item_equiped(_item_uuid: String, _item_class: String):
	if J.is_server():
		update_boosts()
	else:
		equipment_changed()


func _on_item_unequiped(_item_uuid: String):
	if J.is_server():
		update_boosts()
	else:
		equipment_changed()


func _on_died():
	if not J.is_server() and peer_id == multiplayer.get_unique_id():
		$Camera2D/UILayer/GUI/DeathPopup.show_popup()


func _on_respawned():
	if not J.is_server() and peer_id == multiplayer.get_unique_id():
		$Camera2D/UILayer/GUI/DeathPopup.hide()

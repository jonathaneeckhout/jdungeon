extends Node

const COMPONENT_NAME: String = "equipment"

@export var equipment: EquipmentSynchronizerComponent = null
@export var skeleton: Node2D = null
@export var sprites: Node2D = null
@export var update_face: UpdateFaceComponent = null

var _target_node: Node

@onready var equipment_sprites = {
	"Head": sprites.get_node("Head"),
	"Body": sprites.get_node("Body"),
	"Legs": [sprites.get_node("RightLeg"), sprites.get_node("LeftLeg")],
	"Arms": [sprites.get_node("RightArm"), sprites.get_node("LeftArm")],
	"RightHand": sprites.get_node("RightHand"),
	"LeftHand": sprites.get_node("LeftHand"),
	"RightOffHand": sprites.get_node("RightOffHand"),
	"LeftOffHand": sprites.get_node("LeftOffHand")
}

@onready var original_sprite_textures = {
	"Head": sprites.get_node("Head").texture,
	"Body": sprites.get_node("Body").texture,
	"Legs": [sprites.get_node("RightLeg").texture, sprites.get_node("LeftLeg").texture],
	"Arms": [sprites.get_node("RightArm").texture, sprites.get_node("LeftArm").texture],
	"RightHand": sprites.get_node("RightHand").texture,
	"LeftHand": sprites.get_node("LeftHand").texture,
	"RightOffHand": sprites.get_node("RightOffHand").texture,
	"LeftOffHand": sprites.get_node("LeftOffHand").texture
}

@onready var original_scale: Vector2 = skeleton.scale

var right_weapon: Item = null
var left_weapon: Item = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.multiplayer_connection.is_server():
		queue_free()
		return

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	equipment.loaded.connect(_on_equipment_loaded)
	equipment.item_added.connect(_on_item_equiped)
	equipment.item_removed.connect(_on_item_unequiped)

	update_face.direction_changed.connect(_on_direction_changed)


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


func load_equipment_weapons():
	if right_weapon != null:
		right_weapon.queue_free()
		right_weapon = null

	if left_weapon != null:
		left_weapon.queue_free()
		left_weapon = null

	if equipment.items["RightHand"]:
		right_weapon = equipment.items["RightHand"].duplicate()
		right_weapon.scale = right_weapon.scale / original_scale
		right_weapon.get_node("Sprite").hide()
		right_weapon.get_node("EquipmentSprite").show()

	if equipment.items["LeftHand"]:
		left_weapon = equipment.items["LeftHand"].duplicate()
		left_weapon.scale = left_weapon.scale / original_scale
		left_weapon.get_node("Sprite").hide()
		left_weapon.get_node("EquipmentSprite").show()

	move_equipment_weapons()


func move_equipment_weapons():
	for child in equipment_sprites["RightHand"].get_children():
		equipment_sprites["RightHand"].remove_child(child)

	for child in equipment_sprites["LeftHand"].get_children():
		equipment_sprites["LeftHand"].remove_child(child)

	for child in equipment_sprites["RightOffHand"].get_children():
		equipment_sprites["RightOffHand"].remove_child(child)

	for child in equipment_sprites["LeftOffHand"].get_children():
		equipment_sprites["LeftOffHand"].remove_child(child)

	if skeleton.scale == original_scale:
		if right_weapon != null:
			equipment_sprites["RightHand"].add_child(right_weapon)
		if left_weapon != null:
			equipment_sprites["LeftOffHand"].add_child(left_weapon)

	else:
		if right_weapon != null:
			equipment_sprites["LeftHand"].add_child(right_weapon)
		if left_weapon != null:
			equipment_sprites["RightOffHand"].add_child(left_weapon)


func equipment_changed():
	load_equipment_single_sprite("Head")
	load_equipment_single_sprite("Body")
	load_equipment_double_sprites("Arms")
	load_equipment_double_sprites("Legs")
	load_equipment_weapons()


func _on_equipment_loaded():
	equipment_changed()


func _on_item_equiped(_item_uuid: String, _item_class: String):
	equipment_changed()


func _on_item_unequiped(_item_uuid: String):
	equipment_changed()


func _on_direction_changed(_original: bool):
	move_equipment_weapons()

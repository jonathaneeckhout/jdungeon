extends VBoxContainer

class_name EquipmentPanel

@export var item: Item:
	set(new_item):
		item = new_item
		if item:
			$Panel/TextureRect.texture = item.get_node("Icon").texture
		else:
			$Panel/TextureRect.texture = null

@export var slot: String:
	set(slot_name):
		slot = slot_name
		$Label.text = slot_name

var item_uuid: String

var grid_pos: Vector2

@onready var equipment: Equipment = $"../.."


func _gui_input(event: InputEvent):
	if event.is_action_pressed("j_right_click"):
		if item:
			equipment.player.equipment.remove_equipment_item.rpc_id(1, item.uuid)

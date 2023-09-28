extends VBoxContainer

class_name EquipmentPanel

@export var item: JItem:
	set(new_item):
		item = new_item
		if item:
			$TextureRect.texture = item.get_node("Sprite").texture
		else:
			$TextureRect.texture = null

@export var slot: String:
	set(slot_name):
		slot = slot_name
		$Label.text = slot_name

var item_uuid: String

var grid_pos: Vector2

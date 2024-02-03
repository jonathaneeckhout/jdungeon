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

var _equipment_synchronizer_rpc: EquipmentSynchronizerRPC = null


func _ready():
	assert(
		equipment.player.multiplayer_connection != null, "Target's multiplayer connection is null"
	)

	# Get the EquipmentSynchronizerRPC component.
	_equipment_synchronizer_rpc = (
		equipment
		. player
		. multiplayer_connection
		. component_list
		. get_component(EquipmentSynchronizerRPC.COMPONENT_NAME)
	)

	# Ensure the EquipmentSynchronizerRPC component is present
	assert(_equipment_synchronizer_rpc != null, "Failed to get EquipmentSynchronizerRPC component")


func _gui_input(event: InputEvent):
	if event.is_action_pressed("j_right_click"):
		if item:
			_equipment_synchronizer_rpc.remove_equipment_item(item.uuid)

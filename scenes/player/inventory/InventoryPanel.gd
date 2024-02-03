extends Panel

class_name InventoryPanel

@export var item: Item:
	set(new_item):
		item = new_item
		if item:
			$TextureRect.texture = item.get_node("Icon").texture
		else:
			$TextureRect.texture = null

@onready var inventory: Inventory = $"../.."
@onready var drag_panel = $"../../DragPanel"

var grid_pos: Vector2
var selected = false
var drag_panel_offset: Vector2

var _inventory_synchronizer_rpc: InventorySynchronizerRPC = null


func _ready():
	assert(
		inventory.player.multiplayer_connection != null, "Target's multiplayer connection is null"
	)

	# Get the InventorySynchronizerRPC component.
	_inventory_synchronizer_rpc = (
		inventory
		. player
		. multiplayer_connection
		. component_list
		. get_component(InventorySynchronizerRPC.COMPONENT_NAME)
	)

	# Ensure the InventorySynchronizerRPC component is present
	assert(_inventory_synchronizer_rpc != null, "Failed to get InventorySynchronizerRPC component")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent):
	if event.is_action_pressed("j_left_click"):
		if item:
			drag_panel.texture = $TextureRect.texture
			drag_panel.show()
			selected = true
	elif event.is_action_released("j_left_click"):
		if item:
			drag_panel.texture = null
			drag_panel.hide()
			selected = false

		if JUI.above_ui and inventory.mouse_above_this_panel:
			inventory.swap_items(self, inventory.mouse_above_this_panel)
		else:
			if item:
				_inventory_synchronizer_rpc.drop_item(item.uuid)
	elif event.is_action_pressed("j_right_click"):
		if not selected:
			if item:
				_inventory_synchronizer_rpc.use_item(item.uuid)
		else:
			selected = false
			drag_panel.hide()


func _physics_process(_delta):
	if selected:
		drag_panel.position = get_local_mouse_position() + drag_panel_offset


func _on_mouse_entered():
	inventory.mouse_above_this_panel = self


func _on_mouse_exited():
	inventory.mouse_above_this_panel = null

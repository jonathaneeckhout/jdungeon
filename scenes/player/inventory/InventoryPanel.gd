extends Panel

class_name InventoryPanel

@export var item: JItem:
	set(new_item):
		item = new_item
		if item:
			$TextureRect.texture = item.get_node("Sprite").texture
		else:
			$TextureRect.texture = null

@onready var inventory: Inventory = $"../.."
@onready var drag_panel = $"../../DragPanel"

var grid_pos: Vector2
var selected = false
var drag_panel_offset: Vector2


func _ready():
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
				J.rpcs.item.drop_inventory_item.rpc_id(1, item.uuid)


func _physics_process(_delta):
	if selected:
		drag_panel.position = get_local_mouse_position() + drag_panel_offset


func _on_mouse_entered():
	inventory.mouse_above_this_panel = self


func _on_mouse_exited():
	inventory.mouse_above_this_panel = null

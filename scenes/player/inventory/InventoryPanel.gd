extends Panel

class_name InventoryPanel

const DEFAULT_FONT: Font = preload("res://addons/gut/fonts/LobsterTwo-Regular.ttf")

@export var item: Item:
	set = set_item

@onready var inventory: Inventory = $"../.."
@onready var drag_panel = $"../../DragPanel"

var grid_pos: Vector2
var selected: bool = false
var drag_panel_offset: Vector2


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _draw():
	if item is Item:
		var font_height: int = 14
		draw_string(DEFAULT_FONT, Vector2(0, size.y - font_height), str(item.amount),HORIZONTAL_ALIGNMENT_CENTER, -1, font_height)

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
				inventory.player.inventory.client_invoke_drop_item(item.uuid)
	elif event.is_action_pressed("j_right_click"):
		if not selected:
			if item:
				inventory.player.inventory.client_invoke_use_item(item.uuid)
		else:
			selected = false
			drag_panel.hide()


func _physics_process(_delta):
	if selected:
		drag_panel.position = get_local_mouse_position() + drag_panel_offset


func set_item(new_item: Item):
	if item is Item and item.amount_changed.is_connected(queue_redraw):
		item.amount_changed.disconnect(queue_redraw)
	
	item = new_item
	
	if not item is Item:
		return
	
	item.amount_changed.connect(queue_redraw)
	$TextureRect.texture = item.get_icon()


func _on_mouse_entered():
	inventory.mouse_above_this_panel = self


func _on_mouse_exited():
	inventory.mouse_above_this_panel = null

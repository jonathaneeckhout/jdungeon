extends Panel

@export var item: Item:
	set(new_item):
		item = new_item
		if item:
			$TextureRect.texture = item.get_node("Icon").texture
		else:
			$TextureRect.texture = null

var grid_pos: Vector2

@onready var shop: Node = $"../.."

var price: int = 0


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent):
	if event.is_action_pressed("j_right_click"):
		if shop.get("shop_synchronizer") is ShopSynchronizerComponent:
			shop.shop_synchronizer.buy_shop_item.rpc_id(1, item.uuid)
		else:
			GodotLogger.error("This shop has a null shop_synchronizer or lacks the property.")


func _on_mouse_entered():
	if item:
		shop.display_info(position + size / 2, item.item_class, price)


func _on_mouse_exited():
	shop.hide_info()

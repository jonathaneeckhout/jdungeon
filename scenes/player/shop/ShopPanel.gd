extends Panel

@export var item: Item:
	set(new_item):
		item = new_item
		if item:
			$TextureRect.texture = item.get_node("Icon").texture
		else:
			$TextureRect.texture = null

var grid_pos: Vector2

@onready var shop = $"../.."

var price: int = 0


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent):
	if event.is_action_pressed("j_right_click") and shop.vendor != null:
		var shop_synchronizer_rpc: ShopSynchronizerRPC = (
			shop
			. player
			. multiplayer_connection
			. component_list
			. get_component(ShopSynchronizerRPC.COMPONENT_NAME)
		)

		# Ensure the ShopSynchronizerRPC component is present
		assert(shop_synchronizer_rpc != null, "Failed to get ShopSynchronizerRPC component")

		shop_synchronizer_rpc.buy_item(shop.vendor.name, item.uuid)


func _on_mouse_entered():
	if item:
		shop.display_info(position + size / 2, item.item_class, price)


func _on_mouse_exited():
	shop.hide_info()
